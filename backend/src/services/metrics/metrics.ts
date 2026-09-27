export interface Metrics {
  requests: Record<
    string,
    { count: number; errors: number; latencyMs: number }
  >;
  packagesStored: number;
  packagesAcked: number;
  packagesPurged: number;
  storageBytes: Record<string, number>;
  aiRequests: number;
  aiCost: number;
  authFailures: number;
}

export function emptyMetrics(): Metrics {
  return {
    requests: {},
    packagesStored: 0,
    packagesAcked: 0,
    packagesPurged: 0,
    storageBytes: {},
    aiRequests: 0,
    aiCost: 0,
    authFailures: 0,
  };
}

export function noteRequest(
  metrics: Metrics,
  route: string,
  latencyMs: number,
  failed: boolean,
): void {
  const row = metrics.requests[route] ?? { count: 0, errors: 0, latencyMs: 0 };
  row.count += 1;
  row.latencyMs += latencyMs;
  if (failed) row.errors += 1;
  metrics.requests[route] = row;
}
