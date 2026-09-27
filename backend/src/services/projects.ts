import type { AppConfig } from '../config/schema.js';
import { can, type Principal } from '../domain/permissions.js';
import { invalidRequest, notFound } from '../domain/errors.js';
import { clampRetention } from '../domain/retention.js';
import { withTransaction } from '../repositories/base.js';
import type { Store } from '../repositories/store.js';
import type { Membership, Project } from '../types/index.js';

function memberOf(
  store: Store,
  principal: Principal,
  projectId: string,
): Membership | undefined {
  return store
    .members()
    .find(
      (row) => row.projectId === projectId && row.userId === principal.userId,
    );
}

export function visibleProject(
  store: Store,
  principal: Principal,
  projectId: string,
): Project {
  const project = store.projects().find((row) => row.id === projectId);
  const member = memberOf(store, principal, projectId);
  if (
    project === undefined ||
    project.organisationId !== principal.organisationId ||
    (member === undefined && !can(principal, 'adminAction'))
  ) {
    throw notFound();
  }
  return project;
}

export function listProjects(store: Store, principal: Principal): Project[] {
  return store.projects().filter((project) => {
    try {
      visibleProject(store, principal, project.id);
      return true;
    } catch {
      return false;
    }
  });
}

export async function createProject(
  store: Store,
  principal: Principal,
  input: { id: string; name: string },
): Promise<Project> {
  if (!can(principal, 'manageProject')) throw notFound();
  const org = store.orgs().find((row) => row.id === principal.organisationId);
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
    tx.addProject(project);
    tx.addMember({
      projectId: project.id,
      userId: principal.userId,
      contextScope: principal.contextScope,
    });
    tx.recordAudit({
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
  const current = visibleProject(store, principal, projectId);
  const org = store.orgs().find((row) => row.id === principal.organisationId);
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
    tx.saveProject(next);
    tx.recordAudit({
      actorId: principal.userId,
      action: 'patch_project',
      target: projectId,
      before: { name: current.name, relayEnabled: current.relayEnabled },
      after: { name: next.name, relayEnabled: next.relayEnabled },
    });
  });
  return next;
}

export function listMembers(
  store: Store,
  principal: Principal,
  projectId: string,
) {
  visibleProject(store, principal, projectId);
  return store.members().filter((row) => row.projectId === projectId);
}

export async function addMember(
  store: Store,
  principal: Principal,
  projectId: string,
  input: { userId: string; contextScope: string | null },
): Promise<void> {
  if (!can(principal, 'manageMembers')) throw notFound();
  visibleProject(store, principal, projectId);
  const user = store
    .users()
    .find(
      (row) =>
        row.id === input.userId &&
        row.organisationId === principal.organisationId,
    );
  if (user === undefined) throw notFound();
  await withTransaction(store, async (tx) => {
    tx.addMember({
      projectId,
      userId: input.userId,
      contextScope: input.contextScope,
    });
    tx.recordAudit({
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
  visibleProject(store, principal, projectId);
  await withTransaction(store, async (tx) => {
    tx.removeMember(projectId, userId);
    tx.recordAudit({
      actorId: principal.userId,
      action: 'remove_member',
      target: `${projectId}:${userId}`,
      before: null,
      after: null,
    });
  });
}
