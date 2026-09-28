import type { NextFunction, Request, Response } from 'express';
import { unauthorized } from '../domain/errors.js';
import { requestContext } from './request_context.js';
import { readAccess } from '../services/auth/tokens.js';
import type { Deps } from '../deps.js';
export function authenticate(deps: Deps) {
  return async (
    req: Request,
    _res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const header = req.header('authorization') ?? '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : '';
    if (token.length === 0) {
      next(unauthorized());
      return;
    }
    try {
      const principal = readAccess(token, deps.config);
      const device = (await deps.store.devices()).find(
        (row) => row.id === principal.deviceId,
      );
      const user = (await deps.store.users()).find(
        (row) => row.id === principal.userId,
      );
      if (
        device === undefined ||
        device.revoked ||
        device.userId !== principal.userId ||
        user === undefined ||
        user.status !== 'active' ||
        user.organisationId !== principal.organisationId
      ) {
        next(unauthorized());
        return;
      }
      principal.role = user.role;
      const current = requestContext.getStore();
      if (current !== undefined) current.principal = principal;
      req.principal = principal;
      next();
    } catch (error) {
      next(error);
    }
  };
}
