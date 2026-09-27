import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/records/domain/purge_report.dart';

void main() {
  const PurgeReport report = PurgeReport(
    purged: 2,
    skippedRecent: 3,
    skippedMergeNeeded: 1,
    filesRemoved: 5,
    failed: 1,
  );

  test('none counts nothing', () {
    expect(PurgeReport.none.considered, 0);
    expect(PurgeReport.none, const PurgeReport());
  });

  test('considered adds every record the run looked at, files aside', () {
    expect(report.considered, 7);
  });

  test('the summary is counts only, for the launch log', () {
    expect(
      report.summary,
      'purged 2, recent 3, merge needed 1, files 5, failed 1',
    );
    expect(report.toString(), contains(report.summary));
  });

  test('reports with the same counts are equal', () {
    expect(report.copyWith(), report);
    expect(report.copyWith().hashCode, report.hashCode);
    expect(report.copyWith(failed: 0), isNot(report));
    expect(report.copyWith(purged: 9).skippedRecent, 3);
  });
}
