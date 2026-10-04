/// The directory layout of `frontend/lib/`, as constants.
///
/// Every guardrail that has an opinion about where a file belongs reads it
/// from here (dev-plan task 001). A checker that hardcodes its own
/// copy of the list drifts from this one the first time the layout changes,
/// and then two guardrails disagree about what the architecture is.
/// `check_structure.dart` fails a `tool/check_*.dart` file that writes one of
/// these roots as a literal of its own.
library;

/// The root of the Flutter application's Dart sources, relative to
/// `frontend/`.
const String libRoot = 'lib';

/// The design-system catalogue under [libRoot], whose widgets each owe a
/// behaviour or golden test.
const String coreWidgetsDirectory = 'core/widgets';

/// The folders, relative to `frontend/`, that may never hold a compiled-in
/// key (FE-SEC-02): the sources, both native projects and the bundled assets.
const List<String> secretScanRoots = <String>[
  libRoot,
  'android',
  'ios',
  'assets',
];

/// Every root a checker scans, which is what a checker may not spell out
/// for itself.
List<String> get checkerRoots => <String>[
  ...secretScanRoots,
  coreWidgetsDirectory,
];

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
  'assets',
  'audio',
  'backend',
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
  'location',
  'logging',
  'naming',
  'network',
  'normalise',
  'permissions',
  'security',
  'serialisation',
  'speech',
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
