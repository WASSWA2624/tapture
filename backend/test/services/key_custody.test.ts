import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { KeyCustody } from '../../src/services/ai/keys.js';

describe('key custody', () => {
  it('never returns the key', () => {
    const custody = new KeyCustody('sk-abcdefghijklmnop');
    const client = custody.client();
    assert.equal(client.configured, true);
    assert.equal(JSON.stringify(custody).includes('sk-'), false);
    assert.equal(Object.keys(custody).includes('key'), false);
    assert.equal(JSON.stringify(client).includes('sk-'), false);
  });
});
