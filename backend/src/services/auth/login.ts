import type { AppConfig } from '../../config/schema.js';
import { normaliseEmail, sameEmail } from '../../domain/email.js';
import { invalidCredentials, rateLimited } from '../../domain/errors.js';
import type { Repository as Store } from '../../repositories/repository.js';
import type { TokenPair } from '../../types/index.js';
import { verifyPassword } from './password.js';
import { issueTokens } from './tokens.js';
async function noteFailure(
  store: Store,
  config: AppConfig,
  key: string,
  actor: string,
): Promise<void> {
  const current = await store.lockout(key);
  const failures = current.failures + 1;
  const until =
    failures >= config.lockoutFailures
      ? new Date(Date.now() + config.lockoutWindowMs).toISOString()
      : null;
  await store.setLockout(key, failures, until);
  await store.recordSecurity({
    actorId: actor,
    action: 'auth_failure',
    target: key,
    before: null,
    after: { failures, address: key, at: new Date().toISOString() },
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
  const user = (await store.users()).find(
    (row) =>
      row.organisationId === input.organisationId &&
      sameEmail(row.email, email),
  );
  const hash = user?.passwordHash ?? '';
  const ok = await verifyPassword(input.password, hash, config);
  if (user === undefined || user.status !== 'active' || !ok) {
    await noteFailure(store, config, addressKey, user?.id ?? 'unknown');
    if (user !== undefined) {
      await noteFailure(store, config, `acct:${user.id}`, user.id);
    }
    throw invalidCredentials();
  }
  const accountLock = await store.lockout(`acct:${user.id}`);
  if (
    accountLock.until !== null &&
    Date.parse(accountLock.until) > Date.now()
  ) {
    throw rateLimited();
  }
  await store.setLockout(addressKey, 0, null);
  await store.setLockout(`acct:${user.id}`, 0, null);
  let device = (await store.devices()).find((row) => row.id === input.deviceId);
  if (device === undefined) {
    device = {
      id: input.deviceId,
      userId: user.id,
      enrolledAt: new Date().toISOString(),
      lastSeenAt: new Date().toISOString(),
      revoked: false,
    };
    await store.addDevice(device);
  } else if (device.userId !== user.id || device.revoked) {
    throw invalidCredentials();
  } else {
    await store.saveDevice({ ...device, lastSeenAt: new Date().toISOString() });
  }
  return await issueTokens(
    store,
    {
      userId: user.id,
      organisationId: user.organisationId,
      role: user.role,
      deviceId: device.id,
      contextScope: null,
    },
    config,
  );
}
