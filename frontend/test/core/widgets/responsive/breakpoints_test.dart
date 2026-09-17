import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';

void main() {
  test('size class resolves at the compact and expanded edges', () {
    expect(SizeClass.fromWidth(599), SizeClass.compact);
    expect(SizeClass.fromWidth(600), SizeClass.medium);
    expect(SizeClass.fromWidth(1023), SizeClass.medium);
    expect(SizeClass.fromWidth(1024), SizeClass.expanded);
  });
}
