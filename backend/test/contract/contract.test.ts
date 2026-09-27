import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';
import type { Express } from 'express';
import { appFor, makeDeps } from '../helpers.js';
import { compareContract } from './compare.js';
import { driftedRoute } from './fixtures/drifted_route.js';

function documentedPaths(yaml: string): string[] {
  return [...yaml.matchAll(/^  (\/[^:]+):/gm)]
    .map((match) => match[1] ?? '')
    .filter(Boolean);
}

function livePaths(app: Express): string[] {
  const stack = (
    app as unknown as {
      _router: { stack: Array<{ route?: { path: string } }> };
    }
  )._router.stack;
  return stack.flatMap((layer) =>
    layer.route === undefined ? [] : [layer.route.path],
  );
}

function normalise(routePath: string): string {
  return routePath.replace(/:([A-Za-z]+)/g, '{$1}');
}

describe('contract', () => {
  it('matches the running routes and reports every drifted mismatch', async () => {
    const yaml = await readFile(
      path.join(
        path.dirname(fileURLToPath(import.meta.url)),
        '../../openapi.yaml',
      ),
      'utf8',
    );
    const documented = documentedPaths(yaml);
    const live = [...new Set(livePaths(appFor(makeDeps())).map(normalise))];
    const missing = live.filter((routePath) => !documented.includes(routePath));
    assert.deepEqual(missing, []);
    const mismatches = compareContract(documented, [
      { path: driftedRoute.path, field: driftedRoute.field },
      { path: '/api/v1/auth/login' },
    ]);
    assert.equal(mismatches.length, 1);
    assert.equal(mismatches[0]?.path, driftedRoute.path);
    assert.equal(mismatches[0]?.field, driftedRoute.field);
  });
});
