import type { Express } from 'express';
import { invalidRequest } from '../../domain/errors.js';
import type { Role } from '../../domain/permissions.js';
import type { Deps } from '../../deps.js';
import { asyncRoute } from '../../http.js';
import { authenticate } from '../../middleware/authenticate.js';
import { inviteUser, listUsers, patchUser } from '../../services/org/users.js';
import type { User } from '../../types/index.js';
const roles: readonly Role[] = [
  'administrator',
  'project_manager',
  'reviewer',
  'field_operator',
];
function isRole(value: unknown): value is Role {
  return typeof value === 'string' && roles.includes(value as Role);
}
export function registerOrgUsers(app: Express, deps: Deps): void {
  const auth = authenticate(deps);
  app.get(
    '/api/v1/org/users',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      if (principal === undefined) throw invalidRequest('Missing session.');
      const cursor = req.query['cursor'];
      const limit = req.query['limit'];
      res.json(
        await listUsers(deps.store, principal, {
          ...(typeof cursor === 'string' ? { cursor } : {}),
          ...(typeof limit === 'string' ? { limit: Number(limit) } : {}),
        }),
      );
    }),
  );
  app.post(
    '/api/v1/org/users',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      if (principal === undefined) throw invalidRequest('Missing session.');
      const body = req.body as {
        email?: unknown;
        role?: unknown;
      };
      if (typeof body.email !== 'string' || !isRole(body.role)) {
        throw invalidRequest('Missing email or role.');
      }
      const created = await inviteUser(deps.store, deps.config, principal, {
        email: body.email,
        role: body.role,
      });
      res
        .status(201)
        .location(`/api/v1/org/users/${created.userId}`)
        .json(created);
    }),
  );
  app.patch(
    '/api/v1/org/users/:id',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      if (principal === undefined) throw invalidRequest('Missing session.');
      const id = req.params['id'];
      if (id === undefined) throw invalidRequest('Missing user.');
      const body = req.body as {
        role?: unknown;
        status?: unknown;
        password?: unknown;
      };
      if (body.password !== undefined)
        throw invalidRequest('A password cannot be set here.');
      const patch: {
        role?: Role;
        status?: User['status'];
      } = {};
      if (body.role !== undefined) {
        if (!isRole(body.role)) throw invalidRequest('Unknown role.');
        patch.role = body.role;
      }
      if (body.status !== undefined) {
        if (
          body.status !== 'active' &&
          body.status !== 'disabled' &&
          body.status !== 'invited'
        ) {
          throw invalidRequest('Unknown status.');
        }
        patch.status = body.status;
      }
      await patchUser(deps.store, principal, id, patch);
      res.status(204).end();
    }),
  );
}
