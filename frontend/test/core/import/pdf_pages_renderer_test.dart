import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as widgets;
import 'package:pdfrx/pdfrx.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/import/pdf_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const String runtime = String.fromEnvironment('TAPTURE_TEST_PDFIUM');
  if (runtime.isNotEmpty) Pdfrx.pdfiumModulePath = runtime;
  test(
    'real PDF pages render lazily, reject bad indices and preserve originals',
    () async {
      if (!kIsWeb) {
        final Directory cache = await Directory.systemTemp.createTemp(
          'tapture-pdf-',
        );
        final String? previousCache = Pdfrx.cacheDirectoryPath;
        Pdfrx.cacheDirectoryPath = cache.path;
        addTearDown(() async {
          Pdfrx.cacheDirectoryPath = previousCache;
          await cache.delete(recursive: true);
        });
      }
      final widgets.Document fixture = widgets.Document();
      for (final PdfColor color in <PdfColor>[PdfColors.red, PdfColors.blue]) {
        fixture.addPage(
          widgets.Page(
            pageFormat: const PdfPageFormat(200, 100, marginAll: 0),
            build: (_) => widgets.Container(color: color),
          ),
        );
      }
      final Uint8List bytes = await fixture.save();
      final Uint8List original = Uint8List.fromList(bytes);
      final PdfPages renderer = PdfPages();
      addTearDown(renderer.dispose);
      expect((await renderer.pageCount(bytes)).getOrThrow(), 2);
      expect(debugPdfHasOpenDocument(renderer), isFalse);
      final PdfPageImage first = (await renderer.renderPage(
        bytes,
        pageIndex: 0,
        longEdge: 320,
      )).fold((failure) => throw failure, (value) => value);
      final PdfPageImage second = (await renderer.renderPage(
        bytes,
        pageIndex: 1,
        longEdge: 320,
      )).fold((failure) => throw failure, (value) => value);
      expect(debugPdfHasOpenDocument(renderer), isTrue);
      final Uint8List otherSource = Uint8List.fromList(bytes);
      (await renderer.renderPage(
        otherSource,
        pageIndex: 0,
        longEdge: 320,
      )).getOrThrow();
      await renderer.release(bytes);
      expect(
        debugPdfHasOpenDocument(renderer),
        isTrue,
        reason: 'Closing an older source must preserve a newer viewer.',
      );
      await renderer.release(otherSource);
      expect(debugPdfHasOpenDocument(renderer), isFalse);
      // Release is queued behind an in-flight render and permits a later retry.
      final Future<Result<PdfPageImage>> pending = renderer.renderPage(
        bytes,
        pageIndex: 1,
        longEdge: 320,
      );
      final Future<void> release = renderer.release(bytes);
      expect(await pending, isA<Success<PdfPageImage>>());
      await release;
      expect(debugPdfHasOpenDocument(renderer), isFalse);
      final image.Image rendered = image.decodePng(first.bytes)!;
      expect(rendered.width, 320);
      expect(rendered.height, 160);
      expect(rendered.getPixel(160, 80).r, greaterThan(240));
      expect(
        image.decodePng(second.bytes)!.getPixel(160, 80).b,
        greaterThan(240),
      );
      expect(bytes, orderedEquals(original));
      const String preview = String.fromEnvironment('TAPTURE_TEST_PDF_PREVIEW');
      if (!kIsWeb && preview.isNotEmpty) {
        await File('$preview/page-1.png').writeAsBytes(first.bytes);
        await File('$preview/page-2.png').writeAsBytes(second.bytes);
      }
      expect(
        await renderer.renderPage(bytes, pageIndex: 2, longEdge: 320),
        isA<FailureResult<PdfPageImage>>(),
      );
      expect(
        await renderer.pageCount(Uint8List.fromList('%PDF-garbage'.codeUnits)),
        isA<FailureResult<int>>(),
      );
    },
  );
}
