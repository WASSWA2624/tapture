# 231 — Per-project AI and image egress switches

**Phase** 22 · Privacy and security  |  **Depends on** [086](../08-projects/086-project-edit.md), [144](../13-processing/144-image-preprocessing.md), [147](../13-processing/147-provider-registry.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two project-level switches: one makes the project fully manual, so no screen offers an online action; one holds images
back entirely, so extraction runs on on-device OCR text and says so.

## Files

- `frontend/lib/features/projects/presentation/ai_disable_switch.dart` (new)
- `frontend/lib/features/projects/presentation/image_egress_switch.dart` (new)

## Steps

1. Store both flags in project settings (149); the provider registry (270) reads them before a request is composed, so
   the check cannot be skipped by a new caller.
2. With AI off, processing entry points are absent from the record and photo screens rather than shown disabled, and
   the queue accepts no online job for that project.
3. With image egress off, extraction uses on-device OCR (266) text only and the request builder receives no image
   path, on first run, retry and refinement alike.
4. State the basis on the extraction result — "text only, on-device OCR" — so the operator knows what a value came
   from.

## Constraints

- Both switches are per project, not global preferences; a second project is unaffected (FE-SEC-07).
- A switch guards egress at the registry, not in each screen (FE-SEC-03).

## Definition of done

- [ ] With AI off, no screen in the project offers an online action and the project runs end to end with no outbound
      call.
- [ ] With image egress off, no request carries an image path, including retries and refinement.
- [ ] Tests: integration test asserting zero outbound calls for a project with AI off; widget tests of both switches;
      unit test that the composed extraction request holds OCR text and no image for every entry point.
