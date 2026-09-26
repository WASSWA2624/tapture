import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/evidence_linking.dart';

void main() {
  test('a provider region is kept on the photo link', () {
    final List<EvidenceDraft> rows = EvidenceLinking.forValue(
      photoId: 'photo-1',
      regionJson: '{"x":0.1,"y":0.2,"w":0.3,"h":0.1}',
      confidence: 0.9,
    );
    expect(rows, hasLength(1));
    expect(rows.single.sourceType, 'photo');
    expect(rows.single.regionJson, contains('"x"'));
    expect(rows.single.confidence, 0.9);
  });

  test('a local value keeps the block that produced it', () {
    final List<EvidenceDraft> rows = EvidenceLinking.forValue(
      photoId: 'photo-1',
      snippet: 'SN458923',
    );
    expect(rows.single.photoId, 'photo-1');
    expect(rows.single.snippet, 'SN458923');
  });

  test('a value with no locatable region still links to its photo', () {
    final List<EvidenceDraft> rows = EvidenceLinking.forValue(
      photoId: 'photo-1',
    );
    expect(rows, hasLength(1));
    expect(rows.single.photoId, 'photo-1');
    expect(rows.single.regionJson, isNull);
  });

  test('a transcript snippet links without a photo', () {
    final List<EvidenceDraft> rows = EvidenceLinking.forValue(
      snippet: 'serial is four five eight',
    );
    expect(rows.single.sourceType, 'transcript');
    expect(rows.single.photoId, isNull);
  });

  test('nothing to link to yields no row', () {
    expect(EvidenceLinking.forValue(), isEmpty);
  });
}
