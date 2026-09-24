import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/features/settings/presentation/ai_provider_settings_screen.dart';
import 'package:tapture/features/settings/settings.dart';

void main() {
  testWidgets('AI provider settings in every theme and at 200 percent text', (
    WidgetTester tester,
  ) async {
    final List<String> failures = <String>[];
    for (final AppThemeMode mode in AppThemeMode.values) {
      for (final double scale in <double>[1, 2]) {
        await _pump(tester, mode: mode, textScale: scale);
        final String suffix = scale == 2 ? '_text2' : '';
        try {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/ai_provider_settings${suffix}_${mode.name}.png',
            ),
          );
        } catch (error) {
          failures.add('${mode.name} scale $scale: $error');
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
    if (failures.isNotEmpty) {
      fail('golden moved:\n${failures.join('\n')} (FE-TEST-02)');
    }
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required AppThemeMode mode,
  required double textScale,
}) async {
  debugDisableShadows = true;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(() {
    debugDisableShadows = false;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearLocaleTestValue();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(
        brightness: mode == AppThemeMode.dark
            ? Brightness.dark
            : Brightness.light,
        outdoor: mode == AppThemeMode.outdoor,
      ),
      home: AiProviderSettingsScreen(
        registry: _registry(),
        settings: SettingsStore.fake(),
        storage: SecureStorage.fake(backing: <SecretKey, String>{}),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderRegistry _registry() {
  const AiService unavailable = AiService.unavailable();
  return ProviderRegistry(
    descriptors: <ProviderDescriptor>[
      ProviderDescriptor(
        id: ProviderRegistry.backendId,
        label: 'Organisation backend',
        operations: AiOperation.values.toSet(),
        keyCustody: ProviderKeyCustody.backend,
        deviceKeyAllowed: false,
        available: true,
        service: unavailable,
        models: <ModelDescriptor>[
          ModelDescriptor(
            id: 'default',
            label: 'Organisation default',
            operations: AiOperation.values.toSet(),
          ),
        ],
      ),
      ProviderDescriptor(
        id: 'device',
        label: 'Approved device provider',
        operations: const <AiOperation>{AiOperation.extractFields},
        keyCustody: ProviderKeyCustody.device,
        deviceKeyAllowed: true,
        available: true,
        service: unavailable,
        models: <ModelDescriptor>[
          ModelDescriptor(
            id: 'field-model',
            label: 'Field extraction',
            operations: const <AiOperation>{AiOperation.extractFields},
          ),
        ],
      ),
    ],
  );
}
