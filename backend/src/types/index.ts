export type {
  Principal,
  Role,
  Capability,
  Scope,
} from '../domain/permissions.js';
export type { AppConfig } from '../config/schema.js';

export interface Organisation {
  id: string;
  name: string;
  selfRegister: boolean;
  retentionDays: number;
}

export interface User {
  id: string;
  organisationId: string;
  email: string;
  passwordHash: string;
  role: import('../domain/permissions.js').Role;
  status: 'active' | 'disabled' | 'invited';
}

export interface Device {
  id: string;
  userId: string;
  enrolledAt: string;
  lastSeenAt: string;
  revoked: boolean;
}

export interface Project {
  id: string;
  organisationId: string;
  name: string;
  relayEnabled: boolean;
  neverRelay: boolean;
  retentionDays: number;
}

export interface Membership {
  projectId: string;
  userId: string;
  contextScope: string | null;
}

export interface RelayPackage {
  id: string;
  projectId: string;
  authorDeviceId: string;
  byteSize: number;
  createdAt: string;
  expiresAt: string;
  storageRef: string;
}

export interface AuditEvent {
  id: string;
  at: string;
  actorId: string;
  action: string;
  target: string;
  before: Record<string, unknown> | null;
  after: Record<string, unknown> | null;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}
