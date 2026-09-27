import { AsyncLocalStorage } from 'node:async_hooks';
import { randomUUID } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';
import type { Principal } from '../domain/permissions.js';

export interface RequestContext {
  requestId: string;
  principal?: Principal;
}

export const requestContext = new AsyncLocalStorage<RequestContext>();

/// Contract name for the request store.
export const ctx = requestContext;

export function requestContextMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  const header = req.header('x-request-id');
  const requestId =
    header !== undefined && header.length > 0 ? header : randomUUID();
  res.setHeader('x-request-id', requestId);
  requestContext.run({ requestId }, () => next());
}
