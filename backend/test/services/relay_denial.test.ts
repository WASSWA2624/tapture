import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { AppError } from '../../src/domain/errors.js';
import type { Principal } from '../../src/domain/permissions.js';
import { Store } from '../../src/repositories/store.js';
import { acknowledge, uploadPackage } from '../../src/services/relay/relay.js';
import { testConfig } from '../helpers.js';

const principal: Principal = {
  userId: 'user-1',
  organisationId: 'org-1',
  role: 'project_manager',
  deviceId: 'device-1',
  contextScope: null,
};

/// A store with one member project per id; [open] ones allow relay.
function storeWith(projects: Array<{ id: string; open: boolean }>): Store {
  const store = new Store();
  store.addOrg({
    id: 'org-1',
    name: 'Acme',
    selfRegister: false,
    retentionDays: 30,
  });
  for (const project of projects) {
    store.addProject({
      id: project.id,
      organisationId: 'org-1',
      name: project.id,
      relayEnabled: project.open,
      neverRelay: false,
      retentionDays: 30,
    });
    store.addMember({
      projectId: project.id,
      userId: principal.userId,
      contextScope: null,
    });
  }
  return store;
}

function denials(store: Store): string[] {
  return store
    .security()
    .filter((event) => event.action === 'relay_denied')
    .map((event) => event.target);
}

describe('relay denial', () => {
  it('keeps the security event when a refused upload rolls back', async () => {
    const store = storeWith([{ id: 'closed', open: false }]);
    await assert.rejects(
      () =>
        uploadPackage(
          store,
          testConfig(),
          principal,
          'closed',
          Buffer.from('a'),
          'upload-closed',
        ),
      (error: unknown) => error instanceof AppError && error.status === 400,
    );
    await assert.rejects(
      () =>
        uploadPackage(
          store,
          testConfig(),
          principal,
          'hidden',
          Buffer.from('a'),
          'upload-hidden',
        ),
      (error: unknown) => error instanceof AppError && error.status === 404,
    );
    assert.deepEqual(denials(store), ['closed', 'hidden']);
    assert.equal(store.packages().length, 0);
  });

  it('keeps the security event when a refused acknowledgement rolls back', async () => {
    const store = storeWith([
      { id: 'open', open: true },
      { id: 'paused', open: true },
    ]);
    const first = await uploadPackage(
      store,
      testConfig(),
      principal,
      'open',
      Buffer.from('a'),
      'upload-a',
    );
    const second = await uploadPackage(
      store,
      testConfig(),
      principal,
      'paused',
      Buffer.from('b'),
      'upload-b',
    );
    const paused = store.projects().find((row) => row.id === 'paused');
    assert.ok(paused !== undefined);
    store.saveProject({ ...paused, relayEnabled: false });
    await assert.rejects(
      () => acknowledge(store, principal, [first.id, second.id], 'ack-1'),
      (error: unknown) => error instanceof AppError && error.status === 400,
    );
    assert.deepEqual(denials(store), ['paused']);
    assert.equal(store.acks().length, 0);
    assert.equal(store.packages().length, 2);
    assert.equal(
      store.audit().some((event) => event.action === 'relay_ack'),
      false,
    );
  });

  it('records no denial for an allowed upload', async () => {
    const store = storeWith([{ id: 'open', open: true }]);
    await uploadPackage(
      store,
      testConfig(),
      principal,
      'open',
      Buffer.from('a'),
      'upload-a',
    );
    assert.deepEqual(denials(store), []);
    assert.equal(store.packages().length, 1);
  });
});
