import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import type { Role } from '../../src/domain/permissions.js';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

describe('organisation users', () => {
  it('pages administrators and hides the list from every other role', async () => {
    const deps = makeDeps();
    const admin = await seedUser(deps, { role: 'administrator', id: 'user-1' });
    await seedUser(deps, {
      role: 'reviewer',
      email: 'b@acme.test',
      id: 'user-2',
    });
    await seedUser(deps, {
      role: 'field_operator',
      email: 'c@acme.test',
      id: 'user-3',
    });
    const app = appFor(deps);
    const tokens = await signIn(app, admin);
    const page = await request(app)
      .get('/api/v1/org/users?limit=2')
      .set('authorization', `Bearer ${tokens.accessToken}`);
    assert.equal(page.status, 200);
    assert.equal(page.body.users.length, 2);
    assert.ok(page.body.nextCursor);
    const next = await request(app)
      .get(`/api/v1/org/users?limit=2&cursor=${page.body.nextCursor}`)
      .set('authorization', `Bearer ${tokens.accessToken}`);
    assert.equal(next.body.users.length, 1);
    const roles: Role[] = ['project_manager', 'reviewer', 'field_operator'];
    for (const role of roles) {
      const account = await seedUser(deps, {
        role,
        email: `${role}@acme.test`,
        id: `user-${role}`,
      });
      const session = await signIn(app, account);
      const hidden = await request(app)
        .get('/api/v1/org/users')
        .set('authorization', `Bearer ${session.accessToken}`);
      const patch = await request(app)
        .patch('/api/v1/org/users/user-1')
        .set('authorization', `Bearer ${session.accessToken}`)
        .send({ role: 'administrator' });
      assert.equal(hidden.status, 404);
      assert.equal(patch.status, 404);
    }
  });

  it('refuses a password on the role patch', async () => {
    const deps = makeDeps();
    const admin = await seedUser(deps);
    const app = appFor(deps);
    const tokens = await signIn(app, admin);
    const response = await request(app)
      .patch('/api/v1/org/users/user-1')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .send({ password: 'correct-horse' });
    assert.equal(response.status, 400);
  });
});
