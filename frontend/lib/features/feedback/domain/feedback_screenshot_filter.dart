/// Whether a filter keeps entries with a screenshot, without one, or both.
enum FeedbackScreenshotFilter {
  /// Either way.
  any('Any'),

  /// Only entries with a screenshot.
  attached('With'),

  /// Only entries without one.
  missing('Without');

  const FeedbackScreenshotFilter(this.exportLabel);

  /// Name in an exported workbook's details sheet.
  final String exportLabel;

  /// Whether an entry that [hasScreenshot] passes.
  bool admits({required bool hasScreenshot}) {
    return switch (this) {
      FeedbackScreenshotFilter.any => true,
      FeedbackScreenshotFilter.attached => hasScreenshot,
      FeedbackScreenshotFilter.missing => !hasScreenshot,
    };
  }
}
