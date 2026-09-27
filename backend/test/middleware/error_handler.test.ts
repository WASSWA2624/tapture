import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import type { Request, Response } from 'express';
import {
  AppError,
  conflict,
  forbidden,
  internalError,
  invalidCredentials,
  invalidRequest,
  notFound,
  payloadTooLarge,
  quotaExceeded,
  rateLimited,
  unauthorized,
} from '../../src/domain/errors.js';
import { errorHandler } from '../../src/middleware/error_handler.js';

function capture(): {
  res: Response;
  read: () => { status: number; body: unknown };
} {
  let status = 0;
  let body: unknown;
  const res = {
    setHeader() {
      return undefined;
    },
    status(code: number) {
      status = code;
      return this;
    },
    json(payload: unknown) {
      body = payload;
    },
  };
  return { res: res as unknown as Response, read: () => ({ status, body }) };
}

describe('error envelope', () => {
  it('maps every error code and hides internal detail', () => {
    const samples = [
      invalidRequest('Missing name.'),
      unauthorized(),
      invalidCredentials(),
      forbidden(),
      notFound(),
      conflict('Taken.'),
      payloadTooLarge(),
      rateLimited(),
      quotaExceeded(),
      internalError(),
    ];
    for (const error of samples) {
      const captured = capture();
      errorHandler(error, {} as Request, captured.res, () => undefined);
      const body = captured.read().body as {
        error: { code: string; message: string };
      };
      assert.equal(captured.read().status, error.status);
      assert.equal(body.error.code, error.code);
      assert.equal(JSON.stringify(body).includes('stack'), false);
    }
  });

  it('turns an unexpected exception into one 500 and one log line', () => {
    const lines: string[] = [];
    const original = process.stdout.write;
    process.stdout.write = ((chunk: string | Uint8Array) => {
      lines.push(String(chunk));
      return true;
    }) as typeof process.stdout.write;
    try {
      const captured = capture();
      errorHandler(
        new Error('disk failed sk-abcdefghijklmnop'),
        {} as Request,
        captured.res,
        () => undefined,
      );
      const body = captured.read().body as { error: { message: string } };
      assert.equal(captured.read().status, 500);
      assert.equal(body.error.message, 'Something went wrong.');
      assert.equal(JSON.stringify(body).includes('sk-'), false);
      assert.equal(lines.length, 1);
    } finally {
      process.stdout.write = original;
    }
  });

  it('uses the sealed type', () => {
    const error = new AppError('not_found', 404, 'Not found.');
    assert.equal(error.publicMessage, 'Not found.');
  });
});
