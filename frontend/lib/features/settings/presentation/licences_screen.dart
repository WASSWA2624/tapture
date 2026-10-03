import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

/// Open-source licences, one row per package, inside the shell. Rows are
/// built as they scroll into view, and a row opens its full text in a
/// sheet (a side panel on wide windows), so the text is never far below.
class LicencesScreen extends ConsumerWidget {
  /// Creates the licences list.
  const LicencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<List<_LicenceRow>> value = ref.watch(_licencesProvider);
    return AppPage(
      title: localCopy.settingsLicences,
      scrollable: false,
      inset: false,
      body: AsyncValueView<List<_LicenceRow>>(
        value: value,
        onRetry: () => ref.invalidate(_licencesProvider),
        isEmpty: (List<_LicenceRow> rows) => rows.isEmpty,
        empty: () => AppEmptyState(
          icon: AppIcons.info,
          headline: Copy.of(context).settingsLicences,
          message: Copy.of(context).settingsAboutSubtitle,
          actionLabel: Copy.of(context).settingsAboutTitle,
          onAction: () => context.go(RoutePaths.settingsAbout),
        ),
        data: (List<_LicenceRow> rows) {
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (BuildContext context, int index) {
              final _LicenceRow row = rows[index];
              return AppListTile(
                title: row.package,
                subtitle: row.summary,
                trailing: const Icon(AppIcons.open),
                onTap: () => unawaited(_open(context, row)),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _open(BuildContext context, _LicenceRow row) {
    return showAppSheet<void>(
      context,
      title: row.package,
      builder: (BuildContext sheetContext) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(Space.x4),
          child: SelectableText(
            row.text,
            style: AppText.caption.copyWith(
              color: sheetContext.colors.onSurface,
            ),
          ),
        );
      },
    );
  }
}

/// Licences are read once per visit; leaving the page frees them.
final AsyncNotifierProvider<_Licences, List<_LicenceRow>> _licencesProvider =
    AsyncNotifierProvider.autoDispose<_Licences, List<_LicenceRow>>(
      _Licences.new,
    );

class _Licences extends AsyncNotifier<List<_LicenceRow>> {
  @override
  Future<List<_LicenceRow>> build() async {
    final List<_LicenceRow> rows = <_LicenceRow>[];
    await for (final LicenseEntry entry in LicenseRegistry.licenses) {
      final String text = _textOf(entry);
      for (final String package in entry.packages) {
        rows.add((package: package, summary: _summary(text), text: text));
      }
    }
    rows.sort((_LicenceRow a, _LicenceRow b) => a.package.compareTo(b.package));
    return rows;
  }
}

typedef _LicenceRow = ({String package, String summary, String text});

String _textOf(LicenseEntry entry) {
  final StringBuffer buffer = StringBuffer();
  for (final LicenseParagraph paragraph in entry.paragraphs) {
    buffer.writeln(paragraph.text);
  }
  return buffer.toString().trim();
}

String _summary(String text) {
  for (final String name in <String>['BSD', 'MIT', 'Apache', 'ISC']) {
    if (text.contains(name)) {
      return name;
    }
  }
  final int dot = text.indexOf('.');
  if (dot > 0) {
    return text.substring(0, dot + 1);
  }
  return text;
}
