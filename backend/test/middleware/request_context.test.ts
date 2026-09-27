import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import type { Request, Response } from 'express';
import {
  ctx,
  requestContextMiddleware,
} from '../../src/middleware/request_context.js';

describe('request context', () => {
  it('keeps one identifier across an async boundary and returns it', async () => {
    let seen = '';
    const headers: Record<string, string> = {};
    const req = { header: () => 'req-7' } as unknown as Request;
    const res = {
      setHeader(name: string, value: string) {
        headers[name] = value;
      },
    } as unknown as Response;
    await new Promise<void>((resolve) => {
      requestContextMiddleware(req, res, () => {
        void Promise.resolve().then(() => {
          seen = ctx.getStore()?.requestId ?? '';
          resolve();
        });
      });
    });
    assert.equal(seen, 'req-7');
    assert.equal(headers['x-request-id'], 'req-7');
  });
});
