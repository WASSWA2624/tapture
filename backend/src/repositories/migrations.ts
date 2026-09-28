import type { SqlConnection } from '../db/pool.js';

export interface MigrationHistory {
  name: string;
  checksum: string;
}

export async function prepareMigrationHistory(
  connection: SqlConnection,
): Promise<void> {
  await connection.query(`CREATE TABLE IF NOT EXISTS schema_migrations (
    name text PRIMARY KEY, checksum text NOT NULL,
    applied_at timestamptz NOT NULL DEFAULT now())`);
}

export async function migrationHistory(
  connection: SqlConnection,
): Promise<MigrationHistory[]> {
  return connection.query<MigrationHistory & Record<string, unknown>>(
    'SELECT name, checksum FROM schema_migrations ORDER BY name',
  );
}

export async function applyMigration(
  connection: SqlConnection,
  file: MigrationHistory & { sql: string },
): Promise<void> {
  // Released files include their own wrappers. The caller owns the dedicated
  // transaction so the SQL and its history row commit together.
  const sql = file.sql
    .replace(/^((?:\s|--[^\r\n]*(?:\r?\n|$))*)BEGIN\s*;/i, '$1')
    .replace(/COMMIT\s*;\s*$/i, '');
  await connection.query(sql);
  await connection.query(
    'INSERT INTO schema_migrations (name, checksum) VALUES ($1, $2)',
    [file.name, file.checksum],
  );
}

export async function lockMigrations(connection: SqlConnection): Promise<void> {
  await connection.query('SELECT pg_advisory_xact_lock($1)', [744279]);
}
