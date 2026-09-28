import type { Deps } from '../deps.js';
import { runPurge } from './purge.js';

/// Serial runs; shutdown waits for the current transaction before draining.
export function schedulePurge(deps: Deps): () => Promise<void> {
  let current: Promise<void> | undefined;
  const run = () => {
    if (current !== undefined) return;
    current = runPurge(
      deps.store,
      new Date(),
      deps.metrics,
      deps.config.purgeBatchSize,
    )
      .then((report) => {
        deps.log.info('relay_purge', { ...report });
      })
      .catch(() => {
        deps.log.error('relay_purge_failed', { outcome: 'failed' });
      })
      .finally(() => {
        current = undefined;
      });
  };
  const timer = setInterval(run, deps.config.purgeIntervalMs);
  timer.unref();
  run();
  return async () => {
    clearInterval(timer);
    await current;
  };
}
