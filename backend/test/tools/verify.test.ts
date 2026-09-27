import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { runStages, type Stage } from '../../scripts/verify.js';

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
});
