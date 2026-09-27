import type { Express } from 'express';
import { invalidRequest } from '../../domain/errors.js';
import type { Deps } from '../../deps.js';
import { asyncRoute } from '../../http.js';
import { authenticate } from '../../middleware/authenticate.js';
import { listPackages, readPackage } from '../../services/relay/packages.js';

export function registerRelayFetch(app: Express, deps: Deps): void {
  const auth = authenticate(deps);
  app.get(
    '/api/v1/projects/:id/relay/packages',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      const id = req.params['id'];
      if (principal === undefined || id === undefined)
        throw invalidRequest('Missing project.');
      const cursor = req.query['cursor'];
      const limit = req.query['limit'];
      res.json(
        listPackages(deps.store, principal, id, {
          ...(typeof cursor === 'string' ? { cursor } : {}),
          ...(typeof limit === 'string' ? { limit: Number(limit) } : {}),
        }),
      );
    }),
  );
  app.get(
    '/api/v1/projects/:id/relay/packages/:packageId',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      const id = req.params['id'];
      const packageId = req.params['packageId'];
      if (
        principal === undefined ||
        id === undefined ||
        packageId === undefined
      ) {
        throw invalidRequest('Missing package.');
      }
      const found = readPackage(deps.store, principal, id, packageId);
      res.setHeader('content-type', 'application/octet-stream');
      res.send(found.bytes);
    }),
  );
}
