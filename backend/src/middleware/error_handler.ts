import type { NextFunction, Request, Response } from 'express';
import { AppError, internalError, payloadTooLarge } from '../domain/errors.js';
import { log } from '../observability/logger.js';

export function errorHandler(
  error: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  const tooLarge =
    error instanceof Error &&
    'type' in error &&
    (error as { type?: string }).type === 'entity.too.large';
  if (!(error instanceof AppError) && !tooLarge) {
    log.error('unhandled', {
      name: error instanceof Error ? error.name : 'unknown',
    });
  }
  const appError = tooLarge
    ? payloadTooLarge()
    : error instanceof AppError
      ? error
      : internalError();
  const body: {
    error: { code: string; message: string; details?: Record<string, unknown> };
  } = {
    error: { code: appError.code, message: appError.publicMessage },
  };
  if (appError.details !== undefined) body.error.details = appError.details;
  if (appError.status === 429) res.setHeader('retry-after', '60');
  res.status(appError.status).json(body);
}
