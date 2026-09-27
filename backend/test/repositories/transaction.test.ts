import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { AppError } from '../../src/domain/errors.js';
import { withTransaction } from '../../src/repositories/base.js';
import { Store } from '../../src/repositories/store.js';

describe('transactions', () => {
  it('rolls back both tables when the second write fails', async () => {
    const store = new Store();
    store.addOrg({
      id: 'org-1',
      name: 'Acme',
      selfRegister: false,
      retentionDays: 30,
    });
    await assert.rejects(
      () =>
        withTransaction(store, async (tx) => {
          tx.addUser({
            id: 'user-1',
            organisationId: 'org-1',
            email: 'a@acme.test',
            passwordHash: 'hash',
            role: 'reviewer',
            status: 'active',
          });
          tx.recordAudit({
            actorId: 'user-1',
            action: 'create',
            target: 'user-1',
            before: null,
            after: null,
          });
          throw new AppError('conflict', 409, 'Stopped.');
        }),
      (error: unknown) =>
        error instanceof AppError && error.code === 'conflict',
    );
    assert.equal(store.users().length, 0);
    assert.equal(store.audit().length, 0);
  });

  it('maps a unique violation to conflict', () => {
    const store = new Store();
    store.addOrg({
      id: 'org-1',
      name: 'Acme',
      selfRegister: false,
      retentionDays: 30,
    });
    const user = {
      id: 'user-1',
      organisationId: 'org-1',
      email: 'a@acme.test',
      passwordHash: 'hash',
      role: 'reviewer' as const,
      status: 'active' as const,
    };
    store.addUser(user);
    assert.throws(
      () => store.addUser({ ...user, id: 'user-2' }),
      (error: unknown) =>
        error instanceof AppError && error.code === 'conflict',
    );
  });
});
