import '../../integration_test/caption_scope_test.dart' as caption;
import '../../integration_test/capture_to_export_test.dart' as capture;
import '../../integration_test/context_test.dart' as context;
import '../../integration_test/duplicate_test.dart' as duplicate;
import '../../integration_test/export_formats_test.dart' as formats;
import '../../integration_test/meeting_test.dart' as meeting;
import '../../integration_test/merge_test.dart' as merge;
import '../../integration_test/offline_deferred_test.dart' as offline;
import '../../integration_test/signin_proxy_offline_test.dart' as signin;
import '../../integration_test/verification_test.dart' as verification;

void main() {
  caption.main();
  capture.main();
  context.main();
  duplicate.main();
  formats.main();
  meeting.main();
  merge.main();
  offline.main();
  signin.main();
  verification.main();
}
