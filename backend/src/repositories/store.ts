import { randomUUID } from 'node:crypto';
import { AsyncLocalStorage } from 'node:async_hooks';
import { conflict } from '../domain/errors.js';
import type { Role } from '../domain/permissions.js';
import type { Repository } from './repository.js';
import { emptyUsageTotals, type QuotaUsage, type UsageRow } from './usage.js';
import type { RuntimeSetting } from './settings.js';
export type { UsageRow } from './usage.js';
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
  familyId: string;
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
  purpose: 'invitation' | 'password_reset';
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
  usage: Array<UsageRow & { id: string }>;
  idempotency: Array<{
    key: string;
    result: IdempotentResult;
    expiresAt: string;
  }>;
  lockouts: Array<{
    key: string;
    failures: number;
    until: string | null;
    expiresAt: string;
  }>;
  schema: Array<{ name: string; checksum: string }>;
  settings: RuntimeSetting[];
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
    settings: [],
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

  applyRetention(days: number): void {
    this.data.orgs = this.data.orgs.map((row) => ({
      ...row,
      retentionDays: days,
    }));
    this.data.projects = this.data.projects.map((row) => ({
      ...row,
      retentionDays: Math.min(row.retentionDays, days),
    }));
    this.data.packages = this.data.packages.map((row) => ({
      ...row,
      expiresAt: new Date(
        Math.min(
          Date.parse(row.expiresAt),
          Date.parse(row.createdAt) + days * 24 * 60 * 60 * 1000,
        ),
      ).toISOString(),
    }));
  }

  users(): User[] {
    return this.data.users;
  }

  userById(id: string): User | undefined {
    return this.data.users.find((row) => row.id === id);
  }

  userByEmail(organisationId: string, email: string): User | undefined {
    return this.data.users.find(
      (row) =>
        row.organisationId === organisationId &&
        row.email.trim().toLowerCase() === email.trim().toLowerCase(),
    );
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

  deviceById(id: string): Device | undefined {
    return this.data.devices.find((row) => row.id === id);
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
    this.data.acks = this.data.acks.filter((item) => item.packageId !== id);
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
      after: { outcome: 'applied', ...event.after },
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

  refreshByHash(hash: string): RefreshFamily | undefined {
    return this.data.refresh.find((row) => row.tokenHash === hash);
  }

  refreshForFamily(id: string): RefreshFamily[] {
    return this.data.refresh.filter((row) => row.familyId === id);
  }

  refreshForUser(id: string): RefreshFamily[] {
    return this.data.refresh.filter((row) => row.userId === id);
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
    return this.data.usage.map(({ id: _id, ...row }) => row);
  }

  addUsage(row: UsageRow): string {
    const id = randomUUID();
    this.data.usage.push({ ...row, id });
    return id;
  }

  finishUsage(
    id: string,
    outcome: string,
    durationMs: number,
    model: string,
  ): void {
    this.data.usage = this.data.usage.map((row) =>
      row.id === id ? { ...row, outcome, durationMs, model } : row,
    );
  }

  quotaUsage(
    organisationId: string,
    projectId: string,
    dayFrom: string,
    dayTo: string,
  ): QuotaUsage {
    const projects = new Set(
      this.data.projects
        .filter((project) => project.organisationId === organisationId)
        .map((project) => project.id),
    );
    const result: QuotaUsage = {
      project: emptyUsageTotals(),
      organisation: emptyUsageTotals(),
    };
    for (const row of this.data.usage) {
      if (!projects.has(row.projectId)) continue;
      const totals = [result.organisation];
      if (row.projectId === projectId) totals.push(result.project);
      for (const total of totals) {
        total.requests += 1;
        total.cost += row.cost;
        if (row.at >= dayFrom && row.at < dayTo) {
          total.dailyRequests += 1;
          total.dailyCost += row.cost;
        }
      }
    }
    return result;
  }

  idempotency(key: string): IdempotentResult | undefined {
    return this.data.idempotency.find(
      (row) => row.key === key && Date.parse(row.expiresAt) > Date.now(),
    )?.result;
  }

  saveIdempotency(
    key: string,
    result: IdempotentResult,
    expiresAt = new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
  ): void {
    this.data.idempotency = this.data.idempotency.filter(
      (row) => row.key !== key,
    );
    this.data.idempotency.push({ key, result, expiresAt });
  }

  lockout(key: string): { failures: number; until: string | null } {
    return (
      this.data.lockouts.find(
        (row) => row.key === key && Date.parse(row.expiresAt) > Date.now(),
      ) ?? {
        failures: 0,
        until: null,
      }
    );
  }

  setLockout(
    key: string,
    failures: number,
    until: string | null,
    expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
  ): void {
    this.data.lockouts = this.data.lockouts.filter((row) => row.key !== key);
    if (failures > 0)
      this.data.lockouts.push({ key, failures, until, expiresAt });
  }

  schemaHistory(): Snapshot['schema'] {
    return this.data.schema;
  }

  runtimeSettings(): RuntimeSetting[] {
    return this.data.settings;
  }

  saveRuntimeSetting(row: RuntimeSetting): void {
    this.data.settings = this.data.settings.filter(
      (item) => item.name !== row.name,
    );
    this.data.settings.push(row);
  }

  storageUsage(): Record<string, number> {
    const totals: Record<string, number> = {};
    for (const row of this.data.packages)
      totals[row.projectId] = (totals[row.projectId] ?? 0) + row.byteSize;
    return totals;
  }

  relayQuotaUsage(
    organisationId: string,
    projectId: string,
  ): { projectBytes: number; organisationBytes: number } {
    const totals = this.storageUsage();
    return {
      projectBytes: totals[projectId] ?? 0,
      organisationBytes: this.data.projects
        .filter((row) => row.organisationId === organisationId)
        .reduce((sum, row) => sum + (totals[row.id] ?? 0), 0),
    };
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

  purgeTransient(now: Date, limit: number): number {
    let deleted = 0;
    const trim = <T extends { expiresAt: string }>(rows: T[]): T[] =>
      rows.filter((row) => {
        if (deleted < limit && Date.parse(row.expiresAt) <= now.getTime()) {
          deleted += 1;
          return false;
        }
        return true;
      });
    this.data.invites = trim(this.data.invites);
    this.data.refresh = trim(this.data.refresh);
    this.data.idempotency = trim(this.data.idempotency);
    this.data.lockouts = trim(this.data.lockouts);
    return deleted;
  }

  exportMetadata(): Record<string, unknown> {
    return {
      organisations: this.data.orgs,
      accounts: this.data.users.map(({ passwordHash: _hash, ...row }) => row),
      devices: this.data.devices,
      projects: this.data.projects,
      memberships: this.data.members,
      roles: this.data.users.map((row) => ({ userId: row.id, role: row.role })),
      audit: this.data.audit,
      security: this.data.security,
      packageMetadata: this.data.packages,
      acknowledgements: this.data.acks,
      vectors: this.data.vectors,
      invitations: this.data.invites.map(({ tokenHash: _hash, ...row }) => row),
      refreshFamilies: this.data.refresh.map(
        ({ tokenHash: _hash, ...row }) => row,
      ),
      usage: this.data.usage,
      idempotency: this.data.idempotency,
      lockouts: this.data.lockouts,
      configuration: this.data.settings.map(
        ({ fingerprint: _digest, ...row }) => row,
      ),
      schema: this.data.schema,
    };
  }

  destroyOrganisation(organisationId: string): string[] {
    if (this.data.orgs.length !== 1 || this.data.orgs[0]?.id !== organisationId)
      throw new Error(
        'Destroy requires a single matching organisation deployment.',
      );
    this.data = {
      ...this.data,
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
      settings: [],
    };
    return [
      'organisation',
      'users',
      'devices',
      'projects',
      'memberships',
      'package-metadata',
      'relay-ciphertext',
      'acknowledgements',
      'vectors',
      'invitations',
      'refresh-families',
      'usage',
      'audit',
      'security',
      'idempotency',
      'lockouts',
      'configuration-metadata',
    ];
  }

  seedRole(email: string, role: Role): void {
    const user = this.data.users.find((row) => row.email === email);
    if (user !== undefined) user.role = role;
  }
}
