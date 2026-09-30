import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { describe, it } from 'node:test';
import { login } from '../../src/services/auth/login.js';
import { changePassword } from '../../src/services/auth/account.js';
import {
  hashPassword,
  passwordNeedsRehash,
} from '../../src/services/auth/password.js';
import {
  issueTokens,
  readAccess,
  revoke,
  rotate,
} from '../../src/services/auth/tokens.js';
import { makeDeps, seedUser, testConfig } from '../helpers.js';
import { principal, seededStore } from '../fakes/relay_fixture.js';

describe('authentication hardening', () => {
  it('never reactivates an account disabled while a password change is being verified', async () => {
    const deps = makeDeps();
    const account = await seedUser(deps);
    const before = deps.store.users()[0];
    assert.ok(before);
    const transaction = deps.store.withTransaction.bind(deps.store);
    deps.store.withTransaction = async (work) => {
      deps.store.saveUser({ ...before, status: 'disabled' });
      return transaction(work);
    };
    await assert.rejects(() =>
      changePassword(deps.store, deps.config, {
        userId: before.id,
        currentPassword: account.password,
        nextPassword: 'replacement-password',
      }),
    );
    assert.equal(deps.store.users()[0]?.status, 'disabled');
    assert.equal(deps.store.users()[0]?.passwordHash, before.passwordHash);
    assert.equal(deps.store.audit().length, 0);
  });

  it('refuses login if the account changed before enrollment and token issue commit', async () => {
    const deps = makeDeps();
    const account = await seedUser(deps);
    const before = deps.store.users()[0];
    assert.ok(before);
    const transaction = deps.store.withTransaction.bind(deps.store);
    deps.store.withTransaction = async (work) => {
      deps.store.saveUser({ ...before, status: 'disabled' });
      return transaction(work);
    };
    await assert.rejects(() => login(deps.store, deps.config, account));
    assert.equal(deps.store.devices().length, 0);
    assert.equal(deps.store.refresh().length, 0);
    assert.equal(deps.store.users()[0]?.status, 'disabled');
  });
  it('replay revokes only its chain and repeated logout leaves an independent login usable', async () => {
    const store = seededStore();
    const config = testConfig();
    const first = await issueTokens(store, principal, config);
    const independent = await issueTokens(store, principal, config);
    const rotated = await rotate(store, first.refreshToken, config);
    assert.equal(store.refresh()[0]?.familyId, store.refresh()[2]?.familyId);
    assert.notEqual(store.refresh()[0]?.familyId, store.refresh()[1]?.familyId);
    await assert.rejects(() => rotate(store, first.refreshToken, config));
    await assert.rejects(() => rotate(store, rotated.refreshToken, config));
    const surviving = await rotate(store, independent.refreshToken, config);
    const third = await issueTokens(store, principal, config);
    await revoke(store, surviving.refreshToken, config);
    await revoke(store, surviving.refreshToken, config);
    assert.ok((await rotate(store, third.refreshToken, config)).refreshToken);
  });

  it('rehashes an old parameter set only after successful verification', async () => {
    const deps = makeDeps({ ARGON_ITERATIONS: '2' });
    const account = await seedUser(deps);
    const user = deps.store.users()[0];
    assert.ok(user);
    const oldHash = await hashPassword(
      account.password,
      testConfig({ ARGON_ITERATIONS: '1' }),
    );
    deps.store.saveUser({ ...user, passwordHash: oldHash });
    await assert.rejects(() =>
      login(deps.store, deps.config, { ...account, password: 'incorrect' }),
    );
    assert.equal(deps.store.users()[0]?.passwordHash, oldHash);
    await login(deps.store, deps.config, account);
    const rehashed = deps.store.users()[0]?.passwordHash ?? '';
    assert.notEqual(rehashed, oldHash);
    assert.equal(passwordNeedsRehash(rehashed, deps.config), false);
  });

  it('rejects correctly signed malformed principals with an authentication error', () => {
    const config = testConfig();
    for (const body of [
      'invalid-json',
      JSON.stringify({
        ...principal,
        role: 'unknown',
        exp: Date.now() + 10000,
      }),
      JSON.stringify({ ...principal, exp: 'forever' }),
    ]) {
      const payload = Buffer.from(body).toString('base64url');
      const signature = createHmac('sha256', config.tokenSecret)
        .update(payload)
        .digest('base64url');
      assert.throws(
        () => readAccess(`${payload}.${signature}`, config),
        (error: unknown) =>
          error instanceof Error &&
          'code' in error &&
          error.code === 'unauthorized',
      );
    }
  });
});
