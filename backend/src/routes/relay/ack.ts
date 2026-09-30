import type { Express } from 'express';
import { invalidRequest } from '../../domain/errors.js';
import type { Deps } from '../../deps.js';
import { asyncRoute, objectBody } from '../../http.js';
import { authenticate } from '../../middleware/authenticate.js';
import { acknowledge } from '../../services/relay/packages.js';

export function registerRelayAck(app: Express, deps: Deps): void {
  app.post(
    '/api/v1/relay/ack',
    authenticate(deps),
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      if (principal === undefined) throw invalidRequest('Missing session.');
      const key = req.header('idempotency-key');
      if (key === undefined || key.length === 0)
        throw invalidRequest('Missing Idempotency-Key.');
      const body = objectBody(req.body, ['packageIds']);
      if (
        !Array.isArray(body.packageIds) ||
        body.packageIds.some((id) => typeof id !== 'string')
      ) {
        throw invalidRequest('Missing package ids.');
      }
      const result = await acknowledge(
        deps.store,
        principal,
        body.packageIds as string[],
        key,
        deps.metrics,
      );
      res.json(result);
    }),
  );
}
