import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/screen_fixtures.dart';
import '../support/screen_inventory.dart';

void main() {
  test('every discovered collection route has an actual-screen fixture', () {
    final ScreenInventory inventory = ScreenInventory.read(Directory.current);
    expect(
      inventory.collections,
      containsAll(<String>[
        'ProjectListScreen',
        'RecordsListScreen',
        'TemplateListScreen',
        'DatasetBrowserScreen',
        'RecordHistoryScreen',
      ]),
    );
    final List<String> missing = inventory.missingFixtures(
      ScreenFixtures.collections.map((fixture) => fixture.screen),
    );
    expect(
      missing,
      isEmpty,
      reason:
          'Missing production collection fixtures: '
          '${missing.join(', ')}',
    );
  });

  test('new routed collections and delegated views cannot escape coverage', () {
    final ScreenInventory inventory = ScreenInventory.fromSources(
      router:
          'GoRoute(builder: (_) => NewScreen()); '
          'GoRoute(builder: (_) => DelegatedScreen()); '
          'GoRoute(builder: (_) => PlainScreen());',
      sources: <String, String>{
        'lib/new_screen.dart': '''
class NewScreen extends StatelessWidget {
  Widget build(context) => ListView.builder(itemCount: rows.length);
}
class DelegatedScreen extends StatelessWidget {
  Widget build(context) => CollectionRows();
}
class PlainScreen extends StatelessWidget {
  Widget build(context) => Text('Plain');
  Future<void> open() async { NewScreen(); }
}
''',
        'lib/collection_rows.dart': '''
class CollectionRows extends StatelessWidget {
  Widget build(context) => AsyncValueView<List<Row>>(value: loaded);
}
''',
      },
    );
    expect(inventory.collections, <String>{'NewScreen', 'DelegatedScreen'});
    expect(inventory.missingFixtures(const <String>[]), <String>[
      'DelegatedScreen',
      'NewScreen',
    ]);
    expect(
      inventory.missingFixtures(<String>['NewScreen', 'DelegatedScreen']),
      isEmpty,
    );
  });

  test('summary and workbook empty branches are discovered from their AST', () {
    final ScreenInventory inventory = ScreenInventory.fromSources(
      router:
          'GoRoute(builder: (_) => SummaryScreen()); '
          'GoRoute(builder: (_) => WorkbookScreen()); '
          'GoRoute(builder: (_) => RecordSummaryScreen()); '
          'GoRoute(builder: (_) => DetailScreen()); '
          'GoRoute(builder: (_) => FormScreen());',
      sources: <String, String>{
        'lib/empty_branches.dart': '''
class SummaryScreen extends StatelessWidget {
  Widget build(context) => AsyncValueView<Summary>(
    isEmpty: (summary) => summary.records == 0,
    empty: () => AppEmptyState(),
  );
}
class WorkbookScreen extends StatelessWidget {
  Widget build(context) => AsyncValueView<Workbook>(
    isEmpty: (workbook) => workbook.sheets.isEmpty,
    empty: () => AppEmptyState(),
  );
}
class RecordSummaryScreen extends StatelessWidget {
  Widget build(context) => SummaryView((isEmpty: summary.records == 0));
}
class DetailScreen extends StatelessWidget {
  Widget build(context) => AsyncValueView<Record?>(
    isEmpty: (record) => record == null,
    empty: () => AppEmptyState(),
  );
}
class FormScreen extends StatelessWidget {
  Widget build(context) => Column(children: [AppEmptyState(), AddButton()]);
}
''',
      },
    );
    expect(inventory.collections, <String>{
      'SummaryScreen',
      'WorkbookScreen',
      'RecordSummaryScreen',
    });
    expect(inventory.missingFixtures(<String>['WorkbookScreen']), <String>[
      'RecordSummaryScreen',
      'SummaryScreen',
    ]);
  });
}
