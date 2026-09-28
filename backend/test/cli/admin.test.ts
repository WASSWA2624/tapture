import assert from 'node:assert/strict';
import { mkdtemp, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { describe, it } from 'node:test';
import { destroyOrganisation, exportAccounts } from '../../src/cli/admin.js';
import { Store } from '../../src/repositories/store.js';

describe('admin', () => {
  it('exports metadata and says projects are not included', async () => {
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
      role: 'administrator',
      status: 'active',
    });
    const dir = await mkdtemp(path.join(tmpdir(), 'tapture-export-'));
    await exportAccounts(store, dir);
    const readme = await readFile(path.join(dir, 'README.txt'), 'utf8');
    const body = await readFile(path.join(dir, 'export.json'), 'utf8');
    assert.match(readme, /Projects are not included/);
    assert.equal(body.includes('passwordHash'), false);
    assert.match(body, /a@acme.test/);
  });

  it('destroys only after the name is confirmed twice and reports the deletion', async () => {
    const store = new Store();
    store.addOrg({
      id: 'org-1',
      name: 'Acme',
      selfRegister: false,
      retentionDays: 30,
    });
    await assert.rejects(() =>
      destroyOrganisation(store, 'Acme', 'Acme', 'nope'),
    );
    const report = await destroyOrganisation(store, 'Acme', 'Acme', 'Acme');
    assert.ok(report.deleted.includes('users'));
    assert.equal(store.orgs().length, 0);
  });
});
