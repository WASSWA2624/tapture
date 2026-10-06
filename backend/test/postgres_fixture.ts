import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import type { AppConfig } from '../src/config/schema.js';
import { migrate, readMigrations } from '../src/db/migrate.js';
import { createPool, type AppPool } from '../src/db/pool.js';
import { createPostgresRepository } from '../src/repositories/postgres.js';
import type { Repository } from '../src/repositories/repository.js';
import { testConfig } from './helpers.js';

const databaseUrl = process.env['DATABASE_URL'];

/// These cases never replace PostgreSQL with the repository fake.
export const postgresConfigured = /^postgres(?:ql)?:\/\//.test(
  databaseUrl ?? '',
);

export interface PostgresFixture {
  readonly config: AppConfig;
  readonly databaseUrl: string;
  readonly pool: AppPool;
  readonly store: Repository;
}

/// Creates a unique empty schema, applies every migration and releases it even
/// after a failed assertion. A child CLI receives the same scoped database URL.
export async function withPostgres<T>(
  work: (fixture: PostgresFixture) => Promise<T>,
): Promise<T> {
  assert.ok(
    postgresConfigured && databaseUrl,
    'PostgreSQL DATABASE_URL required',
  );
  const schema = `tapture_case_${randomUUID().replaceAll('-', '')}`;
  const admin = createPool(testConfig({ DATABASE_URL: databaseUrl }));
  let pool: AppPool | undefined;
  try {
    await admin.query(`CREATE SCHEMA ${schema}`);
    const scopedUrl = new URL(databaseUrl);
    scopedUrl.searchParams.set('options', `-c search_path=${schema}`);
    const config = testConfig({ DATABASE_URL: scopedUrl.toString() });
    pool = createPool(config);
    const store = createPostgresRepository(pool);
    await migrate(
      store,
      await readMigrations(
        fileURLToPath(new URL('../migrations', import.meta.url)),
      ),
      pool,
    );
    return await work({
      config,
      databaseUrl: scopedUrl.toString(),
      pool,
      store,
    });
  } finally {
    try {
      await pool?.drain();
    } finally {
      try {
        await admin.query(`DROP SCHEMA IF EXISTS ${schema} CASCADE`);
      } finally {
        await admin.drain();
      }
    }
  }
}
