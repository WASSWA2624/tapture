import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/features/reference/data/dataset_csv_import.dart'
    show DatasetImportDraft;
import 'package:tapture/features/reference/domain/reference_dataset.dart';
import 'package:tapture/features/reference/domain/reference_row.dart';

/// When every fixture dataset was imported.
final DateTime fixtureImportedAt = DateTime.utc(2026, 9, 22, 8);

/// The supplier fixture's columns, in import order.
const List<String> supplierColumns = <String>['code', 'name', 'phone'];

/// A supplier dataset keyed on `code`. Override what the test cares about.
ReferenceDataset aDataset({
  String? id,
  String? name,
  String? keyColumn,
  List<String>? columns,
  DatasetSource? source,
  DateTime? importedAt,
  int? rowCount,
  bool duplicatesAllowed = false,
  String? projectId,
  String? sourceFile,
}) {
  return ReferenceDataset(
    id: id ?? 'ds',
    name: name ?? 'Suppliers',
    keyColumn: keyColumn ?? 'code',
    columns: columns ?? supplierColumns,
    source: source ?? DatasetSource.csv,
    importedAt: importedAt ?? fixtureImportedAt,
    rowCount: rowCount ?? 0,
    duplicatesAllowed: duplicatesAllowed,
    projectId: projectId,
    sourceFile: sourceFile ?? 'suppliers.csv',
  );
}

/// One supplier row. [values] defaults to the three supplier columns.
ReferenceRow aReferenceRow({
  String? id,
  String? datasetId,
  String? key,
  Map<String, String>? values,
  bool addedOnDevice = false,
}) {
  final String code = key ?? 'ACME';
  return ReferenceRow(
    id: id ?? '',
    datasetId: datasetId ?? 'ds',
    key: code,
    values:
        values ??
        <String, String>{
          'code': code,
          'name': 'Acme Supplies',
          'phone': '0700 000000',
        },
    addedOnDevice: addedOnDevice,
  );
}

/// [count] supplier rows with zero-padded keys, so key order is row order.
List<ReferenceRow> supplierRows(int count, {String datasetId = 'ds'}) {
  return <ReferenceRow>[
    for (int i = 0; i < count; i++)
      aReferenceRow(
        datasetId: datasetId,
        key: supplierKey(i),
        values: <String, String>{
          'code': supplierKey(i),
          'name': 'Supplier $i',
          'phone': '07${i.toString().padLeft(8, '0')}',
        },
      ),
  ];
}

/// The key of the [index]th generated supplier row.
String supplierKey(int index) => 'K${index.toString().padLeft(5, '0')}';

/// A parsed import ready for the key-column screen.
DatasetImportDraft aDraft({
  ReferenceDataset? dataset,
  List<ReferenceRow>? rows,
  Map<String, int>? duplicateCounts,
  Map<String, List<String>>? samples,
}) {
  final List<ReferenceRow> parsed =
      rows ??
      <ReferenceRow>[
        aReferenceRow(
          datasetId: '',
          key: 'A',
          values: <String, String>{
            'code': 'A',
            'name': 'One',
            'phone': '1',
          },
        ),
        aReferenceRow(
          datasetId: '',
          key: 'B',
          values: <String, String>{
            'code': 'B',
            'name': 'Two',
            'phone': '2',
          },
        ),
      ];
  final ReferenceDataset header =
      dataset ?? aDataset(id: '', rowCount: parsed.length);
  return (
    dataset: header,
    rows: parsed,
    duplicateCounts:
        duplicateCounts ??
        <String, int>{for (final String column in header.columns) column: 0},
    samples:
        samples ??
        <String, List<String>>{
          for (final String column in header.columns)
            column: <String>[
              for (final ReferenceRow row in parsed.take(3))
                row.values[column] ?? '',
            ],
        },
  );
}

/// Sizes the test surface to a phone in portrait.
void setPhoneSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(393, 886);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Builds one stub page so a test can tell where navigation landed.
typedef RouteStub = Widget Function(GoRouterState state);

/// The dataset routes of one project, with every page a stub unless the
/// test supplies it, so `context.go` and `context.pop` land somewhere real.
///
/// Returns the router; `router.routerDelegate.currentConfiguration.uri`
/// says where the screen under test went.
Future<GoRouter> pumpDatasetRoutes(
  WidgetTester tester, {
  required String initialLocation,
  List<Override> overrides = const <Override>[],
  RouteStub? list,
  RouteStub? import,
  RouteStub? dataset,
  RouteStub? row,
}) async {
  final GoRouter router = GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.projectDatasets(':projectId'),
        builder: (BuildContext _, GoRouterState state) =>
            (list ?? _stub('datasets'))(state),
        routes: <RouteBase>[
          GoRoute(
            path: 'import',
            builder: (BuildContext _, GoRouterState state) =>
                (import ?? _stub('import'))(state),
          ),
          GoRoute(
            path: ':datasetId',
            builder: (BuildContext _, GoRouterState state) =>
                (dataset ?? _stub('dataset'))(state),
            routes: <RouteBase>[
              GoRoute(
                path: 'rows/:rowId',
                builder: (BuildContext _, GoRouterState state) =>
                    (row ?? _stub('row'))(state),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: overrides,
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  return router;
}

/// The text a stub page for [name] shows: `name-route`.
String routeStubText(String name) => '$name-route';

RouteStub _stub(String name) {
  return (GoRouterState _) => Text(routeStubText(name));
}
