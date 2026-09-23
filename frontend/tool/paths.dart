/// The directory layout of `frontend/lib/`, as constants.
///
/// Every guardrail that has an opinion about where a file belongs reads it
/// from here (dev-plan 01-orchestration/004). A checker that hardcodes its own
/// copy of the list drifts from this one the first time the layout changes,
/// and then two guardrails disagree about what the architecture is.
library;

/// The root of the Flutter application's Dart sources, relative to
/// `frontend/`.
const String libRoot = 'lib';

/// The three top-level areas, and no fourth
/// (`frontend/.rules/01-structure.md`, FE-STR-02).
///
/// `app/` is the shell, `core/` is everything shared, `features/` is one
/// folder per feature.
const List<String> topLevelAreas = <String>['app', 'core', 'features'];

/// The shared subsystems under `lib/core/`.
///
/// This list is the architecture's vocabulary for shared code: a helper that
/// fits none of these belongs to a feature, or the list is missing an entry
/// and gaining one is a decision, not a side effect of writing a file.
const List<String> coreDirectories = <String>[
  'ai',
  'audio',
  'background',
  'barcode',
  'bundle',
  'camera',
  'cloud',
  'concurrency',
  'constants',
  'copy',
  'db',
  'device',
  'errors',
  'export',
  'feedback',
  'files',
  'hash',
  'ids',
  'import',
  'lifecycle',
  'logging',
  'location',
  'naming',
  'network',
  'normalise',
  'permissions',
  'security',
  'serialisation',
  'team',
  'time',
  'validation',
  'widgets',
];

/// The features under `lib/features/`, one folder each.
const List<String> featureDirectories = <String>[
  'account',
  'capture',
  'cloud',
  'context',
  'exports',
  'feedback',
  'import',
  'meetings',
  'merge',
  'onboarding',
  'processing',
  'projects',
  'quality',
  'records',
  'reference',
  'review',
  'settings',
  'templates',
];

/// The layers inside every feature, in dependency order
/// (`presentation -> domain <- data`, FE-STR-03 and FE-STR-04).
const List<String> featureLayers = <String>['data', 'domain', 'presentation'];

/// Every directory that must exist under [libRoot], in the order a reader
/// would walk them.
///
/// Each one owns a barrel named after it, which is both what makes the
/// directory exist in a fresh checkout and the file a later task exports from.
List<String> get requiredDirectories => <String>[
  'app',
  'core',
  for (final String name in coreDirectories) 'core/$name',
  'features',
  for (final String name in featureDirectories) ...<String>[
    'features/$name',
    for (final String layer in featureLayers) 'features/$name/$layer',
  ],
];

/// The barrel a directory owns, named after the directory itself: `core/db`
/// holds `db.dart`, `features/capture/domain` holds `domain.dart`.
///
/// Returns null for the containers that hold barrels rather than being one —
/// `core/` and `features/` — because a barrel re-exporting every subsystem or
/// every feature is the coupling FE-STR-04 and FE-STR-08 exist to prevent.
String? barrelFor(String directory) {
  if (directory == 'core' || directory == 'features') {
    return null;
  }
  final String name = directory.split('/').last;
  return '$directory/$name.dart';
}
