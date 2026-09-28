import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createPool } from '../db/pool.js';
import { createPostgresRepository } from '../repositories/postgres.js';
import { bootstrapOrganisation } from '../services/auth/bootstrap.js';
import type { Repository as Store } from '../repositories/repository.js';
/// Writes accounts and metadata. Project content is never part of the file.
export async function exportAccounts(
  store: Store,
  outDir: string,
): Promise<void> {
  await mkdir(outDir, { recursive: true });
  const body = {
    accounts: (await store.users()).map((user) => ({
      id: user.id,
      email: user.email,
      role: user.role,
      status: user.status,
      organisationId: user.organisationId,
    })),
    devices: await store.devices(),
    memberships: await store.members(),
    roles: (await store.users()).map((user) => ({
      userId: user.id,
      role: user.role,
    })),
    audit: await store.audit(),
    packageMetadata: await store.packages(),
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
export async function destroyOrganisation(
  store: Store,
  name: string,
  confirm: string,
  again: string,
): Promise<{
  deleted: string[];
}> {
  if (confirm !== name || again !== name) {
    throw new Error('Destroy requires the organisation name twice.');
  }
  const org = (await store.orgs()).find((row) => row.name === name);
  if (org === undefined) throw new Error('Organisation not found.');
  return { deleted: await store.destroyOrganisation(org.id) };
}
function arg(name: string): string | undefined {
  const index = process.argv.indexOf(name);
  if (index < 0) return undefined;
  return process.argv[index + 1];
}
async function main(): Promise<void> {
  const { config } = await import('../config/index.js');
  if (!/^postgres(?:ql)?:\/\//.test(config.databaseUrl))
    throw new Error('Administration requires a PostgreSQL DATABASE_URL.');
  const pool = createPool(config);
  const store = createPostgresRepository(pool);
  try {
    const command = process.argv[2];
    if (command === 'migrate') {
      const { migrate, readMigrations } = await import('../db/migrate.js');
      const files = await readMigrations(
        path.join(
          path.dirname(fileURLToPath(import.meta.url)),
          '../../migrations',
        ),
      );
      const ran = await migrate(store, files, pool);
      process.stdout.write(`applied ${ran.join(', ') || 'nothing'}\n`);
      return;
    }
    if (command === 'export') {
      const out = arg('--out');
      if (out === undefined) throw new Error('Missing --out.');
      await exportAccounts(store, out);
      process.stdout.write(`exported ${out}\n`);
      return;
    }
    if (command === 'destroy') {
      const confirm = arg('--confirm');
      const again = arg('--again');
      if (confirm === undefined || again === undefined) {
        throw new Error('Destroy requires --confirm and --again.');
      }
      const report = await destroyOrganisation(store, confirm, confirm, again);
      process.stdout.write(`deleted ${report.deleted.join(', ')}\n`);
      return;
    }
    if (command === 'bootstrap') {
      const name = arg('--organisation');
      const email = arg('--email');
      const passwordFile = arg('--password-file');
      if (!name || !email || !passwordFile)
        throw new Error(
          'Bootstrap requires --organisation, --email and --password-file.',
        );
      const password = (await readFile(passwordFile, 'utf8')).replace(
        /\r?\n$/,
        '',
      );
      const result = await bootstrapOrganisation(store, config, {
        name,
        email,
        password,
      });
      process.stdout.write(
        `created organisation ${result.organisationId} and administrator ${result.userId}\n`,
      );
      return;
    }
    throw new Error(
      'Use migrate, bootstrap, export --out <dir> or destroy --confirm <org> --again <org>.',
    );
  } finally {
    await pool.drain();
  }
}
const entry = process.argv[1];
if (entry !== undefined && import.meta.url === pathToFileURL(entry).href) {
  main().catch((error: unknown) => {
    process.stderr.write(
      `${error instanceof Error ? error.message : 'admin failed'}\n`,
    );
    process.exit(1);
  });
}
