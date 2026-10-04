import 'package:intl/intl.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';

/// One place every visible catalogue string comes from, keyed by meaning
/// so translation can arrive later without touching a widget (FE-L10N-01,
/// FE-L10N-02, FE-L10N-03).
///
/// Template field labels, option lists and template names are user data and
/// never pass through here (FE-L10N-07).
/// Copy resolved against one app's inherited locale. User data passes unchanged.
final class LocalizedCopy {
  /// Uses the generated catalogue selected by the enclosing app.
  const LocalizedCopy(this._catalog);
  final AppLocalizations _catalog;
  String _withLocale(String Function() callback) =>
      Intl.withLocale<String>(_formatLocale, callback) as String;
  // intl ships en_US symbols before Flutter loads the other date tables. The
  // English audit fallback and pseudo locale must also work in headless stores.
  String get _formatLocale => switch (_catalog.localeName) {
    'en' || 'en_XA' => 'en_US',
    final String locale => locale,
  };

  /// Local image recognition has no browser implementation.
  String get ocrBrowserUnavailable => _catalog.ocrBrowserUnavailable;

  /// Stated absence when a value was not found.
  String get notDetected => _catalog.notDetected;

  /// How many records a list holds. Zero is a stated absence, not a blank.
  String recordsCount(int n) {
    return _catalog.recordsCount(n);
  }

  /// How many fields a template holds. Zero is a stated absence, not a blank.
  String fieldsCount(int n) {
    return _catalog.fieldsCount(n);
  }

  /// Clears the named field.
  String clearField(String label) => _catalog.clearField(label);

  /// Reveals a hidden field such as a PIN, named for its label.
  String showField(String label) => _catalog.showField(label);

  /// Hides a revealed field again, named for its label.
  String hideField(String label) => _catalog.hideField(label);

  /// The camera or photo library was refused.
  String get photoNoAccess => _catalog.photoNoAccess;

  /// The browser display picker was refused.
  String get displayNoAccess => _catalog.displayNoAccess;

  /// The device has no camera the app can open.
  String get photoNoCamera => _catalog.photoNoCamera;

  /// The picker failed for a reason it did not name.
  String get photoPickFailed => _catalog.photoPickFailed;

  /// The display picker failed for a reason it did not name.
  String get displayCaptureFailed => _catalog.displayCaptureFailed;

  /// Starts dictation into a field, named for its label.
  String dictateInto(String label) => _catalog.dictateInto(label);

  /// Stops dictation into a field, named for its label.
  String stopDictating(String label) => _catalog.stopDictating(label);

  /// The platform has no recogniser this app can reach.
  String get dictationUnavailable => _catalog.dictationUnavailable;

  /// The microphone was refused.
  String get dictationNoMicrophone => _catalog.dictationNoMicrophone;

  /// The recogniser heard nothing it could use.
  String get dictationNothingHeard => _catalog.dictationNothingHeard;

  /// The recogniser needs a connection it does not have.
  String get dictationNeedsConnection => _catalog.dictationNeedsConnection;

  /// Offline by choice, and this device cannot recognise speech locally.
  String get dictationOfflineOnly => _catalog.dictationOfflineOnly;

  /// The recogniser stopped for a reason it did not name.
  String get dictationFailed => _catalog.dictationFailed;

  /// A value filled in rather than typed.
  String get autoFilled => _catalog.autoFilled;

  /// A number outside the allowed range.
  String get outOfRange => _catalog.outOfRange;

  /// Selects every visible option in a multi-choice sheet.
  String get selectAll => _catalog.selectAll;

  /// Clears a selection or a field.
  String get clear => _catalog.clear;

  /// Dismisses the named chip.
  String dismissChip(String label) => _catalog.dismissChip(label);

  /// Dismisses a banner or other unnamed surface.
  String get dismiss => _catalog.dismiss;

  /// Backs out of a confirm dialog.
  String get cancel => _catalog.cancel;

  /// Acknowledges an alert.
  String get ok => _catalog.ok;

  /// Title of the unsaved-changes confirm.
  String get discardChangesTitle => _catalog.discardChangesTitle;

  /// Body of the unsaved-changes confirm.
  String get unsavedChanges => _catalog.unsavedChanges;

  /// Confirms discarding unsaved edits.
  String get discard => _catalog.discard;

  /// Heading over a list of invalid fields.
  String fixFields(int n) {
    return _catalog.fixFields(n);
  }

  /// One invalid field in a validation summary. [label] is template content.
  String fieldError(String label, String error) =>
      _catalog.fieldError(label, error);

  /// Label of a field that must be filled before Save.
  String fieldLabelRequired(String label) {
    return _catalog.fieldLabelRequired(label);
  }

  /// Label of a field that may be left empty.
  String fieldLabelOptional(String label) {
    return _catalog.fieldLabelOptional(label);
  }

  /// Announced summary of invalid fields.
  String validationAnnouncement(String heading, List<String> errors) {
    return _catalog.validationAnnouncement(heading, errors.join('. '));
  }

  /// Placeholder when a cached thumb file is missing.
  String get missingPhoto => _catalog.missingPhoto;

  /// Semantic name of a thumbnail's selection checkbox.
  String get photoSelect => _catalog.photoSelect;

  /// A stored photo's file could not be read for its thumbnail.
  String get photoUnreadable => _catalog.photoUnreadable;

  /// Recovery for [photoUnreadable].
  String get photoUnreadableRecovery => _catalog.photoUnreadableRecovery;

  /// Semantic name of a missing thumb, including its type.
  String missingPhotoNamed(String type) => _catalog.missingPhotoNamed(type);

  /// Fallback type name when a photo has none.
  String get photo => _catalog.photo;

  /// Crop action on the photo viewer.
  String get photoCrop => _catalog.photoCrop;

  /// Semantic name of a crop frame corner handle.
  String get photoCropCorner => _catalog.photoCropCorner;

  /// Semantic name of the crop frame body.
  String get photoCropFrame => _catalog.photoCropFrame;

  /// Rotate the visible photo a quarter turn.
  String get photoRotate => _catalog.photoRotate;

  /// Open freehand drawing.
  String get photoDraw => _catalog.photoDraw;

  /// Remove the latest stroke.
  String get photoUndoDraw => _catalog.photoUndoDraw;

  /// Remove every stroke.
  String get photoClearDraw => _catalog.photoClearDraw;

  /// Name of a markup ink, read beside its swatch (FE-A11Y-05).
  String markupInk(MarkupInk ink) {
    return switch (ink) {
      MarkupInk.red => _catalog.markupInk,
      MarkupInk.yellow => _catalog.markupInkYellow,
      MarkupInk.white => _catalog.markupInkWhite,
      MarkupInk.black => _catalog.markupInkBlack,
      MarkupInk.blue => _catalog.markupInkBlue,
      MarkupInk.green => _catalog.markupInkGreen,
    };
  }

  /// Label of the markup ink swatches.
  String get markupInkLabel => _catalog.markupInkLabel;

  /// Label of the markup size choice.
  String get markupSize => _catalog.markupSize;

  /// Switches the dark backing behind typed text on a photo.
  String get markupBacking => _catalog.markupBacking;

  /// What the dark backing does.
  String get markupBackingDescription => _catalog.markupBackingDescription;

  /// How to place typed text on a photo.
  String get markupTypeHint => _catalog.markupTypeHint;

  /// The thinnest stroke or smallest text.
  String get markupSizeSmall => _catalog.markupSizeSmall;

  /// The middle stroke or text size.
  String get markupSizeMedium => _catalog.markupSizeMedium;

  /// The thickest stroke or largest text.
  String get markupSizeLarge => _catalog.markupSizeLarge;

  /// How many photos are in the tray.
  String capturePhotoCount(int count) => _catalog.capturePhotoCount(count);

  /// Badge while a photo is still being prepared.
  String get capturePhotoProcessing => _catalog.capturePhotoProcessing;

  /// Clears a derived crop or typed copy.
  String get photoRevert => _catalog.photoRevert;

  /// The preview's caption line when a photo has none.
  String get photoNoCaption => _catalog.photoNoCaption;

  /// Opens the caption editor in the photo preview.
  String get photoCaptionEdit => _catalog.photoCaptionEdit;

  /// Removes a photo's caption in the preview.
  String get photoCaptionDelete => _catalog.photoCaptionDelete;

  /// What deleting a caption does.
  String get photoCaptionDeleteMessage => _catalog.photoCaptionDeleteMessage;

  /// Confirms a caption was removed, beside Undo.
  String get photoCaptionDeleted => _catalog.photoCaptionDeleted;

  /// Types words onto a derived copy of a photo.
  String get photoTypeOn => _catalog.photoTypeOn;

  /// Semantic name of a thumb: type, missing, caption and selection.
  String photoThumbLabel({
    required String type,
    required bool missing,
    required bool captioned,
    required bool selected,
  }) {
    final StringBuffer buffer = StringBuffer(
      missing ? missingPhotoNamed(type) : type,
    );
    if (captioned) {
      buffer.write(_catalog.photoThumbLabel);
    }
    if (selected) {
      buffer.write(_catalog.photoThumbLabelSelected);
    }
    return buffer.toString();
  }

  /// Facing the subject.
  String get photoFront => _catalog.photoFront;

  /// Reverse of the subject.
  String get photoBack => _catalog.photoBack;

  /// Serial number plate or stamp.
  String get photoSerial => _catalog.photoSerial;

  /// Manufacturer rating plate.
  String get photoRatingPlate => _catalog.photoRatingPlate;

  /// Short overlay for a rating plate.
  String get photoRatingPlateBadge => _catalog.photoRatingPlateBadge;

  /// Visible damage.
  String get photoDamage => _catalog.photoDamage;

  /// Control or breaker panel.
  String get photoPanel => _catalog.photoPanel;

  /// Site or room context.
  String get photoLocation => _catalog.photoLocation;

  /// People present at a meeting.
  String get photoAttendance => _catalog.photoAttendance;

  /// Short overlay for attendance.
  String get photoAttendanceBadge => _catalog.photoAttendanceBadge;

  /// A page or scanned document.
  String get photoDocument => _catalog.photoDocument;

  /// Short overlay for a document.
  String get photoDocumentBadge => _catalog.photoDocumentBadge;

  /// Any other photo type.
  String get photoOther => _catalog.photoOther;

  /// A progress step that finished.
  String get stepDone => _catalog.stepDone;

  /// A progress step that is in progress.
  String get stepRunning => _catalog.stepRunning;

  /// A progress step that has not started.
  String get stepWaiting => _catalog.stepWaiting;

  /// A failed step or record.
  String get failed => _catalog.failed;

  /// Announced name of a progress row.
  String progressAnnouncement({
    required String label,
    required String state,
    String? detail,
  }) {
    if (detail == null) {
      return _catalog.progressAnnouncement(label, state);
    }
    return _catalog.progressAnnouncementValue(label, state, detail);
  }

  /// Saved locally, not yet captured.
  String get statusDraft => _catalog.statusDraft;

  /// Evidence is on the record.
  String get statusCaptured => _catalog.statusCaptured;

  /// Waiting for processing.
  String get statusQueued => _catalog.statusQueued;

  /// A processing job is running.
  String get statusProcessing => _catalog.statusProcessing;

  /// Extraction finished.
  String get statusExtracted => _catalog.statusExtracted;

  /// A person must look at this record.
  String get statusNeedsReview => _catalog.statusNeedsReview;

  /// A person has accepted the record.
  String get statusApproved => _catalog.statusApproved;

  /// Kept for history.
  String get statusArchived => _catalog.statusArchived;

  /// Marked gone.
  String get statusDeleted => _catalog.statusDeleted;

  /// Headline when a list has nothing to show.
  String get emptyHeadline => _catalog.emptyHeadline;

  /// Body when a list has nothing to show.
  String get emptyMessage => _catalog.emptyMessage;

  /// A control or page that is still working.
  String get loading => _catalog.loading;

  /// Busy adverb on an action that is still running.
  String get busy => _catalog.busy;

  /// Named action that is still running.
  String busyAction(String label) => _catalog.busyAction(label, busy);

  /// Retries a failed load.
  String get tryAgain => _catalog.tryAgain;

  /// Persists the current form or record.
  String get save => _catalog.save;

  /// Reverses the last destructive action.
  String get undo => _catalog.undo;

  /// Developer gallery title.
  String get galleryTitle => _catalog.galleryTitle;

  /// Theme-mode switcher.
  String get galleryTheme => _catalog.galleryTheme;

  /// Simulated-width switcher.
  String get galleryWidth => _catalog.galleryWidth;

  /// Text-scale switcher.
  String get galleryTextScale => _catalog.galleryTextScale;

  /// Token family heading.
  String get galleryTokens => _catalog.galleryTokens;

  /// Layout family heading.
  String get galleryLayout => _catalog.galleryLayout;

  /// Button family heading.
  String get galleryButtons => _catalog.galleryButtons;

  /// Field family heading.
  String get galleryFields => _catalog.galleryFields;

  /// Container family heading.
  String get galleryContainers => _catalog.galleryContainers;

  /// State family heading.
  String get galleryStates => _catalog.galleryStates;

  /// Feedback family heading.
  String get galleryFeedback => _catalog.galleryFeedback;

  /// Light appearance.
  String get galleryLight => _catalog.galleryLight;

  /// Dark appearance.
  String get galleryDark => _catalog.galleryDark;

  /// Outdoor appearance.
  String get galleryOutdoor => _catalog.galleryOutdoor;

  /// Compact width.
  String get galleryCompact => _catalog.galleryCompact;

  /// Medium width.
  String get galleryMedium => _catalog.galleryMedium;

  /// Expanded width.
  String get galleryExpanded => _catalog.galleryExpanded;

  /// Default text scale.
  String get galleryScale100 => _catalog.galleryScale100;

  /// Double text scale.
  String get galleryScale200 => _catalog.galleryScale200;

  /// Product name in chrome and the system window.
  String get appName => _catalog.appName;

  /// Prompt on list-pane and picker search fields.
  String get search => _catalog.search;

  /// What to change when a search matches nothing.
  String get searchNoMatchMessage => _catalog.searchNoMatchMessage;

  /// The filter button on a search field, with how many filters are on.
  String searchFilters(int active) {
    return active == 0
        ? _catalog.searchFilters
        : _catalog.searchFiltersFilters(active);
  }

  /// Turns every filter of a list off.
  String get searchClearFilters => _catalog.searchClearFilters;

  /// What to change when a search and its filters match nothing.
  String get searchFilterNoMatchMessage => _catalog.searchFilterNoMatchMessage;

  /// Semantic name of the title-bar overflow control.
  String get overflowMenu => _catalog.overflowMenu;

  /// Shell destination: the project list.
  String get navProjects => _catalog.navProjects;

  /// Headline when the project list has nothing to show.
  String get projectsEmptyHeadline => _catalog.projectsEmptyHeadline;

  /// Body when the project list has nothing to show.
  String get projectsEmptyMessage => _catalog.projectsEmptyMessage;

  /// Primary empty-state action on the project list.
  String get projectsCreate => _catalog.projectsCreate;

  /// Headline when a wide layout has projects but none is open.
  String get projectsPickHeadline => _catalog.projectsPickHeadline;

  /// Body when a wide layout has projects but none is open.
  String get projectsPickMessage => _catalog.projectsPickMessage;

  /// Headline when the project search matches nothing.
  String get projectsNoMatchHeadline => _catalog.projectsNoMatchHeadline;

  /// Body when the project search matches nothing.
  String get projectsNoMatchMessage => _catalog.projectsNoMatchMessage;

  /// Search prompt for names, descriptions, and organisations.
  String get projectSearchHint => _catalog.projectSearchHint;

  /// Secondary filter-sheet title.
  String get projectFiltersTitle => _catalog.projectFiltersTitle;

  /// Status filter heading.
  String get projectStatusFilter => _catalog.projectStatusFilter;

  /// Pin-state filter heading.
  String get projectPinFilter => _catalog.projectPinFilter;

  /// Human label for a pin filter wire name.
  String projectPinFilterLabel(String value) {
    return switch (value) {
      'pinned' => _catalog.projectPinFilterLabel,
      'unpinned' => _catalog.projectPinFilterLabelUnpinned,
      _ => _catalog.projectPinFilterLabelAllProjects,
    };
  }

  /// Commits project filter choices.
  String get projectApplyFilters => _catalog.projectApplyFilters;

  /// Semantic status for a project that stays at the top of the list.
  String get pinnedProject => _catalog.pinnedProject;

  /// Project-home template association count.
  String projectTemplateCount(int count) {
    return _catalog.projectTemplateCount(count);
  }

  /// The Projects list's one Import control (task 020): it opens the import
  /// page, which takes a bundle, a spreadsheet, a dataset or a template.
  String get projectsImport => _catalog.projectsImport;

  /// Duplicate action that opens the create form from an existing project.
  String get projectsDuplicate => _catalog.projectsDuplicate;

  /// Overflow command that returns to the project list from a project home.
  String get projectAllProjects => _catalog.projectAllProjects;

  /// Overflow command that opens the create form from a project home.
  String get projectNew => _catalog.projectNew;

  /// Hides a finished project from the active list.
  String get projectArchive => _catalog.projectArchive;

  /// Restores an archived project to the active list.
  String get projectUnarchive => _catalog.projectUnarchive;

  /// Soft-deletes a project after typed confirmation.
  String get projectDelete => _catalog.projectDelete;

  /// Row menu label. The confirm dialog keeps [projectDelete].
  String get projectDeleteMenu => _catalog.projectDeleteMenu;

  /// Title of the delete confirmation, naming the project.
  String projectDeleteTitle(String name) => _catalog.projectDeleteTitle(name);

  /// Body of the delete confirmation, naming counts and retention.
  String projectDeleteMessage({
    required int records,
    required int files,
    required int days,
  }) {
    return _catalog.projectDeleteMessage(
      recordsCount(records),
      filesCount(files),
      days,
    );
  }

  /// How many files a delete would hide.
  String filesCount(int n) {
    return _catalog.filesCount(n);
  }

  /// Typed-name field on the delete confirmation.
  String get projectDeleteTypeName => _catalog.projectDeleteTypeName;

  /// Alternative on the delete confirmation: export before deleting.
  String get projectExportFirst => _catalog.projectExportFirst;

  /// Filter that reveals archived projects on the landing list.
  String get projectShowArchived => _catalog.projectShowArchived;

  /// Pins a project to the top of the list.
  String get projectPin => _catalog.projectPin;

  /// Removes a project from the top of the list.
  String get projectUnpin => _catalog.projectUnpin;

  /// Opens the rename dialog for a project.
  String get projectRename => _catalog.projectRename;

  /// Title of the rename dialog.
  String get projectRenameTitle => _catalog.projectRenameTitle;

  /// Body of the rename dialog. The folder on disk stays put.
  String get projectRenameMessage => _catalog.projectRenameMessage;

  /// Hands a copy of a project file to another app.
  String get projectOpenWith => _catalog.projectOpenWith;

  /// Saves a copy of a project file on the web, where no app can be launched.
  String get projectDownloadCopy => _catalog.projectDownloadCopy;

  /// Shown when Open with is asked for a project that has no file.
  String get projectNothingToOpen => _catalog.projectNothingToOpen;

  /// What to do when there is nothing to open.
  String get projectNothingToOpenRecovery =>
      _catalog.projectNothingToOpenRecovery;

  /// Title when the hand-off to another app failed.
  String get projectOpenFailedTitle => _catalog.projectOpenFailedTitle;

  /// Body when the hand-off failed.
  String get projectOpenFailed => _catalog.projectOpenFailed;

  /// Body when the named file could not be handed off.
  String projectOpenFailedNamed(String fileName) =>
      _catalog.projectOpenFailedNamed(fileName);

  /// Recovery when the hand-off failed.
  String get projectOpenFailedRecovery => _catalog.projectOpenFailedRecovery;

  /// When no installed app can open the file type.
  String get projectOpenNoApp => _catalog.projectOpenNoApp;

  /// Recovery when no reader is installed.
  String get projectOpenNoAppRecovery => _catalog.projectOpenNoAppRecovery;

  /// When storage permission was refused before writing the copy.
  String get projectOpenPermission => _catalog.projectOpenPermission;

  /// Recovery when storage permission was refused.
  String get projectOpenPermissionRecovery =>
      _catalog.projectOpenPermissionRecovery;

  /// Visible position of a project in the current list.
  String projectListNumber(int n) {
    return _withLocale(() {
      return NumberFormat.decimalPattern().format(n);
    });
  }

  /// Title of the create-project form.
  String get projectCreateTitle => _catalog.projectCreateTitle;

  /// Title of the create form when it is copying another project.
  String get projectDuplicateTitle => _catalog.projectDuplicateTitle;

  /// Required name field on the create form.
  String get projectName => _catalog.projectName;

  /// Optional longer note on the create form.
  String get projectDescription => _catalog.projectDescription;

  /// Optional organisation field on the create form.
  String get projectOrganisation => _catalog.projectOrganisation;

  /// Title of the read-only project page, and the menu item that opens it.
  String get projectEditTitle => _catalog.projectEditTitle;

  /// Title of the form that changes a project's details.
  String get projectEditFormTitle => _catalog.projectEditFormTitle;

  /// Primary action on the project details page.
  String get projectEditDetails => _catalog.projectEditDetails;

  /// A project detail nobody has filled in.
  String get projectValueNotSet => _catalog.projectValueNotSet;

  /// When the project was created, on its details page.
  String get projectCreatedAt => _catalog.projectCreatedAt;

  /// When the project last changed, on its details page.
  String get projectUpdatedAt => _catalog.projectUpdatedAt;

  /// Heading over the template whose fields the context levels come from.
  String get contextLevelSource => _catalog.contextLevelSource;

  /// Title of the per-project settings form.
  String get projectSettingsTitle => _catalog.projectSettingsTitle;

  /// Confirms that the project details form was stored.
  String get projectSaved => _catalog.projectSaved;

  /// Confirms that the project settings form was stored.
  String get projectSettingsSaved => _catalog.projectSettingsSaved;

  /// When fieldwork started.
  String get projectStartsOn => _catalog.projectStartsOn;

  /// When fieldwork finished.
  String get projectEndsOn => _catalog.projectEndsOn;

  /// Open or archived status on the details form.
  String get projectStatus => _catalog.projectStatus;

  /// Status choice: the project is open.
  String get projectStatusActive => _catalog.projectStatusActive;

  /// Status choice: the project is archived.
  String get projectStatusArchived => _catalog.projectStatusArchived;

  /// AI override on the project settings form.
  String get projectAiEnabled => _catalog.projectAiEnabled;

  /// What turning AI off does.
  String get projectAiEnabledEffect => _catalog.projectAiEnabledEffect;

  /// Image-egress override on the project settings form.
  String get projectDoNotSendImages => _catalog.projectDoNotSendImages;

  /// What turning image egress off does.
  String get projectDoNotSendImagesEffect =>
      _catalog.projectDoNotSendImagesEffect;

  /// Refined-columns override on the project settings form.
  String get projectRefineColumns => _catalog.projectRefineColumns;

  /// High-confidence threshold on the project settings form.
  String get projectConfidenceHigh => _catalog.projectConfidenceHigh;

  /// Medium-confidence threshold on the project settings form.
  String get projectConfidenceMedium => _catalog.projectConfidenceMedium;

  /// Inherit the app-level value for this switch.
  String get projectUseAppDefault => _catalog.projectUseAppDefault;

  /// Affirmative override on a three-way choice.
  String get projectOn => _catalog.projectOn;

  /// Negative override on a three-way choice.
  String get projectOff => _catalog.projectOff;

  /// Names the app-level value a row is changing.
  String projectAppDefault(String value) => _catalog.projectAppDefault(value);

  /// Headline when the details form has no open project.
  String get projectEditEmptyHeadline => _catalog.projectEditEmptyHeadline;

  /// Body when the details form has no open project.
  String get projectEditEmptyMessage => _catalog.projectEditEmptyMessage;

  /// Headline when the settings form has no open project.
  String get projectSettingsEmptyHeadline =>
      _catalog.projectSettingsEmptyHeadline;

  /// Body when the settings form has no open project.
  String get projectSettingsEmptyMessage =>
      _catalog.projectSettingsEmptyMessage;

  /// Suggested name for a duplicated project, editable before commit.
  String projectCopyName(String name) => _catalog.projectCopyName(name);

  /// Counts and unprocessed records on one project list row.
  String projectListSubtitle({required int records, required int unprocessed}) {
    return _catalog.projectListSubtitle(
      recordsCount(records),
      unprocessedCount(unprocessed),
    );
  }

  /// Position of one captured record on the project list.
  String projectRecordPosition(int position) =>
      _catalog.projectRecordPosition(position);

  /// Empty project records list.
  String get projectRecordsEmptyHeadline =>
      _catalog.projectRecordsEmptyHeadline;

  /// Explains an empty project records filter.
  String get projectRecordsEmptyMessage => _catalog.projectRecordsEmptyMessage;

  /// Prompt on the project home search: what it looks through.
  String get projectRecordsSearchHint => _catalog.projectRecordsSearchHint;

  /// Title of a project's records filter sheet.
  String get projectRecordFiltersTitle => _catalog.projectRecordFiltersTitle;

  /// The record-status facet of a project's records filters.
  String get projectRecordStatusFilter => _catalog.projectRecordStatusFilter;

  /// A project home search that matched no record, naming the query.
  String projectRecordsNoMatch(String query) {
    final String shown = query.trim();
    if (shown.isEmpty) {
      return _catalog.projectRecordsNoMatch;
    }
    return _catalog.projectRecordsNoMatchNoRecordsMatch(shown);
  }

  /// A choice sheet search that matched no option, naming the query.
  String choiceNoMatch(String query) {
    final String shown = query.trim();
    if (shown.isEmpty) {
      return _catalog.choiceNoMatch;
    }
    return _catalog.choiceNoMatchNothingMatches(shown);
  }

  /// Overflow command that writes a project export.
  String get projectExport => _catalog.projectExport;

  /// Title of the project export screen.
  String get projectExportTitle => _catalog.projectExportTitle;

  /// Empty export screen.
  String get projectExportEmptyHeadline => _catalog.projectExportEmptyHeadline;

  /// Explains that a project needs a record before export.
  String get projectExportEmptyMessage => _catalog.projectExportEmptyMessage;

  /// Shares a finished export.
  String get projectExportShare => _catalog.projectExportShare;

  /// Names the file that was stored.
  String projectExportSaved(String fileName) =>
      _catalog.projectExportSaved(fileName);

  /// Says the share sheet reaches other apps (Android and iOS).
  String get projectExportShareHint => _catalog.projectExportShareHint;

  /// Export summary section: the project itself.
  String get exportSectionProject => _catalog.exportSectionProject;

  /// Export summary section: records by status.
  String get exportSectionRecords => _catalog.exportSectionRecords;

  /// Export summary section: records per template.
  String get exportSectionTemplates => _catalog.exportSectionTemplates;

  /// Export summary section: the file the export writes.
  String get exportSectionFile => _catalog.exportSectionFile;

  /// Audio clips filed on the exported records.
  String exportAudioClips(int n) => _catalog.exportAudioClips(n);

  /// When the exported records were captured. [first] and [last] are
  /// locale-formatted dates; one date when they are the same day.
  String exportCapturedBetween(String first, String last) {
    if (first == last) {
      return _catalog.exportCapturedBetween(first);
    }
    return _catalog.exportCapturedBetweenCapturedTo(first, last);
  }

  /// Exported records not processed yet.
  String exportUnprocessedCount(int n) => _catalog.exportUnprocessedCount(n);

  /// Exported records waiting for a person to review.
  String exportNeedsReviewCount(int n) => _catalog.exportNeedsReviewCount(n);

  /// Exported records already approved.
  String exportApprovedCount(int n) => _catalog.exportApprovedCount(n);

  /// The export's file format.
  String get exportFileFormat => _catalog.exportFileFormat;

  /// What the package holds, for another Tapture app and for a reader.
  String get exportFileColumns => _catalog.exportFileColumns;

  /// How big the package is expected to be, before it is written.
  String exportPackageSize(int bytes) =>
      _catalog.exportPackageSize(fileSize(bytes));

  /// Where the export file is saved: the Exports folder under [place], the
  /// short Downloads label.
  String exportSavedTo(String place) => _catalog.exportSavedTo(place);

  /// Shown while the workbook is written.
  String get projectExportProgress => _catalog.projectExportProgress;

  /// Stops an export before a file is kept.
  String get projectExportCancel => _catalog.projectExportCancel;

  /// Edits one captured record.
  String get recordEdit => _catalog.recordEdit;

  /// Label of the optional project photo on the create and edit screens.
  String get projectPhoto => _catalog.projectPhoto;

  /// Picks a photo for a project that has none.
  String get projectPhotoAdd => _catalog.projectPhotoAdd;

  /// Picks another photo for a project that has one.
  String get projectPhotoChange => _catalog.projectPhotoChange;

  /// Takes the photo off a project.
  String get projectPhotoRemove => _catalog.projectPhotoRemove;

  /// Title of the page that edits a saved record's photos and captions.
  String get recordEditTitle => _catalog.recordEditTitle;

  /// Saves an edited record's photos, captions and audio.
  String get recordEditSave => _catalog.recordEditSave;

  /// Confirms an edited record was saved.
  String get recordEditSaved => _catalog.recordEditSaved;

  /// Edit sheet for a record with nothing to edit.
  String get recordEditNoFieldsHeadline => _catalog.recordEditNoFieldsHeadline;

  /// What to do when a record has no editable field.
  String get recordEditNoFieldsMessage => _catalog.recordEditNoFieldsMessage;

  /// Archives one captured record. The photos stay on the device.
  String get recordDelete => _catalog.recordDelete;

  /// Confirm copy for archiving a captured record.
  String get recordArchiveMessage => _catalog.recordArchiveMessage;

  /// Title of a record's page when no value names it.
  String get recordDetailTitle => _catalog.recordDetailTitle;

  /// A record with no caption, on its page.
  String get recordNoCaption => _catalog.recordNoCaption;

  /// A template field the record holds no value for.
  String get recordFieldEmpty => _catalog.recordFieldEmpty;

  /// Record page section: its field values.
  String get recordSectionFields => _catalog.recordSectionFields;

  /// Opens the template-field editor from a record's page.
  String get recordEditFields => _catalog.recordEditFields;

  /// When a record was captured. [when] is a locale-formatted date and time.
  String recordCapturedAt(String when) => _catalog.recordCapturedAt(when);

  /// A record's page after it was deleted elsewhere.
  String get recordGoneHeadline => _catalog.recordGoneHeadline;

  /// What to do when a record's page has nothing to show.
  String get recordGoneMessage => _catalog.recordGoneMessage;

  /// Primary action on the open-project home when a record already exists.
  String get continueCapturing => _catalog.continueCapturing;

  /// Home primary action before the first record.
  String get captureStart => _catalog.captureStart;

  /// Home primary action after at least one record.
  String get captureMore => _catalog.captureMore;

  /// Headline when the project home has no open project.
  String get homeEmptyHeadline => _catalog.homeEmptyHeadline;

  /// Body when the project home has no open project.
  String get homeEmptyMessage => _catalog.homeEmptyMessage;

  /// Shell destination: capture. Visually dominant in the four-destination bar.
  String get navCapture => _catalog.navCapture;

  /// Shell destination: the records list.
  String get navRecords => _catalog.navRecords;

  /// Shell destination: settings and the rest.
  String get navMore => _catalog.navMore;

  /// Compact navigation control opening secondary destinations.
  String get navMoreMenu => _catalog.navMoreMenu;

  /// Pinned-template destination the status line opens.
  String get navTemplates => _catalog.navTemplates;

  /// Project-scoped template list. The app-wide list keeps [navTemplates].
  String get projectTemplatesTitle => _catalog.projectTemplatesTitle;

  /// Project datasets destination.
  String get navDatasets => _catalog.navDatasets;

  /// Headline when a project has no reference datasets.
  String get datasetsEmptyHeadline => _catalog.datasetsEmptyHeadline;

  /// Body when the dataset list is empty.
  String get datasetsEmptyMessage => _catalog.datasetsEmptyMessage;

  /// Empty-state / primary action that starts an import.
  String get datasetsImport => _catalog.datasetsImport;

  /// Title of the key-column confirmation screen.
  String get datasetsKeyTitle => _catalog.datasetsKeyTitle;

  /// Explains the key-column choice.
  String get datasetsKeyMessage => _catalog.datasetsKeyMessage;

  /// Confirms saving despite duplicate keys.
  String get datasetsAllowDuplicates => _catalog.datasetsAllowDuplicates;

  /// Saves the import after a unique key is chosen.
  String get datasetsSaveImport => _catalog.datasetsSaveImport;

  /// Duplicate-key warning with count.
  String datasetsDuplicateCount(int n) {
    return _catalog.datasetsDuplicateCount(n);
  }

  /// Sample colliding values.
  String datasetsCollidingValues(List<String> values) {
    return _catalog.datasetsCollidingValues(values.join(', '));
  }

  /// List subtitle: rows · source · date. [importedAt] is shown in local time.
  String datasetListSubtitle({
    required int rows,
    required String source,
    required DateTime importedAt,
  }) {
    return _withLocale(() {
      return _catalog.datasetListSubtitle(
        datasetsRowCount(rows),
        source,
        DateFormat.yMMMd().format(importedAt.toLocal()),
      );
    });
  }

  /// How many rows a dataset holds.
  String datasetsRowCount(int n) {
    return _catalog.datasetsRowCount(n);
  }

  /// Dataset source label.
  String datasetSourceLabel(String source) {
    return switch (source) {
      'csv' => _catalog.datasetSourceLabel,
      'xlsx' => _catalog.datasetSourceLabelSpreadsheet,
      'json' => _catalog.datasetSourceLabelJSON,
      'device' => _catalog.datasetSourceLabelOnDevice,
      _ => source,
    };
  }

  /// Browser search hint.
  String get datasetsSearchHint => _catalog.datasetsSearchHint;

  /// Choose visible columns on a narrow screen.
  String get datasetsColumns => _catalog.datasetsColumns;

  /// Row edit title.
  String get datasetsEditRow => _catalog.datasetsEditRow;

  /// Save row edits.
  String get datasetsSaveRow => _catalog.datasetsSaveRow;

  /// Add-row sheet title.
  String get datasetsAddRow => _catalog.datasetsAddRow;

  /// Lookup picker title.
  String get datasetsPickMatch => _catalog.datasetsPickMatch;

  /// Lookup binding screen title.
  String get datasetsLookupBinding => _catalog.datasetsLookupBinding;

  /// Save lookup binding.
  String get datasetsSaveBinding => _catalog.datasetsSaveBinding;

  /// No datasets available for binding.
  String get datasetsBindingEmptyHeadline =>
      _catalog.datasetsBindingEmptyHeadline;

  /// Binding empty body.
  String get datasetsBindingEmptyMessage =>
      _catalog.datasetsBindingEmptyMessage;

  /// Fuzzy matching switch.
  String get datasetsFuzzyEnabled => _catalog.datasetsFuzzyEnabled;

  /// No-match behaviour label.
  String get datasetsOnNoMatch => _catalog.datasetsOnNoMatch;

  /// Mark a row added on device in the browser.
  String get datasetsAddedOnDevice => _catalog.datasetsAddedOnDevice;

  /// Export dataset action.
  String get datasetsExport => _catalog.datasetsExport;

  /// Headline when the dataset browser has no rows.
  String get datasetsBrowserEmptyHeadline =>
      _catalog.datasetsBrowserEmptyHeadline;

  /// Body when the dataset browser has no rows.
  String get datasetsBrowserEmptyMessage =>
      _catalog.datasetsBrowserEmptyMessage;

  /// Headline when a dataset search or lookup matches no row.
  String get datasetsNoMatchHeadline => _catalog.datasetsNoMatchHeadline;

  /// Body when a dataset search matches no row.
  String get datasetsNoMatchMessage => _catalog.datasetsNoMatchMessage;

  /// Body when a lookup finds no row to pick.
  String get datasetsPickNoMatchMessage => _catalog.datasetsPickNoMatchMessage;

  /// Picker row: the columns that tell matching rows apart, as
  /// `column: value` pairs.
  String datasetsPickerSubtitle(Map<String, String> cells) {
    return <String>[
      for (final MapEntry<String, String> cell in cells.entries)
        '${cell.key}: ${cell.value}',
    ].join(' · ');
  }

  /// Clears the dataset search.
  String get datasetsClearSearch => _catalog.datasetsClearSearch;

  /// Headline when no project is open for a dataset screen.
  String get datasetsNoProjectHeadline => _catalog.datasetsNoProjectHeadline;

  /// Body when no project is open for a dataset screen.
  String get datasetsNoProjectMessage => _catalog.datasetsNoProjectMessage;

  /// Key-screen headline before a file is chosen.
  String get datasetsPickHeadline => _catalog.datasetsPickHeadline;

  /// Key-screen body before a file is chosen.
  String get datasetsPickMessage => _catalog.datasetsPickMessage;

  /// Starts choosing a table file.
  String get datasetsPickFile => _catalog.datasetsPickFile;

  /// Progress step while a table file is read.
  String get datasetsReading => _catalog.datasetsReading;

  /// How much of a table file has been read.
  String datasetsReadProgress(int percent) =>
      _catalog.datasetsReadProgress(percent);

  /// A key-column row: its duplicate count and first values.
  String datasetsColumnSummary(int duplicates, List<String> samples) {
    final String shown = samples
        .where((String sample) => sample.trim().isNotEmpty)
        .join(', ');
    final String count = datasetsDuplicateCount(duplicates);
    return shown.isEmpty ? count : _catalog.datasetsColumnSummary(count, shown);
  }

  /// Warning under a non-unique key: the count, the colliding values and
  /// the way forward.
  String datasetsDuplicateWarning(int n, List<String> colliding) {
    final String values = colliding.isEmpty
        ? ''
        : _catalog.datasetsDuplicateWarning(datasetsCollidingValues(colliding));
    return _catalog.datasetsDuplicateWarningPickAnotherKeyColumn(
      datasetsDuplicateCount(n),
      values,
    );
  }

  /// Confirm heading before a dataset with duplicate keys is saved.
  String get datasetsDuplicatesConfirmTitle =>
      _catalog.datasetsDuplicatesConfirmTitle;

  /// Confirm body naming the key column and how many values repeat.
  String datasetsDuplicatesConfirm(String column, int n) {
    return _catalog.datasetsDuplicatesConfirm(
      column,
      datasetsDuplicateCount(n),
    );
  }

  /// Browser action: export the dataset as CSV.
  String get datasetsExportCsv => _catalog.datasetsExportCsv;

  /// Browser action: export the dataset as JSON.
  String get datasetsExportJson => _catalog.datasetsExportJson;

  /// Shown while a dataset export is written.
  String get datasetsExporting => _catalog.datasetsExporting;

  /// Label of the visible-columns choice.
  String get datasetsVisibleColumns => _catalog.datasetsVisibleColumns;

  /// A browser row's second line: its shown values, and whether it was
  /// added on this device.
  String datasetRowSubtitle(
    List<String> values, {
    required bool addedOnDevice,
  }) {
    return <String>[
      ...values.where((String value) => value.trim().isNotEmpty),
      if (addedOnDevice) datasetsAddedOnDevice,
    ].join(' · ');
  }

  /// Headline when a browsed dataset is no longer stored.
  String get datasetsMissingHeadline => _catalog.datasetsMissingHeadline;

  /// Body when a browsed dataset is no longer stored.
  String get datasetsMissingMessage => _catalog.datasetsMissingMessage;

  /// Export refused because no project is open to write it into.
  String get datasetsExportNoProject => _catalog.datasetsExportNoProject;

  /// What to do when no project is open for an export.
  String get datasetsExportNoProjectRecovery =>
      _catalog.datasetsExportNoProjectRecovery;

  /// Headline when an edited row is no longer stored.
  String get datasetsRowMissingHeadline => _catalog.datasetsRowMissingHeadline;

  /// Body when an edited row is no longer stored.
  String get datasetsRowMissingMessage => _catalog.datasetsRowMissingMessage;

  /// Headline when the add-row sheet has no dataset to add to.
  String get datasetsAddRowNoDatasetHeadline =>
      _catalog.datasetsAddRowNoDatasetHeadline;

  /// Body when the add-row sheet has no dataset to add to.
  String get datasetsAddRowNoDatasetMessage =>
      _catalog.datasetsAddRowNoDatasetMessage;

  /// A lookup fill target the template does not define.
  String lookupUnknownTarget(String target) =>
      _catalog.lookupUnknownTarget(target);

  /// A lookup fill target two dataset columns write.
  String lookupTargetTwice(String target) => _catalog.lookupTargetTwice(target);

  /// Binding screen: pick a dataset before saving.
  String get lookupPickDataset => _catalog.lookupPickDataset;

  /// An imported template whose lookup cannot be accepted.
  String get lookupImportRecovery => _catalog.lookupImportRecovery;

  /// Binding screen: one dataset column chosen for two fields.
  String lookupColumnTwice(String column) => _catalog.lookupColumnTwice(column);

  /// Binding screen: a fuzzy threshold as a percentage.
  String lookupThresholdLabel(int percent) =>
      _catalog.lookupThresholdLabel(percent);

  /// Binding screen: the dataset's key column.
  String get lookupKeyColumn => _catalog.lookupKeyColumn;

  /// Binding screen: the ordered match columns.
  String get lookupMatchColumns => _catalog.lookupMatchColumns;

  /// Binding screen: the order match columns are tried in.
  String lookupMatchOrder(List<String> columns) =>
      columns.isEmpty ? _catalog.lookupMatchOrder : columns.join(' → ');

  /// Binding screen: a template field no dataset column fills.
  String get lookupNotFilled => _catalog.lookupNotFilled;

  /// Binding screen: heading over the fill mapping.
  String get lookupFills => _catalog.lookupFills;

  /// Binding screen: the lowest fuzzy score offered, in percent.
  String get lookupFuzzyThreshold => _catalog.lookupFuzzyThreshold;

  /// Binding screen: saving turns the field into a lookup field.
  String get lookupBecomesLookup => _catalog.lookupBecomesLookup;

  /// Binding screen: the field is no longer on the template.
  String get lookupFieldMissingHeadline => _catalog.lookupFieldMissingHeadline;

  /// Binding screen: body when the field is no longer on the template.
  String get lookupFieldMissingMessage => _catalog.lookupFieldMissingMessage;

  /// No-match behaviour: leave the bound fields empty.
  String get lookupNoMatchLeaveEmpty => _catalog.lookupNoMatchLeaveEmpty;

  /// No-match behaviour: offer to add a row.
  String get lookupNoMatchPromptAdd => _catalog.lookupNoMatchPromptAdd;

  /// No-match behaviour: warn only.
  String get lookupNoMatchWarn => _catalog.lookupNoMatchWarn;

  /// Field editor entry that opens the lookup binding.
  String get templatesBindDataset => _catalog.templatesBindDataset;

  /// Headline when the template list is empty.
  String get templatesEmptyHeadline => _catalog.templatesEmptyHeadline;

  /// Body when the template list is empty. The next action is the library.
  String get templatesEmptyMessage => _catalog.templatesEmptyMessage;

  /// Empty-state action that opens the shipped-library picker.
  String get templatesPickLibrary => _catalog.templatesPickLibrary;

  /// Primary action that opens the blank-template form.
  String get templatesCreate => _catalog.templatesCreate;

  /// Renames a template from its row menu.
  String get templatesEdit => _catalog.templatesEdit;

  /// Opens upload and library choices on the template list.
  String get templatesAddChoices => _catalog.templatesAddChoices;

  /// The add action once the project already has a template.
  String get templatesAddMore => _catalog.templatesAddMore;

  /// Empty project template list. The add action sits in the footer.
  String get templatesAddEmptyMessage => _catalog.templatesAddEmptyMessage;

  /// Uploads a template file.
  String get templatesUpload => _catalog.templatesUpload;

  /// Attaches a template that already exists.
  String get templatesUseExisting => _catalog.templatesUseExisting;

  /// Search on the template list matched nothing.
  String get templatesNoMatch => _catalog.templatesNoMatch;

  /// Title of the template list's filter sheet.
  String get templateFiltersTitle => _catalog.templateFiltersTitle;

  /// The template-kind facet of the template list's filters.
  String get templateKindFilter => _catalog.templateKindFilter;

  /// A template that names no kind, as a filter option.
  String get templateKindNone => _catalog.templateKindNone;

  /// Search on the field list matched nothing.
  String get fieldsNoMatch => _catalog.fieldsNoMatch;

  /// Title of a template field list's filter sheet.
  String get fieldFiltersTitle => _catalog.fieldFiltersTitle;

  /// The required, recommended or optional facet of the field filters.
  String get fieldRequirednessFilter => _catalog.fieldRequirednessFilter;

  /// How a project chooses a template when capture starts.
  String get templateChoiceLabel => _catalog.templateChoiceLabel;

  /// Use the only template, and ask when there are several.
  String get templateChoiceAuto => _catalog.templateChoiceAuto;

  /// Suggest a template and let the operator confirm.
  String get templateChoiceSuggest => _catalog.templateChoiceSuggest;

  /// Always ask which template to use.
  String get templateChoiceManual => _catalog.templateChoiceManual;

  /// Title of the blank-template form.
  String get templatesCreateTitle => _catalog.templatesCreateTitle;

  /// Opens the field list for a template.
  String get templatesOpen => _catalog.templatesOpen;

  /// Overflow command that writes a template out. Task 100 owns the screen.
  String get templatesExport => _catalog.templatesExport;

  /// Overflow command that reads a template JSON into this project.
  String get templatesImport => _catalog.templatesImport;

  /// Empty import destination: no file was given.
  String get templatesImportEmptyHeadline =>
      _catalog.templatesImportEmptyHeadline;

  /// Empty import destination explanation.
  String get templatesImportEmptyMessage =>
      _catalog.templatesImportEmptyMessage;

  /// Rejected because schema_version is missing or not this app's version.
  String get templatesImportUnknownSchema =>
      _catalog.templatesImportUnknownSchema;

  /// Recovery for an unknown schema version.
  String get templatesImportUnknownSchemaRecovery =>
      _catalog.templatesImportUnknownSchemaRecovery;

  /// Rejected because the JSON is not a template object.
  String get templatesImportInvalid => _catalog.templatesImportInvalid;

  /// Recovery for an invalid template JSON.
  String get templatesImportInvalidRecovery =>
      _catalog.templatesImportInvalidRecovery;

  /// Rejected because two fields share a key.
  String get templatesImportDuplicateField =>
      _catalog.templatesImportDuplicateField;

  /// Recovery for a duplicate field key.
  String get templatesImportDuplicateFieldRecovery =>
      _catalog.templatesImportDuplicateFieldRecovery;

  /// The chosen spreadsheet is encrypted.
  String get workbookPassword => _catalog.workbookPassword;

  /// Recovery for a password-protected spreadsheet.
  String get workbookPasswordRecovery => _catalog.workbookPasswordRecovery;

  /// The chosen spreadsheet could not be parsed.
  String get workbookCorrupt => _catalog.workbookCorrupt;

  /// Recovery for a corrupt spreadsheet.
  String get workbookCorruptRecovery => _catalog.workbookCorruptRecovery;

  /// Title of the spreadsheet column-mapping screen.
  String get xlsxMappingTitle => _catalog.xlsxMappingTitle;

  /// Headline when no spreadsheet was given.
  String get xlsxMappingEmptyHeadline => _catalog.xlsxMappingEmptyHeadline;

  /// Body when the mapping screen has no file to read.
  String get xlsxMappingEmptyMessage => _catalog.xlsxMappingEmptyMessage;

  /// Primary action that creates the template from the confirmed mapping.
  String get xlsxMappingConfirm => _catalog.xlsxMappingConfirm;

  /// Overflow command that omits one spreadsheet column.
  String get xlsxMappingSkip => _catalog.xlsxMappingSkip;

  /// Overflow command that brings a skipped column back.
  String get xlsxMappingInclude => _catalog.xlsxMappingInclude;

  /// Subtitle when the operator has skipped a column.
  String get xlsxMappingSkipped => _catalog.xlsxMappingSkipped;

  /// Proposed field shown on the right of a mapping row.
  String xlsxMappingProposal({
    required String field,
    required String type,
    required String rule,
  }) {
    return _catalog.xlsxMappingProposal(field, type, rule);
  }

  /// Proposed label when a spreadsheet column has no header.
  String xlsxMappingUntitled(String column) =>
      _catalog.xlsxMappingUntitled(column);

  /// Template name when the sheet tab is blank.
  String get xlsxMappingDefaultName => _catalog.xlsxMappingDefaultName;

  /// The chosen spreadsheet vanished before confirm.
  String get xlsxMappingMissing => _catalog.xlsxMappingMissing;

  /// Recovery when the chosen spreadsheet is missing.
  String get xlsxMappingMissingRecovery => _catalog.xlsxMappingMissingRecovery;

  /// A copy of this name is already in the project templates folder.
  String get xlsxMappingExists => _catalog.xlsxMappingExists;

  /// Recovery when the destination copy already exists.
  String get xlsxMappingExistsRecovery => _catalog.xlsxMappingExistsRecovery;

  /// Title of the per-row aliases screen.
  String get rowAliasesTitle => _catalog.rowAliasesTitle;

  /// Headline when the template has no checklist rows to name.
  String get rowAliasesEmptyHeadline => _catalog.rowAliasesEmptyHeadline;

  /// Body when the aliases list is empty.
  String get rowAliasesEmptyMessage => _catalog.rowAliasesEmptyMessage;

  /// Field label for a row's aliases.
  String get rowAliasesField => _catalog.rowAliasesField;

  /// Hint showing how local names are written.
  String get rowAliasesHint => _catalog.rowAliasesHint;

  /// Overflow command that reads aliases from one spreadsheet column.
  String get rowAliasesImport => _catalog.rowAliasesImport;

  /// Field label for the alias column letter.
  String get rowAliasesColumn => _catalog.rowAliasesColumn;

  /// Refuses a letter that does not name a column in the selected workbook.
  String get rowAliasesInvalidColumn => _catalog.rowAliasesInvalidColumn;

  /// Recovery for an invalid alias column letter.
  String get rowAliasesInvalidColumnRecovery =>
      _catalog.rowAliasesInvalidColumnRecovery;

  /// Stated absence when a row has no aliases yet.
  String get rowAliasesNone => _catalog.rowAliasesNone;

  /// Subtitle listing the aliases already stored on a row.
  String rowAliasesList(List<String> aliases) {
    if (aliases.isEmpty) {
      return rowAliasesNone;
    }
    return aliases.join(', ');
  }

  /// Title of the capture checklist.
  String get checklistTitle => _catalog.checklistTitle;

  /// Spreadsheet column that identifies one predefined checklist row.
  String get checklistIdentifierColumn => _catalog.checklistIdentifierColumn;

  /// Spreadsheet column that names one predefined checklist row.
  String get checklistLabelColumn => _catalog.checklistLabelColumn;

  /// Spreadsheet column that groups checklist rows by place or context.
  String get checklistContextColumn => _catalog.checklistContextColumn;

  /// Opens workbook mapping for an existing template's checklist.
  String get checklistImportRows => _catalog.checklistImportRows;

  /// A checklist requires both identifying and display columns.
  String get checklistMappingIncomplete => _catalog.checklistMappingIncomplete;

  /// Recovery when a checklist mapping is incomplete.
  String get checklistMappingRecovery => _catalog.checklistMappingRecovery;

  /// Headline when the template has no predefined rows.
  String get checklistEmptyHeadline => _catalog.checklistEmptyHeadline;

  /// Body when the checklist is empty.
  String get checklistEmptyMessage => _catalog.checklistEmptyMessage;

  /// Status word for a row that has been found.
  String get checklistFound => _catalog.checklistFound;

  /// Status word for a row that is still missing.
  String get checklistMissing => _catalog.checklistMissing;

  /// Group name when a row has no room or context.
  String get checklistUngrouped => _catalog.checklistUngrouped;

  /// Group heading: the room name and how many rows have been found.
  String checklistProgress({
    required String group,
    required int found,
    required int total,
  }) {
    return _catalog.checklistProgress(group, found, total);
  }

  /// Title of the detection-profile screen.
  String get detectionProfileTitle => _catalog.detectionProfileTitle;

  /// What the detection profile decides.
  String get detectionProfileExplain => _catalog.detectionProfileExplain;

  /// Headline when no template is open.
  String get detectionProfileEmptyHeadline =>
      _catalog.detectionProfileEmptyHeadline;

  /// Body when the detection screen has no template.
  String get detectionProfileEmptyMessage =>
      _catalog.detectionProfileEmptyMessage;

  /// Field label for vision object classes.
  String get detectionProfileClasses => _catalog.detectionProfileClasses;

  /// Field label for OCR keywords.
  String get detectionProfileKeywords => _catalog.detectionProfileKeywords;

  /// Section for identifier patterns reused from field validation.
  String get detectionProfilePatterns => _catalog.detectionProfilePatterns;

  /// Section for datasets already bound on lookup fields.
  String get detectionProfileDatasets => _catalog.detectionProfileDatasets;

  /// Field label for keywords that exclude this template.
  String get detectionProfileNegative => _catalog.detectionProfileNegative;

  /// Hint on a comma-separated signal list.
  String get detectionProfileHint => _catalog.detectionProfileHint;

  /// Shown when no field has a validation pattern to reuse.
  String get detectionProfileNoPatterns => _catalog.detectionProfileNoPatterns;

  /// Shown when no lookup field names a dataset.
  String get detectionProfileNoDatasets => _catalog.detectionProfileNoDatasets;

  /// The template vanished before the profile was saved.
  String get detectionProfileMissing => _catalog.detectionProfileMissing;

  /// Recovery when the template is missing.
  String get detectionProfileMissingRecovery =>
      _catalog.detectionProfileMissingRecovery;

  /// Soft-deletes a template no record uses.
  String get templatesDelete => _catalog.templatesDelete;

  /// Title of the delete confirmation, naming the template.
  String templatesDeleteTitle(String name) =>
      _catalog.templatesDeleteTitle(name);

  /// Body of the delete confirmation, naming field and record counts.
  String templatesDeleteMessage({required int fields, required int records}) {
    return _catalog.templatesDeleteMessage(
      fieldsCount(fields),
      recordsCount(records),
    );
  }

  /// Field-list destination after create, duplicate or open. Task 094 owns it.
  String get templateFieldsTitle => _catalog.templateFieldsTitle;

  /// Primary action that opens the add-field flow. Task 095 owns the sheet.
  String get templatesAddField => _catalog.templatesAddField;

  /// Heading of one field row on the new-template page.
  String templateFieldRowTitle(int n) => _catalog.templateFieldRowTitle(n);

  /// Removes one field row from the new-template page.
  String get templateFieldRowRemove => _catalog.templateFieldRowRemove;

  /// Opens the editor for one field. Task 095 owns the sheet.
  String get templatesEditField => _catalog.templatesEditField;

  /// Removes a field from the template and retires its values.
  String get templatesDeleteField => _catalog.templatesDeleteField;

  /// Title of the field-delete confirmation, naming the field.
  String templatesDeleteFieldTitle(String label) =>
      _catalog.templatesDeleteFieldTitle(label);

  /// Body of the field-delete confirmation, naming the value count.
  String templatesDeleteFieldMessage({required int values}) {
    return _catalog.templatesDeleteFieldMessage(values);
  }

  /// Headline when a template has no fields.
  String get templatesFieldsEmptyHeadline =>
      _catalog.templatesFieldsEmptyHeadline;

  /// Body when the field list is empty. The next action is adding one.
  String get templatesFieldsEmptyMessage =>
      _catalog.templatesFieldsEmptyMessage;

  /// REQUIRED badge on a field row.
  String get fieldRequired => _catalog.fieldRequired;

  /// Field filled by a calculation.
  String get fieldCalculated => _catalog.fieldCalculated;

  /// Field the detection profile can fill from a photo.
  String get fieldFromPhotos => _catalog.fieldFromPhotos;

  /// Field-list subtitle: type, then any of required, calculated, from photos.
  String fieldRowSubtitle({
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
      parts.add(_catalog.fieldRowSubtitle(contextLevel));
    }
    if (pinnedContext) {
      parts.add(_catalog.fieldRowSubtitlePinnedContext);
    }
    final String shownDefault = defaultValue?.trim() ?? '';
    if (shownDefault.isNotEmpty) {
      parts.add(fieldRowDefault(shownDefault));
    }
    return parts.join(' · ');
  }

  /// The value a field takes when nothing fills it, on its field row.
  String fieldRowDefault(String value) => _catalog.fieldRowDefault(value);

  /// RECOMMENDED badge on a field row.
  String get fieldRecommended => _catalog.fieldRecommended;

  /// OPTIONAL badge on a field row.
  String get fieldOptional => _catalog.fieldOptional;

  /// Moves [label] one place earlier in capture and export order.
  String fieldMoveUp(String label) => _catalog.fieldMoveUp(label);

  /// Moves [label] one place later in capture and export order.
  String fieldMoveDown(String label) => _catalog.fieldMoveDown(label);

  /// Drag handle that reorders [label].
  String fieldReorder(String label) => _catalog.fieldReorder(label);

  /// Operator-facing name of a §12.1 field type.
  String fieldTypeLabel(String type) {
    return switch (type) {
      'text' => _catalog.fieldTypeLabel,
      'longText' => _catalog.fieldTypeLabelLongText,
      'number' => _catalog.fieldTypeLabelNumber,
      'decimal' => _catalog.fieldTypeLabelDecimal,
      'currency' => _catalog.fieldTypeLabelCurrency,
      'percentage' => _catalog.fieldTypeLabelPercentage,
      'date' => _catalog.fieldTypeLabelDate,
      'time' => _catalog.fieldTypeLabelTime,
      'dateTime' => _catalog.fieldTypeLabelDateAndTime,
      'boolean' => _catalog.fieldTypeLabelBoolean,
      'choice' => _catalog.fieldTypeLabelChoice,
      'multiChoice' => _catalog.fieldTypeLabelMultiChoice,
      'lookup' => _catalog.fieldTypeLabelLookup,
      'barcode' => _catalog.fieldTypeLabelBarcode,
      'photoReference' => _catalog.fieldTypeLabelPhotoReference,
      'documentReference' => _catalog.fieldTypeLabelDocumentReference,
      'gpsLocation' => _catalog.fieldTypeLabelGPSLocation,
      'signature' => _catalog.fieldTypeLabelSignature,
      'computed' => _catalog.fieldTypeLabelComputed,
      _ => type,
    };
  }

  /// Label of the field being added or edited. Template content follows.
  String get fieldLabel => _catalog.fieldLabel;

  /// Type picker on the add-field sheet.
  String get fieldType => _catalog.fieldType;

  /// Three-way requiredness question on the add-field sheet.
  String get fieldRequiredness => _catalog.fieldRequiredness;

  /// Collapsed section that holds every §12.2 attribute the add flow defaults.
  String get fieldAdvanced => _catalog.fieldAdvanced;

  /// Reveals the collapsed Advanced section.
  String get fieldAdvancedShow => _catalog.fieldAdvancedShow;

  /// Hides the Advanced section again.
  String get fieldAdvancedHide => _catalog.fieldAdvancedHide;

  /// Lets the user keep a two-fact label after the warning.
  String get fieldKeepAnyway => _catalog.fieldKeepAnyway;

  /// Warns that a label packs two facts (§13.1) without blocking the save.
  String get fieldTwoFactsWarning => _catalog.fieldTwoFactsWarning;

  /// Default written when the operator leaves the field empty.
  String get fieldDefaultValue => _catalog.fieldDefaultValue;

  /// Displayed and exported unit, for example kg.
  String get fieldUnit => _catalog.fieldUnit;

  /// One short line of guidance shown under the field.
  String get fieldHelp => _catalog.fieldHelp;

  /// Who may write the field.
  String get fieldInputMode => _catalog.fieldInputMode;

  /// [InputMode.any].
  String get fieldInputAny => _catalog.fieldInputAny;

  /// [InputMode.manualOnly].
  String get fieldInputManual => _catalog.fieldInputManual;

  /// [InputMode.aiAllowed].
  String get fieldInputAi => _catalog.fieldInputAi;

  /// [InputMode.auto].
  String get fieldInputAuto => _catalog.fieldInputAuto;

  /// Whether the field may be pinned as context.
  String get fieldStickable => _catalog.fieldStickable;

  /// Context hierarchy level, when this field is a level of that hierarchy.
  String get fieldContextLevel => _catalog.fieldContextLevel;

  /// System fill source.
  String get fieldAutoFill => _catalog.fieldAutoFill;

  /// No automatic fill.
  String get fieldAutoFillNone => _catalog.fieldAutoFillNone;

  /// Operator-facing name of an [AutoFill] source.
  String fieldAutoFillLabel(String source) {
    return switch (source) {
      'now' => _catalog.fieldAutoFillLabel,
      'today' => _catalog.fieldAutoFillLabelToday,
      'time' => _catalog.fieldAutoFillLabelTimeOfDay,
      'sequence' => _catalog.fieldAutoFillLabelNextInSequence,
      'operator' => _catalog.fieldAutoFillLabelSignedInOperator,
      'device' => _catalog.fieldAutoFillLabelThisDevice,
      'gps' => _catalog.fieldAutoFillLabelCurrentLocation,
      'context' => _catalog.fieldAutoFillLabelPinnedContext,
      _ => fieldAutoFillNone,
    };
  }

  /// Store an AI-refined companion beside the raw value.
  String get fieldRefine => _catalog.fieldRefine;

  /// Whether the field participates in duplicate detection.
  String get fieldIdentity => _catalog.fieldIdentity;

  /// Expression that makes the field required.
  String get fieldRequiredWhen => _catalog.fieldRequiredWhen;

  /// Plain-language reading of a required-when expression.
  String fieldRequiredWhenPreview(String reading) {
    return _catalog.fieldRequiredWhenPreview(reading);
  }

  /// Keeps the field out of capture and export; values stay.
  String get fieldHidden => _catalog.fieldHidden;

  /// Explains that hide is not a delete.
  String get fieldHiddenHelp => _catalog.fieldHiddenHelp;

  /// Validation editor heading.
  String get fieldValidationTitle => _catalog.fieldValidationTitle;

  /// Headline when no validation rule is set.
  String get fieldValidationEmptyHeadline =>
      _catalog.fieldValidationEmptyHeadline;

  /// Body when the validation editor is empty.
  String get fieldValidationEmptyMessage =>
      _catalog.fieldValidationEmptyMessage;

  /// Pattern picker.
  String get fieldPattern => _catalog.fieldPattern;

  /// No pattern.
  String get fieldPatternNone => _catalog.fieldPatternNone;

  /// Ready-made serial pattern.
  String get fieldPatternSerial => _catalog.fieldPatternSerial;

  /// Ready-made asset-tag pattern.
  String get fieldPatternAssetTag => _catalog.fieldPatternAssetTag;

  /// Ready-made registration pattern.
  String get fieldPatternRegistration => _catalog.fieldPatternRegistration;

  /// Custom regular expression.
  String get fieldPatternCustom => _catalog.fieldPatternCustom;

  /// Live box that tries the current validation against a sample.
  String get fieldPatternTest => _catalog.fieldPatternTest;

  /// Sample matches the rule.
  String get fieldPatternTestPass => _catalog.fieldPatternTestPass;

  /// Minimum length.
  String get fieldMinLength => _catalog.fieldMinLength;

  /// Maximum length.
  String get fieldMaxLength => _catalog.fieldMaxLength;

  /// Inclusive lower bound.
  String get fieldRangeMin => _catalog.fieldRangeMin;

  /// Inclusive upper bound.
  String get fieldRangeMax => _catalog.fieldRangeMax;

  /// Another field that must be filled with this one.
  String get fieldRequiredWith => _catalog.fieldRequiredWith;

  /// Choice-options editor heading.
  String get fieldOptionsTitle => _catalog.fieldOptionsTitle;

  /// Headline when a choice field has no options.
  String get fieldOptionsEmptyHeadline => _catalog.fieldOptionsEmptyHeadline;

  /// Body when the options editor is empty.
  String get fieldOptionsEmptyMessage => _catalog.fieldOptionsEmptyMessage;

  /// Label of a new choice.
  String get fieldOptionLabel => _catalog.fieldOptionLabel;

  /// Adds a choice to the list.
  String get fieldOptionAdd => _catalog.fieldOptionAdd;

  /// Retires a choice without rewriting stored codes.
  String get fieldOptionRetire => _catalog.fieldOptionRetire;

  /// Badge on a retired choice.
  String get fieldOptionRetired => _catalog.fieldOptionRetired;

  /// Headline when the add sheet cannot find the template.
  String get fieldAddEmptyHeadline => _catalog.fieldAddEmptyHeadline;

  /// Body when the add sheet has no template.
  String get fieldAddEmptyMessage => _catalog.fieldAddEmptyMessage;

  /// Title of the bulk requiredness screen.
  String get requiredColumnsTitle => _catalog.requiredColumnsTitle;

  /// Headline when the template has no fields to re-scope.
  String get requiredColumnsEmptyHeadline =>
      _catalog.requiredColumnsEmptyHeadline;

  /// Body when the required-columns list is empty.
  String get requiredColumnsEmptyMessage =>
      _catalog.requiredColumnsEmptyMessage;

  /// Hide toggle on a required-columns row.
  String get requiredColumnHide => _catalog.requiredColumnHide;

  /// Reveals an inherited §13.3 group.
  String get requiredColumnShowGroup => _catalog.requiredColumnShowGroup;

  /// Collapses an inherited §13.3 group.
  String get requiredColumnHideGroup => _catalog.requiredColumnHideGroup;

  /// Heading for fields that do not sit in a named group.
  String get requiredColumnUngrouped => _catalog.requiredColumnUngrouped;

  /// Screen-reader name of the three-radio grid for [label].
  String requiredColumnRadios(String label) =>
      _catalog.requiredColumnRadios(label);

  /// One radio cell: field [label] and the requiredness [mark].
  String requiredColumnCell(String label, String mark) {
    return _catalog.requiredColumnCell(label, mark);
  }

  /// Reminder of the shipped requiredness after the user moves it.
  String requiredColumnShipped(String mark) =>
      _catalog.requiredColumnShipped(mark);

  /// Operator-facing name of a field group.
  String requiredColumnGroup(String group) {
    return shippedLabel(_catalog.requiredColumnGroup(group));
  }

  /// Title of the identity-fields screen.
  String get identityFieldsTitle => _catalog.identityFieldsTitle;

  /// What changing the identity set does.
  String get identityFieldsExplain => _catalog.identityFieldsExplain;

  /// Headline when the template has no fields to mark as identity.
  String get identityFieldsEmptyHeadline =>
      _catalog.identityFieldsEmptyHeadline;

  /// Body when the identity list is empty.
  String get identityFieldsEmptyMessage => _catalog.identityFieldsEmptyMessage;

  /// Title of the output-column mapping screen.
  String get outputMappingTitle => _catalog.outputMappingTitle;

  /// Headline when the template has no fields to map.
  String get outputMappingEmptyHeadline => _catalog.outputMappingEmptyHeadline;

  /// Body when the output-mapping list is empty.
  String get outputMappingEmptyMessage => _catalog.outputMappingEmptyMessage;

  /// Why two fields cannot share an output column.
  String get outputMappingDuplicate => _catalog.outputMappingDuplicate;

  /// What to do after a duplicate output column is refused.
  String get outputMappingDuplicateRecovery =>
      _catalog.outputMappingDuplicateRecovery;

  /// Hint on a template built in the app, whose headers are generated.
  String get outputMappingBuiltHint => _catalog.outputMappingBuiltHint;

  /// Hint on a template imported from a workbook.
  String get outputMappingImportedHint => _catalog.outputMappingImportedHint;

  /// Title of the template-migration screen.
  String get templateMigrationTitle => _catalog.templateMigrationTitle;

  /// What staying on a captured version means.
  String get templateMigrationExplain => _catalog.templateMigrationExplain;

  /// Headline when every record is already on the current version.
  String get templateMigrationEmptyHeadline =>
      _catalog.templateMigrationEmptyHeadline;

  /// Body when no record is behind the current template version.
  String get templateMigrationEmptyMessage =>
      _catalog.templateMigrationEmptyMessage;

  /// Added-fields section on the migration screen.
  String get templateMigrationAdded => _catalog.templateMigrationAdded;

  /// Removed-fields section on the migration screen.
  String get templateMigrationRemoved => _catalog.templateMigrationRemoved;

  /// Retyped-fields section on the migration screen.
  String get templateMigrationRetyped => _catalog.templateMigrationRetyped;

  /// Confirm heading before records move.
  String get templateMigrationConfirmTitle =>
      _catalog.templateMigrationConfirmTitle;

  /// Confirm body: how many records move, in one write, or none do.
  String templateMigrationConfirm(int records) {
    return _catalog.templateMigrationConfirm(recordsCount(records));
  }

  /// How many records are behind the current template version.
  String templateMigrationBehind(int records) {
    return _catalog.templateMigrationBehind(recordsCount(records));
  }

  /// Records whose captured version is no longer known on this device.
  String templateMigrationUnresolved(int records) {
    return _catalog.templateMigrationUnresolved(recordsCount(records));
  }

  /// Section of stored values the move retires for unresolved records.
  String get templateMigrationRetiring => _catalog.templateMigrationRetiring;

  /// Primary action that starts the confirmed move.
  String get templateMigrationAction => _catalog.templateMigrationAction;

  /// Suggested name when duplicating [name].
  String templateCopyName(String name) => _catalog.templateCopyName(name);

  /// Field and record counts on one template list row.
  String templateListSubtitle({required int fields, required int records}) {
    return _catalog.templateListSubtitle(
      fieldsCount(fields),
      recordsCount(records),
    );
  }

  /// Title of the shipped-library picker.
  String get templatesLibraryTitle => _catalog.templatesLibraryTitle;

  /// Headline when the packed library could not be listed.
  String get templatesLibraryEmptyHeadline =>
      _catalog.templatesLibraryEmptyHeadline;

  /// Body when the packed library is empty. Next action is a blank template.
  String get templatesLibraryEmptyMessage =>
      _catalog.templatesLibraryEmptyMessage;

  /// Copies the previewed library entry into the open project.
  String get templatesAdd => _catalog.templatesAdd;

  /// Adds a shipped template that this project does not have yet.
  String get templatesAddToProject => _catalog.templatesAddToProject;

  /// Makes another editable copy of a template already on the project.
  String get templatesCustomCopy => _catalog.templatesCustomCopy;

  /// Visible association on a shipped template already copied in.
  String get shippedAddedToProject => _catalog.shippedAddedToProject;

  /// Search hint on the shipped template library, which ranks a name, a code
  /// or a plain description of the work.
  String get shippedLibrarySearchHint => _catalog.shippedLibrarySearchHint;

  /// Heading of a catalogue area. [code] and [title] are catalogue data.
  String shippedAreaTitle(String code, String title) =>
      _catalog.shippedAreaTitle(code, title);

  /// Heading of a catalogue category. [code] and [title] are catalogue data.
  String shippedCatalogueCategoryTitle(String code, String title) {
    return _catalog.shippedCatalogueCategoryTitle(code, title);
  }

  /// A collapsible catalogue category with how many templates it lists.
  String shippedCategoryHeading(String code, String title, int count) {
    return _catalog.shippedCategoryHeading(
      shippedCatalogueCategoryTitle(code, title),
      count,
    );
  }

  /// Row subtitle of a catalogue template: its code, its record type and how
  /// many fields it holds. [code] and [recordType] are catalogue data.
  String shippedCatalogueSubtitle(String code, String recordType, int fields) {
    return _catalog.shippedCatalogueSubtitle(
      code,
      recordType,
      fieldsCount(fields),
    );
  }

  /// Title of the shipped library's filter sheet.
  String get shippedFiltersTitle => _catalog.shippedFiltersTitle;

  /// The area facet of the shipped library's filters.
  String get shippedAreaFilter => _catalog.shippedAreaFilter;

  /// The record-type facet of the shipped library's filters.
  String get shippedRecordTypeFilter => _catalog.shippedRecordTypeFilter;

  /// The tier facet of the shipped library's filters.
  String get shippedTierFilter => _catalog.shippedTierFilter;

  /// Operator-facing name of a catalogue rollout tier.
  String shippedTierLabel(String rollout) {
    return switch (rollout) {
      'p0' => _catalog.shippedTierLabel,
      'p1' => _catalog.shippedTierLabelExpansion,
      'p2' => _catalog.shippedTierLabelSpecialist,
      _ => rollout,
    };
  }

  /// Operator-facing name of a catalogue template's suggested privacy.
  String shippedPrivacyLabel(String privacy) {
    return switch (privacy) {
      'internal' => _catalog.shippedPrivacyLabel,
      'confidential' => _catalog.shippedPrivacyLabelConfidential,
      'restricted' => _catalog.shippedPrivacyLabelRestricted,
      _ => privacy,
    };
  }

  /// Preview row naming the catalogue category a template sits in.
  String get shippedCategoryLabel => _catalog.shippedCategoryLabel;

  /// Preview row naming a catalogue template's record type.
  String get shippedRecordTypeLabel => _catalog.shippedRecordTypeLabel;

  /// Preview row giving a catalogue template's privacy and tier.
  String get shippedPrivacyTierLabel => _catalog.shippedPrivacyTierLabel;

  /// A catalogue template's suggested privacy beside its tier.
  String shippedPrivacyTier(String privacy, String rollout) {
    return _catalog.shippedPrivacyTier(
      shippedPrivacyLabel(privacy),
      shippedTierLabel(rollout),
    );
  }

  /// Preview row: how evidence for the record type is captured.
  String get shippedCaptureLabel => _catalog.shippedCaptureLabel;

  /// Preview row: what AI may do for the record type.
  String get shippedAiAssistanceLabel => _catalog.shippedAiAssistanceLabel;

  /// Preview row: what the record type produces.
  String get shippedOutputsLabel => _catalog.shippedOutputsLabel;

  /// Preview row: what a reviewer checks before approval.
  String get shippedReviewLabel => _catalog.shippedReviewLabel;

  /// Preview subtitle of one field: its type and suggested requiredness.
  String shippedFieldSubtitle(String type, String requiredness) {
    return _catalog.shippedFieldSubtitle(fieldTypeLabel(type), requiredness);
  }

  /// Empty result for the shipped library search.
  String shippedLibraryNoMatch(String query) {
    final String shown = query.trim();
    if (shown.isEmpty) {
      return _catalog.shippedLibraryNoMatch;
    }
    return _catalog.shippedLibraryNoMatchNoTemplatesMatch(shown);
  }

  /// What to change when the shipped library search matches nothing.
  String get shippedLibraryNoMatchMessage => searchNoMatchMessage;

  /// Resolves a packed localisation key at render time (FE-L10N-07).
  String shippedLabel(String key) {
    if (!key.startsWith('templates.') || !key.contains('.')) {
      return key;
    }
    final String last = key.split('.').last;
    final String stem = last.startsWith('item_')
        ? last.substring(_catalog.shippedLabel.length)
        : last;
    if (stem.isEmpty) {
      return last;
    }
    final List<String> words = stem.split('_');
    final StringBuffer buffer = StringBuffer(words.first);
    for (int index = 1; index < words.length; index++) {
      buffer.write(_catalog.shippedLabelValue(words[index]));
    }
    final String text = buffer.toString();
    return _catalog.shippedLabelValue2(
      text[0].toUpperCase(),
      text.substring(1),
    );
  }

  /// Unprocessed-queue destination the status line opens.
  String get navQueue => _catalog.navQueue;

  /// Export-history destination the project home opens.
  String get navExports => _catalog.navExports;

  /// Why the operator name is asked.
  String get operatorNameUse => _catalog.operatorNameUse;

  /// Label of the operator name field.
  String get operatorName => _catalog.operatorName;

  /// Settings screen for the local operator identity.
  String get operatorProfileTitle => _catalog.operatorProfileTitle;

  /// Initials field on the operator profile.
  String get operatorInitials => _catalog.operatorInitials;

  /// Combined contact label when email and phone are shown as one value.
  String get operatorContact => _catalog.operatorContact;

  /// Optional email field on the operator profile.
  String get operatorEmail => _catalog.operatorEmail;

  /// Optional phone field on the operator profile.
  String get operatorPhone => _catalog.operatorPhone;

  /// Name failed the non-empty rule.
  String get nameRequired => _catalog.nameRequired;

  /// A typed email is missing the @ that marks it as an address.
  String get emailNeedsAt => _catalog.emailNeedsAt;

  /// Initials failed the one-to-three-character rule.
  String get initialsLength => _catalog.initialsLength;

  /// Status line when no project is open.
  String get statusNoProject => _catalog.statusNoProject;

  /// Status line when no context is pinned.
  String get statusNoContext => _catalog.statusNoContext;

  /// Context hierarchy screen title.
  String get contextHierarchyTitle => _catalog.contextHierarchyTitle;

  /// Empty hierarchy.
  String get contextHierarchyEmptyHeadline =>
      _catalog.contextHierarchyEmptyHeadline;

  /// Empty hierarchy body.
  String get contextHierarchyEmptyMessage =>
      _catalog.contextHierarchyEmptyMessage;

  /// Add a level.
  String get contextAddLevel => _catalog.contextAddLevel;

  /// One saved or proposed level and its stable field key.
  String contextLevelRow(int level, String fieldKey) =>
      _catalog.contextLevelRow(level, fieldKey);

  /// Accepts all unambiguous template-declared levels.
  String get contextUseTemplateLevels => _catalog.contextUseTemplateLevels;

  /// Template loading failure on context setup.
  String get contextTemplateFailureHeadline =>
      _catalog.contextTemplateFailureHeadline;

  /// Recovery text after template-level loading fails.
  String get contextTemplateFailureMessage =>
      _catalog.contextTemplateFailureMessage;

  /// No project template exists yet.
  String get contextNoTemplatesHeadline => _catalog.contextNoTemplatesHeadline;

  /// Explains how a project gains fields that can become levels.
  String get contextNoTemplatesMessage => _catalog.contextNoTemplatesMessage;

  /// Opens the contextual Templates route.
  String get contextOpenTemplates => _catalog.contextOpenTemplates;

  /// Templates exist but do not declare a hierarchy.
  String get contextNoDeclaredLevelsHeadline =>
      _catalog.contextNoDeclaredLevelsHeadline;

  /// Explains how to declare template levels.
  String get contextNoDeclaredLevelsMessage =>
      _catalog.contextNoDeclaredLevelsMessage;

  /// Every available field is already part of the hierarchy.
  String get contextNoEligibleFieldsHeadline =>
      _catalog.contextNoEligibleFieldsHeadline;

  /// Explains why the manual picker has no remaining fields.
  String get contextNoEligibleFieldsMessage =>
      _catalog.contextNoEligibleFieldsMessage;

  /// Conflicting level metadata requires explicit correction.
  String get contextTemplateConflictHeadline =>
      _catalog.contextTemplateConflictHeadline;

  /// Names template declaration conflicts without guessing through them.
  String contextTemplateConflictMessage(String conflicts) =>
      _catalog.contextTemplateConflictMessage(conflicts);

  /// Save hierarchy.
  String get contextSaveHierarchy => _catalog.contextSaveHierarchy;

  /// Context picker sheet title prefix.
  String contextPickerTitle(String label) => _catalog.contextPickerTitle(label);

  /// Recent values section.
  String get contextRecents => _catalog.contextRecents;

  /// Dataset search section.
  String get contextDatasetSearch => _catalog.contextDatasetSearch;

  /// Free-text confirm.
  String get contextUseValue => _catalog.contextUseValue;

  /// Label of the picker's free-text field.
  String get contextTypeValue => _catalog.contextTypeValue;

  /// A pin with no value in the pinned-fields sheet.
  String get contextValueNotSet => _catalog.contextValueNotSet;

  /// Removes a pinned value in its picker.
  String get contextClearPin => _catalog.contextClearPin;

  /// Context values joined for the status line; the values are data.
  String contextBreadcrumb(List<String> values) => values.join(' · ');

  /// A pinned field and its value on the context bar; both are data.
  String contextPinnedValue(String field, String value) =>
      _catalog.contextPinnedValue(field, value);

  /// Pin fields sheet.
  String get contextPinnedTitle => _catalog.contextPinnedTitle;

  /// Pin empty.
  String get contextPinnedEmptyHeadline => _catalog.contextPinnedEmptyHeadline;

  /// Pin empty body.
  String get contextPinnedEmptyMessage => _catalog.contextPinnedEmptyMessage;

  /// Pin empty body when the project already has a template.
  String get contextMarkPinnable => _catalog.contextMarkPinnable;

  /// Why pinned context is useful.
  String get contextPinnedRelevance => _catalog.contextPinnedRelevance;

  /// Cascade confirm title.
  String get contextCascadeTitle => _catalog.contextCascadeTitle;

  /// Cascade confirm body in the specification's wording.
  ///
  /// [named] is each lower level and its current value. Level names and
  /// values are operator data, not catalogue keys (FE-L10N-07).
  String contextCascadeMessage({
    required String levelLabel,
    required String newValue,
    required List<String> named,
  }) {
    return _catalog.contextCascadeMessage(levelLabel, newValue, _and(named));
  }

  String _and(List<String> named) {
    return switch (named.length) {
      0 => '',
      1 => named.single,
      2 => _catalog.copyAnd(named[0], named[1]),
      _ => _catalog.copyAndAnd(
        named.sublist(0, named.length - 1).join(', '),
        named.last,
      ),
    };
  }

  /// Cascade confirm action.
  String get contextCascadeConfirm => _catalog.contextCascadeConfirm;

  /// Preset list title.
  String get contextPresetsTitle => _catalog.contextPresetsTitle;

  /// Preset empty.
  String get contextPresetsEmptyHeadline =>
      _catalog.contextPresetsEmptyHeadline;

  /// Preset empty body — next action is to apply a preset.
  String get contextPresetsEmptyMessage => _catalog.contextPresetsEmptyMessage;

  /// Save preset.
  String get contextPresetSave => _catalog.contextPresetSave;

  /// Apply preset.
  String get contextPresetApply => _catalog.contextPresetApply;

  /// Opens the preset list from the context bar.
  String get contextPresetsChip => _catalog.contextPresetsChip;

  /// The preset list row on the context levels screen.
  String get contextPresetsHint => _catalog.contextPresetsHint;

  /// Name field of the save-preset sheet.
  String get contextPresetName => _catalog.contextPresetName;

  /// After a preset was applied; [name] is data.
  String contextPresetApplied(String name) =>
      _catalog.contextPresetApplied(name);

  /// After a preset was saved; [name] is data.
  String contextPresetSaved(String name) => _catalog.contextPresetSaved(name);

  /// Deletes one preset from its row menu.
  String get contextPresetDelete => _catalog.contextPresetDelete;

  /// Confirms a preset delete; [name] is data.
  String contextPresetDeleteMessage(String name) =>
      _catalog.contextPresetDeleteMessage(name);

  /// Stored reason for a preset deleted from the list.
  String get contextPresetDeleteReason => _catalog.contextPresetDeleteReason;

  /// Duplicate preset name.
  String get contextPresetOverwriteTitle =>
      _catalog.contextPresetOverwriteTitle;

  /// Duplicate preset body.
  String get contextPresetOverwriteMessage =>
      _catalog.contextPresetOverwriteMessage;

  /// Confirms replacing a preset of the same name.
  String get contextPresetReplace => _catalog.contextPresetReplace;

  /// Auto-clear undo.
  String get contextAutoClearUndo => _catalog.contextAutoClearUndo;

  /// Auto-clear toast.
  String contextAutoClearMessage(String label) =>
      _catalog.contextAutoClearMessage(label);

  /// Movement prompt title.
  String get contextMovementTitle => _catalog.contextMovementTitle;

  /// Movement prompt body.
  String get contextMovementMessage => _catalog.contextMovementMessage;

  /// Opens the lowest level's picker from the movement prompt.
  String get contextMovementChange => _catalog.contextMovementChange;

  /// Pin chip marker.
  String get contextPinMarker => _catalog.contextPinMarker;

  /// A context level with no value on Capture's bar; [level] is data.
  String contextSetLevel(String level) => _catalog.contextSetLevel(level);

  /// A context level and its value on Capture's bar; both are data.
  String contextLevelValue(String level, String value) =>
      _catalog.contextLevelValue(level, value);

  /// Opens the project's context levels from Capture's bar.
  String get contextManage => _catalog.contextManage;

  /// Opens the project's context levels when it has none yet.
  String get contextSetUp => _catalog.contextSetUp;

  /// Remove one hierarchy level.
  String get contextRemoveLevel => _catalog.contextRemoveLevel;

  /// Semantic name of a level's drag handle; [level] is data.
  String contextDragLevel(String level) => _catalog.contextDragLevel(level);

  /// Idle auto-clear switch. Off until the operator turns it on.
  String get settingsContextAutoClear => _catalog.settingsContextAutoClear;

  /// Why auto-clear stays off.
  String get settingsContextAutoClearEffect =>
      _catalog.settingsContextAutoClearEffect;

  /// Idle interval row.
  String settingsContextIdleSubtitle(int minutes) =>
      _catalog.settingsContextIdleSubtitle(minutes);

  /// Movement confirmation switch. Off until the operator turns it on.
  String get settingsContextMovement => _catalog.settingsContextMovement;

  /// Why the movement prompt stays off, and that it does not edit context.
  String get settingsContextMovementEffect =>
      _catalog.settingsContextMovementEffect;

  /// Distance row.
  String settingsContextDistanceSubtitle(int metres) =>
      _catalog.settingsContextDistanceSubtitle(metres);

  /// Idle interval choice: how long the context waits before clearing.
  String get settingsContextIdle => _catalog.settingsContextIdle;

  /// What the idle interval changes.
  String get settingsContextIdleEffect => _catalog.settingsContextIdleEffect;

  /// One idle interval, in minutes.
  String settingsContextIdleOption(int minutes) {
    return _catalog.settingsContextIdleOption(minutes);
  }

  /// Movement distance choice: how far a move is before Tapture asks.
  String get settingsContextDistance => _catalog.settingsContextDistance;

  /// What the movement distance changes.
  String get settingsContextDistanceEffect =>
      _catalog.settingsContextDistanceEffect;

  /// One movement distance, in metres.
  String settingsContextDistanceOption(int metres) {
    return _catalog.settingsContextDistanceOption(metres);
  }

  /// Capture screen title.
  String get captureTitle => _catalog.captureTitle;

  /// Primary save that also enqueues analysis.
  String get captureSaveAndAnalyse => _catalog.captureSaveAndAnalyse;

  /// Why Save and process is off while the device is offline.
  String get captureProcessNeedsNetwork => _catalog.captureProcessNeedsNetwork;

  /// Raw save with no processing.
  String get captureSaveRaw => _catalog.captureSaveRaw;

  /// Empty tray headline.
  String get captureNoPhotosHeadline => _catalog.captureNoPhotosHeadline;

  /// Empty tray body — evidence is the only requirement.
  String get captureNoPhotosMessage => _catalog.captureNoPhotosMessage;

  /// Project selector on the capture surface.
  String get captureProjectLabel => _catalog.captureProjectLabel;

  /// Capture is open and projects exist, but none is selected.
  String get captureChooseProject => _catalog.captureChooseProject;

  /// Capture is open and there is no project to file it under.
  String get captureCreateProjectFirst => _catalog.captureCreateProjectFirst;

  /// Why capture needs a project, under the no-project headline.
  String get captureNoProjectMessage => _catalog.captureNoProjectMessage;

  /// A project is open, but it has no template to capture against.
  String get captureNeedsTemplate => _catalog.captureNeedsTemplate;

  /// More fields expander.
  String get captureMoreFields => _catalog.captureMoreFields;

  /// Camera permission reason before the system prompt.
  String get captureCameraReason => _catalog.captureCameraReason;

  /// Open system settings after a permanent camera refusal.
  String get captureOpenCameraSettings => _catalog.captureOpenCameraSettings;

  /// Asks the system for the camera after the reason is shown.
  String get captureAllowCamera => _catalog.captureAllowCamera;

  /// Title of the full-screen live camera.
  String get captureCameraTitle => _catalog.captureCameraTitle;

  /// Keep a photo despite a quality warning.
  String get captureKeepPhoto => _catalog.captureKeepPhoto;

  /// Retake after a quality warning.
  String get captureRetakePhoto => _catalog.captureRetakePhoto;

  /// Document mode toggle on the live camera.
  String get captureDocumentMode => _catalog.captureDocumentMode;

  /// Document mode found the page and offers the straightened copy.
  String get capturePageBoundaryFound => _catalog.capturePageBoundaryFound;

  /// Use the perspective-corrected copy beside the original.
  String get captureUseCorrected => _catalog.captureUseCorrected;

  /// Document mode could not straighten the page.
  String get captureCorrectionFailed => _catalog.captureCorrectionFailed;

  /// Document mode found no page boundary.
  String get captureNoPageBoundary => _catalog.captureNoPageBoundary;

  /// Flash control label while the flash stays off.
  String get captureFlashOff => _catalog.captureFlashOff;

  /// Flash control label while the device decides.
  String get captureFlashAuto => _catalog.captureFlashAuto;

  /// Flash control label while the flash fires.
  String get captureFlashOn => _catalog.captureFlashOn;

  /// Grid control semantic label.
  String get captureGrid => _catalog.captureGrid;

  /// Focus indicator semantic label.
  String get captureFocus => _catalog.captureFocus;

  /// Zoom-out control label.
  String get captureZoomOut => _catalog.captureZoomOut;

  /// Zoom-in control label.
  String get captureZoomIn => _catalog.captureZoomIn;

  /// Gallery import action.
  String get captureImportGallery => _catalog.captureImportGallery;

  /// Document import action.
  String get captureImportDocument => _catalog.captureImportDocument;

  /// Import cannot start before the document store is available.
  String get captureDocumentsUnavailable =>
      _catalog.captureDocumentsUnavailable;

  /// Recovery for unavailable document storage.
  String get captureDocumentsUnavailableRecovery =>
      _catalog.captureDocumentsUnavailableRecovery;

  /// Rejected import names the reason.
  String captureImportRejected(String reason) => reason;

  /// Try another file recovery.
  String get tryAnotherFile => _catalog.tryAnotherFile;

  /// PDF bytes were not a valid document.
  String get pdfInvalid => _catalog.pdfInvalid;

  /// Names an imported document whose contents cannot be safely read.
  String captureDocumentInvalid(String filename) =>
      _catalog.captureDocumentInvalid(filename);

  /// Requested page is outside the document.
  String get pdfPageMissing => _catalog.pdfPageMissing;

  /// Moves through lazily rendered document pages.
  String get pdfPreviousPage => _catalog.pdfPreviousPage;

  /// Moves through lazily rendered document pages.
  String get pdfNextPage => _catalog.pdfNextPage;

  /// Barcode scanner unavailable on this build.
  String get barcodeUnavailable => _catalog.barcodeUnavailable;

  /// Recovery for a refused scanner camera; typing still works meanwhile.
  String get barcodeAllowCamera => _catalog.barcodeAllowCamera;

  /// Confirm a decoded barcode.
  String get barcodeConfirm => _catalog.barcodeConfirm;

  /// Scan again after a decode.
  String get barcodeRescan => _catalog.barcodeRescan;

  /// No code in the region yet.
  String get barcodeNoCode => _catalog.barcodeNoCode;

  /// Title of the barcode scanner screen.
  String get barcodeTitle => _catalog.barcodeTitle;

  /// Torch toggle on the barcode scanner.
  String get barcodeTorch => _catalog.barcodeTorch;

  /// Unreadable code.
  String get barcodeUnreadable => _catalog.barcodeUnreadable;

  /// Continuous mode running count.
  String barcodeScanCount(int n) => _catalog.barcodeScanCount(n);

  /// A counted code's place in the continuous-mode tally.
  String barcodeCountPosition(int n) => _catalog.barcodeCountPosition(n);

  /// Continuous-mode toggle on the barcode scanner.
  String get barcodeCountMode => _catalog.barcodeCountMode;

  /// Undo last continuous scan.
  String get barcodeUndoLast => _catalog.barcodeUndoLast;

  /// Identifier matched a project record.
  String get identifierMatchRecord => _catalog.identifierMatchRecord;

  /// Identifier matched a reference row.
  String get identifierMatchReference => _catalog.identifierMatchReference;

  /// Identifier matched nothing — start a new record.
  String get identifierNewRecord => _catalog.identifierNewRecord;

  /// Several records share the identifier.
  String get identifierDuplicates => _catalog.identifierDuplicates;

  /// Record caption field label.
  String get captureRecordCaption => _catalog.captureRecordCaption;

  /// Photo group on the capture surface.
  String get capturePhotosSection => _catalog.capturePhotosSection;

  /// Audio group on the capture surface.
  String get captureAudioSection => _catalog.captureAudioSection;

  /// Removes one draft photo from the capture tray.
  String get captureRemovePhoto => _catalog.captureRemovePhoto;

  /// Adds the typed caption to every photo, when none is ticked.
  String captionAddToAll(int n) => _catalog.captionAddToAll(n);

  /// Adds the typed caption to the ticked photos only.
  String captionAddToTicked(int n) => _catalog.captionAddToTicked(n);

  /// Says how many photos a caption was just added to.
  String captionAdded(int n) => _catalog.captionAdded(n);

  /// Append caption mode.
  String get captionAppend => _catalog.captionAppend;

  /// Replace caption mode.
  String get captionReplace => _catalog.captionReplace;

  /// Microphone permission reason.
  String get captureMicReason => _catalog.captureMicReason;

  /// Voice input listening state.
  String get captureListening => _catalog.captureListening;

  /// Audio recorder start.
  String get captureRecordAudio => _catalog.captureRecordAudio;

  /// Audio recorder pause.
  String get capturePauseAudio => _catalog.capturePauseAudio;

  /// Audio recorder stop.
  String get captureStopAudio => _catalog.captureStopAudio;

  /// Audio recorder unavailable.
  String get audioRecorderUnavailable => _catalog.audioRecorderUnavailable;

  /// Refusal when another recording already holds the microphone.
  String get microphoneBusy => _catalog.microphoneBusy;

  /// The recorder refused to start a take.
  String get audioStartFailed => _catalog.audioStartFailed;

  /// Recovery for [audioStartFailed].
  String get audioStartFailedRecovery => _catalog.audioStartFailedRecovery;

  /// A recording path that would leave the storage folder.
  String get audioPathOutsideStorage => _catalog.audioPathOutsideStorage;

  /// Microphone permission failure and recovery.
  String get audioPermissionDenied => _catalog.audioPermissionDenied;

  /// Tells the operator how to grant microphone access.
  String get audioPermissionRecovery => _catalog.audioPermissionRecovery;

  /// Recorder phase and elapsed time.
  String audioRecorderStatus(String phase, int seconds) {
    final String label = switch (phase) {
      'permission' => _catalog.audioRecorderStatus,
      'recording' => _catalog.audioRecorderStatusRecording,
      'paused' => _catalog.audioRecorderStatusPaused,
      'finalizing' => _catalog.audioRecorderStatusSavingAudio,
      'failed' => _catalog.audioRecorderStatusAudioFailed,
      'completed' => _catalog.audioRecorderStatusAudioSaved,
      _ => _catalog.audioRecorderStatusAudioReady,
    };
    return _catalog.audioRecorderStatusS(label, seconds);
  }

  /// Recording bar control that starts a recording with a live transcript.
  String get liveTranscriptStart => _catalog.liveTranscriptStart;

  /// Recording bar control that discards the recording in progress.
  String get liveTranscriptCancel => _catalog.liveTranscriptCancel;

  /// Recording bar status while the microphone opens.
  String get liveTranscriptStatusStarting =>
      _catalog.liveTranscriptStatusStarting;

  /// Recording bar status while audio is recorded and transcribed.
  String get liveTranscriptStatusListening =>
      _catalog.liveTranscriptStatusListening;

  /// Recording bar status while the recording is paused.
  String get liveTranscriptStatusPaused => _catalog.liveTranscriptStatusPaused;

  /// Recording bar status while the recording is closed and the transcript
  /// completes.
  String get liveTranscriptStatusFinishing =>
      _catalog.liveTranscriptStatusFinishing;

  /// Transcript view before any words are recognised.
  String get liveTranscriptEmpty => _catalog.liveTranscriptEmpty;

  /// Transcript view control that scrolls back to the newest words.
  String get liveTranscriptJumpToLatest => _catalog.liveTranscriptJumpToLatest;

  /// Accessible name of the transcript view.
  String get transcriptViewLabel => _catalog.transcriptViewLabel;

  /// Audio evidence association sheet.
  String get captureAudioScopeTitle => _catalog.captureAudioScopeTitle;

  /// Associates the clip with the most recent/current photo.
  String get captureAudioCurrentPhoto => _catalog.captureAudioCurrentPhoto;

  /// Associates the clip with the selected photos.
  String captureAudioSelectedPhotos(int count) =>
      _catalog.captureAudioSelectedPhotos(count);

  /// Associates the clip with every photo.
  String captureAudioAllPhotos(int count) =>
      _catalog.captureAudioAllPhotos(count);

  /// Number of durable clips in this capture.
  String captureAudioCount(int count) => _catalog.captureAudioCount(count);

  /// Delete photo confirm title.
  String get captureDeletePhotoTitle => _catalog.captureDeletePhotoTitle;

  /// Delete photo confirm body.
  String get captureDeletePhotoMessage => _catalog.captureDeletePhotoMessage;

  /// Undo delete snack.
  String get captureUndoDelete => _catalog.captureUndoDelete;

  /// Photo deleted snack.
  String get capturePhotoDeleted => _catalog.capturePhotoDeleted;

  /// Move photos action.
  String get captureMovePhotos => _catalog.captureMovePhotos;

  /// Recovery prompt title.
  String get captureRecoveryTitle => _catalog.captureRecoveryTitle;

  /// Recovery prompt with photo count.
  String captureRecoveryMessage(int photos) {
    return _catalog.captureRecoveryMessage(photos);
  }

  /// Resume interrupted session.
  String get captureResume => _catalog.captureResume;

  /// Discard interrupted session.
  String get captureDiscard => _catalog.captureDiscard;

  /// A discarded session, offered back through Undo.
  String get captureSessionDiscarded => _catalog.captureSessionDiscarded;

  /// Rapid mode title.
  String get captureRapidMode => _catalog.captureRapidMode;

  /// One saved item in the rapid-mode list, numbered from 1.
  String captureRapidItem(int number) => _catalog.captureRapidItem(number);

  /// A saved rapid-mode item's line: its photo count, then its caption.
  String captureRapidSummary(int photos, String caption) => caption.isEmpty
      ? photosCount(photos)
      : _catalog.captureRapidSummary(photosCount(photos), caption);

  /// Rapid mode's one-tap action: save this item raw and start the next.
  String get captureRapidNext => _catalog.captureRapidNext;

  /// Rapid mode's secondary action: queue every item of the run.
  String captureRapidProcessAll(int count) =>
      _catalog.captureRapidProcessAll(count);

  /// Rapid mode queued the run for processing.
  String captureRapidQueued(int count) => _catalog.captureRapidQueued(count);

  /// Rapid mode before any item is saved.
  String get captureRapidEmptyHeadline => _catalog.captureRapidEmptyHeadline;

  /// What to do first in rapid mode.
  String get captureRapidEmptyMessage => _catalog.captureRapidEmptyMessage;

  /// The photos of the item being captured in rapid mode.
  String captureRapidCurrent(int photos) =>
      _catalog.captureRapidCurrent(photosCount(photos));

  /// Storage warning, naming the free space left.
  String captureStorageLow(String free) => _catalog.captureStorageLow(free);

  /// Storage stop, naming the free space left and the way out.
  String captureStorageFull(String free) => _catalog.captureStorageFull(free);

  /// Storage stop offers export.
  String get captureStorageExport => _catalog.captureStorageExport;

  /// A project with no templates still captures; this offers adding one.
  String get captureNoTemplates => _catalog.captureNoTemplates;

  /// Template picker title.
  String get capturePickTemplate => _catalog.capturePickTemplate;

  /// Pin template for this session.
  String get capturePinSession => _catalog.capturePinSession;

  /// A template was pinned to the current context level.
  String get captureTemplatePinned => _catalog.captureTemplatePinned;

  /// Pin template for this context level.
  String get capturePinContext => _catalog.capturePinContext;

  /// Multi-select count.
  String captureSelectedCount(int n) => _catalog.captureSelectedCount(n);

  /// Select all photos.
  String get captureSelectAll => _catalog.captureSelectAll;

  /// Clear photo selection.
  String get captureClearSelection => _catalog.captureClearSelection;

  /// Add photo to tray.
  String get captureAddPhoto => _catalog.captureAddPhoto;

  /// Sheet title for adding a photo.
  String get captureAddSheetTitle => _catalog.captureAddSheetTitle;

  /// Camera action on the add-photo sheet.
  String get captureTakePhoto => _catalog.captureTakePhoto;

  /// Library action on the add-photo sheet.
  String get captureChoosePhoto => _catalog.captureChoosePhoto;

  /// Quality blur advisory.
  String get captureQualityBlur => _catalog.captureQualityBlur;

  /// Quality dark advisory.
  String get captureQualityDark => _catalog.captureQualityDark;

  /// Quality overexposed advisory.
  String get captureQualityBright => _catalog.captureQualityBright;

  /// Quality small-text advisory.
  String get captureQualitySmallText => _catalog.captureQualitySmallText;

  /// Saved announcement for screen readers.
  String get captureSaved => _catalog.captureSaved;

  /// Saving announcement.
  String get captureSaving => _catalog.captureSaving;

  /// Save failed announcement.
  String get captureSaveFailed => _catalog.captureSaveFailed;

  /// Raw evidence committed, but the local processing job did not enqueue.
  String get captureEnqueueFailed => _catalog.captureEnqueueFailed;

  /// A save with nothing to save.
  String get captureNeedsEvidence => _catalog.captureNeedsEvidence;

  /// What to do about [captureNeedsEvidence].
  String get captureNeedsEvidenceRecovery =>
      _catalog.captureNeedsEvidenceRecovery;

  /// A reorder that would drop photos.
  String get captureOrderIncomplete => _catalog.captureOrderIncomplete;

  /// What to do about [captureOrderIncomplete].
  String get captureOrderIncompleteRecovery =>
      _catalog.captureOrderIncompleteRecovery;

  /// A capture change the device could not store.
  String get captureChangeNotSaved => _catalog.captureChangeNotSaved;

  /// What to do about [captureChangeNotSaved].
  String get captureChangeNotSavedRecovery =>
      _catalog.captureChangeNotSavedRecovery;

  /// Editing a saved record where no record store is available.
  String get captureRecordsUnavailable => _catalog.captureRecordsUnavailable;

  /// What to do about [captureRecordsUnavailable].
  String get captureRecordsUnavailableRecovery =>
      _catalog.captureRecordsUnavailableRecovery;

  /// Status line when no template is pinned.
  String get statusNoTemplate => _catalog.statusNoTemplate;

  /// Project and context together on the status line.
  String statusWhere(String project, String context) {
    return _catalog.statusWhere(project, context);
  }

  /// Unmetered path.
  String get networkOnline => _catalog.networkOnline;

  /// Metered path.
  String get networkMetered => _catalog.networkMetered;

  /// Radio is down; not an operator choice.
  String get networkOffline => _catalog.networkOffline;

  /// The operator forced offline.
  String get networkOfflineByChoice => _catalog.networkOfflineByChoice;

  /// Manual offline switch title.
  String get settingsOfflineTitle => _catalog.settingsOfflineTitle;

  /// What keeps working while the switch is on.
  String get settingsOfflineEffect => _catalog.settingsOfflineEffect;

  /// How many records still need processing.
  String unprocessedCount(int n) {
    return _catalog.unprocessedCount(n);
  }

  /// A count on a small badge, locale-formatted and capped so 200 percent
  /// text cannot push the icon out. The control's label keeps the exact
  /// count.
  String badgeCount(int n) {
    return _withLocale(() {
      if (n > 99) {
        return '99+';
      }
      return NumberFormat.decimalPattern().format(n);
    });
  }

  /// Why work continues without a network. Not an error.
  String get offlineWorking => _catalog.offlineWorking;

  /// Title of the last-resort crash recovery screen.
  String get somethingWentWrong => _catalog.somethingWentWrong;

  /// Reassurance that a crash did not wipe local work.
  String get workStillOnDevice => _catalog.workStillOnDevice;

  /// Remounts the failed subtree under the existing provider scope.
  String get restart => _catalog.restart;

  /// Writes the diagnostics buffer to a shareable file.
  String get exportLog => _catalog.exportLog;

  /// Opens the recycle bin.
  String get openRecycleBin => _catalog.openRecycleBin;

  /// Title of the page an unknown path opens.
  String get notFoundTitle => _catalog.notFoundTitle;

  /// Why an unknown path shows no screen. [path] is shown as given.
  String notFoundMessage(String path) => _catalog.notFoundMessage(path);

  /// Recovery for an unknown path. Try again opens Projects.
  String get notFoundRecovery => _catalog.notFoundRecovery;

  /// Window and task-switcher title of the development install.
  String get appNameDev => _catalog.appNameDev;

  /// Settings root title.
  String get settingsTitle => _catalog.settingsTitle;

  /// Settings index group headings.
  String get settingsGroupProfileCapture =>
      _catalog.settingsGroupProfileCapture;

  /// Settings for AI and visual appearance.
  String get settingsGroupIntelligenceAppearance =>
      _catalog.settingsGroupIntelligenceAppearance;

  /// Settings for durable storage and access protection.
  String get settingsGroupStorageSecurity =>
      _catalog.settingsGroupStorageSecurity;

  /// Product information settings group.
  String get settingsGroupAbout => _catalog.settingsGroupAbout;

  /// Operator tile supporting line.
  String get settingsOperatorSubtitle => _catalog.settingsOperatorSubtitle;

  /// Capture tile supporting line.
  String get settingsCaptureSubtitle => _catalog.settingsCaptureSubtitle;

  /// Capture settings: the row and its page share this title, and it is
  /// not the Capture destination's name.
  String get settingsCaptureTitle => _catalog.settingsCaptureTitle;

  /// Relay row under Settings.
  String get settingsRelaySubtitle => _catalog.settingsRelaySubtitle;

  /// AI section title. The screen arrives in a later phase.
  String get settingsAiTitle => _catalog.settingsAiTitle;

  /// AI tile supporting line.
  String get settingsAiSubtitle => _catalog.settingsAiSubtitle;

  /// Language section title. The screen arrives in a later phase.
  String get settingsLanguageTitle => _catalog.settingsLanguageTitle;

  /// Language tile supporting line.
  String get settingsLanguageSubtitle => _catalog.settingsLanguageSubtitle;

  /// The language screens and messages are shown in.
  String get settingsAppLanguage => _catalog.settingsAppLanguage;

  /// Why the app language offers one choice today.
  String get settingsAppLanguageEffect => _catalog.settingsAppLanguageEffect;

  /// The language dictation listens for.
  String get settingsVoiceLanguage => _catalog.settingsVoiceLanguage;

  /// Voice-language names, each in its own language's usual English name.
  String get languageEnglish => _catalog.languageEnglish;

  /// French.
  String get languageFrench => _catalog.languageFrench;

  /// Swahili.
  String get languageSwahili => _catalog.languageSwahili;

  /// Portuguese.
  String get languagePortuguese => _catalog.languagePortuguese;

  /// Spanish.
  String get languageSpanish => _catalog.languageSpanish;

  /// Arabic.
  String get languageArabic => _catalog.languageArabic;

  /// Appearance section title.
  String get settingsAppearanceTitle => _catalog.settingsAppearanceTitle;

  /// Appearance tile supporting line.
  String get settingsAppearanceSubtitle => _catalog.settingsAppearanceSubtitle;

  /// Follow the device light or dark setting.
  String get themeModeSystem => _catalog.themeModeSystem;

  /// Always the light palette.
  String get themeModeLight => _catalog.themeModeLight;

  /// Always the dark palette.
  String get themeModeDark => _catalog.themeModeDark;

  /// High-contrast outdoor palettes; still follows the device.
  String get themeModeOutdoor => _catalog.themeModeOutdoor;

  /// Storage section title.
  String get settingsStorageTitle => _catalog.settingsStorageTitle;

  /// Storage tile supporting line.
  String get settingsStorageSubtitle => _catalog.settingsStorageSubtitle;

  /// Specification "Data" section. Copy rejects the word "data".
  String get settingsFilesTitle => _catalog.settingsFilesTitle;

  /// Files tile supporting line.
  String get settingsFilesSubtitle => _catalog.settingsFilesSubtitle;

  /// Files row that opens the open project's exports.
  String get settingsFilesExportSubtitle =>
      _catalog.settingsFilesExportSubtitle;

  /// Files row that brings a package or spreadsheet in.
  String get settingsFilesImportSubtitle =>
      _catalog.settingsFilesImportSubtitle;

  /// Files row that opens the open project's merge.
  String get settingsFilesMergeSubtitle => _catalog.settingsFilesMergeSubtitle;

  /// Why export and merge are not offered with no project open.
  String get settingsFilesNoProject => _catalog.settingsFilesNoProject;

  /// Files row for past uploads.
  String get settingsFilesUploadsSubtitle =>
      _catalog.settingsFilesUploadsSubtitle;

  /// Security section title. The screen arrives in a later phase.
  String get settingsSecurityTitle => _catalog.settingsSecurityTitle;

  /// Security tile supporting line.
  String get settingsSecuritySubtitle => _catalog.settingsSecuritySubtitle;

  /// About section title.
  String get settingsAboutTitle => _catalog.settingsAboutTitle;

  /// About tile supporting line.
  String get settingsAboutSubtitle => _catalog.settingsAboutSubtitle;

  /// Templates row under Settings.
  String get settingsTemplatesSubtitle => _catalog.settingsTemplatesSubtitle;

  /// Unprocessed row under Settings.
  String get settingsQueueSubtitle => _catalog.settingsQueueSubtitle;

  /// Camera default row.
  String get settingsCamera => _catalog.settingsCamera;

  /// Effect of the camera default.
  String get settingsCameraEffect => _catalog.settingsCameraEffect;

  /// Label for the photo camera default.
  String get settingsCameraPhoto => _catalog.settingsCameraPhoto;

  /// Document camera default.
  String get settingsCameraDocument => _catalog.settingsCameraDocument;

  /// Auto-filled dates row.
  String get settingsAutoFillDates => _catalog.settingsAutoFillDates;

  /// Effect of auto-filled dates.
  String get settingsAutoFillDatesEffect =>
      _catalog.settingsAutoFillDatesEffect;

  /// GPS row.
  String get settingsGps => _catalog.settingsGps;

  /// Why GPS stays off until a person turns it on (FE-SEC-07).
  String get settingsGpsWhyOff => _catalog.settingsGpsWhyOff;

  /// Photo quality row.
  String get settingsPhotoQuality => _catalog.settingsPhotoQuality;

  /// Effect of photo quality.
  String get settingsPhotoQualityEffect => _catalog.settingsPhotoQualityEffect;

  /// Standard JPEG quality label.
  String get settingsQualityStandard => _catalog.settingsQualityStandard;

  /// Smaller JPEG quality label.
  String get settingsQualitySmaller => _catalog.settingsQualitySmaller;

  /// Folder strategy row.
  String get settingsFolderStrategy => _catalog.settingsFolderStrategy;

  /// Folder strategy applies only to files not yet written.
  String get settingsFolderStrategyNewFilesOnly =>
      _catalog.settingsFolderStrategyNewFilesOnly;

  /// Folder strategy: group by context.
  String get settingsFolderByContext => _catalog.settingsFolderByContext;

  /// Folder strategy: group by template.
  String get settingsFolderByTemplate => _catalog.settingsFolderByTemplate;

  /// Folder strategy: group by capture date.
  String get settingsFolderByDate => _catalog.settingsFolderByDate;

  /// Folder strategy: no extra folders.
  String get settingsFolderFlat => _catalog.settingsFolderFlat;

  /// Naming pattern row.
  String get settingsNamingPattern => _catalog.settingsNamingPattern;

  /// Sheet title when editing the naming pattern.
  String get settingsNamingEdit => _catalog.settingsNamingEdit;

  /// Effect of the naming pattern.
  String get settingsNamingPatternEffect =>
      _catalog.settingsNamingPatternEffect;

  /// Camera row, including the current value and its effect.
  String settingsCameraSubtitle(String label) {
    return _catalog.settingsCameraSubtitle(label, settingsCameraEffect);
  }

  /// Photo-quality row, including the current value and its effect.
  String settingsPhotoQualitySubtitle(String label) {
    return _catalog.settingsPhotoQualitySubtitle(
      label,
      settingsPhotoQualityEffect,
    );
  }

  /// Naming-pattern row, including the current value and its effect.
  String settingsNamingSubtitle(String pattern) {
    return _catalog.settingsNamingSubtitle(
      pattern,
      settingsNamingPatternEffect,
    );
  }

  /// Folder strategy row, including the new-files-only statement.
  String settingsFolderStrategySubtitle(String strategy) {
    return _catalog.settingsFolderStrategySubtitle(
      strategy,
      settingsFolderStrategyNewFilesOnly,
    );
  }

  /// Projects group on the storage screen.
  String get settingsProjectsHeader => _catalog.settingsProjectsHeader;

  /// Free-space group on the storage screen.
  String get settingsHeadroomHeader => _catalog.settingsHeadroomHeader;

  /// Retention group on the storage screen.
  String get settingsRetentionHeader => _catalog.settingsRetentionHeader;

  /// Storage-root row name.
  String get settingsStorageRoot => _catalog.settingsStorageRoot;

  /// Snack after a new storage folder is saved: files move there on restart.
  String get settingsStorageRootAfterRestart =>
      _catalog.settingsStorageRootAfterRestart;

  /// Total volume label.
  String get settingsVolumeTotal => _catalog.settingsVolumeTotal;

  /// Used volume label.
  String get settingsVolumeUsed => _catalog.settingsVolumeUsed;

  /// Available volume label.
  String get settingsVolumeAvailable => _catalog.settingsVolumeAvailable;

  /// The three volume figures on one line.
  String settingsVolumeFigures({
    required String total,
    required String used,
    required String available,
  }) {
    return _catalog.settingsVolumeFigures(
      settingsVolumeTotal,
      total,
      settingsVolumeUsed,
      used,
      settingsVolumeAvailable,
      available,
    );
  }

  /// Headroom is ample.
  String get settingsHeadroomAmple => _catalog.settingsHeadroomAmple;

  /// Headroom is low.
  String get settingsHeadroomLow => _catalog.settingsHeadroomLow;

  /// Headroom is critical.
  String get settingsHeadroomCritical => _catalog.settingsHeadroomCritical;

  /// Clear-cache row.
  String get settingsClearCache => _catalog.settingsClearCache;

  /// Effect of clearing the cache.
  String get settingsClearCacheEffect => _catalog.settingsClearCacheEffect;

  /// Cache row with the current size.
  String settingsCacheSize(String size) {
    return _catalog.settingsCacheSize(
      settingsCache,
      size,
      settingsClearCacheEffect,
    );
  }

  /// Retention row with the current window.
  String settingsRetentionSubtitle(int days) {
    return _catalog.settingsRetentionSubtitle(
      settingsRetentionDays(days),
      settingsRetentionEffect,
    );
  }

  /// Confirm title for clearing the cache.
  String get settingsClearCacheTitle => _catalog.settingsClearCacheTitle;

  /// Confirm body for clearing the cache.
  String get settingsClearCacheMessage => _catalog.settingsClearCacheMessage;

  /// Storage row, and the page, that checks files against their records.
  String get storageCheckTitle => _catalog.storageCheckTitle;

  /// What checking files does.
  String get storageCheckSubtitle => _catalog.storageCheckSubtitle;

  /// Heading over the check of the database's own references.
  String get storageCheckDatabaseHeader => _catalog.storageCheckDatabaseHeader;

  /// Every reference in the database resolves.
  String get storageCheckDatabaseClean => _catalog.storageCheckDatabaseClean;

  /// One broken reference: the table it sits in and the row's id.
  String storageCheckFindingRow(String table, String id) {
    return _catalog.storageCheckFindingRow(table, id);
  }

  /// Heading over the open project's file check.
  String storageCheckProjectHeader(String project) {
    return _catalog.storageCheckProjectHeader(project);
  }

  /// No project is open, so there is no folder to check.
  String get storageCheckNoProject => _catalog.storageCheckNoProject;

  /// The open project's folder and its records agree.
  String get storageCheckFilesClean => _catalog.storageCheckFilesClean;

  /// The file check cannot run where the app keeps no project files.
  String get storageCheckFilesUnavailable =>
      _catalog.storageCheckFilesUnavailable;

  /// What to do when the file check cannot run here.
  String get storageCheckFilesUnavailableAction =>
      _catalog.storageCheckFilesUnavailableAction;

  /// Heading over files no record points at.
  String get storageCheckStrayHeader => _catalog.storageCheckStrayHeader;

  /// A stray file: its size and what tapping it does.
  String storageCheckStraySubtitle(String size) {
    return _catalog.storageCheckStraySubtitle(size);
  }

  /// Heading over records whose file is gone.
  String get storageCheckMissingHeader => _catalog.storageCheckMissingHeader;

  /// A record whose file is gone, before it is marked.
  String get storageCheckMissingSubtitle =>
      _catalog.storageCheckMissingSubtitle;

  /// Confirm title for marking a file as missing.
  String get storageCheckFlagTitle => _catalog.storageCheckFlagTitle;

  /// Confirm body for marking a file as missing.
  String get storageCheckFlagMessage => _catalog.storageCheckFlagMessage;

  /// Confirm action for marking a file as missing.
  String get storageCheckFlagConfirm => _catalog.storageCheckFlagConfirm;

  /// Outcome after marking a file as missing.
  String get storageCheckFlagged => _catalog.storageCheckFlagged;

  /// Sheet title for attaching a stray file to a record.
  String get storageCheckAttachTitle => _catalog.storageCheckAttachTitle;

  /// Outcome after attaching a stray file.
  String get storageCheckAttached => _catalog.storageCheckAttached;

  /// The project has no record to attach a file to.
  String get storageCheckNoRecords => _catalog.storageCheckNoRecords;

  /// Why a stray file cannot be attached yet.
  String get storageCheckNoRecordsMessage =>
      _catalog.storageCheckNoRecordsMessage;

  /// Retention row.
  String get settingsRetention => _catalog.settingsRetention;

  /// Effect of the retention window.
  String get settingsRetentionEffect => _catalog.settingsRetentionEffect;

  /// Retention window in days.
  String settingsRetentionDays(int n) {
    return _catalog.settingsRetentionDays(n);
  }

  /// Documents breakdown label.
  String get settingsDocuments => _catalog.settingsDocuments;

  /// Audio breakdown label.
  String get settingsAudio => _catalog.settingsAudio;

  /// Exports breakdown label.
  String get settingsExports => _catalog.settingsExports;

  /// Cache usage row title.
  String get settingsCache => _catalog.settingsCache;

  /// Empty storage headline.
  String get settingsStorageEmptyHeadline =>
      _catalog.settingsStorageEmptyHeadline;

  /// Empty storage next step.
  String get settingsStorageEmptyMessage =>
      _catalog.settingsStorageEmptyMessage;

  /// A file size shown on the storage screen.
  String fileSize(int bytes) {
    const int k = 1024;
    if (bytes < k) {
      return _catalog.fileSize(bytes);
    }
    if (bytes < k * k) {
      return _catalog.fileSizeKB((bytes / k).round());
    }
    if (bytes < k * k * k) {
      return _catalog.fileSizeMB((bytes / (k * k)).round());
    }
    return _catalog.fileSizeGB((bytes / (k * k * k)).round());
  }

  /// Per-project breakdown on one line.
  String settingsProjectUse({
    required String photos,
    required String documents,
    required String audio,
    required String exports,
  }) {
    return _catalog.settingsProjectUse(
      photos,
      settingsDocuments,
      documents,
      settingsAudio,
      audio,
      settingsExports,
      exports,
    );
  }

  /// Version row.
  String get settingsVersion => _catalog.settingsVersion;

  /// Build-number row.
  String get settingsBuild => _catalog.settingsBuild;

  /// Licences row.
  String get settingsLicences => _catalog.settingsLicences;

  /// Effect of the licences row.
  String get settingsLicencesEffect => _catalog.settingsLicencesEffect;

  /// About row linking the development plan.
  String get settingsPlanLink => _catalog.settingsPlanLink;

  /// About row linking the product specification.
  String get settingsSpecLink => _catalog.settingsSpecLink;

  /// A link was copied because no browser can be opened from here.
  String get settingsLinkCopied => _catalog.settingsLinkCopied;

  /// Empty settings headline.
  String get settingsEmptyHeadline => _catalog.settingsEmptyHeadline;

  /// Empty settings next step.
  String get settingsEmptyMessage => _catalog.settingsEmptyMessage;

  /// Empty capture-settings headline.
  String get settingsCaptureEmptyHeadline =>
      _catalog.settingsCaptureEmptyHeadline;

  /// Empty capture-settings next step.
  String get settingsCaptureEmptyMessage =>
      _catalog.settingsCaptureEmptyMessage;

  /// Empty about headline.
  String get settingsAboutEmptyHeadline => _catalog.settingsAboutEmptyHeadline;

  /// Empty about next step.
  String get settingsAboutEmptyMessage => _catalog.settingsAboutEmptyMessage;

  /// Unlock-gate title.
  String get appLockUnlockTitle => _catalog.appLockUnlockTitle;

  /// Settings title for the PIN lock.
  String get appLockTitle => _catalog.appLockTitle;

  /// PIN field.
  String get appLockPin => _catalog.appLockPin;

  /// Current PIN when changing or removing the lock.
  String get appLockCurrentPin => _catalog.appLockCurrentPin;

  /// New PIN when setting or changing the lock.
  String get appLockNewPin => _catalog.appLockNewPin;

  /// Confirm-PIN field.
  String get appLockConfirmPin => _catalog.appLockConfirmPin;

  /// Sets the lock for the first time.
  String get appLockSet => _catalog.appLockSet;

  /// Replaces the stored PIN.
  String get appLockChange => _catalog.appLockChange;

  /// Turns the lock off.
  String get appLockRemove => _catalog.appLockRemove;

  /// Unlock-gate submit.
  String get appLockUnlock => _catalog.appLockUnlock;

  /// Offers the device biometric path when it is enrolled.
  String get appLockBiometrics => _catalog.appLockBiometrics;

  /// Effect of setting a PIN.
  String get appLockSetEffect => _catalog.appLockSetEffect;

  /// Effect of removing the PIN.
  String get appLockRemoveEffect => _catalog.appLockRemoveEffect;

  /// Confirm title before the PIN is removed.
  String get appLockRemoveConfirmTitle => _catalog.appLockRemoveConfirmTitle;

  /// Helper under the current-PIN field while the lock is on.
  String get appLockCurrentPinHelper => _catalog.appLockCurrentPinHelper;

  /// Remove was chosen with the current-PIN field empty.
  String get appLockRemoveNeedsPin => _catalog.appLockRemoveNeedsPin;

  /// Stated when the lock is armed.
  String get appLockOn => _catalog.appLockOn;

  /// Stated when no PIN is stored.
  String get appLockOff => _catalog.appLockOff;

  /// PIN shape.
  String get appLockPinLength => _catalog.appLockPinLength;

  /// Confirm field does not match.
  String get appLockPinMismatch => _catalog.appLockPinMismatch;

  /// Submitted PIN does not match the stored hash.
  String get appLockWrongPin => _catalog.appLockWrongPin;

  /// Recovery path. Does not offer a wipe (FE-SIMP-09).
  String get appLockRecovery => _catalog.appLockRecovery;

  /// Closes a dialog or panel without acting.
  String get close => _catalog.close;

  /// The floating feedback control: its label, tooltip and semantic name.
  String get feedback => _catalog.feedback;

  /// How the floating feedback control behaves, for screen readers.
  String get feedbackButtonHint => _catalog.feedbackButtonHint;

  /// Opens the form to write feedback.
  String get feedbackGive => _catalog.feedbackGive;

  /// Opens the filter to download feedback as a spreadsheet and screenshots.
  String get feedbackDownload => _catalog.feedbackDownload;

  /// Opens the filter to delete feedback.
  String get feedbackDelete => _catalog.feedbackDelete;

  /// Where feedback goes. Nothing is sent (FE-SEC-10).
  String get feedbackStaysOnDevice => _catalog.feedbackStaysOnDevice;

  /// Feedback type: anything that is not one of the others.
  String get feedbackCategoryGeneral => _catalog.feedbackCategoryGeneral;

  /// Feedback type: something that works but could work better.
  String get feedbackCategoryImprovement =>
      _catalog.feedbackCategoryImprovement;

  /// Feedback type: something is wrong.
  String get feedbackCategoryError => _catalog.feedbackCategoryError;

  /// Feedback type: an idea.
  String get feedbackCategorySuggestion => _catalog.feedbackCategorySuggestion;

  /// Feedback type: the operator names it.
  String get feedbackCategoryOther => _catalog.feedbackCategoryOther;

  /// Who wrote an entry: enrolled with the organisation.
  String get feedbackSubmitterSignedIn => _catalog.feedbackSubmitterSignedIn;

  /// Who wrote an entry: a named local operator.
  String get feedbackSubmitterLocal => _catalog.feedbackSubmitterLocal;

  /// Who wrote an entry: no name was set.
  String get feedbackSubmitterAnonymous => _catalog.feedbackSubmitterAnonymous;

  /// Device kind: a touch phone.
  String get feedbackDeviceMobile => _catalog.feedbackDeviceMobile;

  /// Device kind: a touch tablet.
  String get feedbackDeviceTablet => _catalog.feedbackDeviceTablet;

  /// Device kind: a desktop, natively or in a desktop browser.
  String get feedbackDeviceDesktop => _catalog.feedbackDeviceDesktop;

  /// Label of the feedback type choice.
  String get feedbackType => _catalog.feedbackType;

  /// Label of the field that names an "other" type.
  String get feedbackOtherType => _catalog.feedbackOtherType;

  /// The "other" type was chosen but not named.
  String get feedbackOtherRequired => _catalog.feedbackOtherRequired;

  /// Label of the feedback text.
  String get feedbackMessage => _catalog.feedbackMessage;

  /// Prompt inside the empty feedback text.
  String get feedbackMessageHint => _catalog.feedbackMessageHint;

  /// The feedback text was empty.
  String get feedbackMessageRequired => _catalog.feedbackMessageRequired;

  /// Attaches the screenshot taken when Feedback was tapped.
  String get feedbackAttachScreenshot => _catalog.feedbackAttachScreenshot;

  /// Continues a feedback draft started on another screen.
  String get feedbackContinue => _catalog.feedbackContinue;

  /// Adds a screenshot of the screen currently under the overlay.
  String get feedbackAddScreen => _catalog.feedbackAddScreen;

  /// Opt-in so Screenshot current screen includes the Give us feedback chrome.
  /// Short enough to stay on one line beside its checkbox at 360 dp.
  String get feedbackIncludeUi => _catalog.feedbackIncludeUi;

  /// Opens the browser display picker for another window or OS surface.
  String get feedbackAddWindow => _catalog.feedbackAddWindow;

  /// Stops the shared window so later taps open the picker again.
  String get feedbackStopSharing => _catalog.feedbackStopSharing;

  /// Non-colour signal that Screenshot external window is live.
  String get feedbackSharingWindow => _catalog.feedbackSharingWindow;

  /// Label of a still taken from another window.
  String get feedbackOtherWindow => _catalog.feedbackOtherWindow;

  /// Opens the device camera for a photo to attach.
  String get feedbackTakePhoto => _catalog.feedbackTakePhoto;

  /// Opens the device library for photos to attach.
  String get feedbackChoosePhoto => _catalog.feedbackChoosePhoto;

  /// How to capture another Tapture screen when other windows cannot be
  /// shared.
  String get feedbackShotTipScreens => _catalog.feedbackShotTipScreens;

  /// How to attach a system screenshot of another app.
  String get feedbackShotTipApps => _catalog.feedbackShotTipApps;

  /// The attach checkbox, counting the images it covers.
  String feedbackAttachImages(int n) {
    return _catalog.feedbackAttachImages(n);
  }

  /// How many images a kept draft holds, for the compact bar.
  String feedbackImageCount(int n) {
    return _catalog.feedbackImageCount(n);
  }

  /// Semantic name of a larger attached-photo preview.
  String get feedbackShotPreview => _catalog.feedbackShotPreview;

  /// Discards the in-progress feedback draft.
  String get feedbackDiscardDraft => _catalog.feedbackDiscardDraft;

  /// Title of the discard-draft confirm.
  String get feedbackDiscardDraftTitle => _catalog.feedbackDiscardDraftTitle;

  /// Body of the discard-draft confirm, naming the image count (FE-SIMP-07).
  String feedbackDiscardDraftMessage(int images) {
    return _catalog.feedbackDiscardDraftMessage(images);
  }

  /// Collapses the feedback form so the rest of the app stays usable.
  String get feedbackContinueLater => _catalog.feedbackContinueLater;

  /// Compact bar while a draft is kept across screens.
  String get feedbackDraftBarHint => _catalog.feedbackDraftBarHint;

  /// Announced when a screenshot of [screen] was added to the draft.
  String feedbackShotAdded(String screen) {
    return _catalog.feedbackShotAdded(screen);
  }

  /// The draft already holds as many photos as it will take.
  String get feedbackShotsFull => _catalog.feedbackShotsFull;

  /// What the screenshot shows, named for the screen it was taken on.
  String feedbackScreenshotOf(String screen) {
    return _catalog.feedbackScreenshotOf(screen);
  }

  /// The draft holds no screenshot or photo yet.
  String get feedbackNoScreenshot => _catalog.feedbackNoScreenshot;

  /// Semantic name of the screenshot preview.
  String get feedbackScreenshotPreview => _catalog.feedbackScreenshotPreview;

  /// Saves the feedback entry.
  String get feedbackSave => _catalog.feedbackSave;

  /// Announced once the entry is durable.
  String get feedbackSaved => _catalog.feedbackSaved;

  /// Filter: feedback types.
  String get feedbackTypes => _catalog.feedbackTypes;

  /// Filter: earliest submission.
  String get feedbackFrom => _catalog.feedbackFrom;

  /// Filter: latest submission.
  String get feedbackTo => _catalog.feedbackTo;

  /// The date range runs backwards.
  String get feedbackRangeBackwards => _catalog.feedbackRangeBackwards;

  /// Filter: screens feedback was given on.
  String get feedbackScreens => _catalog.feedbackScreens;

  /// Filter: platforms.
  String get feedbackPlatforms => _catalog.feedbackPlatforms;

  /// Filter: device types.
  String get feedbackDeviceTypes => _catalog.feedbackDeviceTypes;

  /// Filter: who submitted.
  String get feedbackSubmittedBy => _catalog.feedbackSubmittedBy;

  /// Filter: whether a screenshot is attached.
  String get feedbackScreenshot => _catalog.feedbackScreenshot;

  /// Screenshot filter: either way.
  String get feedbackScreenshotAny => _catalog.feedbackScreenshotAny;

  /// Screenshot filter: attached.
  String get feedbackScreenshotWith => _catalog.feedbackScreenshotWith;

  /// Screenshot filter: not attached.
  String get feedbackScreenshotWithout => _catalog.feedbackScreenshotWithout;

  /// Prompt on the feedback text search.
  String get feedbackSearch => _catalog.feedbackSearch;

  /// Resets every feedback filter.
  String get feedbackClearFilters => _catalog.feedbackClearFilters;

  /// How many entries the filters let through.
  String feedbackMatching(int matching, int total) {
    return _catalog.feedbackMatching(total, matching);
  }

  /// Downloads the matching entries.
  String feedbackDownloadCount(int n) {
    return _catalog.feedbackDownloadCount(n);
  }

  /// The browser took the download.
  String get feedbackDownloadStarted => _catalog.feedbackDownloadStarted;

  /// The archive was written to [location] on this device.
  String feedbackDownloadedTo(String location) =>
      _catalog.feedbackDownloadedTo(location);

  /// Shared Downloads subfolder on Android and desktop. The › mirrors with
  /// the surrounding line in right-to-left layouts (FE-L10N-05).
  String get downloadsTaptureFolder => _catalog.downloadsTaptureFolder;

  /// Where archives land, before anything is downloaded.
  String feedbackDownloadsGoTo(String place) =>
      _catalog.feedbackDownloadsGoTo(place);

  /// Opens the system Downloads view or the Tapture folder.
  String get feedbackOpenFolder => _catalog.feedbackOpenFolder;

  /// Opens the system picker so the archive can be saved anywhere.
  String get feedbackSaveToFolder => _catalog.feedbackSaveToFolder;

  /// Warning when [place] could not be opened.
  String feedbackOpenFolderFailed(String place) =>
      _catalog.feedbackOpenFolderFailed(place);

  /// Nothing has been written yet.
  String get feedbackEmptyHeadline => _catalog.feedbackEmptyHeadline;

  /// Next step when nothing has been written (FE-SIMP-11).
  String get feedbackEmptyMessage => _catalog.feedbackEmptyMessage;

  /// The filters let nothing through.
  String get feedbackNoMatchHeadline => _catalog.feedbackNoMatchHeadline;

  /// Next step when the filters let nothing through.
  String get feedbackNoMatchMessage => _catalog.feedbackNoMatchMessage;

  /// How many entries are ticked for deletion.
  String feedbackSelected(int n) {
    return _catalog.feedbackSelected(n);
  }

  /// Deletes the ticked entries.
  String feedbackDeleteCount(int n) {
    return _catalog.feedbackDeleteCount(n);
  }

  /// Title of the delete confirm, naming the count (FE-SIMP-07).
  String feedbackDeleteTitle(int n) {
    return _catalog.feedbackDeleteTitle(n);
  }

  /// Body of the delete confirm, naming the consequence (FE-SIMP-07).
  String feedbackDeleteMessage(int n) {
    return _catalog.feedbackDeleteMessage(n);
  }

  /// Announced once the entries are gone.
  String feedbackDeleted(int n) {
    return _catalog.feedbackDeleted(n);
  }

  /// Loads the next page of entries.
  String get feedbackShowMore => _catalog.feedbackShowMore;

  /// One entry's facts on a list row: type, when and where.
  String feedbackEntryFacts(String type, String when, String screen) {
    return _catalog.feedbackEntryFacts(type, when, screen);
  }

  /// One entry's title on a list row: number, Feedback ID and message.
  String feedbackEntryTitle(String number, String reference, String message) {
    return _catalog.feedbackEntryTitle(number, reference, message);
  }

  /// Remaining backoff after a failed unlock.
  String appLockWait(Duration remaining) {
    final int whole = (remaining.inMilliseconds + 999) ~/ 1000;
    final int seconds = whole < 1 ? 1 : whole;
    return _catalog.appLockWait(seconds);
  }

  /// Queue screen title.
  String get queueTitle => _catalog.queueTitle;

  /// Unprocessed count label.
  String get queueUnprocessed => _catalog.queueUnprocessed;

  /// Queued count label.
  String get queueQueued => _catalog.queueQueued;

  /// Failed count label.
  String get queueFailed => _catalog.queueFailed;

  /// Today's online request and image totals against the project cap.
  String queueUsage(int requests, int images, int cap) {
    return _catalog.queueUsage(requests, cap, images);
  }

  /// Unprocessed records, as a complete message.
  String queueUnprocessedCount(int count) =>
      _catalog.queueUnprocessedCount(count);

  /// Records waiting in the queue, as a complete message.
  String queueQueuedCount(int count) => _catalog.queueQueuedCount(count);

  /// Failed jobs, as a complete message.
  String queueFailedCount(int count) => _catalog.queueFailedCount(count);

  /// Context groups in the queue.
  String get queueGroupsTitle => _catalog.queueGroupsTitle;

  /// Process every waiting record.
  String get queueProcessAll => _catalog.queueProcessAll;

  /// Process the records in one group.
  String get queueProcessSelected => _catalog.queueProcessSelected;

  /// Empty queue title.
  String get queueEmptyHeadline => _catalog.queueEmptyHeadline;

  /// Empty queue explanation.
  String get queueEmptyMessage => _catalog.queueEmptyMessage;

  /// Failures list title.
  String get queueFailedTitle => _catalog.queueFailedTitle;

  /// Retry one failed job.
  String get queueRetry => _catalog.queueRetry;

  /// What a screen reader calls the retry control on [record]'s row.
  String queueRetryLabel(String record) => _catalog.queueRetryLabel(record);

  /// Stop the batch that is running.
  String get queueCancel => _catalog.queueCancel;

  /// Why a cancelled batch stopped. Finished work is kept.
  String get queueCancelled => _catalog.queueCancelled;

  /// End-of-run summary, then why the run stopped early when it did.
  String queueSummary(int succeeded, int failed, {String? detail}) {
    final String counts = _catalog.queueSummary(succeeded, failed);
    return detail == null ? counts : _catalog.queueSummaryValue(counts, detail);
  }

  /// A running batch: records finished so far, then what the current one is
  /// doing when known.
  String queueProgress(int done, int failed, {String? stage}) {
    final String counts = _catalog.queueProgress(done, failed);
    return stage == null ? counts : _catalog.queueProgressNow(counts, stage);
  }

  /// Asks before the first online call of a session.
  String get egressTitle => _catalog.egressTitle;

  /// Confirms the preview.
  String get egressSend => _catalog.egressSend;

  /// Why a batch stopped when its egress preview was declined.
  String get egressDecline => _catalog.egressDecline;

  /// What the preview says will be included.
  String egressBody({required int images, required String size}) {
    return _catalog.egressBody(images, size);
  }

  /// Device-held key screen title.
  String get apiKeyTitle => _catalog.apiKeyTitle;

  /// States that device custody is the exception.
  String get apiKeyCustody => _catalog.apiKeyCustody;

  /// Key field label.
  String get apiKeyLabel => _catalog.apiKeyLabel;

  /// Saves the key into secure storage.
  String get apiKeySave => _catalog.apiKeySave;

  /// Removes the key and clears the selection.
  String get apiKeyRemove => _catalog.apiKeyRemove;

  /// Runs the smallest connection test.
  String get apiKeyTest => _catalog.apiKeyTest;

  /// Shown once the key is stored and hidden.
  String get apiKeySaved => _catalog.apiKeySaved;

  /// Confirm title before the device key is removed.
  String get apiKeyRemoveTitle => _catalog.apiKeyRemoveTitle;

  /// What removing the device key changes.
  String get apiKeyRemoveMessage => _catalog.apiKeyRemoveMessage;

  /// Test connection succeeded.
  String get apiKeySuccess => _catalog.apiKeySuccess;

  /// The key was rejected.
  String get apiKeyAuthFailed => _catalog.apiKeyAuthFailed;

  /// The test could not reach the network.
  String get apiKeyNetworkFailed => _catalog.apiKeyNetworkFailed;

  /// The provider answered the test with an error of its own.
  String get apiKeyTestFailed => _catalog.apiKeyTestFailed;

  /// Registry-driven AI controls.
  String get aiOperation => _catalog.aiOperation;

  /// Provider choice field.
  String get aiProvider => _catalog.aiProvider;

  /// Model choice field.
  String get aiModel => _catalog.aiModel;

  /// Operator-facing label for an AI operation id.
  String aiOperationLabel(String value) {
    return switch (value) {
      'readText' => _catalog.aiOperationLabel,
      'extractFields' => _catalog.aiOperationLabelExtractFields,
      'refineText' => _catalog.aiOperationLabelRefineText,
      'transcribe' => _catalog.aiOperationLabelTranscribeAudio,
      _ => value,
    };
  }

  /// Credential custody and live availability explanation.
  String aiCustody(String custody, bool available) {
    final String owner = custody == 'backend'
        ? _catalog.aiCustodyTheOrganisationBackendHolds
        : _catalog.aiCustodyThisProviderUsesA;
    return available ? owner : _catalog.aiCustodyThisProviderIsCurrently(owner);
  }

  /// Saved choice fallback explanation.
  String get aiSelectionFallback => _catalog.aiSelectionFallback;

  /// Provider test could not run because the descriptor is unavailable.
  String get aiProviderUnavailable => _catalog.aiProviderUnavailable;

  /// Provider and model do not support the selected operation.
  String get aiSelectionInvalid => _catalog.aiSelectionInvalid;

  /// Template question.
  String get templateChoiceTitle => _catalog.templateChoiceTitle;

  /// Pins the choice to the current place.
  String get templateChoicePin => _catalog.templateChoicePin;

  /// No templates to offer.
  String get templateChoiceEmptyHeadline =>
      _catalog.templateChoiceEmptyHeadline;

  /// Why the choice sheet is empty.
  String get templateChoiceEmptyMessage => _catalog.templateChoiceEmptyMessage;

  /// The third choice when the shortlist is not enough.
  String get templateChoiceOther => _catalog.templateChoiceOther;

  /// The step detail when no template was chosen. The record stays queued.
  String get templateChoiceSkipped => _catalog.templateChoiceSkipped;

  /// The chosen template could not be applied to the record.
  String get templateChoiceApplyFailed => _catalog.templateChoiceApplyFailed;

  /// What to do when the chosen template could not be applied.
  String get templateChoiceApplyRecovery =>
      _catalog.templateChoiceApplyRecovery;

  /// A record an unattended run set aside for an operator's template
  /// choice.
  String get templateChoiceWaiting => _catalog.templateChoiceWaiting;

  /// A record read on the device, its online work left for later.
  String get processReadOnDevice => _catalog.processReadOnDevice;

  /// Preparing images.
  String get processPreparing => _catalog.processPreparing;

  /// On-device reading.
  String get processReading => _catalog.processReading;

  /// Template detection.
  String get processDetecting => _catalog.processDetecting;

  /// Online extraction.
  String get processExtracting => _catalog.processExtracting;

  /// Validation.
  String get processChecking => _catalog.processChecking;

  /// Local notification title. Counts only.
  String get processingNotificationTitle =>
      _catalog.processingNotificationTitle;

  /// Local notification body. Counts only.
  String processingNotificationBody(int succeeded, int failed) {
    return _catalog.processingNotificationBody(succeeded, failed);
  }

  // Documents picked from the device (task 076).

  /// A document the picker could not hand over.
  String get documentPickFailed => _catalog.documentPickFailed;

  /// A chosen file above what this device can open in one piece.
  String documentTooLarge(int bytes, int ceiling) {
    return _catalog.documentTooLarge(fileSize(bytes), fileSize(ceiling));
  }

  /// What to do about a file that is too large.
  String get documentTooLargeRecovery => _catalog.documentTooLargeRecovery;

  /// A stored export that is no longer where the app wrote it.
  String get storedFileMissing => _catalog.storedFileMissing;

  // Project packages (task 076).

  /// A package whose project is gone.
  String get packageProjectMissing => _catalog.packageProjectMissing;

  /// A package larger than this device writes or opens.
  String packageTooLarge(int bytes, int ceiling) {
    return _catalog.packageTooLarge(fileSize(bytes), fileSize(ceiling));
  }

  /// What to do about a package that is too large.
  String get packageTooLargeRecovery => _catalog.packageTooLargeRecovery;

  /// A package that could not be written.
  String get packageWriteFailed => _catalog.packageWriteFailed;

  /// Why a package was refused; [check] is the failed check's name.
  String packageRejected(String check) {
    return switch (check) {
      'tooLarge' => _catalog.packageRejected,
      'notAPackage' => _catalog.packageRejectedThisFileIsNot,
      'unsafePath' => _catalog.packageRejectedThisPackageHoldsA,
      'missingEntry' => _catalog.packageRejectedThisPackageIsMissing,
      'unreadable' => _catalog.packageRejectedPartOfThisPackage,
      'unknownFormatVersion' => _catalog.packageRejectedThisPackageWasMade,
      'checksumMismatch' => _catalog.packageRejectedThisPackageWasChanged,
      _ => _catalog.packageRejectedThisPackageCouldNot,
    };
  }

  /// What to do about a refused package.
  String get packageRejectedRecovery => _catalog.packageRejectedRecovery;

  // Capture's guide (task 076).

  /// The row under the Template select that opens the guide.
  String get captureGuideTitle => _catalog.captureGuideTitle;

  /// What the photos should show; the template's fields follow.
  String get captureGuidePhotos => _catalog.captureGuidePhotos;

  /// What to say or type in the caption; the template's fields follow.
  String get captureGuideCaption => _catalog.captureGuideCaption;

  /// A guide list's field labels, which are template data.
  String captureGuideItems(List<String> labels) => labels.join(' · ');

  /// Closes the caption panel of the guide.
  String get captureGuideClose => _catalog.captureGuideClose;

  // Importing and merging project packages (task 076, W19 to W22).

  /// Shown while a chosen package is opened and checked.
  String get importChecking => _catalog.importChecking;

  /// Title of the sheet that describes a package before it is imported.
  String get importSheetTitle => _catalog.importSheetTitle;

  /// Where and when the package was made. [device] is package data.
  String importFrom(String device, DateTime exportedAt) {
    return _withLocale(() {
      final String when = DateFormat.yMMMd().add_jm().format(
        exportedAt.toLocal(),
      );
      return _catalog.importFrom(
        when,
        device.isEmpty ? _catalog.importAnotherDevice : device,
      );
    });
  }

  /// What the package holds.
  String importHolds(int records, int photos, int bytes) {
    return _catalog.importHolds(
      recordsCount(records),
      photosCount(photos),
      fileSize(bytes),
    );
  }

  /// How many photos a package or a count covers.
  String photosCount(int n) {
    return _catalog.photosCount(n);
  }

  /// Primary action of the import sheet.
  String get importAsNewProject => _catalog.importAsNewProject;

  /// Secondary action of the import sheet: merge into a project here.
  String get importMergeInto => _catalog.importMergeInto;

  /// Shown while a package's files are copied in.
  String get importCopying => _catalog.importCopying;

  /// Announced once the project is in.
  String importDone(int records) => _catalog.importDone(recordsCount(records));

  /// A package whose project was deleted on this device is refused.
  String get importProjectDeletedHere => _catalog.importProjectDeletedHere;

  /// Recovery for [importProjectDeletedHere].
  String get importProjectDeletedHereRecovery =>
      _catalog.importProjectDeletedHereRecovery;

  /// A package whose project is already here does not import a second copy.
  String get importProjectAlreadyHere => _catalog.importProjectAlreadyHere;

  /// Recovery for [importProjectAlreadyHere].
  String get importProjectAlreadyHereRecovery =>
      _catalog.importProjectAlreadyHereRecovery;

  /// Too little room for the package's files.
  String get importNoRoom => _catalog.importNoRoom;

  /// Recovery for [importNoRoom].
  String get importNoRoomRecovery => _catalog.importNoRoomRecovery;

  /// A file in the package did not arrive as it left.
  String get importFileChanged => _catalog.importFileChanged;

  /// Recovery for any import or merge that stopped part way.
  String get importFailedRecovery => _catalog.importFailedRecovery;

  /// Project home overflow item and the merge screen's title.
  String get mergePackage => _catalog.mergePackage;

  /// Title of the sheet that chooses which project a package merges into.
  String get mergeTargetTitle => _catalog.mergeTargetTitle;

  /// No local project can take the package.
  String get mergeTargetNone => _catalog.mergeTargetNone;

  /// A compatibility status, as its pill reads.
  String compatibilityStatus(String status) {
    return switch (status) {
      'compatible' => _catalog.compatibilityStatus,
      'compatibleWithDifferences' =>
        _catalog.compatibilityStatusCompatibleWithDifferences,
      _ => _catalog.compatibilityStatusNotCompatible,
    };
  }

  /// One named compatibility finding. [field] is template data.
  String compatibilityIssue(String issue, String field) {
    return switch (issue) {
      'noMatch' => _catalog.compatibilityIssue,
      'missingField' => _catalog.compatibilityIssueHoldsValuesButIs(field),
      'typeCannotHold' => _catalog.compatibilityIssueHereCannotHoldThe(field),
      'otherVersion' => _catalog.compatibilityIssueAnotherVersionOfThe,
      'localOnlyFields' => _catalog.compatibilityIssueOnlyHere(field),
      'changedRequiredness' => _catalog.compatibilityIssueIsRequiredOnOne(
        field,
      ),
      'changedLabel' => _catalog.compatibilityIssueHasAnotherLabelHere(field),
      'changedOptions' => _catalog.compatibilityIssueOffersOtherChoicesHere(
        field,
      ),
      'changedType' => _catalog.compatibilityIssueHasAnotherTypeHere(field),
      _ => _catalog.compatibilityIssueIsNotInThe(field),
    };
  }

  /// A template's line in the compatibility report. [name] is template data.
  String compatibilityTemplate(String name, String status) =>
      _catalog.compatibilityTemplate(name, compatibilityStatus(status));

  /// The merge preview's count headings (specification §48.1).
  String mergeCount(String count, int n) {
    final String label = switch (count) {
      'newRecords' => _catalog.mergeCount,
      'updatedRecords' => _catalog.mergeCountRecordsThisMergeChanges,
      'newPhotos' => _catalog.mergeCountNewPhotos,
      'photosHere' => _catalog.mergeCountPhotosAlreadyOnThis,
      'deletions' => _catalog.mergeCountDeletionsToApply,
      'conflicts' => _catalog.mergeCountConflictsToSettle,
      'duplicates' => _catalog.mergeCountPossibleDuplicates,
      'kept' => _catalog.mergeCountValuesKeptAsOn,
      _ => _catalog.mergeCountAlreadyInAnotherProject,
    };
    return _catalog.mergeCountValue(label, n);
  }

  /// Primary merge action while conflicts remain.
  String mergeSettleConflicts(int n) {
    return _catalog.mergeSettleConflicts(n);
  }

  /// Primary merge action once every conflict is settled.
  String get mergeApply => _catalog.mergeApply;

  /// Shown while a merge is written.
  String get mergeApplying => _catalog.mergeApplying;

  /// Announced once a merge is written.
  String get mergeDone => _catalog.mergeDone;

  /// A second merge of the same package.
  String get mergeNothing => _catalog.mergeNothing;

  /// Switch on the merge preview that runs the duplicate check.
  String get mergeCheckDuplicates => _catalog.mergeCheckDuplicates;

  /// Helper under [mergeCheckDuplicates].
  String get mergeCheckDuplicatesHelper => _catalog.mergeCheckDuplicatesHelper;

  /// Shown while the duplicate check runs.
  String get mergeCheckingDuplicates => _catalog.mergeCheckingDuplicates;

  /// Title of the conflict screen, as "Conflict 3 of 7".
  String conflictProgress(int index, int total) =>
      _catalog.conflictProgress(index, total);

  /// What a conflict is about. [field] is template data.
  String conflictKind(String kind, String field) {
    return switch (kind) {
      'value' => field,
      'caption' => _catalog.conflictKind,
      'status' => _catalog.conflictKindStatus,
      'template' => _catalog.mergeTemplatesHeading,
      'reference' => _catalog.navDatasets,
      'deletedThere' => _catalog.conflictKindDeletedOnTheOther,
      _ => _catalog.conflictKindDeletedOnThisDevice,
    };
  }

  /// Explains a deletion conflict.
  String conflictDeletion(String kind) {
    return kind == 'deletedThere'
        ? _catalog.conflictDeletionTheOtherDeviceDeleted
        : _catalog.conflictDeletionThisDeviceDeletedThis;
  }

  /// Heading of this device's side of a conflict.
  String get conflictThisDevice => _catalog.conflictThisDevice;

  /// Heading of the incoming side of a conflict.
  String get conflictIncoming => _catalog.conflictIncoming;

  /// Who last wrote a side, and when. [device] is data.
  String conflictWrittenBy(String device, DateTime? at) {
    return _withLocale(() {
      final String when = at == null
          ? ''
          : _catalog.conflictWrittenBy(
              DateFormat.yMMMd().add_jm().format(at.toLocal()),
            );
      return _catalog.conflictWrittenByValue(
        device.isEmpty ? _catalog.conflictUnknownDevice : device,
        when,
      );
    });
  }

  /// A side of a deletion conflict.
  String get conflictDeleted => _catalog.conflictDeleted;

  /// An empty value on one side.
  String get conflictEmpty => _catalog.conflictEmpty;

  /// Keeps this device's side of one conflict.
  String get conflictKeepMine => _catalog.conflictKeepMine;

  /// Takes the incoming side of one conflict.
  String get conflictTakeIncoming => _catalog.conflictTakeIncoming;

  /// Second control: keep this device's side of every remaining conflict.
  String mergeKeepAllMine(int n) => _catalog.mergeKeepAllMine(n);

  /// Second control: take the incoming side of every remaining conflict.
  String mergeTakeAllIncoming(int n) => _catalog.mergeTakeAllIncoming(n);

  /// Confirms a bulk choice with its count.
  String mergeBulkConfirm(int n, {required bool incoming}) {
    final String side = incoming
        ? _catalog.mergeBulkConfirm
        : _catalog.mergeBulkConfirmThisDeviceSValue;
    return _catalog.mergeBulkConfirmForConflictOtherFor(n, side);
  }

  /// Title of the possible-duplicate view.
  String get duplicateTitle => _catalog.duplicateTitle;

  /// Why a pair was listed.
  String duplicateSignal(String signal) {
    return switch (signal) {
      'identity' => _catalog.duplicateSignal,
      'photo' => _catalog.duplicateSignalSamePhoto,
      'samePhoto' => _catalog.duplicateSignalIdenticalPhoto,
      'nearPhoto' => _catalog.duplicateSignalNearlyTheSamePhoto,
      'predefinedRow' => _catalog.duplicateSignalSameChecklistRow,
      'nameContextTime' => _catalog.duplicateSignalSameNamePlaceAnd,
      _ => _catalog.duplicateSignalSamePlaceCloseIn,
    };
  }

  /// Keeps both records: the default.
  String get duplicateKeepBoth => _catalog.duplicateKeepBoth;

  /// Leaves the incoming record out of the merge.
  String get duplicateSkipIncoming => _catalog.duplicateSkipIncoming;

  /// Marks a pair whose incoming record is left out.
  String get duplicateSkipped => _catalog.duplicateSkipped;

  /// Heading of the incoming side of a pair.
  String get duplicateIncoming => _catalog.duplicateIncoming;

  /// Heading of the local side of a pair.
  String get duplicateHere => _catalog.duplicateHere;

  // The merge preview and its conflicts (task 076, W20 to W22).

  /// Empty state when the merge screen opens with no package.
  String get mergeNoPackageHeadline => _catalog.mergeNoPackageHeadline;

  /// Explains [mergeNoPackageHeadline].
  String get mergeNoPackageMessage => _catalog.mergeNoPackageMessage;

  /// Heading over the compatibility report.
  String get mergeTemplatesHeading => _catalog.mergeTemplatesHeading;

  /// Heading over the preview's counts.
  String get mergeCountsHeading => _catalog.mergeCountsHeading;

  /// Shown when a template blocks the merge.
  String get mergeBlocked => _catalog.mergeBlocked;

  /// A record with no caption, in the preview's lists.
  String mergeRecordUnnamed(String id) {
    final String short = id.length > 8 ? id.substring(id.length - 8) : id;
    return _catalog.mergeRecordUnnamed(short);
  }

  /// A conflict's line in the preview: the record, then what differs.
  String mergeConflictLine(String record, String about) =>
      _catalog.mergeConflictLine(record, about);

  /// A settled conflict's side, under its line.
  String mergeConflictChosen({required bool incoming}) => incoming
      ? _catalog.mergeConflictChosen
      : _catalog.mergeConflictChosenKeepingThisDeviceS;

  /// A conflict not settled yet.
  String get mergeConflictOpen => _catalog.mergeConflictOpen;

  /// The project details that differ in the package, kept as on this device.
  String mergeProjectKept(List<String> columns) {
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
    return _catalog.mergeProjectKept(labels.join(', '));
  }

  /// The deletion side of a conflict that was changed rather than deleted.
  String get conflictChanged => _catalog.conflictChanged;

  /// The duplicate pair view's field line. [label] and [value] are data.
  String duplicateField(String label, String value) =>
      _catalog.duplicateField(label, value.isEmpty ? conflictEmpty : value);

  // Records: list, filters and sort (014).

  /// Prompt on a records list's search field: what it looks through.
  String get recordsSearchHint => _catalog.recordsSearchHint;

  /// A record's list title when nothing names it yet: its [number], or no
  /// number at all before one is allocated.
  String recordsUntitled(int? number) {
    return number == null
        ? _catalog.recordsUntitled
        : _catalog.recordsUntitledRecord(number);
  }

  /// A record row's second line: its [number], [identifier] and [context],
  /// whichever are known, in one line. [identifier] and [context] are
  /// template content (FE-L10N-07).
  String recordsRowSubtitle({
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
  String get recordsEmptyHeadline => _catalog.recordsEmptyHeadline;

  /// Where a project's records come from.
  String get recordsEmptyMessage => _catalog.recordsEmptyMessage;

  /// The next action on an empty records list.
  String get recordsEmptyAction => _catalog.recordsEmptyAction;

  /// A records search or filter that matched nothing, naming the [query].
  String recordsNoMatch(String query) {
    final String shown = query.trim();
    return shown.isEmpty
        ? _catalog.recordsNoMatch
        : _catalog.recordsNoMatchNoRecordsMatch(shown);
  }

  /// Empties a records search that matched nothing.
  String get recordsClearSearch => _catalog.recordsClearSearch;

  /// Empties a records search and turns its filters off, together.
  String get recordsClearAll => _catalog.recordsClearAll;

  /// The records list with no project open.
  String get recordsNoProjectHeadline => _catalog.recordsNoProjectHeadline;

  /// Why the records list is empty without a project.
  String get recordsNoProjectMessage => _catalog.recordsNoProjectMessage;

  /// The next action when no project is open.
  String get recordsOpenProject => _catalog.recordsOpenProject;

  /// Title of a records list's filter sheet.
  String get recordsFiltersTitle => _catalog.recordsFiltersTitle;

  /// The status facet of the records filters.
  String get recordsFilterStatus => _catalog.recordsFilterStatus;

  /// The template facet of the records filters.
  String get recordsFilterTemplate => _catalog.recordsFilterTemplate;

  /// The earliest capture date the records filters keep.
  String get recordsFilterFrom => _catalog.recordsFilterFrom;

  /// The latest capture date the records filters keep.
  String get recordsFilterTo => _catalog.recordsFilterTo;

  /// The operator facet of the records filters.
  String get recordsFilterOperator => _catalog.recordsFilterOperator;

  /// The condition facet of the records filters.
  String get recordsFilterCondition => _catalog.recordsFilterCondition;

  /// The quality-flag facet of the records filters.
  String get recordsFilterFlags => _catalog.recordsFilterFlags;

  /// Quality flag: the record has at least one photo.
  String get recordsFlagHasPhotos => _catalog.recordsFlagHasPhotos;

  /// Quality flag: the record may duplicate another.
  String get recordsFlagHasDuplicate => _catalog.recordsFlagHasDuplicate;

  /// Quality flag: a merge left a conflict on the record.
  String get recordsFlagHasConflict => _catalog.recordsFlagHasConflict;

  /// Quality flag: a value changed after the record was approved.
  String get recordsFlagHasVariance => _catalog.recordsFlagHasVariance;

  /// Quality flag: a value lost every photo it was read from.
  String get recordsFlagEvidenceRemoved => _catalog.recordsFlagEvidenceRemoved;

  /// Quality flag: the record arrived in a package from another device.
  String get recordsFlagMerged => _catalog.recordsFlagMerged;

  /// The filter sheet of a project with no records.
  String get recordsFiltersEmptyHeadline =>
      _catalog.recordsFiltersEmptyHeadline;

  /// What fills the filter sheet.
  String get recordsFiltersEmptyMessage => _catalog.recordsFiltersEmptyMessage;

  /// A template whose name is not on this device.
  String get recordsTemplateUnnamed => _catalog.recordsTemplateUnnamed;

  /// Active-filter chip for a template. [name] is template content.
  String recordsChipTemplate(String name) => _catalog.recordsChipTemplate(name);

  /// Active-filter chip for who captured the records. [name] is data the
  /// operator entered.
  String recordsChipOperator(String name) => _catalog.recordsChipOperator(name);

  /// Active-filter chip for a condition code. [code] is template content.
  String recordsChipCondition(String code) =>
      _catalog.recordsChipCondition(code);

  /// Active-filter chip for one context value: the [level] it sits at and
  /// the [value]. Both are template content.
  String recordsChipContext(String level, String value) =>
      _catalog.recordsChipContext(level, value);

  /// Active-filter chip for the capture date range, in [locale]'s format.
  String recordsChipDates({
    DateTime? from,
    DateTime? to,
    required String locale,
  }) {
    return _withLocale(() {
      final DateFormat format = DateFormat.yMMMd(locale);
      if (from != null && to != null) {
        return _catalog.recordsChipDates(
          format.format(from),
          format.format(to),
        );
      }
      if (from != null) {
        return _catalog.recordsChipDatesFrom(format.format(from));
      }
      return to == null
          ? ''
          : _catalog.recordsChipDatesUntil(format.format(to));
    });
  }

  /// Title of the records sort choice.
  String get recordsSortTitle => _catalog.recordsSortTitle;

  /// The sort control, naming the [current] order.
  String recordsSortLabel(String current) => _catalog.recordsSortLabel(current);

  /// Highest record number first, the newest capture on top.
  String get recordsSortNumberDescending =>
      _catalog.recordsSortNumberDescending;

  /// Lowest record number first.
  String get recordsSortNumberAscending => _catalog.recordsSortNumberAscending;

  /// Latest capture first.
  String get recordsSortCapturedDescending =>
      _catalog.recordsSortCapturedDescending;

  /// Earliest capture first.
  String get recordsSortCapturedAscending =>
      _catalog.recordsSortCapturedAscending;

  /// Names in alphabetical order.
  String get recordsSortNameAscending => _catalog.recordsSortNameAscending;

  /// Names in reverse alphabetical order.
  String get recordsSortNameDescending => _catalog.recordsSortNameDescending;

  // Records: detail and history (014).

  // The record page (014 step 4). Field labels, values, context values,
  // operators, devices, providers and models it shows are data and pass
  // through these strings unchanged (FE-L10N-07).

  /// Leaves the page of a record that is not on this device for the list.
  String get recordDetailBackToList => _catalog.recordDetailBackToList;

  /// Above a record in the recycle bin: why it cannot be changed, and what
  /// to do first.
  String get recordDetailDeletedNotice => _catalog.recordDetailDeletedNotice;

  /// Sends the record shown to review, the step before it is approved.
  String get recordDetailSendToReview => _catalog.recordDetailSendToReview;

  /// Once the record shown waits for review.
  String get recordDetailSentToReview => _catalog.recordDetailSentToReview;

  /// Menu row that brings the record shown back from the archive.
  String get recordDetailUnarchive => _catalog.recordDetailUnarchive;

  /// Once the record shown is back from the archive.
  String get recordDetailUnarchived => _catalog.recordDetailUnarchived;

  /// Opens the page that edits the record's photos, captions and audio.
  String get recordDetailEditPhotos => _catalog.recordDetailEditPhotos;

  /// A status move asked for while another is still being written.
  String get recordDetailBusy => _catalog.recordDetailBusy;

  /// What to do about [recordDetailBusy].
  String get recordDetailBusyAction => _catalog.recordDetailBusyAction;

  /// A record with no values and no fields to fill.
  String get recordDetailNoValues => _catalog.recordDetailNoValues;

  /// Heading over the context in force when the record was captured.
  String get recordDetailContextTitle => _catalog.recordDetailContextTitle;

  /// A record captured with no context in force.
  String get recordDetailContextEmpty => _catalog.recordDetailContextEmpty;

  /// Heading over the count of the record's values by where they came from.
  String get recordDetailProvenanceTitle =>
      _catalog.recordDetailProvenanceTitle;

  /// How many of the record's values came from one source, or carry one
  /// mark.
  String recordDetailValuesCount(int n) {
    return _catalog.recordDetailValuesCount(n);
  }

  /// The values a person confirmed.
  String get recordDetailVerified => _catalog.recordDetailVerified;

  /// The providers, models and methods that read the record's values.
  String get recordDetailReadBy => _catalog.recordDetailReadBy;

  /// Heading over when the record was captured, changed, approved and
  /// exported.
  String get recordDetailDatesTitle => _catalog.recordDetailDatesTitle;

  /// When the record was captured, and on which device.
  String get recordDetailCaptured => _catalog.recordDetailCaptured;

  /// When the record last changed.
  String get recordDetailUpdated => _catalog.recordDetailUpdated;

  /// When the record was last approved, and by whom.
  String get recordDetailApproved => _catalog.recordDetailApproved;

  /// When the record was last exported.
  String get recordDetailExported => _catalog.recordDetailExported;

  /// A record that has never been exported.
  String get recordDetailNotExported => _catalog.recordDetailNotExported;

  /// When something happened to the record, [at] in local time, and who or
  /// which device did it ([by], data) when that is known.
  String recordDetailWhen(DateTime at, {String by = ''}) {
    return _withLocale(() {
      final String when = DateFormat.yMMMd().add_jm().format(at);
      final String who = by.trim();
      return who.isEmpty ? when : _catalog.recordDetailWhen(when, who);
    });
  }

  /// One of the record's photos by its 1-based [position] among [total].
  String recordPhotoPosition(int position, int total) {
    return _catalog.recordPhotoPosition(position, total);
  }

  /// A value typed by a person, or corrected by hand.
  String get recordSourceTyped => _catalog.recordSourceTyped;

  /// A value read from a photo's text on this device.
  String get recordSourceOcr => _catalog.recordSourceOcr;

  /// A value an AI model read from a photo.
  String get recordSourceAiPhoto => _catalog.recordSourceAiPhoto;

  /// A value an AI model read from captions or spoken notes.
  String get recordSourceAiText => _catalog.recordSourceAiText;

  /// A value spoken aloud and written down.
  String get recordSourceSpeech => _catalog.recordSourceSpeech;

  /// A value scanned from a barcode or QR code.
  String get recordSourceBarcode => _catalog.recordSourceBarcode;

  /// A value looked up in a reference list.
  String get recordSourceLookup => _catalog.recordSourceLookup;

  /// A value taken from the context in force at capture.
  String get recordSourceContext => _catalog.recordSourceContext;

  /// A value the template filled in by default.
  String get recordSourceDefault => _catalog.recordSourceDefault;

  /// A value that arrived in an imported table or package.
  String get recordSourceImported => _catalog.recordSourceImported;

  /// A reading the processing was sure of.
  String get recordBandHigh => _catalog.recordBandHigh;

  /// A reading the processing was fairly sure of.
  String get recordBandMedium => _catalog.recordBandMedium;

  /// A reading a person should check.
  String get recordBandLow => _catalog.recordBandLow;

  /// A confidence with no stored band: [score], 0 to 1, as a percentage.
  String recordBandScore(double score) {
    return _withLocale(() {
      return _catalog.recordBandScore(
        NumberFormat.percentPattern().format(score),
      );
    });
  }

  /// A band's words with its [score], 0 to 1, as a percentage beside them.
  String recordBandWithScore(String band, double score) {
    return _withLocale(() {
      return _catalog.recordBandWithScore(
        band,
        NumberFormat.percentPattern().format(score),
      );
    });
  }

  /// What a screen reader hears after a value: where it came from, how sure
  /// the reading was when that is known, and its marks.
  String recordValueMarks({
    required String source,
    String band = '',
    bool evidenceRemoved = false,
    bool retired = false,
  }) {
    return <String>[
      _catalog.recordValueSource(source),
      if (band.isNotEmpty) band,
      if (evidenceRemoved) recordValueEvidenceRemoved,
      if (retired) recordValueRetired,
    ].join(', ');
  }

  // The history page (014 step 6). Field labels, template names, values,
  // package names, providers, models, operators and devices it shows are
  // data and pass through these strings unchanged (FE-L10N-07).

  /// Title of a record's history page.
  String get recordHistoryTitle => _catalog.recordHistoryTitle;

  /// Under the history title: which record the history is of, by its
  /// [number] and [name] (data). Blank when the record has neither.
  String recordHistorySubject({int? number, String name = ''}) {
    return <String>[
      if (number != null) projectRecordPosition(number),
      if (name.isNotEmpty) name,
    ].join(' · ');
  }

  /// A record whose history has no lines yet.
  String get recordHistoryEmptyHeadline => _catalog.recordHistoryEmptyHeadline;

  /// What an empty history will hold, and the next step.
  String get recordHistoryEmptyMessage => _catalog.recordHistoryEmptyMessage;

  /// Leaves an empty history for its record.
  String get recordHistoryBackToRecord => _catalog.recordHistoryBackToRecord;

  /// Heading over one day of a record's history; [day] is local time.
  String recordHistoryDay(DateTime day) {
    return _withLocale(() {
      return DateFormat.yMMMEd().format(day);
    });
  }

  /// When a history line was written, by whom and on which device, under
  /// the line. [at] is local time; [operator] and [device] are data and
  /// either may be blank.
  String recordHistoryByline({
    required DateTime at,
    String operator = '',
    String device = '',
  }) {
    return _withLocale(() {
      final String who = operator.isEmpty
          ? (device.isEmpty ? '' : _catalog.recordHistoryByline(device))
          : (device.isEmpty
                ? operator
                : _catalog.recordHistoryBylineOn(operator, device));
      final String time = DateFormat.jm().format(at);
      return who.isEmpty ? time : _catalog.recordHistoryBylineValue(time, who);
    });
  }

  /// A record captured on a device.
  String get recordHistoryCaptured => _catalog.recordHistoryCaptured;

  /// A record made by hand, which starts as a draft.
  String get recordHistoryCreatedByHand => _catalog.recordHistoryCreatedByHand;

  /// Value [label] written or corrected from [previous] to [next]; all
  /// three are data. A first value shows alone, and a value taken away
  /// says so.
  String recordHistoryValue(
    String label, {
    String previous = '',
    String next = '',
  }) {
    if (previous.isEmpty && next.isEmpty) {
      return _catalog.recordHistoryValue(label);
    }
    if (previous.isEmpty) {
      return _catalog.recordHistoryValueValue(label, next);
    }
    if (next.isEmpty) {
      return _catalog.recordHistoryValueCleared(label);
    }
    return _catalog.recordHistoryValueValue2(label, previous, next);
  }

  /// The caption of a record or of one of its photos, as the label of
  /// [recordHistoryValue].
  String get recordHistoryCaption => _catalog.recordHistoryCaption;

  /// A status move from [previous] to [next], both status names. Only the
  /// new status shows when the old one is not known.
  String recordHistoryStatus({String previous = '', required String next}) {
    return previous.isEmpty
        ? _catalog.recordHistoryStatus(next)
        : _catalog.recordHistoryStatusValue(previous, next);
  }

  /// A photo added to the record after capture, or during it.
  String get recordHistoryPhotoAdded => _catalog.recordHistoryPhotoAdded;

  /// A photo taken off the record. Its file stays until the purge.
  String get recordHistoryPhotoRemoved => _catalog.recordHistoryPhotoRemoved;

  /// The record moved from template [previous] to [next] (names, data).
  /// Either name is blank when that template is not on this device.
  String recordHistoryTemplate({String previous = '', String next = ''}) {
    if (next.isEmpty) {
      return _catalog.recordHistoryTemplate;
    }
    return previous.isEmpty
        ? _catalog.recordHistoryTemplateTemplate(next)
        : _catalog.recordHistoryTemplateTemplate2(previous, next);
  }

  /// Stands in for the name of a template that is not on this device.
  String get recordHistoryTemplateGone => _catalog.recordHistoryTemplateGone;

  /// A processing run that finished, with the [provider] and [model] it
  /// used (data) when they are known.
  String recordHistoryProcessed({String provider = '', String model = ''}) {
    final String by = provider.isEmpty
        ? ''
        : _catalog.recordHistoryProcessed(provider);
    final String using = model.isEmpty
        ? ''
        : _catalog.recordHistoryProcessedValue(model);
    return _catalog.recordHistoryProcessedProcessed(by, using);
  }

  /// A processing run that stopped for good after [attempts] tries; zero
  /// when the count is not known.
  String recordHistoryProcessingFailed(int attempts) {
    if (attempts <= 0) {
      return _catalog.recordHistoryProcessingFailed;
    }
    return _catalog.recordHistoryProcessingFailedOtherAttempts(attempts);
  }

  /// A record that arrived in [package], a package file name (data).
  String recordHistoryImported(String package) {
    return package.isEmpty
        ? _catalog.recordHistoryImported
        : _catalog.recordHistoryImportedImportedFrom(package);
  }

  /// A record changed by merging [package], a package file name (data).
  String recordHistoryMerged(String package) {
    return package.isEmpty
        ? _catalog.recordHistoryMerged
        : _catalog.recordHistoryMergedMergedFrom(package);
  }

  /// A record included in export [version], stored as `v<number>`.
  String recordHistoryExported(String version) {
    return version.isEmpty
        ? _catalog.recordHistoryExported
        : _catalog.recordHistoryExportedExportedInExport(version);
  }

  /// Value [label] (data) lost every photo it was read from. The value is
  /// kept.
  String recordHistoryEvidenceRemoved(String label) {
    return _catalog.recordHistoryEvidenceRemoved(label);
  }

  /// Value [label] (data) has a photo it was read from again.
  String recordHistoryEvidenceRestored(String label) {
    return _catalog.recordHistoryEvidenceRestored(label);
  }

  /// Value [label] (data) kept as retired by a template change.
  String recordHistoryRetired(String label) =>
      _catalog.recordHistoryRetired(label);

  /// Retired value [label] (data) that a template change mapped again.
  String recordHistoryMappedAgain(String label) {
    return _catalog.recordHistoryMappedAgain(label);
  }

  /// The record matched to a row of its template's checklist.
  String get recordHistoryRowMatched => _catalog.recordHistoryRowMatched;

  /// A photo file of the record was found missing from this device.
  String get recordHistoryFileMissing => _catalog.recordHistoryFileMissing;

  /// Any other change the audit table holds for the record.
  String get recordHistoryOther => _catalog.recordHistoryOther;

  /// Title of the sheet that shows one history line whole.
  String get recordHistoryLineTitle => _catalog.recordHistoryLineTitle;

  /// Label of the value or status a change replaced.
  String get recordHistoryBefore => _catalog.recordHistoryBefore;

  /// Label of the value or status a change wrote.
  String get recordHistoryAfter => _catalog.recordHistoryAfter;

  /// Label of when a change was written.
  String get recordHistoryWhen => _catalog.recordHistoryWhen;

  /// Label of who wrote a change.
  String get recordHistoryOperator => _catalog.recordHistoryOperator;

  /// Label of the device a change was written on.
  String get recordHistoryDevice => _catalog.recordHistoryDevice;

  /// Label of why a change was made.
  String get recordHistoryReason => _catalog.recordHistoryReason;

  /// Stands in for an operator or device the audit row does not hold.
  String get recordHistoryNotRecorded => _catalog.recordHistoryNotRecorded;

  /// Stands in for a value that was empty before or after a change.
  String get recordHistoryEmptyValue => _catalog.recordHistoryEmptyValue;

  /// When a change was written, in full; [at] is local time.
  String recordHistoryAt(DateTime at) {
    return _withLocale(() {
      return DateFormat.yMMMd().add_jms().format(at);
    });
  }

  // Records: editing, photos and template change (014).

  /// Title of the page that edits a saved record's values.
  String get recordValuesEditTitle => _catalog.recordValuesEditTitle;

  /// Title of the one-value sheet when the caller does not name the field.
  String get recordValueEditTitle => _catalog.recordValueEditTitle;

  /// Above the values of an approved record: what saving a change does.
  String get recordEditApprovedNotice => _catalog.recordEditApprovedNotice;

  /// Marks a value its record's template no longer has. It is kept, and it
  /// cannot be edited or removed.
  String get recordValueRetired => _catalog.recordValueRetired;

  /// Heading over the values a record keeps after its template dropped them.
  String get recordRetiredValuesTitle => _catalog.recordRetiredValuesTitle;

  /// Why retired values cannot be edited.
  String get recordRetiredValuesMessage => _catalog.recordRetiredValuesMessage;

  /// Marks a value whose source photos were all removed. The value is kept.
  String get recordValueEvidenceRemoved => _catalog.recordValueEvidenceRemoved;

  /// Shown when a record's template is no longer on this device.
  String get recordTemplateMissingNotice =>
      _catalog.recordTemplateMissingNotice;

  /// The edit page of a record that sits in the recycle bin.
  String get recordEditDeletedHeadline => _catalog.recordEditDeletedHeadline;

  /// What to do before editing a record in the recycle bin.
  String get recordEditDeletedMessage => _catalog.recordEditDeletedMessage;

  /// The one-value sheet for a field the record's template no longer has.
  String get recordFieldMissingHeadline => _catalog.recordFieldMissingHeadline;

  /// What to do when the one-value sheet has no field to show.
  String get recordFieldMissingMessage => _catalog.recordFieldMissingMessage;

  /// Why a saved value cannot be emptied: the captured original always
  /// stays, so an empty edit would show it again (FE-SEC-08).
  String get recordValueCannotEmpty => _catalog.recordValueCannotEmpty;

  /// Snack once [n] values are saved. [backToReview] adds that the record,
  /// which was approved, is waiting for review again.
  String recordValuesSaved(int n, {bool backToReview = false}) {
    final String saved = _catalog.recordValuesSaved(n);
    return backToReview
        ? _catalog.recordValuesSavedTheRecordIsBack(saved)
        : _catalog.recordValuesSavedValue(saved);
  }

  // Photos added to a saved record, and moving it to another template.

  /// Title of the offer to process a record again after photos were added.
  String get recordPhotosProcessTitle => _catalog.recordPhotosProcessTitle;

  /// Body of that offer: what processing the [n] added photos does, and
  /// that values already on the record stay.
  String recordPhotosProcessMessage(int n) {
    return _catalog.recordPhotosProcessMessage(n);
  }

  /// Confirms processing the record again.
  String get recordPhotosProcessConfirm => _catalog.recordPhotosProcessConfirm;

  /// Snack once the record is back in the processing queue.
  String get recordPhotosProcessQueued => _catalog.recordPhotosProcessQueued;

  /// Title of the sheet that moves a record to another template.
  String get recordTemplateChangeTitle => _catalog.recordTemplateChangeTitle;

  /// Names the template the record is on now. [name] is data.
  String recordTemplateChangeCurrent(String name) =>
      _catalog.recordTemplateChangeCurrent(name);

  /// Heading over the templates the record can move to.
  String get recordTemplateChangeChoose => _catalog.recordTemplateChangeChoose;

  /// Shown before a template is chosen.
  String get recordTemplateChangeHint => _catalog.recordTemplateChangeHint;

  /// Heading over the values whose field the chosen template also has.
  String recordTemplateChangeMapped(int n) {
    return _catalog.recordTemplateChangeMapped(n);
  }

  /// Heading over the values the chosen template has no field for.
  String recordTemplateChangeRetired(int n) {
    return _catalog.recordTemplateChangeRetired(n);
  }

  /// Heading over the chosen template's fields the record has no value for.
  String recordTemplateChangeAdded(int n) {
    return _catalog.recordTemplateChangeAdded(n);
  }

  /// Heading over retired values whose field the chosen template has again.
  String recordTemplateChangeRestored(int n) {
    return _catalog.recordTemplateChangeRestored(n);
  }

  /// Why retiring a value loses nothing.
  String get recordTemplateChangeRetiredNotice =>
      _catalog.recordTemplateChangeRetiredNotice;

  /// When the move changes no value at all.
  String get recordTemplateChangeNoValues =>
      _catalog.recordTemplateChangeNoValues;

  /// Above the preview of an approved record: what applying does.
  String get recordTemplateChangeApprovedNotice =>
      _catalog.recordTemplateChangeApprovedNotice;

  /// Applies the move.
  String get recordTemplateChangeApply => _catalog.recordTemplateChangeApply;

  /// Snack once the record is on its new template. [backToReview] adds that
  /// the record, which was approved, is waiting for review again.
  String recordTemplateChanged({bool backToReview = false}) {
    return backToReview
        ? _catalog.recordTemplateChanged
        : _catalog.recordTemplateChangedTemplateChanged;
  }

  /// No other template to move the record to.
  String get recordTemplateChangeEmptyHeadline =>
      _catalog.recordTemplateChangeEmptyHeadline;

  /// What to do when the project has no other template.
  String get recordTemplateChangeEmptyMessage =>
      _catalog.recordTemplateChangeEmptyMessage;

  /// Opens the project's templates from the empty state.
  String get recordTemplateChangeEmptyAction =>
      _catalog.recordTemplateChangeEmptyAction;

  /// The record to move is no longer on this device.
  String get recordTemplateChangeGoneHeadline =>
      _catalog.recordTemplateChangeGoneHeadline;

  /// What to do when the record to move is gone.
  String get recordTemplateChangeGoneMessage =>
      _catalog.recordTemplateChangeGoneMessage;

  /// What to do when Change template is pressed before a template is chosen.
  String get recordTemplateChangeChooseAction =>
      _catalog.recordTemplateChangeChooseAction;

  /// A second press while the record is already moving.
  String get recordTemplateChangeApplying =>
      _catalog.recordTemplateChangeApplying;

  /// What to do while the record is already moving.
  String get recordTemplateChangeApplyingAction =>
      _catalog.recordTemplateChangeApplyingAction;

  // Records: delete, recycle bin and bulk actions (014).

  /// Names the delete control for [n] records, for its tooltip and screen
  /// readers.
  String recordsDeleteLabel(int n) {
    return _catalog.recordsDeleteLabel(n);
  }

  /// Title of the confirm before [n] records move to the recycle bin.
  String recordsDeleteTitle(int n) {
    return _catalog.recordsDeleteTitle(n);
  }

  /// Body of that confirm: where the [records] go, and for how many [days]
  /// they can still be restored whole.
  String recordsDeleteMessage({required int records, required int days}) {
    final String window = settingsRetentionDays(days);
    return _catalog.recordsDeleteMessage(records, window);
  }

  /// Confirms the move to the recycle bin.
  String get recordsDeleteConfirm => _catalog.recordsDeleteConfirm;

  /// Snack once [n] records are in the recycle bin. Undo sits beside it.
  String recordsDeleted(int n) {
    return _catalog.recordsDeleted(n);
  }

  /// Snack or line when [n] records could not be deleted.
  String recordsNotDeleted(int n) {
    return _catalog.recordsNotDeleted(n);
  }

  /// Snack when some records were deleted and some were not. Undo brings
  /// back the [deleted] ones.
  String recordsDeletedPartly({required int deleted, required int failed}) {
    return _catalog.recordsDeletedPartly(
      recordsDeleted(deleted),
      recordsNotDeleted(failed),
    );
  }

  /// Snack once [n] records are back from the recycle bin.
  String recordsRestored(int n) {
    return _catalog.recordsRestored(n);
  }

  /// Snack or line when [n] records could not be restored.
  String recordsNotRestored(int n) {
    return _catalog.recordsNotRestored(n);
  }

  // Recycle bin (014 step 7).

  /// Title of the recycle bin page.
  String get recycleBinTitle => _catalog.recycleBinTitle;

  /// Storage settings row that opens the recycle bin.
  String get recycleBinSettingsSubtitle => _catalog.recycleBinSettingsSubtitle;

  /// The line above the recycle bin list: how long a deleted record stays
  /// restorable, [days] being the operator's window.
  String recycleBinKeptFor(int days) {
    return _catalog.recycleBinKeptFor(settingsRetentionDays(days));
  }

  /// Headline of an empty recycle bin.
  String get recycleBinEmptyHeadline => _catalog.recycleBinEmptyHeadline;

  /// What an empty recycle bin is for, and the way a record gets back out:
  /// a deleted record waits here for [days].
  String recycleBinEmptyMessage(int days) {
    return _catalog.recycleBinEmptyMessage(settingsRetentionDays(days));
  }

  /// A recycle bin row's second line: the record's [number] when the row's
  /// title is its name, its [projectName], and when it was deleted
  /// ([deletedAt]). [projectName] is the operator's own text (FE-L10N-07).
  String recycleBinRowSubtitle({
    required String projectName,
    required DateTime deletedAt,
    int? number,
  }) {
    return _withLocale(() {
      final String when = DateFormat.yMMMd().add_jm().format(
        deletedAt.toLocal(),
      );
      return <String>[
        if (number != null) '#$number',
        if (projectName.trim().isNotEmpty) projectName.trim(),
        _catalog.recycleDeletedWhen(when),
      ].join(' · ');
    });
  }

  /// How long a record in the recycle bin has before the purge removes it
  /// for good: [days] whole days, 0 once its window has run out.
  String recycleBinDaysLeft(int days) {
    return _catalog.recycleBinDaysLeft(days);
  }

  /// Tooltip of a recycle bin row's restore control.
  String get recycleBinRestore => _catalog.recycleBinRestore;

  /// Screen-reader name of the restore control on the row of record
  /// [name], which is the record's own text (FE-L10N-07).
  String recycleBinRestoreLabel(String name) =>
      _catalog.recycleBinRestoreLabel(name);

  /// A restore asked for while the same record is being restored.
  String get recycleBinRestoring => _catalog.recycleBinRestoring;

  /// What to do while a record is being restored.
  String get recycleBinRestoringAction => _catalog.recycleBinRestoringAction;

  /// The action that removes everything in the recycle bin now.
  String get recycleBinEmpty => _catalog.recycleBinEmpty;

  /// Title of the strong confirm before [n] records are removed for good.
  String recycleBinEmptyTitle(int n) {
    return _catalog.recycleBinEmptyTitle(n);
  }

  /// Body of that confirm: what goes, that it cannot be undone, and what
  /// stays.
  String recycleBinEmptyWarning(int n) {
    return _catalog.recycleBinEmptyWarning(n);
  }

  /// Label of the field the operator types [n] into to confirm.
  String recycleBinEmptyTypeCount(int n) =>
      _catalog.recycleBinEmptyTypeCount(n);

  /// Confirms emptying the recycle bin.
  String get recycleBinEmptyConfirm => _catalog.recycleBinEmptyConfirm;

  /// Why Empty recycle bin cannot be pressed on this device.
  String get recycleBinEmptyUnavailable => _catalog.recycleBinEmptyUnavailable;

  /// What to do when emptying is not available.
  String get recycleBinEmptyUnavailableAction =>
      _catalog.recycleBinEmptyUnavailableAction;

  /// An empty-now asked for while the recycle bin is being emptied.
  String get recycleBinEmptying => _catalog.recycleBinEmptying;

  /// What to do while the recycle bin is being emptied.
  String get recycleBinEmptyingAction => _catalog.recycleBinEmptyingAction;

  /// Snack after emptying the recycle bin: how many records were [purged],
  /// how many were [kept] because a merge still needs them, and how many
  /// [failed] and stay for the next try.
  String recycleBinEmptied({
    required int purged,
    required int kept,
    required int failed,
  }) {
    return <String>[
      _catalog.recycleBinEmptied(purged),
      if (kept > 0) _catalog.recycleBinEmptiedOtherKeptBecauseA(kept),
      if (failed > 0) _catalog.recycleBinEmptiedOtherCouldNotBe(failed),
    ].join('. ');
  }

  // Bulk actions over a selection (014 step 8).

  /// The bulk action bar's count of ticked records.
  String recordsSelectedCount(int n) {
    return _catalog.recordsSelectedCount(n);
  }

  /// Unticks every record and leaves selection mode.
  String get recordsClearSelection => _catalog.recordsClearSelection;

  /// Ticks every record the list has shown.
  String get recordsSelectAllShown => _catalog.recordsSelectAllShown;

  /// Names the bulk approve control for [n] records.
  String recordsApproveLabel(int n) {
    return _catalog.recordsApproveLabel(n);
  }

  /// Names the bulk archive control for [n] records.
  String recordsArchiveLabel(int n) {
    return _catalog.recordsArchiveLabel(n);
  }

  /// Names the bulk process-again control for [n] records.
  String recordsReprocessLabel(int n) {
    return _catalog.recordsReprocessLabel(n);
  }

  /// Names the bulk export control for [n] records.
  String recordsExportLabel(int n) {
    return _catalog.recordsExportLabel(n);
  }

  /// Title of the confirm before [n] records are archived.
  String recordsArchiveTitle(int n) {
    return _catalog.recordsArchiveTitle(n);
  }

  /// Body of that confirm: where the [n] records go and how to find them.
  String recordsArchiveMessage(int n) {
    return _catalog.recordsArchiveMessage(n);
  }

  /// Confirms archiving.
  String get recordsArchiveConfirm => _catalog.recordsArchiveConfirm;

  /// Title of the confirm before [n] records are processed again.
  String recordsReprocessTitle(int n) {
    return _catalog.recordsReprocessTitle(n);
  }

  /// Body of that confirm: what processing again does to the [n] records.
  String recordsReprocessMessage(int n) {
    return _catalog.recordsReprocessMessage(n);
  }

  /// Confirms processing again.
  String get recordsReprocessConfirm => _catalog.recordsReprocessConfirm;

  /// Title of the confirm before exporting with [n] records selected.
  String recordsExportTitle(int n) {
    return _catalog.recordsExportTitle(n);
  }

  /// Body of that confirm: an export is the whole project's package.
  String recordsExportMessage(int n) {
    return _catalog.recordsExportMessage(n);
  }

  /// Opens the project's export page.
  String get recordsExportConfirm => _catalog.recordsExportConfirm;

  /// Snack once [n] records are approved.
  String recordsApproved(int n) {
    return _catalog.recordsApproved(n);
  }

  /// Snack or line when [n] records could not be approved.
  String recordsNotApproved(int n) {
    return _catalog.recordsNotApproved(n);
  }

  /// Snack once [n] records are archived.
  String recordsArchived(int n) {
    return _catalog.recordsArchived(n);
  }

  /// Snack or line when [n] records could not be archived.
  String recordsNotArchived(int n) {
    return _catalog.recordsNotArchived(n);
  }

  /// Snack once [n] records are back in the processing queue.
  String recordsRequeued(int n) {
    return _catalog.recordsRequeued(n);
  }

  /// Snack or line when [n] records could not be queued again.
  String recordsNotRequeued(int n) {
    return _catalog.recordsNotRequeued(n);
  }

  /// Added to that snack while offline: the [n] queued records wait.
  String recordsRequeuedOffline(int n) {
    return _catalog.recordsRequeuedOffline(n);
  }

  /// A bulk action's summary when some records changed and some did not:
  /// [done] and [notDone] are the two counted sentences.
  String recordsBulkOutcome({required String done, required String notDone}) {
    return _catalog.recordsBulkOutcome(done, notDone);
  }

  /// A bulk action asked for while another is still running.
  String get recordsBulkBusy => _catalog.recordsBulkBusy;

  /// What to do while a bulk action is running.
  String get recordsBulkBusyAction => _catalog.recordsBulkBusyAction;

  // Records: data and purge (014).

  /// How many validation issues a form is showing.
  String validationIssueCount(int errors, int warnings) {
    if (errors > 0 && warnings > 0) {
      return _catalog.validationIssueCount(
        validationErrorCount(errors),
        validationWarningCount(warnings),
      );
    }
    if (errors > 0) {
      return validationErrorCount(errors);
    }
    return validationWarningCount(warnings);
  }

  /// Error count for a validation summary.
  String validationErrorCount(int n) {
    return _catalog.validationErrorCount(n);
  }

  /// Warning count for a validation summary.
  String validationWarningCount(int n) {
    return _catalog.validationWarningCount(n);
  }

  /// Jumps the summary to the first field that has an error.
  String get validationGoToFirstError => _catalog.validationGoToFirstError;

  /// Word beside an error, so the state is not colour alone.
  String get validationErrorLabel => _catalog.validationErrorLabel;

  /// Word beside a warning, so the state is not colour alone.
  String get validationWarningLabel => _catalog.validationWarningLabel;

  /// A required field that is empty.
  String validationRequired(String label) => _catalog.validationRequired(label);

  /// A value that is the wrong kind for its field.
  String validationType(String label) => _catalog.validationType(label);

  /// A value shorter than the field allows.
  String validationTooShort(String label) => _catalog.validationTooShort(label);

  /// A value longer than the field allows.
  String validationTooLong(String label) => _catalog.validationTooLong(label);

  /// A value outside the field's numeric range.
  String validationRange(String label) => _catalog.validationRange(label);

  /// A value that does not match the field's pattern.
  String validationPattern(String label) => _catalog.validationPattern(label);

  /// A choice that is not one of the field's options.
  String validationOption(String label) => _catalog.validationOption(label);

  /// A measurement the field's unit cannot hold.
  String validationUnit(String label) => _catalog.validationUnit(label);

  /// An identity field left empty.
  String validationIdentity(String label) => _catalog.validationIdentity(label);

  /// Evidence the template demands is missing.
  String get validationEvidence => _catalog.validationEvidence;

  /// A computed expression that does not parse.
  String get validationExpression => _catalog.validationExpression;

  /// What to do when an expression does not parse.
  String get validationExpressionAction => _catalog.validationExpressionAction;

  /// An expression names a field the template does not have.
  String validationUnknownField(String name) =>
      _catalog.validationUnknownField(name);

  /// Duplicate prompt title.
  String get duplicatePromptTitle => _catalog.duplicatePromptTitle;

  /// Writes the new values onto the existing record.
  String get duplicateOverride => _catalog.duplicateOverride;

  /// Keeps both records and links them.
  String get duplicateLinkBoth => _catalog.duplicateLinkBoth;

  /// Drops the new record.
  String get duplicateDiscard => _catalog.duplicateDiscard;

  /// Opens the field-by-field merge.
  String get duplicateMerge => _catalog.duplicateMerge;

  /// Headline when two records do not differ.
  String get duplicateNoDifferenceHeadline =>
      _catalog.duplicateNoDifferenceHeadline;

  /// Why the duplicate prompt has nothing to compare.
  String get duplicateNoDifferenceMessage =>
      _catalog.duplicateNoDifferenceMessage;

  /// Duplicate compare title.
  String get duplicateCompareTitle => _catalog.duplicateCompareTitle;

  /// Merge sheet title.
  String get duplicateMergeTitle => _catalog.duplicateMergeTitle;

  /// Keeps this record's value for one field.
  String get duplicateKeepMine => _catalog.duplicateKeepMine;

  /// Takes the other record's value for one field.
  String get duplicateTakeTheirs => _catalog.duplicateTakeTheirs;

  /// Keeps both values for one field as a note.
  String get duplicateKeepBothNote => _catalog.duplicateKeepBothNote;

  /// The one question the duplicate prompt asks.
  String get duplicatePromptQuestion => _catalog.duplicatePromptQuestion;

  /// The prompt's override option: the comparison completes it.
  String get duplicateCompareThenUpdate => _catalog.duplicateCompareThenUpdate;

  /// Goes on with the outcome chosen in the prompt.
  String get duplicatePromptContinue => _catalog.duplicatePromptContinue;

  /// Heading of the record that was there first.
  String get duplicateExistingRecord => _catalog.duplicateExistingRecord;

  /// Heading of the newer record.
  String get duplicateNewRecord => _catalog.duplicateNewRecord;

  /// Heading over the fields two records do not share.
  String get duplicateDifferingFields => _catalog.duplicateDifferingFields;

  /// Leaves the comparison for the duplicates list.
  String get duplicateBackToList => _catalog.duplicateBackToList;

  /// A pair's row title: both records. [existing] and [incoming] are data.
  String duplicatePairTitle(String existing, String incoming) =>
      _catalog.duplicatePairTitle(existing, incoming);

  /// A pair's group: the signal and the template. [template] is data.
  String duplicatesGroup(String signal, String template) =>
      template.isEmpty ? signal : _catalog.duplicatesGroup(signal, template);

  /// The existing value, then the new one. The values are data.
  String duplicateValueChange(String existing, String incoming) =>
      _catalog.duplicateValueChange(
        existing.isEmpty ? conflictEmpty : existing,
        incoming.isEmpty ? conflictEmpty : incoming,
      );

  /// One differing field on a pair's row. The values are data.
  String duplicateDifferenceLine(
    String label,
    String existing,
    String incoming,
  ) => _catalog.duplicateDifferenceLine(
    label,
    duplicateValueChange(existing, incoming),
  );

  /// When and by whom a record was captured, and where. [by] and [place]
  /// are data.
  String duplicateCaptureDetail(DateTime at, String by, String place) {
    return _withLocale(() {
      final String when = DateFormat.yMMMd().add_jm().format(at.toLocal());
      return <String>[
        when,
        if (by.trim().isNotEmpty) by,
        if (place.trim().isNotEmpty) place,
      ].join(' · ');
    });
  }

  /// Confirm heading before an override.
  String get duplicateOverrideConfirmTitle =>
      _catalog.duplicateOverrideConfirmTitle;

  /// Confirm body before an override.
  String get duplicateOverrideConfirmMessage =>
      _catalog.duplicateOverrideConfirmMessage;

  /// Carries the newer record's photos onto the survivor of a merge.
  String get duplicateCarryPhotos => _catalog.duplicateCarryPhotos;

  /// Explains [duplicateCarryPhotos] with how many photos [n] move.
  String duplicateCarryPhotosHelp(int n) =>
      _catalog.duplicateCarryPhotosHelp(photosCount(n));

  /// Applies the merge sheet's choices.
  String get duplicateMergeApply => _catalog.duplicateMergeApply;

  /// The merge choice for one field. [label] is template data.
  String duplicateMergeKeep(String label) => _catalog.duplicateMergeKeep(label);

  /// Merge option: the existing record's value.
  String get duplicateMergeExisting => _catalog.duplicateMergeExisting;

  /// Merge option: the new record's value.
  String get duplicateMergeNew => _catalog.duplicateMergeNew;

  /// Merge option: both values.
  String get duplicateMergeBoth => _catalog.duplicateMergeBoth;

  /// Why the merge cannot run yet.
  String get duplicateMergeChooseAll => _catalog.duplicateMergeChooseAll;

  /// Both values of a field kept together. The values are data.
  String duplicateBothValues(String existing, String incoming) {
    if (existing.trim().isEmpty) {
      return incoming;
    }
    if (incoming.trim().isEmpty) {
      return existing;
    }
    return _catalog.duplicateBothValues(existing, incoming);
  }

  /// Outcome after both records are kept and linked.
  String get duplicateResolvedKeepBoth => _catalog.duplicateResolvedKeepBoth;

  /// Outcome after the new record is discarded.
  String get duplicateResolvedDiscard => _catalog.duplicateResolvedDiscard;

  /// Outcome after an override.
  String get duplicateResolvedOverride => _catalog.duplicateResolvedOverride;

  /// Outcome after a merge.
  String get duplicateResolvedMerge => _catalog.duplicateResolvedMerge;

  /// Recycle-bin reason of a discarded duplicate.
  String get duplicateDiscardedReason => _catalog.duplicateDiscardedReason;

  /// Recycle-bin reason of a record whose values overrode another.
  String get duplicateOverriddenReason => _catalog.duplicateOverriddenReason;

  /// Recycle-bin reason of a record merged into another.
  String get duplicateMergedReason => _catalog.duplicateMergedReason;

  /// A pair that is resolved or gone.
  String get duplicatePairGone => _catalog.duplicatePairGone;

  /// What to do about [duplicatePairGone].
  String get duplicatePairGoneRecovery => _catalog.duplicatePairGoneRecovery;

  /// Runs detection over a whole project.
  String get duplicatesScan => _catalog.duplicatesScan;

  /// Outcome of [duplicatesScan]: how many new pairs [n] were queued.
  String duplicatesScanned(int n) => switch (n) {
    0 => _catalog.duplicatesScanned,
    1 => _catalog.duplicatesScannedNewDuplicatePair,
    _ => _catalog.duplicatesScannedNewDuplicatePairs(n),
  };

  /// The sheet that asks which choice a whole group gets.
  String get duplicatesBulkChoose => _catalog.duplicatesBulkChoose;

  /// Outcome of a bulk choice over [n] pairs.
  String duplicatesBulkDone(int n) => n == 1
      ? _catalog.duplicatesBulkDone
      : _catalog.duplicatesBulkDonePairsResolved(n);

  /// A record's badge: the record it is linked to. [title] is data.
  String duplicateLinkedTo(String title) => _catalog.duplicateLinkedTo(title);

  /// A record's badge: the record it may duplicate. [title] is data.
  String duplicatePossibleOf(String title) =>
      _catalog.duplicatePossibleOf(title);

  /// Duplicates review title.
  String get duplicatesTitle => _catalog.duplicatesTitle;

  /// Empty duplicates list headline.
  String get duplicatesEmptyHeadline => _catalog.duplicatesEmptyHeadline;

  /// Empty duplicates list explanation.
  String get duplicatesEmptyMessage => _catalog.duplicatesEmptyMessage;

  /// Clears every remaining pair in one group.
  String get duplicatesResolveGroup => _catalog.duplicatesResolveGroup;

  /// Bulk confirm title naming [choice] and how many records [n].
  String duplicatesBulkTitle(int n, String choice) =>
      _catalog.duplicatesBulkTitle(choice, n);

  /// Bulk confirm body naming how many records [n] change.
  String duplicatesBulkMessage(int n) => _catalog.duplicatesBulkMessage(n);

  /// Types a value that matches none of the candidates.
  String get conflictTypeOwn => _catalog.conflictTypeOwn;

  /// Keeps the value typed in [conflictTypeOwn].
  String get conflictUseTyped => _catalog.conflictUseTyped;

  /// The reason a person gives for the value they chose.
  String get conflictReason => _catalog.conflictReason;

  /// Empty conflict row headline.
  String get conflictEmptyHeadline => _catalog.conflictEmptyHeadline;

  /// Empty conflict row explanation.
  String get conflictEmptyMessage => _catalog.conflictEmptyMessage;

  /// Unresolved conflict blocks approval and names the field.
  String conflictBlocksApproval(String label) =>
      _catalog.conflictBlocksApproval(label);

  /// Verification mode switch title.
  String get verificationModeTitle => _catalog.verificationModeTitle;

  /// Shown while verification mode is on.
  String get verificationModeOn => _catalog.verificationModeOn;

  /// Shown while verification mode is off.
  String get verificationModeOff => _catalog.verificationModeOff;

  /// Status line mark while verification mode is on.
  String get verificationStatus => _catalog.verificationStatus;

  /// A value that came from the register.
  String get verificationFromRegister => _catalog.verificationFromRegister;

  /// Variance screen title.
  String get varianceTitle => _catalog.varianceTitle;

  /// Empty variance list headline.
  String get varianceEmptyHeadline => _catalog.varianceEmptyHeadline;

  /// Empty variance list explanation.
  String get varianceEmptyMessage => _catalog.varianceEmptyMessage;

  /// A normalised match.
  String get varianceMatch => _catalog.varianceMatch;

  /// A genuine difference.
  String get varianceChanged => _catalog.varianceChanged;

  /// A register value with nothing found.
  String get varianceMissing => _catalog.varianceMissing;

  /// A variance row's detail: its status and both values, which are data.
  String varianceDetail(String status, String recorded, String found) =>
      _catalog.varianceDetail(
        status,
        recorded.isEmpty ? conflictEmpty : recorded,
        found.isEmpty ? conflictEmpty : found,
      );

  /// Register rows no record was captured from.
  String get varianceRegisterNotFound => _catalog.varianceRegisterNotFound;

  /// Checklist rows never captured.
  String get varianceChecklistNotCaptured =>
      _catalog.varianceChecklistNotCaptured;

  /// The variance empty state's next step.
  String get varianceOpenRecords => _catalog.varianceOpenRecords;

  /// Quality summary title.
  String get qualitySummaryTitle => _catalog.qualitySummaryTitle;

  /// Records that fail validation.
  String get qualityInvalid => _catalog.qualityInvalid;

  /// Unresolved duplicate pairs.
  String get qualityDuplicates => _catalog.qualityDuplicates;

  /// Unresolved source conflicts.
  String get qualityConflicts => _catalog.qualityConflicts;

  /// Records still waiting for review.
  String get qualityUnreviewed => _catalog.qualityUnreviewed;

  /// Headline when nothing blocks export.
  String get qualityCleanHeadline => _catalog.qualityCleanHeadline;

  /// Explanation when nothing blocks export.
  String get qualityCleanMessage => _catalog.qualityCleanMessage;

  /// Review screen title.
  String get reviewTitle => _catalog.reviewTitle;

  /// Fields that need a person before approval.
  String get reviewNeedsAttention => _catalog.reviewNeedsAttention;

  /// Confident fields, collapsed until opened.
  String get reviewConfident => _catalog.reviewConfident;

  /// The confident group's heading, with how many fields it holds.
  String reviewConfidentGroup(int count) =>
      _catalog.reviewConfidentGroup(count);

  /// Approves this record and opens the next one.
  String get reviewApproveNext => _catalog.reviewApproveNext;

  /// Empty review headline.
  String get reviewEmptyHeadline => _catalog.reviewEmptyHeadline;

  /// Empty review explanation.
  String get reviewEmptyMessage => _catalog.reviewEmptyMessage;

  /// Shows the captured value.
  String get reviewUseRaw => _catalog.reviewUseRaw;

  /// Shows the refined value.
  String get reviewUseRefined => _catalog.reviewUseRefined;

  /// Neither side has a value.
  String get reviewNoSidesHeadline => _catalog.reviewNoSidesHeadline;

  /// Why the raw or refined toggle has nothing to choose.
  String get reviewNoSidesMessage => _catalog.reviewNoSidesMessage;

  /// A value the extractor did not invent.
  String get reviewNotDetected => _catalog.reviewNotDetected;

  /// Types the missing value.
  String get reviewTypeIt => _catalog.reviewTypeIt;

  /// Photographs the label for the missing value.
  String get reviewPhotograph => _catalog.reviewPhotograph;

  /// No missing value to act on.
  String get reviewNotDetectedEmpty => _catalog.reviewNotDetectedEmpty;

  /// Opens the evidence for a value.
  String get reviewShowEvidence => _catalog.reviewShowEvidence;

  /// Opens the full photo.
  String get reviewOpenPhoto => _catalog.reviewOpenPhoto;

  /// Evidence with no photo and no passage.
  String get reviewEvidenceEmpty => _catalog.reviewEvidenceEmpty;

  /// Verifies the current value without changing it.
  String get reviewVerify => _catalog.reviewVerify;

  /// Verifies every confident field.
  String get reviewVerifyConfident => _catalog.reviewVerifyConfident;

  /// Who verified a value, and when.
  String reviewVerifiedBy(String name) => _catalog.reviewVerifiedBy(name);

  /// Nothing to verify.
  String get reviewVerifyEmpty => _catalog.reviewVerifyEmpty;

  /// Batch position, [index] of [total], both 1-based for [index].
  String reviewPosition(int index, int total) =>
      _catalog.reviewPosition(index, total);

  /// Skips this record and keeps what was typed.
  String get reviewSkip => _catalog.reviewSkip;

  /// Returns to the previous record.
  String get reviewBack => _catalog.reviewBack;

  /// The batch queue is finished.
  String get reviewQueueDone => _catalog.reviewQueueDone;

  /// What to do when the queue is finished.
  String get reviewQueueDoneMessage => _catalog.reviewQueueDoneMessage;

  /// The batch queue has no records.
  String get reviewQueueEmpty => _catalog.reviewQueueEmpty;

  /// Runs processing again.
  String get reviewReanalyse => _catalog.reviewReanalyse;

  /// A proposed value offered beside the current one.
  String get reviewProposal => _catalog.reviewProposal;

  /// Marks a proposal the person accepts.
  String get reviewAccept => _catalog.reviewAccept;

  /// Writes the accepted proposals.
  String get reviewApplyAccepted => _catalog.reviewApplyAccepted;

  /// Declines every proposal.
  String get reviewDeclineAll => _catalog.reviewDeclineAll;

  /// A verified or typed value that re-analysis must not overwrite.
  String get reviewOfferedNotApplied => _catalog.reviewOfferedNotApplied;

  /// No new proposals.
  String get reviewReanalyseEmpty => _catalog.reviewReanalyseEmpty;

  /// This record is still in an unresolved duplicate pair.
  String get reviewBlockedDuplicate => _catalog.reviewBlockedDuplicate;

  /// Where to clear a block.
  String get reviewBlockedAction => _catalog.reviewBlockedAction;

  /// Empty confidence indicator headline.
  String get reviewNoConfidence => _catalog.reviewNoConfidence;

  /// Empty confidence indicator explanation.
  String get reviewNoConfidenceMessage => _catalog.reviewNoConfidenceMessage;

  /// Audit line when review approves a record.
  String get reviewApprovedReason => _catalog.reviewApprovedReason;

  /// Audit line when a person verifies a value without changing it.
  String get reviewVerifiedReason => _catalog.reviewVerifiedReason;

  /// Audit line when a person picks the captured or the refined side.
  String get reviewSideReason => _catalog.reviewSideReason;

  /// Why review refused a write: the record is approved or in the bin.
  String get reviewRecordSettled => _catalog.reviewRecordSettled;

  /// What to do about [reviewRecordSettled].
  String get reviewRecordSettledAction => _catalog.reviewRecordSettledAction;

  /// Why review refused a write: the record is not on this device.
  String get reviewRecordGone => _catalog.reviewRecordGone;

  /// What to do about [reviewRecordGone].
  String get reviewRecordGoneAction => _catalog.reviewRecordGoneAction;

  /// Label of the control that picks which side of a value is final.
  String get reviewFinalSide => _catalog.reviewFinalSide;

  /// Moves back to the previous record in the review queue.
  String get reviewPreviousRecord => _catalog.reviewPreviousRecord;

  /// The review empty state's next step.
  String get reviewBackToRecords => _catalog.reviewBackToRecords;

  /// Snack after verifying [count] values without changing them.
  String reviewVerifiedCount(int count) {
    return _catalog.reviewVerifiedCount(count);
  }

  /// A verified value's mark.
  String get reviewVerified => _catalog.reviewVerified;

  /// Title of the sheet showing where a value came from.
  String get reviewEvidenceTitle => _catalog.reviewEvidenceTitle;

  /// Source label of photo evidence.
  String get reviewEvidencePhoto => _catalog.reviewEvidencePhoto;

  /// Source label of document evidence on [page], when known.
  String reviewEvidenceDocument(int? page) {
    return page == null
        ? _catalog.reviewEvidenceDocument
        : _catalog.reviewEvidenceDocumentFromADocumentPage(page);
  }

  /// Source label of transcript evidence.
  String get reviewEvidenceTranscript => _catalog.reviewEvidenceTranscript;

  /// The highlighted region on an evidence photo, for a screen reader.
  String get reviewEvidenceRegion => _catalog.reviewEvidenceRegion;

  /// Snack after re-analysis was queued.
  String get reviewReanalyseQueued => _catalog.reviewReanalyseQueued;

  /// Banner while re-analysis runs.
  String get reviewReanalysing => _catalog.reviewReanalysing;

  /// Heading of the proposals re-analysis offers.
  String get reviewProposalsTitle => _catalog.reviewProposalsTitle;

  /// One proposal: the [current] value beside the [proposed] one.
  String reviewProposalLine(String current, String proposed) {
    return _catalog.reviewProposalLine(
      current.isEmpty ? recordFieldEmpty : current,
      proposed,
    );
  }

  /// Snack after accepted proposals were written.
  String reviewProposalsApplied(int count) {
    return _catalog.reviewProposalsApplied(count);
  }

  /// Meeting create page title.
  String get meetingTitle => _catalog.meetingTitle;

  /// Starts a meeting from the prefilled header.
  String get meetingStart => _catalog.meetingStart;

  /// Empty meeting headline.
  String get meetingEmptyHeadline => _catalog.meetingEmptyHeadline;

  /// Empty meeting explanation.
  String get meetingEmptyMessage => _catalog.meetingEmptyMessage;

  /// Header date label.
  String get meetingDate => _catalog.meetingDate;

  /// Header start-time label.
  String get meetingStartTime => _catalog.meetingStartTime;

  /// Header location label.
  String get meetingLocation => _catalog.meetingLocation;

  /// Header secretary label.
  String get meetingSecretary => _catalog.meetingSecretary;

  /// Title written when a meeting starts, from the clock's date.
  String meetingStartedTitle(DateTime when) {
    final String month = when.month.toString().padLeft(2, '0');
    final String day = when.day.toString().padLeft(2, '0');
    return _catalog.meetingStartedTitle(when.year, month, day);
  }

  /// Attachments section.
  String get meetingAttachments => _catalog.meetingAttachments;

  /// Adds an attachment.
  String get meetingAddAttachment => _catalog.meetingAddAttachment;

  /// Empty attachments headline.
  String get meetingAttachmentsEmpty => _catalog.meetingAttachmentsEmpty;

  /// Empty attachments explanation.
  String get meetingAttachmentsEmptyMessage =>
      _catalog.meetingAttachmentsEmptyMessage;

  /// Opens an attachment.
  String get meetingOpenAttachment => _catalog.meetingOpenAttachment;

  /// Agenda section.
  String get meetingAgenda => _catalog.meetingAgenda;

  /// Adds an agenda entry.
  String get meetingAddAgenda => _catalog.meetingAddAgenda;

  /// Agenda title field.
  String get meetingAgendaTitle => _catalog.meetingAgendaTitle;

  /// Discussion notes under an agenda entry.
  String get meetingDiscussion => _catalog.meetingDiscussion;

  /// Moves an entry later.
  String get meetingMoveDown => _catalog.meetingMoveDown;

  /// Removes an entry after confirm.
  String get meetingRemove => _catalog.meetingRemove;

  /// Confirm title for a removal.
  String get meetingRemoveTitle => _catalog.meetingRemoveTitle;

  /// Confirm body for a removal.
  String get meetingRemoveMessage => _catalog.meetingRemoveMessage;

  /// Confirm button for a removal.
  String get meetingRemoveConfirm => _catalog.meetingRemoveConfirm;

  /// Empty agenda headline.
  String get meetingAgendaEmpty => _catalog.meetingAgendaEmpty;

  /// Empty agenda explanation.
  String get meetingAgendaEmptyMessage => _catalog.meetingAgendaEmptyMessage;

  /// Attendees section.
  String get meetingAttendees => _catalog.meetingAttendees;

  /// Adds an attendee.
  String get meetingAddAttendee => _catalog.meetingAddAttendee;

  /// Attendee name field.
  String get meetingAttendeeName => _catalog.meetingAttendeeName;

  /// Attendee title field.
  String get meetingAttendeeRole => _catalog.meetingAttendeeRole;

  /// Attendee organisation field.
  String get meetingOrganisation => _catalog.meetingOrganisation;

  /// Attendee contact field.
  String get meetingContact => _catalog.meetingContact;

  /// Marks the person present.
  String get meetingPresent => _catalog.meetingPresent;

  /// Marks an apology.
  String get meetingApology => _catalog.meetingApology;

  /// How many people are present. Apologies are not included.
  String meetingAttendanceCount(int count) {
    return _catalog.meetingAttendanceCount(count);
  }

  /// Accepts a staff suggestion.
  String get meetingAcceptStaff => _catalog.meetingAcceptStaff;

  /// Empty attendees headline.
  String get meetingAttendeesEmpty => _catalog.meetingAttendeesEmpty;

  /// Empty attendees explanation.
  String get meetingAttendeesEmptyMessage =>
      _catalog.meetingAttendeesEmptyMessage;

  /// Attendance sheet section.
  String get meetingAttendanceSheet => _catalog.meetingAttendanceSheet;

  /// Photographs the signed sheet.
  String get meetingPhotographSheet => _catalog.meetingPhotographSheet;

  /// Accepts the edited rows onto the attendee list.
  String get meetingAcceptRows => _catalog.meetingAcceptRows;

  /// A poor read still keeps the photo.
  String get meetingSheetKept => _catalog.meetingSheetKept;

  /// Empty attendance headline.
  String get meetingSheetEmpty => _catalog.meetingSheetEmpty;

  /// Empty attendance explanation.
  String get meetingSheetEmptyMessage => _catalog.meetingSheetEmptyMessage;

  /// Signature column.
  String get meetingSignature => _catalog.meetingSignature;

  /// Recording section.
  String get meetingRecording => _catalog.meetingRecording;

  /// Starts recording.
  String get meetingRecord => _catalog.meetingRecord;

  /// Stops recording.
  String get meetingStop => _catalog.meetingStop;

  /// Elapsed recording time.
  String meetingElapsed(String clock) => _catalog.meetingElapsed(clock);

  /// Free space while recording.
  String meetingRemaining(String label) => _catalog.meetingRemaining(label);

  /// A recording interrupted before stop.
  String get meetingInterrupted => _catalog.meetingInterrupted;

  /// Empty recording headline.
  String get meetingRecordingEmpty => _catalog.meetingRecordingEmpty;

  /// Empty recording explanation.
  String get meetingRecordingEmptyMessage =>
      _catalog.meetingRecordingEmptyMessage;

  /// Decisions section.
  String get meetingDecisions => _catalog.meetingDecisions;

  /// Adds a decision.
  String get meetingAddDecision => _catalog.meetingAddDecision;

  /// Decision text field.
  String get meetingDecisionText => _catalog.meetingDecisionText;

  /// Where a refined decision came from.
  String get meetingSource => _catalog.meetingSource;

  /// Empty decisions headline.
  String get meetingDecisionsEmpty => _catalog.meetingDecisionsEmpty;

  /// Empty decisions explanation.
  String get meetingDecisionsEmptyMessage =>
      _catalog.meetingDecisionsEmptyMessage;

  /// Actions section.
  String get meetingActions => _catalog.meetingActions;

  /// Adds an action.
  String get meetingAddAction => _catalog.meetingAddAction;

  /// Action text field.
  String get meetingActionText => _catalog.meetingActionText;

  /// Owner field.
  String get meetingOwner => _catalog.meetingOwner;

  /// Due date field.
  String get meetingDue => _catalog.meetingDue;

  /// Picks an owner from the attendees.
  String get meetingOwnerAttendee => _catalog.meetingOwnerAttendee;

  /// Picks an owner from the staff dataset.
  String get meetingOwnerStaff => _catalog.meetingOwnerStaff;

  /// Action status.
  String get meetingStatus => _catalog.meetingStatus;

  /// Empty actions headline.
  String get meetingActionsEmpty => _catalog.meetingActionsEmpty;

  /// Empty actions explanation.
  String get meetingActionsEmptyMessage => _catalog.meetingActionsEmptyMessage;

  /// Raw notes beside the minutes.
  String get meetingNotes => _catalog.meetingNotes;

  /// Refined minutes beside the notes.
  String get meetingMinutes => _catalog.meetingMinutes;

  /// Verbatim transcript, never edited here.
  String get meetingTranscript => _catalog.meetingTranscript;

  /// Blocks approval and names the action.
  String meetingActionBlocked(String action) =>
      _catalog.meetingActionBlocked(action);

  /// Approves the meeting.
  String get meetingApprove => _catalog.meetingApprove;

  /// Review page title.
  String get meetingReviewTitle => _catalog.meetingReviewTitle;

  /// Empty review headline.
  String get meetingReviewEmpty => _catalog.meetingReviewEmpty;

  /// Empty review explanation.
  String get meetingReviewEmptyMessage => _catalog.meetingReviewEmptyMessage;

  /// Audit line when a meeting is approved.
  String get meetingApprovedReason => _catalog.meetingApprovedReason;

  /// Starts a meeting from a project, or opens the one a record holds.
  String get meetingStartEntry => _catalog.meetingStartEntry;

  /// Opens the meeting a record holds.
  String get meetingOpen => _catalog.meetingOpen;

  /// Name a project's installed meeting template takes.
  String get meetingTemplateName => _catalog.meetingTemplateName;

  /// A header value nothing filled in.
  String get meetingNotSet => _catalog.meetingNotSet;

  /// The meeting's date, in this device's time zone.
  String meetingDay(DateTime at) =>
      _withLocale(() => DateFormat.yMMMd().format(at.toLocal()));

  /// The meeting's start time, in this device's time zone.
  String meetingClock(DateTime at) =>
      _withLocale(() => DateFormat.jm().format(at.toLocal()));

  /// The project a meeting would be filed on is gone.
  String get meetingNoProject => _catalog.meetingNoProject;

  /// What to do when there is no project to start a meeting on.
  String get meetingNoProjectMessage => _catalog.meetingNoProjectMessage;

  /// Returns to the project list.
  String get meetingBackToProjects => _catalog.meetingBackToProjects;

  /// Summary section of the review.
  String get meetingSummary => _catalog.meetingSummary;

  /// How many decisions the meeting holds.
  String meetingDecisionsCount(int count) {
    return _catalog.meetingDecisionsCount(count);
  }

  /// How many actions the meeting holds.
  String meetingActionsCount(int count) {
    return _catalog.meetingActionsCount(count);
  }

  /// The raw notes and refined minutes section.
  String get meetingNotesAndMinutes => _catalog.meetingNotesAndMinutes;

  /// Refines the minutes from the notes and the transcript.
  String get meetingRefine => _catalog.meetingRefine;

  /// Refinement summarises per agenda point, so it needs an agenda.
  String get meetingRefineNeedsAgenda => _catalog.meetingRefineNeedsAgenda;

  /// Names what the notes and the transcript do not support.
  String meetingUnsupported(List<String> names) =>
      _catalog.meetingUnsupported(names.join(', '));

  /// One agenda point's line in the refined minutes.
  String meetingMinutesLine(String title, String summary) =>
      summary.isEmpty ? title : _catalog.meetingMinutesLine(title, summary);

  /// One transcription run of the recording.
  String meetingTranscriptVersion(int version) =>
      _catalog.meetingTranscriptVersion(version);

  /// Parts of a recording one run could not transcribe.
  String meetingTranscriptGaps(int count) {
    return _catalog.meetingTranscriptGaps(count);
  }

  /// Transcribes a recording.
  String get meetingTranscribe => _catalog.meetingTranscribe;

  /// Transcription progress, one part at a time.
  String meetingTranscribing(int done, int total) =>
      _catalog.meetingTranscribing(done, total);

  /// No service can transcribe right now.
  String get meetingTranscribeUnavailable =>
      _catalog.meetingTranscribeUnavailable;

  /// Plays a recording in the device's player.
  String get meetingPlay => _catalog.meetingPlay;

  /// A take that was interrupted is still on the meeting.
  String get meetingInterruptedKept => _catalog.meetingInterruptedKept;

  /// Photographs a handout or a whiteboard.
  String get meetingPhotographHandout => _catalog.meetingPhotographHandout;

  /// An attached document.
  String get meetingDocument => _catalog.meetingDocument;

  /// An attached photo.
  String get meetingPhoto => _catalog.meetingPhoto;

  /// What an attachment is, and its size.
  String meetingFileDetail(String kind, int bytes) =>
      _catalog.meetingFileDetail(kind, fileSize(bytes));

  /// A recording's length and size.
  String meetingRecordingDetail(Duration length, int bytes) {
    final String minutes = length.inMinutes.toString().padLeft(2, '0');
    final String seconds = length.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return _catalog.meetingRecordingDetail(minutes, seconds, fileSize(bytes));
  }

  /// A cell of the sheet that read with low confidence.
  String get meetingCheckReading => _catalog.meetingCheckReading;

  /// A signature was seen on the sheet.
  String get meetingSigned => _catalog.meetingSigned;

  /// Whether a person attended or sent apologies.
  String get meetingAttendance => _catalog.meetingAttendance;

  /// A staff row offered for a captured name, with its match score.
  String meetingStaffSuggestion(String name, double score) =>
      _catalog.meetingStaffSuggestion(name, (score * 100).round());

  /// The staff row a person accepted.
  String meetingStaffLinked(String name) => _catalog.meetingStaffLinked(name);

  /// Removes an accepted staff link.
  String get meetingUnlinkStaff => _catalog.meetingUnlinkStaff;

  /// One owner a person can pick for an action.
  String meetingOwnerOption(String name, {required bool staff}) => staff
      ? _catalog.meetingOwnerOption(name)
      : _catalog.meetingOwnerOptionAttendee(name);

  /// Action status: not finished.
  String get meetingStatusOpen => _catalog.meetingStatusOpen;

  /// Action status: under way.
  String get meetingStatusInProgress => _catalog.meetingStatusInProgress;

  /// Action status: finished.
  String get meetingStatusDone => _catalog.meetingStatusDone;

  /// Where a refined decision or action was read from.
  String meetingSourceLine(String source) =>
      _catalog.meetingSourceLine(meetingSource, source);

  /// Drag handle of one agenda point.
  String meetingDrag(String title) =>
      _catalog.meetingDrag(title.trim().isEmpty ? meetingAgendaTitle : title);

  /// Moves an entry earlier.
  String get meetingMoveUp => _catalog.meetingMoveUp;

  /// Deliverable export page title.
  String get exportTitle => _catalog.exportTitle;

  /// Starts the export.
  String get exportRun => _catalog.exportRun;

  /// Scope section title.
  String get exportScope => _catalog.exportScope;

  /// Approved records only.
  String get exportScopeApproved => _catalog.exportScopeApproved;

  /// Every record.
  String get exportScopeAll => _catalog.exportScopeAll;

  /// The current context subtree.
  String get exportScopeContext => _catalog.exportScopeContext;

  /// A date range.
  String get exportScopeDates => _catalog.exportScopeDates;

  /// The records list filter.
  String get exportScopeFilter => _catalog.exportScopeFilter;

  /// How many records the scope selects.
  String exportCount(int count) => _catalog.exportCount(count);

  /// Options section title.
  String get exportOptions => _catalog.exportOptions;

  /// Raw value columns.
  String get exportRaw => _catalog.exportRaw;

  /// Refined value columns.
  String get exportRefined => _catalog.exportRefined;

  /// Confidence column.
  String get exportConfidence => _catalog.exportConfidence;

  /// Evidence column.
  String get exportEvidence => _catalog.exportEvidence;

  /// Collapsed extras.
  String get exportAdvanced => _catalog.exportAdvanced;

  /// Photo reference mode.
  String get exportPhotoMode => _catalog.exportPhotoMode;

  /// CSV delimiter.
  String get exportDelimiter => _catalog.exportDelimiter;

  /// Empty export headline.
  String get exportEmptyHeadline => _catalog.exportEmptyHeadline;

  /// Empty export explanation.
  String get exportEmptyMessage => _catalog.exportEmptyMessage;

  /// Progress: records.
  String get exportStageRecords => _catalog.exportStageRecords;

  /// Progress: photos.
  String get exportStagePhotos => _catalog.exportStagePhotos;

  /// Progress: reports.
  String get exportStageReports => _catalog.exportStageReports;

  /// Progress: archive.
  String get exportStageArchive => _catalog.exportStageArchive;

  /// Stops an export and removes partial files.
  String get exportCancel => _catalog.exportCancel;

  /// History page title.
  String get exportHistoryTitle => _catalog.exportHistoryTitle;

  /// Empty history headline.
  String get exportHistoryEmpty => _catalog.exportHistoryEmpty;

  /// Empty history explanation.
  String get exportHistoryEmptyMessage => _catalog.exportHistoryEmptyMessage;

  /// Shares a recorded file again.
  String get exportShare => _catalog.exportShare;

  /// The recorded file is gone.
  String get exportMissing => _catalog.exportMissing;

  /// Offers to run the stored request again.
  String get exportRerun => _catalog.exportRerun;

  /// Gate: go fix the records.
  String get exportFixNow => _catalog.exportFixNow;

  /// Gate: leave the incomplete ones out.
  String get exportExclude => _catalog.exportExclude;

  /// Gate: export and mark the file incomplete.
  String get exportAnyway => _catalog.exportAnyway;

  /// Stamp written into an incomplete export.
  String get exportIncompleteStamp => _catalog.exportIncompleteStamp;

  /// Why an export with no records in its scope was not written.
  String get exportEmptyRecovery => _catalog.exportEmptyRecovery;

  /// Why an export with no file chosen was not written.
  String get exportNoFormat => _catalog.exportNoFormat;

  /// Why a history row cannot be run again from its stored request.
  String get exportReplayMissing => _catalog.exportReplayMissing;

  /// Export screen: what the export writes.
  String get exportOutput => _catalog.exportOutput;

  /// Output choice: chosen reports and data files for readers outside the
  /// app. The project package is [exportFileFormat].
  String get exportOutputFiles => _catalog.exportOutputFiles;

  /// Export screen: which files the reports-and-data output writes.
  String get exportFormats => _catalog.exportFormats;

  /// File choice: the workbook.
  String get exportFormatXlsx => _catalog.exportFormatXlsx;

  /// File choice: one CSV file per template.
  String get exportFormatCsv => _catalog.exportFormatCsv;

  /// File choice: full-fidelity JSON.
  String get exportFormatJson => _catalog.exportFormatJson;

  /// File choice: the PDF reports.
  String get exportFormatPdf => _catalog.exportFormatPdf;

  /// The name of an export scope, by its stored kind.
  String exportScopeName(String kind) => switch (kind) {
    'all' => exportScopeAll,
    'context' => exportScopeContext,
    'dateRange' => exportScopeDates,
    'filter' => exportScopeFilter,
    _ => exportScopeApproved,
  };

  /// Date-range scope: first capture day included.
  String get exportScopeFrom => _catalog.exportScopeFrom;

  /// Date-range scope: last capture day included.
  String get exportScopeTo => _catalog.exportScopeTo;

  /// Advanced extra: the data dictionary.
  String get exportDictionary => _catalog.exportDictionary;

  /// Workbook photo reference: the file name only.
  String get exportPhotoFilename => _catalog.exportPhotoFilename;

  /// Workbook photo reference: the path inside the package.
  String get exportPhotoRelative => _catalog.exportPhotoRelative;

  /// Workbook photo reference: the image itself.
  String get exportPhotoEmbed => _catalog.exportPhotoEmbed;

  /// Advanced extra: how reports lay out photos.
  String get exportPdfPhotos => _catalog.exportPdfPhotos;

  /// Report photo layout: several to a row.
  String get exportPdfThumbnails => _catalog.exportPdfThumbnails;

  /// Report photo layout: one to a row.
  String get exportPdfFull => _catalog.exportPdfFull;

  /// CSV delimiter choice: comma.
  String get exportDelimiterComma => _catalog.exportDelimiterComma;

  /// CSV delimiter choice: semicolon.
  String get exportDelimiterSemicolon => _catalog.exportDelimiterSemicolon;

  /// CSV delimiter choice: tab.
  String get exportDelimiterTab => _catalog.exportDelimiterTab;

  /// Pre-export gate title, naming how many records need a decision.
  String exportGateTitle(int n) => _catalog.exportGateTitle(n);

  /// Pre-export gate message: what is incomplete, unapproved or blocked.
  String exportGateMessage({
    required int incomplete,
    required int unapproved,
    required int blocked,
  }) {
    return <String>[
      if (incomplete > 0) _catalog.exportIncompleteCount(incomplete),
      if (unapproved > 0) _catalog.exportUnapprovedCount(unapproved),
      if (blocked > 0) _catalog.exportBlockedMeetingCount(blocked),
    ].join(', ');
  }

  /// Gate choice detail: fix the records first.
  String get exportFixNowHint => _catalog.exportFixNowHint;

  /// Gate choice detail: export the rest.
  String exportExcludeHint(int n) =>
      _catalog.exportExcludeHint(recordsCount(n).toLowerCase());

  /// Gate choice detail: export everything, stamped incomplete.
  String get exportAnywayHint => _catalog.exportAnywayHint;

  /// History row detail: when, who and how many records.
  String exportHistoryDetail(String when, String operator, int n) {
    return <String>[
      when,
      if (operator.isNotEmpty) operator,
      recordsCount(n),
    ].join(' · ');
  }

  /// Report footer page number.
  String pdfPageOf(int page, int pages) => _catalog.pdfPageOf(page, pages);

  /// Printed where a photo could not be read.
  String get pdfMissingPhoto => _catalog.pdfMissingPhoto;

  /// Report title: one section per record.
  String get pdfRecordReport => _catalog.pdfRecordReport;

  /// Report label of when a record was captured.
  String get pdfCaptured => _catalog.pdfCaptured;

  /// A field label marked as the raw value.
  String pdfRaw(String label) => _catalog.pdfRaw(label);

  /// A field label marked as the refined value.
  String pdfRefined(String label) => _catalog.pdfRefined(label);

  /// Report title: a checklist in its predefined order.
  String get pdfInspectionReport => _catalog.pdfInspectionReport;

  /// A checklist row never captured.
  String get pdfNotFound => _catalog.pdfNotFound;

  /// How many predefined rows a checklist has.
  String pdfChecklistRows(int n) => _catalog.pdfChecklistRows(n);

  /// How many checklist rows were not found.
  String pdfNotFoundCount(int n) => _catalog.pdfNotFoundCount(n);

  /// How many checklist rows comply.
  String pdfCompliance(int compliant, int total) =>
      _catalog.pdfCompliance(compliant, total);

  /// Report title: the project's counts.
  String get pdfSummaryReport => _catalog.pdfSummaryReport;

  /// Summary heading: counts by context.
  String get pdfByContext => _catalog.pdfByContext;

  /// Summary heading: counts by template.
  String get pdfByTemplate => _catalog.pdfByTemplate;

  /// Summary heading: counts by condition.
  String get pdfByCondition => _catalog.pdfByCondition;

  /// Summary heading: counts by status.
  String get pdfByStatus => _catalog.pdfByStatus;

  /// Summary group of records captured with no context.
  String get pdfNoContext => _catalog.pdfNoContext;

  /// Summary group of records with no condition recorded.
  String get pdfNoCondition => _catalog.pdfNoCondition;

  /// Summary status group: not processed yet.
  String get pdfUnprocessed => _catalog.pdfUnprocessed;

  /// Summary status group: waiting for review.
  String get pdfNeedsReview => _catalog.pdfNeedsReview;

  /// Summary status group: approved.
  String get pdfApproved => _catalog.pdfApproved;

  /// Report title: as-recorded against as-found.
  String get pdfVarianceReport => _catalog.pdfVarianceReport;

  /// Variance section: register items found.
  String get pdfMatched => _catalog.pdfMatched;

  /// Variance section: found items the register does not list.
  String get pdfNotInRegister => _catalog.pdfNotInRegister;

  /// Report title: meeting minutes.
  String get pdfMinutesReport => _catalog.pdfMinutesReport;

  /// Label of an action's due date.
  String get pdfDue => _catalog.pdfDue;

  /// An action's status as the register prints it.
  String pdfActionStatus(String stored) => switch (stored) {
    'inProgress' => _catalog.pdfActionStatus,
    'done' => _catalog.pdfActionStatusDone,
    _ => _catalog.pdfActionStatusOpen,
  };

  /// A matched register item whose field was found different.
  String pdfVarianceChanged(String field, String recorded, String found) =>
      _catalog.pdfVarianceChanged(field, recorded, found);

  /// A matched register item whose field was found empty.
  String pdfVarianceEmpty(String field, String recorded) =>
      _catalog.pdfVarianceEmpty(field, recorded);

  /// Heading of the minutes' photo appendix.
  String get pdfPhotoAppendix => _catalog.pdfPhotoAppendix;

  /// Points from the discussion to the photo appendix.
  String pdfPhotoReference(int n) => _catalog.pdfPhotoReference(n);

  /// Cover fact: when the export was made.
  String pdfExportedAt(String when) => _catalog.pdfExportedAt(when);

  /// Cover fact: who made the export.
  String pdfExportedBy(String operator) => _catalog.pdfExportedBy(operator);

  /// Cover fact: which records the export selected.
  String pdfScope(String scope) => _catalog.pdfScope(scope);

  /// Types a replacement for a conflict.
  String get conflictTypeValue => _catalog.conflictTypeValue;

  /// Leaves a conflict unsettled.
  String get conflictDecideLater => _catalog.conflictDecideLater;

  /// Caption replacement label in the conflict editor.
  String get conflictCaptionLabel => _catalog.conflictCaptionLabel;

  /// Replacement value chosen by the operator.
  String get mergeConflictTyped => _catalog.mergeConflictTyped;

  /// Bundle scope section title.
  /// Password input for an encrypted project package.
  String get bundlePassword => _catalog.bundlePassword;

  /// Empty protected bundle password.
  String get bundlePasswordRequired => _catalog.bundlePasswordRequired;

  /// Optional password protection for the current package only.
  String get bundlePasswordOptional => _catalog.bundlePasswordOptional;

  /// Indicates protection without displaying the password.
  String get bundlePasswordSet => _catalog.bundlePasswordSet;

  /// Bundle inclusion scope section.
  String get bundleScope => _catalog.bundleScope;

  /// The whole project.
  String get bundleScopeFull => _catalog.bundleScopeFull;

  /// A date range of records.
  String get bundleScopeDates => _catalog.bundleScopeDates;

  /// The current context subtree.
  String get bundleScopeContext => _catalog.bundleScopeContext;

  /// Approved records only.
  String get bundleScopeApproved => _catalog.bundleScopeApproved;

  /// Records without their photos.
  String get bundleScopeData => _catalog.bundleScopeData;

  /// Estimated bundle size.
  String bundleSize(String label) => _catalog.bundleSize(label);

  /// Shares the bundle file.
  String get bundleShare => _catalog.bundleShare;

  /// Opens a bundle that arrived from outside the app.
  String get bundleOpen => _catalog.bundleOpen;

  /// Merge history title.
  String get mergeHistoryTitle => _catalog.mergeHistoryTitle;

  /// Empty merge history.
  String get mergeHistoryEmpty => _catalog.mergeHistoryEmpty;

  /// Empty merge history explanation.
  String get mergeHistoryEmptyMessage => _catalog.mergeHistoryEmptyMessage;

  /// Undo is still available.
  String mergeUndoUntil(String when) => _catalog.mergeUndoUntil(when);

  /// Locale-aware undo deadline and merge provenance.
  String mergeUndoDeadline(DateTime until) => _withLocale(
    () => mergeUndoUntil(DateFormat.yMMMd().add_jm().format(until.toLocal())),
  );

  /// Package identity, import time and outcome in the history list.
  String mergeHistoryFacts(
    String name,
    String id,
    DateTime at,
    String status,
  ) => _withLocale(
    () => _catalog.mergeHistoryFacts(
      name,
      id,
      DateFormat.yMMMd().add_jm().format(at.toLocal()),
      _catalog.mergeHistoryStatus(status),
    ),
  );

  /// Count of one durable merge category.
  String mergeHistoryCount(String key, int n) =>
      _catalog.mergeHistoryCount(_catalog.mergeHistoryCategory(key), n);

  /// Count of one operator resolution.
  String mergeHistoryResolution(String choice, int n) =>
      _catalog.mergeHistoryResolution(_catalog.mergeHistoryChoice(choice), n);

  /// Undo refuses to discard edits made after a merge.
  String get mergeUndoChanged => _catalog.mergeUndoChanged;

  /// Recovery offered when newer work prevents restoring an old snapshot.
  String get mergeUndoChangedRecovery => _catalog.mergeUndoChangedRecovery;

  /// Missing, expired or previously undone snapshot.
  String get mergeUndoUnavailable => _catalog.mergeUndoUnavailable;

  /// Confirmation after the durable restore commits.
  String get mergeUndoDone => _catalog.mergeUndoDone;

  /// Explains exactly what undo restores and retains.
  String get mergeUndoConfirm => _catalog.mergeUndoConfirm;

  /// Import page title.
  String get importTitle => _catalog.importTitle;

  /// Empty import headline.
  String get importEmptyHeadline => _catalog.importEmptyHeadline;

  /// Empty import explanation.
  String get importEmptyMessage => _catalog.importEmptyMessage;

  /// The import page's one action: pick a file.
  String get importChooseFile => _catalog.importChooseFile;

  /// Shown while a chosen file is checked or read.
  String get importCheckingFile => _catalog.importCheckingFile;

  /// Heading over the four kinds of file the import page takes.
  String get importKindsTitle => _catalog.importKindsTitle;

  /// A bundle, on the import page.
  String get importKindBundle => _catalog.importKindBundle;

  /// Where a bundle goes.
  String get importBundleLine => _catalog.importBundleLine;

  /// A reference dataset, on the import page.
  String get importKindDataset => _catalog.importKindDataset;

  /// Where a dataset goes.
  String get importDatasetLine => _catalog.importDatasetLine;

  /// A template, on the import page.
  String get importKindTemplate => _catalog.importKindTemplate;

  /// Where a template goes.
  String get importTemplateLine => _catalog.importTemplateLine;

  /// A spreadsheet, on the import page.
  String get importKindSheet => _catalog.importKindSheet;

  /// Where a row spreadsheet goes.
  String get importSheetLine => _catalog.importSheetLine;

  /// A file the import page does not take.
  String get importUnsupported => _catalog.importUnsupported;

  /// Every kind except a bundle is added to the open project.
  String get importNeedsProject => _catalog.importNeedsProject;

  /// Recovery for [importNeedsProject].
  String get importNeedsProjectRecovery => _catalog.importNeedsProjectRecovery;

  /// Purpose page title.
  String get importPurposeTitle => _catalog.importPurposeTitle;

  /// Rows become records.
  String get importPurposeRecords => _catalog.importPurposeRecords;

  /// What choosing [importPurposeRecords] does.
  String get importPurposeRecordsLine => _catalog.importPurposeRecordsLine;

  /// Rows feed verification.
  String get importPurposeRegister => _catalog.importPurposeRegister;

  /// What choosing [importPurposeRegister] does.
  String get importPurposeRegisterLine => _catalog.importPurposeRegisterLine;

  /// Mapping and summary pages with no sheet chosen.
  String get importNoSheetHeadline => _catalog.importNoSheetHeadline;

  /// Explains [importNoSheetHeadline].
  String get importNoSheetMessage => _catalog.importNoSheetMessage;

  /// Mapping page title.
  String get importMappingTitle => _catalog.importMappingTitle;

  /// Label of the template the rows are matched onto.
  String get importMappingTemplate => _catalog.importMappingTemplate;

  /// Heading over the column-to-field choices.
  String get importMappingColumns => _catalog.importMappingColumns;

  /// A header with no field yet.
  String get importUnmapped => _catalog.importUnmapped;

  /// A project with no template to match the sheet onto.
  String get importNoTemplateHeadline => _catalog.importNoTemplateHeadline;

  /// Explains [importNoTemplateHeadline].
  String get importNoTemplateMessage => _catalog.importNoTemplateMessage;

  /// Opens template mapping for the chosen sheet.
  String get importMakeTemplate => _catalog.importMakeTemplate;

  /// Heading over the first rows, as they will be read.
  String get importPreviewTitle => _catalog.importPreviewTitle;

  /// One spreadsheet row, by its number in the file.
  String importRow(int row) => _catalog.importRow(row);

  /// The mapping page's one action.
  String importRun(int rows) {
    return _catalog.importRun(rows);
  }

  /// Names the identity field that is still unmapped.
  String importIdentityMissing(String field) =>
      _catalog.importIdentityMissing(field);

  /// Shown while the rows are written.
  String get importWriting => _catalog.importWriting;

  /// How far the import has got.
  String importProgress(int done, int total) =>
      _catalog.importProgress(done, total);

  /// Why a row that matches a record was left alone.
  String get importKeptExisting => _catalog.importKeptExisting;

  /// Why a matching row was skipped with no choice made.
  String get importMatchUnsettled => _catalog.importMatchUnsettled;

  /// Why a row that repeats an earlier row's identity was not written.
  String importRepeatsRow(int row) => _catalog.importRepeatsRow(row);

  /// Every row was written.
  String get importAllDone => _catalog.importAllDone;

  /// Opens the project's records after an import.
  String get importOpenRecords => _catalog.importOpenRecords;

  /// File name of the rows to correct and import again.
  String get importFixFileName => _catalog.importFixFileName;

  /// Column of the rows-to-fix file naming each row's number in the sheet.
  String get importFixRowColumn => _catalog.importFixRowColumn;

  /// Column of the rows-to-fix file saying why each row was not written.
  String get importFixReasonColumn => _catalog.importFixReasonColumn;

  /// Announced once the rows to fix are saved.
  String get importFixSaved => _catalog.importFixSaved;

  /// Summary page title.
  String get importSummaryTitle => _catalog.importSummaryTitle;

  /// How many rows were created.
  String importCreated(int count) => _catalog.importCreated(count);

  /// How many rows updated a record.
  String importUpdated(int count) => _catalog.importUpdated(count);

  /// How many rows were skipped.
  String importSkipped(int count) => _catalog.importSkipped(count);

  /// How many rows failed.
  String importFailed(int count) => _catalog.importFailed(count);

  /// Re-runs only the failed rows.
  String get importRetry => _catalog.importRetry;

  /// Writes the skipped and failed rows.
  String get importExportProblems => _catalog.importExportProblems;

  /// Match sheet title.
  String get importMatchTitle => _catalog.importMatchTitle;

  /// Says which row matched.
  String importMatchMessage(int row) => _catalog.importMatchMessage(row);

  /// Label of the choice on the match sheet.
  String get importMatchChoice => _catalog.importMatchChoice;

  /// Leave the existing record unchanged.
  String get importKeepExisting => _catalog.importKeepExisting;

  /// Replace the existing record with the row.
  String get importReplace => _catalog.importReplace;

  /// Fill only empty fields from the row.
  String get importMerge => _catalog.importMerge;

  /// Applies the choice to every later match.
  String get importApplyToAll => _catalog.importApplyToAll;

  /// Confirms the match sheet.
  String get importMatchConfirm => _catalog.importMatchConfirm;

  /// Settings row for cloud destinations.
  String get cloudDestinationsTitle => _catalog.cloudDestinationsTitle;

  /// Settings row explanation.
  String get cloudDestinationsSubtitle => _catalog.cloudDestinationsSubtitle;

  /// Destinations page title.
  String get destinationTitle => _catalog.destinationTitle;

  /// Empty destinations headline.
  String get destinationEmptyHeadline => _catalog.destinationEmptyHeadline;

  /// Empty destinations explanation.
  String get destinationEmptyMessage => _catalog.destinationEmptyMessage;

  /// Starts adding a destination.
  String get destinationAdd => _catalog.destinationAdd;

  /// Saves a destination after its test succeeds.
  String get destinationSave => _catalog.destinationSave;

  /// Runs the probe upload.
  String get destinationTest => _catalog.destinationTest;

  /// Removes a destination.
  String get destinationRemove => _catalog.destinationRemove;

  /// Removal confirm title.
  String get destinationRemoveTitle => _catalog.destinationRemoveTitle;

  /// Removal confirm explanation.
  String get destinationRemoveMessage => _catalog.destinationRemoveMessage;

  /// Shown when the probe upload fails, so save stays disabled.
  String get destinationCheckFailed => _catalog.destinationCheckFailed;

  /// Label field.
  String get destinationLabel => _catalog.destinationLabel;

  /// Folder field.
  String get destinationFolder => _catalog.destinationFolder;

  /// Obscured credential field.
  String get destinationSecret => _catalog.destinationSecret;

  /// S3 kind label.
  String get destinationKindS3 => _catalog.destinationKindS3;

  /// Google Drive kind label.
  String get destinationKindDrive => _catalog.destinationKindDrive;

  /// OneDrive kind label.
  String get destinationKindOneDrive => _catalog.destinationKindOneDrive;

  /// Dropbox kind label.
  String get destinationKindDropbox => _catalog.destinationKindDropbox;

  /// WebDAV kind label.
  String get destinationKindWebDav => _catalog.destinationKindWebDav;

  /// Device folder kind label.
  String get destinationKindLocal => _catalog.destinationKindLocal;

  /// Title of the sheet that changes a saved destination.
  String get destinationEdit => _catalog.destinationEdit;

  /// Row action that opens the destination for editing.
  String get destinationEditAction => _catalog.destinationEditAction;

  /// Label of the destination type choice.
  String get destinationKind => _catalog.destinationKind;

  /// Submit on the destination form: the probe runs, then the save.
  String get destinationCheckAndSave => _catalog.destinationCheckAndSave;

  /// Folder field for an S3 destination: the key prefix.
  String get destinationBucketFolder => _catalog.destinationBucketFolder;

  /// Hint on a field that may stay empty.
  String get destinationOptional => _catalog.destinationOptional;

  /// Hint on the device folder field.
  String get destinationLocalFolderHint => _catalog.destinationLocalFolderHint;

  /// Opens the platform folder picker for a device or card folder.
  String get destinationChooseFolder => _catalog.destinationChooseFolder;

  /// S3 access key field.
  String get destinationAccessKey => _catalog.destinationAccessKey;

  /// S3 secret key field. Obscured.
  String get destinationSecretKey => _catalog.destinationSecretKey;

  /// S3 region field.
  String get destinationRegion => _catalog.destinationRegion;

  /// S3 bucket field.
  String get destinationBucket => _catalog.destinationBucket;

  /// S3-compatible endpoint field.
  String get destinationEndpoint => _catalog.destinationEndpoint;

  /// Hint on the endpoint field.
  String get destinationEndpointHint => _catalog.destinationEndpointHint;

  /// WebDAV server address field.
  String get destinationAddress => _catalog.destinationAddress;

  /// Hint on the WebDAV address field.
  String get destinationAddressHint => _catalog.destinationAddressHint;

  /// Label of the WebDAV sign-in method choice.
  String get destinationSignInMethod => _catalog.destinationSignInMethod;

  /// Basic authentication.
  String get destinationSignInPassword => _catalog.destinationSignInPassword;

  /// Bearer authentication.
  String get destinationSignInToken => _catalog.destinationSignInToken;

  /// WebDAV user name field.
  String get destinationUsername => _catalog.destinationUsername;

  /// WebDAV password field. Obscured.
  String get destinationPassword => _catalog.destinationPassword;

  /// WebDAV token field. Obscured.
  String get destinationToken => _catalog.destinationToken;

  /// Explains that an edit keeps the stored sign-in unless replaced.
  String get destinationKeepSignIn => _catalog.destinationKeepSignIn;

  /// Asks for a new provider sign-in when a saved one was revoked.
  String get destinationSignInAgain => _catalog.destinationSignInAgain;

  /// Says a provider destination signs in when it is saved.
  String destinationSignInNote(String provider) =>
      _catalog.destinationSignInNote(provider);

  /// No browser sign-in is available for this provider.
  String get destinationSignInUnavailable =>
      _catalog.destinationSignInUnavailable;

  /// The sign-in that came back was not the one this form started.
  String get destinationSignInMismatch => _catalog.destinationSignInMismatch;

  /// Shown instead of an empty remote folder.
  String get destinationFolderRoot => _catalog.destinationFolderRoot;

  /// The first half of a removal failed: nothing was removed.
  String get destinationRemoveNothing => _catalog.destinationRemoveNothing;

  /// The second half of a removal failed.
  String get destinationRemoveHalf => _catalog.destinationRemoveHalf;

  /// Recovery for a failed removal.
  String get destinationRemoveAgain => _catalog.destinationRemoveAgain;

  /// An undone removal could not list the destination again.
  String get destinationRestoreFailed => _catalog.destinationRestoreFailed;

  /// Recovery for a failed restore.
  String get destinationAddAgain => _catalog.destinationAddAgain;

  /// A cancelled removal.
  String get destinationKept => _catalog.destinationKept;

  /// Recovery for a cancelled removal.
  String get destinationKeptRecovery => _catalog.destinationKeptRecovery;

  /// Snack after a removal, offered with undo.
  String destinationRemoved(String label) => _catalog.destinationRemoved(label);

  /// Snack after an undone removal.
  String destinationRestored(String label) =>
      _catalog.destinationRestored(label);

  /// Snack after a save.
  String destinationSaved(String label) => _catalog.destinationSaved(label);

  /// Snack after a passed connection check.
  String destinationCheckPassed(String label) =>
      _catalog.destinationCheckPassed(label);

  /// Row line for the last passed check.
  String destinationCheckedAt(DateTime at) => _withLocale(
    () =>
        _catalog.destinationCheckedAt(DateFormat.yMMMd().format(at.toLocal())),
  );

  /// Row line for the last failed check.
  String destinationCheckFailedAt(String reason) =>
      _catalog.destinationCheckFailedAt(reason);

  /// Row line while a check runs.
  String get destinationChecking => _catalog.destinationChecking;

  /// Headline when this device can hold no destination.
  String get destinationUnavailableHeadline =>
      _catalog.destinationUnavailableHeadline;

  /// Message when this device can hold no destination.
  String get destinationUnavailableMessage =>
      _catalog.destinationUnavailableMessage;

  /// Confirm sheet title.
  String get uploadConfirmTitle => _catalog.uploadConfirmTitle;

  /// Confirm button.
  String get uploadConfirm => _catalog.uploadConfirm;

  /// Names the file, its size, the destination and the folder.
  String uploadConfirmMessage({
    required String name,
    required String size,
    required String destination,
    required String folder,
  }) {
    return _catalog.uploadConfirmMessage(name, size, destination, folder);
  }

  /// History page title.
  String get uploadHistoryTitle => _catalog.uploadHistoryTitle;

  /// Empty history headline.
  String get uploadHistoryEmptyHeadline => _catalog.uploadHistoryEmptyHeadline;

  /// Empty history explanation.
  String get uploadHistoryEmptyMessage => _catalog.uploadHistoryEmptyMessage;

  /// Retries one failed or interrupted upload.
  String get uploadRetry => _catalog.uploadRetry;

  /// History filter label.
  String get uploadFilter => _catalog.uploadFilter;

  /// The history filter option that lists every destination.
  String get uploadFilterAll => _catalog.uploadFilterAll;

  /// Empty history action: set up where files can go.
  String get uploadHistoryEmptyAction => _catalog.uploadHistoryEmptyAction;

  /// Sends a finished file to a destination the person picks.
  String get uploadToDestination => _catalog.uploadToDestination;

  /// Title of the sheet that picks the destination.
  String get uploadPickTitle => _catalog.uploadPickTitle;

  /// Snack when a confirmed upload starts.
  String uploadStarted(String destination) =>
      _catalog.uploadStarted(destination);

  /// Opens the upload history from a snack.
  String get uploadView => _catalog.uploadView;

  /// Snack when an upload finished.
  String uploadSent(String name, String destination) =>
      _catalog.uploadSent(name, destination);

  /// Snack when an upload ended without the file arriving.
  String uploadNotSent(String reason) => _catalog.uploadNotSent(reason);

  /// Snack when the person stopped an upload.
  String get uploadStopped => _catalog.uploadStopped;

  /// The file to send is gone or changed size.
  String get uploadFileMissing => _catalog.uploadFileMissing;

  /// Recovery for a missing file.
  String get uploadFileMissingRecovery => _catalog.uploadFileMissingRecovery;

  /// The destination of a retried upload was removed.
  String get uploadDestinationGone => _catalog.uploadDestinationGone;

  /// Recovery for a removed destination.
  String get uploadDestinationGoneRecovery =>
      _catalog.uploadDestinationGoneRecovery;

  /// Outcome: the file arrived.
  String get uploadOutcomeSent => _catalog.uploadOutcomeSent;

  /// Outcome: the upload failed.
  String get uploadOutcomeFailed => _catalog.uploadOutcomeFailed;

  /// Outcome: the upload never finished, for example the app closed.
  String get uploadOutcomeInterrupted => _catalog.uploadOutcomeInterrupted;

  /// Outcome: the person stopped it.
  String get uploadOutcomeStopped => _catalog.uploadOutcomeStopped;

  /// One history row: outcome, destination, size and start time.
  String uploadAttemptLine({
    required String outcome,
    required String destination,
    required String size,
    required DateTime startedAt,
  }) {
    return _withLocale(() {
      final String when = DateFormat.yMMMd().add_jm().format(
        startedAt.toLocal(),
      );
      return _catalog.uploadAttemptLine(outcome, destination, size, when);
    });
  }

  /// A row while its upload runs.
  String uploadSendingLine({
    required String destination,
    required int percent,
  }) => _catalog.uploadSendingLine(destination, percent);

  /// Row action that stops a running upload.
  String get uploadStop => _catalog.uploadStop;

  /// Row action that shows every field of an attempt.
  String get uploadDetails => _catalog.uploadDetails;

  /// Every field of one attempt, for the details dialog.
  String uploadDetailsMessage({
    required String file,
    required String destination,
    required String folder,
    required String size,
    required DateTime startedAt,
    required DateTime? endedAt,
    required String outcome,
    required String? reason,
  }) {
    return _withLocale(() {
      String when(DateTime at) =>
          DateFormat.yMMMd().add_jms().format(at.toLocal());
      final String ended = endedAt == null ? '—' : when(endedAt);
      final String because = reason == null
          ? ''
          : _catalog.uploadDetailsMessage(reason);
      return _catalog.uploadDetailsMessageFileDestinationFolderSize(
        file,
        destination,
        folder,
        size,
        when(startedAt),
        ended,
        outcome,
        because,
      );
    });
  }

  /// Privacy screen title.
  String get privacyScreenTitle => _catalog.privacyScreenTitle;

  /// Empty privacy headline.
  String get privacyEmptyHeadline => _catalog.privacyEmptyHeadline;

  /// Empty privacy explanation.
  String get privacyEmptyMessage => _catalog.privacyEmptyMessage;

  /// Section of the privacy page listing analysis calls.
  String get egressAnalysisSection => _catalog.egressAnalysisSection;

  /// Section of the privacy page listing uploads and the relay.
  String get egressUploadsSection => _catalog.egressUploadsSection;

  /// Notice while offline mode stops every outbound call.
  String get egressOfflineNotice => _catalog.egressOfflineNotice;

  /// Analysis row: reading text from photos.
  String get egressReadText => _catalog.egressReadText;

  /// Analysis row: filling a record's fields.
  String get egressExtractFields => _catalog.egressExtractFields;

  /// Analysis row: tidying captions.
  String get egressRefineText => _catalog.egressRefineText;

  /// Analysis row: speech to text.
  String get egressTranscribe => _catalog.egressTranscribe;

  /// What one outbound path sends, and where it goes.
  String egressRow(String sends, String destination) =>
      _catalog.egressRow(sends, destination);

  /// What an extraction call sends.
  String get egressSendsText => _catalog.egressSendsText;

  /// What an image call sends.
  String get egressSendsImage => _catalog.egressSendsImage;

  /// What speech sends.
  String get egressSendsAudio => _catalog.egressSendsAudio;

  /// What a cloud upload sends.
  String get egressSendsFile => _catalog.egressSendsFile;

  /// What the relay sends.
  String get egressSendsPackage => _catalog.egressSendsPackage;

  /// Relay row title.
  String get egressRelay => _catalog.egressRelay;

  /// Where the relay sends.
  String get egressRelayServer => _catalog.egressRelayServer;

  /// Basis written when images stay on the device.
  String get egressTextOnly => _catalog.egressTextOnly;

  /// Location section title.
  String get gpsPrivacyTitle => _catalog.gpsPrivacyTitle;

  /// GPS stays off until this is on.
  String get gpsPrivacyCapture => _catalog.gpsPrivacyCapture;

  /// Where location capture is switched, and its state.
  String gpsPrivacyCaptureState(bool on) => on
      ? _catalog.gpsPrivacyCaptureState
      : _catalog.gpsPrivacyCaptureStateOffChangeItIn;

  /// Drops coordinates from exports.
  String get gpsPrivacyExclude => _catalog.gpsPrivacyExclude;

  /// What leaving coordinates out covers.
  String get gpsPrivacyExcludeEffect => _catalog.gpsPrivacyExcludeEffect;

  /// Removes coordinates already stored.
  String get gpsPrivacyRemove => _catalog.gpsPrivacyRemove;

  /// Confirms removing the open project's coordinates.
  String get gpsPrivacyRemoveTitle => _catalog.gpsPrivacyRemoveTitle;

  /// What removing coordinates does.
  String gpsPrivacyRemoveMessage(String project) =>
      _catalog.gpsPrivacyRemoveMessage(project);

  /// Confirm button for removing coordinates.
  String get gpsPrivacyRemoveConfirm => _catalog.gpsPrivacyRemoveConfirm;

  /// How many records lost their coordinates.
  String gpsPrivacyRemoved(int count) =>
      _catalog.gpsPrivacyRemoved(recordsCount(count));

  /// Why the removal is not offered.
  String get gpsPrivacyNoProject => _catalog.gpsPrivacyNoProject;

  /// Blurs faces in exported photos.
  String get faceBlurTitle => _catalog.faceBlurTitle;

  /// What face blurring does, and what happens when it cannot.
  String get faceBlurEffect => _catalog.faceBlurEffect;

  /// Redaction editor title and its entry point.
  String get redactionTitle => _catalog.redactionTitle;

  /// Records held back because no confirmed consent was captured.
  String exportConsentOmitted(List<String> ids) =>
      _catalog.exportConsentOmitted(ids.join(', '));

  /// Face discovery remains visible for each protected photo.
  String exportFaceCounts(Map<String, int> counts) => counts.entries
      .map(
        (MapEntry<String, int> entry) =>
            _catalog.exportFaceCount(entry.key, entry.value),
      )
      .join('\n');

  /// A saved artifact must be regenerated under the current protections.
  String get exportPrivacyChanged => _catalog.exportPrivacyChanged;

  /// How to mark a region.
  String get redactionHint => _catalog.redactionHint;

  /// Saves the marked regions.
  String get redactionSave => _catalog.redactionSave;

  /// How many regions are hidden.
  String redactionCount(int count) => _catalog.redactionCount(count);

  /// After saving the marks.
  String get redactionSaved => _catalog.redactionSaved;

  /// Empty redaction editor headline.
  String get redactionEmptyHeadline => _catalog.redactionEmptyHeadline;

  /// Empty redaction editor explanation.
  String get redactionEmptyMessage => _catalog.redactionEmptyMessage;

  /// Location permission sentence.
  String get permissionLocation => _catalog.permissionLocation;

  /// Storage permission sentence.
  String get permissionStorage => _catalog.permissionStorage;

  /// Notification permission sentence.
  String get permissionNotifications => _catalog.permissionNotifications;

  /// Settings row for privacy.
  String get privacyTitle => _catalog.privacyTitle;

  /// Settings row explanation.
  String get privacySubtitle => _catalog.privacySubtitle;

  /// Settings row for the organisation server.
  String get backendSettingsTitle => _catalog.backendSettingsTitle;

  /// Relay empty state when no project is open.
  String get relayChooseProject => _catalog.relayChooseProject;

  /// Relay switch title.
  String get relayEnable => _catalog.relayEnable;

  /// Relay switch explanation.
  String get relayEnableHelp => _catalog.relayEnableHelp;

  /// Relay shared-key field label.
  String get relaySharedKey => _catalog.relaySharedKey;

  /// Relay shared-key guidance.
  String get relayKeyHelp => _catalog.relayKeyHelp;

  /// Relay action that queues the whole project as one package.
  String get relayQueueProject => _catalog.relayQueueProject;

  /// Relay action that sends queued and fetches incoming packages.
  String get relaySync => _catalog.relaySync;

  /// Relay row that previews a received package before merge.
  String get relayReceivedPackage => _catalog.relayReceivedPackage;

  /// Optional catalogue ranking, always presented as a person's choice.
  String get shippedSuggestWithAi => _catalog.shippedSuggestWithAi;

  /// Badge on a template the AI ranking suggested.
  String get shippedAiSuggestion => _catalog.shippedAiSuggestion;

  /// Explanation under the AI ranking.
  String get shippedAiSuggestionHelp => _catalog.shippedAiSuggestionHelp;

  /// Deployment-specific address is needed only for self-hosted installations.
  String get backendServerAddress => _catalog.backendServerAddress;

  /// Guidance under the server address and organisation fields.
  String get backendConfigurationHelp => _catalog.backendConfigurationHelp;

  /// Session state when this device has no backend session.
  String get backendNotSignedIn => _catalog.backendNotSignedIn;

  /// Session state when this device holds a backend session.
  String get backendSignedIn => _catalog.backendSignedIn;

  /// Label for the cached access grant's expiry.
  String get backendGrantUntil => _catalog.backendGrantUntil;

  /// Settings row: the role the organisation gave this account.
  String get backendRole => _catalog.backendRole;

  /// A server role as the settings row shows it; an unknown one as sent.
  String backendRoleName(String role) => switch (role) {
    'administrator' => _catalog.backendRoleName,
    'project_manager' => _catalog.backendRoleNameProjectManager,
    'reviewer' => _catalog.backendRoleNameReviewer,
    'field_operator' => _catalog.backendRoleNameFieldOperator,
    _ => role,
  };

  /// Settings row: how far this device's enrolment has gone.
  String get backendEnrolment => _catalog.backendEnrolment;

  /// Enrolment value before the first sign-in.
  String get backendNotEnrolled => _catalog.backendNotEnrolled;

  /// Enrolment value while a sign-in is in flight.
  String get backendEnrolling => _catalog.backendEnrolling;

  /// Enrolment value once a grant is cached.
  String get backendEnrolled => _catalog.backendEnrolled;

  /// Enrolment value after the organisation ended the grant.
  String get backendRevokedState => _catalog.backendRevokedState;

  /// Banner when the organisation ended this device's sign-in.
  String get backendRevoked => _catalog.backendRevoked;

  /// Secondary action on the first-run sign-in: work starts without it.
  String get signInLater => _catalog.signInLater;

  /// Action that ends the backend session on this device.
  String get signOutAction => _catalog.signOutAction;

  /// Settings row explanation for the server address and grant.
  String get backendSettingsSubtitle => _catalog.backendSettingsSubtitle;

  /// Sign-in screen title.
  String get signInTitle => _catalog.signInTitle;

  /// Sign-in action.
  String get signInAction => _catalog.signInAction;

  /// Email field.
  String get signInEmail => _catalog.signInEmail;

  /// Password field.
  String get signInPassword => _catalog.signInPassword;

  /// Organisation field on the sign-in screen.
  String get signInOrganisation => _catalog.signInOrganisation;

  /// Quiet line when the server cannot be reached.
  String get backendUnreachable => _catalog.backendUnreachable;

  /// Shown when a grant has expired for relay or analysis.
  String get backendGrantExpired => _catalog.backendGrantExpired;

  /// Sign-out confirmation title.
  String get signOutTitle => _catalog.signOutTitle;

  /// Sign-out warning.
  String get signOutMessage => _catalog.signOutMessage;

  /// Relay control title.
  String get relayTitle => _catalog.relayTitle;

  /// Relay is waiting for a project manager.
  String get relayOff => _catalog.relayOff;

  /// Relay needs a sign-in this device does not hold.
  String get relaySignInNeeded => _catalog.relaySignInNeeded;

  /// Action that opens the shared-key form.
  String get relayAddKey => _catalog.relayAddKey;

  /// A never-relay project has no send action.
  String get relayNever => _catalog.relayNever;

  /// Send action for an enabled relay.
  String get relaySend => _catalog.relaySend;

  /// Count of packages waiting to send.
  String get relayQueued => _catalog.relayQueued;

  /// Count of packages the server accepted.
  String get relaySent => _catalog.relaySent;

  /// Count of packages the server has purged.
  String get relayPurged => _catalog.relayPurged;

  /// Trial control that records a problem on this screen.
  String get frictionLogAction => _catalog.frictionLogAction;

  /// Optional context the tester adds to a trial report.
  String get frictionNote => _catalog.frictionNote;

  /// Explicit consent to attach the current app screen to a local report.
  String get frictionScreenshot => _catalog.frictionScreenshot;

  /// Commits the report before dismissing the sheet.
  String get frictionSave => _catalog.frictionSave;

  /// Confirms that the trial report is stored on this device.
  String get frictionSaved => _catalog.frictionSaved;

  /// Opens the existing workbook and screenshot archive export from settings.
  String get frictionExport => _catalog.frictionExport;

  /// A second save cannot begin while the first is writing.
  String get frictionSaving => _catalog.frictionSaving;

  /// Named screenshot failure, with a path that keeps the optional note.
  String get frictionScreenshotFailed => _catalog.frictionScreenshotFailed;

  /// The tester may save the report without an image.
  String get frictionScreenshotRecovery => _catalog.frictionScreenshotRecovery;

  /// Refuses to overwrite a journal that could not be read.
  String get feedbackJournalInvalid => _catalog.feedbackJournalInvalid;

  /// A retry keeps the existing local journal in place.
  String get feedbackJournalRecovery => _catalog.feedbackJournalRecovery;

  /// Prevents a report archive from quietly omitting a saved attachment.
  String get feedbackImageMissing => _catalog.feedbackImageMissing;

  /// Names the recovery without deleting the journal entry.
  String get feedbackImageRecovery => _catalog.feedbackImageRecovery;

  /// Component-gallery sample Name.
  String get gallerySampleName => _catalog.gallerySampleName;

  /// Component-gallery sample Caption.
  String get gallerySampleCaption => _catalog.gallerySampleCaption;

  /// Component-gallery sample Count.
  String get gallerySampleCount => _catalog.gallerySampleCount;

  /// Component-gallery sample Email.
  String get gallerySampleEmail => _catalog.gallerySampleEmail;

  /// Component-gallery sample Phone.
  String get gallerySamplePhone => _catalog.gallerySamplePhone;

  /// Component-gallery sample When.
  String get gallerySampleWhen => _catalog.gallerySampleWhen;

  /// Component-gallery sample Grade.
  String get gallerySampleGrade => _catalog.gallerySampleGrade;

  /// Component-gallery sample Fuel.
  String get gallerySampleFuel => _catalog.gallerySampleFuel;

  /// Component-gallery sample Tags.
  String get gallerySampleTags => _catalog.gallerySampleTags;

  /// Component-gallery sample GPS.
  String get gallerySampleLocation => _catalog.gallerySampleLocation;

  /// Component-gallery sample Stamp each capture.
  String get gallerySampleStampCapture => _catalog.gallerySampleStampCapture;

  /// Component-gallery sample Boiler A.
  String get gallerySampleBoilerA => _catalog.gallerySampleBoilerA;

  /// Component-gallery sample Boiler B.
  String get gallerySampleBoilerB => _catalog.gallerySampleBoilerB;

  /// Component-gallery sample Open beside this list.
  String get gallerySampleBesideList => _catalog.gallerySampleBesideList;

  /// Component-gallery sample Water.
  String get gallerySampleWater => _catalog.gallerySampleWater;

  /// Component-gallery sample Steam.
  String get gallerySampleSteam => _catalog.gallerySampleSteam;

  /// Component-gallery sample Gas.
  String get gallerySampleGas => _catalog.gallerySampleGas;

  /// Component-gallery sample Chip.
  String get gallerySampleChip => _catalog.gallerySampleChip;

  /// Component-gallery sample Filter.
  String get gallerySampleFilter => _catalog.gallerySampleFilter;

  /// Component-gallery sample List tile.
  String get gallerySampleListTile => _catalog.gallerySampleListTile;

  /// Component-gallery sample Secondary line.
  String get gallerySampleSecondaryLine => _catalog.gallerySampleSecondaryLine;

  /// Theme surface depth sample.
  String surfacePreviewLevel(int level) => _catalog.surfacePreviewLevel(level);

  /// Typography sample.
  String typeRampSample(String name) => _catalog.typeRampSample(name);

  /// Explains why a package exceeds the bounded encrypted relay transport.
  String relayPackageTooLarge(int bytes, int ceiling) =>
      _catalog.relayPackageTooLarge(fileSize(bytes), fileSize(ceiling));

  /// Offers direct sharing or a smaller export when the relay limit is hit.
  String get relayPackageTooLargeRecovery =>
      _catalog.relayPackageTooLargeRecovery;

  /// Native biometric authentication rationale, shown only after opting in.
  String get permissionBiometrics => _catalog.permissionBiometrics;

  /// Reduces metadata before retrying an oversized package import.
  String get packageMetadataTooLargeRecovery =>
      _catalog.packageMetadataTooLargeRecovery;

  /// Default cancelled failure explanation for operator-facing errors.
  String get failureCancelledMessage => _catalog.failureCancelledMessage;

  /// Default cancelled failure recovery for operator-facing errors.
  String get failureCancelledRecovery => _catalog.failureCancelledRecovery;

  /// Default corruption failure explanation for operator-facing errors.
  String get failureCorruptionMessage => _catalog.failureCorruptionMessage;

  /// Default corruption failure recovery for operator-facing errors.
  String get failureCorruptionRecovery => _catalog.failureCorruptionRecovery;

  /// Default network failure explanation for operator-facing errors.
  String get failureNetworkMessage => _catalog.failureNetworkMessage;

  /// Default network failure recovery for operator-facing errors.
  String get failureNetworkRecovery => _catalog.failureNetworkRecovery;

  /// Default permission failure explanation for operator-facing errors.
  String get failurePermissionMessage => _catalog.failurePermissionMessage;

  /// Default permission failure recovery for operator-facing errors.
  String get failurePermissionRecovery => _catalog.failurePermissionRecovery;

  /// Default provider failure explanation for operator-facing errors.
  String get failureProviderMessage => _catalog.failureProviderMessage;

  /// Default provider failure recovery for operator-facing errors.
  String get failureProviderRecovery => _catalog.failureProviderRecovery;

  /// Default storage failure explanation for operator-facing errors.
  String get failureStorageMessage => _catalog.failureStorageMessage;

  /// Default storage failure recovery for operator-facing errors.
  String get failureStorageRecovery => _catalog.failureStorageRecovery;

  /// Default validation failure explanation for operator-facing errors.
  String get failureValidationMessage => _catalog.failureValidationMessage;

  /// Default validation failure recovery for operator-facing errors.
  String get failureValidationRecovery => _catalog.failureValidationRecovery;

  /// Processing retry failure explanation.
  String get processingTimeout => _catalog.processingTimeout;

  /// Processing retry failure explanation.
  String get processingMalformedResponse =>
      _catalog.processingMalformedResponse;

  /// Processing retry failure explanation.
  String get processingStopped => _catalog.processingStopped;

  /// Operator-facing failure retained through headless execution.
  String get failureAIIsNotAvailable => _catalog.failureAIIsNotAvailable;

  /// Operator-facing failure retained through headless execution.
  String get failureContinueCapturingAnalysisCanWait =>
      _catalog.failureContinueCapturingAnalysisCanWait;

  /// Operator-facing failure retained through headless execution.
  String get failureThatPhotoIsNotOnThisDevice =>
      _catalog.failureThatPhotoIsNotOnThisDevice;

  /// Operator-facing failure retained through headless execution.
  String get failureCaptureThePhotoAgainThenTryAgain =>
      _catalog.failureCaptureThePhotoAgainThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThatPhotoCouldNotBeReadOn =>
      _catalog.failureThatPhotoCouldNotBeReadOn;

  /// Operator-facing failure retained through headless execution.
  String get failureUseAnotherPhotoOrEnterTheValue =>
      _catalog.failureUseAnotherPhotoOrEnterTheValue;

  /// Operator-facing failure retained through headless execution.
  String get failureThatPhotoCouldNotBeReadAs =>
      _catalog.failureThatPhotoCouldNotBeReadAs;

  /// Operator-facing failure retained through headless execution.
  String get failureTheAnalysisCopyCouldNotBeRead =>
      _catalog.failureTheAnalysisCopyCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  String get failureKeepTheRecordAndTryAgain =>
      _catalog.failureKeepTheRecordAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheAnalysisResponseCouldNotBeRead =>
      _catalog.failureTheAnalysisResponseCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  String get failureAnalysisCanWait => _catalog.failureAnalysisCanWait;

  /// Operator-facing failure retained through headless execution.
  String get failureTheAnalysisQuotaIsUsedUp =>
      _catalog.failureTheAnalysisQuotaIsUsedUp;

  /// Operator-facing failure retained through headless execution.
  String get failureAnalysisIsPausedOnTheServerFor =>
      _catalog.failureAnalysisIsPausedOnTheServerFor;

  /// Operator-facing failure retained through headless execution.
  String get failureContinueCapturingAnalysisTriesAgainLater =>
      _catalog.failureContinueCapturingAnalysisTriesAgainLater;

  /// Operator-facing failure retained through headless execution.
  String get failureAnalysisAccessIsUnavailableForThisProject =>
      _catalog.failureAnalysisAccessIsUnavailableForThisProject;

  /// Operator-facing failure retained through headless execution.
  String get failureContinueCapturingAndCheckOrganisationAccess =>
      _catalog.failureContinueCapturingAndCheckOrganisationAccess;

  /// Operator-facing failure retained through headless execution.
  String get failureTheAnalysisMediaIsTooLargeTo =>
      _catalog.failureTheAnalysisMediaIsTooLargeTo;

  /// Operator-facing failure retained through headless execution.
  String get failureKeepTheRecordAndCompleteItWithout =>
      _catalog.failureKeepTheRecordAndCompleteItWithout;

  /// Operator-facing failure retained through headless execution.
  String get failureSignInWasNotAccepted =>
      _catalog.failureSignInWasNotAccepted;

  /// Operator-facing failure retained through headless execution.
  String get failureCheckYourEmailPasswordAndOrganisation =>
      _catalog.failureCheckYourEmailPasswordAndOrganisation;

  /// Operator-facing failure retained through headless execution.
  String get failureTheOrganisationEndedThisDeviceSSign =>
      _catalog.failureTheOrganisationEndedThisDeviceSSign;

  /// Operator-facing failure retained through headless execution.
  String get failureSignInAgainWhenTheServerIs =>
      _catalog.failureSignInAgainWhenTheServerIs;

  /// Operator-facing failure retained through headless execution.
  String get failureTheServerCouldNotCompleteSignIn =>
      _catalog.failureTheServerCouldNotCompleteSignIn;

  /// Operator-facing failure retained through headless execution.
  String get failureTryAgainWhenTheServerIsReachable =>
      _catalog.failureTryAgainWhenTheServerIsReachable;

  /// Operator-facing failure retained through headless execution.
  String get failureTheSavedSignInCouldNotBe =>
      _catalog.failureTheSavedSignInCouldNotBe;

  /// Operator-facing failure retained through headless execution.
  String get failureCheckTheAccountSettingsYourLocalWork =>
      _catalog.failureCheckTheAccountSettingsYourLocalWork;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterTheOrganisationSHTTPSServerAddress =>
      _catalog.failureEnterTheOrganisationSHTTPSServerAddress;

  /// Operator-facing failure retained through headless execution.
  String get failureCheckTheAddressWithYourAdministrator =>
      _catalog.failureCheckTheAddressWithYourAdministrator;

  /// Operator-facing failure retained through headless execution.
  String get failureSignOutBeforeChangingOrganisation =>
      _catalog.failureSignOutBeforeChangingOrganisation;

  /// Operator-facing failure retained through headless execution.
  String get failureKeepTheCurrentAccountOrSignOut =>
      _catalog.failureKeepTheCurrentAccountOrSignOut;

  /// Operator-facing failure retained through headless execution.
  String get failureTheOrganisationServerCouldNotBeReached =>
      _catalog.failureTheOrganisationServerCouldNotBeReached;

  /// Operator-facing failure retained through headless execution.
  String get failureContinueWorkingOfflineAndTryAgainLater =>
      _catalog.failureContinueWorkingOfflineAndTryAgainLater;

  /// Operator-facing failure retained through headless execution.
  String get failureUseASharedKeyOfAtLeast =>
      _catalog.failureUseASharedKeyOfAtLeast;

  /// Operator-facing failure retained through headless execution.
  String get failureAskTheProjectManagerForTheSame =>
      _catalog.failureAskTheProjectManagerForTheSame;

  /// Operator-facing failure retained through headless execution.
  String get failureThisProjectIsRegisteredOnTheServer =>
      _catalog.failureThisProjectIsRegisteredOnTheServer;

  /// Operator-facing failure retained through headless execution.
  String get failureAskAnAdministratorToAddYouTo =>
      _catalog.failureAskAnAdministratorToAddYouTo;

  /// Operator-facing failure retained through headless execution.
  String get failureAddTheSharedProjectKeyFirst =>
      _catalog.failureAddTheSharedProjectKeyFirst;

  /// Operator-facing failure retained through headless execution.
  String get failureAskTheProjectManagerForTheKey =>
      _catalog.failureAskTheProjectManagerForTheKey;

  /// Operator-facing failure retained through headless execution.
  String get failureRelayCouldNotCompleteThisRequest =>
      _catalog.failureRelayCouldNotCompleteThisRequest;

  /// Operator-facing failure retained through headless execution.
  String get failureKeepWorkingLocallyAndTrySyncAgain =>
      _catalog.failureKeepWorkingLocallyAndTrySyncAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThatPasswordDidNotOpenTheBundle =>
      _catalog.failureThatPasswordDidNotOpenTheBundle;

  /// Operator-facing failure retained through headless execution.
  String get failureTryThePasswordAgainNothingWasExtracted =>
      _catalog.failureTryThePasswordAgainNothingWasExtracted;

  /// Operator-facing failure retained through headless execution.
  String get failureTheProjectMetadataIsTooLargeFor =>
      _catalog.failureTheProjectMetadataIsTooLargeFor;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseASmallerPackageScope =>
      _catalog.failureChooseASmallerPackageScope;

  /// Operator-facing failure retained through headless execution.
  String get failurePasswordProtectionIsUnavailableOnThisDevice =>
      _catalog.failurePasswordProtectionIsUnavailableOnThisDevice;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenThisPackageOnASupportedDevice =>
      _catalog.failureOpenThisPackageOnASupportedDevice;

  /// Operator-facing failure retained through headless execution.
  String get failurePasswordProtectionNeedsBrowserCryptography =>
      _catalog.failurePasswordProtectionNeedsBrowserCryptography;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenTheAppThroughASecureConnection =>
      _catalog.failureOpenTheAppThroughASecureConnection;

  /// Operator-facing failure retained through headless execution.
  String get failureThisBundleNeedsAPassword =>
      _catalog.failureThisBundleNeedsAPassword;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterItsPasswordToOpenIt =>
      _catalog.failureEnterItsPasswordToOpenIt;

  /// Operator-facing failure retained through headless execution.
  String get failureTheBundleContainsASecretAndWas =>
      _catalog.failureTheBundleContainsASecretAndWas;

  /// Operator-facing failure retained through headless execution.
  String get failureRemoveTheSecretAndExportTheBundle =>
      _catalog.failureRemoveTheSecretAndExportTheBundle;

  /// Operator-facing failure retained through headless execution.
  String get failureTheBundleHasTooManyNestedArchives =>
      _catalog.failureTheBundleHasTooManyNestedArchives;

  /// Operator-facing failure retained through headless execution.
  String get failureANestedBundleArchiveCouldNotBe =>
      _catalog.failureANestedBundleArchiveCouldNotBe;

  /// Operator-facing failure retained through headless execution.
  String get failureAnEncryptedOrUnsupportedAttachmentCouldNot =>
      _catalog.failureAnEncryptedOrUnsupportedAttachmentCouldNot;

  /// Operator-facing failure retained through headless execution.
  String get failureANestedBundleArchiveIsTooLarge =>
      _catalog.failureANestedBundleArchiveIsTooLarge;

  /// Operator-facing failure retained through headless execution.
  String get failureANestedBundleEntryHasAnInvalid =>
      _catalog.failureANestedBundleEntryHasAnInvalid;

  /// Operator-facing failure retained through headless execution.
  String get failureANestedBundleEntryExceedsItsDeclared =>
      _catalog.failureANestedBundleEntryExceedsItsDeclared;

  /// Operator-facing failure retained through headless execution.
  String get failureFinishReadingTheCurrentPackageEntryFirst =>
      _catalog.failureFinishReadingTheCurrentPackageEntryFirst;

  /// Operator-facing failure retained through headless execution.
  String get failureThePackageEntryIsMissing =>
      _catalog.failureThePackageEntryIsMissing;

  /// Operator-facing failure retained through headless execution.
  String get failureReadThisLargePackageEntryAsA =>
      _catalog.failureReadThisLargePackageEntryAsA;

  /// Operator-facing failure retained through headless execution.
  String get failureThePackageEntryChanged =>
      _catalog.failureThePackageEntryChanged;

  /// Operator-facing failure retained through headless execution.
  String get failureThePackageEntryChecksumChanged =>
      _catalog.failureThePackageEntryChecksumChanged;

  /// Operator-facing failure retained through headless execution.
  String failureNoUploadDestinationIsRegisteredForValue(String value0) =>
      _catalog.failureNoUploadDestinationIsRegisteredForValue(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAnotherDestination =>
      _catalog.failureChooseAnotherDestination;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDestinationRefusedTheSignIn =>
      _catalog.failureTheDestinationRefusedTheSignIn;

  /// Operator-facing failure retained through headless execution.
  String get failureCheckTheKeyOrSignInAgain =>
      _catalog.failureCheckTheKeyOrSignInAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThatBucketOrFolderWasNotFound =>
      _catalog.failureThatBucketOrFolderWasNotFound;

  /// Operator-facing failure retained through headless execution.
  String get failureCheckTheNameAndTryTheConnection =>
      _catalog.failureCheckTheNameAndTryTheConnection;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDestinationDidNotFinishTheUpload =>
      _catalog.failureTheDestinationDidNotFinishTheUpload;

  /// Operator-facing failure retained through headless execution.
  String get failureTryAgain => _catalog.failureTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheServerRedirectedTheUploadToAnother =>
      _catalog.failureTheServerRedirectedTheUploadToAnother;

  /// Operator-facing failure retained through headless execution.
  String get failureCheckTheAddressAndTryAgain =>
      _catalog.failureCheckTheAddressAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDestinationRejectedTheUpload =>
      _catalog.failureTheDestinationRejectedTheUpload;

  /// Operator-facing failure retained through headless execution.
  String get failureCheckTheSettingsAndTryAgain =>
      _catalog.failureCheckTheSettingsAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheFileCouldNotBeReadWhile =>
      _catalog.failureTheFileCouldNotBeReadWhile;

  /// Operator-facing failure retained through headless execution.
  String get failureCheckThatTheFileIsStillOn =>
      _catalog.failureCheckThatTheFileIsStillOn;

  /// Operator-facing failure retained through headless execution.
  String get failureUploadsArePausedWhileTheAppIs =>
      _catalog.failureUploadsArePausedWhileTheAppIs;

  /// Operator-facing failure retained through headless execution.
  String get failureGoOnlineThenConfirmTheUploadAgain =>
      _catalog.failureGoOnlineThenConfirmTheUploadAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureUploadsToThisDestinationAreTurnedOff =>
      _catalog.failureUploadsToThisDestinationAreTurnedOff;

  /// Operator-facing failure retained through headless execution.
  String get failureEnableTheDestinationOnThePrivacyPage =>
      _catalog.failureEnableTheDestinationOnThePrivacyPage;

  /// Operator-facing failure retained through headless execution.
  String get failureCloudSignInCouldNotFinish =>
      _catalog.failureCloudSignInCouldNotFinish;

  /// Operator-facing failure retained through headless execution.
  String get failureTrySigningInAgain => _catalog.failureTrySigningInAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDestinationReturnedTooMuchData =>
      _catalog.failureTheDestinationReturnedTooMuchData;

  /// Operator-facing failure retained through headless execution.
  String get failureCheckTheDestinationAddressAndTryAgain =>
      _catalog.failureCheckTheDestinationAddressAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDestinationCouldNotBeReached =>
      _catalog.failureTheDestinationCouldNotBeReached;

  /// Operator-facing failure retained through headless execution.
  String get failureTryAgainWhenYouAreOnline =>
      _catalog.failureTryAgainWhenYouAreOnline;

  /// Operator-facing failure retained through headless execution.
  String get failureRemoveTheDestinationAndAddItAgain =>
      _catalog.failureRemoveTheDestinationAndAddItAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThisDestinationSignInChangedDuringThe =>
      _catalog.failureThisDestinationSignInChangedDuringThe;

  /// Operator-facing failure retained through headless execution.
  String get failureReviewTheDestinationAndConfirmANew =>
      _catalog.failureReviewTheDestinationAndConfirmANew;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDestinationDidNotAcceptTheTest =>
      _catalog.failureTheDestinationDidNotAcceptTheTest;

  /// Operator-facing failure retained through headless execution.
  String get failureSignInAgainAndRetryTheTest =>
      _catalog.failureSignInAgainAndRetryTheTest;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDestinationHasNotFinishedTheUpload =>
      _catalog.failureTheDestinationHasNotFinishedTheUpload;

  /// Operator-facing failure retained through headless execution.
  String get failureRetryTheUpload => _catalog.failureRetryTheUpload;

  /// Operator-facing failure retained through headless execution.
  String get failureThatFolderCannotBeWritten =>
      _catalog.failureThatFolderCannotBeWritten;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseTheFolderAgain =>
      _catalog.failureChooseTheFolderAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheFileCouldNotBeWrittenTo =>
      _catalog.failureTheFileCouldNotBeWrittenTo;

  /// Operator-facing failure retained through headless execution.
  String get failureFreeSomeSpaceOrChooseTheFolder =>
      _catalog.failureFreeSomeSpaceOrChooseTheFolder;

  /// Operator-facing failure retained through headless execution.
  String get failureThisFolderRequiresASupportedSystemFolder =>
      _catalog.failureThisFolderRequiresASupportedSystemFolder;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAnAccessibleFolderOrAnotherDestination =>
      _catalog.failureChooseAnAccessibleFolderOrAnotherDestination;

  /// Operator-facing failure retained through headless execution.
  String get failureThatFolderPathIsNotUsable =>
      _catalog.failureThatFolderPathIsNotUsable;

  /// Operator-facing failure retained through headless execution.
  String get failureTheTaptureFolderOnThisDeviceIs =>
      _catalog.failureTheTaptureFolderOnThisDeviceIs;

  /// Operator-facing failure retained through headless execution.
  String get failureCheckTheStorageLocationInSettings =>
      _catalog.failureCheckTheStorageLocationInSettings;

  /// Operator-facing failure retained through headless execution.
  String get failureThisGoogleDriveSignInIsNo =>
      _catalog.failureThisGoogleDriveSignInIsNo;

  /// Operator-facing failure retained through headless execution.
  String get failureSignInToThisDestinationAgain =>
      _catalog.failureSignInToThisDestinationAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureGoogleDriveNeedsACurrentSignIn =>
      _catalog.failureGoogleDriveNeedsACurrentSignIn;

  /// Operator-facing failure retained through headless execution.
  String get failureSignInAgainToAllowFileAccess =>
      _catalog.failureSignInAgainToAllowFileAccess;

  /// Operator-facing failure retained through headless execution.
  String get failureNativeGoogleDriveSignInIsUnavailable =>
      _catalog.failureNativeGoogleDriveSignInIsUnavailable;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDestinationIsStillSavedSignIn =>
      _catalog.failureTheDestinationIsStillSavedSignIn;

  /// Operator-facing failure retained through headless execution.
  String get failureTheUploadChunkSizeIsNotUsable =>
      _catalog.failureTheUploadChunkSizeIsNotUsable;

  /// Operator-facing failure retained through headless execution.
  String get failureUseTheStandardUploadSettings =>
      _catalog.failureUseTheStandardUploadSettings;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDestinationReturnedAnUnusableUploadResponse =>
      _catalog.failureTheDestinationReturnedAnUnusableUploadResponse;

  /// Operator-facing failure retained through headless execution.
  String get failureTestTheDestinationThenTryTheUpload =>
      _catalog.failureTestTheDestinationThenTryTheUpload;

  /// Operator-facing failure retained through headless execution.
  String get failureTheBucketDidNotAcknowledgeTheUploaded =>
      _catalog.failureTheBucketDidNotAcknowledgeTheUploaded;

  /// Operator-facing failure retained through headless execution.
  String get failureTestTheDestinationAndTryAgain =>
      _catalog.failureTestTheDestinationAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheBucketDidNotFinishTheUpload =>
      _catalog.failureTheBucketDidNotFinishTheUpload;

  /// Operator-facing failure retained through headless execution.
  String get failureTheBucketRefusedToFinishTheUpload =>
      _catalog.failureTheBucketRefusedToFinishTheUpload;

  /// Operator-facing failure retained through headless execution.
  String get failureTheBucketDidNotConfirmTheCompleted =>
      _catalog.failureTheBucketDidNotConfirmTheCompleted;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDestinationDidNotStartTheUpload =>
      _catalog.failureTheDestinationDidNotStartTheUpload;

  /// Operator-facing failure retained through headless execution.
  String get failureTryTheConnectionAgain =>
      _catalog.failureTryTheConnectionAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThisDestinationHasNoSavedSignIn =>
      _catalog.failureThisDestinationHasNoSavedSignIn;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterTheKeysAndTestTheConnection =>
      _catalog.failureEnterTheKeysAndTestTheConnection;

  /// Operator-facing failure retained through headless execution.
  String get failureTheSavedSignInIsNotUsable =>
      _catalog.failureTheSavedSignInIsNotUsable;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterTheKeysAgain => _catalog.failureEnterTheKeysAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheBucketSettingsAreIncomplete =>
      _catalog.failureTheBucketSettingsAreIncomplete;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterTheKeyRegionAndBucket =>
      _catalog.failureEnterTheKeyRegionAndBucket;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAFilenameWithoutFolderSeparators =>
      _catalog.failureChooseAFilenameWithoutFolderSeparators;

  /// Operator-facing failure retained through headless execution.
  String get failureTheFolderCouldNotOpenANew =>
      _catalog.failureTheFolderCouldNotOpenANew;

  /// Operator-facing failure retained through headless execution.
  String get failureTheFolderCouldNotPublishTheFile =>
      _catalog.failureTheFolderCouldNotPublishTheFile;

  /// Operator-facing failure retained through headless execution.
  String get failureAccessToTheChosenFolderWasLost =>
      _catalog.failureAccessToTheChosenFolderWasLost;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAnAccessibleFolderAndTryAgain =>
      _catalog.failureChooseAnAccessibleFolderAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheUploadFilenameIsNotUsable =>
      _catalog.failureTheUploadFilenameIsNotUsable;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterTheAddressAndSignInThen =>
      _catalog.failureEnterTheAddressAndSignInThen;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDestinationAddressOrSignInIs =>
      _catalog.failureTheDestinationAddressOrSignInIs;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterAFullHTTPSAddressAndSign =>
      _catalog.failureEnterAFullHTTPSAddressAndSign;

  /// Operator-facing failure retained through headless execution.
  String get failureGoogleDriveSignInCouldNotFinish =>
      _catalog.failureGoogleDriveSignInCouldNotFinish;

  /// Operator-facing failure retained through headless execution.
  String get failureThisDestinationNeedsAFreshSignIn =>
      _catalog.failureThisDestinationNeedsAFreshSignIn;

  /// Operator-facing failure retained through headless execution.
  String get failureTheUploadCheckpointCouldNotBeSaved =>
      _catalog.failureTheUploadCheckpointCouldNotBeSaved;

  /// Operator-facing failure retained through headless execution.
  String get failureCheckSecureStorageThenTryAgain =>
      _catalog.failureCheckSecureStorageThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThatRowIsNoLongerOnThis =>
      _catalog.failureThatRowIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureRefreshTheListAndTryAgain =>
      _catalog.failureRefreshTheListAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureADeleteNeedsAReason => _catalog.failureADeleteNeedsAReason;

  /// Operator-facing failure retained through headless execution.
  String get failureSayWhyThisRowShouldBeRemoved =>
      _catalog.failureSayWhyThisRowShouldBeRemoved;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDatabaseCouldNotCompleteThatWrite =>
      _catalog.failureTheDatabaseCouldNotCompleteThatWrite;

  /// Operator-facing failure retained through headless execution.
  String get failureFreeUpSpaceOrExportAProject =>
      _catalog.failureFreeUpSpaceOrExportAProject;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDatabaseIsEncryptedAndTheKey =>
      _catalog.failureTheDatabaseIsEncryptedAndTheKey;

  /// Operator-facing failure retained through headless execution.
  String get failureRestoreTheKeyFromABackupThen =>
      _catalog.failureRestoreTheKeyFromABackupThen;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDatabaseKeyIsMissingOrUnreadable =>
      _catalog.failureTheDatabaseKeyIsMissingOrUnreadable;

  /// Operator-facing failure retained through headless execution.
  String get failureTypeDISABLEENCRYPTIONToTurnEncryptionOff =>
      _catalog.failureTypeDISABLEENCRYPTIONToTurnEncryptionOff;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterTheConfirmationExactlyThenTryAgain =>
      _catalog.failureEnterTheConfirmationExactlyThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThereIsNoDatabaseToEncrypt =>
      _catalog.failureThereIsNoDatabaseToEncrypt;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenTheAppOnceSoADatabase =>
      _catalog.failureOpenTheAppOnceSoADatabase;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDatabaseCouldNotBeEncrypted =>
      _catalog.failureTheDatabaseCouldNotBeEncrypted;

  /// Operator-facing failure retained through headless execution.
  String get failureFreeUpSpaceThenTryAgain =>
      _catalog.failureFreeUpSpaceThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheEncryptedCopyDidNotMatchThe =>
      _catalog.failureTheEncryptedCopyDidNotMatchThe;

  /// Operator-facing failure retained through headless execution.
  String get failureTryEncryptingAgainTheOriginalDatabaseWas =>
      _catalog.failureTryEncryptingAgainTheOriginalDatabaseWas;

  /// Operator-facing failure retained through headless execution.
  String get failureKeepTheWorkingDatabaseFreeUpSpace =>
      _catalog.failureKeepTheWorkingDatabaseFreeUpSpace;

  /// Operator-facing failure retained through headless execution.
  String get failureRestoreTheKeyFromABackupThe =>
      _catalog.failureRestoreTheKeyFromABackupThe;

  /// Operator-facing failure retained through headless execution.
  String get failureThisUpdateWouldDropOrRewriteA =>
      _catalog.failureThisUpdateWouldDropOrRewriteA;

  /// Operator-facing failure retained through headless execution.
  String get failureExportYourProjectsThenConfirmTheUpdate =>
      _catalog.failureExportYourProjectsThenConfirmTheUpdate;

  /// Operator-facing failure retained through headless execution.
  String get failureThisDeviceCannotBuildTheRecordSearch =>
      _catalog.failureThisDeviceCannotBuildTheRecordSearch;

  /// Operator-facing failure retained through headless execution.
  String get failureUpdateTheAppThenOpenItAgain =>
      _catalog.failureUpdateTheAppThenOpenItAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheFilePathMustStayInsideThe =>
      _catalog.failureTheFilePathMustStayInsideThe;

  /// Operator-facing failure retained through headless execution.
  String get failureSaveTheFileUnderTheProjectFolder =>
      _catalog.failureSaveTheFileUnderTheProjectFolder;

  /// Operator-facing failure retained through headless execution.
  String get failureTheOriginalCaptionCannotBeChanged =>
      _catalog.failureTheOriginalCaptionCannotBeChanged;

  /// Operator-facing failure retained through headless execution.
  String get failureLeaveTheCapturedTextAndWriteA =>
      _catalog.failureLeaveTheCapturedTextAndWriteA;

  /// Operator-facing failure retained through headless execution.
  String get failureADuplicatePairNeedsTwoRecords =>
      _catalog.failureADuplicatePairNeedsTwoRecords;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseBothRecordsAndTryAgain =>
      _catalog.failureChooseBothRecordsAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureARecordCannotBeADuplicateOf =>
      _catalog.failureARecordCannotBeADuplicateOf;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseTwoDifferentRecordsAndTryAgain =>
      _catalog.failureChooseTwoDifferentRecordsAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureADuplicatePairNeedsAProjectA =>
      _catalog.failureADuplicatePairNeedsAProjectA;

  /// Operator-facing failure retained through headless execution.
  String get failureRunDetectionAgainThenTryAgain =>
      _catalog.failureRunDetectionAgainThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureAResolutionNeedsAChoiceAndAn =>
      _catalog.failureAResolutionNeedsAChoiceAndAn;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseHowToResolveThePairThen =>
      _catalog.failureChooseHowToResolveThePairThen;

  /// Operator-facing failure retained through headless execution.
  String get failureThatPairIsNoLongerOnThis =>
      _catalog.failureThatPairIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureACompletedExportCannotBeChanged =>
      _catalog.failureACompletedExportCannotBeChanged;

  /// Operator-facing failure retained through headless execution.
  String get failureRunANewExportInsteadOfRewriting =>
      _catalog.failureRunANewExportInsteadOfRewriting;

  /// Operator-facing failure retained through headless execution.
  String get failureAnExportIsRecordedOnlyWhenThe =>
      _catalog.failureAnExportIsRecordedOnlyWhenThe;

  /// Operator-facing failure retained through headless execution.
  String get failureFinishWritingTheFileThenRecordThe =>
      _catalog.failureFinishWritingTheFileThenRecordThe;

  /// Operator-facing failure retained through headless execution.
  String get failureTheExportFormatsAreNotInA =>
      _catalog.failureTheExportFormatsAreNotInA;

  /// Operator-facing failure retained through headless execution.
  String get failureFixTheFormatsListAndSaveAgain =>
      _catalog.failureFixTheFormatsListAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheExportFiltersAreNotInA =>
      _catalog.failureTheExportFiltersAreNotInA;

  /// Operator-facing failure retained through headless execution.
  String get failureStoreTheQueryNotTheExportedValues =>
      _catalog.failureStoreTheQueryNotTheExportedValues;

  /// Operator-facing failure retained through headless execution.
  String get failureThatEntryCouldNotBeRead =>
      _catalog.failureThatEntryCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  String get failureChangeItThenSaveAgain =>
      _catalog.failureChangeItThenSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheMarkedAreaOnThePhotoCould =>
      _catalog.failureTheMarkedAreaOnThePhotoCould;

  /// Operator-facing failure retained through headless execution.
  String get failureFixTheRegionObjectAndSaveAgain =>
      _catalog.failureFixTheRegionObjectAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheMarkedAreaOnThePhotoIs =>
      _catalog.failureTheMarkedAreaOnThePhotoIs;

  /// Operator-facing failure retained through headless execution.
  String get failureThatMeetingIsNoLongerOnThis =>
      _catalog.failureThatMeetingIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureTheOriginalTranscriptCannotBeChanged =>
      _catalog.failureTheOriginalTranscriptCannotBeChanged;

  /// Operator-facing failure retained through headless execution.
  String get failureLeaveTheCapturedTextAndWriteRefined =>
      _catalog.failureLeaveTheCapturedTextAndWriteRefined;

  /// Operator-facing failure retained through headless execution.
  String get failureTheMeetingAgendaCouldNotBeRead =>
      _catalog.failureTheMeetingAgendaCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  String get failureFixTheAgendaListAndSaveAgain =>
      _catalog.failureFixTheAgendaListAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheMeetingAgendaIsNotInA =>
      _catalog.failureTheMeetingAgendaIsNotInA;

  /// Operator-facing failure retained through headless execution.
  String get failureTheMergeSummaryCouldNotBeRead =>
      _catalog.failureTheMergeSummaryCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  String get failureFixTheCountsObjectAndSaveAgain =>
      _catalog.failureFixTheCountsObjectAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheMergeSummaryIsNotInA =>
      _catalog.failureTheMergeSummaryIsNotInA;

  /// Operator-facing failure retained through headless execution.
  String get failureAConflictNeedsAChoiceAndAn =>
      _catalog.failureAConflictNeedsAChoiceAndAn;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseASideThenResolveAgain =>
      _catalog.failureChooseASideThenResolveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThatConflictIsNoLongerOnThis =>
      _catalog.failureThatConflictIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureThatJobIsNoLongerOnThis =>
      _catalog.failureThatJobIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureRefreshTheQueueAndTryAgain =>
      _catalog.failureRefreshTheQueueAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureAStoredProviderResponseCannotBeChanged =>
      _catalog.failureAStoredProviderResponseCannotBeChanged;

  /// Operator-facing failure retained through headless execution.
  String get failureLeaveTheOriginalResultAndWriteA =>
      _catalog.failureLeaveTheOriginalResultAndWriteA;

  /// Operator-facing failure retained through headless execution.
  String get failureARequestSummaryCannotIncludeASecret =>
      _catalog.failureARequestSummaryCannotIncludeASecret;

  /// Operator-facing failure retained through headless execution.
  String get failureStoreShapeAndSizeOnlyThenSave =>
      _catalog.failureStoreShapeAndSizeOnlyThenSave;

  /// Operator-facing failure retained through headless execution.
  String get failureTheProjectSettingsCouldNotBeRead =>
      _catalog.failureTheProjectSettingsCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  String get failureChangeTheSettingsAgainThenSave =>
      _catalog.failureChangeTheSettingsAgainThenSave;

  /// Operator-facing failure retained through headless execution.
  String get failureTheProjectSettingsAreNotInA =>
      _catalog.failureTheProjectSettingsAreNotInA;

  /// Operator-facing failure retained through headless execution.
  String get failureThatRecordIsNoLongerOnThis =>
      _catalog.failureThatRecordIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureTheRecordSContextCouldNotBe =>
      _catalog.failureTheRecordSContextCouldNotBe;

  /// Operator-facing failure retained through headless execution.
  String get failureFixTheContextObjectAndSaveAgain =>
      _catalog.failureFixTheContextObjectAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheRecordSContextIsNotIn =>
      _catalog.failureTheRecordSContextIsNotIn;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueIsNoLongerOnThis =>
      _catalog.failureThatValueIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureRefreshTheRecordAndTryAgain =>
      _catalog.failureRefreshTheRecordAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheOriginalValueCannotBeChanged =>
      _catalog.failureTheOriginalValueCannotBeChanged;

  /// Operator-facing failure retained through headless execution.
  String get failureLeaveTheCapturedValueAndWriteA =>
      _catalog.failureLeaveTheCapturedValueAndWriteA;

  /// Operator-facing failure retained through headless execution.
  String get failureADatasetImportNeedsASourceFile =>
      _catalog.failureADatasetImportNeedsASourceFile;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseTheFileAndWhereItBelongs =>
      _catalog.failureChooseTheFileAndWhereItBelongs;

  /// Operator-facing failure retained through headless execution.
  String get failureAProjectDatasetNeedsAProject =>
      _catalog.failureAProjectDatasetNeedsAProject;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseTheProjectThenImportAgain =>
      _catalog.failureChooseTheProjectThenImportAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureAGlobalDatasetCannotBelongToOne =>
      _catalog.failureAGlobalDatasetCannotBelongToOne;

  /// Operator-facing failure retained through headless execution.
  String get failureClearTheProjectThenImportAgain =>
      _catalog.failureClearTheProjectThenImportAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDatasetColumnsAreNotInA =>
      _catalog.failureTheDatasetColumnsAreNotInA;

  /// Operator-facing failure retained through headless execution.
  String get failureFixTheColumnListAndSaveAgain =>
      _catalog.failureFixTheColumnListAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureAReferenceRowIsNotInA =>
      _catalog.failureAReferenceRowIsNotInA;

  /// Operator-facing failure retained through headless execution.
  String get failureFixTheRowValuesAndSaveAgain =>
      _catalog.failureFixTheRowValuesAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThatEntryIsNotInAForm =>
      _catalog.failureThatEntryIsNotInAForm;

  /// Operator-facing failure retained through headless execution.
  String get failureAResolutionNeedsAnOperator =>
      _catalog.failureAResolutionNeedsAnOperator;

  /// Operator-facing failure retained through headless execution.
  String get failureSignInThenResolveTheVarianceAgain =>
      _catalog.failureSignInThenResolveTheVarianceAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThatVarianceIsNoLongerOnThis =>
      _catalog.failureThatVarianceIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDatabaseIsBusy => _catalog.failureTheDatabaseIsBusy;

  /// Operator-facing failure retained through headless execution.
  String get failureWaitAMomentThenTryTheSave =>
      _catalog.failureWaitAMomentThenTryTheSave;

  /// Operator-facing failure retained through headless execution.
  String get failureARecordWithThatIdentityAlreadyExists =>
      _catalog.failureARecordWithThatIdentityAlreadyExists;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenTheExistingRecordOrChangeThe =>
      _catalog.failureOpenTheExistingRecordOrChangeThe;

  /// Operator-facing failure retained through headless execution.
  String get failureThatPhotoCouldNotBeBlurred =>
      _catalog.failureThatPhotoCouldNotBeBlurred;

  /// Operator-facing failure retained through headless execution.
  String get failureADetectedFaceIsOutsideThatPhoto =>
      _catalog.failureADetectedFaceIsOutsideThatPhoto;

  /// Operator-facing failure retained through headless execution.
  String get failureFaceDetectionIsUnavailableOnThisDevice =>
      _catalog.failureFaceDetectionIsUnavailableOnThisDevice;

  /// Operator-facing failure retained through headless execution.
  String get failureUseAnAndroidOrIOSDeviceTo =>
      _catalog.failureUseAnAndroidOrIOSDeviceTo;

  /// Operator-facing failure retained through headless execution.
  String get failureThisPhotoCannotBeCheckedForFaces =>
      _catalog.failureThisPhotoCannotBeCheckedForFaces;

  /// Operator-facing failure retained through headless execution.
  String get failureThisPhotoCannotBeProtected =>
      _catalog.failureThisPhotoCannotBeProtected;

  /// Operator-facing failure retained through headless execution.
  String get failureAHiddenAreaIsInvalid =>
      _catalog.failureAHiddenAreaIsInvalid;

  /// Operator-facing failure retained through headless execution.
  String get failureThisExportFolderAlreadyContainsCompletedFiles =>
      _catalog.failureThisExportFolderAlreadyContainsCompletedFiles;

  /// Operator-facing failure retained through headless execution.
  String get failureCreateTheExportInANewVersion =>
      _catalog.failureCreateTheExportInANewVersion;

  /// Operator-facing failure retained through headless execution.
  String get failureStreamingTextExportNeedsNativeStorage =>
      _catalog.failureStreamingTextExportNeedsNativeStorage;

  /// Operator-facing failure retained through headless execution.
  String get failureTaptureCannotCopyAFileFromThis =>
      _catalog.failureTaptureCannotCopyAFileFromThis;

  /// Operator-facing failure retained through headless execution.
  String get failureAddTheFileAgainFromTaptureThen =>
      _catalog.failureAddTheFileAgainFromTaptureThen;

  /// Operator-facing failure retained through headless execution.
  String failureTaptureCouldNotWriteToValue(String value0) =>
      _catalog.failureTaptureCouldNotWriteToValue(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureTaptureCouldNotNameThatStoredFile =>
      _catalog.failureTaptureCouldNotNameThatStoredFile;

  /// Operator-facing failure retained through headless execution.
  String get failureTryAgainIfItKeepsHappeningExport =>
      _catalog.failureTryAgainIfItKeepsHappeningExport;

  /// Operator-facing failure retained through headless execution.
  String get failureTaptureCouldNotSaveThatOnThis =>
      _catalog.failureTaptureCouldNotSaveThatOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureFreeSomeSpaceThenTryAgain =>
      _catalog.failureFreeSomeSpaceThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheCacheCouldNotBeCleanedOn =>
      _catalog.failureTheCacheCouldNotBeCleanedOn;

  /// Operator-facing failure retained through headless execution.
  String get failureFreeSpaceOrAllowStorageAccessThen =>
      _catalog.failureFreeSpaceOrAllowStorageAccessThen;

  /// Operator-facing failure retained through headless execution.
  String get failureThatImageSizeIsNotValid =>
      _catalog.failureThatImageSizeIsNotValid;

  /// Operator-facing failure retained through headless execution.
  String get failureUseTheAppUploadSizeAndTry =>
      _catalog.failureUseTheAppUploadSizeAndTry;

  /// Operator-facing failure retained through headless execution.
  String get failureTheReducedCopyCouldNotBeCreated =>
      _catalog.failureTheReducedCopyCouldNotBeCreated;

  /// Operator-facing failure retained through headless execution.
  String failureTaptureCouldNotFindValue(String value0) =>
      _catalog.failureTaptureCouldNotFindValue(value0);

  /// Operator-facing failure retained through headless execution.
  String failureTaptureCouldNotSaveValue(String value0) =>
      _catalog.failureTaptureCouldNotSaveValue(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureFreeSomeSpaceThenDownloadAgain =>
      _catalog.failureFreeSomeSpaceThenDownloadAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenDownloadsOnThisDeviceAndLook =>
      _catalog.failureOpenDownloadsOnThisDeviceAndLook;

  /// Operator-facing failure retained through headless execution.
  String get failureOnlyFilesInsideAProjectFolderCan =>
      _catalog.failureOnlyFilesInsideAProjectFolderCan;

  /// Operator-facing failure retained through headless execution.
  String get failureLeaveTheFileInPlaceThePurge =>
      _catalog.failureLeaveTheFileInPlaceThePurge;

  /// Operator-facing failure retained through headless execution.
  String get failureThatPhotoHasNoUsableNameFor =>
      _catalog.failureThatPhotoHasNoUsableNameFor;

  /// Operator-facing failure retained through headless execution.
  String get failureLeaveThePhotoInPlaceThePurge =>
      _catalog.failureLeaveThePhotoInPlaceThePurge;

  /// Operator-facing failure retained through headless execution.
  String get failureADeletedRecordSFilesCouldNot =>
      _catalog.failureADeletedRecordSFilesCouldNot;

  /// Operator-facing failure retained through headless execution.
  String get failureAllowStorageAccessThePurgeTriesAgain =>
      _catalog.failureAllowStorageAccessThePurgeTriesAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThisExportIsTooLargeForThis =>
      _catalog.failureThisExportIsTooLargeForThis;

  /// Operator-facing failure retained through headless execution.
  String get failureExportFewerRecordsOrUseADesktop =>
      _catalog.failureExportFewerRecordsOrUseADesktop;

  /// Operator-facing failure retained through headless execution.
  String failureAnExportSourceIsMissingValue(String value0) =>
      _catalog.failureAnExportSourceIsMissingValue(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureANativeFileSystemIsUnavailable =>
      _catalog.failureANativeFileSystemIsUnavailable;

  /// Operator-facing failure retained through headless execution.
  String failureTaptureCouldNotReadValue(String value0) =>
      _catalog.failureTaptureCouldNotReadValue(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureCaptureOrAddTheFileAgainThen =>
      _catalog.failureCaptureOrAddTheFileAgainThen;

  /// Operator-facing failure retained through headless execution.
  String get failureThatProjectIsNoLongerOnThis =>
      _catalog.failureThatProjectIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenAProjectThenTryAgain =>
      _catalog.failureOpenAProjectThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureRecreateTheProjectFolderThenTryAgain =>
      _catalog.failureRecreateTheProjectFolderThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String failureTheFileValueIsEmpty(String value0) =>
      _catalog.failureTheFileValueIsEmpty(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAFileThatHasContentsAnd =>
      _catalog.failureChooseAFileThatHasContentsAnd;

  /// Operator-facing failure retained through headless execution.
  String failureTheFileValueIsNotASupported(String value0) =>
      _catalog.failureTheFileValueIsNotASupported(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAnImageDocumentSpreadsheetAudioFile =>
      _catalog.failureChooseAnImageDocumentSpreadsheetAudioFile;

  /// Operator-facing failure retained through headless execution.
  String failureTheFileValueDoesNotMatchIts(String value0) =>
      _catalog.failureTheFileValueDoesNotMatchIts(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAFileOfTheExpectedType =>
      _catalog.failureChooseAFileOfTheExpectedType;

  /// Operator-facing failure retained through headless execution.
  String failureTheFileValueIsLargerThanThe(String value0, String value1) =>
      _catalog.failureTheFileValueIsLargerThanThe(value0, value1);

  /// Operator-facing failure retained through headless execution.
  String get failureChooseASmallerFileAndTryAgain =>
      _catalog.failureChooseASmallerFileAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String failureTheArchiveValueContainsAPathThat(String value0) =>
      _catalog.failureTheArchiveValueContainsAPathThat(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureChooseADifferentFileAndTryAgain =>
      _catalog.failureChooseADifferentFileAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String failureTheArchiveValueContainsALinkInstead(String value0) =>
      _catalog.failureTheArchiveValueContainsALinkInstead(value0);

  /// Operator-facing failure retained through headless execution.
  String failureTheArchiveValueDeclaresMoreUncompressedData(String value0) =>
      _catalog.failureTheArchiveValueDeclaresMoreUncompressedData(value0);

  /// Operator-facing failure retained through headless execution.
  String failureTheFileValueIsNotAnArchive(String value0) =>
      _catalog.failureTheFileValueIsNotAnArchive(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAZIPBundleOrSpreadsheetAnd =>
      _catalog.failureChooseAZIPBundleOrSpreadsheetAnd;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseTheFileAgainThenTryAgain =>
      _catalog.failureChooseTheFileAgainThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThePhotoCouldNotBeSavedOn =>
      _catalog.failureThePhotoCouldNotBeSavedOn;

  /// Operator-facing failure retained through headless execution.
  String failureThereIsNotEnoughSpaceToSave(String value0) =>
      _catalog.failureThereIsNotEnoughSpaceToSave(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureAllowStorageAccessThenTryAgain =>
      _catalog.failureAllowStorageAccessThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThisPhotoCannotBeMarked =>
      _catalog.failureThisPhotoCannotBeMarked;

  /// Operator-facing failure retained through headless execution.
  String get failureThisPackageIsTooLargeOrIncomplete =>
      _catalog.failureThisPackageIsTooLargeOrIncomplete;

  /// Operator-facing failure retained through headless execution.
  String get failureFinishTheCurrentPackageBeforeOpeningAnother =>
      _catalog.failureFinishTheCurrentPackageBeforeOpeningAnother;

  /// Operator-facing failure retained through headless execution.
  String get failureThisPackageIsTooLargeToOpen =>
      _catalog.failureThisPackageIsTooLargeToOpen;

  /// Operator-facing failure retained through headless execution.
  String get failureThisPackageCouldNotBeOpened =>
      _catalog.failureThisPackageCouldNotBeOpened;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenTheFileAgainFromItsOriginal =>
      _catalog.failureOpenTheFileAgainFromItsOriginal;

  /// Operator-facing failure retained through headless execution.
  String get failureThatProjectCouldNotBeScanned =>
      _catalog.failureThatProjectCouldNotBeScanned;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenTheProjectAndTryAgain =>
      _catalog.failureOpenTheProjectAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheProjectFolderCouldNotBeScanned =>
      _catalog.failureTheProjectFolderCouldNotBeScanned;

  /// Operator-facing failure retained through headless execution.
  String get failurePutTheFileBackInTheProject =>
      _catalog.failurePutTheFileBackInTheProject;

  /// Operator-facing failure retained through headless execution.
  String get failureTheFileCouldNotBeAdoptedOn =>
      _catalog.failureTheFileCouldNotBeAdoptedOn;

  /// Operator-facing failure retained through headless execution.
  String get failureTheMissingFileCouldNotBeFlagged =>
      _catalog.failureTheMissingFileCouldNotBeFlagged;

  /// Operator-facing failure retained through headless execution.
  String get failureThatFileRowIsNoLongerOn =>
      _catalog.failureThatFileRowIsNoLongerOn;

  /// Operator-facing failure retained through headless execution.
  String get failureThatNameIsNotAValidFolder =>
      _catalog.failureThatNameIsNotAValidFolder;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseANameWithoutSlashesThatPoint =>
      _catalog.failureChooseANameWithoutSlashesThatPoint;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseANameWithLettersOrDigits =>
      _catalog.failureChooseANameWithLettersOrDigits;

  /// Operator-facing failure retained through headless execution.
  String get failureTheFilePathMustStayInsideThe2 =>
      _catalog.failureTheFilePathMustStayInsideThe2;

  /// Operator-facing failure retained through headless execution.
  String get failureThatPhotoIsNoLongerAvailable =>
      _catalog.failureThatPhotoIsNoLongerAvailable;

  /// Operator-facing failure retained through headless execution.
  String get failureHiddenAreasChangedTrySendingAgain =>
      _catalog.failureHiddenAreasChangedTrySendingAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureCheckTheHiddenAreasOnThisEdited =>
      _catalog.failureCheckTheHiddenAreasOnThisEdited;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenHidePartsBeforeSendingAndSave =>
      _catalog.failureOpenHidePartsBeforeSendingAndSave;

  /// Operator-facing failure retained through headless execution.
  String get failureTheProjectFolderCouldNotBeRemoved =>
      _catalog.failureTheProjectFolderCouldNotBeRemoved;

  /// Operator-facing failure retained through headless execution.
  String get failureDeleteTheLeftoverFolderThenTryAgain =>
      _catalog.failureDeleteTheLeftoverFolderThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThatProjectIsAlreadyInTheRecycle =>
      _catalog.failureThatProjectIsAlreadyInTheRecycle;

  /// Operator-facing failure retained through headless execution.
  String get failureRestoreItFromTheRecycleAreaThen =>
      _catalog.failureRestoreItFromTheRecycleAreaThen;

  /// Operator-facing failure retained through headless execution.
  String get failureTheProjectFolderCouldNotBeMoved =>
      _catalog.failureTheProjectFolderCouldNotBeMoved;

  /// Operator-facing failure retained through headless execution.
  String get failureThisProjectHasNoFolderOnDisk =>
      _catalog.failureThisProjectHasNoFolderOnDisk;

  /// Operator-facing failure retained through headless execution.
  String get failureCreateTheProjectFolderThenTryAgain =>
      _catalog.failureCreateTheProjectFolderThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheProjectFolderCouldNotBeCreated =>
      _catalog.failureTheProjectFolderCouldNotBeCreated;

  /// Operator-facing failure retained through headless execution.
  String get failureThatProjectFolderNameIsNotA =>
      _catalog.failureThatProjectFolderNameIsNotA;

  /// Operator-facing failure retained through headless execution.
  String get failureRecreateTheProjectSoItsFolderCan =>
      _catalog.failureRecreateTheProjectSoItsFolderCan;

  /// Operator-facing failure retained through headless execution.
  String get failureThereIsNotEnoughFreeSpaceTo =>
      _catalog.failureThereIsNotEnoughFreeSpaceTo;

  /// Operator-facing failure retained through headless execution.
  String get failureExportAProjectOrCleanTheCache =>
      _catalog.failureExportAProjectOrCleanTheCache;

  /// Operator-facing failure retained through headless execution.
  String get failureTaptureCouldNotReadFreeSpaceOn =>
      _catalog.failureTaptureCouldNotReadFreeSpaceOn;

  /// Operator-facing failure retained through headless execution.
  String get failureThisDeviceHasNoFolderTaptureCan =>
      _catalog.failureThisDeviceHasNoFolderTaptureCan;

  /// Operator-facing failure retained through headless execution.
  String get failureUseTaptureOnAPhoneTabletOr =>
      _catalog.failureUseTaptureOnAPhoneTabletOr;

  /// Operator-facing failure retained through headless execution.
  String get failureTheThumbnailCouldNotBeCreatedOn =>
      _catalog.failureTheThumbnailCouldNotBeCreatedOn;

  /// Operator-facing failure retained through headless execution.
  String get failureThatThumbnailSizeIsNotValid =>
      _catalog.failureThatThumbnailSizeIsNotValid;

  /// Operator-facing failure retained through headless execution.
  String get failureUseTheAppThumbnailSizeAndTry =>
      _catalog.failureUseTheAppThumbnailSizeAndTry;

  /// Operator-facing failure retained through headless execution.
  String get failureThatPhotoCouldNotBeCached =>
      _catalog.failureThatPhotoCouldNotBeCached;

  /// Operator-facing failure retained through headless execution.
  String get failureLocationIsOffForThisProject =>
      _catalog.failureLocationIsOffForThisProject;

  /// Operator-facing failure retained through headless execution.
  String get failureTurnGPSOnThenTryAgain =>
      _catalog.failureTurnGPSOnThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureBiometricAuthenticationIsUnavailable =>
      _catalog.failureBiometricAuthenticationIsUnavailable;

  /// Operator-facing failure retained through headless execution.
  String get failureUnlockWithYourAppPIN =>
      _catalog.failureUnlockWithYourAppPIN;

  /// Operator-facing failure retained through headless execution.
  String get failureTheSecretCouldNotBeSavedOn =>
      _catalog.failureTheSecretCouldNotBeSavedOn;

  /// Operator-facing failure retained through headless execution.
  String get failureTheSecretCouldNotBeReadOn =>
      _catalog.failureTheSecretCouldNotBeReadOn;

  /// Operator-facing failure retained through headless execution.
  String get failureTheSecretCouldNotBeRemovedFrom =>
      _catalog.failureTheSecretCouldNotBeRemovedFrom;

  /// Operator-facing failure retained through headless execution.
  String get failureTypeTheWordsToPlaceOnThis =>
      _catalog.failureTypeTheWordsToPlaceOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterTextThenSaveThePhoto =>
      _catalog.failureEnterTextThenSaveThePhoto;

  /// Operator-facing failure retained through headless execution.
  String get failureDiscardTheInterruptedSessionAndStartAgain =>
      _catalog.failureDiscardTheInterruptedSessionAndStartAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureOnlyARecordEditCanBeSaved =>
      _catalog.failureOnlyARecordEditCanBeSaved;

  /// Operator-facing failure retained through headless execution.
  String get failureGoBackToTheProjectAndPick =>
      _catalog.failureGoBackToTheProjectAndPick;

  /// Operator-facing failure retained through headless execution.
  String get failureTheCaptureSessionIsNotValid =>
      _catalog.failureTheCaptureSessionIsNotValid;

  /// Operator-facing failure retained through headless execution.
  String get failureCompletePhotoMetadataIsRequiredForA =>
      _catalog.failureCompletePhotoMetadataIsRequiredForA;

  /// Operator-facing failure retained through headless execution.
  String get failureThePhotoProjectWasNotFound =>
      _catalog.failureThePhotoProjectWasNotFound;

  /// Operator-facing failure retained through headless execution.
  String get failureThatPhotoCouldNotBeReadFrom =>
      _catalog.failureThatPhotoCouldNotBeReadFrom;

  /// Operator-facing failure retained through headless execution.
  String get failureTheOriginalPhotoStaysInPlace =>
      _catalog.failureTheOriginalPhotoStaysInPlace;

  /// Operator-facing failure retained through headless execution.
  String get failureRevertAnEditedPhotoInstead =>
      _catalog.failureRevertAnEditedPhotoInstead;

  /// Operator-facing failure retained through headless execution.
  String get failureThisPhotoAppearsMoreThanOnce =>
      _catalog.failureThisPhotoAppearsMoreThanOnce;

  /// Operator-facing failure retained through headless execution.
  String get failureReloadTheCaptureAndTryAgain =>
      _catalog.failureReloadTheCaptureAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureAnEditedPhotoIsMissingItsOriginal =>
      _catalog.failureAnEditedPhotoIsMissingItsOriginal;

  /// Operator-facing failure retained through headless execution.
  String get failureKeepThisCaptureAndRestoreTheOriginal =>
      _catalog.failureKeepThisCaptureAndRestoreTheOriginal;

  /// Operator-facing failure retained through headless execution.
  String get failureThesePhotoEditsLoopBackOnThemselves =>
      _catalog.failureThesePhotoEditsLoopBackOnThemselves;

  /// Operator-facing failure retained through headless execution.
  String get failureThatFieldIsNotOnThisRecord =>
      _catalog.failureThatFieldIsNotOnThisRecord;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenTheRecordAndTryAgain =>
      _catalog.failureOpenTheRecordAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThatFieldIsNotAContextLevel =>
      _catalog.failureThatFieldIsNotAContextLevel;

  /// Operator-facing failure retained through headless execution.
  String get failurePickALevelFromTheHierarchyAnd =>
      _catalog.failurePickALevelFromTheHierarchyAnd;

  /// Operator-facing failure retained through headless execution.
  String get failureAPresetNeedsAName => _catalog.failureAPresetNeedsAName;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterANameAndTryAgain =>
      _catalog.failureEnterANameAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureADeleteNeedsAnIdAndA =>
      _catalog.failureADeleteNeedsAnIdAndA;

  /// Operator-facing failure retained through headless execution.
  String get failureContextIsNotAvailableYet =>
      _catalog.failureContextIsNotAvailableYet;

  /// Operator-facing failure retained through headless execution.
  String get failureRestartTheAppAndTryAgain =>
      _catalog.failureRestartTheAppAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureAPresetWithThatNameAlreadyExists =>
      _catalog.failureAPresetWithThatNameAlreadyExists;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAnotherNameOrConfirmOverwrite =>
      _catalog.failureChooseAnotherNameOrConfirmOverwrite;

  /// Operator-facing failure retained through headless execution.
  String get failureTheProjectWasNotFound =>
      _catalog.failureTheProjectWasNotFound;

  /// Operator-facing failure retained through headless execution.
  String get failureAnExportedRecordIsNoLongerAvailable =>
      _catalog.failureAnExportedRecordIsNoLongerAvailable;

  /// Operator-facing failure retained through headless execution.
  String get failureAnExportedPhotoIsNoLongerAvailable =>
      _catalog.failureAnExportedPhotoIsNoLongerAvailable;

  /// Operator-facing failure retained through headless execution.
  String get failureASelectedRecordIsMissingRefreshThe =>
      _catalog.failureASelectedRecordIsMissingRefreshThe;

  /// Operator-facing failure retained through headless execution.
  String get failureAnExportNeedsAProject =>
      _catalog.failureAnExportNeedsAProject;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenAProjectAndExportAgain =>
      _catalog.failureOpenAProjectAndExportAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThisExportedPhotoCannotBeRead =>
      _catalog.failureThisExportedPhotoCannotBeRead;

  /// Operator-facing failure retained through headless execution.
  String get failureThisPhotoFormatCannotBePackagedSafely =>
      _catalog.failureThisPhotoFormatCannotBePackagedSafely;

  /// Operator-facing failure retained through headless execution.
  String get failureProjectFilesAreUnavailableOnThisDevice =>
      _catalog.failureProjectFilesAreUnavailableOnThisDevice;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenAProjectStoredOnThisDevice =>
      _catalog.failureOpenAProjectStoredOnThisDevice;

  /// Operator-facing failure retained through headless execution.
  String get failureWriteYourFeedbackThenSaveAgain =>
      _catalog.failureWriteYourFeedbackThenSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureNameTheTypeThenSaveAgain =>
      _catalog.failureNameTheTypeThenSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureChangeOrClearTheFiltersThenTry =>
      _catalog.failureChangeOrClearTheFiltersThenTry;

  /// Operator-facing failure retained through headless execution.
  String get failureCloseThisTapFeedbackThenTryAgain =>
      _catalog.failureCloseThisTapFeedbackThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureCorrectTheHighlightedFieldAndSaveAgain =>
      _catalog.failureCorrectTheHighlightedFieldAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheTemplateTheseRowsWereMatchedTo =>
      _catalog.failureTheTemplateTheseRowsWereMatchedTo;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAnotherTemplateAndImportAgain =>
      _catalog.failureChooseAnotherTemplateAndImportAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureARecordARowMatchedIsNo =>
      _catalog.failureARecordARowMatchedIsNo;

  /// Operator-facing failure retained through headless execution.
  String get failureImportTheFileAgainToMatchIt =>
      _catalog.failureImportTheFileAgainToMatchIt;

  /// Operator-facing failure retained through headless execution.
  String get failureRecordsCannotBeImportedRightNow =>
      _catalog.failureRecordsCannotBeImportedRightNow;

  /// Operator-facing failure retained through headless execution.
  String get failureRestartTaptureThenImportAgain =>
      _catalog.failureRestartTaptureThenImportAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThatFileIsNotInThisMeeting =>
      _catalog.failureThatFileIsNotInThisMeeting;

  /// Operator-facing failure retained through headless execution.
  String get failureAddTheFileToTheMeetingAgain =>
      _catalog.failureAddTheFileToTheMeetingAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureStartTheMeetingAgain =>
      _catalog.failureStartTheMeetingAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheSnapshotHasBeenPurged =>
      _catalog.failureTheSnapshotHasBeenPurged;

  /// Operator-facing failure retained through headless execution.
  String get failureTheMergeCanNoLongerBeUndone =>
      _catalog.failureTheMergeCanNoLongerBeUndone;

  /// Operator-facing failure retained through headless execution.
  String get failureTaptureCouldNotLookUpAFile =>
      _catalog.failureTaptureCouldNotLookUpAFile;

  /// Operator-facing failure retained through headless execution.
  String get failureAProjectWithThatIdAlreadyExists =>
      _catalog.failureAProjectWithThatIdAlreadyExists;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenTheExistingProjectOrUseA =>
      _catalog.failureOpenTheExistingProjectOrUseA;

  /// Operator-facing failure retained through headless execution.
  String get failureProjectPhotosCannotBeStoredOnThis =>
      _catalog.failureProjectPhotosCannotBeStoredOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureAddThePhotoOnADeviceThat =>
      _catalog.failureAddThePhotoOnADeviceThat;

  /// Operator-facing failure retained through headless execution.
  String get failureAProjectNeedsAName => _catalog.failureAProjectNeedsAName;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterANameAndSaveAgain =>
      _catalog.failureEnterANameAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureProjectFilesAreNotAvailableOnThis =>
      _catalog.failureProjectFilesAreNotAvailableOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureExportFromADeviceThatStoresThis =>
      _catalog.failureExportFromADeviceThatStoresThis;

  /// Operator-facing failure retained through headless execution.
  String get failureThatRecordIsNoLongerInThe =>
      _catalog.failureThatRecordIsNoLongerInThe;

  /// Operator-facing failure retained through headless execution.
  String get failureNothingToRemoveItWasRestoredOr =>
      _catalog.failureNothingToRemoveItWasRestoredOr;

  /// Operator-facing failure retained through headless execution.
  String get failureThatRecordWasDeletedAgainSoIts =>
      _catalog.failureThatRecordWasDeletedAgainSoIts;

  /// Operator-facing failure retained through headless execution.
  String get failureLeaveItThePurgeTakesItOnce =>
      _catalog.failureLeaveItThePurgeTakesItOnce;

  /// Operator-facing failure retained through headless execution.
  String get failureAMergeStillNeedsThatDeletedRecord =>
      _catalog.failureAMergeStillNeedsThatDeletedRecord;

  /// Operator-facing failure retained through headless execution.
  String get failureSendABundleOrSettleTheMerge =>
      _catalog.failureSendABundleOrSettleTheMerge;

  /// Operator-facing failure retained through headless execution.
  String get failureRecordsAreNotAvailableYet =>
      _catalog.failureRecordsAreNotAvailableYet;

  /// Operator-facing failure retained through headless execution.
  String get failureTheRecordWasSavedButCouldNot =>
      _catalog.failureTheRecordWasSavedButCouldNot;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenItFromTheRecordsList =>
      _catalog.failureOpenItFromTheRecordsList;

  /// Operator-facing failure retained through headless execution.
  String get failureThatTemplateIsNoLongerOnThis =>
      _catalog.failureThatTemplateIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAnotherTemplateAndTryAgain =>
      _catalog.failureChooseAnotherTemplateAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThisRecordAlreadyUsesThatTemplate =>
      _catalog.failureThisRecordAlreadyUsesThatTemplate;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseADifferentTemplate =>
      _catalog.failureChooseADifferentTemplate;

  /// Operator-facing failure retained through headless execution.
  String get failureThatTemplateBelongsToAnotherProject =>
      _catalog.failureThatTemplateBelongsToAnotherProject;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseATemplateFromThisProject =>
      _catalog.failureChooseATemplateFromThisProject;

  /// Operator-facing failure retained through headless execution.
  String get failureARecordNeedsAProjectAndA =>
      _catalog.failureARecordNeedsAProjectAndA;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAProjectAndATemplateThen =>
      _catalog.failureChooseAProjectAndATemplateThen;

  /// Operator-facing failure retained through headless execution.
  String get failureSayWhyTheRecordShouldGoThen =>
      _catalog.failureSayWhyTheRecordShouldGoThen;

  /// Operator-facing failure retained through headless execution.
  String get failureAnEditNeedsTheFieldItChanges =>
      _catalog.failureAnEditNeedsTheFieldItChanges;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAFieldThenSaveAgain =>
      _catalog.failureChooseAFieldThenSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureARecordGoesToTheRecycleBin =>
      _catalog.failureARecordGoesToTheRecycleBin;

  /// Operator-facing failure retained through headless execution.
  String get failureUseDeleteWhichLetsYouUndoIt =>
      _catalog.failureUseDeleteWhichLetsYouUndoIt;

  /// Operator-facing failure retained through headless execution.
  String get failureThisRecordIsInTheRecycleBin =>
      _catalog.failureThisRecordIsInTheRecycleBin;

  /// Operator-facing failure retained through headless execution.
  String get failureRestoreItFromTheRecycleBinFirst =>
      _catalog.failureRestoreItFromTheRecycleBinFirst;

  /// Operator-facing failure retained through headless execution.
  String get failureThisRecordIsNotInTheRecycle =>
      _catalog.failureThisRecordIsNotInTheRecycle;

  /// Operator-facing failure retained through headless execution.
  String get failureRefreshTheListItMayAlreadyBe =>
      _catalog.failureRefreshTheListItMayAlreadyBe;

  /// Operator-facing failure retained through headless execution.
  String get failureThisRecordHasAStatusThisVersion =>
      _catalog.failureThisRecordHasAStatusThisVersion;

  /// Operator-facing failure retained through headless execution.
  String get failureUpdateTheAppThenTryAgain =>
      _catalog.failureUpdateTheAppThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String failureThisRecordIsAlreadyValue(String value0) =>
      _catalog.failureThisRecordIsAlreadyValue(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureChooseADifferentStatusOrLeaveIt =>
      _catalog.failureChooseADifferentStatusOrLeaveIt;

  /// Operator-facing failure retained through headless execution.
  String failureARecordThatIsValueCannotBe(String value0, String value1) =>
      _catalog.failureARecordThatIsValueCannotBe(value0, value1);

  /// Operator-facing failure retained through headless execution.
  String get failureRestoreItFromTheRecycleBinBefore =>
      _catalog.failureRestoreItFromTheRecycleBinBefore;

  /// Operator-facing failure retained through headless execution.
  String get failureTheCapturedTemplateVersionIsUnavailable =>
      _catalog.failureTheCapturedTemplateVersionIsUnavailable;

  /// Operator-facing failure retained through headless execution.
  String get failureRestoreTheOriginalProjectPackageBeforeEditing =>
      _catalog.failureRestoreTheOriginalProjectPackageBeforeEditing;

  /// Operator-facing failure retained through headless execution.
  String get failureAQuotedCSVValueIsUnfinished =>
      _catalog.failureAQuotedCSVValueIsUnfinished;

  /// Operator-facing failure retained through headless execution.
  String get failureCloseTheQuotedValueAndImportThe =>
      _catalog.failureCloseTheQuotedValueAndImportThe;

  /// Operator-facing failure retained through headless execution.
  String get failureThatFileIsEmpty => _catalog.failureThatFileIsEmpty;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseACSVWithAHeaderAnd =>
      _catalog.failureChooseACSVWithAHeaderAnd;

  /// Operator-facing failure retained through headless execution.
  String get failureThatTableCouldNotBeReadAs =>
      _catalog.failureThatTableCouldNotBeReadAs;

  /// Operator-facing failure retained through headless execution.
  String get failureSaveItAsUTFCSVAndTry =>
      _catalog.failureSaveItAsUTFCSVAndTry;

  /// Operator-facing failure retained through headless execution.
  String get failureThatCSVCouldNotBeRead =>
      _catalog.failureThatCSVCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  String get failureCheckTheFileAndTryAgain =>
      _catalog.failureCheckTheFileAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseACSVJSONOrXLSXTable =>
      _catalog.failureChooseACSVJSONOrXLSXTable;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAnotherFileOrSplitThisTable =>
      _catalog.failureChooseAnotherFileOrSplitThisTable;

  /// Operator-facing failure retained through headless execution.
  String get failureSaveItAsUTFCSVOrA => _catalog.failureSaveItAsUTFCSVOrA;

  /// Operator-facing failure retained through headless execution.
  String get failureJSONDatasetsMustBeAnArrayOf =>
      _catalog.failureJSONDatasetsMustBeAnArrayOf;

  /// Operator-facing failure retained through headless execution.
  String get failureWrapTheRowsInAnArrayAnd =>
      _catalog.failureWrapTheRowsInAnArrayAnd;

  /// Operator-facing failure retained through headless execution.
  String get failureEveryJSONRowMustBeAnObject =>
      _catalog.failureEveryJSONRowMustBeAnObject;

  /// Operator-facing failure retained through headless execution.
  String get failureRemoveNonObjectRowsAndImportThe =>
      _catalog.failureRemoveNonObjectRowsAndImportThe;

  /// Operator-facing failure retained through headless execution.
  String get failureThatFileHasNoColumns =>
      _catalog.failureThatFileHasNoColumns;

  /// Operator-facing failure retained through headless execution.
  String get failureAddKeysToTheObjectsAndTry =>
      _catalog.failureAddKeysToTheObjectsAndTry;

  /// Operator-facing failure retained through headless execution.
  String get failureThatJSONIsNotValid => _catalog.failureThatJSONIsNotValid;

  /// Operator-facing failure retained through headless execution.
  String get failureFixTheJSONArrayAndImportIt =>
      _catalog.failureFixTheJSONArrayAndImportIt;

  /// Operator-facing failure retained through headless execution.
  String get failureThatJSONCouldNotBeRead =>
      _catalog.failureThatJSONCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  String get failureThatWorkbookHasNoSheets =>
      _catalog.failureThatWorkbookHasNoSheets;

  /// Operator-facing failure retained through headless execution.
  String get failureChooseAWorkbookWithASheetOf =>
      _catalog.failureChooseAWorkbookWithASheetOf;

  /// Operator-facing failure retained through headless execution.
  String get failureThatSheetHasNoHeaderRow =>
      _catalog.failureThatSheetHasNoHeaderRow;

  /// Operator-facing failure retained through headless execution.
  String get failureAddAHeaderRowAndTryAgain =>
      _catalog.failureAddAHeaderRowAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThatKeyColumnHasDuplicateValues =>
      _catalog.failureThatKeyColumnHasDuplicateValues;

  /// Operator-facing failure retained through headless execution.
  String get failurePickAnotherKeyColumnOrConfirmDuplicates =>
      _catalog.failurePickAnotherKeyColumnOrConfirmDuplicates;

  /// Operator-facing failure retained through headless execution.
  String get failureARowNeedsADatasetAndA =>
      _catalog.failureARowNeedsADatasetAndA;

  /// Operator-facing failure retained through headless execution.
  String get failureFillThoseFieldsAndSaveAgain =>
      _catalog.failureFillThoseFieldsAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureADatasetNeedsANameAndA =>
      _catalog.failureADatasetNeedsANameAndA;

  /// Operator-facing failure retained through headless execution.
  String get failureTheKeyColumnMustBeOneOf =>
      _catalog.failureTheKeyColumnMustBeOneOf;

  /// Operator-facing failure retained through headless execution.
  String get failurePickAKeyFromTheColumnList =>
      _catalog.failurePickAKeyFromTheColumnList;

  /// Operator-facing failure retained through headless execution.
  String get failureReferenceDataIsNotAvailableYet =>
      _catalog.failureReferenceDataIsNotAvailableYet;

  /// Operator-facing failure retained through headless execution.
  String get failureThatTableHasNoDataColumns =>
      _catalog.failureThatTableHasNoDataColumns;

  /// Operator-facing failure retained through headless execution.
  String get failureATemplateNeedsAName => _catalog.failureATemplateNeedsAName;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenAProjectThenAddTheTemplate =>
      _catalog.failureOpenAProjectThenAddTheTemplate;

  /// Operator-facing failure retained through headless execution.
  String get failureTheShippedTemplatesCouldNotBeRead =>
      _catalog.failureTheShippedTemplatesCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  String get failureThatShippedTemplateIsNotOnThis =>
      _catalog.failureThatShippedTemplateIsNotOnThis;

  /// Operator-facing failure retained through headless execution.
  String get failurePickAnotherTemplateFromTheLibrary =>
      _catalog.failurePickAnotherTemplateFromTheLibrary;

  /// Operator-facing failure retained through headless execution.
  String get failureTheInheritedFieldGroupsCouldNotBe =>
      _catalog.failureTheInheritedFieldGroupsCouldNotBe;

  /// Operator-facing failure retained through headless execution.
  String failureAShippedTemplateIsMissingValue(String value0) =>
      _catalog.failureAShippedTemplateIsMissingValue(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureReinstallTheAppThenTryAgain =>
      _catalog.failureReinstallTheAppThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureAShippedTemplateUsesAnUnknownSchema =>
      _catalog.failureAShippedTemplateUsesAnUnknownSchema;

  /// Operator-facing failure retained through headless execution.
  String get failureAShippedTemplateHasAnInvalidKey =>
      _catalog.failureAShippedTemplateHasAnInvalidKey;

  /// Operator-facing failure retained through headless execution.
  String get failureAShippedTemplateNameIsNotA =>
      _catalog.failureAShippedTemplateNameIsNotA;

  /// Operator-facing failure retained through headless execution.
  String get failureAShippedTemplateNamesAnUnknownIdentity =>
      _catalog.failureAShippedTemplateNamesAnUnknownIdentity;

  /// Operator-facing failure retained through headless execution.
  String get failureAShippedTemplateNamesAnUnknownParent =>
      _catalog.failureAShippedTemplateNamesAnUnknownParent;

  /// Operator-facing failure retained through headless execution.
  String get failureAShippedTemplateNamesAnUnknownField =>
      _catalog.failureAShippedTemplateNamesAnUnknownField;

  /// Operator-facing failure retained through headless execution.
  String failureAShippedFieldIsMissingValue(String value0) =>
      _catalog.failureAShippedFieldIsMissingValue(value0);

  /// Operator-facing failure retained through headless execution.
  String get failureAShippedFieldUsesAnUnknownType =>
      _catalog.failureAShippedFieldUsesAnUnknownType;

  /// Operator-facing failure retained through headless execution.
  String get failureAShippedFieldLabelIsNotA =>
      _catalog.failureAShippedFieldLabelIsNotA;

  /// Operator-facing failure retained through headless execution.
  String get failureAShippedTemplateCouldNotBeRead =>
      _catalog.failureAShippedTemplateCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  String get failureAShippedTemplateNamesAnUnknownRecord =>
      _catalog.failureAShippedTemplateNamesAnUnknownRecord;

  /// Operator-facing failure retained through headless execution.
  String get failureTheTemplateOrItsRecordsChangedWhile =>
      _catalog.failureTheTemplateOrItsRecordsChangedWhile;

  /// Operator-facing failure retained through headless execution.
  String get failureReviewTheUpdatedChangesAndTryAgain =>
      _catalog.failureReviewTheUpdatedChangesAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureAFieldNeedsAKey => _catalog.failureAFieldNeedsAKey;

  /// Operator-facing failure retained through headless execution.
  String get failureGiveEveryFieldAKeyAndSave =>
      _catalog.failureGiveEveryFieldAKeyAndSave;

  /// Operator-facing failure retained through headless execution.
  String get failureEachFieldKeyMustBeUniqueOn =>
      _catalog.failureEachFieldKeyMustBeUniqueOn;

  /// Operator-facing failure retained through headless execution.
  String get failureRenameTheDuplicateKeyAndSaveAgain =>
      _catalog.failureRenameTheDuplicateKeyAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueIsNotText => _catalog.failureThatValueIsNotText;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterTextOrLeaveTheFieldEmpty =>
      _catalog.failureEnterTextOrLeaveTheFieldEmpty;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueIsNotAWholeNumber =>
      _catalog.failureThatValueIsNotAWholeNumber;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterAWholeNumberOrLeaveThe =>
      _catalog.failureEnterAWholeNumberOrLeaveThe;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueIsNotANumber =>
      _catalog.failureThatValueIsNotANumber;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterANumberOrLeaveTheField =>
      _catalog.failureEnterANumberOrLeaveTheField;

  /// Operator-facing failure retained through headless execution.
  String get failureThatNumberIsOutsideTheAllowedRange =>
      _catalog.failureThatNumberIsOutsideTheAllowedRange;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterANumberInsideTheRangeOr =>
      _catalog.failureEnterANumberInsideTheRangeOr;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueIsShorterThanThisField =>
      _catalog.failureThatValueIsShorterThanThisField;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterALongerValueOrLeaveThe =>
      _catalog.failureEnterALongerValueOrLeaveThe;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueIsLongerThanThisField =>
      _catalog.failureThatValueIsLongerThanThisField;

  /// Operator-facing failure retained through headless execution.
  String get failureShortenTheValueOrLeaveTheField =>
      _catalog.failureShortenTheValueOrLeaveTheField;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueDoesNotMatchTheExpected =>
      _catalog.failureThatValueDoesNotMatchTheExpected;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterAValueInTheExpectedForm =>
      _catalog.failureEnterAValueInTheExpectedForm;

  /// Operator-facing failure retained through headless execution.
  String get failureThisFieldSPatternIsNotValid =>
      _catalog.failureThisFieldSPatternIsNotValid;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenTheTemplateAndCorrectTheField =>
      _catalog.failureOpenTheTemplateAndCorrectTheField;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueIsNotADate => _catalog.failureThatValueIsNotADate;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterACalendarDateOrLeaveThe =>
      _catalog.failureEnterACalendarDateOrLeaveThe;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueIsNotATimeOf =>
      _catalog.failureThatValueIsNotATimeOf;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterATimeOrLeaveTheField =>
      _catalog.failureEnterATimeOrLeaveTheField;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueIsNotADateAnd =>
      _catalog.failureThatValueIsNotADateAnd;

  /// Operator-facing failure retained through headless execution.
  String get failureEnterADateAndTimeOrLeave =>
      _catalog.failureEnterADateAndTimeOrLeave;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueIsNotAYesOr =>
      _catalog.failureThatValueIsNotAYesOr;

  /// Operator-facing failure retained through headless execution.
  String get failureSwitchTheFieldOnOrOffOr =>
      _catalog.failureSwitchTheFieldOnOrOffOr;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueIsNotAChoice =>
      _catalog.failureThatValueIsNotAChoice;

  /// Operator-facing failure retained through headless execution.
  String get failurePickAnOptionFromTheListOr =>
      _catalog.failurePickAnOptionFromTheListOr;

  /// Operator-facing failure retained through headless execution.
  String get failureThatChoiceIsNotOnTheList =>
      _catalog.failureThatChoiceIsNotOnTheList;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueIsNotAFilePath =>
      _catalog.failureThatValueIsNotAFilePath;

  /// Operator-facing failure retained through headless execution.
  String get failureAttachAFileOrLeaveTheField =>
      _catalog.failureAttachAFileOrLeaveTheField;

  /// Operator-facing failure retained through headless execution.
  String get failureThatValueIsNotALocation =>
      _catalog.failureThatValueIsNotALocation;

  /// Operator-facing failure retained through headless execution.
  String get failureCaptureAGPSFixOrLeaveThe =>
      _catalog.failureCaptureAGPSFixOrLeaveThe;

  /// Operator-facing failure retained through headless execution.
  String get failureThatLocationIsOutsideTheEarth =>
      _catalog.failureThatLocationIsOutsideTheEarth;

  /// Operator-facing failure retained through headless execution.
  String get failureCaptureAGPSFixAgainOrLeave =>
      _catalog.failureCaptureAGPSFixAgainOrLeave;

  /// Operator-facing failure retained through headless execution.
  String get failureThisFieldTypeHasNoEditorOn =>
      _catalog.failureThisFieldTypeHasNoEditorOn;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenTheTemplateAndPickAType =>
      _catalog.failureOpenTheTemplateAndPickAType;

  /// Operator-facing failure retained through headless execution.
  String get failureConfirmConsentWithTheNamedOperator =>
      _catalog.failureConfirmConsentWithTheNamedOperator;

  /// Operator-facing failure retained through headless execution.
  String get failureThatFieldTypeIsNotRecognised =>
      _catalog.failureThatFieldTypeIsNotRecognised;

  /// Operator-facing failure retained through headless execution.
  String get failurePickATypeFromTheListAnd =>
      _catalog.failurePickATypeFromTheListAnd;

  /// Operator-facing failure retained through headless execution.
  String get failureThatInputModeIsNotRecognised =>
      _catalog.failureThatInputModeIsNotRecognised;

  /// Operator-facing failure retained through headless execution.
  String get failurePickAnInputModeFromTheList =>
      _catalog.failurePickAnInputModeFromTheList;

  /// Operator-facing failure retained through headless execution.
  String get failureTheSuggestedOrderCouldNotBeRead =>
      _catalog.failureTheSuggestedOrderCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  String get failureUseTheOnDeviceResultsOrTry =>
      _catalog.failureUseTheOnDeviceResultsOrTry;

  /// Operator-facing failure retained through headless execution.
  String get failureOpenTheTemplateListAndTryAgain =>
      _catalog.failureOpenTheTemplateListAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  String get failureTheDailyAnalysisLimitIsReached =>
      _catalog.failureTheDailyAnalysisLimitIsReached;

  /// Operator-facing failure retained through headless execution.
  String get failureUseTheOnDeviceSuggestionsOrTry =>
      _catalog.failureUseTheOnDeviceSuggestionsOrTry;

  /// Operator-facing failure retained through headless execution.
  String get failureExportProtectionsAreUnavailableOnThisDevice =>
      _catalog.failureExportProtectionsAreUnavailableOnThisDevice;

  /// Operator-facing status for processingDailyCap.
  String processingDailyCap(int cap, String resetDay) =>
      _catalog.processingDailyCap(cap, resetDay);

  /// Operator-facing status for processingDailyResetRecovery.
  String get processingDailyResetRecovery =>
      _catalog.processingDailyResetRecovery;

  /// Operator-facing status for bundlePasswordInvalid.
  String get bundlePasswordInvalid => _catalog.bundlePasswordInvalid;

  /// Operator-facing status for bundlePasswordInvalidRecovery.
  String get bundlePasswordInvalidRecovery =>
      _catalog.bundlePasswordInvalidRecovery;

  /// Operator-facing status for incomingBundleBusy.
  String get incomingBundleBusy => _catalog.incomingBundleBusy;

  /// Operator-facing status for incomingBundleTooLarge.
  String get incomingBundleTooLarge => _catalog.incomingBundleTooLarge;

  /// Operator-facing status for incomingBundleIncomplete.
  String get incomingBundleIncomplete => _catalog.incomingBundleIncomplete;

  /// Operator-facing status for incomingBundleUnreadable.
  String get incomingBundleUnreadable => _catalog.incomingBundleUnreadable;

  /// Operator-facing status for incomingBundleUnreadableRecovery.
  String get incomingBundleUnreadableRecovery =>
      _catalog.incomingBundleUnreadableRecovery;

  /// Operator-facing status for biometricUnavailable.
  String get biometricUnavailable => _catalog.biometricUnavailable;

  /// Operator-facing status for biometricPinRecovery.
  String get biometricPinRecovery => _catalog.biometricPinRecovery;

  /// Operator-facing status for appLockStorageUnavailable.
  String get appLockStorageUnavailable => _catalog.appLockStorageUnavailable;

  /// Operator-facing status for appLockStorageRecovery.
  String get appLockStorageRecovery => _catalog.appLockStorageRecovery;

  /// The destination could not be saved.
  String get cloudDestinationSaveFailed => _catalog.cloudDestinationSaveFailed;

  /// That destination is no longer listed.
  String get cloudDestinationMissing => _catalog.cloudDestinationMissing;

  /// Refresh the list.
  String get cloudRefreshDestinations => _catalog.cloudRefreshDestinations;

  /// The upload could not be recorded.
  String get cloudUploadRecordFailed => _catalog.cloudUploadRecordFailed;

  /// The upload history could not be updated.
  String get cloudUploadHistoryUpdateFailed =>
      _catalog.cloudUploadHistoryUpdateFailed;

  /// The file on this device was not changed.
  String get cloudUploadHistoryUpdateRecovery =>
      _catalog.cloudUploadHistoryUpdateRecovery;

  /// Confirm this upload before it can start.
  String get cloudUploadConfirmationRequired =>
      _catalog.cloudUploadConfirmationRequired;

  /// Review the file and confirm it.
  String get cloudUploadConfirmationRecovery =>
      _catalog.cloudUploadConfirmationRecovery;

  /// That upload is no longer in the history.
  String get cloudUploadHistoryMissing => _catalog.cloudUploadHistoryMissing;

  /// Start the upload again.
  String get cloudUploadRestartRecovery => _catalog.cloudUploadRestartRecovery;

  /// That preference cannot be stored.
  String get settingsPreferenceUnsupported =>
      _catalog.settingsPreferenceUnsupported;

  /// Choose a supported value and save again.
  String get settingsPreferenceUnsupportedRecovery =>
      _catalog.settingsPreferenceUnsupportedRecovery;

  /// The preference could not be saved on this device.
  String get settingsPreferenceSaveFailed =>
      _catalog.settingsPreferenceSaveFailed;

  /// Try again. Your last change was not stored.
  String get settingsPreferenceSaveRecovery =>
      _catalog.settingsPreferenceSaveRecovery;

  /// The saved capture could not be read.
  String get privacyCaptureUnreadable => _catalog.privacyCaptureUnreadable;

  /// Recover the capture and try again.
  String get privacyCaptureRecover => _catalog.privacyCaptureRecover;

  /// Open a project before removing its location data.
  String get privacyProjectRequired => _catalog.privacyProjectRequired;

  /// Choose a project, then try again.
  String get privacyProjectRequiredRecovery =>
      _catalog.privacyProjectRequiredRecovery;

  /// This destination sign-in changed.
  String get cloudSignInChanged => _catalog.cloudSignInChanged;

  /// This Google Drive sign-in needs renewal.
  String get cloudGoogleSignInRenewal => _catalog.cloudGoogleSignInRenewal;

  /// Sign in again.
  String get cloudSignInAgain => _catalog.cloudSignInAgain;
}
