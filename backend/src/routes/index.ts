import type { Express } from 'express';
import type { Deps } from '../deps.js';
import { registerAi } from './ai.js';
import { registerLogin } from './auth/login.js';
import { registerMe } from './auth/me.js';
import { registerPassword } from './auth/password.js';
import { registerRegister } from './auth/register.js';
import { registerSession } from './auth/session.js';
import { registerDevices } from './devices.js';
import { registerHealth } from './health.js';
import { registerMetrics } from './metrics.js';
import { registerOrgUsers } from './org/users.js';
import { registerProjects } from './projects.js';
import { registerRelayAck } from './relay/ack.js';
import { registerRelayFetch } from './relay/fetch.js';
import { registerRelayPush } from './relay/push.js';
import { registerRelayState } from './relay/state.js';

export function registerRoutes(app: Express, deps: Deps): void {
  registerHealth(app, deps);
  registerRegister(app, deps);
  registerPassword(app, deps);
  registerLogin(app, deps);
  registerSession(app, deps);
  registerMe(app, deps);
  registerDevices(app, deps);
  registerOrgUsers(app, deps);
  registerProjects(app, deps);
  registerRelayPush(app, deps);
  registerRelayFetch(app, deps);
  registerRelayAck(app, deps);
  registerRelayState(app, deps);
  registerAi(app, deps);
  registerMetrics(app, deps);
}
