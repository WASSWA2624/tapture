import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';
import { packageMetadataKeys } from '../../src/repositories/relay.js';
import { Store } from '../../src/repositories/store.js';

describe('relay schema', () => {
  it('stores no project content on a package row', async () => {
    const sql = await readFile(
      path.join(
        path.dirname(fileURLToPath(import.meta.url)),
        '../../migrations/003_relay.sql',
      ),
      'utf8',
    );
    assert.equal(/caption|photo|template|record_body/i.test(sql), false);
    assert.match(sql, /expires_at timestamptz/);
    assert.match(sql, /created_at timestamptz/);
    const store = new Store();
    store.addPackage(
      {
        id: 'pkg-1',
        projectId: 'project-1',
        authorDeviceId: 'device-1',
        byteSize: 4,
        createdAt: new Date().toISOString(),
        expiresAt: new Date().toISOString(),
        storageRef: 'blob:pkg-1',
      },
      Buffer.from('data'),
    );
    const row = store.packages()[0];
    assert.ok(row !== undefined);
    assert.deepEqual(Object.keys(row).sort(), [...packageMetadataKeys].sort());
  });
});
