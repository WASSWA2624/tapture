import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/router.dart';

void main() {
  test('a record values page sits under the record, in both branches', () {
    expect(RoutePaths.recordValuesEdit('r1'), '/records/r1/values');
    expect(
      RoutePaths.projectRecordValuesEdit('p1', 'r1'),
      '/projects/p1/records/r1/values',
    );
  });

  test('a record history sits under the record, in both branches', () {
    expect(RoutePaths.recordHistory('r1'), '/records/r1/history');
    expect(
      RoutePaths.projectRecordHistory('p1', 'r1'),
      '/projects/p1/records/r1/history',
    );
  });

  test('the recycle bin sits under Settings', () {
    expect(RoutePaths.recycleBin, '/more/recycle-bin');
    expect(RoutePaths.recycleBin, startsWith('${RoutePaths.more}/'));
  });

  test('record page paths never clash with the capture edit page', () {
    expect(
      RoutePaths.projectRecordValuesEdit('p1', 'r1'),
      isNot(RoutePaths.projectRecordEdit('p1', 'r1')),
    );
    expect(
      RoutePaths.projectRecordHistory('p1', 'r1'),
      isNot(RoutePaths.projectRecordEdit('p1', 'r1')),
    );
  });

  test('ids are encoded as one path segment', () {
    expect(RoutePaths.recordValuesEdit('a/b c'), '/records/a%2Fb%20c/values');
    expect(
      RoutePaths.projectRecordHistory('p/1', 'r 1'),
      '/projects/p%2F1/records/r%201/history',
    );
  });

  test('AppRoutes publishes the record page paths unchanged', () {
    expect(AppRoutes.recordValuesEdit('r1'), RoutePaths.recordValuesEdit('r1'));
    expect(AppRoutes.recordHistory('r1'), RoutePaths.recordHistory('r1'));
    expect(
      AppRoutes.projectRecordValuesEdit('p1', 'r1'),
      RoutePaths.projectRecordValuesEdit('p1', 'r1'),
    );
    expect(
      AppRoutes.projectRecordHistory('p1', 'r1'),
      RoutePaths.projectRecordHistory('p1', 'r1'),
    );
    expect(AppRoutes.recycleBin, RoutePaths.recycleBin);
  });
}
