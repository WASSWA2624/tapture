import type { Express } from 'express';
import { invalidRequest } from '../domain/errors.js';
import type { Deps } from '../deps.js';
import { asyncRoute, objectBody } from '../http.js';
import { authenticate } from '../middleware/authenticate.js';
import {
  addMember,
  createProject,
  listMembers,
  listProjects,
  patchProject,
  removeMember,
} from '../services/projects.js';
export function registerProjects(app: Express, deps: Deps): void {
  const auth = authenticate(deps);
  app.get(
    '/api/v1/projects',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      if (principal === undefined) throw invalidRequest('Missing session.');
      res.json(await listProjects(deps.store, principal));
    }),
  );
  app.post(
    '/api/v1/projects',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      if (principal === undefined) throw invalidRequest('Missing session.');
      const body = objectBody(req.body, ['id', 'name']);
      if (
        typeof body.id !== 'string' ||
        body.id.length === 0 ||
        typeof body.name !== 'string' ||
        body.name.length === 0
      ) {
        throw invalidRequest('Missing project id or name.');
      }
      const project = await createProject(deps.store, principal, {
        id: body.id,
        name: body.name,
      });
      res.status(201).location(`/api/v1/projects/${project.id}`).json(project);
    }),
  );
  app.patch(
    '/api/v1/projects/:id',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      if (principal === undefined) throw invalidRequest('Missing session.');
      const id = req.params['id'];
      if (id === undefined) throw invalidRequest('Missing project.');
      const body = objectBody(req.body, [
        'name',
        'relayEnabled',
        'neverRelay',
        'retentionDays',
      ]);
      if (body.id !== undefined)
        throw invalidRequest('The project id cannot change.');
      if (
        (body.name !== undefined &&
          (typeof body.name !== 'string' || body.name.length === 0)) ||
        (body.relayEnabled !== undefined &&
          typeof body.relayEnabled !== 'boolean') ||
        (body.neverRelay !== undefined &&
          typeof body.neverRelay !== 'boolean') ||
        (body.retentionDays !== undefined &&
          (typeof body.retentionDays !== 'number' ||
            !Number.isSafeInteger(body.retentionDays)))
      )
        throw invalidRequest('Invalid project settings.');
      const patch: {
        name?: string;
        relayEnabled?: boolean;
        neverRelay?: boolean;
        retentionDays?: number;
      } = {};
      if (typeof body.name === 'string') patch.name = body.name;
      if (typeof body.relayEnabled === 'boolean')
        patch.relayEnabled = body.relayEnabled;
      if (typeof body.neverRelay === 'boolean')
        patch.neverRelay = body.neverRelay;
      if (typeof body.retentionDays === 'number')
        patch.retentionDays = body.retentionDays;
      const project = await patchProject(
        deps.store,
        deps.config,
        principal,
        id,
        patch,
      );
      res.json(project);
    }),
  );
  app.get(
    '/api/v1/projects/:id/members',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      const id = req.params['id'];
      if (principal === undefined || id === undefined)
        throw invalidRequest('Missing project.');
      res.json(await listMembers(deps.store, principal, id));
    }),
  );
  app.post(
    '/api/v1/projects/:id/members',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      const id = req.params['id'];
      if (principal === undefined || id === undefined)
        throw invalidRequest('Missing project.');
      const body = objectBody(req.body, ['userId', 'contextScope']);
      if (typeof body.userId !== 'string')
        throw invalidRequest('Missing user.');
      if (
        body.contextScope !== undefined &&
        body.contextScope !== null &&
        typeof body.contextScope !== 'string'
      )
        throw invalidRequest('Invalid context scope.');
      await addMember(deps.store, principal, id, {
        userId: body.userId,
        contextScope:
          typeof body.contextScope === 'string' ? body.contextScope : null,
      });
      res
        .status(201)
        .location(`/api/v1/projects/${id}/members/${body.userId}`)
        .json({
          userId: body.userId,
        });
    }),
  );
  app.delete(
    '/api/v1/projects/:id/members/:userId',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      const id = req.params['id'];
      const userId = req.params['userId'];
      if (principal === undefined || id === undefined || userId === undefined) {
        throw invalidRequest('Missing member.');
      }
      await removeMember(deps.store, principal, id, userId);
      res.status(204).end();
    }),
  );
}
