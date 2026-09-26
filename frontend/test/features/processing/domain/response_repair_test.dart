import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/response_repair.dart';

void main() {
  test('one repair is allowed, and no second', () {
    expect(ResponseRepair.maxAttempts, 1);
    expect(ResponseRepair.mayRetry(repairsUsed: 0), isTrue);
    expect(ResponseRepair.mayRetry(repairsUsed: 1), isFalse);
  });

  test('the parse error travels as data', () {
    expect(
      ResponseRepair.followUp(parseError: 'Field count is malformed.'),
      <String, Object?>{'parse_error': 'Field count is malformed.'},
    );
  });
}
