import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps } from '../helpers.js';

describe('metrics', () => {
  it('counts requests and carries no project content', async () => {
    const deps = makeDeps();
    const app = appFor(deps);
    await request(app).get('/health');
    const response = await request(app).get('/metrics');
    assert.equal(response.status, 200);
    assert.ok(response.body.requests['/health'].count >= 1);
    const body = JSON.stringify(response.body);
    assert.equal(/caption|photo|template/i.test(body), false);
  });

  it('uses a bounded unmatched label for arbitrary requested paths', async () => {
    const deps = makeDeps();
    const app = appFor(deps);
    await request(app).get('/private-evidence-1');
    await request(app).get('/private-evidence-2');
    assert.equal(deps.metrics.requests['unmatched']?.count, 2);
    assert.equal(Object.keys(deps.metrics.requests).length, 1);
    assert.equal(
      JSON.stringify(deps.metrics).includes('private-evidence'),
      false,
    );
  });
});
