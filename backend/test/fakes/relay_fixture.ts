import { Store } from '../../src/repositories/store.js';
import type { Principal } from '../../src/domain/permissions.js';

export const principal: Principal = {
  userId: 'user-1',
  organisationId: 'org-1',
  deviceId: 'device-1',
  role: 'administrator',
  contextScope: null,
};

export function seededStore(): Store {
  const store = new Store();
  store.addOrg({
    id: 'org-1',
    name: 'Acme',
    selfRegister: false,
    retentionDays: 30,
  });
  store.addUser({
    id: principal.userId,
    organisationId: principal.organisationId,
    email: 'a@acme.test',
    passwordHash: 'hash',
    role: 'administrator',
    status: 'active',
  });
  store.addDevice({
    id: principal.deviceId,
    userId: principal.userId,
    enrolledAt: new Date().toISOString(),
    lastSeenAt: new Date().toISOString(),
    revoked: false,
  });
  store.addProject({
    id: 'project-1',
    organisationId: principal.organisationId,
    name: 'Project',
    relayEnabled: true,
    neverRelay: false,
    retentionDays: 30,
  });
  store.addMember({
    projectId: 'project-1',
    userId: principal.userId,
    contextScope: null,
  });
  return store;
}
