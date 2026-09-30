import { createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
import { invalidCredentials, unauthorized } from '../../domain/errors.js';
import type { AppConfig } from '../../config/schema.js';
import type { Principal } from '../../domain/permissions.js';
import type { Repository as Store } from '../../repositories/repository.js';
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
  let body: unknown;
  try {
    body = JSON.parse(
      Buffer.from(readSigned(token, config.tokenSecret), 'base64url').toString(
        'utf8',
      ),
    ) as unknown;
  } catch {
    throw unauthorized();
  }
  if (body === null || typeof body !== 'object' || Array.isArray(body))
    throw unauthorized();
  const parsed = body as Record<string, unknown>;
  if (
    typeof parsed.exp !== 'number' ||
    !Number.isSafeInteger(parsed.exp) ||
    parsed.exp <= Date.now() ||
    typeof parsed.userId !== 'string' ||
    parsed.userId.length === 0 ||
    typeof parsed.organisationId !== 'string' ||
    parsed.organisationId.length === 0 ||
    typeof parsed.deviceId !== 'string' ||
    parsed.deviceId.length === 0 ||
    (parsed.contextScope !== null && typeof parsed.contextScope !== 'string') ||
    (parsed.role !== 'administrator' &&
      parsed.role !== 'project_manager' &&
      parsed.role !== 'reviewer' &&
      parsed.role !== 'field_operator')
  )
    throw unauthorized();
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
  familyId = randomBytes(16).toString('hex'),
): Promise<TokenPair> {
  const refreshToken = randomBytes(32).toString('base64url');
  await store.addRefresh({
    id: randomBytes(16).toString('hex'),
    familyId,
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
  const result = await store.withTransaction(async (tx) =>
    rotateLocked(tx, refreshToken, config),
  );
  if (result === undefined) throw invalidCredentials();
  return result;
}

async function rotateLocked(
  store: Store,
  refreshToken: string,
  config: AppConfig,
): Promise<TokenPair | undefined> {
  const hash = hashToken(refreshToken, config.tokenSecret);
  const row = await store.refreshByHash(hash);
  if (
    row === undefined ||
    row.revoked ||
    !(Date.parse(row.expiresAt) > Date.now())
  )
    return undefined;
  if (row.rotated) {
    for (const family of await store.refreshForFamily(row.familyId)) {
      if (family.familyId === row.familyId) {
        await store.saveRefresh({ ...family, revoked: true });
      }
    }
    await store.recordSecurity({
      actorId: row.userId,
      action: 'refresh_reuse',
      target: row.deviceId,
      before: null,
      after: null,
    });
    // Commit the revocations before the caller raises the refusal.
    return undefined;
  }
  const device = await store.deviceById(row.deviceId);
  if (device === undefined || device.revoked) throw invalidCredentials();
  const user = await store.userById(row.userId);
  if (user === undefined || user.status !== 'active')
    throw invalidCredentials();
  await store.saveRefresh({ ...row, rotated: true });
  return await issueTokens(
    store,
    {
      userId: user.id,
      organisationId: user.organisationId,
      role: user.role,
      deviceId: row.deviceId,
      contextScope: null,
    },
    config,
    row.familyId,
  );
}
export async function revoke(
  store: Store,
  refreshToken: string,
  config: AppConfig,
): Promise<void> {
  await store.withTransaction(async (tx) => {
    const hash = hashToken(refreshToken, config.tokenSecret);
    const row = await tx.refreshByHash(hash);
    if (row === undefined) return;
    for (const family of await tx.refreshForFamily(row.familyId)) {
      if (family.familyId === row.familyId) {
        await tx.saveRefresh({ ...family, revoked: true });
      }
    }
  });
}
export async function revokeUser(store: Store, userId: string): Promise<void> {
  for (const family of await store.refreshForUser(userId)) {
    if (family.userId === userId)
      await store.saveRefresh({ ...family, revoked: true });
  }
}
