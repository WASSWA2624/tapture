import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/meetings/domain/attendee.dart';

void main() {
  test('an apology is not attendance and a suggestion is not a link', () {
    const Attendee apology = Attendee(
      id: 'a2',
      name: 'Ben',
      status: AttendanceStatus.apology,
      suggestedStaffId: 's1',
    );
    expect(apology.countsAsAttendance, isFalse);
    expect(apology.staffId, isNull);
    expect(Attendee.fromJson(apology.toJson()), apology);
  });
}
