import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/provenance.dart';

void main() {
  test('a stamp carries source, method, provider, model and prompt', () {
    final ProvenanceStamp stamp = Provenance.stamp(
      source: 'ocr',
      method: 'identifier-pattern',
      provider: 'on-device',
      model: 'mlkit-latin',
      promptVersion: '',
    );
    expect(stamp.source, 'ocr');
    expect(stamp.method, 'identifier-pattern');
    expect(stamp.provider, 'on-device');
    expect(stamp.model, 'mlkit-latin');
  });

  test('the audit row carries the same stamp', () {
    final ProvenanceStamp stamp = Provenance.stamp(
      source: 'ai',
      method: 'extract',
      provider: 'backend',
      model: 'default',
      promptVersion: 'v3',
    );
    expect(Provenance.asAudit(stamp), <String, String>{
      'source': 'ai',
      'method': 'extract',
      'provider': 'backend',
      'model': 'default',
      'promptVersion': 'v3',
    });
  });
}
