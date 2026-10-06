import { RETENTION_HARD_MAX_DAYS } from '../domain/retention.js';
import { parseAiConfiguration, type AiConfiguration } from './ai.js';

export interface AppConfig extends AiConfiguration {
  port: number;
  databaseUrl: string;
  tokenSecret: string;
  accessTtlSeconds: number;
  refreshTtlSeconds: number;
  retentionDays: number;
  rateLimitAuth: number;
  rateLimitGeneral: number;
  /// Maximum distinct active addresses retained by each limiter group.
  rateLimitBucketLimit: number;
  bodyLimitBytes: number;
  /// JSON body limit for `/api/v1/ai/*`, whose requests carry inline media.
  aiBodyLimitBytes: number;
  /// Exact web origins allowed cross-origin. Empty sends no CORS headers.
  corsOrigins: string[];
  packageMaxBytes: number;
  storageCeilingBytes: number;
  organisationStorageCeilingBytes: number;
  argonMemoryKib: number;
  argonIterations: number;
  argonParallelism: number;
  aiTimeoutMs: number;
  aiRetryLimit: number;
  aiBreakerThreshold: number;
  aiProjectRequestLimit: number;
  aiOrganisationRequestLimit: number;
  aiProjectDailyRequestLimit: number;
  aiOrganisationDailyRequestLimit: number;
  aiProjectBudget: number;
  aiOrganisationBudget: number;
  aiProjectDailyBudget: number;
  aiOrganisationDailyBudget: number;
  /// Operator-supplied conservative cost bound for one provider attempt.
  aiRequestCostCeiling: number;
  aiProviderUrl: string;
  aiProviderKey: string;
  aiProviderModel: string;
  lockoutFailures: number;
  lockoutWindowMs: number;
  apiVersion: string;
  buildVersion: string;
  poolMax: number;
  databaseConnectTimeoutMs: number;
  databaseStatementTimeoutMs: number;
  purgeIntervalMs: number;
  purgeBatchSize: number;
  ready: boolean;
}

function required(env: NodeJS.ProcessEnv, name: string): string {
  const value = env[name];
  if (value === undefined || value.length === 0) {
    throw new Error(`Missing required configuration: ${name}`);
  }
  return value;
}

function integer(
  value: string | undefined,
  fallback: number,
  minimum = 1,
  maximum = 2_147_483_647,
): number {
  if (value === undefined || value.length === 0) return fallback;
  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed)) {
    throw new Error(`Configuration value is not a whole number: ${value}`);
  }
  if (parsed < minimum || parsed > maximum)
    throw new Error(
      `Configuration value must be from ${minimum} to ${maximum}: ${value}`,
    );
  return parsed;
}

function quotaNumber(
  env: NodeJS.ProcessEnv,
  name: string,
  fallback: number,
  whole = false,
): number {
  const value = env[name];
  const parsed = value === undefined || value === '' ? fallback : Number(value);
  if (
    !Number.isFinite(parsed) ||
    parsed < 0 ||
    (whole && !Number.isSafeInteger(parsed))
  ) {
    throw new Error(
      `${name} must be a non-negative ${whole ? 'whole number' : 'number'}.`,
    );
  }
  return parsed;
}

/// Parses comma-separated exact origins such as `https://app.example.com`.
function origins(value: string | undefined): string[] {
  if (value === undefined) return [];
  return value
    .split(',')
    .map((entry) => entry.trim())
    .filter((entry) => entry.length > 0)
    .map((entry) => {
      const candidate = entry.replace(/\/$/, '').toLowerCase();
      let origin = '';
      try {
        const url = new URL(candidate);
        if (url.protocol === 'https:' || url.protocol === 'http:') {
          origin = url.origin;
        }
      } catch {
        origin = '';
      }
      if (origin !== candidate) {
        throw new Error(
          `CORS_ORIGINS entries must be origins such as https://app.example.com: ${entry}`,
        );
      }
      return origin;
    });
}

/// Reads one environment snapshot. An invalid snapshot throws before listen.
export function parseConfig(env: NodeJS.ProcessEnv): AppConfig {
  const aiProviderUrl =
    env['AI_PROVIDER_URL'] ??
    'https://generativelanguage.googleapis.com/v1beta';
  if (
    aiProviderUrl.length > 0 &&
    !/^https:\/\/[^\s/?#]+(?:\/[^\s?#]*)?$/.test(aiProviderUrl)
  ) {
    throw new Error('AI_PROVIDER_URL must be an HTTPS endpoint.');
  }
  const aiProviderKey = env['AI_PROVIDER_KEY'] ?? '';
  const aiRetryLimit = integer(env['AI_RETRY_LIMIT'], 2, 0);
  if (aiRetryLimit < 0 || aiRetryLimit > 5)
    throw new Error('AI_RETRY_LIMIT must be from 0 to 5.');
  const aiTimeoutMs = integer(env['AI_TIMEOUT_MS'], 8000);
  if (aiTimeoutMs < 1 || aiTimeoutMs > 120_000)
    throw new Error('AI_TIMEOUT_MS must be from 1 to 120000.');
  if (aiProviderKey.length > 0 && !env['AI_PROVIDER_MODEL']) {
    throw new Error(
      'AI_PROVIDER_MODEL is required when AI_PROVIDER_KEY is configured.',
    );
  }
  const retentionDays = integer(env['RETENTION_DAYS'], 30);
  if (retentionDays < 1 || retentionDays > RETENTION_HARD_MAX_DAYS) {
    throw new Error(
      `RETENTION_DAYS must be from 1 to ${RETENTION_HARD_MAX_DAYS}.`,
    );
  }
  const bodyLimitBytes = integer(env['BODY_LIMIT_BYTES'], 1_000_000);
  // Leaves room for the provider's 20 MB inline request plus the JSON and
  // base64 encoding the device adds in transit.
  const aiBodyLimitBytes = integer(env['AI_BODY_LIMIT_BYTES'], 27_000_000);
  if (aiBodyLimitBytes < bodyLimitBytes) {
    throw new Error('AI_BODY_LIMIT_BYTES must be at least BODY_LIMIT_BYTES.');
  }
  return {
    ...parseAiConfiguration(env, env['AI_PROVIDER_MODEL'] ?? 'default'),
    port: integer(env['PORT'], 8080, 0, 65535),
    databaseUrl: required(env, 'DATABASE_URL'),
    tokenSecret: required(env, 'TOKEN_SECRET'),
    accessTtlSeconds: integer(env['ACCESS_TTL_SECONDS'], 900),
    refreshTtlSeconds: integer(env['REFRESH_TTL_SECONDS'], 60 * 60 * 24 * 30),
    retentionDays,
    rateLimitAuth: integer(env['RATE_LIMIT_AUTH'], 10),
    rateLimitGeneral: integer(env['RATE_LIMIT_GENERAL'], 120),
    rateLimitBucketLimit: integer(
      env['RATE_LIMIT_BUCKET_LIMIT'],
      10_000,
      1,
      1_000_000,
    ),
    bodyLimitBytes,
    aiBodyLimitBytes,
    corsOrigins: origins(env['CORS_ORIGINS']),
    packageMaxBytes: integer(env['PACKAGE_MAX_BYTES'], 20_000_000),
    storageCeilingBytes: integer(env['STORAGE_CEILING_BYTES'], 50_000_000),
    organisationStorageCeilingBytes: integer(
      env['ORGANISATION_STORAGE_CEILING_BYTES'],
      500_000_000,
    ),
    argonMemoryKib: integer(env['ARGON_MEMORY_KIB'], 19456),
    argonIterations: integer(env['ARGON_ITERATIONS'], 2),
    argonParallelism: integer(env['ARGON_PARALLELISM'], 1),
    aiTimeoutMs,
    aiRetryLimit,
    aiBreakerThreshold: integer(env['AI_BREAKER_THRESHOLD'], 3),
    aiProjectRequestLimit: quotaNumber(
      env,
      'AI_PROJECT_REQUEST_LIMIT',
      10_000,
      true,
    ),
    aiOrganisationRequestLimit: quotaNumber(
      env,
      'AI_ORGANISATION_REQUEST_LIMIT',
      100_000,
      true,
    ),
    aiProjectDailyRequestLimit: quotaNumber(
      env,
      'AI_PROJECT_DAILY_REQUEST_LIMIT',
      100,
      true,
    ),
    aiOrganisationDailyRequestLimit: quotaNumber(
      env,
      'AI_ORGANISATION_DAILY_REQUEST_LIMIT',
      1_000,
      true,
    ),
    aiProjectBudget: quotaNumber(env, 'AI_PROJECT_BUDGET', 100),
    aiOrganisationBudget: quotaNumber(env, 'AI_ORGANISATION_BUDGET', 1_000),
    aiProjectDailyBudget: quotaNumber(env, 'AI_PROJECT_DAILY_BUDGET', 10),
    aiOrganisationDailyBudget: quotaNumber(
      env,
      'AI_ORGANISATION_DAILY_BUDGET',
      100,
    ),
    aiRequestCostCeiling: quotaNumber(env, 'AI_REQUEST_COST_CEILING', 0),
    aiProviderUrl,
    aiProviderKey,
    aiProviderModel: env['AI_PROVIDER_MODEL'] ?? 'default',
    lockoutFailures: integer(env['LOCKOUT_FAILURES'], 5),
    lockoutWindowMs: integer(env['LOCKOUT_WINDOW_MS'], 60_000),
    apiVersion: env['API_VERSION'] ?? '1',
    buildVersion: env['BUILD_VERSION'] ?? 'dev',
    poolMax: integer(env['POOL_MAX'], 10),
    databaseConnectTimeoutMs: integer(env['DATABASE_CONNECT_TIMEOUT_MS'], 5000),
    databaseStatementTimeoutMs: integer(
      env['DATABASE_STATEMENT_TIMEOUT_MS'],
      15000,
    ),
    purgeIntervalMs: integer(env['PURGE_INTERVAL_MS'], 60_000),
    purgeBatchSize: integer(env['PURGE_BATCH_SIZE'], 100),
    ready: (env['READY'] ?? 'true') !== 'false',
  };
}
