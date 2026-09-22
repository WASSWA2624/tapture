import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/import/pdf_pages.dart';

void main() {
  test('lazy page count does not modify source', () async {
    final Uint8List bytes = Uint8List.fromList(
      '%PDF-1.4 /Type /Page /Type /Page /Count 2'.codeUnits,
    );
    final Uint8List copy = Uint8List.fromList(bytes);
    final PdfPages pdf = PdfPages.fake(pageCount: 2);
    final int count = (await pdf.pageCount(bytes)).getOrElse(() => 0);
    expect(count, greaterThanOrEqualTo(2));
    expect(bytes, orderedEquals(copy));
    final page = await pdf.renderPage(bytes, pageIndex: 0, longEdge: 800);
    expect(page.fold((_) => -1, (PdfPageImage p) => p.pageIndex), 0);
    expect(bytes, orderedEquals(copy));
  });
}
