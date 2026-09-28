import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import type { AppPool } from './pool.js';
import type { Repository } from '../repositories/repository.js';
import {
  applyMigration,
  lockMigrations,
  migrationHistory,
  prepareMigrationHistory,
  type MigrationHistory,
} from '../repositories/migrations.js';

export interface MigrationFile extends MigrationHistory {
  sql: string;
}

export async function readMigrations(
  directory: string,
): Promise<MigrationFile[]> {
  const names = (await readdir(directory))
    .filter((name) => name.endsWith('.sql'))
    .sort();
  return Promise.all(
    names.map(async (name) => {
      const sql = await readFile(path.join(directory, name), 'utf8');
      return {
        name,
        sql,
        checksum: createHash('sha256').update(sql).digest('hex'),
      };
    }),
  );
}

function pendingMigrations(
  files: MigrationFile[],
  applied: MigrationHistory[],
): MigrationFile[] {
  for (const known of applied) {
    const file = files.find((row) => row.name === known.name);
    if (file === undefined || file.checksum !== known.checksum) {
      throw new Error(`Migration checksum changed: ${known.name}`);
    }
  }
  const knownNames = new Set(applied.map((row) => row.name));
  const pending = [...files]
    .sort((a, b) => a.name.localeCompare(b.name))
    .filter((file) => !knownNames.has(file.name));
  const last = applied
    .map((row) => row.name)
    .sort()
    .at(-1);
  for (const file of pending) {
    if (last !== undefined && file.name < last)
      throw new Error(`Out-of-order migration: ${file.name}`);
  }
  return pending;
}

/// Explicit operator action. SQL and schema history share one connection;
/// the advisory lock serialises concurrent migration commands.
export async function migrate(
  store: Repository,
  files: MigrationFile[],
  pool?: AppPool,
): Promise<string[]> {
  if (pool !== undefined) {
    return pool.transaction(async (connection) => {
      await lockMigrations(connection);
      await prepareMigrationHistory(connection);
      const pending = pendingMigrations(
        files,
        await migrationHistory(connection),
      );
      for (const file of pending) await applyMigration(connection, file);
      return pending.map((file) => file.name);
    });
  }
  return store.withTransaction(async (tx) => {
    const pending = pendingMigrations(files, await tx.schemaHistory());
    for (const file of pending)
      await tx.recordMigration(file.name, file.checksum);
    return pending.map((file) => file.name);
  });
}
