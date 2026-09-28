import express, { type Express } from 'express';
import { invalidRequest } from '../domain/errors.js';
import type { Deps } from '../deps.js';
import { asyncRoute } from '../http.js';
import { authenticate } from '../middleware/authenticate.js';
import { proxyAi, usageReport } from '../services/ai/proxy.js';

/// AI routes parse their own JSON body, after authentication, with the larger
/// `aiBodyLimitBytes` limit. The global parser skips this prefix.
export const aiRoutePrefix = '/api/v1/ai/';

function payload(body: unknown): {
  projectId: string;
  model: string;
  payload: Buffer;
} {
  const record = body as {
    projectId?: unknown;
    model?: unknown;
    payload?: unknown;
  };
  if (
    typeof record.projectId !== 'string' ||
    typeof record.model !== 'string'
  ) {
    throw invalidRequest('Missing project or model.');
  }
  return {
    projectId: record.projectId,
    model: record.model,
    payload: envelope(record.payload),
  };
}

/// The provider envelope as bytes. The app sends it as a JSON object with its
/// media base64-encoded once; a base64 string is still accepted from older
/// clients.
function envelope(value: unknown): Buffer {
  if (typeof value === 'string') return Buffer.from(value, 'base64');
  if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
    return Buffer.from(JSON.stringify(value), 'utf8');
  }
  throw invalidRequest('Missing payload.');
}
/// Registers the AI proxy. Bodies are read only after authentication succeeds.
export function registerAi(app: Express, deps: Deps): void {
  const auth = authenticate(deps);
  const json = express.json({ limit: deps.config.aiBodyLimitBytes });
  for (const method of ['extract', 'ocr', 'transcribe', 'refine'] as const) {
    app.post(
      `${aiRoutePrefix}${method}`,
      auth,
      json,
      asyncRoute(async (req, res) => {
        const principal = req.principal;
        if (principal === undefined) throw invalidRequest('Missing session.');
        const input = payload(req.body);
        const result = await proxyAi(
          deps.store,
          deps.config,
          deps.provider,
          principal,
          method,
          input,
        );
        deps.metrics.aiRequests += 1;
        deps.metrics.aiCost += input.payload.length / 1000;
        res.json(result);
      }),
    );
  }
  app.get(
    `${aiRoutePrefix}usage`,
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      if (principal === undefined) throw invalidRequest('Missing session.');
      const project = req.query['project'];
      const from = req.query['from'];
      const to = req.query['to'];
      if (
        typeof project !== 'string' ||
        typeof from !== 'string' ||
        typeof to !== 'string'
      ) {
        throw invalidRequest('Missing usage window.');
      }
      res.json(
        await usageReport(deps.store, principal, {
          projectId: project,
          from,
          to,
        }),
      );
    }),
  );
}
