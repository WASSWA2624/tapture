import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/domain/consent_field.dart';

void main() {
  test('export omits records that lack consent and lists them', () {
    final List<String> omitted = ConsentField.omitted(
      requiredOnProject: true,
      rows: <ConsentRow>[
        (id: 'kept', consent: (by: 'Ada', at: DateTime.utc(2026, 9, 28))),
        (id: 'missing', consent: null),
      ],
    );
    expect(omitted, <String>['missing']);
    expect(
      ConsentField.omitted(
        requiredOnProject: false,
        rows: const <ConsentRow>[(id: 'missing', consent: null)],
      ),
      isEmpty,
    );
  });
}
