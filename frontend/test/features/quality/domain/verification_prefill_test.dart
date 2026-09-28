import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/quality.dart';

void main() {
  const Map<String, String> binding = <String, String>{
    'serial': 'asset',
    'location': 'room',
    'custodian': 'holder',
  };

  test('a matched row prefills and keeps the register value', () {
    final VerificationPrefill matched = VerificationPrefill.fromRow(
      row: const <String, String>{'asset': 'ABB-1'},
      binding: const <String, String>{'serial': 'asset'},
    );
    expect(matched.onRegister, isTrue);
    expect(matched.asRecorded['serial'], 'ABB-1');
    final Map<String, String> edited = Map<String, String>.of(matched.asFound);
    edited['serial'] = 'ABB-2';
    expect(matched.asRecorded['serial'], 'ABB-1');
    expect(edited['serial'], 'ABB-2');
  });

  test('an unmatched identifier is not on the register', () {
    final VerificationPrefill missed = VerificationPrefill.fromRow(
      row: null,
      binding: const <String, String>{'serial': 'asset'},
    );
    expect(missed.onRegister, isFalse);
    expect(missed.asRecorded, isEmpty);
    expect(missed.asFound, isEmpty);
  });

  test('an empty row is not on the register either', () {
    final VerificationPrefill missed = VerificationPrefill.fromRow(
      row: const <String, String>{},
      binding: binding,
    );
    expect(missed.onRegister, isFalse);
    expect(missed.asRecorded, isEmpty);
  });

  test('every mapped field fills from its column and nothing else does', () {
    final VerificationPrefill matched = VerificationPrefill.fromRow(
      row: const <String, String>{
        'asset': 'AST-00123',
        'room': 'Laboratory',
        'holder': 'J. Okello',
        'condition': 'Good',
      },
      binding: binding,
    );
    expect(matched.asRecorded, <String, String>{
      'serial': 'AST-00123',
      'location': 'Laboratory',
      'custodian': 'J. Okello',
    });
    expect(matched.asRecorded.containsKey('condition'), isFalse);
  });

  test('a blank cell and a column the row lacks leave the field unfilled', () {
    final VerificationPrefill matched = VerificationPrefill.fromRow(
      row: const <String, String>{'asset': 'AST-00123', 'room': '   '},
      binding: binding,
    );
    expect(matched.onRegister, isTrue);
    expect(matched.asRecorded, <String, String>{'serial': 'AST-00123'});
    expect(matched.asFound, <String, String>{'serial': 'AST-00123'});
  });

  test('the register values cannot be edited in place', () {
    final VerificationPrefill matched = VerificationPrefill.fromRow(
      row: const <String, String>{'asset': 'ABB-1'},
      binding: const <String, String>{'serial': 'asset'},
    );
    expect(
      () => matched.asRecorded['serial'] = 'ABB-2',
      throwsUnsupportedError,
    );
    expect(matched.asRecorded['serial'], 'ABB-1');
  });

  test('the as-found values start as a separate copy of the register', () {
    final VerificationPrefill matched = VerificationPrefill.fromRow(
      row: const <String, String>{'asset': 'ABB-1', 'room': 'Theatre'},
      binding: binding,
    );
    expect(matched.asFound, matched.asRecorded);
    expect(identical(matched.asFound, matched.asRecorded), isFalse);
    expect(() => matched.asFound['serial'] = 'ABB-2', throwsUnsupportedError);
  });
}
