import type { Express } from 'express';
import type { Deps } from '../deps.js';

export function registerMetrics(app: Express, deps: Deps): void {
  app.get('/metrics', (_req, res) => {
    res.json(deps.metrics);
  });
}
