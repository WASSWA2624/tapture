# 061 — Resolve shell, settings and capture feedback

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Close the 22 Sep 2026 feedback archive: one database for settings screens, a status line that names the screen, no empty Site band, capture that can add a photo, caption it, resume one session, and reach templates and context.

The executable prompt is `prompts/feedback-22092026-1046/001-resolve-shell-and-capture-feedback.md`. Defaults taken: no URL photo fetch, one capture session per project, template choice stored on `ProjectSettings`.

## Files

- `frontend/lib/app/widgets/status_line.dart`
- `frontend/lib/app/shell_title.dart`
- `frontend/lib/core/db/database_provider.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/settings/presentation/`
- `frontend/lib/features/projects/`
- `frontend/lib/features/context/presentation/`

## Definition of done

- [x] Tests: operator, capture settings, storage, status line, capture add, captions, resume, crop, context chip, template choice.
