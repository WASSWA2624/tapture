import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { shouldPurge } from '../../src/services/relay/purge_decision.js';

describe('purge decision', () => {
  it('uses the injected clock', () => {
    const expiry = '2026-01-02T00:00:00.000Z';
    assert.equal(
      shouldPurge(expiry, new Date('2026-01-01T00:00:00.000Z')),
      false,
    );
    assert.equal(
      shouldPurge(expiry, new Date('2026-01-02T00:00:00.000Z')),
      true,
    );
  });
});
