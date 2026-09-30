import type { NextFunction, Request, Response } from 'express';
import {
  AppError,
  internalError,
  invalidRequest,
  payloadTooLarge,
} from '../domain/errors.js';
import { log } from '../observability/logger.js';
import { requestContext } from './request_context.js';

export function errorHandler(
  error: unknown,
  req: Request,
  res: Response,
  _next: NextFunction,
): void {
  const route = req.route as { path?: unknown } | undefined;
  const context = requestContext.getStore();
  if (context !== undefined && typeof route?.path === 'string')
    context.route = route.path;
  const tooLarge =
    error instanceof Error &&
    'type' in error &&
    (error as { type?: string }).type === 'entity.too.large';
  const malformedJson =
    error instanceof Error &&
    'type' in error &&
    (error as { type?: string }).type === 'entity.parse.failed';
  if (!(error instanceof AppError) && !tooLarge && !malformedJson) {
    log.error('unhandled', {
      name: error instanceof Error ? error.name : 'unknown',
    });
  }
  const appError = tooLarge
    ? payloadTooLarge()
    : malformedJson
      ? invalidRequest('Invalid JSON body.')
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
