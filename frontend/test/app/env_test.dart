import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/env.dart';

void main() {
  tearDown(() => Env.debugFlavor = null);

  test('the default flavour is production', () {
    expect(Env.flavor, Flavor.prod);
    expect(Env.isDev, isFalse);
  });

  test('an override is what Env reports', () {
    Env.debugFlavor = Flavor.dev;

    expect(Env.flavor, Flavor.dev);
    expect(Env.isDev, isTrue);
  });
}
