import type { AppConfig } from '../config/schema.js';
import { can, type Principal } from '../domain/permissions.js';
import { invalidRequest, notFound } from '../domain/errors.js';
import { clampRetention } from '../domain/retention.js';
import { withTransaction } from '../repositories/base.js';
import type { Repository as Store } from '../repositories/repository.js';
import type { Membership, Project } from '../types/index.js';
import type { PageQuery } from '../repositories/queries.js';
import { page, type Page } from './pagination.js';
async function memberOf(
  store: Store,
  principal: Principal,
  projectId: string,
): Promise<Membership | undefined> {
  return (
    await store.members({ projectId, userId: principal.userId, limit: 1 })
  )[0];
}
export async function visibleProject(
  store: Store,
  principal: Principal,
  projectId: string,
): Promise<Project> {
  const project = (await store.projects({ id: projectId, limit: 1 }))[0];
  const member = await memberOf(store, principal, projectId);
  if (
    project === undefined ||
    project.organisationId !== principal.organisationId ||
    (member === undefined && !can(principal, 'adminAction'))
  ) {
    throw notFound();
  }
  return project;
}
export async function listProjects(
  store: Store,
  principal: Principal,
  query: PageQuery = {},
): Promise<Page<Project>> {
  const limit = query.limit ?? 50;
  const rows = await store.projects({
    ...query,
    organisationId: principal.organisationId,
    ...(!can(principal, 'adminAction')
      ? { memberUserId: principal.userId }
      : {}),
    limit: limit + 1,
  });
  return page(rows, limit, (row) => row.id);
}
export async function createProject(
  store: Store,
  principal: Principal,
  input: {
    id: string;
    name: string;
  },
): Promise<Project> {
  if (!can(principal, 'manageProject')) throw notFound();
  const existing = (await store.projects({ id: input.id, limit: 1 }))[0];
  if (existing !== undefined)
    return visibleProject(store, principal, existing.id);
  const org = (await store.orgs()).find(
    (row) => row.id === principal.organisationId,
  );
  if (org === undefined) throw notFound();
  const project: Project = {
    id: input.id,
    organisationId: principal.organisationId,
    name: input.name,
    relayEnabled: false,
    neverRelay: false,
    retentionDays: org.retentionDays,
  };
  await withTransaction(store, async (tx) => {
    await tx.addProject(project);
    await tx.addMember({
      projectId: project.id,
      userId: principal.userId,
      contextScope: principal.contextScope,
    });
    await tx.recordAudit({
      actorId: principal.userId,
      action: 'create_project',
      target: project.id,
      before: null,
      after: { name: project.name },
    });
  });
  return project;
}
export async function patchProject(
  store: Store,
  config: AppConfig,
  principal: Principal,
  projectId: string,
  patch: {
    name?: string;
    relayEnabled?: boolean;
    neverRelay?: boolean;
    retentionDays?: number;
  },
): Promise<Project> {
  if (!can(principal, 'manageProject')) throw notFound();
  const current = await visibleProject(store, principal, projectId);
  const org = (await store.orgs()).find(
    (row) => row.id === principal.organisationId,
  );
  if (org === undefined) throw notFound();
  let retentionDays = current.retentionDays;
  if (patch.retentionDays !== undefined) {
    try {
      retentionDays = clampRetention(patch.retentionDays, org.retentionDays);
    } catch (error) {
      throw invalidRequest(
        error instanceof Error ? error.message : 'Invalid retention.',
      );
    }
  }
  void config;
  const next: Project = {
    ...current,
    name: patch.name ?? current.name,
    relayEnabled: patch.relayEnabled ?? current.relayEnabled,
    neverRelay: patch.neverRelay ?? current.neverRelay,
    retentionDays,
  };
  await withTransaction(store, async (tx) => {
    await tx.saveProject(next);
    await tx.recordAudit({
      actorId: principal.userId,
      action: 'patch_project',
      target: projectId,
      before: {
        name: current.name,
        relayEnabled: current.relayEnabled,
        neverRelay: current.neverRelay,
        retentionDays: current.retentionDays,
      },
      after: {
        name: next.name,
        relayEnabled: next.relayEnabled,
        neverRelay: next.neverRelay,
        retentionDays: next.retentionDays,
      },
    });
  });
  return next;
}
export async function listMembers(
  store: Store,
  principal: Principal,
  projectId: string,
  query: PageQuery = {},
): Promise<Page<Membership>> {
  await visibleProject(store, principal, projectId);
  const limit = query.limit ?? 50;
  return page(
    await store.members({ ...query, projectId, limit: limit + 1 }),
    limit,
    (row) => row.userId,
  );
}
export async function addMember(
  store: Store,
  principal: Principal,
  projectId: string,
  input: {
    userId: string;
    contextScope: string | null;
  },
): Promise<void> {
  if (!can(principal, 'manageMembers')) throw notFound();
  await visibleProject(store, principal, projectId);
  const user = await store.userById(input.userId);
  if (user === undefined || user.organisationId !== principal.organisationId)
    throw notFound();
  await withTransaction(store, async (tx) => {
    await tx.addMember({
      projectId,
      userId: input.userId,
      contextScope: input.contextScope,
    });
    await tx.recordAudit({
      actorId: principal.userId,
      action: 'add_member',
      target: `${projectId}:${input.userId}`,
      before: null,
      after: { contextScope: input.contextScope },
    });
  });
}
export async function removeMember(
  store: Store,
  principal: Principal,
  projectId: string,
  userId: string,
): Promise<void> {
  if (!can(principal, 'manageMembers')) throw notFound();
  await visibleProject(store, principal, projectId);
  await withTransaction(store, async (tx) => {
    await tx.removeMember(projectId, userId);
    await tx.recordAudit({
      actorId: principal.userId,
      action: 'remove_member',
      target: `${projectId}:${userId}`,
      before: null,
      after: null,
    });
  });
}
