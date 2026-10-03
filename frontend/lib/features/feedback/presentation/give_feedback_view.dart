import 'package:tapture/core/copy/copy.dart';

/// The verdicts on the give-feedback form. What was written and chosen
/// lives on the draft, so it survives the form closing.
typedef GiveFeedbackView = ({
  String? messageError,
  LocalizedMessage? localizedMessageError,
  String? otherError,
  LocalizedMessage? localizedOtherError,
  String? saveError,
  LocalizedMessage? localizedSaveError,
});
