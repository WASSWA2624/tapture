import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/assets/assets.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';

const List<Choice<String>> _providers = <Choice<String>>[
  Choice<String>('gemini', 'Gemini', icon: AppIcons.ai),
  Choice<String>('openai', 'OpenAI', icon: AppIcons.ai),
  Choice<String>('xai', 'xAI', icon: AppIcons.ai),
  Choice<String>('custom', 'Field server', icon: AppIcons.context),
];

void main() {
  setUpAll(ScreenFonts.load);

  testWidgets(
    'custom segment leading keeps artwork beside the selection tick',
    (tester) async {
      await _pump(
        tester,
        const ScreenMatrix(Size(393, 852), 2, Brightness.light, false),
        sheet: false,
      );
      expect(find.byType(Image), findsNWidgets(3));
      expect(find.byIcon(AppIcons.check), findsOneWidget);
      expect(find.byIcon(AppIcons.ai), findsNothing);
      await expectNoA11yIssues(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('absent builder retains the default segment glyph replacement', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(
          body: AppChoiceField<String>(
            label: 'Provider',
            value: 'openai',
            options: _providers.take(3).toList(),
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.byIcon(AppIcons.ai), findsNWidgets(2));
    expect(find.byIcon(AppIcons.check), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    for (final TargetPlatform platform in TargetPlatform.values) {
      for (final Locale locale in <Locale>[
        const Locale('en'),
        const Locale('en', 'XA'),
      ]) {
        testWidgets(
          'branded choice ${cell.description} ${platform.name} $locale',
          (tester) async {
            String? selected;
            await _pump(
              tester,
              cell,
              platform: platform,
              locale: locale,
              onChanged: (value) => selected = value,
            );
            expect(find.byType(Image), findsOneWidget);
            expect(find.byType(AppChoiceField<String>), meetsTapTarget());
            await tester.tap(find.byType(AppChoiceField<String>));
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(TextField), 'xAI');
            await tester.pumpAndSettle();
            final Finder option = find.widgetWithText(AppListTile, 'xAI');
            await tester.ensureVisible(option);
            expect(option, findsOneWidget);
            expect(
              find.descendant(of: option, matching: find.byType(Image)),
              findsOneWidget,
            );
            await tester.tap(option);
            await tester.pumpAndSettle();
            expect(selected, 'xai');
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final ({String name, ScreenMatrix cell}) corner
      in ScreenMatrix.corners) {
    testWidgets('branded choice golden ${corner.name}', (tester) async {
      await _pump(tester, corner.cell);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/choice_branded_${corner.name}.png'),
      );
      await tester.tap(find.byType(AppChoiceField<String>));
      await tester.pumpAndSettle();
      expect(find.byIcon(AppIcons.check), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/choice_branded_sheet_${corner.name}.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _leading(BuildContext context, Choice<String> choice) {
  final String? asset = AiProviderAssets.forProvider(
    choice.value,
    inverse: Theme.of(context).brightness == Brightness.dark,
  );
  return asset == null
      ? const Icon(AppIcons.context, size: Space.x6)
      : Image.asset(
          asset,
          width: Space.x6,
          height: Space.x6,
          excludeFromSemantics: true,
        );
}

Future<void> _pump(
  WidgetTester tester,
  ScreenMatrix cell, {
  bool sheet = true,
  TargetPlatform platform = TargetPlatform.android,
  Locale locale = const Locale('en'),
  ValueChanged<String?>? onChanged,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = cell.size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ScreenFonts.theme(
        buildTheme(brightness: cell.brightness, outdoor: cell.outdoor),
      ).copyWith(platform: platform),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(cell.textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(Space.x4),
            child: AppChoiceField<String>(
              label: 'Provider',
              value: 'openai',
              options: sheet ? _providers : _providers.take(3).toList(),
              alwaysSheet: sheet,
              leadingBuilder: _leading,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(() async {
    final BuildContext context = tester.element(
      find.byType(AppChoiceField<String>),
    );
    for (final String asset in <String>[
      AiProviderAssets.gemini,
      AiProviderAssets.openai,
      AiProviderAssets.openaiInverse,
      AiProviderAssets.xai,
      AiProviderAssets.xaiInverse,
    ]) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await tester.pumpAndSettle();
}
