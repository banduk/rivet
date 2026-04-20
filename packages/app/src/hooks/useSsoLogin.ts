import { useState } from 'react';
import { useAtom, useAtomValue, useSetAtom } from 'jotai';
import { invoke } from '@tauri-apps/api/tauri';
import { listen } from '@tauri-apps/api/event';
import { open as shellOpen } from '@tauri-apps/api/shell';
import { ssoConfigState, ssoSessionState, remoteConfigState } from '../state/settings.js';
import type { RemoteConfig, SsoSession } from '@ironclad/rivet-core';
import {
  generatePKCE,
  buildGoogleAuthUrl,
  exchangeCodeForTokens,
  fetchGoogleUserInfo,
  buildSsoSession,
  parseQueryString,
} from '../utils/ssoAuth.js';
import { isInTauri } from '../utils/tauri.js';

export interface UseSsoLoginResult {
  session: SsoSession | undefined;
  isLoading: boolean;
  error: string | undefined;
  login: () => Promise<void>;
  logout: () => void;
}

export function useSsoLogin(): UseSsoLoginResult {
  const config = useAtomValue(ssoConfigState);
  const [session, setSession] = useAtom(ssoSessionState);
  const setRemoteConfig = useSetAtom(remoteConfigState);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | undefined>(undefined);

  const login = async () => {
    if (!config) {
      setError('SSO is not configured. Set a client ID in Settings → Authentication.');
      return;
    }
    if (!isInTauri()) {
      setError('SSO login is only available in the desktop app.');
      return;
    }

    setIsLoading(true);
    setError(undefined);

    try {
      const { codeVerifier, codeChallenge } = await generatePKCE();
      const state = crypto.randomUUID();

      // Register the port listener BEFORE invoking the Rust command to avoid a race.
      // The Rust command emits "oauth://port" as soon as it binds the TCP socket,
      // then blocks waiting for the browser callback.
      let portResolve!: (port: number) => void;
      const portPromise = new Promise<number>((resolve) => {
        portResolve = resolve;
      });
      const unlistenPort = await listen<{ port: number }>('oauth://port', (event) => {
        portResolve(event.payload.port);
      });

      const callbackPromise = invoke<string>('start_oauth_callback_server');
      const port = await portPromise;
      unlistenPort();

      const redirectUri = `http://127.0.0.1:${port}`;
      const authUrl = buildGoogleAuthUrl(config, redirectUri, codeChallenge, state);

      await shellOpen(authUrl);

      // Await the query string returned by the Rust callback server
      const queryString = await callbackPromise;
      const params = parseQueryString(queryString);

      if (params['error']) {
        throw new Error(`OAuth error: ${params['error']} — ${params['error_description'] ?? ''}`);
      }
      if (!params['code']) {
        throw new Error('No authorization code in callback.');
      }
      if (params['state'] !== state) {
        throw new Error('OAuth state mismatch — possible CSRF attack.');
      }

      const tokens = await exchangeCodeForTokens(config, params['code']!, codeVerifier, redirectUri);
      const userInfo = await fetchGoogleUserInfo(tokens.access_token);
      const newSession = buildSsoSession(tokens, userInfo);

      setSession(newSession);

      if (config.remoteConfigEndpoint) {
        await fetchAndApplyRemoteConfig(config.remoteConfigEndpoint, tokens.access_token, setRemoteConfig);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    setSession(undefined);
    setRemoteConfig(undefined);
    setError(undefined);
  };

  return { session, isLoading, error, login, logout };
}

async function fetchAndApplyRemoteConfig(
  endpoint: string,
  accessToken: string,
  setRemoteConfig: (config: RemoteConfig | undefined) => void,
): Promise<void> {
  const response = await fetch(endpoint, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!response.ok) {
    throw new Error(`Remote config fetch failed (${response.status}): ${await response.text()}`);
  }

  const remoteConfig = (await response.json()) as RemoteConfig;
  setRemoteConfig(remoteConfig);
}
