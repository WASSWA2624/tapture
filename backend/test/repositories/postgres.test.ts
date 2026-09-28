import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { it } from 'node:test';
import request from 'supertest';
import { createPool } from '../../src/db/pool.js';
import { migrate, readMigrations } from '../../src/db/migrate.js';
import { createPostgresRepository } from '../../src/repositories/postgres.js';
import { bootstrapOrganisation } from '../../src/services/auth/bootstrap.js';
import { createApp } from '../../src/server.js';
import { emptyMetrics } from '../../src/services/metrics/metrics.js';
import { fakeProvider } from '../../src/services/ai/provider.js';
import { createLogger } from '../../src/observability/logger.js';
import { readAccess, rotate } from '../../src/services/auth/tokens.js';
import { acknowledge, uploadPackage } from '../../src/services/relay/relay.js';
import { testConfig } from '../helpers.js';

const databaseUrl = process.env['DATABASE_URL'];

it(
  'PostgreSQL survives reconnect, rolls back partial writes, serialises replay and removes ciphertext on ack',
  { skip: !databaseUrl?.startsWith('postgres') },
  async () => {
    assert.ok(databaseUrl);
    const schema = `tapture_test_${randomUUID().replaceAll('-', '')}`;
    const admin = createPool(testConfig({ DATABASE_URL: databaseUrl }));
    await admin.query(`CREATE SCHEMA ${schema}`);
    const url = new URL(databaseUrl);
    url.searchParams.set('options', `-c search_path=${schema}`);
    const config = testConfig({ DATABASE_URL: url.toString() });
    let pool = createPool(config);
    try {
      let store = createPostgresRepository(pool);
      const files = await readMigrations(
        fileURLToPath(new URL('../../migrations', import.meta.url)),
      );
      await migrate(store, files, pool);
      assert.deepEqual(await migrate(store, files, pool), []);
      const identity = await bootstrapOrganisation(store, config, {
        name: 'Integration',
        email: 'admin@example.test',
        password: 'integration-test-password',
      });
      const deps = () => ({
        store,
        pool,
        config,
        metrics: emptyMetrics(),
        provider: fakeProvider('ok'),
        log: createLogger(() => undefined),
      });
      let app = createApp(deps());
      assert.equal((await request(app).get('/ready')).status, 200);
      const signedIn = await request(app).post('/api/v1/auth/login').send({
        email: 'admin@example.test',
        password: 'integration-test-password',
        deviceId: 'device-test',
        organisationId: identity.organisationId,
      });
      assert.equal(signedIn.status, 200, JSON.stringify(signedIn.body));
      const tokens = signedIn.body as {
        accessToken: string;
        refreshToken: string;
      };
      const auth = `Bearer ${tokens.accessToken}`;
      assert.equal(
        (
          await request(app)
            .post('/api/v1/projects')
            .set('authorization', auth)
            .send({ id: 'project-test', name: 'Local evidence' })
        ).status,
        201,
      );
      assert.equal(
        (
          await request(app)
            .patch('/api/v1/projects/project-test')
            .set('authorization', auth)
            .send({ relayEnabled: true })
        ).status,
        200,
      );
      await assert.rejects(() =>
        store.withTransaction(async (tx) => {
          await tx.addProject({
            id: 'rolled-back',
            organisationId: identity.organisationId,
            name: 'Partial',
            relayEnabled: false,
            neverRelay: false,
            retentionDays: 30,
          });
          await tx.recordAudit({
            actorId: identity.userId,
            action: 'rolled-back',
            target: 'rolled-back',
            before: null,
            after: null,
          });
          throw new Error('second write failed');
        }),
      );
      assert.equal(
        (await store.projects()).some((row) => row.id === 'rolled-back'),
        false,
      );
      assert.equal(
        (await store.audit()).some((row) => row.action === 'rolled-back'),
        false,
      );
      const principal = readAccess(tokens.accessToken, config);
      const bytes = Buffer.from([0, 255, 17, 99, 0, 123]);
      const [first, replay] = await Promise.all([
        uploadPackage(
          store,
          config,
          principal,
          'project-test',
          bytes,
          'one-key',
        ),
        uploadPackage(
          store,
          config,
          principal,
          'project-test',
          bytes,
          'one-key',
        ),
      ]);
      assert.equal(first.id, replay.id);
      assert.equal((await store.packages()).length, 1);
      await pool.drain();
      pool = createPool(config);
      store = createPostgresRepository(pool);
      app = createApp(deps());
      assert.equal(
        (await request(app).get('/api/v1/auth/me').set('authorization', auth))
          .status,
        200,
      );
      assert.deepEqual(await store.blob(first.storageRef), bytes);
      await acknowledge(store, principal, [first.id], 'ack-key');
      assert.equal((await store.packages()).length, 0);
      assert.equal(await store.blob(first.storageRef), undefined);
      assert.equal((await store.acks()).length, 0);
      const rotations = await Promise.allSettled([
        rotate(store, tokens.refreshToken, config),
        rotate(store, tokens.refreshToken, config),
      ]);
      assert.equal(
        rotations.filter((row) => row.status === 'fulfilled').length,
        1,
      );
      assert.ok((await store.refresh()).every((row) => row.revoked));
      assert.ok(
        (await store.security()).some((row) => row.action === 'refresh_reuse'),
      );
      const changed = files.map((file, index) =>
        index === 0 ? { ...file, checksum: 'different' } : file,
      );
      await assert.rejects(() => migrate(store, changed, pool), /checksum/);
      await pool.drain();
      assert.equal((await request(app).get('/ready')).status, 500);
    } finally {
      if (!pool.status().draining) await pool.drain();
      await admin.query(`DROP SCHEMA ${schema} CASCADE`);
      await admin.drain();
    }
  },
);
