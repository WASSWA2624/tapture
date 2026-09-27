import type { Store } from '../repositories/store.js';
import type { Metrics } from '../services/metrics/metrics.js';
import { shouldPurge } from '../services/relay/purge_decision.js';

export interface PurgeReport {
  deleted: number;
  bytesReclaimed: number;
  oldestAgeSeconds: number;
  failures: number;
}

/// Deletes packages whose expiry is before [now]. The report names no payload.
export async function runPurge(
  store: Store,
  now: Date,
  metrics?: Metrics,
): Promise<PurgeReport> {
  const due = store.packages().filter((row) => shouldPurge(row.expiresAt, now));
  let deleted = 0;
  let bytesReclaimed = 0;
  let oldestAgeSeconds = 0;
  let failures = 0;
  for (const row of due) {
    try {
      const age = Math.floor(
        (now.getTime() - Date.parse(row.createdAt)) / 1000,
      );
      oldestAgeSeconds = Math.max(oldestAgeSeconds, age);
      bytesReclaimed += row.byteSize;
      store.removePackage(row.id);
      deleted += 1;
    } catch {
      failures += 1;
    }
  }
  if (metrics !== undefined) metrics.packagesPurged += deleted;
  return { deleted, bytesReclaimed, oldestAgeSeconds, failures };
}
