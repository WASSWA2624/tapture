import assert from 'node:assert/strict';
import { it } from 'node:test';
import type { AppPool } from '../../src/db/pool.js';
import { createPostgresRepository } from '../../src/repositories/postgres.js';

it('locks the deployment before receipt reads and guards collision updates in parameterised SQL', async () => {
  const statements: Array<{ text: string; values: unknown[] }> = [];
  const pool: AppPool = {
    status: () => ({ connected: true, draining: false }),
    // This controlled pool returns only the aliased receipt row requested by the repository.
    query: async <T extends Record<string, unknown>>(
      text: string,
      values: unknown[] = [],
    ) => {
      statements.push({ text, values });
      return (text.includes('RETURNING idempotency_key')
        ? [{ idempotencyKey: 'a'.repeat(64) }]
        : []) as unknown as T[];
    },
    transaction: async (work) => work(pool),
    probe: async () => true,
    drain: async () => undefined,
  };
  const store = createPostgresRepository(pool);
  await store.withTransaction(async (tx) => {
    await tx.aiReceipt('a'.repeat(64));
    await tx.saveAiReceipt({
      idempotencyKey: 'a'.repeat(64),
      bindingHash: 'b'.repeat(64),
      userId: 'user',
      deviceId: 'device',
      projectId: 'project',
      usageId: 'usage',
      status: 'running',
      createdAt: '2026-10-06T00:00:00.000Z',
    });
  });
  assert.match(statements[0]?.text ?? '', /pg_advisory_xact_lock/);
  assert.match(
    statements[1]?.text ?? '',
    /FROM ai_receipts WHERE idempotency_key=\$1/,
  );
  assert.match(
    statements[2]?.text ?? '',
    /WHERE ai_receipts.binding_hash=\$2.*ai_receipts.usage_id=\$6.*<> 'running'/,
  );
  assert.equal(statements[2]?.text.includes('b'.repeat(64)), false);
  assert.equal(statements[2]?.values[1], 'b'.repeat(64));
});
