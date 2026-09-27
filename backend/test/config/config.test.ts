import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { parseConfig } from '../../src/config/schema.js';

const valid = {
  DATABASE_URL: 'memory://test',
  TOKEN_SECRET: 'secret',
};

describe('config', () => {
  it('accepts a complete environment', () => {
    const config = parseConfig(valid);
    assert.equal(config.tokenSecret, 'secret');
    assert.equal(config.retentionDays, 30);
  });

  it('names a missing secret', () => {
    assert.throws(
      () => parseConfig({ DATABASE_URL: 'memory://test' }),
      /TOKEN_SECRET/,
    );
  });

  it('rejects a malformed number', () => {
    assert.throws(
      () => parseConfig({ ...valid, PORT: 'soon' }),
      /whole number/,
    );
  });

  it('rejects retention past the hard maximum', () => {
    assert.throws(() => parseConfig({ ...valid, RETENTION_DAYS: '91' }), /90/);
  });
});
