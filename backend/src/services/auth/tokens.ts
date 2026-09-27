import { createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
import { invalidCredentials, unauthorized } from '../../domain/errors.js';
import type { AppConfig } from '../../config/schema.js';
import type { Principal } from '../../domain/permissions.js';
import type { Store } from '../../repositories/store.js';
import type { TokenPair } from '../../types/index.js';

function sign(payload: string, secret: string): string {
  const mac = createHmac('sha256', secret).update(payload).digest('base64url');
  return `${payload}.${mac}`;
}

function readSigned(token: string, secret: string): string {
  const dot = token.lastIndexOf('.');
  if (dot <= 0) throw unauthorized();
  const payload = token.slice(0, dot);
  const mac = token.slice(dot + 1);
  const expected = createHmac('sha256', secret)
    .update(payload)
    .digest('base64url');
  const left = Buffer.from(mac);
  const right = Buffer.from(expected);
  if (left.length !== right.length || !timingSafeEqual(left, right)) {
    throw unauthorized();
  }
  return payload;
}

export function issueAccess(principal: Principal, config: AppConfig): string {
  const body = Buffer.from(
    JSON.stringify({
      ...principal,
      exp: Date.now() + config.accessTtlSeconds * 1000,
    }),
  ).toString('base64url');
  return sign(body, config.tokenSecret);
}

export function readAccess(token: string, config: AppConfig): Principal {
  const json = Buffer.from(
    readSigned(token, config.tokenSecret),
    'base64url',
  ).toString('utf8');
  const parsed = JSON.parse(json) as Principal & { exp: number };
  if (parsed.exp < Date.now()) throw unauthorized();
  return {
    userId: parsed.userId,
    organisationId: parsed.organisationId,
    role: parsed.role,
    deviceId: parsed.deviceId,
    contextScope: parsed.contextScope,
  };
}

function hashToken(token: string, secret: string): string {
  return createHmac('sha256', secret).update(token).digest('hex');
}

export async function issueTokens(
  store: Store,
  principal: Principal,
  config: AppConfig,
): Promise<TokenPair> {
  const refreshToken = randomBytes(32).toString('base64url');
  store.addRefresh({
    id: randomBytes(16).toString('hex'),
    userId: principal.userId,
    deviceId: principal.deviceId,
    tokenHash: hashToken(refreshToken, config.tokenSecret),
    rotated: false,
    revoked: false,
    expiresAt: new Date(
      Date.now() + config.refreshTtlSeconds * 1000,
    ).toISOString(),
  });
  return {
    accessToken: issueAccess(principal, config),
    refreshToken,
    expiresIn: config.accessTtlSeconds,
  };
}

export async function rotate(
  store: Store,
  refreshToken: string,
  config: AppConfig,
): Promise<TokenPair> {
  const hash = hashToken(refreshToken, config.tokenSecret);
  const row = store.refresh().find((item) => item.tokenHash === hash);
  if (row === undefined || row.revoked) throw invalidCredentials();
  if (row.rotated) {
    for (const family of store.refresh()) {
      if (family.userId === row.userId && family.deviceId === row.deviceId) {
        store.saveRefresh({ ...family, revoked: true });
      }
    }
    store.recordSecurity({
      actorId: row.userId,
      action: 'refresh_reuse',
      target: row.deviceId,
      before: null,
      after: null,
    });
    throw invalidCredentials();
  }
  const device = store.devices().find((item) => item.id === row.deviceId);
  if (device === undefined || device.revoked) throw invalidCredentials();
  const user = store.users().find((item) => item.id === row.userId);
  if (user === undefined || user.status !== 'active')
    throw invalidCredentials();
  store.saveRefresh({ ...row, rotated: true });
  return issueTokens(
    store,
    {
      userId: user.id,
      organisationId: user.organisationId,
      role: user.role,
      deviceId: row.deviceId,
      contextScope: null,
    },
    config,
  );
}

export function revoke(
  store: Store,
  refreshToken: string,
  config: AppConfig,
): void {
  const hash = hashToken(refreshToken, config.tokenSecret);
  const row = store.refresh().find((item) => item.tokenHash === hash);
  if (row === undefined) return;
  for (const family of store.refresh()) {
    if (family.userId === row.userId && family.deviceId === row.deviceId) {
      store.saveRefresh({ ...family, revoked: true });
    }
  }
}

export function revokeUser(store: Store, userId: string): void {
  for (const family of store.refresh()) {
    if (family.userId === userId)
      store.saveRefresh({ ...family, revoked: true });
  }
}
