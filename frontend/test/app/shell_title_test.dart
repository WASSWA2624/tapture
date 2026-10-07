import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/shell_title.dart';

void main() {
  test('Projects is the only shell root with no parent fallback', () {
    expect(ShellTitle.backLocation(Uri.parse(RoutePaths.projects)), isNull);
    for (final String root in <String>[
      RoutePaths.captureRoot,
      RoutePaths.records,
      RoutePaths.more,
    ]) {
      expect(ShellTitle.backLocation(Uri.parse(root)), RoutePaths.projects);
    }
  });

  test('clearing a filter preserves other query values and the fragment', () {
    final Uri filtered = Uri(
      path: RoutePaths.records,
      queryParameters: <String, Object>{
        RoutePaths.filterQuery: 'needsReview',
        'tag': <String>['first', 'second'],
      },
      fragment: 'selection',
    );
    final Uri parent = Uri.parse(ShellTitle.backLocation(filtered)!);
    expect(parent.path, RoutePaths.records);
    expect(parent.queryParametersAll, <String, List<String>>{
      'tag': <String>['first', 'second'],
    });
    expect(parent.fragment, 'selection');
  });

  test('parents skip route grouping segments that have no screen', () {
    final Map<String, String> parents = <String, String>{
      RoutePaths.project('p1'): RoutePaths.projects,
      RoutePaths.projectDetails('p1'): RoutePaths.project('p1'),
      RoutePaths.projectMeetingCreate('p1'): RoutePaths.project('p1'),
      RoutePaths.projectMeetingReview('p1', 'm1'): RoutePaths.project('p1'),
      RoutePaths.projectDatasetRow('p1', 'd1', 'r1'): RoutePaths.projectDataset(
        'p1',
        'd1',
      ),
      RoutePaths.templateFieldNew('t1'): RoutePaths.templateDetail('t1'),
      RoutePaths.templateField('t1', 'serial'): RoutePaths.templateDetail('t1'),
      RoutePaths.templateField('t1', 'serial', projectId: 'p1'):
          RoutePaths.templateDetail('t1', projectId: 'p1'),
      RoutePaths.templateFieldLookup('t1', 'serial'): RoutePaths.templateField(
        't1',
        'serial',
      ),
      RoutePaths.projectImportRecords: RoutePaths.projectImport,
      RoutePaths.projectCreate: RoutePaths.projects,
      RoutePaths.settingsStorageCheck: RoutePaths.settingsStorage,
    };
    for (final MapEntry<String, String> entry in parents.entries) {
      expect(ShellTitle.parentOf(entry.key), entry.value, reason: entry.key);
    }
  });

  test('encoded identifiers stay encoded in a resolved parent', () {
    expect(
      ShellTitle.parentOf(RoutePaths.projectMeetingReview('site/one', 'm1')),
      RoutePaths.project('site/one'),
    );
    expect(
      ShellTitle.parentOf(RoutePaths.templateField('t/1', 'field/1')),
      RoutePaths.templateDetail('t/1'),
    );
    final String filtered = '${RoutePaths.projectRecords('site/one')}?filter=x';
    expect(
      ShellTitle.backLocation(Uri.parse(filtered)),
      RoutePaths.projectRecords('site/one'),
    );
  });
}
