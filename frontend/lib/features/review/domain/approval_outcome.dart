import 'package:tapture/core/validation/validation_issue.dart';

part 'approved.dart';
part 'blocked.dart';

/// What an approve-and-next attempt did (task 016).
sealed class ApprovalOutcome {
  const ApprovalOutcome();
}
