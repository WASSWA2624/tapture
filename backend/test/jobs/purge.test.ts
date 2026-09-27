import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { runPurge } from '../../src/jobs/purge.js';
import { Store } from '../../src/repositories/store.js';

describe('purge job', () => {
  it('deletes only expired packages and reports counts', async () => {
    const store = new Store();
    const now = new Date('2026-02-01T00:00:00.000Z');
    store.addPackage(
      {
        id: 'old',
        projectId: 'project-1',
        authorDeviceId: 'device-1',
        byteSize: 4,
        createdAt: '2026-01-01T00:00:00.000Z',
        expiresAt: '2026-01-15T00:00:00.000Z',
        storageRef: 'blob:old',
      },
      Buffer.from('old!'),
    );
    store.addPackage(
      {
        id: 'new',
        projectId: 'project-1',
        authorDeviceId: 'device-1',
        byteSize: 3,
        createdAt: '2026-01-20T00:00:00.000Z',
        expiresAt: '2026-03-01T00:00:00.000Z',
        storageRef: 'blob:new',
      },
      Buffer.from('new'),
    );
    const report = await runPurge(store, now);
    assert.equal(report.deleted, 1);
    assert.equal(report.bytesReclaimed, 4);
    assert.equal(report.failures, 0);
    assert.equal(store.packages()[0]?.id, 'new');
  });
});
