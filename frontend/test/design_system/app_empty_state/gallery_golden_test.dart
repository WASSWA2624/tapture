import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

void main() {
  group('app empty state', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_empty_state_${mode.name}.png'),
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
      home: const AppPage(title: 'States', body: _GalleryBody()),
    ),
  );
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: 'Empty'),
        AppEmptyState(
          icon: Icons.folder_open,
          headline: 'No projects yet',
          message: 'Create a project to start capturing.',
          actionLabel: 'Create a project',
          onAction: () {},
        ),
        const AppSectionHeader(title: 'Empty, the icon is the action'),
        AppEmptyState(
          icon: Icons.add_a_photo_outlined,
          headline: 'No photos yet',
          message: 'Add a photo to start this record.',
          onIconTap: () {},
          iconLabel: 'Add photo',
        ),
        const AppSectionHeader(title: 'Error'),
        const AppErrorState(failure: NetworkFailure(), onRetry: _ignore),
        const AppSectionHeader(title: 'Loading'),
        const AppSkeleton(shape: SkeletonShape.list, count: 2),
        const SizedBox(height: Space.x4),
        const AppSkeleton(shape: SkeletonShape.card, count: 1),
        const SizedBox(height: Space.x4),
        const AppSkeleton(shape: SkeletonShape.detail, count: 1),
        const SizedBox(height: Space.x4),
        const Align(
          alignment: Alignment.centerLeft,
          child: AppSkeleton.inline(),
        ),
        const AppSectionHeader(title: 'Async data'),
        AsyncValueView<String>(
          value: const AsyncData<String>('Boiler A'),
          data: (String name) => Text(name),
        ),
      ],
    );
  }
}

void _ignore() {}
