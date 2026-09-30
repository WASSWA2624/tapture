import type { Express } from 'express';
import { invalidRequest } from '../../domain/errors.js';
import type { Deps } from '../../deps.js';
import { asyncRoute } from '../../http.js';
import { authenticate } from '../../middleware/authenticate.js';
import { uploadPackage } from '../../services/relay/packages.js';

export function registerRelayPush(app: Express, deps: Deps): void {
  app.post(
    '/api/v1/projects/:id/relay/packages',
    authenticate(deps),
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      const id = req.params['id'];
      if (principal === undefined || id === undefined)
        throw invalidRequest('Missing project.');
      const key = req.header('idempotency-key');
      if (key === undefined || key.length === 0) {
        throw invalidRequest('Missing Idempotency-Key.');
      }
      const bytes = Buffer.isBuffer(req.body) ? req.body : Buffer.from([]);
      const row = await uploadPackage(
        deps.store,
        deps.config,
        principal,
        id,
        bytes,
        key,
        deps.metrics,
      );
      res
        .status(201)
        .location(`/api/v1/projects/${id}/relay/packages/${row.id}`)
        .json(row);
    }),
  );
}
