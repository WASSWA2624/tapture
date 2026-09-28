import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/export/pdf/pdf_engine.dart';

void main() {
  test(
    'real PDFs paginate the body and embed photos without changing source pixels',
    () async {
      const PdfEngine engine = PdfEngine();
      final Uint8List photo = Uint8List.fromList(
        img.encodeJpg(
          img.Image(width: 400, height: 200)
            ..clear(img.ColorRgb8(10, 100, 180)),
        ),
      );
      final List<int> before = photo.toList();
      final PdfDocument document = engine.document(
        title: 'Inspection report',
        project: 'Field review',
        coverLines: const <String>[
          'Verified export fixture',
          'Raw and refined values are labelled separately.',
        ],
        bodyLines: <String>[
          for (int index = 0; index < 150; index++)
            'Record $index: raw observation. Refined observation remains alongside the original evidence.',
        ],
        photos: engine.photoBlock(const <({String caption, String path})>[
          (caption: 'Inspection evidence', path: 'photos/evidence.jpg'),
        ], columns: 2),
      );
      Uint8List? output;
      await for (final double _ in engine.render(
        document: document,
        token: CancellationToken(),
        emit: (Uint8List value) => output = value,
        discard: () => fail('render discarded'),
        images: <String, Uint8List>{'photos/evidence.jpg': photo},
        font: await File('assets/fonts/NotoSans-Regular.ttf').readAsBytes(),
      )) {}
      final Uint8List bytes = output!;
      final String syntax = latin1.decode(bytes);
      expect(syntax, startsWith('%PDF-'));
      expect(syntax, contains('xref'));
      expect(syntax, contains('startxref'));
      expect(
        RegExp(r'/Type\s*/Page\b').allMatches(syntax).length,
        greaterThan(3),
      );
      expect(RegExp(r'/Subtype\s*/Image').hasMatch(syntax), isTrue);
      expect(photo, before);
      // Optional review artefact for the independent PDF parser/render check.
      final String? target = Platform.environment['TAPTURE_PDF_FIXTURE'];
      if (target != null) await File(target).writeAsBytes(bytes, flush: true);
    },
  );

  test(
    'cancelled rendering emits nothing and removes partial output',
    () async {
      final CancellationToken token = CancellationToken()..cancel();
      var discarded = false;
      const PdfEngine engine = PdfEngine();
      await for (final double _ in engine.render(
        document: engine.document(
          title: 'Report',
          project: 'Project',
          coverLines: const <String>[],
          bodyLines: const <String>[],
        ),
        token: token,
        emit: (_) => fail('cancel emitted'),
        discard: () => discarded = true,
      )) {}
      expect(discarded, isTrue);
    },
  );
}
