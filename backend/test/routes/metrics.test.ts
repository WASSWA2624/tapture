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
});
