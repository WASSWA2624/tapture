import type { Principal } from '../domain/permissions.js';

declare global {
  namespace Express {
    interface Request {
      principal?: Principal;
    }
  }
}

export {};
