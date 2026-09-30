import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { Store } from '../../src/repositories/store.js';
import { issueTokens, revoke, rotate } from '../../src/services/auth/tokens.js';
import { testConfig } from '../helpers.js';
import { AppError } from '../../src/domain/errors.js';

describe('tokens', () => {
  it('rotates once, kills the family on reuse, and allows a second logout', async () => {
    const store = new Store();
    const config = testConfig();
    store.addDevice({
      id: 'device-1',
      userId: 'user-1',
      enrolledAt: new Date().toISOString(),
      lastSeenAt: new Date().toISOString(),
      revoked: false,
    });
    store.addUser({
      id: 'user-1',
      organisationId: 'org-1',
      email: 'a@acme.test',
      passwordHash: 'hash',
      role: 'reviewer',
      status: 'active',
    });
    const first = await issueTokens(
      store,
      {
        userId: 'user-1',
        organisationId: 'org-1',
        role: 'reviewer',
        deviceId: 'device-1',
        contextScope: null,
      },
      config,
    );
    const rotated = await rotate(store, first.refreshToken, config);
    assert.notEqual(rotated.refreshToken, first.refreshToken);
    await assert.rejects(
      () => rotate(store, first.refreshToken, config),
      (error: unknown) => error instanceof AppError,
    );
    await assert.rejects(() => rotate(store, rotated.refreshToken, config));
    assert.ok(
      store.security().some((event) => event.action === 'refresh_reuse'),
    );
    await revoke(store, rotated.refreshToken, config);
    await revoke(store, rotated.refreshToken, config);
    assert.equal(store.refresh().filter((row) => row.revoked).length > 0, true);
    const families = new Set(store.refresh().map((row) => row.deviceId));
    assert.equal(families.size, 1);
  });
});
