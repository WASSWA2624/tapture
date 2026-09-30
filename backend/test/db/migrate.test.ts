import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { migrate, readMigrations } from '../../src/db/migrate.js';
import { createPool } from '../../src/db/pool.js';
import { Store } from '../../src/repositories/store.js';
import { createPostgresRepository } from '../../src/repositories/postgres.js';
import { randomUUID } from 'node:crypto';
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
        '006_account_token_purpose.sql',
        '007_refresh_family_scope.sql',
        '008_runtime_settings.sql',
        '009_transient_retention.sql',
      ],
    );
    const store = new Store();
    const ran = await migrate(store, files);
    assert.equal(ran.length, 9);
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

  it(
    'upgrades a postgres database without dropping seeded rows',
    {
      skip: !process.env['DATABASE_URL']?.startsWith('postgres'),
    },
    async () => {
      const url = process.env['DATABASE_URL'] ?? '';
      const schema = `tapture_upgrade_${randomUUID().replaceAll('-', '')}`;
      const admin = createPool(testConfig({ DATABASE_URL: url }));
      await admin.query(`CREATE SCHEMA ${schema}`);
      const scopedUrl = new URL(url);
      scopedUrl.searchParams.set('options', `-c search_path=${schema}`);
      const pool = createPool(
        testConfig({ DATABASE_URL: scopedUrl.toString() }),
      );
      try {
        const files = await readMigrations(directory);
        const store = createPostgresRepository(pool);
        // The released baseline predates purpose, family and retention fields.
        await migrate(store, files.slice(0, 5), pool);
        await pool.query(
          `INSERT INTO organisations (id, name, self_register, retention_days)
         VALUES ('org-keep', 'Keep', false, 30)`,
        );
        await pool.query(
          "INSERT INTO users(id,organisation_id,email,password_hash,role,status) VALUES('user-keep','org-keep','keep@example.test','irreversible-hash','administrator','active')",
        );
        await pool.query(
          "INSERT INTO devices(id,user_id,enrolled_at,last_seen_at) VALUES('device-keep','user-keep',now(),now())",
        );
        await pool.query(
          "INSERT INTO projects(id,organisation_id,name,retention_days) VALUES('project-keep','org-keep','Registration',30)",
        );
        await pool.query(
          "INSERT INTO project_members(project_id,user_id,context_scope) VALUES('project-keep','user-keep','scope-keep')",
        );
        await pool.query(
          "INSERT INTO refresh_families(id,user_id,device_id,token_hash,expires_at) VALUES('refresh-keep','user-keep','device-keep','refresh-hash',now()+interval '1 day')",
        );
        await pool.query(
          "INSERT INTO invitations(token_hash,user_id,expires_at) VALUES('invite-hash','user-keep',now()+interval '1 day')",
        );
        await pool.query(
          "INSERT INTO relay_packages(id,project_id,author_device_id,byte_size,created_at,expires_at,storage_ref) VALUES('package-keep','project-keep','device-keep',4,now(),now()+interval '1 day','blob:keep')",
        );
        await pool.query(
          "INSERT INTO relay_blobs(package_id,storage_ref,ciphertext) VALUES('package-keep','blob:keep',$1)",
          [Buffer.from([0, 255, 17, 3])],
        );
        await pool.query(
          "INSERT INTO relay_acknowledgements(package_id,device_id) VALUES('package-keep','device-keep')",
        );
        await pool.query(
          "INSERT INTO relay_vectors(project_id,device_id,counter) VALUES('project-keep','device-keep',7)",
        );
        await pool.query(
          "INSERT INTO idempotency_keys(key,status,body,expires_at) VALUES('replay-keep',201,'{}',now()+interval '1 day')",
        );
        await pool.query(
          "INSERT INTO login_lockouts(key,failures,locked_until) VALUES('lock-keep',2,now()+interval '1 hour')",
        );
        await pool.query(
          "INSERT INTO ai_usage(id,project_id,user_id,model,byte_size,duration_ms,outcome,cost,at) VALUES('usage-keep','project-keep','user-keep','model',4,1,'ok',0.01,now())",
        );
        for (const table of ['audit_events', 'security_events'])
          await pool.query(
            `INSERT INTO ${table}(id,at,actor_id,action,target) VALUES('event-keep',now(),'user-keep','preserved','project-keep')`,
          );
        await migrate(store, files, pool);
        const rows = await pool.query<{ id: string }>(
          `SELECT id FROM organisations WHERE id = 'org-keep'`,
        );
        assert.equal(rows[0]?.id, 'org-keep');
        assert.equal((await store.schemaHistory()).length, files.length);
        for (const table of [
          'organisations',
          'users',
          'devices',
          'projects',
          'project_members',
          'refresh_families',
          'invitations',
          'relay_packages',
          'relay_blobs',
          'relay_acknowledgements',
          'relay_vectors',
          'idempotency_keys',
          'login_lockouts',
          'ai_usage',
          'audit_events',
          'security_events',
        ]) {
          const count = await pool.query<{ count: string }>(
            `SELECT count(*) AS count FROM ${table}`,
          );
          assert.equal(count[0]?.count, '1', table);
        }
        assert.equal((await store.invites())[0]?.purpose, 'invitation');
        assert.equal(
          (await store.refresh())[0]?.familyId,
          'legacy:user-keep:device-keep',
        );
        assert.deepEqual(
          await store.blob('blob:keep'),
          Buffer.from([0, 255, 17, 3]),
        );
        const ack = await pool.query<{ matches: boolean }>(
          'SELECT a.expires_at=p.expires_at AS matches FROM relay_acknowledgements a JOIN relay_packages p ON p.id=a.package_id',
        );
        assert.equal(ack[0]?.matches, true);
      } finally {
        await pool.drain();
        await admin.query(`DROP SCHEMA ${schema} CASCADE`);
        await admin.drain();
      }
    },
  );
});
