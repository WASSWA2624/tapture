# 264 — Audit, security events and metrics

**Phase** 24 · The minimal backend  |  **Depends on** [251](251-be-schema-relay.md), [256](256-be-permissions.md), [261](261-be-retention-job.md), [263](263-be-ai-proxy.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The one service every privileged action calls to leave an attributable trail, and the metrics route that exposes the
counters showing whether the product boundary is holding.

## Files

- `backend/src/services/audit.ts` (new)
- `backend/src/routes/metrics.ts` (new)
- `backend/test/services/audit.test.ts` (new)
- `backend/test/routes/metrics.test.ts` (new)

## Contract

```ts
recordAudit(actor: Principal, action: AuditAction, target: AuditTarget, outcome: Outcome): Promise<void>

GET /metrics
```

## Steps

1. Cover user creation, role change, key rotation, retention change, relay enablement, device revocation and purge runs,
   writing one row each with actor, target, action, outcome and time.
2. Write the audit row in the same transaction as the action it describes, so neither can exist without the other.
3. Expose request rate, latency and error rate per route; packages stored, acknowledged and purged; storage bytes by
   project; AI requests and cost; authentication failures.

## Constraints

- Audit rows are append-only; the service exposes no update or delete path (BE-OBS-07).
- Metrics name the boundary failures worth alerting on: storage growing while purge stays flat, purge failing,
  authentication failures spiking, AI spend crossing a threshold (BE-OBS-09).
- No metric label carries project content, a user file name or any other forbidden field (BE-OBS-02).

## Definition of done

- [ ] Every privileged action is attributable to an actor and a time, and rolling back the action rolls back its row.
- [ ] Storage growing while purge counts stay flat is visible immediately.
- [ ] Tests: tests asserting exactly one row per action with actor, target and outcome; tests asserting each counter
      moves for its event and that no label leaks a forbidden field.
