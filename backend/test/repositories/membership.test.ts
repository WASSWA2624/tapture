import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { Store } from '../../src/repositories/store.js';
import { visibleProject } from '../../src/services/projects.js';
import { AppError } from '../../src/domain/errors.js';

describe('membership', () => {
  it('keeps a context scope and hides another organisation', async () => {
    const store = new Store();
    store.addOrg({
      id: 'org-1',
      name: 'Acme',
      selfRegister: false,
      retentionDays: 30,
    });
    store.addOrg({
      id: 'org-2',
      name: 'Other',
      selfRegister: false,
      retentionDays: 30,
    });
    store.addUser({
      id: 'user-1',
      organisationId: 'org-1',
      email: 'a@acme.test',
      passwordHash: 'hash',
      role: 'reviewer',
      status: 'active',
    });
    store.addProject({
      id: 'project-1',
      organisationId: 'org-1',
      name: 'Field',
      relayEnabled: false,
      neverRelay: false,
      retentionDays: 30,
    });
    store.addProject({
      id: 'project-2',
      organisationId: 'org-2',
      name: 'Foreign',
      relayEnabled: false,
      neverRelay: false,
      retentionDays: 30,
    });
    store.addMember({
      projectId: 'project-1',
      userId: 'user-1',
      contextScope: 'north',
    });
    const seen = await visibleProject(
      store,
      {
        userId: 'user-1',
        organisationId: 'org-1',
        role: 'reviewer',
        deviceId: 'device-1',
        contextScope: null,
      },
      'project-1',
    );
    assert.equal(seen.name, 'Field');
    assert.equal(
      store.members().find((row) => row.projectId === 'project-1')
        ?.contextScope,
      'north',
    );
    await assert.rejects(
      () =>
        visibleProject(
          store,
          {
            userId: 'user-1',
            organisationId: 'org-1',
            role: 'reviewer',
            deviceId: 'device-1',
            contextScope: null,
          },
          'project-2',
        ),
      (error: unknown) => error instanceof AppError && error.status === 404,
    );
  });
});
