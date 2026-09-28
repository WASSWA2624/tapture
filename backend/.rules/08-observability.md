# 08 — Observability

## BE-OBS-01 — Structured logs, one line per event

JSON, with timestamp, level, request identifier, route, user, device and outcome. Human-readable formatting is a
local development concern only.

## BE-OBS-02 — What may never be logged

Project content of any kind, package bytes, captions, transcripts, field values, file names from user data,
passwords, tokens, provider keys, and full request bodies. A test scans log output for these patterns.

## BE-OBS-03 — Every request carries an identifier

Generated at the edge, propagated through services and returned to the client, so a field report can be traced
without guesswork.

## BE-OBS-04 — Levels mean something

`error` is actionable and pages someone. `warn` is a degraded path. `info` is a state change. `debug` is off in
production.

## BE-OBS-05 — The metrics that matter

Request rate, latency and error rate per route; relay packages stored, acknowledged and purged; storage bytes by
project; AI requests and cost; authentication failures.

## BE-OBS-06 — Health and readiness are separate

`/health` says the process is alive. Readiness includes the database and the secret store, so a deployment does not
receive traffic before it can serve it.

## BE-OBS-07 — Security and administrative events are audited

User creation, role change, key rotation, retention change, relay enablement and purge runs are recorded with actor,
target, time and outcome, in an append-only table.

## BE-OBS-08 — Log retention is bounded

Logs expire on a documented schedule. Logs are not a back door into an archive of project activity.

## BE-OBS-09 — Alert on the boundary

Alert when storage grows without purge, when purge fails, when authentication failures spike, and when AI spend
crosses a threshold. These are the failure modes that matter.
