import { exec, spawn } from 'node:child_process';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';

export interface Stage {
  name: string;
  run: () => Promise<void>;
}

/// Runs every stage. A failure names the stage and returns 1.
export async function runStages(stages: Stage[]): Promise<number> {
  const failed: string[] = [];
  const results: Array<{ name: string; passed: boolean; durationMs: number }> =
    [];
  for (const stage of stages) {
    const started = performance.now();
    let passed = true;
    try {
      await stage.run();
    } catch (error) {
      passed = false;
      failed.push(stage.name);
      const message = error instanceof Error ? error.message : 'failed';
      process.stderr.write(`${stage.name}: ${message}\n`);
    }
    results.push({
      name: stage.name,
      passed,
      durationMs: Math.round(performance.now() - started),
    });
  }
  process.stdout.write(
    `stage\tstatus\tms\n${results.map((row) => `${row.name}\t${row.passed ? 'PASS' : 'FAIL'}\t${row.durationMs}`).join('\n')}\n`,
  );
  if (failed.length > 0) {
    process.stderr.write(`failed stages: ${failed.join(', ')}\n`);
    return 1;
  }
  return 0;
}

function run(command: string, args: string[]): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: 'inherit', shell: false });
    child.once('error', reject);
    child.on('exit', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${command} exited ${code ?? 1}`));
    });
  });
}

export async function scanSecrets(root: string): Promise<void> {
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
    /sk-[A-Za-z0-9]{8}|AKIA[A-Z0-9]{8}|AIza[0-9A-Za-z_-]{35}|password\s*=\s*['"][^'"]+['"]/;
  const violations: string[] = [];
  for (const file of files) {
    const lines = (await readFile(file, 'utf8')).split(/\r?\n/);
    lines.forEach((line, index) => {
      if (banned.test(line))
        violations.push(`${file}:${index + 1}: secret pattern`);
    });
  }
  if (violations.length > 0) throw new Error(violations.join('\n'));
}

export function productionStages(root: string): Stage[] {
  const require = createRequire(path.join(root, 'package.json'));
  const nodeTool = (name: string, entry: string, args: string[]) =>
    run(process.execPath, [
      path.join(path.dirname(require.resolve(`${name}/package.json`)), entry),
      ...args,
    ]);
  return [
    {
      name: 'format',
      run: () => nodeTool('prettier', 'bin/prettier.cjs', ['--check', '.']),
    },
    {
      name: 'lint',
      run: () =>
        nodeTool('eslint', 'bin/eslint.js', ['src', 'scripts', 'test']),
    },
    {
      name: 'types',
      run: () =>
        nodeTool('typescript', 'bin/tsc', ['-p', 'tsconfig.json', '--noEmit']),
    },
    {
      name: 'test',
      run: () =>
        nodeTool('tsx', 'dist/cli.mjs', [
          '--test',
          '--test-concurrency=1',
          'test/**/*.test.ts',
        ]),
    },
    {
      name: 'audit',
      run: () =>
        new Promise<void>((resolve, reject) => {
          // Static command only: npm's Windows launcher is a shell script. The
          // locally installed compiler/linter/test binaries run directly in Node.
          const child = exec('npm audit --audit-level=high', (error) =>
            error ? reject(error) : resolve(),
          );
          child.stdout?.pipe(process.stdout);
          child.stderr?.pipe(process.stderr);
        }),
    },
    { name: 'secrets', run: () => scanSecrets(path.join(root, 'src')) },
  ];
}

const entry = process.argv[1]?.replace(/\\/g, '/');
if (entry !== undefined && entry.endsWith('scripts/verify.ts')) {
  const code = await runStages(productionStages(process.cwd()));
  process.exit(code);
}
