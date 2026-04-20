/** SSO provider configuration — set by distributors, not end users. */
export interface SsoConfig {
  provider: 'google';
  /** Google OAuth 2.0 client ID (public, required). */
  clientId: string;
  /** OAuth scopes to request. Default: ['openid', 'email', 'profile']. */
  scopes: string[];
  /** Restrict login to a Google Workspace domain (hd parameter). */
  hostedDomain?: string;
  /** URL of the distributor's server that returns RemoteConfig after login. */
  remoteConfigEndpoint?: string;
}

/** Active SSO session held in memory (never persisted to disk). */
export interface SsoSession {
  provider: 'google';
  accessToken: string;
  idToken?: string;
  refreshToken?: string;
  /** Unix timestamp in milliseconds when the access token expires. */
  expiresAt: number;
  user: {
    sub: string;
    email: string;
    name?: string;
    picture?: string;
  };
}

/**
 * Settings fetched from the distributor's remote server after SSO login.
 * Values here override local settings during execution.
 */
export interface RemoteConfig {
  pluginSettings?: Record<string, Record<string, unknown>>;
  pluginEnv?: Record<string, string>;
}

export interface Settings<PluginSettings = Record<string, Record<string, unknown>>> {
  recordingPlaybackLatency?: number;

  /** Configurable settings that a plugin can get and set. Settings can be available in the settings modal and are stored  */
  pluginSettings?: PluginSettings;

  /** A plugin can request environment variables to configure itself. Those can be populated here. */
  pluginEnv?: {
    [key: string]: string | undefined;
  };

  // TODO move to openai plugin
  openAiKey?: string;
  openAiOrganization?: string;
  openAiEndpoint?: string;

  /** Timeout in milliseconds before retrying a chat node call. */
  chatNodeTimeout?: number;

  chatNodeHeaders?: Record<string, string>;

  throttleChatNode?: number;

  /** SSO provider configuration set by the distributor. */
  ssoConfig?: SsoConfig;

  /** Active SSO session (in-memory only, not persisted). */
  ssoSession?: SsoSession;

  /** Remote config fetched from the distributor's server after login (in-memory only). */
  remoteConfig?: RemoteConfig;
}
