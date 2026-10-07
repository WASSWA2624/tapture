import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/context/presentation/context_providers.dart';
import 'package:tapture/features/feedback/presentation/feedback_providers.dart';
import 'package:tapture/features/records/presentation/record_providers.dart';

/// Pumps [child] under the app theme, providers and a fixed clock.
///
/// A test names only [overrides]. [pumpUntil] waits for a condition by
/// pumping frames, never by sleeping.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const <Override>[],
  Brightness brightness = Brightness.light,
  bool outdoor = false,
  DateTime? now,
  Locale? locale,
}) {
  final Clock clock = FixedClock(now ?? DateTime.utc(2026, 9, 28));
  return tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        feedbackClockProvider.overrideWith((Ref _) => clock),
        recordClockProvider.overrideWith((Ref _) => clock),
        contextClockProvider.overrideWith((Ref _) => clock),
        ...overrides,
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildTheme(brightness: brightness, outdoor: outdoor),
        home: child,
      ),
    ),
  );
}

/// Pumps frames until [ready] is true.
Future<void> pumpUntil(WidgetTester tester, bool Function() ready) async {
  for (var frame = 0; frame < 30; frame++) {
    if (ready()) return;
    await tester.pump();
  }
  throw TestFailure('The condition was not met.');
}
