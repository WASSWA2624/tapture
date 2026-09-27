import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { describe, it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

describe('accounts', () => {
  it('registers when enabled and rejects a duplicate', async () => {
    const deps = makeDeps();
    deps.store.addOrg({
      id: 'org-1',
      name: 'Acme',
      selfRegister: true,
      retentionDays: 30,
    });
    const app = appFor(deps);
    const created = await request(app).post('/api/v1/auth/register').send({
      email: 'new@acme.test',
      password: 'correct-horse',
      organisationId: 'org-1',
    });
    const duplicate = await request(app).post('/api/v1/auth/register').send({
      email: 'new@acme.test',
      password: 'correct-horse',
      organisationId: 'org-1',
    });
    assert.equal(created.status, 201);
    assert.equal(duplicate.status, 409);
  });

  it('does not reveal an address when registration is disabled or on reset', async () => {
    const deps = makeDeps();
    const account = await seedUser(deps, { selfRegister: false });
    const app = appFor(deps);
    const known = await request(app).post('/api/v1/auth/register').send({
      email: account.email,
      password: 'correct-horse',
      organisationId: 'org-1',
    });
    const unknown = await request(app).post('/api/v1/auth/register').send({
      email: 'missing@acme.test',
      password: 'correct-horse',
      organisationId: 'org-1',
    });
    assert.equal(known.status, unknown.status);
    assert.deepEqual(known.body, unknown.body);
    const resetKnown = await request(app).post('/api/v1/auth/reset').send({
      email: account.email,
      organisationId: 'org-1',
    });
    const resetUnknown = await request(app).post('/api/v1/auth/reset').send({
      email: 'missing@acme.test',
      organisationId: 'org-1',
    });
    assert.deepEqual(resetKnown.body, resetUnknown.body);
  });

  it('rejects a wrong current password and an expired or replayed reset', async () => {
    const deps = makeDeps();
    const account = await seedUser(deps);
    const app = appFor(deps);
    const tokens = await signIn(app, account);
    const wrong = await request(app)
      .post('/api/v1/auth/change-password')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .send({
        currentPassword: 'not-the-password',
        nextPassword: 'another-horse',
      });
    assert.equal(wrong.status, 401);
    const expired = 'expired-token';
    deps.store.addInvite({
      tokenHash: createHash('sha256').update(expired).digest('hex'),
      userId: 'user-1',
      used: false,
      expiresAt: new Date(Date.now() - 1000).toISOString(),
    });
    const expiredResponse = await request(app).post('/api/v1/auth/reset').send({
      token: expired,
      password: 'another-horse',
    });
    assert.equal(expiredResponse.status, 400);
    const replay = 'replay-token';
    deps.store.addInvite({
      tokenHash: createHash('sha256').update(replay).digest('hex'),
      userId: 'user-1',
      used: false,
      expiresAt: new Date(Date.now() + 60_000).toISOString(),
    });
    const first = await request(app).post('/api/v1/auth/reset').send({
      token: replay,
      password: 'another-horse',
    });
    const second = await request(app).post('/api/v1/auth/reset').send({
      token: replay,
      password: 'another-horse',
    });
    assert.equal(first.status, 200);
    assert.equal(second.status, 400);
    const refreshed = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: tokens.refreshToken });
    assert.equal(refreshed.status, 401);
  });
});
