import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { fakeProvider } from '../fakes/fake_provider.js';

describe('provider contract', () => {
  it('can succeed, fail, time out and return malformed output', async () => {
    const request = {
      projectId: 'project-1',
      model: 'fake',
      payload: Buffer.from('hi'),
    };
    assert.equal(
      (await fakeProvider('ok').extract(request)).text.startsWith('ok:'),
      true,
    );
    await assert.rejects(() => fakeProvider('fail').ocr(request), /failed/);
    await assert.rejects(
      () => fakeProvider('timeout').transcribe(request),
      /timeout/,
    );
    assert.equal((await fakeProvider('malformed').refine(request)).text, '');
  });
});
