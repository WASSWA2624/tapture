import 'package:flutter_test/flutter_test.dart';

import '../../tool/device_matrix.dart';

void main() {
  const String yaml = '''
devices:
  - id: low
    coldStartMs: 100
    shutterMs: 50
''';

  test('a slow sample names the device, the metric and the margin', () {
    final List<DeviceRegression> rows = compareDevices(
      yaml: yaml,
      attached: const <String>{'low'},
      samples: const <DeviceSample>[
        DeviceSample(device: 'low', metric: 'coldStart', milliseconds: 180),
      ],
    );
    expect(rows, hasLength(1));
    expect(rows.single.device, 'low');
    expect(rows.single.metric, 'coldStart');
    expect(rows.single.marginMs, 80);
  });

  test('an unattached class is skipped', () {
    final List<DeviceRegression> rows = compareDevices(
      yaml: yaml,
      attached: const <String>{},
      samples: const <DeviceSample>[
        DeviceSample(device: 'low', metric: 'coldStart', milliseconds: 999),
      ],
    );
    expect(rows, isEmpty);
  });
}
