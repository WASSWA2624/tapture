import type { Express } from 'express';
import request from 'supertest';
import { parseConfig, type AppConfig } from '../src/config/schema.js';
import { createPool } from '../src/db/pool.js';
import type { Deps } from '../src/deps.js';
import { resetRateLimits } from '../src/middleware/rate_limit.js';
import { createLogger } from '../src/observability/logger.js';
import { Store } from '../src/repositories/store.js';
import { createApp } from '../src/server.js';
import { hashPassword } from '../src/services/auth/password.js';
import { resetBreakers } from '../src/services/ai/resilience.js';
import {
  fakeProvider,
  type AiProvider,
  type FakeMode,
} from '../src/services/ai/provider.js';
import { emptyMetrics } from '../src/services/metrics/metrics.js';
import type { Role } from '../src/domain/permissions.js';

export function testConfig(overrides: NodeJS.ProcessEnv = {}): AppConfig {
  return parseConfig({
    DATABASE_URL: 'memory://test',
    TOKEN_SECRET: 'test-secret-value',
    RATE_LIMIT_AUTH: '100',
    RATE_LIMIT_GENERAL: '10000',
    ARGON_MEMORY_KIB: '32',
    ARGON_ITERATIONS: '1',
    ARGON_PARALLELISM: '1',
    LOCKOUT_FAILURES: '5',
    LOCKOUT_WINDOW_MS: '60000',
    PACKAGE_MAX_BYTES: '1000000',
    STORAGE_CEILING_BYTES: '50000000',
    AI_TIMEOUT_MS: '300',
    AI_RETRY_LIMIT: '1',
    AI_BREAKER_THRESHOLD: '3',
    PORT: '0',
    ...overrides,
  });
}

export function makeDeps(
  overrides: NodeJS.ProcessEnv = {},
  mode: FakeMode = 'ok',
  provider?: AiProvider,
): Deps {
  resetRateLimits();
  resetBreakers();
  const config = testConfig(overrides);
  return {
    store: new Store(),
    config,
    pool: createPool(config),
    provider: provider ?? fakeProvider(mode),
    metrics: emptyMetrics(),
    log: createLogger(() => undefined),
  };
}

export function appFor(deps: Deps): Express {
  return createApp(deps);
}

export async function seedUser(
  deps: Deps,
  input?: { role?: Role; email?: string; selfRegister?: boolean; id?: string },
): Promise<{
  email: string;
  password: string;
  deviceId: string;
  organisationId: string;
}> {
  if (!deps.store.orgs().some((row) => row.id === 'org-1')) {
    deps.store.addOrg({
      id: 'org-1',
      name: 'Acme',
      selfRegister: input?.selfRegister ?? true,
      retentionDays: 30,
    });
  }
  const email = input?.email ?? 'a@acme.test';
  const password = 'correct-horse';
  deps.store.addUser({
    id: input?.id ?? 'user-1',
    organisationId: 'org-1',
    email,
    passwordHash: await hashPassword(password, deps.config),
    role: input?.role ?? 'administrator',
    status: 'active',
  });
  return {
    email,
    password,
    deviceId: `device-${input?.id ?? 'user-1'}`,
    organisationId: 'org-1',
  };
}

export async function signIn(
  app: Express,
  account: {
    email: string;
    password: string;
    deviceId: string;
    organisationId: string;
  },
): Promise<{ accessToken: string; refreshToken: string }> {
  const response = await request(app).post('/api/v1/auth/login').send(account);
  if (response.status !== 200) {
    throw new Error(
      `login failed ${response.status} ${JSON.stringify(response.body)}`,
    );
  }
  return response.body as { accessToken: string; refreshToken: string };
}
