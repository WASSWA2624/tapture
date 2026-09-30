import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

describe('authenticate', () => {
  it('accepts a valid token and rejects missing, malformed and expired tokens', async () => {
    const deps = makeDeps();
    const account = await seedUser(deps);
    const app = appFor(deps);
    const tokens = await signIn(app, account);
    const ok = await request(app)
      .get('/api/v1/auth/me')
      .set('authorization', `Bearer ${tokens.accessToken}`);
    const missing = await request(app).get('/api/v1/auth/me');
    const malformed = await request(app)
      .get('/api/v1/auth/me')
      .set('authorization', 'Bearer not-a-token');
    assert.equal(ok.status, 200);
    assert.equal(missing.status, 401);
    assert.equal(malformed.status, 401);

    const expiredDeps = makeDeps();
    expiredDeps.config = { ...expiredDeps.config, accessTtlSeconds: -5 };
    const expiredAccount = await seedUser(expiredDeps);
    const expiredApp = appFor(expiredDeps);
    const expiredTokens = await signIn(expiredApp, expiredAccount);
    const expired = await request(expiredApp)
      .get('/api/v1/auth/me')
      .set('authorization', `Bearer ${expiredTokens.accessToken}`);
    assert.equal(expired.status, 401);
  });
});
