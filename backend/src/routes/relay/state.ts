import type { Express } from 'express';
import { invalidRequest } from '../../domain/errors.js';
import type { Deps } from '../../deps.js';
import { asyncRoute } from '../../http.js';
import { authenticate } from '../../middleware/authenticate.js';
import { relayState } from '../../services/relay/packages.js';
export function registerRelayState(app: Express, deps: Deps): void {
  app.get(
    '/api/v1/projects/:id/relay/state',
    authenticate(deps),
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      const id = req.params['id'];
      if (principal === undefined || id === undefined)
        throw invalidRequest('Missing project.');
      res.json(await relayState(deps.store, principal, id));
    }),
  );
}
