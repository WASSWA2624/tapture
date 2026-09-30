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
      const [device, user] = await Promise.all([
        deps.store.deviceById(principal.deviceId),
        deps.store.userById(principal.userId),
      ]);
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
      if (current !== undefined) {
        current.principal = principal;
        // Express owns this matched route; never log the user-supplied URL.
        const route = req.route as { path?: unknown } | undefined;
        if (typeof route?.path === 'string') current.route = route.path;
      }
      req.principal = principal;
      next();
    } catch (error) {
      next(error);
    }
  };
}
