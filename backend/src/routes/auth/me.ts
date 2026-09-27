import type { Express } from 'express';
import { invalidRequest } from '../../domain/errors.js';
import type { Deps } from '../../deps.js';
import { asyncRoute } from '../../http.js';
import { authenticate } from '../../middleware/authenticate.js';

export function registerMe(app: Express, deps: Deps): void {
  app.get(
    '/api/v1/auth/me',
    authenticate(deps),
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      if (principal === undefined) throw invalidRequest('Missing session.');
      const user = deps.store
        .users()
        .find((row) => row.id === principal.userId);
      if (user === undefined) throw invalidRequest('Missing session.');
      const grants = deps.store
        .members()
        .filter((row) => row.userId === user.id)
        .map((row) => ({
          projectId: row.projectId,
          contextScope: row.contextScope,
        }));
      res.json({
        userId: user.id,
        organisationId: user.organisationId,
        role: user.role,
        grants,
        grantValidUntil: new Date(
          Date.now() + deps.config.refreshTtlSeconds * 1000,
        ).toISOString(),
      });
    }),
  );
}
