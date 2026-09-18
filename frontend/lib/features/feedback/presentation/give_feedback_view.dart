/// The verdicts on the give-feedback form. What was written and chosen
/// lives on the draft, so it survives the form closing.
typedef GiveFeedbackView = ({
  String? messageError,
  String? otherError,
  String? saveError,
});
