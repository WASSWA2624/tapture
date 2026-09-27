import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { makeDeps } from './helpers.js';
import { createApp, listen, shutdown } from '../src/server.js';

describe('boot', () => {
  it('starts, answers health, and shuts down', async () => {
    const deps = makeDeps();
    const server = await listen(deps);
    try {
      const address = server.address();
      assert.ok(address !== null && typeof address === 'object');
      const response = await request(`http://127.0.0.1:${address.port}`).get(
        '/health',
      );
      assert.equal(response.status, 200);
      assert.equal(deps.store.schemaHistory().length, 0);
    } finally {
      await shutdown(deps, server);
    }
    assert.equal(deps.pool.status().draining, true);
  });

  it('does not migrate while serving', () => {
    const deps = makeDeps();
    createApp(deps);
    assert.equal(deps.store.schemaHistory().length, 0);
  });
});
