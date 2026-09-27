import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

describe('auth me', () => {
  it('returns identity and grants and no credential', async () => {
    const deps = makeDeps();
    const account = await seedUser(deps, { role: 'reviewer' });
    deps.store.addProject({
      id: 'project-1',
      organisationId: 'org-1',
      name: 'Field',
      relayEnabled: false,
      neverRelay: false,
      retentionDays: 30,
    });
    deps.store.addMember({
      projectId: 'project-1',
      userId: 'user-1',
      contextScope: 'north',
    });
    const app = appFor(deps);
    const tokens = await signIn(app, account);
    const response = await request(app)
      .get('/api/v1/auth/me')
      .set('authorization', `Bearer ${tokens.accessToken}`);
    const body = JSON.stringify(response.body);
    assert.equal(response.status, 200);
    assert.equal(response.body.role, 'reviewer');
    assert.equal(response.body.grants[0].projectId, 'project-1');
    assert.equal(body.includes('password'), false);
    assert.equal(body.includes('token'), false);
    assert.equal(body.includes(tokens.accessToken), false);
  });
});
