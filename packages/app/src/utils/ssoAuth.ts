import type { RemoteConfig, Settings, SsoConfig, SsoSession } from '@ironclad/rivet-core';

export interface PkceChallenge {
  codeVerifier: string;
  codeChallenge: string;
}

export interface TokenResponse {
  access_token: string;
  id_token?: string;
  refresh_token?: string;
  expires_in: number;
  token_type: string;
}

export interface GoogleUserInfo {
  sub: string;
  email: string;
  name?: string;
  picture?: string;
}

const GOOGLE_AUTH_ENDPOINT = 'https://accounts.google.com/o/oauth2/v2/auth';
const GOOGLE_TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token';
const GOOGLE_USERINFO_ENDPOINT = 'https://openidconnect.googleapis.com/v1/userinfo';

/** Generates a PKCE code_verifier and code_challenge (S256 method). */
export async function generatePKCE(): Promise<PkceChallenge> {
  const array = new Uint8Array(48);
  crypto.getRandomValues(array);
  const codeVerifier = base64UrlEncode(array);

  const encoder = new TextEncoder();
  const data = encoder.encode(codeVerifier);
  const digest = await crypto.subtle.digest('SHA-256', data);
  const codeChallenge = base64UrlEncode(new Uint8Array(digest));

  return { codeVerifier, codeChallenge };
}

/** Builds the Google OAuth 2.0 authorization URL. */
export function buildGoogleAuthUrl(
  config: SsoConfig,
  redirectUri: string,
  codeChallenge: string,
  state: string,
): string {
  const scopes = config.scopes.length > 0 ? config.scopes : ['openid', 'email', 'profile'];

  const params = new URLSearchParams({
    client_id: config.clientId,
    redirect_uri: redirectUri,
    response_type: 'code',
    scope: scopes.join(' '),
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
    state,
    access_type: 'offline',
    prompt: 'consent',
  });

  if (config.hostedDomain) {
    params.set('hd', config.hostedDomain);
  }

  return `${GOOGLE_AUTH_ENDPOINT}?${params.toString()}`;
}

/** Exchanges an authorization code for tokens using PKCE. No client secret required. */
export async function exchangeCodeForTokens(
  config: SsoConfig,
  code: string,
  codeVerifier: string,
  redirectUri: string,
): Promise<TokenResponse> {
  const params = new URLSearchParams({
    grant_type: 'authorization_code',
    client_id: config.clientId,
    code,
    code_verifier: codeVerifier,
    redirect_uri: redirectUri,
  });

  const response = await fetch(GOOGLE_TOKEN_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params.toString(),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Token exchange failed (${response.status}): ${error}`);
  }

  return response.json() as Promise<TokenResponse>;
}

/** Fetches user profile information from Google's UserInfo endpoint. */
export async function fetchGoogleUserInfo(accessToken: string): Promise<GoogleUserInfo> {
  const response = await fetch(GOOGLE_USERINFO_ENDPOINT, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!response.ok) {
    throw new Error(`UserInfo fetch failed (${response.status})`);
  }

  return response.json() as Promise<GoogleUserInfo>;
}

/** Builds an SsoSession from token and user info responses. */
export function buildSsoSession(tokens: TokenResponse, userInfo: GoogleUserInfo): SsoSession {
  return {
    provider: 'google',
    accessToken: tokens.access_token,
    idToken: tokens.id_token,
    refreshToken: tokens.refresh_token,
    expiresAt: Date.now() + tokens.expires_in * 1000,
    user: {
      sub: userInfo.sub,
      email: userInfo.email,
      name: userInfo.name,
      picture: userInfo.picture,
    },
  };
}

/** Parses a query string into a key-value map. */
export function parseQueryString(query: string): Record<string, string> {
  const result: Record<string, string> = {};
  if (!query) return result;
  for (const pair of query.split('&')) {
    const [key, value] = pair.split('=');
    if (key) {
      result[decodeURIComponent(key)] = decodeURIComponent(value ?? '');
    }
  }
  return result;
}

/**
 * Merges remote config (fetched from the distributor's server after login) into the
 * execution settings. Remote values take precedence over locally-configured values,
 * allowing distributors to centrally manage secrets without bundling them in the app.
 */
export function mergeRemoteConfig(
  settings: Settings,
  remoteConfig: RemoteConfig | undefined,
  ssoSession: SsoSession | undefined,
): Settings {
  if (!remoteConfig && !ssoSession) return settings;

  return {
    ...settings,
    ssoSession,
    pluginEnv: {
      ...settings.pluginEnv,
      ...remoteConfig?.pluginEnv,
    },
    pluginSettings: mergePluginSettings(settings.pluginSettings, remoteConfig?.pluginSettings),
  };
}

function mergePluginSettings(
  local: Record<string, Record<string, unknown>> | undefined,
  remote: Record<string, Record<string, unknown>> | undefined,
): Record<string, Record<string, unknown>> {
  if (!remote) return local ?? {};
  if (!local) return remote;

  const merged: Record<string, Record<string, unknown>> = { ...local };
  for (const [pluginId, pluginConfig] of Object.entries(remote)) {
    merged[pluginId] = { ...(merged[pluginId] ?? {}), ...pluginConfig };
  }
  return merged;
}

function base64UrlEncode(buffer: Uint8Array): string {
  return btoa(String.fromCharCode(...buffer))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}
