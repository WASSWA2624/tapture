import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { AppError } from '../../src/domain/errors.js';
import { Store } from '../../src/repositories/store.js';
import { assertQuota } from '../../src/services/ai/quota.js';

describe('ai quota', () => {
  it('refuses before the call once the ceiling is reached', () => {
    const store = new Store();
    const principal = {
      userId: 'user-1',
      organisationId: 'org-1',
      role: 'field_operator' as const,
      deviceId: 'device-1',
      contextScope: null,
    };
    for (let index = 0; index < 100; index += 1) {
      store.addUsage({
        projectId: 'project-1',
        userId: 'user-1',
        model: 'fake',
        byteSize: 1,
        durationMs: 1,
        outcome: 'ok',
        cost: 0,
        at: new Date().toISOString(),
      });
    }
    assert.throws(
      () => assertQuota(store, principal, 'project-1'),
      (error: unknown) =>
        error instanceof AppError && error.code === 'quota_exceeded',
    );
  });
});
