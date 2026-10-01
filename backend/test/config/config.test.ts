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

  it('validates quota counts and monetary bounds at boot', () => {
    for (const value of ['-1', '6'])
      assert.throws(
        () => parseConfig({ ...valid, AI_RETRY_LIMIT: value }),
        /AI_RETRY_LIMIT|Configuration value/,
      );
    for (const value of ['0', '120001'])
      assert.throws(
        () => parseConfig({ ...valid, AI_TIMEOUT_MS: value }),
        /AI_TIMEOUT_MS|Configuration value/,
      );
    for (const name of [
      'AI_PROJECT_REQUEST_LIMIT',
      'AI_ORGANISATION_DAILY_REQUEST_LIMIT',
    ]) {
      for (const value of ['-1', '0.5', 'Infinity', '9007199254740992']) {
        assert.throws(
          () => parseConfig({ ...valid, [name]: value }),
          new RegExp(name),
        );
      }
    }
    for (const name of ['AI_REQUEST_COST_CEILING', 'AI_ORGANISATION_BUDGET']) {
      for (const value of ['-1', 'NaN', 'Infinity']) {
        assert.throws(
          () => parseConfig({ ...valid, [name]: value }),
          new RegExp(name),
        );
      }
    }
    assert.equal(
      parseConfig({ ...valid, AI_REQUEST_COST_CEILING: '0.025' })
        .aiRequestCostCeiling,
      0.025,
    );
  });

  it('rejects non-positive resource, session and purge limits', () => {
    for (const name of [
      'ACCESS_TTL_SECONDS',
      'REFRESH_TTL_SECONDS',
      'RATE_LIMIT_AUTH',
      'RATE_LIMIT_GENERAL',
      'RATE_LIMIT_BUCKET_LIMIT',
      'BODY_LIMIT_BYTES',
      'PACKAGE_MAX_BYTES',
      'STORAGE_CEILING_BYTES',
      'ORGANISATION_STORAGE_CEILING_BYTES',
      'ARGON_MEMORY_KIB',
      'ARGON_ITERATIONS',
      'ARGON_PARALLELISM',
      'LOCKOUT_FAILURES',
      'LOCKOUT_WINDOW_MS',
      'POOL_MAX',
      'DATABASE_CONNECT_TIMEOUT_MS',
      'DATABASE_STATEMENT_TIMEOUT_MS',
      'PURGE_INTERVAL_MS',
      'PURGE_BATCH_SIZE',
    ]) {
      for (const value of ['0', '-1', '2147483648'])
        assert.throws(
          () => parseConfig({ ...valid, [name]: value }),
          /Configuration value/,
          name,
        );
    }
    assert.throws(() => parseConfig({ ...valid, PORT: '65536' }), /65535/);
    assert.throws(
      () => parseConfig({ ...valid, RATE_LIMIT_BUCKET_LIMIT: '1000001' }),
      /1000000/,
    );
  });
});
