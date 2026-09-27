import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import type { AppPool } from './pool.js';
import type { Store } from '../repositories/store.js';

export interface MigrationFile {
  name: string;
  sql: string;
  checksum: string;
}

export async function readMigrations(
  directory: string,
): Promise<MigrationFile[]> {
  const names = (await readdir(directory))
    .filter((name) => name.endsWith('.sql'))
    .sort();
  const files: MigrationFile[] = [];
  for (const name of names) {
    const sql = await readFile(path.join(directory, name), 'utf8');
    files.push({
      name,
      sql,
      checksum: createHash('sha256').update(sql).digest('hex'),
    });
  }
  return files;
}

/// Applies each file in filename order inside the store history.
/// A changed checksum or a file inserted before an applied one throws.
export async function migrate(
  store: Store,
  files: MigrationFile[],
  pool?: AppPool,
): Promise<string[]> {
  if (pool !== undefined) {
    await pool.query(
      `CREATE TABLE IF NOT EXISTS schema_migrations (
        name text PRIMARY KEY,
        checksum text NOT NULL,
        applied_at timestamptz NOT NULL DEFAULT now()
      )`,
    );
    const rows = await pool.query<{ name: string; checksum: string }>(
      'SELECT name, checksum FROM schema_migrations ORDER BY name',
    );
    for (const row of rows) {
      if (!store.schemaHistory().some((known) => known.name === row.name)) {
        store.recordMigration(row.name, row.checksum);
      }
    }
  }
  const applied = store.schemaHistory();
  const appliedNames = new Set(applied.map((row) => row.name));
  for (const known of applied) {
    const file = files.find((row) => row.name === known.name);
    if (file === undefined || file.checksum !== known.checksum) {
      throw new Error(`Migration checksum changed: ${known.name}`);
    }
  }
  const pending = files.filter((file) => !appliedNames.has(file.name));
  const newestApplied = applied.at(-1)?.name;
  for (const file of pending) {
    if (newestApplied !== undefined && file.name < newestApplied) {
      throw new Error(`Out-of-order migration: ${file.name}`);
    }
  }
  const ran: string[] = [];
  for (const file of pending) {
    await store.withTransaction(async (tx) => {
      if (pool !== undefined) {
        await pool.query(file.sql);
        await pool.query(
          'INSERT INTO schema_migrations (name, checksum) VALUES ($1, $2)',
          [file.name, file.checksum],
        );
      }
      tx.recordMigration(file.name, file.checksum);
    });
    ran.push(file.name);
  }
  return ran;
}
