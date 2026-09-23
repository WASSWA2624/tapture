# 062 — Resolve feedback archive 23092026-1635

**Phase** 23 · Hardening  |  **Depends on** [011](../11-context/011-context.md), [012](../12-capture/012-capture.md), [013](../13-processing/013-processing.md), [061](061-resolve-shell-capture-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Close the 23 Sep 2026 feedback archive: durable capture saves and recovery, source-preserving shell navigation, template-driven context, reusable project search and filters, visible project pins and association counts, a compact Settings index, attached audio evidence, and registry-driven AI provider settings.

The executable prompt is `prompts/feedback-23092026-1635/001-resolve-capture-projects-settings-feedback.md`. Defaults taken: `Save and process`; Drift capture sessions; `record` plus additive attachment ownership; registry-fed AI providers with backend custody; duplicate and inactive Settings rows removed from the index.

## Files

- `frontend/lib/app/`
- `frontend/lib/core/ai/`
- `frontend/lib/core/audio/`
- `frontend/lib/core/db/`
- `frontend/lib/features/capture/`
- `frontend/lib/features/context/`
- `frontend/lib/features/projects/`
- `frontend/lib/features/settings/`
- `frontend/lib/features/templates/`
- `frontend/test/`

## Definition of done

- [ ] Durable Save raw and Save and process persist evidence, raw values and context before success.
- [ ] Project routes expose accessible icons and breadcrumbs and Back returns to the source screen.
- [ ] Context levels and pinned fields are proposed from template metadata and inherited by capture.
- [ ] Project search, filters, pin indicators and association counts work at all size classes.
- [ ] Settings contains only active settings destinations; legacy routes remain valid.
- [ ] Audio is stored as raw evidence and linked to its record and selected photos.
- [ ] AI provider and model selection is registry-driven and keeps credentials in secure storage.
- [ ] Tests: migrations, repositories, controllers, routes, widgets, failures, semantics and intended goldens.
