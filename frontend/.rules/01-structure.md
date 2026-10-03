# 01 — Structure

*Enforced by dev-plan task 001 (folder scaffold, layering test and naming checker).*

## FE-STR-01 — The app lives in `frontend/`
The Flutter application is the whole of `frontend/`. Nothing outside `frontend/lib`, `frontend/test`,
`frontend/tool`, `frontend/assets` and the platform folders belongs to it. The backend, the plan and the
specification are siblings, never imports.

## FE-STR-02 — Three top-level areas, and no fourth
`lib/app/` is the shell (entry, router, theme, navigation). `lib/core/` is everything shared. `lib/features/` is
one folder per feature. A file that fits none of these is a sign the design is wrong, not that a fourth area is needed.

## FE-STR-03 — Feature-first, layered inside
Every feature is `data/`, `domain/`, `presentation/`. Domain holds models, repository interfaces and pure logic.
Data holds repository implementations and data sources. Presentation holds screens, controllers and widgets.

## FE-STR-04 — Dependency direction is one-way
`presentation -> domain <- data`. Domain imports neither of the others. `core/` never imports `features/`. A feature
never imports another feature's internals — only its barrel.

## FE-STR-05 — Domain is pure Dart
No file under `domain/` may import Flutter, Drift, a HTTP client or any provider SDK. If a domain type needs a
platform capability, it declares an interface and someone else implements it.

## FE-STR-06 — One public type per file
The file is named after the type: `capture_session.dart` holds `CaptureSession`. Private helpers may share the file;
a second public class means a second file.

## FE-STR-07 — Predictable file names
Screens end `_screen.dart`, controllers `_controller.dart`, repositories `_repository.dart` and
`_repository_impl.dart`, providers `_providers.dart`, widgets are named after what they render.

## FE-STR-08 — Explicit public barrels per feature
Cross-feature imports go through `features/<name>/<name>.dart`. Pure domain consumers use the explicit
`features/<name>/domain/domain.dart` port, which exports only domain models, interfaces and logic; this keeps
presentation and platform implementations out of headless workers. All other feature files remain internal.

## FE-STR-09 — Promotion happens immediately
The moment a widget, helper or extension is needed by a second feature, it moves to `core/` in the same pull request.
Copying is never the cheaper option; it is the more expensive one, paid later.

## FE-STR-10 — Files stay readable
Above roughly 300 lines, split by responsibility. A 900-line screen is several widgets that have not been extracted yet.

## FE-STR-11 — Platform access is wrapped
Camera, files, permissions, secure storage, connectivity and speech are reached only through a `core/` service with an
interface and a fake. No feature calls a plugin directly.

## FE-STR-12 — Assets are typed
Asset paths come from generated constants, never from a string literal at the call site. Assets live under
`assets/<kind>/` and are declared in `pubspec.yaml`.
