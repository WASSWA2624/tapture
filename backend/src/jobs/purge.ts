import type { Repository as Store } from '../repositories/repository.js';
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
  batchSize = 100,
): Promise<PurgeReport> {
  let deleted = 0;
  let bytesReclaimed = 0;
  let oldestAgeSeconds = 0;
  let failures = 0;
  while (true) {
    let batchCount = 0;
    try {
      const batch = await store.withTransaction(async (tx) => {
        const due = (await tx.expiredPackages(now, batchSize)).filter((row) =>
          shouldPurge(row.expiresAt, now),
        );
        batchCount = due.length;
        let bytes = 0;
        let oldest = 0;
        for (const row of due) {
          await tx.removePackage(row.id);
          bytes += row.byteSize;
          oldest = Math.max(
            oldest,
            Math.floor((now.getTime() - Date.parse(row.createdAt)) / 1000),
          );
        }
        if (due.length > 0)
          await tx.recordAudit({
            actorId: 'system',
            action: 'purge',
            target: 'relay',
            before: null,
            after: { deleted: due.length, bytesReclaimed: bytes },
          });
        return { bytes, oldest };
      });
      deleted += batchCount;
      bytesReclaimed += batch.bytes;
      oldestAgeSeconds = Math.max(oldestAgeSeconds, batch.oldest);
    } catch {
      failures += Math.max(batchCount, 1);
      break;
    }
    if (batchCount < batchSize) break;
  }
  if (metrics !== undefined) metrics.packagesPurged += deleted;
  return { deleted, bytesReclaimed, oldestAgeSeconds, failures };
}
