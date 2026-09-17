# 160 — Unattended processing: on connect and while charging

**Phase** 13 · Processing  |  **Depends on** [019](../02-foundation/019-app-bootstrap.md), [025](../02-foundation/025-connectivity-service.md), [078](../07-account-and-settings/078-settings-store.md), [142](142-job-model.md), [144](144-image-preprocessing.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two unattended paths, each off by default: queued jobs start when connectivity returns, and unprocessed records get
their text read while the device charges, so later online work is smaller.

## Files

- `frontend/lib/features/processing/domain/auto_process.dart` (new)
- `frontend/lib/features/processing/domain/background_ocr.dart` (new)

## Steps

1. Trigger automatic processing on a connectivity gain (task 025) when the setting is on, honouring the Wi-Fi-only
   restriction and the budget guard.
2. Run opportunistic OCR only while charging and idle, and stop it immediately when the app resumes (task 019).

## Constraints

- Both paths run only through `BackgroundPolicy`; nothing runs while the app is in the foreground (FE-PERF-08).
- Opportunistic OCR makes no outbound call of any kind (FE-SEC-03).

## Definition of done

- [ ] With both settings off, nothing processes without a tap.
- [ ] Opportunistic OCR stops on resume, uses no network, and leaves battery use negligible.
- [ ] Tests: unit tests over the connectivity trigger with the metered restriction and the cap, and over the
      charging-and-idle gate with a resume interrupt, with no Flutter binding.
