import 'dart:convert';
import 'dart:io';

/// The opt-in native producer; ordinary integration suites do not emit metrics.
const String deviceMetricsTarget = 'integration_test/device_metrics_test.dart';

/// The opt-in on-device speech producer (task 131): it emits the `stt…`
/// metrics of a class, on a physical phone or tablet or on a desktop.
const String speechMetricsTarget = 'integration_test/speech_metrics_test.dart';

/// The prefix of every metric [speechMetricsTarget] owns.
const String speechMetricPrefix = 'stt';

/// One measured run on a device class.
final class DeviceSample {
  /// Creates a sample.
  const DeviceSample({
    required this.device,
    required this.metric,
    required this.value,
  });

  /// Device id from devices.yaml.
  final String device;

  /// A metric declared for the class, such as coldStart or sttRtf.
  final String metric;

  /// The measured milliseconds, or the measured ratio for a metric whose
  /// name ends in `Rtf`.
  final num value;
}

/// A regression past the tolerance in devices.yaml.
final class DeviceRegression {
  /// Creates a regression.
  const DeviceRegression({
    required this.device,
    required this.metric,
    required this.margin,
  });

  /// Device that regressed.
  final String device;

  /// Metric that regressed.
  final String metric;

  /// How far past the tolerance: milliseconds, or a ratio for an `Rtf`
  /// metric.
  final num margin;

  /// The margin with its unit, for a report line.
  String get marginLabel => _isRatio(metric)
      ? '+${margin.toStringAsFixed(3)}'
      : '+${margin.round()}ms';
}

/// Whether [metric] is a dimensionless ratio rather than a duration.
bool _isRatio(String metric) => metric.endsWith('Rtf');

/// The metrics of [limits] that [suite] must emit: the `stt…` metrics for
/// [speechMetricsTarget], the rest for [deviceMetricsTarget], and every
/// declared metric for any other suite.
Set<String> suiteMetrics(String suite, Iterable<String> limits) => <String>{
  for (final String metric in limits)
    if (switch (suite) {
      speechMetricsTarget => metric.startsWith(speechMetricPrefix),
      deviceMetricsTarget => !metric.startsWith(speechMetricPrefix),
      _ => true,
    })
      metric,
};

/// Compares samples with the tolerances in [yaml]. An unknown device is skipped.
List<DeviceRegression> compareDevices({
  required String yaml,
  required List<DeviceSample> samples,
  required Set<String> attached,
  void Function(String)? onWarning,
}) {
  final Map<String, Map<String, num>> limits = _limits(yaml);
  final List<DeviceRegression> found = <DeviceRegression>[];
  for (final String id in limits.keys) {
    if (!attached.contains(id)) {
      (onWarning ?? stderr.writeln)('warning: device $id is not attached');
      continue;
    }
  }
  for (final DeviceSample sample in samples) {
    if (!attached.contains(sample.device)) continue;
    final num? limit = limits[sample.device]?[sample.metric];
    if (limit == null) continue;
    if (sample.value > limit) {
      found.add(
        DeviceRegression(
          device: sample.device,
          metric: sample.metric,
          margin: sample.value - limit,
        ),
      );
    }
  }
  return found;
}

/// Each class's tolerances: `<name>Ms: <positive int>` declares the duration
/// metric `<name>`, and `<name>Rtf: <positive decimal>` the ratio metric
/// `<name>Rtf`.
Map<String, Map<String, num>> _limits(String yaml) {
  final Map<String, Map<String, num>> limits = <String, Map<String, num>>{};
  String? id;
  final Map<String, num> current = <String, num>{};
  void store() {
    if (id == null) return;
    if (id.isEmpty || current.isEmpty || limits.containsKey(id)) {
      throw FormatException('Empty or duplicate device class/metrics: $id');
    }
    limits[id] = Map<String, num>.of(current);
  }

  final RegExp ratio = RegExp(r'^\w+Rtf:');
  for (final (int index, String raw) in yaml.split('\n').indexed) {
    final String line = raw.split('#').first.trim();
    if (line.startsWith('- id:')) {
      store();
      current.clear();
      id = line.substring('- id:'.length).trim();
    } else if (id != null && (line.contains('Ms:') || ratio.hasMatch(line))) {
      final int colon = line.indexOf(':');
      final String name = line.substring(0, colon);
      final bool isRatio = _isRatio(name);
      final String key = isRatio ? name : name.replaceFirst(RegExp(r'Ms$'), '');
      final String text = line.substring(colon + 1).trim();
      final num? value = isRatio ? double.tryParse(text) : int.tryParse(text);
      if (value == null ||
          !value.isFinite ||
          value <= 0 ||
          current.containsKey(key)) {
        throw FormatException(
          'Invalid or repeated metric at devices.yaml:${index + 1}',
        );
      }
      current[key] = value;
    }
  }
  store();
  if (limits.isEmpty) {
    throw const FormatException('devices.yaml declares no device classes.');
  }
  return limits;
}

/// Reads devices.yaml and exits 1 when a sample regresses.
Future<int> main(List<String> args) async {
  try {
    final Map<String, String> options = _options(args);
    final String yaml = await File('tool/devices.yaml').readAsString();
    final Set<String> selected =
        options['devices']?.split(',').toSet() ?? _limits(yaml).keys.toSet();
    final Map<String, String> identifiers = <String, String>{};
    for (final String mapping in (options['device'] ?? '').split(',')) {
      if (mapping.isEmpty) continue;
      final int colon = mapping.indexOf(':');
      if (colon < 1 || colon == mapping.length - 1) {
        throw const FormatException('Use --device=class:device-id.');
      }
      identifiers[mapping.substring(0, colon)] = mapping.substring(colon + 1);
    }
    final List<String> defines = <String>[
      for (final String define in (options['define'] ?? '').split(','))
        if (define.isNotEmpty) define,
    ];
    if (defines.any((String define) => define.indexOf('=') < 1)) {
      throw const FormatException('Use --define=NAME=value[,NAME=value].');
    }
    final Map<String, Object?> report = await runDeviceMatrix(
      yaml: yaml,
      selected: selected,
      identifiers: identifiers,
      suite: options['suite'] ?? deviceMetricsTarget,
      defines: defines,
    );
    final String json = const JsonEncoder.withIndent('  ').convert(report);
    stdout.writeln(json);
    final String? output = options['report'];
    if (output != null) {
      await File(output).writeAsString('$json\n', flush: true);
    }
    exitCode = report['exitCode']! as int;
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 2;
  }
  return exitCode;
}

/// Runs each configured, attached class and requires every metric the suite
/// owns (see [suiteMetrics]).
///
/// Integration scenarios print `TAPTURE_METRIC {"metric":"export",
/// "milliseconds":123}` after measuring real work, or `{"metric":"sttRtf",
/// "ratio":0.21}` for a ratio. Missing or malformed measurements fail rather
/// than turning an empty sample set into a pass. [defines] (`NAME=value`)
/// reach the suite as `--dart-define`s, after the suite's own opt-in.
Future<Map<String, Object?>> runDeviceMatrix({
  required String yaml,
  required Set<String> selected,
  required Map<String, String> identifiers,
  String suite = deviceMetricsTarget,
  List<String> defines = const <String>[],
  Future<ProcessResult> Function(String, List<String>)? run,
}) async {
  final Map<String, Map<String, num>> limits = _limits(yaml);
  if (selected.isEmpty ||
      selected.any((String id) => !limits.containsKey(id))) {
    throw const FormatException(
      'Select device classes declared in devices.yaml.',
    );
  }
  final Future<ProcessResult> Function(String, List<String>) execute =
      run ??
      (String command, List<String> arguments) =>
          Process.run(command, arguments, runInShell: Platform.isWindows);
  final ProcessResult discovery = await execute('flutter', <String>[
    'devices',
    '--machine',
  ]);
  if (discovery.exitCode != 0) {
    throw ProcessException(
      'flutter',
      const <String>['devices', '--machine'],
      '${discovery.stderr}',
      discovery.exitCode,
    );
  }
  final Object? devices = jsonDecode('${discovery.stdout}');
  if (devices is! List<Object?>) {
    throw const FormatException(
      'Flutter returned an invalid device inventory.',
    );
  }
  final Map<String, Map<String, Object?>> attachedDevices =
      <String, Map<String, Object?>>{
        for (final Object? device in devices)
          if (device is Map<String, Object?> && device['id'] is String)
            device['id']! as String: device,
      };
  final List<String> warnings = <String>[];
  final List<String> failures = <String>[];
  final List<DeviceSample> samples = <DeviceSample>[];
  final Map<String, Map<String, Object?>> evidence =
      <String, Map<String, Object?>>{};
  final Set<String> measured = <String>{};
  final bool nativeMetrics = suite == deviceMetricsTarget;
  final bool speechMetrics = suite == speechMetricsTarget;
  for (final String device in selected) {
    final Set<String> required = suiteMetrics(suite, limits[device]!.keys);
    if (required.isEmpty) {
      warnings.add('device $device declares no metric for $suite');
      continue;
    }
    final String? identifier = identifiers[device] ?? _identifier(yaml, device);
    if (identifier == null || !attachedDevices.containsKey(identifier)) {
      warnings.add(
        'device $device is not attached${identifier == null ? ' (no deviceId configured)' : ' ($identifier)'}',
      );
      continue;
    }
    final Map<String, Object?> inventory = attachedDevices[identifier]!;
    final String platform = '${inventory['targetPlatform']}';
    final bool mobile = platform.startsWith('android') || platform == 'ios';
    final bool desktop =
        platform.startsWith('windows') ||
        platform.startsWith('darwin') ||
        platform.startsWith('linux');
    if (nativeMetrics && (inventory['emulator'] != false || !mobile)) {
      failures.add(
        '$device requires a physical Android or iOS device; $identifier is $platform (emulator: ${inventory['emulator']}).',
      );
      continue;
    }
    if (speechMetrics &&
        (inventory['emulator'] != false || !(mobile || desktop))) {
      failures.add(
        '$device requires a physical Android or iOS device or a desktop; $identifier is $platform (emulator: ${inventory['emulator']}).',
      );
      continue;
    }
    measured.add(device);
    evidence[device] = <String, Object?>{
      'deviceId': identifier,
      'targetPlatform': inventory['targetPlatform'],
      'runMode': nativeMetrics
          ? 'profile'
          : speechMetrics
          ? 'speech suite'
          : 'custom suite',
    };
    final ProcessResult result = await execute('flutter', <String>[
      'test',
      suite,
      '-d',
      identifier,
      '--reporter=json',
      if (nativeMetrics) ...<String>[
        '--profile',
        '--dart-define=TAPTURE_DEVICE_METRICS=true',
      ],
      if (speechMetrics) '--dart-define=TAPTURE_SPEECH_METRICS=true',
      for (final String define in defines) '--dart-define=$define',
    ]);
    if (result.exitCode != 0) {
      failures.add(
        '$device integration suite failed (${result.exitCode}): ${result.stderr}',
      );
    }
    final Map<String, num> metrics = <String, num>{};
    for (final String line in '${result.stdout}'.split('\n')) {
      String message = line;
      try {
        final Object? event = jsonDecode(line);
        if (event is Map<String, Object?> && event['message'] is String) {
          message = event['message']! as String;
        }
      } on FormatException {
        // Flutter also writes tool diagnostics outside the JSON event stream.
      }
      const String framePrefix = 'TAPTURE_FRAME_METRIC ';
      if (message.startsWith(framePrefix)) {
        try {
          final Object? value = jsonDecode(
            message.substring(framePrefix.length),
          );
          if (value is! Map<String, Object?> ||
              value['photos'] != 2000 ||
              value['frames'] is! int ||
              (value['frames']! as int) < 20 ||
              evidence[device]!.containsKey('photoGrid')) {
            throw const FormatException(
              'invalid or repeated native frame evidence',
            );
          }
          evidence[device]!['photoGrid'] = value;
        } on FormatException {
          failures.add('$device malformed native frame measurement: $message');
        }
        continue;
      }
      const String prefix = 'TAPTURE_METRIC ';
      if (!message.startsWith(prefix)) continue;
      try {
        final Object? value = jsonDecode(message.substring(prefix.length));
        if (value is! Map<String, Object?> || value['metric'] is! String) {
          throw const FormatException('invalid metric');
        }
        final String metric = value['metric']! as String;
        final Object? measurement = _isRatio(metric)
            ? value['ratio']
            : value['milliseconds'];
        if (measurement is! num ||
            (!_isRatio(metric) && measurement is! int) ||
            !measurement.isFinite ||
            measurement < 0) {
          throw const FormatException('invalid metric');
        }
        if (!required.contains(metric) || metrics.containsKey(metric)) {
          throw const FormatException('unknown or repeated metric');
        }
        metrics[metric] = measurement;
        evidence[device]![metric] = value;
      } on FormatException {
        failures.add('$device malformed measurement: $message');
      }
    }
    for (final String metric in required) {
      final num? value = metrics[metric];
      if (value == null) {
        failures.add('$device missing measurement: $metric');
      } else {
        samples.add(DeviceSample(device: device, metric: metric, value: value));
      }
    }
  }
  final List<DeviceRegression> regressions = compareDevices(
    yaml: yaml,
    samples: samples,
    attached: measured,
    onWarning: (_) {},
  );
  failures.addAll(
    regressions.map(
      (DeviceRegression row) =>
          '${row.device} ${row.metric} ${row.marginLabel}',
    ),
  );
  if (measured.isEmpty) {
    failures.add('No configured device class was measured.');
  }
  return <String, Object?>{
    'exitCode': failures.isEmpty ? 0 : 1,
    'warnings': warnings,
    'failures': failures,
    'evidence': evidence,
    'samples': <Map<String, Object?>>[
      for (final DeviceSample sample in samples)
        <String, Object?>{
          'device': sample.device,
          'metric': sample.metric,
          if (_isRatio(sample.metric)) ...<String, Object?>{
            'ratio': sample.value,
            'limit': limits[sample.device]![sample.metric],
          } else ...<String, Object?>{
            'milliseconds': sample.value,
            'limitMs': limits[sample.device]![sample.metric],
          },
        },
    ],
  };
}

String? _identifier(String yaml, String selected) {
  String? current;
  for (final String raw in yaml.split('\n')) {
    final String line = raw.split('#').first.trim();
    if (line.startsWith('- id:')) current = line.substring(5).trim();
    if (current == selected && line.startsWith('deviceId:')) {
      final String id = line.substring(9).trim();
      return id.isEmpty || id == 'null' ? null : id;
    }
  }
  return null;
}

Map<String, String> _options(List<String> args) {
  final Map<String, String> result = <String, String>{};
  for (int index = 0; index < args.length; index++) {
    final String argument = args[index];
    final int separator = argument.indexOf('=');
    final String key = separator == -1
        ? argument
        : argument.substring(0, separator);
    if (!const <String>{
      '--devices',
      '--device',
      '--suite',
      '--report',
      '--define',
    }.contains(key)) {
      throw FormatException('Unknown option: $argument');
    }
    final String value;
    if (separator >= 0) {
      value = argument.substring(separator + 1);
    } else if (++index < args.length && !args[index].startsWith('--')) {
      value = args[index];
    } else {
      throw FormatException('Missing value: $key');
    }
    if (value.isEmpty || result.containsKey(key.substring(2))) {
      throw FormatException('Empty or repeated option: $key');
    }
    result[key.substring(2)] = value;
  }
  return result;
}
