import assert from 'node:assert/strict';
import { mkdtemp, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { describe, it } from 'node:test';
import { destroyOrganisation, exportAccounts } from '../../src/cli/admin.js';
import { Store } from '../../src/repositories/store.js';
import { testConfig } from '../helpers.js';
import { auditConfiguration } from '../../src/services/configuration.js';
import { issueTokens } from '../../src/services/auth/tokens.js';

describe('admin', () => {
  it('exports metadata and says projects are not included', async () => {
    const store = new Store();
    store.addOrg({
      id: 'org-1',
      name: 'Acme',
      selfRegister: false,
      retentionDays: 30,
    });
    store.addUser({
      id: 'user-1',
      organisationId: 'org-1',
      email: 'a@acme.test',
      passwordHash: 'hash',
      role: 'administrator',
      status: 'active',
    });
    const dir = await mkdtemp(path.join(tmpdir(), 'tapture-export-'));
    await exportAccounts(store, dir);
    const readme = await readFile(path.join(dir, 'README.txt'), 'utf8');
    const body = await readFile(path.join(dir, 'export.json'), 'utf8');
    assert.match(readme, /Projects are not included/);
    assert.equal(body.includes('passwordHash'), false);
    assert.match(body, /a@acme.test/);
  });

  it('destroys only after the name is confirmed twice and reports the deletion', async () => {
    const store = new Store();
    store.addOrg({
      id: 'org-1',
      name: 'Acme',
      selfRegister: false,
      retentionDays: 30,
    });
    await assert.rejects(() =>
      destroyOrganisation(store, 'Acme', 'Acme', 'nope'),
    );
    const report = await destroyOrganisation(store, 'Acme', 'Acme', 'Acme');
    assert.ok(report.deleted.includes('users'));
    assert.equal(store.orgs().length, 0);
  });

  it('exports all operational metadata and destroys every retained organisation row without exporting credentials or ciphertext', async () => {
    const store = new Store();
    store.addOrg({
      id: 'org',
      name: 'Complete',
      selfRegister: false,
      retentionDays: 30,
    });
    store.addUser({
      id: 'user',
      organisationId: 'org',
      email: 'a@example.test',
      passwordHash: 'private-password-hash',
      role: 'administrator',
      status: 'active',
    });
    store.addDevice({
      id: 'device',
      userId: 'user',
      enrolledAt: new Date().toISOString(),
      lastSeenAt: new Date().toISOString(),
      revoked: false,
    });
    store.addProject({
      id: 'project',
      organisationId: 'org',
      name: 'Registration only',
      relayEnabled: true,
      neverRelay: false,
      retentionDays: 30,
    });
    store.addMember({
      projectId: 'project',
      userId: 'user',
      contextScope: 'scope',
    });
    store.addPackage(
      {
        id: 'package',
        projectId: 'project',
        authorDeviceId: 'device',
        byteSize: 18,
        createdAt: new Date().toISOString(),
        expiresAt: '2099-01-01T00:00:00Z',
        storageRef: 'blob:package',
      },
      Buffer.from('private-ciphertext'),
    );
    store.addAck({ packageId: 'package', deviceId: 'device' });
    store.bumpVector('project', 'device');
    store.addInvite({
      tokenHash: 'private-token-hash',
      userId: 'user',
      used: false,
      expiresAt: '2099-01-01T00:00:00Z',
      purpose: 'invitation',
    });
    store.addUsage({
      projectId: 'project',
      userId: 'user',
      model: 'model',
      byteSize: 1,
      durationMs: 1,
      cost: 0.1,
      outcome: 'ok',
      at: new Date().toISOString(),
    });
    store.saveIdempotency('key', {
      status: 200,
      body: { acknowledged: ['package'] },
    });
    store.setLockout('addr', 1, null);
    store.recordSecurity({
      actorId: 'user',
      action: 'failure',
      target: 'device',
      before: null,
      after: null,
    });
    const config = testConfig({ AI_PROVIDER_KEY: 'private-provider-key' });
    await auditConfiguration(store, config);
    await issueTokens(
      store,
      {
        userId: 'user',
        organisationId: 'org',
        deviceId: 'device',
        role: 'administrator',
        contextScope: null,
      },
      config,
    );
    store.recordMigration('migration', 'checksum');
    const dir = await mkdtemp(path.join(tmpdir(), 'tapture-complete-export-'));
    await exportAccounts(store, dir);
    const text = await readFile(path.join(dir, 'export.json'), 'utf8');
    for (const secret of [
      'private-password-hash',
      'private-token-hash',
      'private-ciphertext',
      'private-provider-key',
      'tokenHash',
      'passwordHash',
      'fingerprint',
    ])
      assert.equal(text.includes(secret), false, secret);
    const snapshot = JSON.parse(text) as Record<string, unknown>;
    for (const key of [
      'organisations',
      'accounts',
      'devices',
      'projects',
      'memberships',
      'audit',
      'security',
      'packageMetadata',
      'acknowledgements',
      'vectors',
      'invitations',
      'refreshFamilies',
      'usage',
      'idempotency',
      'lockouts',
      'configuration',
      'schema',
    ])
      assert.ok(Array.isArray(snapshot[key]) && snapshot[key].length > 0, key);
    await assert.rejects(() => exportAccounts(store, dir), /EEXIST/);
    const report = await destroyOrganisation(
      store,
      'Complete',
      'Complete',
      'Complete',
    );
    assert.ok(report.deleted.includes('relay-ciphertext'));
    assert.equal(store.blob('blob:package'), undefined);
    const destroyed = store.exportMetadata();
    for (const [key, rows] of Object.entries(destroyed))
      if (key !== 'schema') assert.deepEqual(rows, [], key);
    assert.equal(store.schemaHistory().length, 1);
  });

  it('refuses whole-deployment destroy when another organisation exists', async () => {
    const store = new Store();
    for (const id of ['one', 'two'])
      store.addOrg({ id, name: id, selfRegister: false, retentionDays: 30 });
    await assert.rejects(
      () => destroyOrganisation(store, 'one', 'one', 'one'),
      /single matching/,
    );
    assert.equal(store.orgs().length, 2);
  });
});
