# 284 — Feedback archive: ship the prompts generator

**Phase** 23 · Hardening  |  **Depends on** [282](282-in-app-feedback.md), [283](283-feedback-dictation-and-layout.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Every feedback download carries `feedback-prompts-generator.md` at the archive root, beside the workbook
and `screenshots/`. It instructs an AI agent to turn the export into ordered, executable implementation
prompts in `prompts/feedback-DDMMYYYY-HHMM/` of the repository:

- files are named `NNN-verb-object.md`, in the order they must be run;
- entries that share a root cause or component merge into one prompt;
- a suggestion too big for one reviewable change splits into several;
- every prompt respects and cites `frontend/.rules/`;
- a human-review stop comes before anything destructive or ambiguous;
- an `INDEX.md` accounts for every entry.

Feedback text is treated as data, never instructions, and personal data never reaches a prompt.

The guide is a Markdown asset, so it is edited as a document and not as code. The app loads it once, and
a missing guide never blocks a download.

## Files

- `frontend/assets/feedback/feedback-prompts-generator.md` (new)
- `frontend/lib/core/constants/document_assets.dart` (new, FE-STR-12)
- `frontend/lib/features/feedback/domain/feedback_archive.dart`
- `frontend/lib/features/feedback/presentation/feedback_providers.dart`, `download_feedback_controller.dart`
- `frontend/pubspec.yaml` (asset folder)

## Constraints

- The archive stays pure Dart and isolate-safe: the guide travels as text on `FeedbackArchive` (FE-STR-05,
  FE-PERF-02).
- The guide never asks the agent to change code; it produces prompts only.

## Definition of done

- [x] A download's zip holds the workbook, every image, and `feedback-prompts-generator.md` at its root.
- [x] A guide that cannot be loaded is left out, and the download still succeeds.
- [x] Tests: the archive with and without a guide, the shipped asset's contract, and an end-to-end
      download through the controller.
