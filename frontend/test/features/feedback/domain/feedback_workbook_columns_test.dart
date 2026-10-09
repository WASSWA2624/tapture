import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/export.dart';
import 'package:tapture/features/feedback/domain/feedback_entry.dart';
import 'package:tapture/features/feedback/domain/feedback_filter.dart';
import 'package:tapture/features/feedback/domain/feedback_workbook.dart';

import '../../../support/factories.dart';

void main() {
  for (final bool isEmpty in <bool>[false, true]) {
    test(
      '${isEmpty ? 'empty' : 'populated'} exports keep the 36 feedback columns',
      () {
        final FeedbackWorkbook workbook = FeedbackWorkbook(
          entries: <FeedbackEntry>[
            if (!isEmpty) aFeedbackEntry(accountId: 'excluded-account-id'),
          ],
          filter: const FeedbackFilter(),
          generatedAtUtc: DateTime.utc(2026, 9, 18, 7, 2),
          utcOffset: const Duration(hours: 3),
          timeZone: 'EAT',
          generatedBy: 'Ada',
        );
        final XlsxSheet sheet = workbook.toBook().sheets.first;
        expect(
          sheet.columns.map((XlsxColumn column) => column.header),
          <String>[
            'Feedback ID',
            'Submitted At (EAT)',
            'Submitted At (UTC)',
            'Category',
            'Feedback',
            'Submitted By',
            'User Email',
            'User Name',
            'Screen',
            'Last Action',
            'Field Trial',
            'Route',
            'Route Name',
            'Page URL',
            'Platform',
            'Device Type',
            'App Version',
            'Environment',
            'Locale',
            'Time Zone',
            'Viewport (px)',
            'Display (px)',
            'Orientation',
            'Breakpoint',
            'Theme',
            'Text Scale',
            'Connectivity',
            'Device Clock (UTC)',
            'User Agent',
            'IP Address',
            'Screenshot',
            'User Initials',
            'Project ID',
            'Device ID',
            'Device Model',
            'OS Version',
          ],
        );
        expect(sheet.rows.length, isEmpty ? 0 : 1);
        for (final List<XlsxCell> row in sheet.rows) {
          expect(row.length, sheet.columns.length);
          expect(row[1], XlsxCell.dateTime(DateTime.utc(2026, 9, 18, 10, 2)));
          expect(row[25], const XlsxCell.number(1));
        }
      },
    );
  }
}
