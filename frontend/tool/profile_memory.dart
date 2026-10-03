import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// A measured process footprint, including the complete post-cleanup window.
/// RSS is sampled; a returned-to-baseline claim is never inferred from disposal.
typedef MemoryProfile = ({
  String scenario,
  int baseline,
  int peak,
  List<int> settled,
  int samples,
  int elapsedMs,
  Map<String, int> resourcesBefore,
  Map<String, int> resourcesAfter,
});

/// Samples real RSS while [operation] runs and after its resources are closed.
/// [settleWindow] is a measurement window, not a retry delay or forced GC.
Future<MemoryProfile> profileMemory({
  required String scenario,
  required Future<void> Function() operation,
  required Map<String, int> Function() resources,
  Duration interval = const Duration(milliseconds: 10),
  Duration settleWindow = const Duration(seconds: 1),
  int Function()? readRss,
}) async {
  if (interval <= Duration.zero || settleWindow < interval) {
    throw ArgumentError('The settling window must contain an RSS sample.');
  }
  final int Function() rss = readRss ?? () => ProcessInfo.currentRss;
  final int baseline = rss();
  final Map<String, int> before = Map<String, int>.of(resources());
  int peak = baseline;
  int samples = 1;
  bool settling = false;
  Object? samplingError;
  final List<int> settled = <int>[];
  void sample() {
    final int value = rss();
    if (value <= 0) {
      throw StateError('RSS is unavailable.');
    }
    samples++;
    peak = max(peak, value);
    if (settling) {
      settled.add(value);
    }
  }

  if (baseline <= 0) {
    throw StateError('RSS is unavailable.');
  }
  final Stopwatch watch = Stopwatch()..start();
  final Timer sampler = Timer.periodic(interval, (_) {
    try {
      sample();
    } on Object catch (error) {
      samplingError ??= error;
    }
  });
  try {
    await operation();
    sample();
    settling = true;
    await Future<void>.delayed(settleWindow);
    sample();
    final Object? failed = samplingError;
    if (failed != null) throw failed;
    return (
      scenario: scenario,
      baseline: baseline,
      peak: peak,
      settled: List<int>.unmodifiable(settled),
      samples: samples,
      elapsedMs: watch.elapsedMilliseconds,
      resourcesBefore: before,
      resourcesAfter: Map<String, int>.of(resources()),
    );
  } finally {
    sampler.cancel();
    watch.stop();
  }
}

/// Explicit budgets for a measured run. Retained RSS uses the *last* sample,
/// so a transient low sample cannot hide memory retained at the end.
List<String> memoryViolations(
  MemoryProfile profile, {
  required int maxAdditionalRss,
  required int maxRetainedRss,
}) {
  if (maxAdditionalRss < 0 || maxRetainedRss < 0) {
    throw ArgumentError('Memory budgets must be nonnegative.');
  }
  final List<String> failures = <String>[];
  if (profile.samples < 2 || profile.settled.isEmpty) {
    failures.add('${profile.scenario}: no post-cleanup RSS measurement');
  }
  if (profile.peak - profile.baseline > maxAdditionalRss) {
    failures.add(
      '${profile.scenario}: peak RSS exceeds $maxAdditionalRss bytes above baseline',
    );
  }
  if (profile.settled.isNotEmpty &&
      profile.settled.last - profile.baseline > maxRetainedRss) {
    failures.add(
      '${profile.scenario}: retained RSS exceeds $maxRetainedRss bytes above baseline',
    );
  }
  for (final String name in <String>{
    ...profile.resourcesBefore.keys,
    ...profile.resourcesAfter.keys,
  }) {
    final int before = profile.resourcesBefore[name] ?? 0;
    final int after = profile.resourcesAfter[name] ?? 0;
    if (after != before) {
      failures.add('${profile.scenario}: $name changed from $before to $after');
    }
  }
  return failures;
}

/// Machine-readable evidence; budgets remain in the run that evaluates it.
Map<String, Object?> memoryProfileJson(MemoryProfile profile) =>
    <String, Object?>{
      'scenario': profile.scenario,
      'baselineRss': profile.baseline,
      'peakRss': profile.peak,
      'settledRss': profile.settled,
      'samples': profile.samples,
      'elapsedMs': profile.elapsedMs,
      'resourcesBefore': profile.resourcesBefore,
      'resourcesAfter': profile.resourcesAfter,
    };

/// Validates evidence produced by integration_test/memory_test.dart. The
/// integration runner remains tool/verify.dart; no physical result is invented.
Future<int> main(List<String> args) async {
  if (args.length != 3 ||
      int.tryParse(args[1]) == null ||
      int.tryParse(args[2]) == null) {
    stderr.writeln(
      'usage: dart run tool/profile_memory.dart <report.json> <peak-bytes> <retained-bytes>',
    );
    exitCode = 64;
    return exitCode;
  }
  try {
    final Object? decoded = jsonDecode(await File(args[0]).readAsString());
    if (decoded is! List<Object?>) {
      throw const FormatException('Expected an array of measured scenarios.');
    }
    final List<MemoryProfile> profiles = decoded
        .map(parseMemoryProfile)
        .toList();
    final List<String> failures = validateMemoryProfiles(
      profiles,
      maxAdditionalRss: int.parse(args[1]),
      maxRetainedRss: int.parse(args[2]),
    );
    for (final String failure in failures) {
      stderr.writeln(failure);
    }
    stdout.writeln(
      'Measured ${profiles.length} scenarios; ${failures.length} violations.',
    );
    exitCode = failures.isEmpty ? 0 : 1;
  } on Object catch (error) {
    stderr.writeln('Invalid memory evidence: $error');
    exitCode = 1;
  }
  return exitCode;
}

/// Rejects missing/repeated scenarios as well as budget and lifetime failures.
List<String> validateMemoryProfiles(
  List<MemoryProfile> profiles, {
  required int maxAdditionalRss,
  required int maxRetainedRss,
}) {
  const Set<String> expected = <String>{
    'capture-200',
    'export-5000',
    'merge-2000-photos',
  };
  final List<String> failures = <String>[];
  final Set<String> seen = <String>{};
  for (final MemoryProfile profile in profiles) {
    if (!seen.add(profile.scenario)) {
      failures.add('${profile.scenario}: repeated scenario');
    }
    if (!expected.contains(profile.scenario)) {
      failures.add('${profile.scenario}: unknown scenario');
    }
    failures.addAll(
      memoryViolations(
        profile,
        maxAdditionalRss: maxAdditionalRss,
        maxRetainedRss: maxRetainedRss,
      ),
    );
  }
  for (final String missing in expected.difference(seen)) {
    failures.add('$missing: missing measured scenario');
  }
  return failures;
}

/// Strict decoding prevents malformed metrics from being counted as zero.
MemoryProfile parseMemoryProfile(Object? value) {
  if (value is! Map<String, Object?> || value['scenario'] is! String) {
    throw const FormatException('Invalid scenario.');
  }
  int integer(String key) {
    final Object? found = value[key];
    if (found is! int || found < 0) {
      throw FormatException('Invalid $key.');
    }
    return found;
  }

  final Object? settled = value['settledRss'];
  if (settled is! List<Object?> ||
      settled.any((Object? rss) => rss is! int || rss <= 0)) {
    throw const FormatException('Invalid settledRss.');
  }
  Map<String, int> counts(String key) {
    final Object? found = value[key];
    if (found is! Map<String, Object?> ||
        found.values.any((Object? count) => count is! int || count < 0)) {
      throw FormatException('Invalid $key.');
    }
    return found.cast<String, int>();
  }

  final int baseline = integer('baselineRss');
  final int peak = integer('peakRss');
  if (baseline == 0 || peak < baseline) {
    throw const FormatException('Invalid RSS baseline/peak.');
  }
  return (
    scenario: value['scenario']! as String,
    baseline: baseline,
    peak: peak,
    settled: settled.cast<int>(),
    samples: integer('samples'),
    elapsedMs: integer('elapsedMs'),
    resourcesBefore: counts('resourcesBefore'),
    resourcesAfter: counts('resourcesAfter'),
  );
}
