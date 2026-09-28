# 10 — Deployment

## BE-DEP-01 — One container, one organisation

A single image running one process, deployed by the organisation that owns the data. No multi-tenancy, no shared
hosting of several organisations.

## BE-DEP-02 — Configuration comes from the environment

Twelve-factor. No configuration file baked into the image. Every variable is documented with its default and whether
it is required.

## BE-DEP-03 — Boot fails loudly on bad configuration

A missing secret or malformed value stops the process with a clear message. Never start in a half-configured state.

## BE-DEP-04 — Migrations run deliberately

As a startup step behind a flag, or as a separate job. Never automatically against a production database without the
operator choosing it.

## BE-DEP-05 — Graceful shutdown

Stop accepting connections, finish in-flight requests, close the pool, exit. In-flight relay uploads either complete
or leave nothing behind.

## BE-DEP-06 — Versioned and reported

`/version` returns the build and API version. Clients use it to detect drift and degrade cleanly.

## BE-DEP-07 — Small by design

Because the server stores no media durably, a fifty-person deployment runs on a modest virtual machine. If sizing
grows unexpectedly, retention is broken — investigate before scaling.

## BE-DEP-08 — Two administrative commands exist

Export the entire server state, and destroy it. Both are documented, tested and safe to run.

## BE-DEP-09 — Backups cover accounts, not projects

The operator may back up the server database, which holds accounts, roles and metadata. It does not hold projects,
and the runbook says so plainly, so nobody assumes otherwise after an incident.

## BE-DEP-10 — The runbook is part of the repository

Deploy, upgrade, rotate a key, change retention, investigate a purge failure, restore. Written down, kept current.
