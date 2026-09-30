import type { AppConfig } from '../config/schema.js';
import { can, type Principal } from '../domain/permissions.js';
import { invalidRequest, notFound } from '../domain/errors.js';
import { clampRetention } from '../domain/retention.js';
import { withTransaction } from '../repositories/base.js';
import type { Repository as Store } from '../repositories/repository.js';
import type { Membership, Project } from '../types/index.js';
async function memberOf(
  store: Store,
  principal: Principal,
  projectId: string,
): Promise<Membership | undefined> {
  return (await store.members()).find(
    (row) => row.projectId === projectId && row.userId === principal.userId,
  );
}
export async function visibleProject(
  store: Store,
  principal: Principal,
  projectId: string,
): Promise<Project> {
  const project = (await store.projects()).find((row) => row.id === projectId);
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
): Promise<Project[]> {
  const memberships = await store.members();
  const visibleIds = new Set(
    memberships
      .filter((row) => row.userId === principal.userId)
      .map((row) => row.projectId),
  );
  return (await store.projects()).filter(
    (project) =>
      project.organisationId === principal.organisationId &&
      (can(principal, 'adminAction') || visibleIds.has(project.id)),
  );
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
  const existing = (await store.projects()).find((row) => row.id === input.id);
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
) {
  await visibleProject(store, principal, projectId);
  return (await store.members()).filter((row) => row.projectId === projectId);
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
  const user = (await store.users()).find(
    (row) =>
      row.id === input.userId &&
      row.organisationId === principal.organisationId,
  );
  if (user === undefined) throw notFound();
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
