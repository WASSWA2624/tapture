import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/features/settings/presentation/api_key_screen.dart';
import 'package:tapture/features/settings/settings.dart';

void main() {
  testWidgets('saving obscures the device key and removal clears selection', (
    WidgetTester tester,
  ) async {
    final Map<SecretKey, String> secrets = <SecretKey, String>{};
    final SecureStorage storage = SecureStorage.fake(backing: secrets);
    final SettingsStore settings = SettingsStore.fake();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: ApiKeyScreen(storage: storage, settings: settings),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'provider-secret');
    await tester.tap(find.text(Copy.apiKeySave));
    await tester.pumpAndSettle();

    expect(secrets[SecretKey.providerCredential], 'provider-secret');
    expect(find.text('provider-secret'), findsNothing);
    expect(find.text(Copy.apiKeySaved), findsOneWidget);
    expect(settings.read(SettingKeys.aiProvider), 'device');

    await tester.tap(find.text(Copy.apiKeyRemove));
    await tester.pumpAndSettle();

    expect(secrets, isEmpty);
    expect(settings.read(SettingKeys.aiProvider), 'backend');
  });
}
