import assert from 'node:assert/strict';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';
import {
  can,
  type Capability,
  type Principal,
  type Role,
} from '../../src/domain/permissions.js';

const roles: Role[] = [
  'administrator',
  'project_manager',
  'reviewer',
  'field_operator',
];
const capabilities: Capability[] = [
  'capture',
  'review',
  'export',
  'relay',
  'aiProxy',
  'adminAction',
  'manageUsers',
  'manageProject',
  'manageMembers',
];

const allowed: Record<Role, Capability[]> = {
  administrator: capabilities,
  project_manager: [
    'capture',
    'review',
    'export',
    'relay',
    'aiProxy',
    'manageProject',
    'manageMembers',
  ],
  reviewer: ['capture', 'review', 'export'],
  field_operator: ['capture', 'export', 'aiProxy'],
};

function principal(role: Role, contextScope: string | null = null): Principal {
  return {
    userId: 'user-1',
    organisationId: 'org-1',
    role,
    deviceId: 'device-1',
    contextScope,
  };
}

describe('permission matrix', () => {
  it('decides every role and capability in one place', () => {
    for (const role of roles) {
      for (const capability of capabilities) {
        assert.equal(
          can(principal(role), capability),
          allowed[role].includes(capability),
          `${role} ${capability}`,
        );
      }
    }
  });

  it('honours a context scope', () => {
    const scoped = principal('reviewer', 'north');
    assert.equal(can(scoped, 'review', { contextId: 'north' }), true);
    assert.equal(can(scoped, 'review', { contextId: 'south' }), false);
  });

  it('keeps role comparisons out of routes', async () => {
    const root = path.join(
      path.dirname(fileURLToPath(import.meta.url)),
      '../../src/routes',
    );
    const files: string[] = [];
    async function walk(dir: string): Promise<void> {
      for (const entry of await readdir(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) await walk(full);
        else files.push(await readFile(full, 'utf8'));
      }
    }
    await walk(root);
    const source = files.join('\n');
    assert.equal(source.includes('role ==='), false);
    assert.equal(source.includes('role =='), false);
  });
});
