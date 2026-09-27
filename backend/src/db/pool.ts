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
  drain(): Promise<void>;
}

/// Opens a pool only for a Postgres URL. `memory://` stays disconnected.
export function createPool(config: AppConfig): AppPool {
  if (!config.databaseUrl.startsWith('postgres')) {
    let draining = false;
    return {
      status: () => ({ connected: !draining, draining }),
      query: async <T extends Record<string, unknown>>() => [] as T[],
      drain: async () => {
        draining = true;
      },
    };
  }
  const pool = new pg.Pool({
    connectionString: config.databaseUrl,
    max: config.poolMax,
  });
  let draining = false;
  return {
    status: () => ({ connected: !draining, draining }),
    query: async <T extends Record<string, unknown>>(
      text: string,
      values?: unknown[],
    ) => {
      const result = await pool.query(text, values);
      return result.rows as T[];
    },
    drain: async () => {
      draining = true;
      await pool.end();
    },
  };
}
