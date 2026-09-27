import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps, seedUser } from '../helpers.js';

describe('rate limit', () => {
  it('returns 429 with a retry hint and records a security event', async () => {
    const deps = makeDeps({ RATE_LIMIT_AUTH: '2' });
    const app = appFor(deps);
    const account = await seedUser(deps);
    const body = { ...account, password: 'wrong-password' };
    const first = await request(app).post('/api/v1/auth/login').send(body);
    const second = await request(app).post('/api/v1/auth/login').send(body);
    const third = await request(app).post('/api/v1/auth/login').send(body);
    assert.equal(first.status, 401);
    assert.equal(second.status, 401);
    assert.equal(third.status, 429);
    assert.equal(third.headers['retry-after'], '60');
    assert.ok(
      deps.store.security().some((event) => event.action === 'rate_limited'),
    );
  });
});
