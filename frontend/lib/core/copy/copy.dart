import 'package:intl/intl.dart';

/// One place every visible catalogue string comes from, keyed by meaning
/// so translation can arrive later without touching a widget (FE-L10N-01,
/// FE-L10N-02, FE-L10N-03).
///
/// Template field labels, option lists and template names are user data and
/// never pass through here (FE-L10N-07).
abstract final class Copy {
  /// Stated absence when a value was not found.
  static String get notDetected => 'Not detected';

  /// How many records a list holds. Zero is a stated absence, not a blank.
  static String recordsCount(int n) {
    return Intl.plural(
      n,
      zero: 'No records',
      one: '1 record',
      other: '$n records',
    );
  }

  /// Clears the named field.
  static String clearField(String label) => 'Clear $label';

  /// A value filled in rather than typed.
  static const String autoFilled = 'Auto-filled';

  /// A number outside the allowed range.
  static const String outOfRange = 'Out of range';

  /// Selects every visible option in a multi-choice sheet.
  static const String selectAll = 'Select all';

  /// Clears a selection or a field.
  static const String clear = 'Clear';

  /// Dismisses the named chip.
  static String dismissChip(String label) => 'Dismiss $label';

  /// Dismisses a banner or other unnamed surface.
  static const String dismiss = 'Dismiss';

  /// Backs out of a confirm dialog.
  static const String cancel = 'Cancel';

  /// Acknowledges an alert.
  static const String ok = 'OK';

  /// Title of the unsaved-changes confirm.
  static const String discardChangesTitle = 'Discard changes?';

  /// Body of the unsaved-changes confirm.
  static const String unsavedChanges = 'You have unsaved changes.';

  /// Confirms discarding unsaved edits.
  static const String discard = 'Discard';

  /// Heading over a list of invalid fields.
  static String fixFields(int n) {
    return Intl.plural(n, one: 'Fix this field', other: 'Fix these fields');
  }

  /// One invalid field in a validation summary. [label] is template content.
  static String fieldError(String label, String error) => '$label: $error';

  /// Announced summary of invalid fields.
  static String validationAnnouncement(String heading, List<String> errors) {
    return '$heading. ${errors.join('. ')}';
  }

  /// Placeholder when a cached thumb file is missing.
  static const String missingPhoto = 'Missing photo';

  /// Semantic name of a missing thumb, including its type.
  static String missingPhotoNamed(String type) => 'Missing photo, $type';

  /// Fallback type name when a photo has none.
  static const String photo = 'Photo';

  /// Semantic name of a thumb: type, missing, caption and selection.
  static String photoThumbLabel({
    required String type,
    required bool missing,
    required bool captioned,
    required bool selected,
  }) {
    final StringBuffer buffer = StringBuffer(
      missing ? missingPhotoNamed(type) : type,
    );
    if (captioned) {
      buffer.write(', captioned');
    }
    if (selected) {
      buffer.write(', selected');
    }
    return buffer.toString();
  }

  /// Facing the subject.
  static const String photoFront = 'Front';

  /// Reverse of the subject.
  static const String photoBack = 'Back';

  /// Serial number plate or stamp.
  static const String photoSerial = 'Serial';

  /// Manufacturer rating plate.
  static const String photoRatingPlate = 'Rating plate';

  /// Short overlay for a rating plate.
  static const String photoRatingPlateBadge = 'Plate';

  /// Visible damage.
  static const String photoDamage = 'Damage';

  /// Control or breaker panel.
  static const String photoPanel = 'Panel';

  /// Site or room context.
  static const String photoLocation = 'Location';

  /// People present at a meeting.
  static const String photoAttendance = 'Attendance';

  /// Short overlay for attendance.
  static const String photoAttendanceBadge = 'Attend';

  /// A page or scanned document.
  static const String photoDocument = 'Document';

  /// Short overlay for a document.
  static const String photoDocumentBadge = 'Doc';

  /// Any other photo type.
  static const String photoOther = 'Other';

  /// A progress step that finished.
  static const String stepDone = 'Done';

  /// A progress step that is in progress.
  static const String stepRunning = 'Running';

  /// A progress step that has not started.
  static const String stepWaiting = 'Waiting';

  /// A failed step or record.
  static const String failed = 'Failed';

  /// Announced name of a progress row.
  static String progressAnnouncement({
    required String label,
    required String state,
    String? detail,
  }) {
    if (detail == null) {
      return '$label, $state';
    }
    return '$label, $state, $detail';
  }

  /// Saved locally, not yet captured.
  static const String statusDraft = 'Draft';

  /// Evidence is on the record.
  static const String statusCaptured = 'Captured';

  /// Waiting for processing.
  static const String statusQueued = 'Queued';

  /// A processing job is running.
  static const String statusProcessing = 'Processing';

  /// Extraction finished.
  static const String statusExtracted = 'Extracted';

  /// A person must look at this record.
  static const String statusNeedsReview = 'Needs review';

  /// A person has accepted the record.
  static const String statusApproved = 'Approved';

  /// Kept for history.
  static const String statusArchived = 'Archived';

  /// Marked gone.
  static const String statusDeleted = 'Deleted';

  /// Headline when a list has nothing to show.
  static const String emptyHeadline = 'Nothing here yet';

  /// Body when a list has nothing to show.
  static const String emptyMessage =
      'When there is something to show, it will appear here.';

  /// A control or page that is still working.
  static const String loading = 'Loading';

  /// Busy adverb on an action that is still running.
  static const String busy = 'loading';

  /// Named action that is still running.
  static String busyAction(String label) => '$label, $busy';

  /// Retries a failed load.
  static const String tryAgain = 'Try again';

  /// Persists the current form or record.
  static const String save = 'Save';

  /// Reverses the last destructive action.
  static const String undo = 'Undo';

  /// Developer gallery title.
  static const String galleryTitle = 'Widget gallery';

  /// Theme-mode switcher.
  static const String galleryTheme = 'Theme';

  /// Simulated-width switcher.
  static const String galleryWidth = 'Width';

  /// Text-scale switcher.
  static const String galleryTextScale = 'Text scale';

  /// Token family heading.
  static const String galleryTokens = 'Tokens';

  /// Layout family heading.
  static const String galleryLayout = 'Layout';

  /// Button family heading.
  static const String galleryButtons = 'Buttons';

  /// Field family heading.
  static const String galleryFields = 'Fields';

  /// Container family heading.
  static const String galleryContainers = 'Containers';

  /// State family heading.
  static const String galleryStates = 'States';

  /// Feedback family heading.
  static const String galleryFeedback = 'Feedback';

  /// Light appearance.
  static const String galleryLight = 'Light';

  /// Dark appearance.
  static const String galleryDark = 'Dark';

  /// Outdoor appearance.
  static const String galleryOutdoor = 'Outdoor';

  /// Compact width.
  static const String galleryCompact = 'Compact';

  /// Medium width.
  static const String galleryMedium = 'Medium';

  /// Expanded width.
  static const String galleryExpanded = 'Expanded';

  /// Default text scale.
  static const String galleryScale100 = '100%';

  /// Double text scale.
  static const String galleryScale200 = '200%';

  /// Product name in chrome and the system window.
  static const String appName = 'Tapture';

  /// Prompt on list-pane and picker search fields.
  static const String search = 'Search';

  /// Shell destination: the project list.
  static const String navProjects = 'Projects';

  /// Shell destination: capture. Visually dominant in the four-destination bar.
  static const String navCapture = 'Capture';

  /// Shell destination: the records list.
  static const String navRecords = 'Records';

  /// Shell destination: settings and the rest.
  static const String navMore = 'More';

  /// Pinned-template destination the status line opens.
  static const String navTemplates = 'Templates';

  /// Unprocessed-queue destination the status line opens.
  static const String navQueue = 'Unprocessed';

  /// First-run screen title; the only question asked.
  static const String firstRunTitle = 'Your name';

  /// Why the name is asked, under the title.
  static const String firstRunSubtitle =
      'Used on every record you capture from this device.';

  /// Label of the operator name field.
  static const String firstRunName = 'Name';

  /// Primary action: create a project from a shipped template.
  static const String firstRunStartProject = 'Start a project';

  /// Caption on the primary action naming the shipped template path.
  static const String firstRunStartCaption = 'Uses a shipped template';

  /// Secondary action: keep the name and go to capture without a project.
  static const String firstRunSkip = 'Skip';

  /// Status line when no project is open.
  static const String statusNoProject = 'No project';

  /// Status line when no context is pinned.
  static const String statusNoContext = 'No context';

  /// Status line when no template is pinned.
  static const String statusNoTemplate = 'No template';

  /// Project and context together on the status line.
  static String statusWhere(String project, String context) {
    return '$project · $context';
  }

  /// Unmetered path.
  static const String networkOnline = 'Online';

  /// Metered path.
  static const String networkMetered = 'Metered';

  /// Radio is down; not an operator choice.
  static const String networkOffline = 'Offline';

  /// The operator forced offline.
  static const String networkOfflineByChoice = 'Offline by choice';

  /// How many records still need processing.
  static String unprocessedCount(int n) {
    return Intl.plural(
      n,
      zero: '0 unprocessed',
      one: '1 unprocessed',
      other: '$n unprocessed',
    );
  }

  /// Why work continues without a network. Not an error.
  static const String offlineWorking =
      'You are offline. Captures stay on this device.';

  /// Title of the last-resort crash recovery screen.
  static const String somethingWentWrong = 'Something went wrong';

  /// Reassurance that a crash did not wipe local work.
  static const String workStillOnDevice = 'Your work is still on this device.';

  /// Remounts the failed subtree under the existing provider scope.
  static const String restart = 'Restart';

  /// Writes the diagnostics buffer to a shareable file.
  static const String exportLog = 'Export the log';

  /// Opens restored records. The destination is the recycle bin once 168
  /// exists.
  static const String openRecycleBin = 'Open recycle bin';
}
