# 096 — Scoped generated localization catalogue and pseudo-locale verification

**Implementation step:** 27.02

**Phase** 27 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

**Depends on** [003](../03-design-system/003-design-system.md), [006](../06-app-shell/006-application-shell.md), [035](../24-product-refinements/035-mark-required-optional-fields.md)

**Implementation started:** Yes

## Implement

Use the SDK's standard `gen-l10n` pipeline instead of the static English-only UI catalogue. Store English ARB messages and a generated pseudo-locale inside `core/copy`, preserving the three-area architecture. Resolve copy through the widget's inherited locale; background/domain failures retain the stable English facade. Changing the locale must preserve drafts and user data, and separate app instances must not change each other's language. Format dates, numbers and plurals with the active locale without mutating `Intl.defaultLocale`.

Build on the shared design system, application shell and field copy. Task [023](023-hardening.md) verifies the resulting integrated localization behavior; its whole-product acceptance is not a prerequisite for implementing this catalogue.

Dependency contract (FE-FLOW-06): `flutter_localizations`, version `sdk` pinned by the repository's Flutter SDK, BSD-3-Clause under the Flutter SDK licence. Purpose: generated catalogue delegates and maintained framework localization. Replaces English-only UI copy and a hand-written localization runtime. Reuses the existing approved `intl` dependency. Generated Dart output is committed so a clean checkout builds without an extraction step.

## Files

- `frontend/l10n.yaml`
- `frontend/lib/core/copy/l10n/app_en.arb`, `app_en_XA.arb`, `app_localizations.g.dart`, `app_localizations_en.g.dart`
- `frontend/lib/core/copy/copy.dart`, `localized_copy.dart`, `localized_message.dart`, `copy_messages.g.dart`, `localized_copy_resolver.g.dart`
- `frontend/lib/app/locale_controller.dart`, `app.dart` and production UI copy consumers
- `frontend/tool/generate_pseudo_locale.dart`, `generate_copy_messages.dart`, `check_l10n.dart`, `allowlist.yaml`
- `frontend/lib/core/copy/domain_copy.g.dart`, `frontend/tool/generate_domain_copy.dart`, `probe_domain_copy.dart`, `domain_copy_imports.g.dart`, and explicit pure feature-domain barrels
- `frontend/test/core/copy/localization_test.dart`, `localized_message_test.dart`, `test/tool/check_l10n_test.dart`, `test/responsive/pseudo_locale_test.dart`

## Definition of done

- [ ] Generated English catalogue preserves the existing public copy contract; both catalogues have every key, description and matching placeholder contract.
- [ ] SDK localization dependency, licence and replacement contract pass the dependency gate.
- [ ] Every rendered production label resolves from the widget's current catalogue; negative widget-literal fixtures fail the copy gate.
- [ ] ICU plural branches and quoted messages survive pseudo generation with at least 35 percent visible-text expansion.
- [ ] Dates/numbers use the selected locale without mutating process-wide `Intl.defaultLocale`; drafts and user-provided values survive language changes.
- [ ] Independent app instances resolve their own locales without a global mutable locale.
- [ ] Serializable semantic messages preserve headless English audit values and render failure, recovery, form and persisted queue details through the inherited catalogue; malformed or newer descriptors retain their explicit fallback.
- [ ] All 35 primary collection fixtures pass the complete pseudo-locale size/orientation/text-scale/theme matrix.
- [ ] Tests and frontend verification pass against the final tree.

Implementation checkpoint — 2026-10-01: generated catalogue, semantic factories/resolver, failure/recovery DTOs and form metadata are implemented in source. Queue and destination diagnostics retain optional descriptor JSON beside English audit strings. Shared error panels, snacks, progress rows and field summaries resolve the inherited catalogue; nested messages retain user labels as data. The small generated DomainCopy catalogue retains only domain-used messages and required core dependencies. A plain Dart VM probe importing every migrated domain file passed, including real preset, lookup and field-validation failures; pure domain ports keep platform/presentation exports out of that graph. Catalogue/literal checks and syntax parsing passed, with regression sources for persisted descriptors, malformed arguments, ICU values, pseudo failures/recovery, locale isolation and draft preservation. Final focused execution and the pseudo matrix remain pending, so acceptance stays open. Physical device capture/traversal, hinged layouts and timing budgets remain in task023.
