import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { describe, it } from 'node:test';
import request from 'supertest';
import { fileURLToPath } from 'node:url';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

describe('projects', () => {
  it('registers a project, refuses an identifier change, and stores no content', async () => {
    const deps = makeDeps();
    const account = await seedUser(deps, { role: 'project_manager' });
    const app = appFor(deps);
    const tokens = await signIn(app, account);
    const created = await request(app)
      .post('/api/v1/projects')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .send({ id: 'project-1', name: 'Field' });
    const renamed = await request(app)
      .patch('/api/v1/projects/project-1')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .send({ id: 'project-2', name: 'Other' });
    const settings = await request(app)
      .patch('/api/v1/projects/project-1')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .send({ relayEnabled: true, retentionDays: 14 });
    assert.equal(created.status, 201);
    assert.equal(created.body.id, 'project-1');
    assert.equal(renamed.status, 400);
    assert.equal(settings.status, 200);
    assert.equal(settings.body.id, 'project-1');
    assert.equal(deps.store.projects()[0]?.id, 'project-1');
    assert.ok(
      deps.store.audit().some((event) => event.action === 'patch_project'),
    );
    const sql = await readFile(
      path.join(
        path.dirname(fileURLToPath(import.meta.url)),
        '../../migrations/002_projects.sql',
      ),
      'utf8',
    );
    assert.equal(/photo|template|caption|record_body/i.test(sql), false);
  });

  it('hides a project from someone who is not a member', async () => {
    const deps = makeDeps();
    const manager = await seedUser(deps, {
      role: 'project_manager',
      id: 'user-1',
    });
    const other = await seedUser(deps, {
      role: 'field_operator',
      email: 'b@acme.test',
      id: 'user-2',
    });
    const app = appFor(deps);
    const managerTokens = await signIn(app, manager);
    await request(app)
      .post('/api/v1/projects')
      .set('authorization', `Bearer ${managerTokens.accessToken}`)
      .send({ id: 'project-1', name: 'Field' });
    const otherTokens = await signIn(app, other);
    const hidden = await request(app)
      .patch('/api/v1/projects/project-1')
      .set('authorization', `Bearer ${otherTokens.accessToken}`)
      .send({ name: 'Nope' });
    assert.equal(hidden.status, 404);
  });
});
