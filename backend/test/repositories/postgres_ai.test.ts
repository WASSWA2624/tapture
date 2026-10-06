import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { it } from 'node:test';
import { AppError } from '../../src/domain/errors.js';
import { createPostgresRepository } from '../../src/repositories/postgres.js';
import {
  credentialStatus,
  deleteCredential,
  saveCredential,
} from '../../src/services/ai/credentials.js';
import { proxyAi } from '../../src/services/ai/proxy.js';
import { fakeProvider } from '../../src/services/ai/provider.js';
import { postgresConfigured, withPostgres } from '../postgres_fixture.js';

it(
  'persists private credentials and replay tombstones across repository recreation without rebilling',
  { skip: !postgresConfigured },
  async () =>
    withPostgres(async ({ store, config: base, pool }) => {
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
        name: 'Private',
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
        name: 'Local-only',
        relayEnabled: false,
        neverRelay: true,
        retentionDays: 30,
      });
      await store.addMember({
        projectId: 'project',
        userId: 'user',
        contextScope: null,
      });
      await saveCredential(
        store,
        config,
        principal,
        'gemini',
        'private-provider-value',
      );
      const payload = Buffer.from('private-source');
      const input = {
        projectId: 'project',
        model: 'default',
        payload,
        processing: {
          version: 1 as const,
          projectRevision: 'revision',
          recordId: 'record',
          requestHash: createHash('sha256').update(payload).digest('hex'),
          idempotencyKey: 'a'.repeat(64),
        },
      };
      await proxyAi(
        store,
        config,
        fakeProvider('ok'),
        principal,
        'extract',
        input,
      );
      const reopened = createPostgresRepository(pool);
      assert.equal(
        (await credentialStatus(reopened, principal, 'gemini')).configured,
        true,
      );
      await assert.rejects(
        () =>
          proxyAi(
            reopened,
            config,
            fakeProvider('ok'),
            principal,
            'extract',
            input,
          ),
        (error: unknown) =>
          error instanceof AppError && error.code === 'ai_result_unavailable',
      );
      assert.equal((await reopened.usage()).length, 1);
      assert.equal(
        (await reopened.aiReceipt('a'.repeat(64)))?.status,
        'completed',
      );
      let calls = 0;
      const answer = async () => {
        calls += 1;
        return { text: 'draft', model: config.aiGeminiModel };
      };
      const provider = {
        extract: answer,
        ocr: answer,
        transcribe: answer,
        refine: answer,
      };
      const simultaneous = {
        ...input,
        processing: { ...input.processing, idempotencyKey: 'b'.repeat(64) },
      };
      const outcomes = await Promise.allSettled([
        proxyAi(store, config, provider, principal, 'extract', simultaneous),
        proxyAi(reopened, config, provider, principal, 'extract', simultaneous),
      ]);
      assert.equal(calls, 1);
      assert.equal(
        outcomes.filter((result) => result.status === 'fulfilled').length,
        1,
      );
      assert.equal((await reopened.usage()).length, 2);
      const current = await reopened.aiReceipt('b'.repeat(64));
      assert.ok(current);
      await assert.rejects(
        async () =>
          reopened.saveAiReceipt({
            ...current,
            bindingHash: 'c'.repeat(64),
            status: 'completed',
          }),
        (error: unknown) =>
          error instanceof AppError && error.code === 'conflict',
      );
      assert.equal(
        (await reopened.aiReceipt('b'.repeat(64)))?.bindingHash,
        current.bindingHash,
      );
      const exported = JSON.stringify(await reopened.exportMetadata());
      assert.equal(exported.includes('private-provider-value'), false);
      assert.equal(exported.includes('encrypted_key'), false);
      assert.equal(exported.includes('private-source'), false);
      await deleteCredential(reopened, principal, 'gemini');
      assert.equal(await store.aiCredential('user', 'gemini'), undefined);
    }),
);
