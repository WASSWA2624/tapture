import assert from 'node:assert/strict';
import { it } from 'node:test';
import { setImmediate } from 'node:timers/promises';
import { createPool } from '../../src/db/pool.js';
import { runPurge } from '../../src/jobs/purge.js';
import { postgresConfigured, withPostgres } from '../postgres_fixture.js';

function signal(): { wait: Promise<void>; release: () => void } {
  let release: (() => void) | undefined;
  const wait = new Promise<void>((resolve) => {
    release = resolve;
  });
  assert.ok(release);
  return { wait, release };
}

it(
  'PostgreSQL drain waits for an in-flight two-table transaction to commit',
  { skip: !postgresConfigured, timeout: 30_000 },
  async () =>
    withPostgres(async ({ config, store }) => {
      await store.addOrg({
        id: 'org',
        name: 'Drain fixture',
        selfRegister: false,
        retentionDays: 30,
      });
      const pool = createPool(config);
      const reached = signal();
      const resume = signal();
      let drained: Promise<void> | undefined;
      let completed = false;
      const transaction = pool.transaction(async (connection) => {
        await connection.query(
          'INSERT INTO users(id,organisation_id,email,password_hash,role,status) VALUES($1,$2,$3,$4,$5,$6)',
          [
            'held-user',
            'org',
            'held@example.test',
            'irreversible-hash',
            'reviewer',
            'active',
          ],
        );
        reached.release();
        await resume.wait;
        await connection.query(
          'INSERT INTO audit_events(id,at,actor_id,action,target) VALUES($1,now(),$2,$3,$4)',
          ['held-audit', 'held-user', 'created', 'held-user'],
        );
        return 'committed';
      });
      try {
        await Promise.race([
          reached.wait,
          transaction.then(() => {
            throw new Error(
              'Transaction passed the test gate without pausing.',
            );
          }),
        ]);
        drained = pool.drain().then(() => {
          completed = true;
        });
        await setImmediate();
        assert.equal(pool.status().draining, true);
        assert.equal(completed, false);
        assert.equal(await pool.probe(), false);
        assert.equal(await store.userById('held-user'), undefined);
        resume.release();
        assert.equal(await transaction, 'committed');
        await drained;
        assert.equal(completed, true);
        assert.equal((await store.userById('held-user'))?.id, 'held-user');
        assert.equal(
          (await store.audit()).find((row) => row.id === 'held-audit')?.target,
          'held-user',
        );
      } finally {
        resume.release();
        await transaction.catch(() => undefined);
        if (drained !== undefined) await drained;
        else await pool.drain();
      }
    }),
);

it(
  'PostgreSQL expiry removes partially acknowledged and unfetched ciphertext at the injected boundary while keeping future packages and vectors',
  { skip: !postgresConfigured },
  async () =>
    withPostgres(async ({ store }) => {
      const createdAt = '2026-10-01T00:00:00.000Z';
      const expiresAt = '2026-10-02T00:00:00.000Z';
      const bytes = Buffer.from('opaque fixture');
      await store.addOrg({
        id: 'org',
        name: 'Expiry fixture',
        selfRegister: false,
        retentionDays: 30,
      });
      await store.addUser({
        id: 'user',
        organisationId: 'org',
        email: 'expiry@example.test',
        passwordHash: 'irreversible-hash',
        role: 'administrator',
        status: 'active',
      });
      await store.addDevice({
        id: 'device',
        userId: 'user',
        enrolledAt: createdAt,
        lastSeenAt: createdAt,
        revoked: false,
      });
      await store.addDevice({
        id: 'waiting-device',
        userId: 'user',
        enrolledAt: createdAt,
        lastSeenAt: createdAt,
        revoked: false,
      });
      await store.addProject({
        id: 'project',
        organisationId: 'org',
        name: 'Registration only',
        relayEnabled: true,
        neverRelay: false,
        retentionDays: 30,
      });
      await store.addMember({
        projectId: 'project',
        userId: 'user',
        contextScope: null,
      });
      for (const id of ['acknowledged', 'unfetched', 'future']) {
        await store.addPackage(
          {
            id,
            projectId: 'project',
            authorDeviceId: 'device',
            byteSize: bytes.length,
            createdAt,
            expiresAt: id === 'future' ? '2026-10-03T00:00:00.000Z' : expiresAt,
            storageRef: `blob:${id}`,
          },
          bytes,
        );
      }
      await store.addAck({ packageId: 'acknowledged', deviceId: 'device' });
      await store.addAck({ packageId: 'future', deviceId: 'device' });
      await store.bumpVector('project', 'device');
      const vectors = await store.vectors('project');
      const before = new Date(Date.parse(expiresAt) - 1);
      assert.deepEqual(await store.expiredPackages(before, 1), []);
      assert.equal((await runPurge(store, before, undefined, 1)).deleted, 0);
      assert.equal((await store.packages()).length, 3);
      assert.equal((await store.acks()).length, 2);
      const boundary = new Date(expiresAt);
      assert.deepEqual(
        (await store.expiredPackages(boundary, 1)).map((row) => row.id),
        ['acknowledged'],
      );
      const report = await runPurge(store, boundary, undefined, 1);
      assert.equal(report.deleted, 2);
      assert.equal(report.bytesReclaimed, 2 * bytes.length);
      assert.equal(report.oldestAgeSeconds, 24 * 60 * 60);
      assert.equal(report.failures, 0);
      assert.equal(await store.blob('blob:acknowledged'), undefined);
      assert.equal(await store.blob('blob:unfetched'), undefined);
      assert.deepEqual(await store.blob('blob:future'), bytes);
      assert.deepEqual(
        (await store.packages()).map((row) => row.id),
        ['future'],
      );
      assert.deepEqual(await store.acks(), [
        { packageId: 'future', deviceId: 'device' },
      ]);
      assert.deepEqual(await store.vectors('project'), vectors);
      assert.equal((await runPurge(store, boundary, undefined, 1)).deleted, 0);
    }),
);
