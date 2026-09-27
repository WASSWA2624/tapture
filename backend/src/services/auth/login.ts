import type { AppConfig } from '../../config/schema.js';
import { invalidCredentials, rateLimited } from '../../domain/errors.js';
import type { Store } from '../../repositories/store.js';
import type { TokenPair } from '../../types/index.js';
import { verifyPassword } from './password.js';
import { issueTokens } from './tokens.js';

async function noteFailure(
  store: Store,
  config: AppConfig,
  key: string,
  actor: string,
): Promise<void> {
  const current = store.lockout(key);
  const failures = current.failures + 1;
  const until =
    failures >= config.lockoutFailures
      ? new Date(Date.now() + config.lockoutWindowMs).toISOString()
      : null;
  store.setLockout(key, failures, until);
  store.recordSecurity({
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
  const addressKey = `addr:${input.organisationId}:${input.email}`;
  const addressLock = store.lockout(addressKey);
  if (
    addressLock.until !== null &&
    Date.parse(addressLock.until) > Date.now()
  ) {
    throw rateLimited();
  }
  const user = store
    .users()
    .find(
      (row) =>
        row.organisationId === input.organisationId &&
        row.email === input.email,
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
  const accountLock = store.lockout(`acct:${user.id}`);
  if (
    accountLock.until !== null &&
    Date.parse(accountLock.until) > Date.now()
  ) {
    throw rateLimited();
  }
  store.setLockout(addressKey, 0, null);
  store.setLockout(`acct:${user.id}`, 0, null);
  let device = store.devices().find((row) => row.id === input.deviceId);
  if (device === undefined) {
    device = {
      id: input.deviceId,
      userId: user.id,
      enrolledAt: new Date().toISOString(),
      lastSeenAt: new Date().toISOString(),
      revoked: false,
    };
    store.addDevice(device);
  } else if (device.userId !== user.id || device.revoked) {
    throw invalidCredentials();
  } else {
    store.saveDevice({ ...device, lastSeenAt: new Date().toISOString() });
  }
  return issueTokens(
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
