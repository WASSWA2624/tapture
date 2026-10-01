import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { createLogger } from '../../src/observability/logger.js';
import { appFor, makeDeps, seedUser } from '../helpers.js';
import type { Request, Response } from 'express';
import { AppError } from '../../src/domain/errors.js';
import { rateLimit } from '../../src/middleware/rate_limit.js';

describe('rate limit', () => {
  it('throttles every authentication endpoint and logs its refusal', async () => {
    for (const path of ['login', 'register', 'reset', 'refresh']) {
      const deps = makeDeps({ RATE_LIMIT_AUTH: '1' });
      const app = appFor(deps);
      const first = await request(app).post(`/api/v1/auth/${path}`).send({});
      const second = await request(app).post(`/api/v1/auth/${path}`).send({});
      assert.notEqual(first.status, 429, path);
      assert.equal(second.status, 429, path);
      assert.equal(second.headers['retry-after'], '60', path);
      assert.equal(
        deps.store.security().filter((row) => row.action === 'rate_limited')
          .length,
        1,
        path,
      );
    }
  });

  it('bounds active address state, reclaims expired buckets and isolates application instances', async (t) => {
    const deps = makeDeps({ RATE_LIMIT_BUCKET_LIMIT: '2' });
    const isolated = makeDeps({ RATE_LIMIT_BUCKET_LIMIT: '2' });
    let now = 100_000;
    t.mock.method(Date, 'now', () => now);
    const middleware = rateLimit(deps, 'general');
    const errors: unknown[] = [];
    const hit = async (address: string, apply = middleware) => {
      // This middleware reads only the peer address and passes its typed error
      // to next; the test deliberately supplies that minimal HTTP boundary.
      await apply(
        { ip: address } as Request,
        {} as Response,
        (error?: unknown) => errors.push(error),
      );
      return errors.at(-1);
    };
    assert.equal(await hit('peer-a'), undefined);
    assert.equal(await hit('peer-b'), undefined);
    const refused = await hit('peer-c');
    assert.ok(refused instanceof AppError && refused.code === 'rate_limited');
    assert.equal(
      await hit('peer-c', rateLimit(isolated, 'general')),
      undefined,
    );
    assert.equal(deps.store.security().length, 1);
    now += 60_001;
    assert.equal(await hit('peer-c'), undefined);
    assert.equal(await hit('peer-d'), undefined);
    assert.equal(deps.store.security().length, 1);
  });

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
