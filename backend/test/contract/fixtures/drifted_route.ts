import express, { type Express } from 'express';

/// Method and response drift the contract suite must reject independently.
export function driftedApp(): Express {
  const app = express();
  app.post('/health', (_req, res) => res.json({ status: 'ok' }));
  app.get('/health', (_req, res) =>
    res.json({ status: 7, recordText: 'forbidden' }),
  );
  return app;
}
