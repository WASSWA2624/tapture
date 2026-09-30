import type { Express } from 'express';
import type { Deps } from '../../deps.js';
import { asyncRoute, field, objectBody, optionalField } from '../../http.js';
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
      const body = objectBody(req.body, [
        'email',
        'password',
        'deviceId',
        'organisationId',
      ]);
      let organisationId = optionalField(body, 'organisationId');
      if (organisationId === undefined) {
        const organisations = await deps.store.orgs();
        if (organisations.length === 1) organisationId = organisations[0]?.id;
      }
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
