# 266 — Export, destroy, deploy and the pipeline

**Phase** 24 · The minimal backend  |  **Depends on** [245](245-be-project-init.md), [264](264-be-audit-service.md), [265](265-be-openapi.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Everything needed to run and to leave this server: the two administrative commands, the container and compose files, the
runbook, and the pipeline that runs the same gate on every push.

## Files

- `backend/src/cli/admin.ts` (new)
- `backend/Dockerfile` (new)
- `backend/docker-compose.yml` (new)
- `backend/RUNBOOK.md` (new)
- `.github/workflows/backend.yml` (new)
- `backend/test/cli/admin.test.ts` (new)
- `backend/test/deploy/image_smoke.test.ts` (new)

## Contract

```text
npm run admin -- export --out <dir> | npm run admin -- destroy --confirm <org>
```

## Steps

1. Export accounts, devices, memberships, roles, audit rows and package metadata as files an operator can read, stating
   in the output that projects are not included because the server never held them.
2. Destroy requires the organisation named explicitly plus a second confirmation, and reports what it deleted.
3. One image, one process, non-root user, twelve-factor configuration, no baked configuration file; migrations run as an
   explicit step; shutdown stops accepting connections, finishes in-flight requests, closes the pool and exits.
4. The runbook covers deploy, upgrade, rotate a key, change retention, investigate a failed purge, and restore — and
   states that a server backup holds accounts, roles and metadata, never projects.
5. The workflow runs `npm run verify` on every push against an ephemeral Postgres, and nothing else: it reproduces the
   gate rather than re-implementing it (BE-FLOW-02).

## Constraints

- One container, one organisation; no multi-tenancy (BE-DEP-01).
- Backups cover accounts, not projects, and the runbook says so plainly so nobody assumes otherwise after an incident
  (BE-DEP-09).
- Sizing that grows unexpectedly means retention is broken; the runbook says investigate before scaling (BE-DEP-07).

## Definition of done

- [ ] An operator can leave the product entirely, taking everything the server holds, in one command.
- [ ] Destroy cannot run without an explicit organisation name and a second confirmation.
- [ ] The runbook states plainly that server backups contain accounts and metadata, never projects.
- [ ] A red pipeline blocks merging.
- [ ] Tests: command tests over a seeded database for export and destroy; a smoke test that builds the image and passes
      its health check; a pipeline run proving the gate fails when any single stage fails.
