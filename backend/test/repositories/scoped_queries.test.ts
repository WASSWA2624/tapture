import assert from 'node:assert/strict';
import { it } from 'node:test';
import { createPostgresRepository } from '../../src/repositories/postgres.js';
import type { AppPool } from '../../src/db/pool.js';

it('pushes list scopes, keyset positions and row bounds into parameterised SQL', async () => {
  const statements: Array<{ text: string; values: unknown[] }> = [];
  const pool: AppPool = {
    status: () => ({ connected: true, draining: false }),
    query: async <T extends Record<string, unknown>>(
      text: string,
      values: unknown[] = [],
    ) => {
      statements.push({ text, values });
      return [] as T[];
    },
    transaction: async (work) => work(pool),
    probe: async () => true,
    drain: async () => undefined,
  };
  const store = createPostgresRepository(pool);
  await store.projects({
    organisationId: 'org',
    memberUserId: 'actor',
    cursor: 'project-cursor',
    limit: 51,
  });
  await store.members({
    projectId: 'project',
    cursor: 'member-cursor',
    limit: 51,
  });
  await store.devices({ userId: 'actor', cursor: 'device-cursor', limit: 51 });
  await store.users({
    organisationId: 'org',
    cursor: 'user-cursor',
    limit: 51,
  });
  await store.packages({
    projectId: 'project',
    unacknowledgedDeviceId: 'device',
    activeAfter: '2026-01-01T00:00:00.000Z',
    after: { createdAt: '2025-01-01T00:00:00.000Z', id: 'package-cursor' },
    limit: 51,
  });
  await store.usagePage({
    projectId: 'project',
    userId: 'actor',
    from: '2025-01-01T00:00:00.000Z',
    to: '2026-01-01T00:00:00.000Z',
    cursor: 'usage-cursor',
    limit: 51,
  });
  assert.equal(statements.length, 6);
  for (const statement of statements) {
    assert.match(statement.text, /WHERE/);
    assert.match(statement.text, /ORDER BY/);
    assert.match(statement.text, /LIMIT \$\d+/);
    assert.equal(statement.values.at(-1), 51);
    assert.ok(
      statement.values.some(
        (value) => typeof value === 'string' && value.endsWith('-cursor'),
      ),
    );
    assert.equal(statement.text.includes('-cursor'), false);
  }
  assert.match(statements[4]?.text ?? '', /NOT EXISTS.*relay_acknowledgements/);
  assert.match(statements[4]?.text ?? '', /\(r.created_at,r.id\)>/);
  assert.deepEqual(statements[0]?.values, [
    null,
    'org',
    'actor',
    'project-cursor',
    51,
  ]);
  assert.deepEqual(statements[5]?.values, [
    'project',
    'actor',
    '2025-01-01T00:00:00.000Z',
    '2026-01-01T00:00:00.000Z',
    'usage-cursor',
    51,
  ]);
});
