import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/features/settings/presentation/gps_privacy_section.dart';

void main() {
  test('an export after exclusion carries no coordinates', () {
    final List<Map<String, Object?>> records = <Map<String, Object?>>[
      <String, Object?>{'name': 'Pump', 'latitude': 0.3, 'longitude': 32.5},
      <String, Object?>{'name': 'Valve'},
    ];
    expect(GpsPrivacySection.strip(records), 1);
    expect(records.first.containsKey('latitude'), isFalse);
    expect(records.first.containsKey('longitude'), isFalse);
    expect(records.first['name'], 'Pump');
    final String exported = records.toString();
    expect(exported.contains('0.3'), isFalse);
    expect(exported.contains('32.5'), isFalse);
  });

  testWidgets('the section reports how many records changed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GpsPrivacySection(removed: 2, onRemove: () async => 2),
      ),
    );
    expect(find.text(Copy.gpsPrivacyRemoved(2)), findsOneWidget);
    expect(
      tester
          .widget<AppSwitchTile>(
            find.byKey(const ValueKey<String>('gps-capture')),
          )
          .value,
      isFalse,
    );
  });
}
