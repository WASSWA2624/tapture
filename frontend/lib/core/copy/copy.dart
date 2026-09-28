import 'package:intl/intl.dart';
import 'package:tapture/app/theme/markup_ink.dart';

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

  /// How many fields a template holds. Zero is a stated absence, not a blank.
  static String fieldsCount(int n) {
    return Intl.plural(
      n,
      zero: 'No fields',
      one: '1 field',
      other: '$n fields',
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

  /// The browser display picker was refused.
  static const String displayNoAccess =
      'Allow screen capture to attach another window. Everything else still '
      'works.';

  /// The device has no camera the app can open.
  static const String photoNoCamera = 'No camera is available on this device.';

  /// The picker failed for a reason it did not name.
  static const String photoPickFailed =
      'That photo could not be added. Try another.';

  /// The display picker failed for a reason it did not name.
  static const String displayCaptureFailed =
      'That window could not be captured. Try another.';

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

  /// Label of a field that must be filled before Save.
  static String fieldLabelRequired(String label) {
    return Intl.message(
      '$label (required)',
      name: 'fieldLabelRequired',
      args: <Object>[label],
    );
  }

  /// Label of a field that may be left empty.
  static String fieldLabelOptional(String label) {
    return Intl.message(
      '$label (optional)',
      name: 'fieldLabelOptional',
      args: <Object>[label],
    );
  }

  /// Announced summary of invalid fields.
  static String validationAnnouncement(String heading, List<String> errors) {
    return '$heading. ${errors.join('. ')}';
  }

  /// Placeholder when a cached thumb file is missing.
  static const String missingPhoto = 'Missing photo';

  /// Semantic name of a thumbnail's selection checkbox.
  static const String photoSelect = 'Select photo';

  /// A stored photo's file could not be read for its thumbnail.
  static const String photoUnreadable =
      'That photo could not be read from this device.';

  /// Recovery for [photoUnreadable].
  static const String photoUnreadableRecovery =
      'Capture the photo again, then try again.';

  /// Semantic name of a missing thumb, including its type.
  static String missingPhotoNamed(String type) => 'Missing photo, $type';

  /// Fallback type name when a photo has none.
  static const String photo = 'Photo';

  /// Crop action on the photo viewer.
  static const String photoCrop = 'Crop';

  /// Semantic name of a crop frame corner handle.
  static const String photoCropCorner = 'Crop corner, drag to resize';

  /// Semantic name of the crop frame body.
  static const String photoCropFrame = 'Crop frame, drag to move';

  /// Rotate the visible photo a quarter turn.
  static const String photoRotate = 'Rotate';

  /// Open freehand drawing.
  static const String photoDraw = 'Draw';

  /// Remove the latest stroke.
  static const String photoUndoDraw = 'Undo drawing';

  /// Remove every stroke.
  static const String photoClearDraw = 'Clear drawing';

  /// Name of a markup ink, read beside its swatch (FE-A11Y-05).
  static String markupInk(MarkupInk ink) {
    return switch (ink) {
      MarkupInk.red => 'Red',
      MarkupInk.yellow => 'Yellow',
      MarkupInk.white => 'White',
      MarkupInk.black => 'Black',
      MarkupInk.blue => 'Blue',
      MarkupInk.green => 'Green',
    };
  }

  /// Label of the markup ink swatches.
  static const String markupInkLabel = 'Ink';

  /// Label of the markup size choice.
  static const String markupSize = 'Size';

  /// Switches the dark backing behind typed text on a photo.
  static const String markupBacking = 'Dark backing';

  /// What the dark backing does.
  static const String markupBackingDescription =
      'Keeps the words readable on a busy photo.';

  /// How to place typed text on a photo.
  static const String markupTypeHint = 'Drag the photo to move the words.';

  /// The thinnest stroke or smallest text.
  static const String markupSizeSmall = 'Small';

  /// The middle stroke or text size.
  static const String markupSizeMedium = 'Medium';

  /// The thickest stroke or largest text.
  static const String markupSizeLarge = 'Large';

  /// How many photos are in the tray.
  static String capturePhotoCount(int count) => Intl.plural(
    count,
    zero: 'No photos',
    one: '1 photo',
    other: '$count photos',
  );

  /// Badge while a photo is still being prepared.
  static const String capturePhotoProcessing = 'Processing';

  /// Clears a derived crop or typed copy.
  static const String photoRevert = 'Revert';

  /// The preview's caption line when a photo has none.
  static const String photoNoCaption = 'No caption yet';

  /// Opens the caption editor in the photo preview.
  static const String photoCaptionEdit = 'Edit caption';

  /// Removes a photo's caption in the preview.
  static const String photoCaptionDelete = 'Delete caption';

  /// What deleting a caption does.
  static const String photoCaptionDeleteMessage =
      'The caption is removed from this photo. You can undo it.';

  /// Confirms a caption was removed, beside Undo.
  static const String photoCaptionDeleted = 'Caption deleted.';

  /// Types words onto a derived copy of a photo.
  static const String photoTypeOn = 'Type on this photo';

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

  /// What to change when a search matches nothing.
  static const String searchNoMatchMessage = 'Change the search.';

  /// The filter button on a search field, with how many filters are on.
  static String searchFilters(int active) {
    return active == 0 ? 'Filters' : 'Filters ($active)';
  }

  /// Turns every filter of a list off.
  static const String searchClearFilters = 'Clear filters';

  /// What to change when a search and its filters match nothing.
  static const String searchFilterNoMatchMessage =
      'Change the search or clear the filters.';

  /// Semantic name of the title-bar overflow control.
  static const String overflowMenu = 'More options';

  /// Shell destination: the project list.
  static const String navProjects = 'Projects';

  /// Headline when the project list has nothing to show.
  static const String projectsEmptyHeadline = 'No projects yet';

  /// Body when the project list has nothing to show.
  static const String projectsEmptyMessage =
      'Create a project to start capturing.';

  /// Primary empty-state action on the project list.
  static const String projectsCreate = 'Create a project';

  /// Headline when the project search matches nothing.
  static const String projectsNoMatchHeadline = 'No matching projects';

  /// Body when the project search matches nothing.
  static const String projectsNoMatchMessage =
      'Try a different name, or create a project.';

  /// Search prompt for names, descriptions, and organisations.
  static const String projectSearchHint = 'Search projects';

  /// Secondary filter-sheet title.
  static const String projectFiltersTitle = 'Project filters';

  /// Status filter heading.
  static const String projectStatusFilter = 'Status';

  /// Pin-state filter heading.
  static const String projectPinFilter = 'Pinned state';

  /// Human label for a pin filter wire name.
  static String projectPinFilterLabel(String value) {
    return switch (value) {
      'pinned' => 'Pinned',
      'unpinned' => 'Unpinned',
      _ => 'All projects',
    };
  }

  /// Commits project filter choices.
  static const String projectApplyFilters = 'Apply filters';

  /// Semantic status for a project that stays at the top of the list.
  static const String pinnedProject = 'Pinned project';

  /// Project-home template association count.
  static String projectTemplateCount(int count) {
    return Intl.plural(
      count,
      zero: 'No templates attached',
      one: '1 template attached',
      other: '$count templates attached',
    );
  }

  /// Secondary empty-state action on the project list. Reserved for task 222
  /// once bundle import ships; the Projects empty state does not show it yet.
  static const String projectsImport = 'Import a project';

  /// Duplicate action that opens the create form from an existing project.
  static const String projectsDuplicate = 'Duplicate';

  /// Overflow command that returns to the project list from a project home.
  static const String projectAllProjects = 'All projects';

  /// Overflow command that opens the create form from a project home.
  static const String projectNew = 'New project';

  /// Hides a finished project from the active list.
  static const String projectArchive = 'Archive';

  /// Restores an archived project to the active list.
  static const String projectUnarchive = 'Unarchive';

  /// Soft-deletes a project after typed confirmation.
  static const String projectDelete = 'Delete project';

  /// Row menu label. The confirm dialog keeps [projectDelete].
  static const String projectDeleteMenu = 'Delete';

  /// Title of the delete confirmation, naming the project.
  static String projectDeleteTitle(String name) => 'Delete $name?';

  /// Body of the delete confirmation, naming counts and retention.
  static String projectDeleteMessage({
    required int records,
    required int files,
    required int days,
  }) {
    return 'This hides ${recordsCount(records)} and ${filesCount(files)}. '
        'You can restore them for $days days. Nothing is removed yet.';
  }

  /// How many files a delete would hide.
  static String filesCount(int n) {
    return Intl.plural(n, zero: 'no files', one: '1 file', other: '$n files');
  }

  /// Typed-name field on the delete confirmation.
  static const String projectDeleteTypeName = 'Type the project name';

  /// Alternative on the delete confirmation: export before deleting.
  static const String projectExportFirst = 'Export first';

  /// Filter that reveals archived projects on the landing list.
  static const String projectShowArchived = 'Show archived';

  /// Pins a project to the top of the list.
  static const String projectPin = 'Pin';

  /// Removes a project from the top of the list.
  static const String projectUnpin = 'Unpin';

  /// Opens the rename dialog for a project.
  static const String projectRename = 'Rename';

  /// Title of the rename dialog.
  static const String projectRenameTitle = 'Rename project';

  /// Body of the rename dialog. The folder on disk stays put.
  static const String projectRenameMessage = 'The folder on disk stays put.';

  /// Hands a copy of a project file to another app.
  static const String projectOpenWith = 'Open with';

  /// Saves a copy of a project file on the web, where no app can be launched.
  static const String projectDownloadCopy = 'Download a copy';

  /// Shown when Open with is asked for a project that has no file.
  static const String projectNothingToOpen =
      'This project has no spreadsheet, document or PDF to open yet.';

  /// What to do when there is nothing to open.
  static const String projectNothingToOpenRecovery =
      'Import a template workbook or export the project, then try again.';

  /// Title when the hand-off to another app failed.
  static const String projectOpenFailedTitle = 'Could not open the file';

  /// Body when the hand-off failed.
  static const String projectOpenFailed =
      'Tapture could not hand the file to another app.';

  /// Body when the named file could not be handed off.
  static String projectOpenFailedNamed(String fileName) =>
      'Tapture could not hand $fileName to another app.';

  /// Recovery when the hand-off failed.
  static const String projectOpenFailedRecovery =
      'Free some space, then try again.';

  /// When no installed app can open the file type.
  static const String projectOpenNoApp =
      'No app on this device can open that file.';

  /// Recovery when no reader is installed.
  static const String projectOpenNoAppRecovery =
      'Install a reader for this file type, then try again.';

  /// When storage permission was refused before writing the copy.
  static const String projectOpenPermission =
      'Tapture needs storage access to open a copy of this file.';

  /// Recovery when storage permission was refused.
  static const String projectOpenPermissionRecovery =
      'Allow storage access, then try again.';

  /// Visible position of a project in the current list.
  static String projectListNumber(int n) {
    return NumberFormat.decimalPattern().format(n);
  }

  /// Title of the create-project form.
  static const String projectCreateTitle = 'Create project';

  /// Title of the create form when it is copying another project.
  static const String projectDuplicateTitle = 'Duplicate project';

  /// Required name field on the create form.
  static const String projectName = 'Name';

  /// Optional longer note on the create form.
  static const String projectDescription = 'Description';

  /// Optional organisation field on the create form.
  static const String projectOrganisation = 'Organisation';

  /// Title of the read-only project page, and the menu item that opens it.
  static const String projectEditTitle = 'Project details';

  /// Title of the form that changes a project's details.
  static const String projectEditFormTitle = 'Edit project';

  /// Primary action on the project details page.
  static const String projectEditDetails = 'Edit details';

  /// A project detail nobody has filled in.
  static const String projectValueNotSet = 'Not set';

  /// When the project was created, on its details page.
  static const String projectCreatedAt = 'Created';

  /// When the project last changed, on its details page.
  static const String projectUpdatedAt = 'Last changed';

  /// Heading over the template whose fields the context levels come from.
  static const String contextLevelSource = 'Suggest levels from';

  /// Title of the per-project settings form.
  static const String projectSettingsTitle = 'Project settings';

  /// Confirms that the project details form was stored.
  static const String projectSaved = 'Project saved';

  /// Confirms that the project settings form was stored.
  static const String projectSettingsSaved = 'Settings saved';

  /// When fieldwork started.
  static const String projectStartsOn = 'Starts';

  /// When fieldwork finished.
  static const String projectEndsOn = 'Ends';

  /// Open or archived status on the details form.
  static const String projectStatus = 'Status';

  /// Status choice: the project is open.
  static const String projectStatusActive = 'Active';

  /// Status choice: the project is archived.
  static const String projectStatusArchived = 'Archived';

  /// AI override on the project settings form.
  static const String projectAiEnabled = 'AI';

  /// What turning AI off does.
  static const String projectAiEnabledEffect =
      'Turn off to keep this project fully manual.';

  /// Image-egress override on the project settings form.
  static const String projectDoNotSendImages = 'Do not send images';

  /// What turning image egress off does.
  static const String projectDoNotSendImagesEffect =
      'Providers never see photo bytes from this project.';

  /// Refined-columns override on the project settings form.
  static const String projectRefineColumns = 'Refined columns';

  /// High-confidence threshold on the project settings form.
  static const String projectConfidenceHigh = 'High confidence';

  /// Medium-confidence threshold on the project settings form.
  static const String projectConfidenceMedium = 'Medium confidence';

  /// Inherit the app-level value for this switch.
  static const String projectUseAppDefault = 'Use app default';

  /// Affirmative override on a three-way choice.
  static const String projectOn = 'On';

  /// Negative override on a three-way choice.
  static const String projectOff = 'Off';

  /// Names the app-level value a row is changing.
  static String projectAppDefault(String value) => 'App default: $value';

  /// Headline when the details form has no open project.
  static const String projectEditEmptyHeadline = 'No project open';

  /// Body when the details form has no open project.
  static const String projectEditEmptyMessage =
      'Open a project to edit its details.';

  /// Headline when the settings form has no open project.
  static const String projectSettingsEmptyHeadline = 'No project open';

  /// Body when the settings form has no open project.
  static const String projectSettingsEmptyMessage =
      'Open a project to change its settings.';

  /// Suggested name for a duplicated project, editable before commit.
  static String projectCopyName(String name) => '$name (copy)';

  /// When the project was last worked, as a date.
  static String projectLastWorked(DateTime at) {
    final DateTime day = at.toUtc();
    return 'Last worked ${day.day} ${_months[day.month - 1]} ${day.year}';
  }

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Counts and unprocessed records on one project list row.
  static String projectListSubtitle({
    required int records,
    required int unprocessed,
  }) {
    return '${recordsCount(records)} · ${unprocessedCount(unprocessed)}';
  }

  /// Position of one captured record on the project list.
  static String projectRecordPosition(int position) => 'Record $position';

  /// Empty project records list.
  static const String projectRecordsEmptyHeadline = 'No records here';

  /// Explains an empty project records filter.
  static const String projectRecordsEmptyMessage =
      'Captured records for this filter appear here.';

  /// Prompt on the project home search: what it looks through.
  static const String projectRecordsSearchHint = 'Search records';

  /// Title of a project's records filter sheet.
  static const String projectRecordFiltersTitle = 'Record filters';

  /// The record-status facet of a project's records filters.
  static const String projectRecordStatusFilter = 'Status';

  /// A project home search that matched no record, naming the query.
  static String projectRecordsNoMatch(String query) {
    final String shown = query.trim();
    if (shown.isEmpty) {
      return 'No records match.';
    }
    return 'No records match "$shown".';
  }

  /// A choice sheet search that matched no option, naming the query.
  static String choiceNoMatch(String query) {
    final String shown = query.trim();
    if (shown.isEmpty) {
      return 'Nothing matches.';
    }
    return 'Nothing matches "$shown".';
  }

  /// Overflow command that writes a project export.
  static const String projectExport = 'Export';

  /// Title of the project export screen.
  static const String projectExportTitle = 'Export project';

  /// Empty export screen.
  static const String projectExportEmptyHeadline = 'Nothing to export';

  /// Explains that a project needs a record before export.
  static const String projectExportEmptyMessage =
      'Capture a record before exporting this project.';

  /// Shares a finished export.
  static const String projectExportShare = 'Share';

  /// Names the file that was stored.
  static String projectExportSaved(String fileName) => 'Saved $fileName.';

  /// Says the share sheet reaches other apps (Android and iOS).
  static const String projectExportShareHint =
      'Send the file to email, chat and other apps on this device.';

  /// Export summary section: the project itself.
  static const String exportSectionProject = 'Project';

  /// Export summary section: records by status.
  static const String exportSectionRecords = 'Records';

  /// Export summary section: records per template.
  static const String exportSectionTemplates = 'Templates';

  /// Export summary section: the file the export writes.
  static const String exportSectionFile = 'File';

  /// Audio clips filed on the exported records.
  static String exportAudioClips(int n) => Intl.plural(
    n,
    zero: 'No audio clips',
    one: '1 audio clip',
    other: '$n audio clips',
  );

  /// When the exported records were captured. [first] and [last] are
  /// locale-formatted dates; one date when they are the same day.
  static String exportCapturedBetween(String first, String last) {
    if (first == last) {
      return 'Captured $first';
    }
    return 'Captured $first to $last';
  }

  /// Exported records not processed yet.
  static String exportUnprocessedCount(int n) => Intl.plural(
    n,
    zero: 'No unprocessed records',
    one: '1 unprocessed record',
    other: '$n unprocessed records',
  );

  /// Exported records waiting for a person to review.
  static String exportNeedsReviewCount(int n) => Intl.plural(
    n,
    zero: 'No records need review',
    one: '1 record needs review',
    other: '$n records need review',
  );

  /// Exported records already approved.
  static String exportApprovedCount(int n) => Intl.plural(
    n,
    zero: 'No approved records',
    one: '1 approved record',
    other: '$n approved records',
  );

  /// The export's file format.
  static const String exportFileFormat = 'Project package (.zip)';

  /// What the package holds, for another Tapture app and for a reader.
  static const String exportFileColumns =
      'Everything another Tapture app needs to open this project: records, '
      'photos, audio, templates, context, reference data and project '
      'settings, with a workbook of the records. Unsaved capture drafts stay '
      'on this device.';

  /// How big the package is expected to be, before it is written.
  static String exportPackageSize(int bytes) => 'About ${fileSize(bytes)}';

  /// Where the export file is saved: the Exports folder under [place], the
  /// short Downloads label.
  static String exportSavedTo(String place) => 'Saved to $place › Exports';

  /// Shown while the workbook is written.
  static const String projectExportProgress = 'Writing the export';

  /// Stops an export before a file is kept.
  static const String projectExportCancel = 'Cancel';

  /// Edits one captured record.
  static const String recordEdit = 'Edit';

  /// Label of the optional project photo on the create and edit screens.
  static const String projectPhoto = 'Project photo (optional)';

  /// Picks a photo for a project that has none.
  static const String projectPhotoAdd = 'Add a photo';

  /// Picks another photo for a project that has one.
  static const String projectPhotoChange = 'Change photo';

  /// Takes the photo off a project.
  static const String projectPhotoRemove = 'Remove photo';

  /// Title of the page that edits a saved record's photos and captions.
  static const String recordEditTitle = 'Edit record';

  /// Saves an edited record's photos, captions and audio.
  static const String recordEditSave = 'Save changes';

  /// Confirms an edited record was saved.
  static const String recordEditSaved = 'Record updated.';

  /// Edit sheet for a record with nothing to edit.
  static const String recordEditNoFieldsHeadline = 'No fields to edit';

  /// What to do when a record has no editable field.
  static const String recordEditNoFieldsMessage =
      "Add fields to this record's template, then edit the record here.";

  /// Archives one captured record. The photos stay on the device.
  static const String recordDelete = 'Delete';

  /// Confirm copy for archiving a captured record.
  static const String recordArchiveMessage =
      'The photos stay on this device. The record leaves this list.';

  /// Title of a record's page when no value names it.
  static const String recordDetailTitle = 'Record';

  /// A record with no caption, on its page.
  static const String recordNoCaption = 'No caption';

  /// A template field the record holds no value for.
  static const String recordFieldEmpty = 'Not entered';

  /// Record page section: its field values.
  static const String recordSectionFields = 'Fields';

  /// Opens the template-field editor from a record's page.
  static const String recordEditFields = 'Edit fields';

  /// When a record was captured. [when] is a locale-formatted date and time.
  static String recordCapturedAt(String when) => 'Captured $when';

  /// A record's page after it was deleted elsewhere.
  static const String recordGoneHeadline = 'This record is no longer here';

  /// What to do when a record's page has nothing to show.
  static const String recordGoneMessage =
      'It was deleted or is not on this device. Go back to the list.';

  /// Primary action on the open-project home when a record already exists.
  static const String continueCapturing = 'Continue capturing';

  /// Home primary action before the first record.
  static const String captureStart = 'Start capturing';

  /// Home primary action after at least one record.
  static const String captureMore = 'Capture more';

  /// Headline when the project home has no open project.
  static const String homeEmptyHeadline = 'No project open';

  /// Body when the project home has no open project.
  static const String homeEmptyMessage =
      'Open a project to see what to do next.';

  /// Shell destination: capture. Visually dominant in the four-destination bar.
  static const String navCapture = 'Capture';

  /// Shell destination: the records list.
  static const String navRecords = 'Records';

  /// Shell destination: settings and the rest.
  static const String navMore = 'Settings';

  /// Pinned-template destination the status line opens.
  static const String navTemplates = 'Templates';

  /// Project-scoped template list. The app-wide list keeps [navTemplates].
  static const String projectTemplatesTitle = 'Project templates';

  /// Project datasets destination.
  static const String navDatasets = 'Datasets';

  /// Headline when a project has no reference datasets.
  static const String datasetsEmptyHeadline = 'No datasets yet';

  /// Body when the dataset list is empty.
  static const String datasetsEmptyMessage =
      'Import a CSV, spreadsheet or JSON table to prefill capture fields.';

  /// Empty-state / primary action that starts an import.
  static const String datasetsImport = 'Import dataset';

  /// Title of the key-column confirmation screen.
  static const String datasetsKeyTitle = 'Choose the key column';

  /// Explains the key-column choice.
  static const String datasetsKeyMessage =
      'The key uniquely identifies each row for lookup.';

  /// Confirms saving despite duplicate keys.
  static const String datasetsAllowDuplicates = 'Save with duplicates';

  /// Saves the import after a unique key is chosen.
  static const String datasetsSaveImport = 'Save dataset';

  /// Duplicate-key warning with count.
  static String datasetsDuplicateCount(int n) {
    return Intl.plural(
      n,
      one: '1 duplicate key value',
      other: '$n duplicate key values',
    );
  }

  /// Sample colliding values.
  static String datasetsCollidingValues(List<String> values) {
    return 'Examples: ${values.join(', ')}';
  }

  /// List subtitle: rows · source · date.
  static String datasetListSubtitle({
    required int rows,
    required String source,
    required String importedAt,
  }) {
    return '${recordsCount(rows)} · $source · $importedAt';
  }

  /// Dataset source label.
  static String datasetSourceLabel(String source) {
    return switch (source) {
      'csv' => 'CSV',
      'xlsx' => 'Spreadsheet',
      'json' => 'JSON',
      'device' => 'On device',
      _ => source,
    };
  }

  /// Browser search hint.
  static const String datasetsSearchHint = 'Search rows';

  /// Choose visible columns on a narrow screen.
  static const String datasetsColumns = 'Columns';

  /// Row edit title.
  static const String datasetsEditRow = 'Edit row';

  /// Save row edits.
  static const String datasetsSaveRow = 'Save row';

  /// Add-row sheet title.
  static const String datasetsAddRow = 'Add row';

  /// Lookup picker title.
  static const String datasetsPickMatch = 'Choose a match';

  /// Lookup binding screen title.
  static const String datasetsLookupBinding = 'Lookup binding';

  /// Save lookup binding.
  static const String datasetsSaveBinding = 'Save binding';

  /// No datasets available for binding.
  static const String datasetsBindingEmptyHeadline =
      'No datasets in this project';

  /// Binding empty body.
  static const String datasetsBindingEmptyMessage =
      'Import a dataset before binding this field.';

  /// Fuzzy matching switch.
  static const String datasetsFuzzyEnabled = 'Allow fuzzy matches';

  /// No-match behaviour label.
  static const String datasetsOnNoMatch = 'When nothing matches';

  /// Mark a row added on device in the browser.
  static const String datasetsAddedOnDevice = 'Added on device';

  /// Export dataset action.
  static const String datasetsExport = 'Export';

  /// Headline when the dataset browser has no rows.
  static const String datasetsBrowserEmptyHeadline = 'No rows';

  /// Body when the dataset browser has no rows.
  static const String datasetsBrowserEmptyMessage =
      'This dataset has no rows to show.';

  /// Headline when the template list is empty.
  static const String templatesEmptyHeadline = 'No templates yet';

  /// Body when the template list is empty. The next action is the library.
  static const String templatesEmptyMessage =
      'Pick a shipped template to start capturing, or create a blank template.';

  /// Empty-state action that opens the shipped-library picker.
  static const String templatesPickLibrary = 'Pick a shipped template';

  /// Primary action that opens the blank-template form.
  static const String templatesCreate = 'Create a blank template';

  /// Renames a template from its row menu.
  static const String templatesEdit = 'Edit';

  /// Opens upload and library choices on the template list.
  static const String templatesAddChoices = 'Add templates';

  /// The add action once the project already has a template.
  static const String templatesAddMore = 'Add more templates';

  /// Empty project template list. The add action sits in the footer.
  static const String templatesAddEmptyMessage =
      'Add templates to start capturing. Create a blank template when none '
      'fits.';

  /// Uploads a template file.
  static const String templatesUpload = 'Upload a template';

  /// Attaches a template that already exists.
  static const String templatesUseExisting = 'Use an existing template';

  /// Search on the template list matched nothing.
  static const String templatesNoMatch = 'No matching templates';

  /// Title of the template list's filter sheet.
  static const String templateFiltersTitle = 'Template filters';

  /// The template-kind facet of the template list's filters.
  static const String templateKindFilter = 'Kind';

  /// A template that names no kind, as a filter option.
  static const String templateKindNone = 'No kind';

  /// Search on the field list matched nothing.
  static const String fieldsNoMatch = 'No matching fields';

  /// Title of a template field list's filter sheet.
  static const String fieldFiltersTitle = 'Field filters';

  /// The required, recommended or optional facet of the field filters.
  static const String fieldRequirednessFilter = 'Requirement';

  /// How a project chooses a template when capture starts.
  static const String templateChoiceLabel = 'Template choice';

  /// Use the only template, and ask when there are several.
  static const String templateChoiceAuto = 'Auto';

  /// Suggest a template and let the operator confirm.
  static const String templateChoiceSuggest = 'Suggest';

  /// Always ask which template to use.
  static const String templateChoiceManual = 'Manual';

  /// Title of the blank-template form.
  static const String templatesCreateTitle = 'New template';

  /// Opens the field list for a template.
  static const String templatesOpen = 'Open';

  /// Overflow command that writes a template out. Task 100 owns the screen.
  static const String templatesExport = 'Export template';

  /// Overflow command that reads a template JSON into this project.
  static const String templatesImport = 'Import template';

  /// Empty import destination: no file was given.
  static const String templatesImportEmptyHeadline = 'No template file';

  /// Empty import destination explanation.
  static const String templatesImportEmptyMessage =
      'Choose a template file to add it to this project.';

  /// Rejected because schema_version is missing or not this app's version.
  static const String templatesImportUnknownSchema =
      'That template file uses a schema this app does not read.';

  /// Recovery for an unknown schema version.
  static const String templatesImportUnknownSchemaRecovery =
      'Export the template again from this version of Tapture.';

  /// Rejected because the JSON is not a template object.
  static const String templatesImportInvalid = 'That file is not a template.';

  /// Recovery for an invalid template JSON.
  static const String templatesImportInvalidRecovery =
      'Choose a template file and try again.';

  /// Rejected because two fields share a key.
  static const String templatesImportDuplicateField =
      'Each field key must be unique on a template.';

  /// Recovery for a duplicate field key.
  static const String templatesImportDuplicateFieldRecovery =
      'Rename the duplicate key and export again.';

  /// The chosen spreadsheet is encrypted.
  static const String workbookPassword =
      'That spreadsheet is locked with a password.';

  /// Recovery for a password-protected spreadsheet.
  static const String workbookPasswordRecovery =
      'Unlock it, save a copy, and choose the copy.';

  /// The chosen spreadsheet could not be parsed.
  static const String workbookCorrupt = 'That spreadsheet could not be read.';

  /// Recovery for a corrupt spreadsheet.
  static const String workbookCorruptRecovery =
      'Keep the original. Export a copy and try again.';

  /// Title of the spreadsheet column-mapping screen.
  static const String xlsxMappingTitle = 'Map columns';

  /// Headline when no spreadsheet was given.
  static const String xlsxMappingEmptyHeadline = 'No spreadsheet';

  /// Body when the mapping screen has no file to read.
  static const String xlsxMappingEmptyMessage =
      'Choose a spreadsheet to map its columns onto a template.';

  /// Primary action that creates the template from the confirmed mapping.
  static const String xlsxMappingConfirm = 'Create template';

  /// Overflow command that omits one spreadsheet column.
  static const String xlsxMappingSkip = 'Skip this column';

  /// Overflow command that brings a skipped column back.
  static const String xlsxMappingInclude = 'Include this column';

  /// Subtitle when the operator has skipped a column.
  static const String xlsxMappingSkipped = 'Skipped';

  /// Proposed field shown on the right of a mapping row.
  static String xlsxMappingProposal({
    required String field,
    required String type,
    required String rule,
  }) {
    return '$field · $type · $rule';
  }

  /// Proposed label when a spreadsheet column has no header.
  static String xlsxMappingUntitled(String column) => 'Column $column';

  /// Template name when the sheet tab is blank.
  static const String xlsxMappingDefaultName = 'Spreadsheet';

  /// The chosen spreadsheet vanished before confirm.
  static const String xlsxMappingMissing =
      'That spreadsheet is no longer on this device.';

  /// Recovery when the chosen spreadsheet is missing.
  static const String xlsxMappingMissingRecovery =
      'Choose the spreadsheet again, then try again.';

  /// A copy of this name is already in the project templates folder.
  static const String xlsxMappingExists =
      'A copy of that spreadsheet is already in this project.';

  /// Recovery when the destination copy already exists.
  static const String xlsxMappingExistsRecovery =
      'Rename the spreadsheet, then try again.';

  /// Title of the per-row aliases screen.
  static const String rowAliasesTitle = 'Row aliases';

  /// Headline when the template has no checklist rows to name.
  static const String rowAliasesEmptyHeadline = 'No rows to name';

  /// Body when the aliases list is empty.
  static const String rowAliasesEmptyMessage =
      'Import spreadsheet rows first, then add the local names that should '
      'match them.';

  /// Field label for a row's aliases.
  static const String rowAliasesField = 'Aliases';

  /// Hint showing how local names are written.
  static const String rowAliasesHint = 'BP machine, BP';

  /// Overflow command that reads aliases from one spreadsheet column.
  static const String rowAliasesImport = 'Import from a column';

  /// Field label for the alias column letter.
  static const String rowAliasesColumn = 'Alias column';

  /// Stated absence when a row has no aliases yet.
  static const String rowAliasesNone = 'No aliases yet';

  /// Subtitle listing the aliases already stored on a row.
  static String rowAliasesList(List<String> aliases) {
    if (aliases.isEmpty) {
      return rowAliasesNone;
    }
    return aliases.join(', ');
  }

  /// Title of the capture checklist.
  static const String checklistTitle = 'Checklist';

  /// Headline when the template has no predefined rows.
  static const String checklistEmptyHeadline = 'Nothing on the checklist';

  /// Body when the checklist is empty.
  static const String checklistEmptyMessage =
      'Import spreadsheet rows to see what is still missing.';

  /// Status word for a row that has been found.
  static const String checklistFound = 'Found';

  /// Status word for a row that is still missing.
  static const String checklistMissing = 'Missing';

  /// Group name when a row has no room or context.
  static const String checklistUngrouped = 'Ungrouped';

  /// Group heading: the room name and how many rows have been found.
  static String checklistProgress({
    required String group,
    required int found,
    required int total,
  }) {
    return '$group · Found $found of $total';
  }

  /// Title of the detection-profile screen.
  static const String detectionProfileTitle = 'Detection';

  /// What the detection profile decides.
  static const String detectionProfileExplain =
      'A photo is matched to this template from these signals. A negative '
      'keyword rules it out.';

  /// Headline when no template is open.
  static const String detectionProfileEmptyHeadline =
      'No template to configure';

  /// Body when the detection screen has no template.
  static const String detectionProfileEmptyMessage =
      'Open a template first, then set how a photo is matched to it.';

  /// Field label for vision object classes.
  static const String detectionProfileClasses = 'Object classes';

  /// Field label for OCR keywords.
  static const String detectionProfileKeywords = 'Keywords';

  /// Section for identifier patterns reused from field validation.
  static const String detectionProfilePatterns = 'Identifier patterns';

  /// Section for datasets already bound on lookup fields.
  static const String detectionProfileDatasets = 'Linked datasets';

  /// Field label for keywords that exclude this template.
  static const String detectionProfileNegative = 'Negative keywords';

  /// Hint on a comma-separated signal list.
  static const String detectionProfileHint = 'Separate with a comma';

  /// Shown when no field has a validation pattern to reuse.
  static const String detectionProfileNoPatterns =
      'Identifier patterns come from field validation. Add a pattern on a '
      'field first.';

  /// Shown when no lookup field names a dataset.
  static const String detectionProfileNoDatasets =
      'Linked datasets come from lookup fields. Bind a lookup first.';

  /// The template vanished before the profile was saved.
  static const String detectionProfileMissing =
      'That template is no longer on this device.';

  /// Recovery when the template is missing.
  static const String detectionProfileMissingRecovery =
      'Open the template list and try again.';

  /// Soft-deletes a template no record uses.
  static const String templatesDelete = 'Delete template';

  /// Title of the delete confirmation, naming the template.
  static String templatesDeleteTitle(String name) => 'Delete $name?';

  /// Body of the delete confirmation, naming field and record counts.
  static String templatesDeleteMessage({
    required int fields,
    required int records,
  }) {
    return 'This hides ${fieldsCount(fields)}. '
        '${recordsCount(records)} stay on this template.';
  }

  /// Field-list destination after create, duplicate or open. Task 094 owns it.
  static const String templateFieldsTitle = 'Fields';

  /// Primary action that opens the add-field flow. Task 095 owns the sheet.
  static const String templatesAddField = 'Add a field';

  /// Heading of one field row on the new-template page.
  static String templateFieldRowTitle(int n) => 'Field $n';

  /// Removes one field row from the new-template page.
  static const String templateFieldRowRemove = 'Remove this field';

  /// Opens the editor for one field. Task 095 owns the sheet.
  static const String templatesEditField = 'Edit field';

  /// Removes a field from the template and retires its values.
  static const String templatesDeleteField = 'Delete field';

  /// Title of the field-delete confirmation, naming the field.
  static String templatesDeleteFieldTitle(String label) => 'Delete $label?';

  /// Body of the field-delete confirmation, naming the value count.
  static String templatesDeleteFieldMessage({required int values}) {
    return Intl.plural(
      values,
      zero:
          'No records hold a value. The field leaves this template. '
          'Existing values stay and export as retired.',
      one: '1 record holds a value. That value stays and exports as retired.',
      other:
          '$values records hold a value. Those values stay and export as '
          'retired.',
    );
  }

  /// Headline when a template has no fields.
  static const String templatesFieldsEmptyHeadline = 'No fields yet';

  /// Body when the field list is empty. The next action is adding one.
  static const String templatesFieldsEmptyMessage =
      'Add a field so this template can capture.';

  /// REQUIRED badge on a field row.
  static const String fieldRequired = 'Required';

  /// Field filled by a calculation.
  static const String fieldCalculated = 'Calculated';

  /// Field the detection profile can fill from a photo.
  static const String fieldFromPhotos = 'From photos';

  /// Field-list subtitle: type, then any of required, calculated, from photos.
  static String fieldRowSubtitle({
    required String typeLabel,
    required bool requiredField,
    required bool calculated,
    required bool fromPhotos,
    bool pinnedContext = false,
    int? contextLevel,
    String? defaultValue,
  }) {
    final List<String> parts = <String>[typeLabel];
    if (requiredField) {
      parts.add(fieldRequired);
    }
    if (calculated) {
      parts.add(fieldCalculated);
    }
    if (fromPhotos) {
      parts.add(fieldFromPhotos);
    }
    if (contextLevel != null && contextLevel > 0) {
      parts.add('Context level $contextLevel');
    }
    if (pinnedContext) {
      parts.add('Pinned context');
    }
    final String shownDefault = defaultValue?.trim() ?? '';
    if (shownDefault.isNotEmpty) {
      parts.add(fieldRowDefault(shownDefault));
    }
    return parts.join(' · ');
  }

  /// The value a field takes when nothing fills it, on its field row.
  static String fieldRowDefault(String value) => 'Default: $value';

  /// RECOMMENDED badge on a field row.
  static const String fieldRecommended = 'Recommended';

  /// OPTIONAL badge on a field row.
  static const String fieldOptional = 'Optional';

  /// Moves [label] one place earlier in capture and export order.
  static String fieldMoveUp(String label) => 'Move $label up';

  /// Moves [label] one place later in capture and export order.
  static String fieldMoveDown(String label) => 'Move $label down';

  /// Drag handle that reorders [label].
  static String fieldReorder(String label) => 'Reorder $label';

  /// Operator-facing name of a §12.1 field type.
  static String fieldTypeLabel(String type) {
    return switch (type) {
      'text' => 'Text',
      'longText' => 'Long text',
      'number' => 'Number',
      'decimal' => 'Decimal',
      'currency' => 'Currency',
      'percentage' => 'Percentage',
      'date' => 'Date',
      'time' => 'Time',
      'dateTime' => 'Date and time',
      'boolean' => 'Boolean',
      'choice' => 'Choice',
      'multiChoice' => 'Multi-choice',
      'lookup' => 'Lookup',
      'barcode' => 'Barcode',
      'photoReference' => 'Photo reference',
      'documentReference' => 'Document reference',
      'gpsLocation' => 'GPS location',
      'signature' => 'Signature',
      'computed' => 'Computed',
      _ => type,
    };
  }

  /// Label of the field being added or edited. Template content follows.
  static const String fieldLabel = 'Label';

  /// Type picker on the add-field sheet.
  static const String fieldType = 'Type';

  /// Three-way requiredness question on the add-field sheet.
  static const String fieldRequiredness = 'Required?';

  /// Collapsed section that holds every §12.2 attribute the add flow defaults.
  static const String fieldAdvanced = 'Advanced';

  /// Reveals the collapsed Advanced section.
  static const String fieldAdvancedShow = 'Show advanced';

  /// Hides the Advanced section again.
  static const String fieldAdvancedHide = 'Hide advanced';

  /// Lets the user keep a two-fact label after the warning.
  static const String fieldKeepAnyway = 'Keep anyway';

  /// Warns that a label packs two facts (§13.1) without blocking the save.
  static const String fieldTwoFactsWarning =
      'This label packs two facts. Split it into two fields, or keep this '
      'one anyway.';

  /// Default written when the operator leaves the field empty.
  static const String fieldDefaultValue = 'Default value';

  /// Displayed and exported unit, for example kg.
  static const String fieldUnit = 'Unit';

  /// One short line of guidance shown under the field.
  static const String fieldHelp = 'Help';

  /// Who may write the field.
  static const String fieldInputMode = 'Who may fill it';

  /// [InputMode.any].
  static const String fieldInputAny = 'Anyone';

  /// [InputMode.manualOnly].
  static const String fieldInputManual = 'A person only';

  /// [InputMode.aiAllowed].
  static const String fieldInputAi = 'AI may propose';

  /// [InputMode.auto].
  static const String fieldInputAuto = 'Filled by the app';

  /// Whether the field may be pinned as context.
  static const String fieldStickable = 'Pin as context';

  /// Context hierarchy level, when this field is a level of that hierarchy.
  static const String fieldContextLevel = 'Context level';

  /// System fill source.
  static const String fieldAutoFill = 'Fill automatically';

  /// No automatic fill.
  static const String fieldAutoFillNone = 'Do not fill';

  /// Operator-facing name of an [AutoFill] source.
  static String fieldAutoFillLabel(String source) {
    return switch (source) {
      'now' => 'Now',
      'today' => 'Today',
      'time' => 'Time of day',
      'sequence' => 'Next in sequence',
      'operator' => 'Signed-in operator',
      'device' => 'This device',
      'gps' => 'Current location',
      'context' => 'Pinned context',
      _ => fieldAutoFillNone,
    };
  }

  /// Store an AI-refined companion beside the raw value.
  static const String fieldRefine = 'Store a refined companion';

  /// Whether the field participates in duplicate detection.
  static const String fieldIdentity = 'Use for duplicates';

  /// Expression that makes the field required.
  static const String fieldRequiredWhen = 'Required when';

  /// Plain-language reading of a required-when expression.
  static String fieldRequiredWhenPreview(String reading) {
    return 'Required when $reading';
  }

  /// Keeps the field out of capture and export; values stay.
  static const String fieldHidden = 'Hide from capture and export';

  /// Explains that hide is not a delete.
  static const String fieldHiddenHelp =
      'Values already captured stay on the record.';

  /// Validation editor heading.
  static const String fieldValidationTitle = 'Validation';

  /// Headline when no validation rule is set.
  static const String fieldValidationEmptyHeadline = 'No validation yet';

  /// Body when the validation editor is empty.
  static const String fieldValidationEmptyMessage =
      'Add a pattern, length, range or required-with rule.';

  /// Pattern picker.
  static const String fieldPattern = 'Pattern';

  /// No pattern.
  static const String fieldPatternNone = 'None';

  /// Ready-made serial pattern.
  static const String fieldPatternSerial = 'Serial';

  /// Ready-made asset-tag pattern.
  static const String fieldPatternAssetTag = 'Asset tag';

  /// Ready-made registration pattern.
  static const String fieldPatternRegistration = 'Registration';

  /// Custom regular expression.
  static const String fieldPatternCustom = 'Custom';

  /// Live box that tries the current validation against a sample.
  static const String fieldPatternTest = 'Try a value';

  /// Sample matches the rule.
  static const String fieldPatternTestPass = 'That value is allowed.';

  /// Minimum length.
  static const String fieldMinLength = 'Shortest';

  /// Maximum length.
  static const String fieldMaxLength = 'Longest';

  /// Inclusive lower bound.
  static const String fieldRangeMin = 'Lowest';

  /// Inclusive upper bound.
  static const String fieldRangeMax = 'Highest';

  /// Another field that must be filled with this one.
  static const String fieldRequiredWith = 'Required with';

  /// Choice-options editor heading.
  static const String fieldOptionsTitle = 'Choices';

  /// Headline when a choice field has no options.
  static const String fieldOptionsEmptyHeadline = 'No choices yet';

  /// Body when the options editor is empty.
  static const String fieldOptionsEmptyMessage =
      'Add a choice so capture has something to pick.';

  /// Label of a new choice.
  static const String fieldOptionLabel = 'Choice name';

  /// Adds a choice to the list.
  static const String fieldOptionAdd = 'Add a choice';

  /// Retires a choice without rewriting stored codes.
  static const String fieldOptionRetire = 'Retire choice';

  /// Badge on a retired choice.
  static const String fieldOptionRetired = 'Retired';

  /// Headline when the add sheet cannot find the template.
  static const String fieldAddEmptyHeadline = 'No template to edit';

  /// Body when the add sheet has no template.
  static const String fieldAddEmptyMessage =
      'Open the template list and pick a template first.';

  /// Title of the bulk requiredness screen.
  static const String requiredColumnsTitle = 'Required columns';

  /// Headline when the template has no fields to re-scope.
  static const String requiredColumnsEmptyHeadline = 'No columns to set';

  /// Body when the required-columns list is empty.
  static const String requiredColumnsEmptyMessage =
      'Add a field first, then choose what this project insists on.';

  /// Hide toggle on a required-columns row.
  static const String requiredColumnHide = 'Hide';

  /// Reveals an inherited §13.3 group.
  static const String requiredColumnShowGroup = 'Show group';

  /// Collapses an inherited §13.3 group.
  static const String requiredColumnHideGroup = 'Hide group';

  /// Heading for fields that do not sit in a named group.
  static const String requiredColumnUngrouped = 'Fields';

  /// Screen-reader name of the three-radio grid for [label].
  static String requiredColumnRadios(String label) => 'Required? · $label';

  /// One radio cell: field [label] and the requiredness [mark].
  static String requiredColumnCell(String label, String mark) {
    return '$label, $mark';
  }

  /// Reminder of the shipped requiredness after the user moves it.
  static String requiredColumnShipped(String mark) => 'Shipped as $mark';

  /// Operator-facing name of a field group.
  static String requiredColumnGroup(String group) {
    return shippedLabel('templates.groups.$group.$group');
  }

  /// Title of the identity-fields screen.
  static const String identityFieldsTitle = 'Identity fields';

  /// What changing the identity set does.
  static const String identityFieldsExplain =
      'These fields decide whether two records are the same thing.';

  /// Headline when the template has no fields to mark as identity.
  static const String identityFieldsEmptyHeadline = 'No fields to mark';

  /// Body when the identity list is empty.
  static const String identityFieldsEmptyMessage =
      'Add a field first, then choose which ones identify a record.';

  /// Title of the output-column mapping screen.
  static const String outputMappingTitle = 'Output columns';

  /// Headline when the template has no fields to map.
  static const String outputMappingEmptyHeadline = 'No columns to map';

  /// Body when the output-mapping list is empty.
  static const String outputMappingEmptyMessage =
      'Add a field first, then choose where each one writes.';

  /// Why two fields cannot share an output column.
  static const String outputMappingDuplicate =
      'Two fields cannot write to the same column.';

  /// What to do after a duplicate output column is refused.
  static const String outputMappingDuplicateRecovery =
      'Give each field its own column, then save.';

  /// Hint on a template built in the app, whose headers are generated.
  static const String outputMappingBuiltHint =
      'Headers are generated from the field labels. You can change them.';

  /// Hint on a template imported from a workbook.
  static const String outputMappingImportedHint =
      'These letters came from the workbook. You can change them.';

  /// Title of the template-migration screen.
  static const String templateMigrationTitle = 'Move records';

  /// What staying on a captured version means.
  static const String templateMigrationExplain =
      'Records stay on the version they were captured under until you move them.';

  /// Headline when every record is already on the current version.
  static const String templateMigrationEmptyHeadline = 'Nothing to move';

  /// Body when no record is behind the current template version.
  static const String templateMigrationEmptyMessage =
      'Every record is already on this template version.';

  /// Added-fields section on the migration screen.
  static const String templateMigrationAdded = 'Added fields';

  /// Removed-fields section on the migration screen.
  static const String templateMigrationRemoved = 'Removed fields';

  /// Retyped-fields section on the migration screen.
  static const String templateMigrationRetyped = 'Retyped fields';

  /// Confirm heading before records move.
  static const String templateMigrationConfirmTitle = 'Move these records?';

  /// Confirm body: one write, or nothing moves.
  static const String templateMigrationConfirm =
      'This writes every listed record to the new version in one step.';

  /// Primary action that starts the confirmed move.
  static const String templateMigrationAction = 'Move records';

  /// Suggested name when duplicating [name].
  static String templateCopyName(String name) => '$name (copy)';

  /// Field and record counts on one template list row.
  static String templateListSubtitle({
    required int fields,
    required int records,
  }) {
    return '${fieldsCount(fields)} · ${recordsCount(records)}';
  }

  /// Title of the shipped-library picker.
  static const String templatesLibraryTitle = 'Shipped templates';

  /// Headline when the packed library could not be listed.
  static const String templatesLibraryEmptyHeadline = 'No shipped templates';

  /// Body when the packed library is empty. Next action is a blank template.
  static const String templatesLibraryEmptyMessage =
      'Create a blank template to start capturing.';

  /// Copies the previewed library entry into the open project.
  static const String templatesAdd = 'Add to this project';

  /// Adds a shipped template that this project does not have yet.
  static const String templatesAddToProject = 'Add to project';

  /// Makes another editable copy of a template already on the project.
  static const String templatesCustomCopy = 'Create a custom copy';

  /// Visible association on a shipped template already copied in.
  static const String shippedAddedToProject = 'Added to this project';

  /// Search hint on the shipped template library, which ranks a name, a code
  /// or a plain description of the work.
  static const String shippedLibrarySearchHint = 'Search or describe your work';

  /// Heading of a catalogue area. [code] and [title] are catalogue data.
  static String shippedAreaTitle(String code, String title) => '$code · $title';

  /// Heading of a catalogue category. [code] and [title] are catalogue data.
  static String shippedCatalogueCategoryTitle(String code, String title) {
    return '$code — $title';
  }

  /// A collapsible catalogue category with how many templates it lists.
  static String shippedCategoryHeading(String code, String title, int count) {
    return '${shippedCatalogueCategoryTitle(code, title)} · $count';
  }

  /// Row subtitle of a catalogue template: its code, its record type and how
  /// many fields it holds. [code] and [recordType] are catalogue data.
  static String shippedCatalogueSubtitle(
    String code,
    String recordType,
    int fields,
  ) {
    return '$code · $recordType · ${fieldsCount(fields)}';
  }

  /// Title of the shipped library's filter sheet.
  static const String shippedFiltersTitle = 'Library filters';

  /// The area facet of the shipped library's filters.
  static const String shippedAreaFilter = 'Area';

  /// The record-type facet of the shipped library's filters.
  static const String shippedRecordTypeFilter = 'Record type';

  /// The tier facet of the shipped library's filters.
  static const String shippedTierFilter = 'Tier';

  /// Operator-facing name of a catalogue rollout tier.
  static String shippedTierLabel(String rollout) {
    return switch (rollout) {
      'p0' => 'Foundation',
      'p1' => 'Expansion',
      'p2' => 'Specialist',
      _ => rollout,
    };
  }

  /// Operator-facing name of a catalogue template's suggested privacy.
  static String shippedPrivacyLabel(String privacy) {
    return switch (privacy) {
      'internal' => 'Internal',
      'confidential' => 'Confidential',
      'restricted' => 'Restricted',
      _ => privacy,
    };
  }

  /// Preview row naming the catalogue category a template sits in.
  static const String shippedCategoryLabel = 'Category';

  /// Preview row naming a catalogue template's record type.
  static const String shippedRecordTypeLabel = 'Record type';

  /// Preview row giving a catalogue template's privacy and tier.
  static const String shippedPrivacyTierLabel = 'Suggested privacy and tier';

  /// A catalogue template's suggested privacy beside its tier.
  static String shippedPrivacyTier(String privacy, String rollout) {
    return '${shippedPrivacyLabel(privacy)} · ${shippedTierLabel(rollout)}';
  }

  /// Preview row: how evidence for the record type is captured.
  static const String shippedCaptureLabel = 'Capture';

  /// Preview row: what AI may do for the record type.
  static const String shippedAiAssistanceLabel = 'AI assistance';

  /// Preview row: what the record type produces.
  static const String shippedOutputsLabel = 'Outputs';

  /// Preview row: what a reviewer checks before approval.
  static const String shippedReviewLabel = 'Review';

  /// Preview subtitle of one field: its type and suggested requiredness.
  static String shippedFieldSubtitle(String type, String requiredness) {
    return '${fieldTypeLabel(type)} · $requiredness';
  }

  /// Empty result for the shipped library search.
  static String shippedLibraryNoMatch(String query) {
    final String shown = query.trim();
    if (shown.isEmpty) {
      return 'No templates match.';
    }
    return 'No templates match "$shown".';
  }

  /// What to change when the shipped library search matches nothing.
  static const String shippedLibraryNoMatchMessage = searchNoMatchMessage;

  /// Resolves a packed localisation key at render time (FE-L10N-07).
  static String shippedLabel(String key) {
    if (!key.startsWith('templates.') || !key.contains('.')) {
      return key;
    }
    final String last = key.split('.').last;
    final String stem = last.startsWith('item_')
        ? last.substring('item_'.length)
        : last;
    if (stem.isEmpty) {
      return last;
    }
    final List<String> words = stem.split('_');
    final StringBuffer buffer = StringBuffer(words.first);
    for (int index = 1; index < words.length; index++) {
      buffer.write(' ${words[index]}');
    }
    final String text = buffer.toString();
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  /// Unprocessed-queue destination the status line opens.
  static const String navQueue = 'Unprocessed';

  /// Export-history destination the project home opens.
  static const String navExports = 'Exports';

  /// Why the operator name is asked.
  static const String operatorNameUse =
      'Used on every record you capture from this device.';

  /// Label of the operator name field.
  static const String operatorName = 'Name';

  /// Settings screen for the local operator identity.
  static const String operatorProfileTitle = 'Operator';

  /// Initials field on the operator profile.
  static const String operatorInitials = 'Initials';

  /// Combined contact label when email and phone are shown as one value.
  static const String operatorContact = 'Contact';

  /// Optional email field on the operator profile.
  static const String operatorEmail = 'Email';

  /// Optional phone field on the operator profile.
  static const String operatorPhone = 'Phone';

  /// Name failed the non-empty rule.
  static const String nameRequired = 'Enter a name';

  /// A typed email is missing the @ that marks it as an address.
  static const String emailNeedsAt = 'Include an @ in the email';

  /// Initials failed the one-to-three-character rule.
  static const String initialsLength = 'Use one to three characters';

  /// Status line when no project is open.
  static const String statusNoProject = 'No project';

  /// Status line when no context is pinned.
  static const String statusNoContext = 'No context';

  /// Context hierarchy screen title.
  static const String contextHierarchyTitle = 'Project contexts';

  /// Empty hierarchy.
  static const String contextHierarchyEmptyHeadline = 'No context levels';

  /// Empty hierarchy body.
  static const String contextHierarchyEmptyMessage =
      'Add field keys from a template to build a hierarchy, or leave none.';

  /// Add a level.
  static const String contextAddLevel = 'Add level';

  /// One saved or proposed level and its stable field key.
  static String contextLevelRow(int level, String fieldKey) =>
      'Level $level · $fieldKey';

  /// Accepts all unambiguous template-declared levels.
  static const String contextUseTemplateLevels = 'Use template levels';

  /// Template loading failure on context setup.
  static const String contextTemplateFailureHeadline =
      'Template levels could not load';

  /// Recovery text after template-level loading fails.
  static const String contextTemplateFailureMessage =
      'Try again. Your saved context has not changed.';

  /// No project template exists yet.
  static const String contextNoTemplatesHeadline = 'No project templates';

  /// Explains how a project gains fields that can become levels.
  static const String contextNoTemplatesMessage =
      'Attach or create a template before choosing context fields.';

  /// Opens the contextual Templates route.
  static const String contextOpenTemplates = 'Add templates';

  /// Templates exist but do not declare a hierarchy.
  static const String contextNoDeclaredLevelsHeadline =
      'No template levels declared';

  /// Explains how to declare template levels.
  static const String contextNoDeclaredLevelsMessage =
      'Set a positive context level on template fields, or add levels manually.';

  /// Every available field is already part of the hierarchy.
  static const String contextNoEligibleFieldsHeadline = 'No fields available';

  /// Explains why the manual picker has no remaining fields.
  static const String contextNoEligibleFieldsMessage =
      'Every template field is already used as a context level.';

  /// Conflicting level metadata requires explicit correction.
  static const String contextTemplateConflictHeadline =
      'Template levels conflict';

  /// Names template declaration conflicts without guessing through them.
  static String contextTemplateConflictMessage(String conflicts) =>
      'Resolve these declarations in Templates: $conflicts.';

  /// Save hierarchy.
  static const String contextSaveHierarchy = 'Save levels';

  /// Context picker sheet title prefix.
  static String contextPickerTitle(String label) => 'Set $label';

  /// Recent values section.
  static const String contextRecents = 'Recent';

  /// Dataset search section.
  static const String contextDatasetSearch = 'From dataset';

  /// Free-text confirm.
  static const String contextUseValue = 'Use this value';

  /// Pin fields sheet.
  static const String contextPinnedTitle = 'Pinned fields';

  /// Pin empty.
  static const String contextPinnedEmptyHeadline = 'No pinnable context fields';

  /// Pin empty body.
  static const String contextPinnedEmptyMessage =
      'Mark fields as pinned context on a template to reuse them during capture.';

  /// Pin empty body when the project already has a template.
  static const String contextMarkPinnable = 'Mark a field as pinnable';

  /// Why pinned context is useful.
  static const String contextPinnedRelevance =
      'Pinned context is reused on each new record until you change it.';

  /// Cascade confirm title.
  static const String contextCascadeTitle = 'Clear lower levels?';

  /// Cascade confirm body in the specification's wording.
  ///
  /// [named] is each lower level and its current value. Level names and
  /// values are operator data, not catalogue keys (FE-L10N-07).
  static String contextCascadeMessage({
    required String levelLabel,
    required String newValue,
    required List<String> named,
  }) {
    return 'Change $levelLabel to $newValue? ${_and(named)} will be cleared.';
  }

  static String _and(List<String> named) {
    return switch (named.length) {
      0 => '',
      1 => named.single,
      2 => '${named[0]} and ${named[1]}',
      _ => '${named.sublist(0, named.length - 1).join(', ')} and ${named.last}',
    };
  }

  /// Cascade confirm action.
  static const String contextCascadeConfirm = 'Clear and continue';

  /// Preset list title.
  static const String contextPresetsTitle = 'Context presets';

  /// Preset empty.
  static const String contextPresetsEmptyHeadline = 'No presets yet';

  /// Preset empty body — next action is to apply a preset.
  static const String contextPresetsEmptyMessage =
      'Save the current context, then apply the preset in one tap.';

  /// Save preset.
  static const String contextPresetSave = 'Save preset';

  /// Apply preset.
  static const String contextPresetApply = 'Apply preset';

  /// Duplicate preset name.
  static const String contextPresetOverwriteTitle = 'Replace preset?';

  /// Duplicate preset body.
  static const String contextPresetOverwriteMessage =
      'A preset with that name already exists. Replace it?';

  /// Auto-clear undo.
  static const String contextAutoClearUndo = 'Undo';

  /// Auto-clear toast.
  static String contextAutoClearMessage(String label) =>
      'Cleared $label after idle.';

  /// Movement prompt title.
  static const String contextMovementTitle = 'Confirm context';

  /// Movement prompt body.
  static const String contextMovementMessage =
      'You have moved. Is the current context still correct?';

  /// Pin chip marker.
  static const String contextPinMarker = 'Pinned';

  /// A context level with no value on Capture's bar; [level] is data.
  static String contextSetLevel(String level) => 'Set $level';

  /// A context level and its value on Capture's bar; both are data.
  static String contextLevelValue(String level, String value) =>
      '$level: $value';

  /// Opens the project's context levels from Capture's bar.
  static const String contextManage = 'Manage';

  /// Opens the project's context levels when it has none yet.
  static const String contextSetUp = 'Set up context';

  /// Remove one hierarchy level.
  static const String contextRemoveLevel = 'Remove level';

  /// Idle auto-clear switch. Off until the operator turns it on.
  static const String settingsContextAutoClear =
      'Clear the lowest level when idle';

  /// Why auto-clear stays off.
  static const String settingsContextAutoClearEffect =
      'Off until you turn it on. Clears only the lowest level, and you can undo.';

  /// Idle interval row.
  static String settingsContextIdleSubtitle(int minutes) =>
      'After $minutes minutes with no change.';

  /// Movement confirmation switch. Off until the operator turns it on.
  static const String settingsContextMovement =
      'Confirm context after movement';

  /// Why the movement prompt stays off, and that it does not edit context.
  static const String settingsContextMovementEffect =
      'Off until you turn it on. Asks you to confirm. It does not change context. Needs GPS and location already allowed.';

  /// Distance row.
  static String settingsContextDistanceSubtitle(int metres) =>
      'After $metres metres.';

  /// Capture screen title.
  static const String captureTitle = 'Capture';

  /// Primary save that also enqueues analysis.
  static const String captureSaveAndAnalyse = 'Save and process';

  /// Why Save and process is off while the device is offline.
  static const String captureProcessNeedsNetwork =
      'Save raw now. Process it once this device is online.';

  /// Raw save with no processing.
  static const String captureSaveRaw = 'Save raw';

  /// Empty tray headline.
  static const String captureNoPhotosHeadline = 'No photos yet';

  /// Empty tray body — evidence is the only requirement.
  static const String captureNoPhotosMessage =
      'Add a photo, import a file, or type a caption to start.';

  /// Project selector on the capture surface.
  static const String captureProjectLabel = 'Project';

  /// Capture is open and projects exist, but none is selected.
  static const String captureChooseProject =
      'Choose a project to start capturing.';

  /// Capture is open and there is no project to file it under.
  static const String captureCreateProjectFirst =
      'Create a project before capturing.';

  /// A project is open, but it has no template to capture against.
  static const String captureNeedsTemplate = 'Add a template before capturing.';

  /// More fields expander.
  static const String captureMoreFields = 'More fields';

  /// Camera permission reason before the system prompt.
  static const String captureCameraReason =
      'Tapture needs the camera to photograph equipment and documents.';

  /// Open system settings after a permanent camera refusal.
  static const String captureOpenCameraSettings = 'Open settings';

  /// Keep a photo despite a quality warning.
  static const String captureKeepPhoto = 'Keep';

  /// Retake after a quality warning.
  static const String captureRetakePhoto = 'Retake';

  /// Document mode found no page boundary.
  static const String captureNoPageBoundary =
      'No page edge found. Captured as a normal photo.';

  /// Flash control semantic label.
  static const String captureFlash = 'Flash';

  /// Grid control semantic label.
  static const String captureGrid = 'Grid';

  /// Focus indicator semantic label.
  static const String captureFocus = 'Focus';

  /// Zoom control semantic label.
  static const String captureZoom = 'Zoom';

  /// Shutter semantic label.
  static const String captureShutter = 'Shutter';

  /// Gallery import action.
  static const String captureImportGallery = 'Import photos';

  /// Document import action.
  static const String captureImportDocument = 'Import document';

  /// Rejected import names the reason.
  static String captureImportRejected(String reason) => reason;

  /// Try another file recovery.
  static const String tryAnotherFile = 'Try another file';

  /// PDF bytes were not a valid document.
  static const String pdfInvalid = 'That PDF could not be read.';

  /// Requested page is outside the document.
  static const String pdfPageMissing = 'That page is not in the document.';

  /// Barcode scanner unavailable on this build.
  static const String barcodeUnavailable =
      'Barcode scanning is not available on this device.';

  /// Confirm a decoded barcode.
  static const String barcodeConfirm = 'Use this code';

  /// Scan again after a decode.
  static const String barcodeRescan = 'Scan again';

  /// No code in the region yet.
  static const String barcodeNoCode = 'Point at a barcode';

  /// Unreadable code.
  static const String barcodeUnreadable = 'That code could not be read.';

  /// Continuous mode running count.
  static String barcodeScanCount(int n) => 'Scanned $n';

  /// Undo last continuous scan.
  static const String barcodeUndoLast = 'Undo last';

  /// Identifier matched a project record.
  static const String identifierMatchRecord = 'Open record';

  /// Identifier matched a reference row.
  static const String identifierMatchReference = 'Use reference';

  /// Identifier matched nothing — start a new record.
  static const String identifierNewRecord = 'New record';

  /// Several records share the identifier.
  static const String identifierDuplicates = 'Several matches';

  /// Record caption field label.
  static const String captureRecordCaption = 'Caption';

  /// Photo group on the capture surface.
  static const String capturePhotosSection = 'Photos';

  /// Audio group on the capture surface.
  static const String captureAudioSection = 'Audio';

  /// Removes one draft photo from the capture tray.
  static const String captureRemovePhoto = 'Remove photo';

  /// Adds the typed caption to every photo, when none is ticked.
  static String captionAddToAll(int n) =>
      Intl.plural(n, one: 'Add to the photo', other: 'Add to all $n photos');

  /// Adds the typed caption to the ticked photos only.
  static String captionAddToTicked(int n) => Intl.plural(
    n,
    one: 'Add to 1 ticked photo',
    other: 'Add to $n ticked photos',
  );

  /// Says how many photos a caption was just added to.
  static String captionAdded(int n) =>
      Intl.plural(n, one: 'Added to the photo', other: 'Added to $n photos');

  /// Append caption mode.
  static const String captionAppend = 'Append';

  /// Replace caption mode.
  static const String captionReplace = 'Replace';

  /// Microphone permission reason.
  static const String captureMicReason =
      'Tapture needs the microphone for spoken notes on an explicit tap.';

  /// Voice input listening state.
  static const String captureListening = 'Listening…';

  /// Audio recorder start.
  static const String captureRecordAudio = 'Record audio';

  /// Audio recorder pause.
  static const String capturePauseAudio = 'Pause';

  /// Audio recorder stop.
  static const String captureStopAudio = 'Stop';

  /// Audio recorder unavailable.
  static const String audioRecorderUnavailable =
      'Audio recording is not available on this device.';

  /// The recorder refused to start a take.
  static const String audioStartFailed = 'Recording could not start.';

  /// Recovery for [audioStartFailed].
  static const String audioStartFailedRecovery =
      'Try again. Nothing already captured was lost.';

  /// A recording path that would leave the storage folder.
  static const String audioPathOutsideStorage =
      'The recording must be saved inside the project folder.';

  /// Microphone permission failure and recovery.
  static const String audioPermissionDenied =
      'Microphone permission was not granted.';

  /// Tells the operator how to grant microphone access.
  static const String audioPermissionRecovery =
      'Allow microphone access in system settings, then try again.';

  /// Recorder phase and elapsed time.
  static String audioRecorderStatus(String phase, int seconds) {
    final String label = switch (phase) {
      'permission' => 'Requesting microphone permission',
      'recording' => 'Recording',
      'paused' => 'Paused',
      'finalizing' => 'Saving audio',
      'failed' => 'Audio failed',
      'completed' => 'Audio saved',
      _ => 'Audio ready',
    };
    return '$label · ${seconds}s';
  }

  /// Audio evidence association sheet.
  static const String captureAudioScopeTitle = 'Use audio with';

  /// Associates the clip with the most recent/current photo.
  static const String captureAudioCurrentPhoto = 'Current photo';

  /// Associates the clip with the selected photos.
  static String captureAudioSelectedPhotos(int count) =>
      'Selected photos ($count)';

  /// Associates the clip with every photo.
  static String captureAudioAllPhotos(int count) => 'All photos ($count)';

  /// Number of durable clips in this capture.
  static String captureAudioCount(int count) => Intl.plural(
    count,
    one: '1 audio clip attached',
    other: '$count audio clips attached',
  );

  /// Delete photo confirm title.
  static const String captureDeletePhotoTitle = 'Delete this photo?';

  /// Delete photo confirm body.
  static const String captureDeletePhotoMessage =
      'It leaves the tray now. The file stays until the retention purge so '
      'you can undo.';

  /// Undo delete snack.
  static const String captureUndoDelete = 'Undo';

  /// Photo deleted snack.
  static const String capturePhotoDeleted = 'Photo deleted';

  /// Move photos action.
  static const String captureMovePhotos = 'Move';

  /// Recovery prompt title.
  static const String captureRecoveryTitle = 'Resume capture?';

  /// Recovery prompt with photo count.
  static String captureRecoveryMessage(int photos) {
    return Intl.plural(
      photos,
      zero: 'An interrupted session has no photos yet.',
      one: 'An interrupted session has 1 photo.',
      other: 'An interrupted session has $photos photos.',
    );
  }

  /// Resume interrupted session.
  static const String captureResume = 'Resume';

  /// Discard interrupted session.
  static const String captureDiscard = 'Discard';

  /// Discard confirm title.
  static const String captureDiscardTitle = 'Discard session?';

  /// Discard confirm body.
  static const String captureDiscardMessage =
      'Photos are tombstoned and stay recoverable until the retention purge.';

  /// Rapid mode title.
  static const String captureRapidMode = 'Rapid mode';

  /// Storage warning dismiss.
  static const String captureStorageDismiss = 'Dismiss';

  /// Storage stop offers export.
  static const String captureStorageExport = 'Export';

  /// Template picker title.
  static const String capturePickTemplate = 'Template';

  /// Pin template for this session.
  static const String capturePinSession = 'Pin for session';

  /// Pin template for this context level.
  static const String capturePinContext = 'Pin for context';

  /// Multi-select count.
  static String captureSelectedCount(int n) => 'Selected $n';

  /// Select all photos.
  static const String captureSelectAll = 'Select all';

  /// Clear photo selection.
  static const String captureClearSelection = 'Clear';

  /// Add photo to tray.
  static const String captureAddPhoto = 'Add photo';

  /// Sheet title for adding a photo.
  static const String captureAddSheetTitle = 'Add a photo';

  /// Camera action on the add-photo sheet.
  static const String captureTakePhoto = 'Take a photo';

  /// Library action on the add-photo sheet.
  static const String captureChoosePhoto = 'Choose from this device';

  /// Quality blur advisory.
  static const String captureQualityBlur = 'This photo looks blurry.';

  /// Quality dark advisory.
  static const String captureQualityDark = 'This photo looks dark.';

  /// Quality overexposed advisory.
  static const String captureQualityBright = 'This photo looks overexposed.';

  /// Quality small-text advisory.
  static const String captureQualitySmallText =
      'Small text may be hard to read.';

  /// Saved announcement for screen readers.
  static const String captureSaved = 'Saved';

  /// Saving announcement.
  static const String captureSaving = 'Saving';

  /// Save failed announcement.
  static const String captureSaveFailed = 'Save failed';

  /// Raw evidence committed, but the local processing job did not enqueue.
  static const String captureEnqueueFailed =
      'The capture was saved, but processing could not be queued.';

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

  /// Opens the recycle bin.
  static const String openRecycleBin = 'Recycle bin';

  /// Settings root title.
  static const String settingsTitle = 'Settings';

  /// Settings index group headings.
  static const String settingsGroupProfileCapture = 'Profile and capture';

  /// Settings for AI and visual appearance.
  static const String settingsGroupIntelligenceAppearance =
      'Intelligence and appearance';

  /// Settings for durable storage and access protection.
  static const String settingsGroupStorageSecurity = 'Storage and security';

  /// Product information settings group.
  static const String settingsGroupAbout = 'About';

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

  /// Appearance section title.
  static const String settingsAppearanceTitle = 'Appearance';

  /// Appearance tile supporting line.
  static const String settingsAppearanceSubtitle =
      'System, light, dark or outdoor.';

  /// Follow the device light or dark setting.
  static const String themeModeSystem = 'System';

  /// Always the light palette.
  static const String themeModeLight = 'Light';

  /// Always the dark palette.
  static const String themeModeDark = 'Dark';

  /// High-contrast outdoor palettes; still follows the device.
  static const String themeModeOutdoor = 'Outdoor';

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
  static const String settingsAboutSubtitle = 'Version and licences.';

  /// Templates row under Settings.
  static const String settingsTemplatesSubtitle =
      'Create, import and edit this project\'s templates.';

  /// Unprocessed row under Settings.
  static const String settingsQueueSubtitle =
      'Records waiting to be processed.';

  /// Camera default row.
  static const String settingsCamera = 'Camera';

  /// Effect of the camera default.
  static const String settingsCameraEffect =
      'Used at the start of the next session.';

  /// Label for the photo camera default.
  static const String settingsCameraPhoto = 'Photo';

  /// Document camera default.
  static const String settingsCameraDocument = 'Document';

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

  /// Sheet title when editing the naming pattern.
  static const String settingsNamingEdit = 'File name pattern';

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

  /// Storage-root row name.
  static const String settingsStorageRoot = 'Storage folder';

  /// Total volume label.
  static const String settingsVolumeTotal = 'Total';

  /// Used volume label.
  static const String settingsVolumeUsed = 'Used';

  /// Available volume label.
  static const String settingsVolumeAvailable = 'Available';

  /// The three volume figures on one line.
  static String settingsVolumeFigures({
    required String total,
    required String used,
    required String available,
  }) {
    return '$settingsVolumeTotal $total · $settingsVolumeUsed $used · '
        '$settingsVolumeAvailable $available';
  }

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
    if (bytes < k * k * k) {
      return '${(bytes / (k * k)).round()} MB';
    }
    return '${(bytes / (k * k * k)).round()} GB';
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
  static const String feedbackAddScreen = 'Screenshot current screen';

  /// Opt-in so Screenshot current screen includes the Give us feedback chrome.
  static const String feedbackIncludeUi = 'Include the feedback UI';

  /// Opens the browser display picker for another window or OS surface.
  static const String feedbackAddWindow = 'Screenshot external window';

  /// Stops the shared window so later taps open the picker again.
  static const String feedbackStopSharing = 'Stop sharing window';

  /// Non-colour signal that Screenshot external window is live.
  static const String feedbackSharingWindow =
      'Sharing a window. Each tap adds a screenshot.';

  /// Label of a still taken from another window.
  static const String feedbackOtherWindow = 'External window';

  /// Opens the device camera for a photo to attach.
  static const String feedbackTakePhoto = 'Take a photo';

  /// Opens the device library for photos to attach.
  static const String feedbackChoosePhoto = 'Choose photos';

  /// How to capture another Tapture screen when other windows cannot be
  /// shared.
  static const String feedbackShotTipScreens =
      'Another screen: tap Continue later, open it, then tap Screenshot '
      'current screen in the bar.';

  /// How to attach a system screenshot of another app.
  static const String feedbackShotTipApps =
      'Another app: take a screenshot with your device, then add it '
      'with Choose photos.';

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

  /// Title of the discard-draft confirm.
  static const String feedbackDiscardDraftTitle = 'Discard this feedback?';

  /// Body of the discard-draft confirm, naming the image count (FE-SIMP-07).
  static String feedbackDiscardDraftMessage(int images) {
    return Intl.plural(
      images,
      zero: 'This feedback will be cleared.',
      one: 'This feedback and its 1 image will be cleared.',
      other: 'This feedback and its $images images will be cleared.',
    );
  }

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

  /// Shared Downloads subfolder on Android and desktop. The › mirrors with
  /// the surrounding line in right-to-left layouts (FE-L10N-05).
  static const String downloadsTaptureFolder = 'Downloads › Tapture';

  /// Where archives land, before anything is downloaded.
  static String feedbackDownloadsGoTo(String place) => 'Downloads go to $place';

  /// Opens the system Downloads view or the Tapture folder.
  static const String feedbackOpenFolder = 'Open folder';

  /// Opens the system picker so the archive can be saved anywhere.
  static const String feedbackSaveToFolder = 'Save to a folder';

  /// Warning when [place] could not be opened.
  static String feedbackOpenFolderFailed(String place) =>
      'The folder could not be opened. Look in $place.';

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

  /// One entry's title on a list row: number, Feedback ID and message.
  static String feedbackEntryTitle(
    String number,
    String reference,
    String message,
  ) {
    return '$number. $reference · $message';
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

  /// Queue screen title.
  static const String queueTitle = 'Process';

  /// Unprocessed count label.
  static const String queueUnprocessed = 'Unprocessed';

  /// Queued count label.
  static const String queueQueued = 'Queued';

  /// Failed count label.
  static const String queueFailed = 'Failed';

  /// Today's online request and image totals against the project cap.
  static String queueUsage(int requests, int images, int cap) {
    return '$requests of $cap online requests today, $images images sent';
  }

  /// Unprocessed records, as a complete message.
  static String queueUnprocessedCount(int count) => Intl.plural(
    count,
    zero: 'No unprocessed records',
    one: '1 unprocessed record',
    other: '$count unprocessed records',
  );

  /// Records waiting in the queue, as a complete message.
  static String queueQueuedCount(int count) => Intl.plural(
    count,
    zero: 'No records queued',
    one: '1 record queued',
    other: '$count records queued',
  );

  /// Failed jobs, as a complete message.
  static String queueFailedCount(int count) => Intl.plural(
    count,
    zero: 'No failed jobs',
    one: '1 failed job',
    other: '$count failed jobs',
  );

  /// Context groups in the queue.
  static const String queueGroupsTitle = 'By context';

  /// Process every waiting record.
  static const String queueProcessAll = 'Process all';

  /// Process the records in one group.
  static const String queueProcessSelected = 'Process selected';

  /// Empty queue title.
  static const String queueEmptyHeadline = 'Nothing waiting';

  /// Empty queue explanation.
  static const String queueEmptyMessage =
      'Captured records appear here when they are ready to process.';

  /// Failures list title.
  static const String queueFailedTitle = 'Failed jobs';

  /// Empty failures title.
  static const String queueFailedEmptyHeadline = 'No failed jobs';

  /// Empty failures explanation.
  static const String queueFailedEmptyMessage =
      'Jobs that stop are listed here with the reason.';

  /// Retry one failed job.
  static const String queueRetry = 'Retry';

  /// Stop the batch that is running.
  static const String queueCancel = 'Cancel';

  /// End-of-run summary.
  static String queueSummary(int succeeded, int failed) {
    return '$succeeded succeeded, $failed failed';
  }

  /// Asks before the first online call of a session.
  static const String egressTitle = 'Send for analysis?';

  /// Confirms the preview.
  static const String egressSend = 'Send';

  /// Declines the preview and stays offline.
  static const String egressDecline = 'Stay offline';

  /// Nothing would leave the device.
  static const String egressEmptyHeadline = 'Nothing to send';

  /// Why the preview is empty.
  static const String egressEmptyMessage =
      'This record has no images that would leave the device.';

  /// What the preview says will be included.
  static String egressBody({required int images, required String size}) {
    return '$images compressed images, about $size. Captions, field names, '
        'on-device text, context and predefined row labels are included.';
  }

  /// Device-held key screen title.
  static const String apiKeyTitle = 'Provider key';

  /// States that device custody is the exception.
  static const String apiKeyCustody =
      'This key lives on this device only. The usual arrangement is for '
      "the organisation's backend to hold it.";

  /// Key field label.
  static const String apiKeyLabel = 'Provider key';

  /// Saves the key into secure storage.
  static const String apiKeySave = 'Save key';

  /// Removes the key and clears the selection.
  static const String apiKeyRemove = 'Remove key';

  /// Runs the smallest connection test.
  static const String apiKeyTest = 'Test connection';

  /// Shown once the key is stored and hidden.
  static const String apiKeySaved = 'Saved on this device';

  /// Test connection succeeded.
  static const String apiKeySuccess = 'Connection succeeded.';

  /// The key was rejected.
  static const String apiKeyAuthFailed = 'The key was rejected.';

  /// The test could not reach the network.
  static const String apiKeyNetworkFailed = 'The network is not available.';

  /// The provider answered the test with an error of its own.
  static const String apiKeyTestFailed =
      'The provider answered with an error. Try again later.';

  /// Registry-driven AI controls.
  static const String aiOperation = 'Operation';

  /// Provider choice field.
  static const String aiProvider = 'Provider';

  /// Model choice field.
  static const String aiModel = 'Model';

  /// Operator-facing label for an AI operation id.
  static String aiOperationLabel(String value) {
    return switch (value) {
      'readText' => 'Read text',
      'extractFields' => 'Extract fields',
      'refineText' => 'Refine text',
      'transcribe' => 'Transcribe audio',
      _ => value,
    };
  }

  /// Credential custody and live availability explanation.
  static String aiCustody(String custody, bool available) {
    final String owner = custody == 'backend'
        ? 'The organisation backend holds the provider key.'
        : 'This provider uses a device-held credential when enabled by an administrator.';
    return available ? owner : '$owner This provider is currently unavailable.';
  }

  /// Saved choice fallback explanation.
  static const String aiSelectionFallback =
      'The saved choice is unavailable. The organisation backend is selected for now.';

  /// Provider test could not run because the descriptor is unavailable.
  static const String aiProviderUnavailable =
      'This provider is not available. Processing will remain queued.';

  /// Provider and model do not support the selected operation.
  static const String aiSelectionInvalid =
      'Choose a provider and model that support this operation.';

  /// Template question.
  static const String templateChoiceTitle = 'What is this?';

  /// Pins the choice to the current place.
  static const String templateChoicePin =
      'Use this template for the rest of this location';

  /// No templates to offer.
  static const String templateChoiceEmptyHeadline = 'No templates';

  /// Why the choice sheet is empty.
  static const String templateChoiceEmptyMessage =
      'Add a template before choosing one.';

  /// The third choice when the shortlist is not enough.
  static const String templateChoiceOther = 'Something else';

  /// The step detail when no template was chosen. The record stays queued.
  static const String templateChoiceSkipped =
      'No template chosen. The record stays in the queue.';

  /// The chosen template could not be applied to the record.
  static const String templateChoiceApplyFailed =
      'That template could not be applied.';

  /// What to do when the chosen template could not be applied.
  static const String templateChoiceApplyRecovery =
      'Process the record again and choose once more.';

  /// A record an unattended run set aside for an operator's template
  /// choice.
  static const String templateChoiceWaiting =
      'Waiting for someone to choose its template.';

  /// A record read on the device, its online work left for later.
  static const String processReadOnDevice = 'Read on this device';

  /// Preparing images.
  static const String processPreparing = 'Preparing images';

  /// On-device reading.
  static const String processReading = 'Reading text on device';

  /// Template detection.
  static const String processDetecting = 'Identifying template';

  /// Online extraction.
  static const String processExtracting = 'Extracting fields';

  /// Validation.
  static const String processChecking = 'Checking values';

  /// Local notification title. Counts only.
  static const String processingNotificationTitle = 'Processing finished';

  /// Local notification body. Counts only.
  static String processingNotificationBody(int succeeded, int failed) {
    return '$succeeded succeeded, $failed failed';
  }

  // Documents picked from the device (task 076).

  /// A document the picker could not hand over.
  static const String documentPickFailed = 'That file could not be opened.';

  /// A chosen file above what this device can open in one piece.
  static String documentTooLarge(int bytes, int ceiling) {
    return 'That file is ${fileSize(bytes)}; this device opens files up to '
        '${fileSize(ceiling)}.';
  }

  /// What to do about a file that is too large.
  static const String documentTooLargeRecovery =
      'Open it in the Tapture app on a phone or computer instead.';

  /// A stored export that is no longer where the app wrote it.
  static const String storedFileMissing =
      'That export is no longer on this device.';

  // Project packages (task 076).

  /// A package whose project is gone.
  static const String packageProjectMissing =
      'That project is no longer on this device.';

  /// A package larger than this device writes or opens.
  static String packageTooLarge(int bytes, int ceiling) {
    return 'This project package would be ${fileSize(bytes)}; this device '
        'handles packages up to ${fileSize(ceiling)}.';
  }

  /// What to do about a package that is too large.
  static const String packageTooLargeRecovery =
      'Export from the Tapture app on a phone or computer, which handles '
      'larger packages.';

  /// A package that could not be written.
  static const String packageWriteFailed =
      'The project package could not be written.';

  /// Why a package was refused; [check] is the failed check's name.
  static String packageRejected(String check) {
    return switch (check) {
      'tooLarge' => 'This package is larger than this device can open.',
      'notAPackage' => 'This file is not a Tapture project package.',
      'unsafePath' =>
        'This package holds a file that would land outside its project.',
      'missingEntry' => 'This package is missing a file it lists.',
      'unreadable' => 'Part of this package could not be read.',
      'unknownFormatVersion' =>
        'This package was made by a newer version of Tapture.',
      'checksumMismatch' =>
        'This package was changed after it was made: a file does not match '
            'its checksum.',
      _ => 'This package could not be opened.',
    };
  }

  /// What to do about a refused package.
  static const String packageRejectedRecovery =
      'Nothing was imported. Export the project again on the other device, '
      'or update Tapture for a newer package.';

  // Capture's guide (task 076).

  /// The row under the Template select that opens the guide.
  static const String captureGuideTitle = 'What to capture';

  /// What the photos should show; the template's fields follow.
  static const String captureGuidePhotos = 'Photos should show';

  /// What to say or type in the caption; the template's fields follow.
  static const String captureGuideCaption = 'Say or type in the caption';

  /// A guide list's field labels, which are template data.
  static String captureGuideItems(List<String> labels) => labels.join(' · ');

  /// Closes the caption panel of the guide.
  static const String captureGuideClose = 'Hide the caption guide';

  // Importing and merging project packages (task 076, W19 to W22).

  /// Shown while a chosen package is opened and checked.
  static const String importChecking = 'Checking the package…';

  /// Title of the sheet that describes a package before it is imported.
  static const String importSheetTitle = 'Import a project';

  /// Where and when the package was made. [device] is package data.
  static String importFrom(String device, DateTime exportedAt) {
    final String when = DateFormat.yMMMd().add_jm().format(
      exportedAt.toLocal(),
    );
    return 'Exported $when on ${device.isEmpty ? 'another device' : device}';
  }

  /// What the package holds.
  static String importHolds(int records, int photos, int bytes) {
    return '${recordsCount(records)} · ${photosCount(photos)} · '
        '${fileSize(bytes)}';
  }

  /// How many photos a package or a count covers.
  static String photosCount(int n) {
    return Intl.plural(
      n,
      zero: 'No photos',
      one: '1 photo',
      other: '$n photos',
    );
  }

  /// Primary action of the import sheet.
  static const String importAsNewProject = 'Import as a new project';

  /// Secondary action of the import sheet: merge into a project here.
  static const String importMergeInto = 'Merge into a project…';

  /// Shown while a package's files are copied in.
  static const String importCopying = 'Importing the project…';

  /// Announced once the project is in.
  static String importDone(int records) =>
      'Project imported: ${recordsCount(records)}';

  /// A package whose project was deleted on this device is refused.
  static const String importProjectDeletedHere =
      'This project was deleted on this device. A merge never brings back '
      'what was deleted.';

  /// Recovery for [importProjectDeletedHere].
  static const String importProjectDeletedHereRecovery =
      'Restore the project from the recycle bin, or import on another device.';

  /// A package whose project is already here does not import a second copy.
  static const String importProjectAlreadyHere =
      'This project is already on this device.';

  /// Recovery for [importProjectAlreadyHere].
  static const String importProjectAlreadyHereRecovery =
      'Merge the package into it instead.';

  /// Too little room for the package's files.
  static const String importNoRoom =
      'There is not enough free space on this device for this package.';

  /// Recovery for [importNoRoom].
  static const String importNoRoomRecovery =
      'Free some space, then import again.';

  /// A file in the package did not arrive as it left.
  static const String importFileChanged =
      'A file in this package did not copy correctly.';

  /// Recovery for any import or merge that stopped part way.
  static const String importFailedRecovery =
      'Nothing was changed. Try again, or export the package again.';

  /// Project home overflow item and the merge screen's title.
  static const String mergePackage = 'Merge a package';

  /// Title of the sheet that chooses which project a package merges into.
  static const String mergeTargetTitle = 'Merge into which project?';

  /// No local project can take the package.
  static const String mergeTargetNone =
      'No project on this device uses the templates this package needs.';

  /// A compatibility status, as its pill reads.
  static String compatibilityStatus(String status) {
    return switch (status) {
      'compatible' => 'Compatible',
      'compatibleWithDifferences' => 'Compatible, with differences',
      _ => 'Not compatible',
    };
  }

  /// One named compatibility finding. [field] is template data.
  static String compatibilityIssue(String issue, String field) {
    return switch (issue) {
      'noMatch' => 'No matching template here',
      'missingField' => '$field holds values but is not in the template here',
      'typeCannotHold' => '$field here cannot hold the incoming values',
      'otherVersion' => 'Another version of the template',
      'localOnlyFields' => 'Only here: $field',
      'changedRequiredness' => '$field is required on one side only',
      'changedLabel' => '$field has another label here',
      'changedOptions' => '$field offers other choices here',
      'changedType' => '$field has another type here',
      _ => '$field is not in the template here, and holds no values',
    };
  }

  /// A template's line in the compatibility report. [name] is template data.
  static String compatibilityTemplate(String name, String status) =>
      '$name: ${compatibilityStatus(status)}';

  /// The merge preview's count headings (specification §48.1).
  static String mergeCount(String count, int n) {
    final String label = switch (count) {
      'newRecords' => 'New records',
      'updatedRecords' => 'Records this merge changes',
      'newPhotos' => 'New photos',
      'photosHere' => 'Photos already on this device',
      'deletions' => 'Deletions to apply',
      'conflicts' => 'Conflicts to settle',
      'duplicates' => 'Possible duplicates',
      'kept' => 'Values kept as on this device',
      _ => 'Already in another project here',
    };
    return '$label: $n';
  }

  /// Primary merge action while conflicts remain.
  static String mergeSettleConflicts(int n) {
    return Intl.plural(
      n,
      one: 'Settle 1 conflict',
      other: 'Settle $n conflicts',
    );
  }

  /// Primary merge action once every conflict is settled.
  static const String mergeApply = 'Merge';

  /// Shown while a merge is written.
  static const String mergeApplying = 'Merging…';

  /// Announced once a merge is written.
  static const String mergeDone = 'Merged';

  /// A second merge of the same package.
  static const String mergeNothing =
      'Nothing to merge: this project already holds everything in the package.';

  /// Switch on the merge preview that runs the duplicate check.
  static const String mergeCheckDuplicates = 'Check for possible duplicates';

  /// Helper under [mergeCheckDuplicates].
  static const String mergeCheckDuplicatesHelper =
      'Lists incoming records that look like ones already here. You decide '
      'for each.';

  /// Shown while the duplicate check runs.
  static const String mergeCheckingDuplicates = 'Looking for duplicates…';

  /// Title of the conflict screen, as "Conflict 3 of 7".
  static String conflictProgress(int index, int total) =>
      'Conflict $index of $total';

  /// What a conflict is about. [field] is template data.
  static String conflictKind(String kind, String field) {
    return switch (kind) {
      'value' => field,
      'caption' => 'Caption',
      'status' => 'Status',
      'deletedThere' => 'Deleted on the other device',
      _ => 'Deleted on this device',
    };
  }

  /// Explains a deletion conflict.
  static String conflictDeletion(String kind) {
    return kind == 'deletedThere'
        ? 'The other device deleted this, but it was changed here since.'
        : 'This device deleted this, but the other device changed it since.';
  }

  /// Heading of this device's side of a conflict.
  static const String conflictThisDevice = 'This device';

  /// Heading of the incoming side of a conflict.
  static const String conflictIncoming = 'Incoming';

  /// Who last wrote a side, and when. [device] is data.
  static String conflictWrittenBy(String device, DateTime? at) {
    final String when = at == null
        ? ''
        : ' · ${DateFormat.yMMMd().add_jm().format(at.toLocal())}';
    return '${device.isEmpty ? 'Unknown device' : device}$when';
  }

  /// A side of a deletion conflict.
  static const String conflictDeleted = 'Deleted';

  /// An empty value on one side.
  static const String conflictEmpty = 'Empty';

  /// Keeps this device's side of one conflict.
  static const String conflictKeepMine = "Keep this device's";

  /// Takes the incoming side of one conflict.
  static const String conflictTakeIncoming = 'Take incoming';

  /// Second control: keep this device's side of every remaining conflict.
  static String mergeKeepAllMine(int n) => "Keep this device's for all $n";

  /// Second control: take the incoming side of every remaining conflict.
  static String mergeTakeAllIncoming(int n) => 'Take incoming for all $n';

  /// Confirms a bulk choice with its count.
  static String mergeBulkConfirm(int n, {required bool incoming}) {
    final String side = incoming ? 'the incoming value' : "this device's value";
    return Intl.plural(
      n,
      one: 'Use $side for 1 conflict?',
      other: 'Use $side for all $n conflicts?',
    );
  }

  /// Title of the possible-duplicate view.
  static const String duplicateTitle = 'Possible duplicate';

  /// Why a pair was listed.
  static String duplicateSignal(String signal) {
    return switch (signal) {
      'identity' => 'Same identity fields',
      'photo' => 'Same photo',
      'samePhoto' => 'Identical photo',
      'nearPhoto' => 'Nearly the same photo',
      'predefinedRow' => 'Same checklist row',
      'nameContextTime' => 'Same name, place and time',
      _ => 'Same place, close in time, similar caption',
    };
  }

  /// Keeps both records: the default.
  static const String duplicateKeepBoth = 'Keep both';

  /// Leaves the incoming record out of the merge.
  static const String duplicateSkipIncoming = "Don't import this record";

  /// Marks a pair whose incoming record is left out.
  static const String duplicateSkipped = 'Not imported';

  /// Heading of the incoming side of a pair.
  static const String duplicateIncoming = 'Incoming record';

  /// Heading of the local side of a pair.
  static const String duplicateHere = 'On this device';

  // The merge preview and its conflicts (task 076, W20 to W22).

  /// Empty state when the merge screen opens with no package.
  static const String mergeNoPackageHeadline = 'No package open';

  /// Explains [mergeNoPackageHeadline].
  static const String mergeNoPackageMessage =
      'Choose Merge a package from the project menu to pick one.';

  /// Heading over the compatibility report.
  static const String mergeTemplatesHeading = 'Templates';

  /// Heading over the preview's counts.
  static const String mergeCountsHeading = 'What the merge does';

  /// Shown when a template blocks the merge.
  static const String mergeBlocked =
      'This package cannot merge into this project until its templates match.';

  /// A record with no caption, in the preview's lists.
  static String mergeRecordUnnamed(String id) {
    final String short = id.length > 8 ? id.substring(id.length - 8) : id;
    return 'Record …$short';
  }

  /// A conflict's line in the preview: the record, then what differs.
  static String mergeConflictLine(String record, String about) =>
      '$record · $about';

  /// A settled conflict's side, under its line.
  static String mergeConflictChosen({required bool incoming}) =>
      incoming ? 'Taking incoming' : "Keeping this device's";

  /// A conflict not settled yet.
  static const String mergeConflictOpen = 'Not settled yet';

  /// The project details that differ in the package, kept as on this device.
  static String mergeProjectKept(List<String> columns) {
    final List<String> labels = <String>[
      for (final String column in columns)
        switch (column) {
          'name' => projectName,
          'client' => projectOrganisation,
          'status' => projectStatus,
          'started_at' => projectStartsOn,
          'completed_at' => projectEndsOn,
          _ => projectSettingsTitle,
        },
    ];
    return 'Project details kept as on this device: ${labels.join(', ')}';
  }

  /// The deletion side of a conflict that was changed rather than deleted.
  static const String conflictChanged = 'Kept and changed';

  /// The duplicate pair view's field line. [label] and [value] are data.
  static String duplicateField(String label, String value) =>
      '$label: ${value.isEmpty ? conflictEmpty : value}';

  // Records: list, filters and sort (014).

  /// Prompt on a records list's search field: what it looks through.
  static const String recordsSearchHint = 'Search records';

  /// A record's list title when nothing names it yet: its [number], or no
  /// number at all before one is allocated.
  static String recordsUntitled(int? number) {
    return number == null ? 'Untitled record' : 'Record $number';
  }

  /// A record row's second line: its [number], [identifier] and [context],
  /// whichever are known, in one line. [identifier] and [context] are
  /// template content (FE-L10N-07).
  static String recordsRowSubtitle({
    int? number,
    String identifier = '',
    String context = '',
  }) {
    return <String>[
      if (number != null) '#$number',
      if (identifier.trim().isNotEmpty) identifier.trim(),
      if (context.trim().isNotEmpty) context.trim(),
    ].join(' · ');
  }

  /// A project with no records yet.
  static const String recordsEmptyHeadline = 'No records yet';

  /// Where a project's records come from.
  static const String recordsEmptyMessage =
      'Records you capture in this project appear here.';

  /// The next action on an empty records list.
  static const String recordsEmptyAction = 'Capture a record';

  /// A records search or filter that matched nothing, naming the [query].
  static String recordsNoMatch(String query) {
    final String shown = query.trim();
    return shown.isEmpty ? 'No records match.' : 'No records match "$shown".';
  }

  /// Empties a records search that matched nothing.
  static const String recordsClearSearch = 'Clear search';

  /// Empties a records search and turns its filters off, together.
  static const String recordsClearAll = 'Clear search and filters';

  /// The records list with no project open.
  static const String recordsNoProjectHeadline = 'No project open';

  /// Why the records list is empty without a project.
  static const String recordsNoProjectMessage =
      'Records belong to a project. Open one to see its records.';

  /// The next action when no project is open.
  static const String recordsOpenProject = 'Open a project';

  /// Title of a records list's filter sheet.
  static const String recordsFiltersTitle = 'Record filters';

  /// The status facet of the records filters.
  static const String recordsFilterStatus = 'Status';

  /// The template facet of the records filters.
  static const String recordsFilterTemplate = 'Template';

  /// The earliest capture date the records filters keep.
  static const String recordsFilterFrom = 'Captured from';

  /// The latest capture date the records filters keep.
  static const String recordsFilterTo = 'Captured until';

  /// The operator facet of the records filters.
  static const String recordsFilterOperator = 'Captured by';

  /// The condition facet of the records filters.
  static const String recordsFilterCondition = 'Condition';

  /// The quality-flag facet of the records filters.
  static const String recordsFilterFlags = 'Quality';

  /// Quality flag: the record has at least one photo.
  static const String recordsFlagHasPhotos = 'Has photos';

  /// Quality flag: the record may duplicate another.
  static const String recordsFlagHasDuplicate = 'Possible duplicate';

  /// Quality flag: a merge left a conflict on the record.
  static const String recordsFlagHasConflict = 'Merge conflict';

  /// Quality flag: a value changed after the record was approved.
  static const String recordsFlagHasVariance = 'Changed since approval';

  /// Quality flag: a value lost every photo it was read from.
  static const String recordsFlagEvidenceRemoved = 'Evidence removed';

  /// Quality flag: the record arrived in a package from another device.
  static const String recordsFlagMerged = 'From another device';

  /// The filter sheet of a project with no records.
  static const String recordsFiltersEmptyHeadline = 'Nothing to filter yet';

  /// What fills the filter sheet.
  static const String recordsFiltersEmptyMessage =
      'Capture records in this project, then narrow them down here.';

  /// A template whose name is not on this device.
  static const String recordsTemplateUnnamed = 'Unnamed template';

  /// Active-filter chip for a template. [name] is template content.
  static String recordsChipTemplate(String name) => 'Template: $name';

  /// Active-filter chip for who captured the records. [name] is data the
  /// operator entered.
  static String recordsChipOperator(String name) => 'Captured by $name';

  /// Active-filter chip for a condition code. [code] is template content.
  static String recordsChipCondition(String code) => 'Condition: $code';

  /// Active-filter chip for one context value: the [level] it sits at and
  /// the [value]. Both are template content.
  static String recordsChipContext(String level, String value) =>
      '$level: $value';

  /// Active-filter chip for the capture date range, in [locale]'s format.
  static String recordsChipDates({
    DateTime? from,
    DateTime? to,
    required String locale,
  }) {
    final DateFormat format = DateFormat.yMMMd(locale);
    if (from != null && to != null) {
      return '${format.format(from)} – ${format.format(to)}';
    }
    if (from != null) {
      return 'From ${format.format(from)}';
    }
    return to == null ? '' : 'Until ${format.format(to)}';
  }

  /// Title of the records sort choice.
  static const String recordsSortTitle = 'Sort records';

  /// The sort control, naming the [current] order.
  static String recordsSortLabel(String current) => 'Sort: $current';

  /// Highest record number first, the newest capture on top.
  static const String recordsSortNumberDescending = 'Number, highest first';

  /// Lowest record number first.
  static const String recordsSortNumberAscending = 'Number, lowest first';

  /// Latest capture first.
  static const String recordsSortCapturedDescending = 'Captured, newest first';

  /// Earliest capture first.
  static const String recordsSortCapturedAscending = 'Captured, oldest first';

  /// Names in alphabetical order.
  static const String recordsSortNameAscending = 'Name, A to Z';

  /// Names in reverse alphabetical order.
  static const String recordsSortNameDescending = 'Name, Z to A';

  // Records: detail and history (014).

  // The record page (014 step 4). Field labels, values, context values,
  // operators, devices, providers and models it shows are data and pass
  // through these strings unchanged (FE-L10N-07).

  /// Leaves the page of a record that is not on this device for the list.
  static const String recordDetailBackToList = 'Back to the list';

  /// Above a record in the recycle bin: why it cannot be changed, and what
  /// to do first.
  static const String recordDetailDeletedNotice =
      'This record is in the recycle bin. Restore it to change it again.';

  /// Sends the record shown to review, the step before it is approved.
  static const String recordDetailSendToReview = 'Send to review';

  /// Once the record shown waits for review.
  static const String recordDetailSentToReview = 'Record sent to review';

  /// Menu row that brings the record shown back from the archive.
  static const String recordDetailUnarchive = 'Unarchive record';

  /// Once the record shown is back from the archive.
  static const String recordDetailUnarchived = 'Record back from the archive';

  /// Opens the page that edits the record's photos, captions and audio.
  static const String recordDetailEditPhotos = 'Edit photos and captions';

  /// A status move asked for while another is still being written.
  static const String recordDetailBusy =
      'A change to this record is still being saved.';

  /// What to do about [recordDetailBusy].
  static const String recordDetailBusyAction =
      'Wait for it to finish, then try again.';

  /// A record with no values and no fields to fill.
  static const String recordDetailNoValues = 'This record has no values yet.';

  /// Heading over the context in force when the record was captured.
  static const String recordDetailContextTitle = 'Context';

  /// A record captured with no context in force.
  static const String recordDetailContextEmpty =
      'No context was set when this record was captured.';

  /// Heading over the count of the record's values by where they came from.
  static const String recordDetailProvenanceTitle =
      'Where the values came from';

  /// How many of the record's values came from one source, or carry one
  /// mark.
  static String recordDetailValuesCount(int n) {
    return Intl.plural(
      n,
      zero: 'No values',
      one: '1 value',
      other: '$n values',
    );
  }

  /// The values a person confirmed.
  static const String recordDetailVerified = 'Confirmed by a person';

  /// The providers, models and methods that read the record's values.
  static const String recordDetailReadBy = 'Read by';

  /// Heading over when the record was captured, changed, approved and
  /// exported.
  static const String recordDetailDatesTitle = 'Dates';

  /// When the record was captured, and on which device.
  static const String recordDetailCaptured = 'Captured';

  /// When the record last changed.
  static const String recordDetailUpdated = 'Last changed';

  /// When the record was last approved, and by whom.
  static const String recordDetailApproved = 'Approved';

  /// When the record was last exported.
  static const String recordDetailExported = 'Exported';

  /// A record that has never been exported.
  static const String recordDetailNotExported = 'Not exported yet';

  /// When something happened to the record, [at] in local time, and who or
  /// which device did it ([by], data) when that is known.
  static String recordDetailWhen(DateTime at, {String by = ''}) {
    final String when = DateFormat.yMMMd().add_jm().format(at);
    final String who = by.trim();
    return who.isEmpty ? when : '$when · $who';
  }

  /// One of the record's photos by its 1-based [position] among [total].
  static String recordPhotoPosition(int position, int total) {
    return 'Photo $position of $total';
  }

  /// A value typed by a person, or corrected by hand.
  static const String recordSourceTyped = 'Typed';

  /// A value read from a photo's text on this device.
  static const String recordSourceOcr = 'Read from photo';

  /// A value an AI model read from a photo.
  static const String recordSourceAiPhoto = 'AI from photo';

  /// A value an AI model read from captions or spoken notes.
  static const String recordSourceAiText = 'AI from notes';

  /// A value spoken aloud and written down.
  static const String recordSourceSpeech = 'Dictated';

  /// A value scanned from a barcode or QR code.
  static const String recordSourceBarcode = 'Barcode';

  /// A value looked up in a reference list.
  static const String recordSourceLookup = 'Looked up';

  /// A value taken from the context in force at capture.
  static const String recordSourceContext = 'From context';

  /// A value the template filled in by default.
  static const String recordSourceDefault = 'Filled in';

  /// A value that arrived in an imported table or package.
  static const String recordSourceImported = 'Imported';

  /// A reading the processing was sure of.
  static const String recordBandHigh = 'High confidence';

  /// A reading the processing was fairly sure of.
  static const String recordBandMedium = 'Medium confidence';

  /// A reading a person should check.
  static const String recordBandLow = 'Low confidence';

  /// A confidence with no stored band: [score], 0 to 1, as a percentage.
  static String recordBandScore(double score) {
    return '${NumberFormat.percentPattern().format(score)} confidence';
  }

  /// What a screen reader hears after a value: where it came from, how sure
  /// the reading was when that is known, and its marks.
  static String recordValueMarks({
    required String source,
    String band = '',
    bool evidenceRemoved = false,
    bool retired = false,
  }) {
    return <String>[
      'Source: $source',
      if (band.isNotEmpty) band,
      if (evidenceRemoved) recordValueEvidenceRemoved,
      if (retired) recordValueRetired,
    ].join(', ');
  }

  // The history page (014 step 6). Field labels, template names, values,
  // package names, providers, models, operators and devices it shows are
  // data and pass through these strings unchanged (FE-L10N-07).

  /// Title of a record's history page.
  static const String recordHistoryTitle = 'History';

  /// Under the history title: which record the history is of, by its
  /// [number] and [name] (data). Blank when the record has neither.
  static String recordHistorySubject({int? number, String name = ''}) {
    return <String>[
      if (number != null) projectRecordPosition(number),
      if (name.isNotEmpty) name,
    ].join(' · ');
  }

  /// A record whose history has no lines yet.
  static const String recordHistoryEmptyHeadline = 'No history yet';

  /// What an empty history will hold, and the next step.
  static const String recordHistoryEmptyMessage =
      'Captures, processing runs, edits, approvals, merges and exports of '
      'this record appear here. Go back to the record to change it.';

  /// Leaves an empty history for its record.
  static const String recordHistoryBackToRecord = 'Back to the record';

  /// Heading over one day of a record's history; [day] is local time.
  static String recordHistoryDay(DateTime day) {
    return DateFormat.yMMMEd().format(day);
  }

  /// When a history line was written, by whom and on which device, under
  /// the line. [at] is local time; [operator] and [device] are data and
  /// either may be blank.
  static String recordHistoryByline({
    required DateTime at,
    String operator = '',
    String device = '',
  }) {
    final String who = operator.isEmpty
        ? (device.isEmpty ? '' : 'On $device')
        : (device.isEmpty ? operator : '$operator on $device');
    final String time = DateFormat.jm().format(at);
    return who.isEmpty ? time : '$time · $who';
  }

  /// A record captured on a device.
  static const String recordHistoryCaptured = 'Captured';

  /// A record made by hand, which starts as a draft.
  static const String recordHistoryCreatedByHand = 'Created by hand';

  /// Value [label] written or corrected from [previous] to [next]; all
  /// three are data. A first value shows alone, and a value taken away
  /// says so.
  static String recordHistoryValue(
    String label, {
    String previous = '',
    String next = '',
  }) {
    if (previous.isEmpty && next.isEmpty) {
      return '$label changed';
    }
    if (previous.isEmpty) {
      return '$label: $next';
    }
    if (next.isEmpty) {
      return '$label cleared';
    }
    return '$label: $previous → $next';
  }

  /// The caption of a record or of one of its photos, as the label of
  /// [recordHistoryValue].
  static const String recordHistoryCaption = 'Caption';

  /// A status move from [previous] to [next], both status names. Only the
  /// new status shows when the old one is not known.
  static String recordHistoryStatus({
    String previous = '',
    required String next,
  }) {
    return previous.isEmpty ? 'Status: $next' : '$previous → $next';
  }

  /// A photo added to the record after capture, or during it.
  static const String recordHistoryPhotoAdded = 'Photo added';

  /// A photo taken off the record. Its file stays until the purge.
  static const String recordHistoryPhotoRemoved = 'Photo removed';

  /// The record moved from template [previous] to [next] (names, data).
  /// Either name is blank when that template is not on this device.
  static String recordHistoryTemplate({
    String previous = '',
    String next = '',
  }) {
    if (next.isEmpty) {
      return 'Template changed';
    }
    return previous.isEmpty ? 'Template: $next' : 'Template: $previous → $next';
  }

  /// Stands in for the name of a template that is not on this device.
  static const String recordHistoryTemplateGone =
      'A template not on this device';

  /// A processing run that finished, with the [provider] and [model] it
  /// used (data) when they are known.
  static String recordHistoryProcessed({
    String provider = '',
    String model = '',
  }) {
    final String by = provider.isEmpty ? '' : ' by $provider';
    final String using = model.isEmpty ? '' : ' ($model)';
    return 'Processed$by$using';
  }

  /// A processing run that stopped for good after [attempts] tries; zero
  /// when the count is not known.
  static String recordHistoryProcessingFailed(int attempts) {
    if (attempts <= 0) {
      return 'Processing failed';
    }
    return Intl.plural(
      attempts,
      one: 'Processing failed after 1 attempt',
      other: 'Processing failed after $attempts attempts',
    );
  }

  /// A record that arrived in [package], a package file name (data).
  static String recordHistoryImported(String package) {
    return package.isEmpty
        ? 'Imported from a package'
        : 'Imported from $package';
  }

  /// A record changed by merging [package], a package file name (data).
  static String recordHistoryMerged(String package) {
    return package.isEmpty ? 'Merged from a package' : 'Merged from $package';
  }

  /// A record included in export [version], stored as `v<number>`.
  static String recordHistoryExported(String version) {
    return version.isEmpty ? 'Exported' : 'Exported in export $version';
  }

  /// Value [label] (data) lost every photo it was read from. The value is
  /// kept.
  static String recordHistoryEvidenceRemoved(String label) {
    return '$label: evidence removed';
  }

  /// Value [label] (data) has a photo it was read from again.
  static String recordHistoryEvidenceRestored(String label) {
    return '$label: evidence restored';
  }

  /// Value [label] (data) kept as retired by a template change.
  static String recordHistoryRetired(String label) => '$label retired';

  /// Retired value [label] (data) that a template change mapped again.
  static String recordHistoryMappedAgain(String label) {
    return '$label mapped again';
  }

  /// The record matched to a row of its template's checklist.
  static const String recordHistoryRowMatched = 'Matched to a checklist row';

  /// A photo file of the record was found missing from this device.
  static const String recordHistoryFileMissing = 'A photo file is missing';

  /// Any other change the audit table holds for the record.
  static const String recordHistoryOther = 'Record changed';

  /// Title of the sheet that shows one history line whole.
  static const String recordHistoryLineTitle = 'Change';

  /// Label of the value or status a change replaced.
  static const String recordHistoryBefore = 'Before';

  /// Label of the value or status a change wrote.
  static const String recordHistoryAfter = 'After';

  /// Label of when a change was written.
  static const String recordHistoryWhen = 'When';

  /// Label of who wrote a change.
  static const String recordHistoryOperator = 'Operator';

  /// Label of the device a change was written on.
  static const String recordHistoryDevice = 'Device';

  /// Label of why a change was made.
  static const String recordHistoryReason = 'Reason';

  /// Stands in for an operator or device the audit row does not hold.
  static const String recordHistoryNotRecorded = 'Not recorded';

  /// Stands in for a value that was empty before or after a change.
  static const String recordHistoryEmptyValue = 'Empty';

  /// When a change was written, in full; [at] is local time.
  static String recordHistoryAt(DateTime at) {
    return DateFormat.yMMMd().add_jms().format(at);
  }

  // Records: editing, photos and template change (014).

  /// Title of the page that edits a saved record's values.
  static const String recordValuesEditTitle = 'Edit values';

  /// Title of the one-value sheet when the caller does not name the field.
  static const String recordValueEditTitle = 'Edit value';

  /// Above the values of an approved record: what saving a change does.
  static const String recordEditApprovedNotice =
      'This record is approved. Saving a change sends it back to review.';

  /// Marks a value its record's template no longer has. It is kept, and it
  /// cannot be edited or removed.
  static const String recordValueRetired = 'Retired';

  /// Heading over the values a record keeps after its template dropped them.
  static const String recordRetiredValuesTitle = 'Retired values';

  /// Why retired values cannot be edited.
  static const String recordRetiredValuesMessage =
      "This record's template no longer has these fields. Their values are "
      "kept as they were and can't be edited.";

  /// Marks a value whose source photos were all removed. The value is kept.
  static const String recordValueEvidenceRemoved = 'Evidence removed';

  /// Shown when a record's template is no longer on this device.
  static const String recordTemplateMissingNotice =
      "This record's template is no longer on this device. Its values are "
      'kept; change its template to edit them.';

  /// The edit page of a record that sits in the recycle bin.
  static const String recordEditDeletedHeadline =
      'This record is in the recycle bin';

  /// What to do before editing a record in the recycle bin.
  static const String recordEditDeletedMessage =
      'Restore it from the recycle bin, then change its values.';

  /// The one-value sheet for a field the record's template no longer has.
  static const String recordFieldMissingHeadline =
      'This field is not on the record';

  /// What to do when the one-value sheet has no field to show.
  static const String recordFieldMissingMessage =
      "The record's template no longer has this field. Go back to the record.";

  /// Why a saved value cannot be emptied: the captured original always
  /// stays, so an empty edit would show it again (FE-SEC-08).
  static const String recordValueCannotEmpty =
      'A saved value cannot be emptied. Type the corrected value instead.';

  /// Snack once [n] values are saved. [backToReview] adds that the record,
  /// which was approved, is waiting for review again.
  static String recordValuesSaved(int n, {bool backToReview = false}) {
    final String saved = Intl.plural(
      n,
      one: '1 value saved',
      other: '$n values saved',
    );
    return backToReview ? '$saved. The record is back in review.' : '$saved.';
  }

  // Photos added to a saved record, and moving it to another template.

  /// Title of the offer to process a record again after photos were added.
  static const String recordPhotosProcessTitle = 'Process this record again?';

  /// Body of that offer: what processing the [n] added photos does, and
  /// that values already on the record stay.
  static String recordPhotosProcessMessage(int n) {
    return Intl.plural(
      n,
      one:
          'You added 1 photo. Processing again reads it and fills fields '
          'that are still empty. Values already on the record stay as they '
          'are.',
      other:
          'You added $n photos. Processing again reads them and fills '
          'fields that are still empty. Values already on the record stay '
          'as they are.',
    );
  }

  /// Confirms processing the record again.
  static const String recordPhotosProcessConfirm = 'Process again';

  /// Snack once the record is back in the processing queue.
  static const String recordPhotosProcessQueued =
      'Record queued for processing.';

  /// Title of the sheet that moves a record to another template.
  static const String recordTemplateChangeTitle = 'Change template';

  /// Names the template the record is on now. [name] is data.
  static String recordTemplateChangeCurrent(String name) => 'Now on $name';

  /// Heading over the templates the record can move to.
  static const String recordTemplateChangeChoose = 'Move to';

  /// Shown before a template is chosen.
  static const String recordTemplateChangeHint =
      'Choose a template to see what happens to each value before anything '
      'changes.';

  /// Heading over the values whose field the chosen template also has.
  static String recordTemplateChangeMapped(int n) {
    return Intl.plural(
      n,
      one: '1 value carried over',
      other: '$n values carried over',
    );
  }

  /// Heading over the values the chosen template has no field for.
  static String recordTemplateChangeRetired(int n) {
    return Intl.plural(
      n,
      one: '1 value kept as retired',
      other: '$n values kept as retired',
    );
  }

  /// Heading over the chosen template's fields the record has no value for.
  static String recordTemplateChangeAdded(int n) {
    return Intl.plural(
      n,
      one: '1 field starts empty',
      other: '$n fields start empty',
    );
  }

  /// Heading over retired values whose field the chosen template has again.
  static String recordTemplateChangeRestored(int n) {
    return Intl.plural(
      n,
      one: '1 retired value comes back',
      other: '$n retired values come back',
    );
  }

  /// Why retiring a value loses nothing.
  static const String recordTemplateChangeRetiredNotice =
      'Retired values stay on the record and are never deleted. They come '
      'back if the record moves to a template with their field.';

  /// When the move changes no value at all.
  static const String recordTemplateChangeNoValues =
      'No value changes: the record has no values for this template to take '
      'over, and the template has no fields.';

  /// Above the preview of an approved record: what applying does.
  static const String recordTemplateChangeApprovedNotice =
      'This record is approved. Changing its template sends it back to '
      'review.';

  /// Applies the move.
  static const String recordTemplateChangeApply = 'Change template';

  /// Snack once the record is on its new template. [backToReview] adds that
  /// the record, which was approved, is waiting for review again.
  static String recordTemplateChanged({bool backToReview = false}) {
    return backToReview
        ? 'Template changed. The record is back in review.'
        : 'Template changed.';
  }

  /// No other template to move the record to.
  static const String recordTemplateChangeEmptyHeadline = 'No other template';

  /// What to do when the project has no other template.
  static const String recordTemplateChangeEmptyMessage =
      'This project has only the template this record uses. Add another '
      'template to the project, then move the record to it.';

  /// Opens the project's templates from the empty state.
  static const String recordTemplateChangeEmptyAction = 'Open templates';

  /// The record to move is no longer on this device.
  static const String recordTemplateChangeGoneHeadline =
      'This record is no longer on this device';

  /// What to do when the record to move is gone.
  static const String recordTemplateChangeGoneMessage =
      'Close this sheet and pick another record.';

  /// What to do when Change template is pressed before a template is chosen.
  static const String recordTemplateChangeChooseAction =
      'Choose a template under Move to, then apply.';

  /// A second press while the record is already moving.
  static const String recordTemplateChangeApplying =
      'This record is already moving to that template.';

  /// What to do while the record is already moving.
  static const String recordTemplateChangeApplyingAction =
      'Wait a moment, then check the record.';

  // Records: delete, recycle bin and bulk actions (014).

  /// Names the delete control for [n] records, for its tooltip and screen
  /// readers.
  static String recordsDeleteLabel(int n) {
    return Intl.plural(n, one: 'Delete record', other: 'Delete $n records');
  }

  /// Title of the confirm before [n] records move to the recycle bin.
  static String recordsDeleteTitle(int n) {
    return Intl.plural(n, one: 'Delete 1 record?', other: 'Delete $n records?');
  }

  /// Body of that confirm: where the [records] go, and for how many [days]
  /// they can still be restored whole.
  static String recordsDeleteMessage({
    required int records,
    required int days,
  }) {
    final String window = settingsRetentionDays(days);
    return Intl.plural(
      records,
      one:
          'It moves to the recycle bin, where you can restore it for '
          '$window. Its photos stay on this device until then.',
      other:
          'They move to the recycle bin, where you can restore them for '
          '$window. Their photos stay on this device until then.',
    );
  }

  /// Confirms the move to the recycle bin.
  static const String recordsDeleteConfirm = 'Delete';

  /// Snack once [n] records are in the recycle bin. Undo sits beside it.
  static String recordsDeleted(int n) {
    return Intl.plural(n, one: '1 record deleted', other: '$n records deleted');
  }

  /// Snack or line when [n] records could not be deleted.
  static String recordsNotDeleted(int n) {
    return Intl.plural(
      n,
      one: '1 record could not be deleted',
      other: '$n records could not be deleted',
    );
  }

  /// Snack when some records were deleted and some were not. Undo brings
  /// back the [deleted] ones.
  static String recordsDeletedPartly({
    required int deleted,
    required int failed,
  }) {
    return '${recordsDeleted(deleted)}. ${recordsNotDeleted(failed)}.';
  }

  /// Snack once [n] records are back from the recycle bin.
  static String recordsRestored(int n) {
    return Intl.plural(
      n,
      one: '1 record restored',
      other: '$n records restored',
    );
  }

  /// Snack or line when [n] records could not be restored.
  static String recordsNotRestored(int n) {
    return Intl.plural(
      n,
      one: '1 record could not be restored',
      other: '$n records could not be restored',
    );
  }

  // Recycle bin (014 step 7).

  /// Title of the recycle bin page.
  static const String recycleBinTitle = 'Recycle bin';

  /// Storage settings row that opens the recycle bin.
  static const String recycleBinSettingsSubtitle =
      'Restore a deleted record before it is removed for good.';

  /// The line above the recycle bin list: how long a deleted record stays
  /// restorable, [days] being the operator's window.
  static String recycleBinKeptFor(int days) {
    return 'Deleted records stay here for ${settingsRetentionDays(days)}, '
        'then they are removed for good.';
  }

  /// Headline of an empty recycle bin.
  static const String recycleBinEmptyHeadline = 'Nothing in the recycle bin';

  /// What an empty recycle bin is for, and the way a record gets back out:
  /// a deleted record waits here for [days].
  static String recycleBinEmptyMessage(int days) {
    return 'A record you delete waits here for '
        '${settingsRetentionDays(days)}. Restore it from here to put it back '
        'in its list.';
  }

  /// A recycle bin row's second line: the record's [number] when the row's
  /// title is its name, its [projectName], and when it was deleted
  /// ([deletedAt]). [projectName] is the operator's own text (FE-L10N-07).
  static String recycleBinRowSubtitle({
    required String projectName,
    required DateTime deletedAt,
    int? number,
  }) {
    final String when = DateFormat.yMMMd().add_jm().format(deletedAt.toLocal());
    return <String>[
      if (number != null) '#$number',
      if (projectName.trim().isNotEmpty) projectName.trim(),
      'Deleted $when',
    ].join(' · ');
  }

  /// How long a record in the recycle bin has before the purge removes it
  /// for good: [days] whole days, 0 once its window has run out.
  static String recycleBinDaysLeft(int days) {
    return Intl.plural(
      days,
      zero: 'Deletes today',
      one: 'Deletes in 1 day',
      other: 'Deletes in $days days',
    );
  }

  /// Tooltip of a recycle bin row's restore control.
  static const String recycleBinRestore = 'Restore';

  /// Screen-reader name of the restore control on the row of record
  /// [name], which is the record's own text (FE-L10N-07).
  static String recycleBinRestoreLabel(String name) => 'Restore $name';

  /// A restore asked for while the same record is being restored.
  static const String recycleBinRestoring =
      'This record is already being restored.';

  /// What to do while a record is being restored.
  static const String recycleBinRestoringAction =
      'Wait a moment, then look for it in its list.';

  /// The action that removes everything in the recycle bin now.
  static const String recycleBinEmpty = 'Empty recycle bin';

  /// Title of the strong confirm before [n] records are removed for good.
  static String recycleBinEmptyTitle(int n) {
    return Intl.plural(
      n,
      one: 'Remove 1 record for good?',
      other: 'Remove $n records for good?',
    );
  }

  /// Body of that confirm: what goes, that it cannot be undone, and what
  /// stays.
  static String recycleBinEmptyWarning(int n) {
    return Intl.plural(
      n,
      one:
          'The record in the recycle bin and its photos are removed from '
          'this device now. This cannot be undone. A record a merge still '
          'needs stays until it has been shared.',
      other:
          'All $n records in the recycle bin and their photos are removed '
          'from this device now. This cannot be undone. Records a merge '
          'still needs stay until they have been shared.',
    );
  }

  /// Label of the field the operator types [n] into to confirm.
  static String recycleBinEmptyTypeCount(int n) => 'Type $n to confirm';

  /// Confirms emptying the recycle bin.
  static const String recycleBinEmptyConfirm = 'Remove for good';

  /// Why Empty recycle bin cannot be pressed on this device.
  static const String recycleBinEmptyUnavailable =
      'Emptying is not available on this device. Each record is removed '
      'for good once its days run out.';

  /// What to do when emptying is not available.
  static const String recycleBinEmptyUnavailableAction =
      'Restore what you need before its days run out.';

  /// An empty-now asked for while the recycle bin is being emptied.
  static const String recycleBinEmptying =
      'The recycle bin is already being emptied.';

  /// What to do while the recycle bin is being emptied.
  static const String recycleBinEmptyingAction = 'Wait for it to finish.';

  /// Snack after emptying the recycle bin: how many records were [purged],
  /// how many were [kept] because a merge still needs them, and how many
  /// [failed] and stay for the next try.
  static String recycleBinEmptied({
    required int purged,
    required int kept,
    required int failed,
  }) {
    return <String>[
      Intl.plural(
        purged,
        zero: 'No records removed',
        one: '1 record removed for good',
        other: '$purged records removed for good',
      ),
      if (kept > 0)
        Intl.plural(
          kept,
          one: '1 kept because a merge still needs it',
          other: '$kept kept because a merge still needs them',
        ),
      if (failed > 0)
        Intl.plural(
          failed,
          one: '1 could not be removed',
          other: '$failed could not be removed',
        ),
    ].join('. ');
  }

  // Bulk actions over a selection (014 step 8).

  /// The bulk action bar's count of ticked records.
  static String recordsSelectedCount(int n) {
    return Intl.plural(n, one: '1 selected', other: '$n selected');
  }

  /// Unticks every record and leaves selection mode.
  static const String recordsClearSelection = 'Clear selection';

  /// Ticks every record the list has shown.
  static const String recordsSelectAllShown = 'Select all shown';

  /// Names the bulk approve control for [n] records.
  static String recordsApproveLabel(int n) {
    return Intl.plural(n, one: 'Approve record', other: 'Approve $n records');
  }

  /// Names the bulk archive control for [n] records.
  static String recordsArchiveLabel(int n) {
    return Intl.plural(n, one: 'Archive record', other: 'Archive $n records');
  }

  /// Names the bulk process-again control for [n] records.
  static String recordsReprocessLabel(int n) {
    return Intl.plural(
      n,
      one: 'Process record again',
      other: 'Process $n records again',
    );
  }

  /// Names the bulk export control for [n] records.
  static String recordsExportLabel(int n) {
    return Intl.plural(n, one: 'Export record', other: 'Export $n records');
  }

  /// Title of the confirm before [n] records are archived.
  static String recordsArchiveTitle(int n) {
    return Intl.plural(
      n,
      one: 'Archive 1 record?',
      other: 'Archive $n records?',
    );
  }

  /// Body of that confirm: where the [n] records go and how to find them.
  static String recordsArchiveMessage(int n) {
    return Intl.plural(
      n,
      one:
          'It leaves the records list and default exports, and keeps its '
          'values and photos. Filter by Archived to find it again.',
      other:
          'They leave the records list and default exports, and keep their '
          'values and photos. Filter by Archived to find them again.',
    );
  }

  /// Confirms archiving.
  static const String recordsArchiveConfirm = 'Archive';

  /// Title of the confirm before [n] records are processed again.
  static String recordsReprocessTitle(int n) {
    return Intl.plural(
      n,
      one: 'Process 1 record again?',
      other: 'Process $n records again?',
    );
  }

  /// Body of that confirm: what processing again does to the [n] records.
  static String recordsReprocessMessage(int n) {
    return Intl.plural(
      n,
      one:
          'It goes back to the processing queue and is read again from the '
          'first step, with the other records waiting in this project. '
          'Values it already has are kept. If it was approved, it needs '
          'review again.',
      other:
          'They go back to the processing queue and are read again from the '
          'first step, with the other records waiting in this project. '
          'Values they already have are kept. Approved ones need review '
          'again.',
    );
  }

  /// Confirms processing again.
  static const String recordsReprocessConfirm = 'Process again';

  /// Title of the confirm before exporting with [n] records selected.
  static String recordsExportTitle(int n) {
    return Intl.plural(
      n,
      one: 'Export the project with this record?',
      other: 'Export the project with these $n records?',
    );
  }

  /// Body of that confirm: an export is the whole project's package.
  static String recordsExportMessage(int n) {
    return Intl.plural(
      n,
      one:
          'An export is one package of the whole project: every record in '
          'it, this one included, with their photos. You choose where it '
          'goes once it is written.',
      other:
          'An export is one package of the whole project: every record in '
          'it, the $n selected included, with their photos. You choose '
          'where it goes once it is written.',
    );
  }

  /// Opens the project's export page.
  static const String recordsExportConfirm = 'Open export';

  /// Snack once [n] records are approved.
  static String recordsApproved(int n) {
    return Intl.plural(
      n,
      one: '1 record approved',
      other: '$n records approved',
    );
  }

  /// Snack or line when [n] records could not be approved.
  static String recordsNotApproved(int n) {
    return Intl.plural(
      n,
      one: '1 record could not be approved',
      other: '$n records could not be approved',
    );
  }

  /// Snack once [n] records are archived.
  static String recordsArchived(int n) {
    return Intl.plural(
      n,
      one: '1 record archived',
      other: '$n records archived',
    );
  }

  /// Snack or line when [n] records could not be archived.
  static String recordsNotArchived(int n) {
    return Intl.plural(
      n,
      one: '1 record could not be archived',
      other: '$n records could not be archived',
    );
  }

  /// Snack once [n] records are back in the processing queue.
  static String recordsRequeued(int n) {
    return Intl.plural(
      n,
      one: '1 record queued to process again',
      other: '$n records queued to process again',
    );
  }

  /// Snack or line when [n] records could not be queued again.
  static String recordsNotRequeued(int n) {
    return Intl.plural(
      n,
      one: '1 record could not be queued',
      other: '$n records could not be queued',
    );
  }

  /// Added to that snack while offline: the [n] queued records wait.
  static String recordsRequeuedOffline(int n) {
    return Intl.plural(
      n,
      one:
          'It waits in the processing queue; process it from there once '
          'you are online.',
      other:
          'They wait in the processing queue; process them from there once '
          'you are online.',
    );
  }

  /// A bulk action's summary when some records changed and some did not:
  /// [done] and [notDone] are the two counted sentences.
  static String recordsBulkOutcome({
    required String done,
    required String notDone,
  }) {
    return '$done. $notDone.';
  }

  /// A bulk action asked for while another is still running.
  static const String recordsBulkBusy = 'Another bulk action is running.';

  /// What to do while a bulk action is running.
  static const String recordsBulkBusyAction =
      'Wait for it to finish, then try again.';

  // Records: data and purge (014).

  /// How many validation issues a form is showing.
  static String validationIssueCount(int errors, int warnings) {
    if (errors > 0 && warnings > 0) {
      return '${validationErrorCount(errors)}, ${validationWarningCount(warnings)}';
    }
    if (errors > 0) {
      return validationErrorCount(errors);
    }
    return validationWarningCount(warnings);
  }

  /// Error count for a validation summary.
  static String validationErrorCount(int n) {
    return Intl.plural(n, one: '1 error', other: '$n errors');
  }

  /// Warning count for a validation summary.
  static String validationWarningCount(int n) {
    return Intl.plural(n, one: '1 warning', other: '$n warnings');
  }

  /// Jumps the summary to the first field that has an error.
  static const String validationGoToFirstError = 'Go to the first error';

  /// Word beside an error, so the state is not colour alone.
  static const String validationErrorLabel = 'Error';

  /// Word beside a warning, so the state is not colour alone.
  static const String validationWarningLabel = 'Warning';

  /// A required field that is empty.
  static String validationRequired(String label) => '$label is required.';

  /// A value that is the wrong kind for its field.
  static String validationType(String label) =>
      '$label is not a valid value for this field.';

  /// A value shorter than the field allows.
  static String validationTooShort(String label) => '$label is too short.';

  /// A value longer than the field allows.
  static String validationTooLong(String label) => '$label is too long.';

  /// A value outside the field's numeric range.
  static String validationRange(String label) =>
      '$label is outside the allowed range.';

  /// A value that does not match the field's pattern.
  static String validationPattern(String label) =>
      '$label does not match the expected pattern.';

  /// A choice that is not one of the field's options.
  static String validationOption(String label) =>
      '$label is not one of the allowed choices.';

  /// A measurement the field's unit cannot hold.
  static String validationUnit(String label) =>
      '$label is not in a unit this field can store.';

  /// An identity field left empty.
  static String validationIdentity(String label) =>
      '$label identifies the record and is required.';

  /// Evidence the template demands is missing.
  static const String validationEvidence =
      'This record needs its evidence before it can be approved.';

  /// A computed expression that does not parse.
  static const String validationExpression =
      'That expression could not be read.';

  /// What to do when an expression does not parse.
  static const String validationExpressionAction =
      'Use fields on this template, comparisons and arithmetic only.';

  /// An expression names a field the template does not have.
  static String validationUnknownField(String name) =>
      'Required when names "$name", which this template does not have.';

  /// Duplicate prompt title.
  static const String duplicatePromptTitle = 'This may be a duplicate';

  /// Writes the new values onto the existing record.
  static const String duplicateOverride = 'Update the existing record';

  /// Keeps both records and links them.
  static const String duplicateLinkBoth = 'Keep both and link them';

  /// Drops the new record.
  static const String duplicateDiscard = 'Discard the new record';

  /// Opens the field-by-field merge.
  static const String duplicateMerge = 'Merge field by field';

  /// Headline when two records do not differ.
  static const String duplicateNoDifferenceHeadline = 'Nothing differs';

  /// Why the duplicate prompt has nothing to compare.
  static const String duplicateNoDifferenceMessage =
      'These records hold the same values.';

  /// Duplicate compare title.
  static const String duplicateCompareTitle = 'Compare records';

  /// Merge sheet title.
  static const String duplicateMergeTitle = 'Merge fields';

  /// Keeps this record's value for one field.
  static const String duplicateKeepMine = 'Keep mine';

  /// Takes the other record's value for one field.
  static const String duplicateTakeTheirs = 'Take theirs';

  /// Keeps both values for one field as a note.
  static const String duplicateKeepBothNote = 'Keep both as a note';

  /// Duplicates review title.
  static const String duplicatesTitle = 'Duplicates';

  /// Empty duplicates list headline.
  static const String duplicatesEmptyHeadline = 'No duplicate pairs';

  /// Empty duplicates list explanation.
  static const String duplicatesEmptyMessage =
      'Pairs appear here when two records look like the same thing.';

  /// Clears every remaining pair in one group.
  static const String duplicatesResolveGroup = 'Resolve this group';

  /// Bulk confirm title naming [choice] and how many records [n].
  static String duplicatesBulkTitle(int n, String choice) =>
      '$choice for $n records?';

  /// Bulk confirm body naming how many records [n] change.
  static String duplicatesBulkMessage(int n) =>
      'This changes $n records. The other groups stay as they are.';

  /// Types a value that matches none of the candidates.
  static const String conflictTypeOwn = 'Type a different value';

  /// The reason a person gives for the value they chose.
  static const String conflictReason = 'Why this value';

  /// Empty conflict row headline.
  static const String conflictEmptyHeadline = 'No candidates';

  /// Empty conflict row explanation.
  static const String conflictEmptyMessage =
      'Nothing was proposed for this field.';

  /// Unresolved conflict blocks approval and names the field.
  static String conflictBlocksApproval(String label) =>
      '$label still has a conflict. Resolve it before approving.';

  /// Verification mode switch title.
  static const String verificationModeTitle = 'Verification mode';

  /// Shown while verification mode is on.
  static const String verificationModeOn =
      'Capture confirms the register instead of starting a blank record.';

  /// Shown while verification mode is off.
  static const String verificationModeOff = 'Capture starts a new record.';

  /// Status line mark while verification mode is on.
  static const String verificationStatus = 'Verifying';

  /// A value that came from the register.
  static const String verificationFromRegister = 'From the register';

  /// Variance screen title.
  static const String varianceTitle = 'Variances';

  /// Empty variance list headline.
  static const String varianceEmptyHeadline = 'No variances';

  /// Empty variance list explanation.
  static const String varianceEmptyMessage =
      'Differences between the register and what was found appear here.';

  /// A normalised match.
  static const String varianceMatch = 'Match';

  /// A genuine difference.
  static const String varianceChanged = 'Changed';

  /// A register value with nothing found.
  static const String varianceMissing = 'Missing';

  /// Quality summary title.
  static const String qualitySummaryTitle = 'Data quality';

  /// Records that fail validation.
  static const String qualityInvalid = 'Invalid records';

  /// Unresolved duplicate pairs.
  static const String qualityDuplicates = 'Duplicate pairs';

  /// Unresolved source conflicts.
  static const String qualityConflicts = 'Unresolved conflicts';

  /// Records still waiting for review.
  static const String qualityUnreviewed = 'Unreviewed records';

  /// Headline when nothing blocks export.
  static const String qualityCleanHeadline = 'Ready to export';

  /// Explanation when nothing blocks export.
  static const String qualityCleanMessage =
      'Nothing here still blocks a clean export.';

  /// Review screen title.
  static const String reviewTitle = 'Review';

  /// Fields that need a person before approval.
  static const String reviewNeedsAttention = 'Needs attention';

  /// Confident fields, collapsed until opened.
  static const String reviewConfident = 'Confident';

  /// Approves this record and opens the next one.
  static const String reviewApproveNext = 'Approve and next';

  /// Empty review headline.
  static const String reviewEmptyHeadline = 'Nothing to review';

  /// Empty review explanation.
  static const String reviewEmptyMessage =
      'Records that need a person appear here.';

  /// Shows the captured value.
  static const String reviewUseRaw = 'Use captured';

  /// Shows the refined value.
  static const String reviewUseRefined = 'Use refined';

  /// Neither side has a value.
  static const String reviewNoSidesHeadline = 'No values yet';

  /// Why the raw or refined toggle has nothing to choose.
  static const String reviewNoSidesMessage =
      'This field has neither a captured nor a refined value.';

  /// A value the extractor did not invent.
  static const String reviewNotDetected = 'Not detected';

  /// Types the missing value.
  static const String reviewTypeIt = 'Type it';

  /// Photographs the label for the missing value.
  static const String reviewPhotograph = 'Photograph the label';

  /// No missing value to act on.
  static const String reviewNotDetectedEmpty = 'Nothing is missing';

  /// Opens the evidence for a value.
  static const String reviewShowEvidence = 'Show evidence';

  /// Opens the full photo.
  static const String reviewOpenPhoto = 'Open photo';

  /// Evidence with no photo and no passage.
  static const String reviewEvidenceEmpty = 'No evidence linked';

  /// Verifies the current value without changing it.
  static const String reviewVerify = 'Verify';

  /// Verifies every confident field.
  static const String reviewVerifyConfident = 'Verify confident fields';

  /// Who verified a value, and when.
  static String reviewVerifiedBy(String name) => 'Verified by $name';

  /// Nothing to verify.
  static const String reviewVerifyEmpty = 'Nothing to verify';

  /// Batch position, [index] of [total], both 1-based for [index].
  static String reviewPosition(int index, int total) => '$index of $total';

  /// Skips this record and keeps what was typed.
  static const String reviewSkip = 'Skip';

  /// Returns to the previous record.
  static const String reviewBack = 'Back';

  /// The batch queue is finished.
  static const String reviewQueueDone = 'Review is finished';

  /// What to do when the queue is finished.
  static const String reviewQueueDoneMessage =
      'Every record in this set has been seen.';

  /// The batch queue has no records.
  static const String reviewQueueEmpty = 'No records in this review';

  /// Runs processing again.
  static const String reviewReanalyse = 'Re-analyse';

  /// A proposed value offered beside the current one.
  static const String reviewProposal = 'Proposed';

  /// Marks a proposal the person accepts.
  static const String reviewAccept = 'Accept';

  /// Writes the accepted proposals.
  static const String reviewApplyAccepted = 'Apply accepted';

  /// Declines every proposal.
  static const String reviewDeclineAll = 'Decline all';

  /// A verified or typed value that re-analysis must not overwrite.
  static const String reviewOfferedNotApplied = 'Offered, not applied';

  /// No new proposals.
  static const String reviewReanalyseEmpty = 'No new proposals';

  /// This record is still in an unresolved duplicate pair.
  static const String reviewBlockedDuplicate =
      'This record is part of an unresolved duplicate.';

  /// Where to clear a block.
  static const String reviewBlockedAction =
      'Fix the named field, then approve again.';

  /// Empty confidence indicator headline.
  static const String reviewNoConfidence = 'No confidence';

  /// Empty confidence indicator explanation.
  static const String reviewNoConfidenceMessage =
      'This value has no confidence band yet.';

  /// Audit line when review approves a record.
  static const String reviewApprovedReason = 'Approved in review.';

  /// Meeting create page title.
  static const String meetingTitle = 'Meeting';

  /// Starts a meeting from the prefilled header.
  static const String meetingStart = 'Start meeting';

  /// Empty meeting headline.
  static const String meetingEmptyHeadline = 'No meeting yet';

  /// Empty meeting explanation.
  static const String meetingEmptyMessage =
      'Date, time, location and secretary fill in from this project.';

  /// Header date label.
  static const String meetingDate = 'Date';

  /// Header start-time label.
  static const String meetingStartTime = 'Start time';

  /// Header location label.
  static const String meetingLocation = 'Location';

  /// Header secretary label.
  static const String meetingSecretary = 'Secretary';

  /// Title written when a meeting starts, from the clock's date.
  static String meetingStartedTitle(DateTime when) {
    final String month = when.month.toString().padLeft(2, '0');
    final String day = when.day.toString().padLeft(2, '0');
    return 'Meeting ${when.year}-$month-$day';
  }

  /// Attachments section.
  static const String meetingAttachments = 'Attachments';

  /// Adds an attachment.
  static const String meetingAddAttachment = 'Add attachment';

  /// Empty attachments headline.
  static const String meetingAttachmentsEmpty = 'No attachments';

  /// Empty attachments explanation.
  static const String meetingAttachmentsEmptyMessage =
      'Agendas, reports, handouts and whiteboard photos land here.';

  /// Opens an attachment.
  static const String meetingOpenAttachment = 'Open';

  /// Agenda section.
  static const String meetingAgenda = 'Agenda';

  /// Adds an agenda entry.
  static const String meetingAddAgenda = 'Add agenda item';

  /// Agenda title field.
  static const String meetingAgendaTitle = 'Agenda item';

  /// Discussion notes under an agenda entry.
  static const String meetingDiscussion = 'Discussion';

  /// Moves an entry later.
  static const String meetingMoveDown = 'Move down';

  /// Removes an entry after confirm.
  static const String meetingRemove = 'Remove';

  /// Confirm title for a removal.
  static const String meetingRemoveTitle = 'Remove this?';

  /// Confirm body for a removal.
  static const String meetingRemoveMessage = 'This leaves the meeting.';

  /// Confirm button for a removal.
  static const String meetingRemoveConfirm = 'Remove';

  /// Empty agenda headline.
  static const String meetingAgendaEmpty = 'No agenda yet';

  /// Empty agenda explanation.
  static const String meetingAgendaEmptyMessage =
      'Add the items you will discuss, in the order you want them.';

  /// Attendees section.
  static const String meetingAttendees = 'Attendees';

  /// Adds an attendee.
  static const String meetingAddAttendee = 'Add attendee';

  /// Attendee name field.
  static const String meetingAttendeeName = 'Name';

  /// Attendee title field.
  static const String meetingAttendeeRole = 'Title';

  /// Attendee organisation field.
  static const String meetingOrganisation = 'Organisation';

  /// Attendee contact field.
  static const String meetingContact = 'Contact';

  /// Marks the person present.
  static const String meetingPresent = 'Present';

  /// Marks an apology.
  static const String meetingApology = 'Apology';

  /// How many people are present. Apologies are not included.
  static String meetingAttendanceCount(int count) {
    return Intl.plural(count, one: '1 present', other: '$count present');
  }

  /// Accepts a staff suggestion.
  static const String meetingAcceptStaff = 'Link staff';

  /// Empty attendees headline.
  static const String meetingAttendeesEmpty = 'No attendees yet';

  /// Empty attendees explanation.
  static const String meetingAttendeesEmptyMessage =
      'Add who is present, and record apologies separately.';

  /// Attendance sheet section.
  static const String meetingAttendanceSheet = 'Attendance sheet';

  /// Photographs the signed sheet.
  static const String meetingPhotographSheet = 'Photograph the sheet';

  /// Accepts the edited rows onto the attendee list.
  static const String meetingAcceptRows = 'Add these attendees';

  /// A poor read still keeps the photo.
  static const String meetingSheetKept =
      'The photo stays attached. Type the names if the reading is wrong.';

  /// Empty attendance headline.
  static const String meetingSheetEmpty = 'No attendance sheet';

  /// Empty attendance explanation.
  static const String meetingSheetEmptyMessage =
      'Photograph the signed sheet, then check each name before adding it.';

  /// Signature column.
  static const String meetingSignature = 'Signature';

  /// Recording section.
  static const String meetingRecording = 'Recording';

  /// Starts recording.
  static const String meetingRecord = 'Record';

  /// Stops recording.
  static const String meetingStop = 'Stop';

  /// Elapsed recording time.
  static String meetingElapsed(String clock) => 'Elapsed $clock';

  /// Free space while recording.
  static String meetingRemaining(String label) => '$label free';

  /// A recording interrupted before stop.
  static const String meetingInterrupted = 'Recording interrupted';

  /// Empty recording headline.
  static const String meetingRecordingEmpty = 'No recording';

  /// Empty recording explanation.
  static const String meetingRecordingEmptyMessage =
      'A recording stays on the meeting, including one that was interrupted.';

  /// Decisions section.
  static const String meetingDecisions = 'Decisions';

  /// Adds a decision.
  static const String meetingAddDecision = 'Add decision';

  /// Decision text field.
  static const String meetingDecisionText = 'Decision';

  /// Where a refined decision came from.
  static const String meetingSource = 'From the notes';

  /// Empty decisions headline.
  static const String meetingDecisionsEmpty = 'No decisions yet';

  /// Empty decisions explanation.
  static const String meetingDecisionsEmptyMessage =
      'Decisions from the minutes or typed here are listed together.';

  /// Actions section.
  static const String meetingActions = 'Actions';

  /// Adds an action.
  static const String meetingAddAction = 'Add action';

  /// Action text field.
  static const String meetingActionText = 'Action';

  /// Owner field.
  static const String meetingOwner = 'Owner';

  /// Due date field.
  static const String meetingDue = 'Due date';

  /// Picks an owner from the attendees.
  static const String meetingOwnerAttendee = 'Owner from attendees';

  /// Picks an owner from the staff dataset.
  static const String meetingOwnerStaff = 'Owner from staff';

  /// Action status.
  static const String meetingStatus = 'Status';

  /// Empty actions headline.
  static const String meetingActionsEmpty = 'No actions yet';

  /// Empty actions explanation.
  static const String meetingActionsEmptyMessage =
      'Actions keep an owner, a due date and a status.';

  /// Raw notes beside the minutes.
  static const String meetingNotes = 'Raw notes';

  /// Refined minutes beside the notes.
  static const String meetingMinutes = 'Refined minutes';

  /// Verbatim transcript, never edited here.
  static const String meetingTranscript = 'Transcript';

  /// Blocks approval and names the action.
  static String meetingActionBlocked(String action) =>
      '$action needs an owner and a due date before it can be approved.';

  /// Approves the meeting.
  static const String meetingApprove = 'Approve meeting';

  /// Review page title.
  static const String meetingReviewTitle = 'Review meeting';

  /// Empty review headline.
  static const String meetingReviewEmpty = 'No meeting to review';

  /// Empty review explanation.
  static const String meetingReviewEmptyMessage =
      'Open a meeting to see attendance, decisions and actions.';

  /// Audit line when a meeting is approved.
  static const String meetingApprovedReason = 'Approved in review.';

  /// Deliverable export page title.
  static const String exportTitle = 'Export';

  /// Starts the export.
  static const String exportRun = 'Export';

  /// Scope section title.
  static const String exportScope = 'What to include';

  /// Approved records only.
  static const String exportScopeApproved = 'Approved only';

  /// Every record.
  static const String exportScopeAll = 'All records';

  /// The current context subtree.
  static const String exportScopeContext = 'Current context';

  /// A date range.
  static const String exportScopeDates = 'Date range';

  /// The records list filter.
  static const String exportScopeFilter = 'Current filter';

  /// How many records the scope selects.
  static String exportCount(int count) => '$count records';

  /// Options section title.
  static const String exportOptions = 'Columns';

  /// Raw value columns.
  static const String exportRaw = 'Raw columns';

  /// Refined value columns.
  static const String exportRefined = 'Refined columns';

  /// Confidence column.
  static const String exportConfidence = 'Confidence';

  /// Evidence column.
  static const String exportEvidence = 'Evidence';

  /// Collapsed extras.
  static const String exportAdvanced = 'Advanced';

  /// Photo reference mode.
  static const String exportPhotoMode = 'Photo reference';

  /// CSV delimiter.
  static const String exportDelimiter = 'Delimiter';

  /// Empty export headline.
  static const String exportEmptyHeadline = 'Nothing to export';

  /// Empty export explanation.
  static const String exportEmptyMessage = 'This scope has no records yet.';

  /// Progress: records.
  static const String exportStageRecords = 'Records';

  /// Progress: photos.
  static const String exportStagePhotos = 'Photos';

  /// Progress: reports.
  static const String exportStageReports = 'Reports';

  /// Progress: archive.
  static const String exportStageArchive = 'Archive';

  /// Stops an export and removes partial files.
  static const String exportCancel = 'Cancel';

  /// History page title.
  static const String exportHistoryTitle = 'Export history';

  /// Empty history headline.
  static const String exportHistoryEmpty = 'No exports yet';

  /// Empty history explanation.
  static const String exportHistoryEmptyMessage =
      'A finished export is kept here, with who made it and what it held.';

  /// Shares a recorded file again.
  static const String exportShare = 'Share';

  /// The recorded file is gone.
  static const String exportMissing = 'That file is no longer on this device.';

  /// Offers to run the stored request again.
  static const String exportRerun = 'Run this export again';

  /// Gate: go fix the records.
  static const String exportFixNow = 'Fix now';

  /// Gate: leave the incomplete ones out.
  static const String exportExclude = 'Leave them out';

  /// Gate: export and mark the file incomplete.
  static const String exportAnyway = 'Export anyway';

  /// Stamp written into an incomplete export.
  static const String exportIncompleteStamp = 'Marked incomplete';

  /// Types a replacement for a conflict.
  static const String conflictTypeValue = 'Type a value';

  /// Leaves a conflict unsettled.
  static const String conflictDecideLater = 'Decide later';

  /// Bundle scope section title.
  static const String bundleScope = 'What to include';

  /// The whole project.
  static const String bundleScopeFull = 'Full project';

  /// A date range of records.
  static const String bundleScopeDates = 'Date range';

  /// The current context subtree.
  static const String bundleScopeContext = 'Current context';

  /// Approved records only.
  static const String bundleScopeApproved = 'Approved only';

  /// Records without their photos.
  static const String bundleScopeData = 'Data without photos';

  /// Estimated bundle size.
  static String bundleSize(String label) => 'About $label';

  /// Shares the bundle file.
  static const String bundleShare = 'Share bundle';

  /// Opens a bundle that arrived from outside the app.
  static const String bundleOpen = 'Open bundle';

  /// Merge history title.
  static const String mergeHistoryTitle = 'Merge history';

  /// Empty merge history.
  static const String mergeHistoryEmpty = 'No merges yet';

  /// Empty merge history explanation.
  static const String mergeHistoryEmptyMessage =
      'A merge is kept here with its source, counts and how long undo lasts.';

  /// Undo is still available.
  static String mergeUndoUntil(String when) => 'Undo until $when';

  /// Import page title.
  static const String importTitle = 'Import';

  /// Empty import headline.
  static const String importEmptyHeadline = 'No file yet';

  /// Empty import explanation.
  static const String importEmptyMessage =
      'Choose a bundle, a spreadsheet, a dataset or a template.';

  /// Where a bundle goes.
  static const String importBundleLine =
      'A bundle opens the merge flow, after it is checked.';

  /// Where a dataset goes.
  static const String importDatasetLine =
      'A reference dataset opens the dataset importer.';

  /// Where a template goes.
  static const String importTemplateLine =
      'A template workbook opens template mapping.';

  /// Where a row spreadsheet goes.
  static const String importSheetLine =
      'A spreadsheet asks whether its rows are records or a register.';

  /// Opens the merge flow.
  static const String importOpenBundle = 'Open merge';

  /// Opens the dataset importer.
  static const String importOpenDataset = 'Open dataset';

  /// Opens template mapping.
  static const String importOpenTemplate = 'Open template';

  /// Opens the purpose question.
  static const String importOpenSheet = 'Continue';

  /// A kind this screen does not import.
  static const String importRefused = 'This file cannot be imported';

  /// Purpose page title.
  static const String importPurposeTitle = 'What is this sheet?';

  /// Rows become records.
  static const String importPurposeRecords = 'Records to hold';

  /// Rows feed verification.
  static const String importPurposeRegister = 'Register to verify against';

  /// Mapping page title.
  static const String importMappingTitle = 'Match columns';

  /// A header with no field yet.
  static const String importUnmapped = 'Not matched';

  /// Continues the import.
  static const String importContinue = 'Continue';

  /// Names the identity field that is still unmapped.
  static String importIdentityMissing(String field) =>
      '$field is an identity field and still needs a column.';

  /// Summary page title.
  static const String importSummaryTitle = 'Import summary';

  /// How many rows were created.
  static String importCreated(int count) => '$count created';

  /// How many rows updated a record.
  static String importUpdated(int count) => '$count updated';

  /// How many rows were skipped.
  static String importSkipped(int count) => '$count skipped';

  /// How many rows failed.
  static String importFailed(int count) => '$count failed';

  /// One row and why it was not written.
  static String importRowReason(int row, String reason) => 'Row $row: $reason';

  /// Re-runs only the failed rows.
  static const String importRetry = 'Retry failures';

  /// Writes the skipped and failed rows.
  static const String importExportProblems = 'Export rows to fix';

  /// Match sheet title.
  static const String importMatchTitle = 'This row matches a record';

  /// Leave the existing record unchanged.
  static const String importKeepExisting = 'Keep existing';

  /// Replace the existing record with the row.
  static const String importReplace = 'Replace';

  /// Fill only empty fields from the row.
  static const String importMerge = 'Merge';

  /// Asks whether the choice applies to later matches.
  static const String importApplyToAllTitle = 'Apply to the rest?';

  /// Explains apply-to-all.
  static const String importApplyToAllMessage =
      'Use this choice for every later match in this import.';

  /// Confirms apply-to-all.
  static const String importApplyToAllConfirm = 'Apply to the rest';

  /// Keeps the choice on this row only.
  static const String importApplyToThis = 'Only this row';

  /// Settings row for cloud destinations.
  static const String cloudDestinationsTitle = 'Upload destinations';

  /// Settings row explanation.
  static const String cloudDestinationsSubtitle =
      'Where a finished file can be sent, when you confirm it.';

  /// Destinations page title.
  static const String destinationTitle = 'Upload destinations';

  /// Empty destinations headline.
  static const String destinationEmptyHeadline = 'No destinations yet';

  /// Empty destinations explanation.
  static const String destinationEmptyMessage =
      'Add a bucket, a folder or a drive you sign in to. Nothing is sent until you confirm it.';

  /// Starts adding a destination.
  static const String destinationAdd = 'Add a destination';

  /// Saves a destination after its test succeeds.
  static const String destinationSave = 'Save';

  /// Runs the probe upload.
  static const String destinationTest = 'Test connection';

  /// Removes a destination.
  static const String destinationRemove = 'Remove';

  /// Removal confirm title.
  static const String destinationRemoveTitle = 'Remove this destination?';

  /// Removal confirm explanation.
  static const String destinationRemoveMessage =
      'The destination and its saved sign-in are both deleted.';

  /// Shown when the probe upload fails, so save stays disabled.
  static const String destinationCheckFailed =
      'The connection test did not succeed, so this destination was not saved.';

  /// Label field.
  static const String destinationLabel = 'Name';

  /// Folder field.
  static const String destinationFolder = 'Folder';

  /// Obscured credential field.
  static const String destinationSecret = 'Sign-in';

  /// S3 kind label.
  static const String destinationKindS3 = 'S3 bucket';

  /// Google Drive kind label.
  static const String destinationKindDrive = 'Google Drive';

  /// OneDrive kind label.
  static const String destinationKindOneDrive = 'OneDrive';

  /// Dropbox kind label.
  static const String destinationKindDropbox = 'Dropbox';

  /// WebDAV kind label.
  static const String destinationKindWebDav = 'WebDAV';

  /// Device folder kind label.
  static const String destinationKindLocal = 'Folder on this device';

  /// Confirm sheet title.
  static const String uploadConfirmTitle = 'Send this file?';

  /// Confirm button.
  static const String uploadConfirm = 'Send';

  /// Names the file, its size, the destination and the folder.
  static String uploadConfirmMessage({
    required String name,
    required String size,
    required String destination,
    required String folder,
  }) {
    return '$name ($size) will be sent to $destination, in $folder.';
  }

  /// History page title.
  static const String uploadHistoryTitle = 'Uploads';

  /// Empty history headline.
  static const String uploadHistoryEmptyHeadline = 'No uploads yet';

  /// Empty history explanation.
  static const String uploadHistoryEmptyMessage =
      'A file appears here after you confirm sending it.';

  /// Retries one failed or interrupted upload.
  static const String uploadRetry = 'Retry';

  /// History filter label.
  static const String uploadFilter = 'Destination';

  /// Privacy screen title.
  static const String privacyScreenTitle = 'What leaves this device';

  /// Empty privacy headline.
  static const String privacyEmptyHeadline = 'Nothing is set up to send';

  /// Empty privacy explanation.
  static const String privacyEmptyMessage =
      'Providers and upload destinations appear here when they are added.';

  /// What an extraction call sends.
  static const String egressSendsText = 'Text only';

  /// What an image call sends.
  static const String egressSendsImage = 'An image';

  /// What speech sends.
  static const String egressSendsAudio = 'Audio';

  /// What a cloud upload sends.
  static const String egressSendsFile = 'A file';

  /// Basis written when images stay on the device.
  static const String egressTextOnly =
      'Text only, on-device OCR';

  /// Location section title.
  static const String gpsPrivacyTitle = 'Location';

  /// GPS stays off until this is on.
  static const String gpsPrivacyCapture = 'Save location with captures';

  /// Drops coordinates from exports.
  static const String gpsPrivacyExclude = 'Leave coordinates out of exports';

  /// Removes coordinates already stored.
  static const String gpsPrivacyRemove = 'Remove saved coordinates';

  /// How many records lost their coordinates.
  static String gpsPrivacyRemoved(int count) =>
      '$count records no longer have coordinates.';

  /// Project switch: no online calls.
  static const String aiDisableTitle = 'Manual only';

  /// Explains the manual switch.
  static const String aiDisableMessage =
      'No screen in this project offers an online action.';

  /// Project switch: hold images back.
  static const String imageEgressTitle = 'Keep images on this device';

  /// Explains image hold-back.
  static const String imageEgressMessage =
      'Extraction uses on-device text only.';

  /// Camera permission sentence.
  static const String permissionCamera =
      'Tapture uses the camera when you take a photo.';

  /// Microphone permission sentence.
  static const String permissionMicrophone =
      'Tapture listens when you tap the microphone.';

  /// Location permission sentence.
  static const String permissionLocation =
      'Tapture saves a location only when you turn location on for a project.';

  /// Storage permission sentence.
  static const String permissionStorage =
      'Tapture opens photos and files you choose to import.';

  /// Settings row for privacy.
  static const String privacyTitle = 'Privacy';

  /// Settings row explanation.
  static const String privacySubtitle =
      'What can leave this device, and what never does.';

  /// Settings row for the organisation server.
  static const String backendSettingsTitle = 'Organisation';

  /// Settings row explanation for the server address and grant.
  static const String backendSettingsSubtitle =
      'The server this device is enrolled with.';

  /// Sign-in screen title.
  static const String signInTitle = 'Sign in';

  /// Sign-in action.
  static const String signInAction = 'Sign in';

  /// Email field.
  static const String signInEmail = 'Email';

  /// Password field.
  static const String signInPassword = 'Password';

  /// Organisation field on the sign-in screen.
  static const String signInOrganisation = 'Organisation';

  /// Quiet line when the server cannot be reached.
  static const String backendUnreachable =
      'The server cannot be reached. Work on this device continues.';

  /// Shown when a grant has expired for relay or analysis.
  static const String backendGrantExpired =
      'The saved sign-in has expired for relay, analysis and role changes.';

  /// Sign-out confirmation title.
  static const String signOutTitle = 'Sign out';

  /// Sign-out warning.
  static const String signOutMessage =
      'Signing back in needs a connection to the server.';

  /// Relay control title.
  static const String relayTitle = 'Change relay';

  /// Relay is waiting for a project manager.
  static const String relayOff = 'Relay is off until a project manager enables it.';

  /// A never-relay project has no send action.
  static const String relayNever = 'This project never uses the relay.';

  /// Send action for an enabled relay.
  static const String relaySend = 'Send changes';

  /// Count of packages waiting to send.
  static const String relayQueued = 'Queued';

  /// Count of packages the server accepted.
  static const String relaySent = 'Sent';

  /// Count of packages the server has purged.
  static const String relayPurged = 'Purged';

  /// Trial control that records a problem on this screen.
  static const String frictionLogAction = 'Something went wrong here';
}
