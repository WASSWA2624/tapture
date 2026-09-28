import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { migrate, readMigrations } from '../../src/db/migrate.js';
import { createPool } from '../../src/db/pool.js';
import { Store } from '../../src/repositories/store.js';
import { testConfig } from '../helpers.js';

const directory = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  '../../migrations',
);

describe('migrations', () => {
  it('applies files in order and refuses a changed checksum', async () => {
    const files = await readMigrations(directory);
    assert.deepEqual(
      files.map((file) => file.name),
      [
        '001_identity.sql',
        '002_projects.sql',
        '003_relay.sql',
        '004_audit.sql',
        '005_runtime_persistence.sql',
      ],
    );
    const store = new Store();
    const ran = await migrate(store, files);
    assert.equal(ran.length, 5);
    const again = await migrate(store, files);
    assert.equal(again.length, 0);
    const changed = files.map((file, index) =>
      index === 0 ? { ...file, checksum: 'different' } : file,
    );
    await assert.rejects(() => migrate(store, changed), /checksum/);
  });

  it('refuses a file inserted before an applied migration', async () => {
    const files = await readMigrations(directory);
    const last = files[3];
    if (last === undefined) throw new Error('missing migration');
    const store = new Store();
    await migrate(store, [last]);
    await assert.rejects(() => migrate(store, files), /Out-of-order/);
  });

  it('upgrades a postgres database without dropping seeded rows', async () => {
    const url = process.env['DATABASE_URL'] ?? '';
    if (!url.startsWith('postgres')) return;
    const pool = createPool(testConfig({ DATABASE_URL: url }));
    const files = await readMigrations(directory);
    const store = new Store();
    await migrate(store, files.slice(0, 3), pool);
    await pool.query(
      `INSERT INTO organisations (id, name, self_register, retention_days)
       VALUES ('org-keep', 'Keep', false, 30)`,
    );
    await migrate(store, files, pool);
    const rows = await pool.query<{ id: string }>(
      `SELECT id FROM organisations WHERE id = 'org-keep'`,
    );
    assert.equal(rows[0]?.id, 'org-keep');
    await pool.drain();
  });
});
