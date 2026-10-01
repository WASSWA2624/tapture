import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { it } from 'node:test';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';
import { auditConfiguration } from '../../src/services/configuration.js';
import { issueTokens } from '../../src/services/auth/tokens.js';
import { postgresConfigured, withPostgres } from '../postgres_fixture.js';

const execute = promisify(execFile);
const root = fileURLToPath(new URL('../../', import.meta.url));

it(
  'real admin processes export seeded PostgreSQL without credentials and destroy it only after matching confirmations',
  { skip: !postgresConfigured, timeout: 60_000 },
  async () =>
    withPostgres(async ({ store, config, databaseUrl }) => {
      const temporary = await mkdtemp(
        path.join(tmpdir(), 'tapture-postgres-admin-'),
      );
      const out = path.join(temporary, 'export');
      const orgName = `CLI fixture ${randomUUID()}`;
      const passwordHash = randomUUID();
      const invitationHash = randomUUID();
      const ciphertext = Buffer.from(randomUUID());
      const run = (...args: string[]) =>
        execute(
          process.execPath,
          [
            '--import',
            'tsx',
            path.join(root, 'src', 'cli', 'admin.ts'),
            ...args,
          ],
          {
            cwd: root,
            timeout: 15_000,
            maxBuffer: 1_000_000,
            env: {
              ...process.env,
              DATABASE_URL: databaseUrl,
              TOKEN_SECRET: randomUUID(),
            },
          },
        );
      try {
        const now = new Date().toISOString();
        await store.addOrg({
          id: 'org',
          name: orgName,
          selfRegister: false,
          retentionDays: 30,
        });
        await store.addUser({
          id: 'user',
          organisationId: 'org',
          email: 'cli@example.test',
          passwordHash,
          role: 'administrator',
          status: 'active',
        });
        await store.addDevice({
          id: 'device',
          userId: 'user',
          enrolledAt: now,
          lastSeenAt: now,
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
          contextScope: 'north',
        });
        await store.addPackage(
          {
            id: 'package',
            projectId: 'project',
            authorDeviceId: 'device',
            byteSize: ciphertext.length,
            createdAt: now,
            expiresAt: '2099-01-01T00:00:00Z',
            storageRef: 'blob:package',
          },
          ciphertext,
        );
        await store.addAck({ packageId: 'package', deviceId: 'device' });
        await store.bumpVector('project', 'device');
        await store.addInvite({
          tokenHash: invitationHash,
          userId: 'user',
          used: false,
          expiresAt: '2099-01-01T00:00:00Z',
          purpose: 'invitation',
        });
        await issueTokens(
          store,
          {
            userId: 'user',
            organisationId: 'org',
            role: 'administrator',
            deviceId: 'device',
            contextScope: null,
          },
          config,
        );
        await store.addUsage({
          projectId: 'project',
          userId: 'user',
          model: 'fake',
          byteSize: 1,
          durationMs: 1,
          outcome: 'ok',
          cost: 0.01,
          at: now,
        });
        await store.saveIdempotency('replay', {
          status: 201,
          body: { id: 'package' },
        });
        await store.setLockout('lock', 1, null);
        await store.recordAudit({
          actorId: 'user',
          action: 'seeded',
          target: 'project',
          before: null,
          after: null,
        });
        await store.recordSecurity({
          actorId: 'user',
          action: 'seeded',
          target: 'device',
          before: null,
          after: null,
        });
        await auditConfiguration(store, config);

        const exported = await run('export', '--out', out);
        assert.match(exported.stdout, /exported/);
        assert.equal(exported.stderr, '');
        const text = await readFile(path.join(out, 'export.json'), 'utf8');
        const snapshot = JSON.parse(text) as Record<string, unknown[]>;
        for (const key of [
          'organisations',
          'accounts',
          'devices',
          'projects',
          'memberships',
          'packageMetadata',
          'acknowledgements',
          'vectors',
          'invitations',
          'refreshFamilies',
          'usage',
          'idempotency',
          'lockouts',
          'audit',
          'security',
          'configuration',
          'schema',
        ])
          assert.ok(
            Array.isArray(snapshot[key]) && snapshot[key].length > 0,
            key,
          );
        for (const secret of [
          passwordHash,
          invitationHash,
          ciphertext.toString(),
          'password_hash',
          'token_hash',
          'fingerprint',
        ]) {
          assert.equal(text.includes(secret), false, secret);
          assert.equal(exported.stdout.includes(secret), false, secret);
        }
        assert.match(
          await readFile(path.join(out, 'README.txt'), 'utf8'),
          /Projects are not included/,
        );
        const before = await store.exportMetadata();
        for (const args of [
          ['destroy', '--confirm', orgName],
          ['destroy', '--confirm', orgName, '--again', 'wrong organisation'],
        ]) {
          await assert.rejects(
            () => run(...args),
            (error: unknown) =>
              error instanceof Error && 'code' in error && error.code === 1,
          );
          assert.deepEqual(await store.exportMetadata(), before);
          assert.deepEqual(await store.blob('blob:package'), ciphertext);
        }
        const destroyed = await run(
          'destroy',
          '--confirm',
          orgName,
          '--again',
          orgName,
        );
        assert.match(destroyed.stdout, /deleted .*relay-ciphertext/);
        assert.equal(destroyed.stderr, '');
        assert.equal(await store.blob('blob:package'), undefined);
        for (const [key, rows] of Object.entries(
          await store.exportMetadata(),
        )) {
          if (key === 'schema') assert.deepEqual(rows, before[key]);
          else assert.deepEqual(rows, [], key);
        }
      } finally {
        await rm(temporary, { recursive: true, force: true });
      }
    }),
);
