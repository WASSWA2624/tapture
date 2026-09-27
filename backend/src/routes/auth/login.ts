import type { Express } from 'express';
import type { Deps } from '../../deps.js';
import { asyncRoute, field } from '../../http.js';
import { rateLimit } from '../../middleware/rate_limit.js';
import { login } from '../../services/auth/login.js';

export function registerLogin(app: Express, deps: Deps): void {
  app.post(
    '/api/v1/auth/login',
    rateLimit(deps, 'auth'),
    asyncRoute(async (req, res) => {
      const tokens = await login(deps.store, deps.config, {
        email: field(req.body, 'email'),
        password: field(req.body, 'password'),
        deviceId: field(req.body, 'deviceId'),
        organisationId: field(req.body, 'organisationId'),
      });
      res.json(tokens);
    }),
  );
}
