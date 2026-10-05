// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.g.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get ocrBrowserUnavailable =>
      'On-device photo reading is unavailable in this browser. Review fields manually or enable online analysis.';

  @override
  String get notDetected => 'Not detected';

  @override
  String recordsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records',
      one: '1 record',
      zero: 'No records',
    );
    return '$_temp0';
  }

  @override
  String fieldsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fields',
      one: '1 field',
      zero: 'No fields',
    );
    return '$_temp0';
  }

  @override
  String clearField(Object label) {
    return 'Clear $label';
  }

  @override
  String showField(Object label) {
    return 'Show $label';
  }

  @override
  String hideField(Object label) {
    return 'Hide $label';
  }

  @override
  String get photoNoAccess =>
      'Allow the camera or photos to attach one. Everything else still works.';

  @override
  String get displayNoAccess =>
      'Allow screen capture to attach another window. Everything else still works.';

  @override
  String get photoNoCamera => 'No camera is available on this device.';

  @override
  String get photoPickFailed => 'That photo could not be added. Try another.';

  @override
  String get displayCaptureFailed =>
      'That window could not be captured. Try another.';

  @override
  String dictateInto(Object label) {
    return 'Speak into $label';
  }

  @override
  String stopDictating(Object label) {
    return 'Stop speaking into $label';
  }

  @override
  String get dictationUnavailable =>
      'Voice input is not available here. Type instead.';

  @override
  String get dictationNoMicrophone =>
      'Allow the microphone to speak into a field. Typing still works.';

  @override
  String get dictationNothingHeard =>
      'Nothing was heard. Tap the microphone and speak again.';

  @override
  String get dictationNeedsConnection =>
      'Voice input needs a connection on this device. Type instead.';

  @override
  String get dictationOfflineOnly =>
      'You are working offline, and this device cannot recognise speech without a connection. Type instead.';

  @override
  String get dictationFailed =>
      'Voice input stopped. Try again, or type instead.';

  @override
  String get speechUnavailable =>
      'Speech recognition is not available in this version of the app.';

  @override
  String get speechModelMissing =>
      'The speech model is not installed on this device.';

  @override
  String get speechModelMissingRecovery =>
      'Reinstall the app, or import the model in Settings.';

  @override
  String get speechModelDamaged =>
      'The speech model file is damaged, so it was not used.';

  @override
  String get speechModelDamagedRecovery =>
      'Reinstall the app, or import the model again in Settings.';

  @override
  String get speechDeviceUnsupported =>
      'This device cannot run speech recognition.';

  @override
  String get speechLowMemory =>
      'There is not enough free memory to load the speech model.';

  @override
  String get speechLowMemoryRecovery => 'Close other apps, then try again.';

  @override
  String get speechTranscriptionFailed =>
      'Part of the speech could not be turned into text. The audio is kept.';

  @override
  String get speechLanguageUnsupported =>
      'Speech recognition on this device does not support the chosen voice language.';

  @override
  String get speechEngineStopped =>
      'Speech recognition stopped unexpectedly. Try again.';

  @override
  String get speechImportUnknown =>
      'This file is not a speech model the app recognises.';

  @override
  String get speechImportUnknownRecovery =>
      'Choose one of the model files named in Settings.';

  @override
  String get transcriptSaveFailed =>
      'The transcript could not be saved on this device.';

  @override
  String get transcriptSegmentOutOfOrder =>
      'Part of the transcript arrived out of order and was not saved.';

  @override
  String get transcriptStillRecording =>
      'This transcript is still being recorded. Edit it once the recording has finished.';

  @override
  String get autoFilled => 'Auto-filled';

  @override
  String get outOfRange => 'Out of range';

  @override
  String get selectAll => 'Select all';

  @override
  String get clear => 'Clear';

  @override
  String dismissChip(Object label) {
    return 'Dismiss $label';
  }

  @override
  String get dismiss => 'Dismiss';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get unsavedChanges => 'You have unsaved changes.';

  @override
  String get discard => 'Discard';

  @override
  String fixFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fix these fields',
      one: 'Fix this field',
    );
    return '$_temp0';
  }

  @override
  String fieldError(Object label, Object error) {
    return '$label: $error';
  }

  @override
  String fieldLabelRequired(Object label) {
    return '$label (required)';
  }

  @override
  String fieldLabelOptional(Object label) {
    return '$label (optional)';
  }

  @override
  String validationAnnouncement(Object heading, Object errorsjoin) {
    return '$heading. $errorsjoin';
  }

  @override
  String get missingPhoto => 'Missing photo';

  @override
  String get photoSelect => 'Select photo';

  @override
  String get photoUnreadable =>
      'That photo could not be read from this device.';

  @override
  String get photoUnreadableRecovery =>
      'Capture the photo again, then try again.';

  @override
  String missingPhotoNamed(Object type) {
    return 'Missing photo, $type';
  }

  @override
  String get photo => 'Photo';

  @override
  String get photoCrop => 'Crop';

  @override
  String get photoCropCorner => 'Crop corner, drag to resize';

  @override
  String get photoCropFrame => 'Crop frame, drag to move';

  @override
  String get photoRotate => 'Rotate';

  @override
  String get photoDraw => 'Draw';

  @override
  String get photoUndoDraw => 'Undo drawing';

  @override
  String get photoClearDraw => 'Clear drawing';

  @override
  String get markupInk => 'Red';

  @override
  String get markupInkYellow => 'Yellow';

  @override
  String get markupInkWhite => 'White';

  @override
  String get markupInkBlack => 'Black';

  @override
  String get markupInkBlue => 'Blue';

  @override
  String get markupInkGreen => 'Green';

  @override
  String get markupInkLabel => 'Ink';

  @override
  String get markupSize => 'Size';

  @override
  String get markupBacking => 'Dark backing';

  @override
  String get markupBackingDescription =>
      'Keeps the words readable on a busy photo.';

  @override
  String get markupTypeHint => 'Drag the photo to move the words.';

  @override
  String get markupSizeSmall => 'Small';

  @override
  String get markupSizeMedium => 'Medium';

  @override
  String get markupSizeLarge => 'Large';

  @override
  String capturePhotoCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString photos',
      one: '1 photo',
      zero: 'No photos',
    );
    return '$_temp0';
  }

  @override
  String get capturePhotoProcessing => 'Processing';

  @override
  String get photoRevert => 'Revert';

  @override
  String get photoNoCaption => 'No caption yet';

  @override
  String get photoCaptionEdit => 'Edit caption';

  @override
  String get photoCaptionDelete => 'Delete caption';

  @override
  String get photoCaptionDeleteMessage =>
      'The caption is removed from this photo. You can undo it.';

  @override
  String get photoCaptionDeleted => 'Caption deleted.';

  @override
  String get photoTypeOn => 'Type on this photo';

  @override
  String get photoThumbLabel => ', captioned';

  @override
  String get photoThumbLabelSelected => ', selected';

  @override
  String get photoFront => 'Front';

  @override
  String get photoBack => 'Back';

  @override
  String get photoSerial => 'Serial';

  @override
  String get photoRatingPlate => 'Rating plate';

  @override
  String get photoRatingPlateBadge => 'Plate';

  @override
  String get photoDamage => 'Damage';

  @override
  String get photoPanel => 'Panel';

  @override
  String get photoLocation => 'Location';

  @override
  String get photoAttendance => 'Attendance';

  @override
  String get photoAttendanceBadge => 'Attend';

  @override
  String get photoDocument => 'Document';

  @override
  String get photoDocumentBadge => 'Doc';

  @override
  String get photoOther => 'Other';

  @override
  String get stepDone => 'Done';

  @override
  String get stepRunning => 'Running';

  @override
  String get stepWaiting => 'Waiting';

  @override
  String get failed => 'Failed';

  @override
  String progressAnnouncement(Object label, Object state) {
    return '$label, $state';
  }

  @override
  String progressAnnouncementValue(Object label, Object state, Object detail) {
    return '$label, $state, $detail';
  }

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusCaptured => 'Captured';

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusProcessing => 'Processing';

  @override
  String get statusExtracted => 'Extracted';

  @override
  String get statusNeedsReview => 'Needs review';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusArchived => 'Archived';

  @override
  String get statusDeleted => 'Deleted';

  @override
  String get emptyHeadline => 'Nothing here yet';

  @override
  String get emptyMessage =>
      'When there is something to show, it will appear here.';

  @override
  String get loading => 'Loading';

  @override
  String get busy => 'loading';

  @override
  String busyAction(Object label, Object busy) {
    return '$label, $busy';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String get save => 'Save';

  @override
  String get undo => 'Undo';

  @override
  String get galleryTitle => 'Widget gallery';

  @override
  String get galleryTheme => 'Theme';

  @override
  String get galleryWidth => 'Width';

  @override
  String get galleryTextScale => 'Text scale';

  @override
  String get galleryTokens => 'Tokens';

  @override
  String get galleryLayout => 'Layout';

  @override
  String get galleryButtons => 'Buttons';

  @override
  String get galleryFields => 'Fields';

  @override
  String get galleryContainers => 'Containers';

  @override
  String get galleryStates => 'States';

  @override
  String get galleryFeedback => 'Feedback';

  @override
  String get galleryLight => 'Light';

  @override
  String get galleryDark => 'Dark';

  @override
  String get galleryOutdoor => 'Outdoor';

  @override
  String get galleryCompact => 'Compact';

  @override
  String get galleryMedium => 'Medium';

  @override
  String get galleryExpanded => 'Expanded';

  @override
  String get galleryScale100 => '100%';

  @override
  String get galleryScale200 => '200%';

  @override
  String get appName => 'Tapture';

  @override
  String get search => 'Search';

  @override
  String get searchNoMatchMessage => 'Change the search.';

  @override
  String get searchFilters => 'Filters';

  @override
  String searchFiltersFilters(int active) {
    final intl.NumberFormat activeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String activeString = activeNumberFormat.format(active);

    return 'Filters ($activeString)';
  }

  @override
  String get searchClearFilters => 'Clear filters';

  @override
  String get searchFilterNoMatchMessage =>
      'Change the search or clear the filters.';

  @override
  String get overflowMenu => 'More options';

  @override
  String get navProjects => 'Projects';

  @override
  String get projectsEmptyHeadline => 'No projects yet';

  @override
  String get projectsEmptyMessage => 'Create a project to start capturing.';

  @override
  String get projectsCreate => 'Create a project';

  @override
  String get projectsPickHeadline => 'Choose a project';

  @override
  String get projectsPickMessage => 'Select a project from the list.';

  @override
  String get projectsNoMatchHeadline => 'No matching projects';

  @override
  String get projectsNoMatchMessage =>
      'Try a different name, or create a project.';

  @override
  String get projectSearchHint => 'Search projects';

  @override
  String get projectFiltersTitle => 'Project filters';

  @override
  String get projectStatusFilter => 'Status';

  @override
  String get projectPinFilter => 'Pinned state';

  @override
  String get projectPinFilterLabel => 'Pinned';

  @override
  String get projectPinFilterLabelUnpinned => 'Unpinned';

  @override
  String get projectPinFilterLabelAllProjects => 'All projects';

  @override
  String get projectApplyFilters => 'Apply filters';

  @override
  String get pinnedProject => 'Pinned project';

  @override
  String projectTemplateCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString templates attached',
      one: '1 template attached',
      zero: 'No templates attached',
    );
    return '$_temp0';
  }

  @override
  String get projectsImport => 'Import a file';

  @override
  String get projectsDuplicate => 'Duplicate';

  @override
  String get projectAllProjects => 'All projects';

  @override
  String get projectNew => 'New project';

  @override
  String get projectArchive => 'Archive';

  @override
  String get projectUnarchive => 'Unarchive';

  @override
  String get projectDelete => 'Delete project';

  @override
  String get projectDeleteMenu => 'Delete';

  @override
  String projectDeleteTitle(Object name) {
    return 'Delete $name?';
  }

  @override
  String projectDeleteMessage(
    Object recordsCountrecords,
    Object filesCountfiles,
    int days,
  ) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'This hides $recordsCountrecords and $filesCountfiles. You can restore them for $daysString days. Nothing is removed yet.';
  }

  @override
  String filesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files',
      one: '1 file',
      zero: 'no files',
    );
    return '$_temp0';
  }

  @override
  String get projectDeleteTypeName => 'Type the project name';

  @override
  String get projectExportFirst => 'Export first';

  @override
  String get projectShowArchived => 'Show archived';

  @override
  String get projectPin => 'Pin';

  @override
  String get projectUnpin => 'Unpin';

  @override
  String get projectRename => 'Rename';

  @override
  String get projectRenameTitle => 'Rename project';

  @override
  String get projectRenameMessage => 'The folder on disk stays put.';

  @override
  String get projectOpenWith => 'Open with';

  @override
  String get projectDownloadCopy => 'Download a copy';

  @override
  String get projectNothingToOpen =>
      'This project has no spreadsheet, document or PDF to open yet.';

  @override
  String get projectNothingToOpenRecovery =>
      'Import a template workbook or export the project, then try again.';

  @override
  String get projectOpenFailedTitle => 'Could not open the file';

  @override
  String get projectOpenFailed =>
      'Tapture could not hand the file to another app.';

  @override
  String projectOpenFailedNamed(Object fileName) {
    return 'Tapture could not hand $fileName to another app.';
  }

  @override
  String get projectOpenFailedRecovery => 'Free some space, then try again.';

  @override
  String get projectOpenNoApp => 'No app on this device can open that file.';

  @override
  String get projectOpenNoAppRecovery =>
      'Install a reader for this file type, then try again.';

  @override
  String get projectOpenPermission =>
      'Tapture needs storage access to open a copy of this file.';

  @override
  String get projectOpenPermissionRecovery =>
      'Allow storage access, then try again.';

  @override
  String get projectCreateTitle => 'Create project';

  @override
  String get projectDuplicateTitle => 'Duplicate project';

  @override
  String get projectName => 'Name';

  @override
  String get projectDescription => 'Description';

  @override
  String get projectOrganisation => 'Organisation';

  @override
  String get projectEditTitle => 'Project details';

  @override
  String get projectEditFormTitle => 'Edit project';

  @override
  String get projectEditDetails => 'Edit details';

  @override
  String get projectValueNotSet => 'Not set';

  @override
  String get projectCreatedAt => 'Created';

  @override
  String get projectUpdatedAt => 'Last changed';

  @override
  String get contextLevelSource => 'Suggest levels from';

  @override
  String get projectSettingsTitle => 'Project settings';

  @override
  String get projectSaved => 'Project saved';

  @override
  String get projectSettingsSaved => 'Settings saved';

  @override
  String get projectStartsOn => 'Starts';

  @override
  String get projectEndsOn => 'Ends';

  @override
  String get projectStatus => 'Status';

  @override
  String get projectStatusActive => 'Active';

  @override
  String get projectStatusArchived => 'Archived';

  @override
  String get projectAiEnabled => 'AI';

  @override
  String get projectAiEnabledEffect =>
      'Turn off to keep this project fully manual.';

  @override
  String get projectDoNotSendImages => 'Do not send images';

  @override
  String get projectDoNotSendImagesEffect =>
      'Providers never see photo bytes from this project.';

  @override
  String get projectRefineColumns => 'Refined columns';

  @override
  String get projectConfidenceHigh => 'High confidence';

  @override
  String get projectConfidenceMedium => 'Medium confidence';

  @override
  String get projectUseAppDefault => 'Use app default';

  @override
  String get projectOn => 'On';

  @override
  String get projectOff => 'Off';

  @override
  String projectAppDefault(Object value) {
    return 'App default: $value';
  }

  @override
  String get projectEditEmptyHeadline => 'No project open';

  @override
  String get projectEditEmptyMessage => 'Open a project to edit its details.';

  @override
  String get projectSettingsEmptyHeadline => 'No project open';

  @override
  String get projectSettingsEmptyMessage =>
      'Open a project to change its settings.';

  @override
  String projectCopyName(Object name) {
    return '$name (copy)';
  }

  @override
  String projectListSubtitle(
    Object recordsCountrecords,
    Object unprocessedCountunprocessed,
  ) {
    return '$recordsCountrecords · $unprocessedCountunprocessed';
  }

  @override
  String projectRecordPosition(int position) {
    final intl.NumberFormat positionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String positionString = positionNumberFormat.format(position);

    return 'Record $positionString';
  }

  @override
  String get projectRecordsEmptyHeadline => 'No records here';

  @override
  String get projectRecordsEmptyMessage =>
      'Captured records for this filter appear here.';

  @override
  String get projectRecordsSearchHint => 'Search records';

  @override
  String get projectRecordFiltersTitle => 'Record filters';

  @override
  String get projectRecordStatusFilter => 'Status';

  @override
  String get projectRecordsNoMatch => 'No records match.';

  @override
  String projectRecordsNoMatchNoRecordsMatch(Object shown) {
    return 'No records match \"$shown\".';
  }

  @override
  String get choiceNoMatch => 'Nothing matches.';

  @override
  String choiceNoMatchNothingMatches(Object shown) {
    return 'Nothing matches \"$shown\".';
  }

  @override
  String get projectExport => 'Export';

  @override
  String get projectExportTitle => 'Export project';

  @override
  String get projectExportEmptyHeadline => 'Nothing to export';

  @override
  String get projectExportEmptyMessage =>
      'Capture a record before exporting this project.';

  @override
  String get projectExportShare => 'Share';

  @override
  String projectExportSaved(Object fileName) {
    return 'Saved $fileName.';
  }

  @override
  String get projectExportShareHint =>
      'Send the file to email, chat and other apps on this device.';

  @override
  String get exportSectionProject => 'Project';

  @override
  String get exportSectionRecords => 'Records';

  @override
  String get exportSectionTemplates => 'Templates';

  @override
  String get exportSectionFile => 'File';

  @override
  String exportAudioClips(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString audio clips',
      one: '1 audio clip',
      zero: 'No audio clips',
    );
    return '$_temp0';
  }

  @override
  String exportCapturedBetween(Object first) {
    return 'Captured $first';
  }

  @override
  String exportCapturedBetweenCapturedTo(Object first, Object last) {
    return 'Captured $first to $last';
  }

  @override
  String exportUnprocessedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString unprocessed records',
      one: '1 unprocessed record',
      zero: 'No unprocessed records',
    );
    return '$_temp0';
  }

  @override
  String exportNeedsReviewCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records need review',
      one: '1 record needs review',
      zero: 'No records need review',
    );
    return '$_temp0';
  }

  @override
  String exportApprovedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString approved records',
      one: '1 approved record',
      zero: 'No approved records',
    );
    return '$_temp0';
  }

  @override
  String get exportFileFormat => 'Project package (.zip)';

  @override
  String get exportFileColumns =>
      'Everything another Tapture app needs to open this project: records, photos, audio, templates, context, reference data and project settings, with a workbook of the records. Unsaved capture drafts stay on this device.';

  @override
  String exportPackageSize(Object fileSizebytes) {
    return 'About $fileSizebytes';
  }

  @override
  String exportSavedTo(Object place) {
    return 'Saved to $place › Exports';
  }

  @override
  String get projectExportProgress => 'Writing the export';

  @override
  String get projectExportCancel => 'Cancel';

  @override
  String get recordEdit => 'Edit';

  @override
  String get projectPhoto => 'Project photo (optional)';

  @override
  String get projectPhotoAdd => 'Add a photo';

  @override
  String get projectPhotoChange => 'Change photo';

  @override
  String get projectPhotoRemove => 'Remove photo';

  @override
  String get recordEditTitle => 'Edit record';

  @override
  String get recordEditSave => 'Save changes';

  @override
  String get recordEditSaved => 'Record updated.';

  @override
  String get recordEditNoFieldsHeadline => 'No fields to edit';

  @override
  String get recordEditNoFieldsMessage =>
      'Add fields to this record\'s template, then edit the record here.';

  @override
  String get recordDelete => 'Delete';

  @override
  String get recordArchiveMessage =>
      'The photos stay on this device. The record leaves this list.';

  @override
  String get recordDetailTitle => 'Record';

  @override
  String get recordNoCaption => 'No caption';

  @override
  String get recordFieldEmpty => 'Not entered';

  @override
  String get recordSectionFields => 'Fields';

  @override
  String get recordEditFields => 'Edit fields';

  @override
  String recordCapturedAt(Object when) {
    return 'Captured $when';
  }

  @override
  String get recordGoneHeadline => 'This record is no longer here';

  @override
  String get recordGoneMessage =>
      'It was deleted or is not on this device. Go back to the list.';

  @override
  String get continueCapturing => 'Continue capturing';

  @override
  String get captureStart => 'Start capturing';

  @override
  String get captureMore => 'Capture more';

  @override
  String get homeEmptyHeadline => 'No project open';

  @override
  String get homeEmptyMessage => 'Open a project to see what to do next.';

  @override
  String get navCapture => 'Capture';

  @override
  String get navRecords => 'Records';

  @override
  String get navMore => 'Settings';

  @override
  String get navMoreMenu => 'More';

  @override
  String get navTemplates => 'Templates';

  @override
  String get projectTemplatesTitle => 'Project templates';

  @override
  String get navDatasets => 'Datasets';

  @override
  String get datasetsEmptyHeadline => 'No datasets yet';

  @override
  String get datasetsEmptyMessage =>
      'Import a CSV, spreadsheet or JSON table to prefill capture fields.';

  @override
  String get datasetsImport => 'Import dataset';

  @override
  String get datasetsKeyTitle => 'Choose the key column';

  @override
  String get datasetsKeyMessage =>
      'The key uniquely identifies each row for lookup.';

  @override
  String get datasetsAllowDuplicates => 'Save with duplicates';

  @override
  String get datasetsSaveImport => 'Save dataset';

  @override
  String datasetsDuplicateCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString duplicate key values',
      one: '1 duplicate key value',
    );
    return '$_temp0';
  }

  @override
  String datasetsCollidingValues(Object valuesjoin) {
    return 'Examples: $valuesjoin';
  }

  @override
  String datasetListSubtitle(
    Object datasetsRowCountrows,
    Object source,
    Object dateFormatyMMMdformat,
  ) {
    return '$datasetsRowCountrows · $source · $dateFormatyMMMdformat';
  }

  @override
  String datasetsRowCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString rows',
      one: '1 row',
    );
    return '$_temp0';
  }

  @override
  String get datasetSourceLabel => 'CSV';

  @override
  String get datasetSourceLabelSpreadsheet => 'Spreadsheet';

  @override
  String get datasetSourceLabelJSON => 'JSON';

  @override
  String get datasetSourceLabelOnDevice => 'On device';

  @override
  String get datasetsSearchHint => 'Search rows';

  @override
  String get datasetsColumns => 'Columns';

  @override
  String get datasetsEditRow => 'Edit row';

  @override
  String get datasetsSaveRow => 'Save row';

  @override
  String get datasetsAddRow => 'Add row';

  @override
  String get datasetsPickMatch => 'Choose a match';

  @override
  String get datasetsLookupBinding => 'Lookup binding';

  @override
  String get datasetsSaveBinding => 'Save binding';

  @override
  String get datasetsBindingEmptyHeadline => 'No datasets in this project';

  @override
  String get datasetsBindingEmptyMessage =>
      'Import a dataset before binding this field.';

  @override
  String get datasetsFuzzyEnabled => 'Allow fuzzy matches';

  @override
  String get datasetsOnNoMatch => 'When nothing matches';

  @override
  String get datasetsAddedOnDevice => 'Added on device';

  @override
  String get datasetsExport => 'Export';

  @override
  String get datasetsBrowserEmptyHeadline => 'No rows';

  @override
  String get datasetsBrowserEmptyMessage => 'This dataset has no rows to show.';

  @override
  String get datasetsNoMatchHeadline => 'No matching rows';

  @override
  String get datasetsNoMatchMessage =>
      'No row matches that search. Clear it to see every row.';

  @override
  String get datasetsPickNoMatchMessage =>
      'Nothing in this dataset matches. The typed value stays as it is.';

  @override
  String get datasetsClearSearch => 'Clear search';

  @override
  String get datasetsNoProjectHeadline => 'Open a project first';

  @override
  String get datasetsNoProjectMessage =>
      'Datasets belong to a project. Open one to import or browse its tables.';

  @override
  String get datasetsPickHeadline => 'Choose a table to import';

  @override
  String get datasetsPickMessage =>
      'Pick a CSV, spreadsheet or JSON file. You choose its key column next.';

  @override
  String get datasetsPickFile => 'Choose a file';

  @override
  String get datasetsReading => 'Reading the table';

  @override
  String datasetsReadProgress(int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return '$percentString% read';
  }

  @override
  String datasetsColumnSummary(Object count, Object shown) {
    return '$count · $shown';
  }

  @override
  String datasetsDuplicateWarning(Object datasetsCollidingValuescolliding) {
    return ' $datasetsCollidingValuescolliding.';
  }

  @override
  String datasetsDuplicateWarningPickAnotherKeyColumn(
    Object datasetsDuplicateCountn,
    Object values,
  ) {
    return '$datasetsDuplicateCountn.$values Pick another key column, or save the dataset with duplicates.';
  }

  @override
  String get datasetsDuplicatesConfirmTitle => 'Save with duplicate keys?';

  @override
  String datasetsDuplicatesConfirm(
    Object column,
    Object datasetsDuplicateCountn,
  ) {
    return 'The key column $column has $datasetsDuplicateCountn. A lookup on a repeated key asks which row to use.';
  }

  @override
  String get datasetsExportCsv => 'Export as CSV';

  @override
  String get datasetsExportJson => 'Export as JSON';

  @override
  String get datasetsExporting => 'Exporting the dataset';

  @override
  String get datasetsVisibleColumns => 'Columns to show';

  @override
  String get datasetsMissingHeadline => 'Dataset not found';

  @override
  String get datasetsMissingMessage =>
      'This dataset is no longer on this device.';

  @override
  String get datasetsExportNoProject =>
      'Open a project before exporting this dataset.';

  @override
  String get datasetsExportNoProjectRecovery =>
      'Open the project and try again.';

  @override
  String get datasetsRowMissingHeadline => 'Row not found';

  @override
  String get datasetsRowMissingMessage =>
      'This row is no longer in the dataset.';

  @override
  String get datasetsAddRowNoDatasetHeadline => 'No dataset bound';

  @override
  String get datasetsAddRowNoDatasetMessage =>
      'Bind this field to a dataset before adding rows from capture.';

  @override
  String lookupUnknownTarget(Object target) {
    return 'Unknown fill target \"$target\".';
  }

  @override
  String lookupTargetTwice(Object target) {
    return 'Fill target \"$target\" is mapped more than once.';
  }

  @override
  String get lookupPickDataset => 'Pick a dataset before saving the binding.';

  @override
  String get lookupImportRecovery =>
      'Fix the lookup fills in the template file and import it again.';

  @override
  String lookupColumnTwice(Object column) {
    return 'Column \"$column\" is chosen for two fields. Pick one field for it.';
  }

  @override
  String lookupThresholdLabel(int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return '$percentString%';
  }

  @override
  String get lookupKeyColumn => 'Key column';

  @override
  String get lookupMatchColumns => 'Match on';

  @override
  String get lookupMatchOrder => 'The key column only';

  @override
  String get lookupNotFilled => 'Not filled';

  @override
  String get lookupFills => 'Fill these fields';

  @override
  String get lookupFuzzyThreshold => 'Suggest matches scoring at least';

  @override
  String get lookupBecomesLookup => 'Saving makes this field a lookup field.';

  @override
  String get lookupFieldMissingHeadline => 'Field not found';

  @override
  String get lookupFieldMissingMessage =>
      'This field is no longer on the template.';

  @override
  String get lookupNoMatchLeaveEmpty => 'Leave empty';

  @override
  String get lookupNoMatchPromptAdd => 'Offer to add a row';

  @override
  String get lookupNoMatchWarn => 'Warn';

  @override
  String get templatesBindDataset => 'Bind to dataset';

  @override
  String get templatesEmptyHeadline => 'No templates yet';

  @override
  String get templatesEmptyMessage =>
      'Pick a shipped template to start capturing, or create a blank template.';

  @override
  String get templatesPickLibrary => 'Pick a shipped template';

  @override
  String get templatesCreate => 'Create a blank template';

  @override
  String get templatesEdit => 'Edit';

  @override
  String get templatesAddChoices => 'Add templates';

  @override
  String get templatesAddMore => 'Add more templates';

  @override
  String get templatesAddEmptyMessage =>
      'Add templates to start capturing. Create a blank template when none fits.';

  @override
  String get templatesUpload => 'Upload a template';

  @override
  String get templatesUseExisting => 'Use an existing template';

  @override
  String get templatesNoMatch => 'No matching templates';

  @override
  String get templateFiltersTitle => 'Template filters';

  @override
  String get templateKindFilter => 'Kind';

  @override
  String get templateKindNone => 'No kind';

  @override
  String get fieldsNoMatch => 'No matching fields';

  @override
  String get fieldFiltersTitle => 'Field filters';

  @override
  String get fieldRequirednessFilter => 'Requirement';

  @override
  String get templateChoiceLabel => 'Template choice';

  @override
  String get templateChoiceAuto => 'Auto';

  @override
  String get templateChoiceSuggest => 'Suggest';

  @override
  String get templateChoiceManual => 'Manual';

  @override
  String get templatesCreateTitle => 'New template';

  @override
  String get templatesOpen => 'Open';

  @override
  String get templatesExport => 'Export template';

  @override
  String get templatesImport => 'Import template';

  @override
  String get templatesImportEmptyHeadline => 'No template file';

  @override
  String get templatesImportEmptyMessage =>
      'Choose a template file to add it to this project.';

  @override
  String get templatesImportUnknownSchema =>
      'That template file uses a schema this app does not read.';

  @override
  String get templatesImportUnknownSchemaRecovery =>
      'Export the template again from this version of Tapture.';

  @override
  String get templatesImportInvalid => 'That file is not a template.';

  @override
  String get templatesImportInvalidRecovery =>
      'Choose a template file and try again.';

  @override
  String get templatesImportDuplicateField =>
      'Each field key must be unique on a template.';

  @override
  String get templatesImportDuplicateFieldRecovery =>
      'Rename the duplicate key and export again.';

  @override
  String get workbookPassword => 'That spreadsheet is locked with a password.';

  @override
  String get workbookPasswordRecovery =>
      'Unlock it, save a copy, and choose the copy.';

  @override
  String get workbookCorrupt => 'That spreadsheet could not be read.';

  @override
  String get workbookCorruptRecovery =>
      'Keep the original. Export a copy and try again.';

  @override
  String get xlsxMappingTitle => 'Map columns';

  @override
  String get xlsxMappingEmptyHeadline => 'No spreadsheet';

  @override
  String get xlsxMappingEmptyMessage =>
      'Choose a spreadsheet to map its columns onto a template.';

  @override
  String get xlsxMappingConfirm => 'Create template';

  @override
  String get xlsxMappingSkip => 'Skip this column';

  @override
  String get xlsxMappingInclude => 'Include this column';

  @override
  String get xlsxMappingSkipped => 'Skipped';

  @override
  String xlsxMappingProposal(Object field, Object type, Object rule) {
    return '$field · $type · $rule';
  }

  @override
  String xlsxMappingUntitled(Object column) {
    return 'Column $column';
  }

  @override
  String get xlsxMappingDefaultName => 'Spreadsheet';

  @override
  String get xlsxMappingMissing =>
      'That spreadsheet is no longer on this device.';

  @override
  String get xlsxMappingMissingRecovery =>
      'Choose the spreadsheet again, then try again.';

  @override
  String get xlsxMappingExists =>
      'A copy of that spreadsheet is already in this project.';

  @override
  String get xlsxMappingExistsRecovery =>
      'Rename the spreadsheet, then try again.';

  @override
  String get rowAliasesTitle => 'Row aliases';

  @override
  String get rowAliasesEmptyHeadline => 'No rows to name';

  @override
  String get rowAliasesEmptyMessage =>
      'Import spreadsheet rows first, then add the local names that should match them.';

  @override
  String get rowAliasesField => 'Aliases';

  @override
  String get rowAliasesHint => 'BP machine, BP';

  @override
  String get rowAliasesImport => 'Import from a column';

  @override
  String get rowAliasesColumn => 'Alias column';

  @override
  String get rowAliasesInvalidColumn =>
      'That column is not in the spreadsheet.';

  @override
  String get rowAliasesInvalidColumnRecovery =>
      'Enter a column letter shown in the spreadsheet.';

  @override
  String get rowAliasesNone => 'No aliases yet';

  @override
  String get checklistTitle => 'Checklist';

  @override
  String get checklistIdentifierColumn => 'Identifier column';

  @override
  String get checklistLabelColumn => 'Label column';

  @override
  String get checklistContextColumn => 'Context column';

  @override
  String get checklistImportRows => 'Import rows';

  @override
  String get checklistMappingIncomplete =>
      'Choose an identifier and a label column.';

  @override
  String get checklistMappingRecovery =>
      'Confirm both columns before importing the rows.';

  @override
  String get checklistEmptyHeadline => 'Nothing on the checklist';

  @override
  String get checklistEmptyMessage =>
      'Import spreadsheet rows to see what is still missing.';

  @override
  String get checklistFound => 'Found';

  @override
  String get checklistMissing => 'Missing';

  @override
  String get checklistUngrouped => 'Ungrouped';

  @override
  String checklistProgress(Object group, int found, int total) {
    final intl.NumberFormat foundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String foundString = foundNumberFormat.format(found);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$group · Found $foundString of $totalString';
  }

  @override
  String get detectionProfileTitle => 'Detection';

  @override
  String get detectionProfileExplain =>
      'A photo is matched to this template from these signals. A negative keyword rules it out.';

  @override
  String get detectionProfileEmptyHeadline => 'No template to configure';

  @override
  String get detectionProfileEmptyMessage =>
      'Open a template first, then set how a photo is matched to it.';

  @override
  String get detectionProfileClasses => 'Object classes';

  @override
  String get detectionProfileKeywords => 'Keywords';

  @override
  String get detectionProfilePatterns => 'Identifier patterns';

  @override
  String get detectionProfileDatasets => 'Linked datasets';

  @override
  String get detectionProfileNegative => 'Negative keywords';

  @override
  String get detectionProfileHint => 'Separate with a comma';

  @override
  String get detectionProfileNoPatterns =>
      'Identifier patterns come from field validation. Add a pattern on a field first.';

  @override
  String get detectionProfileNoDatasets =>
      'Linked datasets come from lookup fields. Bind a lookup first.';

  @override
  String get detectionProfileMissing =>
      'That template is no longer on this device.';

  @override
  String get detectionProfileMissingRecovery =>
      'Open the template list and try again.';

  @override
  String get templatesDelete => 'Delete template';

  @override
  String templatesDeleteTitle(Object name) {
    return 'Delete $name?';
  }

  @override
  String templatesDeleteMessage(
    Object fieldsCountfields,
    Object recordsCountrecords,
  ) {
    return 'This hides $fieldsCountfields. $recordsCountrecords stay on this template.';
  }

  @override
  String get templateFieldsTitle => 'Fields';

  @override
  String get templatesAddField => 'Add a field';

  @override
  String templateFieldRowTitle(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Field $nString';
  }

  @override
  String get templateFieldRowRemove => 'Remove this field';

  @override
  String get templatesEditField => 'Edit field';

  @override
  String get templatesDeleteField => 'Delete field';

  @override
  String templatesDeleteFieldTitle(Object label) {
    return 'Delete $label?';
  }

  @override
  String templatesDeleteFieldMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countString records hold a value. Those values stay and export as retired.',
      one: '1 record holds a value. That value stays and exports as retired.',
      zero:
          'No records hold a value. The field leaves this template. Existing values stay and export as retired.',
    );
    return '$_temp0';
  }

  @override
  String get templatesFieldsEmptyHeadline => 'No fields yet';

  @override
  String get templatesFieldsEmptyMessage =>
      'Add a field so this template can capture.';

  @override
  String get fieldRequired => 'Required';

  @override
  String get fieldCalculated => 'Calculated';

  @override
  String get fieldFromPhotos => 'From photos';

  @override
  String fieldRowSubtitle(Object contextLevel) {
    return 'Context level $contextLevel';
  }

  @override
  String get fieldRowSubtitlePinnedContext => 'Pinned context';

  @override
  String fieldRowDefault(Object value) {
    return 'Default: $value';
  }

  @override
  String get fieldRecommended => 'Recommended';

  @override
  String get fieldOptional => 'Optional';

  @override
  String fieldMoveUp(Object label) {
    return 'Move $label up';
  }

  @override
  String fieldMoveDown(Object label) {
    return 'Move $label down';
  }

  @override
  String fieldReorder(Object label) {
    return 'Reorder $label';
  }

  @override
  String get fieldTypeLabel => 'Text';

  @override
  String get fieldTypeLabelLongText => 'Long text';

  @override
  String get fieldTypeLabelNumber => 'Number';

  @override
  String get fieldTypeLabelDecimal => 'Decimal';

  @override
  String get fieldTypeLabelCurrency => 'Currency';

  @override
  String get fieldTypeLabelPercentage => 'Percentage';

  @override
  String get fieldTypeLabelDate => 'Date';

  @override
  String get fieldTypeLabelTime => 'Time';

  @override
  String get fieldTypeLabelDateAndTime => 'Date and time';

  @override
  String get fieldTypeLabelBoolean => 'Boolean';

  @override
  String get fieldTypeLabelChoice => 'Choice';

  @override
  String get fieldTypeLabelMultiChoice => 'Multi-choice';

  @override
  String get fieldTypeLabelLookup => 'Lookup';

  @override
  String get fieldTypeLabelBarcode => 'Barcode';

  @override
  String get fieldTypeLabelPhotoReference => 'Photo reference';

  @override
  String get fieldTypeLabelDocumentReference => 'Document reference';

  @override
  String get fieldTypeLabelGPSLocation => 'GPS location';

  @override
  String get fieldTypeLabelSignature => 'Signature';

  @override
  String get fieldTypeLabelComputed => 'Computed';

  @override
  String get fieldLabel => 'Label';

  @override
  String get fieldType => 'Type';

  @override
  String get fieldRequiredness => 'Required?';

  @override
  String get fieldAdvanced => 'Advanced';

  @override
  String get fieldAdvancedShow => 'Show advanced';

  @override
  String get fieldAdvancedHide => 'Hide advanced';

  @override
  String get fieldKeepAnyway => 'Keep anyway';

  @override
  String get fieldTwoFactsWarning =>
      'This label packs two facts. Split it into two fields, or keep this one anyway.';

  @override
  String get fieldDefaultValue => 'Default value';

  @override
  String get fieldUnit => 'Unit';

  @override
  String get fieldHelp => 'Help';

  @override
  String get fieldInputMode => 'Who may fill it';

  @override
  String get fieldInputAny => 'Anyone';

  @override
  String get fieldInputManual => 'A person only';

  @override
  String get fieldInputAi => 'AI may propose';

  @override
  String get fieldInputAuto => 'Filled by the app';

  @override
  String get fieldStickable => 'Pin as context';

  @override
  String get fieldContextLevel => 'Context level';

  @override
  String get fieldAutoFill => 'Fill automatically';

  @override
  String get fieldAutoFillNone => 'Do not fill';

  @override
  String get fieldAutoFillLabel => 'Now';

  @override
  String get fieldAutoFillLabelToday => 'Today';

  @override
  String get fieldAutoFillLabelTimeOfDay => 'Time of day';

  @override
  String get fieldAutoFillLabelNextInSequence => 'Next in sequence';

  @override
  String get fieldAutoFillLabelSignedInOperator => 'Signed-in operator';

  @override
  String get fieldAutoFillLabelThisDevice => 'This device';

  @override
  String get fieldAutoFillLabelCurrentLocation => 'Current location';

  @override
  String get fieldAutoFillLabelPinnedContext => 'Pinned context';

  @override
  String get fieldRefine => 'Store a refined companion';

  @override
  String get fieldIdentity => 'Use for duplicates';

  @override
  String get fieldRequiredWhen => 'Required when';

  @override
  String fieldRequiredWhenPreview(Object reading) {
    return 'Required when $reading';
  }

  @override
  String get fieldHidden => 'Hide from capture and export';

  @override
  String get fieldHiddenHelp => 'Values already captured stay on the record.';

  @override
  String get fieldValidationTitle => 'Validation';

  @override
  String get fieldValidationEmptyHeadline => 'No validation yet';

  @override
  String get fieldValidationEmptyMessage =>
      'Add a pattern, length, range or required-with rule.';

  @override
  String get fieldPattern => 'Pattern';

  @override
  String get fieldPatternNone => 'None';

  @override
  String get fieldPatternSerial => 'Serial';

  @override
  String get fieldPatternAssetTag => 'Asset tag';

  @override
  String get fieldPatternRegistration => 'Registration';

  @override
  String get fieldPatternCustom => 'Custom';

  @override
  String get fieldPatternTest => 'Try a value';

  @override
  String get fieldPatternTestPass => 'That value is allowed.';

  @override
  String get fieldMinLength => 'Shortest';

  @override
  String get fieldMaxLength => 'Longest';

  @override
  String get fieldRangeMin => 'Lowest';

  @override
  String get fieldRangeMax => 'Highest';

  @override
  String get fieldRequiredWith => 'Required with';

  @override
  String get fieldOptionsTitle => 'Choices';

  @override
  String get fieldOptionsEmptyHeadline => 'No choices yet';

  @override
  String get fieldOptionsEmptyMessage =>
      'Add a choice so capture has something to pick.';

  @override
  String get fieldOptionLabel => 'Choice name';

  @override
  String get fieldOptionAdd => 'Add a choice';

  @override
  String get fieldOptionRetire => 'Retire choice';

  @override
  String get fieldOptionRetired => 'Retired';

  @override
  String get fieldAddEmptyHeadline => 'No template to edit';

  @override
  String get fieldAddEmptyMessage =>
      'Open the template list and pick a template first.';

  @override
  String get requiredColumnsTitle => 'Required columns';

  @override
  String get requiredColumnsEmptyHeadline => 'No columns to set';

  @override
  String get requiredColumnsEmptyMessage =>
      'Add a field first, then choose what this project insists on.';

  @override
  String get requiredColumnHide => 'Hide';

  @override
  String get requiredColumnShowGroup => 'Show group';

  @override
  String get requiredColumnHideGroup => 'Hide group';

  @override
  String get requiredColumnUngrouped => 'Fields';

  @override
  String requiredColumnRadios(Object label) {
    return 'Required? · $label';
  }

  @override
  String requiredColumnCell(Object label, Object mark) {
    return '$label, $mark';
  }

  @override
  String requiredColumnShipped(Object mark) {
    return 'Shipped as $mark';
  }

  @override
  String requiredColumnGroup(Object group) {
    return 'templates.groups.$group.$group';
  }

  @override
  String get identityFieldsTitle => 'Identity fields';

  @override
  String get identityFieldsExplain =>
      'These fields decide whether two records are the same thing.';

  @override
  String get identityFieldsEmptyHeadline => 'No fields to mark';

  @override
  String get identityFieldsEmptyMessage =>
      'Add a field first, then choose which ones identify a record.';

  @override
  String get outputMappingTitle => 'Output columns';

  @override
  String get outputMappingEmptyHeadline => 'No columns to map';

  @override
  String get outputMappingEmptyMessage =>
      'Add a field first, then choose where each one writes.';

  @override
  String get outputMappingDuplicate =>
      'Two fields cannot write to the same column.';

  @override
  String get outputMappingDuplicateRecovery =>
      'Give each field its own column, then save.';

  @override
  String get outputMappingBuiltHint =>
      'Headers are generated from the field labels. You can change them.';

  @override
  String get outputMappingImportedHint =>
      'These letters came from the workbook. You can change them.';

  @override
  String get templateMigrationTitle => 'Move records';

  @override
  String get templateMigrationExplain =>
      'Records stay on the version they were captured under until you move them.';

  @override
  String get templateMigrationEmptyHeadline => 'Nothing to move';

  @override
  String get templateMigrationEmptyMessage =>
      'Every record is already on this template version.';

  @override
  String get templateMigrationAdded => 'Added fields';

  @override
  String get templateMigrationRemoved => 'Removed fields';

  @override
  String get templateMigrationRetyped => 'Retyped fields';

  @override
  String get templateMigrationConfirmTitle => 'Move these records?';

  @override
  String templateMigrationConfirm(Object recordsCountrecords) {
    return 'This moves $recordsCountrecords to the new version in one step. Values of removed fields are kept and retired.';
  }

  @override
  String templateMigrationBehind(Object recordsCountrecords) {
    return '$recordsCountrecords on an earlier version';
  }

  @override
  String templateMigrationUnresolved(Object recordsCountrecords) {
    return '$recordsCountrecords were captured under a version this device no longer has. Their values for fields not on the current template are listed under Values that will retire.';
  }

  @override
  String get templateMigrationRetiring => 'Values that will retire';

  @override
  String get templateMigrationAction => 'Move records';

  @override
  String templateCopyName(Object name) {
    return '$name (copy)';
  }

  @override
  String templateListSubtitle(
    Object fieldsCountfields,
    Object recordsCountrecords,
  ) {
    return '$fieldsCountfields · $recordsCountrecords';
  }

  @override
  String get templatesLibraryTitle => 'Shipped templates';

  @override
  String get templatesLibraryEmptyHeadline => 'No shipped templates';

  @override
  String get templatesLibraryEmptyMessage =>
      'Create a blank template to start capturing.';

  @override
  String get templatesAdd => 'Add to this project';

  @override
  String get templatesAddToProject => 'Add to project';

  @override
  String get templatesCustomCopy => 'Create a custom copy';

  @override
  String get shippedAddedToProject => 'Added to this project';

  @override
  String get shippedLibrarySearchHint => 'Search or describe your work';

  @override
  String shippedAreaTitle(Object code, Object title) {
    return '$code · $title';
  }

  @override
  String shippedCatalogueCategoryTitle(Object code, Object title) {
    return '$code — $title';
  }

  @override
  String shippedCategoryHeading(
    Object shippedCatalogueCategoryTitlecodetitle,
    int count,
  ) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$shippedCatalogueCategoryTitlecodetitle · $countString';
  }

  @override
  String shippedCatalogueSubtitle(
    Object code,
    Object recordType,
    Object fieldsCountfields,
  ) {
    return '$code · $recordType · $fieldsCountfields';
  }

  @override
  String get shippedFiltersTitle => 'Library filters';

  @override
  String get shippedAreaFilter => 'Area';

  @override
  String get shippedRecordTypeFilter => 'Record type';

  @override
  String get shippedTierFilter => 'Tier';

  @override
  String get shippedTierLabel => 'Foundation';

  @override
  String get shippedTierLabelExpansion => 'Expansion';

  @override
  String get shippedTierLabelSpecialist => 'Specialist';

  @override
  String get shippedPrivacyLabel => 'Internal';

  @override
  String get shippedPrivacyLabelConfidential => 'Confidential';

  @override
  String get shippedPrivacyLabelRestricted => 'Restricted';

  @override
  String get shippedCategoryLabel => 'Category';

  @override
  String get shippedRecordTypeLabel => 'Record type';

  @override
  String get shippedPrivacyTierLabel => 'Suggested privacy and tier';

  @override
  String shippedPrivacyTier(
    Object shippedPrivacyLabelprivacy,
    Object shippedTierLabelrollout,
  ) {
    return '$shippedPrivacyLabelprivacy · $shippedTierLabelrollout';
  }

  @override
  String get shippedCaptureLabel => 'Capture';

  @override
  String get shippedAiAssistanceLabel => 'AI assistance';

  @override
  String get shippedOutputsLabel => 'Outputs';

  @override
  String get shippedReviewLabel => 'Review';

  @override
  String shippedFieldSubtitle(Object fieldTypeLabeltype, Object requiredness) {
    return '$fieldTypeLabeltype · $requiredness';
  }

  @override
  String get shippedLibraryNoMatch => 'No templates match.';

  @override
  String shippedLibraryNoMatchNoTemplatesMatch(Object shown) {
    return 'No templates match \"$shown\".';
  }

  @override
  String get shippedLabel => 'item_';

  @override
  String shippedLabelValue(Object wordsindex) {
    return ' $wordsindex';
  }

  @override
  String shippedLabelValue2(Object text0toUpperCase, Object textsubstring1) {
    return '$text0toUpperCase$textsubstring1';
  }

  @override
  String get navQueue => 'Unprocessed';

  @override
  String get navExports => 'Exports';

  @override
  String get operatorNameUse =>
      'Used on every record you capture from this device.';

  @override
  String get operatorName => 'Name';

  @override
  String get operatorProfileTitle => 'Operator';

  @override
  String get operatorInitials => 'Initials';

  @override
  String get operatorContact => 'Contact';

  @override
  String get operatorEmail => 'Email';

  @override
  String get operatorPhone => 'Phone';

  @override
  String get nameRequired => 'Enter a name';

  @override
  String get emailNeedsAt => 'Include an @ in the email';

  @override
  String get initialsLength => 'Use one to three characters';

  @override
  String get statusNoProject => 'No project';

  @override
  String get statusNoContext => 'No context';

  @override
  String get contextHierarchyTitle => 'Project contexts';

  @override
  String get contextHierarchyEmptyHeadline => 'No context levels';

  @override
  String get contextHierarchyEmptyMessage =>
      'Add field keys from a template to build a hierarchy, or leave none.';

  @override
  String get contextAddLevel => 'Add level';

  @override
  String contextLevelRow(int level, Object fieldKey) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Level $levelString · $fieldKey';
  }

  @override
  String get contextUseTemplateLevels => 'Use template levels';

  @override
  String get contextTemplateFailureHeadline => 'Template levels could not load';

  @override
  String get contextTemplateFailureMessage =>
      'Try again. Your saved context has not changed.';

  @override
  String get contextNoTemplatesHeadline => 'No project templates';

  @override
  String get contextNoTemplatesMessage =>
      'Attach or create a template before choosing context fields.';

  @override
  String get contextOpenTemplates => 'Add templates';

  @override
  String get contextNoDeclaredLevelsHeadline => 'No template levels declared';

  @override
  String get contextNoDeclaredLevelsMessage =>
      'Set a positive context level on template fields, or add levels manually.';

  @override
  String get contextNoEligibleFieldsHeadline => 'No fields available';

  @override
  String get contextNoEligibleFieldsMessage =>
      'Every template field is already used as a context level.';

  @override
  String get contextTemplateConflictHeadline => 'Template levels conflict';

  @override
  String contextTemplateConflictMessage(Object conflicts) {
    return 'Resolve these declarations in Templates: $conflicts.';
  }

  @override
  String get contextSaveHierarchy => 'Save levels';

  @override
  String contextPickerTitle(Object label) {
    return 'Set $label';
  }

  @override
  String get contextRecents => 'Recent';

  @override
  String get contextDatasetSearch => 'From dataset';

  @override
  String get contextUseValue => 'Use this value';

  @override
  String get contextTypeValue => 'Type a value';

  @override
  String get contextValueNotSet => 'Not set';

  @override
  String get contextClearPin => 'Clear pin';

  @override
  String contextPinnedValue(Object field, Object value) {
    return '$field: $value';
  }

  @override
  String get contextPinnedTitle => 'Pinned fields';

  @override
  String get contextPinnedEmptyHeadline => 'No pinnable context fields';

  @override
  String get contextPinnedEmptyMessage =>
      'Mark fields as pinned context on a template to reuse them during capture.';

  @override
  String get contextMarkPinnable => 'Mark a field as pinnable';

  @override
  String get contextPinnedRelevance =>
      'Pinned context is reused on each new record until you change it.';

  @override
  String get contextCascadeTitle => 'Clear lower levels?';

  @override
  String contextCascadeMessage(
    Object levelLabel,
    Object newValue,
    Object andnamed,
  ) {
    return 'Change $levelLabel to $newValue? $andnamed will be cleared.';
  }

  @override
  String get contextCascadeConfirm => 'Clear and continue';

  @override
  String get contextPresetsTitle => 'Context presets';

  @override
  String get contextPresetsEmptyHeadline => 'No presets yet';

  @override
  String get contextPresetsEmptyMessage =>
      'Save the current context, then apply the preset in one tap.';

  @override
  String get contextPresetSave => 'Save preset';

  @override
  String get contextPresetApply => 'Apply preset';

  @override
  String get contextPresetsChip => 'Presets';

  @override
  String get contextPresetsHint =>
      'Save the current values, or switch rooms in one tap.';

  @override
  String get contextPresetName => 'Preset name';

  @override
  String contextPresetApplied(Object name) {
    return 'Switched to $name.';
  }

  @override
  String contextPresetSaved(Object name) {
    return 'Saved preset $name.';
  }

  @override
  String get contextPresetDelete => 'Delete preset';

  @override
  String contextPresetDeleteMessage(Object name) {
    return 'Delete $name? Values already set stay as they are.';
  }

  @override
  String get contextPresetDeleteReason => 'Deleted from the list.';

  @override
  String get contextPresetOverwriteTitle => 'Replace preset?';

  @override
  String get contextPresetOverwriteMessage =>
      'A preset with that name already exists. Replace it?';

  @override
  String get contextPresetReplace => 'Replace';

  @override
  String get contextAutoClearUndo => 'Undo';

  @override
  String contextAutoClearMessage(Object label) {
    return 'Cleared $label after idle.';
  }

  @override
  String get contextMovementTitle => 'Confirm context';

  @override
  String get contextMovementMessage =>
      'You have moved. Is the current context still correct?';

  @override
  String get contextMovementChange => 'Change context';

  @override
  String get contextPinMarker => 'Pinned';

  @override
  String contextSetLevel(Object level) {
    return 'Set $level';
  }

  @override
  String contextLevelValue(Object level, Object value) {
    return '$level: $value';
  }

  @override
  String get contextManage => 'Manage';

  @override
  String get contextSetUp => 'Set up context';

  @override
  String get contextRemoveLevel => 'Remove level';

  @override
  String contextDragLevel(Object level) {
    return 'Drag $level to reorder';
  }

  @override
  String get settingsContextAutoClear => 'Clear the lowest level when idle';

  @override
  String get settingsContextAutoClearEffect =>
      'Off until you turn it on. Clears only the lowest level, and you can undo.';

  @override
  String settingsContextIdleSubtitle(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'After $minutesString minutes with no change.';
  }

  @override
  String get settingsContextMovement => 'Confirm context after movement';

  @override
  String get settingsContextMovementEffect =>
      'Off until you turn it on. Asks you to confirm. It does not change context. Needs GPS and location already allowed.';

  @override
  String settingsContextDistanceSubtitle(int metres) {
    final intl.NumberFormat metresNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String metresString = metresNumberFormat.format(metres);

    return 'After $metresString metres.';
  }

  @override
  String get settingsContextIdle => 'Clear context after';

  @override
  String get settingsContextIdleEffect =>
      'How long with no change before the lowest level clears.';

  @override
  String settingsContextIdleOption(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get settingsContextDistance => 'Ask when I move';

  @override
  String get settingsContextDistanceEffect =>
      'How far you move before Tapture asks you to confirm the context.';

  @override
  String settingsContextDistanceOption(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString metres',
      one: '1 metre',
    );
    return '$_temp0';
  }

  @override
  String get captureTitle => 'Capture';

  @override
  String get captureSaveAndAnalyse => 'Save and process';

  @override
  String get captureProcessNeedsNetwork =>
      'Save raw now. Process it once this device is online.';

  @override
  String get captureSaveRaw => 'Save raw';

  @override
  String get captureNoPhotosHeadline => 'No photos yet';

  @override
  String get captureNoPhotosMessage =>
      'Add a photo, import a file, or type a caption to start.';

  @override
  String get captureProjectLabel => 'Project';

  @override
  String get captureChooseProject => 'Choose a project to start capturing.';

  @override
  String get captureCreateProjectFirst => 'Create a project before capturing.';

  @override
  String get captureNoProjectMessage =>
      'Every photo and record is filed under a project.';

  @override
  String get captureNeedsTemplate => 'Add a template before capturing.';

  @override
  String get captureMoreFields => 'More fields';

  @override
  String get captureCameraReason =>
      'Tapture needs the camera to photograph equipment and documents.';

  @override
  String get captureOpenCameraSettings => 'Open settings';

  @override
  String get captureAllowCamera => 'Allow camera';

  @override
  String get captureCameraTitle => 'Camera';

  @override
  String get captureKeepPhoto => 'Keep';

  @override
  String get captureRetakePhoto => 'Retake';

  @override
  String get captureDocumentMode => 'Document mode';

  @override
  String get capturePageBoundaryFound =>
      'Page edge found. A straightened copy is ready.';

  @override
  String get captureUseCorrected => 'Use corrected';

  @override
  String get captureCorrectionFailed =>
      'The page could not be straightened. The original is kept.';

  @override
  String get captureNoPageBoundary =>
      'No page edge found. Captured as a normal photo.';

  @override
  String get captureFlashOff => 'Flash off';

  @override
  String get captureFlashAuto => 'Flash auto';

  @override
  String get captureFlashOn => 'Flash on';

  @override
  String get captureGrid => 'Grid';

  @override
  String get captureFocus => 'Focus';

  @override
  String get captureZoomOut => 'Zoom out';

  @override
  String get captureZoomIn => 'Zoom in';

  @override
  String get captureImportGallery => 'Import photos';

  @override
  String get captureImportDocument => 'Import document';

  @override
  String get captureDocumentsUnavailable =>
      'Documents are not available on this device.';

  @override
  String get captureDocumentsUnavailableRecovery =>
      'Try again after reopening the app.';

  @override
  String get tryAnotherFile => 'Try another file';

  @override
  String get pdfInvalid => 'That PDF could not be read.';

  @override
  String captureDocumentInvalid(Object filename) {
    return 'The contents of $filename could not be read.';
  }

  @override
  String get pdfPageMissing => 'That page is not in the document.';

  @override
  String get pdfPreviousPage => 'Previous page';

  @override
  String get pdfNextPage => 'Next page';

  @override
  String get barcodeUnavailable =>
      'Barcode scanning is not available on this device.';

  @override
  String get barcodeAllowCamera =>
      'Allow the camera in settings to scan, or type the code.';

  @override
  String get barcodeConfirm => 'Use this code';

  @override
  String get barcodeRescan => 'Scan again';

  @override
  String get barcodeNoCode => 'Point at a barcode';

  @override
  String get barcodeTitle => 'Scan a code';

  @override
  String get barcodeTorch => 'Torch';

  @override
  String get barcodeUnreadable => 'That code could not be read.';

  @override
  String barcodeScanCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Scanned $nString';
  }

  @override
  String barcodeCountPosition(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Scan $nString';
  }

  @override
  String get barcodeCountMode => 'Count items';

  @override
  String get barcodeUndoLast => 'Undo last';

  @override
  String get identifierMatchRecord => 'Open record';

  @override
  String get identifierMatchReference => 'Use reference';

  @override
  String get identifierNewRecord => 'New record';

  @override
  String get identifierDuplicates => 'Several matches';

  @override
  String get captureRecordCaption => 'Caption';

  @override
  String get capturePhotosSection => 'Photos';

  @override
  String get captureAudioSection => 'Audio';

  @override
  String get captureRemovePhoto => 'Remove photo';

  @override
  String captionAddToAll(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add to all $countString photos',
      one: 'Add to the photo',
    );
    return '$_temp0';
  }

  @override
  String captionAddToTicked(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add to $countString ticked photos',
      one: 'Add to 1 ticked photo',
    );
    return '$_temp0';
  }

  @override
  String captionAdded(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added to $countString photos',
      one: 'Added to the photo',
    );
    return '$_temp0';
  }

  @override
  String get captionAppend => 'Append';

  @override
  String get captionReplace => 'Replace';

  @override
  String get captureMicReason =>
      'Tapture needs the microphone for spoken notes on an explicit tap.';

  @override
  String get captureListening => 'Listening…';

  @override
  String get captureRecordAudio => 'Record audio';

  @override
  String get captureRecordTranscribe => 'Record and transcribe';

  @override
  String get capturePauseAudio => 'Pause';

  @override
  String get captureStopAudio => 'Stop';

  @override
  String get audioRecorderUnavailable =>
      'Audio recording is not available on this device.';

  @override
  String get microphoneBusy =>
      'The microphone is in use by another recording. Stop it first, then try again.';

  @override
  String get audioStartFailed => 'Recording could not start.';

  @override
  String get audioStartFailedRecovery =>
      'Try again. Nothing already captured was lost.';

  @override
  String get audioTakeLimitReached =>
      'This recording reached the longest take this browser can keep. Everything captured so far is kept.';

  @override
  String get audioTakeLimitReachedRecovery =>
      'Stop this recording, then start a new one to continue.';

  @override
  String get audioPathOutsideStorage =>
      'The recording must be saved inside the project folder.';

  @override
  String get audioPermissionDenied => 'Microphone permission was not granted.';

  @override
  String get audioPermissionRecovery =>
      'Allow microphone access in system settings, then try again.';

  @override
  String get audioRecorderStatus => 'Requesting microphone permission';

  @override
  String get audioRecorderStatusRecording => 'Recording';

  @override
  String get audioRecorderStatusPaused => 'Paused';

  @override
  String get audioRecorderStatusSavingAudio => 'Saving audio';

  @override
  String get audioRecorderStatusAudioFailed => 'Audio failed';

  @override
  String get audioRecorderStatusAudioSaved => 'Audio saved';

  @override
  String get audioRecorderStatusAudioReady => 'Audio ready';

  @override
  String get liveTranscriptStart => 'Start recording';

  @override
  String get liveTranscriptCancel => 'Discard';

  @override
  String get liveTranscriptStatusStarting => 'Opening the microphone';

  @override
  String get liveTranscriptStatusListening => 'Recording and transcribing';

  @override
  String get liveTranscriptStatusPaused => 'Paused';

  @override
  String get liveTranscriptStatusFinishing => 'Finishing the transcript';

  @override
  String get liveTranscriptEmpty => 'Speak, and the words appear here.';

  @override
  String get liveTranscriptJumpToLatest => 'Jump to latest';

  @override
  String get transcriptViewLabel => 'Transcript';

  @override
  String get liveTranscriptStatusDraining => 'Saved. Finishing the transcript.';

  @override
  String get liveTranscriptStatusSaved => 'Saved on this device';

  @override
  String get liveTranscriptStatusPausedBackground =>
      'Paused while Tapture was in the background. Everything so far is saved.';

  @override
  String get liveTranscriptStatusPausedInterruption =>
      'Paused by another app or a call.';

  @override
  String get liveTranscriptMicLost =>
      'The microphone was turned off. What was recorded is saved.';

  @override
  String get liveTranscriptPermissionRevoked =>
      'Microphone access was turned off. What was recorded is saved. Allow access to go on, or stop to keep it.';

  @override
  String get liveTranscriptRetrySave => 'Try saving again';

  @override
  String get liveTranscriptOpen => 'Open transcript';

  @override
  String get liveTranscriptCancelTitle => 'Discard this recording?';

  @override
  String get liveTranscriptCancelMessage =>
      'It is not added here. The audio file stays in the project folder.';

  @override
  String get liveTranscriptAudioOnly =>
      'Recording without a live transcript: no speech model is available.';

  @override
  String liveTranscriptBehind(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'The transcript is $minutesString minutes behind. Recording goes on.',
      one: 'The transcript is 1 minute behind. Recording goes on.',
      zero: 'The transcript is catching up. Recording goes on.',
    );
    return '$_temp0';
  }

  @override
  String get liveTranscriptUtteranceSkipped =>
      'A part could not be transcribed. Its audio is kept.';

  @override
  String get liveTranscriptUnsaved =>
      'The transcript could not be saved yet. The recording is kept, and saving is tried again.';

  @override
  String get liveTranscriptSessionLimit =>
      'The recording reached the longest length allowed and was saved.';

  @override
  String get liveTranscriptStorageStop =>
      'Storage is full, so recording stopped. What was recorded is saved.';

  @override
  String get liveTranscriptStorageLow =>
      'Storage is running low. Recording goes on.';

  @override
  String get liveTranscriptListTitle => 'Transcripts';

  @override
  String get liveTranscriptUntitled => 'Untitled transcript';

  @override
  String liveTranscriptRowWhen(Object when) {
    return 'Recorded $when';
  }

  @override
  String liveTranscriptRowDetail(Object when, Object preview) {
    return '$when · $preview';
  }

  @override
  String get liveTranscriptEdited => 'Edited';

  @override
  String get liveTranscriptInterrupted => 'Interrupted';

  @override
  String get liveTranscriptRecording => 'Recording';

  @override
  String get speechOfflineBadge => 'On this device';

  @override
  String get liveTranscriptUnavailable =>
      'Live transcription needs a speech model on this device.';

  @override
  String get liveTranscriptUnavailableRecovery =>
      'Open Settings, Language, to check the speech model.';

  @override
  String get navTranscripts => 'Transcripts';

  @override
  String get transcriptsTitle => 'Transcripts';

  @override
  String get transcriptsNew => 'New transcription';

  @override
  String get transcriptsEmptyHeadline => 'No transcripts yet';

  @override
  String get transcriptsEmptyMessage =>
      'Record speech and Tapture writes it down on this device. No connection is needed.';

  @override
  String get transcriptsNoMatchHeadline => 'No matching transcripts';

  @override
  String get transcriptsSearchHint => 'Search transcripts';

  @override
  String get transcriptsNoProject => 'Open a project to transcribe';

  @override
  String get transcriptsNoProjectMessage =>
      'Recordings and transcripts are saved in the project folder.';

  @override
  String get transcribeTitle => 'Transcribe';

  @override
  String get transcriptDetailTitle => 'Transcript';

  @override
  String get transcriptMissing => 'This transcript is not on this device';

  @override
  String get transcriptMissingMessage =>
      'It was discarded, or it belongs to a project that is not here.';

  @override
  String get transcriptOriginCapture => 'From a capture';

  @override
  String get transcriptOriginMeeting => 'From a meeting';

  @override
  String get transcriptOriginStandalone => 'Transcription';

  @override
  String get transcriptStatusInterrupted =>
      'Interrupted. What was heard is kept.';

  @override
  String get transcriptEditedLabel => 'Edited text';

  @override
  String get transcriptOriginalLabel => 'Original, as heard';

  @override
  String get transcriptSaveEdit => 'Save changes';

  @override
  String get transcriptEditSaved =>
      'Changes saved. The original transcript is kept.';

  @override
  String get transcriptRevert => 'Go back to the original';

  @override
  String get transcriptRevertTitle => 'Go back to the original transcript?';

  @override
  String get transcriptRevertMessage =>
      'Your changes are removed. The original stays as it was recorded.';

  @override
  String get transcriptRevertConfirm => 'Use original';

  @override
  String get transcriptReverted => 'The original transcript is back.';

  @override
  String get transcriptRename => 'Rename';

  @override
  String get transcriptTitleLabel => 'Title';

  @override
  String transcriptLanguage(Object language) {
    return 'Language: $language';
  }

  @override
  String transcriptModel(Object model) {
    return 'Speech model: $model';
  }

  @override
  String transcriptAudioLength(Object minutes, Object seconds) {
    return 'Recording $minutes:$seconds';
  }

  @override
  String get transcriptNoAudio => 'The recording was not kept on this device.';

  @override
  String transcriptGaps(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString parts of the recording are not transcribed yet.',
      one: 'One part of the recording is not transcribed yet.',
      zero: 'All of the recording is transcribed.',
    );
    return '$_temp0';
  }

  @override
  String get transcriptFinish => 'Finish the transcript';

  @override
  String get transcriptFinished => 'The transcript is finished.';

  @override
  String get transcriptTranscribeOnDevice => 'Transcribe on this device';

  @override
  String get captureAudioScopeTitle => 'Use audio with';

  @override
  String get captureAudioCurrentPhoto => 'Current photo';

  @override
  String captureAudioSelectedPhotos(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Selected photos ($countString)';
  }

  @override
  String captureAudioAllPhotos(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'All photos ($countString)';
  }

  @override
  String captureAudioCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString audio clips attached',
      one: '1 audio clip attached',
    );
    return '$_temp0';
  }

  @override
  String get captureDeletePhotoTitle => 'Delete this photo?';

  @override
  String get captureDeletePhotoMessage =>
      'It leaves the tray now. The file stays until the retention purge so you can undo.';

  @override
  String get captureUndoDelete => 'Undo';

  @override
  String get capturePhotoDeleted => 'Photo deleted';

  @override
  String get captureMovePhotos => 'Move';

  @override
  String get captureRecoveryTitle => 'Resume capture?';

  @override
  String captureRecoveryMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'An interrupted session has $countString photos.',
      one: 'An interrupted session has 1 photo.',
      zero: 'An interrupted session has no photos yet.',
    );
    return '$_temp0';
  }

  @override
  String get captureResume => 'Resume';

  @override
  String get captureDiscard => 'Discard';

  @override
  String get captureSessionDiscarded =>
      'Session discarded. Its photos stay recoverable.';

  @override
  String get captureRapidMode => 'Rapid mode';

  @override
  String captureRapidItem(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'Item $numberString';
  }

  @override
  String captureRapidSummary(Object photosCountphotos, Object caption) {
    return '$photosCountphotos · $caption';
  }

  @override
  String get captureRapidNext => 'Save and next item';

  @override
  String captureRapidProcessAll(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Process all ($countString)';
  }

  @override
  String captureRapidQueued(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString items queued for processing',
      one: '1 item queued for processing',
    );
    return '$_temp0';
  }

  @override
  String get captureRapidEmptyHeadline => 'No items yet';

  @override
  String get captureRapidEmptyMessage =>
      'Take photos of the first item, then save it to start the next.';

  @override
  String captureRapidCurrent(Object photosCountphotos) {
    return 'This item: $photosCountphotos';
  }

  @override
  String captureStorageLow(Object free) {
    return 'Space is getting low: $free left. Capture carries on.';
  }

  @override
  String captureStorageFull(Object free) {
    return 'Only $free left, not enough for a new photo. Export a project or clean the cache to make room.';
  }

  @override
  String get captureStorageExport => 'Export';

  @override
  String get captureNoTemplates =>
      'This project has no templates yet. You can capture now and add one later.';

  @override
  String get capturePickTemplate => 'Template';

  @override
  String get capturePinSession => 'Pin for session';

  @override
  String get captureTemplatePinned =>
      'This template is now used here every time.';

  @override
  String get capturePinContext => 'Pin for context';

  @override
  String captureSelectedCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Selected $nString';
  }

  @override
  String get captureSelectAll => 'Select all';

  @override
  String get captureClearSelection => 'Clear';

  @override
  String get captureAddPhoto => 'Add photo';

  @override
  String get captureAddSheetTitle => 'Add a photo';

  @override
  String get captureTakePhoto => 'Take a photo';

  @override
  String get captureChoosePhoto => 'Choose from this device';

  @override
  String get captureQualityBlur => 'This photo looks blurry.';

  @override
  String get captureQualityDark => 'This photo looks dark.';

  @override
  String get captureQualityBright => 'This photo looks overexposed.';

  @override
  String get captureQualitySmallText => 'Small text may be hard to read.';

  @override
  String get captureSaved => 'Saved';

  @override
  String get captureSaving => 'Saving';

  @override
  String get captureSaveFailed => 'Save failed';

  @override
  String get captureEnqueueFailed =>
      'The capture was saved, but processing could not be queued.';

  @override
  String get captureNeedsEvidence =>
      'Add at least one photo or a caption before saving.';

  @override
  String get captureNeedsEvidenceRecovery => 'Add evidence, then try again.';

  @override
  String get captureOrderIncomplete => 'The photo order is incomplete.';

  @override
  String get captureOrderIncompleteRecovery =>
      'Keep every photo in the tray and try again.';

  @override
  String get captureChangeNotSaved => 'That change could not be saved.';

  @override
  String get captureChangeNotSavedRecovery =>
      'Try again. Nothing already captured was lost.';

  @override
  String get captureRecordsUnavailable =>
      'Saved records cannot be edited on this device.';

  @override
  String get captureRecordsUnavailableRecovery =>
      'Open the record on a device that stores records.';

  @override
  String get statusNoTemplate => 'No template';

  @override
  String statusWhere(Object project, Object context) {
    return '$project · $context';
  }

  @override
  String get networkOnline => 'Online';

  @override
  String get networkMetered => 'Metered';

  @override
  String get networkOffline => 'Offline';

  @override
  String get networkOfflineByChoice => 'Offline by choice';

  @override
  String get settingsOfflineTitle => 'Stay offline';

  @override
  String get settingsOfflineEffect => 'Everything still works except sending.';

  @override
  String unprocessedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString unprocessed',
      one: '1 unprocessed',
      zero: '0 unprocessed',
    );
    return '$_temp0';
  }

  @override
  String get offlineWorking => 'You are offline. Captures stay on this device.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get workStillOnDevice => 'Your work is still on this device.';

  @override
  String get restart => 'Restart';

  @override
  String get exportLog => 'Export log';

  @override
  String get openRecycleBin => 'Recycle bin';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String notFoundMessage(Object path) {
    return 'The page \"$path\" is not in Tapture.';
  }

  @override
  String get notFoundRecovery => 'Try again to go back to Projects.';

  @override
  String get appNameDev => 'Tapture Dev';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGroupProfileCapture => 'Profile and capture';

  @override
  String get settingsGroupIntelligenceAppearance =>
      'Intelligence and appearance';

  @override
  String get settingsGroupStorageSecurity => 'Storage and security';

  @override
  String get settingsGroupAbout => 'About';

  @override
  String get settingsOperatorSubtitle =>
      'Name, initials and contact on this device.';

  @override
  String get settingsCaptureSubtitle =>
      'Camera, dates, location and how new files are named.';

  @override
  String get settingsCaptureTitle => 'Capture defaults';

  @override
  String get settingsRelaySubtitle =>
      'Send changes between this project\'s devices.';

  @override
  String get settingsAiTitle => 'AI';

  @override
  String get settingsAiSubtitle => 'When and how proposals run.';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'App and voice.';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsAppLanguageEffect =>
      'English. Screens and messages use this language.';

  @override
  String get settingsVoiceLanguage => 'Voice language';

  @override
  String get settingsSpeechSection => 'Speech recognition';

  @override
  String settingsSpeechEngineWhisper(Object model) {
    return 'Speech is turned into text on this device by the $model.';
  }

  @override
  String get settingsSpeechEnginePlatform =>
      'Speech is turned into text by this device’s own speech service, on the device only.';

  @override
  String get settingsSpeechEngineNone =>
      'Voice input is not available on this device yet.';

  @override
  String get settingsSpeechQuality => 'Transcription quality';

  @override
  String get settingsSpeechQualityEffect =>
      'Automatic picks the best model this device can run smoothly.';

  @override
  String get settingsSpeechQualityAuto => 'Automatic';

  @override
  String get settingsSpeechQualityFast => 'Faster, uses less battery';

  @override
  String get settingsSpeechQualityAccurate =>
      'More accurate, needs a stronger device';

  @override
  String get settingsSpeechModels => 'Speech models';

  @override
  String get settingsSpeechModelFast => 'Fast model';

  @override
  String get settingsSpeechModelBalanced => 'Balanced model';

  @override
  String get settingsSpeechModelAccurate => 'Accurate model';

  @override
  String get settingsSpeechModelVad => 'Voice detector';

  @override
  String get settingsSpeechModelBundled => 'Included with the app';

  @override
  String get settingsSpeechModelImported => 'Imported';

  @override
  String get settingsSpeechModelImportOnly => 'Import only';

  @override
  String get settingsSpeechModelPresent => 'Installed';

  @override
  String get settingsSpeechModelVerified => 'Checked';

  @override
  String get settingsSpeechModelMissing => 'Missing';

  @override
  String get settingsSpeechModelDamaged => 'Damaged';

  @override
  String get settingsSpeechModelInUse => 'In use';

  @override
  String settingsSpeechModelDetail(Object origin, Object state, Object size) {
    return '$origin · $state · $size';
  }

  @override
  String get settingsSpeechTooLarge =>
      'Too large for the memory this device has free. A smaller model is used.';

  @override
  String get settingsSpeechVerify => 'Verify';

  @override
  String settingsSpeechVerified(Object model) {
    return 'The $model matches its published file.';
  }

  @override
  String settingsSpeechVerifyMismatch(Object model) {
    return 'The $model does not match its published file. Import it again or reinstall the app.';
  }

  @override
  String get settingsSpeechImport => 'Import a speech model';

  @override
  String settingsSpeechImported(Object model) {
    return 'The $model was checked and added.';
  }

  @override
  String get settingsSpeechRemove => 'Remove';

  @override
  String settingsSpeechRemoveTitle(Object model) {
    return 'Remove the $model?';
  }

  @override
  String get settingsSpeechRemoveMessage =>
      'Its file is deleted from this device. Speech uses a smaller model until you import it again.';

  @override
  String settingsSpeechRemoved(Object model) {
    return 'The $model was removed.';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'French';

  @override
  String get languageSwahili => 'Swahili';

  @override
  String get languagePortuguese => 'Portuguese';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsAppearanceSubtitle => 'System, light, dark or outdoor.';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeOutdoor => 'Outdoor';

  @override
  String get settingsStorageTitle => 'Storage';

  @override
  String get settingsStorageSubtitle =>
      'Space used, cache and how long files stay.';

  @override
  String get settingsFilesTitle => 'Files';

  @override
  String get settingsFilesSubtitle => 'Import, export, uploads and merges.';

  @override
  String get settingsFilesExportSubtitle =>
      'Save the open project as a package or spreadsheet.';

  @override
  String get settingsFilesImportSubtitle =>
      'Bring in a project package or a spreadsheet.';

  @override
  String get settingsFilesMergeSubtitle =>
      'Combine a package from another device into the open project.';

  @override
  String get settingsFilesNoProject =>
      'Open a project to export it or merge into it.';

  @override
  String get settingsFilesUploadsSubtitle =>
      'What was sent to each destination.';

  @override
  String get settingsSecurityTitle => 'Security';

  @override
  String get settingsSecuritySubtitle => 'App lock and export encryption.';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsAboutSubtitle => 'Version and licences.';

  @override
  String get settingsTemplatesSubtitle =>
      'Create, import and edit this project\'s templates.';

  @override
  String get settingsQueueSubtitle => 'Records waiting to be processed.';

  @override
  String get settingsCamera => 'Camera';

  @override
  String get settingsCameraEffect => 'Used at the start of the next session.';

  @override
  String get settingsCameraPhoto => 'Photo';

  @override
  String get settingsCameraDocument => 'Document';

  @override
  String get settingsAutoFillDates => 'Fill dates automatically';

  @override
  String get settingsAutoFillDatesEffect =>
      'New captures get today without asking.';

  @override
  String get settingsGps => 'GPS';

  @override
  String get settingsGpsWhyOff =>
      'Off until you turn it on, so a location is never stored by accident.';

  @override
  String get settingsPhotoQuality => 'Photo quality';

  @override
  String get settingsPhotoQualityEffect => 'Higher quality makes larger files.';

  @override
  String get settingsQualityStandard => 'Standard';

  @override
  String get settingsQualitySmaller => 'Smaller files';

  @override
  String get settingsFolderStrategy => 'Photo folders';

  @override
  String get settingsFolderStrategyNewFilesOnly =>
      'Applies to new files only. Existing files stay put.';

  @override
  String get settingsFolderByContext => 'By context';

  @override
  String get settingsFolderByTemplate => 'By template';

  @override
  String get settingsFolderByDate => 'By date';

  @override
  String get settingsFolderFlat => 'One folder';

  @override
  String get settingsNamingPattern => 'File names';

  @override
  String get settingsNamingEdit => 'File name pattern';

  @override
  String get settingsNamingPatternEffect => 'How a new photo file is named.';

  @override
  String settingsCameraSubtitle(Object label, Object settingsCameraEffect) {
    return '$label. $settingsCameraEffect';
  }

  @override
  String settingsPhotoQualitySubtitle(
    Object label,
    Object settingsPhotoQualityEffect,
  ) {
    return '$label. $settingsPhotoQualityEffect';
  }

  @override
  String settingsNamingSubtitle(
    Object pattern,
    Object settingsNamingPatternEffect,
  ) {
    return '$pattern. $settingsNamingPatternEffect';
  }

  @override
  String settingsFolderStrategySubtitle(
    Object strategy,
    Object settingsFolderStrategyNewFilesOnly,
  ) {
    return '$strategy. $settingsFolderStrategyNewFilesOnly';
  }

  @override
  String get settingsProjectsHeader => 'Projects';

  @override
  String get settingsHeadroomHeader => 'Free space';

  @override
  String get settingsRetentionHeader => 'Retention';

  @override
  String get settingsStorageRoot => 'Storage folder';

  @override
  String get settingsStorageRootAfterRestart =>
      'Saved. Tapture uses the new folder the next time it opens.';

  @override
  String get settingsVolumeTotal => 'Total';

  @override
  String get settingsVolumeUsed => 'Used';

  @override
  String get settingsVolumeAvailable => 'Available';

  @override
  String settingsVolumeFigures(
    Object settingsVolumeTotal,
    Object total,
    Object settingsVolumeUsed,
    Object used,
    Object settingsVolumeAvailable,
    Object available,
  ) {
    return '$settingsVolumeTotal $total · $settingsVolumeUsed $used · $settingsVolumeAvailable $available';
  }

  @override
  String get settingsHeadroomAmple => 'Plenty of space';

  @override
  String get settingsHeadroomLow => 'Space is getting low';

  @override
  String get settingsHeadroomCritical => 'Not enough space for a new photo';

  @override
  String get settingsClearCache => 'Clear cache';

  @override
  String get settingsClearCacheEffect =>
      'Removes derived copies only. Originals stay.';

  @override
  String settingsCacheSize(
    Object settingsCache,
    Object size,
    Object settingsClearCacheEffect,
  ) {
    return '$settingsCache · $size. $settingsClearCacheEffect';
  }

  @override
  String settingsRetentionSubtitle(
    Object settingsRetentionDaysdays,
    Object settingsRetentionEffect,
  ) {
    return '$settingsRetentionDaysdays. $settingsRetentionEffect';
  }

  @override
  String get settingsClearCacheTitle => 'Clear the cache?';

  @override
  String get settingsClearCacheMessage =>
      'Thumbnails and upload copies will be removed. Original photos stay.';

  @override
  String get storageCheckTitle => 'Check files';

  @override
  String get storageCheckSubtitle =>
      'Find files with no record and records whose file is gone. Nothing is deleted.';

  @override
  String get storageCheckDatabaseHeader => 'Records and references';

  @override
  String get storageCheckDatabaseClean =>
      'Every record, value and file reference is whole.';

  @override
  String storageCheckFindingRow(Object table, Object id) {
    return '$table · $id';
  }

  @override
  String storageCheckProjectHeader(Object project) {
    return 'Files in $project';
  }

  @override
  String get storageCheckNoProject => 'Open a project to check its files.';

  @override
  String get storageCheckFilesClean =>
      'Every file has its record, and every record has its file.';

  @override
  String get storageCheckFilesUnavailable =>
      'This device keeps no project folder, so its files can\'t be checked.';

  @override
  String get storageCheckFilesUnavailableAction =>
      'Check the files on the phone, tablet or computer that took them.';

  @override
  String get storageCheckStrayHeader => 'Files with no record';

  @override
  String storageCheckStraySubtitle(Object size) {
    return '$size · Tap to attach it to a record.';
  }

  @override
  String get storageCheckMissingHeader => 'Records whose file is gone';

  @override
  String get storageCheckMissingSubtitle =>
      'Tap to mark the file as missing. The record stays.';

  @override
  String get storageCheckFlagTitle => 'Mark the file as missing?';

  @override
  String get storageCheckFlagMessage =>
      'The record and its other evidence stay. Its history notes that this file is gone.';

  @override
  String get storageCheckFlagConfirm => 'Mark as missing';

  @override
  String get storageCheckFlagged => 'Marked as missing.';

  @override
  String get storageCheckAttachTitle => 'Attach to a record';

  @override
  String get storageCheckAttached => 'File attached to the record.';

  @override
  String get storageCheckNoRecords => 'No records yet';

  @override
  String get storageCheckNoRecordsMessage =>
      'Capture a record in this project, then attach the file to it.';

  @override
  String get settingsRetention => 'Keep deleted files';

  @override
  String get settingsRetentionEffect =>
      'How long a deleted file can be restored.';

  @override
  String settingsRetentionDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String get settingsDocuments => 'Documents';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsExports => 'Exports';

  @override
  String get settingsCache => 'Cache';

  @override
  String get settingsStorageEmptyHeadline => 'No project folders yet';

  @override
  String get settingsStorageEmptyMessage =>
      'Space used appears here once a project has files.';

  @override
  String fileSize(int bytes) {
    final intl.NumberFormat bytesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bytesString = bytesNumberFormat.format(bytes);

    return '$bytesString B';
  }

  @override
  String fileSizeKB(Object byteskround) {
    return '$byteskround KB';
  }

  @override
  String fileSizeMB(Object byteskk) {
    return '$byteskk MB';
  }

  @override
  String fileSizeGB(Object byteskk) {
    return '$byteskk GB';
  }

  @override
  String settingsProjectUse(
    Object photos,
    Object settingsDocuments,
    Object documents,
    Object settingsAudio,
    Object audio,
    Object settingsExports,
    Object exports,
  ) {
    return 'Photos $photos · $settingsDocuments $documents · $settingsAudio $audio · $settingsExports $exports';
  }

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsBuild => 'Build';

  @override
  String get settingsLicences => 'Licences';

  @override
  String get settingsLicencesEffect => 'Open-source licences used in this app.';

  @override
  String get settingsPlanLink => 'Development plan';

  @override
  String get settingsSpecLink => 'Specification';

  @override
  String get settingsLinkCopied =>
      'Link copied. Paste it into a browser to open it.';

  @override
  String get settingsEmptyHeadline => 'No settings yet';

  @override
  String get settingsEmptyMessage =>
      'Settings for this device will appear here.';

  @override
  String get settingsCaptureEmptyHeadline => 'No capture defaults yet';

  @override
  String get settingsCaptureEmptyMessage =>
      'Camera, dates and GPS will appear here.';

  @override
  String get settingsAboutEmptyHeadline => 'No version yet';

  @override
  String get settingsAboutEmptyMessage =>
      'The version and licences will appear here.';

  @override
  String get appLockUnlockTitle => 'Unlock Tapture';

  @override
  String get appLockTitle => 'App lock';

  @override
  String get appLockPin => 'PIN';

  @override
  String get appLockCurrentPin => 'Current PIN';

  @override
  String get appLockNewPin => 'New PIN';

  @override
  String get appLockConfirmPin => 'Confirm PIN';

  @override
  String get appLockSet => 'Set PIN';

  @override
  String get appLockChange => 'Change PIN';

  @override
  String get appLockRemove => 'Remove PIN';

  @override
  String get appLockUnlock => 'Unlock';

  @override
  String get appLockBiometrics => 'Unlock with this device';

  @override
  String get appLockSetEffect =>
      'Required the next time the app opens or returns.';

  @override
  String get appLockRemoveEffect => 'The next open will not ask for a PIN.';

  @override
  String get appLockRemoveConfirmTitle => 'Remove the PIN?';

  @override
  String get appLockCurrentPinHelper => 'Needed to change or remove the PIN.';

  @override
  String get appLockRemoveNeedsPin => 'Enter your current PIN, then remove it.';

  @override
  String get appLockOn => 'App lock is on.';

  @override
  String get appLockOff =>
      'App lock is off. Set a PIN to require it on launch and resume.';

  @override
  String get appLockPinLength => 'Use 4 to 8 digits.';

  @override
  String get appLockPinMismatch => 'The two PINs do not match.';

  @override
  String get appLockWrongPin => 'That PIN does not match.';

  @override
  String get appLockRecovery =>
      'Nobody can reset this PIN. Your files stay on this device. Nothing here deletes them.';

  @override
  String get close => 'Close';

  @override
  String get feedback => 'Feedback';

  @override
  String get feedbackButtonHint =>
      'Opens the feedback options. Drag to move it.';

  @override
  String get feedbackGive => 'Give us feedback';

  @override
  String get feedbackDownload => 'Download feedback';

  @override
  String get feedbackDelete => 'Delete feedback';

  @override
  String get feedbackStaysOnDevice =>
      'Saved on this device only. Nothing is sent anywhere.';

  @override
  String get feedbackCategoryGeneral => 'General';

  @override
  String get feedbackCategoryImprovement => 'Improvement';

  @override
  String get feedbackCategoryError => 'Error';

  @override
  String get feedbackCategorySuggestion => 'Suggestion';

  @override
  String get feedbackCategoryOther => 'Other';

  @override
  String get feedbackSubmitterSignedIn => 'Signed-in user';

  @override
  String get feedbackSubmitterLocal => 'Local operator';

  @override
  String get feedbackSubmitterAnonymous => 'Anonymous';

  @override
  String get feedbackDeviceMobile => 'Mobile';

  @override
  String get feedbackDeviceTablet => 'Tablet';

  @override
  String get feedbackDeviceDesktop => 'Desktop';

  @override
  String get feedbackType => 'Type of feedback';

  @override
  String get feedbackOtherType => 'What kind of feedback is it?';

  @override
  String get feedbackOtherRequired => 'Say what kind of feedback it is';

  @override
  String get feedbackMessage => 'Your feedback';

  @override
  String get feedbackMessageHint =>
      'What happened, or what would make this better?';

  @override
  String get feedbackMessageRequired => 'Write your feedback';

  @override
  String get feedbackAttachScreenshot => 'Attach screenshot';

  @override
  String get feedbackContinue => 'Continue feedback';

  @override
  String get feedbackAddScreen => 'Screenshot current screen';

  @override
  String get feedbackIncludeUi => 'Include feedback UI';

  @override
  String get feedbackAddWindow => 'Screenshot external window';

  @override
  String get feedbackStopSharing => 'Stop sharing window';

  @override
  String get feedbackSharingWindow =>
      'Sharing a window. Each tap adds a screenshot.';

  @override
  String get feedbackOtherWindow => 'External window';

  @override
  String get feedbackTakePhoto => 'Take a photo';

  @override
  String get feedbackChoosePhoto => 'Choose photos';

  @override
  String get feedbackShotTipScreens =>
      'Another screen: tap Continue later, open it, then tap Screenshot current screen in the bar.';

  @override
  String get feedbackShotTipApps =>
      'Another app: take a screenshot with your device, then add it with Choose photos.';

  @override
  String feedbackAttachImages(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Attach $countString images',
      one: 'Attach 1 image',
    );
    return '$_temp0';
  }

  @override
  String feedbackImageCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString images',
      one: '1 image',
    );
    return '$_temp0';
  }

  @override
  String get feedbackShotPreview => 'Photo preview';

  @override
  String get feedbackDiscardDraft => 'Discard draft';

  @override
  String get feedbackDiscardDraftTitle => 'Discard this feedback?';

  @override
  String feedbackDiscardDraftMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This feedback and its $countString images will be cleared.',
      one: 'This feedback and its 1 image will be cleared.',
      zero: 'This feedback will be cleared.',
    );
    return '$_temp0';
  }

  @override
  String get feedbackContinueLater => 'Continue later';

  @override
  String get feedbackDraftBarHint =>
      'Opens the feedback you started. Keep typing or speaking here.';

  @override
  String feedbackShotAdded(Object screen) {
    return 'Added a screenshot of $screen';
  }

  @override
  String get feedbackShotsFull => 'Remove a photo before adding another.';

  @override
  String feedbackScreenshotOf(Object screen) {
    return 'Screenshot of $screen';
  }

  @override
  String get feedbackNoScreenshot => 'No images yet';

  @override
  String get feedbackScreenshotPreview => 'Screenshot preview';

  @override
  String get feedbackSave => 'Save feedback';

  @override
  String get feedbackSaved => 'Feedback saved on this device.';

  @override
  String get feedbackTypes => 'Types';

  @override
  String get feedbackFrom => 'Submitted from';

  @override
  String get feedbackTo => 'Submitted to';

  @override
  String get feedbackRangeBackwards =>
      'The start is after the end. Swap them or clear one.';

  @override
  String get feedbackScreens => 'Screens';

  @override
  String get feedbackPlatforms => 'Platforms';

  @override
  String get feedbackDeviceTypes => 'Device types';

  @override
  String get feedbackSubmittedBy => 'Submitted by';

  @override
  String get feedbackScreenshot => 'Screenshot';

  @override
  String get feedbackScreenshotAny => 'Any';

  @override
  String get feedbackScreenshotWith => 'With';

  @override
  String get feedbackScreenshotWithout => 'Without';

  @override
  String get feedbackSearch => 'Search the feedback text';

  @override
  String get feedbackClearFilters => 'Clear filters';

  @override
  String feedbackMatching(int count, int matching) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat matchingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String matchingString = matchingNumberFormat.format(matching);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$matchingString of $countString entries match',
      one: '$matchingString of 1 entry matches',
    );
    return '$_temp0';
  }

  @override
  String feedbackDownloadCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Download $countString entries',
      one: 'Download 1 entry',
      zero: 'Nothing to download',
    );
    return '$_temp0';
  }

  @override
  String get feedbackDownloadStarted => 'Download started.';

  @override
  String feedbackDownloadedTo(Object location) {
    return 'Saved to $location';
  }

  @override
  String get downloadsTaptureFolder => 'Downloads › Tapture';

  @override
  String feedbackDownloadsGoTo(Object place) {
    return 'Downloads go to $place';
  }

  @override
  String get feedbackOpenFolder => 'Open folder';

  @override
  String get feedbackSaveToFolder => 'Save to a folder';

  @override
  String feedbackOpenFolderFailed(Object place) {
    return 'The folder could not be opened. Look in $place.';
  }

  @override
  String get feedbackEmptyHeadline => 'No feedback yet';

  @override
  String get feedbackEmptyMessage =>
      'Tap Feedback on any screen to write the first entry.';

  @override
  String get feedbackNoMatchHeadline => 'No feedback matches';

  @override
  String get feedbackNoMatchMessage =>
      'Change or clear the filters to see more.';

  @override
  String feedbackSelected(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString selected',
      one: '1 selected',
      zero: 'None selected',
    );
    return '$_temp0';
  }

  @override
  String feedbackDeleteCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $countString entries',
      one: 'Delete 1 entry',
      zero: 'Select entries to delete',
    );
    return '$_temp0';
  }

  @override
  String feedbackDeleteTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $countString feedback entries?',
      one: 'Delete 1 feedback entry?',
    );
    return '$_temp0';
  }

  @override
  String feedbackDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'They and their screenshots are removed from this device for good. You can undo straight after.',
      one:
          'It and its screenshot are removed from this device for good. You can undo straight after.',
    );
    return '$_temp0';
  }

  @override
  String feedbackDeleted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString feedback entries deleted',
      one: '1 feedback entry deleted',
    );
    return '$_temp0';
  }

  @override
  String get feedbackShowMore => 'Show more';

  @override
  String feedbackEntryFacts(Object type, Object when, Object screen) {
    return '$type · $when · $screen';
  }

  @override
  String feedbackEntryTitle(Object number, Object reference, Object message) {
    return '$number. $reference · $message';
  }

  @override
  String appLockWait(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wait $countString seconds before trying again.',
      one: 'Wait 1 second before trying again.',
    );
    return '$_temp0';
  }

  @override
  String get queueTitle => 'Process';

  @override
  String get queueUnprocessed => 'Unprocessed';

  @override
  String get queueQueued => 'Queued';

  @override
  String get queueFailed => 'Failed';

  @override
  String queueUsage(int requests, int cap, int images) {
    final intl.NumberFormat requestsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String requestsString = requestsNumberFormat.format(requests);
    final intl.NumberFormat capNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String capString = capNumberFormat.format(cap);
    final intl.NumberFormat imagesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String imagesString = imagesNumberFormat.format(images);

    return '$requestsString of $capString online requests today, $imagesString images sent';
  }

  @override
  String queueUnprocessedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString unprocessed records',
      one: '1 unprocessed record',
      zero: 'No unprocessed records',
    );
    return '$_temp0';
  }

  @override
  String queueQueuedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records queued',
      one: '1 record queued',
      zero: 'No records queued',
    );
    return '$_temp0';
  }

  @override
  String queueFailedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString failed jobs',
      one: '1 failed job',
      zero: 'No failed jobs',
    );
    return '$_temp0';
  }

  @override
  String get queueGroupsTitle => 'By context';

  @override
  String get queueProcessAll => 'Process all';

  @override
  String get queueProcessSelected => 'Process selected';

  @override
  String get queueEmptyHeadline => 'Nothing waiting';

  @override
  String get queueEmptyMessage =>
      'Captured records appear here when they are ready to process.';

  @override
  String get queueFailedTitle => 'Failed jobs';

  @override
  String get queueRetry => 'Retry';

  @override
  String queueRetryLabel(Object record) {
    return 'Retry $record';
  }

  @override
  String get queueCancel => 'Cancel';

  @override
  String get queueCancelled => 'Stopped. The rest stay in the queue.';

  @override
  String queueSummary(int succeeded, int failed) {
    final intl.NumberFormat succeededNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String succeededString = succeededNumberFormat.format(succeeded);
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);

    return '$succeededString succeeded, $failedString failed';
  }

  @override
  String queueSummaryValue(Object counts, Object detail) {
    return '$counts. $detail';
  }

  @override
  String queueProgress(int done, int failed) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);

    return 'Processing: $doneString done, $failedString failed';
  }

  @override
  String queueProgressNow(Object counts, Object stage) {
    return '$counts. Now: $stage';
  }

  @override
  String get egressTitle => 'Send for analysis?';

  @override
  String get egressSend => 'Send';

  @override
  String get egressDecline =>
      'Nothing was sent. The records stay in the queue.';

  @override
  String egressBody(int images, Object size) {
    final intl.NumberFormat imagesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String imagesString = imagesNumberFormat.format(images);

    return '$imagesString compressed images, about $size. Captions, field names, on-device text, context and predefined row labels are included.';
  }

  @override
  String get apiKeyTitle => 'Provider key';

  @override
  String get apiKeyCustody =>
      'This key lives on this device only. The usual arrangement is for the organisation\'s backend to hold it.';

  @override
  String get apiKeyLabel => 'Provider key';

  @override
  String get apiKeySave => 'Save key';

  @override
  String get apiKeyRemove => 'Remove key';

  @override
  String get apiKeyTest => 'Test connection';

  @override
  String get apiKeySaved => 'Saved on this device';

  @override
  String get apiKeyRemoveTitle => 'Remove the provider key?';

  @override
  String get apiKeyRemoveMessage =>
      'The key is deleted from this device, and AI goes back to your organisation\'s provider.';

  @override
  String get apiKeySuccess => 'Connection succeeded.';

  @override
  String get apiKeyAuthFailed => 'The key was rejected.';

  @override
  String get apiKeyNetworkFailed => 'The network is not available.';

  @override
  String get apiKeyTestFailed =>
      'The provider answered with an error. Try again later.';

  @override
  String get aiOperation => 'Operation';

  @override
  String get aiProvider => 'Provider';

  @override
  String get aiModel => 'Model';

  @override
  String get aiOperationLabel => 'Read text';

  @override
  String get aiOperationLabelExtractFields => 'Extract fields';

  @override
  String get aiOperationLabelRefineText => 'Refine text';

  @override
  String get aiOperationLabelTranscribeAudio => 'Transcribe audio';

  @override
  String get aiCustodyTheOrganisationBackendHolds =>
      'The organisation backend holds the provider key.';

  @override
  String get aiCustodyThisProviderUsesA =>
      'This provider uses a device-held credential when enabled by an administrator.';

  @override
  String aiCustodyThisProviderIsCurrently(Object owner) {
    return '$owner This provider is currently unavailable.';
  }

  @override
  String get aiSelectionFallback =>
      'The saved choice is unavailable. The organisation backend is selected for now.';

  @override
  String get aiProviderUnavailable =>
      'This provider is not available. Processing will remain queued.';

  @override
  String get aiSelectionInvalid =>
      'Choose a provider and model that support this operation.';

  @override
  String get templateChoiceTitle => 'What is this?';

  @override
  String get templateChoicePin =>
      'Use this template for the rest of this location';

  @override
  String get templateChoiceEmptyHeadline => 'No templates';

  @override
  String get templateChoiceEmptyMessage =>
      'Add a template before choosing one.';

  @override
  String get templateChoiceOther => 'Something else';

  @override
  String get templateChoiceSkipped =>
      'No template chosen. The record stays in the queue.';

  @override
  String get templateChoiceApplyFailed => 'That template could not be applied.';

  @override
  String get templateChoiceApplyRecovery =>
      'Process the record again and choose once more.';

  @override
  String get templateChoiceWaiting =>
      'Waiting for someone to choose its template.';

  @override
  String get processReadOnDevice => 'Read on this device';

  @override
  String get processPreparing => 'Preparing images';

  @override
  String get processReading => 'Reading text on device';

  @override
  String get processDetecting => 'Identifying template';

  @override
  String get processExtracting => 'Extracting fields';

  @override
  String get processChecking => 'Checking values';

  @override
  String get processingNotificationTitle => 'Processing finished';

  @override
  String processingNotificationBody(int succeeded, int failed) {
    final intl.NumberFormat succeededNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String succeededString = succeededNumberFormat.format(succeeded);
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);

    return '$succeededString succeeded, $failedString failed';
  }

  @override
  String get documentPickFailed => 'That file could not be opened.';

  @override
  String documentTooLarge(Object fileSizebytes, Object fileSizeceiling) {
    return 'That file is $fileSizebytes; this device opens files up to $fileSizeceiling.';
  }

  @override
  String get documentTooLargeRecovery =>
      'Open it in the Tapture app on a phone or computer instead.';

  @override
  String get storedFileMissing => 'That export is no longer on this device.';

  @override
  String get packageProjectMissing =>
      'That project is no longer on this device.';

  @override
  String packageTooLarge(Object fileSizebytes, Object fileSizeceiling) {
    return 'This project package would be $fileSizebytes; this device handles packages up to $fileSizeceiling.';
  }

  @override
  String get packageTooLargeRecovery =>
      'Export from the Tapture app on a phone or computer, which handles larger packages.';

  @override
  String get packageWriteFailed => 'The project package could not be written.';

  @override
  String get packageRejected =>
      'This package is larger than this device can open.';

  @override
  String get packageRejectedThisFileIsNot =>
      'This file is not a Tapture project package.';

  @override
  String get packageRejectedThisPackageHoldsA =>
      'This package holds a file that would land outside its project.';

  @override
  String get packageRejectedThisPackageIsMissing =>
      'This package is missing a file it lists.';

  @override
  String get packageRejectedPartOfThisPackage =>
      'Part of this package could not be read.';

  @override
  String get packageRejectedThisPackageWasMade =>
      'This package was made by a newer version of Tapture.';

  @override
  String get packageRejectedThisPackageWasChanged =>
      'This package was changed after it was made: a file does not match its checksum.';

  @override
  String get packageRejectedThisPackageCouldNot =>
      'This package could not be opened.';

  @override
  String get packageRejectedRecovery =>
      'Nothing was imported. Export the project again on the other device, or update Tapture for a newer package.';

  @override
  String get captureGuideTitle => 'What to capture';

  @override
  String get captureGuidePhotos => 'Photos should show';

  @override
  String get captureGuideCaption => 'Say or type in the caption';

  @override
  String get captureGuideClose => 'Hide the caption guide';

  @override
  String get importChecking => 'Checking the package…';

  @override
  String get importSheetTitle => 'Import a project';

  @override
  String importFrom(Object when, Object deviceisEmptyanother) {
    return 'Exported $when on $deviceisEmptyanother';
  }

  @override
  String importHolds(
    Object recordsCountrecords,
    Object photosCountphotos,
    Object fileSizebytes,
  ) {
    return '$recordsCountrecords · $photosCountphotos · $fileSizebytes';
  }

  @override
  String photosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString photos',
      one: '1 photo',
      zero: 'No photos',
    );
    return '$_temp0';
  }

  @override
  String get importAsNewProject => 'Import as a new project';

  @override
  String get importMergeInto => 'Merge into a project…';

  @override
  String get importCopying => 'Importing the project…';

  @override
  String importDone(Object recordsCountrecords) {
    return 'Project imported: $recordsCountrecords';
  }

  @override
  String get importProjectDeletedHere =>
      'This project was deleted on this device. A merge never brings back what was deleted.';

  @override
  String get importProjectDeletedHereRecovery =>
      'Restore the project from the recycle bin, or import on another device.';

  @override
  String get importProjectAlreadyHere =>
      'This project is already on this device.';

  @override
  String get importProjectAlreadyHereRecovery =>
      'Merge the package into it instead.';

  @override
  String get importNoRoom =>
      'There is not enough free space on this device for this package.';

  @override
  String get importNoRoomRecovery => 'Free some space, then import again.';

  @override
  String get importFileChanged =>
      'A file in this package did not copy correctly.';

  @override
  String get importFailedRecovery =>
      'Nothing was changed. Try again, or export the package again.';

  @override
  String get mergePackage => 'Merge a package';

  @override
  String get mergeTargetTitle => 'Merge into which project?';

  @override
  String get mergeTargetNone =>
      'No project on this device uses the templates this package needs.';

  @override
  String get compatibilityStatus => 'Compatible';

  @override
  String get compatibilityStatusCompatibleWithDifferences =>
      'Compatible, with differences';

  @override
  String get compatibilityStatusNotCompatible => 'Not compatible';

  @override
  String get compatibilityIssue => 'No matching template here';

  @override
  String compatibilityIssueHoldsValuesButIs(Object field) {
    return '$field holds values but is not in the template here';
  }

  @override
  String compatibilityIssueHereCannotHoldThe(Object field) {
    return '$field here cannot hold the incoming values';
  }

  @override
  String get compatibilityIssueAnotherVersionOfThe =>
      'Another version of the template';

  @override
  String compatibilityIssueOnlyHere(Object field) {
    return 'Only here: $field';
  }

  @override
  String compatibilityIssueIsRequiredOnOne(Object field) {
    return '$field is required on one side only';
  }

  @override
  String compatibilityIssueHasAnotherLabelHere(Object field) {
    return '$field has another label here';
  }

  @override
  String compatibilityIssueOffersOtherChoicesHere(Object field) {
    return '$field offers other choices here';
  }

  @override
  String compatibilityIssueHasAnotherTypeHere(Object field) {
    return '$field has another type here';
  }

  @override
  String compatibilityIssueIsNotInThe(Object field) {
    return '$field is not in the template here, and holds no values';
  }

  @override
  String compatibilityTemplate(Object name, Object compatibilityStatusstatus) {
    return '$name: $compatibilityStatusstatus';
  }

  @override
  String get mergeCount => 'New records';

  @override
  String get mergeCountRecordsThisMergeChanges => 'Records this merge changes';

  @override
  String get mergeCountNewPhotos => 'New photos';

  @override
  String get mergeCountPhotosAlreadyOnThis => 'Photos already on this device';

  @override
  String get mergeCountDeletionsToApply => 'Deletions to apply';

  @override
  String get mergeCountConflictsToSettle => 'Conflicts to settle';

  @override
  String get mergeCountPossibleDuplicates => 'Possible duplicates';

  @override
  String get mergeCountValuesKeptAsOn => 'Values kept as on this device';

  @override
  String get mergeCountAlreadyInAnotherProject =>
      'Already in another project here';

  @override
  String mergeCountValue(Object label, int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$label: $nString';
  }

  @override
  String mergeSettleConflicts(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Settle $countString conflicts',
      one: 'Settle 1 conflict',
    );
    return '$_temp0';
  }

  @override
  String get mergeApply => 'Merge';

  @override
  String get mergeApplying => 'Merging…';

  @override
  String get mergeDone => 'Merged';

  @override
  String get mergeNothing =>
      'Nothing to merge: this project already holds everything in the package.';

  @override
  String get mergeCheckDuplicates => 'Check for possible duplicates';

  @override
  String get mergeCheckDuplicatesHelper =>
      'Lists incoming records that look like ones already here. You decide for each.';

  @override
  String get mergeCheckingDuplicates => 'Looking for duplicates…';

  @override
  String conflictProgress(int index, int total) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Conflict $indexString of $totalString';
  }

  @override
  String get conflictKind => 'Caption';

  @override
  String get conflictKindStatus => 'Status';

  @override
  String get conflictKindDeletedOnTheOther => 'Deleted on the other device';

  @override
  String get conflictKindDeletedOnThisDevice => 'Deleted on this device';

  @override
  String get conflictDeletionTheOtherDeviceDeleted =>
      'The other device deleted this, but it was changed here since.';

  @override
  String get conflictDeletionThisDeviceDeletedThis =>
      'This device deleted this, but the other device changed it since.';

  @override
  String get conflictThisDevice => 'This device';

  @override
  String get conflictIncoming => 'Incoming';

  @override
  String conflictWrittenBy(Object dateFormatyMMMdadd) {
    return ' · $dateFormatyMMMdadd';
  }

  @override
  String conflictWrittenByValue(Object deviceisEmptyUnknown, Object when) {
    return '$deviceisEmptyUnknown$when';
  }

  @override
  String get conflictDeleted => 'Deleted';

  @override
  String get conflictEmpty => 'Empty';

  @override
  String get conflictKeepMine => 'Keep this device\'s';

  @override
  String get conflictTakeIncoming => 'Take incoming';

  @override
  String mergeKeepAllMine(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Keep this device\'s for all $nString';
  }

  @override
  String mergeTakeAllIncoming(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Take incoming for all $nString';
  }

  @override
  String get mergeBulkConfirm => 'the incoming value';

  @override
  String get mergeBulkConfirmThisDeviceSValue => 'this device\'s value';

  @override
  String mergeBulkConfirmForConflictOtherFor(int count, Object side) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Use $side for all $countString conflicts?',
      one: 'Use $side for 1 conflict?',
    );
    return '$_temp0';
  }

  @override
  String get duplicateTitle => 'Possible duplicate';

  @override
  String get duplicateSignal => 'Same identity fields';

  @override
  String get duplicateSignalSamePhoto => 'Same photo';

  @override
  String get duplicateSignalIdenticalPhoto => 'Identical photo';

  @override
  String get duplicateSignalNearlyTheSamePhoto => 'Nearly the same photo';

  @override
  String get duplicateSignalSameChecklistRow => 'Same checklist row';

  @override
  String get duplicateSignalSameNamePlaceAnd => 'Same name, place and time';

  @override
  String get duplicateSignalSamePlaceCloseIn =>
      'Same place, close in time, similar caption';

  @override
  String get duplicateKeepBoth => 'Keep both';

  @override
  String get duplicateSkipIncoming => 'Don\'t import this record';

  @override
  String get duplicateSkipped => 'Not imported';

  @override
  String get duplicateIncoming => 'Incoming record';

  @override
  String get duplicateHere => 'On this device';

  @override
  String get mergeNoPackageHeadline => 'No package open';

  @override
  String get mergeNoPackageMessage =>
      'Choose Merge a package from the project menu to pick one.';

  @override
  String get mergeTemplatesHeading => 'Templates';

  @override
  String get mergeCountsHeading => 'What the merge does';

  @override
  String get mergeBlocked =>
      'This package cannot merge into this project until its templates match.';

  @override
  String mergeRecordUnnamed(Object short) {
    return 'Record …$short';
  }

  @override
  String mergeConflictLine(Object record, Object about) {
    return '$record · $about';
  }

  @override
  String get mergeConflictChosen => 'Taking incoming';

  @override
  String get mergeConflictChosenKeepingThisDeviceS => 'Keeping this device\'s';

  @override
  String get mergeConflictOpen => 'Not settled yet';

  @override
  String mergeProjectKept(Object labelsjoin) {
    return 'Project details kept as on this device: $labelsjoin';
  }

  @override
  String get conflictChanged => 'Kept and changed';

  @override
  String duplicateField(Object label, Object valueisEmptyconflictEmpty) {
    return '$label: $valueisEmptyconflictEmpty';
  }

  @override
  String get recordsSearchHint => 'Search records';

  @override
  String get recordsUntitled => 'Untitled record';

  @override
  String recordsUntitledRecord(Object number) {
    return 'Record $number';
  }

  @override
  String get recordsEmptyHeadline => 'No records yet';

  @override
  String get recordsEmptyMessage =>
      'Records you capture in this project appear here.';

  @override
  String get recordsEmptyAction => 'Capture a record';

  @override
  String get recordsNoMatch => 'No records match.';

  @override
  String recordsNoMatchNoRecordsMatch(Object shown) {
    return 'No records match \"$shown\".';
  }

  @override
  String get recordsClearSearch => 'Clear search';

  @override
  String get recordsClearAll => 'Clear search and filters';

  @override
  String get recordsNoProjectHeadline => 'No project open';

  @override
  String get recordsNoProjectMessage =>
      'Records belong to a project. Open one to see its records.';

  @override
  String get recordsOpenProject => 'Open a project';

  @override
  String get recordsFiltersTitle => 'Record filters';

  @override
  String get recordsFilterStatus => 'Status';

  @override
  String get recordsFilterTemplate => 'Template';

  @override
  String get recordsFilterFrom => 'Captured from';

  @override
  String get recordsFilterTo => 'Captured until';

  @override
  String get recordsFilterOperator => 'Captured by';

  @override
  String get recordsFilterCondition => 'Condition';

  @override
  String get recordsFilterFlags => 'Quality';

  @override
  String get recordsFlagHasPhotos => 'Has photos';

  @override
  String get recordsFlagHasDuplicate => 'Possible duplicate';

  @override
  String get recordsFlagHasConflict => 'Merge conflict';

  @override
  String get recordsFlagHasVariance => 'Changed since approval';

  @override
  String get recordsFlagEvidenceRemoved => 'Evidence removed';

  @override
  String get recordsFlagMerged => 'From another device';

  @override
  String get recordsFiltersEmptyHeadline => 'Nothing to filter yet';

  @override
  String get recordsFiltersEmptyMessage =>
      'Capture records in this project, then narrow them down here.';

  @override
  String get recordsTemplateUnnamed => 'Unnamed template';

  @override
  String recordsChipTemplate(Object name) {
    return 'Template: $name';
  }

  @override
  String recordsChipOperator(Object name) {
    return 'Captured by $name';
  }

  @override
  String recordsChipCondition(Object code) {
    return 'Condition: $code';
  }

  @override
  String recordsChipContext(Object level, Object value) {
    return '$level: $value';
  }

  @override
  String recordsChipDates(Object formatformatfrom, Object formatformatto) {
    return '$formatformatfrom – $formatformatto';
  }

  @override
  String recordsChipDatesFrom(Object formatformatfrom) {
    return 'From $formatformatfrom';
  }

  @override
  String recordsChipDatesUntil(Object formatformatto) {
    return 'Until $formatformatto';
  }

  @override
  String get recordsSortTitle => 'Sort records';

  @override
  String recordsSortLabel(Object current) {
    return 'Sort: $current';
  }

  @override
  String get recordsSortNumberDescending => 'Number, highest first';

  @override
  String get recordsSortNumberAscending => 'Number, lowest first';

  @override
  String get recordsSortCapturedDescending => 'Captured, newest first';

  @override
  String get recordsSortCapturedAscending => 'Captured, oldest first';

  @override
  String get recordsSortNameAscending => 'Name, A to Z';

  @override
  String get recordsSortNameDescending => 'Name, Z to A';

  @override
  String get recordDetailBackToList => 'Back to the list';

  @override
  String get recordDetailDeletedNotice =>
      'This record is in the recycle bin. Restore it to change it again.';

  @override
  String get recordDetailSendToReview => 'Send to review';

  @override
  String get recordDetailSentToReview => 'Record sent to review';

  @override
  String get recordDetailUnarchive => 'Unarchive record';

  @override
  String get recordDetailUnarchived => 'Record back from the archive';

  @override
  String get recordDetailEditPhotos => 'Edit photos and captions';

  @override
  String get recordDetailBusy =>
      'A change to this record is still being saved.';

  @override
  String get recordDetailBusyAction => 'Wait for it to finish, then try again.';

  @override
  String get recordDetailNoValues => 'This record has no values yet.';

  @override
  String get recordDetailContextTitle => 'Context';

  @override
  String get recordDetailContextEmpty =>
      'No context was set when this record was captured.';

  @override
  String get recordDetailProvenanceTitle => 'Where the values came from';

  @override
  String recordDetailValuesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString values',
      one: '1 value',
      zero: 'No values',
    );
    return '$_temp0';
  }

  @override
  String get recordDetailVerified => 'Confirmed by a person';

  @override
  String get recordDetailReadBy => 'Read by';

  @override
  String get recordDetailDatesTitle => 'Dates';

  @override
  String get recordDetailCaptured => 'Captured';

  @override
  String get recordDetailUpdated => 'Last changed';

  @override
  String get recordDetailApproved => 'Approved';

  @override
  String get recordDetailExported => 'Exported';

  @override
  String get recordDetailNotExported => 'Not exported yet';

  @override
  String recordDetailWhen(Object when, Object who) {
    return '$when · $who';
  }

  @override
  String recordPhotoPosition(int position, int total) {
    final intl.NumberFormat positionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String positionString = positionNumberFormat.format(position);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Photo $positionString of $totalString';
  }

  @override
  String get recordSourceTyped => 'Typed';

  @override
  String get recordSourceOcr => 'Read from photo';

  @override
  String get recordSourceAiPhoto => 'AI from photo';

  @override
  String get recordSourceAiText => 'AI from notes';

  @override
  String get recordSourceSpeech => 'Dictated';

  @override
  String get recordSourceBarcode => 'Barcode';

  @override
  String get recordSourceLookup => 'Looked up';

  @override
  String get recordSourceContext => 'From context';

  @override
  String get recordSourceDefault => 'Filled in';

  @override
  String get recordSourceImported => 'Imported';

  @override
  String get recordBandHigh => 'High confidence';

  @override
  String get recordBandMedium => 'Medium confidence';

  @override
  String get recordBandLow => 'Low confidence';

  @override
  String recordBandScore(Object numberFormatpercentPatternformat) {
    return '$numberFormatpercentPatternformat confidence';
  }

  @override
  String recordBandWithScore(
    Object band,
    Object numberFormatpercentPatternformat,
  ) {
    return '$band, $numberFormatpercentPatternformat';
  }

  @override
  String get recordHistoryTitle => 'History';

  @override
  String get recordHistoryEmptyHeadline => 'No history yet';

  @override
  String get recordHistoryEmptyMessage =>
      'Captures, processing runs, edits, approvals, merges and exports of this record appear here. Go back to the record to change it.';

  @override
  String get recordHistoryBackToRecord => 'Back to the record';

  @override
  String recordHistoryByline(Object device) {
    return 'On $device';
  }

  @override
  String recordHistoryBylineOn(Object operator, Object device) {
    return '$operator on $device';
  }

  @override
  String recordHistoryBylineValue(Object time, Object who) {
    return '$time · $who';
  }

  @override
  String get recordHistoryCaptured => 'Captured';

  @override
  String get recordHistoryCreatedByHand => 'Created by hand';

  @override
  String recordHistoryValue(Object label) {
    return '$label changed';
  }

  @override
  String recordHistoryValueValue(Object label, Object next) {
    return '$label: $next';
  }

  @override
  String recordHistoryValueCleared(Object label) {
    return '$label cleared';
  }

  @override
  String recordHistoryValueValue2(Object label, Object previous, Object next) {
    return '$label: $previous → $next';
  }

  @override
  String get recordHistoryCaption => 'Caption';

  @override
  String recordHistoryStatus(Object next) {
    return 'Status: $next';
  }

  @override
  String recordHistoryStatusValue(Object previous, Object next) {
    return '$previous → $next';
  }

  @override
  String get recordHistoryPhotoAdded => 'Photo added';

  @override
  String get recordHistoryPhotoRemoved => 'Photo removed';

  @override
  String get recordHistoryTemplate => 'Template changed';

  @override
  String recordHistoryTemplateTemplate(Object next) {
    return 'Template: $next';
  }

  @override
  String recordHistoryTemplateTemplate2(Object previous, Object next) {
    return 'Template: $previous → $next';
  }

  @override
  String get recordHistoryTemplateGone => 'A template not on this device';

  @override
  String recordHistoryProcessed(Object provider) {
    return ' by $provider';
  }

  @override
  String recordHistoryProcessedValue(Object model) {
    return ' ($model)';
  }

  @override
  String recordHistoryProcessedProcessed(Object by, Object using) {
    return 'Processed$by$using';
  }

  @override
  String get recordHistoryProcessingFailed => 'Processing failed';

  @override
  String recordHistoryProcessingFailedOtherAttempts(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Processing failed after $countString attempts',
      one: 'Processing failed after 1 attempt',
    );
    return '$_temp0';
  }

  @override
  String get recordHistoryImported => 'Imported from a package';

  @override
  String recordHistoryImportedImportedFrom(Object package) {
    return 'Imported from $package';
  }

  @override
  String get recordHistoryMerged => 'Merged from a package';

  @override
  String recordHistoryMergedMergedFrom(Object package) {
    return 'Merged from $package';
  }

  @override
  String get recordHistoryExported => 'Exported';

  @override
  String recordHistoryExportedExportedInExport(Object version) {
    return 'Exported in export $version';
  }

  @override
  String recordHistoryEvidenceRemoved(Object label) {
    return '$label: evidence removed';
  }

  @override
  String recordHistoryEvidenceRestored(Object label) {
    return '$label: evidence restored';
  }

  @override
  String recordHistoryRetired(Object label) {
    return '$label retired';
  }

  @override
  String recordHistoryMappedAgain(Object label) {
    return '$label mapped again';
  }

  @override
  String get recordHistoryRowMatched => 'Matched to a checklist row';

  @override
  String get recordHistoryFileMissing => 'A photo file is missing';

  @override
  String get recordHistoryOther => 'Record changed';

  @override
  String get recordHistoryLineTitle => 'Change';

  @override
  String get recordHistoryBefore => 'Before';

  @override
  String get recordHistoryAfter => 'After';

  @override
  String get recordHistoryWhen => 'When';

  @override
  String get recordHistoryOperator => 'Operator';

  @override
  String get recordHistoryDevice => 'Device';

  @override
  String get recordHistoryReason => 'Reason';

  @override
  String get recordHistoryNotRecorded => 'Not recorded';

  @override
  String get recordHistoryEmptyValue => 'Empty';

  @override
  String get recordValuesEditTitle => 'Edit values';

  @override
  String get recordValueEditTitle => 'Edit value';

  @override
  String get recordEditApprovedNotice =>
      'This record is approved. Saving a change sends it back to review.';

  @override
  String get recordValueRetired => 'Retired';

  @override
  String get recordRetiredValuesTitle => 'Retired values';

  @override
  String get recordRetiredValuesMessage =>
      'This record\'s template no longer has these fields. Their values are kept as they were and can\'t be edited.';

  @override
  String get recordValueEvidenceRemoved => 'Evidence removed';

  @override
  String get recordTemplateMissingNotice =>
      'This record\'s template is no longer on this device. Its values are kept; change its template to edit them.';

  @override
  String get recordEditDeletedHeadline => 'This record is in the recycle bin';

  @override
  String get recordEditDeletedMessage =>
      'Restore it from the recycle bin, then change its values.';

  @override
  String get recordFieldMissingHeadline => 'This field is not on the record';

  @override
  String get recordFieldMissingMessage =>
      'The record\'s template no longer has this field. Go back to the record.';

  @override
  String get recordValueCannotEmpty =>
      'A saved value cannot be emptied. Type the corrected value instead.';

  @override
  String recordValuesSaved(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString values saved',
      one: '1 value saved',
    );
    return '$_temp0';
  }

  @override
  String recordValuesSavedTheRecordIsBack(Object saved) {
    return '$saved. The record is back in review.';
  }

  @override
  String recordValuesSavedValue(Object saved) {
    return '$saved.';
  }

  @override
  String get recordPhotosProcessTitle => 'Process this record again?';

  @override
  String recordPhotosProcessMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You added $countString photos. Processing again reads them and fills fields that are still empty. Values already on the record stay as they are.',
      one:
          'You added 1 photo. Processing again reads it and fills fields that are still empty. Values already on the record stay as they are.',
    );
    return '$_temp0';
  }

  @override
  String get recordPhotosProcessConfirm => 'Process again';

  @override
  String get recordPhotosProcessQueued => 'Record queued for processing.';

  @override
  String get recordTemplateChangeTitle => 'Change template';

  @override
  String recordTemplateChangeCurrent(Object name) {
    return 'Now on $name';
  }

  @override
  String get recordTemplateChangeChoose => 'Move to';

  @override
  String get recordTemplateChangeHint =>
      'Choose a template to see what happens to each value before anything changes.';

  @override
  String recordTemplateChangeMapped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString values carried over',
      one: '1 value carried over',
    );
    return '$_temp0';
  }

  @override
  String recordTemplateChangeRetired(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString values kept as retired',
      one: '1 value kept as retired',
    );
    return '$_temp0';
  }

  @override
  String recordTemplateChangeAdded(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fields start empty',
      one: '1 field starts empty',
    );
    return '$_temp0';
  }

  @override
  String recordTemplateChangeRestored(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString retired values come back',
      one: '1 retired value comes back',
    );
    return '$_temp0';
  }

  @override
  String get recordTemplateChangeRetiredNotice =>
      'Retired values stay on the record and are never deleted. They come back if the record moves to a template with their field.';

  @override
  String get recordTemplateChangeNoValues =>
      'No value changes: the record has no values for this template to take over, and the template has no fields.';

  @override
  String get recordTemplateChangeApprovedNotice =>
      'This record is approved. Changing its template sends it back to review.';

  @override
  String get recordTemplateChangeApply => 'Change template';

  @override
  String get recordTemplateChanged =>
      'Template changed. The record is back in review.';

  @override
  String get recordTemplateChangedTemplateChanged => 'Template changed.';

  @override
  String get recordTemplateChangeEmptyHeadline => 'No other template';

  @override
  String get recordTemplateChangeEmptyMessage =>
      'This project has only the template this record uses. Add another template to the project, then move the record to it.';

  @override
  String get recordTemplateChangeEmptyAction => 'Open templates';

  @override
  String get recordTemplateChangeGoneHeadline =>
      'This record is no longer on this device';

  @override
  String get recordTemplateChangeGoneMessage =>
      'Close this sheet and pick another record.';

  @override
  String get recordTemplateChangeChooseAction =>
      'Choose a template under Move to, then apply.';

  @override
  String get recordTemplateChangeApplying =>
      'This record is already moving to that template.';

  @override
  String get recordTemplateChangeApplyingAction =>
      'Wait a moment, then check the record.';

  @override
  String recordsDeleteLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $countString records',
      one: 'Delete record',
    );
    return '$_temp0';
  }

  @override
  String recordsDeleteTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $countString records?',
      one: 'Delete 1 record?',
    );
    return '$_temp0';
  }

  @override
  String recordsDeleteMessage(int count, Object window) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'They move to the recycle bin, where you can restore them for $window. Their photos stay on this device until then.',
      one:
          'It moves to the recycle bin, where you can restore it for $window. Its photos stay on this device until then.',
    );
    return '$_temp0';
  }

  @override
  String get recordsDeleteConfirm => 'Delete';

  @override
  String recordsDeleted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records deleted',
      one: '1 record deleted',
    );
    return '$_temp0';
  }

  @override
  String recordsNotDeleted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records could not be deleted',
      one: '1 record could not be deleted',
    );
    return '$_temp0';
  }

  @override
  String recordsDeletedPartly(
    Object recordsDeleteddeleted,
    Object recordsNotDeletedfailed,
  ) {
    return '$recordsDeleteddeleted. $recordsNotDeletedfailed.';
  }

  @override
  String recordsRestored(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records restored',
      one: '1 record restored',
    );
    return '$_temp0';
  }

  @override
  String recordsNotRestored(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records could not be restored',
      one: '1 record could not be restored',
    );
    return '$_temp0';
  }

  @override
  String get recycleBinTitle => 'Recycle bin';

  @override
  String get recycleBinSettingsSubtitle =>
      'Restore a deleted record before it is removed for good.';

  @override
  String recycleBinKeptFor(Object settingsRetentionDaysdays) {
    return 'Deleted records stay here for $settingsRetentionDaysdays, then they are removed for good.';
  }

  @override
  String get recycleBinEmptyHeadline => 'Nothing in the recycle bin';

  @override
  String recycleBinEmptyMessage(Object settingsRetentionDaysdays) {
    return 'A record you delete waits here for $settingsRetentionDaysdays. Restore it from here to put it back in its list.';
  }

  @override
  String recycleBinDaysLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deletes in $countString days',
      one: 'Deletes in 1 day',
      zero: 'Deletes today',
    );
    return '$_temp0';
  }

  @override
  String get recycleBinRestore => 'Restore';

  @override
  String recycleBinRestoreLabel(Object name) {
    return 'Restore $name';
  }

  @override
  String get recycleBinRestoring => 'This record is already being restored.';

  @override
  String get recycleBinRestoringAction =>
      'Wait a moment, then look for it in its list.';

  @override
  String get recycleBinEmpty => 'Empty recycle bin';

  @override
  String recycleBinEmptyTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove $countString records for good?',
      one: 'Remove 1 record for good?',
    );
    return '$_temp0';
  }

  @override
  String recycleBinEmptyWarning(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'All $countString records in the recycle bin and their photos are removed from this device now. This cannot be undone. Records a merge still needs stay until they have been shared.',
      one:
          'The record in the recycle bin and its photos are removed from this device now. This cannot be undone. A record a merge still needs stays until it has been shared.',
    );
    return '$_temp0';
  }

  @override
  String recycleBinEmptyTypeCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Type $nString to confirm';
  }

  @override
  String get recycleBinEmptyConfirm => 'Remove for good';

  @override
  String get recycleBinEmptyUnavailable =>
      'Emptying is not available on this device. Each record is removed for good once its days run out.';

  @override
  String get recycleBinEmptyUnavailableAction =>
      'Restore what you need before its days run out.';

  @override
  String get recycleBinEmptying => 'The recycle bin is already being emptied.';

  @override
  String get recycleBinEmptyingAction => 'Wait for it to finish.';

  @override
  String recycleBinEmptied(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records removed for good',
      one: '1 record removed for good',
      zero: 'No records removed',
    );
    return '$_temp0';
  }

  @override
  String recycleBinEmptiedOtherKeptBecauseA(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString kept because a merge still needs them',
      one: '1 kept because a merge still needs it',
    );
    return '$_temp0';
  }

  @override
  String recycleBinEmptiedOtherCouldNotBe(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString could not be removed',
      one: '1 could not be removed',
    );
    return '$_temp0';
  }

  @override
  String recordsSelectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get recordsClearSelection => 'Clear selection';

  @override
  String get recordsSelectAllShown => 'Select all shown';

  @override
  String recordsApproveLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Approve $countString records',
      one: 'Approve record',
    );
    return '$_temp0';
  }

  @override
  String recordsArchiveLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Archive $countString records',
      one: 'Archive record',
    );
    return '$_temp0';
  }

  @override
  String recordsReprocessLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Process $countString records again',
      one: 'Process record again',
    );
    return '$_temp0';
  }

  @override
  String recordsExportLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Export $countString records',
      one: 'Export record',
    );
    return '$_temp0';
  }

  @override
  String recordsArchiveTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Archive $countString records?',
      one: 'Archive 1 record?',
    );
    return '$_temp0';
  }

  @override
  String recordsArchiveMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'They leave the records list and default exports, and keep their values and photos. Filter by Archived to find them again.',
      one:
          'It leaves the records list and default exports, and keeps its values and photos. Filter by Archived to find it again.',
    );
    return '$_temp0';
  }

  @override
  String get recordsArchiveConfirm => 'Archive';

  @override
  String recordsReprocessTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Process $countString records again?',
      one: 'Process 1 record again?',
    );
    return '$_temp0';
  }

  @override
  String recordsReprocessMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'They go back to the processing queue and are read again from the first step, with the other records waiting in this project. Values they already have are kept. Approved ones need review again.',
      one:
          'It goes back to the processing queue and is read again from the first step, with the other records waiting in this project. Values it already has are kept. If it was approved, it needs review again.',
    );
    return '$_temp0';
  }

  @override
  String get recordsReprocessConfirm => 'Process again';

  @override
  String recordsExportTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Export the project with these $countString records?',
      one: 'Export the project with this record?',
    );
    return '$_temp0';
  }

  @override
  String recordsExportMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'An export is one package of the whole project: every record in it, the $countString selected included, with their photos. You choose where it goes once it is written.',
      one:
          'An export is one package of the whole project: every record in it, this one included, with their photos. You choose where it goes once it is written.',
    );
    return '$_temp0';
  }

  @override
  String get recordsExportConfirm => 'Open export';

  @override
  String recordsApproved(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records approved',
      one: '1 record approved',
    );
    return '$_temp0';
  }

  @override
  String recordsNotApproved(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records could not be approved',
      one: '1 record could not be approved',
    );
    return '$_temp0';
  }

  @override
  String recordsArchived(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records archived',
      one: '1 record archived',
    );
    return '$_temp0';
  }

  @override
  String recordsNotArchived(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records could not be archived',
      one: '1 record could not be archived',
    );
    return '$_temp0';
  }

  @override
  String recordsRequeued(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records queued to process again',
      one: '1 record queued to process again',
    );
    return '$_temp0';
  }

  @override
  String recordsNotRequeued(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records could not be queued',
      one: '1 record could not be queued',
    );
    return '$_temp0';
  }

  @override
  String recordsRequeuedOffline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'They wait in the processing queue; process them from there once you are online.',
      one:
          'It waits in the processing queue; process it from there once you are online.',
    );
    return '$_temp0';
  }

  @override
  String recordsBulkOutcome(Object done, Object notDone) {
    return '$done. $notDone.';
  }

  @override
  String get recordsBulkBusy => 'Another bulk action is running.';

  @override
  String get recordsBulkBusyAction => 'Wait for it to finish, then try again.';

  @override
  String validationIssueCount(
    Object validationErrorCounterrors,
    Object validationWarningCountwarnings,
  ) {
    return '$validationErrorCounterrors, $validationWarningCountwarnings';
  }

  @override
  String validationErrorCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString errors',
      one: '1 error',
    );
    return '$_temp0';
  }

  @override
  String validationWarningCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString warnings',
      one: '1 warning',
    );
    return '$_temp0';
  }

  @override
  String get validationGoToFirstError => 'Go to the first error';

  @override
  String get validationErrorLabel => 'Error';

  @override
  String get validationWarningLabel => 'Warning';

  @override
  String validationRequired(Object label) {
    return '$label is required.';
  }

  @override
  String validationType(Object label) {
    return '$label is not a valid value for this field.';
  }

  @override
  String validationTooShort(Object label) {
    return '$label is too short.';
  }

  @override
  String validationTooLong(Object label) {
    return '$label is too long.';
  }

  @override
  String validationRange(Object label) {
    return '$label is outside the allowed range.';
  }

  @override
  String validationPattern(Object label) {
    return '$label does not match the expected pattern.';
  }

  @override
  String validationOption(Object label) {
    return '$label is not one of the allowed choices.';
  }

  @override
  String validationUnit(Object label) {
    return '$label is not in a unit this field can store.';
  }

  @override
  String validationIdentity(Object label) {
    return '$label identifies the record and is required.';
  }

  @override
  String get validationEvidence =>
      'This record needs its evidence before it can be approved.';

  @override
  String get validationExpression => 'That expression could not be read.';

  @override
  String get validationExpressionAction =>
      'Use fields on this template, comparisons and arithmetic only.';

  @override
  String validationUnknownField(Object name) {
    return 'Required when names \"$name\", which this template does not have.';
  }

  @override
  String get duplicatePromptTitle => 'This may be a duplicate';

  @override
  String get duplicateOverride => 'Update the existing record';

  @override
  String get duplicateLinkBoth => 'Keep both and link them';

  @override
  String get duplicateDiscard => 'Discard the new record';

  @override
  String get duplicateMerge => 'Merge field by field';

  @override
  String get duplicateNoDifferenceHeadline => 'Nothing differs';

  @override
  String get duplicateNoDifferenceMessage =>
      'These records hold the same values.';

  @override
  String get duplicateCompareTitle => 'Compare records';

  @override
  String get duplicateMergeTitle => 'Merge fields';

  @override
  String get duplicateKeepMine => 'Keep mine';

  @override
  String get duplicateTakeTheirs => 'Take theirs';

  @override
  String get duplicateKeepBothNote => 'Keep both as a note';

  @override
  String get duplicatePromptQuestion =>
      'What should happen to these two records?';

  @override
  String get duplicateCompareThenUpdate =>
      'Compare, then update the existing record';

  @override
  String get duplicatePromptContinue => 'Continue';

  @override
  String get duplicateExistingRecord => 'Existing record';

  @override
  String get duplicateNewRecord => 'New record';

  @override
  String get duplicateDifferingFields => 'Fields that differ';

  @override
  String get duplicateBackToList => 'Back to duplicates';

  @override
  String duplicatePairTitle(Object existing, Object incoming) {
    return '$existing and $incoming';
  }

  @override
  String duplicatesGroup(Object signal, Object template) {
    return '$signal · $template';
  }

  @override
  String duplicateValueChange(
    Object existingisEmptyconflictEmpty,
    Object incomingisEmptyconflictEmpty,
  ) {
    return '$existingisEmptyconflictEmpty → $incomingisEmptyconflictEmpty';
  }

  @override
  String duplicateDifferenceLine(
    Object label,
    Object duplicateValueChangeexistingincoming,
  ) {
    return '$label: $duplicateValueChangeexistingincoming';
  }

  @override
  String get duplicateOverrideConfirmTitle => 'Update the existing record?';

  @override
  String get duplicateOverrideConfirmMessage =>
      'The existing record takes the new values and photos. The values it replaces stay in its history, and the new record goes to the recycle bin.';

  @override
  String get duplicateCarryPhotos => 'Keep the new record\'s photos';

  @override
  String duplicateCarryPhotosHelp(Object photosCountn) {
    return '$photosCountn move to the existing record.';
  }

  @override
  String get duplicateMergeApply => 'Merge records';

  @override
  String duplicateMergeKeep(Object label) {
    return 'Keep for $label';
  }

  @override
  String get duplicateMergeExisting => 'Existing';

  @override
  String get duplicateMergeNew => 'New';

  @override
  String get duplicateMergeBoth => 'Both';

  @override
  String get duplicateMergeChooseAll => 'Choose a value for each field.';

  @override
  String duplicateBothValues(Object existing, Object incoming) {
    return '$existing / $incoming';
  }

  @override
  String get duplicateResolvedKeepBoth => 'Both records kept and linked';

  @override
  String get duplicateResolvedDiscard => 'New record moved to the recycle bin';

  @override
  String get duplicateResolvedOverride => 'Existing record updated';

  @override
  String get duplicateResolvedMerge => 'Records merged';

  @override
  String get duplicateDiscardedReason => 'Discarded as a duplicate';

  @override
  String get duplicateOverriddenReason =>
      'Its values updated an existing record';

  @override
  String get duplicateMergedReason => 'Merged into an existing record';

  @override
  String get duplicatePairGone =>
      'That pair is no longer waiting for a choice.';

  @override
  String get duplicatePairGoneRecovery =>
      'Go back to the duplicates list; it shows what is left.';

  @override
  String get duplicatesScan => 'Check for duplicates';

  @override
  String get duplicatesScanned => 'No new duplicate pairs';

  @override
  String get duplicatesScannedNewDuplicatePair => '1 new duplicate pair';

  @override
  String duplicatesScannedNewDuplicatePairs(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString new duplicate pairs';
  }

  @override
  String get duplicatesBulkChoose => 'Choose one outcome for the group';

  @override
  String get duplicatesBulkDone => '1 pair resolved';

  @override
  String duplicatesBulkDonePairsResolved(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString pairs resolved';
  }

  @override
  String duplicateLinkedTo(Object title) {
    return 'Linked to $title';
  }

  @override
  String duplicatePossibleOf(Object title) {
    return 'May duplicate $title';
  }

  @override
  String get duplicatesTitle => 'Duplicates';

  @override
  String get duplicatesEmptyHeadline => 'No duplicate pairs';

  @override
  String get duplicatesEmptyMessage =>
      'Pairs appear here when two records look like the same thing.';

  @override
  String get duplicatesResolveGroup => 'Resolve this group';

  @override
  String duplicatesBulkTitle(Object choice, int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$choice for $nString records?';
  }

  @override
  String duplicatesBulkMessage(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'This changes $nString records. The other groups stay as they are.';
  }

  @override
  String get conflictTypeOwn => 'Type a different value';

  @override
  String get conflictUseTyped => 'Use the typed value';

  @override
  String get conflictReason => 'Why this value';

  @override
  String get conflictEmptyHeadline => 'No candidates';

  @override
  String get conflictEmptyMessage => 'Nothing was proposed for this field.';

  @override
  String conflictBlocksApproval(Object label) {
    return '$label still has a conflict. Resolve it before approving.';
  }

  @override
  String get verificationModeTitle => 'Verification mode';

  @override
  String get verificationModeOn =>
      'Capture confirms the register instead of starting a blank record.';

  @override
  String get verificationModeOff => 'Capture starts a new record.';

  @override
  String get verificationStatus => 'Verifying';

  @override
  String get verificationFromRegister => 'From the register';

  @override
  String get varianceTitle => 'Variances';

  @override
  String get varianceEmptyHeadline => 'No variances';

  @override
  String get varianceEmptyMessage =>
      'Differences between the register and what was found appear here.';

  @override
  String get varianceMatch => 'Match';

  @override
  String get varianceChanged => 'Changed';

  @override
  String get varianceMissing => 'Missing';

  @override
  String varianceDetail(
    Object status,
    Object recordedisEmptyconflictEmpty,
    Object foundisEmptyconflictEmpty,
  ) {
    return '$status · $recordedisEmptyconflictEmpty → $foundisEmptyconflictEmpty';
  }

  @override
  String get varianceRegisterNotFound => 'Register rows not found';

  @override
  String get varianceChecklistNotCaptured => 'Checklist rows not captured';

  @override
  String get varianceOpenRecords => 'Open records';

  @override
  String get qualitySummaryTitle => 'Data quality';

  @override
  String get qualityInvalid => 'Invalid records';

  @override
  String get qualityDuplicates => 'Duplicate pairs';

  @override
  String get qualityConflicts => 'Unresolved conflicts';

  @override
  String get qualityUnreviewed => 'Unreviewed records';

  @override
  String get qualityCleanHeadline => 'Ready to export';

  @override
  String get qualityCleanMessage => 'Nothing here still blocks a clean export.';

  @override
  String get reviewTitle => 'Review';

  @override
  String get reviewNeedsAttention => 'Needs attention';

  @override
  String get reviewConfident => 'Confident';

  @override
  String reviewConfidentGroup(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Confident ($countString)';
  }

  @override
  String get reviewApproveNext => 'Approve and next';

  @override
  String get reviewEmptyHeadline => 'Nothing to review';

  @override
  String get reviewEmptyMessage => 'Records that need a person appear here.';

  @override
  String get reviewUseRaw => 'Use captured';

  @override
  String get reviewUseRefined => 'Use refined';

  @override
  String get reviewNoSidesHeadline => 'No values yet';

  @override
  String get reviewNoSidesMessage =>
      'This field has neither a captured nor a refined value.';

  @override
  String get reviewNotDetected => 'Not detected';

  @override
  String get reviewTypeIt => 'Type it';

  @override
  String get reviewPhotograph => 'Photograph the label';

  @override
  String get reviewNotDetectedEmpty => 'Nothing is missing';

  @override
  String get reviewShowEvidence => 'Show evidence';

  @override
  String get reviewOpenPhoto => 'Open photo';

  @override
  String get reviewEvidenceEmpty => 'No evidence linked';

  @override
  String get reviewVerify => 'Verify';

  @override
  String get reviewVerifyConfident => 'Verify confident fields';

  @override
  String reviewVerifiedBy(Object name) {
    return 'Verified by $name';
  }

  @override
  String get reviewVerifyEmpty => 'Nothing to verify';

  @override
  String reviewPosition(int index, int total) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$indexString of $totalString';
  }

  @override
  String get reviewSkip => 'Skip';

  @override
  String get reviewBack => 'Back';

  @override
  String get reviewQueueDone => 'Review is finished';

  @override
  String get reviewQueueDoneMessage =>
      'Every record in this set has been seen.';

  @override
  String get reviewQueueEmpty => 'No records in this review';

  @override
  String get reviewReanalyse => 'Re-analyse';

  @override
  String get reviewProposal => 'Proposed';

  @override
  String get reviewAccept => 'Accept';

  @override
  String get reviewApplyAccepted => 'Apply accepted';

  @override
  String get reviewDeclineAll => 'Decline all';

  @override
  String get reviewOfferedNotApplied => 'Offered, not applied';

  @override
  String get reviewReanalyseEmpty => 'No new proposals';

  @override
  String get reviewBlockedDuplicate =>
      'This record is part of an unresolved duplicate.';

  @override
  String get reviewBlockedAction => 'Fix the named field, then approve again.';

  @override
  String get reviewNoConfidence => 'No confidence';

  @override
  String get reviewNoConfidenceMessage =>
      'This value has no confidence band yet.';

  @override
  String get reviewApprovedReason => 'Approved in review.';

  @override
  String get reviewVerifiedReason => 'Verified in review.';

  @override
  String get reviewSideReason => 'Final side chosen in review.';

  @override
  String get reviewRecordSettled =>
      'This record is approved or in the recycle bin.';

  @override
  String get reviewRecordSettledAction =>
      'Send it back to review from its record page, then try again.';

  @override
  String get reviewRecordGone => 'That record is no longer on this device.';

  @override
  String get reviewRecordGoneAction =>
      'Go back to the records list and open another record.';

  @override
  String get reviewFinalSide => 'Final value';

  @override
  String get reviewPreviousRecord => 'Previous record';

  @override
  String get reviewBackToRecords => 'Back to records';

  @override
  String reviewVerifiedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString values verified',
      one: '1 value verified',
    );
    return '$_temp0';
  }

  @override
  String get reviewVerified => 'Verified';

  @override
  String get reviewEvidenceTitle => 'Evidence';

  @override
  String get reviewEvidencePhoto => 'From a photo';

  @override
  String get reviewEvidenceDocument => 'From a document';

  @override
  String reviewEvidenceDocumentFromADocumentPage(Object page) {
    return 'From a document, page $page';
  }

  @override
  String get reviewEvidenceTranscript => 'From a transcript';

  @override
  String get reviewEvidenceRegion => 'Where the value was read';

  @override
  String get reviewReanalyseQueued =>
      'Queued for re-analysis. New values are offered here when it finishes.';

  @override
  String get reviewReanalysing =>
      'Re-analysing. Nothing changes until you accept a proposal.';

  @override
  String get reviewProposalsTitle => 'Proposed values';

  @override
  String reviewProposalLine(
    Object currentisEmptyrecordFieldEmpty,
    Object proposed,
  ) {
    return 'Now: $currentisEmptyrecordFieldEmpty · Proposed: $proposed';
  }

  @override
  String reviewProposalsApplied(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString proposals applied',
      one: '1 proposal applied',
    );
    return '$_temp0';
  }

  @override
  String get meetingTitle => 'Meeting';

  @override
  String get meetingStart => 'Start meeting';

  @override
  String get meetingEmptyHeadline => 'No meeting yet';

  @override
  String get meetingEmptyMessage =>
      'Date, time, location and secretary fill in from this project.';

  @override
  String get meetingDate => 'Date';

  @override
  String get meetingStartTime => 'Start time';

  @override
  String get meetingLocation => 'Location';

  @override
  String get meetingSecretary => 'Secretary';

  @override
  String meetingStartedTitle(Object whenyear, Object month, Object day) {
    return 'Meeting $whenyear-$month-$day';
  }

  @override
  String get meetingAttachments => 'Attachments';

  @override
  String get meetingAddAttachment => 'Add attachment';

  @override
  String get meetingAttachmentsEmpty => 'No attachments';

  @override
  String get meetingAttachmentsEmptyMessage =>
      'Agendas, reports, handouts and whiteboard photos land here.';

  @override
  String get meetingOpenAttachment => 'Open';

  @override
  String get meetingAgenda => 'Agenda';

  @override
  String get meetingAddAgenda => 'Add agenda item';

  @override
  String get meetingAgendaTitle => 'Agenda item';

  @override
  String get meetingDiscussion => 'Discussion';

  @override
  String get meetingMoveDown => 'Move down';

  @override
  String get meetingRemove => 'Remove';

  @override
  String get meetingRemoveTitle => 'Remove this?';

  @override
  String get meetingRemoveMessage => 'This leaves the meeting.';

  @override
  String get meetingRemoveConfirm => 'Remove';

  @override
  String get meetingAgendaEmpty => 'No agenda yet';

  @override
  String get meetingAgendaEmptyMessage =>
      'Add the items you will discuss, in the order you want them.';

  @override
  String get meetingAttendees => 'Attendees';

  @override
  String get meetingAddAttendee => 'Add attendee';

  @override
  String get meetingAttendeeName => 'Name';

  @override
  String get meetingAttendeeRole => 'Title';

  @override
  String get meetingOrganisation => 'Organisation';

  @override
  String get meetingContact => 'Contact';

  @override
  String get meetingPresent => 'Present';

  @override
  String get meetingApology => 'Apology';

  @override
  String meetingAttendanceCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString present',
      one: '1 present',
    );
    return '$_temp0';
  }

  @override
  String get meetingAcceptStaff => 'Link staff';

  @override
  String get meetingAttendeesEmpty => 'No attendees yet';

  @override
  String get meetingAttendeesEmptyMessage =>
      'Add who is present, and record apologies separately.';

  @override
  String get meetingAttendanceSheet => 'Attendance sheet';

  @override
  String get meetingPhotographSheet => 'Photograph the sheet';

  @override
  String get meetingAcceptRows => 'Add these attendees';

  @override
  String get meetingSheetKept =>
      'The photo stays attached. Type the names if the reading is wrong.';

  @override
  String get meetingSheetEmpty => 'No attendance sheet';

  @override
  String get meetingSheetEmptyMessage =>
      'Photograph the signed sheet, then check each name before adding it.';

  @override
  String get meetingSignature => 'Signature';

  @override
  String get meetingRecording => 'Recording';

  @override
  String get meetingRecord => 'Record';

  @override
  String get meetingStop => 'Stop';

  @override
  String meetingElapsed(Object clock) {
    return 'Elapsed $clock';
  }

  @override
  String meetingRemaining(Object label) {
    return '$label free';
  }

  @override
  String get meetingInterrupted => 'Recording interrupted';

  @override
  String get meetingRecordingEmpty => 'No recording';

  @override
  String get meetingRecordingEmptyMessage =>
      'A recording stays on the meeting, including one that was interrupted.';

  @override
  String get meetingDecisions => 'Decisions';

  @override
  String get meetingAddDecision => 'Add decision';

  @override
  String get meetingDecisionText => 'Decision';

  @override
  String get meetingSource => 'From the notes';

  @override
  String get meetingDecisionsEmpty => 'No decisions yet';

  @override
  String get meetingDecisionsEmptyMessage =>
      'Decisions from the minutes or typed here are listed together.';

  @override
  String get meetingActions => 'Actions';

  @override
  String get meetingAddAction => 'Add action';

  @override
  String get meetingActionText => 'Action';

  @override
  String get meetingOwner => 'Owner';

  @override
  String get meetingDue => 'Due date';

  @override
  String get meetingOwnerAttendee => 'Owner from attendees';

  @override
  String get meetingOwnerStaff => 'Owner from staff';

  @override
  String get meetingStatus => 'Status';

  @override
  String get meetingActionsEmpty => 'No actions yet';

  @override
  String get meetingActionsEmptyMessage =>
      'Actions keep an owner, a due date and a status.';

  @override
  String get meetingNotes => 'Raw notes';

  @override
  String get meetingMinutes => 'Refined minutes';

  @override
  String get meetingTranscript => 'Transcript';

  @override
  String meetingActionBlocked(Object action) {
    return '$action needs an owner and a due date before it can be approved.';
  }

  @override
  String get meetingApprove => 'Approve meeting';

  @override
  String get meetingReviewTitle => 'Review meeting';

  @override
  String get meetingReviewEmpty => 'No meeting to review';

  @override
  String get meetingReviewEmptyMessage =>
      'Open a meeting to see attendance, decisions and actions.';

  @override
  String get meetingApprovedReason => 'Approved in review.';

  @override
  String get meetingStartEntry => 'Start a meeting';

  @override
  String get meetingOpen => 'Open meeting';

  @override
  String get meetingTemplateName => 'Meeting notes capture';

  @override
  String get meetingNotSet => 'Not set';

  @override
  String get meetingNoProject => 'This project is no longer here';

  @override
  String get meetingNoProjectMessage =>
      'Open a project, then start the meeting from it.';

  @override
  String get meetingBackToProjects => 'Back to projects';

  @override
  String get meetingSummary => 'Summary';

  @override
  String meetingDecisionsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString decisions',
      one: '1 decision',
      zero: 'No decisions',
    );
    return '$_temp0';
  }

  @override
  String meetingActionsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString actions',
      one: '1 action',
      zero: 'No actions',
    );
    return '$_temp0';
  }

  @override
  String get meetingNotesAndMinutes => 'Notes and minutes';

  @override
  String get meetingRefine => 'Refine minutes';

  @override
  String get meetingRefineNeedsAgenda =>
      'Add the agenda first, so each point gets its own summary.';

  @override
  String meetingUnsupported(Object namesjoin) {
    return 'Not in the notes or transcript: $namesjoin. Check these before approving.';
  }

  @override
  String meetingMinutesLine(Object title, Object summary) {
    return '$title: $summary';
  }

  @override
  String meetingTranscriptVersion(int version) {
    final intl.NumberFormat versionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String versionString = versionNumberFormat.format(version);

    return 'Transcript, run $versionString';
  }

  @override
  String get meetingTranscriptCloudVersion => 'Online transcription';

  @override
  String meetingTranscriptGaps(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString parts could not be transcribed',
      one: '1 part could not be transcribed',
    );
    return '$_temp0';
  }

  @override
  String get meetingTranscribe => 'Transcribe';

  @override
  String meetingTranscribing(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Transcribing part $doneString of $totalString';
  }

  @override
  String get meetingTranscribeUnavailable =>
      'Transcription is not available right now. The recording stays on the meeting.';

  @override
  String get meetingPlay => 'Play';

  @override
  String get meetingInterruptedKept =>
      'Recording interrupted. What was recorded is kept on the meeting.';

  @override
  String get meetingPhotographHandout => 'Photograph a handout';

  @override
  String get meetingDocument => 'Document';

  @override
  String get meetingPhoto => 'Photo';

  @override
  String meetingFileDetail(Object kind, Object fileSizebytes) {
    return '$kind · $fileSizebytes';
  }

  @override
  String meetingRecordingDetail(
    Object minutes,
    Object seconds,
    Object fileSizebytes,
  ) {
    return '$minutes:$seconds · $fileSizebytes';
  }

  @override
  String get meetingCheckReading =>
      'Check this: the sheet was hard to read here.';

  @override
  String get meetingSigned => 'Signed on the sheet';

  @override
  String get meetingAttendance => 'Attendance';

  @override
  String meetingStaffSuggestion(Object name, Object score100round) {
    return 'Staff list: $name ($score100round% match)';
  }

  @override
  String meetingStaffLinked(Object name) {
    return 'Linked to staff: $name';
  }

  @override
  String get meetingUnlinkStaff => 'Unlink';

  @override
  String meetingOwnerOption(Object name) {
    return '$name · Staff';
  }

  @override
  String meetingOwnerOptionAttendee(Object name) {
    return '$name · Attendee';
  }

  @override
  String get meetingStatusOpen => 'Open';

  @override
  String get meetingStatusInProgress => 'In progress';

  @override
  String get meetingStatusDone => 'Done';

  @override
  String meetingSourceLine(Object meetingSource, Object source) {
    return '$meetingSource: $source';
  }

  @override
  String meetingDrag(Object titletrimisEmpty) {
    return 'Drag $titletrimisEmpty to reorder';
  }

  @override
  String get meetingMoveUp => 'Move up';

  @override
  String get exportTitle => 'Export';

  @override
  String get exportRun => 'Export';

  @override
  String get exportScope => 'What to include';

  @override
  String get exportScopeApproved => 'Approved only';

  @override
  String get exportScopeAll => 'All records';

  @override
  String get exportScopeContext => 'Current context';

  @override
  String get exportScopeDates => 'Date range';

  @override
  String get exportScopeFilter => 'Current filter';

  @override
  String exportCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString records';
  }

  @override
  String get exportOptions => 'Columns';

  @override
  String get exportRaw => 'Raw columns';

  @override
  String get exportRefined => 'Refined columns';

  @override
  String get exportConfidence => 'Confidence';

  @override
  String get exportEvidence => 'Evidence';

  @override
  String get exportAdvanced => 'Advanced';

  @override
  String get exportPhotoMode => 'Photo reference';

  @override
  String get exportDelimiter => 'Delimiter';

  @override
  String get exportEmptyHeadline => 'Nothing to export';

  @override
  String get exportEmptyMessage => 'This scope has no records yet.';

  @override
  String get exportStageRecords => 'Records';

  @override
  String get exportStagePhotos => 'Photos';

  @override
  String get exportStageReports => 'Reports';

  @override
  String get exportStageArchive => 'Archive';

  @override
  String get exportCancel => 'Cancel';

  @override
  String get exportHistoryTitle => 'Export history';

  @override
  String get exportHistoryEmpty => 'No exports yet';

  @override
  String get exportHistoryEmptyMessage =>
      'A finished export is kept here, with who made it and what it held.';

  @override
  String get exportShare => 'Share';

  @override
  String get exportMissing => 'That file is no longer on this device.';

  @override
  String get exportRerun => 'Run this export again';

  @override
  String get exportFixNow => 'Fix now';

  @override
  String get exportExclude => 'Leave them out';

  @override
  String get exportAnyway => 'Export anyway';

  @override
  String get exportIncompleteStamp => 'Marked incomplete';

  @override
  String get exportEmptyRecovery => 'Choose a scope with records.';

  @override
  String get exportNoFormat => 'Choose an output format.';

  @override
  String get exportReplayMissing => 'This export is no longer available.';

  @override
  String get exportOutput => 'Output';

  @override
  String get exportOutputFiles => 'Reports and data files';

  @override
  String get exportFormats => 'Files';

  @override
  String get exportFormatXlsx => 'Spreadsheet (.xlsx)';

  @override
  String get exportFormatCsv => 'CSV';

  @override
  String get exportFormatJson => 'JSON';

  @override
  String get exportFormatPdf => 'PDF reports';

  @override
  String get exportScopeFrom => 'From';

  @override
  String get exportScopeTo => 'To';

  @override
  String get exportDictionary => 'Data dictionary';

  @override
  String get exportPhotoFilename => 'File name';

  @override
  String get exportPhotoRelative => 'Path in the package';

  @override
  String get exportPhotoEmbed => 'Embedded image';

  @override
  String get exportPdfPhotos => 'Report photos';

  @override
  String get exportPdfThumbnails => 'Thumbnails';

  @override
  String get exportPdfFull => 'Full size';

  @override
  String get exportDelimiterComma => 'Comma';

  @override
  String get exportDelimiterSemicolon => 'Semicolon';

  @override
  String get exportDelimiterTab => 'Tab';

  @override
  String exportGateTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString records need attention',
      one: '1 record needs attention',
    );
    return '$_temp0';
  }

  @override
  String get exportFixNowHint =>
      'Open the records that need attention. Nothing is exported.';

  @override
  String exportExcludeHint(Object recordsCountntoLowerCase) {
    return 'Export the other $recordsCountntoLowerCase.';
  }

  @override
  String get exportAnywayHint => 'Every file says it is incomplete.';

  @override
  String pdfPageOf(int page, int pages) {
    final intl.NumberFormat pageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String pageString = pageNumberFormat.format(page);
    final intl.NumberFormat pagesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pagesString = pagesNumberFormat.format(pages);

    return '$pageString of $pagesString';
  }

  @override
  String get pdfMissingPhoto => 'Missing photo';

  @override
  String get pdfRecordReport => 'Record report';

  @override
  String get pdfCaptured => 'Captured';

  @override
  String pdfRaw(Object label) {
    return '$label (raw)';
  }

  @override
  String pdfRefined(Object label) {
    return '$label (refined)';
  }

  @override
  String get pdfInspectionReport => 'Inspection report';

  @override
  String get pdfNotFound => 'Not found';

  @override
  String pdfChecklistRows(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString checklist rows',
      one: '1 checklist row',
    );
    return '$_temp0';
  }

  @override
  String pdfNotFoundCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString not found';
  }

  @override
  String pdfCompliance(int compliant, int total) {
    final intl.NumberFormat compliantNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String compliantString = compliantNumberFormat.format(compliant);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Compliant: $compliantString of $totalString';
  }

  @override
  String get pdfSummaryReport => 'Project summary';

  @override
  String get pdfByContext => 'By context';

  @override
  String get pdfByTemplate => 'By template';

  @override
  String get pdfByCondition => 'By condition';

  @override
  String get pdfByStatus => 'By status';

  @override
  String get pdfNoContext => 'No context';

  @override
  String get pdfNoCondition => 'Not recorded';

  @override
  String get pdfUnprocessed => 'Unprocessed';

  @override
  String get pdfNeedsReview => 'Needs review';

  @override
  String get pdfApproved => 'Approved';

  @override
  String get pdfVarianceReport => 'Variance report';

  @override
  String get pdfMatched => 'Matched';

  @override
  String get pdfNotInRegister => 'Not in register';

  @override
  String get pdfMinutesReport => 'Meeting minutes';

  @override
  String get pdfTranscriptReport => 'Transcripts';

  @override
  String pdfTranscriptHeard(Object title) {
    return '$title (as heard)';
  }

  @override
  String pdfTranscriptEdited(Object title) {
    return '$title (edited)';
  }

  @override
  String get pdfDue => 'Due';

  @override
  String get pdfActionStatus => 'In progress';

  @override
  String get pdfActionStatusDone => 'Done';

  @override
  String get pdfActionStatusOpen => 'Open';

  @override
  String pdfVarianceChanged(Object field, Object recorded, Object found) {
    return '$field: $recorded recorded, $found found';
  }

  @override
  String pdfVarianceEmpty(Object field, Object recorded) {
    return '$field: $recorded recorded, not found';
  }

  @override
  String get pdfPhotoAppendix => 'Photo appendix';

  @override
  String pdfPhotoReference(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'See $countString photos in the photo appendix.',
      one: 'See 1 photo in the photo appendix.',
    );
    return '$_temp0';
  }

  @override
  String pdfExportedAt(Object when) {
    return 'Exported $when';
  }

  @override
  String pdfExportedBy(Object operator) {
    return 'Exported by $operator';
  }

  @override
  String pdfScope(Object scope) {
    return 'Records: $scope';
  }

  @override
  String get conflictTypeValue => 'Type a value';

  @override
  String get conflictDecideLater => 'Decide later';

  @override
  String get conflictCaptionLabel => 'Caption';

  @override
  String get mergeConflictTyped => 'Use the entered value';

  @override
  String get bundlePassword => 'Bundle password';

  @override
  String get bundlePasswordRequired => 'Enter the bundle password.';

  @override
  String get bundlePasswordOptional => 'Set a bundle password (optional)';

  @override
  String get bundlePasswordSet => 'Bundle password set';

  @override
  String get bundleScope => 'What to include';

  @override
  String get bundleScopeFull => 'Full project';

  @override
  String get bundleScopeDates => 'Date range';

  @override
  String get bundleScopeContext => 'Current context';

  @override
  String get bundleScopeApproved => 'Approved only';

  @override
  String get bundleScopeData => 'Data without photos';

  @override
  String bundleSize(Object label) {
    return 'About $label';
  }

  @override
  String get bundleShare => 'Share bundle';

  @override
  String get bundleOpen => 'Open bundle';

  @override
  String get mergeHistoryTitle => 'Merge history';

  @override
  String get mergeHistoryEmpty => 'No merges yet';

  @override
  String get mergeHistoryEmptyMessage =>
      'A merge is kept here with its source, counts and how long undo lasts.';

  @override
  String mergeUndoUntil(Object when) {
    return 'Undo until $when';
  }

  @override
  String mergeHistoryFacts(
    Object name,
    Object id,
    Object dateFormatyMMMdadd,
    Object switchstatusapplied,
  ) {
    return '$name · $id · $dateFormatyMMMdadd · $switchstatusapplied';
  }

  @override
  String mergeHistoryCount(Object switchkeyrecords, int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$switchkeyrecords: $nString';
  }

  @override
  String mergeHistoryResolution(Object switchchoicemine, int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$switchchoicemine: $nString';
  }

  @override
  String get mergeUndoChanged => 'This merge has later changes.';

  @override
  String get mergeUndoChangedRecovery =>
      'Keep the later changes, or undo the newer merge first.';

  @override
  String get mergeUndoUnavailable => 'This merge can no longer be undone.';

  @override
  String get mergeUndoDone => 'Merge undone';

  @override
  String get mergeUndoConfirm =>
      'Restore the values from before this merge. Incoming evidence stays in the recycle area.';

  @override
  String get importTitle => 'Import';

  @override
  String get importEmptyHeadline => 'No file yet';

  @override
  String get importEmptyMessage =>
      'Choose a bundle, a spreadsheet, a dataset or a template. Tapture checks it and opens the step that fits.';

  @override
  String get importChooseFile => 'Choose a file';

  @override
  String get importCheckingFile => 'Checking the file…';

  @override
  String get importKindsTitle => 'What each file opens';

  @override
  String get importKindBundle => 'Bundle (.zip)';

  @override
  String get importBundleLine =>
      'Checked, then added as a project or merged into one.';

  @override
  String get importKindDataset => 'Reference dataset (.json)';

  @override
  String get importDatasetLine =>
      'A table of reference rows opens the dataset importer.';

  @override
  String get importKindTemplate => 'Template (.json)';

  @override
  String get importTemplateLine =>
      'A template file is checked, then added to the open project.';

  @override
  String get importKindSheet => 'Spreadsheet (.xlsx or .csv)';

  @override
  String get importSheetLine =>
      'Asks whether its rows are records or a register to check against.';

  @override
  String get importUnsupported => 'Tapture cannot import this kind of file.';

  @override
  String get importNeedsProject =>
      'Open a project first. A spreadsheet, dataset or template is added to the open project.';

  @override
  String get importNeedsProjectRecovery =>
      'Open the project from the list, then import the file again.';

  @override
  String get importPurposeTitle => 'What is this sheet?';

  @override
  String get importPurposeRecords => 'Records to hold';

  @override
  String get importPurposeRecordsLine =>
      'Each row becomes a record on one of this project’s templates.';

  @override
  String get importPurposeRegister => 'Register to verify against';

  @override
  String get importPurposeRegisterLine =>
      'The rows become a reference dataset that verification checks what you find against. No records are made.';

  @override
  String get importNoSheetHeadline => 'No sheet chosen';

  @override
  String get importNoSheetMessage =>
      'Choose a spreadsheet on the import page first.';

  @override
  String get importMappingTitle => 'Match columns';

  @override
  String get importMappingTemplate => 'Template';

  @override
  String get importMappingColumns => 'Columns';

  @override
  String get importUnmapped => 'Not matched';

  @override
  String get importNoTemplateHeadline => 'No template to match';

  @override
  String get importNoTemplateMessage =>
      'This project has no template yet. Make one from this sheet’s columns, then import its rows.';

  @override
  String get importMakeTemplate => 'Make a template from this sheet';

  @override
  String get importPreviewTitle => 'First rows, as they will be read';

  @override
  String importRow(int row) {
    final intl.NumberFormat rowNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowString = rowNumberFormat.format(row);

    return 'Row $rowString';
  }

  @override
  String importRun(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $countString rows',
      one: 'Import 1 row',
    );
    return '$_temp0';
  }

  @override
  String importIdentityMissing(Object field) {
    return '$field is an identity field and still needs a column.';
  }

  @override
  String get importWriting => 'Importing the rows';

  @override
  String importProgress(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString of $totalString rows';
  }

  @override
  String get importKeptExisting => 'Kept the record already here.';

  @override
  String get importMatchUnsettled =>
      'Matches a record already here, and no choice was made.';

  @override
  String importRepeatsRow(int row) {
    final intl.NumberFormat rowNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowString = rowNumberFormat.format(row);

    return 'Repeats the identity of row $rowString in this file.';
  }

  @override
  String get importAllDone => 'Every row was imported.';

  @override
  String get importOpenRecords => 'Open records';

  @override
  String get importFixFileName => 'rows-to-fix.csv';

  @override
  String get importFixRowColumn => 'Row in sheet';

  @override
  String get importFixReasonColumn => 'Why it was not imported';

  @override
  String get importFixSaved => 'Rows to fix saved.';

  @override
  String get importSummaryTitle => 'Import summary';

  @override
  String importCreated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString created';
  }

  @override
  String importUpdated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString updated';
  }

  @override
  String importSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString skipped';
  }

  @override
  String importFailed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString failed';
  }

  @override
  String get importRetry => 'Retry failures';

  @override
  String get importExportProblems => 'Export rows to fix';

  @override
  String get importMatchTitle => 'This row matches a record';

  @override
  String importMatchMessage(int row) {
    final intl.NumberFormat rowNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowString = rowNumberFormat.format(row);

    return 'Row $rowString has the same identity as a record already in this project.';
  }

  @override
  String get importMatchChoice => 'What to do with it';

  @override
  String get importKeepExisting => 'Keep existing';

  @override
  String get importReplace => 'Replace';

  @override
  String get importMerge => 'Merge';

  @override
  String get importApplyToAll => 'Use this choice for every later match';

  @override
  String get importMatchConfirm => 'Apply';

  @override
  String get cloudDestinationsTitle => 'Upload destinations';

  @override
  String get cloudDestinationsSubtitle =>
      'Where a finished file can be sent, when you confirm it.';

  @override
  String get destinationTitle => 'Upload destinations';

  @override
  String get destinationEmptyHeadline => 'No destinations yet';

  @override
  String get destinationEmptyMessage =>
      'Add a bucket, a folder or a drive you sign in to. Nothing is sent until you confirm it.';

  @override
  String get destinationAdd => 'Add a destination';

  @override
  String get destinationSave => 'Save';

  @override
  String get destinationTest => 'Test connection';

  @override
  String get destinationRemove => 'Remove';

  @override
  String get destinationRemoveTitle => 'Remove this destination?';

  @override
  String get destinationRemoveMessage =>
      'The destination and its saved sign-in are both deleted.';

  @override
  String get destinationCheckFailed =>
      'The connection test did not succeed, so this destination was not saved.';

  @override
  String get destinationLabel => 'Name';

  @override
  String get destinationFolder => 'Folder';

  @override
  String get destinationSecret => 'Sign-in';

  @override
  String get destinationKindS3 => 'S3 bucket';

  @override
  String get destinationKindDrive => 'Google Drive';

  @override
  String get destinationKindOneDrive => 'OneDrive';

  @override
  String get destinationKindDropbox => 'Dropbox';

  @override
  String get destinationKindWebDav => 'WebDAV';

  @override
  String get destinationKindLocal => 'Folder on this device';

  @override
  String get destinationEdit => 'Edit destination';

  @override
  String get destinationEditAction => 'Edit';

  @override
  String get destinationKind => 'Type';

  @override
  String get destinationCheckAndSave => 'Check and save';

  @override
  String get destinationBucketFolder => 'Folder in the bucket';

  @override
  String get destinationOptional => 'Optional';

  @override
  String get destinationLocalFolderHint =>
      'A folder inside the Tapture folder, or choose one';

  @override
  String get destinationChooseFolder => 'Choose a folder';

  @override
  String get destinationAccessKey => 'Access key';

  @override
  String get destinationSecretKey => 'Secret key';

  @override
  String get destinationRegion => 'Region';

  @override
  String get destinationBucket => 'Bucket';

  @override
  String get destinationEndpoint => 'Endpoint';

  @override
  String get destinationEndpointHint => 'Leave empty for Amazon S3';

  @override
  String get destinationAddress => 'Server address';

  @override
  String get destinationAddressHint => 'https://files.example.org/dav/';

  @override
  String get destinationSignInMethod => 'Sign-in method';

  @override
  String get destinationSignInPassword => 'Name and password';

  @override
  String get destinationSignInToken => 'Token';

  @override
  String get destinationUsername => 'User name';

  @override
  String get destinationPassword => 'Password';

  @override
  String get destinationToken => 'Token';

  @override
  String get destinationKeepSignIn =>
      'Leave the sign-in fields empty to keep the saved sign-in.';

  @override
  String get destinationSignInAgain => 'Sign in again';

  @override
  String destinationSignInNote(Object provider) {
    return 'You sign in to $provider when you save. Tapture can reach only the files it creates there.';
  }

  @override
  String get destinationSignInUnavailable =>
      'Signing in to this provider is not available on this device.';

  @override
  String get destinationSignInMismatch =>
      'The sign-in did not finish. Try saving again.';

  @override
  String get destinationFolderRoot => 'the top folder';

  @override
  String get destinationRemoveNothing =>
      'The destination and its sign-in are both still saved.';

  @override
  String get destinationRemoveHalf =>
      'The sign-in was removed, but the destination is still listed.';

  @override
  String get destinationRemoveAgain => 'Try removing it again.';

  @override
  String get destinationRestoreFailed =>
      'The destination could not be put back.';

  @override
  String get destinationAddAgain => 'Add it again.';

  @override
  String get destinationKept => 'The destination was kept.';

  @override
  String get destinationKeptRecovery => 'Remove it later if you still want to.';

  @override
  String destinationRemoved(Object label) {
    return '$label was removed.';
  }

  @override
  String destinationRestored(Object label) {
    return '$label is back.';
  }

  @override
  String destinationSaved(Object label) {
    return '$label was saved.';
  }

  @override
  String destinationCheckPassed(Object label) {
    return 'The connection to $label works.';
  }

  @override
  String destinationCheckedAt(Object dateFormatyMMMdformat) {
    return 'Checked $dateFormatyMMMdformat';
  }

  @override
  String destinationCheckFailedAt(Object reason) {
    return 'Check failed: $reason';
  }

  @override
  String get destinationChecking => 'Checking the connection…';

  @override
  String get destinationUnavailableHeadline => 'Uploads are sent from a device';

  @override
  String get destinationUnavailableMessage =>
      'Open Tapture on a phone or computer to add a destination.';

  @override
  String get uploadConfirmTitle => 'Send this file?';

  @override
  String get uploadConfirm => 'Send';

  @override
  String uploadConfirmMessage(
    Object name,
    Object size,
    Object destination,
    Object folder,
  ) {
    return '$name ($size) will be sent to $destination, in $folder.';
  }

  @override
  String get uploadHistoryTitle => 'Uploads';

  @override
  String get uploadHistoryEmptyHeadline => 'No uploads yet';

  @override
  String get uploadHistoryEmptyMessage =>
      'A file appears here after you confirm sending it.';

  @override
  String get uploadRetry => 'Retry';

  @override
  String get uploadFilter => 'Destination';

  @override
  String get uploadFilterAll => 'All destinations';

  @override
  String get uploadHistoryEmptyAction => 'Set up a destination';

  @override
  String get uploadToDestination => 'Upload to a destination';

  @override
  String get uploadPickTitle => 'Send to';

  @override
  String uploadStarted(Object destination) {
    return 'Sending to $destination. Follow it under Uploads.';
  }

  @override
  String get uploadView => 'View';

  @override
  String uploadSent(Object name, Object destination) {
    return '$name was sent to $destination.';
  }

  @override
  String uploadNotSent(Object reason) {
    return 'Not sent. $reason';
  }

  @override
  String get uploadStopped =>
      'The upload was stopped. The file on this device is unchanged.';

  @override
  String get uploadFileMissing =>
      'The file is no longer on this device as it was exported.';

  @override
  String get uploadFileMissingRecovery => 'Export it again, then send it.';

  @override
  String get uploadDestinationGone => 'That destination was removed.';

  @override
  String get uploadDestinationGoneRecovery =>
      'Send the file again from its export.';

  @override
  String get uploadOutcomeSent => 'Sent';

  @override
  String get uploadOutcomeFailed => 'Failed';

  @override
  String get uploadOutcomeInterrupted => 'Interrupted';

  @override
  String get uploadOutcomeStopped => 'Stopped';

  @override
  String uploadAttemptLine(
    Object outcome,
    Object destination,
    Object size,
    Object when,
  ) {
    return '$outcome · $destination · $size · $when';
  }

  @override
  String uploadSendingLine(Object destination, int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return 'Sending to $destination · $percentString%';
  }

  @override
  String get uploadStop => 'Stop upload';

  @override
  String get uploadDetails => 'Details';

  @override
  String uploadDetailsMessage(Object reason) {
    return '\nReason: $reason';
  }

  @override
  String uploadDetailsMessageFileDestinationFolderSize(
    Object file,
    Object destination,
    Object folder,
    Object size,
    Object whenstartedAt,
    Object ended,
    Object outcome,
    Object because,
  ) {
    return 'File: $file\nDestination: $destination\nFolder: $folder\nSize: $size\nStarted: $whenstartedAt\nEnded: $ended\nOutcome: $outcome$because';
  }

  @override
  String get privacyScreenTitle => 'What leaves this device';

  @override
  String get privacyEmptyHeadline => 'Nothing is set up to send';

  @override
  String get privacyEmptyMessage =>
      'Analysis providers and upload destinations appear here when they are added.';

  @override
  String get egressAnalysisSection => 'Analysis';

  @override
  String get egressUploadsSection => 'Uploads';

  @override
  String get egressOfflineNotice =>
      'Offline mode is on, so nothing leaves this device.';

  @override
  String get egressReadText => 'Reading text from photos';

  @override
  String get egressExtractFields => 'Filling fields from a record';

  @override
  String get egressRefineText => 'Tidying captions';

  @override
  String get egressTranscribe => 'Turning speech into text';

  @override
  String egressRow(Object sends, Object destination) {
    return '$sends · to $destination';
  }

  @override
  String get egressSendsText => 'Text only';

  @override
  String get egressSendsImage => 'An image';

  @override
  String get egressSendsAudio => 'Audio';

  @override
  String get egressSendsFile => 'A file';

  @override
  String get egressSendsPackage => 'Encrypted project packages';

  @override
  String get egressRelay => 'Relay for this project';

  @override
  String get egressRelayServer => 'the organisation server';

  @override
  String get egressTextOnly => 'Text only, on-device OCR';

  @override
  String get gpsPrivacyTitle => 'Location';

  @override
  String get gpsPrivacyCapture => 'Save location with captures';

  @override
  String get gpsPrivacyCaptureState => 'On. Change it in capture settings.';

  @override
  String get gpsPrivacyCaptureStateOffChangeItIn =>
      'Off. Change it in capture settings.';

  @override
  String get gpsPrivacyExclude => 'Leave coordinates out of exports';

  @override
  String get gpsPrivacyExcludeEffect =>
      'Exports carry no location fields and no location in photo details.';

  @override
  String get gpsPrivacyRemove => 'Remove saved coordinates';

  @override
  String get gpsPrivacyRemoveTitle => 'Remove saved coordinates?';

  @override
  String gpsPrivacyRemoveMessage(Object project) {
    return 'Every record and photo in $project loses its saved location. The history records who removed them and when.';
  }

  @override
  String get gpsPrivacyRemoveConfirm => 'Remove';

  @override
  String gpsPrivacyRemoved(Object recordsCountcount) {
    return '$recordsCountcount changed. No saved coordinates remain.';
  }

  @override
  String get gpsPrivacyNoProject =>
      'Open a project to remove its saved coordinates.';

  @override
  String get faceBlurTitle => 'Blur faces in exported photos';

  @override
  String get faceBlurEffect =>
      'A photo whose faces cannot be checked on this device stays out of the export.';

  @override
  String get redactionTitle => 'Hide parts before sending';

  @override
  String exportConsentOmitted(Object idsjoin) {
    return 'Omitted without consent: $idsjoin';
  }

  @override
  String get exportPrivacyChanged =>
      'Privacy settings changed. Export a new file before sharing.';

  @override
  String get redactionHint =>
      'Drag across anything that must not be sent. The photo itself does not change.';

  @override
  String get redactionSave => 'Save hidden areas';

  @override
  String redactionCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString areas hidden',
      one: '1 area hidden',
      zero: 'Nothing hidden yet',
    );
    return '$_temp0';
  }

  @override
  String get redactionSaved =>
      'Saved. These areas are covered in every copy sent for analysis.';

  @override
  String get redactionEmptyHeadline => 'No photo to mark';

  @override
  String get redactionEmptyMessage =>
      'Open a photo from a record, then mark what to hide.';

  @override
  String get permissionLocation =>
      'Tapture saves a location only when you turn location on for a project.';

  @override
  String get permissionStorage =>
      'Tapture opens photos and files you choose to import.';

  @override
  String get permissionNotifications =>
      'Tapture tells you when a batch of analysis finishes.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacySubtitle =>
      'What can leave this device, and what never does.';

  @override
  String get backendSettingsTitle => 'Organisation';

  @override
  String get relayChooseProject =>
      'Open a project to exchange changes with its other devices.';

  @override
  String get relayEnable => 'Enable relay';

  @override
  String get relayEnableHelp =>
      'Encrypted packages pass through the organisation server temporarily.';

  @override
  String get relaySharedKey => 'Shared project key';

  @override
  String get relayKeyHelp =>
      'Use the same key of at least 16 characters on each device. Exchange it separately; it never goes to the server.';

  @override
  String get relayQueueProject => 'Queue project package';

  @override
  String get relaySync => 'Sync relay';

  @override
  String get relayReceivedPackage => 'Preview received changes';

  @override
  String get shippedSuggestWithAi => 'Suggest with AI';

  @override
  String get shippedAiSuggestion => 'AI suggestion';

  @override
  String get shippedAiSuggestionHelp =>
      'Suggested order only. Preview and choose the templates you want.';

  @override
  String get backendServerAddress => 'Server address';

  @override
  String get backendConfigurationHelp =>
      'Use the HTTPS address supplied by your administrator. Leave Organisation empty when this server hosts one organisation.';

  @override
  String get backendNotSignedIn => 'Not signed in';

  @override
  String get backendSignedIn => 'Signed in on this device';

  @override
  String get backendGrantUntil => 'Cached access until';

  @override
  String get backendRole => 'Role';

  @override
  String get backendRoleName => 'Administrator';

  @override
  String get backendRoleNameProjectManager => 'Project manager';

  @override
  String get backendRoleNameReviewer => 'Reviewer';

  @override
  String get backendRoleNameFieldOperator => 'Field operator';

  @override
  String get backendEnrolment => 'Enrolment';

  @override
  String get backendNotEnrolled => 'Not enrolled';

  @override
  String get backendEnrolling => 'Signing in';

  @override
  String get backendEnrolled => 'Enrolled';

  @override
  String get backendRevokedState => 'Ended by the organisation';

  @override
  String get backendRevoked =>
      'The organisation ended this device’s sign-in. Sign in again when the server is reachable. Work on this device continues.';

  @override
  String get signInLater => 'Continue without signing in';

  @override
  String get signOutAction => 'Sign out';

  @override
  String get backendSettingsSubtitle =>
      'The server this device is enrolled with.';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInAction => 'Sign in';

  @override
  String get signInEmail => 'Email';

  @override
  String get signInPassword => 'Password';

  @override
  String get signInOrganisation => 'Organisation';

  @override
  String get backendUnreachable =>
      'The server cannot be reached. Work on this device continues.';

  @override
  String get backendGrantExpired =>
      'The saved sign-in has expired for relay, analysis and role changes.';

  @override
  String get signOutTitle => 'Sign out';

  @override
  String get signOutMessage =>
      'Signing back in needs a connection to the server.';

  @override
  String get relayTitle => 'Change relay';

  @override
  String get relayOff => 'Relay is off until a project manager enables it.';

  @override
  String get relaySignInNeeded =>
      'Sign in to use the relay. Work on this device continues.';

  @override
  String get relayAddKey => 'Add shared key';

  @override
  String get relayNever => 'This project never uses the relay.';

  @override
  String get relaySend => 'Send changes';

  @override
  String get relayQueued => 'Queued';

  @override
  String get relaySent => 'Sent';

  @override
  String get relayPurged => 'Purged';

  @override
  String get frictionLogAction => 'Something went wrong here';

  @override
  String get frictionNote => 'Note (optional)';

  @override
  String get frictionScreenshot => 'Include a screenshot';

  @override
  String get frictionSave => 'Save report';

  @override
  String get frictionSaved => 'Report saved on this device.';

  @override
  String get frictionExport => 'Export field trial log';

  @override
  String get frictionSaving => 'Your report is being saved.';

  @override
  String get frictionScreenshotFailed =>
      'The screenshot could not be captured.';

  @override
  String get frictionScreenshotRecovery =>
      'Try again or turn off the screenshot and save the report.';

  @override
  String get feedbackJournalInvalid => 'Your saved feedback could not be read.';

  @override
  String get feedbackJournalRecovery =>
      'Try again. Keep the saved files so they can be recovered.';

  @override
  String get feedbackImageMissing => 'A saved feedback image is missing.';

  @override
  String get feedbackImageRecovery =>
      'Restore the saved image, then export the feedback again.';

  @override
  String copyAnd(Object named0, Object named1) {
    return '$named0 and $named1';
  }

  @override
  String copyAndAnd(Object namedsublist0, Object namedlast) {
    return '$namedsublist0 and $namedlast';
  }

  @override
  String get gallerySampleName => 'Name';

  @override
  String get gallerySampleCaption => 'Caption';

  @override
  String get gallerySampleCount => 'Count';

  @override
  String get gallerySampleEmail => 'Email';

  @override
  String get gallerySamplePhone => 'Phone';

  @override
  String get gallerySampleWhen => 'When';

  @override
  String get gallerySampleGrade => 'Grade';

  @override
  String get gallerySampleFuel => 'Fuel';

  @override
  String get gallerySampleTags => 'Tags';

  @override
  String get gallerySampleLocation => 'GPS';

  @override
  String get gallerySampleStampCapture => 'Stamp each capture';

  @override
  String get gallerySampleBoilerA => 'Boiler A';

  @override
  String get gallerySampleBoilerB => 'Boiler B';

  @override
  String get gallerySampleBesideList => 'Open beside this list';

  @override
  String get gallerySampleWater => 'Water';

  @override
  String get gallerySampleSteam => 'Steam';

  @override
  String get gallerySampleGas => 'Gas';

  @override
  String get gallerySampleChip => 'Chip';

  @override
  String get gallerySampleFilter => 'Filter';

  @override
  String get gallerySampleListTile => 'List tile';

  @override
  String get gallerySampleSecondaryLine => 'Secondary line';

  @override
  String surfacePreviewLevel(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Level $levelString';
  }

  @override
  String typeRampSample(String name) {
    return 'The $name role — Tap it. It\'s data.';
  }

  @override
  String get importAnotherDevice => 'another device';

  @override
  String get conflictUnknownDevice => 'Unknown device';

  @override
  String recordValueSource(String source) {
    return 'Source: $source';
  }

  @override
  String recycleDeletedWhen(String when) {
    return 'Deleted $when';
  }

  @override
  String exportIncompleteCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString incomplete';
  }

  @override
  String exportUnapprovedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString not approved';
  }

  @override
  String exportBlockedMeetingCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString with meeting actions missing an owner or due date, which stay out';
  }

  @override
  String exportFaceCount(String id, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$id: $countString faces';
  }

  @override
  String mergeHistoryStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'applied': 'Merged',
      'undone': 'Undone',
      'imported': 'Imported',
      'other': 'Failed',
    });
    return '$_temp0';
  }

  @override
  String mergeHistoryCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'records': 'New records',
      'updated_records': 'Updated records',
      'photos': 'New photos',
      'photos_here': 'Photos already here',
      'files': 'Files',
      'deletions': 'Deletions',
      'conflicts': 'Conflicts',
      'kept': 'Values kept',
      'elsewhere': 'Already in another project',
      'duplicates': 'Possible duplicates',
      'skipped': 'Skipped records',
      'other': '$category',
    });
    return '$_temp0';
  }

  @override
  String mergeHistoryChoice(String choice) {
    String _temp0 = intl.Intl.selectLogic(choice, {
      'mine': 'Kept this device’s value',
      'theirs': 'Used incoming value',
      'typed': 'Entered a replacement',
      'keepBoth': 'Kept both templates',
      'other': 'Waiting for a decision',
    });
    return '$_temp0';
  }

  @override
  String relayPackageTooLarge(String bytes, String ceiling) {
    return 'This encrypted package would be $bytes; relay accepts packages up to $ceiling.';
  }

  @override
  String get relayPackageTooLargeRecovery =>
      'Share the exported package directly or export a smaller selection.';

  @override
  String get permissionBiometrics =>
      'Tapture uses biometrics only when you choose biometric app unlock.';

  @override
  String get packageMetadataTooLargeRecovery =>
      'Choose a smaller package scope on the exporting device, then open the new package.';

  @override
  String get failureCancelledMessage => 'The action was cancelled.';

  @override
  String get failureCancelledRecovery =>
      'Start the action again if you still need it.';

  @override
  String get failureCorruptionMessage => 'This file or row could not be read.';

  @override
  String get failureCorruptionRecovery =>
      'Keep the original. Export a copy and try opening it again.';

  @override
  String get failureNetworkMessage =>
      'The network is not available. Work on this device is saved.';

  @override
  String get failureNetworkRecovery =>
      'Keep capturing. Processing will retry when you are back online.';

  @override
  String get failurePermissionMessage =>
      'Tapture does not have permission to do that.';

  @override
  String get failurePermissionRecovery =>
      'Allow the permission in settings, then try again.';

  @override
  String get failureProviderMessage => 'A service this screen uses failed.';

  @override
  String get failureProviderRecovery =>
      'Try again. Nothing already captured was lost.';

  @override
  String get failureStorageMessage =>
      'The photo could not be saved on this device.';

  @override
  String get failureStorageRecovery =>
      'Free up space or export a project, then try again.';

  @override
  String get failureValidationMessage => 'That value is not valid.';

  @override
  String get failureValidationRecovery =>
      'Correct the highlighted field and save again.';

  @override
  String get processingTimeout => 'The provider did not answer in time.';

  @override
  String get processingMalformedResponse =>
      'The provider response could not be read.';

  @override
  String get processingStopped => 'Processing stopped.';

  @override
  String get failureAIIsNotAvailable => 'AI is not available.';

  @override
  String get failureContinueCapturingAnalysisCanWait =>
      'Continue capturing. Analysis can wait.';

  @override
  String get failureThatPhotoIsNotOnThisDevice =>
      'That photo is not on this device.';

  @override
  String get failureCaptureThePhotoAgainThenTryAgain =>
      'Capture the photo again, then try again.';

  @override
  String get failureThatPhotoCouldNotBeReadOn =>
      'That photo could not be read on this device.';

  @override
  String get failureUseAnotherPhotoOrEnterTheValue =>
      'Use another photo or enter the value by hand.';

  @override
  String get failureThatPhotoCouldNotBeReadAs =>
      'That photo could not be read as an image.';

  @override
  String get failureTheAnalysisCopyCouldNotBeRead =>
      'The analysis copy could not be read.';

  @override
  String get failureKeepTheRecordAndTryAgain =>
      'Keep the record and try again.';

  @override
  String get failureTheAnalysisResponseCouldNotBeRead =>
      'The analysis response could not be read.';

  @override
  String get failureAnalysisCanWait => 'Analysis can wait.';

  @override
  String get failureTheAnalysisQuotaIsUsedUp =>
      'The analysis quota is used up.';

  @override
  String get failureAnalysisIsPausedOnTheServerFor =>
      'Analysis is paused on the server for a moment.';

  @override
  String get failureContinueCapturingAnalysisTriesAgainLater =>
      'Continue capturing. Analysis tries again later.';

  @override
  String get failureAnalysisAccessIsUnavailableForThisProject =>
      'Analysis access is unavailable for this project.';

  @override
  String get failureContinueCapturingAndCheckOrganisationAccess =>
      'Continue capturing and check organisation access.';

  @override
  String get failureTheAnalysisMediaIsTooLargeTo =>
      'The analysis media is too large to send.';

  @override
  String get failureKeepTheRecordAndCompleteItWithout =>
      'Keep the record and complete it without analysis.';

  @override
  String get failureSignInWasNotAccepted => 'Sign-in was not accepted.';

  @override
  String get failureCheckYourEmailPasswordAndOrganisation =>
      'Check your email, password and organisation.';

  @override
  String get failureTheOrganisationEndedThisDeviceSSign =>
      'The organisation ended this device’s sign-in.';

  @override
  String get failureSignInAgainWhenTheServerIs =>
      'Sign in again when the server is reachable. Work on this device continues.';

  @override
  String get failureTheServerCouldNotCompleteSignIn =>
      'The server could not complete sign-in.';

  @override
  String get failureTryAgainWhenTheServerIsReachable =>
      'Try again when the server is reachable. Work on this device continues.';

  @override
  String get failureTheSavedSignInCouldNotBe =>
      'The saved sign-in could not be read.';

  @override
  String get failureCheckTheAccountSettingsYourLocalWork =>
      'Check the account settings. Your local work is unchanged.';

  @override
  String get failureEnterTheOrganisationSHTTPSServerAddress =>
      'Enter the organisation’s HTTPS server address.';

  @override
  String get failureCheckTheAddressWithYourAdministrator =>
      'Check the address with your administrator.';

  @override
  String get failureSignOutBeforeChangingOrganisation =>
      'Sign out before changing organisation.';

  @override
  String get failureKeepTheCurrentAccountOrSignOut =>
      'Keep the current account or sign out first.';

  @override
  String get failureTheOrganisationServerCouldNotBeReached =>
      'The organisation server could not be reached.';

  @override
  String get failureContinueWorkingOfflineAndTryAgainLater =>
      'Continue working offline and try again later.';

  @override
  String get failureUseASharedKeyOfAtLeast =>
      'Use a shared key of at least 16 characters.';

  @override
  String get failureAskTheProjectManagerForTheSame =>
      'Ask the project manager for the same key used on the other devices.';

  @override
  String get failureThisProjectIsRegisteredOnTheServer =>
      'This project is registered on the server to others.';

  @override
  String get failureAskAnAdministratorToAddYouTo =>
      'Ask an administrator to add you to it. Work on this device continues.';

  @override
  String get failureAddTheSharedProjectKeyFirst =>
      'Add the shared project key first.';

  @override
  String get failureAskTheProjectManagerForTheKey =>
      'Ask the project manager for the key.';

  @override
  String get failureRelayCouldNotCompleteThisRequest =>
      'Relay could not complete this request.';

  @override
  String get failureKeepWorkingLocallyAndTrySyncAgain =>
      'Keep working locally and try Sync again.';

  @override
  String get failureThatPasswordDidNotOpenTheBundle =>
      'That password did not open the bundle.';

  @override
  String get failureTryThePasswordAgainNothingWasExtracted =>
      'Try the password again. Nothing was extracted.';

  @override
  String get failureTheProjectMetadataIsTooLargeFor =>
      'The project metadata is too large for one package.';

  @override
  String get failureChooseASmallerPackageScope =>
      'Choose a smaller package scope.';

  @override
  String get failurePasswordProtectionIsUnavailableOnThisDevice =>
      'Password protection is unavailable on this device.';

  @override
  String get failureOpenThisPackageOnASupportedDevice =>
      'Open this package on a supported device.';

  @override
  String get failurePasswordProtectionNeedsBrowserCryptography =>
      'Password protection needs browser cryptography.';

  @override
  String get failureOpenTheAppThroughASecureConnection =>
      'Open the app through a secure connection.';

  @override
  String get failureThisBundleNeedsAPassword => 'This bundle needs a password.';

  @override
  String get failureEnterItsPasswordToOpenIt =>
      'Enter its password to open it.';

  @override
  String get failureTheBundleContainsASecretAndWas =>
      'The bundle contains a secret and was not written.';

  @override
  String get failureRemoveTheSecretAndExportTheBundle =>
      'Remove the secret and export the bundle again.';

  @override
  String get failureTheBundleHasTooManyNestedArchives =>
      'The bundle has too many nested archives.';

  @override
  String get failureANestedBundleArchiveCouldNotBe =>
      'A nested bundle archive could not be safely checked.';

  @override
  String get failureAnEncryptedOrUnsupportedAttachmentCouldNot =>
      'An encrypted or unsupported attachment could not be checked.';

  @override
  String get failureANestedBundleArchiveIsTooLarge =>
      'A nested bundle archive is too large.';

  @override
  String get failureANestedBundleEntryHasAnInvalid =>
      'A nested bundle entry has an invalid size.';

  @override
  String get failureANestedBundleEntryExceedsItsDeclared =>
      'A nested bundle entry exceeds its declared size.';

  @override
  String get failureFinishReadingTheCurrentPackageEntryFirst =>
      'Finish reading the current package entry first.';

  @override
  String get failureThePackageEntryIsMissing => 'The package entry is missing.';

  @override
  String get failureReadThisLargePackageEntryAsA =>
      'Read this large package entry as a stream.';

  @override
  String get failureThePackageEntryChanged => 'The package entry changed.';

  @override
  String get failureThePackageEntryChecksumChanged =>
      'The package entry checksum changed.';

  @override
  String failureNoUploadDestinationIsRegisteredForValue(String value0) {
    return 'No upload destination is registered for $value0.';
  }

  @override
  String get failureChooseAnotherDestination => 'Choose another destination.';

  @override
  String get failureTheDestinationRefusedTheSignIn =>
      'The destination refused the sign-in.';

  @override
  String get failureCheckTheKeyOrSignInAgain =>
      'Check the key or sign in again.';

  @override
  String get failureThatBucketOrFolderWasNotFound =>
      'That bucket or folder was not found.';

  @override
  String get failureCheckTheNameAndTryTheConnection =>
      'Check the name and try the connection again.';

  @override
  String get failureTheDestinationDidNotFinishTheUpload =>
      'The destination did not finish the upload.';

  @override
  String get failureTryAgain => 'Try again.';

  @override
  String get failureTheServerRedirectedTheUploadToAnother =>
      'The server redirected the upload to another host.';

  @override
  String get failureCheckTheAddressAndTryAgain =>
      'Check the address and try again.';

  @override
  String get failureTheDestinationRejectedTheUpload =>
      'The destination rejected the upload.';

  @override
  String get failureCheckTheSettingsAndTryAgain =>
      'Check the settings and try again.';

  @override
  String get failureTheFileCouldNotBeReadWhile =>
      'The file could not be read while it was being sent.';

  @override
  String get failureCheckThatTheFileIsStillOn =>
      'Check that the file is still on this device, then retry.';

  @override
  String get failureUploadsArePausedWhileTheAppIs =>
      'Uploads are paused while the app is offline.';

  @override
  String get failureGoOnlineThenConfirmTheUploadAgain =>
      'Go online, then confirm the upload again.';

  @override
  String get failureUploadsToThisDestinationAreTurnedOff =>
      'Uploads to this destination are turned off.';

  @override
  String get failureEnableTheDestinationOnThePrivacyPage =>
      'Enable the destination on the privacy page first.';

  @override
  String get failureCloudSignInCouldNotFinish =>
      'Cloud sign-in could not finish.';

  @override
  String get failureTrySigningInAgain => 'Try signing in again.';

  @override
  String get failureTheDestinationReturnedTooMuchData =>
      'The destination returned too much data.';

  @override
  String get failureCheckTheDestinationAddressAndTryAgain =>
      'Check the destination address and try again.';

  @override
  String get failureTheDestinationCouldNotBeReached =>
      'The destination could not be reached.';

  @override
  String get failureTryAgainWhenYouAreOnline =>
      'Try again when you are online.';

  @override
  String get failureRemoveTheDestinationAndAddItAgain =>
      'Remove the destination and add it again.';

  @override
  String get failureThisDestinationSignInChangedDuringThe =>
      'This destination sign-in changed during the upload.';

  @override
  String get failureReviewTheDestinationAndConfirmANew =>
      'Review the destination and confirm a new upload.';

  @override
  String get failureTheDestinationDidNotAcceptTheTest =>
      'The destination did not accept the test file.';

  @override
  String get failureSignInAgainAndRetryTheTest =>
      'Sign in again and retry the test.';

  @override
  String get failureTheDestinationHasNotFinishedTheUpload =>
      'The destination has not finished the upload.';

  @override
  String get failureRetryTheUpload => 'Retry the upload.';

  @override
  String get failureThatFolderCannotBeWritten =>
      'That folder cannot be written.';

  @override
  String get failureChooseTheFolderAgain => 'Choose the folder again.';

  @override
  String get failureTheFileCouldNotBeWrittenTo =>
      'The file could not be written to that folder.';

  @override
  String get failureFreeSomeSpaceOrChooseTheFolder =>
      'Free some space or choose the folder again.';

  @override
  String get failureThisFolderRequiresASupportedSystemFolder =>
      'This folder requires a supported system folder grant.';

  @override
  String get failureChooseAnAccessibleFolderOrAnotherDestination =>
      'Choose an accessible folder or another destination.';

  @override
  String get failureThatFolderPathIsNotUsable =>
      'That folder path is not usable.';

  @override
  String get failureTheTaptureFolderOnThisDeviceIs =>
      'The Tapture folder on this device is not available.';

  @override
  String get failureCheckTheStorageLocationInSettings =>
      'Check the storage location in Settings.';

  @override
  String get failureThisGoogleDriveSignInIsNo =>
      'This Google Drive sign-in is no longer available.';

  @override
  String get failureSignInToThisDestinationAgain =>
      'Sign in to this destination again.';

  @override
  String get failureGoogleDriveNeedsACurrentSignIn =>
      'Google Drive needs a current sign-in for this account.';

  @override
  String get failureSignInAgainToAllowFileAccess =>
      'Sign in again to allow file access.';

  @override
  String get failureNativeGoogleDriveSignInIsUnavailable =>
      'Native Google Drive sign-in is unavailable.';

  @override
  String get failureTheDestinationIsStillSavedSignIn =>
      'The destination is still saved. Sign in, then try the upload.';

  @override
  String get failureTheUploadChunkSizeIsNotUsable =>
      'The upload chunk size is not usable.';

  @override
  String get failureUseTheStandardUploadSettings =>
      'Use the standard upload settings.';

  @override
  String get failureTheDestinationReturnedAnUnusableUploadResponse =>
      'The destination returned an unusable upload response.';

  @override
  String get failureTestTheDestinationThenTryTheUpload =>
      'Test the destination, then try the upload again.';

  @override
  String get failureTheBucketDidNotAcknowledgeTheUploaded =>
      'The bucket did not acknowledge the uploaded part.';

  @override
  String get failureTestTheDestinationAndTryAgain =>
      'Test the destination and try again.';

  @override
  String get failureTheBucketDidNotFinishTheUpload =>
      'The bucket did not finish the upload.';

  @override
  String get failureTheBucketRefusedToFinishTheUpload =>
      'The bucket refused to finish the upload.';

  @override
  String get failureTheBucketDidNotConfirmTheCompleted =>
      'The bucket did not confirm the completed upload.';

  @override
  String get failureTheDestinationDidNotStartTheUpload =>
      'The destination did not start the upload.';

  @override
  String get failureTryTheConnectionAgain => 'Try the connection again.';

  @override
  String get failureThisDestinationHasNoSavedSignIn =>
      'This destination has no saved sign-in.';

  @override
  String get failureEnterTheKeysAndTestTheConnection =>
      'Enter the keys and test the connection.';

  @override
  String get failureTheSavedSignInIsNotUsable =>
      'The saved sign-in is not usable.';

  @override
  String get failureEnterTheKeysAgain => 'Enter the keys again.';

  @override
  String get failureTheBucketSettingsAreIncomplete =>
      'The bucket settings are incomplete.';

  @override
  String get failureEnterTheKeyRegionAndBucket =>
      'Enter the key, region and bucket.';

  @override
  String get failureChooseAFilenameWithoutFolderSeparators =>
      'Choose a filename without folder separators.';

  @override
  String get failureTheFolderCouldNotOpenANew =>
      'The folder could not open a new file.';

  @override
  String get failureTheFolderCouldNotPublishTheFile =>
      'The folder could not publish the file.';

  @override
  String get failureAccessToTheChosenFolderWasLost =>
      'Access to the chosen folder was lost.';

  @override
  String get failureChooseAnAccessibleFolderAndTryAgain =>
      'Choose an accessible folder and try again.';

  @override
  String get failureTheUploadFilenameIsNotUsable =>
      'The upload filename is not usable.';

  @override
  String get failureEnterTheAddressAndSignInThen =>
      'Enter the address and sign-in, then test it.';

  @override
  String get failureTheDestinationAddressOrSignInIs =>
      'The destination address or sign-in is not usable.';

  @override
  String get failureEnterAFullHTTPSAddressAndSign =>
      'Enter a full HTTPS address and sign-in again.';

  @override
  String get failureGoogleDriveSignInCouldNotFinish =>
      'Google Drive sign-in could not finish.';

  @override
  String get failureThisDestinationNeedsAFreshSignIn =>
      'This destination needs a fresh sign-in.';

  @override
  String get failureTheUploadCheckpointCouldNotBeSaved =>
      'The upload checkpoint could not be saved in time.';

  @override
  String get failureCheckSecureStorageThenTryAgain =>
      'Check secure storage, then try again.';

  @override
  String get failureThatRowIsNoLongerOnThis =>
      'That row is no longer on this device.';

  @override
  String get failureRefreshTheListAndTryAgain =>
      'Refresh the list and try again.';

  @override
  String get failureADeleteNeedsAReason => 'A delete needs a reason.';

  @override
  String get failureSayWhyThisRowShouldBeRemoved =>
      'Say why this row should be removed, then try again.';

  @override
  String get failureTheDatabaseCouldNotCompleteThatWrite =>
      'The database could not complete that write.';

  @override
  String get failureFreeUpSpaceOrExportAProject =>
      'Free up space or export a project, then try again.';

  @override
  String get failureTheDatabaseIsEncryptedAndTheKey =>
      'The database is encrypted and the key is missing.';

  @override
  String get failureRestoreTheKeyFromABackupThen =>
      'Restore the key from a backup, then open the app again.';

  @override
  String get failureTheDatabaseKeyIsMissingOrUnreadable =>
      'The database key is missing or unreadable.';

  @override
  String get failureTypeDISABLEENCRYPTIONToTurnEncryptionOff =>
      'Type DISABLE ENCRYPTION to turn encryption off.';

  @override
  String get failureEnterTheConfirmationExactlyThenTryAgain =>
      'Enter the confirmation exactly, then try again.';

  @override
  String get failureThereIsNoDatabaseToEncrypt =>
      'There is no database to encrypt.';

  @override
  String get failureOpenTheAppOnceSoADatabase =>
      'Open the app once so a database is created, then try again.';

  @override
  String get failureTheDatabaseCouldNotBeEncrypted =>
      'The database could not be encrypted.';

  @override
  String get failureFreeUpSpaceThenTryAgain => 'Free up space, then try again.';

  @override
  String get failureTheEncryptedCopyDidNotMatchThe =>
      'The encrypted copy did not match the original.';

  @override
  String get failureTryEncryptingAgainTheOriginalDatabaseWas =>
      'Try encrypting again. The original database was not changed.';

  @override
  String get failureKeepTheWorkingDatabaseFreeUpSpace =>
      'Keep the working database. Free up space, then close again.';

  @override
  String get failureRestoreTheKeyFromABackupThe =>
      'Restore the key from a backup. The encrypted database was not changed.';

  @override
  String get failureThisUpdateWouldDropOrRewriteA =>
      'This update would drop or rewrite a column.';

  @override
  String get failureExportYourProjectsThenConfirmTheUpdate =>
      'Export your projects, then confirm the update.';

  @override
  String get failureThisDeviceCannotBuildTheRecordSearch =>
      'This device cannot build the record search index.';

  @override
  String get failureUpdateTheAppThenOpenItAgain =>
      'Update the app, then open it again.';

  @override
  String get failureTheFilePathMustStayInsideThe =>
      'The file path must stay inside the project folder.';

  @override
  String get failureSaveTheFileUnderTheProjectFolder =>
      'Save the file under the project folder and try again.';

  @override
  String get failureTheOriginalCaptionCannotBeChanged =>
      'The original caption cannot be changed.';

  @override
  String get failureLeaveTheCapturedTextAndWriteA =>
      'Leave the captured text and write a refined one.';

  @override
  String get failureADuplicatePairNeedsTwoRecords =>
      'A duplicate pair needs two records.';

  @override
  String get failureChooseBothRecordsAndTryAgain =>
      'Choose both records and try again.';

  @override
  String get failureARecordCannotBeADuplicateOf =>
      'A record cannot be a duplicate of itself.';

  @override
  String get failureChooseTwoDifferentRecordsAndTryAgain =>
      'Choose two different records and try again.';

  @override
  String get failureADuplicatePairNeedsAProjectA =>
      'A duplicate pair needs a project, a signal and a score.';

  @override
  String get failureRunDetectionAgainThenTryAgain =>
      'Run detection again, then try again.';

  @override
  String get failureAResolutionNeedsAChoiceAndAn =>
      'A resolution needs a choice and an operator.';

  @override
  String get failureChooseHowToResolveThePairThen =>
      'Choose how to resolve the pair, then try again.';

  @override
  String get failureThatPairIsNoLongerOnThis =>
      'That pair is no longer on this device.';

  @override
  String get failureACompletedExportCannotBeChanged =>
      'A completed export cannot be changed.';

  @override
  String get failureRunANewExportInsteadOfRewriting =>
      'Run a new export instead of rewriting this one.';

  @override
  String get failureAnExportIsRecordedOnlyWhenThe =>
      'An export is recorded only when the file is finished.';

  @override
  String get failureFinishWritingTheFileThenRecordThe =>
      'Finish writing the file, then record the export.';

  @override
  String get failureTheExportFormatsAreNotInA =>
      'The export formats are not in a form Tapture can store.';

  @override
  String get failureFixTheFormatsListAndSaveAgain =>
      'Fix the formats list and save again.';

  @override
  String get failureTheExportFiltersAreNotInA =>
      'The export filters are not in a form Tapture can store.';

  @override
  String get failureStoreTheQueryNotTheExportedValues =>
      'Store the query, not the exported values.';

  @override
  String get failureThatEntryCouldNotBeRead => 'That entry could not be read.';

  @override
  String get failureChangeItThenSaveAgain => 'Change it, then save again.';

  @override
  String get failureTheMarkedAreaOnThePhotoCould =>
      'The marked area on the photo could not be read.';

  @override
  String get failureFixTheRegionObjectAndSaveAgain =>
      'Fix the region object and save again.';

  @override
  String get failureTheMarkedAreaOnThePhotoIs =>
      'The marked area on the photo is not in a form Tapture can store.';

  @override
  String get failureThatMeetingIsNoLongerOnThis =>
      'That meeting is no longer on this device.';

  @override
  String get failureTheOriginalTranscriptCannotBeChanged =>
      'The original transcript cannot be changed.';

  @override
  String get failureLeaveTheCapturedTextAndWriteRefined =>
      'Leave the captured text and write refined minutes.';

  @override
  String get failureTheMeetingAgendaCouldNotBeRead =>
      'The meeting agenda could not be read.';

  @override
  String get failureFixTheAgendaListAndSaveAgain =>
      'Fix the agenda list and save again.';

  @override
  String get failureTheMeetingAgendaIsNotInA =>
      'The meeting agenda is not in a form Tapture can store.';

  @override
  String get failureTheMergeSummaryCouldNotBeRead =>
      'The merge summary could not be read.';

  @override
  String get failureFixTheCountsObjectAndSaveAgain =>
      'Fix the counts object and save again.';

  @override
  String get failureTheMergeSummaryIsNotInA =>
      'The merge summary is not in a form Tapture can store.';

  @override
  String get failureAConflictNeedsAChoiceAndAn =>
      'A conflict needs a choice and an operator.';

  @override
  String get failureChooseASideThenResolveAgain =>
      'Choose a side, then resolve again.';

  @override
  String get failureThatConflictIsNoLongerOnThis =>
      'That conflict is no longer on this device.';

  @override
  String get failureThatJobIsNoLongerOnThis =>
      'That job is no longer on this device.';

  @override
  String get failureRefreshTheQueueAndTryAgain =>
      'Refresh the queue and try again.';

  @override
  String get failureAStoredProviderResponseCannotBeChanged =>
      'A stored provider response cannot be changed.';

  @override
  String get failureLeaveTheOriginalResultAndWriteA =>
      'Leave the original result and write a new one.';

  @override
  String get failureARequestSummaryCannotIncludeASecret =>
      'A request summary cannot include a secret.';

  @override
  String get failureStoreShapeAndSizeOnlyThenSave =>
      'Store shape and size only, then save again.';

  @override
  String get failureTheProjectSettingsCouldNotBeRead =>
      'The project settings could not be read.';

  @override
  String get failureChangeTheSettingsAgainThenSave =>
      'Change the settings again, then save.';

  @override
  String get failureTheProjectSettingsAreNotInA =>
      'The project settings are not in a form Tapture can store.';

  @override
  String get failureThatRecordIsNoLongerOnThis =>
      'That record is no longer on this device.';

  @override
  String get failureTheRecordSContextCouldNotBe =>
      'The record\'s context could not be read.';

  @override
  String get failureFixTheContextObjectAndSaveAgain =>
      'Fix the context object and save again.';

  @override
  String get failureTheRecordSContextIsNotIn =>
      'The record\'s context is not in a form Tapture can store.';

  @override
  String get failureThatValueIsNoLongerOnThis =>
      'That value is no longer on this device.';

  @override
  String get failureRefreshTheRecordAndTryAgain =>
      'Refresh the record and try again.';

  @override
  String get failureTheOriginalValueCannotBeChanged =>
      'The original value cannot be changed.';

  @override
  String get failureLeaveTheCapturedValueAndWriteA =>
      'Leave the captured value and write a refined one.';

  @override
  String get failureADatasetImportNeedsASourceFile =>
      'A dataset import needs a source file and a scope.';

  @override
  String get failureChooseTheFileAndWhereItBelongs =>
      'Choose the file and where it belongs, then import again.';

  @override
  String get failureAProjectDatasetNeedsAProject =>
      'A project dataset needs a project.';

  @override
  String get failureChooseTheProjectThenImportAgain =>
      'Choose the project, then import again.';

  @override
  String get failureAGlobalDatasetCannotBelongToOne =>
      'A global dataset cannot belong to one project.';

  @override
  String get failureClearTheProjectThenImportAgain =>
      'Clear the project, then import again.';

  @override
  String get failureTheDatasetColumnsAreNotInA =>
      'The dataset columns are not in a form Tapture can store.';

  @override
  String get failureFixTheColumnListAndSaveAgain =>
      'Fix the column list and save again.';

  @override
  String get failureAReferenceRowIsNotInA =>
      'A reference row is not in a form Tapture can store.';

  @override
  String get failureFixTheRowValuesAndSaveAgain =>
      'Fix the row values and save again.';

  @override
  String get failureThatEntryIsNotInAForm =>
      'That entry is not in a form Tapture can store.';

  @override
  String get failureAResolutionNeedsAnOperator =>
      'A resolution needs an operator.';

  @override
  String get failureSignInThenResolveTheVarianceAgain =>
      'Sign in, then resolve the variance again.';

  @override
  String get failureThatVarianceIsNoLongerOnThis =>
      'That variance is no longer on this device.';

  @override
  String get failureTheDatabaseIsBusy => 'The database is busy.';

  @override
  String get failureWaitAMomentThenTryTheSave =>
      'Wait a moment, then try the save again.';

  @override
  String get failureARecordWithThatIdentityAlreadyExists =>
      'A record with that identity already exists.';

  @override
  String get failureOpenTheExistingRecordOrChangeThe =>
      'Open the existing record, or change the identity.';

  @override
  String get failureThatPhotoCouldNotBeBlurred =>
      'That photo could not be blurred.';

  @override
  String get failureADetectedFaceIsOutsideThatPhoto =>
      'A detected face is outside that photo.';

  @override
  String get failureFaceDetectionIsUnavailableOnThisDevice =>
      'Face detection is unavailable on this device.';

  @override
  String get failureUseAnAndroidOrIOSDeviceTo =>
      'Use an Android or iOS device to blur faces.';

  @override
  String get failureThisPhotoCannotBeCheckedForFaces =>
      'This photo cannot be checked for faces.';

  @override
  String get failureThisPhotoCannotBeProtected =>
      'This photo cannot be protected.';

  @override
  String get failureAHiddenAreaIsInvalid => 'A hidden area is invalid.';

  @override
  String get failureThisExportFolderAlreadyContainsCompletedFiles =>
      'This export folder already contains completed files.';

  @override
  String get failureCreateTheExportInANewVersion =>
      'Create the export in a new version folder.';

  @override
  String get failureStreamingTextExportNeedsNativeStorage =>
      'Streaming text export needs native storage.';

  @override
  String get failureTaptureCannotCopyAFileFromThis =>
      'Tapture cannot copy a file from this device here.';

  @override
  String get failureAddTheFileAgainFromTaptureThen =>
      'Add the file again from Tapture, then try again.';

  @override
  String failureTaptureCouldNotWriteToValue(String value0) {
    return 'Tapture could not write to $value0.';
  }

  @override
  String get failureTaptureCouldNotNameThatStoredFile =>
      'Tapture could not name that stored file.';

  @override
  String get failureTryAgainIfItKeepsHappeningExport =>
      'Try again. If it keeps happening, export the log.';

  @override
  String get failureTaptureCouldNotSaveThatOnThis =>
      'Tapture could not save that on this device.';

  @override
  String get failureFreeSomeSpaceThenTryAgain =>
      'Free some space, then try again.';

  @override
  String get failureTheCacheCouldNotBeCleanedOn =>
      'The cache could not be cleaned on this device.';

  @override
  String get failureFreeSpaceOrAllowStorageAccessThen =>
      'Free space or allow storage access, then try again.';

  @override
  String get failureThatImageSizeIsNotValid => 'That image size is not valid.';

  @override
  String get failureUseTheAppUploadSizeAndTry =>
      'Use the app upload size and try again.';

  @override
  String get failureTheReducedCopyCouldNotBeCreated =>
      'The reduced copy could not be created on this device.';

  @override
  String failureTaptureCouldNotFindValue(String value0) {
    return 'Tapture could not find $value0.';
  }

  @override
  String failureTaptureCouldNotSaveValue(String value0) {
    return 'Tapture could not save $value0.';
  }

  @override
  String get failureFreeSomeSpaceThenDownloadAgain =>
      'Free some space, then download again.';

  @override
  String get failureOpenDownloadsOnThisDeviceAndLook =>
      'Open Downloads on this device and look in Tapture.';

  @override
  String get failureOnlyFilesInsideAProjectFolderCan =>
      'Only files inside a project folder can be removed for good.';

  @override
  String get failureLeaveTheFileInPlaceThePurge =>
      'Leave the file in place; the purge will skip it.';

  @override
  String get failureThatPhotoHasNoUsableNameFor =>
      'That photo has no usable name for its cached copies.';

  @override
  String get failureLeaveThePhotoInPlaceThePurge =>
      'Leave the photo in place; the purge will skip it.';

  @override
  String get failureADeletedRecordSFilesCouldNot =>
      'A deleted record’s files could not be removed from this device.';

  @override
  String get failureAllowStorageAccessThePurgeTriesAgain =>
      'Allow storage access; the purge tries again next launch.';

  @override
  String get failureThisExportIsTooLargeForThis =>
      'This export is too large for this browser.';

  @override
  String get failureExportFewerRecordsOrUseADesktop =>
      'Export fewer records or use a desktop device.';

  @override
  String failureAnExportSourceIsMissingValue(String value0) {
    return 'An export source is missing: $value0';
  }

  @override
  String get failureANativeFileSystemIsUnavailable =>
      'A native file system is unavailable.';

  @override
  String failureTaptureCouldNotReadValue(String value0) {
    return 'Tapture could not read $value0.';
  }

  @override
  String get failureCaptureOrAddTheFileAgainThen =>
      'Capture or add the file again, then try again.';

  @override
  String get failureThatProjectIsNoLongerOnThis =>
      'That project is no longer on this device.';

  @override
  String get failureOpenAProjectThenTryAgain =>
      'Open a project, then try again.';

  @override
  String get failureRecreateTheProjectFolderThenTryAgain =>
      'Recreate the project folder, then try again.';

  @override
  String failureTheFileValueIsEmpty(String value0) {
    return 'The file $value0 is empty.';
  }

  @override
  String get failureChooseAFileThatHasContentsAnd =>
      'Choose a file that has contents and try again.';

  @override
  String failureTheFileValueIsNotASupported(String value0) {
    return 'The file $value0 is not a supported type.';
  }

  @override
  String get failureChooseAnImageDocumentSpreadsheetAudioFile =>
      'Choose an image, document, spreadsheet, audio file or bundle and try again.';

  @override
  String failureTheFileValueDoesNotMatchIts(String value0) {
    return 'The file $value0 does not match its type.';
  }

  @override
  String get failureChooseAFileOfTheExpectedType =>
      'Choose a file of the expected type and try again.';

  @override
  String failureTheFileValueIsLargerThanThe(String value0, String value1) {
    return 'The file $value0 is larger than the allowed size for a $value1.';
  }

  @override
  String get failureChooseASmallerFileAndTryAgain =>
      'Choose a smaller file and try again.';

  @override
  String failureTheArchiveValueContainsAPathThat(String value0) {
    return 'The archive $value0 contains a path that leaves the folder.';
  }

  @override
  String get failureChooseADifferentFileAndTryAgain =>
      'Choose a different file and try again.';

  @override
  String failureTheArchiveValueContainsALinkInstead(String value0) {
    return 'The archive $value0 contains a link instead of a file.';
  }

  @override
  String failureTheArchiveValueDeclaresMoreUncompressedData(String value0) {
    return 'The archive $value0 declares more uncompressed data than is allowed.';
  }

  @override
  String failureTheFileValueIsNotAnArchive(String value0) {
    return 'The file $value0 is not an archive.';
  }

  @override
  String get failureChooseAZIPBundleOrSpreadsheetAnd =>
      'Choose a ZIP bundle or spreadsheet and try again.';

  @override
  String get failureChooseTheFileAgainThenTryAgain =>
      'Choose the file again, then try again.';

  @override
  String get failureThePhotoCouldNotBeSavedOn =>
      'The photo could not be saved on this device.';

  @override
  String failureThereIsNotEnoughSpaceToSave(String value0) {
    return 'There is not enough space to save $value0.';
  }

  @override
  String get failureAllowStorageAccessThenTryAgain =>
      'Allow storage access, then try again.';

  @override
  String get failureThisPhotoCannotBeMarked => 'This photo cannot be marked.';

  @override
  String get failureThisPackageIsTooLargeOrIncomplete =>
      'This package is too large or incomplete.';

  @override
  String get failureFinishTheCurrentPackageBeforeOpeningAnother =>
      'Finish the current package before opening another.';

  @override
  String get failureThisPackageIsTooLargeToOpen =>
      'This package is too large to open.';

  @override
  String get failureThisPackageCouldNotBeOpened =>
      'This package could not be opened.';

  @override
  String get failureOpenTheFileAgainFromItsOriginal =>
      'Open the file again from its original location.';

  @override
  String get failureThatProjectCouldNotBeScanned =>
      'That project could not be scanned.';

  @override
  String get failureOpenTheProjectAndTryAgain =>
      'Open the project and try again.';

  @override
  String get failureTheProjectFolderCouldNotBeScanned =>
      'The project folder could not be scanned on this device.';

  @override
  String get failurePutTheFileBackInTheProject =>
      'Put the file back in the project folder, then try again.';

  @override
  String get failureTheFileCouldNotBeAdoptedOn =>
      'The file could not be adopted on this device.';

  @override
  String get failureTheMissingFileCouldNotBeFlagged =>
      'The missing file could not be flagged on this device.';

  @override
  String get failureThatFileRowIsNoLongerOn =>
      'That file row is no longer on this device.';

  @override
  String get failureThatNameIsNotAValidFolder =>
      'That name is not a valid folder.';

  @override
  String get failureChooseANameWithoutSlashesThatPoint =>
      'Choose a name without slashes that point elsewhere.';

  @override
  String get failureChooseANameWithLettersOrDigits =>
      'Choose a name with letters or digits.';

  @override
  String get failureTheFilePathMustStayInsideThe2 =>
      'The file path must stay inside the storage folder.';

  @override
  String get failureThatPhotoIsNoLongerAvailable =>
      'That photo is no longer available.';

  @override
  String get failureHiddenAreasChangedTrySendingAgain =>
      'Hidden areas changed. Try sending again.';

  @override
  String get failureCheckTheHiddenAreasOnThisEdited =>
      'Check the hidden areas on this edited photo before sending it.';

  @override
  String get failureOpenHidePartsBeforeSendingAndSave =>
      'Open Hide parts before sending and save the areas for this version.';

  @override
  String get failureTheProjectFolderCouldNotBeRemoved =>
      'The project folder could not be removed from this device.';

  @override
  String get failureDeleteTheLeftoverFolderThenTryAgain =>
      'Delete the leftover folder, then try again.';

  @override
  String get failureThatProjectIsAlreadyInTheRecycle =>
      'That project is already in the recycle area on this device.';

  @override
  String get failureRestoreItFromTheRecycleAreaThen =>
      'Restore it from the recycle area, then try again.';

  @override
  String get failureTheProjectFolderCouldNotBeMoved =>
      'The project folder could not be moved to the recycle area.';

  @override
  String get failureThisProjectHasNoFolderOnDisk =>
      'This project has no folder on disk yet.';

  @override
  String get failureCreateTheProjectFolderThenTryAgain =>
      'Create the project folder, then try again.';

  @override
  String get failureTheProjectFolderCouldNotBeCreated =>
      'The project folder could not be created on this device.';

  @override
  String get failureThatProjectFolderNameIsNotA =>
      'That project folder name is not a valid folder.';

  @override
  String get failureRecreateTheProjectSoItsFolderCan =>
      'Recreate the project so its folder can be rebuilt.';

  @override
  String get failureThereIsNotEnoughFreeSpaceTo =>
      'There is not enough free space to take another photo.';

  @override
  String get failureExportAProjectOrCleanTheCache =>
      'Export a project or clean the cache, then try again.';

  @override
  String get failureTaptureCouldNotReadFreeSpaceOn =>
      'Tapture could not read free space on this device.';

  @override
  String get failureThisDeviceHasNoFolderTaptureCan =>
      'This device has no folder Tapture can keep project files in.';

  @override
  String get failureUseTaptureOnAPhoneTabletOr =>
      'Use Tapture on a phone, tablet or computer to keep files.';

  @override
  String get failureTheThumbnailCouldNotBeCreatedOn =>
      'The thumbnail could not be created on this device.';

  @override
  String get failureThatThumbnailSizeIsNotValid =>
      'That thumbnail size is not valid.';

  @override
  String get failureUseTheAppThumbnailSizeAndTry =>
      'Use the app thumbnail size and try again.';

  @override
  String get failureThatPhotoCouldNotBeCached =>
      'That photo could not be cached.';

  @override
  String get failureLocationIsOffForThisProject =>
      'Location is off for this project.';

  @override
  String get failureTurnGPSOnThenTryAgain => 'Turn GPS on, then try again.';

  @override
  String get failureBiometricAuthenticationIsUnavailable =>
      'Biometric authentication is unavailable.';

  @override
  String get failureUnlockWithYourAppPIN => 'Unlock with your app PIN.';

  @override
  String get failureTheSecretCouldNotBeSavedOn =>
      'The secret could not be saved on this device.';

  @override
  String get failureTheSecretCouldNotBeReadOn =>
      'The secret could not be read on this device.';

  @override
  String get failureTheSecretCouldNotBeRemovedFrom =>
      'The secret could not be removed from this device.';

  @override
  String get failureTypeTheWordsToPlaceOnThis =>
      'Type the words to place on this photo.';

  @override
  String get failureEnterTextThenSaveThePhoto =>
      'Enter text, then save the photo.';

  @override
  String get failureDiscardTheInterruptedSessionAndStartAgain =>
      'Discard the interrupted session and start again.';

  @override
  String get failureOnlyARecordEditCanBeSaved =>
      'Only a record edit can be saved here.';

  @override
  String get failureGoBackToTheProjectAndPick =>
      'Go back to the project and pick another record.';

  @override
  String get failureTheCaptureSessionIsNotValid =>
      'The capture session is not valid.';

  @override
  String get failureCompletePhotoMetadataIsRequiredForA =>
      'Complete photo metadata is required for a new capture.';

  @override
  String get failureThePhotoProjectWasNotFound =>
      'The photo project was not found.';

  @override
  String get failureThatPhotoCouldNotBeReadFrom =>
      'That photo could not be read from this device.';

  @override
  String get failureTheOriginalPhotoStaysInPlace =>
      'The original photo stays in place.';

  @override
  String get failureRevertAnEditedPhotoInstead =>
      'Revert an edited photo instead.';

  @override
  String get failureThisPhotoAppearsMoreThanOnce =>
      'This photo appears more than once.';

  @override
  String get failureReloadTheCaptureAndTryAgain =>
      'Reload the capture and try again.';

  @override
  String get failureAnEditedPhotoIsMissingItsOriginal =>
      'An edited photo is missing its original.';

  @override
  String get failureKeepThisCaptureAndRestoreTheOriginal =>
      'Keep this capture and restore the original photo.';

  @override
  String get failureThesePhotoEditsLoopBackOnThemselves =>
      'These photo edits loop back on themselves.';

  @override
  String get failureThatFieldIsNotOnThisRecord =>
      'That field is not on this record.';

  @override
  String get failureOpenTheRecordAndTryAgain =>
      'Open the record and try again.';

  @override
  String get failureThatFieldIsNotAContextLevel =>
      'That field is not a context level.';

  @override
  String get failurePickALevelFromTheHierarchyAnd =>
      'Pick a level from the hierarchy and try again.';

  @override
  String get failureAPresetNeedsAName => 'A preset needs a name.';

  @override
  String get failureEnterANameAndTryAgain => 'Enter a name and try again.';

  @override
  String get failureADeleteNeedsAnIdAndA =>
      'A delete needs an id and a reason.';

  @override
  String get failureContextIsNotAvailableYet => 'Context is not available yet.';

  @override
  String get failureRestartTheAppAndTryAgain =>
      'Restart the app and try again.';

  @override
  String get failureAPresetWithThatNameAlreadyExists =>
      'A preset with that name already exists.';

  @override
  String get failureChooseAnotherNameOrConfirmOverwrite =>
      'Choose another name, or confirm overwrite.';

  @override
  String get failureTheProjectWasNotFound => 'The project was not found.';

  @override
  String get failureAnExportedRecordIsNoLongerAvailable =>
      'An exported record is no longer available.';

  @override
  String get failureAnExportedPhotoIsNoLongerAvailable =>
      'An exported photo is no longer available.';

  @override
  String get failureASelectedRecordIsMissingRefreshThe =>
      'A selected record is missing. Refresh the export.';

  @override
  String get failureAnExportNeedsAProject => 'An export needs a project.';

  @override
  String get failureOpenAProjectAndExportAgain =>
      'Open a project and export again.';

  @override
  String get failureThisExportedPhotoCannotBeRead =>
      'This exported photo cannot be read.';

  @override
  String get failureThisPhotoFormatCannotBePackagedSafely =>
      'This photo format cannot be packaged safely.';

  @override
  String get failureProjectFilesAreUnavailableOnThisDevice =>
      'Project files are unavailable on this device.';

  @override
  String get failureOpenAProjectStoredOnThisDevice =>
      'Open a project stored on this device and try again.';

  @override
  String get failureWriteYourFeedbackThenSaveAgain =>
      'Write your feedback, then save again.';

  @override
  String get failureNameTheTypeThenSaveAgain =>
      'Name the type, then save again.';

  @override
  String get failureChangeOrClearTheFiltersThenTry =>
      'Change or clear the filters, then try again.';

  @override
  String get failureCloseThisTapFeedbackThenTryAgain =>
      'Close this, tap Feedback, then try again.';

  @override
  String get failureCorrectTheHighlightedFieldAndSaveAgain =>
      'Correct the highlighted field and save again.';

  @override
  String get failureTheTemplateTheseRowsWereMatchedTo =>
      'The template these rows were matched to is no longer here.';

  @override
  String get failureChooseAnotherTemplateAndImportAgain =>
      'Choose another template and import again.';

  @override
  String get failureARecordARowMatchedIsNo =>
      'A record a row matched is no longer on this device.';

  @override
  String get failureImportTheFileAgainToMatchIt =>
      'Import the file again to match it afresh.';

  @override
  String get failureRecordsCannotBeImportedRightNow =>
      'Records cannot be imported right now.';

  @override
  String get failureRestartTaptureThenImportAgain =>
      'Restart Tapture, then import again.';

  @override
  String get failureThatFileIsNotInThisMeeting =>
      'That file is not in this meeting’s project folder.';

  @override
  String get failureAddTheFileToTheMeetingAgain =>
      'Add the file to the meeting again.';

  @override
  String get failureStartTheMeetingAgain => 'Start the meeting again.';

  @override
  String get failureTheSnapshotHasBeenPurged => 'The snapshot has been purged.';

  @override
  String get failureTheMergeCanNoLongerBeUndone =>
      'The merge can no longer be undone.';

  @override
  String get failureTaptureCouldNotLookUpAFile =>
      'Tapture could not look up a file for this project.';

  @override
  String get failureAProjectWithThatIdAlreadyExists =>
      'A project with that id already exists.';

  @override
  String get failureOpenTheExistingProjectOrUseA =>
      'Open the existing project or use a new id.';

  @override
  String get failureProjectPhotosCannotBeStoredOnThis =>
      'Project photos cannot be stored on this device.';

  @override
  String get failureAddThePhotoOnADeviceThat =>
      'Add the photo on a device that stores files.';

  @override
  String get failureAProjectNeedsAName => 'A project needs a name.';

  @override
  String get failureEnterANameAndSaveAgain => 'Enter a name and save again.';

  @override
  String get failureProjectFilesAreNotAvailableOnThis =>
      'Project files are not available on this device.';

  @override
  String get failureExportFromADeviceThatStoresThis =>
      'Export from a device that stores this project.';

  @override
  String get failureThatRecordIsNoLongerInThe =>
      'That record is no longer in the recycle bin.';

  @override
  String get failureNothingToRemoveItWasRestoredOr =>
      'Nothing to remove; it was restored or already removed.';

  @override
  String get failureThatRecordWasDeletedAgainSoIts =>
      'That record was deleted again, so its retention starts over.';

  @override
  String get failureLeaveItThePurgeTakesItOnce =>
      'Leave it; the purge takes it once its new window passes.';

  @override
  String get failureAMergeStillNeedsThatDeletedRecord =>
      'A merge still needs that deleted record.';

  @override
  String get failureSendABundleOrSettleTheMerge =>
      'Send a bundle or settle the merge, then try again.';

  @override
  String get failureRecordsAreNotAvailableYet =>
      'Records are not available yet.';

  @override
  String get failureTheRecordWasSavedButCouldNot =>
      'The record was saved but could not be opened.';

  @override
  String get failureOpenItFromTheRecordsList =>
      'Open it from the records list.';

  @override
  String get failureThatTemplateIsNoLongerOnThis =>
      'That template is no longer on this device.';

  @override
  String get failureChooseAnotherTemplateAndTryAgain =>
      'Choose another template and try again.';

  @override
  String get failureThisRecordAlreadyUsesThatTemplate =>
      'This record already uses that template.';

  @override
  String get failureChooseADifferentTemplate => 'Choose a different template.';

  @override
  String get failureThatTemplateBelongsToAnotherProject =>
      'That template belongs to another project.';

  @override
  String get failureChooseATemplateFromThisProject =>
      'Choose a template from this project.';

  @override
  String get failureARecordNeedsAProjectAndA =>
      'A record needs a project and a template.';

  @override
  String get failureChooseAProjectAndATemplateThen =>
      'Choose a project and a template, then save again.';

  @override
  String get failureSayWhyTheRecordShouldGoThen =>
      'Say why the record should go, then try again.';

  @override
  String get failureAnEditNeedsTheFieldItChanges =>
      'An edit needs the field it changes.';

  @override
  String get failureChooseAFieldThenSaveAgain =>
      'Choose a field, then save again.';

  @override
  String get failureARecordGoesToTheRecycleBin =>
      'A record goes to the recycle bin only through delete.';

  @override
  String get failureUseDeleteWhichLetsYouUndoIt =>
      'Use Delete, which lets you undo it.';

  @override
  String get failureThisRecordIsInTheRecycleBin =>
      'This record is in the recycle bin.';

  @override
  String get failureRestoreItFromTheRecycleBinFirst =>
      'Restore it from the recycle bin first.';

  @override
  String get failureThisRecordIsNotInTheRecycle =>
      'This record is not in the recycle bin.';

  @override
  String get failureRefreshTheListItMayAlreadyBe =>
      'Refresh the list; it may already be restored.';

  @override
  String get failureThisRecordHasAStatusThisVersion =>
      'This record has a status this version of the app does not know.';

  @override
  String get failureUpdateTheAppThenTryAgain =>
      'Update the app, then try again.';

  @override
  String failureThisRecordIsAlreadyValue(String value0) {
    return 'This record is already $value0.';
  }

  @override
  String get failureChooseADifferentStatusOrLeaveIt =>
      'Choose a different status, or leave it as it is.';

  @override
  String failureARecordThatIsValueCannotBe(String value0, String value1) {
    return 'A record that is $value0 cannot be $value1.';
  }

  @override
  String get failureRestoreItFromTheRecycleBinBefore =>
      'Restore it from the recycle bin before changing it.';

  @override
  String get failureTheCapturedTemplateVersionIsUnavailable =>
      'The captured template version is unavailable.';

  @override
  String get failureRestoreTheOriginalProjectPackageBeforeEditing =>
      'Restore the original project package before editing these values.';

  @override
  String get failureAQuotedCSVValueIsUnfinished =>
      'A quoted CSV value is unfinished.';

  @override
  String get failureCloseTheQuotedValueAndImportThe =>
      'Close the quoted value and import the file again.';

  @override
  String get failureThatFileIsEmpty => 'That file is empty.';

  @override
  String get failureChooseACSVWithAHeaderAnd =>
      'Choose a CSV with a header and rows.';

  @override
  String get failureThatTableCouldNotBeReadAs =>
      'That table could not be read as text.';

  @override
  String get failureSaveItAsUTFCSVAndTry =>
      'Save it as UTF-8 CSV and try again.';

  @override
  String get failureThatCSVCouldNotBeRead => 'That CSV could not be read.';

  @override
  String get failureCheckTheFileAndTryAgain => 'Check the file and try again.';

  @override
  String get failureChooseACSVJSONOrXLSXTable =>
      'Choose a CSV, JSON or XLSX table within the import size limit.';

  @override
  String get failureChooseAnotherFileOrSplitThisTable =>
      'Choose another file or split this table into smaller files.';

  @override
  String get failureSaveItAsUTFCSVOrA =>
      'Save it as UTF-8 CSV or a JSON array and try again.';

  @override
  String get failureJSONDatasetsMustBeAnArrayOf =>
      'JSON datasets must be an array of objects.';

  @override
  String get failureWrapTheRowsInAnArrayAnd =>
      'Wrap the rows in an array and try again.';

  @override
  String get failureEveryJSONRowMustBeAnObject =>
      'Every JSON row must be an object.';

  @override
  String get failureRemoveNonObjectRowsAndImportThe =>
      'Remove non-object rows and import the file again.';

  @override
  String get failureThatFileHasNoColumns => 'That file has no columns.';

  @override
  String get failureAddKeysToTheObjectsAndTry =>
      'Add keys to the objects and try again.';

  @override
  String get failureThatJSONIsNotValid => 'That JSON is not valid.';

  @override
  String get failureFixTheJSONArrayAndImportIt =>
      'Fix the JSON array and import it again.';

  @override
  String get failureThatJSONCouldNotBeRead => 'That JSON could not be read.';

  @override
  String get failureThatWorkbookHasNoSheets => 'That workbook has no sheets.';

  @override
  String get failureChooseAWorkbookWithASheetOf =>
      'Choose a workbook with a sheet of data.';

  @override
  String get failureThatSheetHasNoHeaderRow => 'That sheet has no header row.';

  @override
  String get failureAddAHeaderRowAndTryAgain =>
      'Add a header row and try again.';

  @override
  String get failureThatKeyColumnHasDuplicateValues =>
      'That key column has duplicate values.';

  @override
  String get failurePickAnotherKeyColumnOrConfirmDuplicates =>
      'Pick another key column, or confirm duplicates are expected.';

  @override
  String get failureARowNeedsADatasetAndA => 'A row needs a dataset and a key.';

  @override
  String get failureFillThoseFieldsAndSaveAgain =>
      'Fill those fields and save again.';

  @override
  String get failureADatasetNeedsANameAndA =>
      'A dataset needs a name and a key column.';

  @override
  String get failureTheKeyColumnMustBeOneOf =>
      'The key column must be one of the dataset columns.';

  @override
  String get failurePickAKeyFromTheColumnList =>
      'Pick a key from the column list.';

  @override
  String get failureReferenceDataIsNotAvailableYet =>
      'Reference data is not available yet.';

  @override
  String get failureThatTableHasNoDataColumns =>
      'That table has no data columns.';

  @override
  String get failureATemplateNeedsAName => 'A template needs a name.';

  @override
  String get failureOpenAProjectThenAddTheTemplate =>
      'Open a project, then add the template.';

  @override
  String get failureTheShippedTemplatesCouldNotBeRead =>
      'The shipped templates could not be read.';

  @override
  String get failureThatShippedTemplateIsNotOnThis =>
      'That shipped template is not on this device.';

  @override
  String get failurePickAnotherTemplateFromTheLibrary =>
      'Pick another template from the library.';

  @override
  String get failureTheInheritedFieldGroupsCouldNotBe =>
      'The inherited field groups could not be read.';

  @override
  String failureAShippedTemplateIsMissingValue(String value0) {
    return 'A shipped template is missing \"$value0\".';
  }

  @override
  String get failureReinstallTheAppThenTryAgain =>
      'Reinstall the app, then try again.';

  @override
  String get failureAShippedTemplateUsesAnUnknownSchema =>
      'A shipped template uses an unknown schema.';

  @override
  String get failureAShippedTemplateHasAnInvalidKey =>
      'A shipped template has an invalid key.';

  @override
  String get failureAShippedTemplateNameIsNotA =>
      'A shipped template name is not a localisation key.';

  @override
  String get failureAShippedTemplateNamesAnUnknownIdentity =>
      'A shipped template names an unknown identity field.';

  @override
  String get failureAShippedTemplateNamesAnUnknownParent =>
      'A shipped template names an unknown parent.';

  @override
  String get failureAShippedTemplateNamesAnUnknownField =>
      'A shipped template names an unknown field group.';

  @override
  String failureAShippedFieldIsMissingValue(String value0) {
    return 'A shipped field is missing \"$value0\".';
  }

  @override
  String get failureAShippedFieldUsesAnUnknownType =>
      'A shipped field uses an unknown type.';

  @override
  String get failureAShippedFieldLabelIsNotA =>
      'A shipped field label is not a localisation key.';

  @override
  String get failureAShippedTemplateCouldNotBeRead =>
      'A shipped template could not be read.';

  @override
  String get failureAShippedTemplateNamesAnUnknownRecord =>
      'A shipped template names an unknown record type.';

  @override
  String get failureTheTemplateOrItsRecordsChangedWhile =>
      'The template or its records changed while you reviewed the migration.';

  @override
  String get failureReviewTheUpdatedChangesAndTryAgain =>
      'Review the updated changes and try again.';

  @override
  String get failureAFieldNeedsAKey => 'A field needs a key.';

  @override
  String get failureGiveEveryFieldAKeyAndSave =>
      'Give every field a key and save again.';

  @override
  String get failureEachFieldKeyMustBeUniqueOn =>
      'Each field key must be unique on a template.';

  @override
  String get failureRenameTheDuplicateKeyAndSaveAgain =>
      'Rename the duplicate key and save again.';

  @override
  String get failureThatValueIsNotText => 'That value is not text.';

  @override
  String get failureEnterTextOrLeaveTheFieldEmpty =>
      'Enter text, or leave the field empty.';

  @override
  String get failureThatValueIsNotAWholeNumber =>
      'That value is not a whole number.';

  @override
  String get failureEnterAWholeNumberOrLeaveThe =>
      'Enter a whole number, or leave the field empty.';

  @override
  String get failureThatValueIsNotANumber => 'That value is not a number.';

  @override
  String get failureEnterANumberOrLeaveTheField =>
      'Enter a number, or leave the field empty.';

  @override
  String get failureThatNumberIsOutsideTheAllowedRange =>
      'That number is outside the allowed range.';

  @override
  String get failureEnterANumberInsideTheRangeOr =>
      'Enter a number inside the range, or leave the field empty.';

  @override
  String get failureThatValueIsShorterThanThisField =>
      'That value is shorter than this field allows.';

  @override
  String get failureEnterALongerValueOrLeaveThe =>
      'Enter a longer value, or leave the field empty.';

  @override
  String get failureThatValueIsLongerThanThisField =>
      'That value is longer than this field allows.';

  @override
  String get failureShortenTheValueOrLeaveTheField =>
      'Shorten the value, or leave the field empty.';

  @override
  String get failureThatValueDoesNotMatchTheExpected =>
      'That value does not match the expected pattern.';

  @override
  String get failureEnterAValueInTheExpectedForm =>
      'Enter a value in the expected form, or leave the field empty.';

  @override
  String get failureThisFieldSPatternIsNotValid =>
      'This field\'s pattern is not valid.';

  @override
  String get failureOpenTheTemplateAndCorrectTheField =>
      'Open the template and correct the field\'s pattern.';

  @override
  String get failureThatValueIsNotADate => 'That value is not a date.';

  @override
  String get failureEnterACalendarDateOrLeaveThe =>
      'Enter a calendar date, or leave the field empty.';

  @override
  String get failureThatValueIsNotATimeOf => 'That value is not a time of day.';

  @override
  String get failureEnterATimeOrLeaveTheField =>
      'Enter a time, or leave the field empty.';

  @override
  String get failureThatValueIsNotADateAnd =>
      'That value is not a date and time.';

  @override
  String get failureEnterADateAndTimeOrLeave =>
      'Enter a date and time, or leave the field empty.';

  @override
  String get failureThatValueIsNotAYesOr => 'That value is not a yes or no.';

  @override
  String get failureSwitchTheFieldOnOrOffOr =>
      'Switch the field on or off, or leave it unset.';

  @override
  String get failureThatValueIsNotAChoice => 'That value is not a choice.';

  @override
  String get failurePickAnOptionFromTheListOr =>
      'Pick an option from the list, or leave the field empty.';

  @override
  String get failureThatChoiceIsNotOnTheList =>
      'That choice is not on the list.';

  @override
  String get failureThatValueIsNotAFilePath => 'That value is not a file path.';

  @override
  String get failureAttachAFileOrLeaveTheField =>
      'Attach a file, or leave the field empty.';

  @override
  String get failureThatValueIsNotALocation => 'That value is not a location.';

  @override
  String get failureCaptureAGPSFixOrLeaveThe =>
      'Capture a GPS fix, or leave the field empty.';

  @override
  String get failureThatLocationIsOutsideTheEarth =>
      'That location is outside the earth.';

  @override
  String get failureCaptureAGPSFixAgainOrLeave =>
      'Capture a GPS fix again, or leave the field empty.';

  @override
  String get failureThisFieldTypeHasNoEditorOn =>
      'This field type has no editor on this screen.';

  @override
  String get failureOpenTheTemplateAndPickAType =>
      'Open the template and pick a type this screen supports.';

  @override
  String get failureConfirmConsentWithTheNamedOperator =>
      'Confirm consent with the named operator.';

  @override
  String get failureThatFieldTypeIsNotRecognised =>
      'That field type is not recognised.';

  @override
  String get failurePickATypeFromTheListAnd =>
      'Pick a type from the list and save again.';

  @override
  String get failureThatInputModeIsNotRecognised =>
      'That input mode is not recognised.';

  @override
  String get failurePickAnInputModeFromTheList =>
      'Pick an input mode from the list and save again.';

  @override
  String get failureTheSuggestedOrderCouldNotBeRead =>
      'The suggested order could not be read.';

  @override
  String get failureUseTheOnDeviceResultsOrTry =>
      'Use the on-device results or try again.';

  @override
  String get failureOpenTheTemplateListAndTryAgain =>
      'Open the template list and try again.';

  @override
  String get failureTheDailyAnalysisLimitIsReached =>
      'The daily analysis limit is reached.';

  @override
  String get failureUseTheOnDeviceSuggestionsOrTry =>
      'Use the on-device suggestions or try tomorrow.';

  @override
  String get failureExportProtectionsAreUnavailableOnThisDevice =>
      'Export protections are unavailable on this device.';

  @override
  String processingDailyCap(int cap, String resetDay) {
    return 'Today\'s limit of $cap online requests is used. It resets at 00:00 UTC on $resetDay.';
  }

  @override
  String get processingDailyResetRecovery =>
      'Processing will be available after the daily reset.';

  @override
  String get bundlePasswordInvalid => 'That password did not open the bundle.';

  @override
  String get bundlePasswordInvalidRecovery =>
      'Try the password again. Nothing was extracted.';

  @override
  String get incomingBundleBusy =>
      'Finish the current package before opening another.';

  @override
  String get incomingBundleTooLarge => 'This package is too large to open.';

  @override
  String get incomingBundleIncomplete =>
      'This package is too large or incomplete.';

  @override
  String get incomingBundleUnreadable => 'This package could not be opened.';

  @override
  String get incomingBundleUnreadableRecovery =>
      'Open the file again from its original location.';

  @override
  String get biometricUnavailable => 'Biometric authentication is unavailable.';

  @override
  String get biometricPinRecovery => 'Unlock with your app PIN.';

  @override
  String get appLockStorageUnavailable =>
      'The app lock could not be read on this device.';

  @override
  String get appLockStorageRecovery =>
      'Try unlocking again when secure storage is available.';

  @override
  String get cloudDestinationSaveFailed =>
      'The destination could not be saved.';

  @override
  String get cloudDestinationMissing => 'That destination is no longer listed.';

  @override
  String get cloudRefreshDestinations => 'Refresh the list.';

  @override
  String get cloudUploadRecordFailed => 'The upload could not be recorded.';

  @override
  String get cloudUploadHistoryUpdateFailed =>
      'The upload history could not be updated.';

  @override
  String get cloudUploadHistoryUpdateRecovery =>
      'The file on this device was not changed.';

  @override
  String get cloudUploadConfirmationRequired =>
      'Confirm this upload before it can start.';

  @override
  String get cloudUploadConfirmationRecovery =>
      'Review the file and confirm it.';

  @override
  String get cloudUploadHistoryMissing =>
      'That upload is no longer in the history.';

  @override
  String get cloudUploadRestartRecovery => 'Start the upload again.';

  @override
  String get settingsPreferenceUnsupported =>
      'That preference cannot be stored.';

  @override
  String get settingsPreferenceUnsupportedRecovery =>
      'Choose a supported value and save again.';

  @override
  String get settingsPreferenceSaveFailed =>
      'The preference could not be saved on this device.';

  @override
  String get settingsPreferenceSaveRecovery =>
      'Try again. Your last change was not stored.';

  @override
  String get privacyCaptureUnreadable => 'The saved capture could not be read.';

  @override
  String get privacyCaptureRecover => 'Recover the capture and try again.';

  @override
  String get privacyProjectRequired =>
      'Open a project before removing its location data.';

  @override
  String get privacyProjectRequiredRecovery =>
      'Choose a project, then try again.';

  @override
  String get cloudSignInChanged => 'This destination sign-in changed.';

  @override
  String get cloudGoogleSignInRenewal =>
      'This Google Drive sign-in needs renewal.';

  @override
  String get cloudSignInAgain => 'Sign in again.';
}

/// The translations for English (`en_XA`).
class AppLocalizationsEnXa extends AppLocalizationsEn {
  AppLocalizationsEnXa() : super('en_XA');

  @override
  String get ocrBrowserUnavailable =>
      'Ón-dévícé phótó réádíng ís únáváíláblé ín thís brówsér. Révíéw fíélds mánúálly ór énáblé ónlíné ánálysís.·····································';

  @override
  String get notDetected => 'Nót détéctéd·····';

  @override
  String recordsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds···',
      one: '1 récórd···',
      zero: 'Nó récórds····',
    );
    return '$_temp0';
  }

  @override
  String fieldsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fíélds···',
      one: '1 fíéld···',
      zero: 'Nó fíélds····',
    );
    return '$_temp0';
  }

  @override
  String clearField(Object label) {
    return 'Cléár ···$label';
  }

  @override
  String showField(Object label) {
    return 'Shów ··$label';
  }

  @override
  String hideField(Object label) {
    return 'Hídé ··$label';
  }

  @override
  String get photoNoAccess =>
      'Állów thé cámérá ór phótós tó áttách óné. Évérythíng élsé stíll wórks.·························';

  @override
  String get displayNoAccess =>
      'Állów scréén cáptúré tó áttách ánóthér wíndów. Évérythíng élsé stíll wórks.···························';

  @override
  String get photoNoCamera =>
      'Nó cámérá ís áváíláblé ón thís dévícé.··············';

  @override
  String get photoPickFailed =>
      'Thát phótó cóúld nót bé áddéd. Try ánóthér.················';

  @override
  String get displayCaptureFailed =>
      'Thát wíndów cóúld nót bé cáptúréd. Try ánóthér.·················';

  @override
  String dictateInto(Object label) {
    return 'Spéák íntó ····$label';
  }

  @override
  String stopDictating(Object label) {
    return 'Stóp spéákíng íntó ·······$label';
  }

  @override
  String get dictationUnavailable =>
      'Vóícé ínpút ís nót áváíláblé héré. Typé ínstéád.·················';

  @override
  String get dictationNoMicrophone =>
      'Állów thé mícróphóné tó spéák íntó á fíéld. Typíng stíll wórks.·······················';

  @override
  String get dictationNothingHeard =>
      'Nóthíng wás héárd. Táp thé mícróphóné ánd spéák ágáín.···················';

  @override
  String get dictationNeedsConnection =>
      'Vóícé ínpút nééds á cónnéctíón ón thís dévícé. Typé ínstéád.·····················';

  @override
  String get dictationOfflineOnly =>
      'Yóú áré wórkíng ófflíné, ánd thís dévícé cánnót récógnísé spééch wíthóút á cónnéctíón. Typé ínstéád.···································';

  @override
  String get dictationFailed =>
      'Vóícé ínpút stóppéd. Try ágáín, ór typé ínstéád.·················';

  @override
  String get speechUnavailable =>
      'Spééch récógnítíón ís nót áváíláblé ín thís vérsíón óf thé ápp.·······················';

  @override
  String get speechModelMissing =>
      'Thé spééch módél ís nót ínstálléd ón thís dévícé.··················';

  @override
  String get speechModelMissingRecovery =>
      'Réínstáll thé ápp, ór ímpórt thé módél ín Séttíngs.··················';

  @override
  String get speechModelDamaged =>
      'Thé spééch módél fílé ís dámágéd, só ít wás nót úséd.···················';

  @override
  String get speechModelDamagedRecovery =>
      'Réínstáll thé ápp, ór ímpórt thé módél ágáín ín Séttíngs.····················';

  @override
  String get speechDeviceUnsupported =>
      'Thís dévícé cánnót rún spééch récógnítíón.···············';

  @override
  String get speechLowMemory =>
      'Théré ís nót énóúgh fréé mémóry tó lóád thé spééch módél.····················';

  @override
  String get speechLowMemoryRecovery =>
      'Clósé óthér ápps, thén try ágáín.············';

  @override
  String get speechTranscriptionFailed =>
      'Párt óf thé spééch cóúld nót bé túrnéd íntó téxt. Thé áúdíó ís képt.························';

  @override
  String get speechLanguageUnsupported =>
      'Spééch récógnítíón ón thís dévícé dóés nót súppórt thé chósén vóícé lángúágé.···························';

  @override
  String get speechEngineStopped =>
      'Spééch récógnítíón stóppéd únéxpéctédly. Try ágáín.··················';

  @override
  String get speechImportUnknown =>
      'Thís fílé ís nót á spééch módél thé ápp récógnísés.··················';

  @override
  String get speechImportUnknownRecovery =>
      'Chóósé óné óf thé módél fílés náméd ín Séttíngs.·················';

  @override
  String get transcriptSaveFailed =>
      'Thé tránscrípt cóúld nót bé sávéd ón thís dévícé.··················';

  @override
  String get transcriptSegmentOutOfOrder =>
      'Párt óf thé tránscrípt árrívéd óút óf órdér ánd wás nót sávéd.······················';

  @override
  String get transcriptStillRecording =>
      'Thís tránscrípt ís stíll béíng récórdéd. Édít ít óncé thé récórdíng hás fíníshéd.·····························';

  @override
  String get autoFilled => 'Áútó-fílléd····';

  @override
  String get outOfRange => 'Óút óf rángé·····';

  @override
  String get selectAll => 'Séléct áll····';

  @override
  String get clear => 'Cléár··';

  @override
  String dismissChip(Object label) {
    return 'Dísmíss ···$label';
  }

  @override
  String get dismiss => 'Dísmíss···';

  @override
  String get cancel => 'Cáncél···';

  @override
  String get ok => 'ÓK·';

  @override
  String get discardChangesTitle => 'Díscárd chángés?······';

  @override
  String get unsavedChanges => 'Yóú hávé únsávéd chángés.·········';

  @override
  String get discard => 'Díscárd···';

  @override
  String fixFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fíx thésé fíélds······',
      one: 'Fíx thís fíéld·····',
    );
    return '$_temp0';
  }

  @override
  String fieldError(Object label, Object error) {
    return '$label: $error';
  }

  @override
  String fieldLabelRequired(Object label) {
    return '$label (réqúíréd)····';
  }

  @override
  String fieldLabelOptional(Object label) {
    return '$label (óptíónál)····';
  }

  @override
  String validationAnnouncement(Object heading, Object errorsjoin) {
    return '$heading. $errorsjoin';
  }

  @override
  String get missingPhoto => 'Míssíng phótó·····';

  @override
  String get photoSelect => 'Séléct phótó·····';

  @override
  String get photoUnreadable =>
      'Thát phótó cóúld nót bé réád fróm thís dévícé.·················';

  @override
  String get photoUnreadableRecovery =>
      'Cáptúré thé phótó ágáín, thén try ágáín.··············';

  @override
  String missingPhotoNamed(Object type) {
    return 'Míssíng phótó, ······$type';
  }

  @override
  String get photo => 'Phótó··';

  @override
  String get photoCrop => 'Cróp··';

  @override
  String get photoCropCorner => 'Cróp córnér, drág tó résízé··········';

  @override
  String get photoCropFrame => 'Cróp frámé, drág tó móvé·········';

  @override
  String get photoRotate => 'Rótáté···';

  @override
  String get photoDraw => 'Dráw··';

  @override
  String get photoUndoDraw => 'Úndó dráwíng·····';

  @override
  String get photoClearDraw => 'Cléár dráwíng·····';

  @override
  String get markupInk => 'Réd··';

  @override
  String get markupInkYellow => 'Yéllów···';

  @override
  String get markupInkWhite => 'Whíté··';

  @override
  String get markupInkBlack => 'Bláck··';

  @override
  String get markupInkBlue => 'Blúé··';

  @override
  String get markupInkGreen => 'Gréén··';

  @override
  String get markupInkLabel => 'Ínk··';

  @override
  String get markupSize => 'Sízé··';

  @override
  String get markupBacking => 'Dárk báckíng·····';

  @override
  String get markupBackingDescription =>
      'Kééps thé wórds réádáblé ón á búsy phótó.···············';

  @override
  String get markupTypeHint => 'Drág thé phótó tó móvé thé wórds.············';

  @override
  String get markupSizeSmall => 'Smáll··';

  @override
  String get markupSizeMedium => 'Médíúm···';

  @override
  String get markupSizeLarge => 'Lárgé··';

  @override
  String capturePhotoCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString phótós···',
      one: '1 phótó···',
      zero: 'Nó phótós····',
    );
    return '$_temp0';
  }

  @override
  String get capturePhotoProcessing => 'Prócéssíng····';

  @override
  String get photoRevert => 'Révért···';

  @override
  String get photoNoCaption => 'Nó cáptíón yét·····';

  @override
  String get photoCaptionEdit => 'Édít cáptíón·····';

  @override
  String get photoCaptionDelete => 'Délété cáptíón·····';

  @override
  String get photoCaptionDeleteMessage =>
      'Thé cáptíón ís rémóvéd fróm thís phótó. Yóú cán úndó ít.····················';

  @override
  String get photoCaptionDeleted => 'Cáptíón délétéd.······';

  @override
  String get photoTypeOn => 'Typé ón thís phótó·······';

  @override
  String get photoThumbLabel => ', cáptíónéd····';

  @override
  String get photoThumbLabelSelected => ', séléctéd····';

  @override
  String get photoFront => 'Frónt··';

  @override
  String get photoBack => 'Báck··';

  @override
  String get photoSerial => 'Séríál···';

  @override
  String get photoRatingPlate => 'Rátíng pláté·····';

  @override
  String get photoRatingPlateBadge => 'Pláté··';

  @override
  String get photoDamage => 'Dámágé···';

  @override
  String get photoPanel => 'Pánél··';

  @override
  String get photoLocation => 'Lócátíón···';

  @override
  String get photoAttendance => 'Átténdáncé····';

  @override
  String get photoAttendanceBadge => 'Átténd···';

  @override
  String get photoDocument => 'Dócúmént···';

  @override
  String get photoDocumentBadge => 'Dóc··';

  @override
  String get photoOther => 'Óthér··';

  @override
  String get stepDone => 'Dóné··';

  @override
  String get stepRunning => 'Rúnníng···';

  @override
  String get stepWaiting => 'Wáítíng···';

  @override
  String get failed => 'Fáíléd···';

  @override
  String progressAnnouncement(Object label, Object state) {
    return '$label, $state';
  }

  @override
  String progressAnnouncementValue(Object label, Object state, Object detail) {
    return '$label, $state, $detail';
  }

  @override
  String get statusDraft => 'Dráft··';

  @override
  String get statusCaptured => 'Cáptúréd···';

  @override
  String get statusQueued => 'Qúéúéd···';

  @override
  String get statusProcessing => 'Prócéssíng····';

  @override
  String get statusExtracted => 'Éxtráctéd····';

  @override
  String get statusNeedsReview => 'Nééds révíéw·····';

  @override
  String get statusApproved => 'Áppróvéd···';

  @override
  String get statusArchived => 'Árchívéd···';

  @override
  String get statusDeleted => 'Délétéd···';

  @override
  String get emptyHeadline => 'Nóthíng héré yét······';

  @override
  String get emptyMessage =>
      'Whén théré ís sóméthíng tó shów, ít wíll áppéár héré.···················';

  @override
  String get loading => 'Lóádíng···';

  @override
  String get busy => 'lóádíng···';

  @override
  String busyAction(Object label, Object busy) {
    return '$label, $busy';
  }

  @override
  String get tryAgain => 'Try ágáín····';

  @override
  String get save => 'Sávé··';

  @override
  String get undo => 'Úndó··';

  @override
  String get galleryTitle => 'Wídgét gálléry·····';

  @override
  String get galleryTheme => 'Thémé··';

  @override
  String get galleryWidth => 'Wídth··';

  @override
  String get galleryTextScale => 'Téxt scálé····';

  @override
  String get galleryTokens => 'Tókéns···';

  @override
  String get galleryLayout => 'Láyóút···';

  @override
  String get galleryButtons => 'Búttóns···';

  @override
  String get galleryFields => 'Fíélds···';

  @override
  String get galleryContainers => 'Cóntáínérs····';

  @override
  String get galleryStates => 'Státés···';

  @override
  String get galleryFeedback => 'Féédbáck···';

  @override
  String get galleryLight => 'Líght··';

  @override
  String get galleryDark => 'Dárk··';

  @override
  String get galleryOutdoor => 'Óútdóór···';

  @override
  String get galleryCompact => 'Cómpáct···';

  @override
  String get galleryMedium => 'Médíúm···';

  @override
  String get galleryExpanded => 'Éxpándéd···';

  @override
  String get galleryScale100 => '100%';

  @override
  String get galleryScale200 => '200%';

  @override
  String get appName => 'Táptúré···';

  @override
  String get search => 'Séárch···';

  @override
  String get searchNoMatchMessage => 'Chángé thé séárch.·······';

  @override
  String get searchFilters => 'Fíltérs···';

  @override
  String searchFiltersFilters(int active) {
    final intl.NumberFormat activeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String activeString = activeNumberFormat.format(active);

    return 'Fíltérs (····$activeString)';
  }

  @override
  String get searchClearFilters => 'Cléár fíltérs·····';

  @override
  String get searchFilterNoMatchMessage =>
      'Chángé thé séárch ór cléár thé fíltérs.··············';

  @override
  String get overflowMenu => 'Móré óptíóns·····';

  @override
  String get navProjects => 'Prójécts···';

  @override
  String get projectsEmptyHeadline => 'Nó prójécts yét······';

  @override
  String get projectsEmptyMessage =>
      'Créáté á prójéct tó stárt cáptúríng.·············';

  @override
  String get projectsCreate => 'Créáté á prójéct······';

  @override
  String get projectsPickHeadline => 'Chóósé á prójéct······';

  @override
  String get projectsPickMessage =>
      'Séléct á prójéct fróm thé líst.···········';

  @override
  String get projectsNoMatchHeadline => 'Nó mátchíng prójécts·······';

  @override
  String get projectsNoMatchMessage =>
      'Try á dífférént námé, ór créáté á prójéct.···············';

  @override
  String get projectSearchHint => 'Séárch prójécts······';

  @override
  String get projectFiltersTitle => 'Prójéct fíltérs······';

  @override
  String get projectStatusFilter => 'Státús···';

  @override
  String get projectPinFilter => 'Pínnéd státé·····';

  @override
  String get projectPinFilterLabel => 'Pínnéd···';

  @override
  String get projectPinFilterLabelUnpinned => 'Únpínnéd···';

  @override
  String get projectPinFilterLabelAllProjects => 'Áll prójécts·····';

  @override
  String get projectApplyFilters => 'Ápply fíltérs·····';

  @override
  String get pinnedProject => 'Pínnéd prójéct·····';

  @override
  String projectTemplateCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString témplátés áttáchéd·······',
      one: '1 témpláté áttáchéd·······',
      zero: 'Nó témplátés áttáchéd········',
    );
    return '$_temp0';
  }

  @override
  String get projectsImport => 'Ímpórt á fílé·····';

  @override
  String get projectsDuplicate => 'Dúplícáté····';

  @override
  String get projectAllProjects => 'Áll prójécts·····';

  @override
  String get projectNew => 'Néw prójéct····';

  @override
  String get projectArchive => 'Árchívé···';

  @override
  String get projectUnarchive => 'Únárchívé····';

  @override
  String get projectDelete => 'Délété prójéct·····';

  @override
  String get projectDeleteMenu => 'Délété···';

  @override
  String projectDeleteTitle(Object name) {
    return 'Délété ···$name?';
  }

  @override
  String projectDeleteMessage(
    Object recordsCountrecords,
    Object filesCountfiles,
    int days,
  ) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Thís hídés ····$recordsCountrecords ánd ··$filesCountfiles. Yóú cán réstóré thém fór ··········$daysString dáys. Nóthíng ís rémóvéd yét.···········';
  }

  @override
  String filesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fílés···',
      one: '1 fílé···',
      zero: 'nó fílés···',
    );
    return '$_temp0';
  }

  @override
  String get projectDeleteTypeName => 'Typé thé prójéct námé········';

  @override
  String get projectExportFirst => 'Éxpórt fírst·····';

  @override
  String get projectShowArchived => 'Shów árchívéd·····';

  @override
  String get projectPin => 'Pín··';

  @override
  String get projectUnpin => 'Únpín··';

  @override
  String get projectRename => 'Rénámé···';

  @override
  String get projectRenameTitle => 'Rénámé prójéct·····';

  @override
  String get projectRenameMessage => 'Thé fóldér ón dísk stáys pút.···········';

  @override
  String get projectOpenWith => 'Ópén wíth····';

  @override
  String get projectDownloadCopy => 'Dównlóád á cópy······';

  @override
  String get projectNothingToOpen =>
      'Thís prójéct hás nó spréádshéét, dócúmént ór PDF tó ópén yét.······················';

  @override
  String get projectNothingToOpenRecovery =>
      'Ímpórt á témpláté wórkbóók ór éxpórt thé prójéct, thén try ágáín.·······················';

  @override
  String get projectOpenFailedTitle => 'Cóúld nót ópén thé fílé·········';

  @override
  String get projectOpenFailed =>
      'Táptúré cóúld nót hánd thé fílé tó ánóthér ápp.·················';

  @override
  String projectOpenFailedNamed(Object fileName) {
    return 'Táptúré cóúld nót hánd ·········$fileName tó ánóthér ápp.······';
  }

  @override
  String get projectOpenFailedRecovery =>
      'Fréé sómé spácé, thén try ágáín.············';

  @override
  String get projectOpenNoApp =>
      'Nó ápp ón thís dévícé cán ópén thát fílé.···············';

  @override
  String get projectOpenNoAppRecovery =>
      'Ínstáll á réádér fór thís fílé typé, thén try ágáín.···················';

  @override
  String get projectOpenPermission =>
      'Táptúré nééds stórágé áccéss tó ópén á cópy óf thís fílé.····················';

  @override
  String get projectOpenPermissionRecovery =>
      'Állów stórágé áccéss, thén try ágáín.·············';

  @override
  String get projectCreateTitle => 'Créáté prójéct·····';

  @override
  String get projectDuplicateTitle => 'Dúplícáté prójéct······';

  @override
  String get projectName => 'Námé··';

  @override
  String get projectDescription => 'Déscríptíón····';

  @override
  String get projectOrganisation => 'Órgánísátíón·····';

  @override
  String get projectEditTitle => 'Prójéct détáíls······';

  @override
  String get projectEditFormTitle => 'Édít prójéct·····';

  @override
  String get projectEditDetails => 'Édít détáíls·····';

  @override
  String get projectValueNotSet => 'Nót sét···';

  @override
  String get projectCreatedAt => 'Créátéd···';

  @override
  String get projectUpdatedAt => 'Lást chángéd·····';

  @override
  String get contextLevelSource => 'Súggést lévéls fróm·······';

  @override
  String get projectSettingsTitle => 'Prójéct séttíngs······';

  @override
  String get projectSaved => 'Prójéct sávéd·····';

  @override
  String get projectSettingsSaved => 'Séttíngs sávéd·····';

  @override
  String get projectStartsOn => 'Stárts···';

  @override
  String get projectEndsOn => 'Énds··';

  @override
  String get projectStatus => 'Státús···';

  @override
  String get projectStatusActive => 'Áctívé···';

  @override
  String get projectStatusArchived => 'Árchívéd···';

  @override
  String get projectAiEnabled => 'ÁÍ·';

  @override
  String get projectAiEnabledEffect =>
      'Túrn óff tó kéép thís prójéct fúlly mánúál.················';

  @override
  String get projectDoNotSendImages => 'Dó nót sénd ímágés·······';

  @override
  String get projectDoNotSendImagesEffect =>
      'Próvídérs névér séé phótó bytés fróm thís prójéct.··················';

  @override
  String get projectRefineColumns => 'Réfínéd cólúmns······';

  @override
  String get projectConfidenceHigh => 'Hígh cónfídéncé······';

  @override
  String get projectConfidenceMedium => 'Médíúm cónfídéncé······';

  @override
  String get projectUseAppDefault => 'Úsé ápp défáúlt······';

  @override
  String get projectOn => 'Ón·';

  @override
  String get projectOff => 'Óff··';

  @override
  String projectAppDefault(Object value) {
    return 'Ápp défáúlt: ·····$value';
  }

  @override
  String get projectEditEmptyHeadline => 'Nó prójéct ópén······';

  @override
  String get projectEditEmptyMessage =>
      'Ópén á prójéct tó édít íts détáíls.·············';

  @override
  String get projectSettingsEmptyHeadline => 'Nó prójéct ópén······';

  @override
  String get projectSettingsEmptyMessage =>
      'Ópén á prójéct tó chángé íts séttíngs.··············';

  @override
  String projectCopyName(Object name) {
    return '$name (cópy)···';
  }

  @override
  String projectListSubtitle(
    Object recordsCountrecords,
    Object unprocessedCountunprocessed,
  ) {
    return '$recordsCountrecords · $unprocessedCountunprocessed';
  }

  @override
  String projectRecordPosition(int position) {
    final intl.NumberFormat positionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String positionString = positionNumberFormat.format(position);

    return 'Récórd ···$positionString';
  }

  @override
  String get projectRecordsEmptyHeadline => 'Nó récórds héré······';

  @override
  String get projectRecordsEmptyMessage =>
      'Cáptúréd récórds fór thís fíltér áppéár héré.················';

  @override
  String get projectRecordsSearchHint => 'Séárch récórds·····';

  @override
  String get projectRecordFiltersTitle => 'Récórd fíltérs·····';

  @override
  String get projectRecordStatusFilter => 'Státús···';

  @override
  String get projectRecordsNoMatch => 'Nó récórds mátch.······';

  @override
  String projectRecordsNoMatchNoRecordsMatch(Object shown) {
    return 'Nó récórds mátch \"·······$shown\".';
  }

  @override
  String get choiceNoMatch => 'Nóthíng mátchés.······';

  @override
  String choiceNoMatchNothingMatches(Object shown) {
    return 'Nóthíng mátchés \"······$shown\".';
  }

  @override
  String get projectExport => 'Éxpórt···';

  @override
  String get projectExportTitle => 'Éxpórt prójéct·····';

  @override
  String get projectExportEmptyHeadline => 'Nóthíng tó éxpórt······';

  @override
  String get projectExportEmptyMessage =>
      'Cáptúré á récórd béfóré éxpórtíng thís prójéct.·················';

  @override
  String get projectExportShare => 'Sháré··';

  @override
  String projectExportSaved(Object fileName) {
    return 'Sávéd ···$fileName.';
  }

  @override
  String get projectExportShareHint =>
      'Sénd thé fílé tó émáíl, chát ánd óthér ápps ón thís dévícé.·····················';

  @override
  String get exportSectionProject => 'Prójéct···';

  @override
  String get exportSectionRecords => 'Récórds···';

  @override
  String get exportSectionTemplates => 'Témplátés····';

  @override
  String get exportSectionFile => 'Fílé··';

  @override
  String exportAudioClips(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString áúdíó clíps·····',
      one: '1 áúdíó clíp·····',
      zero: 'Nó áúdíó clíps·····',
    );
    return '$_temp0';
  }

  @override
  String exportCapturedBetween(Object first) {
    return 'Cáptúréd ····$first';
  }

  @override
  String exportCapturedBetweenCapturedTo(Object first, Object last) {
    return 'Cáptúréd ····$first tó ··$last';
  }

  @override
  String exportUnprocessedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString únprócésséd récórds·······',
      one: '1 únprócésséd récórd·······',
      zero: 'Nó únprócésséd récórds········',
    );
    return '$_temp0';
  }

  @override
  String exportNeedsReviewCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds nééd révíéw·······',
      one: '1 récórd nééds révíéw········',
      zero: 'Nó récórds nééd révíéw········',
    );
    return '$_temp0';
  }

  @override
  String exportApprovedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString áppróvéd récórds······',
      one: '1 áppróvéd récórd······',
      zero: 'Nó áppróvéd récórds·······',
    );
    return '$_temp0';
  }

  @override
  String get exportFileFormat => 'Prójéct páckágé (.zíp)········';

  @override
  String get exportFileColumns =>
      'Évérythíng ánóthér Táptúré ápp nééds tó ópén thís prójéct: récórds, phótós, áúdíó, témplátés, cóntéxt, référéncé dátá ánd prójéct séttíngs, wíth á wórkbóók óf thé récórds. Únsávéd cáptúré dráfts stáy ón thís dévícé.············································································';

  @override
  String exportPackageSize(Object fileSizebytes) {
    return 'Ábóút ···$fileSizebytes';
  }

  @override
  String exportSavedTo(Object place) {
    return 'Sávéd tó ····$place › Éxpórts····';
  }

  @override
  String get projectExportProgress => 'Wrítíng thé éxpórt·······';

  @override
  String get projectExportCancel => 'Cáncél···';

  @override
  String get recordEdit => 'Édít··';

  @override
  String get projectPhoto => 'Prójéct phótó (óptíónál)·········';

  @override
  String get projectPhotoAdd => 'Ádd á phótó····';

  @override
  String get projectPhotoChange => 'Chángé phótó·····';

  @override
  String get projectPhotoRemove => 'Rémóvé phótó·····';

  @override
  String get recordEditTitle => 'Édít récórd····';

  @override
  String get recordEditSave => 'Sávé chángés·····';

  @override
  String get recordEditSaved => 'Récórd úpdátéd.······';

  @override
  String get recordEditNoFieldsHeadline => 'Nó fíélds tó édít······';

  @override
  String get recordEditNoFieldsMessage =>
      'Ádd fíélds tó thís récórd\'s témpláté, thén édít thé récórd héré.·······················';

  @override
  String get recordDelete => 'Délété···';

  @override
  String get recordArchiveMessage =>
      'Thé phótós stáy ón thís dévícé. Thé récórd léávés thís líst.·····················';

  @override
  String get recordDetailTitle => 'Récórd···';

  @override
  String get recordNoCaption => 'Nó cáptíón····';

  @override
  String get recordFieldEmpty => 'Nót éntéréd····';

  @override
  String get recordSectionFields => 'Fíélds···';

  @override
  String get recordEditFields => 'Édít fíélds····';

  @override
  String recordCapturedAt(Object when) {
    return 'Cáptúréd ····$when';
  }

  @override
  String get recordGoneHeadline => 'Thís récórd ís nó lóngér héré···········';

  @override
  String get recordGoneMessage =>
      'Ít wás délétéd ór ís nót ón thís dévícé. Gó báck tó thé líst.······················';

  @override
  String get continueCapturing => 'Cóntínúé cáptúríng·······';

  @override
  String get captureStart => 'Stárt cáptúríng······';

  @override
  String get captureMore => 'Cáptúré móré·····';

  @override
  String get homeEmptyHeadline => 'Nó prójéct ópén······';

  @override
  String get homeEmptyMessage =>
      'Ópén á prójéct tó séé whát tó dó néxt.··············';

  @override
  String get navCapture => 'Cáptúré···';

  @override
  String get navRecords => 'Récórds···';

  @override
  String get navMore => 'Séttíngs···';

  @override
  String get navMoreMenu => 'Móré··';

  @override
  String get navTemplates => 'Témplátés····';

  @override
  String get projectTemplatesTitle => 'Prójéct témplátés······';

  @override
  String get navDatasets => 'Dátáséts···';

  @override
  String get datasetsEmptyHeadline => 'Nó dátáséts yét······';

  @override
  String get datasetsEmptyMessage =>
      'Ímpórt á CSV, spréádshéét ór JSÓN táblé tó préfíll cáptúré fíélds.························';

  @override
  String get datasetsImport => 'Ímpórt dátásét·····';

  @override
  String get datasetsKeyTitle => 'Chóósé thé kéy cólúmn········';

  @override
  String get datasetsKeyMessage =>
      'Thé kéy úníqúély ídéntífíés éách rów fór lóókúp.·················';

  @override
  String get datasetsAllowDuplicates => 'Sávé wíth dúplícátés·······';

  @override
  String get datasetsSaveImport => 'Sávé dátásét·····';

  @override
  String datasetsDuplicateCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dúplícáté kéy válúés········',
      one: '1 dúplícáté kéy válúé········',
    );
    return '$_temp0';
  }

  @override
  String datasetsCollidingValues(Object valuesjoin) {
    return 'Éxámplés: ····$valuesjoin';
  }

  @override
  String datasetListSubtitle(
    Object datasetsRowCountrows,
    Object source,
    Object dateFormatyMMMdformat,
  ) {
    return '$datasetsRowCountrows · $source · $dateFormatyMMMdformat';
  }

  @override
  String datasetsRowCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString róws··',
      one: '1 rów··',
    );
    return '$_temp0';
  }

  @override
  String get datasetSourceLabel => 'CSV··';

  @override
  String get datasetSourceLabelSpreadsheet => 'Spréádshéét····';

  @override
  String get datasetSourceLabelJSON => 'JSÓN··';

  @override
  String get datasetSourceLabelOnDevice => 'Ón dévícé····';

  @override
  String get datasetsSearchHint => 'Séárch róws····';

  @override
  String get datasetsColumns => 'Cólúmns···';

  @override
  String get datasetsEditRow => 'Édít rów···';

  @override
  String get datasetsSaveRow => 'Sávé rów···';

  @override
  String get datasetsAddRow => 'Ádd rów···';

  @override
  String get datasetsPickMatch => 'Chóósé á mátch·····';

  @override
  String get datasetsLookupBinding => 'Lóókúp bíndíng·····';

  @override
  String get datasetsSaveBinding => 'Sávé bíndíng·····';

  @override
  String get datasetsBindingEmptyHeadline =>
      'Nó dátáséts ín thís prójéct··········';

  @override
  String get datasetsBindingEmptyMessage =>
      'Ímpórt á dátásét béfóré bíndíng thís fíéld.················';

  @override
  String get datasetsFuzzyEnabled => 'Állów fúzzy mátchés·······';

  @override
  String get datasetsOnNoMatch => 'Whén nóthíng mátchés·······';

  @override
  String get datasetsAddedOnDevice => 'Áddéd ón dévícé······';

  @override
  String get datasetsExport => 'Éxpórt···';

  @override
  String get datasetsBrowserEmptyHeadline => 'Nó róws···';

  @override
  String get datasetsBrowserEmptyMessage =>
      'Thís dátásét hás nó róws tó shów.············';

  @override
  String get datasetsNoMatchHeadline => 'Nó mátchíng róws······';

  @override
  String get datasetsNoMatchMessage =>
      'Nó rów mátchés thát séárch. Cléár ít tó séé évéry rów.···················';

  @override
  String get datasetsPickNoMatchMessage =>
      'Nóthíng ín thís dátásét mátchés. Thé typéd válúé stáys ás ít ís.·······················';

  @override
  String get datasetsClearSearch => 'Cléár séárch·····';

  @override
  String get datasetsNoProjectHeadline => 'Ópén á prójéct fírst·······';

  @override
  String get datasetsNoProjectMessage =>
      'Dátáséts bélóng tó á prójéct. Ópén óné tó ímpórt ór brówsé íts táblés.·························';

  @override
  String get datasetsPickHeadline => 'Chóósé á táblé tó ímpórt·········';

  @override
  String get datasetsPickMessage =>
      'Píck á CSV, spréádshéét ór JSÓN fílé. Yóú chóósé íts kéy cólúmn néxt.·························';

  @override
  String get datasetsPickFile => 'Chóósé á fílé·····';

  @override
  String get datasetsReading => 'Réádíng thé táblé······';

  @override
  String datasetsReadProgress(int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return '$percentString% réád···';
  }

  @override
  String datasetsColumnSummary(Object count, Object shown) {
    return '$count · $shown';
  }

  @override
  String datasetsDuplicateWarning(Object datasetsCollidingValuescolliding) {
    return ' $datasetsCollidingValuescolliding.';
  }

  @override
  String datasetsDuplicateWarningPickAnotherKeyColumn(
    Object datasetsDuplicateCountn,
    Object values,
  ) {
    return '$datasetsDuplicateCountn.$values Píck ánóthér kéy cólúmn, ór sávé thé dátásét wíth dúplícátés.······················';
  }

  @override
  String get datasetsDuplicatesConfirmTitle =>
      'Sávé wíth dúplícáté kéys?·········';

  @override
  String datasetsDuplicatesConfirm(
    Object column,
    Object datasetsDuplicateCountn,
  ) {
    return 'Thé kéy cólúmn ······$column hás ··$datasetsDuplicateCountn. Á lóókúp ón á répéátéd kéy ásks whích rów tó úsé.··················';
  }

  @override
  String get datasetsExportCsv => 'Éxpórt ás CSV·····';

  @override
  String get datasetsExportJson => 'Éxpórt ás JSÓN·····';

  @override
  String get datasetsExporting => 'Éxpórtíng thé dátásét········';

  @override
  String get datasetsVisibleColumns => 'Cólúmns tó shów······';

  @override
  String get datasetsMissingHeadline => 'Dátásét nót fóúnd······';

  @override
  String get datasetsMissingMessage =>
      'Thís dátásét ís nó lóngér ón thís dévícé.···············';

  @override
  String get datasetsExportNoProject =>
      'Ópén á prójéct béfóré éxpórtíng thís dátásét.················';

  @override
  String get datasetsExportNoProjectRecovery =>
      'Ópén thé prójéct ánd try ágáín.···········';

  @override
  String get datasetsRowMissingHeadline => 'Rów nót fóúnd·····';

  @override
  String get datasetsRowMissingMessage =>
      'Thís rów ís nó lóngér ín thé dátásét.·············';

  @override
  String get datasetsAddRowNoDatasetHeadline => 'Nó dátásét bóúnd······';

  @override
  String get datasetsAddRowNoDatasetMessage =>
      'Bínd thís fíéld tó á dátásét béfóré áddíng róws fróm cáptúré.······················';

  @override
  String lookupUnknownTarget(Object target) {
    return 'Únknówn fíll tárgét \"········$target\".';
  }

  @override
  String lookupTargetTwice(Object target) {
    return 'Fíll tárgét \"·····$target\" ís máppéd móré thán óncé.··········';
  }

  @override
  String get lookupPickDataset =>
      'Píck á dátásét béfóré sávíng thé bíndíng.···············';

  @override
  String get lookupImportRecovery =>
      'Fíx thé lóókúp fílls ín thé témpláté fílé ánd ímpórt ít ágáín.······················';

  @override
  String lookupColumnTwice(Object column) {
    return 'Cólúmn \"···$column\" ís chósén fór twó fíélds. Píck óné fíéld fór ít.··················';
  }

  @override
  String lookupThresholdLabel(int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return '$percentString%';
  }

  @override
  String get lookupKeyColumn => 'Kéy cólúmn····';

  @override
  String get lookupMatchColumns => 'Mátch ón···';

  @override
  String get lookupMatchOrder => 'Thé kéy cólúmn ónly·······';

  @override
  String get lookupNotFilled => 'Nót fílléd····';

  @override
  String get lookupFills => 'Fíll thésé fíélds······';

  @override
  String get lookupFuzzyThreshold =>
      'Súggést mátchés scóríng át léást············';

  @override
  String get lookupBecomesLookup =>
      'Sávíng mákés thís fíéld á lóókúp fíéld.··············';

  @override
  String get lookupFieldMissingHeadline => 'Fíéld nót fóúnd······';

  @override
  String get lookupFieldMissingMessage =>
      'Thís fíéld ís nó lóngér ón thé témpláté.··············';

  @override
  String get lookupNoMatchLeaveEmpty => 'Léávé émpty····';

  @override
  String get lookupNoMatchPromptAdd => 'Óffér tó ádd á rów·······';

  @override
  String get lookupNoMatchWarn => 'Wárn··';

  @override
  String get templatesBindDataset => 'Bínd tó dátásét······';

  @override
  String get templatesEmptyHeadline => 'Nó témplátés yét······';

  @override
  String get templatesEmptyMessage =>
      'Píck á shíppéd témpláté tó stárt cáptúríng, ór créáté á blánk témpláté.·························';

  @override
  String get templatesPickLibrary => 'Píck á shíppéd témpláté·········';

  @override
  String get templatesCreate => 'Créáté á blánk témpláté·········';

  @override
  String get templatesEdit => 'Édít··';

  @override
  String get templatesAddChoices => 'Ádd témplátés·····';

  @override
  String get templatesAddMore => 'Ádd móré témplátés·······';

  @override
  String get templatesAddEmptyMessage =>
      'Ádd témplátés tó stárt cáptúríng. Créáté á blánk témpláté whén nóné fíts.··························';

  @override
  String get templatesUpload => 'Úplóád á témpláté······';

  @override
  String get templatesUseExisting => 'Úsé án éxístíng témpláté·········';

  @override
  String get templatesNoMatch => 'Nó mátchíng témplátés········';

  @override
  String get templateFiltersTitle => 'Témpláté fíltérs······';

  @override
  String get templateKindFilter => 'Kínd··';

  @override
  String get templateKindNone => 'Nó kínd···';

  @override
  String get fieldsNoMatch => 'Nó mátchíng fíélds·······';

  @override
  String get fieldFiltersTitle => 'Fíéld fíltérs·····';

  @override
  String get fieldRequirednessFilter => 'Réqúírémént····';

  @override
  String get templateChoiceLabel => 'Témpláté chóícé······';

  @override
  String get templateChoiceAuto => 'Áútó··';

  @override
  String get templateChoiceSuggest => 'Súggést···';

  @override
  String get templateChoiceManual => 'Mánúál···';

  @override
  String get templatesCreateTitle => 'Néw témpláté·····';

  @override
  String get templatesOpen => 'Ópén··';

  @override
  String get templatesExport => 'Éxpórt témpláté······';

  @override
  String get templatesImport => 'Ímpórt témpláté······';

  @override
  String get templatesImportEmptyHeadline => 'Nó témpláté fílé······';

  @override
  String get templatesImportEmptyMessage =>
      'Chóósé á témpláté fílé tó ádd ít tó thís prójéct.··················';

  @override
  String get templatesImportUnknownSchema =>
      'Thát témpláté fílé úsés á schémá thís ápp dóés nót réád.····················';

  @override
  String get templatesImportUnknownSchemaRecovery =>
      'Éxpórt thé témpláté ágáín fróm thís vérsíón óf Táptúré.····················';

  @override
  String get templatesImportInvalid => 'Thát fílé ís nót á témpláté.··········';

  @override
  String get templatesImportInvalidRecovery =>
      'Chóósé á témpláté fílé ánd try ágáín.·············';

  @override
  String get templatesImportDuplicateField =>
      'Éách fíéld kéy múst bé úníqúé ón á témpláté.················';

  @override
  String get templatesImportDuplicateFieldRecovery =>
      'Rénámé thé dúplícáté kéy ánd éxpórt ágáín.···············';

  @override
  String get workbookPassword =>
      'Thát spréádshéét ís lóckéd wíth á pásswórd.················';

  @override
  String get workbookPasswordRecovery =>
      'Únlóck ít, sávé á cópy, ánd chóósé thé cópy.················';

  @override
  String get workbookCorrupt =>
      'Thát spréádshéét cóúld nót bé réád.·············';

  @override
  String get workbookCorruptRecovery =>
      'Kéép thé órígínál. Éxpórt á cópy ánd try ágáín.·················';

  @override
  String get xlsxMappingTitle => 'Máp cólúmns····';

  @override
  String get xlsxMappingEmptyHeadline => 'Nó spréádshéét·····';

  @override
  String get xlsxMappingEmptyMessage =>
      'Chóósé á spréádshéét tó máp íts cólúmns óntó á témpláté.····················';

  @override
  String get xlsxMappingConfirm => 'Créáté témpláté······';

  @override
  String get xlsxMappingSkip => 'Skíp thís cólúmn······';

  @override
  String get xlsxMappingInclude => 'Ínclúdé thís cólúmn·······';

  @override
  String get xlsxMappingSkipped => 'Skíppéd···';

  @override
  String xlsxMappingProposal(Object field, Object type, Object rule) {
    return '$field · $type · $rule';
  }

  @override
  String xlsxMappingUntitled(Object column) {
    return 'Cólúmn ···$column';
  }

  @override
  String get xlsxMappingDefaultName => 'Spréádshéét····';

  @override
  String get xlsxMappingMissing =>
      'Thát spréádshéét ís nó lóngér ón thís dévícé.················';

  @override
  String get xlsxMappingMissingRecovery =>
      'Chóósé thé spréádshéét ágáín, thén try ágáín.················';

  @override
  String get xlsxMappingExists =>
      'Á cópy óf thát spréádshéét ís álréády ín thís prójéct.···················';

  @override
  String get xlsxMappingExistsRecovery =>
      'Rénámé thé spréádshéét, thén try ágáín.··············';

  @override
  String get rowAliasesTitle => 'Rów álíásés····';

  @override
  String get rowAliasesEmptyHeadline => 'Nó róws tó námé······';

  @override
  String get rowAliasesEmptyMessage =>
      'Ímpórt spréádshéét róws fírst, thén ádd thé lócál námés thát shóúld mátch thém.····························';

  @override
  String get rowAliasesField => 'Álíásés···';

  @override
  String get rowAliasesHint => 'BP máchíné, BP·····';

  @override
  String get rowAliasesImport => 'Ímpórt fróm á cólúmn·······';

  @override
  String get rowAliasesColumn => 'Álíás cólúmn·····';

  @override
  String get rowAliasesInvalidColumn =>
      'Thát cólúmn ís nót ín thé spréádshéét.··············';

  @override
  String get rowAliasesInvalidColumnRecovery =>
      'Éntér á cólúmn léttér shówn ín thé spréádshéét.·················';

  @override
  String get rowAliasesNone => 'Nó álíásés yét·····';

  @override
  String get checklistTitle => 'Chécklíst····';

  @override
  String get checklistIdentifierColumn => 'Ídéntífíér cólúmn······';

  @override
  String get checklistLabelColumn => 'Lábél cólúmn·····';

  @override
  String get checklistContextColumn => 'Cóntéxt cólúmn·····';

  @override
  String get checklistImportRows => 'Ímpórt róws····';

  @override
  String get checklistMappingIncomplete =>
      'Chóósé án ídéntífíér ánd á lábél cólúmn.··············';

  @override
  String get checklistMappingRecovery =>
      'Cónfírm bóth cólúmns béfóré ímpórtíng thé róws.·················';

  @override
  String get checklistEmptyHeadline => 'Nóthíng ón thé chécklíst·········';

  @override
  String get checklistEmptyMessage =>
      'Ímpórt spréádshéét róws tó séé whát ís stíll míssíng.···················';

  @override
  String get checklistFound => 'Fóúnd··';

  @override
  String get checklistMissing => 'Míssíng···';

  @override
  String get checklistUngrouped => 'Úngróúpéd····';

  @override
  String checklistProgress(Object group, int found, int total) {
    final intl.NumberFormat foundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String foundString = foundNumberFormat.format(found);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$group · Fóúnd ····$foundString óf ··$totalString';
  }

  @override
  String get detectionProfileTitle => 'Détéctíón····';

  @override
  String get detectionProfileExplain =>
      'Á phótó ís mátchéd tó thís témpláté fróm thésé sígnáls. Á négátívé kéywórd rúlés ít óút.·······························';

  @override
  String get detectionProfileEmptyHeadline =>
      'Nó témpláté tó cónfígúré·········';

  @override
  String get detectionProfileEmptyMessage =>
      'Ópén á témpláté fírst, thén sét hów á phótó ís mátchéd tó ít.······················';

  @override
  String get detectionProfileClasses => 'Óbjéct clássés·····';

  @override
  String get detectionProfileKeywords => 'Kéywórds···';

  @override
  String get detectionProfilePatterns => 'Ídéntífíér páttérns·······';

  @override
  String get detectionProfileDatasets => 'Línkéd dátáséts······';

  @override
  String get detectionProfileNegative => 'Négátívé kéywórds······';

  @override
  String get detectionProfileHint => 'Sépáráté wíth á cómmá········';

  @override
  String get detectionProfileNoPatterns =>
      'Ídéntífíér páttérns cómé fróm fíéld válídátíón. Ádd á páttérn ón á fíéld fírst.····························';

  @override
  String get detectionProfileNoDatasets =>
      'Línkéd dátáséts cómé fróm lóókúp fíélds. Bínd á lóókúp fírst.······················';

  @override
  String get detectionProfileMissing =>
      'Thát témpláté ís nó lóngér ón thís dévícé.···············';

  @override
  String get detectionProfileMissingRecovery =>
      'Ópén thé témpláté líst ánd try ágáín.·············';

  @override
  String get templatesDelete => 'Délété témpláté······';

  @override
  String templatesDeleteTitle(Object name) {
    return 'Délété ···$name?';
  }

  @override
  String templatesDeleteMessage(
    Object fieldsCountfields,
    Object recordsCountrecords,
  ) {
    return 'Thís hídés ····$fieldsCountfields. $recordsCountrecords stáy ón thís témpláté.·········';
  }

  @override
  String get templateFieldsTitle => 'Fíélds···';

  @override
  String get templatesAddField => 'Ádd á fíéld····';

  @override
  String templateFieldRowTitle(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Fíéld ···$nString';
  }

  @override
  String get templateFieldRowRemove => 'Rémóvé thís fíéld······';

  @override
  String get templatesEditField => 'Édít fíéld····';

  @override
  String get templatesDeleteField => 'Délété fíéld·····';

  @override
  String templatesDeleteFieldTitle(Object label) {
    return 'Délété ···$label?';
  }

  @override
  String templatesDeleteFieldMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countString récórds hóld á válúé. Thósé válúés stáy ánd éxpórt ás rétíréd.·······················',
      one:
          '1 récórd hólds á válúé. Thát válúé stáys ánd éxpórts ás rétíréd.·······················',
      zero:
          'Nó récórds hóld á válúé. Thé fíéld léávés thís témpláté. Éxístíng válúés stáy ánd éxpórt ás rétíréd.···································',
    );
    return '$_temp0';
  }

  @override
  String get templatesFieldsEmptyHeadline => 'Nó fíélds yét·····';

  @override
  String get templatesFieldsEmptyMessage =>
      'Ádd á fíéld só thís témpláté cán cáptúré.···············';

  @override
  String get fieldRequired => 'Réqúíréd···';

  @override
  String get fieldCalculated => 'Cálcúlátéd····';

  @override
  String get fieldFromPhotos => 'Fróm phótós····';

  @override
  String fieldRowSubtitle(Object contextLevel) {
    return 'Cóntéxt lévél ·····$contextLevel';
  }

  @override
  String get fieldRowSubtitlePinnedContext => 'Pínnéd cóntéxt·····';

  @override
  String fieldRowDefault(Object value) {
    return 'Défáúlt: ····$value';
  }

  @override
  String get fieldRecommended => 'Récómméndéd····';

  @override
  String get fieldOptional => 'Óptíónál···';

  @override
  String fieldMoveUp(Object label) {
    return 'Móvé ··$label úp··';
  }

  @override
  String fieldMoveDown(Object label) {
    return 'Móvé ··$label dówn··';
  }

  @override
  String fieldReorder(Object label) {
    return 'Réórdér ···$label';
  }

  @override
  String get fieldTypeLabel => 'Téxt··';

  @override
  String get fieldTypeLabelLongText => 'Lóng téxt····';

  @override
  String get fieldTypeLabelNumber => 'Númbér···';

  @override
  String get fieldTypeLabelDecimal => 'Décímál···';

  @override
  String get fieldTypeLabelCurrency => 'Cúrréncy···';

  @override
  String get fieldTypeLabelPercentage => 'Pércéntágé····';

  @override
  String get fieldTypeLabelDate => 'Dáté··';

  @override
  String get fieldTypeLabelTime => 'Tímé··';

  @override
  String get fieldTypeLabelDateAndTime => 'Dáté ánd tímé·····';

  @override
  String get fieldTypeLabelBoolean => 'Bóóléán···';

  @override
  String get fieldTypeLabelChoice => 'Chóícé···';

  @override
  String get fieldTypeLabelMultiChoice => 'Múltí-chóícé·····';

  @override
  String get fieldTypeLabelLookup => 'Lóókúp···';

  @override
  String get fieldTypeLabelBarcode => 'Bárcódé···';

  @override
  String get fieldTypeLabelPhotoReference => 'Phótó référéncé······';

  @override
  String get fieldTypeLabelDocumentReference => 'Dócúmént référéncé·······';

  @override
  String get fieldTypeLabelGPSLocation => 'GPS lócátíón·····';

  @override
  String get fieldTypeLabelSignature => 'Sígnátúré····';

  @override
  String get fieldTypeLabelComputed => 'Cómpútéd···';

  @override
  String get fieldLabel => 'Lábél··';

  @override
  String get fieldType => 'Typé··';

  @override
  String get fieldRequiredness => 'Réqúíréd?····';

  @override
  String get fieldAdvanced => 'Ádváncéd···';

  @override
  String get fieldAdvancedShow => 'Shów ádváncéd·····';

  @override
  String get fieldAdvancedHide => 'Hídé ádváncéd·····';

  @override
  String get fieldKeepAnyway => 'Kéép ánywáy····';

  @override
  String get fieldTwoFactsWarning =>
      'Thís lábél pácks twó fácts. Splít ít íntó twó fíélds, ór kéép thís óné ánywáy.····························';

  @override
  String get fieldDefaultValue => 'Défáúlt válúé·····';

  @override
  String get fieldUnit => 'Únít··';

  @override
  String get fieldHelp => 'Hélp··';

  @override
  String get fieldInputMode => 'Whó máy fíll ít······';

  @override
  String get fieldInputAny => 'Ányóné···';

  @override
  String get fieldInputManual => 'Á pérsón ónly·····';

  @override
  String get fieldInputAi => 'ÁÍ máy própósé·····';

  @override
  String get fieldInputAuto => 'Fílléd by thé ápp······';

  @override
  String get fieldStickable => 'Pín ás cóntéxt·····';

  @override
  String get fieldContextLevel => 'Cóntéxt lévél·····';

  @override
  String get fieldAutoFill => 'Fíll áútómátícálly·······';

  @override
  String get fieldAutoFillNone => 'Dó nót fíll····';

  @override
  String get fieldAutoFillLabel => 'Nów··';

  @override
  String get fieldAutoFillLabelToday => 'Tódáy··';

  @override
  String get fieldAutoFillLabelTimeOfDay => 'Tímé óf dáy····';

  @override
  String get fieldAutoFillLabelNextInSequence => 'Néxt ín séqúéncé······';

  @override
  String get fieldAutoFillLabelSignedInOperator => 'Sígnéd-ín ópérátór·······';

  @override
  String get fieldAutoFillLabelThisDevice => 'Thís dévícé····';

  @override
  String get fieldAutoFillLabelCurrentLocation => 'Cúrrént lócátíón······';

  @override
  String get fieldAutoFillLabelPinnedContext => 'Pínnéd cóntéxt·····';

  @override
  String get fieldRefine => 'Stóré á réfínéd cómpáníón·········';

  @override
  String get fieldIdentity => 'Úsé fór dúplícátés·······';

  @override
  String get fieldRequiredWhen => 'Réqúíréd whén·····';

  @override
  String fieldRequiredWhenPreview(Object reading) {
    return 'Réqúíréd whén ·····$reading';
  }

  @override
  String get fieldHidden => 'Hídé fróm cáptúré ánd éxpórt··········';

  @override
  String get fieldHiddenHelp =>
      'Válúés álréády cáptúréd stáy ón thé récórd.················';

  @override
  String get fieldValidationTitle => 'Válídátíón····';

  @override
  String get fieldValidationEmptyHeadline => 'Nó válídátíón yét······';

  @override
  String get fieldValidationEmptyMessage =>
      'Ádd á páttérn, léngth, rángé ór réqúíréd-wíth rúlé.··················';

  @override
  String get fieldPattern => 'Páttérn···';

  @override
  String get fieldPatternNone => 'Nóné··';

  @override
  String get fieldPatternSerial => 'Séríál···';

  @override
  String get fieldPatternAssetTag => 'Ássét tág····';

  @override
  String get fieldPatternRegistration => 'Régístrátíón·····';

  @override
  String get fieldPatternCustom => 'Cústóm···';

  @override
  String get fieldPatternTest => 'Try á válúé····';

  @override
  String get fieldPatternTestPass => 'Thát válúé ís állówéd.········';

  @override
  String get fieldMinLength => 'Shórtést···';

  @override
  String get fieldMaxLength => 'Lóngést···';

  @override
  String get fieldRangeMin => 'Lówést···';

  @override
  String get fieldRangeMax => 'Híghést···';

  @override
  String get fieldRequiredWith => 'Réqúíréd wíth·····';

  @override
  String get fieldOptionsTitle => 'Chóícés···';

  @override
  String get fieldOptionsEmptyHeadline => 'Nó chóícés yét·····';

  @override
  String get fieldOptionsEmptyMessage =>
      'Ádd á chóícé só cáptúré hás sóméthíng tó píck.·················';

  @override
  String get fieldOptionLabel => 'Chóícé námé····';

  @override
  String get fieldOptionAdd => 'Ádd á chóícé·····';

  @override
  String get fieldOptionRetire => 'Rétíré chóícé·····';

  @override
  String get fieldOptionRetired => 'Rétíréd···';

  @override
  String get fieldAddEmptyHeadline => 'Nó témpláté tó édít·······';

  @override
  String get fieldAddEmptyMessage =>
      'Ópén thé témpláté líst ánd píck á témpláté fírst.··················';

  @override
  String get requiredColumnsTitle => 'Réqúíréd cólúmns······';

  @override
  String get requiredColumnsEmptyHeadline => 'Nó cólúmns tó sét······';

  @override
  String get requiredColumnsEmptyMessage =>
      'Ádd á fíéld fírst, thén chóósé whát thís prójéct ínsísts ón.·····················';

  @override
  String get requiredColumnHide => 'Hídé··';

  @override
  String get requiredColumnShowGroup => 'Shów gróúp····';

  @override
  String get requiredColumnHideGroup => 'Hídé gróúp····';

  @override
  String get requiredColumnUngrouped => 'Fíélds···';

  @override
  String requiredColumnRadios(Object label) {
    return 'Réqúíréd? · ·····$label';
  }

  @override
  String requiredColumnCell(Object label, Object mark) {
    return '$label, $mark';
  }

  @override
  String requiredColumnShipped(Object mark) {
    return 'Shíppéd ás ····$mark';
  }

  @override
  String requiredColumnGroup(Object group) {
    return 'témplátés.gróúps.······$group.$group';
  }

  @override
  String get identityFieldsTitle => 'Ídéntíty fíélds······';

  @override
  String get identityFieldsExplain =>
      'Thésé fíélds décídé whéthér twó récórds áré thé sámé thíng.·····················';

  @override
  String get identityFieldsEmptyHeadline => 'Nó fíélds tó márk······';

  @override
  String get identityFieldsEmptyMessage =>
      'Ádd á fíéld fírst, thén chóósé whích ónés ídéntífy á récórd.·····················';

  @override
  String get outputMappingTitle => 'Óútpút cólúmns·····';

  @override
  String get outputMappingEmptyHeadline => 'Nó cólúmns tó máp······';

  @override
  String get outputMappingEmptyMessage =>
      'Ádd á fíéld fírst, thén chóósé whéré éách óné wrítés.···················';

  @override
  String get outputMappingDuplicate =>
      'Twó fíélds cánnót wríté tó thé sámé cólúmn.················';

  @override
  String get outputMappingDuplicateRecovery =>
      'Gívé éách fíéld íts ówn cólúmn, thén sávé.···············';

  @override
  String get outputMappingBuiltHint =>
      'Héádérs áré générátéd fróm thé fíéld lábéls. Yóú cán chángé thém.·······················';

  @override
  String get outputMappingImportedHint =>
      'Thésé léttérs cámé fróm thé wórkbóók. Yóú cán chángé thém.·····················';

  @override
  String get templateMigrationTitle => 'Móvé récórds·····';

  @override
  String get templateMigrationExplain =>
      'Récórds stáy ón thé vérsíón théy wéré cáptúréd úndér úntíl yóú móvé thém.··························';

  @override
  String get templateMigrationEmptyHeadline => 'Nóthíng tó móvé······';

  @override
  String get templateMigrationEmptyMessage =>
      'Évéry récórd ís álréády ón thís témpláté vérsíón.··················';

  @override
  String get templateMigrationAdded => 'Áddéd fíélds·····';

  @override
  String get templateMigrationRemoved => 'Rémóvéd fíélds·····';

  @override
  String get templateMigrationRetyped => 'Rétypéd fíélds·····';

  @override
  String get templateMigrationConfirmTitle => 'Móvé thésé récórds?·······';

  @override
  String templateMigrationConfirm(Object recordsCountrecords) {
    return 'Thís móvés ····$recordsCountrecords tó thé néw vérsíón ín óné stép. Válúés óf rémóvéd fíélds áré képt ánd rétíréd.····························';
  }

  @override
  String templateMigrationBehind(Object recordsCountrecords) {
    return '$recordsCountrecords ón án éárlíér vérsíón········';
  }

  @override
  String templateMigrationUnresolved(Object recordsCountrecords) {
    return '$recordsCountrecords wéré cáptúréd úndér á vérsíón thís dévícé nó lóngér hás. Théír válúés fór fíélds nót ón thé cúrrént témpláté áré lístéd úndér Válúés thát wíll rétíré.·····················································';
  }

  @override
  String get templateMigrationRetiring => 'Válúés thát wíll rétíré·········';

  @override
  String get templateMigrationAction => 'Móvé récórds·····';

  @override
  String templateCopyName(Object name) {
    return '$name (cópy)···';
  }

  @override
  String templateListSubtitle(
    Object fieldsCountfields,
    Object recordsCountrecords,
  ) {
    return '$fieldsCountfields · $recordsCountrecords';
  }

  @override
  String get templatesLibraryTitle => 'Shíppéd témplátés······';

  @override
  String get templatesLibraryEmptyHeadline => 'Nó shíppéd témplátés·······';

  @override
  String get templatesLibraryEmptyMessage =>
      'Créáté á blánk témpláté tó stárt cáptúríng.················';

  @override
  String get templatesAdd => 'Ádd tó thís prójéct·······';

  @override
  String get templatesAddToProject => 'Ádd tó prójéct·····';

  @override
  String get templatesCustomCopy => 'Créáté á cústóm cópy·······';

  @override
  String get shippedAddedToProject => 'Áddéd tó thís prójéct········';

  @override
  String get shippedLibrarySearchHint =>
      'Séárch ór déscríbé yóúr wórk··········';

  @override
  String shippedAreaTitle(Object code, Object title) {
    return '$code · $title';
  }

  @override
  String shippedCatalogueCategoryTitle(Object code, Object title) {
    return '$code — $title';
  }

  @override
  String shippedCategoryHeading(
    Object shippedCatalogueCategoryTitlecodetitle,
    int count,
  ) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$shippedCatalogueCategoryTitlecodetitle · $countString';
  }

  @override
  String shippedCatalogueSubtitle(
    Object code,
    Object recordType,
    Object fieldsCountfields,
  ) {
    return '$code · $recordType · $fieldsCountfields';
  }

  @override
  String get shippedFiltersTitle => 'Líbráry fíltérs······';

  @override
  String get shippedAreaFilter => 'Áréá··';

  @override
  String get shippedRecordTypeFilter => 'Récórd typé····';

  @override
  String get shippedTierFilter => 'Tíér··';

  @override
  String get shippedTierLabel => 'Fóúndátíón····';

  @override
  String get shippedTierLabelExpansion => 'Éxpánsíón····';

  @override
  String get shippedTierLabelSpecialist => 'Spécíálíst····';

  @override
  String get shippedPrivacyLabel => 'Íntérnál···';

  @override
  String get shippedPrivacyLabelConfidential => 'Cónfídéntíál·····';

  @override
  String get shippedPrivacyLabelRestricted => 'Réstríctéd····';

  @override
  String get shippedCategoryLabel => 'Cátégóry···';

  @override
  String get shippedRecordTypeLabel => 'Récórd typé····';

  @override
  String get shippedPrivacyTierLabel => 'Súggéstéd prívácy ánd tíér··········';

  @override
  String shippedPrivacyTier(
    Object shippedPrivacyLabelprivacy,
    Object shippedTierLabelrollout,
  ) {
    return '$shippedPrivacyLabelprivacy · $shippedTierLabelrollout';
  }

  @override
  String get shippedCaptureLabel => 'Cáptúré···';

  @override
  String get shippedAiAssistanceLabel => 'ÁÍ ássístáncé·····';

  @override
  String get shippedOutputsLabel => 'Óútpúts···';

  @override
  String get shippedReviewLabel => 'Révíéw···';

  @override
  String shippedFieldSubtitle(Object fieldTypeLabeltype, Object requiredness) {
    return '$fieldTypeLabeltype · $requiredness';
  }

  @override
  String get shippedLibraryNoMatch => 'Nó témplátés mátch.·······';

  @override
  String shippedLibraryNoMatchNoTemplatesMatch(Object shown) {
    return 'Nó témplátés mátch \"·······$shown\".';
  }

  @override
  String get shippedLabel => 'ítém_··';

  @override
  String shippedLabelValue(Object wordsindex) {
    return ' $wordsindex';
  }

  @override
  String shippedLabelValue2(Object text0toUpperCase, Object textsubstring1) {
    return '$text0toUpperCase$textsubstring1';
  }

  @override
  String get navQueue => 'Únprócésséd····';

  @override
  String get navExports => 'Éxpórts···';

  @override
  String get operatorNameUse =>
      'Úséd ón évéry récórd yóú cáptúré fróm thís dévícé.··················';

  @override
  String get operatorName => 'Námé··';

  @override
  String get operatorProfileTitle => 'Ópérátór···';

  @override
  String get operatorInitials => 'Ínítíáls···';

  @override
  String get operatorContact => 'Cóntáct···';

  @override
  String get operatorEmail => 'Émáíl··';

  @override
  String get operatorPhone => 'Phóné··';

  @override
  String get nameRequired => 'Éntér á námé·····';

  @override
  String get emailNeedsAt => 'Ínclúdé án @ ín thé émáíl·········';

  @override
  String get initialsLength => 'Úsé óné tó thréé cháráctérs··········';

  @override
  String get statusNoProject => 'Nó prójéct····';

  @override
  String get statusNoContext => 'Nó cóntéxt····';

  @override
  String get contextHierarchyTitle => 'Prójéct cóntéxts······';

  @override
  String get contextHierarchyEmptyHeadline => 'Nó cóntéxt lévéls······';

  @override
  String get contextHierarchyEmptyMessage =>
      'Ádd fíéld kéys fróm á témpláté tó búíld á híérárchy, ór léávé nóné.························';

  @override
  String get contextAddLevel => 'Ádd lévél····';

  @override
  String contextLevelRow(int level, Object fieldKey) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Lévél ···$levelString · $fieldKey';
  }

  @override
  String get contextUseTemplateLevels => 'Úsé témpláté lévéls·······';

  @override
  String get contextTemplateFailureHeadline =>
      'Témpláté lévéls cóúld nót lóád···········';

  @override
  String get contextTemplateFailureMessage =>
      'Try ágáín. Yóúr sávéd cóntéxt hás nót chángéd.·················';

  @override
  String get contextNoTemplatesHeadline => 'Nó prójéct témplátés·······';

  @override
  String get contextNoTemplatesMessage =>
      'Áttách ór créáté á témpláté béfóré chóósíng cóntéxt fíélds.·····················';

  @override
  String get contextOpenTemplates => 'Ádd témplátés·····';

  @override
  String get contextNoDeclaredLevelsHeadline =>
      'Nó témpláté lévéls décláréd··········';

  @override
  String get contextNoDeclaredLevelsMessage =>
      'Sét á pósítívé cóntéxt lévél ón témpláté fíélds, ór ádd lévéls mánúálly.··························';

  @override
  String get contextNoEligibleFieldsHeadline => 'Nó fíélds áváíláblé·······';

  @override
  String get contextNoEligibleFieldsMessage =>
      'Évéry témpláté fíéld ís álréády úséd ás á cóntéxt lévél.····················';

  @override
  String get contextTemplateConflictHeadline =>
      'Témpláté lévéls cónflíct·········';

  @override
  String contextTemplateConflictMessage(Object conflicts) {
    return 'Résólvé thésé déclárátíóns ín Témplátés: ···············$conflicts.';
  }

  @override
  String get contextSaveHierarchy => 'Sávé lévéls····';

  @override
  String contextPickerTitle(Object label) {
    return 'Sét ··$label';
  }

  @override
  String get contextRecents => 'Récént···';

  @override
  String get contextDatasetSearch => 'Fróm dátásét·····';

  @override
  String get contextUseValue => 'Úsé thís válúé·····';

  @override
  String get contextTypeValue => 'Typé á válúé·····';

  @override
  String get contextValueNotSet => 'Nót sét···';

  @override
  String get contextClearPin => 'Cléár pín····';

  @override
  String contextPinnedValue(Object field, Object value) {
    return '$field: $value';
  }

  @override
  String get contextPinnedTitle => 'Pínnéd fíélds·····';

  @override
  String get contextPinnedEmptyHeadline =>
      'Nó pínnáblé cóntéxt fíélds··········';

  @override
  String get contextPinnedEmptyMessage =>
      'Márk fíélds ás pínnéd cóntéxt ón á témpláté tó réúsé thém dúríng cáptúré.··························';

  @override
  String get contextMarkPinnable => 'Márk á fíéld ás pínnáblé·········';

  @override
  String get contextPinnedRelevance =>
      'Pínnéd cóntéxt ís réúséd ón éách néw récórd úntíl yóú chángé ít.·······················';

  @override
  String get contextCascadeTitle => 'Cléár lówér lévéls?·······';

  @override
  String contextCascadeMessage(
    Object levelLabel,
    Object newValue,
    Object andnamed,
  ) {
    return 'Chángé ···$levelLabel tó ··$newValue? $andnamed wíll bé cléáréd.······';
  }

  @override
  String get contextCascadeConfirm => 'Cléár ánd cóntínúé·······';

  @override
  String get contextPresetsTitle => 'Cóntéxt préséts······';

  @override
  String get contextPresetsEmptyHeadline => 'Nó préséts yét·····';

  @override
  String get contextPresetsEmptyMessage =>
      'Sávé thé cúrrént cóntéxt, thén ápply thé prését ín óné táp.·····················';

  @override
  String get contextPresetSave => 'Sávé prését····';

  @override
  String get contextPresetApply => 'Ápply prését·····';

  @override
  String get contextPresetsChip => 'Préséts···';

  @override
  String get contextPresetsHint =>
      'Sávé thé cúrrént válúés, ór swítch róóms ín óné táp.···················';

  @override
  String get contextPresetName => 'Prését námé····';

  @override
  String contextPresetApplied(Object name) {
    return 'Swítchéd tó ·····$name.';
  }

  @override
  String contextPresetSaved(Object name) {
    return 'Sávéd prését ·····$name.';
  }

  @override
  String get contextPresetDelete => 'Délété prését·····';

  @override
  String contextPresetDeleteMessage(Object name) {
    return 'Délété ···$name? Válúés álréády sét stáy ás théy áré.··············';
  }

  @override
  String get contextPresetDeleteReason => 'Délétéd fróm thé líst.········';

  @override
  String get contextPresetOverwriteTitle => 'Réplácé prését?······';

  @override
  String get contextPresetOverwriteMessage =>
      'Á prését wíth thát námé álréády éxísts. Réplácé ít?··················';

  @override
  String get contextPresetReplace => 'Réplácé···';

  @override
  String get contextAutoClearUndo => 'Úndó··';

  @override
  String contextAutoClearMessage(Object label) {
    return 'Cléáréd ···$label áftér ídlé.·····';
  }

  @override
  String get contextMovementTitle => 'Cónfírm cóntéxt······';

  @override
  String get contextMovementMessage =>
      'Yóú hávé móvéd. Ís thé cúrrént cóntéxt stíll córréct?···················';

  @override
  String get contextMovementChange => 'Chángé cóntéxt·····';

  @override
  String get contextPinMarker => 'Pínnéd···';

  @override
  String contextSetLevel(Object level) {
    return 'Sét ··$level';
  }

  @override
  String contextLevelValue(Object level, Object value) {
    return '$level: $value';
  }

  @override
  String get contextManage => 'Mánágé···';

  @override
  String get contextSetUp => 'Sét úp cóntéxt·····';

  @override
  String get contextRemoveLevel => 'Rémóvé lévél·····';

  @override
  String contextDragLevel(Object level) {
    return 'Drág ··$level tó réórdér····';
  }

  @override
  String get settingsContextAutoClear =>
      'Cléár thé lówést lévél whén ídlé············';

  @override
  String get settingsContextAutoClearEffect =>
      'Óff úntíl yóú túrn ít ón. Cléárs ónly thé lówést lévél, ánd yóú cán úndó.··························';

  @override
  String settingsContextIdleSubtitle(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Áftér ···$minutesString mínútés wíth nó chángé.·········';
  }

  @override
  String get settingsContextMovement =>
      'Cónfírm cóntéxt áftér móvémént···········';

  @override
  String get settingsContextMovementEffect =>
      'Óff úntíl yóú túrn ít ón. Ásks yóú tó cónfírm. Ít dóés nót chángé cóntéxt. Nééds GPS ánd lócátíón álréády állówéd.········································';

  @override
  String settingsContextDistanceSubtitle(int metres) {
    final intl.NumberFormat metresNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String metresString = metresNumberFormat.format(metres);

    return 'Áftér ···$metresString métrés.···';
  }

  @override
  String get settingsContextIdle => 'Cléár cóntéxt áftér·······';

  @override
  String get settingsContextIdleEffect =>
      'Hów lóng wíth nó chángé béfóré thé lówést lévél cléárs.····················';

  @override
  String settingsContextIdleOption(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString mínútés···',
      one: '1 mínúté···',
    );
    return '$_temp0';
  }

  @override
  String get settingsContextDistance => 'Ásk whén Í móvé······';

  @override
  String get settingsContextDistanceEffect =>
      'Hów fár yóú móvé béfóré Táptúré ásks yóú tó cónfírm thé cóntéxt.·······················';

  @override
  String settingsContextDistanceOption(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString métrés···',
      one: '1 métré···',
    );
    return '$_temp0';
  }

  @override
  String get captureTitle => 'Cáptúré···';

  @override
  String get captureSaveAndAnalyse => 'Sávé ánd prócéss······';

  @override
  String get captureProcessNeedsNetwork =>
      'Sávé ráw nów. Prócéss ít óncé thís dévícé ís ónlíné.···················';

  @override
  String get captureSaveRaw => 'Sávé ráw···';

  @override
  String get captureNoPhotosHeadline => 'Nó phótós yét·····';

  @override
  String get captureNoPhotosMessage =>
      'Ádd á phótó, ímpórt á fílé, ór typé á cáptíón tó stárt.····················';

  @override
  String get captureProjectLabel => 'Prójéct···';

  @override
  String get captureChooseProject =>
      'Chóósé á prójéct tó stárt cáptúríng.·············';

  @override
  String get captureCreateProjectFirst =>
      'Créáté á prójéct béfóré cáptúríng.············';

  @override
  String get captureNoProjectMessage =>
      'Évéry phótó ánd récórd ís fíléd úndér á prójéct.·················';

  @override
  String get captureNeedsTemplate =>
      'Ádd á témpláté béfóré cáptúríng.············';

  @override
  String get captureMoreFields => 'Móré fíélds····';

  @override
  String get captureCameraReason =>
      'Táptúré nééds thé cámérá tó phótógráph éqúípmént ánd dócúménts.·······················';

  @override
  String get captureOpenCameraSettings => 'Ópén séttíngs·····';

  @override
  String get captureAllowCamera => 'Állów cámérá·····';

  @override
  String get captureCameraTitle => 'Cámérá···';

  @override
  String get captureKeepPhoto => 'Kéép··';

  @override
  String get captureRetakePhoto => 'Rétáké···';

  @override
  String get captureDocumentMode => 'Dócúmént módé·····';

  @override
  String get capturePageBoundaryFound =>
      'Págé édgé fóúnd. Á stráíghténéd cópy ís réády.·················';

  @override
  String get captureUseCorrected => 'Úsé córréctéd·····';

  @override
  String get captureCorrectionFailed =>
      'Thé págé cóúld nót bé stráíghténéd. Thé órígínál ís képt.····················';

  @override
  String get captureNoPageBoundary =>
      'Nó págé édgé fóúnd. Cáptúréd ás á nórmál phótó.·················';

  @override
  String get captureFlashOff => 'Flásh óff····';

  @override
  String get captureFlashAuto => 'Flásh áútó····';

  @override
  String get captureFlashOn => 'Flásh ón···';

  @override
  String get captureGrid => 'Gríd··';

  @override
  String get captureFocus => 'Fócús··';

  @override
  String get captureZoomOut => 'Zóóm óút···';

  @override
  String get captureZoomIn => 'Zóóm ín···';

  @override
  String get captureImportGallery => 'Ímpórt phótós·····';

  @override
  String get captureImportDocument => 'Ímpórt dócúmént······';

  @override
  String get captureDocumentsUnavailable =>
      'Dócúménts áré nót áváíláblé ón thís dévícé.················';

  @override
  String get captureDocumentsUnavailableRecovery =>
      'Try ágáín áftér réópéníng thé ápp.············';

  @override
  String get tryAnotherFile => 'Try ánóthér fílé······';

  @override
  String get pdfInvalid => 'Thát PDF cóúld nót bé réád.··········';

  @override
  String captureDocumentInvalid(Object filename) {
    return 'Thé cónténts óf ······$filename cóúld nót bé réád.·······';
  }

  @override
  String get pdfPageMissing => 'Thát págé ís nót ín thé dócúmént.············';

  @override
  String get pdfPreviousPage => 'Prévíóús págé·····';

  @override
  String get pdfNextPage => 'Néxt págé····';

  @override
  String get barcodeUnavailable =>
      'Bárcódé scánníng ís nót áváíláblé ón thís dévícé.··················';

  @override
  String get barcodeAllowCamera =>
      'Állów thé cámérá ín séttíngs tó scán, ór typé thé códé.····················';

  @override
  String get barcodeConfirm => 'Úsé thís códé·····';

  @override
  String get barcodeRescan => 'Scán ágáín····';

  @override
  String get barcodeNoCode => 'Póínt át á bárcódé·······';

  @override
  String get barcodeTitle => 'Scán á códé····';

  @override
  String get barcodeTorch => 'Tórch··';

  @override
  String get barcodeUnreadable => 'Thát códé cóúld nót bé réád.··········';

  @override
  String barcodeScanCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Scánnéd ···$nString';
  }

  @override
  String barcodeCountPosition(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Scán ··$nString';
  }

  @override
  String get barcodeCountMode => 'Cóúnt ítéms····';

  @override
  String get barcodeUndoLast => 'Úndó lást····';

  @override
  String get identifierMatchRecord => 'Ópén récórd····';

  @override
  String get identifierMatchReference => 'Úsé référéncé·····';

  @override
  String get identifierNewRecord => 'Néw récórd····';

  @override
  String get identifierDuplicates => 'Sévérál mátchés······';

  @override
  String get captureRecordCaption => 'Cáptíón···';

  @override
  String get capturePhotosSection => 'Phótós···';

  @override
  String get captureAudioSection => 'Áúdíó··';

  @override
  String get captureRemovePhoto => 'Rémóvé phótó·····';

  @override
  String captionAddToAll(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ádd tó áll ····$countString phótós···',
      one: 'Ádd tó thé phótó······',
    );
    return '$_temp0';
  }

  @override
  String captionAddToTicked(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ádd tó ···$countString tíckéd phótós·····',
      one: 'Ádd tó 1 tíckéd phótó········',
    );
    return '$_temp0';
  }

  @override
  String captionAdded(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Áddéd tó ····$countString phótós···',
      one: 'Áddéd tó thé phótó·······',
    );
    return '$_temp0';
  }

  @override
  String get captionAppend => 'Áppénd···';

  @override
  String get captionReplace => 'Réplácé···';

  @override
  String get captureMicReason =>
      'Táptúré nééds thé mícróphóné fór spókén nótés ón án éxplícít táp.·······················';

  @override
  String get captureListening => 'Lísténíng…····';

  @override
  String get captureRecordAudio => 'Récórd áúdíó·····';

  @override
  String get captureRecordTranscribe => 'Récórd ánd tránscríbé········';

  @override
  String get capturePauseAudio => 'Páúsé··';

  @override
  String get captureStopAudio => 'Stóp··';

  @override
  String get audioRecorderUnavailable =>
      'Áúdíó récórdíng ís nót áváíláblé ón thís dévícé.·················';

  @override
  String get microphoneBusy =>
      'Thé mícróphóné ís ín úsé by ánóthér récórdíng. Stóp ít fírst, thén try ágáín.···························';

  @override
  String get audioStartFailed => 'Récórdíng cóúld nót stárt.··········';

  @override
  String get audioStartFailedRecovery =>
      'Try ágáín. Nóthíng álréády cáptúréd wás lóst.················';

  @override
  String get audioTakeLimitReached =>
      'Thís récórdíng réáchéd thé lóngést táké thís brówsér cán kéép. Évérythíng cáptúréd só fár ís képt.···································';

  @override
  String get audioTakeLimitReachedRecovery =>
      'Stóp thís récórdíng, thén stárt á néw óné tó cóntínúé.···················';

  @override
  String get audioPathOutsideStorage =>
      'Thé récórdíng múst bé sávéd ínsídé thé prójéct fóldér.···················';

  @override
  String get audioPermissionDenied =>
      'Mícróphóné pérmíssíón wás nót grántéd.··············';

  @override
  String get audioPermissionRecovery =>
      'Állów mícróphóné áccéss ín systém séttíngs, thén try ágáín.·····················';

  @override
  String get audioRecorderStatus =>
      'Réqúéstíng mícróphóné pérmíssíón············';

  @override
  String get audioRecorderStatusRecording => 'Récórdíng····';

  @override
  String get audioRecorderStatusPaused => 'Páúséd···';

  @override
  String get audioRecorderStatusSavingAudio => 'Sávíng áúdíó·····';

  @override
  String get audioRecorderStatusAudioFailed => 'Áúdíó fáíléd·····';

  @override
  String get audioRecorderStatusAudioSaved => 'Áúdíó sávéd····';

  @override
  String get audioRecorderStatusAudioReady => 'Áúdíó réády····';

  @override
  String get liveTranscriptStart => 'Stárt récórdíng······';

  @override
  String get liveTranscriptCancel => 'Díscárd···';

  @override
  String get liveTranscriptStatusStarting => 'Ópéníng thé mícróphóné········';

  @override
  String get liveTranscriptStatusListening =>
      'Récórdíng ánd tránscríbíng··········';

  @override
  String get liveTranscriptStatusPaused => 'Páúséd···';

  @override
  String get liveTranscriptStatusFinishing =>
      'Fíníshíng thé tránscrípt·········';

  @override
  String get liveTranscriptEmpty =>
      'Spéák, ánd thé wórds áppéár héré.············';

  @override
  String get liveTranscriptJumpToLatest => 'Júmp tó látést·····';

  @override
  String get transcriptViewLabel => 'Tránscrípt····';

  @override
  String get liveTranscriptStatusDraining =>
      'Sávéd. Fíníshíng thé tránscrípt.············';

  @override
  String get liveTranscriptStatusSaved => 'Sávéd ón thís dévícé·······';

  @override
  String get liveTranscriptStatusPausedBackground =>
      'Páúséd whílé Táptúré wás ín thé báckgróúnd. Évérythíng só fár ís sávéd.·························';

  @override
  String get liveTranscriptStatusPausedInterruption =>
      'Páúséd by ánóthér ápp ór á cáll.············';

  @override
  String get liveTranscriptMicLost =>
      'Thé mícróphóné wás túrnéd óff. Whát wás récórdéd ís sávéd.·····················';

  @override
  String get liveTranscriptPermissionRevoked =>
      'Mícróphóné áccéss wás túrnéd óff. Whát wás récórdéd ís sávéd. Állów áccéss tó gó ón, ór stóp tó kéép ít.·····································';

  @override
  String get liveTranscriptRetrySave => 'Try sávíng ágáín······';

  @override
  String get liveTranscriptOpen => 'Ópén tránscrípt······';

  @override
  String get liveTranscriptCancelTitle => 'Díscárd thís récórdíng?·········';

  @override
  String get liveTranscriptCancelMessage =>
      'Ít ís nót áddéd héré. Thé áúdíó fílé stáys ín thé prójéct fóldér.·······················';

  @override
  String get liveTranscriptAudioOnly =>
      'Récórdíng wíthóút á lívé tránscrípt: nó spééch módél ís áváíláblé.························';

  @override
  String liveTranscriptBehind(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Thé tránscrípt ís ·······$minutesString mínútés béhínd. Récórdíng góés ón.·············',
      one:
          'Thé tránscrípt ís 1 mínúté béhínd. Récórdíng góés ón.···················',
      zero:
          'Thé tránscrípt ís cátchíng úp. Récórdíng góés ón.··················',
    );
    return '$_temp0';
  }

  @override
  String get liveTranscriptUtteranceSkipped =>
      'Á párt cóúld nót bé tránscríbéd. Íts áúdíó ís képt.··················';

  @override
  String get liveTranscriptUnsaved =>
      'Thé tránscrípt cóúld nót bé sávéd yét. Thé récórdíng ís képt, ánd sávíng ís tríéd ágáín.·······························';

  @override
  String get liveTranscriptSessionLimit =>
      'Thé récórdíng réáchéd thé lóngést léngth állówéd ánd wás sávéd.·······················';

  @override
  String get liveTranscriptStorageStop =>
      'Stórágé ís fúll, só récórdíng stóppéd. Whát wás récórdéd ís sávéd.························';

  @override
  String get liveTranscriptStorageLow =>
      'Stórágé ís rúnníng lów. Récórdíng góés ón.···············';

  @override
  String get liveTranscriptListTitle => 'Tránscrípts····';

  @override
  String get liveTranscriptUntitled => 'Úntítléd tránscrípt·······';

  @override
  String liveTranscriptRowWhen(Object when) {
    return 'Récórdéd ····$when';
  }

  @override
  String liveTranscriptRowDetail(Object when, Object preview) {
    return '$when · $preview';
  }

  @override
  String get liveTranscriptEdited => 'Édítéd···';

  @override
  String get liveTranscriptInterrupted => 'Íntérrúptéd····';

  @override
  String get liveTranscriptRecording => 'Récórdíng····';

  @override
  String get speechOfflineBadge => 'Ón thís dévícé·····';

  @override
  String get liveTranscriptUnavailable =>
      'Lívé tránscríptíón nééds á spééch módél ón thís dévícé.····················';

  @override
  String get liveTranscriptUnavailableRecovery =>
      'Ópén Séttíngs, Lángúágé, tó chéck thé spééch módél.··················';

  @override
  String get navTranscripts => 'Tránscrípts····';

  @override
  String get transcriptsTitle => 'Tránscrípts····';

  @override
  String get transcriptsNew => 'Néw tránscríptíón······';

  @override
  String get transcriptsEmptyHeadline => 'Nó tránscrípts yét·······';

  @override
  String get transcriptsEmptyMessage =>
      'Récórd spééch ánd Táptúré wrítés ít dówn ón thís dévícé. Nó cónnéctíón ís néédéd.·····························';

  @override
  String get transcriptsNoMatchHeadline => 'Nó mátchíng tránscrípts·········';

  @override
  String get transcriptsSearchHint => 'Séárch tránscrípts·······';

  @override
  String get transcriptsNoProject => 'Ópén á prójéct tó tránscríbé··········';

  @override
  String get transcriptsNoProjectMessage =>
      'Récórdíngs ánd tránscrípts áré sávéd ín thé prójéct fóldér.·····················';

  @override
  String get transcribeTitle => 'Tránscríbé····';

  @override
  String get transcriptDetailTitle => 'Tránscrípt····';

  @override
  String get transcriptMissing =>
      'Thís tránscrípt ís nót ón thís dévícé·············';

  @override
  String get transcriptMissingMessage =>
      'Ít wás díscárdéd, ór ít bélóngs tó á prójéct thát ís nót héré.······················';

  @override
  String get transcriptOriginCapture => 'Fróm á cáptúré·····';

  @override
  String get transcriptOriginMeeting => 'Fróm á méétíng·····';

  @override
  String get transcriptOriginStandalone => 'Tránscríptíón·····';

  @override
  String get transcriptStatusInterrupted =>
      'Íntérrúptéd. Whát wás héárd ís képt.·············';

  @override
  String get transcriptEditedLabel => 'Édítéd téxt····';

  @override
  String get transcriptOriginalLabel => 'Órígínál, ás héárd·······';

  @override
  String get transcriptSaveEdit => 'Sávé chángés·····';

  @override
  String get transcriptEditSaved =>
      'Chángés sávéd. Thé órígínál tránscrípt ís képt.·················';

  @override
  String get transcriptRevert => 'Gó báck tó thé órígínál·········';

  @override
  String get transcriptRevertTitle =>
      'Gó báck tó thé órígínál tránscrípt?·············';

  @override
  String get transcriptRevertMessage =>
      'Yóúr chángés áré rémóvéd. Thé órígínál stáys ás ít wás récórdéd.·······················';

  @override
  String get transcriptRevertConfirm => 'Úsé órígínál·····';

  @override
  String get transcriptReverted =>
      'Thé órígínál tránscrípt ís báck.············';

  @override
  String get transcriptRename => 'Rénámé···';

  @override
  String get transcriptTitleLabel => 'Títlé··';

  @override
  String transcriptLanguage(Object language) {
    return 'Lángúágé: ····$language';
  }

  @override
  String transcriptModel(Object model) {
    return 'Spééch módél: ·····$model';
  }

  @override
  String transcriptAudioLength(Object minutes, Object seconds) {
    return 'Récórdíng ····$minutes:$seconds';
  }

  @override
  String get transcriptNoAudio =>
      'Thé récórdíng wás nót képt ón thís dévícé.···············';

  @override
  String transcriptGaps(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countString párts óf thé récórdíng áré nót tránscríbéd yét.·················',
      one:
          'Óné párt óf thé récórdíng ís nót tránscríbéd yét.··················',
      zero: 'Áll óf thé récórdíng ís tránscríbéd.·············',
    );
    return '$_temp0';
  }

  @override
  String get transcriptFinish => 'Fínísh thé tránscrípt········';

  @override
  String get transcriptFinished => 'Thé tránscrípt ís fíníshéd.··········';

  @override
  String get transcriptTranscribeOnDevice =>
      'Tránscríbé ón thís dévícé·········';

  @override
  String get captureAudioScopeTitle => 'Úsé áúdíó wíth·····';

  @override
  String get captureAudioCurrentPhoto => 'Cúrrént phótó·····';

  @override
  String captureAudioSelectedPhotos(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Séléctéd phótós (······$countString)';
  }

  @override
  String captureAudioAllPhotos(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Áll phótós (·····$countString)';
  }

  @override
  String captureAudioCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString áúdíó clíps áttáchéd········',
      one: '1 áúdíó clíp áttáchéd········',
    );
    return '$_temp0';
  }

  @override
  String get captureDeletePhotoTitle => 'Délété thís phótó?·······';

  @override
  String get captureDeletePhotoMessage =>
      'Ít léávés thé tráy nów. Thé fílé stáys úntíl thé réténtíón púrgé só yóú cán úndó.·····························';

  @override
  String get captureUndoDelete => 'Úndó··';

  @override
  String get capturePhotoDeleted => 'Phótó délétéd·····';

  @override
  String get captureMovePhotos => 'Móvé··';

  @override
  String get captureRecoveryTitle => 'Résúmé cáptúré?······';

  @override
  String captureRecoveryMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Án íntérrúptéd séssíón hás ··········$countString phótós.···',
      one: 'Án íntérrúptéd séssíón hás 1 phótó.·············',
      zero: 'Án íntérrúptéd séssíón hás nó phótós yét.···············',
    );
    return '$_temp0';
  }

  @override
  String get captureResume => 'Résúmé···';

  @override
  String get captureDiscard => 'Díscárd···';

  @override
  String get captureSessionDiscarded =>
      'Séssíón díscárdéd. Íts phótós stáy récóvéráblé.·················';

  @override
  String get captureRapidMode => 'Rápíd módé····';

  @override
  String captureRapidItem(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'Ítém ··$numberString';
  }

  @override
  String captureRapidSummary(Object photosCountphotos, Object caption) {
    return '$photosCountphotos · $caption';
  }

  @override
  String get captureRapidNext => 'Sávé ánd néxt ítém·······';

  @override
  String captureRapidProcessAll(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Prócéss áll (·····$countString)';
  }

  @override
  String captureRapidQueued(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ítéms qúéúéd fór prócéssíng··········',
      one: '1 ítém qúéúéd fór prócéssíng··········',
    );
    return '$_temp0';
  }

  @override
  String get captureRapidEmptyHeadline => 'Nó ítéms yét·····';

  @override
  String get captureRapidEmptyMessage =>
      'Táké phótós óf thé fírst ítém, thén sávé ít tó stárt thé néxt.······················';

  @override
  String captureRapidCurrent(Object photosCountphotos) {
    return 'Thís ítém: ····$photosCountphotos';
  }

  @override
  String captureStorageLow(Object free) {
    return 'Spácé ís géttíng lów: ········$free léft. Cáptúré cárríés ón.··········';
  }

  @override
  String captureStorageFull(Object free) {
    return 'Ónly ··$free léft, nót énóúgh fór á néw phótó. Éxpórt á prójéct ór cléán thé cáché tó máké róóm.······························';
  }

  @override
  String get captureStorageExport => 'Éxpórt···';

  @override
  String get captureNoTemplates =>
      'Thís prójéct hás nó témplátés yét. Yóú cán cáptúré nów ánd ádd óné látér.··························';

  @override
  String get capturePickTemplate => 'Témpláté···';

  @override
  String get capturePinSession => 'Pín fór séssíón······';

  @override
  String get captureTemplatePinned =>
      'Thís témpláté ís nów úséd héré évéry tímé.···············';

  @override
  String get capturePinContext => 'Pín fór cóntéxt······';

  @override
  String captureSelectedCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Séléctéd ····$nString';
  }

  @override
  String get captureSelectAll => 'Séléct áll····';

  @override
  String get captureClearSelection => 'Cléár··';

  @override
  String get captureAddPhoto => 'Ádd phótó····';

  @override
  String get captureAddSheetTitle => 'Ádd á phótó····';

  @override
  String get captureTakePhoto => 'Táké á phótó·····';

  @override
  String get captureChoosePhoto => 'Chóósé fróm thís dévícé·········';

  @override
  String get captureQualityBlur => 'Thís phótó lóóks blúrry.·········';

  @override
  String get captureQualityDark => 'Thís phótó lóóks dárk.········';

  @override
  String get captureQualityBright => 'Thís phótó lóóks óvéréxpóséd.···········';

  @override
  String get captureQualitySmallText =>
      'Smáll téxt máy bé hárd tó réád.···········';

  @override
  String get captureSaved => 'Sávéd··';

  @override
  String get captureSaving => 'Sávíng···';

  @override
  String get captureSaveFailed => 'Sávé fáíléd····';

  @override
  String get captureEnqueueFailed =>
      'Thé cáptúré wás sávéd, bút prócéssíng cóúld nót bé qúéúéd.·····················';

  @override
  String get captureNeedsEvidence =>
      'Ádd át léást óné phótó ór á cáptíón béfóré sávíng.··················';

  @override
  String get captureNeedsEvidenceRecovery =>
      'Ádd évídéncé, thén try ágáín.···········';

  @override
  String get captureOrderIncomplete =>
      'Thé phótó órdér ís íncómplété.···········';

  @override
  String get captureOrderIncompleteRecovery =>
      'Kéép évéry phótó ín thé tráy ánd try ágáín.················';

  @override
  String get captureChangeNotSaved =>
      'Thát chángé cóúld nót bé sávéd.···········';

  @override
  String get captureChangeNotSavedRecovery =>
      'Try ágáín. Nóthíng álréády cáptúréd wás lóst.················';

  @override
  String get captureRecordsUnavailable =>
      'Sávéd récórds cánnót bé édítéd ón thís dévícé.·················';

  @override
  String get captureRecordsUnavailableRecovery =>
      'Ópén thé récórd ón á dévícé thát stórés récórds.·················';

  @override
  String get statusNoTemplate => 'Nó témpláté····';

  @override
  String statusWhere(Object project, Object context) {
    return '$project · $context';
  }

  @override
  String get networkOnline => 'Ónlíné···';

  @override
  String get networkMetered => 'Météréd···';

  @override
  String get networkOffline => 'Ófflíné···';

  @override
  String get networkOfflineByChoice => 'Ófflíné by chóícé······';

  @override
  String get settingsOfflineTitle => 'Stáy ófflíné·····';

  @override
  String get settingsOfflineEffect =>
      'Évérythíng stíll wórks éxcépt séndíng.··············';

  @override
  String unprocessedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString únprócésséd·····',
      one: '1 únprócésséd·····',
      zero: '0 únprócésséd·····',
    );
    return '$_temp0';
  }

  @override
  String get offlineWorking =>
      'Yóú áré ófflíné. Cáptúrés stáy ón thís dévícé.·················';

  @override
  String get somethingWentWrong => 'Sóméthíng wént wróng·······';

  @override
  String get workStillOnDevice =>
      'Yóúr wórk ís stíll ón thís dévícé.············';

  @override
  String get restart => 'Réstárt···';

  @override
  String get exportLog => 'Éxpórt lóg····';

  @override
  String get openRecycleBin => 'Récyclé bín····';

  @override
  String get notFoundTitle => 'Págé nót fóúnd·····';

  @override
  String notFoundMessage(Object path) {
    return 'Thé págé \"····$path\" ís nót ín Táptúré.·······';
  }

  @override
  String get notFoundRecovery =>
      'Try ágáín tó gó báck tó Prójécts.············';

  @override
  String get appNameDev => 'Táptúré Dév····';

  @override
  String get settingsTitle => 'Séttíngs···';

  @override
  String get settingsGroupProfileCapture => 'Prófílé ánd cáptúré·······';

  @override
  String get settingsGroupIntelligenceAppearance =>
      'Íntéllígéncé ánd áppéáráncé··········';

  @override
  String get settingsGroupStorageSecurity => 'Stórágé ánd sécúríty·······';

  @override
  String get settingsGroupAbout => 'Ábóút··';

  @override
  String get settingsOperatorSubtitle =>
      'Námé, ínítíáls ánd cóntáct ón thís dévícé.···············';

  @override
  String get settingsCaptureSubtitle =>
      'Cámérá, dátés, lócátíón ánd hów néw fílés áré náméd.···················';

  @override
  String get settingsCaptureTitle => 'Cáptúré défáúlts······';

  @override
  String get settingsRelaySubtitle =>
      'Sénd chángés bétwéén thís prójéct\'s dévícés.················';

  @override
  String get settingsAiTitle => 'ÁÍ·';

  @override
  String get settingsAiSubtitle => 'Whén ánd hów própósáls rún.··········';

  @override
  String get settingsLanguageTitle => 'Lángúágé···';

  @override
  String get settingsLanguageSubtitle => 'Ápp ánd vóícé.·····';

  @override
  String get settingsAppLanguage => 'Ápp lángúágé·····';

  @override
  String get settingsAppLanguageEffect =>
      'Énglísh. Scrééns ánd mésságés úsé thís lángúágé.·················';

  @override
  String get settingsVoiceLanguage => 'Vóícé lángúágé·····';

  @override
  String get settingsSpeechSection => 'Spééch récógnítíón·······';

  @override
  String settingsSpeechEngineWhisper(Object model) {
    return 'Spééch ís túrnéd íntó téxt ón thís dévícé by thé ··················$model.';
  }

  @override
  String get settingsSpeechEnginePlatform =>
      'Spééch ís túrnéd íntó téxt by thís dévícé’s ówn spééch sérvícé, ón thé dévícé ónly.······························';

  @override
  String get settingsSpeechEngineNone =>
      'Vóícé ínpút ís nót áváíláblé ón thís dévícé yét.·················';

  @override
  String get settingsSpeechQuality => 'Tránscríptíón qúálíty········';

  @override
  String get settingsSpeechQualityEffect =>
      'Áútómátíc pícks thé bést módél thís dévícé cán rún smóóthly.·····················';

  @override
  String get settingsSpeechQualityAuto => 'Áútómátíc····';

  @override
  String get settingsSpeechQualityFast => 'Fástér, úsés léss báttéry·········';

  @override
  String get settingsSpeechQualityAccurate =>
      'Móré áccúráté, nééds á stróngér dévícé··············';

  @override
  String get settingsSpeechModels => 'Spééch módéls·····';

  @override
  String get settingsSpeechModelFast => 'Fást módél····';

  @override
  String get settingsSpeechModelBalanced => 'Báláncéd módél·····';

  @override
  String get settingsSpeechModelAccurate => 'Áccúráté módél·····';

  @override
  String get settingsSpeechModelVad => 'Vóícé détéctór·····';

  @override
  String get settingsSpeechModelBundled => 'Ínclúdéd wíth thé ápp········';

  @override
  String get settingsSpeechModelImported => 'Ímpórtéd···';

  @override
  String get settingsSpeechModelImportOnly => 'Ímpórt ónly····';

  @override
  String get settingsSpeechModelPresent => 'Ínstálléd····';

  @override
  String get settingsSpeechModelVerified => 'Chéckéd···';

  @override
  String get settingsSpeechModelMissing => 'Míssíng···';

  @override
  String get settingsSpeechModelDamaged => 'Dámágéd···';

  @override
  String get settingsSpeechModelInUse => 'Ín úsé···';

  @override
  String settingsSpeechModelDetail(Object origin, Object state, Object size) {
    return '$origin · $state · $size';
  }

  @override
  String get settingsSpeechTooLarge =>
      'Tóó lárgé fór thé mémóry thís dévícé hás fréé. Á smállér módél ís úséd.·························';

  @override
  String get settingsSpeechVerify => 'Vérífy···';

  @override
  String settingsSpeechVerified(Object model) {
    return 'Thé ··$model mátchés íts públíshéd fílé.··········';
  }

  @override
  String settingsSpeechVerifyMismatch(Object model) {
    return 'Thé ··$model dóés nót mátch íts públíshéd fílé. Ímpórt ít ágáín ór réínstáll thé ápp.··························';
  }

  @override
  String get settingsSpeechImport => 'Ímpórt á spééch módél········';

  @override
  String settingsSpeechImported(Object model) {
    return 'Thé ··$model wás chéckéd ánd áddéd.·········';
  }

  @override
  String get settingsSpeechRemove => 'Rémóvé···';

  @override
  String settingsSpeechRemoveTitle(Object model) {
    return 'Rémóvé thé ····$model?';
  }

  @override
  String get settingsSpeechRemoveMessage =>
      'Íts fílé ís délétéd fróm thís dévícé. Spééch úsés á smállér módél úntíl yóú ímpórt ít ágáín.·································';

  @override
  String settingsSpeechRemoved(Object model) {
    return 'Thé ··$model wás rémóvéd.·····';
  }

  @override
  String get languageEnglish => 'Énglísh···';

  @override
  String get languageFrench => 'Frénch···';

  @override
  String get languageSwahili => 'Swáhílí···';

  @override
  String get languagePortuguese => 'Pórtúgúésé····';

  @override
  String get languageSpanish => 'Spánísh···';

  @override
  String get languageArabic => 'Árábíc···';

  @override
  String get settingsAppearanceTitle => 'Áppéáráncé····';

  @override
  String get settingsAppearanceSubtitle =>
      'Systém, líght, dárk ór óútdóór.···········';

  @override
  String get themeModeSystem => 'Systém···';

  @override
  String get themeModeLight => 'Líght··';

  @override
  String get themeModeDark => 'Dárk··';

  @override
  String get themeModeOutdoor => 'Óútdóór···';

  @override
  String get settingsStorageTitle => 'Stórágé···';

  @override
  String get settingsStorageSubtitle =>
      'Spácé úséd, cáché ánd hów lóng fílés stáy.···············';

  @override
  String get settingsFilesTitle => 'Fílés··';

  @override
  String get settingsFilesSubtitle =>
      'Ímpórt, éxpórt, úplóáds ánd mérgés.·············';

  @override
  String get settingsFilesExportSubtitle =>
      'Sávé thé ópén prójéct ás á páckágé ór spréádshéét.··················';

  @override
  String get settingsFilesImportSubtitle =>
      'Bríng ín á prójéct páckágé ór á spréádshéét.················';

  @override
  String get settingsFilesMergeSubtitle =>
      'Cómbíné á páckágé fróm ánóthér dévícé íntó thé ópén prójéct.·····················';

  @override
  String get settingsFilesNoProject =>
      'Ópén á prójéct tó éxpórt ít ór mérgé íntó ít.················';

  @override
  String get settingsFilesUploadsSubtitle =>
      'Whát wás sént tó éách déstínátíón.············';

  @override
  String get settingsSecurityTitle => 'Sécúríty···';

  @override
  String get settingsSecuritySubtitle =>
      'Ápp lóck ánd éxpórt éncryptíón.···········';

  @override
  String get settingsAboutTitle => 'Ábóút··';

  @override
  String get settingsAboutSubtitle => 'Vérsíón ánd lícéncés.········';

  @override
  String get settingsTemplatesSubtitle =>
      'Créáté, ímpórt ánd édít thís prójéct\'s témplátés.··················';

  @override
  String get settingsQueueSubtitle =>
      'Récórds wáítíng tó bé prócésséd.············';

  @override
  String get settingsCamera => 'Cámérá···';

  @override
  String get settingsCameraEffect =>
      'Úséd át thé stárt óf thé néxt séssíón.··············';

  @override
  String get settingsCameraPhoto => 'Phótó··';

  @override
  String get settingsCameraDocument => 'Dócúmént···';

  @override
  String get settingsAutoFillDates => 'Fíll dátés áútómátícálly·········';

  @override
  String get settingsAutoFillDatesEffect =>
      'Néw cáptúrés gét tódáy wíthóút áskíng.··············';

  @override
  String get settingsGps => 'GPS··';

  @override
  String get settingsGpsWhyOff =>
      'Óff úntíl yóú túrn ít ón, só á lócátíón ís névér stóréd by áccídént.························';

  @override
  String get settingsPhotoQuality => 'Phótó qúálíty·····';

  @override
  String get settingsPhotoQualityEffect =>
      'Híghér qúálíty mákés lárgér fílés.············';

  @override
  String get settingsQualityStandard => 'Stándárd···';

  @override
  String get settingsQualitySmaller => 'Smállér fílés·····';

  @override
  String get settingsFolderStrategy => 'Phótó fóldérs·····';

  @override
  String get settingsFolderStrategyNewFilesOnly =>
      'Ápplíés tó néw fílés ónly. Éxístíng fílés stáy pút.··················';

  @override
  String get settingsFolderByContext => 'By cóntéxt····';

  @override
  String get settingsFolderByTemplate => 'By témpláté····';

  @override
  String get settingsFolderByDate => 'By dáté···';

  @override
  String get settingsFolderFlat => 'Óné fóldér····';

  @override
  String get settingsNamingPattern => 'Fílé námés····';

  @override
  String get settingsNamingEdit => 'Fílé námé páttérn······';

  @override
  String get settingsNamingPatternEffect =>
      'Hów á néw phótó fílé ís náméd.···········';

  @override
  String settingsCameraSubtitle(Object label, Object settingsCameraEffect) {
    return '$label. $settingsCameraEffect';
  }

  @override
  String settingsPhotoQualitySubtitle(
    Object label,
    Object settingsPhotoQualityEffect,
  ) {
    return '$label. $settingsPhotoQualityEffect';
  }

  @override
  String settingsNamingSubtitle(
    Object pattern,
    Object settingsNamingPatternEffect,
  ) {
    return '$pattern. $settingsNamingPatternEffect';
  }

  @override
  String settingsFolderStrategySubtitle(
    Object strategy,
    Object settingsFolderStrategyNewFilesOnly,
  ) {
    return '$strategy. $settingsFolderStrategyNewFilesOnly';
  }

  @override
  String get settingsProjectsHeader => 'Prójécts···';

  @override
  String get settingsHeadroomHeader => 'Fréé spácé····';

  @override
  String get settingsRetentionHeader => 'Réténtíón····';

  @override
  String get settingsStorageRoot => 'Stórágé fóldér·····';

  @override
  String get settingsStorageRootAfterRestart =>
      'Sávéd. Táptúré úsés thé néw fóldér thé néxt tímé ít ópéns.·····················';

  @override
  String get settingsVolumeTotal => 'Tótál··';

  @override
  String get settingsVolumeUsed => 'Úséd··';

  @override
  String get settingsVolumeAvailable => 'Áváíláblé····';

  @override
  String settingsVolumeFigures(
    Object settingsVolumeTotal,
    Object total,
    Object settingsVolumeUsed,
    Object used,
    Object settingsVolumeAvailable,
    Object available,
  ) {
    return '$settingsVolumeTotal $total · $settingsVolumeUsed $used · $settingsVolumeAvailable $available';
  }

  @override
  String get settingsHeadroomAmple => 'Plénty óf spácé······';

  @override
  String get settingsHeadroomLow => 'Spácé ís géttíng lów·······';

  @override
  String get settingsHeadroomCritical =>
      'Nót énóúgh spácé fór á néw phótó············';

  @override
  String get settingsClearCache => 'Cléár cáché····';

  @override
  String get settingsClearCacheEffect =>
      'Rémóvés dérívéd cópíés ónly. Órígínáls stáy.················';

  @override
  String settingsCacheSize(
    Object settingsCache,
    Object size,
    Object settingsClearCacheEffect,
  ) {
    return '$settingsCache · $size. $settingsClearCacheEffect';
  }

  @override
  String settingsRetentionSubtitle(
    Object settingsRetentionDaysdays,
    Object settingsRetentionEffect,
  ) {
    return '$settingsRetentionDaysdays. $settingsRetentionEffect';
  }

  @override
  String get settingsClearCacheTitle => 'Cléár thé cáché?······';

  @override
  String get settingsClearCacheMessage =>
      'Thúmbnáíls ánd úplóád cópíés wíll bé rémóvéd. Órígínál phótós stáy.························';

  @override
  String get storageCheckTitle => 'Chéck fílés····';

  @override
  String get storageCheckSubtitle =>
      'Fínd fílés wíth nó récórd ánd récórds whósé fílé ís góné. Nóthíng ís délétéd.···························';

  @override
  String get storageCheckDatabaseHeader => 'Récórds ánd référéncés········';

  @override
  String get storageCheckDatabaseClean =>
      'Évéry récórd, válúé ánd fílé référéncé ís whólé.·················';

  @override
  String storageCheckFindingRow(Object table, Object id) {
    return '$table · $id';
  }

  @override
  String storageCheckProjectHeader(Object project) {
    return 'Fílés ín ····$project';
  }

  @override
  String get storageCheckNoProject =>
      'Ópén á prójéct tó chéck íts fílés.············';

  @override
  String get storageCheckFilesClean =>
      'Évéry fílé hás íts récórd, ánd évéry récórd hás íts fílé.····················';

  @override
  String get storageCheckFilesUnavailable =>
      'Thís dévícé kééps nó prójéct fóldér, só íts fílés cán\'t bé chéckéd.························';

  @override
  String get storageCheckFilesUnavailableAction =>
      'Chéck thé fílés ón thé phóné, táblét ór cómpútér thát tóók thém.·······················';

  @override
  String get storageCheckStrayHeader => 'Fílés wíth nó récórd·······';

  @override
  String storageCheckStraySubtitle(Object size) {
    return '$size · Táp tó áttách ít tó á récórd.············';
  }

  @override
  String get storageCheckMissingHeader =>
      'Récórds whósé fílé ís góné··········';

  @override
  String get storageCheckMissingSubtitle =>
      'Táp tó márk thé fílé ás míssíng. Thé récórd stáys.··················';

  @override
  String get storageCheckFlagTitle => 'Márk thé fílé ás míssíng?·········';

  @override
  String get storageCheckFlagMessage =>
      'Thé récórd ánd íts óthér évídéncé stáy. Íts hístóry nótés thát thís fílé ís góné.·····························';

  @override
  String get storageCheckFlagConfirm => 'Márk ás míssíng······';

  @override
  String get storageCheckFlagged => 'Márkéd ás míssíng.·······';

  @override
  String get storageCheckAttachTitle => 'Áttách tó á récórd·······';

  @override
  String get storageCheckAttached => 'Fílé áttáchéd tó thé récórd.··········';

  @override
  String get storageCheckNoRecords => 'Nó récórds yét·····';

  @override
  String get storageCheckNoRecordsMessage =>
      'Cáptúré á récórd ín thís prójéct, thén áttách thé fílé tó ít.······················';

  @override
  String get settingsRetention => 'Kéép délétéd fílés·······';

  @override
  String get settingsRetentionEffect =>
      'Hów lóng á délétéd fílé cán bé réstóréd.··············';

  @override
  String settingsRetentionDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dáys··',
      one: '1 dáy··',
      zero: '0 dáys···',
    );
    return '$_temp0';
  }

  @override
  String get settingsDocuments => 'Dócúménts····';

  @override
  String get settingsAudio => 'Áúdíó··';

  @override
  String get settingsExports => 'Éxpórts···';

  @override
  String get settingsCache => 'Cáché··';

  @override
  String get settingsStorageEmptyHeadline => 'Nó prójéct fóldérs yét········';

  @override
  String get settingsStorageEmptyMessage =>
      'Spácé úséd áppéárs héré óncé á prójéct hás fílés.··················';

  @override
  String fileSize(int bytes) {
    final intl.NumberFormat bytesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bytesString = bytesNumberFormat.format(bytes);

    return '$bytesString B·';
  }

  @override
  String fileSizeKB(Object byteskround) {
    return '$byteskround KB··';
  }

  @override
  String fileSizeMB(Object byteskk) {
    return '$byteskk MB··';
  }

  @override
  String fileSizeGB(Object byteskk) {
    return '$byteskk GB··';
  }

  @override
  String settingsProjectUse(
    Object photos,
    Object settingsDocuments,
    Object documents,
    Object settingsAudio,
    Object audio,
    Object settingsExports,
    Object exports,
  ) {
    return 'Phótós ···$photos · $settingsDocuments $documents · $settingsAudio $audio · $settingsExports $exports';
  }

  @override
  String get settingsVersion => 'Vérsíón···';

  @override
  String get settingsBuild => 'Búíld··';

  @override
  String get settingsLicences => 'Lícéncés···';

  @override
  String get settingsLicencesEffect =>
      'Ópén-sóúrcé lícéncés úséd ín thís ápp.··············';

  @override
  String get settingsPlanLink => 'Dévélópmént plán······';

  @override
  String get settingsSpecLink => 'Spécífícátíón·····';

  @override
  String get settingsLinkCopied =>
      'Línk cópíéd. Pásté ít íntó á brówsér tó ópén ít.·················';

  @override
  String get settingsEmptyHeadline => 'Nó séttíngs yét······';

  @override
  String get settingsEmptyMessage =>
      'Séttíngs fór thís dévícé wíll áppéár héré.···············';

  @override
  String get settingsCaptureEmptyHeadline => 'Nó cáptúré défáúlts yét·········';

  @override
  String get settingsCaptureEmptyMessage =>
      'Cámérá, dátés ánd GPS wíll áppéár héré.··············';

  @override
  String get settingsAboutEmptyHeadline => 'Nó vérsíón yét·····';

  @override
  String get settingsAboutEmptyMessage =>
      'Thé vérsíón ánd lícéncés wíll áppéár héré.···············';

  @override
  String get appLockUnlockTitle => 'Únlóck Táptúré·····';

  @override
  String get appLockTitle => 'Ápp lóck···';

  @override
  String get appLockPin => 'PÍN··';

  @override
  String get appLockCurrentPin => 'Cúrrént PÍN····';

  @override
  String get appLockNewPin => 'Néw PÍN···';

  @override
  String get appLockConfirmPin => 'Cónfírm PÍN····';

  @override
  String get appLockSet => 'Sét PÍN···';

  @override
  String get appLockChange => 'Chángé PÍN····';

  @override
  String get appLockRemove => 'Rémóvé PÍN····';

  @override
  String get appLockUnlock => 'Únlóck···';

  @override
  String get appLockBiometrics => 'Únlóck wíth thís dévícé·········';

  @override
  String get appLockSetEffect =>
      'Réqúíréd thé néxt tímé thé ápp ópéns ór rétúrns.·················';

  @override
  String get appLockRemoveEffect =>
      'Thé néxt ópén wíll nót ásk fór á PÍN.·············';

  @override
  String get appLockRemoveConfirmTitle => 'Rémóvé thé PÍN?······';

  @override
  String get appLockCurrentPinHelper =>
      'Néédéd tó chángé ór rémóvé thé PÍN.·············';

  @override
  String get appLockRemoveNeedsPin =>
      'Éntér yóúr cúrrént PÍN, thén rémóvé ít.··············';

  @override
  String get appLockOn => 'Ápp lóck ís ón.······';

  @override
  String get appLockOff =>
      'Ápp lóck ís óff. Sét á PÍN tó réqúíré ít ón láúnch ánd résúmé.······················';

  @override
  String get appLockPinLength => 'Úsé 4 tó 8 dígíts.·······';

  @override
  String get appLockPinMismatch => 'Thé twó PÍNs dó nót mátch.··········';

  @override
  String get appLockWrongPin => 'Thát PÍN dóés nót mátch.·········';

  @override
  String get appLockRecovery =>
      'Nóbódy cán rését thís PÍN. Yóúr fílés stáy ón thís dévícé. Nóthíng héré délétés thém.······························';

  @override
  String get close => 'Clósé··';

  @override
  String get feedback => 'Féédbáck···';

  @override
  String get feedbackButtonHint =>
      'Ópéns thé féédbáck óptíóns. Drág tó móvé ít.················';

  @override
  String get feedbackGive => 'Gívé ús féédbáck······';

  @override
  String get feedbackDownload => 'Dównlóád féédbáck······';

  @override
  String get feedbackDelete => 'Délété féédbáck······';

  @override
  String get feedbackStaysOnDevice =>
      'Sávéd ón thís dévícé ónly. Nóthíng ís sént ánywhéré.···················';

  @override
  String get feedbackCategoryGeneral => 'Générál···';

  @override
  String get feedbackCategoryImprovement => 'Ímpróvémént····';

  @override
  String get feedbackCategoryError => 'Érrór··';

  @override
  String get feedbackCategorySuggestion => 'Súggéstíón····';

  @override
  String get feedbackCategoryOther => 'Óthér··';

  @override
  String get feedbackSubmitterSignedIn => 'Sígnéd-ín úsér·····';

  @override
  String get feedbackSubmitterLocal => 'Lócál ópérátór·····';

  @override
  String get feedbackSubmitterAnonymous => 'Ánónymóús····';

  @override
  String get feedbackDeviceMobile => 'Móbílé···';

  @override
  String get feedbackDeviceTablet => 'Táblét···';

  @override
  String get feedbackDeviceDesktop => 'Désktóp···';

  @override
  String get feedbackType => 'Typé óf féédbáck······';

  @override
  String get feedbackOtherType => 'Whát kínd óf féédbáck ís ít?··········';

  @override
  String get feedbackOtherRequired =>
      'Sáy whát kínd óf féédbáck ít ís···········';

  @override
  String get feedbackMessage => 'Yóúr féédbáck·····';

  @override
  String get feedbackMessageHint =>
      'Whát háppénéd, ór whát wóúld máké thís béttér?·················';

  @override
  String get feedbackMessageRequired => 'Wríté yóúr féédbáck·······';

  @override
  String get feedbackAttachScreenshot => 'Áttách scréénshót······';

  @override
  String get feedbackContinue => 'Cóntínúé féédbáck······';

  @override
  String get feedbackAddScreen => 'Scréénshót cúrrént scréén·········';

  @override
  String get feedbackIncludeUi => 'Ínclúdé féédbáck ÚÍ·······';

  @override
  String get feedbackAddWindow => 'Scréénshót éxtérnál wíndów··········';

  @override
  String get feedbackStopSharing => 'Stóp sháríng wíndów·······';

  @override
  String get feedbackSharingWindow =>
      'Sháríng á wíndów. Éách táp ádds á scréénshót.················';

  @override
  String get feedbackOtherWindow => 'Éxtérnál wíndów······';

  @override
  String get feedbackTakePhoto => 'Táké á phótó·····';

  @override
  String get feedbackChoosePhoto => 'Chóósé phótós·····';

  @override
  String get feedbackShotTipScreens =>
      'Ánóthér scréén: táp Cóntínúé látér, ópén ít, thén táp Scréénshót cúrrént scréén ín thé bár.································';

  @override
  String get feedbackShotTipApps =>
      'Ánóthér ápp: táké á scréénshót wíth yóúr dévícé, thén ádd ít wíth Chóósé phótós.····························';

  @override
  String feedbackAttachImages(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Áttách ···$countString ímágés···',
      one: 'Áttách 1 ímágé·····',
    );
    return '$_temp0';
  }

  @override
  String feedbackImageCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ímágés···',
      one: '1 ímágé···',
    );
    return '$_temp0';
  }

  @override
  String get feedbackShotPreview => 'Phótó prévíéw·····';

  @override
  String get feedbackDiscardDraft => 'Díscárd dráft·····';

  @override
  String get feedbackDiscardDraftTitle => 'Díscárd thís féédbáck?········';

  @override
  String feedbackDiscardDraftMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Thís féédbáck ánd íts ········$countString ímágés wíll bé cléáréd.·········',
      one: 'Thís féédbáck ánd íts 1 ímágé wíll bé cléáréd.·················',
      zero: 'Thís féédbáck wíll bé cléáréd.···········',
    );
    return '$_temp0';
  }

  @override
  String get feedbackContinueLater => 'Cóntínúé látér·····';

  @override
  String get feedbackDraftBarHint =>
      'Ópéns thé féédbáck yóú stártéd. Kéép typíng ór spéákíng héré.······················';

  @override
  String feedbackShotAdded(Object screen) {
    return 'Áddéd á scréénshót óf ········$screen';
  }

  @override
  String get feedbackShotsFull =>
      'Rémóvé á phótó béfóré áddíng ánóthér.·············';

  @override
  String feedbackScreenshotOf(Object screen) {
    return 'Scréénshót óf ·····$screen';
  }

  @override
  String get feedbackNoScreenshot => 'Nó ímágés yét·····';

  @override
  String get feedbackScreenshotPreview => 'Scréénshót prévíéw·······';

  @override
  String get feedbackSave => 'Sávé féédbáck·····';

  @override
  String get feedbackSaved => 'Féédbáck sávéd ón thís dévícé.···········';

  @override
  String get feedbackTypes => 'Typés··';

  @override
  String get feedbackFrom => 'Súbmíttéd fróm·····';

  @override
  String get feedbackTo => 'Súbmíttéd tó·····';

  @override
  String get feedbackRangeBackwards =>
      'Thé stárt ís áftér thé énd. Swáp thém ór cléár óné.··················';

  @override
  String get feedbackScreens => 'Scrééns···';

  @override
  String get feedbackPlatforms => 'Plátfórms····';

  @override
  String get feedbackDeviceTypes => 'Dévícé typés·····';

  @override
  String get feedbackSubmittedBy => 'Súbmíttéd by·····';

  @override
  String get feedbackScreenshot => 'Scréénshót····';

  @override
  String get feedbackScreenshotAny => 'Ány··';

  @override
  String get feedbackScreenshotWith => 'Wíth··';

  @override
  String get feedbackScreenshotWithout => 'Wíthóút···';

  @override
  String get feedbackSearch => 'Séárch thé féédbáck téxt·········';

  @override
  String get feedbackClearFilters => 'Cléár fíltérs·····';

  @override
  String feedbackMatching(int count, int matching) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat matchingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String matchingString = matchingNumberFormat.format(matching);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$matchingString óf ··$countString éntríés mátch·····',
      one: '$matchingString óf 1 éntry mátchés·······',
    );
    return '$_temp0';
  }

  @override
  String feedbackDownloadCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dównlóád ····$countString éntríés···',
      one: 'Dównlóád 1 éntry······',
      zero: 'Nóthíng tó dównlóád·······',
    );
    return '$_temp0';
  }

  @override
  String get feedbackDownloadStarted => 'Dównlóád stártéd.······';

  @override
  String feedbackDownloadedTo(Object location) {
    return 'Sávéd tó ····$location';
  }

  @override
  String get downloadsTaptureFolder => 'Dównlóáds › Táptúré·······';

  @override
  String feedbackDownloadsGoTo(Object place) {
    return 'Dównlóáds gó tó ······$place';
  }

  @override
  String get feedbackOpenFolder => 'Ópén fóldér····';

  @override
  String get feedbackSaveToFolder => 'Sávé tó á fóldér······';

  @override
  String feedbackOpenFolderFailed(Object place) {
    return 'Thé fóldér cóúld nót bé ópénéd. Lóók ín ··············$place.';
  }

  @override
  String get feedbackEmptyHeadline => 'Nó féédbáck yét······';

  @override
  String get feedbackEmptyMessage =>
      'Táp Féédbáck ón ány scréén tó wríté thé fírst éntry.···················';

  @override
  String get feedbackNoMatchHeadline => 'Nó féédbáck mátchés·······';

  @override
  String get feedbackNoMatchMessage =>
      'Chángé ór cléár thé fíltérs tó séé móré.··············';

  @override
  String feedbackSelected(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString séléctéd····',
      one: '1 séléctéd····',
      zero: 'Nóné séléctéd·····',
    );
    return '$_temp0';
  }

  @override
  String feedbackDeleteCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Délété ···$countString éntríés···',
      one: 'Délété 1 éntry·····',
      zero: 'Séléct éntríés tó délété·········',
    );
    return '$_temp0';
  }

  @override
  String feedbackDeleteTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Délété ···$countString féédbáck éntríés?·······',
      one: 'Délété 1 féédbáck éntry?·········',
    );
    return '$_temp0';
  }

  @override
  String feedbackDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Théy ánd théír scréénshóts áré rémóvéd fróm thís dévícé fór góód. Yóú cán úndó stráíght áftér.·································',
      one:
          'Ít ánd íts scréénshót áré rémóvéd fróm thís dévícé fór góód. Yóú cán úndó stráíght áftér.································',
    );
    return '$_temp0';
  }

  @override
  String feedbackDeleted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString féédbáck éntríés délétéd·········',
      one: '1 féédbáck éntry délétéd·········',
    );
    return '$_temp0';
  }

  @override
  String get feedbackShowMore => 'Shów móré····';

  @override
  String feedbackEntryFacts(Object type, Object when, Object screen) {
    return '$type · $when · $screen';
  }

  @override
  String feedbackEntryTitle(Object number, Object reference, Object message) {
    return '$number. $reference · $message';
  }

  @override
  String appLockWait(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wáít ··$countString sécónds béfóré tryíng ágáín.···········',
      one: 'Wáít 1 sécónd béfóré tryíng ágáín.············',
    );
    return '$_temp0';
  }

  @override
  String get queueTitle => 'Prócéss···';

  @override
  String get queueUnprocessed => 'Únprócésséd····';

  @override
  String get queueQueued => 'Qúéúéd···';

  @override
  String get queueFailed => 'Fáíléd···';

  @override
  String queueUsage(int requests, int cap, int images) {
    final intl.NumberFormat requestsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String requestsString = requestsNumberFormat.format(requests);
    final intl.NumberFormat capNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String capString = capNumberFormat.format(cap);
    final intl.NumberFormat imagesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String imagesString = imagesNumberFormat.format(images);

    return '$requestsString óf ··$capString ónlíné réqúésts tódáy, ·········$imagesString ímágés sént·····';
  }

  @override
  String queueUnprocessedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString únprócésséd récórds·······',
      one: '1 únprócésséd récórd·······',
      zero: 'Nó únprócésséd récórds········',
    );
    return '$_temp0';
  }

  @override
  String queueQueuedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds qúéúéd······',
      one: '1 récórd qúéúéd······',
      zero: 'Nó récórds qúéúéd······',
    );
    return '$_temp0';
  }

  @override
  String queueFailedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fáíléd jóbs·····',
      one: '1 fáíléd jób·····',
      zero: 'Nó fáíléd jóbs·····',
    );
    return '$_temp0';
  }

  @override
  String get queueGroupsTitle => 'By cóntéxt····';

  @override
  String get queueProcessAll => 'Prócéss áll····';

  @override
  String get queueProcessSelected => 'Prócéss séléctéd······';

  @override
  String get queueEmptyHeadline => 'Nóthíng wáítíng······';

  @override
  String get queueEmptyMessage =>
      'Cáptúréd récórds áppéár héré whén théy áré réády tó prócéss.·····················';

  @override
  String get queueFailedTitle => 'Fáíléd jóbs····';

  @override
  String get queueRetry => 'Rétry··';

  @override
  String queueRetryLabel(Object record) {
    return 'Rétry ···$record';
  }

  @override
  String get queueCancel => 'Cáncél···';

  @override
  String get queueCancelled =>
      'Stóppéd. Thé rést stáy ín thé qúéúé.·············';

  @override
  String queueSummary(int succeeded, int failed) {
    final intl.NumberFormat succeededNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String succeededString = succeededNumberFormat.format(succeeded);
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);

    return '$succeededString súccéédéd, ·····$failedString fáíléd···';
  }

  @override
  String queueSummaryValue(Object counts, Object detail) {
    return '$counts. $detail';
  }

  @override
  String queueProgress(int done, int failed) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);

    return 'Prócéssíng: ·····$doneString dóné, ···$failedString fáíléd···';
  }

  @override
  String queueProgressNow(Object counts, Object stage) {
    return '$counts. Nów: ···$stage';
  }

  @override
  String get egressTitle => 'Sénd fór ánálysís?·······';

  @override
  String get egressSend => 'Sénd··';

  @override
  String get egressDecline =>
      'Nóthíng wás sént. Thé récórds stáy ín thé qúéúé.·················';

  @override
  String egressBody(int images, Object size) {
    final intl.NumberFormat imagesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String imagesString = imagesNumberFormat.format(images);

    return '$imagesString cómprésséd ímágés, ábóút ··········$size. Cáptíóns, fíéld námés, ón-dévícé téxt, cóntéxt ánd prédéfínéd rów lábéls áré ínclúdéd.·······························';
  }

  @override
  String get apiKeyTitle => 'Próvídér kéy·····';

  @override
  String get apiKeyCustody =>
      'Thís kéy lívés ón thís dévícé ónly. Thé úsúál árrángémént ís fór thé órgánísátíón\'s báckénd tó hóld ít.·····································';

  @override
  String get apiKeyLabel => 'Próvídér kéy·····';

  @override
  String get apiKeySave => 'Sávé kéy···';

  @override
  String get apiKeyRemove => 'Rémóvé kéy····';

  @override
  String get apiKeyTest => 'Tést cónnéctíón······';

  @override
  String get apiKeySaved => 'Sávéd ón thís dévícé·······';

  @override
  String get apiKeyRemoveTitle => 'Rémóvé thé próvídér kéy?·········';

  @override
  String get apiKeyRemoveMessage =>
      'Thé kéy ís délétéd fróm thís dévícé, ánd ÁÍ góés báck tó yóúr órgánísátíón\'s próvídér.·······························';

  @override
  String get apiKeySuccess => 'Cónnéctíón súccéédéd.········';

  @override
  String get apiKeyAuthFailed => 'Thé kéy wás réjéctéd.········';

  @override
  String get apiKeyNetworkFailed => 'Thé nétwórk ís nót áváíláblé.···········';

  @override
  String get apiKeyTestFailed =>
      'Thé próvídér ánswéréd wíth án érrór. Try ágáín látér.···················';

  @override
  String get aiOperation => 'Ópérátíón····';

  @override
  String get aiProvider => 'Próvídér···';

  @override
  String get aiModel => 'Módél··';

  @override
  String get aiOperationLabel => 'Réád téxt····';

  @override
  String get aiOperationLabelExtractFields => 'Éxtráct fíélds·····';

  @override
  String get aiOperationLabelRefineText => 'Réfíné téxt····';

  @override
  String get aiOperationLabelTranscribeAudio => 'Tránscríbé áúdíó······';

  @override
  String get aiCustodyTheOrganisationBackendHolds =>
      'Thé órgánísátíón báckénd hólds thé próvídér kéy.·················';

  @override
  String get aiCustodyThisProviderUsesA =>
      'Thís próvídér úsés á dévícé-héld crédéntíál whén énábléd by án ádmínístrátór.···························';

  @override
  String aiCustodyThisProviderIsCurrently(Object owner) {
    return '$owner Thís próvídér ís cúrréntly únáváíláblé.··············';
  }

  @override
  String get aiSelectionFallback =>
      'Thé sávéd chóícé ís únáváíláblé. Thé órgánísátíón báckénd ís séléctéd fór nów.····························';

  @override
  String get aiProviderUnavailable =>
      'Thís próvídér ís nót áváíláblé. Prócéssíng wíll rémáín qúéúéd.······················';

  @override
  String get aiSelectionInvalid =>
      'Chóósé á próvídér ánd módél thát súppórt thís ópérátíón.····················';

  @override
  String get templateChoiceTitle => 'Whát ís thís?·····';

  @override
  String get templateChoicePin =>
      'Úsé thís témpláté fór thé rést óf thís lócátíón·················';

  @override
  String get templateChoiceEmptyHeadline => 'Nó témplátés·····';

  @override
  String get templateChoiceEmptyMessage =>
      'Ádd á témpláté béfóré chóósíng óné.·············';

  @override
  String get templateChoiceOther => 'Sóméthíng élsé·····';

  @override
  String get templateChoiceSkipped =>
      'Nó témpláté chósén. Thé récórd stáys ín thé qúéúé.··················';

  @override
  String get templateChoiceApplyFailed =>
      'Thát témpláté cóúld nót bé ápplíéd.·············';

  @override
  String get templateChoiceApplyRecovery =>
      'Prócéss thé récórd ágáín ánd chóósé óncé móré.·················';

  @override
  String get templateChoiceWaiting =>
      'Wáítíng fór sóméóné tó chóósé íts témpláté.················';

  @override
  String get processReadOnDevice => 'Réád ón thís dévícé·······';

  @override
  String get processPreparing => 'Prépáríng ímágés······';

  @override
  String get processReading => 'Réádíng téxt ón dévícé········';

  @override
  String get processDetecting => 'Ídéntífyíng témpláté·······';

  @override
  String get processExtracting => 'Éxtráctíng fíélds······';

  @override
  String get processChecking => 'Chéckíng válúés······';

  @override
  String get processingNotificationTitle => 'Prócéssíng fíníshéd·······';

  @override
  String processingNotificationBody(int succeeded, int failed) {
    final intl.NumberFormat succeededNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String succeededString = succeededNumberFormat.format(succeeded);
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);

    return '$succeededString súccéédéd, ·····$failedString fáíléd···';
  }

  @override
  String get documentPickFailed => 'Thát fílé cóúld nót bé ópénéd.···········';

  @override
  String documentTooLarge(Object fileSizebytes, Object fileSizeceiling) {
    return 'Thát fílé ís ·····$fileSizebytes; thís dévícé ópéns fílés úp tó ············$fileSizeceiling.';
  }

  @override
  String get documentTooLargeRecovery =>
      'Ópén ít ín thé Táptúré ápp ón á phóné ór cómpútér ínstéád.·····················';

  @override
  String get storedFileMissing =>
      'Thát éxpórt ís nó lóngér ón thís dévícé.··············';

  @override
  String get packageProjectMissing =>
      'Thát prójéct ís nó lóngér ón thís dévícé.···············';

  @override
  String packageTooLarge(Object fileSizebytes, Object fileSizeceiling) {
    return 'Thís prójéct páckágé wóúld bé ···········$fileSizebytes; thís dévícé hándlés páckágés úp tó ·············$fileSizeceiling.';
  }

  @override
  String get packageTooLargeRecovery =>
      'Éxpórt fróm thé Táptúré ápp ón á phóné ór cómpútér, whích hándlés lárgér páckágés.·····························';

  @override
  String get packageWriteFailed =>
      'Thé prójéct páckágé cóúld nót bé wríttén.···············';

  @override
  String get packageRejected =>
      'Thís páckágé ís lárgér thán thís dévícé cán ópén.··················';

  @override
  String get packageRejectedThisFileIsNot =>
      'Thís fílé ís nót á Táptúré prójéct páckágé.················';

  @override
  String get packageRejectedThisPackageHoldsA =>
      'Thís páckágé hólds á fílé thát wóúld lánd óútsídé íts prójéct.······················';

  @override
  String get packageRejectedThisPackageIsMissing =>
      'Thís páckágé ís míssíng á fílé ít lísts.··············';

  @override
  String get packageRejectedPartOfThisPackage =>
      'Párt óf thís páckágé cóúld nót bé réád.··············';

  @override
  String get packageRejectedThisPackageWasMade =>
      'Thís páckágé wás mádé by á néwér vérsíón óf Táptúré.···················';

  @override
  String get packageRejectedThisPackageWasChanged =>
      'Thís páckágé wás chángéd áftér ít wás mádé: á fílé dóés nót mátch íts chécksúm.····························';

  @override
  String get packageRejectedThisPackageCouldNot =>
      'Thís páckágé cóúld nót bé ópénéd.············';

  @override
  String get packageRejectedRecovery =>
      'Nóthíng wás ímpórtéd. Éxpórt thé prójéct ágáín ón thé óthér dévícé, ór úpdáté Táptúré fór á néwér páckágé.······································';

  @override
  String get captureGuideTitle => 'Whát tó cáptúré······';

  @override
  String get captureGuidePhotos => 'Phótós shóúld shów·······';

  @override
  String get captureGuideCaption => 'Sáy ór typé ín thé cáptíón··········';

  @override
  String get captureGuideClose => 'Hídé thé cáptíón gúídé········';

  @override
  String get importChecking => 'Chéckíng thé páckágé…········';

  @override
  String get importSheetTitle => 'Ímpórt á prójéct······';

  @override
  String importFrom(Object when, Object deviceisEmptyanother) {
    return 'Éxpórtéd ····$when ón ··$deviceisEmptyanother';
  }

  @override
  String importHolds(
    Object recordsCountrecords,
    Object photosCountphotos,
    Object fileSizebytes,
  ) {
    return '$recordsCountrecords · $photosCountphotos · $fileSizebytes';
  }

  @override
  String photosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString phótós···',
      one: '1 phótó···',
      zero: 'Nó phótós····',
    );
    return '$_temp0';
  }

  @override
  String get importAsNewProject => 'Ímpórt ás á néw prójéct·········';

  @override
  String get importMergeInto => 'Mérgé íntó á prójéct…········';

  @override
  String get importCopying => 'Ímpórtíng thé prójéct…········';

  @override
  String importDone(Object recordsCountrecords) {
    return 'Prójéct ímpórtéd: ·······$recordsCountrecords';
  }

  @override
  String get importProjectDeletedHere =>
      'Thís prójéct wás délétéd ón thís dévícé. Á mérgé névér bríngs báck whát wás délétéd.······························';

  @override
  String get importProjectDeletedHereRecovery =>
      'Réstóré thé prójéct fróm thé récyclé bín, ór ímpórt ón ánóthér dévícé.·························';

  @override
  String get importProjectAlreadyHere =>
      'Thís prójéct ís álréády ón thís dévícé.··············';

  @override
  String get importProjectAlreadyHereRecovery =>
      'Mérgé thé páckágé íntó ít ínstéád.············';

  @override
  String get importNoRoom =>
      'Théré ís nót énóúgh fréé spácé ón thís dévícé fór thís páckágé.·······················';

  @override
  String get importNoRoomRecovery =>
      'Fréé sómé spácé, thén ímpórt ágáín.·············';

  @override
  String get importFileChanged =>
      'Á fílé ín thís páckágé díd nót cópy córréctly.·················';

  @override
  String get importFailedRecovery =>
      'Nóthíng wás chángéd. Try ágáín, ór éxpórt thé páckágé ágáín.·····················';

  @override
  String get mergePackage => 'Mérgé á páckágé······';

  @override
  String get mergeTargetTitle => 'Mérgé íntó whích prójéct?·········';

  @override
  String get mergeTargetNone =>
      'Nó prójéct ón thís dévícé úsés thé témplátés thís páckágé nééds.·······················';

  @override
  String get compatibilityStatus => 'Cómpátíblé····';

  @override
  String get compatibilityStatusCompatibleWithDifferences =>
      'Cómpátíblé, wíth dífféréncés··········';

  @override
  String get compatibilityStatusNotCompatible => 'Nót cómpátíblé·····';

  @override
  String get compatibilityIssue => 'Nó mátchíng témpláté héré·········';

  @override
  String compatibilityIssueHoldsValuesButIs(Object field) {
    return '$field hólds válúés bút ís nót ín thé témpláté héré················';
  }

  @override
  String compatibilityIssueHereCannotHoldThe(Object field) {
    return '$field héré cánnót hóld thé íncómíng válúés·············';
  }

  @override
  String get compatibilityIssueAnotherVersionOfThe =>
      'Ánóthér vérsíón óf thé témpláté···········';

  @override
  String compatibilityIssueOnlyHere(Object field) {
    return 'Ónly héré: ····$field';
  }

  @override
  String compatibilityIssueIsRequiredOnOne(Object field) {
    return '$field ís réqúíréd ón óné sídé ónly···········';
  }

  @override
  String compatibilityIssueHasAnotherLabelHere(Object field) {
    return '$field hás ánóthér lábél héré·········';
  }

  @override
  String compatibilityIssueOffersOtherChoicesHere(Object field) {
    return '$field ófférs óthér chóícés héré··········';
  }

  @override
  String compatibilityIssueHasAnotherTypeHere(Object field) {
    return '$field hás ánóthér typé héré········';
  }

  @override
  String compatibilityIssueIsNotInThe(Object field) {
    return '$field ís nót ín thé témpláté héré, ánd hólds nó válúés··················';
  }

  @override
  String compatibilityTemplate(Object name, Object compatibilityStatusstatus) {
    return '$name: $compatibilityStatusstatus';
  }

  @override
  String get mergeCount => 'Néw récórds····';

  @override
  String get mergeCountRecordsThisMergeChanges =>
      'Récórds thís mérgé chángés··········';

  @override
  String get mergeCountNewPhotos => 'Néw phótós····';

  @override
  String get mergeCountPhotosAlreadyOnThis =>
      'Phótós álréády ón thís dévícé···········';

  @override
  String get mergeCountDeletionsToApply => 'Délétíóns tó ápply·······';

  @override
  String get mergeCountConflictsToSettle => 'Cónflícts tó séttlé·······';

  @override
  String get mergeCountPossibleDuplicates => 'Póssíblé dúplícátés·······';

  @override
  String get mergeCountValuesKeptAsOn =>
      'Válúés képt ás ón thís dévícé···········';

  @override
  String get mergeCountAlreadyInAnotherProject =>
      'Álréády ín ánóthér prójéct héré···········';

  @override
  String mergeCountValue(Object label, int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$label: $nString';
  }

  @override
  String mergeSettleConflicts(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Séttlé ···$countString cónflícts····',
      one: 'Séttlé 1 cónflíct······',
    );
    return '$_temp0';
  }

  @override
  String get mergeApply => 'Mérgé··';

  @override
  String get mergeApplying => 'Mérgíng…···';

  @override
  String get mergeDone => 'Mérgéd···';

  @override
  String get mergeNothing =>
      'Nóthíng tó mérgé: thís prójéct álréády hólds évérythíng ín thé páckágé.·························';

  @override
  String get mergeCheckDuplicates => 'Chéck fór póssíblé dúplícátés···········';

  @override
  String get mergeCheckDuplicatesHelper =>
      'Lísts íncómíng récórds thát lóók líké ónés álréády héré. Yóú décídé fór éách.···························';

  @override
  String get mergeCheckingDuplicates => 'Lóókíng fór dúplícátés…·········';

  @override
  String conflictProgress(int index, int total) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Cónflíct ····$indexString óf ··$totalString';
  }

  @override
  String get conflictKind => 'Cáptíón···';

  @override
  String get conflictKindStatus => 'Státús···';

  @override
  String get conflictKindDeletedOnTheOther =>
      'Délétéd ón thé óthér dévícé··········';

  @override
  String get conflictKindDeletedOnThisDevice =>
      'Délétéd ón thís dévícé········';

  @override
  String get conflictDeletionTheOtherDeviceDeleted =>
      'Thé óthér dévícé délétéd thís, bút ít wás chángéd héré síncé.······················';

  @override
  String get conflictDeletionThisDeviceDeletedThis =>
      'Thís dévícé délétéd thís, bút thé óthér dévícé chángéd ít síncé.·······················';

  @override
  String get conflictThisDevice => 'Thís dévícé····';

  @override
  String get conflictIncoming => 'Íncómíng···';

  @override
  String conflictWrittenBy(Object dateFormatyMMMdadd) {
    return ' · $dateFormatyMMMdadd';
  }

  @override
  String conflictWrittenByValue(Object deviceisEmptyUnknown, Object when) {
    return '$deviceisEmptyUnknown$when';
  }

  @override
  String get conflictDeleted => 'Délétéd···';

  @override
  String get conflictEmpty => 'Émpty··';

  @override
  String get conflictKeepMine => 'Kéép thís dévícé\'s·······';

  @override
  String get conflictTakeIncoming => 'Táké íncómíng·····';

  @override
  String mergeKeepAllMine(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Kéép thís dévícé\'s fór áll ··········$nString';
  }

  @override
  String mergeTakeAllIncoming(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Táké íncómíng fór áll ········$nString';
  }

  @override
  String get mergeBulkConfirm => 'thé íncómíng válúé·······';

  @override
  String get mergeBulkConfirmThisDeviceSValue => 'thís dévícé\'s válúé·······';

  @override
  String mergeBulkConfirmForConflictOtherFor(int count, Object side) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Úsé ··$side fór áll ····$countString cónflícts?····',
      one: 'Úsé ··$side fór 1 cónflíct?······',
    );
    return '$_temp0';
  }

  @override
  String get duplicateTitle => 'Póssíblé dúplícáté·······';

  @override
  String get duplicateSignal => 'Sámé ídéntíty fíélds·······';

  @override
  String get duplicateSignalSamePhoto => 'Sámé phótó····';

  @override
  String get duplicateSignalIdenticalPhoto => 'Ídéntícál phótó······';

  @override
  String get duplicateSignalNearlyTheSamePhoto =>
      'Néárly thé sámé phótó········';

  @override
  String get duplicateSignalSameChecklistRow => 'Sámé chécklíst rów·······';

  @override
  String get duplicateSignalSameNamePlaceAnd =>
      'Sámé námé, plácé ánd tímé·········';

  @override
  String get duplicateSignalSamePlaceCloseIn =>
      'Sámé plácé, clósé ín tímé, símílár cáptíón···············';

  @override
  String get duplicateKeepBoth => 'Kéép bóth····';

  @override
  String get duplicateSkipIncoming => 'Dón\'t ímpórt thís récórd·········';

  @override
  String get duplicateSkipped => 'Nót ímpórtéd·····';

  @override
  String get duplicateIncoming => 'Íncómíng récórd······';

  @override
  String get duplicateHere => 'Ón thís dévícé·····';

  @override
  String get mergeNoPackageHeadline => 'Nó páckágé ópén······';

  @override
  String get mergeNoPackageMessage =>
      'Chóósé Mérgé á páckágé fróm thé prójéct ménú tó píck óné.····················';

  @override
  String get mergeTemplatesHeading => 'Témplátés····';

  @override
  String get mergeCountsHeading => 'Whát thé mérgé dóés·······';

  @override
  String get mergeBlocked =>
      'Thís páckágé cánnót mérgé íntó thís prójéct úntíl íts témplátés mátch.·························';

  @override
  String mergeRecordUnnamed(Object short) {
    return 'Récórd …···$short';
  }

  @override
  String mergeConflictLine(Object record, Object about) {
    return '$record · $about';
  }

  @override
  String get mergeConflictChosen => 'Tákíng íncómíng······';

  @override
  String get mergeConflictChosenKeepingThisDeviceS =>
      'Kéépíng thís dévícé\'s········';

  @override
  String get mergeConflictOpen => 'Nót séttléd yét······';

  @override
  String mergeProjectKept(Object labelsjoin) {
    return 'Prójéct détáíls képt ás ón thís dévícé: ··············$labelsjoin';
  }

  @override
  String get conflictChanged => 'Képt ánd chángéd······';

  @override
  String duplicateField(Object label, Object valueisEmptyconflictEmpty) {
    return '$label: $valueisEmptyconflictEmpty';
  }

  @override
  String get recordsSearchHint => 'Séárch récórds·····';

  @override
  String get recordsUntitled => 'Úntítléd récórd······';

  @override
  String recordsUntitledRecord(Object number) {
    return 'Récórd ···$number';
  }

  @override
  String get recordsEmptyHeadline => 'Nó récórds yét·····';

  @override
  String get recordsEmptyMessage =>
      'Récórds yóú cáptúré ín thís prójéct áppéár héré.·················';

  @override
  String get recordsEmptyAction => 'Cáptúré á récórd······';

  @override
  String get recordsNoMatch => 'Nó récórds mátch.······';

  @override
  String recordsNoMatchNoRecordsMatch(Object shown) {
    return 'Nó récórds mátch \"·······$shown\".';
  }

  @override
  String get recordsClearSearch => 'Cléár séárch·····';

  @override
  String get recordsClearAll => 'Cléár séárch ánd fíltérs·········';

  @override
  String get recordsNoProjectHeadline => 'Nó prójéct ópén······';

  @override
  String get recordsNoProjectMessage =>
      'Récórds bélóng tó á prójéct. Ópén óné tó séé íts récórds.····················';

  @override
  String get recordsOpenProject => 'Ópén á prójéct·····';

  @override
  String get recordsFiltersTitle => 'Récórd fíltérs·····';

  @override
  String get recordsFilterStatus => 'Státús···';

  @override
  String get recordsFilterTemplate => 'Témpláté···';

  @override
  String get recordsFilterFrom => 'Cáptúréd fróm·····';

  @override
  String get recordsFilterTo => 'Cáptúréd úntíl·····';

  @override
  String get recordsFilterOperator => 'Cáptúréd by····';

  @override
  String get recordsFilterCondition => 'Cóndítíón····';

  @override
  String get recordsFilterFlags => 'Qúálíty···';

  @override
  String get recordsFlagHasPhotos => 'Hás phótós····';

  @override
  String get recordsFlagHasDuplicate => 'Póssíblé dúplícáté·······';

  @override
  String get recordsFlagHasConflict => 'Mérgé cónflíct·····';

  @override
  String get recordsFlagHasVariance => 'Chángéd síncé áppróvál········';

  @override
  String get recordsFlagEvidenceRemoved => 'Évídéncé rémóvéd······';

  @override
  String get recordsFlagMerged => 'Fróm ánóthér dévícé·······';

  @override
  String get recordsFiltersEmptyHeadline => 'Nóthíng tó fíltér yét········';

  @override
  String get recordsFiltersEmptyMessage =>
      'Cáptúré récórds ín thís prójéct, thén nárrów thém dówn héré.·····················';

  @override
  String get recordsTemplateUnnamed => 'Únnáméd témpláté······';

  @override
  String recordsChipTemplate(Object name) {
    return 'Témpláté: ····$name';
  }

  @override
  String recordsChipOperator(Object name) {
    return 'Cáptúréd by ·····$name';
  }

  @override
  String recordsChipCondition(Object code) {
    return 'Cóndítíón: ····$code';
  }

  @override
  String recordsChipContext(Object level, Object value) {
    return '$level: $value';
  }

  @override
  String recordsChipDates(Object formatformatfrom, Object formatformatto) {
    return '$formatformatfrom – $formatformatto';
  }

  @override
  String recordsChipDatesFrom(Object formatformatfrom) {
    return 'Fróm ··$formatformatfrom';
  }

  @override
  String recordsChipDatesUntil(Object formatformatto) {
    return 'Úntíl ···$formatformatto';
  }

  @override
  String get recordsSortTitle => 'Sórt récórds·····';

  @override
  String recordsSortLabel(Object current) {
    return 'Sórt: ···$current';
  }

  @override
  String get recordsSortNumberDescending => 'Númbér, híghést fírst········';

  @override
  String get recordsSortNumberAscending => 'Númbér, lówést fírst·······';

  @override
  String get recordsSortCapturedDescending => 'Cáptúréd, néwést fírst········';

  @override
  String get recordsSortCapturedAscending => 'Cáptúréd, óldést fírst········';

  @override
  String get recordsSortNameAscending => 'Námé, Á tó Z·····';

  @override
  String get recordsSortNameDescending => 'Námé, Z tó Á·····';

  @override
  String get recordDetailBackToList => 'Báck tó thé líst······';

  @override
  String get recordDetailDeletedNotice =>
      'Thís récórd ís ín thé récyclé bín. Réstóré ít tó chángé ít ágáín.·······················';

  @override
  String get recordDetailSendToReview => 'Sénd tó révíéw·····';

  @override
  String get recordDetailSentToReview => 'Récórd sént tó révíéw········';

  @override
  String get recordDetailUnarchive => 'Únárchívé récórd······';

  @override
  String get recordDetailUnarchived => 'Récórd báck fróm thé árchívé··········';

  @override
  String get recordDetailEditPhotos => 'Édít phótós ánd cáptíóns·········';

  @override
  String get recordDetailBusy =>
      'Á chángé tó thís récórd ís stíll béíng sávéd.················';

  @override
  String get recordDetailBusyAction =>
      'Wáít fór ít tó fínísh, thén try ágáín.··············';

  @override
  String get recordDetailNoValues =>
      'Thís récórd hás nó válúés yét.···········';

  @override
  String get recordDetailContextTitle => 'Cóntéxt···';

  @override
  String get recordDetailContextEmpty =>
      'Nó cóntéxt wás sét whén thís récórd wás cáptúréd.··················';

  @override
  String get recordDetailProvenanceTitle =>
      'Whéré thé válúés cámé fróm··········';

  @override
  String recordDetailValuesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString válúés···',
      one: '1 válúé···',
      zero: 'Nó válúés····',
    );
    return '$_temp0';
  }

  @override
  String get recordDetailVerified => 'Cónfírméd by á pérsón········';

  @override
  String get recordDetailReadBy => 'Réád by···';

  @override
  String get recordDetailDatesTitle => 'Dátés··';

  @override
  String get recordDetailCaptured => 'Cáptúréd···';

  @override
  String get recordDetailUpdated => 'Lást chángéd·····';

  @override
  String get recordDetailApproved => 'Áppróvéd···';

  @override
  String get recordDetailExported => 'Éxpórtéd···';

  @override
  String get recordDetailNotExported => 'Nót éxpórtéd yét······';

  @override
  String recordDetailWhen(Object when, Object who) {
    return '$when · $who';
  }

  @override
  String recordPhotoPosition(int position, int total) {
    final intl.NumberFormat positionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String positionString = positionNumberFormat.format(position);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Phótó ···$positionString óf ··$totalString';
  }

  @override
  String get recordSourceTyped => 'Typéd··';

  @override
  String get recordSourceOcr => 'Réád fróm phótó······';

  @override
  String get recordSourceAiPhoto => 'ÁÍ fróm phótó·····';

  @override
  String get recordSourceAiText => 'ÁÍ fróm nótés·····';

  @override
  String get recordSourceSpeech => 'Díctátéd···';

  @override
  String get recordSourceBarcode => 'Bárcódé···';

  @override
  String get recordSourceLookup => 'Lóókéd úp····';

  @override
  String get recordSourceContext => 'Fróm cóntéxt·····';

  @override
  String get recordSourceDefault => 'Fílléd ín····';

  @override
  String get recordSourceImported => 'Ímpórtéd···';

  @override
  String get recordBandHigh => 'Hígh cónfídéncé······';

  @override
  String get recordBandMedium => 'Médíúm cónfídéncé······';

  @override
  String get recordBandLow => 'Lów cónfídéncé·····';

  @override
  String recordBandScore(Object numberFormatpercentPatternformat) {
    return '$numberFormatpercentPatternformat cónfídéncé····';
  }

  @override
  String recordBandWithScore(
    Object band,
    Object numberFormatpercentPatternformat,
  ) {
    return '$band, $numberFormatpercentPatternformat';
  }

  @override
  String get recordHistoryTitle => 'Hístóry···';

  @override
  String get recordHistoryEmptyHeadline => 'Nó hístóry yét·····';

  @override
  String get recordHistoryEmptyMessage =>
      'Cáptúrés, prócéssíng rúns, édíts, áppróváls, mérgés ánd éxpórts óf thís récórd áppéár héré. Gó báck tó thé récórd tó chángé ít.·············································';

  @override
  String get recordHistoryBackToRecord => 'Báck tó thé récórd·······';

  @override
  String recordHistoryByline(Object device) {
    return 'Ón ··$device';
  }

  @override
  String recordHistoryBylineOn(Object operator, Object device) {
    return '$operator ón ··$device';
  }

  @override
  String recordHistoryBylineValue(Object time, Object who) {
    return '$time · $who';
  }

  @override
  String get recordHistoryCaptured => 'Cáptúréd···';

  @override
  String get recordHistoryCreatedByHand => 'Créátéd by hánd······';

  @override
  String recordHistoryValue(Object label) {
    return '$label chángéd···';
  }

  @override
  String recordHistoryValueValue(Object label, Object next) {
    return '$label: $next';
  }

  @override
  String recordHistoryValueCleared(Object label) {
    return '$label cléáréd···';
  }

  @override
  String recordHistoryValueValue2(Object label, Object previous, Object next) {
    return '$label: $previous → $next';
  }

  @override
  String get recordHistoryCaption => 'Cáptíón···';

  @override
  String recordHistoryStatus(Object next) {
    return 'Státús: ···$next';
  }

  @override
  String recordHistoryStatusValue(Object previous, Object next) {
    return '$previous → $next';
  }

  @override
  String get recordHistoryPhotoAdded => 'Phótó áddéd····';

  @override
  String get recordHistoryPhotoRemoved => 'Phótó rémóvéd·····';

  @override
  String get recordHistoryTemplate => 'Témpláté chángéd······';

  @override
  String recordHistoryTemplateTemplate(Object next) {
    return 'Témpláté: ····$next';
  }

  @override
  String recordHistoryTemplateTemplate2(Object previous, Object next) {
    return 'Témpláté: ····$previous → $next';
  }

  @override
  String get recordHistoryTemplateGone =>
      'Á témpláté nót ón thís dévícé···········';

  @override
  String recordHistoryProcessed(Object provider) {
    return ' by ··$provider';
  }

  @override
  String recordHistoryProcessedValue(Object model) {
    return ' ($model)';
  }

  @override
  String recordHistoryProcessedProcessed(Object by, Object using) {
    return 'Prócésséd····$by$using';
  }

  @override
  String get recordHistoryProcessingFailed => 'Prócéssíng fáíléd······';

  @override
  String recordHistoryProcessingFailedOtherAttempts(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Prócéssíng fáíléd áftér ·········$countString áttémpts····',
      one: 'Prócéssíng fáíléd áftér 1 áttémpt············',
    );
    return '$_temp0';
  }

  @override
  String get recordHistoryImported => 'Ímpórtéd fróm á páckágé·········';

  @override
  String recordHistoryImportedImportedFrom(Object package) {
    return 'Ímpórtéd fróm ·····$package';
  }

  @override
  String get recordHistoryMerged => 'Mérgéd fróm á páckágé········';

  @override
  String recordHistoryMergedMergedFrom(Object package) {
    return 'Mérgéd fróm ·····$package';
  }

  @override
  String get recordHistoryExported => 'Éxpórtéd···';

  @override
  String recordHistoryExportedExportedInExport(Object version) {
    return 'Éxpórtéd ín éxpórt ·······$version';
  }

  @override
  String recordHistoryEvidenceRemoved(Object label) {
    return '$label: évídéncé rémóvéd·······';
  }

  @override
  String recordHistoryEvidenceRestored(Object label) {
    return '$label: évídéncé réstóréd·······';
  }

  @override
  String recordHistoryRetired(Object label) {
    return '$label rétíréd···';
  }

  @override
  String recordHistoryMappedAgain(Object label) {
    return '$label máppéd ágáín·····';
  }

  @override
  String get recordHistoryRowMatched => 'Mátchéd tó á chécklíst rów··········';

  @override
  String get recordHistoryFileMissing => 'Á phótó fílé ís míssíng·········';

  @override
  String get recordHistoryOther => 'Récórd chángéd·····';

  @override
  String get recordHistoryLineTitle => 'Chángé···';

  @override
  String get recordHistoryBefore => 'Béfóré···';

  @override
  String get recordHistoryAfter => 'Áftér··';

  @override
  String get recordHistoryWhen => 'Whén··';

  @override
  String get recordHistoryOperator => 'Ópérátór···';

  @override
  String get recordHistoryDevice => 'Dévícé···';

  @override
  String get recordHistoryReason => 'Réásón···';

  @override
  String get recordHistoryNotRecorded => 'Nót récórdéd·····';

  @override
  String get recordHistoryEmptyValue => 'Émpty··';

  @override
  String get recordValuesEditTitle => 'Édít válúés····';

  @override
  String get recordValueEditTitle => 'Édít válúé····';

  @override
  String get recordEditApprovedNotice =>
      'Thís récórd ís áppróvéd. Sávíng á chángé sénds ít báck tó révíéw.·······················';

  @override
  String get recordValueRetired => 'Rétíréd···';

  @override
  String get recordRetiredValuesTitle => 'Rétíréd válúés·····';

  @override
  String get recordRetiredValuesMessage =>
      'Thís récórd\'s témpláté nó lóngér hás thésé fíélds. Théír válúés áré képt ás théy wéré ánd cán\'t bé édítéd.······································';

  @override
  String get recordValueEvidenceRemoved => 'Évídéncé rémóvéd······';

  @override
  String get recordTemplateMissingNotice =>
      'Thís récórd\'s témpláté ís nó lóngér ón thís dévícé. Íts válúés áré képt; chángé íts témpláté tó édít thém.······································';

  @override
  String get recordEditDeletedHeadline =>
      'Thís récórd ís ín thé récyclé bín············';

  @override
  String get recordEditDeletedMessage =>
      'Réstóré ít fróm thé récyclé bín, thén chángé íts válúés.····················';

  @override
  String get recordFieldMissingHeadline =>
      'Thís fíéld ís nót ón thé récórd···········';

  @override
  String get recordFieldMissingMessage =>
      'Thé récórd\'s témpláté nó lóngér hás thís fíéld. Gó báck tó thé récórd.·························';

  @override
  String get recordValueCannotEmpty =>
      'Á sávéd válúé cánnót bé émptíéd. Typé thé córréctéd válúé ínstéád.························';

  @override
  String recordValuesSaved(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString válúés sávéd·····',
      one: '1 válúé sávéd·····',
    );
    return '$_temp0';
  }

  @override
  String recordValuesSavedTheRecordIsBack(Object saved) {
    return '$saved. Thé récórd ís báck ín révíéw.···········';
  }

  @override
  String recordValuesSavedValue(Object saved) {
    return '$saved.';
  }

  @override
  String get recordPhotosProcessTitle => 'Prócéss thís récórd ágáín?··········';

  @override
  String recordPhotosProcessMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Yóú áddéd ····$countString phótós. Prócéssíng ágáín réáds thém ánd fílls fíélds thát áré stíll émpty. Válúés álréády ón thé récórd stáy ás théy áré.···········································',
      one:
          'Yóú áddéd 1 phótó. Prócéssíng ágáín réáds ít ánd fílls fíélds thát áré stíll émpty. Válúés álréády ón thé récórd stáy ás théy áré.··············································',
    );
    return '$_temp0';
  }

  @override
  String get recordPhotosProcessConfirm => 'Prócéss ágáín·····';

  @override
  String get recordPhotosProcessQueued =>
      'Récórd qúéúéd fór prócéssíng.···········';

  @override
  String get recordTemplateChangeTitle => 'Chángé témpláté······';

  @override
  String recordTemplateChangeCurrent(Object name) {
    return 'Nów ón ···$name';
  }

  @override
  String get recordTemplateChangeChoose => 'Móvé tó···';

  @override
  String get recordTemplateChangeHint =>
      'Chóósé á témpláté tó séé whát háppéns tó éách válúé béfóré ánythíng chángés.···························';

  @override
  String recordTemplateChangeMapped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString válúés cárríéd óvér·······',
      one: '1 válúé cárríéd óvér·······',
    );
    return '$_temp0';
  }

  @override
  String recordTemplateChangeRetired(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString válúés képt ás rétíréd·········',
      one: '1 válúé képt ás rétíréd·········',
    );
    return '$_temp0';
  }

  @override
  String recordTemplateChangeAdded(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fíélds stárt émpty·······',
      one: '1 fíéld stárts émpty·······',
    );
    return '$_temp0';
  }

  @override
  String recordTemplateChangeRestored(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString rétíréd válúés cómé báck·········',
      one: '1 rétíréd válúé cómés báck··········',
    );
    return '$_temp0';
  }

  @override
  String get recordTemplateChangeRetiredNotice =>
      'Rétíréd válúés stáy ón thé récórd ánd áré névér délétéd. Théy cómé báck íf thé récórd móvés tó á témpláté wíth théír fíéld.············································';

  @override
  String get recordTemplateChangeNoValues =>
      'Nó válúé chángés: thé récórd hás nó válúés fór thís témpláté tó táké óvér, ánd thé témpláté hás nó fíélds.······································';

  @override
  String get recordTemplateChangeApprovedNotice =>
      'Thís récórd ís áppróvéd. Chángíng íts témpláté sénds ít báck tó révíéw.·························';

  @override
  String get recordTemplateChangeApply => 'Chángé témpláté······';

  @override
  String get recordTemplateChanged =>
      'Témpláté chángéd. Thé récórd ís báck ín révíéw.·················';

  @override
  String get recordTemplateChangedTemplateChanged => 'Témpláté chángéd.······';

  @override
  String get recordTemplateChangeEmptyHeadline => 'Nó óthér témpláté······';

  @override
  String get recordTemplateChangeEmptyMessage =>
      'Thís prójéct hás ónly thé témpláté thís récórd úsés. Ádd ánóthér témpláté tó thé prójéct, thén móvé thé récórd tó ít.·········································';

  @override
  String get recordTemplateChangeEmptyAction => 'Ópén témplátés·····';

  @override
  String get recordTemplateChangeGoneHeadline =>
      'Thís récórd ís nó lóngér ón thís dévícé··············';

  @override
  String get recordTemplateChangeGoneMessage =>
      'Clósé thís shéét ánd píck ánóthér récórd.···············';

  @override
  String get recordTemplateChangeChooseAction =>
      'Chóósé á témpláté úndér Móvé tó, thén ápply.················';

  @override
  String get recordTemplateChangeApplying =>
      'Thís récórd ís álréády móvíng tó thát témpláté.·················';

  @override
  String get recordTemplateChangeApplyingAction =>
      'Wáít á mómént, thén chéck thé récórd.·············';

  @override
  String recordsDeleteLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Délété ···$countString récórds···',
      one: 'Délété récórd·····',
    );
    return '$_temp0';
  }

  @override
  String recordsDeleteTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Délété ···$countString récórds?····',
      one: 'Délété 1 récórd?······',
    );
    return '$_temp0';
  }

  @override
  String recordsDeleteMessage(int count, Object window) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Théy móvé tó thé récyclé bín, whéré yóú cán réstóré thém fór ······················$window. Théír phótós stáy ón thís dévícé úntíl thén.·················',
      one:
          'Ít móvés tó thé récyclé bín, whéré yóú cán réstóré ít fór ·····················$window. Íts phótós stáy ón thís dévícé úntíl thén.················',
    );
    return '$_temp0';
  }

  @override
  String get recordsDeleteConfirm => 'Délété···';

  @override
  String recordsDeleted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds délétéd······',
      one: '1 récórd délétéd······',
    );
    return '$_temp0';
  }

  @override
  String recordsNotDeleted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds cóúld nót bé délétéd···········',
      one: '1 récórd cóúld nót bé délétéd···········',
    );
    return '$_temp0';
  }

  @override
  String recordsDeletedPartly(
    Object recordsDeleteddeleted,
    Object recordsNotDeletedfailed,
  ) {
    return '$recordsDeleteddeleted. $recordsNotDeletedfailed.';
  }

  @override
  String recordsRestored(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds réstóréd······',
      one: '1 récórd réstóréd······',
    );
    return '$_temp0';
  }

  @override
  String recordsNotRestored(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds cóúld nót bé réstóréd···········',
      one: '1 récórd cóúld nót bé réstóréd···········',
    );
    return '$_temp0';
  }

  @override
  String get recycleBinTitle => 'Récyclé bín····';

  @override
  String get recycleBinSettingsSubtitle =>
      'Réstóré á délétéd récórd béfóré ít ís rémóvéd fór góód.····················';

  @override
  String recycleBinKeptFor(Object settingsRetentionDaysdays) {
    return 'Délétéd récórds stáy héré fór ···········$settingsRetentionDaysdays, thén théy áré rémóvéd fór góód.············';
  }

  @override
  String get recycleBinEmptyHeadline => 'Nóthíng ín thé récyclé bín··········';

  @override
  String recycleBinEmptyMessage(Object settingsRetentionDaysdays) {
    return 'Á récórd yóú délété wáíts héré fór ·············$settingsRetentionDaysdays. Réstóré ít fróm héré tó pút ít báck ín íts líst.··················';
  }

  @override
  String recycleBinDaysLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Délétés ín ····$countString dáys··',
      one: 'Délétés ín 1 dáy······',
      zero: 'Délétés tódáy·····',
    );
    return '$_temp0';
  }

  @override
  String get recycleBinRestore => 'Réstóré···';

  @override
  String recycleBinRestoreLabel(Object name) {
    return 'Réstóré ···$name';
  }

  @override
  String get recycleBinRestoring =>
      'Thís récórd ís álréády béíng réstóréd.··············';

  @override
  String get recycleBinRestoringAction =>
      'Wáít á mómént, thén lóók fór ít ín íts líst.················';

  @override
  String get recycleBinEmpty => 'Émpty récyclé bín······';

  @override
  String recycleBinEmptyTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rémóvé ···$countString récórds fór góód?·······',
      one: 'Rémóvé 1 récórd fór góód?·········',
    );
    return '$_temp0';
  }

  @override
  String recycleBinEmptyWarning(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Áll ··$countString récórds ín thé récyclé bín ánd théír phótós áré rémóvéd fróm thís dévícé nów. Thís cánnót bé úndóné. Récórds á mérgé stíll nééds stáy úntíl théy hávé béén sháréd.··························································',
      one:
          'Thé récórd ín thé récyclé bín ánd íts phótós áré rémóvéd fróm thís dévícé nów. Thís cánnót bé úndóné. Á récórd á mérgé stíll nééds stáys úntíl ít hás béén sháréd.·························································',
    );
    return '$_temp0';
  }

  @override
  String recycleBinEmptyTypeCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Typé ··$nString tó cónfírm····';
  }

  @override
  String get recycleBinEmptyConfirm => 'Rémóvé fór góód······';

  @override
  String get recycleBinEmptyUnavailable =>
      'Émptyíng ís nót áváíláblé ón thís dévícé. Éách récórd ís rémóvéd fór góód óncé íts dáys rún óút.··································';

  @override
  String get recycleBinEmptyUnavailableAction =>
      'Réstóré whát yóú nééd béfóré íts dáys rún óút.·················';

  @override
  String get recycleBinEmptying =>
      'Thé récyclé bín ís álréády béíng émptíéd.···············';

  @override
  String get recycleBinEmptyingAction => 'Wáít fór ít tó fínísh.········';

  @override
  String recycleBinEmptied(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds rémóvéd fór góód·········',
      one: '1 récórd rémóvéd fór góód·········',
      zero: 'Nó récórds rémóvéd·······',
    );
    return '$_temp0';
  }

  @override
  String recycleBinEmptiedOtherKeptBecauseA(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString képt bécáúsé á mérgé stíll nééds thém··············',
      one: '1 képt bécáúsé á mérgé stíll nééds ít·············',
    );
    return '$_temp0';
  }

  @override
  String recycleBinEmptiedOtherCouldNotBe(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString cóúld nót bé rémóvéd········',
      one: '1 cóúld nót bé rémóvéd········',
    );
    return '$_temp0';
  }

  @override
  String recordsSelectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString séléctéd····',
      one: '1 séléctéd····',
    );
    return '$_temp0';
  }

  @override
  String get recordsClearSelection => 'Cléár séléctíón······';

  @override
  String get recordsSelectAllShown => 'Séléct áll shówn······';

  @override
  String recordsApproveLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Áppróvé ···$countString récórds···',
      one: 'Áppróvé récórd·····',
    );
    return '$_temp0';
  }

  @override
  String recordsArchiveLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Árchívé ···$countString récórds···',
      one: 'Árchívé récórd·····',
    );
    return '$_temp0';
  }

  @override
  String recordsReprocessLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Prócéss ···$countString récórds ágáín·····',
      one: 'Prócéss récórd ágáín·······',
    );
    return '$_temp0';
  }

  @override
  String recordsExportLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Éxpórt ···$countString récórds···',
      one: 'Éxpórt récórd·····',
    );
    return '$_temp0';
  }

  @override
  String recordsArchiveTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Árchívé ···$countString récórds?····',
      one: 'Árchívé 1 récórd?······',
    );
    return '$_temp0';
  }

  @override
  String recordsArchiveMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Théy léávé thé récórds líst ánd défáúlt éxpórts, ánd kéép théír válúés ánd phótós. Fíltér by Árchívéd tó fínd thém ágáín.···········································',
      one:
          'Ít léávés thé récórds líst ánd défáúlt éxpórts, ánd kééps íts válúés ánd phótós. Fíltér by Árchívéd tó fínd ít ágáín.·········································',
    );
    return '$_temp0';
  }

  @override
  String get recordsArchiveConfirm => 'Árchívé···';

  @override
  String recordsReprocessTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Prócéss ···$countString récórds ágáín?······',
      one: 'Prócéss 1 récórd ágáín?·········',
    );
    return '$_temp0';
  }

  @override
  String recordsReprocessMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Théy gó báck tó thé prócéssíng qúéúé ánd áré réád ágáín fróm thé fírst stép, wíth thé óthér récórds wáítíng ín thís prójéct. Válúés théy álréády hávé áré képt. Áppróvéd ónés nééd révíéw ágáín.····································································',
      one:
          'Ít góés báck tó thé prócéssíng qúéúé ánd ís réád ágáín fróm thé fírst stép, wíth thé óthér récórds wáítíng ín thís prójéct. Válúés ít álréády hás áré képt. Íf ít wás áppróvéd, ít nééds révíéw ágáín.······································································',
    );
    return '$_temp0';
  }

  @override
  String get recordsReprocessConfirm => 'Prócéss ágáín·····';

  @override
  String recordsExportTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Éxpórt thé prójéct wíth thésé ···········$countString récórds?····',
      one: 'Éxpórt thé prójéct wíth thís récórd?·············',
    );
    return '$_temp0';
  }

  @override
  String recordsExportMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Án éxpórt ís óné páckágé óf thé whólé prójéct: évéry récórd ín ít, thé ·························$countString séléctéd ínclúdéd, wíth théír phótós. Yóú chóósé whéré ít góés óncé ít ís wríttén.······························',
      one:
          'Án éxpórt ís óné páckágé óf thé whólé prójéct: évéry récórd ín ít, thís óné ínclúdéd, wíth théír phótós. Yóú chóósé whéré ít góés óncé ít ís wríttén.·····················································',
    );
    return '$_temp0';
  }

  @override
  String get recordsExportConfirm => 'Ópén éxpórt····';

  @override
  String recordsApproved(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds áppróvéd······',
      one: '1 récórd áppróvéd······',
    );
    return '$_temp0';
  }

  @override
  String recordsNotApproved(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds cóúld nót bé áppróvéd···········',
      one: '1 récórd cóúld nót bé áppróvéd···········',
    );
    return '$_temp0';
  }

  @override
  String recordsArchived(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds árchívéd······',
      one: '1 récórd árchívéd······',
    );
    return '$_temp0';
  }

  @override
  String recordsNotArchived(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds cóúld nót bé árchívéd···········',
      one: '1 récórd cóúld nót bé árchívéd···········',
    );
    return '$_temp0';
  }

  @override
  String recordsRequeued(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds qúéúéd tó prócéss ágáín············',
      one: '1 récórd qúéúéd tó prócéss ágáín············',
    );
    return '$_temp0';
  }

  @override
  String recordsNotRequeued(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds cóúld nót bé qúéúéd··········',
      one: '1 récórd cóúld nót bé qúéúéd··········',
    );
    return '$_temp0';
  }

  @override
  String recordsRequeuedOffline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Théy wáít ín thé prócéssíng qúéúé; prócéss thém fróm théré óncé yóú áré ónlíné.····························',
      one:
          'Ít wáíts ín thé prócéssíng qúéúé; prócéss ít fróm théré óncé yóú áré ónlíné.···························',
    );
    return '$_temp0';
  }

  @override
  String recordsBulkOutcome(Object done, Object notDone) {
    return '$done. $notDone.';
  }

  @override
  String get recordsBulkBusy => 'Ánóthér búlk áctíón ís rúnníng.···········';

  @override
  String get recordsBulkBusyAction =>
      'Wáít fór ít tó fínísh, thén try ágáín.··············';

  @override
  String validationIssueCount(
    Object validationErrorCounterrors,
    Object validationWarningCountwarnings,
  ) {
    return '$validationErrorCounterrors, $validationWarningCountwarnings';
  }

  @override
  String validationErrorCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString érrórs···',
      one: '1 érrór···',
    );
    return '$_temp0';
  }

  @override
  String validationWarningCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString wárníngs····',
      one: '1 wárníng····',
    );
    return '$_temp0';
  }

  @override
  String get validationGoToFirstError => 'Gó tó thé fírst érrór········';

  @override
  String get validationErrorLabel => 'Érrór··';

  @override
  String get validationWarningLabel => 'Wárníng···';

  @override
  String validationRequired(Object label) {
    return '$label ís réqúíréd.·····';
  }

  @override
  String validationType(Object label) {
    return '$label ís nót á válíd válúé fór thís fíéld.·············';
  }

  @override
  String validationTooShort(Object label) {
    return '$label ís tóó shórt.·····';
  }

  @override
  String validationTooLong(Object label) {
    return '$label ís tóó lóng.·····';
  }

  @override
  String validationRange(Object label) {
    return '$label ís óútsídé thé állówéd rángé.···········';
  }

  @override
  String validationPattern(Object label) {
    return '$label dóés nót mátch thé éxpéctéd páttérn.·············';
  }

  @override
  String validationOption(Object label) {
    return '$label ís nót óné óf thé állówéd chóícés.·············';
  }

  @override
  String validationUnit(Object label) {
    return '$label ís nót ín á únít thís fíéld cán stóré.··············';
  }

  @override
  String validationIdentity(Object label) {
    return '$label ídéntífíés thé récórd ánd ís réqúíréd.··············';
  }

  @override
  String get validationEvidence =>
      'Thís récórd nééds íts évídéncé béfóré ít cán bé áppróvéd.····················';

  @override
  String get validationExpression =>
      'Thát éxpréssíón cóúld nót bé réád.············';

  @override
  String get validationExpressionAction =>
      'Úsé fíélds ón thís témpláté, cómpárísóns ánd áríthmétíc ónly.······················';

  @override
  String validationUnknownField(Object name) {
    return 'Réqúíréd whén námés \"········$name\", whích thís témpláté dóés nót hávé.·············';
  }

  @override
  String get duplicatePromptTitle => 'Thís máy bé á dúplícáté·········';

  @override
  String get duplicateOverride => 'Úpdáté thé éxístíng récórd··········';

  @override
  String get duplicateLinkBoth => 'Kéép bóth ánd línk thém·········';

  @override
  String get duplicateDiscard => 'Díscárd thé néw récórd········';

  @override
  String get duplicateMerge => 'Mérgé fíéld by fíéld·······';

  @override
  String get duplicateNoDifferenceHeadline => 'Nóthíng dífférs······';

  @override
  String get duplicateNoDifferenceMessage =>
      'Thésé récórds hóld thé sámé válúés.·············';

  @override
  String get duplicateCompareTitle => 'Cómpáré récórds······';

  @override
  String get duplicateMergeTitle => 'Mérgé fíélds·····';

  @override
  String get duplicateKeepMine => 'Kéép míné····';

  @override
  String get duplicateTakeTheirs => 'Táké théírs····';

  @override
  String get duplicateKeepBothNote => 'Kéép bóth ás á nóté·······';

  @override
  String get duplicatePromptQuestion =>
      'Whát shóúld háppén tó thésé twó récórds?··············';

  @override
  String get duplicateCompareThenUpdate =>
      'Cómpáré, thén úpdáté thé éxístíng récórd··············';

  @override
  String get duplicatePromptContinue => 'Cóntínúé···';

  @override
  String get duplicateExistingRecord => 'Éxístíng récórd······';

  @override
  String get duplicateNewRecord => 'Néw récórd····';

  @override
  String get duplicateDifferingFields => 'Fíélds thát díffér·······';

  @override
  String get duplicateBackToList => 'Báck tó dúplícátés·······';

  @override
  String duplicatePairTitle(Object existing, Object incoming) {
    return '$existing ánd ··$incoming';
  }

  @override
  String duplicatesGroup(Object signal, Object template) {
    return '$signal · $template';
  }

  @override
  String duplicateValueChange(
    Object existingisEmptyconflictEmpty,
    Object incomingisEmptyconflictEmpty,
  ) {
    return '$existingisEmptyconflictEmpty → $incomingisEmptyconflictEmpty';
  }

  @override
  String duplicateDifferenceLine(
    Object label,
    Object duplicateValueChangeexistingincoming,
  ) {
    return '$label: $duplicateValueChangeexistingincoming';
  }

  @override
  String get duplicateOverrideConfirmTitle =>
      'Úpdáté thé éxístíng récórd?··········';

  @override
  String get duplicateOverrideConfirmMessage =>
      'Thé éxístíng récórd tákés thé néw válúés ánd phótós. Thé válúés ít réplácés stáy ín íts hístóry, ánd thé néw récórd góés tó thé récyclé bín.·················································';

  @override
  String get duplicateCarryPhotos => 'Kéép thé néw récórd\'s phótós···········';

  @override
  String duplicateCarryPhotosHelp(Object photosCountn) {
    return '$photosCountn móvé tó thé éxístíng récórd.···········';
  }

  @override
  String get duplicateMergeApply => 'Mérgé récórds·····';

  @override
  String duplicateMergeKeep(Object label) {
    return 'Kéép fór ····$label';
  }

  @override
  String get duplicateMergeExisting => 'Éxístíng···';

  @override
  String get duplicateMergeNew => 'Néw··';

  @override
  String get duplicateMergeBoth => 'Bóth··';

  @override
  String get duplicateMergeChooseAll =>
      'Chóósé á válúé fór éách fíéld.···········';

  @override
  String duplicateBothValues(Object existing, Object incoming) {
    return '$existing / $incoming';
  }

  @override
  String get duplicateResolvedKeepBoth =>
      'Bóth récórds képt ánd línkéd··········';

  @override
  String get duplicateResolvedDiscard =>
      'Néw récórd móvéd tó thé récyclé bín·············';

  @override
  String get duplicateResolvedOverride => 'Éxístíng récórd úpdátéd·········';

  @override
  String get duplicateResolvedMerge => 'Récórds mérgéd·····';

  @override
  String get duplicateDiscardedReason => 'Díscárdéd ás á dúplícáté·········';

  @override
  String get duplicateOverriddenReason =>
      'Íts válúés úpdátéd án éxístíng récórd·············';

  @override
  String get duplicateMergedReason =>
      'Mérgéd íntó án éxístíng récórd···········';

  @override
  String get duplicatePairGone =>
      'Thát páír ís nó lóngér wáítíng fór á chóícé.················';

  @override
  String get duplicatePairGoneRecovery =>
      'Gó báck tó thé dúplícátés líst; ít shóws whát ís léft.···················';

  @override
  String get duplicatesScan => 'Chéck fór dúplícátés·······';

  @override
  String get duplicatesScanned => 'Nó néw dúplícáté páírs········';

  @override
  String get duplicatesScannedNewDuplicatePair => '1 néw dúplícáté páír·······';

  @override
  String duplicatesScannedNewDuplicatePairs(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString néw dúplícáté páírs·······';
  }

  @override
  String get duplicatesBulkChoose =>
      'Chóósé óné óútcómé fór thé gróúp············';

  @override
  String get duplicatesBulkDone => '1 páír résólvéd······';

  @override
  String duplicatesBulkDonePairsResolved(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString páírs résólvéd······';
  }

  @override
  String duplicateLinkedTo(Object title) {
    return 'Línkéd tó ····$title';
  }

  @override
  String duplicatePossibleOf(Object title) {
    return 'Máy dúplícáté ·····$title';
  }

  @override
  String get duplicatesTitle => 'Dúplícátés····';

  @override
  String get duplicatesEmptyHeadline => 'Nó dúplícáté páírs·······';

  @override
  String get duplicatesEmptyMessage =>
      'Páírs áppéár héré whén twó récórds lóók líké thé sámé thíng.·····················';

  @override
  String get duplicatesResolveGroup => 'Résólvé thís gróúp·······';

  @override
  String duplicatesBulkTitle(Object choice, int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$choice fór ··$nString récórds?····';
  }

  @override
  String duplicatesBulkMessage(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Thís chángés ·····$nString récórds. Thé óthér gróúps stáy ás théy áré.················';
  }

  @override
  String get conflictTypeOwn => 'Typé á dífférént válúé········';

  @override
  String get conflictUseTyped => 'Úsé thé typéd válúé·······';

  @override
  String get conflictReason => 'Why thís válúé·····';

  @override
  String get conflictEmptyHeadline => 'Nó cándídátés·····';

  @override
  String get conflictEmptyMessage =>
      'Nóthíng wás própóséd fór thís fíéld.·············';

  @override
  String conflictBlocksApproval(Object label) {
    return '$label stíll hás á cónflíct. Résólvé ít béfóré áppróvíng.··················';
  }

  @override
  String get verificationModeTitle => 'Vérífícátíón módé······';

  @override
  String get verificationModeOn =>
      'Cáptúré cónfírms thé régístér ínstéád óf stártíng á blánk récórd.·······················';

  @override
  String get verificationModeOff => 'Cáptúré stárts á néw récórd.··········';

  @override
  String get verificationStatus => 'Vérífyíng····';

  @override
  String get verificationFromRegister => 'Fróm thé régístér······';

  @override
  String get varianceTitle => 'Váríáncés····';

  @override
  String get varianceEmptyHeadline => 'Nó váríáncés·····';

  @override
  String get varianceEmptyMessage =>
      'Dífféréncés bétwéén thé régístér ánd whát wás fóúnd áppéár héré.·······················';

  @override
  String get varianceMatch => 'Mátch··';

  @override
  String get varianceChanged => 'Chángéd···';

  @override
  String get varianceMissing => 'Míssíng···';

  @override
  String varianceDetail(
    Object status,
    Object recordedisEmptyconflictEmpty,
    Object foundisEmptyconflictEmpty,
  ) {
    return '$status · $recordedisEmptyconflictEmpty → $foundisEmptyconflictEmpty';
  }

  @override
  String get varianceRegisterNotFound => 'Régístér róws nót fóúnd·········';

  @override
  String get varianceChecklistNotCaptured =>
      'Chécklíst róws nót cáptúréd··········';

  @override
  String get varianceOpenRecords => 'Ópén récórds·····';

  @override
  String get qualitySummaryTitle => 'Dátá qúálíty·····';

  @override
  String get qualityInvalid => 'Ínválíd récórds······';

  @override
  String get qualityDuplicates => 'Dúplícáté páírs······';

  @override
  String get qualityConflicts => 'Únrésólvéd cónflícts·······';

  @override
  String get qualityUnreviewed => 'Únrévíéwéd récórds·······';

  @override
  String get qualityCleanHeadline => 'Réády tó éxpórt······';

  @override
  String get qualityCleanMessage =>
      'Nóthíng héré stíll blócks á cléán éxpórt.···············';

  @override
  String get reviewTitle => 'Révíéw···';

  @override
  String get reviewNeedsAttention => 'Nééds átténtíón······';

  @override
  String get reviewConfident => 'Cónfídént····';

  @override
  String reviewConfidentGroup(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Cónfídént (····$countString)';
  }

  @override
  String get reviewApproveNext => 'Áppróvé ánd néxt······';

  @override
  String get reviewEmptyHeadline => 'Nóthíng tó révíéw······';

  @override
  String get reviewEmptyMessage =>
      'Récórds thát nééd á pérsón áppéár héré.··············';

  @override
  String get reviewUseRaw => 'Úsé cáptúréd·····';

  @override
  String get reviewUseRefined => 'Úsé réfínéd····';

  @override
  String get reviewNoSidesHeadline => 'Nó válúés yét·····';

  @override
  String get reviewNoSidesMessage =>
      'Thís fíéld hás néíthér á cáptúréd nór á réfínéd válúé.···················';

  @override
  String get reviewNotDetected => 'Nót détéctéd·····';

  @override
  String get reviewTypeIt => 'Typé ít···';

  @override
  String get reviewPhotograph => 'Phótógráph thé lábél·······';

  @override
  String get reviewNotDetectedEmpty => 'Nóthíng ís míssíng·······';

  @override
  String get reviewShowEvidence => 'Shów évídéncé·····';

  @override
  String get reviewOpenPhoto => 'Ópén phótó····';

  @override
  String get reviewEvidenceEmpty => 'Nó évídéncé línkéd·······';

  @override
  String get reviewVerify => 'Vérífy···';

  @override
  String get reviewVerifyConfident => 'Vérífy cónfídént fíélds·········';

  @override
  String reviewVerifiedBy(Object name) {
    return 'Vérífíéd by ·····$name';
  }

  @override
  String get reviewVerifyEmpty => 'Nóthíng tó vérífy······';

  @override
  String reviewPosition(int index, int total) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$indexString óf ··$totalString';
  }

  @override
  String get reviewSkip => 'Skíp··';

  @override
  String get reviewBack => 'Báck··';

  @override
  String get reviewQueueDone => 'Révíéw ís fíníshéd·······';

  @override
  String get reviewQueueDoneMessage =>
      'Évéry récórd ín thís sét hás béén séén.··············';

  @override
  String get reviewQueueEmpty => 'Nó récórds ín thís révíéw·········';

  @override
  String get reviewReanalyse => 'Ré-ánálysé····';

  @override
  String get reviewProposal => 'Própóséd···';

  @override
  String get reviewAccept => 'Áccépt···';

  @override
  String get reviewApplyAccepted => 'Ápply áccéptéd·····';

  @override
  String get reviewDeclineAll => 'Déclíné áll····';

  @override
  String get reviewOfferedNotApplied => 'Ófféréd, nót ápplíéd·······';

  @override
  String get reviewReanalyseEmpty => 'Nó néw própósáls······';

  @override
  String get reviewBlockedDuplicate =>
      'Thís récórd ís párt óf án únrésólvéd dúplícáté.·················';

  @override
  String get reviewBlockedAction =>
      'Fíx thé náméd fíéld, thén áppróvé ágáín.··············';

  @override
  String get reviewNoConfidence => 'Nó cónfídéncé·····';

  @override
  String get reviewNoConfidenceMessage =>
      'Thís válúé hás nó cónfídéncé bánd yét.··············';

  @override
  String get reviewApprovedReason => 'Áppróvéd ín révíéw.·······';

  @override
  String get reviewVerifiedReason => 'Vérífíéd ín révíéw.·······';

  @override
  String get reviewSideReason => 'Fínál sídé chósén ín révíéw.··········';

  @override
  String get reviewRecordSettled =>
      'Thís récórd ís áppróvéd ór ín thé récyclé bín.·················';

  @override
  String get reviewRecordSettledAction =>
      'Sénd ít báck tó révíéw fróm íts récórd págé, thén try ágáín.·····················';

  @override
  String get reviewRecordGone =>
      'Thát récórd ís nó lóngér ón thís dévícé.··············';

  @override
  String get reviewRecordGoneAction =>
      'Gó báck tó thé récórds líst ánd ópén ánóthér récórd.···················';

  @override
  String get reviewFinalSide => 'Fínál válúé····';

  @override
  String get reviewPreviousRecord => 'Prévíóús récórd······';

  @override
  String get reviewBackToRecords => 'Báck tó récórds······';

  @override
  String reviewVerifiedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString válúés vérífíéd······',
      one: '1 válúé vérífíéd······',
    );
    return '$_temp0';
  }

  @override
  String get reviewVerified => 'Vérífíéd···';

  @override
  String get reviewEvidenceTitle => 'Évídéncé···';

  @override
  String get reviewEvidencePhoto => 'Fróm á phótó·····';

  @override
  String get reviewEvidenceDocument => 'Fróm á dócúmént······';

  @override
  String reviewEvidenceDocumentFromADocumentPage(Object page) {
    return 'Fróm á dócúmént, págé ········$page';
  }

  @override
  String get reviewEvidenceTranscript => 'Fróm á tránscrípt······';

  @override
  String get reviewEvidenceRegion => 'Whéré thé válúé wás réád·········';

  @override
  String get reviewReanalyseQueued =>
      'Qúéúéd fór ré-ánálysís. Néw válúés áré ófféréd héré whén ít fíníshés.·························';

  @override
  String get reviewReanalysing =>
      'Ré-ánálysíng. Nóthíng chángés úntíl yóú áccépt á própósál.·····················';

  @override
  String get reviewProposalsTitle => 'Própóséd válúés······';

  @override
  String reviewProposalLine(
    Object currentisEmptyrecordFieldEmpty,
    Object proposed,
  ) {
    return 'Nów: ··$currentisEmptyrecordFieldEmpty · Própóséd: ·····$proposed';
  }

  @override
  String reviewProposalsApplied(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString própósáls ápplíéd·······',
      one: '1 própósál ápplíéd·······',
    );
    return '$_temp0';
  }

  @override
  String get meetingTitle => 'Méétíng···';

  @override
  String get meetingStart => 'Stárt méétíng·····';

  @override
  String get meetingEmptyHeadline => 'Nó méétíng yét·····';

  @override
  String get meetingEmptyMessage =>
      'Dáté, tímé, lócátíón ánd sécrétáry fíll ín fróm thís prójéct.······················';

  @override
  String get meetingDate => 'Dáté··';

  @override
  String get meetingStartTime => 'Stárt tímé····';

  @override
  String get meetingLocation => 'Lócátíón···';

  @override
  String get meetingSecretary => 'Sécrétáry····';

  @override
  String meetingStartedTitle(Object whenyear, Object month, Object day) {
    return 'Méétíng ···$whenyear-$month-$day';
  }

  @override
  String get meetingAttachments => 'Áttáchménts····';

  @override
  String get meetingAddAttachment => 'Ádd áttáchmént·····';

  @override
  String get meetingAttachmentsEmpty => 'Nó áttáchménts·····';

  @override
  String get meetingAttachmentsEmptyMessage =>
      'Ágéndás, répórts, hándóúts ánd whítébóárd phótós lánd héré.·····················';

  @override
  String get meetingOpenAttachment => 'Ópén··';

  @override
  String get meetingAgenda => 'Ágéndá···';

  @override
  String get meetingAddAgenda => 'Ádd ágéndá ítém······';

  @override
  String get meetingAgendaTitle => 'Ágéndá ítém····';

  @override
  String get meetingDiscussion => 'Díscússíón····';

  @override
  String get meetingMoveDown => 'Móvé dówn····';

  @override
  String get meetingRemove => 'Rémóvé···';

  @override
  String get meetingRemoveTitle => 'Rémóvé thís?·····';

  @override
  String get meetingRemoveMessage => 'Thís léávés thé méétíng.·········';

  @override
  String get meetingRemoveConfirm => 'Rémóvé···';

  @override
  String get meetingAgendaEmpty => 'Nó ágéndá yét·····';

  @override
  String get meetingAgendaEmptyMessage =>
      'Ádd thé ítéms yóú wíll díscúss, ín thé órdér yóú wánt thém.·····················';

  @override
  String get meetingAttendees => 'Átténdéés····';

  @override
  String get meetingAddAttendee => 'Ádd átténdéé·····';

  @override
  String get meetingAttendeeName => 'Námé··';

  @override
  String get meetingAttendeeRole => 'Títlé··';

  @override
  String get meetingOrganisation => 'Órgánísátíón·····';

  @override
  String get meetingContact => 'Cóntáct···';

  @override
  String get meetingPresent => 'Présént···';

  @override
  String get meetingApology => 'Ápólógy···';

  @override
  String meetingAttendanceCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString présént···',
      one: '1 présént····',
    );
    return '$_temp0';
  }

  @override
  String get meetingAcceptStaff => 'Línk stáff····';

  @override
  String get meetingAttendeesEmpty => 'Nó átténdéés yét······';

  @override
  String get meetingAttendeesEmptyMessage =>
      'Ádd whó ís présént, ánd récórd ápólógíés sépárátély.···················';

  @override
  String get meetingAttendanceSheet => 'Átténdáncé shéét······';

  @override
  String get meetingPhotographSheet => 'Phótógráph thé shéét·······';

  @override
  String get meetingAcceptRows => 'Ádd thésé átténdéés·······';

  @override
  String get meetingSheetKept =>
      'Thé phótó stáys áttáchéd. Typé thé námés íf thé réádíng ís wróng.·······················';

  @override
  String get meetingSheetEmpty => 'Nó átténdáncé shéét·······';

  @override
  String get meetingSheetEmptyMessage =>
      'Phótógráph thé sígnéd shéét, thén chéck éách námé béfóré áddíng ít.························';

  @override
  String get meetingSignature => 'Sígnátúré····';

  @override
  String get meetingRecording => 'Récórdíng····';

  @override
  String get meetingRecord => 'Récórd···';

  @override
  String get meetingStop => 'Stóp··';

  @override
  String meetingElapsed(Object clock) {
    return 'Élápséd ···$clock';
  }

  @override
  String meetingRemaining(Object label) {
    return '$label fréé··';
  }

  @override
  String get meetingInterrupted => 'Récórdíng íntérrúptéd········';

  @override
  String get meetingRecordingEmpty => 'Nó récórdíng·····';

  @override
  String get meetingRecordingEmptyMessage =>
      'Á récórdíng stáys ón thé méétíng, ínclúdíng óné thát wás íntérrúptéd.·························';

  @override
  String get meetingDecisions => 'Décísíóns····';

  @override
  String get meetingAddDecision => 'Ádd décísíón·····';

  @override
  String get meetingDecisionText => 'Décísíón···';

  @override
  String get meetingSource => 'Fróm thé nótés·····';

  @override
  String get meetingDecisionsEmpty => 'Nó décísíóns yét······';

  @override
  String get meetingDecisionsEmptyMessage =>
      'Décísíóns fróm thé mínútés ór typéd héré áré lístéd tógéthér.······················';

  @override
  String get meetingActions => 'Áctíóns···';

  @override
  String get meetingAddAction => 'Ádd áctíón····';

  @override
  String get meetingActionText => 'Áctíón···';

  @override
  String get meetingOwner => 'Ównér··';

  @override
  String get meetingDue => 'Dúé dáté···';

  @override
  String get meetingOwnerAttendee => 'Ównér fróm átténdéés·······';

  @override
  String get meetingOwnerStaff => 'Ównér fróm stáff······';

  @override
  String get meetingStatus => 'Státús···';

  @override
  String get meetingActionsEmpty => 'Nó áctíóns yét·····';

  @override
  String get meetingActionsEmptyMessage =>
      'Áctíóns kéép án ównér, á dúé dáté ánd á státús.·················';

  @override
  String get meetingNotes => 'Ráw nótés····';

  @override
  String get meetingMinutes => 'Réfínéd mínútés······';

  @override
  String get meetingTranscript => 'Tránscrípt····';

  @override
  String meetingActionBlocked(Object action) {
    return '$action nééds án ównér ánd á dúé dáté béfóré ít cán bé áppróvéd.····················';
  }

  @override
  String get meetingApprove => 'Áppróvé méétíng······';

  @override
  String get meetingReviewTitle => 'Révíéw méétíng·····';

  @override
  String get meetingReviewEmpty => 'Nó méétíng tó révíéw·······';

  @override
  String get meetingReviewEmptyMessage =>
      'Ópén á méétíng tó séé átténdáncé, décísíóns ánd áctíóns.····················';

  @override
  String get meetingApprovedReason => 'Áppróvéd ín révíéw.·······';

  @override
  String get meetingStartEntry => 'Stárt á méétíng······';

  @override
  String get meetingOpen => 'Ópén méétíng·····';

  @override
  String get meetingTemplateName => 'Méétíng nótés cáptúré········';

  @override
  String get meetingNotSet => 'Nót sét···';

  @override
  String get meetingNoProject => 'Thís prójéct ís nó lóngér héré···········';

  @override
  String get meetingNoProjectMessage =>
      'Ópén á prójéct, thén stárt thé méétíng fróm ít.·················';

  @override
  String get meetingBackToProjects => 'Báck tó prójécts······';

  @override
  String get meetingSummary => 'Súmmáry···';

  @override
  String meetingDecisionsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString décísíóns····',
      one: '1 décísíón····',
      zero: 'Nó décísíóns·····',
    );
    return '$_temp0';
  }

  @override
  String meetingActionsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString áctíóns···',
      one: '1 áctíón···',
      zero: 'Nó áctíóns····',
    );
    return '$_temp0';
  }

  @override
  String get meetingNotesAndMinutes => 'Nótés ánd mínútés······';

  @override
  String get meetingRefine => 'Réfíné mínútés·····';

  @override
  String get meetingRefineNeedsAgenda =>
      'Ádd thé ágéndá fírst, só éách póínt géts íts ówn súmmáry.····················';

  @override
  String meetingUnsupported(Object namesjoin) {
    return 'Nót ín thé nótés ór tránscrípt: ············$namesjoin. Chéck thésé béfóré áppróvíng.···········';
  }

  @override
  String meetingMinutesLine(Object title, Object summary) {
    return '$title: $summary';
  }

  @override
  String meetingTranscriptVersion(int version) {
    final intl.NumberFormat versionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String versionString = versionNumberFormat.format(version);

    return 'Tránscrípt, rún ······$versionString';
  }

  @override
  String get meetingTranscriptCloudVersion => 'Ónlíné tránscríptíón·······';

  @override
  String meetingTranscriptGaps(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString párts cóúld nót bé tránscríbéd···········',
      one: '1 párt cóúld nót bé tránscríbéd···········',
    );
    return '$_temp0';
  }

  @override
  String get meetingTranscribe => 'Tránscríbé····';

  @override
  String meetingTranscribing(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Tránscríbíng párt ·······$doneString óf ··$totalString';
  }

  @override
  String get meetingTranscribeUnavailable =>
      'Tránscríptíón ís nót áváíláblé ríght nów. Thé récórdíng stáys ón thé méétíng.···························';

  @override
  String get meetingPlay => 'Pláy··';

  @override
  String get meetingInterruptedKept =>
      'Récórdíng íntérrúptéd. Whát wás récórdéd ís képt ón thé méétíng.·······················';

  @override
  String get meetingPhotographHandout => 'Phótógráph á hándóút·······';

  @override
  String get meetingDocument => 'Dócúmént···';

  @override
  String get meetingPhoto => 'Phótó··';

  @override
  String meetingFileDetail(Object kind, Object fileSizebytes) {
    return '$kind · $fileSizebytes';
  }

  @override
  String meetingRecordingDetail(
    Object minutes,
    Object seconds,
    Object fileSizebytes,
  ) {
    return '$minutes:$seconds · $fileSizebytes';
  }

  @override
  String get meetingCheckReading =>
      'Chéck thís: thé shéét wás hárd tó réád héré.················';

  @override
  String get meetingSigned => 'Sígnéd ón thé shéét·······';

  @override
  String get meetingAttendance => 'Átténdáncé····';

  @override
  String meetingStaffSuggestion(Object name, Object score100round) {
    return 'Stáff líst: ·····$name ($score100round% mátch)···';
  }

  @override
  String meetingStaffLinked(Object name) {
    return 'Línkéd tó stáff: ······$name';
  }

  @override
  String get meetingUnlinkStaff => 'Únlínk···';

  @override
  String meetingOwnerOption(Object name) {
    return '$name · Stáff···';
  }

  @override
  String meetingOwnerOptionAttendee(Object name) {
    return '$name · Átténdéé····';
  }

  @override
  String get meetingStatusOpen => 'Ópén··';

  @override
  String get meetingStatusInProgress => 'Ín prógréss····';

  @override
  String get meetingStatusDone => 'Dóné··';

  @override
  String meetingSourceLine(Object meetingSource, Object source) {
    return '$meetingSource: $source';
  }

  @override
  String meetingDrag(Object titletrimisEmpty) {
    return 'Drág ··$titletrimisEmpty tó réórdér····';
  }

  @override
  String get meetingMoveUp => 'Móvé úp···';

  @override
  String get exportTitle => 'Éxpórt···';

  @override
  String get exportRun => 'Éxpórt···';

  @override
  String get exportScope => 'Whát tó ínclúdé······';

  @override
  String get exportScopeApproved => 'Áppróvéd ónly·····';

  @override
  String get exportScopeAll => 'Áll récórds····';

  @override
  String get exportScopeContext => 'Cúrrént cóntéxt······';

  @override
  String get exportScopeDates => 'Dáté rángé····';

  @override
  String get exportScopeFilter => 'Cúrrént fíltér·····';

  @override
  String exportCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString récórds···';
  }

  @override
  String get exportOptions => 'Cólúmns···';

  @override
  String get exportRaw => 'Ráw cólúmns····';

  @override
  String get exportRefined => 'Réfínéd cólúmns······';

  @override
  String get exportConfidence => 'Cónfídéncé····';

  @override
  String get exportEvidence => 'Évídéncé···';

  @override
  String get exportAdvanced => 'Ádváncéd···';

  @override
  String get exportPhotoMode => 'Phótó référéncé······';

  @override
  String get exportDelimiter => 'Délímítér····';

  @override
  String get exportEmptyHeadline => 'Nóthíng tó éxpórt······';

  @override
  String get exportEmptyMessage => 'Thís scópé hás nó récórds yét.···········';

  @override
  String get exportStageRecords => 'Récórds···';

  @override
  String get exportStagePhotos => 'Phótós···';

  @override
  String get exportStageReports => 'Répórts···';

  @override
  String get exportStageArchive => 'Árchívé···';

  @override
  String get exportCancel => 'Cáncél···';

  @override
  String get exportHistoryTitle => 'Éxpórt hístóry·····';

  @override
  String get exportHistoryEmpty => 'Nó éxpórts yét·····';

  @override
  String get exportHistoryEmptyMessage =>
      'Á fíníshéd éxpórt ís képt héré, wíth whó mádé ít ánd whát ít héld.························';

  @override
  String get exportShare => 'Sháré··';

  @override
  String get exportMissing =>
      'Thát fílé ís nó lóngér ón thís dévícé.··············';

  @override
  String get exportRerun => 'Rún thís éxpórt ágáín········';

  @override
  String get exportFixNow => 'Fíx nów···';

  @override
  String get exportExclude => 'Léávé thém óút·····';

  @override
  String get exportAnyway => 'Éxpórt ánywáy·····';

  @override
  String get exportIncompleteStamp => 'Márkéd íncómplété······';

  @override
  String get exportEmptyRecovery => 'Chóósé á scópé wíth récórds.··········';

  @override
  String get exportNoFormat => 'Chóósé án óútpút fórmát.·········';

  @override
  String get exportReplayMissing =>
      'Thís éxpórt ís nó lóngér áváíláblé.·············';

  @override
  String get exportOutput => 'Óútpút···';

  @override
  String get exportOutputFiles => 'Répórts ánd dátá fílés········';

  @override
  String get exportFormats => 'Fílés··';

  @override
  String get exportFormatXlsx => 'Spréádshéét (.xlsx)·······';

  @override
  String get exportFormatCsv => 'CSV··';

  @override
  String get exportFormatJson => 'JSÓN··';

  @override
  String get exportFormatPdf => 'PDF répórts····';

  @override
  String get exportScopeFrom => 'Fróm··';

  @override
  String get exportScopeTo => 'Tó·';

  @override
  String get exportDictionary => 'Dátá díctíónáry······';

  @override
  String get exportPhotoFilename => 'Fílé námé····';

  @override
  String get exportPhotoRelative => 'Páth ín thé páckágé·······';

  @override
  String get exportPhotoEmbed => 'Émbéddéd ímágé·····';

  @override
  String get exportPdfPhotos => 'Répórt phótós·····';

  @override
  String get exportPdfThumbnails => 'Thúmbnáíls····';

  @override
  String get exportPdfFull => 'Fúll sízé····';

  @override
  String get exportDelimiterComma => 'Cómmá··';

  @override
  String get exportDelimiterSemicolon => 'Sémícólón····';

  @override
  String get exportDelimiterTab => 'Táb··';

  @override
  String exportGateTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString récórds nééd átténtíón·········',
      one: '1 récórd nééds átténtíón·········',
    );
    return '$_temp0';
  }

  @override
  String get exportFixNowHint =>
      'Ópén thé récórds thát nééd átténtíón. Nóthíng ís éxpórtéd.·····················';

  @override
  String exportExcludeHint(Object recordsCountntoLowerCase) {
    return 'Éxpórt thé óthér ······$recordsCountntoLowerCase.';
  }

  @override
  String get exportAnywayHint =>
      'Évéry fílé sáys ít ís íncómplété.············';

  @override
  String pdfPageOf(int page, int pages) {
    final intl.NumberFormat pageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String pageString = pageNumberFormat.format(page);
    final intl.NumberFormat pagesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pagesString = pagesNumberFormat.format(pages);

    return '$pageString óf ··$pagesString';
  }

  @override
  String get pdfMissingPhoto => 'Míssíng phótó·····';

  @override
  String get pdfRecordReport => 'Récórd répórt·····';

  @override
  String get pdfCaptured => 'Cáptúréd···';

  @override
  String pdfRaw(Object label) {
    return '$label (ráw)···';
  }

  @override
  String pdfRefined(Object label) {
    return '$label (réfínéd)····';
  }

  @override
  String get pdfInspectionReport => 'Ínspéctíón répórt······';

  @override
  String get pdfNotFound => 'Nót fóúnd····';

  @override
  String pdfChecklistRows(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString chécklíst róws······',
      one: '1 chécklíst rów······',
    );
    return '$_temp0';
  }

  @override
  String pdfNotFoundCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString nót fóúnd····';
  }

  @override
  String pdfCompliance(int compliant, int total) {
    final intl.NumberFormat compliantNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String compliantString = compliantNumberFormat.format(compliant);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Cómplíánt: ····$compliantString óf ··$totalString';
  }

  @override
  String get pdfSummaryReport => 'Prójéct súmmáry······';

  @override
  String get pdfByContext => 'By cóntéxt····';

  @override
  String get pdfByTemplate => 'By témpláté····';

  @override
  String get pdfByCondition => 'By cóndítíón·····';

  @override
  String get pdfByStatus => 'By státús····';

  @override
  String get pdfNoContext => 'Nó cóntéxt····';

  @override
  String get pdfNoCondition => 'Nót récórdéd·····';

  @override
  String get pdfUnprocessed => 'Únprócésséd····';

  @override
  String get pdfNeedsReview => 'Nééds révíéw·····';

  @override
  String get pdfApproved => 'Áppróvéd···';

  @override
  String get pdfVarianceReport => 'Váríáncé répórt······';

  @override
  String get pdfMatched => 'Mátchéd···';

  @override
  String get pdfNotInRegister => 'Nót ín régístér······';

  @override
  String get pdfMinutesReport => 'Méétíng mínútés······';

  @override
  String get pdfTranscriptReport => 'Tránscrípts····';

  @override
  String pdfTranscriptHeard(Object title) {
    return '$title (ás héárd)····';
  }

  @override
  String pdfTranscriptEdited(Object title) {
    return '$title (édítéd)····';
  }

  @override
  String get pdfDue => 'Dúé··';

  @override
  String get pdfActionStatus => 'Ín prógréss····';

  @override
  String get pdfActionStatusDone => 'Dóné··';

  @override
  String get pdfActionStatusOpen => 'Ópén··';

  @override
  String pdfVarianceChanged(Object field, Object recorded, Object found) {
    return '$field: $recorded récórdéd, ····$found fóúnd···';
  }

  @override
  String pdfVarianceEmpty(Object field, Object recorded) {
    return '$field: $recorded récórdéd, nót fóúnd·······';
  }

  @override
  String get pdfPhotoAppendix => 'Phótó áppéndíx·····';

  @override
  String pdfPhotoReference(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Séé ··$countString phótós ín thé phótó áppéndíx.···········',
      one: 'Séé 1 phótó ín thé phótó áppéndíx.············',
    );
    return '$_temp0';
  }

  @override
  String pdfExportedAt(Object when) {
    return 'Éxpórtéd ····$when';
  }

  @override
  String pdfExportedBy(Object operator) {
    return 'Éxpórtéd by ·····$operator';
  }

  @override
  String pdfScope(Object scope) {
    return 'Récórds: ····$scope';
  }

  @override
  String get conflictTypeValue => 'Typé á válúé·····';

  @override
  String get conflictDecideLater => 'Décídé látér·····';

  @override
  String get conflictCaptionLabel => 'Cáptíón···';

  @override
  String get mergeConflictTyped => 'Úsé thé éntéréd válúé········';

  @override
  String get bundlePassword => 'Búndlé pásswórd······';

  @override
  String get bundlePasswordRequired => 'Éntér thé búndlé pásswórd.··········';

  @override
  String get bundlePasswordOptional =>
      'Sét á búndlé pásswórd (óptíónál)············';

  @override
  String get bundlePasswordSet => 'Búndlé pásswórd sét·······';

  @override
  String get bundleScope => 'Whát tó ínclúdé······';

  @override
  String get bundleScopeFull => 'Fúll prójéct·····';

  @override
  String get bundleScopeDates => 'Dáté rángé····';

  @override
  String get bundleScopeContext => 'Cúrrént cóntéxt······';

  @override
  String get bundleScopeApproved => 'Áppróvéd ónly·····';

  @override
  String get bundleScopeData => 'Dátá wíthóút phótós·······';

  @override
  String bundleSize(Object label) {
    return 'Ábóút ···$label';
  }

  @override
  String get bundleShare => 'Sháré búndlé·····';

  @override
  String get bundleOpen => 'Ópén búndlé····';

  @override
  String get mergeHistoryTitle => 'Mérgé hístóry·····';

  @override
  String get mergeHistoryEmpty => 'Nó mérgés yét·····';

  @override
  String get mergeHistoryEmptyMessage =>
      'Á mérgé ís képt héré wíth íts sóúrcé, cóúnts ánd hów lóng úndó lásts.·························';

  @override
  String mergeUndoUntil(Object when) {
    return 'Úndó úntíl ····$when';
  }

  @override
  String mergeHistoryFacts(
    Object name,
    Object id,
    Object dateFormatyMMMdadd,
    Object switchstatusapplied,
  ) {
    return '$name · $id · $dateFormatyMMMdadd · $switchstatusapplied';
  }

  @override
  String mergeHistoryCount(Object switchkeyrecords, int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$switchkeyrecords: $nString';
  }

  @override
  String mergeHistoryResolution(Object switchchoicemine, int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$switchchoicemine: $nString';
  }

  @override
  String get mergeUndoChanged => 'Thís mérgé hás látér chángés.···········';

  @override
  String get mergeUndoChangedRecovery =>
      'Kéép thé látér chángés, ór úndó thé néwér mérgé fírst.···················';

  @override
  String get mergeUndoUnavailable =>
      'Thís mérgé cán nó lóngér bé úndóné.·············';

  @override
  String get mergeUndoDone => 'Mérgé úndóné·····';

  @override
  String get mergeUndoConfirm =>
      'Réstóré thé válúés fróm béfóré thís mérgé. Íncómíng évídéncé stáys ín thé récyclé áréá.·······························';

  @override
  String get importTitle => 'Ímpórt···';

  @override
  String get importEmptyHeadline => 'Nó fílé yét····';

  @override
  String get importEmptyMessage =>
      'Chóósé á búndlé, á spréádshéét, á dátásét ór á témpláté. Táptúré chécks ít ánd ópéns thé stép thát fíts.·····································';

  @override
  String get importChooseFile => 'Chóósé á fílé·····';

  @override
  String get importCheckingFile => 'Chéckíng thé fílé…·······';

  @override
  String get importKindsTitle => 'Whát éách fílé ópéns·······';

  @override
  String get importKindBundle => 'Búndlé (.zíp)·····';

  @override
  String get importBundleLine =>
      'Chéckéd, thén áddéd ás á prójéct ór mérgéd íntó óné.···················';

  @override
  String get importKindDataset => 'Référéncé dátásét (.jsón)·········';

  @override
  String get importDatasetLine =>
      'Á táblé óf référéncé róws ópéns thé dátásét ímpórtér.···················';

  @override
  String get importKindTemplate => 'Témpláté (.jsón)······';

  @override
  String get importTemplateLine =>
      'Á témpláté fílé ís chéckéd, thén áddéd tó thé ópén prójéct.·····················';

  @override
  String get importKindSheet => 'Spréádshéét (.xlsx ór .csv)··········';

  @override
  String get importSheetLine =>
      'Ásks whéthér íts róws áré récórds ór á régístér tó chéck ágáínst.·······················';

  @override
  String get importUnsupported =>
      'Táptúré cánnót ímpórt thís kínd óf fílé.··············';

  @override
  String get importNeedsProject =>
      'Ópén á prójéct fírst. Á spréádshéét, dátásét ór témpláté ís áddéd tó thé ópén prójéct.·······························';

  @override
  String get importNeedsProjectRecovery =>
      'Ópén thé prójéct fróm thé líst, thén ímpórt thé fílé ágáín.·····················';

  @override
  String get importPurposeTitle => 'Whát ís thís shéét?·······';

  @override
  String get importPurposeRecords => 'Récórds tó hóld······';

  @override
  String get importPurposeRecordsLine =>
      'Éách rów bécómés á récórd ón óné óf thís prójéct’s témplátés.······················';

  @override
  String get importPurposeRegister => 'Régístér tó vérífy ágáínst··········';

  @override
  String get importPurposeRegisterLine =>
      'Thé róws bécómé á référéncé dátásét thát vérífícátíón chécks whát yóú fínd ágáínst. Nó récórds áré mádé.·····································';

  @override
  String get importNoSheetHeadline => 'Nó shéét chósén······';

  @override
  String get importNoSheetMessage =>
      'Chóósé á spréádshéét ón thé ímpórt págé fírst.·················';

  @override
  String get importMappingTitle => 'Mátch cólúmns·····';

  @override
  String get importMappingTemplate => 'Témpláté···';

  @override
  String get importMappingColumns => 'Cólúmns···';

  @override
  String get importUnmapped => 'Nót mátchéd····';

  @override
  String get importNoTemplateHeadline => 'Nó témpláté tó mátch·······';

  @override
  String get importNoTemplateMessage =>
      'Thís prójéct hás nó témpláté yét. Máké óné fróm thís shéét’s cólúmns, thén ímpórt íts róws.································';

  @override
  String get importMakeTemplate => 'Máké á témpláté fróm thís shéét···········';

  @override
  String get importPreviewTitle =>
      'Fírst róws, ás théy wíll bé réád············';

  @override
  String importRow(int row) {
    final intl.NumberFormat rowNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowString = rowNumberFormat.format(row);

    return 'Rów ··$rowString';
  }

  @override
  String importRun(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ímpórt ···$countString róws··',
      one: 'Ímpórt 1 rów·····',
    );
    return '$_temp0';
  }

  @override
  String importIdentityMissing(Object field) {
    return '$field ís án ídéntíty fíéld ánd stíll nééds á cólúmn.·················';
  }

  @override
  String get importWriting => 'Ímpórtíng thé róws·······';

  @override
  String importProgress(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString óf ··$totalString róws··';
  }

  @override
  String get importKeptExisting => 'Képt thé récórd álréády héré.···········';

  @override
  String get importMatchUnsettled =>
      'Mátchés á récórd álréády héré, ánd nó chóícé wás mádé.···················';

  @override
  String importRepeatsRow(int row) {
    final intl.NumberFormat rowNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowString = rowNumberFormat.format(row);

    return 'Répéáts thé ídéntíty óf rów ··········$rowString ín thís fílé.·····';
  }

  @override
  String get importAllDone => 'Évéry rów wás ímpórtéd.·········';

  @override
  String get importOpenRecords => 'Ópén récórds·····';

  @override
  String get importFixFileName => 'róws-tó-fíx.csv······';

  @override
  String get importFixRowColumn => 'Rów ín shéét·····';

  @override
  String get importFixReasonColumn => 'Why ít wás nót ímpórtéd·········';

  @override
  String get importFixSaved => 'Róws tó fíx sávéd.·······';

  @override
  String get importSummaryTitle => 'Ímpórt súmmáry·····';

  @override
  String importCreated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString créátéd···';
  }

  @override
  String importUpdated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString úpdátéd···';
  }

  @override
  String importSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString skíppéd···';
  }

  @override
  String importFailed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString fáíléd···';
  }

  @override
  String get importRetry => 'Rétry fáílúrés·····';

  @override
  String get importExportProblems => 'Éxpórt róws tó fíx·······';

  @override
  String get importMatchTitle => 'Thís rów mátchés á récórd·········';

  @override
  String importMatchMessage(int row) {
    final intl.NumberFormat rowNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowString = rowNumberFormat.format(row);

    return 'Rów ··$rowString hás thé sámé ídéntíty ás á récórd álréády ín thís prójéct.·····················';
  }

  @override
  String get importMatchChoice => 'Whát tó dó wíth ít·······';

  @override
  String get importKeepExisting => 'Kéép éxístíng·····';

  @override
  String get importReplace => 'Réplácé···';

  @override
  String get importMerge => 'Mérgé··';

  @override
  String get importApplyToAll =>
      'Úsé thís chóícé fór évéry látér mátch·············';

  @override
  String get importMatchConfirm => 'Ápply··';

  @override
  String get cloudDestinationsTitle => 'Úplóád déstínátíóns·······';

  @override
  String get cloudDestinationsSubtitle =>
      'Whéré á fíníshéd fílé cán bé sént, whén yóú cónfírm ít.····················';

  @override
  String get destinationTitle => 'Úplóád déstínátíóns·······';

  @override
  String get destinationEmptyHeadline => 'Nó déstínátíóns yét·······';

  @override
  String get destinationEmptyMessage =>
      'Ádd á búckét, á fóldér ór á drívé yóú sígn ín tó. Nóthíng ís sént úntíl yóú cónfírm ít.·······························';

  @override
  String get destinationAdd => 'Ádd á déstínátíón······';

  @override
  String get destinationSave => 'Sávé··';

  @override
  String get destinationTest => 'Tést cónnéctíón······';

  @override
  String get destinationRemove => 'Rémóvé···';

  @override
  String get destinationRemoveTitle => 'Rémóvé thís déstínátíón?·········';

  @override
  String get destinationRemoveMessage =>
      'Thé déstínátíón ánd íts sávéd sígn-ín áré bóth délétéd.····················';

  @override
  String get destinationCheckFailed =>
      'Thé cónnéctíón tést díd nót súccééd, só thís déstínátíón wás nót sávéd.·························';

  @override
  String get destinationLabel => 'Námé··';

  @override
  String get destinationFolder => 'Fóldér···';

  @override
  String get destinationSecret => 'Sígn-ín···';

  @override
  String get destinationKindS3 => 'S3 búckét····';

  @override
  String get destinationKindDrive => 'Góóglé Drívé·····';

  @override
  String get destinationKindOneDrive => 'ÓnéDrívé···';

  @override
  String get destinationKindDropbox => 'Drópbóx···';

  @override
  String get destinationKindWebDav => 'WébDÁV···';

  @override
  String get destinationKindLocal => 'Fóldér ón thís dévícé········';

  @override
  String get destinationEdit => 'Édít déstínátíón······';

  @override
  String get destinationEditAction => 'Édít··';

  @override
  String get destinationKind => 'Typé··';

  @override
  String get destinationCheckAndSave => 'Chéck ánd sávé·····';

  @override
  String get destinationBucketFolder => 'Fóldér ín thé búckét·······';

  @override
  String get destinationOptional => 'Óptíónál···';

  @override
  String get destinationLocalFolderHint =>
      'Á fóldér ínsídé thé Táptúré fóldér, ór chóósé óné··················';

  @override
  String get destinationChooseFolder => 'Chóósé á fóldér······';

  @override
  String get destinationAccessKey => 'Áccéss kéy····';

  @override
  String get destinationSecretKey => 'Sécrét kéy····';

  @override
  String get destinationRegion => 'Régíón···';

  @override
  String get destinationBucket => 'Búckét···';

  @override
  String get destinationEndpoint => 'Éndpóínt···';

  @override
  String get destinationEndpointHint => 'Léávé émpty fór Ámázón S3·········';

  @override
  String get destinationAddress => 'Sérvér áddréss·····';

  @override
  String get destinationAddressHint =>
      'https://fílés.éxámplé.órg/dáv/···········';

  @override
  String get destinationSignInMethod => 'Sígn-ín méthód·····';

  @override
  String get destinationSignInPassword => 'Námé ánd pásswórd······';

  @override
  String get destinationSignInToken => 'Tókén··';

  @override
  String get destinationUsername => 'Úsér námé····';

  @override
  String get destinationPassword => 'Pásswórd···';

  @override
  String get destinationToken => 'Tókén··';

  @override
  String get destinationKeepSignIn =>
      'Léávé thé sígn-ín fíélds émpty tó kéép thé sávéd sígn-ín.····················';

  @override
  String get destinationSignInAgain => 'Sígn ín ágáín·····';

  @override
  String destinationSignInNote(Object provider) {
    return 'Yóú sígn ín tó ······$provider whén yóú sávé. Táptúré cán réách ónly thé fílés ít créátés théré.························';
  }

  @override
  String get destinationSignInUnavailable =>
      'Sígníng ín tó thís próvídér ís nót áváíláblé ón thís dévícé.·····················';

  @override
  String get destinationSignInMismatch =>
      'Thé sígn-ín díd nót fínísh. Try sávíng ágáín.················';

  @override
  String get destinationFolderRoot => 'thé tóp fóldér·····';

  @override
  String get destinationRemoveNothing =>
      'Thé déstínátíón ánd íts sígn-ín áré bóth stíll sávéd.···················';

  @override
  String get destinationRemoveHalf =>
      'Thé sígn-ín wás rémóvéd, bút thé déstínátíón ís stíll lístéd.······················';

  @override
  String get destinationRemoveAgain => 'Try rémóvíng ít ágáín.········';

  @override
  String get destinationRestoreFailed =>
      'Thé déstínátíón cóúld nót bé pút báck.··············';

  @override
  String get destinationAddAgain => 'Ádd ít ágáín.·····';

  @override
  String get destinationKept => 'Thé déstínátíón wás képt.·········';

  @override
  String get destinationKeptRecovery =>
      'Rémóvé ít látér íf yóú stíll wánt tó.·············';

  @override
  String destinationRemoved(Object label) {
    return '$label wás rémóvéd.·····';
  }

  @override
  String destinationRestored(Object label) {
    return '$label ís báck.····';
  }

  @override
  String destinationSaved(Object label) {
    return '$label wás sávéd.····';
  }

  @override
  String destinationCheckPassed(Object label) {
    return 'Thé cónnéctíón tó ·······$label wórks.···';
  }

  @override
  String destinationCheckedAt(Object dateFormatyMMMdformat) {
    return 'Chéckéd ···$dateFormatyMMMdformat';
  }

  @override
  String destinationCheckFailedAt(Object reason) {
    return 'Chéck fáíléd: ·····$reason';
  }

  @override
  String get destinationChecking => 'Chéckíng thé cónnéctíón…·········';

  @override
  String get destinationUnavailableHeadline =>
      'Úplóáds áré sént fróm á dévícé···········';

  @override
  String get destinationUnavailableMessage =>
      'Ópén Táptúré ón á phóné ór cómpútér tó ádd á déstínátíón.····················';

  @override
  String get uploadConfirmTitle => 'Sénd thís fílé?······';

  @override
  String get uploadConfirm => 'Sénd··';

  @override
  String uploadConfirmMessage(
    Object name,
    Object size,
    Object destination,
    Object folder,
  ) {
    return '$name ($size) wíll bé sént tó ·······$destination, ín ··$folder.';
  }

  @override
  String get uploadHistoryTitle => 'Úplóáds···';

  @override
  String get uploadHistoryEmptyHeadline => 'Nó úplóáds yét·····';

  @override
  String get uploadHistoryEmptyMessage =>
      'Á fílé áppéárs héré áftér yóú cónfírm séndíng ít.··················';

  @override
  String get uploadRetry => 'Rétry··';

  @override
  String get uploadFilter => 'Déstínátíón····';

  @override
  String get uploadFilterAll => 'Áll déstínátíóns······';

  @override
  String get uploadHistoryEmptyAction => 'Sét úp á déstínátíón·······';

  @override
  String get uploadToDestination => 'Úplóád tó á déstínátíón·········';

  @override
  String get uploadPickTitle => 'Sénd tó···';

  @override
  String uploadStarted(Object destination) {
    return 'Séndíng tó ····$destination. Fóllów ít úndér Úplóáds.··········';
  }

  @override
  String get uploadView => 'Víéw··';

  @override
  String uploadSent(Object name, Object destination) {
    return '$name wás sént tó ·····$destination.';
  }

  @override
  String uploadNotSent(Object reason) {
    return 'Nót sént. ····$reason';
  }

  @override
  String get uploadStopped =>
      'Thé úplóád wás stóppéd. Thé fílé ón thís dévícé ís únchángéd.······················';

  @override
  String get uploadFileMissing =>
      'Thé fílé ís nó lóngér ón thís dévícé ás ít wás éxpórtéd.····················';

  @override
  String get uploadFileMissingRecovery =>
      'Éxpórt ít ágáín, thén sénd ít.···········';

  @override
  String get uploadDestinationGone =>
      'Thát déstínátíón wás rémóvéd.···········';

  @override
  String get uploadDestinationGoneRecovery =>
      'Sénd thé fílé ágáín fróm íts éxpórt.·············';

  @override
  String get uploadOutcomeSent => 'Sént··';

  @override
  String get uploadOutcomeFailed => 'Fáíléd···';

  @override
  String get uploadOutcomeInterrupted => 'Íntérrúptéd····';

  @override
  String get uploadOutcomeStopped => 'Stóppéd···';

  @override
  String uploadAttemptLine(
    Object outcome,
    Object destination,
    Object size,
    Object when,
  ) {
    return '$outcome · $destination · $size · $when';
  }

  @override
  String uploadSendingLine(Object destination, int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return 'Séndíng tó ····$destination · $percentString%';
  }

  @override
  String get uploadStop => 'Stóp úplóád····';

  @override
  String get uploadDetails => 'Détáíls···';

  @override
  String uploadDetailsMessage(Object reason) {
    return '\nRéásón: ····$reason';
  }

  @override
  String uploadDetailsMessageFileDestinationFolderSize(
    Object file,
    Object destination,
    Object folder,
    Object size,
    Object whenstartedAt,
    Object ended,
    Object outcome,
    Object because,
  ) {
    return 'Fílé: ···$file\nDéstínátíón: ·····$destination\nFóldér: ····$folder\nSízé: ···$size\nStártéd: ····$whenstartedAt\nÉndéd: ···$ended\nÓútcómé: ····$outcome$because';
  }

  @override
  String get privacyScreenTitle => 'Whát léávés thís dévícé·········';

  @override
  String get privacyEmptyHeadline => 'Nóthíng ís sét úp tó sénd·········';

  @override
  String get privacyEmptyMessage =>
      'Ánálysís próvídérs ánd úplóád déstínátíóns áppéár héré whén théy áré áddéd.···························';

  @override
  String get egressAnalysisSection => 'Ánálysís···';

  @override
  String get egressUploadsSection => 'Úplóáds···';

  @override
  String get egressOfflineNotice =>
      'Ófflíné módé ís ón, só nóthíng léávés thís dévícé.··················';

  @override
  String get egressReadText => 'Réádíng téxt fróm phótós·········';

  @override
  String get egressExtractFields => 'Fíllíng fíélds fróm á récórd··········';

  @override
  String get egressRefineText => 'Tídyíng cáptíóns······';

  @override
  String get egressTranscribe => 'Túrníng spééch íntó téxt·········';

  @override
  String egressRow(Object sends, Object destination) {
    return '$sends · tó ···$destination';
  }

  @override
  String get egressSendsText => 'Téxt ónly····';

  @override
  String get egressSendsImage => 'Án ímágé···';

  @override
  String get egressSendsAudio => 'Áúdíó··';

  @override
  String get egressSendsFile => 'Á fílé···';

  @override
  String get egressSendsPackage => 'Éncryptéd prójéct páckágés··········';

  @override
  String get egressRelay => 'Réláy fór thís prójéct········';

  @override
  String get egressRelayServer => 'thé órgánísátíón sérvér·········';

  @override
  String get egressTextOnly => 'Téxt ónly, ón-dévícé ÓCR·········';

  @override
  String get gpsPrivacyTitle => 'Lócátíón···';

  @override
  String get gpsPrivacyCapture => 'Sávé lócátíón wíth cáptúrés··········';

  @override
  String get gpsPrivacyCaptureState =>
      'Ón. Chángé ít ín cáptúré séttíngs.············';

  @override
  String get gpsPrivacyCaptureStateOffChangeItIn =>
      'Óff. Chángé ít ín cáptúré séttíngs.·············';

  @override
  String get gpsPrivacyExclude =>
      'Léávé cóórdínátés óút óf éxpórts············';

  @override
  String get gpsPrivacyExcludeEffect =>
      'Éxpórts cárry nó lócátíón fíélds ánd nó lócátíón ín phótó détáíls.························';

  @override
  String get gpsPrivacyRemove => 'Rémóvé sávéd cóórdínátés·········';

  @override
  String get gpsPrivacyRemoveTitle => 'Rémóvé sávéd cóórdínátés?·········';

  @override
  String gpsPrivacyRemoveMessage(Object project) {
    return 'Évéry récórd ánd phótó ín ··········$project lósés íts sávéd lócátíón. Thé hístóry récórds whó rémóvéd thém ánd whén.··························';
  }

  @override
  String get gpsPrivacyRemoveConfirm => 'Rémóvé···';

  @override
  String gpsPrivacyRemoved(Object recordsCountcount) {
    return '$recordsCountcount chángéd. Nó sávéd cóórdínátés rémáín.··············';
  }

  @override
  String get gpsPrivacyNoProject =>
      'Ópén á prójéct tó rémóvé íts sávéd cóórdínátés.·················';

  @override
  String get faceBlurTitle => 'Blúr fácés ín éxpórtéd phótós···········';

  @override
  String get faceBlurEffect =>
      'Á phótó whósé fácés cánnót bé chéckéd ón thís dévícé stáys óút óf thé éxpórt.···························';

  @override
  String get redactionTitle => 'Hídé párts béfóré séndíng·········';

  @override
  String exportConsentOmitted(Object idsjoin) {
    return 'Ómíttéd wíthóút cónsént: ·········$idsjoin';
  }

  @override
  String get exportPrivacyChanged =>
      'Prívácy séttíngs chángéd. Éxpórt á néw fílé béfóré sháríng.·····················';

  @override
  String get redactionHint =>
      'Drág ácróss ánythíng thát múst nót bé sént. Thé phótó ítsélf dóés nót chángé.···························';

  @override
  String get redactionSave => 'Sávé híddén áréás······';

  @override
  String redactionCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString áréás híddén·····',
      one: '1 áréá híddén·····',
      zero: 'Nóthíng híddén yét·······',
    );
    return '$_temp0';
  }

  @override
  String get redactionSaved =>
      'Sávéd. Thésé áréás áré cóvéréd ín évéry cópy sént fór ánálysís.·······················';

  @override
  String get redactionEmptyHeadline => 'Nó phótó tó márk······';

  @override
  String get redactionEmptyMessage =>
      'Ópén á phótó fróm á récórd, thén márk whát tó hídé.··················';

  @override
  String get permissionLocation =>
      'Táptúré sávés á lócátíón ónly whén yóú túrn lócátíón ón fór á prójéct.·························';

  @override
  String get permissionStorage =>
      'Táptúré ópéns phótós ánd fílés yóú chóósé tó ímpórt.···················';

  @override
  String get permissionNotifications =>
      'Táptúré télls yóú whén á bátch óf ánálysís fíníshés.···················';

  @override
  String get privacyTitle => 'Prívácy···';

  @override
  String get privacySubtitle =>
      'Whát cán léávé thís dévícé, ánd whát névér dóés.·················';

  @override
  String get backendSettingsTitle => 'Órgánísátíón·····';

  @override
  String get relayChooseProject =>
      'Ópén á prójéct tó éxchángé chángés wíth íts óthér dévícés.·····················';

  @override
  String get relayEnable => 'Énáblé réláy·····';

  @override
  String get relayEnableHelp =>
      'Éncryptéd páckágés páss thróúgh thé órgánísátíón sérvér témpóráríly.························';

  @override
  String get relaySharedKey => 'Sháréd prójéct kéy·······';

  @override
  String get relayKeyHelp =>
      'Úsé thé sámé kéy óf át léást 16 cháráctérs ón éách dévícé. Éxchángé ít sépárátély; ít névér góés tó thé sérvér.·······································';

  @override
  String get relayQueueProject => 'Qúéúé prójéct páckágé········';

  @override
  String get relaySync => 'Sync réláy····';

  @override
  String get relayReceivedPackage => 'Prévíéw récéívéd chángés·········';

  @override
  String get shippedSuggestWithAi => 'Súggést wíth ÁÍ······';

  @override
  String get shippedAiSuggestion => 'ÁÍ súggéstíón·····';

  @override
  String get shippedAiSuggestionHelp =>
      'Súggéstéd órdér ónly. Prévíéw ánd chóósé thé témplátés yóú wánt.·······················';

  @override
  String get backendServerAddress => 'Sérvér áddréss·····';

  @override
  String get backendConfigurationHelp =>
      'Úsé thé HTTPS áddréss súpplíéd by yóúr ádmínístrátór. Léávé Órgánísátíón émpty whén thís sérvér hósts óné órgánísátíón.··········································';

  @override
  String get backendNotSignedIn => 'Nót sígnéd ín·····';

  @override
  String get backendSignedIn => 'Sígnéd ín ón thís dévícé·········';

  @override
  String get backendGrantUntil => 'Cáchéd áccéss úntíl·······';

  @override
  String get backendRole => 'Rólé··';

  @override
  String get backendRoleName => 'Ádmínístrátór·····';

  @override
  String get backendRoleNameProjectManager => 'Prójéct mánágér······';

  @override
  String get backendRoleNameReviewer => 'Révíéwér···';

  @override
  String get backendRoleNameFieldOperator => 'Fíéld ópérátór·····';

  @override
  String get backendEnrolment => 'Énrólmént····';

  @override
  String get backendNotEnrolled => 'Nót énrólléd·····';

  @override
  String get backendEnrolling => 'Sígníng ín····';

  @override
  String get backendEnrolled => 'Énrólléd···';

  @override
  String get backendRevokedState => 'Éndéd by thé órgánísátíón·········';

  @override
  String get backendRevoked =>
      'Thé órgánísátíón éndéd thís dévícé’s sígn-ín. Sígn ín ágáín whén thé sérvér ís réácháblé. Wórk ón thís dévícé cóntínúés.··········································';

  @override
  String get signInLater => 'Cóntínúé wíthóút sígníng ín··········';

  @override
  String get signOutAction => 'Sígn óút···';

  @override
  String get backendSettingsSubtitle =>
      'Thé sérvér thís dévícé ís énrólléd wíth.··············';

  @override
  String get signInTitle => 'Sígn ín···';

  @override
  String get signInAction => 'Sígn ín···';

  @override
  String get signInEmail => 'Émáíl··';

  @override
  String get signInPassword => 'Pásswórd···';

  @override
  String get signInOrganisation => 'Órgánísátíón·····';

  @override
  String get backendUnreachable =>
      'Thé sérvér cánnót bé réáchéd. Wórk ón thís dévícé cóntínúés.·····················';

  @override
  String get backendGrantExpired =>
      'Thé sávéd sígn-ín hás éxpíréd fór réláy, ánálysís ánd rólé chángés.························';

  @override
  String get signOutTitle => 'Sígn óút···';

  @override
  String get signOutMessage =>
      'Sígníng báck ín nééds á cónnéctíón tó thé sérvér.··················';

  @override
  String get relayTitle => 'Chángé réláy·····';

  @override
  String get relayOff =>
      'Réláy ís óff úntíl á prójéct mánágér énáblés ít.·················';

  @override
  String get relaySignInNeeded =>
      'Sígn ín tó úsé thé réláy. Wórk ón thís dévícé cóntínúés.····················';

  @override
  String get relayAddKey => 'Ádd sháréd kéy·····';

  @override
  String get relayNever => 'Thís prójéct névér úsés thé réláy.············';

  @override
  String get relaySend => 'Sénd chángés·····';

  @override
  String get relayQueued => 'Qúéúéd···';

  @override
  String get relaySent => 'Sént··';

  @override
  String get relayPurged => 'Púrgéd···';

  @override
  String get frictionLogAction => 'Sóméthíng wént wróng héré·········';

  @override
  String get frictionNote => 'Nóté (óptíónál)······';

  @override
  String get frictionScreenshot => 'Ínclúdé á scréénshót·······';

  @override
  String get frictionSave => 'Sávé répórt····';

  @override
  String get frictionSaved => 'Répórt sávéd ón thís dévícé.··········';

  @override
  String get frictionExport => 'Éxpórt fíéld tríál lóg········';

  @override
  String get frictionSaving => 'Yóúr répórt ís béíng sávéd.··········';

  @override
  String get frictionScreenshotFailed =>
      'Thé scréénshót cóúld nót bé cáptúréd.·············';

  @override
  String get frictionScreenshotRecovery =>
      'Try ágáín ór túrn óff thé scréénshót ánd sávé thé répórt.····················';

  @override
  String get feedbackJournalInvalid =>
      'Yóúr sávéd féédbáck cóúld nót bé réád.··············';

  @override
  String get feedbackJournalRecovery =>
      'Try ágáín. Kéép thé sávéd fílés só théy cán bé récóvéréd.····················';

  @override
  String get feedbackImageMissing =>
      'Á sávéd féédbáck ímágé ís míssíng.············';

  @override
  String get feedbackImageRecovery =>
      'Réstóré thé sávéd ímágé, thén éxpórt thé féédbáck ágáín.····················';

  @override
  String copyAnd(Object named0, Object named1) {
    return '$named0 ánd ··$named1';
  }

  @override
  String copyAndAnd(Object namedsublist0, Object namedlast) {
    return '$namedsublist0 ánd ··$namedlast';
  }

  @override
  String get gallerySampleName => 'Námé··';

  @override
  String get gallerySampleCaption => 'Cáptíón···';

  @override
  String get gallerySampleCount => 'Cóúnt··';

  @override
  String get gallerySampleEmail => 'Émáíl··';

  @override
  String get gallerySamplePhone => 'Phóné··';

  @override
  String get gallerySampleWhen => 'Whén··';

  @override
  String get gallerySampleGrade => 'Grádé··';

  @override
  String get gallerySampleFuel => 'Fúél··';

  @override
  String get gallerySampleTags => 'Tágs··';

  @override
  String get gallerySampleLocation => 'GPS··';

  @override
  String get gallerySampleStampCapture => 'Stámp éách cáptúré·······';

  @override
  String get gallerySampleBoilerA => 'Bóílér Á···';

  @override
  String get gallerySampleBoilerB => 'Bóílér B···';

  @override
  String get gallerySampleBesideList => 'Ópén bésídé thís líst········';

  @override
  String get gallerySampleWater => 'Wátér··';

  @override
  String get gallerySampleSteam => 'Stéám··';

  @override
  String get gallerySampleGas => 'Gás··';

  @override
  String get gallerySampleChip => 'Chíp··';

  @override
  String get gallerySampleFilter => 'Fíltér···';

  @override
  String get gallerySampleListTile => 'Líst tílé····';

  @override
  String get gallerySampleSecondaryLine => 'Sécóndáry líné·····';

  @override
  String surfacePreviewLevel(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Lévél ···$levelString';
  }

  @override
  String typeRampSample(String name) {
    return 'Thé ··$name rólé — Táp ít. Ít\'s dátá.··········';
  }

  @override
  String get importAnotherDevice => 'ánóthér dévícé·····';

  @override
  String get conflictUnknownDevice => 'Únknówn dévícé·····';

  @override
  String recordValueSource(String source) {
    return 'Sóúrcé: ···$source';
  }

  @override
  String recycleDeletedWhen(String when) {
    return 'Délétéd ···$when';
  }

  @override
  String exportIncompleteCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString íncómplété····';
  }

  @override
  String exportUnapprovedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString nót áppróvéd·····';
  }

  @override
  String exportBlockedMeetingCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString wíth méétíng áctíóns míssíng án ównér ór dúé dáté, whích stáy óút························';
  }

  @override
  String exportFaceCount(String id, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$id: $countString fácés···';
  }

  @override
  String mergeHistoryStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'applied': 'Mérgéd···',
      'undone': 'Úndóné···',
      'imported': 'Ímpórtéd···',
      'other': 'Fáíléd···',
    });
    return '$_temp0';
  }

  @override
  String mergeHistoryCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'records': 'Néw récórds····',
      'updated_records': 'Úpdátéd récórds······',
      'photos': 'Néw phótós····',
      'photos_here': 'Phótós álréády héré·······',
      'files': 'Fílés··',
      'deletions': 'Délétíóns····',
      'conflicts': 'Cónflícts····',
      'kept': 'Válúés képt····',
      'elsewhere': 'Álréády ín ánóthér prójéct··········',
      'duplicates': 'Póssíblé dúplícátés·······',
      'skipped': 'Skíppéd récórds······',
      'other': '$category',
    });
    return '$_temp0';
  }

  @override
  String mergeHistoryChoice(String choice) {
    String _temp0 = intl.Intl.selectLogic(choice, {
      'mine': 'Képt thís dévícé’s válúé·········',
      'theirs': 'Úséd íncómíng válúé·······',
      'typed': 'Éntéréd á réplácémént········',
      'keepBoth': 'Képt bóth témplátés·······',
      'other': 'Wáítíng fór á décísíón········',
    });
    return '$_temp0';
  }

  @override
  String relayPackageTooLarge(String bytes, String ceiling) {
    return 'Thís éncryptéd páckágé wóúld bé ············$bytes; réláy áccépts páckágés úp tó ···········$ceiling.';
  }

  @override
  String get relayPackageTooLargeRecovery =>
      'Sháré thé éxpórtéd páckágé díréctly ór éxpórt á smállér séléctíón.························';

  @override
  String get permissionBiometrics =>
      'Táptúré úsés bíómétrícs ónly whén yóú chóósé bíómétríc ápp únlóck.························';

  @override
  String get packageMetadataTooLargeRecovery =>
      'Chóósé á smállér páckágé scópé ón thé éxpórtíng dévícé, thén ópén thé néw páckágé.·····························';

  @override
  String get failureCancelledMessage => 'Thé áctíón wás cáncélléd.·········';

  @override
  String get failureCancelledRecovery =>
      'Stárt thé áctíón ágáín íf yóú stíll nééd ít.················';

  @override
  String get failureCorruptionMessage =>
      'Thís fílé ór rów cóúld nót bé réád.·············';

  @override
  String get failureCorruptionRecovery =>
      'Kéép thé órígínál. Éxpórt á cópy ánd try ópéníng ít ágáín.·····················';

  @override
  String get failureNetworkMessage =>
      'Thé nétwórk ís nót áváíláblé. Wórk ón thís dévícé ís sávéd.·····················';

  @override
  String get failureNetworkRecovery =>
      'Kéép cáptúríng. Prócéssíng wíll rétry whén yóú áré báck ónlíné.·······················';

  @override
  String get failurePermissionMessage =>
      'Táptúré dóés nót hávé pérmíssíón tó dó thát.················';

  @override
  String get failurePermissionRecovery =>
      'Állów thé pérmíssíón ín séttíngs, thén try ágáín.··················';

  @override
  String get failureProviderMessage =>
      'Á sérvícé thís scréén úsés fáíléd.············';

  @override
  String get failureProviderRecovery =>
      'Try ágáín. Nóthíng álréády cáptúréd wás lóst.················';

  @override
  String get failureStorageMessage =>
      'Thé phótó cóúld nót bé sávéd ón thís dévícé.················';

  @override
  String get failureStorageRecovery =>
      'Fréé úp spácé ór éxpórt á prójéct, thén try ágáín.··················';

  @override
  String get failureValidationMessage => 'Thát válúé ís nót válíd.·········';

  @override
  String get failureValidationRecovery =>
      'Córréct thé híghlíghtéd fíéld ánd sávé ágáín.················';

  @override
  String get processingTimeout =>
      'Thé próvídér díd nót ánswér ín tímé.·············';

  @override
  String get processingMalformedResponse =>
      'Thé próvídér réspónsé cóúld nót bé réád.··············';

  @override
  String get processingStopped => 'Prócéssíng stóppéd.·······';

  @override
  String get failureAIIsNotAvailable => 'ÁÍ ís nót áváíláblé.·······';

  @override
  String get failureContinueCapturingAnalysisCanWait =>
      'Cóntínúé cáptúríng. Ánálysís cán wáít.··············';

  @override
  String get failureThatPhotoIsNotOnThisDevice =>
      'Thát phótó ís nót ón thís dévícé.············';

  @override
  String get failureCaptureThePhotoAgainThenTryAgain =>
      'Cáptúré thé phótó ágáín, thén try ágáín.··············';

  @override
  String get failureThatPhotoCouldNotBeReadOn =>
      'Thát phótó cóúld nót bé réád ón thís dévícé.················';

  @override
  String get failureUseAnotherPhotoOrEnterTheValue =>
      'Úsé ánóthér phótó ór éntér thé válúé by hánd.················';

  @override
  String get failureThatPhotoCouldNotBeReadAs =>
      'Thát phótó cóúld nót bé réád ás án ímágé.···············';

  @override
  String get failureTheAnalysisCopyCouldNotBeRead =>
      'Thé ánálysís cópy cóúld nót bé réád.·············';

  @override
  String get failureKeepTheRecordAndTryAgain =>
      'Kéép thé récórd ánd try ágáín.···········';

  @override
  String get failureTheAnalysisResponseCouldNotBeRead =>
      'Thé ánálysís réspónsé cóúld nót bé réád.··············';

  @override
  String get failureAnalysisCanWait => 'Ánálysís cán wáít.·······';

  @override
  String get failureTheAnalysisQuotaIsUsedUp =>
      'Thé ánálysís qúótá ís úséd úp.···········';

  @override
  String get failureAnalysisIsPausedOnTheServerFor =>
      'Ánálysís ís páúséd ón thé sérvér fór á mómént.·················';

  @override
  String get failureContinueCapturingAnalysisTriesAgainLater =>
      'Cóntínúé cáptúríng. Ánálysís tríés ágáín látér.·················';

  @override
  String get failureAnalysisAccessIsUnavailableForThisProject =>
      'Ánálysís áccéss ís únáváíláblé fór thís prójéct.·················';

  @override
  String get failureContinueCapturingAndCheckOrganisationAccess =>
      'Cóntínúé cáptúríng ánd chéck órgánísátíón áccéss.··················';

  @override
  String get failureTheAnalysisMediaIsTooLargeTo =>
      'Thé ánálysís médíá ís tóó lárgé tó sénd.··············';

  @override
  String get failureKeepTheRecordAndCompleteItWithout =>
      'Kéép thé récórd ánd cómplété ít wíthóút ánálysís.··················';

  @override
  String get failureSignInWasNotAccepted =>
      'Sígn-ín wás nót áccéptéd.·········';

  @override
  String get failureCheckYourEmailPasswordAndOrganisation =>
      'Chéck yóúr émáíl, pásswórd ánd órgánísátíón.················';

  @override
  String get failureTheOrganisationEndedThisDeviceSSign =>
      'Thé órgánísátíón éndéd thís dévícé’s sígn-ín.················';

  @override
  String get failureSignInAgainWhenTheServerIs =>
      'Sígn ín ágáín whén thé sérvér ís réácháblé. Wórk ón thís dévícé cóntínúés.··························';

  @override
  String get failureTheServerCouldNotCompleteSignIn =>
      'Thé sérvér cóúld nót cómplété sígn-ín.··············';

  @override
  String get failureTryAgainWhenTheServerIsReachable =>
      'Try ágáín whén thé sérvér ís réácháblé. Wórk ón thís dévícé cóntínúés.·························';

  @override
  String get failureTheSavedSignInCouldNotBe =>
      'Thé sávéd sígn-ín cóúld nót bé réád.·············';

  @override
  String get failureCheckTheAccountSettingsYourLocalWork =>
      'Chéck thé áccóúnt séttíngs. Yóúr lócál wórk ís únchángéd.····················';

  @override
  String get failureEnterTheOrganisationSHTTPSServerAddress =>
      'Éntér thé órgánísátíón’s HTTPS sérvér áddréss.·················';

  @override
  String get failureCheckTheAddressWithYourAdministrator =>
      'Chéck thé áddréss wíth yóúr ádmínístrátór.···············';

  @override
  String get failureSignOutBeforeChangingOrganisation =>
      'Sígn óút béfóré chángíng órgánísátíón.··············';

  @override
  String get failureKeepTheCurrentAccountOrSignOut =>
      'Kéép thé cúrrént áccóúnt ór sígn óút fírst.················';

  @override
  String get failureTheOrganisationServerCouldNotBeReached =>
      'Thé órgánísátíón sérvér cóúld nót bé réáchéd.················';

  @override
  String get failureContinueWorkingOfflineAndTryAgainLater =>
      'Cóntínúé wórkíng ófflíné ánd try ágáín látér.················';

  @override
  String get failureUseASharedKeyOfAtLeast =>
      'Úsé á sháréd kéy óf át léást 16 cháráctérs.················';

  @override
  String get failureAskTheProjectManagerForTheSame =>
      'Ásk thé prójéct mánágér fór thé sámé kéy úséd ón thé óthér dévícés.························';

  @override
  String get failureThisProjectIsRegisteredOnTheServer =>
      'Thís prójéct ís régístéréd ón thé sérvér tó óthérs.··················';

  @override
  String get failureAskAnAdministratorToAddYouTo =>
      'Ásk án ádmínístrátór tó ádd yóú tó ít. Wórk ón thís dévícé cóntínúés.·························';

  @override
  String get failureAddTheSharedProjectKeyFirst =>
      'Ádd thé sháréd prójéct kéy fírst.············';

  @override
  String get failureAskTheProjectManagerForTheKey =>
      'Ásk thé prójéct mánágér fór thé kéy.·············';

  @override
  String get failureRelayCouldNotCompleteThisRequest =>
      'Réláy cóúld nót cómplété thís réqúést.··············';

  @override
  String get failureKeepWorkingLocallyAndTrySyncAgain =>
      'Kéép wórkíng lócálly ánd try Sync ágáín.··············';

  @override
  String get failureThatPasswordDidNotOpenTheBundle =>
      'Thát pásswórd díd nót ópén thé búndlé.··············';

  @override
  String get failureTryThePasswordAgainNothingWasExtracted =>
      'Try thé pásswórd ágáín. Nóthíng wás éxtráctéd.·················';

  @override
  String get failureTheProjectMetadataIsTooLargeFor =>
      'Thé prójéct métádátá ís tóó lárgé fór óné páckágé.··················';

  @override
  String get failureChooseASmallerPackageScope =>
      'Chóósé á smállér páckágé scópé.···········';

  @override
  String get failurePasswordProtectionIsUnavailableOnThisDevice =>
      'Pásswórd prótéctíón ís únáváíláblé ón thís dévícé.··················';

  @override
  String get failureOpenThisPackageOnASupportedDevice =>
      'Ópén thís páckágé ón á súppórtéd dévícé.··············';

  @override
  String get failurePasswordProtectionNeedsBrowserCryptography =>
      'Pásswórd prótéctíón nééds brówsér cryptógráphy.·················';

  @override
  String get failureOpenTheAppThroughASecureConnection =>
      'Ópén thé ápp thróúgh á sécúré cónnéctíón.···············';

  @override
  String get failureThisBundleNeedsAPassword =>
      'Thís búndlé nééds á pásswórd.···········';

  @override
  String get failureEnterItsPasswordToOpenIt =>
      'Éntér íts pásswórd tó ópén ít.···········';

  @override
  String get failureTheBundleContainsASecretAndWas =>
      'Thé búndlé cóntáíns á sécrét ánd wás nót wríttén.··················';

  @override
  String get failureRemoveTheSecretAndExportTheBundle =>
      'Rémóvé thé sécrét ánd éxpórt thé búndlé ágáín.·················';

  @override
  String get failureTheBundleHasTooManyNestedArchives =>
      'Thé búndlé hás tóó mány néstéd árchívés.··············';

  @override
  String get failureANestedBundleArchiveCouldNotBe =>
      'Á néstéd búndlé árchívé cóúld nót bé sáfély chéckéd.···················';

  @override
  String get failureAnEncryptedOrUnsupportedAttachmentCouldNot =>
      'Án éncryptéd ór únsúppórtéd áttáchmént cóúld nót bé chéckéd.·····················';

  @override
  String get failureANestedBundleArchiveIsTooLarge =>
      'Á néstéd búndlé árchívé ís tóó lárgé.·············';

  @override
  String get failureANestedBundleEntryHasAnInvalid =>
      'Á néstéd búndlé éntry hás án ínválíd sízé.···············';

  @override
  String get failureANestedBundleEntryExceedsItsDeclared =>
      'Á néstéd búndlé éntry éxcééds íts décláréd sízé.·················';

  @override
  String get failureFinishReadingTheCurrentPackageEntryFirst =>
      'Fínísh réádíng thé cúrrént páckágé éntry fírst.·················';

  @override
  String get failureThePackageEntryIsMissing =>
      'Thé páckágé éntry ís míssíng.···········';

  @override
  String get failureReadThisLargePackageEntryAsA =>
      'Réád thís lárgé páckágé éntry ás á stréám.···············';

  @override
  String get failureThePackageEntryChanged =>
      'Thé páckágé éntry chángéd.··········';

  @override
  String get failureThePackageEntryChecksumChanged =>
      'Thé páckágé éntry chécksúm chángéd.·············';

  @override
  String failureNoUploadDestinationIsRegisteredForValue(String value0) {
    return 'Nó úplóád déstínátíón ís régístéréd fór ··············$value0.';
  }

  @override
  String get failureChooseAnotherDestination =>
      'Chóósé ánóthér déstínátíón.··········';

  @override
  String get failureTheDestinationRefusedTheSignIn =>
      'Thé déstínátíón réfúséd thé sígn-ín.·············';

  @override
  String get failureCheckTheKeyOrSignInAgain =>
      'Chéck thé kéy ór sígn ín ágáín.···········';

  @override
  String get failureThatBucketOrFolderWasNotFound =>
      'Thát búckét ór fóldér wás nót fóúnd.·············';

  @override
  String get failureCheckTheNameAndTryTheConnection =>
      'Chéck thé námé ánd try thé cónnéctíón ágáín.················';

  @override
  String get failureTheDestinationDidNotFinishTheUpload =>
      'Thé déstínátíón díd nót fínísh thé úplóád.···············';

  @override
  String get failureTryAgain => 'Try ágáín.····';

  @override
  String get failureTheServerRedirectedTheUploadToAnother =>
      'Thé sérvér rédíréctéd thé úplóád tó ánóthér hóst.··················';

  @override
  String get failureCheckTheAddressAndTryAgain =>
      'Chéck thé áddréss ánd try ágáín.············';

  @override
  String get failureTheDestinationRejectedTheUpload =>
      'Thé déstínátíón réjéctéd thé úplóád.·············';

  @override
  String get failureCheckTheSettingsAndTryAgain =>
      'Chéck thé séttíngs ánd try ágáín.············';

  @override
  String get failureTheFileCouldNotBeReadWhile =>
      'Thé fílé cóúld nót bé réád whílé ít wás béíng sént.··················';

  @override
  String get failureCheckThatTheFileIsStillOn =>
      'Chéck thát thé fílé ís stíll ón thís dévícé, thén rétry.····················';

  @override
  String get failureUploadsArePausedWhileTheAppIs =>
      'Úplóáds áré páúséd whílé thé ápp ís ófflíné.················';

  @override
  String get failureGoOnlineThenConfirmTheUploadAgain =>
      'Gó ónlíné, thén cónfírm thé úplóád ágáín.···············';

  @override
  String get failureUploadsToThisDestinationAreTurnedOff =>
      'Úplóáds tó thís déstínátíón áré túrnéd óff.················';

  @override
  String get failureEnableTheDestinationOnThePrivacyPage =>
      'Énáblé thé déstínátíón ón thé prívácy págé fírst.··················';

  @override
  String get failureCloudSignInCouldNotFinish =>
      'Clóúd sígn-ín cóúld nót fínísh.···········';

  @override
  String get failureTrySigningInAgain => 'Try sígníng ín ágáín.········';

  @override
  String get failureTheDestinationReturnedTooMuchData =>
      'Thé déstínátíón rétúrnéd tóó múch dátá.··············';

  @override
  String get failureCheckTheDestinationAddressAndTryAgain =>
      'Chéck thé déstínátíón áddréss ánd try ágáín.················';

  @override
  String get failureTheDestinationCouldNotBeReached =>
      'Thé déstínátíón cóúld nót bé réáchéd.·············';

  @override
  String get failureTryAgainWhenYouAreOnline =>
      'Try ágáín whén yóú áré ónlíné.···········';

  @override
  String get failureRemoveTheDestinationAndAddItAgain =>
      'Rémóvé thé déstínátíón ánd ádd ít ágáín.··············';

  @override
  String get failureThisDestinationSignInChangedDuringThe =>
      'Thís déstínátíón sígn-ín chángéd dúríng thé úplóád.··················';

  @override
  String get failureReviewTheDestinationAndConfirmANew =>
      'Révíéw thé déstínátíón ánd cónfírm á néw úplóád.·················';

  @override
  String get failureTheDestinationDidNotAcceptTheTest =>
      'Thé déstínátíón díd nót áccépt thé tést fílé.················';

  @override
  String get failureSignInAgainAndRetryTheTest =>
      'Sígn ín ágáín ánd rétry thé tést.············';

  @override
  String get failureTheDestinationHasNotFinishedTheUpload =>
      'Thé déstínátíón hás nót fíníshéd thé úplóád.················';

  @override
  String get failureRetryTheUpload => 'Rétry thé úplóád.······';

  @override
  String get failureThatFolderCannotBeWritten =>
      'Thát fóldér cánnót bé wríttén.···········';

  @override
  String get failureChooseTheFolderAgain => 'Chóósé thé fóldér ágáín.·········';

  @override
  String get failureTheFileCouldNotBeWrittenTo =>
      'Thé fílé cóúld nót bé wríttén tó thát fóldér.················';

  @override
  String get failureFreeSomeSpaceOrChooseTheFolder =>
      'Fréé sómé spácé ór chóósé thé fóldér ágáín.················';

  @override
  String get failureThisFolderRequiresASupportedSystemFolder =>
      'Thís fóldér réqúírés á súppórtéd systém fóldér gránt.···················';

  @override
  String get failureChooseAnAccessibleFolderOrAnotherDestination =>
      'Chóósé án áccéssíblé fóldér ór ánóthér déstínátíón.··················';

  @override
  String get failureThatFolderPathIsNotUsable =>
      'Thát fóldér páth ís nót úsáblé.···········';

  @override
  String get failureTheTaptureFolderOnThisDeviceIs =>
      'Thé Táptúré fóldér ón thís dévícé ís nót áváíláblé.··················';

  @override
  String get failureCheckTheStorageLocationInSettings =>
      'Chéck thé stórágé lócátíón ín Séttíngs.··············';

  @override
  String get failureThisGoogleDriveSignInIsNo =>
      'Thís Góóglé Drívé sígn-ín ís nó lóngér áváíláblé.··················';

  @override
  String get failureSignInToThisDestinationAgain =>
      'Sígn ín tó thís déstínátíón ágáín.············';

  @override
  String get failureGoogleDriveNeedsACurrentSignIn =>
      'Góóglé Drívé nééds á cúrrént sígn-ín fór thís áccóúnt.···················';

  @override
  String get failureSignInAgainToAllowFileAccess =>
      'Sígn ín ágáín tó állów fílé áccéss.·············';

  @override
  String get failureNativeGoogleDriveSignInIsUnavailable =>
      'Nátívé Góóglé Drívé sígn-ín ís únáváíláblé.················';

  @override
  String get failureTheDestinationIsStillSavedSignIn =>
      'Thé déstínátíón ís stíll sávéd. Sígn ín, thén try thé úplóád.······················';

  @override
  String get failureTheUploadChunkSizeIsNotUsable =>
      'Thé úplóád chúnk sízé ís nót úsáblé.·············';

  @override
  String get failureUseTheStandardUploadSettings =>
      'Úsé thé stándárd úplóád séttíngs.············';

  @override
  String get failureTheDestinationReturnedAnUnusableUploadResponse =>
      'Thé déstínátíón rétúrnéd án únúsáblé úplóád réspónsé.···················';

  @override
  String get failureTestTheDestinationThenTryTheUpload =>
      'Tést thé déstínátíón, thén try thé úplóád ágáín.·················';

  @override
  String get failureTheBucketDidNotAcknowledgeTheUploaded =>
      'Thé búckét díd nót ácknówlédgé thé úplóádéd párt.··················';

  @override
  String get failureTestTheDestinationAndTryAgain =>
      'Tést thé déstínátíón ánd try ágáín.·············';

  @override
  String get failureTheBucketDidNotFinishTheUpload =>
      'Thé búckét díd nót fínísh thé úplóád.·············';

  @override
  String get failureTheBucketRefusedToFinishTheUpload =>
      'Thé búckét réfúséd tó fínísh thé úplóád.··············';

  @override
  String get failureTheBucketDidNotConfirmTheCompleted =>
      'Thé búckét díd nót cónfírm thé cómplétéd úplóád.·················';

  @override
  String get failureTheDestinationDidNotStartTheUpload =>
      'Thé déstínátíón díd nót stárt thé úplóád.···············';

  @override
  String get failureTryTheConnectionAgain =>
      'Try thé cónnéctíón ágáín.·········';

  @override
  String get failureThisDestinationHasNoSavedSignIn =>
      'Thís déstínátíón hás nó sávéd sígn-ín.··············';

  @override
  String get failureEnterTheKeysAndTestTheConnection =>
      'Éntér thé kéys ánd tést thé cónnéctíón.··············';

  @override
  String get failureTheSavedSignInIsNotUsable =>
      'Thé sávéd sígn-ín ís nót úsáblé.············';

  @override
  String get failureEnterTheKeysAgain => 'Éntér thé kéys ágáín.········';

  @override
  String get failureTheBucketSettingsAreIncomplete =>
      'Thé búckét séttíngs áré íncómplété.·············';

  @override
  String get failureEnterTheKeyRegionAndBucket =>
      'Éntér thé kéy, régíón ánd búckét.············';

  @override
  String get failureChooseAFilenameWithoutFolderSeparators =>
      'Chóósé á fílénámé wíthóút fóldér sépárátórs.················';

  @override
  String get failureTheFolderCouldNotOpenANew =>
      'Thé fóldér cóúld nót ópén á néw fílé.·············';

  @override
  String get failureTheFolderCouldNotPublishTheFile =>
      'Thé fóldér cóúld nót públísh thé fílé.··············';

  @override
  String get failureAccessToTheChosenFolderWasLost =>
      'Áccéss tó thé chósén fóldér wás lóst.·············';

  @override
  String get failureChooseAnAccessibleFolderAndTryAgain =>
      'Chóósé án áccéssíblé fóldér ánd try ágáín.···············';

  @override
  String get failureTheUploadFilenameIsNotUsable =>
      'Thé úplóád fílénámé ís nót úsáblé.············';

  @override
  String get failureEnterTheAddressAndSignInThen =>
      'Éntér thé áddréss ánd sígn-ín, thén tést ít.················';

  @override
  String get failureTheDestinationAddressOrSignInIs =>
      'Thé déstínátíón áddréss ór sígn-ín ís nót úsáblé.··················';

  @override
  String get failureEnterAFullHTTPSAddressAndSign =>
      'Éntér á fúll HTTPS áddréss ánd sígn-ín ágáín.················';

  @override
  String get failureGoogleDriveSignInCouldNotFinish =>
      'Góóglé Drívé sígn-ín cóúld nót fínísh.··············';

  @override
  String get failureThisDestinationNeedsAFreshSignIn =>
      'Thís déstínátíón nééds á frésh sígn-ín.··············';

  @override
  String get failureTheUploadCheckpointCouldNotBeSaved =>
      'Thé úplóád chéckpóínt cóúld nót bé sávéd ín tímé.··················';

  @override
  String get failureCheckSecureStorageThenTryAgain =>
      'Chéck sécúré stórágé, thén try ágáín.·············';

  @override
  String get failureThatRowIsNoLongerOnThis =>
      'Thát rów ís nó lóngér ón thís dévícé.·············';

  @override
  String get failureRefreshTheListAndTryAgain =>
      'Réfrésh thé líst ánd try ágáín.···········';

  @override
  String get failureADeleteNeedsAReason => 'Á délété nééds á réásón.·········';

  @override
  String get failureSayWhyThisRowShouldBeRemoved =>
      'Sáy why thís rów shóúld bé rémóvéd, thén try ágáín.··················';

  @override
  String get failureTheDatabaseCouldNotCompleteThatWrite =>
      'Thé dátábásé cóúld nót cómplété thát wríté.················';

  @override
  String get failureFreeUpSpaceOrExportAProject =>
      'Fréé úp spácé ór éxpórt á prójéct, thén try ágáín.··················';

  @override
  String get failureTheDatabaseIsEncryptedAndTheKey =>
      'Thé dátábásé ís éncryptéd ánd thé kéy ís míssíng.··················';

  @override
  String get failureRestoreTheKeyFromABackupThen =>
      'Réstóré thé kéy fróm á báckúp, thén ópén thé ápp ágáín.····················';

  @override
  String get failureTheDatabaseKeyIsMissingOrUnreadable =>
      'Thé dátábásé kéy ís míssíng ór únréádáblé.···············';

  @override
  String get failureTypeDISABLEENCRYPTIONToTurnEncryptionOff =>
      'Typé DÍSÁBLÉ ÉNCRYPTÍÓN tó túrn éncryptíón óff.·················';

  @override
  String get failureEnterTheConfirmationExactlyThenTryAgain =>
      'Éntér thé cónfírmátíón éxáctly, thén try ágáín.·················';

  @override
  String get failureThereIsNoDatabaseToEncrypt =>
      'Théré ís nó dátábásé tó éncrypt.············';

  @override
  String get failureOpenTheAppOnceSoADatabase =>
      'Ópén thé ápp óncé só á dátábásé ís créátéd, thén try ágáín.·····················';

  @override
  String get failureTheDatabaseCouldNotBeEncrypted =>
      'Thé dátábásé cóúld nót bé éncryptéd.·············';

  @override
  String get failureFreeUpSpaceThenTryAgain =>
      'Fréé úp spácé, thén try ágáín.···········';

  @override
  String get failureTheEncryptedCopyDidNotMatchThe =>
      'Thé éncryptéd cópy díd nót mátch thé órígínál.·················';

  @override
  String get failureTryEncryptingAgainTheOriginalDatabaseWas =>
      'Try éncryptíng ágáín. Thé órígínál dátábásé wás nót chángéd.·····················';

  @override
  String get failureKeepTheWorkingDatabaseFreeUpSpace =>
      'Kéép thé wórkíng dátábásé. Fréé úp spácé, thén clósé ágáín.·····················';

  @override
  String get failureRestoreTheKeyFromABackupThe =>
      'Réstóré thé kéy fróm á báckúp. Thé éncryptéd dátábásé wás nót chángéd.·························';

  @override
  String get failureThisUpdateWouldDropOrRewriteA =>
      'Thís úpdáté wóúld dróp ór réwríté á cólúmn.················';

  @override
  String get failureExportYourProjectsThenConfirmTheUpdate =>
      'Éxpórt yóúr prójécts, thén cónfírm thé úpdáté.·················';

  @override
  String get failureThisDeviceCannotBuildTheRecordSearch =>
      'Thís dévícé cánnót búíld thé récórd séárch índéx.··················';

  @override
  String get failureUpdateTheAppThenOpenItAgain =>
      'Úpdáté thé ápp, thén ópén ít ágáín.·············';

  @override
  String get failureTheFilePathMustStayInsideThe =>
      'Thé fílé páth múst stáy ínsídé thé prójéct fóldér.··················';

  @override
  String get failureSaveTheFileUnderTheProjectFolder =>
      'Sávé thé fílé úndér thé prójéct fóldér ánd try ágáín.···················';

  @override
  String get failureTheOriginalCaptionCannotBeChanged =>
      'Thé órígínál cáptíón cánnót bé chángéd.··············';

  @override
  String get failureLeaveTheCapturedTextAndWriteA =>
      'Léávé thé cáptúréd téxt ánd wríté á réfínéd óné.·················';

  @override
  String get failureADuplicatePairNeedsTwoRecords =>
      'Á dúplícáté páír nééds twó récórds.·············';

  @override
  String get failureChooseBothRecordsAndTryAgain =>
      'Chóósé bóth récórds ánd try ágáín.············';

  @override
  String get failureARecordCannotBeADuplicateOf =>
      'Á récórd cánnót bé á dúplícáté óf ítsélf.···············';

  @override
  String get failureChooseTwoDifferentRecordsAndTryAgain =>
      'Chóósé twó dífférént récórds ánd try ágáín.················';

  @override
  String get failureADuplicatePairNeedsAProjectA =>
      'Á dúplícáté páír nééds á prójéct, á sígnál ánd á scóré.····················';

  @override
  String get failureRunDetectionAgainThenTryAgain =>
      'Rún détéctíón ágáín, thén try ágáín.·············';

  @override
  String get failureAResolutionNeedsAChoiceAndAn =>
      'Á résólútíón nééds á chóícé ánd án ópérátór.················';

  @override
  String get failureChooseHowToResolveThePairThen =>
      'Chóósé hów tó résólvé thé páír, thén try ágáín.·················';

  @override
  String get failureThatPairIsNoLongerOnThis =>
      'Thát páír ís nó lóngér ón thís dévícé.··············';

  @override
  String get failureACompletedExportCannotBeChanged =>
      'Á cómplétéd éxpórt cánnót bé chángéd.·············';

  @override
  String get failureRunANewExportInsteadOfRewriting =>
      'Rún á néw éxpórt ínstéád óf réwrítíng thís óné.·················';

  @override
  String get failureAnExportIsRecordedOnlyWhenThe =>
      'Án éxpórt ís récórdéd ónly whén thé fílé ís fíníshéd.···················';

  @override
  String get failureFinishWritingTheFileThenRecordThe =>
      'Fínísh wrítíng thé fílé, thén récórd thé éxpórt.·················';

  @override
  String get failureTheExportFormatsAreNotInA =>
      'Thé éxpórt fórmáts áré nót ín á fórm Táptúré cán stóré.····················';

  @override
  String get failureFixTheFormatsListAndSaveAgain =>
      'Fíx thé fórmáts líst ánd sávé ágáín.·············';

  @override
  String get failureTheExportFiltersAreNotInA =>
      'Thé éxpórt fíltérs áré nót ín á fórm Táptúré cán stóré.····················';

  @override
  String get failureStoreTheQueryNotTheExportedValues =>
      'Stóré thé qúéry, nót thé éxpórtéd válúés.···············';

  @override
  String get failureThatEntryCouldNotBeRead =>
      'Thát éntry cóúld nót bé réád.···········';

  @override
  String get failureChangeItThenSaveAgain =>
      'Chángé ít, thén sávé ágáín.··········';

  @override
  String get failureTheMarkedAreaOnThePhotoCould =>
      'Thé márkéd áréá ón thé phótó cóúld nót bé réád.·················';

  @override
  String get failureFixTheRegionObjectAndSaveAgain =>
      'Fíx thé régíón óbjéct ánd sávé ágáín.·············';

  @override
  String get failureTheMarkedAreaOnThePhotoIs =>
      'Thé márkéd áréá ón thé phótó ís nót ín á fórm Táptúré cán stóré.·······················';

  @override
  String get failureThatMeetingIsNoLongerOnThis =>
      'Thát méétíng ís nó lóngér ón thís dévícé.···············';

  @override
  String get failureTheOriginalTranscriptCannotBeChanged =>
      'Thé órígínál tránscrípt cánnót bé chángéd.···············';

  @override
  String get failureLeaveTheCapturedTextAndWriteRefined =>
      'Léávé thé cáptúréd téxt ánd wríté réfínéd mínútés.··················';

  @override
  String get failureTheMeetingAgendaCouldNotBeRead =>
      'Thé méétíng ágéndá cóúld nót bé réád.·············';

  @override
  String get failureFixTheAgendaListAndSaveAgain =>
      'Fíx thé ágéndá líst ánd sávé ágáín.·············';

  @override
  String get failureTheMeetingAgendaIsNotInA =>
      'Thé méétíng ágéndá ís nót ín á fórm Táptúré cán stóré.···················';

  @override
  String get failureTheMergeSummaryCouldNotBeRead =>
      'Thé mérgé súmmáry cóúld nót bé réád.·············';

  @override
  String get failureFixTheCountsObjectAndSaveAgain =>
      'Fíx thé cóúnts óbjéct ánd sávé ágáín.·············';

  @override
  String get failureTheMergeSummaryIsNotInA =>
      'Thé mérgé súmmáry ís nót ín á fórm Táptúré cán stóré.···················';

  @override
  String get failureAConflictNeedsAChoiceAndAn =>
      'Á cónflíct nééds á chóícé ánd án ópérátór.···············';

  @override
  String get failureChooseASideThenResolveAgain =>
      'Chóósé á sídé, thén résólvé ágáín.············';

  @override
  String get failureThatConflictIsNoLongerOnThis =>
      'Thát cónflíct ís nó lóngér ón thís dévícé.···············';

  @override
  String get failureThatJobIsNoLongerOnThis =>
      'Thát jób ís nó lóngér ón thís dévícé.·············';

  @override
  String get failureRefreshTheQueueAndTryAgain =>
      'Réfrésh thé qúéúé ánd try ágáín.············';

  @override
  String get failureAStoredProviderResponseCannotBeChanged =>
      'Á stóréd próvídér réspónsé cánnót bé chángéd.················';

  @override
  String get failureLeaveTheOriginalResultAndWriteA =>
      'Léávé thé órígínál résúlt ánd wríté á néw óné.·················';

  @override
  String get failureARequestSummaryCannotIncludeASecret =>
      'Á réqúést súmmáry cánnót ínclúdé á sécrét.···············';

  @override
  String get failureStoreShapeAndSizeOnlyThenSave =>
      'Stóré shápé ánd sízé ónly, thén sávé ágáín.················';

  @override
  String get failureTheProjectSettingsCouldNotBeRead =>
      'Thé prójéct séttíngs cóúld nót bé réád.··············';

  @override
  String get failureChangeTheSettingsAgainThenSave =>
      'Chángé thé séttíngs ágáín, thén sávé.·············';

  @override
  String get failureTheProjectSettingsAreNotInA =>
      'Thé prójéct séttíngs áré nót ín á fórm Táptúré cán stóré.····················';

  @override
  String get failureThatRecordIsNoLongerOnThis =>
      'Thát récórd ís nó lóngér ón thís dévícé.··············';

  @override
  String get failureTheRecordSContextCouldNotBe =>
      'Thé récórd\'s cóntéxt cóúld nót bé réád.··············';

  @override
  String get failureFixTheContextObjectAndSaveAgain =>
      'Fíx thé cóntéxt óbjéct ánd sávé ágáín.··············';

  @override
  String get failureTheRecordSContextIsNotIn =>
      'Thé récórd\'s cóntéxt ís nót ín á fórm Táptúré cán stóré.····················';

  @override
  String get failureThatValueIsNoLongerOnThis =>
      'Thát válúé ís nó lóngér ón thís dévícé.··············';

  @override
  String get failureRefreshTheRecordAndTryAgain =>
      'Réfrésh thé récórd ánd try ágáín.············';

  @override
  String get failureTheOriginalValueCannotBeChanged =>
      'Thé órígínál válúé cánnót bé chángéd.·············';

  @override
  String get failureLeaveTheCapturedValueAndWriteA =>
      'Léávé thé cáptúréd válúé ánd wríté á réfínéd óné.··················';

  @override
  String get failureADatasetImportNeedsASourceFile =>
      'Á dátásét ímpórt nééds á sóúrcé fílé ánd á scópé.··················';

  @override
  String get failureChooseTheFileAndWhereItBelongs =>
      'Chóósé thé fílé ánd whéré ít bélóngs, thén ímpórt ágáín.····················';

  @override
  String get failureAProjectDatasetNeedsAProject =>
      'Á prójéct dátásét nééds á prójéct.············';

  @override
  String get failureChooseTheProjectThenImportAgain =>
      'Chóósé thé prójéct, thén ímpórt ágáín.··············';

  @override
  String get failureAGlobalDatasetCannotBelongToOne =>
      'Á glóbál dátásét cánnót bélóng tó óné prójéct.·················';

  @override
  String get failureClearTheProjectThenImportAgain =>
      'Cléár thé prójéct, thén ímpórt ágáín.·············';

  @override
  String get failureTheDatasetColumnsAreNotInA =>
      'Thé dátásét cólúmns áré nót ín á fórm Táptúré cán stóré.····················';

  @override
  String get failureFixTheColumnListAndSaveAgain =>
      'Fíx thé cólúmn líst ánd sávé ágáín.·············';

  @override
  String get failureAReferenceRowIsNotInA =>
      'Á référéncé rów ís nót ín á fórm Táptúré cán stóré.··················';

  @override
  String get failureFixTheRowValuesAndSaveAgain =>
      'Fíx thé rów válúés ánd sávé ágáín.············';

  @override
  String get failureThatEntryIsNotInAForm =>
      'Thát éntry ís nót ín á fórm Táptúré cán stóré.·················';

  @override
  String get failureAResolutionNeedsAnOperator =>
      'Á résólútíón nééds án ópérátór.···········';

  @override
  String get failureSignInThenResolveTheVarianceAgain =>
      'Sígn ín, thén résólvé thé váríáncé ágáín.···············';

  @override
  String get failureThatVarianceIsNoLongerOnThis =>
      'Thát váríáncé ís nó lóngér ón thís dévícé.···············';

  @override
  String get failureTheDatabaseIsBusy => 'Thé dátábásé ís búsy.········';

  @override
  String get failureWaitAMomentThenTryTheSave =>
      'Wáít á mómént, thén try thé sávé ágáín.··············';

  @override
  String get failureARecordWithThatIdentityAlreadyExists =>
      'Á récórd wíth thát ídéntíty álréády éxísts.················';

  @override
  String get failureOpenTheExistingRecordOrChangeThe =>
      'Ópén thé éxístíng récórd, ór chángé thé ídéntíty.··················';

  @override
  String get failureThatPhotoCouldNotBeBlurred =>
      'Thát phótó cóúld nót bé blúrréd.············';

  @override
  String get failureADetectedFaceIsOutsideThatPhoto =>
      'Á détéctéd fácé ís óútsídé thát phótó.··············';

  @override
  String get failureFaceDetectionIsUnavailableOnThisDevice =>
      'Fácé détéctíón ís únáváíláblé ón thís dévícé.················';

  @override
  String get failureUseAnAndroidOrIOSDeviceTo =>
      'Úsé án Ándróíd ór íÓS dévícé tó blúr fácés.················';

  @override
  String get failureThisPhotoCannotBeCheckedForFaces =>
      'Thís phótó cánnót bé chéckéd fór fácés.··············';

  @override
  String get failureThisPhotoCannotBeProtected =>
      'Thís phótó cánnót bé prótéctéd.···········';

  @override
  String get failureAHiddenAreaIsInvalid =>
      'Á híddén áréá ís ínválíd.·········';

  @override
  String get failureThisExportFolderAlreadyContainsCompletedFiles =>
      'Thís éxpórt fóldér álréády cóntáíns cómplétéd fílés.···················';

  @override
  String get failureCreateTheExportInANewVersion =>
      'Créáté thé éxpórt ín á néw vérsíón fóldér.···············';

  @override
  String get failureStreamingTextExportNeedsNativeStorage =>
      'Stréámíng téxt éxpórt nééds nátívé stórágé.················';

  @override
  String get failureTaptureCannotCopyAFileFromThis =>
      'Táptúré cánnót cópy á fílé fróm thís dévícé héré.··················';

  @override
  String get failureAddTheFileAgainFromTaptureThen =>
      'Ádd thé fílé ágáín fróm Táptúré, thén try ágáín.·················';

  @override
  String failureTaptureCouldNotWriteToValue(String value0) {
    return 'Táptúré cóúld nót wríté tó ··········$value0.';
  }

  @override
  String get failureTaptureCouldNotNameThatStoredFile =>
      'Táptúré cóúld nót námé thát stóréd fílé.··············';

  @override
  String get failureTryAgainIfItKeepsHappeningExport =>
      'Try ágáín. Íf ít kééps háppéníng, éxpórt thé lóg.··················';

  @override
  String get failureTaptureCouldNotSaveThatOnThis =>
      'Táptúré cóúld nót sávé thát ón thís dévícé.················';

  @override
  String get failureFreeSomeSpaceThenTryAgain =>
      'Fréé sómé spácé, thén try ágáín.············';

  @override
  String get failureTheCacheCouldNotBeCleanedOn =>
      'Thé cáché cóúld nót bé cléánéd ón thís dévícé.·················';

  @override
  String get failureFreeSpaceOrAllowStorageAccessThen =>
      'Fréé spácé ór állów stórágé áccéss, thén try ágáín.··················';

  @override
  String get failureThatImageSizeIsNotValid =>
      'Thát ímágé sízé ís nót válíd.···········';

  @override
  String get failureUseTheAppUploadSizeAndTry =>
      'Úsé thé ápp úplóád sízé ánd try ágáín.··············';

  @override
  String get failureTheReducedCopyCouldNotBeCreated =>
      'Thé rédúcéd cópy cóúld nót bé créátéd ón thís dévícé.···················';

  @override
  String failureTaptureCouldNotFindValue(String value0) {
    return 'Táptúré cóúld nót fínd ·········$value0.';
  }

  @override
  String failureTaptureCouldNotSaveValue(String value0) {
    return 'Táptúré cóúld nót sávé ·········$value0.';
  }

  @override
  String get failureFreeSomeSpaceThenDownloadAgain =>
      'Fréé sómé spácé, thén dównlóád ágáín.·············';

  @override
  String get failureOpenDownloadsOnThisDeviceAndLook =>
      'Ópén Dównlóáds ón thís dévícé ánd lóók ín Táptúré.··················';

  @override
  String get failureOnlyFilesInsideAProjectFolderCan =>
      'Ónly fílés ínsídé á prójéct fóldér cán bé rémóvéd fór góód.·····················';

  @override
  String get failureLeaveTheFileInPlaceThePurge =>
      'Léávé thé fílé ín plácé; thé púrgé wíll skíp ít.·················';

  @override
  String get failureThatPhotoHasNoUsableNameFor =>
      'Thát phótó hás nó úsáblé námé fór íts cáchéd cópíés.···················';

  @override
  String get failureLeaveThePhotoInPlaceThePurge =>
      'Léávé thé phótó ín plácé; thé púrgé wíll skíp ít.··················';

  @override
  String get failureADeletedRecordSFilesCouldNot =>
      'Á délétéd récórd’s fílés cóúld nót bé rémóvéd fróm thís dévícé.·······················';

  @override
  String get failureAllowStorageAccessThePurgeTriesAgain =>
      'Állów stórágé áccéss; thé púrgé tríés ágáín néxt láúnch.····················';

  @override
  String get failureThisExportIsTooLargeForThis =>
      'Thís éxpórt ís tóó lárgé fór thís brówsér.···············';

  @override
  String get failureExportFewerRecordsOrUseADesktop =>
      'Éxpórt féwér récórds ór úsé á désktóp dévícé.················';

  @override
  String failureAnExportSourceIsMissingValue(String value0) {
    return 'Án éxpórt sóúrcé ís míssíng: ···········$value0';
  }

  @override
  String get failureANativeFileSystemIsUnavailable =>
      'Á nátívé fílé systém ís únáváíláblé.·············';

  @override
  String failureTaptureCouldNotReadValue(String value0) {
    return 'Táptúré cóúld nót réád ·········$value0.';
  }

  @override
  String get failureCaptureOrAddTheFileAgainThen =>
      'Cáptúré ór ádd thé fílé ágáín, thén try ágáín.·················';

  @override
  String get failureThatProjectIsNoLongerOnThis =>
      'Thát prójéct ís nó lóngér ón thís dévícé.···············';

  @override
  String get failureOpenAProjectThenTryAgain =>
      'Ópén á prójéct, thén try ágáín.···········';

  @override
  String get failureRecreateTheProjectFolderThenTryAgain =>
      'Récréáté thé prójéct fóldér, thén try ágáín.················';

  @override
  String failureTheFileValueIsEmpty(String value0) {
    return 'Thé fílé ····$value0 ís émpty.····';
  }

  @override
  String get failureChooseAFileThatHasContentsAnd =>
      'Chóósé á fílé thát hás cónténts ánd try ágáín.·················';

  @override
  String failureTheFileValueIsNotASupported(String value0) {
    return 'Thé fílé ····$value0 ís nót á súppórtéd typé.·········';
  }

  @override
  String get failureChooseAnImageDocumentSpreadsheetAudioFile =>
      'Chóósé án ímágé, dócúmént, spréádshéét, áúdíó fílé ór búndlé ánd try ágáín.···························';

  @override
  String failureTheFileValueDoesNotMatchIts(String value0) {
    return 'Thé fílé ····$value0 dóés nót mátch íts typé.·········';
  }

  @override
  String get failureChooseAFileOfTheExpectedType =>
      'Chóósé á fílé óf thé éxpéctéd typé ánd try ágáín.··················';

  @override
  String failureTheFileValueIsLargerThanThe(String value0, String value1) {
    return 'Thé fílé ····$value0 ís lárgér thán thé állówéd sízé fór á ··············$value1.';
  }

  @override
  String get failureChooseASmallerFileAndTryAgain =>
      'Chóósé á smállér fílé ánd try ágáín.·············';

  @override
  String failureTheArchiveValueContainsAPathThat(String value0) {
    return 'Thé árchívé ·····$value0 cóntáíns á páth thát léávés thé fóldér.··············';
  }

  @override
  String get failureChooseADifferentFileAndTryAgain =>
      'Chóósé á dífférént fílé ánd try ágáín.··············';

  @override
  String failureTheArchiveValueContainsALinkInstead(String value0) {
    return 'Thé árchívé ·····$value0 cóntáíns á línk ínstéád óf á fílé.·············';
  }

  @override
  String failureTheArchiveValueDeclaresMoreUncompressedData(String value0) {
    return 'Thé árchívé ·····$value0 déclárés móré úncómprésséd dátá thán ís állówéd.··················';
  }

  @override
  String failureTheFileValueIsNotAnArchive(String value0) {
    return 'Thé fílé ····$value0 ís nót án árchívé.·······';
  }

  @override
  String get failureChooseAZIPBundleOrSpreadsheetAnd =>
      'Chóósé á ZÍP búndlé ór spréádshéét ánd try ágáín.··················';

  @override
  String get failureChooseTheFileAgainThenTryAgain =>
      'Chóósé thé fílé ágáín, thén try ágáín.··············';

  @override
  String get failureThePhotoCouldNotBeSavedOn =>
      'Thé phótó cóúld nót bé sávéd ón thís dévícé.················';

  @override
  String failureThereIsNotEnoughSpaceToSave(String value0) {
    return 'Théré ís nót énóúgh spácé tó sávé ············$value0.';
  }

  @override
  String get failureAllowStorageAccessThenTryAgain =>
      'Állów stórágé áccéss, thén try ágáín.·············';

  @override
  String get failureThisPhotoCannotBeMarked =>
      'Thís phótó cánnót bé márkéd.··········';

  @override
  String get failureThisPackageIsTooLargeOrIncomplete =>
      'Thís páckágé ís tóó lárgé ór íncómplété.··············';

  @override
  String get failureFinishTheCurrentPackageBeforeOpeningAnother =>
      'Fínísh thé cúrrént páckágé béfóré ópéníng ánóthér.··················';

  @override
  String get failureThisPackageIsTooLargeToOpen =>
      'Thís páckágé ís tóó lárgé tó ópén.············';

  @override
  String get failureThisPackageCouldNotBeOpened =>
      'Thís páckágé cóúld nót bé ópénéd.············';

  @override
  String get failureOpenTheFileAgainFromItsOriginal =>
      'Ópén thé fílé ágáín fróm íts órígínál lócátíón.·················';

  @override
  String get failureThatProjectCouldNotBeScanned =>
      'Thát prójéct cóúld nót bé scánnéd.············';

  @override
  String get failureOpenTheProjectAndTryAgain =>
      'Ópén thé prójéct ánd try ágáín.···········';

  @override
  String get failureTheProjectFolderCouldNotBeScanned =>
      'Thé prójéct fóldér cóúld nót bé scánnéd ón thís dévícé.····················';

  @override
  String get failurePutTheFileBackInTheProject =>
      'Pút thé fílé báck ín thé prójéct fóldér, thén try ágáín.····················';

  @override
  String get failureTheFileCouldNotBeAdoptedOn =>
      'Thé fílé cóúld nót bé ádóptéd ón thís dévícé.················';

  @override
  String get failureTheMissingFileCouldNotBeFlagged =>
      'Thé míssíng fílé cóúld nót bé flággéd ón thís dévícé.···················';

  @override
  String get failureThatFileRowIsNoLongerOn =>
      'Thát fílé rów ís nó lóngér ón thís dévícé.···············';

  @override
  String get failureThatNameIsNotAValidFolder =>
      'Thát námé ís nót á válíd fóldér.············';

  @override
  String get failureChooseANameWithoutSlashesThatPoint =>
      'Chóósé á námé wíthóút sláshés thát póínt élséwhéré.··················';

  @override
  String get failureChooseANameWithLettersOrDigits =>
      'Chóósé á námé wíth léttérs ór dígíts.·············';

  @override
  String get failureTheFilePathMustStayInsideThe2 =>
      'Thé fílé páth múst stáy ínsídé thé stórágé fóldér.··················';

  @override
  String get failureThatPhotoIsNoLongerAvailable =>
      'Thát phótó ís nó lóngér áváíláblé.············';

  @override
  String get failureHiddenAreasChangedTrySendingAgain =>
      'Híddén áréás chángéd. Try séndíng ágáín.··············';

  @override
  String get failureCheckTheHiddenAreasOnThisEdited =>
      'Chéck thé híddén áréás ón thís édítéd phótó béfóré séndíng ít.······················';

  @override
  String get failureOpenHidePartsBeforeSendingAndSave =>
      'Ópén Hídé párts béfóré séndíng ánd sávé thé áréás fór thís vérsíón.························';

  @override
  String get failureTheProjectFolderCouldNotBeRemoved =>
      'Thé prójéct fóldér cóúld nót bé rémóvéd fróm thís dévícé.····················';

  @override
  String get failureDeleteTheLeftoverFolderThenTryAgain =>
      'Délété thé léftóvér fóldér, thén try ágáín.················';

  @override
  String get failureThatProjectIsAlreadyInTheRecycle =>
      'Thát prójéct ís álréády ín thé récyclé áréá ón thís dévícé.·····················';

  @override
  String get failureRestoreItFromTheRecycleAreaThen =>
      'Réstóré ít fróm thé récyclé áréá, thén try ágáín.··················';

  @override
  String get failureTheProjectFolderCouldNotBeMoved =>
      'Thé prójéct fóldér cóúld nót bé móvéd tó thé récyclé áréá.·····················';

  @override
  String get failureThisProjectHasNoFolderOnDisk =>
      'Thís prójéct hás nó fóldér ón dísk yét.··············';

  @override
  String get failureCreateTheProjectFolderThenTryAgain =>
      'Créáté thé prójéct fóldér, thén try ágáín.···············';

  @override
  String get failureTheProjectFolderCouldNotBeCreated =>
      'Thé prójéct fóldér cóúld nót bé créátéd ón thís dévícé.····················';

  @override
  String get failureThatProjectFolderNameIsNotA =>
      'Thát prójéct fóldér námé ís nót á válíd fóldér.·················';

  @override
  String get failureRecreateTheProjectSoItsFolderCan =>
      'Récréáté thé prójéct só íts fóldér cán bé rébúílt.··················';

  @override
  String get failureThereIsNotEnoughFreeSpaceTo =>
      'Théré ís nót énóúgh fréé spácé tó táké ánóthér phótó.···················';

  @override
  String get failureExportAProjectOrCleanTheCache =>
      'Éxpórt á prójéct ór cléán thé cáché, thén try ágáín.···················';

  @override
  String get failureTaptureCouldNotReadFreeSpaceOn =>
      'Táptúré cóúld nót réád fréé spácé ón thís dévícé.··················';

  @override
  String get failureThisDeviceHasNoFolderTaptureCan =>
      'Thís dévícé hás nó fóldér Táptúré cán kéép prójéct fílés ín.·····················';

  @override
  String get failureUseTaptureOnAPhoneTabletOr =>
      'Úsé Táptúré ón á phóné, táblét ór cómpútér tó kéép fílés.····················';

  @override
  String get failureTheThumbnailCouldNotBeCreatedOn =>
      'Thé thúmbnáíl cóúld nót bé créátéd ón thís dévícé.··················';

  @override
  String get failureThatThumbnailSizeIsNotValid =>
      'Thát thúmbnáíl sízé ís nót válíd.············';

  @override
  String get failureUseTheAppThumbnailSizeAndTry =>
      'Úsé thé ápp thúmbnáíl sízé ánd try ágáín.···············';

  @override
  String get failureThatPhotoCouldNotBeCached =>
      'Thát phótó cóúld nót bé cáchéd.···········';

  @override
  String get failureLocationIsOffForThisProject =>
      'Lócátíón ís óff fór thís prójéct.············';

  @override
  String get failureTurnGPSOnThenTryAgain =>
      'Túrn GPS ón, thén try ágáín.··········';

  @override
  String get failureBiometricAuthenticationIsUnavailable =>
      'Bíómétríc áúthéntícátíón ís únáváíláblé.··············';

  @override
  String get failureUnlockWithYourAppPIN =>
      'Únlóck wíth yóúr ápp PÍN.·········';

  @override
  String get failureTheSecretCouldNotBeSavedOn =>
      'Thé sécrét cóúld nót bé sávéd ón thís dévícé.················';

  @override
  String get failureTheSecretCouldNotBeReadOn =>
      'Thé sécrét cóúld nót bé réád ón thís dévícé.················';

  @override
  String get failureTheSecretCouldNotBeRemovedFrom =>
      'Thé sécrét cóúld nót bé rémóvéd fróm thís dévícé.··················';

  @override
  String get failureTypeTheWordsToPlaceOnThis =>
      'Typé thé wórds tó plácé ón thís phótó.··············';

  @override
  String get failureEnterTextThenSaveThePhoto =>
      'Éntér téxt, thén sávé thé phótó.············';

  @override
  String get failureDiscardTheInterruptedSessionAndStartAgain =>
      'Díscárd thé íntérrúptéd séssíón ánd stárt ágáín.·················';

  @override
  String get failureOnlyARecordEditCanBeSaved =>
      'Ónly á récórd édít cán bé sávéd héré.·············';

  @override
  String get failureGoBackToTheProjectAndPick =>
      'Gó báck tó thé prójéct ánd píck ánóthér récórd.·················';

  @override
  String get failureTheCaptureSessionIsNotValid =>
      'Thé cáptúré séssíón ís nót válíd.············';

  @override
  String get failureCompletePhotoMetadataIsRequiredForA =>
      'Cómplété phótó métádátá ís réqúíréd fór á néw cáptúré.···················';

  @override
  String get failureThePhotoProjectWasNotFound =>
      'Thé phótó prójéct wás nót fóúnd.············';

  @override
  String get failureThatPhotoCouldNotBeReadFrom =>
      'Thát phótó cóúld nót bé réád fróm thís dévícé.·················';

  @override
  String get failureTheOriginalPhotoStaysInPlace =>
      'Thé órígínál phótó stáys ín plácé.············';

  @override
  String get failureRevertAnEditedPhotoInstead =>
      'Révért án édítéd phótó ínstéád.···········';

  @override
  String get failureThisPhotoAppearsMoreThanOnce =>
      'Thís phótó áppéárs móré thán óncé.············';

  @override
  String get failureReloadTheCaptureAndTryAgain =>
      'Rélóád thé cáptúré ánd try ágáín.············';

  @override
  String get failureAnEditedPhotoIsMissingItsOriginal =>
      'Án édítéd phótó ís míssíng íts órígínál.··············';

  @override
  String get failureKeepThisCaptureAndRestoreTheOriginal =>
      'Kéép thís cáptúré ánd réstóré thé órígínál phótó.··················';

  @override
  String get failureThesePhotoEditsLoopBackOnThemselves =>
      'Thésé phótó édíts lóóp báck ón thémsélvés.···············';

  @override
  String get failureThatFieldIsNotOnThisRecord =>
      'Thát fíéld ís nót ón thís récórd.············';

  @override
  String get failureOpenTheRecordAndTryAgain =>
      'Ópén thé récórd ánd try ágáín.···········';

  @override
  String get failureThatFieldIsNotAContextLevel =>
      'Thát fíéld ís nót á cóntéxt lévél.············';

  @override
  String get failurePickALevelFromTheHierarchyAnd =>
      'Píck á lévél fróm thé híérárchy ánd try ágáín.·················';

  @override
  String get failureAPresetNeedsAName => 'Á prését nééds á námé.········';

  @override
  String get failureEnterANameAndTryAgain =>
      'Éntér á námé ánd try ágáín.··········';

  @override
  String get failureADeleteNeedsAnIdAndA =>
      'Á délété nééds án íd ánd á réásón.············';

  @override
  String get failureContextIsNotAvailableYet =>
      'Cóntéxt ís nót áváíláblé yét.···········';

  @override
  String get failureRestartTheAppAndTryAgain =>
      'Réstárt thé ápp ánd try ágáín.···········';

  @override
  String get failureAPresetWithThatNameAlreadyExists =>
      'Á prését wíth thát námé álréády éxísts.··············';

  @override
  String get failureChooseAnotherNameOrConfirmOverwrite =>
      'Chóósé ánóthér námé, ór cónfírm óvérwríté.···············';

  @override
  String get failureTheProjectWasNotFound =>
      'Thé prójéct wás nót fóúnd.··········';

  @override
  String get failureAnExportedRecordIsNoLongerAvailable =>
      'Án éxpórtéd récórd ís nó lóngér áváíláblé.···············';

  @override
  String get failureAnExportedPhotoIsNoLongerAvailable =>
      'Án éxpórtéd phótó ís nó lóngér áváíláblé.···············';

  @override
  String get failureASelectedRecordIsMissingRefreshThe =>
      'Á séléctéd récórd ís míssíng. Réfrésh thé éxpórt.··················';

  @override
  String get failureAnExportNeedsAProject =>
      'Án éxpórt nééds á prójéct.··········';

  @override
  String get failureOpenAProjectAndExportAgain =>
      'Ópén á prójéct ánd éxpórt ágáín.············';

  @override
  String get failureThisExportedPhotoCannotBeRead =>
      'Thís éxpórtéd phótó cánnót bé réád.·············';

  @override
  String get failureThisPhotoFormatCannotBePackagedSafely =>
      'Thís phótó fórmát cánnót bé páckágéd sáfély.················';

  @override
  String get failureProjectFilesAreUnavailableOnThisDevice =>
      'Prójéct fílés áré únáváíláblé ón thís dévícé.················';

  @override
  String get failureOpenAProjectStoredOnThisDevice =>
      'Ópén á prójéct stóréd ón thís dévícé ánd try ágáín.··················';

  @override
  String get failureWriteYourFeedbackThenSaveAgain =>
      'Wríté yóúr féédbáck, thén sávé ágáín.·············';

  @override
  String get failureNameTheTypeThenSaveAgain =>
      'Námé thé typé, thén sávé ágáín.···········';

  @override
  String get failureChangeOrClearTheFiltersThenTry =>
      'Chángé ór cléár thé fíltérs, thén try ágáín.················';

  @override
  String get failureCloseThisTapFeedbackThenTryAgain =>
      'Clósé thís, táp Féédbáck, thén try ágáín.···············';

  @override
  String get failureCorrectTheHighlightedFieldAndSaveAgain =>
      'Córréct thé híghlíghtéd fíéld ánd sávé ágáín.················';

  @override
  String get failureTheTemplateTheseRowsWereMatchedTo =>
      'Thé témpláté thésé róws wéré mátchéd tó ís nó lóngér héré.·····················';

  @override
  String get failureChooseAnotherTemplateAndImportAgain =>
      'Chóósé ánóthér témpláté ánd ímpórt ágáín.···············';

  @override
  String get failureARecordARowMatchedIsNo =>
      'Á récórd á rów mátchéd ís nó lóngér ón thís dévícé.··················';

  @override
  String get failureImportTheFileAgainToMatchIt =>
      'Ímpórt thé fílé ágáín tó mátch ít áfrésh.···············';

  @override
  String get failureRecordsCannotBeImportedRightNow =>
      'Récórds cánnót bé ímpórtéd ríght nów.·············';

  @override
  String get failureRestartTaptureThenImportAgain =>
      'Réstárt Táptúré, thén ímpórt ágáín.·············';

  @override
  String get failureThatFileIsNotInThisMeeting =>
      'Thát fílé ís nót ín thís méétíng’s prójéct fóldér.··················';

  @override
  String get failureAddTheFileToTheMeetingAgain =>
      'Ádd thé fílé tó thé méétíng ágáín.············';

  @override
  String get failureStartTheMeetingAgain => 'Stárt thé méétíng ágáín.·········';

  @override
  String get failureTheSnapshotHasBeenPurged =>
      'Thé snápshót hás béén púrgéd.···········';

  @override
  String get failureTheMergeCanNoLongerBeUndone =>
      'Thé mérgé cán nó lóngér bé úndóné.············';

  @override
  String get failureTaptureCouldNotLookUpAFile =>
      'Táptúré cóúld nót lóók úp á fílé fór thís prójéct.··················';

  @override
  String get failureAProjectWithThatIdAlreadyExists =>
      'Á prójéct wíth thát íd álréády éxísts.··············';

  @override
  String get failureOpenTheExistingProjectOrUseA =>
      'Ópén thé éxístíng prójéct ór úsé á néw íd.···············';

  @override
  String get failureProjectPhotosCannotBeStoredOnThis =>
      'Prójéct phótós cánnót bé stóréd ón thís dévícé.·················';

  @override
  String get failureAddThePhotoOnADeviceThat =>
      'Ádd thé phótó ón á dévícé thát stórés fílés.················';

  @override
  String get failureAProjectNeedsAName => 'Á prójéct nééds á námé.·········';

  @override
  String get failureEnterANameAndSaveAgain =>
      'Éntér á námé ánd sávé ágáín.··········';

  @override
  String get failureProjectFilesAreNotAvailableOnThis =>
      'Prójéct fílés áré nót áváíláblé ón thís dévícé.·················';

  @override
  String get failureExportFromADeviceThatStoresThis =>
      'Éxpórt fróm á dévícé thát stórés thís prójéct.·················';

  @override
  String get failureThatRecordIsNoLongerInThe =>
      'Thát récórd ís nó lóngér ín thé récyclé bín.················';

  @override
  String get failureNothingToRemoveItWasRestoredOr =>
      'Nóthíng tó rémóvé; ít wás réstóréd ór álréády rémóvéd.···················';

  @override
  String get failureThatRecordWasDeletedAgainSoIts =>
      'Thát récórd wás délétéd ágáín, só íts réténtíón stárts óvér.·····················';

  @override
  String get failureLeaveItThePurgeTakesItOnce =>
      'Léávé ít; thé púrgé tákés ít óncé íts néw wíndów pássés.····················';

  @override
  String get failureAMergeStillNeedsThatDeletedRecord =>
      'Á mérgé stíll nééds thát délétéd récórd.··············';

  @override
  String get failureSendABundleOrSettleTheMerge =>
      'Sénd á búndlé ór séttlé thé mérgé, thén try ágáín.··················';

  @override
  String get failureRecordsAreNotAvailableYet =>
      'Récórds áré nót áváíláblé yét.···········';

  @override
  String get failureTheRecordWasSavedButCouldNot =>
      'Thé récórd wás sávéd bút cóúld nót bé ópénéd.················';

  @override
  String get failureOpenItFromTheRecordsList =>
      'Ópén ít fróm thé récórds líst.···········';

  @override
  String get failureThatTemplateIsNoLongerOnThis =>
      'Thát témpláté ís nó lóngér ón thís dévícé.···············';

  @override
  String get failureChooseAnotherTemplateAndTryAgain =>
      'Chóósé ánóthér témpláté ánd try ágáín.··············';

  @override
  String get failureThisRecordAlreadyUsesThatTemplate =>
      'Thís récórd álréády úsés thát témpláté.··············';

  @override
  String get failureChooseADifferentTemplate =>
      'Chóósé á dífférént témpláté.··········';

  @override
  String get failureThatTemplateBelongsToAnotherProject =>
      'Thát témpláté bélóngs tó ánóthér prójéct.···············';

  @override
  String get failureChooseATemplateFromThisProject =>
      'Chóósé á témpláté fróm thís prójéct.·············';

  @override
  String get failureARecordNeedsAProjectAndA =>
      'Á récórd nééds á prójéct ánd á témpláté.··············';

  @override
  String get failureChooseAProjectAndATemplateThen =>
      'Chóósé á prójéct ánd á témpláté, thén sávé ágáín.··················';

  @override
  String get failureSayWhyTheRecordShouldGoThen =>
      'Sáy why thé récórd shóúld gó, thén try ágáín.················';

  @override
  String get failureAnEditNeedsTheFieldItChanges =>
      'Án édít nééds thé fíéld ít chángés.·············';

  @override
  String get failureChooseAFieldThenSaveAgain =>
      'Chóósé á fíéld, thén sávé ágáín.············';

  @override
  String get failureARecordGoesToTheRecycleBin =>
      'Á récórd góés tó thé récyclé bín ónly thróúgh délété.···················';

  @override
  String get failureUseDeleteWhichLetsYouUndoIt =>
      'Úsé Délété, whích léts yóú úndó ít.·············';

  @override
  String get failureThisRecordIsInTheRecycleBin =>
      'Thís récórd ís ín thé récyclé bín.············';

  @override
  String get failureRestoreItFromTheRecycleBinFirst =>
      'Réstóré ít fróm thé récyclé bín fírst.··············';

  @override
  String get failureThisRecordIsNotInTheRecycle =>
      'Thís récórd ís nót ín thé récyclé bín.··············';

  @override
  String get failureRefreshTheListItMayAlreadyBe =>
      'Réfrésh thé líst; ít máy álréády bé réstóréd.················';

  @override
  String get failureThisRecordHasAStatusThisVersion =>
      'Thís récórd hás á státús thís vérsíón óf thé ápp dóés nót knów.·······················';

  @override
  String get failureUpdateTheAppThenTryAgain =>
      'Úpdáté thé ápp, thén try ágáín.···········';

  @override
  String failureThisRecordIsAlreadyValue(String value0) {
    return 'Thís récórd ís álréády ·········$value0.';
  }

  @override
  String get failureChooseADifferentStatusOrLeaveIt =>
      'Chóósé á dífférént státús, ór léávé ít ás ít ís.·················';

  @override
  String failureARecordThatIsValueCannotBe(String value0, String value1) {
    return 'Á récórd thát ís ······$value0 cánnót bé ····$value1.';
  }

  @override
  String get failureRestoreItFromTheRecycleBinBefore =>
      'Réstóré ít fróm thé récyclé bín béfóré chángíng ít.··················';

  @override
  String get failureTheCapturedTemplateVersionIsUnavailable =>
      'Thé cáptúréd témpláté vérsíón ís únáváíláblé.················';

  @override
  String get failureRestoreTheOriginalProjectPackageBeforeEditing =>
      'Réstóré thé órígínál prójéct páckágé béfóré édítíng thésé válúés.·······················';

  @override
  String get failureAQuotedCSVValueIsUnfinished =>
      'Á qúótéd CSV válúé ís únfíníshéd.············';

  @override
  String get failureCloseTheQuotedValueAndImportThe =>
      'Clósé thé qúótéd válúé ánd ímpórt thé fílé ágáín.··················';

  @override
  String get failureThatFileIsEmpty => 'Thát fílé ís émpty.·······';

  @override
  String get failureChooseACSVWithAHeaderAnd =>
      'Chóósé á CSV wíth á héádér ánd róws.·············';

  @override
  String get failureThatTableCouldNotBeReadAs =>
      'Thát táblé cóúld nót bé réád ás téxt.·············';

  @override
  String get failureSaveItAsUTFCSVAndTry =>
      'Sávé ít ás ÚTF-8 CSV ánd try ágáín.·············';

  @override
  String get failureThatCSVCouldNotBeRead =>
      'Thát CSV cóúld nót bé réád.··········';

  @override
  String get failureCheckTheFileAndTryAgain =>
      'Chéck thé fílé ánd try ágáín.···········';

  @override
  String get failureChooseACSVJSONOrXLSXTable =>
      'Chóósé á CSV, JSÓN ór XLSX táblé wíthín thé ímpórt sízé límít.······················';

  @override
  String get failureChooseAnotherFileOrSplitThisTable =>
      'Chóósé ánóthér fílé ór splít thís táblé íntó smállér fílés.·····················';

  @override
  String get failureSaveItAsUTFCSVOrA =>
      'Sávé ít ás ÚTF-8 CSV ór á JSÓN árráy ánd try ágáín.··················';

  @override
  String get failureJSONDatasetsMustBeAnArrayOf =>
      'JSÓN dátáséts múst bé án árráy óf óbjécts.···············';

  @override
  String get failureWrapTheRowsInAnArrayAnd =>
      'Wráp thé róws ín án árráy ánd try ágáín.··············';

  @override
  String get failureEveryJSONRowMustBeAnObject =>
      'Évéry JSÓN rów múst bé án óbjéct.············';

  @override
  String get failureRemoveNonObjectRowsAndImportThe =>
      'Rémóvé nón-óbjéct róws ánd ímpórt thé fílé ágáín.··················';

  @override
  String get failureThatFileHasNoColumns =>
      'Thát fílé hás nó cólúmns.·········';

  @override
  String get failureAddKeysToTheObjectsAndTry =>
      'Ádd kéys tó thé óbjécts ánd try ágáín.··············';

  @override
  String get failureThatJSONIsNotValid => 'Thát JSÓN ís nót válíd.·········';

  @override
  String get failureFixTheJSONArrayAndImportIt =>
      'Fíx thé JSÓN árráy ánd ímpórt ít ágáín.··············';

  @override
  String get failureThatJSONCouldNotBeRead =>
      'Thát JSÓN cóúld nót bé réád.··········';

  @override
  String get failureThatWorkbookHasNoSheets =>
      'Thát wórkbóók hás nó shééts.··········';

  @override
  String get failureChooseAWorkbookWithASheetOf =>
      'Chóósé á wórkbóók wíth á shéét óf dátá.··············';

  @override
  String get failureThatSheetHasNoHeaderRow =>
      'Thát shéét hás nó héádér rów.···········';

  @override
  String get failureAddAHeaderRowAndTryAgain =>
      'Ádd á héádér rów ánd try ágáín.···········';

  @override
  String get failureThatKeyColumnHasDuplicateValues =>
      'Thát kéy cólúmn hás dúplícáté válúés.·············';

  @override
  String get failurePickAnotherKeyColumnOrConfirmDuplicates =>
      'Píck ánóthér kéy cólúmn, ór cónfírm dúplícátés áré éxpéctéd.·····················';

  @override
  String get failureARowNeedsADatasetAndA =>
      'Á rów nééds á dátásét ánd á kéy.············';

  @override
  String get failureFillThoseFieldsAndSaveAgain =>
      'Fíll thósé fíélds ánd sávé ágáín.············';

  @override
  String get failureADatasetNeedsANameAndA =>
      'Á dátásét nééds á námé ánd á kéy cólúmn.··············';

  @override
  String get failureTheKeyColumnMustBeOneOf =>
      'Thé kéy cólúmn múst bé óné óf thé dátásét cólúmns.··················';

  @override
  String get failurePickAKeyFromTheColumnList =>
      'Píck á kéy fróm thé cólúmn líst.············';

  @override
  String get failureReferenceDataIsNotAvailableYet =>
      'Référéncé dátá ís nót áváíláblé yét.·············';

  @override
  String get failureThatTableHasNoDataColumns =>
      'Thát táblé hás nó dátá cólúmns.···········';

  @override
  String get failureATemplateNeedsAName => 'Á témpláté nééds á námé.·········';

  @override
  String get failureOpenAProjectThenAddTheTemplate =>
      'Ópén á prójéct, thén ádd thé témpláté.··············';

  @override
  String get failureTheShippedTemplatesCouldNotBeRead =>
      'Thé shíppéd témplátés cóúld nót bé réád.··············';

  @override
  String get failureThatShippedTemplateIsNotOnThis =>
      'Thát shíppéd témpláté ís nót ón thís dévícé.················';

  @override
  String get failurePickAnotherTemplateFromTheLibrary =>
      'Píck ánóthér témpláté fróm thé líbráry.··············';

  @override
  String get failureTheInheritedFieldGroupsCouldNotBe =>
      'Thé ínhérítéd fíéld gróúps cóúld nót bé réád.················';

  @override
  String failureAShippedTemplateIsMissingValue(String value0) {
    return 'Á shíppéd témpláté ís míssíng \"···········$value0\".';
  }

  @override
  String get failureReinstallTheAppThenTryAgain =>
      'Réínstáll thé ápp, thén try ágáín.············';

  @override
  String get failureAShippedTemplateUsesAnUnknownSchema =>
      'Á shíppéd témpláté úsés án únknówn schémá.···············';

  @override
  String get failureAShippedTemplateHasAnInvalidKey =>
      'Á shíppéd témpláté hás án ínválíd kéy.··············';

  @override
  String get failureAShippedTemplateNameIsNotA =>
      'Á shíppéd témpláté námé ís nót á lócálísátíón kéy.··················';

  @override
  String get failureAShippedTemplateNamesAnUnknownIdentity =>
      'Á shíppéd témpláté námés án únknówn ídéntíty fíéld.··················';

  @override
  String get failureAShippedTemplateNamesAnUnknownParent =>
      'Á shíppéd témpláté námés án únknówn párént.················';

  @override
  String get failureAShippedTemplateNamesAnUnknownField =>
      'Á shíppéd témpláté námés án únknówn fíéld gróúp.·················';

  @override
  String failureAShippedFieldIsMissingValue(String value0) {
    return 'Á shíppéd fíéld ís míssíng \"··········$value0\".';
  }

  @override
  String get failureAShippedFieldUsesAnUnknownType =>
      'Á shíppéd fíéld úsés án únknówn typé.·············';

  @override
  String get failureAShippedFieldLabelIsNotA =>
      'Á shíppéd fíéld lábél ís nót á lócálísátíón kéy.·················';

  @override
  String get failureAShippedTemplateCouldNotBeRead =>
      'Á shíppéd témpláté cóúld nót bé réád.·············';

  @override
  String get failureAShippedTemplateNamesAnUnknownRecord =>
      'Á shíppéd témpláté námés án únknówn récórd typé.·················';

  @override
  String get failureTheTemplateOrItsRecordsChangedWhile =>
      'Thé témpláté ór íts récórds chángéd whílé yóú révíéwéd thé mígrátíón.·························';

  @override
  String get failureReviewTheUpdatedChangesAndTryAgain =>
      'Révíéw thé úpdátéd chángés ánd try ágáín.···············';

  @override
  String get failureAFieldNeedsAKey => 'Á fíéld nééds á kéy.·······';

  @override
  String get failureGiveEveryFieldAKeyAndSave =>
      'Gívé évéry fíéld á kéy ánd sávé ágáín.··············';

  @override
  String get failureEachFieldKeyMustBeUniqueOn =>
      'Éách fíéld kéy múst bé úníqúé ón á témpláté.················';

  @override
  String get failureRenameTheDuplicateKeyAndSaveAgain =>
      'Rénámé thé dúplícáté kéy ánd sávé ágáín.··············';

  @override
  String get failureThatValueIsNotText => 'Thát válúé ís nót téxt.·········';

  @override
  String get failureEnterTextOrLeaveTheFieldEmpty =>
      'Éntér téxt, ór léávé thé fíéld émpty.·············';

  @override
  String get failureThatValueIsNotAWholeNumber =>
      'Thát válúé ís nót á whólé númbér.············';

  @override
  String get failureEnterAWholeNumberOrLeaveThe =>
      'Éntér á whólé númbér, ór léávé thé fíéld émpty.·················';

  @override
  String get failureThatValueIsNotANumber =>
      'Thát válúé ís nót á númbér.··········';

  @override
  String get failureEnterANumberOrLeaveTheField =>
      'Éntér á númbér, ór léávé thé fíéld émpty.···············';

  @override
  String get failureThatNumberIsOutsideTheAllowedRange =>
      'Thát númbér ís óútsídé thé állówéd rángé.···············';

  @override
  String get failureEnterANumberInsideTheRangeOr =>
      'Éntér á númbér ínsídé thé rángé, ór léávé thé fíéld émpty.·····················';

  @override
  String get failureThatValueIsShorterThanThisField =>
      'Thát válúé ís shórtér thán thís fíéld állóws.················';

  @override
  String get failureEnterALongerValueOrLeaveThe =>
      'Éntér á lóngér válúé, ór léávé thé fíéld émpty.·················';

  @override
  String get failureThatValueIsLongerThanThisField =>
      'Thát válúé ís lóngér thán thís fíéld állóws.················';

  @override
  String get failureShortenTheValueOrLeaveTheField =>
      'Shórtén thé válúé, ór léávé thé fíéld émpty.················';

  @override
  String get failureThatValueDoesNotMatchTheExpected =>
      'Thát válúé dóés nót mátch thé éxpéctéd páttérn.·················';

  @override
  String get failureEnterAValueInTheExpectedForm =>
      'Éntér á válúé ín thé éxpéctéd fórm, ór léávé thé fíéld émpty.······················';

  @override
  String get failureThisFieldSPatternIsNotValid =>
      'Thís fíéld\'s páttérn ís nót válíd.·············';

  @override
  String get failureOpenTheTemplateAndCorrectTheField =>
      'Ópén thé témpláté ánd córréct thé fíéld\'s páttérn.··················';

  @override
  String get failureThatValueIsNotADate => 'Thát válúé ís nót á dáté.·········';

  @override
  String get failureEnterACalendarDateOrLeaveThe =>
      'Éntér á cáléndár dáté, ór léávé thé fíéld émpty.·················';

  @override
  String get failureThatValueIsNotATimeOf =>
      'Thát válúé ís nót á tímé óf dáy.············';

  @override
  String get failureEnterATimeOrLeaveTheField =>
      'Éntér á tímé, ór léávé thé fíéld émpty.··············';

  @override
  String get failureThatValueIsNotADateAnd =>
      'Thát válúé ís nót á dáté ánd tímé.············';

  @override
  String get failureEnterADateAndTimeOrLeave =>
      'Éntér á dáté ánd tímé, ór léávé thé fíéld émpty.·················';

  @override
  String get failureThatValueIsNotAYesOr =>
      'Thát válúé ís nót á yés ór nó.···········';

  @override
  String get failureSwitchTheFieldOnOrOffOr =>
      'Swítch thé fíéld ón ór óff, ór léávé ít únsét.·················';

  @override
  String get failureThatValueIsNotAChoice =>
      'Thát válúé ís nót á chóícé.··········';

  @override
  String get failurePickAnOptionFromTheListOr =>
      'Píck án óptíón fróm thé líst, ór léávé thé fíéld émpty.····················';

  @override
  String get failureThatChoiceIsNotOnTheList =>
      'Thát chóícé ís nót ón thé líst.···········';

  @override
  String get failureThatValueIsNotAFilePath =>
      'Thát válúé ís nót á fílé páth.···········';

  @override
  String get failureAttachAFileOrLeaveTheField =>
      'Áttách á fílé, ór léávé thé fíéld émpty.··············';

  @override
  String get failureThatValueIsNotALocation =>
      'Thát válúé ís nót á lócátíón.···········';

  @override
  String get failureCaptureAGPSFixOrLeaveThe =>
      'Cáptúré á GPS fíx, ór léávé thé fíéld émpty.················';

  @override
  String get failureThatLocationIsOutsideTheEarth =>
      'Thát lócátíón ís óútsídé thé éárth.·············';

  @override
  String get failureCaptureAGPSFixAgainOrLeave =>
      'Cáptúré á GPS fíx ágáín, ór léávé thé fíéld émpty.··················';

  @override
  String get failureThisFieldTypeHasNoEditorOn =>
      'Thís fíéld typé hás nó édítór ón thís scréén.················';

  @override
  String get failureOpenTheTemplateAndPickAType =>
      'Ópén thé témpláté ánd píck á typé thís scréén súppórts.····················';

  @override
  String get failureConfirmConsentWithTheNamedOperator =>
      'Cónfírm cónsént wíth thé náméd ópérátór.··············';

  @override
  String get failureThatFieldTypeIsNotRecognised =>
      'Thát fíéld typé ís nót récógníséd.············';

  @override
  String get failurePickATypeFromTheListAnd =>
      'Píck á typé fróm thé líst ánd sávé ágáín.···············';

  @override
  String get failureThatInputModeIsNotRecognised =>
      'Thát ínpút módé ís nót récógníséd.············';

  @override
  String get failurePickAnInputModeFromTheList =>
      'Píck án ínpút módé fróm thé líst ánd sávé ágáín.·················';

  @override
  String get failureTheSuggestedOrderCouldNotBeRead =>
      'Thé súggéstéd órdér cóúld nót bé réád.··············';

  @override
  String get failureUseTheOnDeviceResultsOrTry =>
      'Úsé thé ón-dévícé résúlts ór try ágáín.··············';

  @override
  String get failureOpenTheTemplateListAndTryAgain =>
      'Ópén thé témpláté líst ánd try ágáín.·············';

  @override
  String get failureTheDailyAnalysisLimitIsReached =>
      'Thé dáíly ánálysís límít ís réáchéd.·············';

  @override
  String get failureUseTheOnDeviceSuggestionsOrTry =>
      'Úsé thé ón-dévícé súggéstíóns ór try tómórrów.·················';

  @override
  String get failureExportProtectionsAreUnavailableOnThisDevice =>
      'Éxpórt prótéctíóns áré únáváíláblé ón thís dévícé.··················';

  @override
  String processingDailyCap(int cap, String resetDay) {
    return 'Tódáy\'s límít óf ·······$cap ónlíné réqúésts ís úséd. Ít réséts át 00:00 ÚTC ón ···················$resetDay.';
  }

  @override
  String get processingDailyResetRecovery =>
      'Prócéssíng wíll bé áváíláblé áftér thé dáíly rését.··················';

  @override
  String get bundlePasswordInvalid =>
      'Thát pásswórd díd nót ópén thé búndlé.··············';

  @override
  String get bundlePasswordInvalidRecovery =>
      'Try thé pásswórd ágáín. Nóthíng wás éxtráctéd.·················';

  @override
  String get incomingBundleBusy =>
      'Fínísh thé cúrrént páckágé béfóré ópéníng ánóthér.··················';

  @override
  String get incomingBundleTooLarge =>
      'Thís páckágé ís tóó lárgé tó ópén.············';

  @override
  String get incomingBundleIncomplete =>
      'Thís páckágé ís tóó lárgé ór íncómplété.··············';

  @override
  String get incomingBundleUnreadable =>
      'Thís páckágé cóúld nót bé ópénéd.············';

  @override
  String get incomingBundleUnreadableRecovery =>
      'Ópén thé fílé ágáín fróm íts órígínál lócátíón.·················';

  @override
  String get biometricUnavailable =>
      'Bíómétríc áúthéntícátíón ís únáváíláblé.··············';

  @override
  String get biometricPinRecovery => 'Únlóck wíth yóúr ápp PÍN.·········';

  @override
  String get appLockStorageUnavailable =>
      'Thé ápp lóck cóúld nót bé réád ón thís dévícé.·················';

  @override
  String get appLockStorageRecovery =>
      'Try únlóckíng ágáín whén sécúré stórágé ís áváíláblé.···················';

  @override
  String get cloudDestinationSaveFailed =>
      'Thé déstínátíón cóúld nót bé sávéd.·············';

  @override
  String get cloudDestinationMissing =>
      'Thát déstínátíón ís nó lóngér lístéd.·············';

  @override
  String get cloudRefreshDestinations => 'Réfrésh thé líst.······';

  @override
  String get cloudUploadRecordFailed =>
      'Thé úplóád cóúld nót bé récórdéd.············';

  @override
  String get cloudUploadHistoryUpdateFailed =>
      'Thé úplóád hístóry cóúld nót bé úpdátéd.··············';

  @override
  String get cloudUploadHistoryUpdateRecovery =>
      'Thé fílé ón thís dévícé wás nót chángéd.··············';

  @override
  String get cloudUploadConfirmationRequired =>
      'Cónfírm thís úplóád béfóré ít cán stárt.··············';

  @override
  String get cloudUploadConfirmationRecovery =>
      'Révíéw thé fílé ánd cónfírm ít.···········';

  @override
  String get cloudUploadHistoryMissing =>
      'Thát úplóád ís nó lóngér ín thé hístóry.··············';

  @override
  String get cloudUploadRestartRecovery => 'Stárt thé úplóád ágáín.·········';

  @override
  String get settingsPreferenceUnsupported =>
      'Thát préféréncé cánnót bé stóréd.············';

  @override
  String get settingsPreferenceUnsupportedRecovery =>
      'Chóósé á súppórtéd válúé ánd sávé ágáín.··············';

  @override
  String get settingsPreferenceSaveFailed =>
      'Thé préféréncé cóúld nót bé sávéd ón thís dévícé.··················';

  @override
  String get settingsPreferenceSaveRecovery =>
      'Try ágáín. Yóúr lást chángé wás nót stóréd.················';

  @override
  String get privacyCaptureUnreadable =>
      'Thé sávéd cáptúré cóúld nót bé réád.·············';

  @override
  String get privacyCaptureRecover =>
      'Récóvér thé cáptúré ánd try ágáín.············';

  @override
  String get privacyProjectRequired =>
      'Ópén á prójéct béfóré rémóvíng íts lócátíón dátá.··················';

  @override
  String get privacyProjectRequiredRecovery =>
      'Chóósé á prójéct, thén try ágáín.············';

  @override
  String get cloudSignInChanged =>
      'Thís déstínátíón sígn-ín chángéd.············';

  @override
  String get cloudGoogleSignInRenewal =>
      'Thís Góóglé Drívé sígn-ín nééds rénéwál.··············';

  @override
  String get cloudSignInAgain => 'Sígn ín ágáín.·····';
}
