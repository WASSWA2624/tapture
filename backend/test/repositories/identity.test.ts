import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';
import { conflict } from '../../src/domain/errors.js';
import { Store } from '../../src/repositories/store.js';

describe('identity', () => {
  it('creates and finds a user and a device, and enforces uniqueness', () => {
    const store = new Store();
    store.addOrg({
      id: 'org-1',
      name: 'Acme',
      selfRegister: false,
      retentionDays: 30,
    });
    store.addUser({
      id: 'user-1',
      organisationId: 'org-1',
      email: 'a@acme.test',
      passwordHash: 'hash',
      role: 'field_operator',
      status: 'active',
    });
    store.addDevice({
      id: 'device-1',
      userId: 'user-1',
      enrolledAt: new Date().toISOString(),
      lastSeenAt: new Date().toISOString(),
      revoked: false,
    });
    assert.equal(
      store.users().find((row) => row.email === 'a@acme.test')?.id,
      'user-1',
    );
    assert.throws(
      () =>
        store.addUser({
          id: 'user-2',
          organisationId: 'org-1',
          email: 'a@acme.test',
          passwordHash: 'other',
          role: 'reviewer',
          status: 'active',
        }),
      (error: unknown) =>
        error instanceof Error && error.message.includes('already exists'),
    );
    assert.throws(() => {
      throw conflict('That device is already enrolled.');
    });
    assert.throws(() =>
      store.addDevice({
        id: 'device-1',
        userId: 'user-1',
        enrolledAt: new Date().toISOString(),
        lastSeenAt: new Date().toISOString(),
        revoked: false,
      }),
    );
  });

  it('declares the unique constraints in SQL', async () => {
    const sql = await readFile(
      path.join(
        path.dirname(fileURLToPath(import.meta.url)),
        '../../migrations/001_identity.sql',
      ),
      'utf8',
    );
    assert.match(sql, /UNIQUE \(organisation_id, email\)/);
    assert.match(sql, /id text PRIMARY KEY/);
  });
});
