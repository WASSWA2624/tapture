import 'dart:convert';
import 'dart:io';

import 'paths.dart';

/// The project's own analyzer configuration, and the one that narrows it for
/// the shared surface under `lib/core/`.
const String _rootOptions = 'analysis_options.yaml';
const String _coreOptions = 'lib/core/analysis_options.yaml';

/// The shared rule set every rule here is layered on top of.
const String _flutterLints = 'package:flutter_lints/flutter.yaml';

/// One line saying what a public member is for, required in `core/` only.
const String _documentationRule = 'public_member_api_docs';

/// Strict type checks that must be on under `analyzer: language:`. Without
/// them the analyzer accepts an implicit downcast, an inferred `dynamic` and a
/// raw generic, and the type system stops being the first reviewer.
const List<String> _requiredLanguageFlags = <String>[
  'strict-casts',
  'strict-inference',
  'strict-raw-types',
];

/// Lint rules this project turns on beyond the shared set: const usage, sorted
/// directives, unnecessary awaits, and the one unused element the analyzer
/// does not report on its own.
const List<String> _requiredRules = <String>[
  'avoid_unused_constructor_parameters',
  'directives_ordering',
  'prefer_const_constructors',
  'prefer_const_constructors_in_immutables',
  'prefer_const_declarations',
  'prefer_const_literals_to_create_immutables',
  'unnecessary_await_in_return',
];

/// Diagnostics the analyzer raises as a warning or a hint that this project
/// reads as an error: what the strict checks report, code nothing reaches, a
/// broken annotation contract, and a directive or literal that does not say
/// what it appears to say.
///
/// The analyzer has no wildcard promotion, so every code is named. The
/// severity check below catches a lint rule that is enabled and never
/// promoted; this list is what catches one of these — which no rule enables —
/// being dropped.
const List<String> _requiredPromotions = <String>[
  'assignment_of_do_not_store',
  'body_might_complete_normally_catch_error',
  'duplicate_hidden_name',
  'duplicate_import',
  'duplicate_shown_name',
  'equal_elements_in_set',
  'equal_keys_in_map',
  'inference_failure_on_collection_literal',
  'inference_failure_on_function_invocation',
  'inference_failure_on_function_return_type',
  'inference_failure_on_generic_invocation',
  'inference_failure_on_instance_creation',
  'inference_failure_on_uninitialized_variable',
  'inference_failure_on_untyped_parameter',
  'invalid_factory_method_impl',
  'invalid_language_version_override',
  'missing_override_of_must_be_overridden',
  'non_const_call_to_literal_constructor',
  'nullable_type_in_catch_clause',
  'override_on_non_overriding_member',
  'pattern_never_matches_value_type',
  'return_of_do_not_store',
  'strict_raw_type',
  'text_direction_code_point_in_literal',
  'unnecessary_nan_comparison',
  'unnecessary_null_comparison',
  'unnecessary_wildcard_pattern',
  'unused_catch_clause',
  'unused_catch_stack',
  'unused_element',
  'unused_field',
  'unused_import',
  'unused_label',
  'unused_local_variable',
  'unused_result',
  'unused_shown_name',
];

/// Checks the analyzer configuration, printing one line per violation.
///
/// Takes the directory to check, defaulting to the working directory.
Future<int> main(List<String> args) async {
  final Directory root = Directory(
    args.isEmpty ? Directory.current.path : args.first,
  );
  final List<({String file, int line, String message})> violations =
      findAnalyzerConfigViolations(root);
  for (final ({String file, int line, String message}) violation
      in violations) {
    stderr.writeln('${violation.file}:${violation.line}: ${violation.message}');
  }
  stdout.writeln(
    violations.isEmpty
        ? 'analyzer configuration: strict'
        : 'analyzer configuration: ${violations.length} violation(s)',
  );
  exitCode = violations.isEmpty ? 0 : 1;
  return exitCode;
}

/// Reports every way the configuration in [root] falls short of the analyzer
/// this project reviews with, each with the file and the line that has to
/// change to fix it.
List<({String file, int line, String message})> findAnalyzerConfigViolations(
  Directory root,
) {
  return <({String file, int line, String message})>[
    ..._rootOptionsViolations(root),
    ..._coreOptionsViolations(root),
  ];
}

Iterable<({String file, int line, String message})> _rootOptionsViolations(
  Directory root,
) sync* {
  final File file = File('${root.path}/$_rootOptions');
  if (!file.existsSync()) {
    yield (
      file: _rootOptions,
      line: 0,
      message: 'the project has no $_rootOptions',
    );
    return;
  }
  final _Options options = _Options.resolve(file, root, _rootOptions);
  yield* options.failures;
  if (!options.includes.contains(_flutterLints)) {
    yield (
      file: _rootOptions,
      line: 1,
      message: 'does not include $_flutterLints',
    );
  }
  for (final String flag in _requiredLanguageFlags) {
    final ({String file, int line, String value})? setting =
        options.language[flag];
    if (setting == null) {
      yield (
        file: _rootOptions,
        line: options.lineOf('analyzer.language'),
        message: 'analyzer: language: does not set $flag',
      );
    } else if (setting.value != 'true') {
      yield (
        file: setting.file,
        line: setting.line,
        message: '$flag is ${setting.value}, expected true',
      );
    }
  }
  for (final String rule in _requiredRules) {
    if (!options.rules.containsKey(rule)) {
      yield (
        file: _rootOptions,
        line: options.lineOf('linter.rules'),
        message: 'the linter does not enable $rule',
      );
    }
  }
  for (final String code in _requiredPromotions) {
    if (!options.errors.containsKey(code)) {
      yield (
        file: _rootOptions,
        line: options.lineOf('analyzer.errors'),
        message: '$code is a warning, not an error',
      );
    }
  }
  yield* _severityViolations(options);
}

Iterable<({String file, int line, String message})> _coreOptionsViolations(
  Directory root,
) sync* {
  final File file = File('${root.path}/$_coreOptions');
  if (!file.existsSync()) {
    yield (
      file: _coreOptions,
      line: 0,
      message:
          'the shared surface has no $_coreOptions, so $_documentationRule is '
          'required nowhere',
    );
    return;
  }
  final _Options options = _Options.resolve(file, root, _coreOptions);
  yield* options.failures;
  final bool includesProject = options.includes.any(
    (String include) => include.endsWith(_rootOptions),
  );
  if (!includesProject) {
    yield (
      file: _coreOptions,
      line: 1,
      message: 'does not include the project $_rootOptions',
    );
  }
  if (!options.rules.containsKey(_documentationRule)) {
    yield (
      file: _coreOptions,
      line: options.lineOf('linter.rules'),
      message: 'the linter does not enable $_documentationRule',
    );
  }
  yield* _severityViolations(options);
}

/// Reports every rule that reports as something other than an error: one that
/// is enabled and never promoted, and one an entry has demoted.
Iterable<({String file, int line, String message})> _severityViolations(
  _Options options,
) sync* {
  for (final MapEntry<String, ({String file, int line})> rule
      in options.rules.entries) {
    if (!options.errors.containsKey(rule.key)) {
      yield (
        file: options.path,
        line: options.lineOf('analyzer.errors'),
        message:
            '${rule.key}, enabled in ${rule.value.file}, reports as a '
            'suggestion rather than an error',
      );
    }
  }
  for (final MapEntry<String, ({String file, int line, String value})> promotion
      in options.errors.entries) {
    if (promotion.value.value != 'error') {
      yield (
        file: promotion.value.file,
        line: promotion.value.line,
        message:
            '${promotion.key} is ${promotion.value.value}; the analyzer is the '
            'gate, so nothing it finds sits below an error',
      );
    }
  }
}

/// An analyzer options file and everything it includes, flattened to the
/// sections this guardrail reads.
///
/// It understands the subset of YAML these files use — nested maps of scalars,
/// and sequences of scalars — and remembers where every entry came from, so a
/// violation can name the file and the line that has to change.
class _Options {
  _Options._(this.path);

  /// Reads [file], named [path] in a report, and every file it includes.
  /// Package includes are resolved through the package graph of [root].
  factory _Options.resolve(File file, Directory root, String path) {
    final _Options options = _Options._(path);
    options._read(file, root, path, isRoot: true);
    return options;
  }

  /// The path of the file this was read from, as a reader would write it.
  final String path;

  /// Include targets, in the order they were read.
  final List<String> includes = <String>[];

  /// `analyzer: language:` flags, by name.
  final Map<String, ({String file, int line, String value})> language =
      <String, ({String file, int line, String value})>{};

  /// `analyzer: errors:` severities, by diagnostic code.
  final Map<String, ({String file, int line, String value})> errors =
      <String, ({String file, int line, String value})>{};

  /// `linter: rules:` entries, by rule name.
  final Map<String, ({String file, int line})> rules =
      <String, ({String file, int line})>{};

  /// Includes that could not be read, reported like any other violation.
  final List<({String file, int line, String message})> failures =
      <({String file, int line, String message})>[];

  final Map<String, int> _sections = <String, int>{};
  final Set<String> _visited = <String>{};

  /// The line [section] starts on, or 0 when the file has no such section for
  /// a violation to point at.
  int lineOf(String section) => _sections[section] ?? 0;

  void _read(File file, Directory root, String display, {bool isRoot = false}) {
    if (!_visited.add(file.absolute.path)) {
      return;
    }
    if (!file.existsSync()) {
      failures.add((
        file: display,
        line: 0,
        message: 'the included options file $display does not exist',
      ));
      return;
    }
    final List<String> included = <String>[];
    final List<({int indent, String key})> stack =
        <({int indent, String key})>[];
    final List<String> lines = file.readAsLinesSync();
    for (int index = 0; index < lines.length; index++) {
      final String raw = lines[index];
      final String trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      final int indent = raw.length - raw.trimLeft().length;
      final int line = index + 1;
      if (trimmed.startsWith('- ')) {
        _add(
          _pathOf(stack),
          trimmed.substring(2).trim(),
          display,
          line,
          included,
        );
        continue;
      }
      while (stack.isNotEmpty && stack.last.indent >= indent) {
        stack.removeLast();
      }
      final int separator = trimmed.indexOf(':');
      if (separator == -1) {
        continue;
      }
      stack.add((indent: indent, key: trimmed.substring(0, separator).trim()));
      final String section = _pathOf(stack);
      if (isRoot) {
        _sections.putIfAbsent(section, () => line);
      }
      final String value = trimmed.substring(separator + 1).trim();
      if (value.isNotEmpty) {
        _add(section, value, display, line, included);
      }
    }
    for (final String include in included) {
      final File? target = _includedFile(include, file, root);
      if (target == null) {
        failures.add((
          file: display,
          line: 0,
          message: 'cannot resolve the include $include',
        ));
        continue;
      }
      _read(target, root, include);
    }
  }

  void _add(
    String section,
    String value,
    String display,
    int line,
    List<String> included,
  ) {
    const String languageSection = 'analyzer.language.';
    const String errorsSection = 'analyzer.errors.';
    if (section == 'include') {
      includes.add(value);
      included.add(value);
    } else if (section == 'linter.rules') {
      rules.putIfAbsent(value, () => (file: display, line: line));
    } else if (section.startsWith(languageSection)) {
      language.putIfAbsent(
        section.substring(languageSection.length),
        () => (file: display, line: line, value: value),
      );
    } else if (section.startsWith(errorsSection)) {
      errors.putIfAbsent(
        section.substring(errorsSection.length),
        () => (file: display, line: line, value: value),
      );
    }
  }

  String _pathOf(List<({int indent, String key})> stack) {
    return stack.map((({int indent, String key}) entry) => entry.key).join('.');
  }
}

/// Resolves one `include:` target, which is either a path relative to the
/// including file or a `package:` URI resolved through the package graph.
File? _includedFile(String include, File from, Directory root) {
  if (!include.startsWith('package:')) {
    return File('${from.parent.path}/$include');
  }
  final Uri uri = Uri.parse(include);
  final String name = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
  final String relative = uri.pathSegments.skip(1).join('/');
  final File config = File('${root.path}/.dart_tool/package_config.json');
  if (name.isEmpty || relative.isEmpty || !config.existsSync()) {
    return null;
  }
  final Object? decoded = jsonDecode(config.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    return null;
  }
  final Object? packages = decoded['packages'];
  if (packages is! List<Object?>) {
    return null;
  }
  for (final Object? entry in packages) {
    if (entry is! Map<String, Object?>) {
      continue;
    }
    final Object? packageRoot = entry['rootUri'];
    if (entry['name'] != name || packageRoot is! String) {
      continue;
    }
    final Object? packageLib = entry['packageUri'];
    final Uri base = Uri.file(config.path).resolve(_asDirectory(packageRoot));
    final Uri lib = base.resolve(
      _asDirectory(packageLib is String ? packageLib : libRoot),
    );
    return File(lib.resolve(relative).toFilePath());
  }
  return null;
}

String _asDirectory(String uri) => uri.endsWith('/') ? uri : '$uri/';
