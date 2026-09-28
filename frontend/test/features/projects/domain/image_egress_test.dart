import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/security/untrusted_text.dart';
import 'package:tapture/features/processing/domain/extraction_request.dart';
import 'package:tapture/features/projects/domain/image_egress.dart';

void main() {
  test('a project holding images back keeps OCR text and drops paths', () {
    const ExtractionRequest request = ExtractionRequest(
      template: 'Pump',
      fields: <ExtractionField>[],
      context: <String, String>{},
      predefinedRows: <String>[],
      caption: UntrustedText('plate'),
      ocrText: UntrustedText('SN1'),
      images: <String>['photos/a.jpg'],
      basis: Copy.egressTextOnly,
    );
    final ExtractionRequest held = ExtractionRequest(
      template: request.template,
      fields: request.fields,
      context: request.context,
      predefinedRows: request.predefinedRows,
      caption: request.caption,
      ocrText: request.ocrText,
      images: ImageEgress.paths(holdImages: true, images: request.images),
      basis: Copy.egressTextOnly,
    );
    expect(held.toService().imagePaths, isEmpty);
    expect(held.toService().ocrText, contains('SN1'));
    expect(held.toJson()['basis'], Copy.egressTextOnly);
    expect(
      ImageEgress.paths(holdImages: true, images: request.images),
      isEmpty,
    );
  });

  test('a project that sends images passes every path through', () {
    const List<String> images = <String>['photos/a.jpg', 'photos/b.jpg'];
    expect(ImageEgress.paths(holdImages: false, images: images), images);
  });
}
