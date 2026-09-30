import type { AppConfig } from '../../config/schema.js';
import { normaliseEmail } from '../../domain/email.js';
import { invalidCredentials, rateLimited } from '../../domain/errors.js';
import type { Repository as Store } from '../../repositories/repository.js';
import type { TokenPair } from '../../types/index.js';
import {
  hashPassword,
  passwordNeedsRehash,
  verifyPassword,
} from './password.js';
import { issueTokens } from './tokens.js';
async function noteFailure(
  store: Store,
  config: AppConfig,
  key: string,
  actor: string,
): Promise<void> {
  await store.withTransaction(async (tx) => {
    const current = await tx.lockout(key);
    const failures =
      current.until !== null && Date.parse(current.until) <= Date.now()
        ? 1
        : current.failures + 1;
    const until =
      failures >= config.lockoutFailures
        ? new Date(Date.now() + config.lockoutWindowMs).toISOString()
        : null;
    await tx.setLockout(key, failures, until);
    await tx.recordSecurity({
      actorId: actor,
      action: 'auth_failure',
      target: key,
      before: null,
      after: { failures, address: key, at: new Date().toISOString() },
    });
  });
}
/// Signs in. An unknown address and a wrong password return the same error.
export async function login(
  store: Store,
  config: AppConfig,
  input: {
    email: string;
    password: string;
    deviceId: string;
    organisationId: string;
  },
): Promise<TokenPair> {
  const email = normaliseEmail(input.email);
  const addressKey = `addr:${input.organisationId}:${email}`;
  const addressLock = await store.lockout(addressKey);
  if (
    addressLock.until !== null &&
    Date.parse(addressLock.until) > Date.now()
  ) {
    throw rateLimited();
  }
  const user = await store.userByEmail(input.organisationId, email);
  const hash = user?.passwordHash ?? '';
  const ok = await verifyPassword(input.password, hash, config);
  if (user === undefined || user.status !== 'active' || !ok) {
    await noteFailure(store, config, addressKey, user?.id ?? 'unknown');
    if (user !== undefined) {
      await noteFailure(store, config, `acct:${user.id}`, user.id);
    }
    throw invalidCredentials();
  }
  const passwordHash = passwordNeedsRehash(hash, config)
    ? await hashPassword(input.password, config)
    : hash;
  return store.withTransaction(async (tx) => {
    const current = await tx.userById(user.id);
    if (
      current === undefined ||
      current.status !== 'active' ||
      current.passwordHash !== hash
    )
      throw invalidCredentials();
    const accountLock = await tx.lockout(`acct:${user.id}`);
    if (
      accountLock.until !== null &&
      Date.parse(accountLock.until) > Date.now()
    ) {
      throw rateLimited();
    }
    await tx.setLockout(addressKey, 0, null);
    await tx.setLockout(`acct:${user.id}`, 0, null);
    if (passwordHash !== current.passwordHash)
      await tx.saveUser({ ...current, passwordHash });
    let device = await tx.deviceById(input.deviceId);
    if (device === undefined) {
      device = {
        id: input.deviceId,
        userId: user.id,
        enrolledAt: new Date().toISOString(),
        lastSeenAt: new Date().toISOString(),
        revoked: false,
      };
      await tx.addDevice(device);
    } else if (device.userId !== user.id || device.revoked) {
      throw invalidCredentials();
    } else {
      await tx.saveDevice({ ...device, lastSeenAt: new Date().toISOString() });
    }
    return await issueTokens(
      tx,
      {
        userId: user.id,
        organisationId: current.organisationId,
        role: current.role,
        deviceId: device.id,
        contextScope: null,
      },
      config,
    );
  });
}
