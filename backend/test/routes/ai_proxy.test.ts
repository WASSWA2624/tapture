import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

describe('ai proxy', () => {
  it('passes a payload through and records usage without the payload', async () => {
    const deps = makeDeps();
    const account = await seedUser(deps, { role: 'field_operator' });
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
      contextScope: null,
    });
    const app = appFor(deps);
    const tokens = await signIn(app, account);
    const response = await request(app)
      .post('/api/v1/ai/extract')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .send({
        projectId: 'project-1',
        model: 'fake',
        payload: Buffer.from('caption').toString('base64'),
      });
    assert.equal(response.status, 200);
    assert.match(response.body.text, /^ok:/);
    const usage = deps.store.usage()[0];
    assert.ok(usage !== undefined);
    assert.equal(JSON.stringify(usage).includes('caption'), false);
    const report = await request(app)
      .get('/api/v1/ai/usage')
      .query({ project: 'project-1', from: '2000-01-01', to: '2999-01-01' })
      .set('authorization', `Bearer ${tokens.accessToken}`);
    assert.equal(report.status, 200);
    assert.equal(JSON.stringify(report.body).includes('caption'), false);
  });
});
