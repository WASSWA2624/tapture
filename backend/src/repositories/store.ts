import { randomUUID } from 'node:crypto';
import { AsyncLocalStorage } from 'node:async_hooks';
import { conflict } from '../domain/errors.js';
import type { Role } from '../domain/permissions.js';
import type { Repository } from './repository.js';
import type {
  AuditEvent,
  Device,
  Membership,
  Organisation,
  Project,
  RelayPackage,
  User,
} from '../types/index.js';

export interface RefreshFamily {
  id: string;
  userId: string;
  deviceId: string;
  tokenHash: string;
  rotated: boolean;
  revoked: boolean;
  expiresAt: string;
}

export interface Ack {
  packageId: string;
  deviceId: string;
}

export interface Invite {
  tokenHash: string;
  userId: string;
  used: boolean;
  expiresAt: string;
}

export interface UsageRow {
  projectId: string;
  userId: string;
  model: string;
  byteSize: number;
  durationMs: number;
  outcome: string;
  cost: number;
  at: string;
}

export interface IdempotentResult {
  status: number;
  body: unknown;
}

interface Snapshot {
  orgs: Organisation[];
  users: User[];
  devices: Device[];
  projects: Project[];
  members: Membership[];
  packages: RelayPackage[];
  blobs: Array<{ ref: string; bytes: Buffer }>;
  acks: Ack[];
  vectors: Array<{ projectId: string; deviceId: string; counter: number }>;
  audit: AuditEvent[];
  security: AuditEvent[];
  invites: Invite[];
  refresh: RefreshFamily[];
  usage: UsageRow[];
  idempotency: Array<{ key: string; result: IdempotentResult }>;
  lockouts: Array<{ key: string; failures: number; until: string | null }>;
  schema: Array<{ name: string; checksum: string }>;
}

function clone(snapshot: Snapshot): Snapshot {
  return structuredClone(snapshot);
}

/// In-memory repository for deterministic tests. Production uses Postgres.
export class Store {
  private data: Snapshot = {
    orgs: [],
    users: [],
    devices: [],
    projects: [],
    members: [],
    packages: [],
    blobs: [],
    acks: [],
    vectors: [],
    audit: [],
    security: [],
    invites: [],
    refresh: [],
    usage: [],
    idempotency: [],
    lockouts: [],
    schema: [],
  };

  private readonly transactionContext = new AsyncLocalStorage<boolean>();
  private pending: Promise<void> = Promise.resolve();

  async withTransaction<T>(
    work: (store: Repository) => Promise<T>,
  ): Promise<T> {
    if (this.transactionContext.getStore()) return work(this);
    const previous = this.pending;
    let release: () => void = () => undefined;
    this.pending = new Promise<void>((resolve) => {
      release = resolve;
    });
    await previous;
    const snapshot = clone(this.data);
    try {
      return await this.transactionContext.run(true, () => work(this));
    } catch (error) {
      this.data = snapshot;
      throw error;
    } finally {
      release();
    }
  }

  orgs(): Organisation[] {
    return this.data.orgs;
  }

  addOrg(org: Organisation): void {
    this.data.orgs.push(org);
  }

  users(): User[] {
    return this.data.users;
  }

  addUser(user: User): void {
    const taken = this.data.users.some(
      (row) =>
        row.organisationId === user.organisationId && row.email === user.email,
    );
    if (taken) throw conflict('An account with that address already exists.');
    this.data.users.push(user);
  }

  saveUser(user: User): void {
    this.data.users = this.data.users.map((row) =>
      row.id === user.id ? user : row,
    );
  }

  devices(): Device[] {
    return this.data.devices;
  }

  addDevice(device: Device): void {
    if (this.data.devices.some((row) => row.id === device.id)) {
      throw conflict('That device is already enrolled.');
    }
    this.data.devices.push(device);
  }

  saveDevice(device: Device): void {
    this.data.devices = this.data.devices.map((row) =>
      row.id === device.id ? device : row,
    );
  }

  projects(): Project[] {
    return this.data.projects;
  }

  addProject(project: Project): void {
    this.data.projects.push(project);
  }

  saveProject(project: Project): void {
    this.data.projects = this.data.projects.map((row) =>
      row.id === project.id ? project : row,
    );
  }

  members(): Membership[] {
    return this.data.members;
  }

  addMember(member: Membership): void {
    const taken = this.data.members.some(
      (row) =>
        row.projectId === member.projectId && row.userId === member.userId,
    );
    if (taken) throw conflict('That person is already a member.');
    this.data.members.push(member);
  }

  removeMember(projectId: string, userId: string): void {
    this.data.members = this.data.members.filter(
      (row) => !(row.projectId === projectId && row.userId === userId),
    );
  }

  packages(): RelayPackage[] {
    return this.data.packages;
  }

  addPackage(row: RelayPackage, bytes: Buffer): void {
    this.data.packages.push(row);
    this.data.blobs.push({ ref: row.storageRef, bytes });
  }

  removePackage(id: string): void {
    const row = this.data.packages.find((item) => item.id === id);
    this.data.packages = this.data.packages.filter((item) => item.id !== id);
    if (row !== undefined) {
      this.data.blobs = this.data.blobs.filter(
        (blob) => blob.ref !== row.storageRef,
      );
    }
  }

  blob(ref: string): Buffer | undefined {
    return this.data.blobs.find((row) => row.ref === ref)?.bytes;
  }

  acks(): Ack[] {
    return this.data.acks;
  }

  addAck(ack: Ack): void {
    const taken = this.data.acks.some(
      (row) => row.packageId === ack.packageId && row.deviceId === ack.deviceId,
    );
    if (!taken) this.data.acks.push(ack);
  }

  vectors(): Snapshot['vectors'] {
    return this.data.vectors;
  }

  bumpVector(projectId: string, deviceId: string): number {
    const row = this.data.vectors.find(
      (item) => item.projectId === projectId && item.deviceId === deviceId,
    );
    if (row === undefined) {
      this.data.vectors.push({ projectId, deviceId, counter: 1 });
      return 1;
    }
    row.counter += 1;
    return row.counter;
  }

  audit(): AuditEvent[] {
    return this.data.audit;
  }

  security(): AuditEvent[] {
    return this.data.security;
  }

  recordAudit(event: Omit<AuditEvent, 'id' | 'at'>): void {
    this.data.audit.push({
      id: randomUUID(),
      at: new Date().toISOString(),
      ...event,
    });
  }

  recordSecurity(event: Omit<AuditEvent, 'id' | 'at'>): void {
    this.data.security.push({
      id: randomUUID(),
      at: new Date().toISOString(),
      ...event,
    });
  }

  invites(): Invite[] {
    return this.data.invites;
  }

  addInvite(invite: Invite): void {
    this.data.invites.push(invite);
  }

  saveInvite(invite: Invite): void {
    this.data.invites = this.data.invites.map((row) =>
      row.tokenHash === invite.tokenHash ? invite : row,
    );
  }

  refresh(): RefreshFamily[] {
    return this.data.refresh;
  }

  addRefresh(row: RefreshFamily): void {
    this.data.refresh.push(row);
  }

  saveRefresh(row: RefreshFamily): void {
    this.data.refresh = this.data.refresh.map((item) =>
      item.id === row.id ? row : item,
    );
  }

  usage(): UsageRow[] {
    return this.data.usage;
  }

  addUsage(row: UsageRow): void {
    this.data.usage.push(row);
  }

  idempotency(key: string): IdempotentResult | undefined {
    return this.data.idempotency.find((row) => row.key === key)?.result;
  }

  saveIdempotency(key: string, result: IdempotentResult): void {
    this.data.idempotency.push({ key, result });
  }

  lockout(key: string): { failures: number; until: string | null } {
    return (
      this.data.lockouts.find((row) => row.key === key) ?? {
        failures: 0,
        until: null,
      }
    );
  }

  setLockout(key: string, failures: number, until: string | null): void {
    this.data.lockouts = this.data.lockouts.filter((row) => row.key !== key);
    this.data.lockouts.push({ key, failures, until });
  }

  schemaHistory(): Snapshot['schema'] {
    return this.data.schema;
  }

  recordMigration(name: string, checksum: string): void {
    this.data.schema.push({ name, checksum });
  }

  expiredPackages(now: Date, limit: number): RelayPackage[] {
    return this.data.packages
      .filter((row) => Date.parse(row.expiresAt) <= now.getTime())
      .sort((a, b) => a.expiresAt.localeCompare(b.expiresAt))
      .slice(0, limit);
  }

  destroyOrganisation(organisationId: string): string[] {
    const deleted: string[] = [];
    const userIds = new Set(
      this.data.users
        .filter((row) => row.organisationId === organisationId)
        .map((row) => row.id),
    );
    const projectIds = new Set(
      this.data.projects
        .filter((row) => row.organisationId === organisationId)
        .map((row) => row.id),
    );
    this.data.orgs = this.data.orgs.filter((row) => row.id !== organisationId);
    deleted.push('organisation');
    this.data.users = this.data.users.filter(
      (row) => row.organisationId !== organisationId,
    );
    deleted.push('users');
    this.data.devices = this.data.devices.filter(
      (row) => !userIds.has(row.userId),
    );
    deleted.push('devices');
    this.data.projects = this.data.projects.filter(
      (row) => row.organisationId !== organisationId,
    );
    deleted.push('projects');
    this.data.members = this.data.members.filter(
      (row) => !projectIds.has(row.projectId),
    );
    deleted.push('memberships');
    const packageIds = new Set(
      this.data.packages
        .filter((row) => projectIds.has(row.projectId))
        .map((row) => row.id),
    );
    this.data.packages = this.data.packages.filter(
      (row) => !projectIds.has(row.projectId),
    );
    deleted.push('package-metadata');
    this.data.acks = this.data.acks.filter(
      (row) => !packageIds.has(row.packageId),
    );
    this.data.refresh = this.data.refresh.filter(
      (row) => !userIds.has(row.userId),
    );
    return deleted;
  }

  seedRole(email: string, role: Role): void {
    const user = this.data.users.find((row) => row.email === email);
    if (user !== undefined) user.role = role;
  }
}
