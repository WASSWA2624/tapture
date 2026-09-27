import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps } from '../helpers.js';

describe('health', () => {
  it('reports liveness, readiness and version', async () => {
    const deps = makeDeps();
    const app = appFor(deps);
    const live = await request(app).get('/health');
    const ready = await request(app).get('/ready');
    const version = await request(app).get('/version');
    assert.equal(live.status, 200);
    assert.equal(ready.status, 200);
    assert.equal(version.body.build, 'dev');
    assert.equal(version.body.apiVersion, '1');
  });

  it('fails readiness when the process is not ready', async () => {
    const deps = makeDeps({ READY: 'false' });
    const response = await request(appFor(deps)).get('/ready');
    assert.equal(response.status, 500);
    assert.equal(response.body.error.code, 'internal');
  });

  it('rejects a client speaking another API version', async () => {
    const response = await request(appFor(makeDeps()))
      .get('/health')
      .set('x-api-version', '0');
    assert.equal(response.status, 400);
    assert.match(response.body.error.message, /API version/);
  });
});
