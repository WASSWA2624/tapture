import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/features/account/presentation/backend_settings_screen.dart';
import '../../../support/pump_app.dart';

void main() {
  for (final double width in <double>[360, 768, 1280]) {
    testWidgets('cached account details fit width $width at 200 percent text', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpApp(
        tester,
        MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: const TextScaler.linear(2),
          ),
          child: BackendSettingsScreen(
            config: BackendConfig(
              baseUrl: 'https://organisation.example.test',
              organisationId: 'organisation-with-a-long-identifier',
              accountEmail: 'person@example.test',
              role: 'project_manager',
              state: EnrolmentState.enrolled,
              grantValidUntil: DateTime.utc(2026, 10, 28),
              reachable: false,
            ),
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<AppPage>(find.byType(AppPage)).layout,
        AppPageLayout.compact,
      );
      expect(find.text('person@example.test'), findsOneWidget);
      expect(find.text('organisation-with-a-long-identifier'), findsOneWidget);
      expect(
        find.text(Copy.backendRoleName('project_manager')),
        findsOneWidget,
      );
      expect(find.text(Copy.backendEnrolled), findsOneWidget);
      expect(find.text(Copy.backendUnreachable), findsOneWidget);
      expect(find.text(Copy.signOutAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'a revoked device says the organisation ended its sign-in and offers it',
    (WidgetTester tester) async {
      await pumpApp(
        tester,
        const BackendSettingsScreen(
          config: BackendConfig(
            baseUrl: 'https://organisation.example.test',
            accountId: 'account',
            state: EnrolmentState.revoked,
          ),
          authority: AuthorityState.cachedExpired,
        ),
      );
      expect(find.text(Copy.backendRevoked), findsOneWidget);
      expect(find.text(Copy.backendRevokedState), findsOneWidget);
      expect(find.text(Copy.backendNotSignedIn), findsOneWidget);
      expect(
        find.widgetWithText(AppPrimaryAction, Copy.signInAction),
        findsOneWidget,
      );
      expect(find.text(Copy.signOutAction), findsNothing);
    },
  );

  testWidgets('a lapsed grant says which work needs a fresh sign-in', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      BackendSettingsScreen(
        config: BackendConfig(
          baseUrl: 'https://organisation.example.test',
          accountEmail: 'person@example.test',
          state: EnrolmentState.enrolled,
          grantValidUntil: DateTime.utc(2026, 8, 1),
        ),
        authority: AuthorityState.cachedExpired,
      ),
    );
    expect(find.text(Copy.backendGrantExpired), findsOneWidget);
    expect(find.text(Copy.backendUnreachable), findsNothing);
  });
}
