# 230 — What leaves this device, and location control

**Phase** 22 · Privacy and security  |  **Depends on** [135](../12-capture/135-auto-fields.md), [147](../13-processing/147-provider-registry.md), [225](../21-cloud-upload/225-destination-list.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One settings screen naming every outbound path, what it sends and whether it is on, each switchable from there; plus
the location section that keeps GPS off by default, excludes coordinates from exports and strips them from records
already captured.

## Files

- `frontend/lib/features/settings/presentation/egress_summary_screen.dart` (new)
- `frontend/lib/features/settings/presentation/gps_privacy_section.dart` (new)

## Steps

1. Build the outbound list from the provider registry (270) and the destination repository (419), never from a
   hardcoded array, so a new provider or destination cannot be missing from the screen.
2. Each row states the operation — AI extraction, OCR, speech, refinement, cloud upload — what leaves it (text only,
   image, audio, file), where it goes, and its on or off state, with the switch in the row.
3. Location section: GPS off by default, a switch excluding coordinates from every export, and an action removing
   coordinates from the current project's existing records.
4. Coordinate removal writes an audit entry naming who removed them and when, and reports how many records changed.

## Constraints

- The screen reads state and flips flags; it holds no client and composes no request (FE-SEC-03).
- Coordinate removal is an audited edit, not a silent rewrite of raw evidence (FE-SEC-08, FE-SEC-09).
- Off is the default for every row that sends anything (FE-SEC-07).

## Definition of done

- [ ] Every outbound path can be seen and disabled from this one screen, and a newly registered provider or
      destination appears without editing the screen.
- [ ] A project can be delivered with no location data at all, and each coordinate removal is visible in the audit
      trail.
- [ ] Tests: widget test of `egress_summary_screen.dart` over empty, all-off, all-on and failure states; test
      asserting a new registry entry appears in the list; test asserting an export after exclusion carries no
      coordinates and `gps_privacy_section.dart` reports the changed record count.
