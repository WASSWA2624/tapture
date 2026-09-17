import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

void main() {
  group('app dialog service', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_dialog_${mode.name}.png'),
        );
      });
    }
  });
}

List<({String name, ThemeData theme})> get _modes {
  return <({String name, ThemeData theme})>[
    (name: 'light', theme: buildTheme(brightness: Brightness.light)),
    (name: 'dark', theme: buildTheme(brightness: Brightness.dark)),
    (name: 'outdoor', theme: buildOutdoorTheme(Brightness.light)),
  ];
}

Future<void> _pumpGallery(WidgetTester tester, ThemeData theme) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 1800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      theme: theme,
      home: const AppPage(title: 'Feedback', body: _GalleryBody()),
    ),
  );
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(title: 'Dialogs'),
        AppDialog.confirm(
          title: 'Delete record',
          message: 'This hides the record. You can undo.',
          confirmLabel: 'Delete',
          destructive: true,
          onConfirm: _ignore,
          onCancel: _ignore,
        ),
        AppDialog.alert(
          title: 'Saved',
          message: 'The project is on this device.',
          onConfirm: _ignore,
        ),
        AppSectionHeader(title: 'Sheet'),
        SizedBox(
          height: Space.x12 * 5,
          child: AppBottomSheet(
            title: 'Pick a grade',
            child: Padding(
              padding: EdgeInsets.all(Space.x4),
              child: Text('Sheet body'),
            ),
          ),
        ),
        AppSectionHeader(title: 'Snacks'),
        AppSnackbar(message: 'Queued for processing'),
        AppSnackbar(message: 'Record saved', tone: SnackTone.success),
        AppSnackbar(
          message: 'Record deleted',
          tone: SnackTone.error,
          undoLabel: 'Undo',
          onUndo: _ignore,
        ),
        AppSectionHeader(title: 'Banners'),
        AppBanner(
          message: 'You are offline. Captures stay on this device.',
          icon: Icons.cloud_off,
          tone: SnackTone.warning,
          onDismiss: _ignore,
        ),
        AppBanner(
          message: 'Storage is low.',
          icon: Icons.save_outlined,
          tone: SnackTone.error,
        ),
      ],
    );
  }
}

void _ignore() {}
