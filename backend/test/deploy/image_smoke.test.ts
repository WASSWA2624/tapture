import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '../..');

describe('image', () => {
  it('runs as non-root and bakes no secret', async () => {
    const docker = await readFile(path.join(root, 'Dockerfile'), 'utf8');
    assert.match(docker, /USER node/);
    assert.equal(/ENV\s+TOKEN_SECRET/i.test(docker), false);
    const runbook = await readFile(path.join(root, 'RUNBOOK.md'), 'utf8');
    assert.match(runbook, /Projects are not included/);
    assert.match(runbook, /investigate before/i);
  });
});
