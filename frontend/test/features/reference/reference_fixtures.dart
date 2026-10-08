import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export.dart';
import 'package:tapture/features/reference/domain/domain.dart';

import '../../support/fakes/fake_reference_repository.dart';

export '../../support/fakes/fake_reference_repository.dart';

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

/// A fake holding the supplier dataset `ds` of [projectId] with [count]
/// generated rows, released when the test ends.
Future<FakeReferenceRepository> seededSuppliers(
  int count, {
  String projectId = 'p1',
}) async {
  final FakeReferenceRepository repo = FakeReferenceRepository();
  addTearDown(repo.dispose);
  final Result<ReferenceDataset> saved = await repo.importDataset(
    dataset: aDataset(projectId: projectId, rowCount: count),
    rows: supplierRows(count),
  );
  if (saved case FailureResult<ReferenceDataset>(:final Failure failure)) {
    throw TestFailure(failure.message);
  }
  return repo;
}

/// A parsed import ready for the key-column screen, built the way every
/// reader builds one, so counts, samples and colliding values agree with
/// [rows]. The header defaults to [aDataset]'s, keyed on its first column.
DatasetImportDraft aDraft({
  List<String> columns = supplierColumns,
  List<Map<String, String>>? rows,
  String? projectId,
}) {
  return DatasetDraft.build(
    columns: columns,
    rows:
        rows ??
        <Map<String, String>>[
          <String, String>{'code': 'A', 'name': 'One', 'phone': '1'},
          <String, String>{'code': 'B', 'name': 'Two', 'phone': '2'},
        ],
    source: DatasetSource.csv,
    sourceFile: 'suppliers.csv',
    importedAt: fixtureImportedAt,
    projectId: projectId,
    name: 'Suppliers',
  );
}

/// A one-sheet workbook of the supplier columns plus the device marker:
/// `A` imported, `B` added on a device.
Uint8List supplierWorkbook() {
  return XlsxEncoder.encode(
    XlsxBook(
      createdUtc: fixtureImportedAt,
      sheets: const <XlsxSheet>[
        XlsxSheet(
          name: 'Suppliers',
          columns: <XlsxColumn>[
            XlsxColumn('code'),
            XlsxColumn('name'),
            XlsxColumn('phone'),
            XlsxColumn('addedOnDevice'),
          ],
          rows: <List<XlsxCell>>[
            <XlsxCell>[
              XlsxCell.text('A'),
              XlsxCell.text('Acme'),
              XlsxCell.text('0700 1'),
              XlsxCell.empty,
            ],
            <XlsxCell>[
              XlsxCell.text('B'),
              XlsxCell.text('Beta'),
              XlsxCell.text('0700 2'),
              XlsxCell.text('true'),
            ],
          ],
        ),
      ],
    ),
  );
}

/// The failure [BrokenPagesRepository] returns for every page.
const StorageFailure brokenPageFailure = StorageFailure(
  message: 'Reference rows could not be read.',
  recoveryAction: 'Try again.',
);

/// A repository whose key lookups miss and whose row pages all fail with
/// [brokenPageFailure]. Any other call is a test mistake and throws.
final class BrokenPagesRepository implements ReferenceRepository {
  @override
  Future<Result<ReferenceRow?>> lookupByKey({
    required String datasetId,
    required String keyValue,
  }) async {
    return const Success<ReferenceRow?>(null);
  }

  @override
  Future<Result<List<ReferenceRow>>> lookupByNormalised({
    required String datasetId,
    required String query,
  }) async {
    return const Success<List<ReferenceRow>>(<ReferenceRow>[]);
  }

  @override
  Future<Result<List<ReferenceRow>>> pageRows({
    required String datasetId,
    required int offset,
    required int limit,
    String query = '',
  }) async {
    return const FailureResult<List<ReferenceRow>>(brokenPageFailure);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
        // A pattern, not a location: RoutePaths would escape the colon.
        path: '${RoutePaths.projects}/:projectId/datasets',
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
