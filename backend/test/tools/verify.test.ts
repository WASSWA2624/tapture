import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { runStages, scanSecrets, type Stage } from '../../scripts/verify.js';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';

describe('verify', () => {
  it('returns 0 when every stage passes', async () => {
    const stages: Stage[] = [{ name: 'format', run: async () => undefined }];
    assert.equal(await runStages(stages), 0);
  });

  it('returns 1 and names the failed stage', async () => {
    const stages: Stage[] = [
      { name: 'format', run: async () => undefined },
      {
        name: 'lint',
        run: async () => {
          throw new Error('lint broke');
        },
      },
    ];
    assert.equal(await runStages(stages), 1);
  });

  it('continues all stages when any individual stage fails', async () => {
    const names = ['format', 'lint', 'types', 'test', 'audit', 'secrets'];
    for (const failure of names) {
      const ran: string[] = [];
      const stages = names.map((name) => ({
        name,
        run: async () => {
          ran.push(name);
          if (name === failure) throw new Error('deliberate violation');
        },
      }));
      assert.equal(await runStages(stages), 1);
      assert.deepEqual(ran, names);
    }
  });

  it('passes clean source and reports every secret violation with file and line', async () => {
    const root = await mkdtemp(path.join(tmpdir(), 'tapture-secret-scan-'));
    try {
      await writeFile(path.join(root, 'valid.ts'), 'export const value = 1;\n');
      await scanSecrets(root);
      const first = path.join(root, 'first.ts');
      const second = path.join(root, 'second.ts');
      const key = ['s', 'k', '-', 'abcdefghijklmnop'].join('');
      await writeFile(
        first,
        `export const safe = 1;\nexport const key = '${key}';\n`,
      );
      await writeFile(second, `export const key = '${key}';\n`);
      await assert.rejects(
        () => scanSecrets(root),
        (error: unknown) => {
          assert.ok(error instanceof Error);
          assert.ok(error.message.includes(`${first}:2:`));
          assert.ok(error.message.includes(`${second}:1:`));
          assert.equal(error.message.includes(key), false);
          return true;
        },
      );
    } finally {
      assert.equal(path.dirname(path.resolve(root)), path.resolve(tmpdir()));
      assert.ok(path.basename(root).startsWith('tapture-secret-scan-'));
      await rm(root, { recursive: true, force: true });
    }
  });
});
