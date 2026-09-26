import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';

import 'record_bundle.dart';

/// The detect stage: makes sure the record has a template to fill.
final class DetectStage {
  /// Creates the stage.
  const DetectStage();

  /// Throws a [ValidationFailure] when [bundle] has no template.
  Future<void> run(RecordBundle bundle, CancellationToken cancel) async {
    if (bundle.template.id.isEmpty) {
      throw const ValidationFailure(
        message: 'This record has no template.',
        recoveryAction: 'Choose a template, then retry processing.',
      );
    }
  }
}
