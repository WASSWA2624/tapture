import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { it } from 'node:test';
import { AppError } from '../../src/domain/errors.js';
import { createPostgresRepository } from '../../src/repositories/postgres.js';
import {
  decryptCredential,
  saveCredential,
} from '../../src/services/ai/credentials.js';
import { proxyAi } from '../../src/services/ai/proxy.js';
import { fakeProvider } from '../../src/services/ai/provider.js';
import { catalogueProvider } from '../fakes/provider_catalogue.js';
import { postgresConfigured, withPostgres } from '../postgres_fixture.js';

const failure = (code: string) => (error: unknown) =>
  error instanceof AppError && error.code === code;

it(
  'persists configured custody and keyless receipts without rerouting or rebilling after repository recreation',
  { skip: !postgresConfigured },
  async () =>
    withPostgres(async ({ store, pool, config: base }) => {
      const required = catalogueProvider({
        id: 'field-gemini',
        protocol: 'gemini-generate-content',
        authMode: 'required',
      });
      const config = {
        ...base,
        aiProviderCatalogue: [catalogueProvider(), required],
        aiCredentialEncryptionKey: 'ab'.repeat(32),
      };
      const principal = {
        userId: 'user',
        deviceId: 'device',
        organisationId: 'org',
        role: 'field_operator' as const,
        contextScope: null,
      };
      await store.addOrg({
        id: 'org',
        name: 'Local fixture',
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
      await store.addMember({
        projectId: 'project',
        userId: 'user',
        contextScope: null,
      });
      await saveCredential(
        store,
        config,
        principal,
        required.id,
        'private-catalogue-fixture',
      );
      const reopened = createPostgresRepository(pool);
      const credential = await reopened.aiCredential('user', required.id);
      assert.ok(credential);
      assert.equal(
        credential.encryptedKey.includes('private-catalogue-fixture'),
        false,
      );
      assert.equal(
        decryptCredential(config, credential),
        'private-catalogue-fixture',
      );
      assert.equal(await reopened.aiCredential('user', 'field-ai'), undefined);
      const payload = Buffer.from('private-original-evidence');
      const input = {
        projectId: 'project',
        model: 'default',
        payload,
        billing: { kind: 'managed' as const, provider: 'field-ai' },
        processing: {
          version: 1 as const,
          projectRevision: 'revision',
          recordId: 'record',
          requestHash: createHash('sha256').update(payload).digest('hex'),
          idempotencyKey: 'a'.repeat(64),
        },
      };
      let calls = 0;
      const factory = (provider: string, key: string) => {
        assert.equal(
          key,
          provider === required.id ? 'private-catalogue-fixture' : '',
        );
        const answer = async (request: { model: string }) => {
          calls += 1;
          return { text: 'private-proposed-evidence', model: request.model };
        };
        return {
          extract: answer,
          ocr: answer,
          refine: answer,
          transcribe: answer,
        };
      };
      const run = (nextConfig = config, attempt = input) =>
        proxyAi(
          reopened,
          nextConfig,
          fakeProvider('fail'),
          principal,
          'extract',
          attempt,
          undefined,
          factory,
        );
      assert.equal((await run()).provider, 'field-ai');
      await assert.rejects(() => run(), failure('ai_result_unavailable'));
      await assert.rejects(
        () =>
          run({
            ...config,
            aiProviderCatalogue: [
              catalogueProvider({ baseUrl: 'https://changed.test/v1' }),
              required,
            ],
          }),
        failure('conflict'),
      );
      await assert.rejects(
        () => run({ ...config, aiProviderCatalogue: [required] }),
        failure('invalid_request'),
      );
      await assert.rejects(
        () =>
          run(
            { ...config, aiProjectBudget: 0 },
            {
              ...input,
              processing: {
                ...input.processing,
                idempotencyKey: 'b'.repeat(64),
              },
            },
          ),
        failure('quota_exceeded'),
      );
      assert.equal(calls, 1);
      assert.equal((await reopened.usage()).length, 1);
      await proxyAi(
        reopened,
        config,
        fakeProvider('fail'),
        principal,
        'extract',
        {
          ...input,
          billing: { kind: 'personal', provider: required.id },
          processing: { ...input.processing, idempotencyKey: 'c'.repeat(64) },
        },
        undefined,
        factory,
      );
      await assert.rejects(
        () =>
          proxyAi(
            reopened,
            config,
            fakeProvider('fail'),
            principal,
            'extract',
            { ...input, signal: AbortSignal.abort() },
            undefined,
            factory,
          ),
        failure('ai_request_uncertain'),
      );
      const usage = await reopened.usage();
      assert.deepEqual(
        usage.map((row) => [row.provider, row.billingKind]),
        [
          ['field-ai', 'managed'],
          ['field-gemini', 'personal'],
        ],
      );
      assert.equal(calls, 2);
      const metadata = JSON.stringify(await reopened.exportMetadata());
      for (const forbidden of [
        credential.encryptedKey,
        'private-catalogue-fixture',
        'private-original-evidence',
        'private-proposed-evidence',
      ])
        assert.equal(metadata.includes(forbidden), false);
    }),
);
