import type { Express } from 'express';
import { invalidRequest } from '../domain/errors.js';
import type { Deps } from '../deps.js';
import { asyncRoute } from '../http.js';
import { authenticate } from '../middleware/authenticate.js';
import { listDevices, revokeDevice } from '../services/auth/devices.js';

export function registerDevices(app: Express, deps: Deps): void {
  const auth = authenticate(deps);
  app.post(
    '/api/v1/devices',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      if (principal === undefined) throw invalidRequest('Missing session.');
      const existing = deps.store
        .devices()
        .find((row) => row.id === principal.deviceId);
      res
        .status(201)
        .location(`/api/v1/devices/${principal.deviceId}`)
        .json(existing);
    }),
  );
  app.get(
    '/api/v1/devices',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      if (principal === undefined) throw invalidRequest('Missing session.');
      res.json(listDevices(deps.store, principal));
    }),
  );
  app.delete(
    '/api/v1/devices/:id',
    auth,
    asyncRoute(async (req, res) => {
      const principal = req.principal;
      if (principal === undefined) throw invalidRequest('Missing session.');
      const id = req.params['id'];
      if (id === undefined) throw invalidRequest('Missing device.');
      await revokeDevice(deps.store, principal, id);
      res.status(204).end();
    }),
  );
}
