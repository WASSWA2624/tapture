import type { Express } from 'express';
import type { Deps } from '../../deps.js';
import { asyncRoute, field } from '../../http.js';
import { invalidCredentials } from '../../domain/errors.js';
import { rateLimit } from '../../middleware/rate_limit.js';
import { login } from '../../services/auth/login.js';
export function registerLogin(app: Express, deps: Deps): void {
  app.post(
    '/api/v1/auth/login',
    rateLimit(deps, 'auth'),
    asyncRoute(async (req, res) => {
      // One deployment hosts one organisation; its id need not be compiled
      // into a device or entered during the ordinary first sign-in.
      const body = req.body as Record<string, unknown>;
      const organisations = await deps.store.orgs();
      const organisationId =
        typeof body['organisationId'] === 'string'
          ? body['organisationId']
          : organisations.length === 1
            ? organisations[0]?.id
            : undefined;
      if (!organisationId) throw invalidCredentials();
      const tokens = await login(deps.store, deps.config, {
        email: field(req.body, 'email'),
        password: field(req.body, 'password'),
        deviceId: field(req.body, 'deviceId'),
        organisationId,
      });
      res.json(tokens);
    }),
  );
}
