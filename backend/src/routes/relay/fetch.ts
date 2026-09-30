import type { Express } from 'express';
import { invalidRequest } from '../../domain/errors.js';
import type { Deps } from '../../deps.js';
import { asyncRoute, pageQuery } from '../../http.js';
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
      res.json(
        await listPackages(deps.store, principal, id, pageQuery(req.query)),
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
      const found = await readPackage(deps.store, principal, id, packageId);
      res.setHeader('content-type', 'application/octet-stream');
      res.send(found.bytes);
    }),
  );
}
