import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { it } from 'node:test';
import { migrate, readMigrations } from '../../src/db/migrate.js';
import { saveCredential } from '../../src/services/ai/credentials.js';
import { postgresConfigured, withPostgres } from '../postgres_fixture.js';

it(
  '011 to 012 preserves exact credentials, ciphertext, usage and receipt values; failed upgrade rolls back',
  { skip: !postgresConfigured },
  async () =>
    withPostgres(
      async ({ store, pool, config: base }) => {
        const config = { ...base, aiCredentialEncryptionKey: 'ab'.repeat(32) };
        const principal = {
          userId: 'user',
          deviceId: 'device',
          organisationId: 'org',
          role: 'field_operator' as const,
          contextScope: null,
        };
        await store.addOrg({
          id: 'org',
          name: 'Fixture',
          selfRegister: false,
          retentionDays: 30,
        });
        await store.addUser({
          id: 'user',
          organisationId: 'org',
          email: 'user@example.test',
          passwordHash: 'irreversible-fixture',
          role: 'field_operator',
          status: 'active',
        });
        await store.addDevice({
          id: 'device',
          userId: 'user',
          enrolledAt: new Date().toISOString(),
          lastSeenAt: new Date().toISOString(),
          revoked: false,
        });
        await store.addProject({
          id: 'project',
          organisationId: 'org',
          name: 'Local project',
          relayEnabled: false,
          neverRelay: true,
          retentionDays: 30,
        });
        for (const provider of ['gemini', 'openai'])
          await saveCredential(
            store,
            config,
            principal,
            provider,
            `private-${provider}-fixture`,
          );
        for (const [index, status] of (
          ['running', 'completed', 'uncertain'] as const
        ).entries()) {
          const usageId = await store.addUsage({
            projectId: 'project',
            userId: 'user',
            model: 'fake',
            provider: 'gemini',
            billingKind: 'managed',
            byteSize: 7,
            durationMs: 0,
            outcome: 'reserved',
            cost: 0.01,
            at: new Date().toISOString(),
          });
          await store.saveAiReceipt({
            idempotencyKey: String(index).repeat(64),
            bindingHash: 'a'.repeat(64),
            userId: 'user',
            deviceId: 'device',
            projectId: 'project',
            usageId,
            status,
            createdAt: new Date().toISOString(),
          });
        }
        const snapshot = async () => ({
          credentials: await pool.query(
            'SELECT * FROM ai_credentials ORDER BY provider',
          ),
          usage: await pool.query('SELECT * FROM ai_usage ORDER BY id'),
          receipts: await pool.query(
            'SELECT * FROM ai_receipts ORDER BY idempotency_key',
          ),
        });
        const before = await snapshot();
        const files = await readMigrations(
          fileURLToPath(new URL('../../migrations', import.meta.url)),
        );
        const next = files.find(
          (file) => file.name === '012_ai_provider_catalogue.sql',
        );
        assert.ok(next);
        const badSql = next.sql.replace(
          'COMMIT;',
          'SELECT * FROM deliberately_missing_w16_table; COMMIT;',
        );
        const broken = files.map((file) =>
          file === next
            ? {
                ...file,
                sql: badSql,
                checksum: createHash('sha256').update(badSql).digest('hex'),
              }
            : file,
        );
        await assert.rejects(() => migrate(store, broken, pool));
        assert.deepEqual(await snapshot(), before);
        assert.equal((await store.schemaHistory()).length, 11);
        const legacy = await store.aiCredential('user', 'gemini');
        assert.ok(legacy);
        await assert.rejects(async () =>
          store.saveAiCredential({ ...legacy, provider: 'field-ai' }),
        );
        assert.deepEqual(await migrate(store, files, pool), [
          '012_ai_provider_catalogue.sql',
        ]);
        assert.deepEqual(await snapshot(), before);
        await store.saveAiCredential({ ...legacy, provider: 'field-ai' });
        assert.deepEqual(await store.aiCredential('user', 'field-ai'), {
          ...legacy,
          provider: 'field-ai',
        });
        await assert.rejects(async () =>
          store.saveAiCredential({ ...legacy, provider: 'Bad/Provider' }),
        );
      },
      { through: '011_ai_processing.sql' },
    ),
);
