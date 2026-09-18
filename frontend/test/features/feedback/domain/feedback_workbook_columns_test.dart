import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/export.dart';
import 'package:tapture/features/feedback/domain/feedback_entry.dart';
import 'package:tapture/features/feedback/domain/feedback_filter.dart';
import 'package:tapture/features/feedback/domain/feedback_workbook.dart';

import '../../../support/factories.dart';

void main() {
  test('the Feedback sheet keeps the organisation column order', () {
    final FeedbackWorkbook workbook = FeedbackWorkbook(
      entries: <FeedbackEntry>[aFeedbackEntry()],
      filter: const FeedbackFilter(),
      generatedAtUtc: DateTime.utc(2026, 9, 18, 7, 2),
      utcOffset: const Duration(hours: 3),
      timeZone: 'EAT',
      generatedBy: 'Ada',
    );
    final List<String> headers = workbook
        .toBook()
        .sheets
        .first
        .columns
        .map((XlsxColumn column) => column.header)
        .toList();
    expect(headers.take(9), <String>[
      'Feedback ID',
      'Submitted At (EAT)',
      'Submitted At (UTC)',
      'Category',
      'Feedback',
      'Submitted By',
      'User Email',
      'User Name',
      'User ID',
    ]);
    expect(
      headers,
      containsAll(<String>[
        'Position Title',
        'Tenant',
        'Screen',
        'Platform',
        'Device Type',
        'Screenshot',
        'Device ID',
      ]),
    );
    expect(headers.last, 'OS Version');
  });
}
