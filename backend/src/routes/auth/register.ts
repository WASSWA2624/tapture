import type { Express } from 'express';
import type { Deps } from '../../deps.js';
import { asyncRoute, field, optionalField } from '../../http.js';
import { rateLimit } from '../../middleware/rate_limit.js';
import { registerAccount } from '../../services/auth/account.js';

export function registerRegister(app: Express, deps: Deps): void {
  app.post(
    '/api/v1/auth/register',
    rateLimit(deps, 'auth'),
    asyncRoute(async (req, res) => {
      const invitationToken = optionalField(req.body, 'invitationToken');
      const created = await registerAccount(deps.store, deps.config, {
        email: field(req.body, 'email'),
        password: field(req.body, 'password'),
        organisationId: field(req.body, 'organisationId'),
        ...(invitationToken !== undefined ? { invitationToken } : {}),
      });
      res
        .status(201)
        .location(`/api/v1/org/users/${created.userId}`)
        .json(created);
    }),
  );
}
