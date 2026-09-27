import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/package_presence.dart';

void main() {
  test('a package project is absent, live or deleted here, nothing else', () {
    expect(PackagePresence.values, <PackagePresence>[
      PackagePresence.absent,
      PackagePresence.live,
      PackagePresence.deleted,
    ]);
  });
}
