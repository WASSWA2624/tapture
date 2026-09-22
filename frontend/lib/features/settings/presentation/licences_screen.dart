import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';

/// Open-source licences, one row per package, inside the shell.
class LicencesScreen extends ConsumerWidget {
  /// Creates the licences list.
  const LicencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<_LicenceRow>> value = ref.watch(_licencesProvider);
    final String? open = ref.watch(_openLicenceProvider);
    return AppPage(
      title: Copy.settingsLicences,
      body: AsyncValueView<List<_LicenceRow>>(
        value: value,
        onRetry: () => ref.invalidate(_licencesProvider),
        data: (List<_LicenceRow> rows) {
          _LicenceRow? selected;
          if (open != null) {
            for (final _LicenceRow row in rows) {
              if (row.package == open) {
                selected = row;
                break;
              }
            }
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final _LicenceRow row in rows)
                AppListTile(
                  title: row.package,
                  subtitle: row.summary,
                  onTap: () {
                    ref.read(_openLicenceProvider.notifier).select(row.package);
                  },
                ),
              if (selected != null) Text(selected.text),
            ],
          );
        },
      ),
    );
  }
}

final AsyncNotifierProvider<_Licences, List<_LicenceRow>> _licencesProvider =
    AsyncNotifierProvider<_Licences, List<_LicenceRow>>(_Licences.new);

final NotifierProvider<_OpenLicence, String?> _openLicenceProvider =
    NotifierProvider<_OpenLicence, String?>(_OpenLicence.new);

class _OpenLicence extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String package) => state = package;
}

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
