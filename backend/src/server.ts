import { pathToFileURL } from 'node:url';
import express, { type Express } from 'express';
import { parseConfig } from './config/schema.js';
import type { Deps } from './deps.js';
import { createPool } from './db/pool.js';
import { invalidRequest } from './domain/errors.js';
import { errorHandler } from './middleware/error_handler.js';
import { rateLimit } from './middleware/rate_limit.js';
import { requestContextMiddleware } from './middleware/request_context.js';
import { securityHeaders } from './middleware/security_headers.js';
import { log } from './observability/logger.js';
import { Store } from './repositories/store.js';
import { registerRoutes } from './routes/index.js';
import { fakeProvider } from './services/ai/provider.js';
import { emptyMetrics, noteRequest } from './services/metrics/metrics.js';

/// Builds the process. Middleware order is fixed.
export function createApp(deps: Deps): Express {
  const app = express();
  app.disable('x-powered-by');
  app.use(requestContextMiddleware);
  app.use((req, res, next) => {
    if (req.is('application/octet-stream')) {
      express.raw({
        type: 'application/octet-stream',
        limit: deps.config.packageMaxBytes,
      })(req, res, next);
      return;
    }
    express.json({ limit: deps.config.bodyLimitBytes })(req, res, next);
  });
  app.use(securityHeaders);
  app.use((req, _res, next) => {
    const client = req.header('x-api-version');
    if (client !== undefined && client !== deps.config.apiVersion) {
      next(
        invalidRequest(
          `This server speaks API version ${deps.config.apiVersion}, not ${client}.`,
        ),
      );
      return;
    }
    next();
  });
  app.use(rateLimit(deps, 'general'));
  app.use((req, res, next) => {
    const started = Date.now();
    res.on('finish', () => {
      noteRequest(
        deps.metrics,
        req.path,
        Date.now() - started,
        res.statusCode >= 400,
      );
      if (res.statusCode === 401) deps.metrics.authFailures += 1;
    });
    next();
  });
  registerRoutes(app, deps);
  app.use(errorHandler);
  return app;
}

export async function shutdown(
  deps: Deps,
  server: ReturnType<Express['listen']>,
): Promise<void> {
  await new Promise<void>((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
  await deps.pool.drain();
}

export function listen(deps: Deps): Promise<ReturnType<Express['listen']>> {
  const app = createApp(deps);
  return new Promise((resolve) => {
    const server = app.listen(deps.config.port, () => resolve(server));
  });
}

async function main(): Promise<void> {
  const config = parseConfig(process.env);
  const deps: Deps = {
    store: new Store(),
    config,
    pool: createPool(config),
    provider: fakeProvider('ok'),
    metrics: emptyMetrics(),
    log,
  };
  await listen(deps);
  log.info('listening', { port: config.port });
}

const entry = process.argv[1];
if (entry !== undefined && import.meta.url === pathToFileURL(entry).href) {
  main().catch((error: unknown) => {
    const message = error instanceof Error ? error.message : 'boot failed';
    process.stderr.write(`${message}\n`);
    process.exit(1);
  });
}
