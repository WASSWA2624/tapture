import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/cloud/presentation/upload_confirm_sheet.dart';

void main() {
  testWidgets('cancel performs no request and reads no credential', (
    WidgetTester tester,
  ) async {
    var reads = 0;
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () async {
                final bool confirmed = await confirmUpload(
                  context,
                  name: 'pack.zip',
                  size: '12 KB',
                  destination: 'Archive',
                  folder: 'inbox',
                );
                if (confirmed) {
                  reads += 1;
                  requests += 1;
                }
              },
              child: const Text('Send file'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Send file'));
    await tester.pumpAndSettle();
    expect(find.textContaining('pack.zip'), findsOneWidget);
    expect(find.textContaining('Archive'), findsOneWidget);
    expect(find.textContaining('inbox'), findsOneWidget);
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();
    expect(reads, 0);
    expect(requests, 0);
  });

  testWidgets('the same file asks again', (WidgetTester tester) async {
    var asks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () async {
                asks += 1;
                await confirmUpload(
                  context,
                  name: 'pack.zip',
                  size: '12 KB',
                  destination: 'Archive',
                  folder: 'inbox',
                );
              },
              child: const Text('Send file'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Send file'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send file'));
    await tester.pumpAndSettle();
    expect(asks, 2);
    expect(find.text(Copy.uploadConfirmTitle), findsOneWidget);
  });
}
