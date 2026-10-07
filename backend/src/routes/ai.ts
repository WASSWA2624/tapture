import express, { type Express } from 'express';
import { invalidRequest } from '../domain/errors.js';
import type { Deps } from '../deps.js';
import { asyncRoute, objectBody, pageQuery } from '../http.js';
import { authenticate } from '../middleware/authenticate.js';
import { proxyAi, usageReport } from '../services/ai/proxy.js';
import {
  credentialStatus,
  deleteCredential,
  saveCredential,
} from '../services/ai/credentials.js';
import { providerCatalogue } from '../services/ai/provider-selection.js';
import { aiInput, providerName } from './ai-input.js';

/// AI routes parse their own JSON body, after authentication, with the larger
/// `aiBodyLimitBytes` limit. The global parser skips this prefix.
export const aiRoutePrefix = '/api/v1/ai/';

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
        const input = aiInput(req.body);
        const controller = new AbortController();
        const abort = () => {
          if (!res.writableEnded) controller.abort();
        };
        req.once('aborted', abort);
        res.once('close', abort);
        try {
          const result = await proxyAi(
            deps.store,
            deps.config,
            deps.provider,
            principal,
            method,
            { ...input, signal: controller.signal },
            deps.metrics,
            deps.providerFactory,
          );
          if (!res.destroyed) res.json(result);
        } finally {
          req.removeListener('aborted', abort);
          res.removeListener('close', abort);
        }
      }),
    );
  }
  const credentialPath = `${aiRoutePrefix}credentials/:provider`;
  app.get(
    credentialPath,
    auth,
    asyncRoute(async (req, res) => {
      if (req.principal === undefined) throw invalidRequest('Missing session.');
      res.json(
        await credentialStatus(
          deps.store,
          req.principal,
          providerName(req.params['provider']),
          deps.config,
        ),
      );
    }),
  );
  app.put(
    credentialPath,
    auth,
    express.json({ limit: deps.config.bodyLimitBytes }),
    asyncRoute(async (req, res) => {
      if (req.principal === undefined) throw invalidRequest('Missing session.');
      const row = objectBody(req.body, ['apiKey']);
      if (typeof row['apiKey'] !== 'string')
        throw invalidRequest('Enter a provider credential.');
      await saveCredential(
        deps.store,
        deps.config,
        req.principal,
        providerName(req.params['provider']),
        row['apiKey'],
      );
      res.status(204).end();
    }),
  );
  app.delete(
    credentialPath,
    auth,
    asyncRoute(async (req, res) => {
      if (req.principal === undefined) throw invalidRequest('Missing session.');
      await deleteCredential(
        deps.store,
        req.principal,
        providerName(req.params['provider']),
        deps.config,
      );
      res.status(204).end();
    }),
  );
  app.get(
    `${aiRoutePrefix}providers`,
    auth,
    asyncRoute(async (req, res) => {
      if (req.principal === undefined) throw invalidRequest('Missing session.');
      res.json(await providerCatalogue(deps.store, deps.config, req.principal));
    }),
  );
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
      if (
        !Number.isFinite(Date.parse(from)) ||
        !Number.isFinite(Date.parse(to)) ||
        Date.parse(from) > Date.parse(to)
      )
        throw invalidRequest('Invalid usage window.');
      res.json(
        await usageReport(deps.store, principal, {
          projectId: project,
          from: new Date(from).toISOString(),
          to: new Date(to).toISOString(),
          ...pageQuery(req.query),
        }),
      );
    }),
  );
}
