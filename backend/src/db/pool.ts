import pg from 'pg';
import type { AppConfig } from '../config/schema.js';

export interface PoolStatus {
  connected: boolean;
  draining: boolean;
}

export interface AppPool {
  status(): PoolStatus;
  query<T extends Record<string, unknown> = Record<string, unknown>>(
    text: string,
    values?: unknown[],
  ): Promise<T[]>;
  transaction<T>(work: (connection: SqlConnection) => Promise<T>): Promise<T>;
  probe(): Promise<boolean>;
  drain(): Promise<void>;
}

export type SqlConnection = Pick<AppPool, 'query'>;

/// Opens a pool only for a Postgres URL. `memory://` stays disconnected.
/// `open` builds the driver pool; tests inject a fake one.
export function createPool(
  config: AppConfig,
  open: (options: pg.PoolConfig) => pg.Pool = (options) => new pg.Pool(options),
): AppPool {
  if (!config.databaseUrl.startsWith('postgres')) {
    let draining = false;
    const memory: AppPool = {
      status: () => ({ connected: !draining, draining }),
      query: async <T extends Record<string, unknown>>() => [] as T[],
      transaction: async (work) => work(memory),
      probe: async () => !draining,
      drain: async () => {
        draining = true;
      },
    };
    return memory;
  }
  const pool = open({
    connectionString: config.databaseUrl,
    max: config.poolMax,
    connectionTimeoutMillis: config.databaseConnectTimeoutMs,
    statement_timeout: config.databaseStatementTimeoutMs,
  });
  let draining = false;
  let connected = false;
  pool.on('error', () => {
    connected = false;
  });
  return {
    status: () => ({ connected, draining }),
    query: async <T extends Record<string, unknown>>(
      text: string,
      values?: unknown[],
    ) => {
      try {
        const result = await pool.query<T>(text, values);
        connected = true;
        return result.rows;
      } catch (error) {
        connected = false;
        throw error;
      }
    },
    probe: async () => {
      if (draining) return false;
      try {
        await pool.query('SELECT 1');
        connected = true;
      } catch {
        connected = false;
      }
      return connected;
    },
    transaction: async (work) => {
      const client = await pool.connect();
      // The pool only listens to idle clients. A checked-out client that loses
      // its connection emits 'error'; without a listener the process exits.
      let broken: Error | undefined;
      const onError = (error: Error): void => {
        broken = error;
        connected = false;
      };
      client.on('error', onError);
      try {
        await client.query('BEGIN');
        const result = await work({
          query: async <T extends Record<string, unknown>>(
            text: string,
            values?: unknown[],
          ) => (await client.query<T>(text, values)).rows,
        });
        await client.query('COMMIT');
        return result;
      } catch (error) {
        try {
          await client.query('ROLLBACK');
        } catch (rollbackError) {
          // Keep the original failure; a failed rollback means a dead link.
          broken ??=
            rollbackError instanceof Error
              ? rollbackError
              : new Error('Rollback failed.');
        }
        throw error;
      } finally {
        client.removeListener('error', onError);
        // Releasing with an error makes the pool destroy the broken client.
        client.release(broken);
      }
    },
    drain: async () => {
      draining = true;
      await pool.end();
    },
  };
}
