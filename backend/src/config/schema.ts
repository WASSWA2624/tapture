import { RETENTION_HARD_MAX_DAYS } from '../domain/retention.js';

export interface AppConfig {
  port: number;
  databaseUrl: string;
  tokenSecret: string;
  accessTtlSeconds: number;
  refreshTtlSeconds: number;
  retentionDays: number;
  rateLimitAuth: number;
  rateLimitGeneral: number;
  bodyLimitBytes: number;
  packageMaxBytes: number;
  storageCeilingBytes: number;
  argonMemoryKib: number;
  argonIterations: number;
  argonParallelism: number;
  aiTimeoutMs: number;
  aiRetryLimit: number;
  aiBreakerThreshold: number;
  lockoutFailures: number;
  lockoutWindowMs: number;
  apiVersion: string;
  buildVersion: string;
  poolMax: number;
  ready: boolean;
}

function required(env: NodeJS.ProcessEnv, name: string): string {
  const value = env[name];
  if (value === undefined || value.length === 0) {
    throw new Error(`Missing required configuration: ${name}`);
  }
  return value;
}

function integer(value: string | undefined, fallback: number): number {
  if (value === undefined || value.length === 0) return fallback;
  const parsed = Number(value);
  if (!Number.isInteger(parsed)) {
    throw new Error(`Configuration value is not a whole number: ${value}`);
  }
  return parsed;
}

/// Reads one environment snapshot. An invalid snapshot throws before listen.
export function parseConfig(env: NodeJS.ProcessEnv): AppConfig {
  const retentionDays = integer(env['RETENTION_DAYS'], 30);
  if (retentionDays < 1 || retentionDays > RETENTION_HARD_MAX_DAYS) {
    throw new Error(
      `RETENTION_DAYS must be from 1 to ${RETENTION_HARD_MAX_DAYS}.`,
    );
  }
  return {
    port: integer(env['PORT'], 8080),
    databaseUrl: required(env, 'DATABASE_URL'),
    tokenSecret: required(env, 'TOKEN_SECRET'),
    accessTtlSeconds: integer(env['ACCESS_TTL_SECONDS'], 900),
    refreshTtlSeconds: integer(env['REFRESH_TTL_SECONDS'], 60 * 60 * 24 * 30),
    retentionDays,
    rateLimitAuth: integer(env['RATE_LIMIT_AUTH'], 10),
    rateLimitGeneral: integer(env['RATE_LIMIT_GENERAL'], 120),
    bodyLimitBytes: integer(env['BODY_LIMIT_BYTES'], 1_000_000),
    packageMaxBytes: integer(env['PACKAGE_MAX_BYTES'], 20_000_000),
    storageCeilingBytes: integer(env['STORAGE_CEILING_BYTES'], 50_000_000),
    argonMemoryKib: integer(env['ARGON_MEMORY_KIB'], 19456),
    argonIterations: integer(env['ARGON_ITERATIONS'], 2),
    argonParallelism: integer(env['ARGON_PARALLELISM'], 1),
    aiTimeoutMs: integer(env['AI_TIMEOUT_MS'], 8000),
    aiRetryLimit: integer(env['AI_RETRY_LIMIT'], 2),
    aiBreakerThreshold: integer(env['AI_BREAKER_THRESHOLD'], 3),
    lockoutFailures: integer(env['LOCKOUT_FAILURES'], 5),
    lockoutWindowMs: integer(env['LOCKOUT_WINDOW_MS'], 60_000),
    apiVersion: env['API_VERSION'] ?? '1',
    buildVersion: env['BUILD_VERSION'] ?? 'dev',
    poolMax: integer(env['POOL_MAX'], 10),
    ready: (env['READY'] ?? 'true') !== 'false',
  };
}
