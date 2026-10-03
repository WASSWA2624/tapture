import 'dart:convert';
import 'dart:io';

/// The opt-in native producer; ordinary integration suites do not emit metrics.
const String deviceMetricsTarget = 'integration_test/device_metrics_test.dart';

/// One measured run on a device class.
final class DeviceSample {
  /// Creates a sample.
  const DeviceSample({
    required this.device,
    required this.metric,
    required this.milliseconds,
  });

  /// Device id from devices.yaml.
  final String device;

  /// coldStart, shutter, export or merge.
  final String metric;

  /// Measured duration.
  final int milliseconds;
}

/// A regression past the tolerance in devices.yaml.
final class DeviceRegression {
  /// Creates a regression.
  const DeviceRegression({
    required this.device,
    required this.metric,
    required this.marginMs,
  });

  /// Device that regressed.
  final String device;

  /// Metric that regressed.
  final String metric;

  /// How far past the tolerance, in milliseconds.
  final int marginMs;
}

/// Compares samples with the tolerances in [yaml]. An unknown device is skipped.
List<DeviceRegression> compareDevices({
  required String yaml,
  required List<DeviceSample> samples,
  required Set<String> attached,
  void Function(String)? onWarning,
}) {
  final Map<String, Map<String, int>> limits = _limits(yaml);
  final List<DeviceRegression> found = <DeviceRegression>[];
  for (final String id in limits.keys) {
    if (!attached.contains(id)) {
      (onWarning ?? stderr.writeln)('warning: device $id is not attached');
      continue;
    }
  }
  for (final DeviceSample sample in samples) {
    if (!attached.contains(sample.device)) continue;
    final int? limit = limits[sample.device]?[sample.metric];
    if (limit == null) continue;
    if (sample.milliseconds > limit) {
      found.add(
        DeviceRegression(
          device: sample.device,
          metric: sample.metric,
          marginMs: sample.milliseconds - limit,
        ),
      );
    }
  }
  return found;
}

Map<String, Map<String, int>> _limits(String yaml) {
  final Map<String, Map<String, int>> limits = <String, Map<String, int>>{};
  String? id;
  final Map<String, int> current = <String, int>{};
  void store() {
    if (id == null) return;
    if (id.isEmpty || current.isEmpty || limits.containsKey(id)) {
      throw FormatException('Empty or duplicate device class/metrics: $id');
    }
    limits[id] = Map<String, int>.of(current);
  }

  for (final (int index, String raw) in yaml.split('\n').indexed) {
    final String line = raw.split('#').first.trim();
    if (line.startsWith('- id:')) {
      store();
      current.clear();
      id = line.substring('- id:'.length).trim();
    } else if (id != null && line.contains('Ms:')) {
      final int colon = line.indexOf(':');
      final String key = line
          .substring(0, colon)
          .replaceFirst(RegExp(r'Ms$'), '');
      final int? value = int.tryParse(line.substring(colon + 1).trim());
      if (value == null || value <= 0 || current.containsKey(key)) {
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
    final Map<String, Object?> report = await runDeviceMatrix(
      yaml: yaml,
      selected: selected,
      identifiers: identifiers,
      suite: options['suite'] ?? deviceMetricsTarget,
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

/// Runs each configured, attached class and requires every declared metric.
///
/// Integration scenarios print `TAPTURE_METRIC {"metric":"export",
/// "milliseconds":123}` after measuring real work. Missing or malformed
/// measurements fail rather than turning an empty sample set into a pass.
Future<Map<String, Object?>> runDeviceMatrix({
  required String yaml,
  required Set<String> selected,
  required Map<String, String> identifiers,
  String suite = deviceMetricsTarget,
  Future<ProcessResult> Function(String, List<String>)? run,
}) async {
  final Map<String, Map<String, int>> limits = _limits(yaml);
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
  for (final String device in selected) {
    final String? identifier = identifiers[device] ?? _identifier(yaml, device);
    if (identifier == null || !attachedDevices.containsKey(identifier)) {
      warnings.add(
        'device $device is not attached${identifier == null ? ' (no deviceId configured)' : ' ($identifier)'}',
      );
      continue;
    }
    final bool nativeMetrics = suite == deviceMetricsTarget;
    final Map<String, Object?> inventory = attachedDevices[identifier]!;
    final String platform = '${inventory['targetPlatform']}';
    if (nativeMetrics &&
        (inventory['emulator'] != false ||
            !(platform.startsWith('android') || platform == 'ios'))) {
      failures.add(
        '$device requires a physical Android or iOS device; $identifier is $platform (emulator: ${inventory['emulator']}).',
      );
      continue;
    }
    measured.add(device);
    evidence[device] = <String, Object?>{
      'deviceId': identifier,
      'targetPlatform': inventory['targetPlatform'],
      'runMode': nativeMetrics ? 'profile' : 'custom suite',
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
    ]);
    if (result.exitCode != 0) {
      failures.add(
        '$device integration suite failed (${result.exitCode}): ${result.stderr}',
      );
    }
    final Map<String, int> metrics = <String, int>{};
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
        if (value is! Map<String, Object?> ||
            value['metric'] is! String ||
            value['milliseconds'] is! int ||
            (value['milliseconds']! as int) < 0) {
          throw const FormatException('invalid metric');
        }
        final String metric = value['metric']! as String;
        if (!limits[device]!.containsKey(metric) ||
            metrics.containsKey(metric)) {
          throw const FormatException('unknown or repeated metric');
        }
        metrics[metric] = value['milliseconds']! as int;
        evidence[device]![metric] = value;
      } on FormatException {
        failures.add('$device malformed measurement: $message');
      }
    }
    for (final String metric in limits[device]!.keys) {
      final int? value = metrics[metric];
      if (value == null) {
        failures.add('$device missing measurement: $metric');
      } else {
        samples.add(
          DeviceSample(device: device, metric: metric, milliseconds: value),
        );
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
          '${row.device} ${row.metric} +${row.marginMs}ms',
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
          'milliseconds': sample.milliseconds,
          'limitMs': limits[sample.device]![sample.metric],
        },
    ],
  };
}

String? _identifier(String yaml, String selected) {
  String? current;
  for (final String raw in yaml.split('\n')) {
    final String line = raw.trim();
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
