import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { Store } from '../../src/repositories/store.js';
import { runPurge } from '../../src/jobs/purge.js';
import { auditConfiguration } from '../../src/services/configuration.js';
import { acknowledge, uploadPackage } from '../../src/services/relay/relay.js';
import { appFor, makeDeps, seedUser, testConfig } from '../helpers.js';
import { principal, seededStore } from '../fakes/relay_fixture.js';

describe('configuration audit', () => {
  it('shortens existing ciphertext expiry when retention shrinks and never extends it on increase', async () => {
    const store = seededStore();
    const config = testConfig();
    const row = await uploadPackage(
      store,
      config,
      principal,
      'project-1',
      Buffer.from('opaque'),
      'retained',
    );
    await auditConfiguration(store, config);
    await auditConfiguration(store, { ...config, retentionDays: 10 });
    const shorter = new Date(
      Date.parse(row.createdAt) + 10 * 24 * 60 * 60 * 1000,
    ).toISOString();
    assert.equal(store.orgs()[0]?.retentionDays, 10);
    assert.equal(store.projects()[0]?.retentionDays, 10);
    assert.equal(store.packages()[0]?.expiresAt, shorter);
    await auditConfiguration(store, { ...config, retentionDays: 60 });
    assert.equal(store.orgs()[0]?.retentionDays, 60);
    assert.equal(store.projects()[0]?.retentionDays, 10);
    assert.equal(store.packages()[0]?.expiresAt, shorter);
  });

  it('rolls back policy metadata and applied retention if its audit row fails', async () => {
    const store = seededStore();
    store.recordAudit = () => {
      throw new Error('audit storage refused');
    };
    await assert.rejects(
      () => auditConfiguration(store, testConfig({ RETENTION_DAYS: '10' })),
      /audit storage refused/,
    );
    assert.equal(store.runtimeSettings().length, 0);
    assert.equal(store.orgs()[0]?.retentionDays, 30);
    assert.equal(store.projects()[0]?.retentionDays, 30);
  });
  it('audits each applied configuration change exactly once and never records keys', async () => {
    const store = new Store();
    const initial = testConfig({
      AI_PROVIDER_KEY: 'first-private-provider-value',
    });
    await auditConfiguration(store, initial);
    assert.equal(store.audit().length, 5);
    await auditConfiguration(store, initial);
    assert.equal(store.audit().length, 5);
    await auditConfiguration(store, {
      ...initial,
      aiProviderKey: 'second-private-provider-value',
      retentionDays: 20,
    });
    const changed = store
      .audit()
      .filter((row) => row.action === 'configuration_changed');
    assert.deepEqual(changed.map((row) => row.target).sort(), [
      'provider_key',
      'relay_policy',
    ]);
    assert.ok(
      changed.every((row) => row.actorId === 'deployment' && row.at.length > 0),
    );
    const exported = JSON.stringify(store.exportMetadata());
    assert.equal(exported.includes('private-provider-value'), false);
    assert.equal(exported.includes(initial.tokenSecret), false);
    assert.equal(exported.includes('fingerprint'), false);
  });
});

describe('retained state and metrics', () => {
  it('bounds transient cleanup and preserves unexpired tokens and durable vectors', async () => {
    const store = seededStore();
    const now = new Date();
    const expired = new Date(now.getTime() - 1).toISOString();
    const future = new Date(now.getTime() + 100000).toISOString();
    store.addInvite({
      tokenHash: 'old',
      userId: principal.userId,
      used: false,
      expiresAt: expired,
      purpose: 'invitation',
    });
    store.addInvite({
      tokenHash: 'future',
      userId: principal.userId,
      used: false,
      expiresAt: future,
      purpose: 'password_reset',
    });
    store.addRefresh({
      id: 'refresh',
      familyId: 'family',
      userId: principal.userId,
      deviceId: principal.deviceId,
      tokenHash: 'hash',
      rotated: false,
      revoked: false,
      expiresAt: expired,
    });
    store.saveIdempotency(
      'expired',
      { status: 200, body: { acknowledged: [] } },
      expired,
    );
    store.setLockout('addr:org-1:a@acme.test', 1, null, expired);
    store.bumpVector('project-1', principal.deviceId);
    assert.equal(store.purgeTransient(now, 2), 2);
    assert.equal(store.purgeTransient(now, 2), 2);
    assert.equal(store.purgeTransient(now, 2), 0);
    assert.equal(store.invites()[0]?.tokenHash, 'future');
    assert.equal(store.vectors().length, 1);
    assert.equal(store.idempotency('expired'), undefined);
    store.saveIdempotency('expired', { status: 201, body: {} }, future);
    assert.equal(store.idempotency('expired')?.status, 201);
  });

  it('moves counters for committed events only, including replay and expiry reclamation', async () => {
    const deps = makeDeps();
    const store = seededStore();
    const row = await uploadPackage(
      store,
      deps.config,
      principal,
      'project-1',
      Buffer.from('opaque'),
      'upload',
      deps.metrics,
    );
    await uploadPackage(
      store,
      deps.config,
      principal,
      'project-1',
      Buffer.from('different'),
      'upload',
      deps.metrics,
    );
    assert.equal(deps.metrics.packagesStored, 1);
    assert.equal(deps.metrics.storageBytes['project-1'], 6);
    await assert.rejects(() =>
      uploadPackage(
        store,
        { ...deps.config, storageCeilingBytes: 6 },
        principal,
        'project-1',
        Buffer.from('overflow'),
        'refused',
        deps.metrics,
      ),
    );
    assert.equal(deps.metrics.packagesStored, 1);
    assert.equal(deps.metrics.storageBytes['project-1'], 6);
    await acknowledge(store, principal, [row.id], 'ack', deps.metrics);
    await acknowledge(store, principal, [row.id], 'ack', deps.metrics);
    await acknowledge(store, principal, [row.id], 'other-key', deps.metrics);
    assert.equal(deps.metrics.packagesAcked, 1);
    assert.equal(deps.metrics.packagesPurged, 1);
    assert.equal(deps.metrics.storageBytes['project-1'], 0);
    assert.equal(store.acks().length, 0);
    const waiting = await uploadPackage(
      store,
      deps.config,
      principal,
      'project-1',
      Buffer.from('bytes'),
      'expiry',
      deps.metrics,
    );
    const report = await runPurge(
      store,
      new Date(Date.parse(waiting.expiresAt) + 1),
      deps.metrics,
      1,
    );
    assert.equal(report.deleted, 1);
    assert.equal(report.bytesReclaimed, 5);
    assert.equal(deps.metrics.packagesPurged, 2);
    assert.deepEqual(deps.metrics.storageBytes, {});
    assert.equal(store.blob(waiting.storageRef), undefined);
  });

  it('counts parser and limiter failures before route execution', async () => {
    const deps = makeDeps({ RATE_LIMIT_GENERAL: '1' });
    const app = appFor(deps);
    const malformed = await request(app)
      .post('/api/v1/auth/login')
      .set('content-type', 'application/json')
      .send('{');
    assert.equal(malformed.status, 400);
    await request(app).get('/health');
    assert.equal((await request(app).get('/health')).status, 429);
    assert.equal(deps.metrics.requests['unmatched']?.errors, 2);
    assert.equal(deps.metrics.requests['/health']?.count, 1);
  });
});
