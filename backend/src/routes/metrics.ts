import type { Express } from 'express';
import type { Deps } from '../deps.js';
import { asyncRoute } from '../http.js';

export function registerMetrics(app: Express, deps: Deps): void {
  app.get(
    '/metrics',
    asyncRoute(async (_req, res) => {
      deps.metrics.storageBytes = await deps.store.storageUsage();
      res.json(deps.metrics);
    }),
  );
}
