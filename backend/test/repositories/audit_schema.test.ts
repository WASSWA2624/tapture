import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';
import { assertAppendOnly } from '../../src/repositories/relay.js';

describe('audit schema', () => {
  it('forbids update and delete in SQL and in the service', async () => {
    const sql = await readFile(
      path.join(
        path.dirname(fileURLToPath(import.meta.url)),
        '../../migrations/004_audit.sql',
      ),
      'utf8',
    );
    assert.match(sql, /BEFORE UPDATE OR DELETE ON audit_events/);
    assert.match(sql, /BEFORE UPDATE OR DELETE ON security_events/);
    assert.throws(() => assertAppendOnly('update'), /append-only/);
    assert.throws(() => assertAppendOnly('delete'), /append-only/);
  });
});
