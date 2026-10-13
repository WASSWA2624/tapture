import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/value_formatter.dart' show ExportFormat;
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/features/exports/presentation/export_request_extras.dart';

import '../../../support/pump_app.dart';
import '../../../support/screen_probe.dart';

void main() {
  testWidgets('advanced file edits retain every unrelated export choice', (
    WidgetTester tester,
  ) async {
    const ExportRequest request = ExportRequest(
      projectId: 'p1',
      formats: <ExportFormat>{ExportFormat.xlsx, ExportFormat.pdf},
      scope: (
        kind: ExportScopeKind.approved,
        context: null,
        from: null,
        to: null,
        filter: null,
      ),
      columns: (raw: true, refined: true, confidence: true, evidence: false),
      extras: (
        dictionary: false,
        photoIndex: false,
        photoMode: 'relative',
        pdfPhotos: PdfPhotoLayout.full,
        delimiter: ';',
      ),
    );
    ExportRequest? changed;
    await pumpApp(
      tester,
      AppPage(
        title: Copy.exportTitle,
        layout: AppPageLayout.sectioned,
        body: ExportRequestExtras(
          request: request,
          onChanged: (ExportRequest value) => changed = value,
        ),
      ),
    );
    await tester.tap(find.widgetWithText(AppSwitchTile, Copy.exportDictionary));
    await tester.pump();
    expect(changed?.extras.dictionary, isTrue);
    expect(changed?.extras.photoIndex, request.extras.photoIndex);
    expect(changed?.extras.photoMode, request.extras.photoMode);
    expect(changed?.extras.pdfPhotos, request.extras.pdfPhotos);
    expect(changed?.extras.delimiter, request.extras.delimiter);
    expect(changed?.scope, request.scope);
    expect(changed?.formats, request.formats);
    expect(changed?.columns, request.columns);

    await tester.tap(find.text(Copy.exportPhotoEmbed));
    await tester.pump();
    expect(changed?.extras.photoMode, 'embed');
    expect(changed?.extras.dictionary, request.extras.dictionary);
    expect(changed?.extras.pdfPhotos, request.extras.pdfPhotos);
    expect(changed?.extras.delimiter, request.extras.delimiter);
    expect(ScreenProbe.layoutIssues(tester), isEmpty);
  });
}
