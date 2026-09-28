import 'dart:io';

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
}) {
  final Map<String, Map<String, int>> limits = _limits(yaml);
  final List<DeviceRegression> found = <DeviceRegression>[];
  for (final String id in limits.keys) {
    if (!attached.contains(id)) {
      stderr.writeln('warning: device $id is not attached');
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
  for (final String raw in yaml.split('\n')) {
    final String line = raw.trim();
    if (line.startsWith('- id:')) {
      if (id != null) limits[id] = Map<String, int>.of(current);
      current.clear();
      id = line.substring('- id:'.length).trim();
    } else if (id != null &&
        line.endsWith('Ms:') == false &&
        line.contains('Ms:')) {
      final int colon = line.indexOf(':');
      final String key = line.substring(0, colon).replaceAll('Ms', '');
      current[key] = int.parse(line.substring(colon + 1).trim());
    }
  }
  if (id != null) limits[id] = Map<String, int>.of(current);
  return limits;
}

/// Reads devices.yaml and exits 1 when a sample regresses.
Future<int> main(List<String> args) async {
  final String yaml = File('tool/devices.yaml').readAsStringSync();
  final Set<String> attached = <String>{
    for (final String arg in args)
      if (arg.startsWith('--devices='))
        ...arg.substring('--devices='.length).split(','),
  };
  final List<DeviceRegression> regressions = compareDevices(
    yaml: yaml,
    samples: const <DeviceSample>[],
    attached: attached,
  );
  for (final DeviceRegression row in regressions) {
    stderr.writeln('${row.device} ${row.metric} +${row.marginMs}ms');
  }
  return regressions.isEmpty ? 0 : 1;
}
