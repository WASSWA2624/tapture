import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/backend_config.dart';

void main() {
  const BackendConfig start = BackendConfig(baseUrl: 'https://org.example');

  test('enrolment moves only along the sign-in path', () {
    final BackendConfig enrolling = start.apply(EnrolmentEvent.start);
    expect(enrolling.state, EnrolmentState.enrolling);
    expect(
      enrolling.apply(EnrolmentEvent.fail).state,
      EnrolmentState.notEnrolled,
    );
    final BackendConfig enrolled = enrolling.apply(EnrolmentEvent.succeed);
    expect(enrolled.state, EnrolmentState.enrolled);
    expect(enrolled.needsSignIn, isFalse);
    final BackendConfig revoked = enrolled.apply(EnrolmentEvent.revoke);
    expect(revoked.state, EnrolmentState.revoked);
    expect(revoked.needsSignIn, isTrue);
    expect(revoked.apply(EnrolmentEvent.start).state, EnrolmentState.enrolling);
    expect(
      start.apply(EnrolmentEvent.succeed).state,
      EnrolmentState.notEnrolled,
    );
  });

  test('records keep their operator name and gain the account id', () {
    final ({String operatorName, String accountId}) linked =
        BackendConfig.linkOperator(operatorName: 'Ada', accountId: 'user-1');
    expect(linked.operatorName, 'Ada');
    expect(linked.accountId, 'user-1');
  });
}
