import type { Express } from 'express';
import type { Deps } from '../../deps.js';
import { asyncRoute, field } from '../../http.js';
import { rateLimit } from '../../middleware/rate_limit.js';
import { revoke, rotate } from '../../services/auth/tokens.js';

export function registerSession(app: Express, deps: Deps): void {
  app.post(
    '/api/v1/auth/refresh',
    rateLimit(deps, 'auth'),
    asyncRoute(async (req, res) => {
      res.json(
        await rotate(deps.store, field(req.body, 'refreshToken'), deps.config),
      );
    }),
  );
  app.post(
    '/api/v1/auth/logout',
    asyncRoute(async (req, res) => {
      revoke(deps.store, field(req.body, 'refreshToken'), deps.config);
      res.status(204).end();
    }),
  );
}
