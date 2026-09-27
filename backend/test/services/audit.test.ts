import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { AppError } from '../../src/domain/errors.js';
import { withTransaction } from '../../src/repositories/base.js';
import { Store } from '../../src/repositories/store.js';
import { listAudit, recordAudit } from '../../src/services/audit.js';

describe('audit', () => {
  it('writes in the same transaction and keeps no row when that transaction fails', async () => {
    const store = new Store();
    await assert.rejects(() =>
      withTransaction(store, async (tx) => {
        recordAudit(tx, {
          actorId: 'user-1',
          action: 'change_role',
          target: 'user-2',
          before: { role: 'reviewer' },
          after: { role: 'project_manager' },
        });
        throw new AppError('conflict', 409, 'Stopped.');
      }),
    );
    assert.equal(listAudit(store).length, 0);
    recordAudit(store, {
      actorId: 'user-1',
      action: 'change_role',
      target: 'user-2',
      before: { role: 'reviewer' },
      after: { role: 'project_manager' },
    });
    assert.equal(listAudit(store)[0]?.action, 'change_role');
    assert.equal(typeof store.audit().find, 'function');
    assert.equal('updateAudit' in store, false);
  });
});
