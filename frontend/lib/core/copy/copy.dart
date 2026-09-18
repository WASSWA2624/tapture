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

  /// Reveals a hidden field such as a PIN, named for its label.
  static String showField(String label) => 'Show $label';

  /// Hides a revealed field again, named for its label.
  static String hideField(String label) => 'Hide $label';

  /// The camera or photo library was refused.
  static const String photoNoAccess =
      'Allow the camera or photos to attach one. Everything else still works.';

  /// The device has no camera the app can open.
  static const String photoNoCamera = 'No camera is available on this device.';

  /// The picker failed for a reason it did not name.
  static const String photoPickFailed =
      'That photo could not be added. Try another.';

  /// Starts dictation into a field, named for its label.
  static String dictateInto(String label) => 'Speak into $label';

  /// Stops dictation into a field, named for its label.
  static String stopDictating(String label) => 'Stop speaking into $label';

  /// The platform has no recogniser this app can reach.
  static const String dictationUnavailable =
      'Voice input is not available here. Type instead.';

  /// The microphone was refused.
  static const String dictationNoMicrophone =
      'Allow the microphone to speak into a field. Typing still works.';

  /// The recogniser heard nothing it could use.
  static const String dictationNothingHeard =
      'Nothing was heard. Tap the microphone and speak again.';

  /// The recogniser needs a connection it does not have.
  static const String dictationNeedsConnection =
      'Voice input needs a connection on this device. Type instead.';

  /// Offline by choice, and this device cannot recognise speech locally.
  static const String dictationOfflineOnly =
      'You are working offline, and this device cannot recognise speech '
      'without a connection. Type instead.';

  /// The recogniser stopped for a reason it did not name.
  static const String dictationFailed =
      'Voice input stopped. Try again, or type instead.';

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

  /// Caption on a field that must be filled before Save.
  static const String fieldRequired = 'Required';

  /// Caption on a field that may be left empty.
  static const String fieldOptional = 'Optional';

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

  /// Semantic name of the title-bar overflow control.
  static const String overflowMenu = 'More options';

  /// Shell destination: the project list.
  static const String navProjects = 'Projects';

  /// Shell destination: capture. Visually dominant in the four-destination bar.
  static const String navCapture = 'Capture';

  /// Shell destination: the records list.
  static const String navRecords = 'Records';

  /// Shell destination: settings and the rest.
  static const String navMore = 'Settings';

  /// Pinned-template destination the status line opens.
  static const String navTemplates = 'Templates';

  /// Unprocessed-queue destination the status line opens.
  static const String navQueue = 'Unprocessed';

  /// Why the operator name is asked.
  static const String operatorNameUse =
      'Used on every record you capture from this device.';

  /// Label of the operator name field.
  static const String operatorName = 'Name';

  /// Settings screen for the local operator identity.
  static const String operatorProfileTitle = 'Operator';

  /// Initials field on the operator profile.
  static const String operatorInitials = 'Initials';

  /// Optional contact field on the operator profile.
  static const String operatorContact = 'Contact';

  /// Name failed the non-empty rule.
  static const String nameRequired = 'Enter a name';

  /// Initials failed the one-to-three-character rule.
  static const String initialsLength = 'Use one to three characters';

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

  /// Manual offline switch title.
  static const String settingsOfflineTitle = 'Stay offline';

  /// What keeps working while the switch is on.
  static const String settingsOfflineEffect =
      'Everything still works except sending.';

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
  static const String exportLog = 'Export log';

  /// Opens restored records. The destination is the recycle bin once 168
  /// exists.
  static const String openRecycleBin = 'Recycle bin';

  /// Settings root title.
  static const String settingsTitle = 'Settings';

  /// Operator tile supporting line.
  static const String settingsOperatorSubtitle =
      'Name, initials and contact on this device.';

  /// Capture tile supporting line.
  static const String settingsCaptureSubtitle =
      'Camera, dates, GPS and how new files are named.';

  /// AI section title. The screen arrives in a later phase.
  static const String settingsAiTitle = 'AI';

  /// AI tile supporting line.
  static const String settingsAiSubtitle = 'When and how proposals run.';

  /// Language section title. The screen arrives in a later phase.
  static const String settingsLanguageTitle = 'Language';

  /// Language tile supporting line.
  static const String settingsLanguageSubtitle = 'App and voice.';

  /// Storage section title.
  static const String settingsStorageTitle = 'Storage';

  /// Storage tile supporting line.
  static const String settingsStorageSubtitle =
      'Space used, cache and how long files stay.';

  /// Specification "Data" section. Copy rejects the word "data".
  static const String settingsFilesTitle = 'Files';

  /// Files tile supporting line.
  static const String settingsFilesSubtitle =
      'Import, export and the recycle bin.';

  /// Security section title. The screen arrives in a later phase.
  static const String settingsSecurityTitle = 'Security';

  /// Security tile supporting line.
  static const String settingsSecuritySubtitle =
      'App lock and export encryption.';

  /// About section title.
  static const String settingsAboutTitle = 'About';

  /// About tile supporting line.
  static const String settingsAboutSubtitle = 'Version, licences and the plan.';

  /// Camera default row.
  static const String settingsCamera = 'Camera';

  /// Effect of the camera default.
  static const String settingsCameraEffect =
      'Used at the start of the next session.';

  /// Label for the photo camera default.
  static const String settingsCameraPhoto = 'Photo';

  /// Auto-filled dates row.
  static const String settingsAutoFillDates = 'Fill dates automatically';

  /// Effect of auto-filled dates.
  static const String settingsAutoFillDatesEffect =
      'New captures get today without asking.';

  /// GPS row.
  static const String settingsGps = 'GPS';

  /// Why GPS stays off until a person turns it on (FE-SEC-07).
  static const String settingsGpsWhyOff =
      'Off until you turn it on, so a location is never stored by accident.';

  /// Photo quality row.
  static const String settingsPhotoQuality = 'Photo quality';

  /// Effect of photo quality.
  static const String settingsPhotoQualityEffect =
      'Higher quality makes larger files.';

  /// Standard JPEG quality label.
  static const String settingsQualityStandard = 'Standard';

  /// Smaller JPEG quality label.
  static const String settingsQualitySmaller = 'Smaller files';

  /// Folder strategy row.
  static const String settingsFolderStrategy = 'Photo folders';

  /// Folder strategy applies only to files not yet written.
  static const String settingsFolderStrategyNewFilesOnly =
      'Applies to new files only. Existing files stay put.';

  /// Folder strategy: group by context.
  static const String settingsFolderByContext = 'By context';

  /// Folder strategy: group by template.
  static const String settingsFolderByTemplate = 'By template';

  /// Folder strategy: group by capture date.
  static const String settingsFolderByDate = 'By date';

  /// Folder strategy: no extra folders.
  static const String settingsFolderFlat = 'One folder';

  /// Naming pattern row.
  static const String settingsNamingPattern = 'File names';

  /// Effect of the naming pattern.
  static const String settingsNamingPatternEffect =
      'How a new photo file is named.';

  /// Camera row, including the current value and its effect.
  static String settingsCameraSubtitle(String label) {
    return '$label. $settingsCameraEffect';
  }

  /// Photo-quality row, including the current value and its effect.
  static String settingsPhotoQualitySubtitle(String label) {
    return '$label. $settingsPhotoQualityEffect';
  }

  /// Naming-pattern row, including the current value and its effect.
  static String settingsNamingSubtitle(String pattern) {
    return '$pattern. $settingsNamingPatternEffect';
  }

  /// Folder strategy row, including the new-files-only statement.
  static String settingsFolderStrategySubtitle(String strategy) {
    return '$strategy. $settingsFolderStrategyNewFilesOnly';
  }

  /// Projects group on the storage screen.
  static const String settingsProjectsHeader = 'Projects';

  /// Free-space group on the storage screen.
  static const String settingsHeadroomHeader = 'Free space';

  /// Retention group on the storage screen.
  static const String settingsRetentionHeader = 'Retention';

  /// Headroom is ample.
  static const String settingsHeadroomAmple = 'Plenty of space';

  /// Headroom is low.
  static const String settingsHeadroomLow = 'Space is getting low';

  /// Headroom is critical.
  static const String settingsHeadroomCritical =
      'Not enough space for a new photo';

  /// Clear-cache row.
  static const String settingsClearCache = 'Clear cache';

  /// Effect of clearing the cache.
  static const String settingsClearCacheEffect =
      'Removes derived copies only. Originals stay.';

  /// Cache row with the current size.
  static String settingsCacheSize(String size) {
    return '$settingsCache · $size. $settingsClearCacheEffect';
  }

  /// Retention row with the current window.
  static String settingsRetentionSubtitle(int days) {
    return '${settingsRetentionDays(days)}. $settingsRetentionEffect';
  }

  /// Confirm title for clearing the cache.
  static const String settingsClearCacheTitle = 'Clear the cache?';

  /// Confirm body for clearing the cache.
  static const String settingsClearCacheMessage =
      'Thumbnails and upload copies will be removed. Original photos stay.';

  /// Retention row.
  static const String settingsRetention = 'Keep deleted files';

  /// Effect of the retention window.
  static const String settingsRetentionEffect =
      'How long a deleted file can be restored.';

  /// Retention window in days.
  static String settingsRetentionDays(int n) {
    return Intl.plural(n, zero: '0 days', one: '1 day', other: '$n days');
  }

  /// Documents breakdown label.
  static const String settingsDocuments = 'Documents';

  /// Audio breakdown label.
  static const String settingsAudio = 'Audio';

  /// Exports breakdown label.
  static const String settingsExports = 'Exports';

  /// Cache usage row title.
  static const String settingsCache = 'Cache';

  /// Empty storage headline.
  static const String settingsStorageEmptyHeadline = 'No project folders yet';

  /// Empty storage next step.
  static const String settingsStorageEmptyMessage =
      'Space used appears here once a project has files.';

  /// A file size shown on the storage screen.
  static String fileSize(int bytes) {
    const int k = 1024;
    if (bytes < k) {
      return '$bytes B';
    }
    if (bytes < k * k) {
      return '${(bytes / k).round()} KB';
    }
    return '${(bytes / (k * k)).round()} MB';
  }

  /// Per-project breakdown on one line.
  static String settingsProjectUse({
    required String photos,
    required String documents,
    required String audio,
    required String exports,
  }) {
    return 'Photos $photos · $settingsDocuments $documents · '
        '$settingsAudio $audio · $settingsExports $exports';
  }

  /// Version row.
  static const String settingsVersion = 'Version';

  /// Build-number row.
  static const String settingsBuild = 'Build';

  /// Licences row.
  static const String settingsLicences = 'Licences';

  /// Effect of the licences row.
  static const String settingsLicencesEffect =
      'Open-source licences used in this app.';

  /// Plan link row.
  static const String settingsPlan = 'The plan';

  /// Specification link row.
  static const String settingsSpecification = 'The specification';

  /// Public plan URL shown on About.
  static const String settingsPlanUrl =
      'https://github.com/WASSWA2624/tapture/tree/main/dev-plan';

  /// Public specification URL shown on About.
  static const String settingsSpecificationUrl =
      'https://github.com/WASSWA2624/tapture';

  /// Empty settings headline.
  static const String settingsEmptyHeadline = 'No settings yet';

  /// Empty settings next step.
  static const String settingsEmptyMessage =
      'Settings for this device will appear here.';

  /// Empty capture-settings headline.
  static const String settingsCaptureEmptyHeadline = 'No capture defaults yet';

  /// Empty capture-settings next step.
  static const String settingsCaptureEmptyMessage =
      'Camera, dates and GPS will appear here.';

  /// Empty about headline.
  static const String settingsAboutEmptyHeadline = 'No version yet';

  /// Empty about next step.
  static const String settingsAboutEmptyMessage =
      'The version and licences will appear here.';

  /// Unlock-gate title.
  static const String appLockUnlockTitle = 'Unlock Tapture';

  /// Settings title for the PIN lock.
  static const String appLockTitle = 'App lock';

  /// PIN field.
  static const String appLockPin = 'PIN';

  /// Current PIN when changing or removing the lock.
  static const String appLockCurrentPin = 'Current PIN';

  /// New PIN when setting or changing the lock.
  static const String appLockNewPin = 'New PIN';

  /// Confirm-PIN field.
  static const String appLockConfirmPin = 'Confirm PIN';

  /// Sets the lock for the first time.
  static const String appLockSet = 'Set PIN';

  /// Replaces the stored PIN.
  static const String appLockChange = 'Change PIN';

  /// Turns the lock off.
  static const String appLockRemove = 'Remove PIN';

  /// Unlock-gate submit.
  static const String appLockUnlock = 'Unlock';

  /// Offers the device biometric path when it is enrolled.
  static const String appLockBiometrics = 'Unlock with this device';

  /// Effect of setting a PIN.
  static const String appLockSetEffect =
      'Required the next time the app opens or returns.';

  /// Effect of removing the PIN.
  static const String appLockRemoveEffect =
      'The next open will not ask for a PIN.';

  /// Stated when the lock is armed.
  static const String appLockOn = 'App lock is on.';

  /// Stated when no PIN is stored.
  static const String appLockOff =
      'App lock is off. Set a PIN to require it on launch and resume.';

  /// PIN shape.
  static const String appLockPinLength = 'Use 4 to 8 digits.';

  /// Confirm field does not match.
  static const String appLockPinMismatch = 'The two PINs do not match.';

  /// Submitted PIN does not match the stored hash.
  static const String appLockWrongPin = 'That PIN does not match.';

  /// Recovery path. Does not offer a wipe (FE-SIMP-09).
  static const String appLockRecovery =
      'Nobody can reset this PIN. Your files stay on this device. '
      'Nothing here deletes them.';

  /// Closes a dialog or panel without acting.
  static const String close = 'Close';

  /// The floating feedback control: its label, tooltip and semantic name.
  static const String feedback = 'Feedback';

  /// How the floating feedback control behaves, for screen readers.
  static const String feedbackButtonHint =
      'Opens the feedback options. Drag to move it.';

  /// Opens the form to write feedback.
  static const String feedbackGive = 'Give us feedback';

  /// Opens the filter to download feedback as a spreadsheet and screenshots.
  static const String feedbackDownload = 'Download feedback';

  /// Opens the filter to delete feedback.
  static const String feedbackDelete = 'Delete feedback';

  /// Where feedback goes. Nothing is sent (FE-SEC-10).
  static const String feedbackStaysOnDevice =
      'Saved on this device only. Nothing is sent anywhere.';

  /// Feedback type: anything that is not one of the others.
  static const String feedbackCategoryGeneral = 'General';

  /// Feedback type: something that works but could work better.
  static const String feedbackCategoryImprovement = 'Improvement';

  /// Feedback type: something is wrong.
  static const String feedbackCategoryError = 'Error';

  /// Feedback type: an idea.
  static const String feedbackCategorySuggestion = 'Suggestion';

  /// Feedback type: the operator names it.
  static const String feedbackCategoryOther = 'Other';

  /// Who wrote an entry: enrolled with the organisation.
  static const String feedbackSubmitterSignedIn = 'Signed-in user';

  /// Who wrote an entry: a named local operator.
  static const String feedbackSubmitterLocal = 'Local operator';

  /// Who wrote an entry: no name was set.
  static const String feedbackSubmitterAnonymous = 'Anonymous';

  /// Device kind: a touch phone.
  static const String feedbackDeviceMobile = 'Mobile';

  /// Device kind: a touch tablet.
  static const String feedbackDeviceTablet = 'Tablet';

  /// Device kind: a desktop, natively or in a desktop browser.
  static const String feedbackDeviceDesktop = 'Desktop';

  /// Label of the feedback type choice.
  static const String feedbackType = 'Type of feedback';

  /// Label of the field that names an "other" type.
  static const String feedbackOtherType = 'What kind of feedback is it?';

  /// The "other" type was chosen but not named.
  static const String feedbackOtherRequired = 'Say what kind of feedback it is';

  /// Label of the feedback text.
  static const String feedbackMessage = 'Your feedback';

  /// Prompt inside the empty feedback text.
  static const String feedbackMessageHint =
      'What happened, or what would make this better?';

  /// The feedback text was empty.
  static const String feedbackMessageRequired = 'Write your feedback';

  /// Attaches the screenshot taken when Feedback was tapped.
  static const String feedbackAttachScreenshot = 'Attach screenshot';

  /// Continues a feedback draft started on another screen.
  static const String feedbackContinue = 'Continue feedback';

  /// Adds a screenshot of the screen currently under the overlay.
  static const String feedbackAddScreen = 'Add this screen';

  /// Opens the device camera for a photo to attach.
  static const String feedbackTakePhoto = 'Take a photo';

  /// Opens the device library for photos to attach.
  static const String feedbackChoosePhoto = 'Choose photos';

  /// The attach checkbox, counting the images it covers.
  static String feedbackAttachImages(int n) {
    return Intl.plural(n, one: 'Attach 1 image', other: 'Attach $n images');
  }

  /// How many images a kept draft holds, for the compact bar.
  static String feedbackImageCount(int n) {
    return Intl.plural(n, one: '1 image', other: '$n images');
  }

  /// Removes one attached photo or screenshot.
  static String feedbackRemoveShot(String label) => 'Remove $label';

  /// Semantic name of a larger attached-photo preview.
  static const String feedbackShotPreview = 'Photo preview';

  /// Discards the in-progress feedback draft.
  static const String feedbackDiscardDraft = 'Discard draft';

  /// Confirms discarding the in-progress feedback draft.
  static const String feedbackDiscardDraftMessage =
      'This feedback and its photos will be cleared.';

  /// Collapses the feedback form so the rest of the app stays usable.
  static const String feedbackContinueLater = 'Continue later';

  /// Compact bar while a draft is kept across screens.
  static const String feedbackDraftBarHint =
      'Opens the feedback you started. Keep typing or speaking here.';

  /// Announced when a screenshot of [screen] was added to the draft.
  static String feedbackShotAdded(String screen) {
    return 'Added a screenshot of $screen';
  }

  /// The draft already holds as many photos as it will take.
  static const String feedbackShotsFull =
      'Remove a photo before adding another.';

  /// What the screenshot shows, named for the screen it was taken on.
  static String feedbackScreenshotOf(String screen) {
    return 'Screenshot of $screen';
  }

  /// The draft holds no screenshot or photo yet.
  static const String feedbackNoScreenshot = 'No images yet';

  /// Semantic name of the screenshot preview.
  static const String feedbackScreenshotPreview = 'Screenshot preview';

  /// Saves the feedback entry.
  static const String feedbackSave = 'Save feedback';

  /// Announced once the entry is durable.
  static const String feedbackSaved = 'Feedback saved on this device.';

  /// Filter: feedback types.
  static const String feedbackTypes = 'Types';

  /// Filter: earliest submission.
  static const String feedbackFrom = 'Submitted from';

  /// Filter: latest submission.
  static const String feedbackTo = 'Submitted to';

  /// The date range runs backwards.
  static const String feedbackRangeBackwards =
      'The start is after the end. Swap them or clear one.';

  /// Filter: screens feedback was given on.
  static const String feedbackScreens = 'Screens';

  /// Filter: platforms.
  static const String feedbackPlatforms = 'Platforms';

  /// Filter: device types.
  static const String feedbackDeviceTypes = 'Device types';

  /// Filter: who submitted.
  static const String feedbackSubmittedBy = 'Submitted by';

  /// Filter: whether a screenshot is attached.
  static const String feedbackScreenshot = 'Screenshot';

  /// Screenshot filter: either way.
  static const String feedbackScreenshotAny = 'Any';

  /// Screenshot filter: attached.
  static const String feedbackScreenshotWith = 'With';

  /// Screenshot filter: not attached.
  static const String feedbackScreenshotWithout = 'Without';

  /// Prompt on the feedback text search.
  static const String feedbackSearch = 'Search the feedback text';

  /// Resets every feedback filter.
  static const String feedbackClearFilters = 'Clear filters';

  /// Opens the facets beyond search and type, counting those in use.
  static String feedbackMoreFilters(int active) {
    return Intl.plural(
      active,
      zero: 'More filters',
      one: 'More filters (1)',
      other: 'More filters ($active)',
    );
  }

  /// Folds the extra facets away again.
  static const String feedbackFewerFilters = 'Fewer filters';

  /// How many entries the filters let through.
  static String feedbackMatching(int matching, int total) {
    return Intl.plural(
      total,
      one: '$matching of 1 entry matches',
      other: '$matching of $total entries match',
    );
  }

  /// Downloads the matching entries.
  static String feedbackDownloadCount(int n) {
    return Intl.plural(
      n,
      zero: 'Nothing to download',
      one: 'Download 1 entry',
      other: 'Download $n entries',
    );
  }

  /// The browser took the download.
  static const String feedbackDownloadStarted = 'Download started.';

  /// The archive was written to [location] on this device.
  static String feedbackDownloadedTo(String location) => 'Saved to $location';

  /// Nothing has been written yet.
  static const String feedbackEmptyHeadline = 'No feedback yet';

  /// Next step when nothing has been written (FE-SIMP-11).
  static const String feedbackEmptyMessage =
      'Tap Feedback on any screen to write the first entry.';

  /// The filters let nothing through.
  static const String feedbackNoMatchHeadline = 'No feedback matches';

  /// Next step when the filters let nothing through.
  static const String feedbackNoMatchMessage =
      'Change or clear the filters to see more.';

  /// How many entries are ticked for deletion.
  static String feedbackSelected(int n) {
    return Intl.plural(
      n,
      zero: 'None selected',
      one: '1 selected',
      other: '$n selected',
    );
  }

  /// Deletes the ticked entries.
  static String feedbackDeleteCount(int n) {
    return Intl.plural(
      n,
      zero: 'Select entries to delete',
      one: 'Delete 1 entry',
      other: 'Delete $n entries',
    );
  }

  /// Title of the delete confirm, naming the count (FE-SIMP-07).
  static String feedbackDeleteTitle(int n) {
    return Intl.plural(
      n,
      one: 'Delete 1 feedback entry?',
      other: 'Delete $n feedback entries?',
    );
  }

  /// Body of the delete confirm, naming the consequence (FE-SIMP-07).
  static String feedbackDeleteMessage(int n) {
    return Intl.plural(
      n,
      one:
          'It and its screenshot are removed from this device for good. '
          'You can undo straight after.',
      other:
          'They and their screenshots are removed from this device for '
          'good. You can undo straight after.',
    );
  }

  /// Announced once the entries are gone.
  static String feedbackDeleted(int n) {
    return Intl.plural(
      n,
      one: '1 feedback entry deleted',
      other: '$n feedback entries deleted',
    );
  }

  /// Loads the next page of entries.
  static const String feedbackShowMore = 'Show more';

  /// One entry's facts on a list row: type, when and where.
  static String feedbackEntryFacts(String type, String when, String screen) {
    return '$type · $when · $screen';
  }

  /// Remaining backoff after a failed unlock.
  static String appLockWait(Duration remaining) {
    // Rounded up, so the count never reads lower than the real wait.
    final int whole = (remaining.inMilliseconds + 999) ~/ 1000;
    final int seconds = whole < 1 ? 1 : whole;
    return Intl.plural(
      seconds,
      one: 'Wait 1 second before trying again.',
      other: 'Wait $seconds seconds before trying again.',
    );
  }
}
