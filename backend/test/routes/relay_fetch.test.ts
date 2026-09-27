import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

describe('relay fetch', () => {
  it('lists across a cursor, downloads bytes, and hides another project', async () => {
    const deps = makeDeps();
    const manager = await seedUser(deps, {
      role: 'project_manager',
      id: 'user-1',
    });
    const stranger = await seedUser(deps, {
      role: 'project_manager',
      email: 'b@acme.test',
      id: 'user-2',
    });
    const app = appFor(deps);
    const tokens = await signIn(app, manager);
    await request(app)
      .post('/api/v1/projects')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .send({ id: 'project-1', name: 'Field' });
    await request(app)
      .patch('/api/v1/projects/project-1')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .send({ relayEnabled: true });
    for (const key of ['a', 'b', 'c']) {
      await request(app)
        .post('/api/v1/projects/project-1/relay/packages')
        .set('authorization', `Bearer ${tokens.accessToken}`)
        .set('idempotency-key', key)
        .set('content-type', 'application/octet-stream')
        .send(Buffer.from(key));
    }
    const page = await request(app)
      .get('/api/v1/projects/project-1/relay/packages?limit=2')
      .set('authorization', `Bearer ${tokens.accessToken}`);
    assert.equal(page.body.items.length, 2);
    const rest = await request(app)
      .get(
        `/api/v1/projects/project-1/relay/packages?limit=2&cursor=${page.body.nextCursor}`,
      )
      .set('authorization', `Bearer ${tokens.accessToken}`);
    assert.equal(rest.body.items.length, 1);
    const downloaded = await request(app)
      .get(`/api/v1/projects/project-1/relay/packages/${page.body.items[0].id}`)
      .set('authorization', `Bearer ${tokens.accessToken}`);
    assert.equal(downloaded.status, 200);
    const other = await signIn(app, stranger);
    const hidden = await request(app)
      .get(`/api/v1/projects/project-1/relay/packages/${page.body.items[0].id}`)
      .set('authorization', `Bearer ${other.accessToken}`);
    assert.equal(hidden.status, 404);
    assert.ok(
      deps.store.security().some((event) => event.action === 'relay_denied'),
    );
  });
});
