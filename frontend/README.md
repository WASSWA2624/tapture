# tapture

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Database code generation

Drift schema and companions are generated and committed (FE-CODE-13). After
changing `lib/core/db/app_database.dart` or a table it includes, regenerate in
the same change:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Template catalogue generation

The full template catalogue under `assets/templates/catalogue/` and the list of
every shipped template in `../resources/template-library.md` are generated from
`../resources/templates.md` (specification §13.7). The typed record-type packs
and per-field corrections live in `tool/template_catalogue/`. After changing any
of them, regenerate in the same change and check the result:

```sh
dart run tool/build_template_catalogue.dart
dart run tool/check_templates.dart
```

`dart run tool/build_template_catalogue.dart --check` exits 1 when a committed
file has drifted from its source.
