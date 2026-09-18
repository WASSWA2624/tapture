import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/settings/domain/operator_profile.dart';
import 'package:tapture/features/settings/presentation/operator_profile_screen.dart';

void main() {
  testWidgets('an empty name and empty initials fail validation', (
    WidgetTester tester,
  ) async {
    final _Store store = _Store(
      const OperatorProfile(name: 'Ada', initials: 'A'),
    );
    await _pump(tester, store);

    await tester.enterText(find.byType(TextField).at(0), '');
    await tester.enterText(find.byType(TextField).at(1), '');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();

    expect(find.text(Copy.nameRequired), findsWidgets);
    expect(find.text(Copy.initialsLength), findsWidgets);
    expect(store.saves, 0);
    expect(store.profile.name, 'Ada');
  });

  testWidgets('saving writes the name, initials and optional contact', (
    WidgetTester tester,
  ) async {
    final _Store store = _Store(
      const OperatorProfile(name: 'Ada', initials: 'A'),
    );
    await _pump(tester, store);

    await tester.enterText(find.byType(TextField).at(0), 'Bea Lovelace');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller?.text,
      'BL',
    );

    await tester.enterText(find.byType(TextField).at(1), 'BX');
    await tester.enterText(find.byType(TextField).at(2), 'bea@x');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();

    expect(store.saves, 1);
    expect(store.profile.name, 'Bea Lovelace');
    expect(store.profile.initials, 'BX');
    expect(store.profile.contact, 'bea@x');
    expect(store.profile.accountId, isNull);
  });

  testWidgets('leaving a dirty form prompts before popping', (
    WidgetTester tester,
  ) async {
    final _Store store = _Store(
      const OperatorProfile(name: 'Ada', initials: 'A'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(store),
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext _) {
                            return const OperatorProfileScreen();
                          },
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Bea');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(Copy.discardChangesTitle), findsOneWidget);
    expect(find.text(Copy.unsavedChanges), findsOneWidget);

    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();
    expect(find.text(Copy.operatorProfileTitle), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.discard));
    await tester.pumpAndSettle();
    expect(find.text(Copy.operatorProfileTitle), findsNothing);
  });

  testWidgets('the screen does not authenticate anyone', (
    WidgetTester tester,
  ) async {
    final _Store store = _Store(
      const OperatorProfile(name: 'Ada', initials: 'A'),
    );
    await _pump(tester, store);

    expect(find.text('Password'), findsNothing);
    expect(find.text('PIN'), findsNothing);
    expect(find.text('Token'), findsNothing);
    expect(find.byType(AppPage), findsOneWidget);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .where((TextField field) => field.obscureText),
      isEmpty,
    );
  });

  testWidgets('a failed load offers try again', (WidgetTester tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: <Override>[
          operatorProfileOverride(
            load: () async {
              attempts += 1;
              if (attempts == 1) {
                throw Exception('Operator profile could not be read.');
              }
              return const OperatorProfile(name: 'Ada', initials: 'A');
            },
            save: (OperatorProfile profile) async =>
                Success<OperatorProfile>(profile),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const OperatorProfileScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppErrorState), findsOneWidget);
    await tester.tap(find.text(Copy.tryAgain));
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorState), findsNothing);
    expect(find.text(Copy.operatorName), findsOneWidget);
  });
}

final class _Store {
  _Store(this.profile);

  OperatorProfile profile;
  int saves = 0;

  Future<OperatorProfile> load() async => profile;

  Future<Result<OperatorProfile>> save(OperatorProfile next) async {
    saves += 1;
    profile = next;
    return Success<OperatorProfile>(next);
  }
}

List<Override> _overrides(_Store store) {
  return <Override>[
    operatorProfileOverride(load: store.load, save: store.save),
  ];
}

Future<void> _pump(WidgetTester tester, _Store store) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(store),
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const OperatorProfileScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
