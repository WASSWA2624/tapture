import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { createLogger } from '../../src/observability/logger.js';
import { appFor, makeDeps, seedUser } from '../helpers.js';

describe('rate limit', () => {
  it('returns 429 with a retry hint and records a security event', async () => {
    const deps = makeDeps({ RATE_LIMIT_AUTH: '2' });
    const app = appFor(deps);
    const account = await seedUser(deps);
    const body = { ...account, password: 'wrong-password' };
    const first = await request(app).post('/api/v1/auth/login').send(body);
    const second = await request(app).post('/api/v1/auth/login').send(body);
    const third = await request(app).post('/api/v1/auth/login').send(body);
    assert.equal(first.status, 401);
    assert.equal(second.status, 401);
    assert.equal(third.status, 429);
    assert.equal(third.headers['retry-after'], '60');
    assert.ok(
      deps.store.security().some((event) => event.action === 'rate_limited'),
    );
  });

  it('still answers 429 when the audit write fails, without an unhandled rejection', async (t) => {
    const deps = makeDeps({ RATE_LIMIT_GENERAL: '1' });
    const lines: string[] = [];
    deps.log = createLogger((line) => {
      lines.push(line);
    });
    t.mock.method(deps.store, 'recordSecurity', async () => {
      throw new Error('database unavailable');
    });
    const app = appFor(deps);
    const unhandled: unknown[] = [];
    const onUnhandled = (reason: unknown): void => {
      unhandled.push(reason);
    };
    process.on('unhandledRejection', onUnhandled);
    try {
      const first = await request(app).get('/health').timeout(2000);
      const second = await request(app).get('/health').timeout(2000);
      await new Promise<void>((resolve) => {
        setImmediate(resolve);
      });
      assert.equal(first.status, 200);
      assert.equal(second.status, 429);
      assert.equal(second.headers['retry-after'], '60');
      assert.deepEqual(unhandled, []);
      assert.ok(lines.some((line) => line.includes('rate_limit_audit_failed')));
    } finally {
      process.off('unhandledRejection', onUnhandled);
    }
  });
});
