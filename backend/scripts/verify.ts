import { spawn } from 'node:child_process';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';

export interface Stage {
  name: string;
  run: () => Promise<void>;
}

/// Runs every stage. A failure names the stage and returns 1.
export async function runStages(stages: Stage[]): Promise<number> {
  const failed: string[] = [];
  for (const stage of stages) {
    try {
      await stage.run();
    } catch (error) {
      failed.push(stage.name);
      const message = error instanceof Error ? error.message : 'failed';
      process.stderr.write(`${stage.name}: ${message}\n`);
    }
  }
  if (failed.length > 0) {
    process.stderr.write(`failed stages: ${failed.join(', ')}\n`);
    return 1;
  }
  return 0;
}

function run(command: string, args: string[]): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: 'inherit', shell: true });
    child.on('exit', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${command} exited ${code ?? 1}`));
    });
  });
}

async function scanSecrets(root: string): Promise<void> {
  const files: string[] = [];
  async function walk(dir: string): Promise<void> {
    for (const entry of await readdir(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) await walk(full);
      else if (entry.name.endsWith('.ts')) files.push(full);
    }
  }
  await walk(root);
  const banned =
    /sk-[A-Za-z0-9]{8}|AKIA[A-Z0-9]{8}|password\s*=\s*['"][^'"]+['"]/;
  for (const file of files) {
    const text = await readFile(file, 'utf8');
    if (banned.test(text)) throw new Error(`secret pattern in ${file}`);
  }
}

export function productionStages(root: string): Stage[] {
  const npx = process.platform === 'win32' ? 'npx.cmd' : 'npx';
  return [
    { name: 'format', run: () => run(npx, ['prettier', '--check', '.']) },
    { name: 'lint', run: () => run(npx, ['eslint', 'src', 'scripts', 'test']) },
    {
      name: 'types',
      run: () => run(npx, ['tsc', '-p', 'tsconfig.json', '--noEmit']),
    },
    {
      name: 'test',
      run: () =>
        run(npx, [
          'tsx',
          '--test',
          '--test-concurrency=1',
          'test/**/*.test.ts',
        ]),
    },
    { name: 'audit', run: () => run('npm', ['audit', '--audit-level=high']) },
    { name: 'secrets', run: () => scanSecrets(path.join(root, 'src')) },
  ];
}

const entry = process.argv[1]?.replace(/\\/g, '/');
if (entry !== undefined && entry.endsWith('scripts/verify.ts')) {
  const code = await runStages(productionStages(process.cwd()));
  process.exit(code);
}
