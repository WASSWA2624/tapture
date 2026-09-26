import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';

void main() {
  test('a provider failure is unclassified unless it says otherwise', () {
    const ProviderFailure plain = ProviderFailure(message: '500 from provider');
    const ProviderFailure refused = ProviderFailure(
      message: 'The key was refused.',
      kind: ProviderFailureKind.authentication,
    );

    expect(plain.kind, ProviderFailureKind.unknown);
    expect(refused.kind, ProviderFailureKind.authentication);
    expect(refused.message, 'The key was refused.');
  });

  test('every kind the retry classifier and the test action need exists', () {
    expect(
      ProviderFailureKind.values.map((ProviderFailureKind kind) => kind.name),
      <String>[
        'authentication',
        'rateLimited',
        'unavailable',
        'unsupportedMedia',
        'malformed',
        'unknown',
      ],
    );
  });
}
