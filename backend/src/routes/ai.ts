import type { Express } from 'express';
import { invalidRequest } from '../domain/errors.js';
import type { Deps } from '../deps.js';
import { asyncRoute } from '../http.js';
import { authenticate } from '../middleware/authenticate.js';
import { proxyAi, usageReport } from '../services/ai/proxy.js';

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
  if (typeof record.payload !== 'string')
    throw invalidRequest('Missing payload.');
  return {
    projectId: record.projectId,
    model: record.model,
    payload: Buffer.from(record.payload, 'base64'),
  };
}

export function registerAi(app: Express, deps: Deps): void {
  const auth = authenticate(deps);
  for (const method of ['extract', 'ocr', 'transcribe', 'refine'] as const) {
    app.post(
      `/api/v1/ai/${method}`,
      auth,
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
    '/api/v1/ai/usage',
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
        usageReport(deps.store, principal, { projectId: project, from, to }),
      );
    }),
  );
}
