export interface UsageRow {
  projectId: string;
  userId: string;
  model: string;
  byteSize: number;
  durationMs: number;
  outcome: string;
  cost: number;
  at: string;
}

export interface UsageTotals {
  requests: number;
  dailyRequests: number;
  cost: number;
  dailyCost: number;
}

export interface QuotaUsage {
  project: UsageTotals;
  organisation: UsageTotals;
}

export const emptyUsageTotals = (): UsageTotals => ({
  requests: 0,
  dailyRequests: 0,
  cost: 0,
  dailyCost: 0,
});
