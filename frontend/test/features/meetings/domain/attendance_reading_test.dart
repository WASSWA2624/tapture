import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/meetings/domain/attendance_reading.dart';

void main() {
  test('editing a reading keeps the cell confidence', () {
    const AttendanceReading reading = AttendanceReading(
      name: 'Ada',
      nameConfidence: 0.91,
    );
    expect(reading.copyWith(name: 'Ada Lovelace').nameConfidence, 0.91);
  });
}
