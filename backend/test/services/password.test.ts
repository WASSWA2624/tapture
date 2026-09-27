import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  hashPassword,
  verifyPassword,
} from '../../src/services/auth/password.js';
import { testConfig } from '../helpers.js';

describe('passwords', () => {
  it('verifies a hash and rejects a parameter change', async () => {
    const config = testConfig();
    const hash = await hashPassword('correct-horse', config);
    assert.equal(hash.includes('correct-horse'), false);
    assert.equal(await verifyPassword('correct-horse', hash, config), true);
    assert.equal(await verifyPassword('wrong-password', hash, config), false);
    const other = testConfig({ ARGON_ITERATIONS: '2' });
    assert.equal(await verifyPassword('correct-horse', hash, other), true);
    const changed = await hashPassword('correct-horse', other);
    assert.notEqual(hash, changed);
  });
});
