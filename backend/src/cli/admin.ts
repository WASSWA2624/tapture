import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import type { Store } from '../repositories/store.js';

/// Writes accounts and metadata. Project content is never part of the file.
export async function exportAccounts(
  store: Store,
  outDir: string,
): Promise<void> {
  await mkdir(outDir, { recursive: true });
  const body = {
    accounts: store.users().map((user) => ({
      id: user.id,
      email: user.email,
      role: user.role,
      status: user.status,
      organisationId: user.organisationId,
    })),
    devices: store.devices(),
    memberships: store.members(),
    roles: store.users().map((user) => ({ userId: user.id, role: user.role })),
    audit: store.audit(),
    packageMetadata: store.packages(),
  };
  await writeFile(
    path.join(outDir, 'export.json'),
    JSON.stringify(body, null, 2),
  );
  await writeFile(
    path.join(outDir, 'README.txt'),
    'Projects are not included. This export holds accounts, devices, memberships, roles, audit and package metadata only.\n',
  );
}

/// Deletes one organisation after the name is confirmed twice.
export function destroyOrganisation(
  store: Store,
  name: string,
  confirm: string,
  again: string,
): { deleted: string[] } {
  if (confirm !== name || again !== name) {
    throw new Error('Destroy requires the organisation name twice.');
  }
  const org = store.orgs().find((row) => row.name === name);
  if (org === undefined) throw new Error('Organisation not found.');
  return { deleted: store.destroyOrganisation(org.id) };
}

function arg(name: string): string | undefined {
  const index = process.argv.indexOf(name);
  if (index < 0) return undefined;
  return process.argv[index + 1];
}

async function main(): Promise<void> {
  const command = process.argv[2];
  if (command === 'migrate') {
    const { parseConfig } = await import('../config/schema.js');
    const { createPool } = await import('../db/pool.js');
    const { migrate, readMigrations } = await import('../db/migrate.js');
    const { Store } = await import('../repositories/store.js');
    const config = parseConfig(process.env);
    const files = await readMigrations(
      path.join(
        path.dirname(fileURLToPath(import.meta.url)),
        '../../migrations',
      ),
    );
    const ran = await migrate(new Store(), files, createPool(config));
    process.stdout.write(`applied ${ran.join(', ') || 'nothing'}\n`);
    return;
  }
  if (command === 'export') {
    const out = arg('--out');
    if (out === undefined) throw new Error('Missing --out.');
    const { Store } = await import('../repositories/store.js');
    await exportAccounts(new Store(), out);
    process.stdout.write(`exported ${out}\n`);
    return;
  }
  if (command === 'destroy') {
    const confirm = arg('--confirm');
    const again = arg('--again');
    if (confirm === undefined || again === undefined) {
      throw new Error('Destroy requires --confirm and --again.');
    }
    process.stdout.write(`refused without a loaded organisation: ${confirm}\n`);
    return;
  }
  throw new Error(
    'Use export --out <dir> or destroy --confirm <org> --again <org>.',
  );
}

const entry = process.argv[1]?.replace(/\\/g, '/');
if (entry !== undefined && entry.endsWith('src/cli/admin.ts')) {
  main().catch((error: unknown) => {
    process.stderr.write(
      `${error instanceof Error ? error.message : 'admin failed'}\n`,
    );
    process.exit(1);
  });
}
