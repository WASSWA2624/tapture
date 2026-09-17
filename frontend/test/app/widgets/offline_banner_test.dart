import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/features/onboarding/presentation/first_run_screen.dart';

void main() {
  testWidgets(
    'going offline shows the explanation once per transition, and dismiss lasts',
    (WidgetTester tester) async {
      final StreamController<NetworkState> radio =
          StreamController<NetworkState>(sync: true);
      addTearDown(radio.close);
      radio.add(NetworkState.online);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firstRunCompletedOverride(),
            connectivityServiceProvider.overrideWith((Ref ref) {
              final ConnectivityService service = ConnectivityService.fake(
                source: radio.stream,
              );
              ref.onDispose(service.dispose);
              return service;
            }),
          ],
          child: const TaptureApp(),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(AppBanner), findsNothing);
      expect(find.text(Copy.offlineWorking), findsNothing);

      radio.add(NetworkState.offline);
      await tester.pump();
      expect(find.byType(AppBanner), findsOneWidget);
      expect(find.text(Copy.offlineWorking), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsWidgets);

      await tester.tap(find.byTooltip(Copy.dismiss));
      await tester.pump();
      expect(find.byType(AppBanner), findsNothing);

      await tester.pump();
      expect(find.byType(AppBanner), findsNothing);

      await tester.tap(find.text(Copy.navRecords));
      await tester.pumpAndSettle();
      expect(find.byType(AppBanner), findsNothing);
      expect(find.text(Copy.offlineWorking), findsNothing);

      radio.add(NetworkState.online);
      await tester.pump();
      expect(find.byType(AppBanner), findsNothing);

      radio.add(NetworkState.offline);
      await tester.pump();
      expect(find.byType(AppBanner), findsOneWidget);
      expect(find.text(Copy.offlineWorking), findsOneWidget);
    },
  );
}
