# 06 — Relay and retention

These rules are the product boundary. They are what keeps a coordination service from quietly becoming the place the
data lives.

*Implements specification sections 70.2, 70.3 and 72.*

## BE-RELAY-01 — The server is transit, not truth
The device holds the authoritative project. The server holds packages in flight, and nothing else. No feature may
assume the server can reconstruct a project, because it cannot.

## BE-RELAY-02 — Packages arrive encrypted and leave encrypted
The server receives ciphertext, stores ciphertext and returns ciphertext. It holds no key and has no code path that
attempts to decrypt, parse or inspect a package.

## BE-RELAY-03 — Purge on acknowledgement
A package is deleted as soon as every enrolled device on that project has acknowledged it. Acknowledgement is
recorded in the same transaction as the delete decision.

## BE-RELAY-04 — Purge on expiry, unconditionally
Any package older than the retention window is deleted whether or not it has been acknowledged. Default 30 days,
configurable, hard maximum 90. The maximum is enforced in code, not by policy.

## BE-RELAY-05 — No archive, no backup, no copy
No second copy for safety, no cold storage, no "just in case" bucket, no analytics extract. A device that misses the
window re-synchronises from a peer.

## BE-RELAY-06 — Metadata is minimal and listed
Package identifier, project, author device, byte size, created time, expiry, acknowledgement state. Nothing else on
the package row. Adding a metadata column requires a task and a written justification.

Version vectors are the one adjacent record, kept per project and device rather than per package, so a returning
device can be told what it has yet to receive (task 260). They carry counters and device identifiers only — never a
record identifier, a field name or anything else drawn from project content.

## BE-RELAY-07 — Access is membership-scoped
A package is downloadable only by an enrolled device of a member of that project. Every access is authorised in the
service layer and logged.

## BE-RELAY-08 — Purge is observable and provable
The purge job runs on a schedule, records counts and ages, and an administrator can verify that expired packages are
gone. A test drives the clock forward and asserts deletion.

## BE-RELAY-09 — Relay is off until asked for
Relay is enabled per project by a project manager. A project marked "never relay" is rejected by the server, not only
hidden in the client.

## BE-RELAY-10 — Storage is bounded and reported
Per-project and per-organisation ceilings, with a clear error when exceeded. Growth is a signal that purge is broken.

## BE-RELAY-11 — Merge stays on the device
The server never merges, resolves a conflict, or orders changes. It moves opaque packages and records who has seen
what.
