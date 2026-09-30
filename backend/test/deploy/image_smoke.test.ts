import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';
import { randomUUID } from 'node:crypto';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { setTimeout as delay } from 'node:timers/promises';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '../..');
const execute = promisify(execFile);

async function docker(...args: string[]): Promise<string> {
  const result = await execute('docker', args, {
    timeout: 180_000,
    maxBuffer: 4_000_000,
  });
  return result.stdout.trim();
}

async function eventually(check: () => Promise<boolean>): Promise<void> {
  const deadline = Date.now() + 30_000;
  while (Date.now() < deadline) {
    if (await check()) return;
    await delay(250);
  }
  assert.fail('Container did not become healthy within 30 seconds.');
}

describe('image', () => {
  it('runs as non-root and bakes no secret', async () => {
    const docker = await readFile(path.join(root, 'Dockerfile'), 'utf8');
    assert.match(docker, /USER node/);
    assert.match(docker, /CMD \["node", "dist\/src\/server\.js"\]/);
    assert.match(docker, /HEALTHCHECK/);
    assert.equal(/CMD.*npx/.test(docker), false);
    assert.equal(/ENV\s+TOKEN_SECRET/i.test(docker), false);
    const runbook = await readFile(path.join(root, 'RUNBOOK.md'), 'utf8');
    assert.match(runbook, /Projects are not included/);
    assert.match(runbook, /investigate before/i);
    const ignored = await readFile(path.join(root, '.dockerignore'), 'utf8');
    assert.match(ignored, /^node_modules$/m);
    assert.match(ignored, /^\.env$/m);
  });

  it(
    'builds the image, migrates an ephemeral Postgres and passes its health check',
    {
      skip: process.env['RUN_DOCKER_SMOKE'] !== 'true',
      timeout: 300_000,
    },
    async () => {
      const suffix = randomUUID().slice(0, 8);
      const network = `tapture-smoke-${suffix}`;
      const database = `${network}-database`;
      const server = `${network}-server`;
      const image = `tapture-smoke:${suffix}`;
      const password = randomUUID();
      const environment = [
        '--env',
        `DATABASE_URL=postgres://postgres:${password}@postgres:5432/tapture`,
        '--env',
        `TOKEN_SECRET=${randomUUID()}`,
      ];
      try {
        await docker('build', '--tag', image, root);
        await docker('network', 'create', network);
        await docker(
          'run',
          '--detach',
          '--name',
          database,
          '--network',
          network,
          '--network-alias',
          'postgres',
          '--env',
          `POSTGRES_PASSWORD=${password}`,
          '--env',
          'POSTGRES_DB=tapture',
          'postgres:16-alpine',
        );
        await eventually(async () => {
          try {
            await docker(
              'exec',
              database,
              'pg_isready',
              '-U',
              'postgres',
              '-d',
              'tapture',
            );
            return true;
          } catch {
            return false;
          }
        });
        await docker(
          'run',
          '--rm',
          '--network',
          network,
          ...environment,
          image,
          'node',
          'dist/src/cli/admin.js',
          'migrate',
        );
        await docker(
          'run',
          '--detach',
          '--name',
          server,
          '--network',
          network,
          '--publish',
          '127.0.0.1::8080',
          '--health-interval=1s',
          '--health-start-period=1s',
          ...environment,
          image,
        );
        await eventually(
          async () =>
            (await docker(
              'inspect',
              '--format',
              '{{.State.Health.Status}}',
              server,
            )) === 'healthy',
        );
        const address = await docker('port', server, '8080/tcp');
        const response = await fetch(`http://${address}/health`, {
          signal: AbortSignal.timeout(5_000),
        });
        assert.equal(response.status, 200);
        const ready = await fetch(`http://${address}/ready`, {
          signal: AbortSignal.timeout(5_000),
        });
        assert.equal(ready.status, 200);
        assert.equal(
          await docker('inspect', '--format', '{{.Config.User}}', server),
          'node',
        );
        const imageEnvironment = await docker(
          'image',
          'inspect',
          '--format',
          '{{json .Config.Env}}',
          image,
        );
        assert.equal(imageEnvironment.includes('TOKEN_SECRET'), false);
      } finally {
        await Promise.allSettled([
          docker('rm', '--force', server),
          docker('rm', '--force', database),
        ]);
        await docker('network', 'rm', network).catch(() => undefined);
        await docker('image', 'rm', '--force', image).catch(() => undefined);
      }
    },
  );
});
