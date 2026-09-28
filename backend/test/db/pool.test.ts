import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { describe, it } from 'node:test';
import type { Pool } from 'pg';
import { createPool, type AppPool } from '../../src/db/pool.js';
import { testConfig } from '../helpers.js';

/// Stands in for a checked-out pg client.
class FakeClient extends EventEmitter {
  readonly statements: string[] = [];
  readonly released: Array<Error | boolean | undefined> = [];
  failure: Error | undefined;

  async query(text: string): Promise<{ rows: unknown[] }> {
    this.statements.push(text);
    if (this.failure !== undefined) throw this.failure;
    return { rows: [] };
  }

  release(error?: Error | boolean): void {
    this.released.push(error);
  }
}

/// A Postgres-configured pool whose driver hands out [client].
function postgresPool(client: FakeClient): AppPool {
  const driver = Object.assign(new EventEmitter(), {
    connect: async () => client,
    query: async () => ({ rows: [] }),
    end: async () => undefined,
  });
  return createPool(
    testConfig({ DATABASE_URL: 'postgres://fake/tapture' }),
    () => driver as unknown as Pool,
  );
}

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

  it('commits and returns a healthy client without a lingering listener', async () => {
    const client = new FakeClient();
    const pool = postgresPool(client);
    const value = await pool.transaction(async (connection) => {
      await connection.query('SELECT 1');
      return 'done';
    });
    assert.equal(value, 'done');
    assert.deepEqual(client.statements, ['BEGIN', 'SELECT 1', 'COMMIT']);
    assert.deepEqual(client.released, [undefined]);
    assert.equal(client.listenerCount('error'), 0);
  });

  it('rolls back an ordinary failure and keeps the client', async () => {
    const client = new FakeClient();
    const pool = postgresPool(client);
    const conflict = new Error('duplicate key');
    await assert.rejects(
      pool.transaction(async () => {
        throw conflict;
      }),
      (error: unknown) => error === conflict,
    );
    assert.deepEqual(client.statements, ['BEGIN', 'ROLLBACK']);
    assert.deepEqual(client.released, [undefined]);
  });

  it('survives a connection lost mid-transaction and discards the client', async () => {
    const client = new FakeClient();
    const pool = postgresPool(client);
    await pool.query('SELECT 1');
    assert.equal(pool.status().connected, true);
    const lost = new Error(
      'terminating connection due to administrator command',
    );
    await assert.rejects(
      pool.transaction(async (connection) => {
        // pg emits 'error' on a checked-out client; with no listener the
        // emit throws and, outside a request, exits the process.
        client.emit('error', lost);
        client.failure = lost;
        await connection.query('SELECT 1');
      }),
      (error: unknown) => error === lost,
    );
    assert.deepEqual(client.statements, ['BEGIN', 'SELECT 1', 'ROLLBACK']);
    assert.equal(client.released[0], lost);
    assert.equal(client.listenerCount('error'), 0);
    assert.equal(pool.status().connected, false);
  });

  it('keeps the original failure when the rollback fails too', async () => {
    const client = new FakeClient();
    const pool = postgresPool(client);
    const original = new Error('statement timeout');
    const gone = new Error('Connection terminated unexpectedly');
    await assert.rejects(
      pool.transaction(async () => {
        client.failure = gone;
        throw original;
      }),
      (error: unknown) => error === original,
    );
    assert.deepEqual(client.statements, ['BEGIN', 'ROLLBACK']);
    assert.equal(client.released[0], gone);
  });
});
