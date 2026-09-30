import type { Express } from 'express';
import { invalidRequest } from '../../domain/errors.js';
import type { Deps } from '../../deps.js';
import { asyncRoute, field, objectBody, optionalField } from '../../http.js';
import { authenticate } from '../../middleware/authenticate.js';
import { rateLimit } from '../../middleware/rate_limit.js';
import {
  changePassword,
  completeReset,
  requestReset,
} from '../../services/auth/account.js';

export function registerPassword(app: Express, deps: Deps): void {
  app.post(
    '/api/v1/auth/change-password',
    authenticate(deps),
    asyncRoute(async (req, res) => {
      objectBody(req.body, ['currentPassword', 'nextPassword']);
      const principal = req.principal;
      if (principal === undefined) throw invalidRequest('Missing session.');
      await changePassword(deps.store, deps.config, {
        userId: principal.userId,
        currentPassword: field(req.body, 'currentPassword'),
        nextPassword: field(req.body, 'nextPassword'),
      });
      res.status(204).end();
    }),
  );
  app.post(
    '/api/v1/auth/reset',
    rateLimit(deps, 'auth'),
    asyncRoute(async (req, res) => {
      objectBody(req.body, ['token', 'password', 'email', 'organisationId']);
      const token = optionalField(req.body, 'token');
      if (token !== undefined) {
        objectBody(req.body, ['token', 'password']);
        await completeReset(deps.store, deps.config, {
          token,
          password: field(req.body, 'password'),
        });
        res.json({ accepted: true });
        return;
      }
      objectBody(req.body, ['email', 'organisationId']);
      await requestReset(deps.store, {
        email: field(req.body, 'email'),
        organisationId: field(req.body, 'organisationId'),
      });
      res.json({ accepted: true });
    }),
  );
}
