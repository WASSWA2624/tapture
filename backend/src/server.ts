import { pathToFileURL } from 'node:url';
import express, { type Express } from 'express';
import type { Deps } from './deps.js';
import { createPool } from './db/pool.js';
import { invalidRequest, notFound } from './domain/errors.js';
import { cors } from './middleware/cors.js';
import { errorHandler } from './middleware/error_handler.js';
import { rateLimit } from './middleware/rate_limit.js';
import { requestContextMiddleware } from './middleware/request_context.js';
import { securityHeaders } from './middleware/security_headers.js';
import { log } from './observability/logger.js';
import { createPostgresRepository } from './repositories/postgres.js';
import { schedulePurge } from './jobs/schedule_purge.js';
import { aiRoutePrefix } from './routes/ai.js';
import { registerRoutes } from './routes/index.js';
import { httpProvider } from './services/ai/http_provider.js';
import { emptyMetrics, noteRequest } from './services/metrics/metrics.js';
import { warmPasswordVerification } from './services/auth/password.js';
import { auditConfiguration } from './services/configuration.js';

/// Builds the process. Middleware order is fixed: CORS precedes body parsing,
/// authentication and rate limiting so every answer carries its headers.
export function createApp(deps: Deps): Express {
  const app = express();
  app.disable('x-powered-by');
  app.use(requestContextMiddleware);
  app.use((req, res, next) => {
    const started = Date.now();
    res.on('finish', () => {
      noteRequest(
        deps.metrics,
        // One bounded label per registered route, not one per project/device
        // identifier or arbitrary URL an unauthenticated caller can invent.
        typeof (req.route as { path?: unknown } | undefined)?.path === 'string'
          ? (req.route as { path: string }).path
          : 'unmatched',
        Date.now() - started,
        res.statusCode >= 400,
      );
      if (res.statusCode === 401) deps.metrics.authFailures += 1;
    });
    next();
  });
  app.use(securityHeaders);
  app.use(cors(deps.config));
  const raw = express.raw({
    type: 'application/octet-stream',
    limit: deps.config.packageMaxBytes,
  });
  const json = express.json({ limit: deps.config.bodyLimitBytes });
  app.use((req, res, next) => {
    if (req.path.toLowerCase().startsWith(aiRoutePrefix)) {
      // AI routes parse after authentication with their own, larger limit.
      next();
      return;
    }
    if (req.is('application/octet-stream')) {
      raw(req, res, next);
      return;
    }
    json(req, res, next);
  });
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
  registerRoutes(app, deps);
  app.use((_req, _res, next) => next(notFound()));
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

export async function listen(
  deps: Deps,
): Promise<ReturnType<Express['listen']>> {
  await warmPasswordVerification(deps.config);
  const app = createApp(deps);
  return new Promise((resolve) => {
    const server = app.listen(deps.config.port, () => resolve(server));
  });
}

async function main(): Promise<void> {
  const { config } = await import('./config/index.js');
  if (!/^postgres(?:ql)?:\/\//.test(config.databaseUrl)) {
    throw new Error(
      'DATABASE_URL must use PostgreSQL when running the server.',
    );
  }
  const pool = createPool(config);
  if (!(await pool.probe())) {
    await pool.drain();
    throw new Error(
      'Database unavailable. Check DATABASE_URL before starting.',
    );
  }
  const store = createPostgresRepository(pool);
  if (
    !(await store.schemaHistory()).some(
      (row) => row.name === '009_transient_retention.sql',
    )
  ) {
    await pool.drain();
    throw new Error(
      'Database schema is outdated. Run the explicit admin migrate command.',
    );
  }
  const deps: Deps = {
    store,
    config,
    pool,
    provider: httpProvider(config),
    metrics: emptyMetrics(),
    log,
  };
  await auditConfiguration(store, config);
  deps.metrics.storageBytes = await store.storageUsage();
  const server = await listen(deps);
  const stopPurge = schedulePurge(deps);
  let stopping = false;
  const stop = () => {
    if (stopping) return;
    stopping = true;
    void stopPurge()
      .then(() => shutdown(deps, server))
      .catch(() => {
        log.error('shutdown_failed', { outcome: 'failed' });
        process.exitCode = 1;
      });
  };
  process.once('SIGTERM', stop);
  process.once('SIGINT', stop);
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
