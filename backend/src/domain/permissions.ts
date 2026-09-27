export type Role =
  'administrator' | 'project_manager' | 'reviewer' | 'field_operator';

export type Capability =
  | 'capture'
  | 'review'
  | 'export'
  | 'relay'
  | 'aiProxy'
  | 'adminAction'
  | 'manageUsers'
  | 'manageProject'
  | 'manageMembers';

export interface Principal {
  userId: string;
  organisationId: string;
  role: Role;
  deviceId: string;
  contextScope: string | null;
}

export interface Scope {
  projectId?: string;
  contextId?: string;
}

const matrix: Record<Role, ReadonlySet<Capability>> = {
  administrator: new Set([
    'capture',
    'review',
    'export',
    'relay',
    'aiProxy',
    'adminAction',
    'manageUsers',
    'manageProject',
    'manageMembers',
  ]),
  project_manager: new Set([
    'capture',
    'review',
    'export',
    'relay',
    'aiProxy',
    'manageProject',
    'manageMembers',
  ]),
  reviewer: new Set(['capture', 'review', 'export']),
  field_operator: new Set(['capture', 'export', 'aiProxy']),
};

/// The only role check. Routes never compare roles themselves.
export function can(
  principal: Principal,
  capability: Capability,
  scope?: Scope,
): boolean {
  if (!matrix[principal.role].has(capability)) return false;
  if (
    principal.contextScope !== null &&
    scope?.contextId !== undefined &&
    scope.contextId !== principal.contextScope
  ) {
    return false;
  }
  return true;
}
