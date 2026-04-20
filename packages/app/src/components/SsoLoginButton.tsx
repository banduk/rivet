import { type FC } from 'react';
import { css } from '@emotion/react';
import { useAtomValue } from 'jotai';
import { ssoConfigState } from '../state/settings.js';
import { useSsoLogin } from '../hooks/useSsoLogin.js';

const styles = css`
  position: fixed;
  top: calc(20px + var(--project-selector-height));
  left: 20px;
  z-index: 50;
  display: flex;
  align-items: center;
  gap: 8px;

  .sso-login-btn,
  .sso-logout-btn,
  .sso-user-info {
    display: flex;
    align-items: center;
    gap: 6px;
    height: 32px;
    padding: 0 12px;
    border-radius: 4px;
    border: 1px solid var(--grey-dark);
    font-size: 12px;
    cursor: pointer;
    transition: background 0.15s;
  }

  .sso-login-btn {
    background: var(--grey-darker);
    color: var(--foreground);

    &:hover {
      background: var(--grey-darkish);
    }

    &:disabled {
      opacity: 0.6;
      cursor: default;
    }
  }

  .sso-user-info {
    background: var(--grey-darker);
    color: var(--foreground);
    cursor: default;

    img {
      width: 20px;
      height: 20px;
      border-radius: 50%;
    }
  }

  .sso-logout-btn {
    background: transparent;
    color: var(--foreground-muted);
    border-color: transparent;
    padding: 0 6px;

    &:hover {
      background: rgba(255, 255, 255, 0.1);
      color: var(--foreground);
    }
  }

  .sso-error {
    font-size: 11px;
    color: var(--error);
    max-width: 200px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
`;

export const SsoLoginButton: FC = () => {
  const config = useAtomValue(ssoConfigState);
  const { session, isLoading, error, login, logout } = useSsoLogin();

  if (!config?.clientId) {
    return null;
  }

  if (session) {
    return (
      <div css={styles}>
        <div className="sso-user-info" title={session.user.email}>
          {session.user.picture && (
            <img src={session.user.picture} alt={session.user.name ?? session.user.email} />
          )}
          <span>{session.user.name ?? session.user.email}</span>
        </div>
        <button className="sso-logout-btn" onClick={logout} title="Sign out">
          ✕
        </button>
      </div>
    );
  }

  return (
    <div css={styles}>
      <button className="sso-login-btn" onClick={login} disabled={isLoading}>
        {isLoading ? 'Signing in…' : 'Sign in'}
      </button>
      {error && <span className="sso-error" title={error}>⚠ {error}</span>}
    </div>
  );
};
