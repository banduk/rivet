import { type FC } from 'react';
import { useAtom } from 'jotai';
import { css } from '@emotion/react';
import { Field, HelperMessage, Label } from '@atlaskit/form';
import TextField from '@atlaskit/textfield';
import { ssoConfigState } from '../state/settings.js';
import type { SsoConfig } from '@ironclad/rivet-core';

const fields = css`
  display: flex;
  flex-direction: column;
  gap: 20px;

  .hint {
    background: var(--grey-darkish);
    border-left: 3px solid var(--primary);
    padding: 12px 16px;
    border-radius: 0 4px 4px 0;
    font-size: 12px;
    color: var(--foreground-muted);
    line-height: 1.6;

    code {
      background: var(--grey-dark);
      padding: 1px 5px;
      border-radius: 3px;
      font-family: monospace;
    }
  }
`;

const DEFAULT_SCOPES = 'openid email profile';

export const SsoSettingsPage: FC = () => {
  const [config, setConfig] = useAtom(ssoConfigState);

  const clientId = config?.clientId ?? '';
  const scopes = config?.scopes.join(' ') ?? DEFAULT_SCOPES;
  const hostedDomain = config?.hostedDomain ?? '';
  const remoteConfigEndpoint = config?.remoteConfigEndpoint ?? '';

  const update = (patch: Partial<Omit<SsoConfig, 'provider'>>) => {
    setConfig((prev) => ({
      provider: 'google',
      clientId: prev?.clientId ?? '',
      scopes: prev?.scopes ?? DEFAULT_SCOPES.split(' '),
      ...prev,
      ...patch,
    }));
  };

  const clearIfEmpty = () => {
    if (!config?.clientId) {
      setConfig(undefined);
    }
  };

  return (
    <div css={fields}>
      <div className="hint">
        Configure Google SSO to allow users to authenticate and automatically fetch secrets from your server.
        Leave <strong>Client ID</strong> empty to disable SSO entirely.
        <br />
        <br />
        Alternatively, set these environment variables before launching the app:
        <br />
        <code>RIVET_SSO_CLIENT_ID</code>, <code>RIVET_SSO_SCOPES</code>,{' '}
        <code>RIVET_SSO_HOSTED_DOMAIN</code>, <code>RIVET_SSO_REMOTE_CONFIG_URL</code>
      </div>

      <Field name="sso-client-id" label="Google OAuth Client ID">
        {() => (
          <>
            <TextField
              value={clientId}
              placeholder="123456789-abc.apps.googleusercontent.com"
              onChange={(e) => update({ clientId: (e.target as HTMLInputElement).value })}
              onBlur={clearIfEmpty}
            />
            <HelperMessage>
              Create an OAuth 2.0 Client ID in the Google Cloud Console with type "Desktop app". Ensure{' '}
              <code>http://127.0.0.1</code> is listed as an authorized redirect URI.
            </HelperMessage>
          </>
        )}
      </Field>

      <Field name="sso-scopes" label="OAuth Scopes">
        {() => (
          <>
            <TextField
              value={scopes}
              placeholder={DEFAULT_SCOPES}
              onChange={(e) =>
                update({ scopes: (e.target as HTMLInputElement).value.split(/\s+/).filter(Boolean) })
              }
            />
            <HelperMessage>Space-separated OAuth scopes. Default: openid email profile</HelperMessage>
          </>
        )}
      </Field>

      <Field name="sso-hosted-domain" label="Hosted Domain (optional)">
        {() => (
          <>
            <TextField
              value={hostedDomain}
              placeholder="yourcompany.com"
              onChange={(e) =>
                update({ hostedDomain: (e.target as HTMLInputElement).value || undefined })
              }
            />
            <HelperMessage>
              Restrict login to a Google Workspace domain. Leave empty to allow any Google account.
            </HelperMessage>
          </>
        )}
      </Field>

      <Field name="sso-remote-config-endpoint" label="Remote Config Endpoint (optional)">
        {() => (
          <>
            <TextField
              value={remoteConfigEndpoint}
              placeholder="https://api.yourcompany.com/rivet/config"
              onChange={(e) =>
                update({ remoteConfigEndpoint: (e.target as HTMLInputElement).value || undefined })
              }
            />
            <HelperMessage>
              After login, Rivet will call this URL with <code>Authorization: Bearer &lt;token&gt;</code> and
              expect a JSON response with <code>pluginSettings</code> and/or <code>pluginEnv</code>. These
              values are merged into the execution settings, overriding any local values.
            </HelperMessage>
          </>
        )}
      </Field>
    </div>
  );
};
