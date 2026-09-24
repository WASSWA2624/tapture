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

- [x] Durable Save raw and Save and process persist evidence, raw values and context before success.
- [x] Project routes expose accessible icons and breadcrumbs and Back returns to the source screen.
- [x] Context levels and pinned fields are proposed from template metadata and inherited by capture.
- [x] Project search, filters, pin indicators and association counts work at all size classes.
- [x] Settings contains only active settings destinations; legacy routes remain valid.
- [x] Audio is stored as raw evidence and linked to its record and selected photos.
- [x] AI provider and model selection is registry-driven and keeps credentials in secure storage.
- [x] Tests: migrations, repositories, controllers, routes, widgets, failures, semantics and intended goldens.

## Verification

- `dart analyze`: clean.
- Focused capture, context, AI, reference and template suites: 59 tests passed.
- Projects, Settings and processing worker suites: 240 tests passed.
- Architecture layering and raw-evidence safety suites: 28 tests passed.
- Schema migration suite: 11 tests passed, including populated v17 and v18 upgrades.
- Intended golden suites: 45 images passed comparison.
- `flutter build apk --debug`: built `build/app/outputs/flutter-apk/app-debug.apk`.
- `dart run tool/verify.dart --fast`: analyzer, dependency allowlist, structure, plan,
  templates, and all unit/widget tests passed. The aggregate gate remains red on
  repository-wide pre-existing debt: 72 one-file-per-test entries, 11 naming
  violations, existing state/token literals, and their related guardrail tests.
- Android emulator-only back, permission, and process-death exercises were not run:
  no Android device or AVD is installed in the verification environment.

### Regenerated intended goldens

- `frontend/test/app/goldens/nav_pane_empty_dark.png`
- `frontend/test/app/goldens/nav_pane_empty_light.png`
- `frontend/test/app/goldens/nav_pane_empty_outdoor.png`
- `frontend/test/app/goldens/nav_pane_header_text2_dark.png`
- `frontend/test/app/goldens/nav_pane_header_text2_light.png`
- `frontend/test/app/goldens/nav_pane_header_text2_outdoor.png`
- `frontend/test/app/goldens/nav_pane_projects_dark.png`
- `frontend/test/app/goldens/nav_pane_projects_light.png`
- `frontend/test/app/goldens/nav_pane_projects_outdoor.png`
- `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_dark.png`
- `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_light.png`
- `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_outdoor.png`
- `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_text2_dark.png`
- `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_text2_light.png`
- `frontend/test/features/projects/presentation/goldens/project_home_open_with_menu_text2_outdoor.png`
- `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_dark.png`
- `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_light.png`
- `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_outdoor.png`
- `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_text2_dark.png`
- `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_text2_light.png`
- `frontend/test/features/projects/presentation/goldens/project_list_numbered_pinned_text2_outdoor.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_dark.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_light.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_outdoor.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_system.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_text2_dark.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_text2_light.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_text2_outdoor.png`
- `frontend/test/features/settings/presentation/goldens/settings_index_text2_system.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_dark.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_light.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_outdoor.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_system.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_text2_dark.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_text2_light.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_text2_outdoor.png`
- `frontend/test/features/settings/presentation/goldens/ai_provider_settings_text2_system.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_dark.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_light.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_outdoor.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_system.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_text2_dark.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_text2_light.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_text2_outdoor.png`
- `frontend/test/features/context/presentation/goldens/context_hierarchy_text2_system.png`
