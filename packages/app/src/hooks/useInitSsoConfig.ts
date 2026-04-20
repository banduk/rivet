import useAsyncEffect from 'use-async-effect';
import { useAtom } from 'jotai';
import { ssoConfigState } from '../state/settings.js';
import { getEnvVar } from '../utils/tauri.js';

/**
 * Runs once at startup. If no SSO config is persisted, attempts to build one
 * from environment variables (RIVET_SSO_CLIENT_ID, etc.).
 * This lets distributors configure SSO without requiring users to visit Settings.
 */
export function useInitSsoConfig() {
  const [config, setConfig] = useAtom(ssoConfigState);

  useAsyncEffect(async () => {
    if (config?.clientId) return;

    const clientId = await getEnvVar('RIVET_SSO_CLIENT_ID');
    if (!clientId) return;

    const scopesEnv = await getEnvVar('RIVET_SSO_SCOPES');
    const scopes = scopesEnv ? scopesEnv.split(/\s+/).filter(Boolean) : ['openid', 'email', 'profile'];
    const hostedDomain = (await getEnvVar('RIVET_SSO_HOSTED_DOMAIN')) || undefined;
    const remoteConfigEndpoint = (await getEnvVar('RIVET_SSO_REMOTE_CONFIG_URL')) || undefined;

    setConfig({ provider: 'google', clientId, scopes, hostedDomain, remoteConfigEndpoint });
  }, []);
}
