import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/exports/domain/export_versioning.dart';

void main() {
  test('the same day allocates v1 then v2 and never reuses either', () async {
    final ExportVersioning versioning = ExportVersioning(<String>{});
    final DateTime now = DateTime.utc(2026, 9, 28, 10);
    expect(await versioning.allocate('p1', now), 'p1/2026-09-28/v1');
    expect(await versioning.allocate('p1', now), 'p1/2026-09-28/v2');
    expect(versioning.taken, contains('p1/2026-09-28/v1'));
  });
}
