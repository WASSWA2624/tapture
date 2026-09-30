import type { AppConfig } from '../../config/schema.js';
import type { Principal } from '../../domain/permissions.js';
import { quotaExceeded, unavailable } from '../../domain/errors.js';
import type { Repository } from '../../repositories/repository.js';
import type { UsageTotals } from '../../repositories/usage.js';

function assertLimit(
  used: number,
  incoming: number,
  ceiling: number,
  scope: string,
  kind: string,
): void {
  if (used + incoming <= ceiling) return;
  throw quotaExceeded(
    `The ${scope} AI ${kind} limit is reached. Ask your administrator to review usage or limits.`,
    { scope, kind, ceiling },
  );
}

function assertScope(
  used: UsageTotals,
  cost: number,
  scope: string,
  limits: {
    requests: number;
    dailyRequests: number;
    budget: number;
    dailyBudget: number;
  },
): void {
  assertLimit(used.requests, 1, limits.requests, scope, 'request');
  assertLimit(
    used.dailyRequests,
    1,
    limits.dailyRequests,
    scope,
    'daily request',
  );
  assertLimit(used.cost, cost, limits.budget, scope, 'budget');
  assertLimit(used.dailyCost, cost, limits.dailyBudget, scope, 'daily budget');
}

/// Must run in the same transaction as the reservation. All users and pending
/// requests share a project's limits; all projects share organisation limits.
export async function assertQuota(
  store: Repository,
  config: AppConfig,
  principal: Principal,
  projectId: string,
  now = new Date(),
): Promise<number> {
  // Reserve every possible retry; timeout does not prove the call was not billed.
  // An operator-supplied upper bound replaces invented monetary media-byte costs.
  if (config.aiRequestCostCeiling <= 0) throw unavailable();
  const cost = config.aiRequestCostCeiling * (config.aiRetryLimit + 1);
  const day = new Date(now);
  day.setUTCHours(0, 0, 0, 0);
  const usage = await store.quotaUsage(
    principal.organisationId,
    projectId,
    day.toISOString(),
    new Date(day.getTime() + 86_400_000).toISOString(),
  );
  assertScope(usage.project, cost, 'project', {
    requests: config.aiProjectRequestLimit,
    dailyRequests: config.aiProjectDailyRequestLimit,
    budget: config.aiProjectBudget,
    dailyBudget: config.aiProjectDailyBudget,
  });
  assertScope(usage.organisation, cost, 'organisation', {
    requests: config.aiOrganisationRequestLimit,
    dailyRequests: config.aiOrganisationDailyRequestLimit,
    budget: config.aiOrganisationBudget,
    dailyBudget: config.aiOrganisationDailyBudget,
  });
  return cost;
}
