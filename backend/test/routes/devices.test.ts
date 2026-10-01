import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

describe('devices', () => {
  it('enrols, lists and revokes, then blocks refresh and relay', async () => {
    const deps = makeDeps();
    const account = await seedUser(deps, { role: 'project_manager' });
    const app = appFor(deps);
    const tokens = await signIn(app, account);
    const enrolled = await request(app)
      .post('/api/v1/devices')
      .set('authorization', `Bearer ${tokens.accessToken}`);
    const listed = await request(app)
      .get('/api/v1/devices')
      .set('authorization', `Bearer ${tokens.accessToken}`);
    assert.equal(enrolled.status, 201);
    assert.equal(listed.body.items.length, 1);
    assert.equal(listed.body.nextCursor, null);
    const removed = await request(app)
      .delete(`/api/v1/devices/${account.deviceId}`)
      .set('authorization', `Bearer ${tokens.accessToken}`);
    assert.equal(removed.status, 204);
    const refreshed = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: tokens.refreshToken });
    const relay = await request(app)
      .get('/api/v1/projects/missing/relay/state')
      .set('authorization', `Bearer ${tokens.accessToken}`);
    assert.equal(refreshed.status, 401);
    assert.equal(relay.status, 401);
    const again = await request(app)
      .post('/api/v1/auth/logout')
      .send({ refreshToken: tokens.refreshToken });
    const twice = await request(app)
      .post('/api/v1/auth/logout')
      .send({ refreshToken: tokens.refreshToken });
    assert.equal(again.status, 204);
    assert.equal(twice.status, 204);
  });
});
