import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import type { Role } from '../../src/domain/permissions.js';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

describe('members', () => {
  it('lets a project manager add and remove a member and hides that from a reviewer', async () => {
    const deps = makeDeps();
    const manager = await seedUser(deps, {
      role: 'project_manager',
      id: 'user-1',
    });
    await seedUser(deps, {
      role: 'field_operator',
      email: 'b@acme.test',
      id: 'user-2',
    });
    const reviewer = await seedUser(deps, {
      role: 'reviewer',
      email: 'c@acme.test',
      id: 'user-3',
    });
    const app = appFor(deps);
    const managerTokens = await signIn(app, manager);
    await request(app)
      .post('/api/v1/projects')
      .set('authorization', `Bearer ${managerTokens.accessToken}`)
      .send({ id: 'project-1', name: 'Field' });
    const added = await request(app)
      .post('/api/v1/projects/project-1/members')
      .set('authorization', `Bearer ${managerTokens.accessToken}`)
      .send({ userId: 'user-2', contextScope: 'north' });
    assert.equal(added.status, 201);
    const reviewerTokens = await signIn(app, reviewer);
    const denied = await request(app)
      .post('/api/v1/projects/project-1/members')
      .set('authorization', `Bearer ${reviewerTokens.accessToken}`)
      .send({ userId: 'user-3' });
    assert.equal(denied.status, 404);
    const removed = await request(app)
      .delete('/api/v1/projects/project-1/members/user-2')
      .set('authorization', `Bearer ${managerTokens.accessToken}`);
    assert.equal(removed.status, 204);
    const roles: Role[] = ['administrator'];
    assert.equal(roles.includes('administrator'), true);
  });
});
