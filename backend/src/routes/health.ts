import type { Express } from 'express';
import { internalError } from '../domain/errors.js';
import type { Deps } from '../deps.js';
import { asyncRoute } from '../http.js';

export function registerHealth(app: Express, deps: Deps): void {
  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' });
  });
  app.get(
    '/ready',
    asyncRoute(async (_req, res) => {
      const connected = await deps.pool.probe();
      if (!connected || deps.pool.status().draining || !deps.config.ready) {
        throw internalError();
      }
      res.json({ status: 'ready' });
    }),
  );
  app.get('/version', (_req, res) => {
    res.json({
      apiVersion: deps.config.apiVersion,
      build: deps.config.buildVersion,
    });
  });
}
