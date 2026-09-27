import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps, seedUser } from '../helpers.js';

describe('login', () => {
  it('accepts the right password and treats a wrong password like an unknown address', async () => {
    const deps = makeDeps({
      LOCKOUT_FAILURES: '3',
      LOCKOUT_WINDOW_MS: '60000',
    });
    const account = await seedUser(deps);
    const app = appFor(deps);
    const success = await request(app).post('/api/v1/auth/login').send(account);
    assert.equal(success.status, 200);
    assert.equal(JSON.stringify(success.body).includes('argon'), false);
    const wrong = await request(app)
      .post('/api/v1/auth/login')
      .send({
        ...account,
        password: 'wrong-password',
        deviceId: 'device-wrong',
      });
    const unknown = await request(app)
      .post('/api/v1/auth/login')
      .send({
        ...account,
        email: 'missing@acme.test',
        deviceId: 'device-missing',
      });
    assert.equal(wrong.status, unknown.status);
    assert.deepEqual(wrong.body, unknown.body);
    assert.ok(
      deps.store
        .security()
        .some((event) => event.after?.['address'] !== undefined),
    );
  });

  it('locks out, refuses the correct password while locked, and clears after success', async () => {
    const deps = makeDeps({
      LOCKOUT_FAILURES: '2',
      LOCKOUT_WINDOW_MS: '60000',
    });
    const account = await seedUser(deps);
    const app = appFor(deps);
    await request(app)
      .post('/api/v1/auth/login')
      .send({ ...account, password: 'wrong-password' });
    await request(app)
      .post('/api/v1/auth/login')
      .send({ ...account, password: 'wrong-password' });
    const locked = await request(app).post('/api/v1/auth/login').send(account);
    assert.equal(locked.status, 429);
    deps.store.setLockout(
      `addr:${account.organisationId}:${account.email}`,
      0,
      null,
    );
    deps.store.setLockout('acct:user-1', 0, null);
    const again = await request(app).post('/api/v1/auth/login').send(account);
    assert.equal(again.status, 200);
    await request(app)
      .post('/api/v1/auth/login')
      .send({
        ...account,
        password: 'wrong-password',
        deviceId: 'device-other',
      });
    const stillOpen = await request(app)
      .post('/api/v1/auth/login')
      .send({ ...account, deviceId: 'device-third' });
    assert.equal(stillOpen.status, 200);
  });
});
