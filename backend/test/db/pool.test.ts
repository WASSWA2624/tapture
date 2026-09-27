import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { createPool } from '../../src/db/pool.js';
import { testConfig } from '../helpers.js';

describe('pool', () => {
  it('drains a memory pool', async () => {
    const pool = createPool(testConfig());
    assert.equal(pool.status().connected, true);
    await pool.drain();
    assert.equal(pool.status().draining, true);
  });

  it('drains a postgres pool when DATABASE_URL is set', async () => {
    const url = process.env['DATABASE_URL'] ?? '';
    if (!url.startsWith('postgres')) return;
    const pool = createPool(testConfig({ DATABASE_URL: url }));
    await pool.query('SELECT 1 AS ok');
    await pool.drain();
    assert.equal(pool.status().draining, true);
  });
});
