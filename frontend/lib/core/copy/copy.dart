import 'package:flutter/widgets.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'copy_messages.g.dart';
import 'l10n/app_localizations.g.dart';
import 'l10n/app_localizations_en.g.dart';
import 'localized_copy.dart';
export 'localized_copy.dart';
export 'localized_copy_resolver.g.dart';
export 'localized_message.dart';

/// Compatibility copy for services without a widget context, in English.
/// Widgets resolve their own inherited locale through [of].
abstract final class Copy {
  /// Serializable messages for services and state without a widget context.
  static const CopyMessages messages = CopyMessages();

  static final LocalizedCopy _english = LocalizedCopy(AppLocalizationsEn());

  /// Stable fallback for background services and optional presentation helpers.
  static LocalizedCopy get english => _english;

  /// Resolves copy from the calling app without a shared mutable locale.
  static LocalizedCopy of(BuildContext context) {
    final AppLocalizations? catalog = AppLocalizations.of(context);
    return catalog == null ? _english : LocalizedCopy(catalog);
  }

  /// Local image recognition has no browser implementation.
  static String get ocrBrowserUnavailable => _english.ocrBrowserUnavailable;

  /// Stated absence when a value was not found.
  static String get notDetected => _english.notDetected;

  /// How many records a list holds. Zero is a stated absence, not a blank.
  static String recordsCount(int n) => _english.recordsCount(n);

  /// How many fields a template holds. Zero is a stated absence, not a blank.
  static String fieldsCount(int n) => _english.fieldsCount(n);

  /// Clears the named field.
  static String clearField(String label) => _english.clearField(label);

  /// Reveals a hidden field such as a PIN, named for its label.
  static String showField(String label) => _english.showField(label);

  /// Hides a revealed field again, named for its label.
  static String hideField(String label) => _english.hideField(label);

  /// The camera or photo library was refused.
  static String get photoNoAccess => _english.photoNoAccess;

  /// The browser display picker was refused.
  static String get displayNoAccess => _english.displayNoAccess;

  /// The device has no camera the app can open.
  static String get photoNoCamera => _english.photoNoCamera;

  /// The picker failed for a reason it did not name.
  static String get photoPickFailed => _english.photoPickFailed;

  /// The display picker failed for a reason it did not name.
  static String get displayCaptureFailed => _english.displayCaptureFailed;

  /// Starts dictation into a field, named for its label.
  static String dictateInto(String label) => _english.dictateInto(label);

  /// Stops dictation into a field, named for its label.
  static String stopDictating(String label) => _english.stopDictating(label);

  /// The platform has no recogniser this app can reach.
  static String get dictationUnavailable => _english.dictationUnavailable;

  /// The microphone was refused.
  static String get dictationNoMicrophone => _english.dictationNoMicrophone;

  /// The recogniser heard nothing it could use.
  static String get dictationNothingHeard => _english.dictationNothingHeard;

  /// The recogniser needs a connection it does not have.
  static String get dictationNeedsConnection =>
      _english.dictationNeedsConnection;

  /// Offline by choice, and this device cannot recognise speech locally.
  static String get dictationOfflineOnly => _english.dictationOfflineOnly;

  /// The recogniser stopped for a reason it did not name.
  static String get dictationFailed => _english.dictationFailed;

  /// The on-device speech engine is missing or could not start.
  static String get speechUnavailable => _english.speechUnavailable;

  /// The on-device speech model file is absent.
  static String get speechModelMissing => _english.speechModelMissing;

  /// What to do when the on-device speech model is absent.
  static String get speechModelMissingRecovery =>
      _english.speechModelMissingRecovery;

  /// The on-device speech model failed its size, header or checksum check.
  static String get speechModelDamaged => _english.speechModelDamaged;

  /// What to do when the on-device speech model is damaged.
  static String get speechModelDamagedRecovery =>
      _english.speechModelDamagedRecovery;

  /// The processor, memory or browser cannot run the on-device speech engine.
  static String get speechDeviceUnsupported => _english.speechDeviceUnsupported;

  /// The on-device speech model could not be loaded for lack of memory.
  static String get speechLowMemory => _english.speechLowMemory;

  /// What to do when memory is too low for the on-device speech model.
  static String get speechLowMemoryRecovery => _english.speechLowMemoryRecovery;

  /// The on-device speech engine failed on one stretch of audio.
  static String get speechTranscriptionFailed =>
      _english.speechTranscriptionFailed;

  /// The voice language has no on-device speech model.
  static String get speechLanguageUnsupported =>
      _english.speechLanguageUnsupported;

  /// The on-device speech engine stopped or was closed mid-task.
  static String get speechEngineStopped => _english.speechEngineStopped;

  /// An imported file matches no known speech model.
  static String get speechImportUnknown => _english.speechImportUnknown;

  /// What to do when an imported file is not a known speech model.
  static String get speechImportUnknownRecovery =>
      _english.speechImportUnknownRecovery;

  /// A value filled in rather than typed.
  static String get autoFilled => _english.autoFilled;

  /// A number outside the allowed range.
  static String get outOfRange => _english.outOfRange;

  /// Selects every visible option in a multi-choice sheet.
  static String get selectAll => _english.selectAll;

  /// Clears a selection or a field.
  static String get clear => _english.clear;

  /// Dismisses the named chip.
  static String dismissChip(String label) => _english.dismissChip(label);

  /// Dismisses a banner or other unnamed surface.
  static String get dismiss => _english.dismiss;

  /// Backs out of a confirm dialog.
  static String get cancel => _english.cancel;

  /// Acknowledges an alert.
  static String get ok => _english.ok;

  /// Title of the unsaved-changes confirm.
  static String get discardChangesTitle => _english.discardChangesTitle;

  /// Body of the unsaved-changes confirm.
  static String get unsavedChanges => _english.unsavedChanges;

  /// Confirms discarding unsaved edits.
  static String get discard => _english.discard;

  /// Heading over a list of invalid fields.
  static String fixFields(int n) => _english.fixFields(n);

  /// One invalid field in a validation summary. [label] is template content.
  static String fieldError(String label, String error) =>
      _english.fieldError(label, error);

  /// Label of a field that must be filled before Save.
  static String fieldLabelRequired(String label) =>
      _english.fieldLabelRequired(label);

  /// Label of a field that may be left empty.
  static String fieldLabelOptional(String label) =>
      _english.fieldLabelOptional(label);

  /// Announced summary of invalid fields.
  static String validationAnnouncement(String heading, List<String> errors) =>
      _english.validationAnnouncement(heading, errors);

  /// Placeholder when a cached thumb file is missing.
  static String get missingPhoto => _english.missingPhoto;

  /// Semantic name of a thumbnail's selection checkbox.
  static String get photoSelect => _english.photoSelect;

  /// A stored photo's file could not be read for its thumbnail.
  static String get photoUnreadable => _english.photoUnreadable;

  /// Recovery for [photoUnreadable].
  static String get photoUnreadableRecovery => _english.photoUnreadableRecovery;

  /// Semantic name of a missing thumb, including its type.
  static String missingPhotoNamed(String type) =>
      _english.missingPhotoNamed(type);

  /// Fallback type name when a photo has none.
  static String get photo => _english.photo;

  /// Crop action on the photo viewer.
  static String get photoCrop => _english.photoCrop;

  /// Semantic name of a crop frame corner handle.
  static String get photoCropCorner => _english.photoCropCorner;

  /// Semantic name of the crop frame body.
  static String get photoCropFrame => _english.photoCropFrame;

  /// Rotate the visible photo a quarter turn.
  static String get photoRotate => _english.photoRotate;

  /// Open freehand drawing.
  static String get photoDraw => _english.photoDraw;

  /// Remove the latest stroke.
  static String get photoUndoDraw => _english.photoUndoDraw;

  /// Remove every stroke.
  static String get photoClearDraw => _english.photoClearDraw;

  /// Name of a markup ink, read beside its swatch (FE-A11Y-05).
  static String markupInk(MarkupInk ink) => _english.markupInk(ink);

  /// Label of the markup ink swatches.
  static String get markupInkLabel => _english.markupInkLabel;

  /// Label of the markup size choice.
  static String get markupSize => _english.markupSize;

  /// Switches the dark backing behind typed text on a photo.
  static String get markupBacking => _english.markupBacking;

  /// What the dark backing does.
  static String get markupBackingDescription =>
      _english.markupBackingDescription;

  /// How to place typed text on a photo.
  static String get markupTypeHint => _english.markupTypeHint;

  /// The thinnest stroke or smallest text.
  static String get markupSizeSmall => _english.markupSizeSmall;

  /// The middle stroke or text size.
  static String get markupSizeMedium => _english.markupSizeMedium;

  /// The thickest stroke or largest text.
  static String get markupSizeLarge => _english.markupSizeLarge;

  /// How many photos are in the tray.
  static String capturePhotoCount(int count) =>
      _english.capturePhotoCount(count);

  /// Badge while a photo is still being prepared.
  static String get capturePhotoProcessing => _english.capturePhotoProcessing;

  /// Clears a derived crop or typed copy.
  static String get photoRevert => _english.photoRevert;

  /// The preview's caption line when a photo has none.
  static String get photoNoCaption => _english.photoNoCaption;

  /// Opens the caption editor in the photo preview.
  static String get photoCaptionEdit => _english.photoCaptionEdit;

  /// Removes a photo's caption in the preview.
  static String get photoCaptionDelete => _english.photoCaptionDelete;

  /// What deleting a caption does.
  static String get photoCaptionDeleteMessage =>
      _english.photoCaptionDeleteMessage;

  /// Confirms a caption was removed, beside Undo.
  static String get photoCaptionDeleted => _english.photoCaptionDeleted;

  /// Types words onto a derived copy of a photo.
  static String get photoTypeOn => _english.photoTypeOn;

  /// Semantic name of a thumb: type, missing, caption and selection.
  static String photoThumbLabel({
    required String type,
    required bool missing,
    required bool captioned,
    required bool selected,
  }) => _english.photoThumbLabel(
    type: type,
    missing: missing,
    captioned: captioned,
    selected: selected,
  );

  /// Facing the subject.
  static String get photoFront => _english.photoFront;

  /// Reverse of the subject.
  static String get photoBack => _english.photoBack;

  /// Serial number plate or stamp.
  static String get photoSerial => _english.photoSerial;

  /// Manufacturer rating plate.
  static String get photoRatingPlate => _english.photoRatingPlate;

  /// Short overlay for a rating plate.
  static String get photoRatingPlateBadge => _english.photoRatingPlateBadge;

  /// Visible damage.
  static String get photoDamage => _english.photoDamage;

  /// Control or breaker panel.
  static String get photoPanel => _english.photoPanel;

  /// Site or room context.
  static String get photoLocation => _english.photoLocation;

  /// People present at a meeting.
  static String get photoAttendance => _english.photoAttendance;

  /// Short overlay for attendance.
  static String get photoAttendanceBadge => _english.photoAttendanceBadge;

  /// A page or scanned document.
  static String get photoDocument => _english.photoDocument;

  /// Short overlay for a document.
  static String get photoDocumentBadge => _english.photoDocumentBadge;

  /// Any other photo type.
  static String get photoOther => _english.photoOther;

  /// A progress step that finished.
  static String get stepDone => _english.stepDone;

  /// A progress step that is in progress.
  static String get stepRunning => _english.stepRunning;

  /// A progress step that has not started.
  static String get stepWaiting => _english.stepWaiting;

  /// A failed step or record.
  static String get failed => _english.failed;

  /// Announced name of a progress row.
  static String progressAnnouncement({
    required String label,
    required String state,
    String? detail,
  }) =>
      _english.progressAnnouncement(label: label, state: state, detail: detail);

  /// Saved locally, not yet captured.
  static String get statusDraft => _english.statusDraft;

  /// Evidence is on the record.
  static String get statusCaptured => _english.statusCaptured;

  /// Waiting for processing.
  static String get statusQueued => _english.statusQueued;

  /// A processing job is running.
  static String get statusProcessing => _english.statusProcessing;

  /// Extraction finished.
  static String get statusExtracted => _english.statusExtracted;

  /// A person must look at this record.
  static String get statusNeedsReview => _english.statusNeedsReview;

  /// A person has accepted the record.
  static String get statusApproved => _english.statusApproved;

  /// Kept for history.
  static String get statusArchived => _english.statusArchived;

  /// Marked gone.
  static String get statusDeleted => _english.statusDeleted;

  /// Headline when a list has nothing to show.
  static String get emptyHeadline => _english.emptyHeadline;

  /// Body when a list has nothing to show.
  static String get emptyMessage => _english.emptyMessage;

  /// A control or page that is still working.
  static String get loading => _english.loading;

  /// Busy adverb on an action that is still running.
  static String get busy => _english.busy;

  /// Named action that is still running.
  static String busyAction(String label) => _english.busyAction(label);

  /// Retries a failed load.
  static String get tryAgain => _english.tryAgain;

  /// Persists the current form or record.
  static String get save => _english.save;

  /// Reverses the last destructive action.
  static String get undo => _english.undo;

  /// Developer gallery title.
  static String get galleryTitle => _english.galleryTitle;

  /// Theme-mode switcher.
  static String get galleryTheme => _english.galleryTheme;

  /// Simulated-width switcher.
  static String get galleryWidth => _english.galleryWidth;

  /// Text-scale switcher.
  static String get galleryTextScale => _english.galleryTextScale;

  /// Token family heading.
  static String get galleryTokens => _english.galleryTokens;

  /// Layout family heading.
  static String get galleryLayout => _english.galleryLayout;

  /// Button family heading.
  static String get galleryButtons => _english.galleryButtons;

  /// Field family heading.
  static String get galleryFields => _english.galleryFields;

  /// Container family heading.
  static String get galleryContainers => _english.galleryContainers;

  /// State family heading.
  static String get galleryStates => _english.galleryStates;

  /// Feedback family heading.
  static String get galleryFeedback => _english.galleryFeedback;

  /// Light appearance.
  static String get galleryLight => _english.galleryLight;

  /// Dark appearance.
  static String get galleryDark => _english.galleryDark;

  /// Outdoor appearance.
  static String get galleryOutdoor => _english.galleryOutdoor;

  /// Compact width.
  static String get galleryCompact => _english.galleryCompact;

  /// Medium width.
  static String get galleryMedium => _english.galleryMedium;

  /// Expanded width.
  static String get galleryExpanded => _english.galleryExpanded;

  /// Default text scale.
  static String get galleryScale100 => _english.galleryScale100;

  /// Double text scale.
  static String get galleryScale200 => _english.galleryScale200;

  /// Product name in chrome and the system window.
  static String get appName => _english.appName;

  /// Prompt on list-pane and picker search fields.
  static String get search => _english.search;

  /// What to change when a search matches nothing.
  static String get searchNoMatchMessage => _english.searchNoMatchMessage;

  /// The filter button on a search field, with how many filters are on.
  static String searchFilters(int active) => _english.searchFilters(active);

  /// Turns every filter of a list off.
  static String get searchClearFilters => _english.searchClearFilters;

  /// What to change when a search and its filters match nothing.
  static String get searchFilterNoMatchMessage =>
      _english.searchFilterNoMatchMessage;

  /// Semantic name of the title-bar overflow control.
  static String get overflowMenu => _english.overflowMenu;

  /// Shell destination: the project list.
  static String get navProjects => _english.navProjects;

  /// Headline when the project list has nothing to show.
  static String get projectsEmptyHeadline => _english.projectsEmptyHeadline;

  /// Body when the project list has nothing to show.
  static String get projectsEmptyMessage => _english.projectsEmptyMessage;

  /// Primary empty-state action on the project list.
  static String get projectsCreate => _english.projectsCreate;

  /// Headline when a wide layout has projects but none is open.
  static String get projectsPickHeadline => _english.projectsPickHeadline;

  /// Body when a wide layout has projects but none is open.
  static String get projectsPickMessage => _english.projectsPickMessage;

  /// Headline when the project search matches nothing.
  static String get projectsNoMatchHeadline => _english.projectsNoMatchHeadline;

  /// Body when the project search matches nothing.
  static String get projectsNoMatchMessage => _english.projectsNoMatchMessage;

  /// Search prompt for names, descriptions, and organisations.
  static String get projectSearchHint => _english.projectSearchHint;

  /// Secondary filter-sheet title.
  static String get projectFiltersTitle => _english.projectFiltersTitle;

  /// Status filter heading.
  static String get projectStatusFilter => _english.projectStatusFilter;

  /// Pin-state filter heading.
  static String get projectPinFilter => _english.projectPinFilter;

  /// Human label for a pin filter wire name.
  static String projectPinFilterLabel(String value) =>
      _english.projectPinFilterLabel(value);

  /// Commits project filter choices.
  static String get projectApplyFilters => _english.projectApplyFilters;

  /// Semantic status for a project that stays at the top of the list.
  static String get pinnedProject => _english.pinnedProject;

  /// Project-home template association count.
  static String projectTemplateCount(int count) =>
      _english.projectTemplateCount(count);

  /// The Projects list's one Import control (task 020): it opens the import
  /// page, which takes a bundle, a spreadsheet, a dataset or a template.
  static String get projectsImport => _english.projectsImport;

  /// Duplicate action that opens the create form from an existing project.
  static String get projectsDuplicate => _english.projectsDuplicate;

  /// Overflow command that returns to the project list from a project home.
  static String get projectAllProjects => _english.projectAllProjects;

  /// Overflow command that opens the create form from a project home.
  static String get projectNew => _english.projectNew;

  /// Hides a finished project from the active list.
  static String get projectArchive => _english.projectArchive;

  /// Restores an archived project to the active list.
  static String get projectUnarchive => _english.projectUnarchive;

  /// Soft-deletes a project after typed confirmation.
  static String get projectDelete => _english.projectDelete;

  /// Row menu label. The confirm dialog keeps [projectDelete].
  static String get projectDeleteMenu => _english.projectDeleteMenu;

  /// Title of the delete confirmation, naming the project.
  static String projectDeleteTitle(String name) =>
      _english.projectDeleteTitle(name);

  /// Body of the delete confirmation, naming counts and retention.
  static String projectDeleteMessage({
    required int records,
    required int files,
    required int days,
  }) =>
      _english.projectDeleteMessage(records: records, files: files, days: days);

  /// How many files a delete would hide.
  static String filesCount(int n) => _english.filesCount(n);

  /// Typed-name field on the delete confirmation.
  static String get projectDeleteTypeName => _english.projectDeleteTypeName;

  /// Alternative on the delete confirmation: export before deleting.
  static String get projectExportFirst => _english.projectExportFirst;

  /// Filter that reveals archived projects on the landing list.
  static String get projectShowArchived => _english.projectShowArchived;

  /// Pins a project to the top of the list.
  static String get projectPin => _english.projectPin;

  /// Removes a project from the top of the list.
  static String get projectUnpin => _english.projectUnpin;

  /// Opens the rename dialog for a project.
  static String get projectRename => _english.projectRename;

  /// Title of the rename dialog.
  static String get projectRenameTitle => _english.projectRenameTitle;

  /// Body of the rename dialog. The folder on disk stays put.
  static String get projectRenameMessage => _english.projectRenameMessage;

  /// Hands a copy of a project file to another app.
  static String get projectOpenWith => _english.projectOpenWith;

  /// Saves a copy of a project file on the web, where no app can be launched.
  static String get projectDownloadCopy => _english.projectDownloadCopy;

  /// Shown when Open with is asked for a project that has no file.
  static String get projectNothingToOpen => _english.projectNothingToOpen;

  /// What to do when there is nothing to open.
  static String get projectNothingToOpenRecovery =>
      _english.projectNothingToOpenRecovery;

  /// Title when the hand-off to another app failed.
  static String get projectOpenFailedTitle => _english.projectOpenFailedTitle;

  /// Body when the hand-off failed.
  static String get projectOpenFailed => _english.projectOpenFailed;

  /// Body when the named file could not be handed off.
  static String projectOpenFailedNamed(String fileName) =>
      _english.projectOpenFailedNamed(fileName);

  /// Recovery when the hand-off failed.
  static String get projectOpenFailedRecovery =>
      _english.projectOpenFailedRecovery;

  /// When no installed app can open the file type.
  static String get projectOpenNoApp => _english.projectOpenNoApp;

  /// Recovery when no reader is installed.
  static String get projectOpenNoAppRecovery =>
      _english.projectOpenNoAppRecovery;

  /// When storage permission was refused before writing the copy.
  static String get projectOpenPermission => _english.projectOpenPermission;

  /// Recovery when storage permission was refused.
  static String get projectOpenPermissionRecovery =>
      _english.projectOpenPermissionRecovery;

  /// Visible position of a project in the current list.
  static String projectListNumber(int n) => _english.projectListNumber(n);

  /// Title of the create-project form.
  static String get projectCreateTitle => _english.projectCreateTitle;

  /// Title of the create form when it is copying another project.
  static String get projectDuplicateTitle => _english.projectDuplicateTitle;

  /// Required name field on the create form.
  static String get projectName => _english.projectName;

  /// Optional longer note on the create form.
  static String get projectDescription => _english.projectDescription;

  /// Optional organisation field on the create form.
  static String get projectOrganisation => _english.projectOrganisation;

  /// Title of the read-only project page, and the menu item that opens it.
  static String get projectEditTitle => _english.projectEditTitle;

  /// Title of the form that changes a project's details.
  static String get projectEditFormTitle => _english.projectEditFormTitle;

  /// Primary action on the project details page.
  static String get projectEditDetails => _english.projectEditDetails;

  /// A project detail nobody has filled in.
  static String get projectValueNotSet => _english.projectValueNotSet;

  /// When the project was created, on its details page.
  static String get projectCreatedAt => _english.projectCreatedAt;

  /// When the project last changed, on its details page.
  static String get projectUpdatedAt => _english.projectUpdatedAt;

  /// Heading over the template whose fields the context levels come from.
  static String get contextLevelSource => _english.contextLevelSource;

  /// Title of the per-project settings form.
  static String get projectSettingsTitle => _english.projectSettingsTitle;

  /// Confirms that the project details form was stored.
  static String get projectSaved => _english.projectSaved;

  /// Confirms that the project settings form was stored.
  static String get projectSettingsSaved => _english.projectSettingsSaved;

  /// When fieldwork started.
  static String get projectStartsOn => _english.projectStartsOn;

  /// When fieldwork finished.
  static String get projectEndsOn => _english.projectEndsOn;

  /// Open or archived status on the details form.
  static String get projectStatus => _english.projectStatus;

  /// Status choice: the project is open.
  static String get projectStatusActive => _english.projectStatusActive;

  /// Status choice: the project is archived.
  static String get projectStatusArchived => _english.projectStatusArchived;

  /// AI override on the project settings form.
  static String get projectAiEnabled => _english.projectAiEnabled;

  /// What turning AI off does.
  static String get projectAiEnabledEffect => _english.projectAiEnabledEffect;

  /// Image-egress override on the project settings form.
  static String get projectDoNotSendImages => _english.projectDoNotSendImages;

  /// What turning image egress off does.
  static String get projectDoNotSendImagesEffect =>
      _english.projectDoNotSendImagesEffect;

  /// Refined-columns override on the project settings form.
  static String get projectRefineColumns => _english.projectRefineColumns;

  /// High-confidence threshold on the project settings form.
  static String get projectConfidenceHigh => _english.projectConfidenceHigh;

  /// Medium-confidence threshold on the project settings form.
  static String get projectConfidenceMedium => _english.projectConfidenceMedium;

  /// Inherit the app-level value for this switch.
  static String get projectUseAppDefault => _english.projectUseAppDefault;

  /// Affirmative override on a three-way choice.
  static String get projectOn => _english.projectOn;

  /// Negative override on a three-way choice.
  static String get projectOff => _english.projectOff;

  /// Names the app-level value a row is changing.
  static String projectAppDefault(String value) =>
      _english.projectAppDefault(value);

  /// Headline when the details form has no open project.
  static String get projectEditEmptyHeadline =>
      _english.projectEditEmptyHeadline;

  /// Body when the details form has no open project.
  static String get projectEditEmptyMessage => _english.projectEditEmptyMessage;

  /// Headline when the settings form has no open project.
  static String get projectSettingsEmptyHeadline =>
      _english.projectSettingsEmptyHeadline;

  /// Body when the settings form has no open project.
  static String get projectSettingsEmptyMessage =>
      _english.projectSettingsEmptyMessage;

  /// Suggested name for a duplicated project, editable before commit.
  static String projectCopyName(String name) => _english.projectCopyName(name);

  /// Counts and unprocessed records on one project list row.
  static String projectListSubtitle({
    required int records,
    required int unprocessed,
  }) =>
      _english.projectListSubtitle(records: records, unprocessed: unprocessed);

  /// Position of one captured record on the project list.
  static String projectRecordPosition(int position) =>
      _english.projectRecordPosition(position);

  /// Empty project records list.
  static String get projectRecordsEmptyHeadline =>
      _english.projectRecordsEmptyHeadline;

  /// Explains an empty project records filter.
  static String get projectRecordsEmptyMessage =>
      _english.projectRecordsEmptyMessage;

  /// Prompt on the project home search: what it looks through.
  static String get projectRecordsSearchHint =>
      _english.projectRecordsSearchHint;

  /// Title of a project's records filter sheet.
  static String get projectRecordFiltersTitle =>
      _english.projectRecordFiltersTitle;

  /// The record-status facet of a project's records filters.
  static String get projectRecordStatusFilter =>
      _english.projectRecordStatusFilter;

  /// A project home search that matched no record, naming the query.
  static String projectRecordsNoMatch(String query) =>
      _english.projectRecordsNoMatch(query);

  /// A choice sheet search that matched no option, naming the query.
  static String choiceNoMatch(String query) => _english.choiceNoMatch(query);

  /// Overflow command that writes a project export.
  static String get projectExport => _english.projectExport;

  /// Title of the project export screen.
  static String get projectExportTitle => _english.projectExportTitle;

  /// Empty export screen.
  static String get projectExportEmptyHeadline =>
      _english.projectExportEmptyHeadline;

  /// Explains that a project needs a record before export.
  static String get projectExportEmptyMessage =>
      _english.projectExportEmptyMessage;

  /// Shares a finished export.
  static String get projectExportShare => _english.projectExportShare;

  /// Names the file that was stored.
  static String projectExportSaved(String fileName) =>
      _english.projectExportSaved(fileName);

  /// Says the share sheet reaches other apps (Android and iOS).
  static String get projectExportShareHint => _english.projectExportShareHint;

  /// Export summary section: the project itself.
  static String get exportSectionProject => _english.exportSectionProject;

  /// Export summary section: records by status.
  static String get exportSectionRecords => _english.exportSectionRecords;

  /// Export summary section: records per template.
  static String get exportSectionTemplates => _english.exportSectionTemplates;

  /// Export summary section: the file the export writes.
  static String get exportSectionFile => _english.exportSectionFile;

  /// Audio clips filed on the exported records.
  static String exportAudioClips(int n) => _english.exportAudioClips(n);

  /// When the exported records were captured. [first] and [last] are
  /// locale-formatted dates; one date when they are the same day.
  static String exportCapturedBetween(String first, String last) =>
      _english.exportCapturedBetween(first, last);

  /// Exported records not processed yet.
  static String exportUnprocessedCount(int n) =>
      _english.exportUnprocessedCount(n);

  /// Exported records waiting for a person to review.
  static String exportNeedsReviewCount(int n) =>
      _english.exportNeedsReviewCount(n);

  /// Exported records already approved.
  static String exportApprovedCount(int n) => _english.exportApprovedCount(n);

  /// The export's file format.
  static String get exportFileFormat => _english.exportFileFormat;

  /// What the package holds, for another Tapture app and for a reader.
  static String get exportFileColumns => _english.exportFileColumns;

  /// How big the package is expected to be, before it is written.
  static String exportPackageSize(int bytes) =>
      _english.exportPackageSize(bytes);

  /// Where the export file is saved: the Exports folder under [place], the
  /// short Downloads label.
  static String exportSavedTo(String place) => _english.exportSavedTo(place);

  /// Shown while the workbook is written.
  static String get projectExportProgress => _english.projectExportProgress;

  /// Stops an export before a file is kept.
  static String get projectExportCancel => _english.projectExportCancel;

  /// Edits one captured record.
  static String get recordEdit => _english.recordEdit;

  /// Label of the optional project photo on the create and edit screens.
  static String get projectPhoto => _english.projectPhoto;

  /// Picks a photo for a project that has none.
  static String get projectPhotoAdd => _english.projectPhotoAdd;

  /// Picks another photo for a project that has one.
  static String get projectPhotoChange => _english.projectPhotoChange;

  /// Takes the photo off a project.
  static String get projectPhotoRemove => _english.projectPhotoRemove;

  /// Title of the page that edits a saved record's photos and captions.
  static String get recordEditTitle => _english.recordEditTitle;

  /// Saves an edited record's photos, captions and audio.
  static String get recordEditSave => _english.recordEditSave;

  /// Confirms an edited record was saved.
  static String get recordEditSaved => _english.recordEditSaved;

  /// Edit sheet for a record with nothing to edit.
  static String get recordEditNoFieldsHeadline =>
      _english.recordEditNoFieldsHeadline;

  /// What to do when a record has no editable field.
  static String get recordEditNoFieldsMessage =>
      _english.recordEditNoFieldsMessage;

  /// Archives one captured record. The photos stay on the device.
  static String get recordDelete => _english.recordDelete;

  /// Confirm copy for archiving a captured record.
  static String get recordArchiveMessage => _english.recordArchiveMessage;

  /// Title of a record's page when no value names it.
  static String get recordDetailTitle => _english.recordDetailTitle;

  /// A record with no caption, on its page.
  static String get recordNoCaption => _english.recordNoCaption;

  /// A template field the record holds no value for.
  static String get recordFieldEmpty => _english.recordFieldEmpty;

  /// Record page section: its field values.
  static String get recordSectionFields => _english.recordSectionFields;

  /// Opens the template-field editor from a record's page.
  static String get recordEditFields => _english.recordEditFields;

  /// When a record was captured. [when] is a locale-formatted date and time.
  static String recordCapturedAt(String when) =>
      _english.recordCapturedAt(when);

  /// A record's page after it was deleted elsewhere.
  static String get recordGoneHeadline => _english.recordGoneHeadline;

  /// What to do when a record's page has nothing to show.
  static String get recordGoneMessage => _english.recordGoneMessage;

  /// Primary action on the open-project home when a record already exists.
  static String get continueCapturing => _english.continueCapturing;

  /// Home primary action before the first record.
  static String get captureStart => _english.captureStart;

  /// Home primary action after at least one record.
  static String get captureMore => _english.captureMore;

  /// Headline when the project home has no open project.
  static String get homeEmptyHeadline => _english.homeEmptyHeadline;

  /// Body when the project home has no open project.
  static String get homeEmptyMessage => _english.homeEmptyMessage;

  /// Shell destination: capture. Visually dominant in the four-destination bar.
  static String get navCapture => _english.navCapture;

  /// Shell destination: the records list.
  static String get navRecords => _english.navRecords;

  /// Shell destination: settings and the rest.
  static String get navMore => _english.navMore;

  /// Compact navigation control opening secondary destinations.
  static String get navMoreMenu => _english.navMoreMenu;

  /// Pinned-template destination the status line opens.
  static String get navTemplates => _english.navTemplates;

  /// Project-scoped template list. The app-wide list keeps [navTemplates].
  static String get projectTemplatesTitle => _english.projectTemplatesTitle;

  /// Project datasets destination.
  static String get navDatasets => _english.navDatasets;

  /// Headline when a project has no reference datasets.
  static String get datasetsEmptyHeadline => _english.datasetsEmptyHeadline;

  /// Body when the dataset list is empty.
  static String get datasetsEmptyMessage => _english.datasetsEmptyMessage;

  /// Empty-state / primary action that starts an import.
  static String get datasetsImport => _english.datasetsImport;

  /// Title of the key-column confirmation screen.
  static String get datasetsKeyTitle => _english.datasetsKeyTitle;

  /// Explains the key-column choice.
  static String get datasetsKeyMessage => _english.datasetsKeyMessage;

  /// Confirms saving despite duplicate keys.
  static String get datasetsAllowDuplicates => _english.datasetsAllowDuplicates;

  /// Saves the import after a unique key is chosen.
  static String get datasetsSaveImport => _english.datasetsSaveImport;

  /// Duplicate-key warning with count.
  static String datasetsDuplicateCount(int n) =>
      _english.datasetsDuplicateCount(n);

  /// Sample colliding values.
  static String datasetsCollidingValues(List<String> values) =>
      _english.datasetsCollidingValues(values);

  /// List subtitle: rows · source · date. [importedAt] is shown in local time.
  static String datasetListSubtitle({
    required int rows,
    required String source,
    required DateTime importedAt,
  }) => _english.datasetListSubtitle(
    rows: rows,
    source: source,
    importedAt: importedAt,
  );

  /// How many rows a dataset holds.
  static String datasetsRowCount(int n) => _english.datasetsRowCount(n);

  /// Dataset source label.
  static String datasetSourceLabel(String source) =>
      _english.datasetSourceLabel(source);

  /// Browser search hint.
  static String get datasetsSearchHint => _english.datasetsSearchHint;

  /// Choose visible columns on a narrow screen.
  static String get datasetsColumns => _english.datasetsColumns;

  /// Row edit title.
  static String get datasetsEditRow => _english.datasetsEditRow;

  /// Save row edits.
  static String get datasetsSaveRow => _english.datasetsSaveRow;

  /// Add-row sheet title.
  static String get datasetsAddRow => _english.datasetsAddRow;

  /// Lookup picker title.
  static String get datasetsPickMatch => _english.datasetsPickMatch;

  /// Lookup binding screen title.
  static String get datasetsLookupBinding => _english.datasetsLookupBinding;

  /// Save lookup binding.
  static String get datasetsSaveBinding => _english.datasetsSaveBinding;

  /// No datasets available for binding.
  static String get datasetsBindingEmptyHeadline =>
      _english.datasetsBindingEmptyHeadline;

  /// Binding empty body.
  static String get datasetsBindingEmptyMessage =>
      _english.datasetsBindingEmptyMessage;

  /// Fuzzy matching switch.
  static String get datasetsFuzzyEnabled => _english.datasetsFuzzyEnabled;

  /// No-match behaviour label.
  static String get datasetsOnNoMatch => _english.datasetsOnNoMatch;

  /// Mark a row added on device in the browser.
  static String get datasetsAddedOnDevice => _english.datasetsAddedOnDevice;

  /// Export dataset action.
  static String get datasetsExport => _english.datasetsExport;

  /// Headline when the dataset browser has no rows.
  static String get datasetsBrowserEmptyHeadline =>
      _english.datasetsBrowserEmptyHeadline;

  /// Body when the dataset browser has no rows.
  static String get datasetsBrowserEmptyMessage =>
      _english.datasetsBrowserEmptyMessage;

  /// Headline when a dataset search or lookup matches no row.
  static String get datasetsNoMatchHeadline => _english.datasetsNoMatchHeadline;

  /// Body when a dataset search matches no row.
  static String get datasetsNoMatchMessage => _english.datasetsNoMatchMessage;

  /// Body when a lookup finds no row to pick.
  static String get datasetsPickNoMatchMessage =>
      _english.datasetsPickNoMatchMessage;

  /// Picker row: the columns that tell matching rows apart, as
  /// `column: value` pairs.
  static String datasetsPickerSubtitle(Map<String, String> cells) =>
      _english.datasetsPickerSubtitle(cells);

  /// Clears the dataset search.
  static String get datasetsClearSearch => _english.datasetsClearSearch;

  /// Headline when no project is open for a dataset screen.
  static String get datasetsNoProjectHeadline =>
      _english.datasetsNoProjectHeadline;

  /// Body when no project is open for a dataset screen.
  static String get datasetsNoProjectMessage =>
      _english.datasetsNoProjectMessage;

  /// Key-screen headline before a file is chosen.
  static String get datasetsPickHeadline => _english.datasetsPickHeadline;

  /// Key-screen body before a file is chosen.
  static String get datasetsPickMessage => _english.datasetsPickMessage;

  /// Starts choosing a table file.
  static String get datasetsPickFile => _english.datasetsPickFile;

  /// Progress step while a table file is read.
  static String get datasetsReading => _english.datasetsReading;

  /// How much of a table file has been read.
  static String datasetsReadProgress(int percent) =>
      _english.datasetsReadProgress(percent);

  /// A key-column row: its duplicate count and first values.
  static String datasetsColumnSummary(int duplicates, List<String> samples) =>
      _english.datasetsColumnSummary(duplicates, samples);

  /// Warning under a non-unique key: the count, the colliding values and
  /// the way forward.
  static String datasetsDuplicateWarning(int n, List<String> colliding) =>
      _english.datasetsDuplicateWarning(n, colliding);

  /// Confirm heading before a dataset with duplicate keys is saved.
  static String get datasetsDuplicatesConfirmTitle =>
      _english.datasetsDuplicatesConfirmTitle;

  /// Confirm body naming the key column and how many values repeat.
  static String datasetsDuplicatesConfirm(String column, int n) =>
      _english.datasetsDuplicatesConfirm(column, n);

  /// Browser action: export the dataset as CSV.
  static String get datasetsExportCsv => _english.datasetsExportCsv;

  /// Browser action: export the dataset as JSON.
  static String get datasetsExportJson => _english.datasetsExportJson;

  /// Shown while a dataset export is written.
  static String get datasetsExporting => _english.datasetsExporting;

  /// Label of the visible-columns choice.
  static String get datasetsVisibleColumns => _english.datasetsVisibleColumns;

  /// A browser row's second line: its shown values, and whether it was
  /// added on this device.
  static String datasetRowSubtitle(
    List<String> values, {
    required bool addedOnDevice,
  }) => _english.datasetRowSubtitle(values, addedOnDevice: addedOnDevice);

  /// Headline when a browsed dataset is no longer stored.
  static String get datasetsMissingHeadline => _english.datasetsMissingHeadline;

  /// Body when a browsed dataset is no longer stored.
  static String get datasetsMissingMessage => _english.datasetsMissingMessage;

  /// Export refused because no project is open to write it into.
  static String get datasetsExportNoProject => _english.datasetsExportNoProject;

  /// What to do when no project is open for an export.
  static String get datasetsExportNoProjectRecovery =>
      _english.datasetsExportNoProjectRecovery;

  /// Headline when an edited row is no longer stored.
  static String get datasetsRowMissingHeadline =>
      _english.datasetsRowMissingHeadline;

  /// Body when an edited row is no longer stored.
  static String get datasetsRowMissingMessage =>
      _english.datasetsRowMissingMessage;

  /// Headline when the add-row sheet has no dataset to add to.
  static String get datasetsAddRowNoDatasetHeadline =>
      _english.datasetsAddRowNoDatasetHeadline;

  /// Body when the add-row sheet has no dataset to add to.
  static String get datasetsAddRowNoDatasetMessage =>
      _english.datasetsAddRowNoDatasetMessage;

  /// A lookup fill target the template does not define.
  static String lookupUnknownTarget(String target) =>
      _english.lookupUnknownTarget(target);

  /// A lookup fill target two dataset columns write.
  static String lookupTargetTwice(String target) =>
      _english.lookupTargetTwice(target);

  /// Binding screen: pick a dataset before saving.
  static String get lookupPickDataset => _english.lookupPickDataset;

  /// An imported template whose lookup cannot be accepted.
  static String get lookupImportRecovery => _english.lookupImportRecovery;

  /// Binding screen: one dataset column chosen for two fields.
  static String lookupColumnTwice(String column) =>
      _english.lookupColumnTwice(column);

  /// Binding screen: a fuzzy threshold as a percentage.
  static String lookupThresholdLabel(int percent) =>
      _english.lookupThresholdLabel(percent);

  /// Binding screen: the dataset's key column.
  static String get lookupKeyColumn => _english.lookupKeyColumn;

  /// Binding screen: the ordered match columns.
  static String get lookupMatchColumns => _english.lookupMatchColumns;

  /// Binding screen: the order match columns are tried in.
  static String lookupMatchOrder(List<String> columns) =>
      _english.lookupMatchOrder(columns);

  /// Binding screen: a template field no dataset column fills.
  static String get lookupNotFilled => _english.lookupNotFilled;

  /// Binding screen: heading over the fill mapping.
  static String get lookupFills => _english.lookupFills;

  /// Binding screen: the lowest fuzzy score offered, in percent.
  static String get lookupFuzzyThreshold => _english.lookupFuzzyThreshold;

  /// Binding screen: saving turns the field into a lookup field.
  static String get lookupBecomesLookup => _english.lookupBecomesLookup;

  /// Binding screen: the field is no longer on the template.
  static String get lookupFieldMissingHeadline =>
      _english.lookupFieldMissingHeadline;

  /// Binding screen: body when the field is no longer on the template.
  static String get lookupFieldMissingMessage =>
      _english.lookupFieldMissingMessage;

  /// No-match behaviour: leave the bound fields empty.
  static String get lookupNoMatchLeaveEmpty => _english.lookupNoMatchLeaveEmpty;

  /// No-match behaviour: offer to add a row.
  static String get lookupNoMatchPromptAdd => _english.lookupNoMatchPromptAdd;

  /// No-match behaviour: warn only.
  static String get lookupNoMatchWarn => _english.lookupNoMatchWarn;

  /// Field editor entry that opens the lookup binding.
  static String get templatesBindDataset => _english.templatesBindDataset;

  /// Headline when the template list is empty.
  static String get templatesEmptyHeadline => _english.templatesEmptyHeadline;

  /// Body when the template list is empty. The next action is the library.
  static String get templatesEmptyMessage => _english.templatesEmptyMessage;

  /// Empty-state action that opens the shipped-library picker.
  static String get templatesPickLibrary => _english.templatesPickLibrary;

  /// Primary action that opens the blank-template form.
  static String get templatesCreate => _english.templatesCreate;

  /// Renames a template from its row menu.
  static String get templatesEdit => _english.templatesEdit;

  /// Opens upload and library choices on the template list.
  static String get templatesAddChoices => _english.templatesAddChoices;

  /// The add action once the project already has a template.
  static String get templatesAddMore => _english.templatesAddMore;

  /// Empty project template list. The add action sits in the footer.
  static String get templatesAddEmptyMessage =>
      _english.templatesAddEmptyMessage;

  /// Uploads a template file.
  static String get templatesUpload => _english.templatesUpload;

  /// Attaches a template that already exists.
  static String get templatesUseExisting => _english.templatesUseExisting;

  /// Search on the template list matched nothing.
  static String get templatesNoMatch => _english.templatesNoMatch;

  /// Title of the template list's filter sheet.
  static String get templateFiltersTitle => _english.templateFiltersTitle;

  /// The template-kind facet of the template list's filters.
  static String get templateKindFilter => _english.templateKindFilter;

  /// A template that names no kind, as a filter option.
  static String get templateKindNone => _english.templateKindNone;

  /// Search on the field list matched nothing.
  static String get fieldsNoMatch => _english.fieldsNoMatch;

  /// Title of a template field list's filter sheet.
  static String get fieldFiltersTitle => _english.fieldFiltersTitle;

  /// The required, recommended or optional facet of the field filters.
  static String get fieldRequirednessFilter => _english.fieldRequirednessFilter;

  /// How a project chooses a template when capture starts.
  static String get templateChoiceLabel => _english.templateChoiceLabel;

  /// Use the only template, and ask when there are several.
  static String get templateChoiceAuto => _english.templateChoiceAuto;

  /// Suggest a template and let the operator confirm.
  static String get templateChoiceSuggest => _english.templateChoiceSuggest;

  /// Always ask which template to use.
  static String get templateChoiceManual => _english.templateChoiceManual;

  /// Title of the blank-template form.
  static String get templatesCreateTitle => _english.templatesCreateTitle;

  /// Opens the field list for a template.
  static String get templatesOpen => _english.templatesOpen;

  /// Overflow command that writes a template out. Task 100 owns the screen.
  static String get templatesExport => _english.templatesExport;

  /// Overflow command that reads a template JSON into this project.
  static String get templatesImport => _english.templatesImport;

  /// Empty import destination: no file was given.
  static String get templatesImportEmptyHeadline =>
      _english.templatesImportEmptyHeadline;

  /// Empty import destination explanation.
  static String get templatesImportEmptyMessage =>
      _english.templatesImportEmptyMessage;

  /// Rejected because schema_version is missing or not this app's version.
  static String get templatesImportUnknownSchema =>
      _english.templatesImportUnknownSchema;

  /// Recovery for an unknown schema version.
  static String get templatesImportUnknownSchemaRecovery =>
      _english.templatesImportUnknownSchemaRecovery;

  /// Rejected because the JSON is not a template object.
  static String get templatesImportInvalid => _english.templatesImportInvalid;

  /// Recovery for an invalid template JSON.
  static String get templatesImportInvalidRecovery =>
      _english.templatesImportInvalidRecovery;

  /// Rejected because two fields share a key.
  static String get templatesImportDuplicateField =>
      _english.templatesImportDuplicateField;

  /// Recovery for a duplicate field key.
  static String get templatesImportDuplicateFieldRecovery =>
      _english.templatesImportDuplicateFieldRecovery;

  /// The chosen spreadsheet is encrypted.
  static String get workbookPassword => _english.workbookPassword;

  /// Recovery for a password-protected spreadsheet.
  static String get workbookPasswordRecovery =>
      _english.workbookPasswordRecovery;

  /// The chosen spreadsheet could not be parsed.
  static String get workbookCorrupt => _english.workbookCorrupt;

  /// Recovery for a corrupt spreadsheet.
  static String get workbookCorruptRecovery => _english.workbookCorruptRecovery;

  /// Title of the spreadsheet column-mapping screen.
  static String get xlsxMappingTitle => _english.xlsxMappingTitle;

  /// Headline when no spreadsheet was given.
  static String get xlsxMappingEmptyHeadline =>
      _english.xlsxMappingEmptyHeadline;

  /// Body when the mapping screen has no file to read.
  static String get xlsxMappingEmptyMessage => _english.xlsxMappingEmptyMessage;

  /// Primary action that creates the template from the confirmed mapping.
  static String get xlsxMappingConfirm => _english.xlsxMappingConfirm;

  /// Overflow command that omits one spreadsheet column.
  static String get xlsxMappingSkip => _english.xlsxMappingSkip;

  /// Overflow command that brings a skipped column back.
  static String get xlsxMappingInclude => _english.xlsxMappingInclude;

  /// Subtitle when the operator has skipped a column.
  static String get xlsxMappingSkipped => _english.xlsxMappingSkipped;

  /// Proposed field shown on the right of a mapping row.
  static String xlsxMappingProposal({
    required String field,
    required String type,
    required String rule,
  }) => _english.xlsxMappingProposal(field: field, type: type, rule: rule);

  /// Proposed label when a spreadsheet column has no header.
  static String xlsxMappingUntitled(String column) =>
      _english.xlsxMappingUntitled(column);

  /// Template name when the sheet tab is blank.
  static String get xlsxMappingDefaultName => _english.xlsxMappingDefaultName;

  /// The chosen spreadsheet vanished before confirm.
  static String get xlsxMappingMissing => _english.xlsxMappingMissing;

  /// Recovery when the chosen spreadsheet is missing.
  static String get xlsxMappingMissingRecovery =>
      _english.xlsxMappingMissingRecovery;

  /// A copy of this name is already in the project templates folder.
  static String get xlsxMappingExists => _english.xlsxMappingExists;

  /// Recovery when the destination copy already exists.
  static String get xlsxMappingExistsRecovery =>
      _english.xlsxMappingExistsRecovery;

  /// Title of the per-row aliases screen.
  static String get rowAliasesTitle => _english.rowAliasesTitle;

  /// Headline when the template has no checklist rows to name.
  static String get rowAliasesEmptyHeadline => _english.rowAliasesEmptyHeadline;

  /// Body when the aliases list is empty.
  static String get rowAliasesEmptyMessage => _english.rowAliasesEmptyMessage;

  /// Field label for a row's aliases.
  static String get rowAliasesField => _english.rowAliasesField;

  /// Hint showing how local names are written.
  static String get rowAliasesHint => _english.rowAliasesHint;

  /// Overflow command that reads aliases from one spreadsheet column.
  static String get rowAliasesImport => _english.rowAliasesImport;

  /// Field label for the alias column letter.
  static String get rowAliasesColumn => _english.rowAliasesColumn;

  /// Refuses a letter that does not name a column in the selected workbook.
  static String get rowAliasesInvalidColumn => _english.rowAliasesInvalidColumn;

  /// Recovery for an invalid alias column letter.
  static String get rowAliasesInvalidColumnRecovery =>
      _english.rowAliasesInvalidColumnRecovery;

  /// Stated absence when a row has no aliases yet.
  static String get rowAliasesNone => _english.rowAliasesNone;

  /// Subtitle listing the aliases already stored on a row.
  static String rowAliasesList(List<String> aliases) =>
      _english.rowAliasesList(aliases);

  /// Title of the capture checklist.
  static String get checklistTitle => _english.checklistTitle;

  /// Spreadsheet column that identifies one predefined checklist row.
  static String get checklistIdentifierColumn =>
      _english.checklistIdentifierColumn;

  /// Spreadsheet column that names one predefined checklist row.
  static String get checklistLabelColumn => _english.checklistLabelColumn;

  /// Spreadsheet column that groups checklist rows by place or context.
  static String get checklistContextColumn => _english.checklistContextColumn;

  /// Opens workbook mapping for an existing template's checklist.
  static String get checklistImportRows => _english.checklistImportRows;

  /// A checklist requires both identifying and display columns.
  static String get checklistMappingIncomplete =>
      _english.checklistMappingIncomplete;

  /// Recovery when a checklist mapping is incomplete.
  static String get checklistMappingRecovery =>
      _english.checklistMappingRecovery;

  /// Headline when the template has no predefined rows.
  static String get checklistEmptyHeadline => _english.checklistEmptyHeadline;

  /// Body when the checklist is empty.
  static String get checklistEmptyMessage => _english.checklistEmptyMessage;

  /// Status word for a row that has been found.
  static String get checklistFound => _english.checklistFound;

  /// Status word for a row that is still missing.
  static String get checklistMissing => _english.checklistMissing;

  /// Group name when a row has no room or context.
  static String get checklistUngrouped => _english.checklistUngrouped;

  /// Group heading: the room name and how many rows have been found.
  static String checklistProgress({
    required String group,
    required int found,
    required int total,
  }) => _english.checklistProgress(group: group, found: found, total: total);

  /// Title of the detection-profile screen.
  static String get detectionProfileTitle => _english.detectionProfileTitle;

  /// What the detection profile decides.
  static String get detectionProfileExplain => _english.detectionProfileExplain;

  /// Headline when no template is open.
  static String get detectionProfileEmptyHeadline =>
      _english.detectionProfileEmptyHeadline;

  /// Body when the detection screen has no template.
  static String get detectionProfileEmptyMessage =>
      _english.detectionProfileEmptyMessage;

  /// Field label for vision object classes.
  static String get detectionProfileClasses => _english.detectionProfileClasses;

  /// Field label for OCR keywords.
  static String get detectionProfileKeywords =>
      _english.detectionProfileKeywords;

  /// Section for identifier patterns reused from field validation.
  static String get detectionProfilePatterns =>
      _english.detectionProfilePatterns;

  /// Section for datasets already bound on lookup fields.
  static String get detectionProfileDatasets =>
      _english.detectionProfileDatasets;

  /// Field label for keywords that exclude this template.
  static String get detectionProfileNegative =>
      _english.detectionProfileNegative;

  /// Hint on a comma-separated signal list.
  static String get detectionProfileHint => _english.detectionProfileHint;

  /// Shown when no field has a validation pattern to reuse.
  static String get detectionProfileNoPatterns =>
      _english.detectionProfileNoPatterns;

  /// Shown when no lookup field names a dataset.
  static String get detectionProfileNoDatasets =>
      _english.detectionProfileNoDatasets;

  /// The template vanished before the profile was saved.
  static String get detectionProfileMissing => _english.detectionProfileMissing;

  /// Recovery when the template is missing.
  static String get detectionProfileMissingRecovery =>
      _english.detectionProfileMissingRecovery;

  /// Soft-deletes a template no record uses.
  static String get templatesDelete => _english.templatesDelete;

  /// Title of the delete confirmation, naming the template.
  static String templatesDeleteTitle(String name) =>
      _english.templatesDeleteTitle(name);

  /// Body of the delete confirmation, naming field and record counts.
  static String templatesDeleteMessage({
    required int fields,
    required int records,
  }) => _english.templatesDeleteMessage(fields: fields, records: records);

  /// Field-list destination after create, duplicate or open. Task 094 owns it.
  static String get templateFieldsTitle => _english.templateFieldsTitle;

  /// Primary action that opens the add-field flow. Task 095 owns the sheet.
  static String get templatesAddField => _english.templatesAddField;

  /// Heading of one field row on the new-template page.
  static String templateFieldRowTitle(int n) =>
      _english.templateFieldRowTitle(n);

  /// Removes one field row from the new-template page.
  static String get templateFieldRowRemove => _english.templateFieldRowRemove;

  /// Opens the editor for one field. Task 095 owns the sheet.
  static String get templatesEditField => _english.templatesEditField;

  /// Removes a field from the template and retires its values.
  static String get templatesDeleteField => _english.templatesDeleteField;

  /// Title of the field-delete confirmation, naming the field.
  static String templatesDeleteFieldTitle(String label) =>
      _english.templatesDeleteFieldTitle(label);

  /// Body of the field-delete confirmation, naming the value count.
  static String templatesDeleteFieldMessage({required int values}) =>
      _english.templatesDeleteFieldMessage(values: values);

  /// Headline when a template has no fields.
  static String get templatesFieldsEmptyHeadline =>
      _english.templatesFieldsEmptyHeadline;

  /// Body when the field list is empty. The next action is adding one.
  static String get templatesFieldsEmptyMessage =>
      _english.templatesFieldsEmptyMessage;

  /// REQUIRED badge on a field row.
  static String get fieldRequired => _english.fieldRequired;

  /// Field filled by a calculation.
  static String get fieldCalculated => _english.fieldCalculated;

  /// Field the detection profile can fill from a photo.
  static String get fieldFromPhotos => _english.fieldFromPhotos;

  /// Field-list subtitle: type, then any of required, calculated, from photos.
  static String fieldRowSubtitle({
    required String typeLabel,
    required bool requiredField,
    required bool calculated,
    required bool fromPhotos,
    bool pinnedContext = false,
    int? contextLevel,
    String? defaultValue,
  }) => _english.fieldRowSubtitle(
    typeLabel: typeLabel,
    requiredField: requiredField,
    calculated: calculated,
    fromPhotos: fromPhotos,
    pinnedContext: pinnedContext,
    contextLevel: contextLevel,
    defaultValue: defaultValue,
  );

  /// The value a field takes when nothing fills it, on its field row.
  static String fieldRowDefault(String value) =>
      _english.fieldRowDefault(value);

  /// RECOMMENDED badge on a field row.
  static String get fieldRecommended => _english.fieldRecommended;

  /// OPTIONAL badge on a field row.
  static String get fieldOptional => _english.fieldOptional;

  /// Moves [label] one place earlier in capture and export order.
  static String fieldMoveUp(String label) => _english.fieldMoveUp(label);

  /// Moves [label] one place later in capture and export order.
  static String fieldMoveDown(String label) => _english.fieldMoveDown(label);

  /// Drag handle that reorders [label].
  static String fieldReorder(String label) => _english.fieldReorder(label);

  /// Operator-facing name of a §12.1 field type.
  static String fieldTypeLabel(String type) => _english.fieldTypeLabel(type);

  /// Label of the field being added or edited. Template content follows.
  static String get fieldLabel => _english.fieldLabel;

  /// Type picker on the add-field sheet.
  static String get fieldType => _english.fieldType;

  /// Three-way requiredness question on the add-field sheet.
  static String get fieldRequiredness => _english.fieldRequiredness;

  /// Collapsed section that holds every §12.2 attribute the add flow defaults.
  static String get fieldAdvanced => _english.fieldAdvanced;

  /// Reveals the collapsed Advanced section.
  static String get fieldAdvancedShow => _english.fieldAdvancedShow;

  /// Hides the Advanced section again.
  static String get fieldAdvancedHide => _english.fieldAdvancedHide;

  /// Lets the user keep a two-fact label after the warning.
  static String get fieldKeepAnyway => _english.fieldKeepAnyway;

  /// Warns that a label packs two facts (§13.1) without blocking the save.
  static String get fieldTwoFactsWarning => _english.fieldTwoFactsWarning;

  /// Default written when the operator leaves the field empty.
  static String get fieldDefaultValue => _english.fieldDefaultValue;

  /// Displayed and exported unit, for example kg.
  static String get fieldUnit => _english.fieldUnit;

  /// One short line of guidance shown under the field.
  static String get fieldHelp => _english.fieldHelp;

  /// Who may write the field.
  static String get fieldInputMode => _english.fieldInputMode;

  /// [InputMode.any].
  static String get fieldInputAny => _english.fieldInputAny;

  /// [InputMode.manualOnly].
  static String get fieldInputManual => _english.fieldInputManual;

  /// [InputMode.aiAllowed].
  static String get fieldInputAi => _english.fieldInputAi;

  /// [InputMode.auto].
  static String get fieldInputAuto => _english.fieldInputAuto;

  /// Whether the field may be pinned as context.
  static String get fieldStickable => _english.fieldStickable;

  /// Context hierarchy level, when this field is a level of that hierarchy.
  static String get fieldContextLevel => _english.fieldContextLevel;

  /// System fill source.
  static String get fieldAutoFill => _english.fieldAutoFill;

  /// No automatic fill.
  static String get fieldAutoFillNone => _english.fieldAutoFillNone;

  /// Operator-facing name of an [AutoFill] source.
  static String fieldAutoFillLabel(String source) =>
      _english.fieldAutoFillLabel(source);

  /// Store an AI-refined companion beside the raw value.
  static String get fieldRefine => _english.fieldRefine;

  /// Whether the field participates in duplicate detection.
  static String get fieldIdentity => _english.fieldIdentity;

  /// Expression that makes the field required.
  static String get fieldRequiredWhen => _english.fieldRequiredWhen;

  /// Plain-language reading of a required-when expression.
  static String fieldRequiredWhenPreview(String reading) =>
      _english.fieldRequiredWhenPreview(reading);

  /// Keeps the field out of capture and export; values stay.
  static String get fieldHidden => _english.fieldHidden;

  /// Explains that hide is not a delete.
  static String get fieldHiddenHelp => _english.fieldHiddenHelp;

  /// Validation editor heading.
  static String get fieldValidationTitle => _english.fieldValidationTitle;

  /// Headline when no validation rule is set.
  static String get fieldValidationEmptyHeadline =>
      _english.fieldValidationEmptyHeadline;

  /// Body when the validation editor is empty.
  static String get fieldValidationEmptyMessage =>
      _english.fieldValidationEmptyMessage;

  /// Pattern picker.
  static String get fieldPattern => _english.fieldPattern;

  /// No pattern.
  static String get fieldPatternNone => _english.fieldPatternNone;

  /// Ready-made serial pattern.
  static String get fieldPatternSerial => _english.fieldPatternSerial;

  /// Ready-made asset-tag pattern.
  static String get fieldPatternAssetTag => _english.fieldPatternAssetTag;

  /// Ready-made registration pattern.
  static String get fieldPatternRegistration =>
      _english.fieldPatternRegistration;

  /// Custom regular expression.
  static String get fieldPatternCustom => _english.fieldPatternCustom;

  /// Live box that tries the current validation against a sample.
  static String get fieldPatternTest => _english.fieldPatternTest;

  /// Sample matches the rule.
  static String get fieldPatternTestPass => _english.fieldPatternTestPass;

  /// Minimum length.
  static String get fieldMinLength => _english.fieldMinLength;

  /// Maximum length.
  static String get fieldMaxLength => _english.fieldMaxLength;

  /// Inclusive lower bound.
  static String get fieldRangeMin => _english.fieldRangeMin;

  /// Inclusive upper bound.
  static String get fieldRangeMax => _english.fieldRangeMax;

  /// Another field that must be filled with this one.
  static String get fieldRequiredWith => _english.fieldRequiredWith;

  /// Choice-options editor heading.
  static String get fieldOptionsTitle => _english.fieldOptionsTitle;

  /// Headline when a choice field has no options.
  static String get fieldOptionsEmptyHeadline =>
      _english.fieldOptionsEmptyHeadline;

  /// Body when the options editor is empty.
  static String get fieldOptionsEmptyMessage =>
      _english.fieldOptionsEmptyMessage;

  /// Label of a new choice.
  static String get fieldOptionLabel => _english.fieldOptionLabel;

  /// Adds a choice to the list.
  static String get fieldOptionAdd => _english.fieldOptionAdd;

  /// Retires a choice without rewriting stored codes.
  static String get fieldOptionRetire => _english.fieldOptionRetire;

  /// Badge on a retired choice.
  static String get fieldOptionRetired => _english.fieldOptionRetired;

  /// Headline when the add sheet cannot find the template.
  static String get fieldAddEmptyHeadline => _english.fieldAddEmptyHeadline;

  /// Body when the add sheet has no template.
  static String get fieldAddEmptyMessage => _english.fieldAddEmptyMessage;

  /// Title of the bulk requiredness screen.
  static String get requiredColumnsTitle => _english.requiredColumnsTitle;

  /// Headline when the template has no fields to re-scope.
  static String get requiredColumnsEmptyHeadline =>
      _english.requiredColumnsEmptyHeadline;

  /// Body when the required-columns list is empty.
  static String get requiredColumnsEmptyMessage =>
      _english.requiredColumnsEmptyMessage;

  /// Hide toggle on a required-columns row.
  static String get requiredColumnHide => _english.requiredColumnHide;

  /// Reveals an inherited §13.3 group.
  static String get requiredColumnShowGroup => _english.requiredColumnShowGroup;

  /// Collapses an inherited §13.3 group.
  static String get requiredColumnHideGroup => _english.requiredColumnHideGroup;

  /// Heading for fields that do not sit in a named group.
  static String get requiredColumnUngrouped => _english.requiredColumnUngrouped;

  /// Screen-reader name of the three-radio grid for [label].
  static String requiredColumnRadios(String label) =>
      _english.requiredColumnRadios(label);

  /// One radio cell: field [label] and the requiredness [mark].
  static String requiredColumnCell(String label, String mark) =>
      _english.requiredColumnCell(label, mark);

  /// Reminder of the shipped requiredness after the user moves it.
  static String requiredColumnShipped(String mark) =>
      _english.requiredColumnShipped(mark);

  /// Operator-facing name of a field group.
  static String requiredColumnGroup(String group) =>
      _english.requiredColumnGroup(group);

  /// Title of the identity-fields screen.
  static String get identityFieldsTitle => _english.identityFieldsTitle;

  /// What changing the identity set does.
  static String get identityFieldsExplain => _english.identityFieldsExplain;

  /// Headline when the template has no fields to mark as identity.
  static String get identityFieldsEmptyHeadline =>
      _english.identityFieldsEmptyHeadline;

  /// Body when the identity list is empty.
  static String get identityFieldsEmptyMessage =>
      _english.identityFieldsEmptyMessage;

  /// Title of the output-column mapping screen.
  static String get outputMappingTitle => _english.outputMappingTitle;

  /// Headline when the template has no fields to map.
  static String get outputMappingEmptyHeadline =>
      _english.outputMappingEmptyHeadline;

  /// Body when the output-mapping list is empty.
  static String get outputMappingEmptyMessage =>
      _english.outputMappingEmptyMessage;

  /// Why two fields cannot share an output column.
  static String get outputMappingDuplicate => _english.outputMappingDuplicate;

  /// What to do after a duplicate output column is refused.
  static String get outputMappingDuplicateRecovery =>
      _english.outputMappingDuplicateRecovery;

  /// Hint on a template built in the app, whose headers are generated.
  static String get outputMappingBuiltHint => _english.outputMappingBuiltHint;

  /// Hint on a template imported from a workbook.
  static String get outputMappingImportedHint =>
      _english.outputMappingImportedHint;

  /// Title of the template-migration screen.
  static String get templateMigrationTitle => _english.templateMigrationTitle;

  /// What staying on a captured version means.
  static String get templateMigrationExplain =>
      _english.templateMigrationExplain;

  /// Headline when every record is already on the current version.
  static String get templateMigrationEmptyHeadline =>
      _english.templateMigrationEmptyHeadline;

  /// Body when no record is behind the current template version.
  static String get templateMigrationEmptyMessage =>
      _english.templateMigrationEmptyMessage;

  /// Added-fields section on the migration screen.
  static String get templateMigrationAdded => _english.templateMigrationAdded;

  /// Removed-fields section on the migration screen.
  static String get templateMigrationRemoved =>
      _english.templateMigrationRemoved;

  /// Retyped-fields section on the migration screen.
  static String get templateMigrationRetyped =>
      _english.templateMigrationRetyped;

  /// Confirm heading before records move.
  static String get templateMigrationConfirmTitle =>
      _english.templateMigrationConfirmTitle;

  /// Confirm body: how many records move, in one write, or none do.
  static String templateMigrationConfirm(int records) =>
      _english.templateMigrationConfirm(records);

  /// How many records are behind the current template version.
  static String templateMigrationBehind(int records) =>
      _english.templateMigrationBehind(records);

  /// Records whose captured version is no longer known on this device.
  static String templateMigrationUnresolved(int records) =>
      _english.templateMigrationUnresolved(records);

  /// Section of stored values the move retires for unresolved records.
  static String get templateMigrationRetiring =>
      _english.templateMigrationRetiring;

  /// Primary action that starts the confirmed move.
  static String get templateMigrationAction => _english.templateMigrationAction;

  /// Suggested name when duplicating [name].
  static String templateCopyName(String name) =>
      _english.templateCopyName(name);

  /// Field and record counts on one template list row.
  static String templateListSubtitle({
    required int fields,
    required int records,
  }) => _english.templateListSubtitle(fields: fields, records: records);

  /// Title of the shipped-library picker.
  static String get templatesLibraryTitle => _english.templatesLibraryTitle;

  /// Headline when the packed library could not be listed.
  static String get templatesLibraryEmptyHeadline =>
      _english.templatesLibraryEmptyHeadline;

  /// Body when the packed library is empty. Next action is a blank template.
  static String get templatesLibraryEmptyMessage =>
      _english.templatesLibraryEmptyMessage;

  /// Copies the previewed library entry into the open project.
  static String get templatesAdd => _english.templatesAdd;

  /// Adds a shipped template that this project does not have yet.
  static String get templatesAddToProject => _english.templatesAddToProject;

  /// Makes another editable copy of a template already on the project.
  static String get templatesCustomCopy => _english.templatesCustomCopy;

  /// Visible association on a shipped template already copied in.
  static String get shippedAddedToProject => _english.shippedAddedToProject;

  /// Search hint on the shipped template library, which ranks a name, a code
  /// or a plain description of the work.
  static String get shippedLibrarySearchHint =>
      _english.shippedLibrarySearchHint;

  /// Heading of a catalogue area. [code] and [title] are catalogue data.
  static String shippedAreaTitle(String code, String title) =>
      _english.shippedAreaTitle(code, title);

  /// Heading of a catalogue category. [code] and [title] are catalogue data.
  static String shippedCatalogueCategoryTitle(String code, String title) =>
      _english.shippedCatalogueCategoryTitle(code, title);

  /// A collapsible catalogue category with how many templates it lists.
  static String shippedCategoryHeading(String code, String title, int count) =>
      _english.shippedCategoryHeading(code, title, count);

  /// Row subtitle of a catalogue template: its code, its record type and how
  /// many fields it holds. [code] and [recordType] are catalogue data.
  static String shippedCatalogueSubtitle(
    String code,
    String recordType,
    int fields,
  ) => _english.shippedCatalogueSubtitle(code, recordType, fields);

  /// Title of the shipped library's filter sheet.
  static String get shippedFiltersTitle => _english.shippedFiltersTitle;

  /// The area facet of the shipped library's filters.
  static String get shippedAreaFilter => _english.shippedAreaFilter;

  /// The record-type facet of the shipped library's filters.
  static String get shippedRecordTypeFilter => _english.shippedRecordTypeFilter;

  /// The tier facet of the shipped library's filters.
  static String get shippedTierFilter => _english.shippedTierFilter;

  /// Operator-facing name of a catalogue rollout tier.
  static String shippedTierLabel(String rollout) =>
      _english.shippedTierLabel(rollout);

  /// Operator-facing name of a catalogue template's suggested privacy.
  static String shippedPrivacyLabel(String privacy) =>
      _english.shippedPrivacyLabel(privacy);

  /// Preview row naming the catalogue category a template sits in.
  static String get shippedCategoryLabel => _english.shippedCategoryLabel;

  /// Preview row naming a catalogue template's record type.
  static String get shippedRecordTypeLabel => _english.shippedRecordTypeLabel;

  /// Preview row giving a catalogue template's privacy and tier.
  static String get shippedPrivacyTierLabel => _english.shippedPrivacyTierLabel;

  /// A catalogue template's suggested privacy beside its tier.
  static String shippedPrivacyTier(String privacy, String rollout) =>
      _english.shippedPrivacyTier(privacy, rollout);

  /// Preview row: how evidence for the record type is captured.
  static String get shippedCaptureLabel => _english.shippedCaptureLabel;

  /// Preview row: what AI may do for the record type.
  static String get shippedAiAssistanceLabel =>
      _english.shippedAiAssistanceLabel;

  /// Preview row: what the record type produces.
  static String get shippedOutputsLabel => _english.shippedOutputsLabel;

  /// Preview row: what a reviewer checks before approval.
  static String get shippedReviewLabel => _english.shippedReviewLabel;

  /// Preview subtitle of one field: its type and suggested requiredness.
  static String shippedFieldSubtitle(String type, String requiredness) =>
      _english.shippedFieldSubtitle(type, requiredness);

  /// Empty result for the shipped library search.
  static String shippedLibraryNoMatch(String query) =>
      _english.shippedLibraryNoMatch(query);

  /// What to change when the shipped library search matches nothing.
  static String get shippedLibraryNoMatchMessage =>
      _english.shippedLibraryNoMatchMessage;

  /// Resolves a packed localisation key at render time (FE-L10N-07).
  static String shippedLabel(String key) => _english.shippedLabel(key);

  /// Unprocessed-queue destination the status line opens.
  static String get navQueue => _english.navQueue;

  /// Export-history destination the project home opens.
  static String get navExports => _english.navExports;

  /// Why the operator name is asked.
  static String get operatorNameUse => _english.operatorNameUse;

  /// Label of the operator name field.
  static String get operatorName => _english.operatorName;

  /// Settings screen for the local operator identity.
  static String get operatorProfileTitle => _english.operatorProfileTitle;

  /// Initials field on the operator profile.
  static String get operatorInitials => _english.operatorInitials;

  /// Combined contact label when email and phone are shown as one value.
  static String get operatorContact => _english.operatorContact;

  /// Optional email field on the operator profile.
  static String get operatorEmail => _english.operatorEmail;

  /// Optional phone field on the operator profile.
  static String get operatorPhone => _english.operatorPhone;

  /// Name failed the non-empty rule.
  static String get nameRequired => _english.nameRequired;

  /// A typed email is missing the @ that marks it as an address.
  static String get emailNeedsAt => _english.emailNeedsAt;

  /// Initials failed the one-to-three-character rule.
  static String get initialsLength => _english.initialsLength;

  /// Status line when no project is open.
  static String get statusNoProject => _english.statusNoProject;

  /// Status line when no context is pinned.
  static String get statusNoContext => _english.statusNoContext;

  /// Context hierarchy screen title.
  static String get contextHierarchyTitle => _english.contextHierarchyTitle;

  /// Empty hierarchy.
  static String get contextHierarchyEmptyHeadline =>
      _english.contextHierarchyEmptyHeadline;

  /// Empty hierarchy body.
  static String get contextHierarchyEmptyMessage =>
      _english.contextHierarchyEmptyMessage;

  /// Add a level.
  static String get contextAddLevel => _english.contextAddLevel;

  /// One saved or proposed level and its stable field key.
  static String contextLevelRow(int level, String fieldKey) =>
      _english.contextLevelRow(level, fieldKey);

  /// Accepts all unambiguous template-declared levels.
  static String get contextUseTemplateLevels =>
      _english.contextUseTemplateLevels;

  /// Template loading failure on context setup.
  static String get contextTemplateFailureHeadline =>
      _english.contextTemplateFailureHeadline;

  /// Recovery text after template-level loading fails.
  static String get contextTemplateFailureMessage =>
      _english.contextTemplateFailureMessage;

  /// No project template exists yet.
  static String get contextNoTemplatesHeadline =>
      _english.contextNoTemplatesHeadline;

  /// Explains how a project gains fields that can become levels.
  static String get contextNoTemplatesMessage =>
      _english.contextNoTemplatesMessage;

  /// Opens the contextual Templates route.
  static String get contextOpenTemplates => _english.contextOpenTemplates;

  /// Templates exist but do not declare a hierarchy.
  static String get contextNoDeclaredLevelsHeadline =>
      _english.contextNoDeclaredLevelsHeadline;

  /// Explains how to declare template levels.
  static String get contextNoDeclaredLevelsMessage =>
      _english.contextNoDeclaredLevelsMessage;

  /// Every available field is already part of the hierarchy.
  static String get contextNoEligibleFieldsHeadline =>
      _english.contextNoEligibleFieldsHeadline;

  /// Explains why the manual picker has no remaining fields.
  static String get contextNoEligibleFieldsMessage =>
      _english.contextNoEligibleFieldsMessage;

  /// Conflicting level metadata requires explicit correction.
  static String get contextTemplateConflictHeadline =>
      _english.contextTemplateConflictHeadline;

  /// Names template declaration conflicts without guessing through them.
  static String contextTemplateConflictMessage(String conflicts) =>
      _english.contextTemplateConflictMessage(conflicts);

  /// Save hierarchy.
  static String get contextSaveHierarchy => _english.contextSaveHierarchy;

  /// Context picker sheet title prefix.
  static String contextPickerTitle(String label) =>
      _english.contextPickerTitle(label);

  /// Recent values section.
  static String get contextRecents => _english.contextRecents;

  /// Dataset search section.
  static String get contextDatasetSearch => _english.contextDatasetSearch;

  /// Free-text confirm.
  static String get contextUseValue => _english.contextUseValue;

  /// Label of the picker's free-text field.
  static String get contextTypeValue => _english.contextTypeValue;

  /// A pin with no value in the pinned-fields sheet.
  static String get contextValueNotSet => _english.contextValueNotSet;

  /// Removes a pinned value in its picker.
  static String get contextClearPin => _english.contextClearPin;

  /// Context values joined for the status line; the values are data.
  static String contextBreadcrumb(List<String> values) =>
      _english.contextBreadcrumb(values);

  /// A pinned field and its value on the context bar; both are data.
  static String contextPinnedValue(String field, String value) =>
      _english.contextPinnedValue(field, value);

  /// Pin fields sheet.
  static String get contextPinnedTitle => _english.contextPinnedTitle;

  /// Pin empty.
  static String get contextPinnedEmptyHeadline =>
      _english.contextPinnedEmptyHeadline;

  /// Pin empty body.
  static String get contextPinnedEmptyMessage =>
      _english.contextPinnedEmptyMessage;

  /// Pin empty body when the project already has a template.
  static String get contextMarkPinnable => _english.contextMarkPinnable;

  /// Why pinned context is useful.
  static String get contextPinnedRelevance => _english.contextPinnedRelevance;

  /// Cascade confirm title.
  static String get contextCascadeTitle => _english.contextCascadeTitle;

  /// Cascade confirm body in the specification's wording.
  ///
  /// [named] is each lower level and its current value. Level names and
  /// values are operator data, not catalogue keys (FE-L10N-07).
  static String contextCascadeMessage({
    required String levelLabel,
    required String newValue,
    required List<String> named,
  }) => _english.contextCascadeMessage(
    levelLabel: levelLabel,
    newValue: newValue,
    named: named,
  );

  /// Cascade confirm action.
  static String get contextCascadeConfirm => _english.contextCascadeConfirm;

  /// Preset list title.
  static String get contextPresetsTitle => _english.contextPresetsTitle;

  /// Preset empty.
  static String get contextPresetsEmptyHeadline =>
      _english.contextPresetsEmptyHeadline;

  /// Preset empty body — next action is to apply a preset.
  static String get contextPresetsEmptyMessage =>
      _english.contextPresetsEmptyMessage;

  /// Save preset.
  static String get contextPresetSave => _english.contextPresetSave;

  /// Apply preset.
  static String get contextPresetApply => _english.contextPresetApply;

  /// Opens the preset list from the context bar.
  static String get contextPresetsChip => _english.contextPresetsChip;

  /// The preset list row on the context levels screen.
  static String get contextPresetsHint => _english.contextPresetsHint;

  /// Name field of the save-preset sheet.
  static String get contextPresetName => _english.contextPresetName;

  /// After a preset was applied; [name] is data.
  static String contextPresetApplied(String name) =>
      _english.contextPresetApplied(name);

  /// After a preset was saved; [name] is data.
  static String contextPresetSaved(String name) =>
      _english.contextPresetSaved(name);

  /// Deletes one preset from its row menu.
  static String get contextPresetDelete => _english.contextPresetDelete;

  /// Confirms a preset delete; [name] is data.
  static String contextPresetDeleteMessage(String name) =>
      _english.contextPresetDeleteMessage(name);

  /// Stored reason for a preset deleted from the list.
  static String get contextPresetDeleteReason =>
      _english.contextPresetDeleteReason;

  /// Duplicate preset name.
  static String get contextPresetOverwriteTitle =>
      _english.contextPresetOverwriteTitle;

  /// Duplicate preset body.
  static String get contextPresetOverwriteMessage =>
      _english.contextPresetOverwriteMessage;

  /// Confirms replacing a preset of the same name.
  static String get contextPresetReplace => _english.contextPresetReplace;

  /// Auto-clear undo.
  static String get contextAutoClearUndo => _english.contextAutoClearUndo;

  /// Auto-clear toast.
  static String contextAutoClearMessage(String label) =>
      _english.contextAutoClearMessage(label);

  /// Movement prompt title.
  static String get contextMovementTitle => _english.contextMovementTitle;

  /// Movement prompt body.
  static String get contextMovementMessage => _english.contextMovementMessage;

  /// Opens the lowest level's picker from the movement prompt.
  static String get contextMovementChange => _english.contextMovementChange;

  /// Pin chip marker.
  static String get contextPinMarker => _english.contextPinMarker;

  /// A context level with no value on Capture's bar; [level] is data.
  static String contextSetLevel(String level) =>
      _english.contextSetLevel(level);

  /// A context level and its value on Capture's bar; both are data.
  static String contextLevelValue(String level, String value) =>
      _english.contextLevelValue(level, value);

  /// Opens the project's context levels from Capture's bar.
  static String get contextManage => _english.contextManage;

  /// Opens the project's context levels when it has none yet.
  static String get contextSetUp => _english.contextSetUp;

  /// Remove one hierarchy level.
  static String get contextRemoveLevel => _english.contextRemoveLevel;

  /// Semantic name of a level's drag handle; [level] is data.
  static String contextDragLevel(String level) =>
      _english.contextDragLevel(level);

  /// Idle auto-clear switch. Off until the operator turns it on.
  static String get settingsContextAutoClear =>
      _english.settingsContextAutoClear;

  /// Why auto-clear stays off.
  static String get settingsContextAutoClearEffect =>
      _english.settingsContextAutoClearEffect;

  /// Idle interval row.
  static String settingsContextIdleSubtitle(int minutes) =>
      _english.settingsContextIdleSubtitle(minutes);

  /// Movement confirmation switch. Off until the operator turns it on.
  static String get settingsContextMovement => _english.settingsContextMovement;

  /// Why the movement prompt stays off, and that it does not edit context.
  static String get settingsContextMovementEffect =>
      _english.settingsContextMovementEffect;

  /// Distance row.
  static String settingsContextDistanceSubtitle(int metres) =>
      _english.settingsContextDistanceSubtitle(metres);

  /// Idle interval choice: how long the context waits before clearing.
  static String get settingsContextIdle => _english.settingsContextIdle;

  /// What the idle interval changes.
  static String get settingsContextIdleEffect =>
      _english.settingsContextIdleEffect;

  /// One idle interval, in minutes.
  static String settingsContextIdleOption(int minutes) =>
      _english.settingsContextIdleOption(minutes);

  /// Movement distance choice: how far a move is before Tapture asks.
  static String get settingsContextDistance => _english.settingsContextDistance;

  /// What the movement distance changes.
  static String get settingsContextDistanceEffect =>
      _english.settingsContextDistanceEffect;

  /// One movement distance, in metres.
  static String settingsContextDistanceOption(int metres) =>
      _english.settingsContextDistanceOption(metres);

  /// Capture screen title.
  static String get captureTitle => _english.captureTitle;

  /// Primary save that also enqueues analysis.
  static String get captureSaveAndAnalyse => _english.captureSaveAndAnalyse;

  /// Why Save and process is off while the device is offline.
  static String get captureProcessNeedsNetwork =>
      _english.captureProcessNeedsNetwork;

  /// Raw save with no processing.
  static String get captureSaveRaw => _english.captureSaveRaw;

  /// Empty tray headline.
  static String get captureNoPhotosHeadline => _english.captureNoPhotosHeadline;

  /// Empty tray body — evidence is the only requirement.
  static String get captureNoPhotosMessage => _english.captureNoPhotosMessage;

  /// Project selector on the capture surface.
  static String get captureProjectLabel => _english.captureProjectLabel;

  /// Capture is open and projects exist, but none is selected.
  static String get captureChooseProject => _english.captureChooseProject;

  /// Capture is open and there is no project to file it under.
  static String get captureCreateProjectFirst =>
      _english.captureCreateProjectFirst;

  /// Why capture needs a project, under the no-project headline.
  static String get captureNoProjectMessage => _english.captureNoProjectMessage;

  /// A project is open, but it has no template to capture against.
  static String get captureNeedsTemplate => _english.captureNeedsTemplate;

  /// More fields expander.
  static String get captureMoreFields => _english.captureMoreFields;

  /// Camera permission reason before the system prompt.
  static String get captureCameraReason => _english.captureCameraReason;

  /// Open system settings after a permanent camera refusal.
  static String get captureOpenCameraSettings =>
      _english.captureOpenCameraSettings;

  /// Asks the system for the camera after the reason is shown.
  static String get captureAllowCamera => _english.captureAllowCamera;

  /// Title of the full-screen live camera.
  static String get captureCameraTitle => _english.captureCameraTitle;

  /// Keep a photo despite a quality warning.
  static String get captureKeepPhoto => _english.captureKeepPhoto;

  /// Retake after a quality warning.
  static String get captureRetakePhoto => _english.captureRetakePhoto;

  /// Document mode toggle on the live camera.
  static String get captureDocumentMode => _english.captureDocumentMode;

  /// Document mode found the page and offers the straightened copy.
  static String get capturePageBoundaryFound =>
      _english.capturePageBoundaryFound;

  /// Use the perspective-corrected copy beside the original.
  static String get captureUseCorrected => _english.captureUseCorrected;

  /// Document mode could not straighten the page.
  static String get captureCorrectionFailed => _english.captureCorrectionFailed;

  /// Document mode found no page boundary.
  static String get captureNoPageBoundary => _english.captureNoPageBoundary;

  /// Flash control label while the flash stays off.
  static String get captureFlashOff => _english.captureFlashOff;

  /// Flash control label while the device decides.
  static String get captureFlashAuto => _english.captureFlashAuto;

  /// Flash control label while the flash fires.
  static String get captureFlashOn => _english.captureFlashOn;

  /// Grid control semantic label.
  static String get captureGrid => _english.captureGrid;

  /// Focus indicator semantic label.
  static String get captureFocus => _english.captureFocus;

  /// Zoom-out control label.
  static String get captureZoomOut => _english.captureZoomOut;

  /// Zoom-in control label.
  static String get captureZoomIn => _english.captureZoomIn;

  /// Gallery import action.
  static String get captureImportGallery => _english.captureImportGallery;

  /// Document import action.
  static String get captureImportDocument => _english.captureImportDocument;

  /// Import cannot start before the document store is available.
  static String get captureDocumentsUnavailable =>
      _english.captureDocumentsUnavailable;

  /// Recovery for unavailable document storage.
  static String get captureDocumentsUnavailableRecovery =>
      _english.captureDocumentsUnavailableRecovery;

  /// Rejected import names the reason.
  static String captureImportRejected(String reason) =>
      _english.captureImportRejected(reason);

  /// Try another file recovery.
  static String get tryAnotherFile => _english.tryAnotherFile;

  /// PDF bytes were not a valid document.
  static String get pdfInvalid => _english.pdfInvalid;

  /// Names an imported document whose contents cannot be safely read.
  static String captureDocumentInvalid(String filename) =>
      _english.captureDocumentInvalid(filename);

  /// Requested page is outside the document.
  static String get pdfPageMissing => _english.pdfPageMissing;

  /// Moves through lazily rendered document pages.
  static String get pdfPreviousPage => _english.pdfPreviousPage;

  /// Moves through lazily rendered document pages.
  static String get pdfNextPage => _english.pdfNextPage;

  /// Barcode scanner unavailable on this build.
  static String get barcodeUnavailable => _english.barcodeUnavailable;

  /// Recovery for a refused scanner camera; typing still works meanwhile.
  static String get barcodeAllowCamera => _english.barcodeAllowCamera;

  /// Confirm a decoded barcode.
  static String get barcodeConfirm => _english.barcodeConfirm;

  /// Scan again after a decode.
  static String get barcodeRescan => _english.barcodeRescan;

  /// No code in the region yet.
  static String get barcodeNoCode => _english.barcodeNoCode;

  /// Title of the barcode scanner screen.
  static String get barcodeTitle => _english.barcodeTitle;

  /// Torch toggle on the barcode scanner.
  static String get barcodeTorch => _english.barcodeTorch;

  /// Unreadable code.
  static String get barcodeUnreadable => _english.barcodeUnreadable;

  /// Continuous mode running count.
  static String barcodeScanCount(int n) => _english.barcodeScanCount(n);

  /// A counted code's place in the continuous-mode tally.
  static String barcodeCountPosition(int n) => _english.barcodeCountPosition(n);

  /// Continuous-mode toggle on the barcode scanner.
  static String get barcodeCountMode => _english.barcodeCountMode;

  /// Undo last continuous scan.
  static String get barcodeUndoLast => _english.barcodeUndoLast;

  /// Identifier matched a project record.
  static String get identifierMatchRecord => _english.identifierMatchRecord;

  /// Identifier matched a reference row.
  static String get identifierMatchReference =>
      _english.identifierMatchReference;

  /// Identifier matched nothing — start a new record.
  static String get identifierNewRecord => _english.identifierNewRecord;

  /// Several records share the identifier.
  static String get identifierDuplicates => _english.identifierDuplicates;

  /// Record caption field label.
  static String get captureRecordCaption => _english.captureRecordCaption;

  /// Photo group on the capture surface.
  static String get capturePhotosSection => _english.capturePhotosSection;

  /// Audio group on the capture surface.
  static String get captureAudioSection => _english.captureAudioSection;

  /// Removes one draft photo from the capture tray.
  static String get captureRemovePhoto => _english.captureRemovePhoto;

  /// Adds the typed caption to every photo, when none is ticked.
  static String captionAddToAll(int n) => _english.captionAddToAll(n);

  /// Adds the typed caption to the ticked photos only.
  static String captionAddToTicked(int n) => _english.captionAddToTicked(n);

  /// Says how many photos a caption was just added to.
  static String captionAdded(int n) => _english.captionAdded(n);

  /// Append caption mode.
  static String get captionAppend => _english.captionAppend;

  /// Replace caption mode.
  static String get captionReplace => _english.captionReplace;

  /// Microphone permission reason.
  static String get captureMicReason => _english.captureMicReason;

  /// Voice input listening state.
  static String get captureListening => _english.captureListening;

  /// Audio recorder start.
  static String get captureRecordAudio => _english.captureRecordAudio;

  /// Audio recorder pause.
  static String get capturePauseAudio => _english.capturePauseAudio;

  /// Audio recorder stop.
  static String get captureStopAudio => _english.captureStopAudio;

  /// Audio recorder unavailable.
  static String get audioRecorderUnavailable =>
      _english.audioRecorderUnavailable;

  /// Refusal when another recording already holds the microphone.
  static String get microphoneBusy => _english.microphoneBusy;

  /// The recorder refused to start a take.
  static String get audioStartFailed => _english.audioStartFailed;

  /// Recovery for [audioStartFailed].
  static String get audioStartFailedRecovery =>
      _english.audioStartFailedRecovery;

  /// A browser take refused more audio at its length cap.
  static String get audioTakeLimitReached => _english.audioTakeLimitReached;

  /// Recovery for [audioTakeLimitReached].
  static String get audioTakeLimitReachedRecovery =>
      _english.audioTakeLimitReachedRecovery;

  /// A recording path that would leave the storage folder.
  static String get audioPathOutsideStorage => _english.audioPathOutsideStorage;

  /// Microphone permission failure and recovery.
  static String get audioPermissionDenied => _english.audioPermissionDenied;

  /// Tells the operator how to grant microphone access.
  static String get audioPermissionRecovery => _english.audioPermissionRecovery;

  /// Recorder phase, without the elapsed time the recording bar shows.
  static String audioRecorderStatus(String phase) =>
      _english.audioRecorderStatus(phase);

  /// Recording bar control that starts a recording with a live transcript.
  static String get liveTranscriptStart => _english.liveTranscriptStart;

  /// Recording bar control that discards the recording in progress.
  static String get liveTranscriptCancel => _english.liveTranscriptCancel;

  /// Recording bar status while the microphone opens.
  static String get liveTranscriptStatusStarting =>
      _english.liveTranscriptStatusStarting;

  /// Recording bar status while audio is recorded and transcribed.
  static String get liveTranscriptStatusListening =>
      _english.liveTranscriptStatusListening;

  /// Recording bar status while the recording is paused.
  static String get liveTranscriptStatusPaused =>
      _english.liveTranscriptStatusPaused;

  /// Recording bar status while the recording is closed and the transcript
  /// completes.
  static String get liveTranscriptStatusFinishing =>
      _english.liveTranscriptStatusFinishing;

  /// Transcript view before any words are recognised.
  static String get liveTranscriptEmpty => _english.liveTranscriptEmpty;

  /// Transcript view control that scrolls back to the newest words.
  static String get liveTranscriptJumpToLatest =>
      _english.liveTranscriptJumpToLatest;

  /// Accessible name of the transcript view.
  static String get transcriptViewLabel => _english.transcriptViewLabel;

  /// Audio evidence association sheet.
  static String get captureAudioScopeTitle => _english.captureAudioScopeTitle;

  /// Associates the clip with the most recent/current photo.
  static String get captureAudioCurrentPhoto =>
      _english.captureAudioCurrentPhoto;

  /// Associates the clip with the selected photos.
  static String captureAudioSelectedPhotos(int count) =>
      _english.captureAudioSelectedPhotos(count);

  /// Associates the clip with every photo.
  static String captureAudioAllPhotos(int count) =>
      _english.captureAudioAllPhotos(count);

  /// Number of durable clips in this capture.
  static String captureAudioCount(int count) =>
      _english.captureAudioCount(count);

  /// Delete photo confirm title.
  static String get captureDeletePhotoTitle => _english.captureDeletePhotoTitle;

  /// Delete photo confirm body.
  static String get captureDeletePhotoMessage =>
      _english.captureDeletePhotoMessage;

  /// Undo delete snack.
  static String get captureUndoDelete => _english.captureUndoDelete;

  /// Photo deleted snack.
  static String get capturePhotoDeleted => _english.capturePhotoDeleted;

  /// Move photos action.
  static String get captureMovePhotos => _english.captureMovePhotos;

  /// Recovery prompt title.
  static String get captureRecoveryTitle => _english.captureRecoveryTitle;

  /// Recovery prompt with photo count.
  static String captureRecoveryMessage(int photos) =>
      _english.captureRecoveryMessage(photos);

  /// Resume interrupted session.
  static String get captureResume => _english.captureResume;

  /// Discard interrupted session.
  static String get captureDiscard => _english.captureDiscard;

  /// A discarded session, offered back through Undo.
  static String get captureSessionDiscarded => _english.captureSessionDiscarded;

  /// Rapid mode title.
  static String get captureRapidMode => _english.captureRapidMode;

  /// One saved item in the rapid-mode list, numbered from 1.
  static String captureRapidItem(int number) =>
      _english.captureRapidItem(number);

  /// A saved rapid-mode item's line: its photo count, then its caption.
  static String captureRapidSummary(int photos, String caption) =>
      _english.captureRapidSummary(photos, caption);

  /// Rapid mode's one-tap action: save this item raw and start the next.
  static String get captureRapidNext => _english.captureRapidNext;

  /// Rapid mode's secondary action: queue every item of the run.
  static String captureRapidProcessAll(int count) =>
      _english.captureRapidProcessAll(count);

  /// Rapid mode queued the run for processing.
  static String captureRapidQueued(int count) =>
      _english.captureRapidQueued(count);

  /// Rapid mode before any item is saved.
  static String get captureRapidEmptyHeadline =>
      _english.captureRapidEmptyHeadline;

  /// What to do first in rapid mode.
  static String get captureRapidEmptyMessage =>
      _english.captureRapidEmptyMessage;

  /// The photos of the item being captured in rapid mode.
  static String captureRapidCurrent(int photos) =>
      _english.captureRapidCurrent(photos);

  /// Storage warning, naming the free space left.
  static String captureStorageLow(String free) =>
      _english.captureStorageLow(free);

  /// Storage stop, naming the free space left and the way out.
  static String captureStorageFull(String free) =>
      _english.captureStorageFull(free);

  /// Storage stop offers export.
  static String get captureStorageExport => _english.captureStorageExport;

  /// A project with no templates still captures; this offers adding one.
  static String get captureNoTemplates => _english.captureNoTemplates;

  /// Template picker title.
  static String get capturePickTemplate => _english.capturePickTemplate;

  /// Pin template for this session.
  static String get capturePinSession => _english.capturePinSession;

  /// A template was pinned to the current context level.
  static String get captureTemplatePinned => _english.captureTemplatePinned;

  /// Pin template for this context level.
  static String get capturePinContext => _english.capturePinContext;

  /// Multi-select count.
  static String captureSelectedCount(int n) => _english.captureSelectedCount(n);

  /// Select all photos.
  static String get captureSelectAll => _english.captureSelectAll;

  /// Clear photo selection.
  static String get captureClearSelection => _english.captureClearSelection;

  /// Add photo to tray.
  static String get captureAddPhoto => _english.captureAddPhoto;

  /// Sheet title for adding a photo.
  static String get captureAddSheetTitle => _english.captureAddSheetTitle;

  /// Camera action on the add-photo sheet.
  static String get captureTakePhoto => _english.captureTakePhoto;

  /// Library action on the add-photo sheet.
  static String get captureChoosePhoto => _english.captureChoosePhoto;

  /// Quality blur advisory.
  static String get captureQualityBlur => _english.captureQualityBlur;

  /// Quality dark advisory.
  static String get captureQualityDark => _english.captureQualityDark;

  /// Quality overexposed advisory.
  static String get captureQualityBright => _english.captureQualityBright;

  /// Quality small-text advisory.
  static String get captureQualitySmallText => _english.captureQualitySmallText;

  /// Saved announcement for screen readers.
  static String get captureSaved => _english.captureSaved;

  /// Saving announcement.
  static String get captureSaving => _english.captureSaving;

  /// Save failed announcement.
  static String get captureSaveFailed => _english.captureSaveFailed;

  /// Raw evidence committed, but the local processing job did not enqueue.
  static String get captureEnqueueFailed => _english.captureEnqueueFailed;

  /// A save with nothing to save.
  static String get captureNeedsEvidence => _english.captureNeedsEvidence;

  /// What to do about [captureNeedsEvidence].
  static String get captureNeedsEvidenceRecovery =>
      _english.captureNeedsEvidenceRecovery;

  /// A reorder that would drop photos.
  static String get captureOrderIncomplete => _english.captureOrderIncomplete;

  /// What to do about [captureOrderIncomplete].
  static String get captureOrderIncompleteRecovery =>
      _english.captureOrderIncompleteRecovery;

  /// A capture change the device could not store.
  static String get captureChangeNotSaved => _english.captureChangeNotSaved;

  /// What to do about [captureChangeNotSaved].
  static String get captureChangeNotSavedRecovery =>
      _english.captureChangeNotSavedRecovery;

  /// Editing a saved record where no record store is available.
  static String get captureRecordsUnavailable =>
      _english.captureRecordsUnavailable;

  /// What to do about [captureRecordsUnavailable].
  static String get captureRecordsUnavailableRecovery =>
      _english.captureRecordsUnavailableRecovery;

  /// Status line when no template is pinned.
  static String get statusNoTemplate => _english.statusNoTemplate;

  /// Project and context together on the status line.
  static String statusWhere(String project, String context) =>
      _english.statusWhere(project, context);

  /// Unmetered path.
  static String get networkOnline => _english.networkOnline;

  /// Metered path.
  static String get networkMetered => _english.networkMetered;

  /// Radio is down; not an operator choice.
  static String get networkOffline => _english.networkOffline;

  /// The operator forced offline.
  static String get networkOfflineByChoice => _english.networkOfflineByChoice;

  /// Manual offline switch title.
  static String get settingsOfflineTitle => _english.settingsOfflineTitle;

  /// What keeps working while the switch is on.
  static String get settingsOfflineEffect => _english.settingsOfflineEffect;

  /// How many records still need processing.
  static String unprocessedCount(int n) => _english.unprocessedCount(n);

  /// A count on a small badge, locale-formatted and capped so 200 percent
  /// text cannot push the icon out. The control's label keeps the exact
  /// count.
  static String badgeCount(int n) => _english.badgeCount(n);

  /// Why work continues without a network. Not an error.
  static String get offlineWorking => _english.offlineWorking;

  /// Title of the last-resort crash recovery screen.
  static String get somethingWentWrong => _english.somethingWentWrong;

  /// Reassurance that a crash did not wipe local work.
  static String get workStillOnDevice => _english.workStillOnDevice;

  /// Remounts the failed subtree under the existing provider scope.
  static String get restart => _english.restart;

  /// Writes the diagnostics buffer to a shareable file.
  static String get exportLog => _english.exportLog;

  /// Opens the recycle bin.
  static String get openRecycleBin => _english.openRecycleBin;

  /// Title of the page an unknown path opens.
  static String get notFoundTitle => _english.notFoundTitle;

  /// Why an unknown path shows no screen. [path] is shown as given.
  static String notFoundMessage(String path) => _english.notFoundMessage(path);

  /// Recovery for an unknown path. Try again opens Projects.
  static String get notFoundRecovery => _english.notFoundRecovery;

  /// Window and task-switcher title of the development install.
  static String get appNameDev => _english.appNameDev;

  /// Settings root title.
  static String get settingsTitle => _english.settingsTitle;

  /// Settings index group headings.
  static String get settingsGroupProfileCapture =>
      _english.settingsGroupProfileCapture;

  /// Settings for AI and visual appearance.
  static String get settingsGroupIntelligenceAppearance =>
      _english.settingsGroupIntelligenceAppearance;

  /// Settings for durable storage and access protection.
  static String get settingsGroupStorageSecurity =>
      _english.settingsGroupStorageSecurity;

  /// Product information settings group.
  static String get settingsGroupAbout => _english.settingsGroupAbout;

  /// Operator tile supporting line.
  static String get settingsOperatorSubtitle =>
      _english.settingsOperatorSubtitle;

  /// Capture tile supporting line.
  static String get settingsCaptureSubtitle => _english.settingsCaptureSubtitle;

  /// Capture settings: the row and its page share this title, and it is
  /// not the Capture destination's name.
  static String get settingsCaptureTitle => _english.settingsCaptureTitle;

  /// Relay row under Settings.
  static String get settingsRelaySubtitle => _english.settingsRelaySubtitle;

  /// AI section title. The screen arrives in a later phase.
  static String get settingsAiTitle => _english.settingsAiTitle;

  /// AI tile supporting line.
  static String get settingsAiSubtitle => _english.settingsAiSubtitle;

  /// Language section title. The screen arrives in a later phase.
  static String get settingsLanguageTitle => _english.settingsLanguageTitle;

  /// Language tile supporting line.
  static String get settingsLanguageSubtitle =>
      _english.settingsLanguageSubtitle;

  /// The language screens and messages are shown in.
  static String get settingsAppLanguage => _english.settingsAppLanguage;

  /// Why the app language offers one choice today.
  static String get settingsAppLanguageEffect =>
      _english.settingsAppLanguageEffect;

  /// The language dictation listens for.
  static String get settingsVoiceLanguage => _english.settingsVoiceLanguage;

  /// Voice-language names, each in its own language's usual English name.
  static String get languageEnglish => _english.languageEnglish;

  /// French.
  static String get languageFrench => _english.languageFrench;

  /// Swahili.
  static String get languageSwahili => _english.languageSwahili;

  /// Portuguese.
  static String get languagePortuguese => _english.languagePortuguese;

  /// Spanish.
  static String get languageSpanish => _english.languageSpanish;

  /// Arabic.
  static String get languageArabic => _english.languageArabic;

  /// Appearance section title.
  static String get settingsAppearanceTitle => _english.settingsAppearanceTitle;

  /// Appearance tile supporting line.
  static String get settingsAppearanceSubtitle =>
      _english.settingsAppearanceSubtitle;

  /// Follow the device light or dark setting.
  static String get themeModeSystem => _english.themeModeSystem;

  /// Always the light palette.
  static String get themeModeLight => _english.themeModeLight;

  /// Always the dark palette.
  static String get themeModeDark => _english.themeModeDark;

  /// High-contrast outdoor palettes; still follows the device.
  static String get themeModeOutdoor => _english.themeModeOutdoor;

  /// Storage section title.
  static String get settingsStorageTitle => _english.settingsStorageTitle;

  /// Storage tile supporting line.
  static String get settingsStorageSubtitle => _english.settingsStorageSubtitle;

  /// Specification "Data" section. Copy rejects the word "data".
  static String get settingsFilesTitle => _english.settingsFilesTitle;

  /// Files tile supporting line.
  static String get settingsFilesSubtitle => _english.settingsFilesSubtitle;

  /// Files row that opens the open project's exports.
  static String get settingsFilesExportSubtitle =>
      _english.settingsFilesExportSubtitle;

  /// Files row that brings a package or spreadsheet in.
  static String get settingsFilesImportSubtitle =>
      _english.settingsFilesImportSubtitle;

  /// Files row that opens the open project's merge.
  static String get settingsFilesMergeSubtitle =>
      _english.settingsFilesMergeSubtitle;

  /// Why export and merge are not offered with no project open.
  static String get settingsFilesNoProject => _english.settingsFilesNoProject;

  /// Files row for past uploads.
  static String get settingsFilesUploadsSubtitle =>
      _english.settingsFilesUploadsSubtitle;

  /// Security section title. The screen arrives in a later phase.
  static String get settingsSecurityTitle => _english.settingsSecurityTitle;

  /// Security tile supporting line.
  static String get settingsSecuritySubtitle =>
      _english.settingsSecuritySubtitle;

  /// About section title.
  static String get settingsAboutTitle => _english.settingsAboutTitle;

  /// About tile supporting line.
  static String get settingsAboutSubtitle => _english.settingsAboutSubtitle;

  /// Templates row under Settings.
  static String get settingsTemplatesSubtitle =>
      _english.settingsTemplatesSubtitle;

  /// Unprocessed row under Settings.
  static String get settingsQueueSubtitle => _english.settingsQueueSubtitle;

  /// Camera default row.
  static String get settingsCamera => _english.settingsCamera;

  /// Effect of the camera default.
  static String get settingsCameraEffect => _english.settingsCameraEffect;

  /// Label for the photo camera default.
  static String get settingsCameraPhoto => _english.settingsCameraPhoto;

  /// Document camera default.
  static String get settingsCameraDocument => _english.settingsCameraDocument;

  /// Auto-filled dates row.
  static String get settingsAutoFillDates => _english.settingsAutoFillDates;

  /// Effect of auto-filled dates.
  static String get settingsAutoFillDatesEffect =>
      _english.settingsAutoFillDatesEffect;

  /// GPS row.
  static String get settingsGps => _english.settingsGps;

  /// Why GPS stays off until a person turns it on (FE-SEC-07).
  static String get settingsGpsWhyOff => _english.settingsGpsWhyOff;

  /// Photo quality row.
  static String get settingsPhotoQuality => _english.settingsPhotoQuality;

  /// Effect of photo quality.
  static String get settingsPhotoQualityEffect =>
      _english.settingsPhotoQualityEffect;

  /// Standard JPEG quality label.
  static String get settingsQualityStandard => _english.settingsQualityStandard;

  /// Smaller JPEG quality label.
  static String get settingsQualitySmaller => _english.settingsQualitySmaller;

  /// Folder strategy row.
  static String get settingsFolderStrategy => _english.settingsFolderStrategy;

  /// Folder strategy applies only to files not yet written.
  static String get settingsFolderStrategyNewFilesOnly =>
      _english.settingsFolderStrategyNewFilesOnly;

  /// Folder strategy: group by context.
  static String get settingsFolderByContext => _english.settingsFolderByContext;

  /// Folder strategy: group by template.
  static String get settingsFolderByTemplate =>
      _english.settingsFolderByTemplate;

  /// Folder strategy: group by capture date.
  static String get settingsFolderByDate => _english.settingsFolderByDate;

  /// Folder strategy: no extra folders.
  static String get settingsFolderFlat => _english.settingsFolderFlat;

  /// Naming pattern row.
  static String get settingsNamingPattern => _english.settingsNamingPattern;

  /// Sheet title when editing the naming pattern.
  static String get settingsNamingEdit => _english.settingsNamingEdit;

  /// Effect of the naming pattern.
  static String get settingsNamingPatternEffect =>
      _english.settingsNamingPatternEffect;

  /// Camera row, including the current value and its effect.
  static String settingsCameraSubtitle(String label) =>
      _english.settingsCameraSubtitle(label);

  /// Photo-quality row, including the current value and its effect.
  static String settingsPhotoQualitySubtitle(String label) =>
      _english.settingsPhotoQualitySubtitle(label);

  /// Naming-pattern row, including the current value and its effect.
  static String settingsNamingSubtitle(String pattern) =>
      _english.settingsNamingSubtitle(pattern);

  /// Folder strategy row, including the new-files-only statement.
  static String settingsFolderStrategySubtitle(String strategy) =>
      _english.settingsFolderStrategySubtitle(strategy);

  /// Projects group on the storage screen.
  static String get settingsProjectsHeader => _english.settingsProjectsHeader;

  /// Free-space group on the storage screen.
  static String get settingsHeadroomHeader => _english.settingsHeadroomHeader;

  /// Retention group on the storage screen.
  static String get settingsRetentionHeader => _english.settingsRetentionHeader;

  /// Storage-root row name.
  static String get settingsStorageRoot => _english.settingsStorageRoot;

  /// Snack after a new storage folder is saved: files move there on restart.
  static String get settingsStorageRootAfterRestart =>
      _english.settingsStorageRootAfterRestart;

  /// Total volume label.
  static String get settingsVolumeTotal => _english.settingsVolumeTotal;

  /// Used volume label.
  static String get settingsVolumeUsed => _english.settingsVolumeUsed;

  /// Available volume label.
  static String get settingsVolumeAvailable => _english.settingsVolumeAvailable;

  /// The three volume figures on one line.
  static String settingsVolumeFigures({
    required String total,
    required String used,
    required String available,
  }) => _english.settingsVolumeFigures(
    total: total,
    used: used,
    available: available,
  );

  /// Headroom is ample.
  static String get settingsHeadroomAmple => _english.settingsHeadroomAmple;

  /// Headroom is low.
  static String get settingsHeadroomLow => _english.settingsHeadroomLow;

  /// Headroom is critical.
  static String get settingsHeadroomCritical =>
      _english.settingsHeadroomCritical;

  /// Clear-cache row.
  static String get settingsClearCache => _english.settingsClearCache;

  /// Effect of clearing the cache.
  static String get settingsClearCacheEffect =>
      _english.settingsClearCacheEffect;

  /// Cache row with the current size.
  static String settingsCacheSize(String size) =>
      _english.settingsCacheSize(size);

  /// Retention row with the current window.
  static String settingsRetentionSubtitle(int days) =>
      _english.settingsRetentionSubtitle(days);

  /// Confirm title for clearing the cache.
  static String get settingsClearCacheTitle => _english.settingsClearCacheTitle;

  /// Confirm body for clearing the cache.
  static String get settingsClearCacheMessage =>
      _english.settingsClearCacheMessage;

  /// Storage row, and the page, that checks files against their records.
  static String get storageCheckTitle => _english.storageCheckTitle;

  /// What checking files does.
  static String get storageCheckSubtitle => _english.storageCheckSubtitle;

  /// Heading over the check of the database's own references.
  static String get storageCheckDatabaseHeader =>
      _english.storageCheckDatabaseHeader;

  /// Every reference in the database resolves.
  static String get storageCheckDatabaseClean =>
      _english.storageCheckDatabaseClean;

  /// One broken reference: the table it sits in and the row's id.
  static String storageCheckFindingRow(String table, String id) =>
      _english.storageCheckFindingRow(table, id);

  /// Heading over the open project's file check.
  static String storageCheckProjectHeader(String project) =>
      _english.storageCheckProjectHeader(project);

  /// No project is open, so there is no folder to check.
  static String get storageCheckNoProject => _english.storageCheckNoProject;

  /// The open project's folder and its records agree.
  static String get storageCheckFilesClean => _english.storageCheckFilesClean;

  /// The file check cannot run where the app keeps no project files.
  static String get storageCheckFilesUnavailable =>
      _english.storageCheckFilesUnavailable;

  /// What to do when the file check cannot run here.
  static String get storageCheckFilesUnavailableAction =>
      _english.storageCheckFilesUnavailableAction;

  /// Heading over files no record points at.
  static String get storageCheckStrayHeader => _english.storageCheckStrayHeader;

  /// A stray file: its size and what tapping it does.
  static String storageCheckStraySubtitle(String size) =>
      _english.storageCheckStraySubtitle(size);

  /// Heading over records whose file is gone.
  static String get storageCheckMissingHeader =>
      _english.storageCheckMissingHeader;

  /// A record whose file is gone, before it is marked.
  static String get storageCheckMissingSubtitle =>
      _english.storageCheckMissingSubtitle;

  /// Confirm title for marking a file as missing.
  static String get storageCheckFlagTitle => _english.storageCheckFlagTitle;

  /// Confirm body for marking a file as missing.
  static String get storageCheckFlagMessage => _english.storageCheckFlagMessage;

  /// Confirm action for marking a file as missing.
  static String get storageCheckFlagConfirm => _english.storageCheckFlagConfirm;

  /// Outcome after marking a file as missing.
  static String get storageCheckFlagged => _english.storageCheckFlagged;

  /// Sheet title for attaching a stray file to a record.
  static String get storageCheckAttachTitle => _english.storageCheckAttachTitle;

  /// Outcome after attaching a stray file.
  static String get storageCheckAttached => _english.storageCheckAttached;

  /// The project has no record to attach a file to.
  static String get storageCheckNoRecords => _english.storageCheckNoRecords;

  /// Why a stray file cannot be attached yet.
  static String get storageCheckNoRecordsMessage =>
      _english.storageCheckNoRecordsMessage;

  /// Retention row.
  static String get settingsRetention => _english.settingsRetention;

  /// Effect of the retention window.
  static String get settingsRetentionEffect => _english.settingsRetentionEffect;

  /// Retention window in days.
  static String settingsRetentionDays(int n) =>
      _english.settingsRetentionDays(n);

  /// Documents breakdown label.
  static String get settingsDocuments => _english.settingsDocuments;

  /// Audio breakdown label.
  static String get settingsAudio => _english.settingsAudio;

  /// Exports breakdown label.
  static String get settingsExports => _english.settingsExports;

  /// Cache usage row title.
  static String get settingsCache => _english.settingsCache;

  /// Empty storage headline.
  static String get settingsStorageEmptyHeadline =>
      _english.settingsStorageEmptyHeadline;

  /// Empty storage next step.
  static String get settingsStorageEmptyMessage =>
      _english.settingsStorageEmptyMessage;

  /// A file size shown on the storage screen.
  static String fileSize(int bytes) => _english.fileSize(bytes);

  /// Per-project breakdown on one line.
  static String settingsProjectUse({
    required String photos,
    required String documents,
    required String audio,
    required String exports,
  }) => _english.settingsProjectUse(
    photos: photos,
    documents: documents,
    audio: audio,
    exports: exports,
  );

  /// Version row.
  static String get settingsVersion => _english.settingsVersion;

  /// Build-number row.
  static String get settingsBuild => _english.settingsBuild;

  /// Licences row.
  static String get settingsLicences => _english.settingsLicences;

  /// Effect of the licences row.
  static String get settingsLicencesEffect => _english.settingsLicencesEffect;

  /// About row linking the development plan.
  static String get settingsPlanLink => _english.settingsPlanLink;

  /// About row linking the product specification.
  static String get settingsSpecLink => _english.settingsSpecLink;

  /// A link was copied because no browser can be opened from here.
  static String get settingsLinkCopied => _english.settingsLinkCopied;

  /// Empty settings headline.
  static String get settingsEmptyHeadline => _english.settingsEmptyHeadline;

  /// Empty settings next step.
  static String get settingsEmptyMessage => _english.settingsEmptyMessage;

  /// Empty capture-settings headline.
  static String get settingsCaptureEmptyHeadline =>
      _english.settingsCaptureEmptyHeadline;

  /// Empty capture-settings next step.
  static String get settingsCaptureEmptyMessage =>
      _english.settingsCaptureEmptyMessage;

  /// Empty about headline.
  static String get settingsAboutEmptyHeadline =>
      _english.settingsAboutEmptyHeadline;

  /// Empty about next step.
  static String get settingsAboutEmptyMessage =>
      _english.settingsAboutEmptyMessage;

  /// Unlock-gate title.
  static String get appLockUnlockTitle => _english.appLockUnlockTitle;

  /// Settings title for the PIN lock.
  static String get appLockTitle => _english.appLockTitle;

  /// PIN field.
  static String get appLockPin => _english.appLockPin;

  /// Current PIN when changing or removing the lock.
  static String get appLockCurrentPin => _english.appLockCurrentPin;

  /// New PIN when setting or changing the lock.
  static String get appLockNewPin => _english.appLockNewPin;

  /// Confirm-PIN field.
  static String get appLockConfirmPin => _english.appLockConfirmPin;

  /// Sets the lock for the first time.
  static String get appLockSet => _english.appLockSet;

  /// Replaces the stored PIN.
  static String get appLockChange => _english.appLockChange;

  /// Turns the lock off.
  static String get appLockRemove => _english.appLockRemove;

  /// Unlock-gate submit.
  static String get appLockUnlock => _english.appLockUnlock;

  /// Offers the device biometric path when it is enrolled.
  static String get appLockBiometrics => _english.appLockBiometrics;

  /// Effect of setting a PIN.
  static String get appLockSetEffect => _english.appLockSetEffect;

  /// Effect of removing the PIN.
  static String get appLockRemoveEffect => _english.appLockRemoveEffect;

  /// Confirm title before the PIN is removed.
  static String get appLockRemoveConfirmTitle =>
      _english.appLockRemoveConfirmTitle;

  /// Helper under the current-PIN field while the lock is on.
  static String get appLockCurrentPinHelper => _english.appLockCurrentPinHelper;

  /// Remove was chosen with the current-PIN field empty.
  static String get appLockRemoveNeedsPin => _english.appLockRemoveNeedsPin;

  /// Stated when the lock is armed.
  static String get appLockOn => _english.appLockOn;

  /// Stated when no PIN is stored.
  static String get appLockOff => _english.appLockOff;

  /// PIN shape.
  static String get appLockPinLength => _english.appLockPinLength;

  /// Confirm field does not match.
  static String get appLockPinMismatch => _english.appLockPinMismatch;

  /// Submitted PIN does not match the stored hash.
  static String get appLockWrongPin => _english.appLockWrongPin;

  /// Recovery path. Does not offer a wipe (FE-SIMP-09).
  static String get appLockRecovery => _english.appLockRecovery;

  /// Closes a dialog or panel without acting.
  static String get close => _english.close;

  /// The floating feedback control: its label, tooltip and semantic name.
  static String get feedback => _english.feedback;

  /// How the floating feedback control behaves, for screen readers.
  static String get feedbackButtonHint => _english.feedbackButtonHint;

  /// Opens the form to write feedback.
  static String get feedbackGive => _english.feedbackGive;

  /// Opens the filter to download feedback as a spreadsheet and screenshots.
  static String get feedbackDownload => _english.feedbackDownload;

  /// Opens the filter to delete feedback.
  static String get feedbackDelete => _english.feedbackDelete;

  /// Where feedback goes. Nothing is sent (FE-SEC-10).
  static String get feedbackStaysOnDevice => _english.feedbackStaysOnDevice;

  /// Feedback type: anything that is not one of the others.
  static String get feedbackCategoryGeneral => _english.feedbackCategoryGeneral;

  /// Feedback type: something that works but could work better.
  static String get feedbackCategoryImprovement =>
      _english.feedbackCategoryImprovement;

  /// Feedback type: something is wrong.
  static String get feedbackCategoryError => _english.feedbackCategoryError;

  /// Feedback type: an idea.
  static String get feedbackCategorySuggestion =>
      _english.feedbackCategorySuggestion;

  /// Feedback type: the operator names it.
  static String get feedbackCategoryOther => _english.feedbackCategoryOther;

  /// Who wrote an entry: enrolled with the organisation.
  static String get feedbackSubmitterSignedIn =>
      _english.feedbackSubmitterSignedIn;

  /// Who wrote an entry: a named local operator.
  static String get feedbackSubmitterLocal => _english.feedbackSubmitterLocal;

  /// Who wrote an entry: no name was set.
  static String get feedbackSubmitterAnonymous =>
      _english.feedbackSubmitterAnonymous;

  /// Device kind: a touch phone.
  static String get feedbackDeviceMobile => _english.feedbackDeviceMobile;

  /// Device kind: a touch tablet.
  static String get feedbackDeviceTablet => _english.feedbackDeviceTablet;

  /// Device kind: a desktop, natively or in a desktop browser.
  static String get feedbackDeviceDesktop => _english.feedbackDeviceDesktop;

  /// Label of the feedback type choice.
  static String get feedbackType => _english.feedbackType;

  /// Label of the field that names an "other" type.
  static String get feedbackOtherType => _english.feedbackOtherType;

  /// The "other" type was chosen but not named.
  static String get feedbackOtherRequired => _english.feedbackOtherRequired;

  /// Label of the feedback text.
  static String get feedbackMessage => _english.feedbackMessage;

  /// Prompt inside the empty feedback text.
  static String get feedbackMessageHint => _english.feedbackMessageHint;

  /// The feedback text was empty.
  static String get feedbackMessageRequired => _english.feedbackMessageRequired;

  /// Attaches the screenshot taken when Feedback was tapped.
  static String get feedbackAttachScreenshot =>
      _english.feedbackAttachScreenshot;

  /// Continues a feedback draft started on another screen.
  static String get feedbackContinue => _english.feedbackContinue;

  /// Adds a screenshot of the screen currently under the overlay.
  static String get feedbackAddScreen => _english.feedbackAddScreen;

  /// Opt-in so Screenshot current screen includes the Give us feedback chrome.
  /// Short enough to stay on one line beside its checkbox at 360 dp.
  static String get feedbackIncludeUi => _english.feedbackIncludeUi;

  /// Opens the browser display picker for another window or OS surface.
  static String get feedbackAddWindow => _english.feedbackAddWindow;

  /// Stops the shared window so later taps open the picker again.
  static String get feedbackStopSharing => _english.feedbackStopSharing;

  /// Non-colour signal that Screenshot external window is live.
  static String get feedbackSharingWindow => _english.feedbackSharingWindow;

  /// Label of a still taken from another window.
  static String get feedbackOtherWindow => _english.feedbackOtherWindow;

  /// Opens the device camera for a photo to attach.
  static String get feedbackTakePhoto => _english.feedbackTakePhoto;

  /// Opens the device library for photos to attach.
  static String get feedbackChoosePhoto => _english.feedbackChoosePhoto;

  /// How to capture another Tapture screen when other windows cannot be
  /// shared.
  static String get feedbackShotTipScreens => _english.feedbackShotTipScreens;

  /// How to attach a system screenshot of another app.
  static String get feedbackShotTipApps => _english.feedbackShotTipApps;

  /// The attach checkbox, counting the images it covers.
  static String feedbackAttachImages(int n) => _english.feedbackAttachImages(n);

  /// How many images a kept draft holds, for the compact bar.
  static String feedbackImageCount(int n) => _english.feedbackImageCount(n);

  /// Semantic name of a larger attached-photo preview.
  static String get feedbackShotPreview => _english.feedbackShotPreview;

  /// Discards the in-progress feedback draft.
  static String get feedbackDiscardDraft => _english.feedbackDiscardDraft;

  /// Title of the discard-draft confirm.
  static String get feedbackDiscardDraftTitle =>
      _english.feedbackDiscardDraftTitle;

  /// Body of the discard-draft confirm, naming the image count (FE-SIMP-07).
  static String feedbackDiscardDraftMessage(int images) =>
      _english.feedbackDiscardDraftMessage(images);

  /// Collapses the feedback form so the rest of the app stays usable.
  static String get feedbackContinueLater => _english.feedbackContinueLater;

  /// Compact bar while a draft is kept across screens.
  static String get feedbackDraftBarHint => _english.feedbackDraftBarHint;

  /// Announced when a screenshot of [screen] was added to the draft.
  static String feedbackShotAdded(String screen) =>
      _english.feedbackShotAdded(screen);

  /// The draft already holds as many photos as it will take.
  static String get feedbackShotsFull => _english.feedbackShotsFull;

  /// What the screenshot shows, named for the screen it was taken on.
  static String feedbackScreenshotOf(String screen) =>
      _english.feedbackScreenshotOf(screen);

  /// The draft holds no screenshot or photo yet.
  static String get feedbackNoScreenshot => _english.feedbackNoScreenshot;

  /// Semantic name of the screenshot preview.
  static String get feedbackScreenshotPreview =>
      _english.feedbackScreenshotPreview;

  /// Saves the feedback entry.
  static String get feedbackSave => _english.feedbackSave;

  /// Announced once the entry is durable.
  static String get feedbackSaved => _english.feedbackSaved;

  /// Filter: feedback types.
  static String get feedbackTypes => _english.feedbackTypes;

  /// Filter: earliest submission.
  static String get feedbackFrom => _english.feedbackFrom;

  /// Filter: latest submission.
  static String get feedbackTo => _english.feedbackTo;

  /// The date range runs backwards.
  static String get feedbackRangeBackwards => _english.feedbackRangeBackwards;

  /// Filter: screens feedback was given on.
  static String get feedbackScreens => _english.feedbackScreens;

  /// Filter: platforms.
  static String get feedbackPlatforms => _english.feedbackPlatforms;

  /// Filter: device types.
  static String get feedbackDeviceTypes => _english.feedbackDeviceTypes;

  /// Filter: who submitted.
  static String get feedbackSubmittedBy => _english.feedbackSubmittedBy;

  /// Filter: whether a screenshot is attached.
  static String get feedbackScreenshot => _english.feedbackScreenshot;

  /// Screenshot filter: either way.
  static String get feedbackScreenshotAny => _english.feedbackScreenshotAny;

  /// Screenshot filter: attached.
  static String get feedbackScreenshotWith => _english.feedbackScreenshotWith;

  /// Screenshot filter: not attached.
  static String get feedbackScreenshotWithout =>
      _english.feedbackScreenshotWithout;

  /// Prompt on the feedback text search.
  static String get feedbackSearch => _english.feedbackSearch;

  /// Resets every feedback filter.
  static String get feedbackClearFilters => _english.feedbackClearFilters;

  /// How many entries the filters let through.
  static String feedbackMatching(int matching, int total) =>
      _english.feedbackMatching(matching, total);

  /// Downloads the matching entries.
  static String feedbackDownloadCount(int n) =>
      _english.feedbackDownloadCount(n);

  /// The browser took the download.
  static String get feedbackDownloadStarted => _english.feedbackDownloadStarted;

  /// The archive was written to [location] on this device.
  static String feedbackDownloadedTo(String location) =>
      _english.feedbackDownloadedTo(location);

  /// Shared Downloads subfolder on Android and desktop. The › mirrors with
  /// the surrounding line in right-to-left layouts (FE-L10N-05).
  static String get downloadsTaptureFolder => _english.downloadsTaptureFolder;

  /// Where archives land, before anything is downloaded.
  static String feedbackDownloadsGoTo(String place) =>
      _english.feedbackDownloadsGoTo(place);

  /// Opens the system Downloads view or the Tapture folder.
  static String get feedbackOpenFolder => _english.feedbackOpenFolder;

  /// Opens the system picker so the archive can be saved anywhere.
  static String get feedbackSaveToFolder => _english.feedbackSaveToFolder;

  /// Warning when [place] could not be opened.
  static String feedbackOpenFolderFailed(String place) =>
      _english.feedbackOpenFolderFailed(place);

  /// Nothing has been written yet.
  static String get feedbackEmptyHeadline => _english.feedbackEmptyHeadline;

  /// Next step when nothing has been written (FE-SIMP-11).
  static String get feedbackEmptyMessage => _english.feedbackEmptyMessage;

  /// The filters let nothing through.
  static String get feedbackNoMatchHeadline => _english.feedbackNoMatchHeadline;

  /// Next step when the filters let nothing through.
  static String get feedbackNoMatchMessage => _english.feedbackNoMatchMessage;

  /// How many entries are ticked for deletion.
  static String feedbackSelected(int n) => _english.feedbackSelected(n);

  /// Deletes the ticked entries.
  static String feedbackDeleteCount(int n) => _english.feedbackDeleteCount(n);

  /// Title of the delete confirm, naming the count (FE-SIMP-07).
  static String feedbackDeleteTitle(int n) => _english.feedbackDeleteTitle(n);

  /// Body of the delete confirm, naming the consequence (FE-SIMP-07).
  static String feedbackDeleteMessage(int n) =>
      _english.feedbackDeleteMessage(n);

  /// Announced once the entries are gone.
  static String feedbackDeleted(int n) => _english.feedbackDeleted(n);

  /// Loads the next page of entries.
  static String get feedbackShowMore => _english.feedbackShowMore;

  /// One entry's facts on a list row: type, when and where.
  static String feedbackEntryFacts(String type, String when, String screen) =>
      _english.feedbackEntryFacts(type, when, screen);

  /// One entry's title on a list row: number, Feedback ID and message.
  static String feedbackEntryTitle(
    String number,
    String reference,
    String message,
  ) => _english.feedbackEntryTitle(number, reference, message);

  /// Remaining backoff after a failed unlock.
  static String appLockWait(Duration remaining) =>
      _english.appLockWait(remaining);

  /// Queue screen title.
  static String get queueTitle => _english.queueTitle;

  /// Unprocessed count label.
  static String get queueUnprocessed => _english.queueUnprocessed;

  /// Queued count label.
  static String get queueQueued => _english.queueQueued;

  /// Failed count label.
  static String get queueFailed => _english.queueFailed;

  /// Today's online request and image totals against the project cap.
  static String queueUsage(int requests, int images, int cap) =>
      _english.queueUsage(requests, images, cap);

  /// Unprocessed records, as a complete message.
  static String queueUnprocessedCount(int count) =>
      _english.queueUnprocessedCount(count);

  /// Records waiting in the queue, as a complete message.
  static String queueQueuedCount(int count) => _english.queueQueuedCount(count);

  /// Failed jobs, as a complete message.
  static String queueFailedCount(int count) => _english.queueFailedCount(count);

  /// Context groups in the queue.
  static String get queueGroupsTitle => _english.queueGroupsTitle;

  /// Process every waiting record.
  static String get queueProcessAll => _english.queueProcessAll;

  /// Process the records in one group.
  static String get queueProcessSelected => _english.queueProcessSelected;

  /// Empty queue title.
  static String get queueEmptyHeadline => _english.queueEmptyHeadline;

  /// Empty queue explanation.
  static String get queueEmptyMessage => _english.queueEmptyMessage;

  /// Failures list title.
  static String get queueFailedTitle => _english.queueFailedTitle;

  /// Retry one failed job.
  static String get queueRetry => _english.queueRetry;

  /// What a screen reader calls the retry control on [record]'s row.
  static String queueRetryLabel(String record) =>
      _english.queueRetryLabel(record);

  /// Stop the batch that is running.
  static String get queueCancel => _english.queueCancel;

  /// Why a cancelled batch stopped. Finished work is kept.
  static String get queueCancelled => _english.queueCancelled;

  /// End-of-run summary, then why the run stopped early when it did.
  static String queueSummary(int succeeded, int failed, {String? detail}) =>
      _english.queueSummary(succeeded, failed, detail: detail);

  /// A running batch: records finished so far, then what the current one is
  /// doing when known.
  static String queueProgress(int done, int failed, {String? stage}) =>
      _english.queueProgress(done, failed, stage: stage);

  /// Asks before the first online call of a session.
  static String get egressTitle => _english.egressTitle;

  /// Confirms the preview.
  static String get egressSend => _english.egressSend;

  /// Why a batch stopped when its egress preview was declined.
  static String get egressDecline => _english.egressDecline;

  /// What the preview says will be included.
  static String egressBody({required int images, required String size}) =>
      _english.egressBody(images: images, size: size);

  /// Device-held key screen title.
  static String get apiKeyTitle => _english.apiKeyTitle;

  /// States that device custody is the exception.
  static String get apiKeyCustody => _english.apiKeyCustody;

  /// Key field label.
  static String get apiKeyLabel => _english.apiKeyLabel;

  /// Saves the key into secure storage.
  static String get apiKeySave => _english.apiKeySave;

  /// Removes the key and clears the selection.
  static String get apiKeyRemove => _english.apiKeyRemove;

  /// Runs the smallest connection test.
  static String get apiKeyTest => _english.apiKeyTest;

  /// Shown once the key is stored and hidden.
  static String get apiKeySaved => _english.apiKeySaved;

  /// Confirm title before the device key is removed.
  static String get apiKeyRemoveTitle => _english.apiKeyRemoveTitle;

  /// What removing the device key changes.
  static String get apiKeyRemoveMessage => _english.apiKeyRemoveMessage;

  /// Test connection succeeded.
  static String get apiKeySuccess => _english.apiKeySuccess;

  /// The key was rejected.
  static String get apiKeyAuthFailed => _english.apiKeyAuthFailed;

  /// The test could not reach the network.
  static String get apiKeyNetworkFailed => _english.apiKeyNetworkFailed;

  /// The provider answered the test with an error of its own.
  static String get apiKeyTestFailed => _english.apiKeyTestFailed;

  /// Registry-driven AI controls.
  static String get aiOperation => _english.aiOperation;

  /// Provider choice field.
  static String get aiProvider => _english.aiProvider;

  /// Model choice field.
  static String get aiModel => _english.aiModel;

  /// Operator-facing label for an AI operation id.
  static String aiOperationLabel(String value) =>
      _english.aiOperationLabel(value);

  /// Credential custody and live availability explanation.
  static String aiCustody(String custody, bool available) =>
      _english.aiCustody(custody, available);

  /// Saved choice fallback explanation.
  static String get aiSelectionFallback => _english.aiSelectionFallback;

  /// Provider test could not run because the descriptor is unavailable.
  static String get aiProviderUnavailable => _english.aiProviderUnavailable;

  /// Provider and model do not support the selected operation.
  static String get aiSelectionInvalid => _english.aiSelectionInvalid;

  /// Template question.
  static String get templateChoiceTitle => _english.templateChoiceTitle;

  /// Pins the choice to the current place.
  static String get templateChoicePin => _english.templateChoicePin;

  /// No templates to offer.
  static String get templateChoiceEmptyHeadline =>
      _english.templateChoiceEmptyHeadline;

  /// Why the choice sheet is empty.
  static String get templateChoiceEmptyMessage =>
      _english.templateChoiceEmptyMessage;

  /// The third choice when the shortlist is not enough.
  static String get templateChoiceOther => _english.templateChoiceOther;

  /// The step detail when no template was chosen. The record stays queued.
  static String get templateChoiceSkipped => _english.templateChoiceSkipped;

  /// The chosen template could not be applied to the record.
  static String get templateChoiceApplyFailed =>
      _english.templateChoiceApplyFailed;

  /// What to do when the chosen template could not be applied.
  static String get templateChoiceApplyRecovery =>
      _english.templateChoiceApplyRecovery;

  /// A record an unattended run set aside for an operator's template
  /// choice.
  static String get templateChoiceWaiting => _english.templateChoiceWaiting;

  /// A record read on the device, its online work left for later.
  static String get processReadOnDevice => _english.processReadOnDevice;

  /// Preparing images.
  static String get processPreparing => _english.processPreparing;

  /// On-device reading.
  static String get processReading => _english.processReading;

  /// Template detection.
  static String get processDetecting => _english.processDetecting;

  /// Online extraction.
  static String get processExtracting => _english.processExtracting;

  /// Validation.
  static String get processChecking => _english.processChecking;

  /// Local notification title. Counts only.
  static String get processingNotificationTitle =>
      _english.processingNotificationTitle;

  /// Local notification body. Counts only.
  static String processingNotificationBody(int succeeded, int failed) =>
      _english.processingNotificationBody(succeeded, failed);

  /// A document the picker could not hand over.
  static String get documentPickFailed => _english.documentPickFailed;

  /// A chosen file above what this device can open in one piece.
  static String documentTooLarge(int bytes, int ceiling) =>
      _english.documentTooLarge(bytes, ceiling);

  /// What to do about a file that is too large.
  static String get documentTooLargeRecovery =>
      _english.documentTooLargeRecovery;

  /// A stored export that is no longer where the app wrote it.
  static String get storedFileMissing => _english.storedFileMissing;

  /// A package whose project is gone.
  static String get packageProjectMissing => _english.packageProjectMissing;

  /// A package larger than this device writes or opens.
  static String packageTooLarge(int bytes, int ceiling) =>
      _english.packageTooLarge(bytes, ceiling);

  /// What to do about a package that is too large.
  static String get packageTooLargeRecovery => _english.packageTooLargeRecovery;

  /// A package that could not be written.
  static String get packageWriteFailed => _english.packageWriteFailed;

  /// Why a package was refused; [check] is the failed check's name.
  static String packageRejected(String check) =>
      _english.packageRejected(check);

  /// What to do about a refused package.
  static String get packageRejectedRecovery => _english.packageRejectedRecovery;

  /// The row under the Template select that opens the guide.
  static String get captureGuideTitle => _english.captureGuideTitle;

  /// What the photos should show; the template's fields follow.
  static String get captureGuidePhotos => _english.captureGuidePhotos;

  /// What to say or type in the caption; the template's fields follow.
  static String get captureGuideCaption => _english.captureGuideCaption;

  /// A guide list's field labels, which are template data.
  static String captureGuideItems(List<String> labels) =>
      _english.captureGuideItems(labels);

  /// Closes the caption panel of the guide.
  static String get captureGuideClose => _english.captureGuideClose;

  /// Shown while a chosen package is opened and checked.
  static String get importChecking => _english.importChecking;

  /// Title of the sheet that describes a package before it is imported.
  static String get importSheetTitle => _english.importSheetTitle;

  /// Where and when the package was made. [device] is package data.
  static String importFrom(String device, DateTime exportedAt) =>
      _english.importFrom(device, exportedAt);

  /// What the package holds.
  static String importHolds(int records, int photos, int bytes) =>
      _english.importHolds(records, photos, bytes);

  /// How many photos a package or a count covers.
  static String photosCount(int n) => _english.photosCount(n);

  /// Primary action of the import sheet.
  static String get importAsNewProject => _english.importAsNewProject;

  /// Secondary action of the import sheet: merge into a project here.
  static String get importMergeInto => _english.importMergeInto;

  /// Shown while a package's files are copied in.
  static String get importCopying => _english.importCopying;

  /// Announced once the project is in.
  static String importDone(int records) => _english.importDone(records);

  /// A package whose project was deleted on this device is refused.
  static String get importProjectDeletedHere =>
      _english.importProjectDeletedHere;

  /// Recovery for [importProjectDeletedHere].
  static String get importProjectDeletedHereRecovery =>
      _english.importProjectDeletedHereRecovery;

  /// A package whose project is already here does not import a second copy.
  static String get importProjectAlreadyHere =>
      _english.importProjectAlreadyHere;

  /// Recovery for [importProjectAlreadyHere].
  static String get importProjectAlreadyHereRecovery =>
      _english.importProjectAlreadyHereRecovery;

  /// Too little room for the package's files.
  static String get importNoRoom => _english.importNoRoom;

  /// Recovery for [importNoRoom].
  static String get importNoRoomRecovery => _english.importNoRoomRecovery;

  /// A file in the package did not arrive as it left.
  static String get importFileChanged => _english.importFileChanged;

  /// Recovery for any import or merge that stopped part way.
  static String get importFailedRecovery => _english.importFailedRecovery;

  /// Project home overflow item and the merge screen's title.
  static String get mergePackage => _english.mergePackage;

  /// Title of the sheet that chooses which project a package merges into.
  static String get mergeTargetTitle => _english.mergeTargetTitle;

  /// No local project can take the package.
  static String get mergeTargetNone => _english.mergeTargetNone;

  /// A compatibility status, as its pill reads.
  static String compatibilityStatus(String status) =>
      _english.compatibilityStatus(status);

  /// One named compatibility finding. [field] is template data.
  static String compatibilityIssue(String issue, String field) =>
      _english.compatibilityIssue(issue, field);

  /// A template's line in the compatibility report. [name] is template data.
  static String compatibilityTemplate(String name, String status) =>
      _english.compatibilityTemplate(name, status);

  /// The merge preview's count headings (specification §48.1).
  static String mergeCount(String count, int n) =>
      _english.mergeCount(count, n);

  /// Primary merge action while conflicts remain.
  static String mergeSettleConflicts(int n) => _english.mergeSettleConflicts(n);

  /// Primary merge action once every conflict is settled.
  static String get mergeApply => _english.mergeApply;

  /// Shown while a merge is written.
  static String get mergeApplying => _english.mergeApplying;

  /// Announced once a merge is written.
  static String get mergeDone => _english.mergeDone;

  /// A second merge of the same package.
  static String get mergeNothing => _english.mergeNothing;

  /// Switch on the merge preview that runs the duplicate check.
  static String get mergeCheckDuplicates => _english.mergeCheckDuplicates;

  /// Helper under [mergeCheckDuplicates].
  static String get mergeCheckDuplicatesHelper =>
      _english.mergeCheckDuplicatesHelper;

  /// Shown while the duplicate check runs.
  static String get mergeCheckingDuplicates => _english.mergeCheckingDuplicates;

  /// Title of the conflict screen, as "Conflict 3 of 7".
  static String conflictProgress(int index, int total) =>
      _english.conflictProgress(index, total);

  /// What a conflict is about. [field] is template data.
  static String conflictKind(String kind, String field) =>
      _english.conflictKind(kind, field);

  /// Explains a deletion conflict.
  static String conflictDeletion(String kind) =>
      _english.conflictDeletion(kind);

  /// Heading of this device's side of a conflict.
  static String get conflictThisDevice => _english.conflictThisDevice;

  /// Heading of the incoming side of a conflict.
  static String get conflictIncoming => _english.conflictIncoming;

  /// Who last wrote a side, and when. [device] is data.
  static String conflictWrittenBy(String device, DateTime? at) =>
      _english.conflictWrittenBy(device, at);

  /// A side of a deletion conflict.
  static String get conflictDeleted => _english.conflictDeleted;

  /// An empty value on one side.
  static String get conflictEmpty => _english.conflictEmpty;

  /// Keeps this device's side of one conflict.
  static String get conflictKeepMine => _english.conflictKeepMine;

  /// Takes the incoming side of one conflict.
  static String get conflictTakeIncoming => _english.conflictTakeIncoming;

  /// Second control: keep this device's side of every remaining conflict.
  static String mergeKeepAllMine(int n) => _english.mergeKeepAllMine(n);

  /// Second control: take the incoming side of every remaining conflict.
  static String mergeTakeAllIncoming(int n) => _english.mergeTakeAllIncoming(n);

  /// Confirms a bulk choice with its count.
  static String mergeBulkConfirm(int n, {required bool incoming}) =>
      _english.mergeBulkConfirm(n, incoming: incoming);

  /// Title of the possible-duplicate view.
  static String get duplicateTitle => _english.duplicateTitle;

  /// Why a pair was listed.
  static String duplicateSignal(String signal) =>
      _english.duplicateSignal(signal);

  /// Keeps both records: the default.
  static String get duplicateKeepBoth => _english.duplicateKeepBoth;

  /// Leaves the incoming record out of the merge.
  static String get duplicateSkipIncoming => _english.duplicateSkipIncoming;

  /// Marks a pair whose incoming record is left out.
  static String get duplicateSkipped => _english.duplicateSkipped;

  /// Heading of the incoming side of a pair.
  static String get duplicateIncoming => _english.duplicateIncoming;

  /// Heading of the local side of a pair.
  static String get duplicateHere => _english.duplicateHere;

  /// Empty state when the merge screen opens with no package.
  static String get mergeNoPackageHeadline => _english.mergeNoPackageHeadline;

  /// Explains [mergeNoPackageHeadline].
  static String get mergeNoPackageMessage => _english.mergeNoPackageMessage;

  /// Heading over the compatibility report.
  static String get mergeTemplatesHeading => _english.mergeTemplatesHeading;

  /// Heading over the preview's counts.
  static String get mergeCountsHeading => _english.mergeCountsHeading;

  /// Shown when a template blocks the merge.
  static String get mergeBlocked => _english.mergeBlocked;

  /// A record with no caption, in the preview's lists.
  static String mergeRecordUnnamed(String id) =>
      _english.mergeRecordUnnamed(id);

  /// A conflict's line in the preview: the record, then what differs.
  static String mergeConflictLine(String record, String about) =>
      _english.mergeConflictLine(record, about);

  /// A settled conflict's side, under its line.
  static String mergeConflictChosen({required bool incoming}) =>
      _english.mergeConflictChosen(incoming: incoming);

  /// A conflict not settled yet.
  static String get mergeConflictOpen => _english.mergeConflictOpen;

  /// The project details that differ in the package, kept as on this device.
  static String mergeProjectKept(List<String> columns) =>
      _english.mergeProjectKept(columns);

  /// The deletion side of a conflict that was changed rather than deleted.
  static String get conflictChanged => _english.conflictChanged;

  /// The duplicate pair view's field line. [label] and [value] are data.
  static String duplicateField(String label, String value) =>
      _english.duplicateField(label, value);

  /// Prompt on a records list's search field: what it looks through.
  static String get recordsSearchHint => _english.recordsSearchHint;

  /// A record's list title when nothing names it yet: its [number], or no
  /// number at all before one is allocated.
  static String recordsUntitled(int? number) =>
      _english.recordsUntitled(number);

  /// A record row's second line: its [number], [identifier] and [context],
  /// whichever are known, in one line. [identifier] and [context] are
  /// template content (FE-L10N-07).
  static String recordsRowSubtitle({
    int? number,
    String identifier = '',
    String context = '',
  }) => _english.recordsRowSubtitle(
    number: number,
    identifier: identifier,
    context: context,
  );

  /// A project with no records yet.
  static String get recordsEmptyHeadline => _english.recordsEmptyHeadline;

  /// Where a project's records come from.
  static String get recordsEmptyMessage => _english.recordsEmptyMessage;

  /// The next action on an empty records list.
  static String get recordsEmptyAction => _english.recordsEmptyAction;

  /// A records search or filter that matched nothing, naming the [query].
  static String recordsNoMatch(String query) => _english.recordsNoMatch(query);

  /// Empties a records search that matched nothing.
  static String get recordsClearSearch => _english.recordsClearSearch;

  /// Empties a records search and turns its filters off, together.
  static String get recordsClearAll => _english.recordsClearAll;

  /// The records list with no project open.
  static String get recordsNoProjectHeadline =>
      _english.recordsNoProjectHeadline;

  /// Why the records list is empty without a project.
  static String get recordsNoProjectMessage => _english.recordsNoProjectMessage;

  /// The next action when no project is open.
  static String get recordsOpenProject => _english.recordsOpenProject;

  /// Title of a records list's filter sheet.
  static String get recordsFiltersTitle => _english.recordsFiltersTitle;

  /// The status facet of the records filters.
  static String get recordsFilterStatus => _english.recordsFilterStatus;

  /// The template facet of the records filters.
  static String get recordsFilterTemplate => _english.recordsFilterTemplate;

  /// The earliest capture date the records filters keep.
  static String get recordsFilterFrom => _english.recordsFilterFrom;

  /// The latest capture date the records filters keep.
  static String get recordsFilterTo => _english.recordsFilterTo;

  /// The operator facet of the records filters.
  static String get recordsFilterOperator => _english.recordsFilterOperator;

  /// The condition facet of the records filters.
  static String get recordsFilterCondition => _english.recordsFilterCondition;

  /// The quality-flag facet of the records filters.
  static String get recordsFilterFlags => _english.recordsFilterFlags;

  /// Quality flag: the record has at least one photo.
  static String get recordsFlagHasPhotos => _english.recordsFlagHasPhotos;

  /// Quality flag: the record may duplicate another.
  static String get recordsFlagHasDuplicate => _english.recordsFlagHasDuplicate;

  /// Quality flag: a merge left a conflict on the record.
  static String get recordsFlagHasConflict => _english.recordsFlagHasConflict;

  /// Quality flag: a value changed after the record was approved.
  static String get recordsFlagHasVariance => _english.recordsFlagHasVariance;

  /// Quality flag: a value lost every photo it was read from.
  static String get recordsFlagEvidenceRemoved =>
      _english.recordsFlagEvidenceRemoved;

  /// Quality flag: the record arrived in a package from another device.
  static String get recordsFlagMerged => _english.recordsFlagMerged;

  /// The filter sheet of a project with no records.
  static String get recordsFiltersEmptyHeadline =>
      _english.recordsFiltersEmptyHeadline;

  /// What fills the filter sheet.
  static String get recordsFiltersEmptyMessage =>
      _english.recordsFiltersEmptyMessage;

  /// A template whose name is not on this device.
  static String get recordsTemplateUnnamed => _english.recordsTemplateUnnamed;

  /// Active-filter chip for a template. [name] is template content.
  static String recordsChipTemplate(String name) =>
      _english.recordsChipTemplate(name);

  /// Active-filter chip for who captured the records. [name] is data the
  /// operator entered.
  static String recordsChipOperator(String name) =>
      _english.recordsChipOperator(name);

  /// Active-filter chip for a condition code. [code] is template content.
  static String recordsChipCondition(String code) =>
      _english.recordsChipCondition(code);

  /// Active-filter chip for one context value: the [level] it sits at and
  /// the [value]. Both are template content.
  static String recordsChipContext(String level, String value) =>
      _english.recordsChipContext(level, value);

  /// Active-filter chip for the capture date range, in [locale]'s format.
  static String recordsChipDates({
    DateTime? from,
    DateTime? to,
    required String locale,
  }) => _english.recordsChipDates(from: from, to: to, locale: locale);

  /// Title of the records sort choice.
  static String get recordsSortTitle => _english.recordsSortTitle;

  /// The sort control, naming the [current] order.
  static String recordsSortLabel(String current) =>
      _english.recordsSortLabel(current);

  /// Highest record number first, the newest capture on top.
  static String get recordsSortNumberDescending =>
      _english.recordsSortNumberDescending;

  /// Lowest record number first.
  static String get recordsSortNumberAscending =>
      _english.recordsSortNumberAscending;

  /// Latest capture first.
  static String get recordsSortCapturedDescending =>
      _english.recordsSortCapturedDescending;

  /// Earliest capture first.
  static String get recordsSortCapturedAscending =>
      _english.recordsSortCapturedAscending;

  /// Names in alphabetical order.
  static String get recordsSortNameAscending =>
      _english.recordsSortNameAscending;

  /// Names in reverse alphabetical order.
  static String get recordsSortNameDescending =>
      _english.recordsSortNameDescending;

  /// Leaves the page of a record that is not on this device for the list.
  static String get recordDetailBackToList => _english.recordDetailBackToList;

  /// Above a record in the recycle bin: why it cannot be changed, and what
  /// to do first.
  static String get recordDetailDeletedNotice =>
      _english.recordDetailDeletedNotice;

  /// Sends the record shown to review, the step before it is approved.
  static String get recordDetailSendToReview =>
      _english.recordDetailSendToReview;

  /// Once the record shown waits for review.
  static String get recordDetailSentToReview =>
      _english.recordDetailSentToReview;

  /// Menu row that brings the record shown back from the archive.
  static String get recordDetailUnarchive => _english.recordDetailUnarchive;

  /// Once the record shown is back from the archive.
  static String get recordDetailUnarchived => _english.recordDetailUnarchived;

  /// Opens the page that edits the record's photos, captions and audio.
  static String get recordDetailEditPhotos => _english.recordDetailEditPhotos;

  /// A status move asked for while another is still being written.
  static String get recordDetailBusy => _english.recordDetailBusy;

  /// What to do about [recordDetailBusy].
  static String get recordDetailBusyAction => _english.recordDetailBusyAction;

  /// A record with no values and no fields to fill.
  static String get recordDetailNoValues => _english.recordDetailNoValues;

  /// Heading over the context in force when the record was captured.
  static String get recordDetailContextTitle =>
      _english.recordDetailContextTitle;

  /// A record captured with no context in force.
  static String get recordDetailContextEmpty =>
      _english.recordDetailContextEmpty;

  /// Heading over the count of the record's values by where they came from.
  static String get recordDetailProvenanceTitle =>
      _english.recordDetailProvenanceTitle;

  /// How many of the record's values came from one source, or carry one
  /// mark.
  static String recordDetailValuesCount(int n) =>
      _english.recordDetailValuesCount(n);

  /// The values a person confirmed.
  static String get recordDetailVerified => _english.recordDetailVerified;

  /// The providers, models and methods that read the record's values.
  static String get recordDetailReadBy => _english.recordDetailReadBy;

  /// Heading over when the record was captured, changed, approved and
  /// exported.
  static String get recordDetailDatesTitle => _english.recordDetailDatesTitle;

  /// When the record was captured, and on which device.
  static String get recordDetailCaptured => _english.recordDetailCaptured;

  /// When the record last changed.
  static String get recordDetailUpdated => _english.recordDetailUpdated;

  /// When the record was last approved, and by whom.
  static String get recordDetailApproved => _english.recordDetailApproved;

  /// When the record was last exported.
  static String get recordDetailExported => _english.recordDetailExported;

  /// A record that has never been exported.
  static String get recordDetailNotExported => _english.recordDetailNotExported;

  /// When something happened to the record, [at] in local time, and who or
  /// which device did it ([by], data) when that is known.
  static String recordDetailWhen(DateTime at, {String by = ''}) =>
      _english.recordDetailWhen(at, by: by);

  /// One of the record's photos by its 1-based [position] among [total].
  static String recordPhotoPosition(int position, int total) =>
      _english.recordPhotoPosition(position, total);

  /// A value typed by a person, or corrected by hand.
  static String get recordSourceTyped => _english.recordSourceTyped;

  /// A value read from a photo's text on this device.
  static String get recordSourceOcr => _english.recordSourceOcr;

  /// A value an AI model read from a photo.
  static String get recordSourceAiPhoto => _english.recordSourceAiPhoto;

  /// A value an AI model read from captions or spoken notes.
  static String get recordSourceAiText => _english.recordSourceAiText;

  /// A value spoken aloud and written down.
  static String get recordSourceSpeech => _english.recordSourceSpeech;

  /// A value scanned from a barcode or QR code.
  static String get recordSourceBarcode => _english.recordSourceBarcode;

  /// A value looked up in a reference list.
  static String get recordSourceLookup => _english.recordSourceLookup;

  /// A value taken from the context in force at capture.
  static String get recordSourceContext => _english.recordSourceContext;

  /// A value the template filled in by default.
  static String get recordSourceDefault => _english.recordSourceDefault;

  /// A value that arrived in an imported table or package.
  static String get recordSourceImported => _english.recordSourceImported;

  /// A reading the processing was sure of.
  static String get recordBandHigh => _english.recordBandHigh;

  /// A reading the processing was fairly sure of.
  static String get recordBandMedium => _english.recordBandMedium;

  /// A reading a person should check.
  static String get recordBandLow => _english.recordBandLow;

  /// A confidence with no stored band: [score], 0 to 1, as a percentage.
  static String recordBandScore(double score) =>
      _english.recordBandScore(score);

  /// A band's words with its [score], 0 to 1, as a percentage beside them.
  static String recordBandWithScore(String band, double score) =>
      _english.recordBandWithScore(band, score);

  /// What a screen reader hears after a value: where it came from, how sure
  /// the reading was when that is known, and its marks.
  static String recordValueMarks({
    required String source,
    String band = '',
    bool evidenceRemoved = false,
    bool retired = false,
  }) => _english.recordValueMarks(
    source: source,
    band: band,
    evidenceRemoved: evidenceRemoved,
    retired: retired,
  );

  /// Title of a record's history page.
  static String get recordHistoryTitle => _english.recordHistoryTitle;

  /// Under the history title: which record the history is of, by its
  /// [number] and [name] (data). Blank when the record has neither.
  static String recordHistorySubject({int? number, String name = ''}) =>
      _english.recordHistorySubject(number: number, name: name);

  /// A record whose history has no lines yet.
  static String get recordHistoryEmptyHeadline =>
      _english.recordHistoryEmptyHeadline;

  /// What an empty history will hold, and the next step.
  static String get recordHistoryEmptyMessage =>
      _english.recordHistoryEmptyMessage;

  /// Leaves an empty history for its record.
  static String get recordHistoryBackToRecord =>
      _english.recordHistoryBackToRecord;

  /// Heading over one day of a record's history; [day] is local time.
  static String recordHistoryDay(DateTime day) =>
      _english.recordHistoryDay(day);

  /// When a history line was written, by whom and on which device, under
  /// the line. [at] is local time; [operator] and [device] are data and
  /// either may be blank.
  static String recordHistoryByline({
    required DateTime at,
    String operator = '',
    String device = '',
  }) =>
      _english.recordHistoryByline(at: at, operator: operator, device: device);

  /// A record captured on a device.
  static String get recordHistoryCaptured => _english.recordHistoryCaptured;

  /// A record made by hand, which starts as a draft.
  static String get recordHistoryCreatedByHand =>
      _english.recordHistoryCreatedByHand;

  /// Value [label] written or corrected from [previous] to [next]; all
  /// three are data. A first value shows alone, and a value taken away
  /// says so.
  static String recordHistoryValue(
    String label, {
    String previous = '',
    String next = '',
  }) => _english.recordHistoryValue(label, previous: previous, next: next);

  /// The caption of a record or of one of its photos, as the label of
  /// [recordHistoryValue].
  static String get recordHistoryCaption => _english.recordHistoryCaption;

  /// A status move from [previous] to [next], both status names. Only the
  /// new status shows when the old one is not known.
  static String recordHistoryStatus({
    String previous = '',
    required String next,
  }) => _english.recordHistoryStatus(previous: previous, next: next);

  /// A photo added to the record after capture, or during it.
  static String get recordHistoryPhotoAdded => _english.recordHistoryPhotoAdded;

  /// A photo taken off the record. Its file stays until the purge.
  static String get recordHistoryPhotoRemoved =>
      _english.recordHistoryPhotoRemoved;

  /// The record moved from template [previous] to [next] (names, data).
  /// Either name is blank when that template is not on this device.
  static String recordHistoryTemplate({
    String previous = '',
    String next = '',
  }) => _english.recordHistoryTemplate(previous: previous, next: next);

  /// Stands in for the name of a template that is not on this device.
  static String get recordHistoryTemplateGone =>
      _english.recordHistoryTemplateGone;

  /// A processing run that finished, with the [provider] and [model] it
  /// used (data) when they are known.
  static String recordHistoryProcessed({
    String provider = '',
    String model = '',
  }) => _english.recordHistoryProcessed(provider: provider, model: model);

  /// A processing run that stopped for good after [attempts] tries; zero
  /// when the count is not known.
  static String recordHistoryProcessingFailed(int attempts) =>
      _english.recordHistoryProcessingFailed(attempts);

  /// A record that arrived in [package], a package file name (data).
  static String recordHistoryImported(String package) =>
      _english.recordHistoryImported(package);

  /// A record changed by merging [package], a package file name (data).
  static String recordHistoryMerged(String package) =>
      _english.recordHistoryMerged(package);

  /// A record included in export [version], stored as `v<number>`.
  static String recordHistoryExported(String version) =>
      _english.recordHistoryExported(version);

  /// Value [label] (data) lost every photo it was read from. The value is
  /// kept.
  static String recordHistoryEvidenceRemoved(String label) =>
      _english.recordHistoryEvidenceRemoved(label);

  /// Value [label] (data) has a photo it was read from again.
  static String recordHistoryEvidenceRestored(String label) =>
      _english.recordHistoryEvidenceRestored(label);

  /// Value [label] (data) kept as retired by a template change.
  static String recordHistoryRetired(String label) =>
      _english.recordHistoryRetired(label);

  /// Retired value [label] (data) that a template change mapped again.
  static String recordHistoryMappedAgain(String label) =>
      _english.recordHistoryMappedAgain(label);

  /// The record matched to a row of its template's checklist.
  static String get recordHistoryRowMatched => _english.recordHistoryRowMatched;

  /// A photo file of the record was found missing from this device.
  static String get recordHistoryFileMissing =>
      _english.recordHistoryFileMissing;

  /// Any other change the audit table holds for the record.
  static String get recordHistoryOther => _english.recordHistoryOther;

  /// Title of the sheet that shows one history line whole.
  static String get recordHistoryLineTitle => _english.recordHistoryLineTitle;

  /// Label of the value or status a change replaced.
  static String get recordHistoryBefore => _english.recordHistoryBefore;

  /// Label of the value or status a change wrote.
  static String get recordHistoryAfter => _english.recordHistoryAfter;

  /// Label of when a change was written.
  static String get recordHistoryWhen => _english.recordHistoryWhen;

  /// Label of who wrote a change.
  static String get recordHistoryOperator => _english.recordHistoryOperator;

  /// Label of the device a change was written on.
  static String get recordHistoryDevice => _english.recordHistoryDevice;

  /// Label of why a change was made.
  static String get recordHistoryReason => _english.recordHistoryReason;

  /// Stands in for an operator or device the audit row does not hold.
  static String get recordHistoryNotRecorded =>
      _english.recordHistoryNotRecorded;

  /// Stands in for a value that was empty before or after a change.
  static String get recordHistoryEmptyValue => _english.recordHistoryEmptyValue;

  /// When a change was written, in full; [at] is local time.
  static String recordHistoryAt(DateTime at) => _english.recordHistoryAt(at);

  /// Title of the page that edits a saved record's values.
  static String get recordValuesEditTitle => _english.recordValuesEditTitle;

  /// Title of the one-value sheet when the caller does not name the field.
  static String get recordValueEditTitle => _english.recordValueEditTitle;

  /// Above the values of an approved record: what saving a change does.
  static String get recordEditApprovedNotice =>
      _english.recordEditApprovedNotice;

  /// Marks a value its record's template no longer has. It is kept, and it
  /// cannot be edited or removed.
  static String get recordValueRetired => _english.recordValueRetired;

  /// Heading over the values a record keeps after its template dropped them.
  static String get recordRetiredValuesTitle =>
      _english.recordRetiredValuesTitle;

  /// Why retired values cannot be edited.
  static String get recordRetiredValuesMessage =>
      _english.recordRetiredValuesMessage;

  /// Marks a value whose source photos were all removed. The value is kept.
  static String get recordValueEvidenceRemoved =>
      _english.recordValueEvidenceRemoved;

  /// Shown when a record's template is no longer on this device.
  static String get recordTemplateMissingNotice =>
      _english.recordTemplateMissingNotice;

  /// The edit page of a record that sits in the recycle bin.
  static String get recordEditDeletedHeadline =>
      _english.recordEditDeletedHeadline;

  /// What to do before editing a record in the recycle bin.
  static String get recordEditDeletedMessage =>
      _english.recordEditDeletedMessage;

  /// The one-value sheet for a field the record's template no longer has.
  static String get recordFieldMissingHeadline =>
      _english.recordFieldMissingHeadline;

  /// What to do when the one-value sheet has no field to show.
  static String get recordFieldMissingMessage =>
      _english.recordFieldMissingMessage;

  /// Why a saved value cannot be emptied: the captured original always
  /// stays, so an empty edit would show it again (FE-SEC-08).
  static String get recordValueCannotEmpty => _english.recordValueCannotEmpty;

  /// Snack once [n] values are saved. [backToReview] adds that the record,
  /// which was approved, is waiting for review again.
  static String recordValuesSaved(int n, {bool backToReview = false}) =>
      _english.recordValuesSaved(n, backToReview: backToReview);

  /// Title of the offer to process a record again after photos were added.
  static String get recordPhotosProcessTitle =>
      _english.recordPhotosProcessTitle;

  /// Body of that offer: what processing the [n] added photos does, and
  /// that values already on the record stay.
  static String recordPhotosProcessMessage(int n) =>
      _english.recordPhotosProcessMessage(n);

  /// Confirms processing the record again.
  static String get recordPhotosProcessConfirm =>
      _english.recordPhotosProcessConfirm;

  /// Snack once the record is back in the processing queue.
  static String get recordPhotosProcessQueued =>
      _english.recordPhotosProcessQueued;

  /// Title of the sheet that moves a record to another template.
  static String get recordTemplateChangeTitle =>
      _english.recordTemplateChangeTitle;

  /// Names the template the record is on now. [name] is data.
  static String recordTemplateChangeCurrent(String name) =>
      _english.recordTemplateChangeCurrent(name);

  /// Heading over the templates the record can move to.
  static String get recordTemplateChangeChoose =>
      _english.recordTemplateChangeChoose;

  /// Shown before a template is chosen.
  static String get recordTemplateChangeHint =>
      _english.recordTemplateChangeHint;

  /// Heading over the values whose field the chosen template also has.
  static String recordTemplateChangeMapped(int n) =>
      _english.recordTemplateChangeMapped(n);

  /// Heading over the values the chosen template has no field for.
  static String recordTemplateChangeRetired(int n) =>
      _english.recordTemplateChangeRetired(n);

  /// Heading over the chosen template's fields the record has no value for.
  static String recordTemplateChangeAdded(int n) =>
      _english.recordTemplateChangeAdded(n);

  /// Heading over retired values whose field the chosen template has again.
  static String recordTemplateChangeRestored(int n) =>
      _english.recordTemplateChangeRestored(n);

  /// Why retiring a value loses nothing.
  static String get recordTemplateChangeRetiredNotice =>
      _english.recordTemplateChangeRetiredNotice;

  /// When the move changes no value at all.
  static String get recordTemplateChangeNoValues =>
      _english.recordTemplateChangeNoValues;

  /// Above the preview of an approved record: what applying does.
  static String get recordTemplateChangeApprovedNotice =>
      _english.recordTemplateChangeApprovedNotice;

  /// Applies the move.
  static String get recordTemplateChangeApply =>
      _english.recordTemplateChangeApply;

  /// Snack once the record is on its new template. [backToReview] adds that
  /// the record, which was approved, is waiting for review again.
  static String recordTemplateChanged({bool backToReview = false}) =>
      _english.recordTemplateChanged(backToReview: backToReview);

  /// No other template to move the record to.
  static String get recordTemplateChangeEmptyHeadline =>
      _english.recordTemplateChangeEmptyHeadline;

  /// What to do when the project has no other template.
  static String get recordTemplateChangeEmptyMessage =>
      _english.recordTemplateChangeEmptyMessage;

  /// Opens the project's templates from the empty state.
  static String get recordTemplateChangeEmptyAction =>
      _english.recordTemplateChangeEmptyAction;

  /// The record to move is no longer on this device.
  static String get recordTemplateChangeGoneHeadline =>
      _english.recordTemplateChangeGoneHeadline;

  /// What to do when the record to move is gone.
  static String get recordTemplateChangeGoneMessage =>
      _english.recordTemplateChangeGoneMessage;

  /// What to do when Change template is pressed before a template is chosen.
  static String get recordTemplateChangeChooseAction =>
      _english.recordTemplateChangeChooseAction;

  /// A second press while the record is already moving.
  static String get recordTemplateChangeApplying =>
      _english.recordTemplateChangeApplying;

  /// What to do while the record is already moving.
  static String get recordTemplateChangeApplyingAction =>
      _english.recordTemplateChangeApplyingAction;

  /// Names the delete control for [n] records, for its tooltip and screen
  /// readers.
  static String recordsDeleteLabel(int n) => _english.recordsDeleteLabel(n);

  /// Title of the confirm before [n] records move to the recycle bin.
  static String recordsDeleteTitle(int n) => _english.recordsDeleteTitle(n);

  /// Body of that confirm: where the [records] go, and for how many [days]
  /// they can still be restored whole.
  static String recordsDeleteMessage({
    required int records,
    required int days,
  }) => _english.recordsDeleteMessage(records: records, days: days);

  /// Confirms the move to the recycle bin.
  static String get recordsDeleteConfirm => _english.recordsDeleteConfirm;

  /// Snack once [n] records are in the recycle bin. Undo sits beside it.
  static String recordsDeleted(int n) => _english.recordsDeleted(n);

  /// Snack or line when [n] records could not be deleted.
  static String recordsNotDeleted(int n) => _english.recordsNotDeleted(n);

  /// Snack when some records were deleted and some were not. Undo brings
  /// back the [deleted] ones.
  static String recordsDeletedPartly({
    required int deleted,
    required int failed,
  }) => _english.recordsDeletedPartly(deleted: deleted, failed: failed);

  /// Snack once [n] records are back from the recycle bin.
  static String recordsRestored(int n) => _english.recordsRestored(n);

  /// Snack or line when [n] records could not be restored.
  static String recordsNotRestored(int n) => _english.recordsNotRestored(n);

  /// Title of the recycle bin page.
  static String get recycleBinTitle => _english.recycleBinTitle;

  /// Storage settings row that opens the recycle bin.
  static String get recycleBinSettingsSubtitle =>
      _english.recycleBinSettingsSubtitle;

  /// The line above the recycle bin list: how long a deleted record stays
  /// restorable, [days] being the operator's window.
  static String recycleBinKeptFor(int days) => _english.recycleBinKeptFor(days);

  /// Headline of an empty recycle bin.
  static String get recycleBinEmptyHeadline => _english.recycleBinEmptyHeadline;

  /// What an empty recycle bin is for, and the way a record gets back out:
  /// a deleted record waits here for [days].
  static String recycleBinEmptyMessage(int days) =>
      _english.recycleBinEmptyMessage(days);

  /// A recycle bin row's second line: the record's [number] when the row's
  /// title is its name, its [projectName], and when it was deleted
  /// ([deletedAt]). [projectName] is the operator's own text (FE-L10N-07).
  static String recycleBinRowSubtitle({
    required String projectName,
    required DateTime deletedAt,
    int? number,
  }) => _english.recycleBinRowSubtitle(
    projectName: projectName,
    deletedAt: deletedAt,
    number: number,
  );

  /// How long a record in the recycle bin has before the purge removes it
  /// for good: [days] whole days, 0 once its window has run out.
  static String recycleBinDaysLeft(int days) =>
      _english.recycleBinDaysLeft(days);

  /// Tooltip of a recycle bin row's restore control.
  static String get recycleBinRestore => _english.recycleBinRestore;

  /// Screen-reader name of the restore control on the row of record
  /// [name], which is the record's own text (FE-L10N-07).
  static String recycleBinRestoreLabel(String name) =>
      _english.recycleBinRestoreLabel(name);

  /// A restore asked for while the same record is being restored.
  static String get recycleBinRestoring => _english.recycleBinRestoring;

  /// What to do while a record is being restored.
  static String get recycleBinRestoringAction =>
      _english.recycleBinRestoringAction;

  /// The action that removes everything in the recycle bin now.
  static String get recycleBinEmpty => _english.recycleBinEmpty;

  /// Title of the strong confirm before [n] records are removed for good.
  static String recycleBinEmptyTitle(int n) => _english.recycleBinEmptyTitle(n);

  /// Body of that confirm: what goes, that it cannot be undone, and what
  /// stays.
  static String recycleBinEmptyWarning(int n) =>
      _english.recycleBinEmptyWarning(n);

  /// Label of the field the operator types [n] into to confirm.
  static String recycleBinEmptyTypeCount(int n) =>
      _english.recycleBinEmptyTypeCount(n);

  /// Confirms emptying the recycle bin.
  static String get recycleBinEmptyConfirm => _english.recycleBinEmptyConfirm;

  /// Why Empty recycle bin cannot be pressed on this device.
  static String get recycleBinEmptyUnavailable =>
      _english.recycleBinEmptyUnavailable;

  /// What to do when emptying is not available.
  static String get recycleBinEmptyUnavailableAction =>
      _english.recycleBinEmptyUnavailableAction;

  /// An empty-now asked for while the recycle bin is being emptied.
  static String get recycleBinEmptying => _english.recycleBinEmptying;

  /// What to do while the recycle bin is being emptied.
  static String get recycleBinEmptyingAction =>
      _english.recycleBinEmptyingAction;

  /// Snack after emptying the recycle bin: how many records were [purged],
  /// how many were [kept] because a merge still needs them, and how many
  /// [failed] and stay for the next try.
  static String recycleBinEmptied({
    required int purged,
    required int kept,
    required int failed,
  }) => _english.recycleBinEmptied(purged: purged, kept: kept, failed: failed);

  /// The bulk action bar's count of ticked records.
  static String recordsSelectedCount(int n) => _english.recordsSelectedCount(n);

  /// Unticks every record and leaves selection mode.
  static String get recordsClearSelection => _english.recordsClearSelection;

  /// Ticks every record the list has shown.
  static String get recordsSelectAllShown => _english.recordsSelectAllShown;

  /// Names the bulk approve control for [n] records.
  static String recordsApproveLabel(int n) => _english.recordsApproveLabel(n);

  /// Names the bulk archive control for [n] records.
  static String recordsArchiveLabel(int n) => _english.recordsArchiveLabel(n);

  /// Names the bulk process-again control for [n] records.
  static String recordsReprocessLabel(int n) =>
      _english.recordsReprocessLabel(n);

  /// Names the bulk export control for [n] records.
  static String recordsExportLabel(int n) => _english.recordsExportLabel(n);

  /// Title of the confirm before [n] records are archived.
  static String recordsArchiveTitle(int n) => _english.recordsArchiveTitle(n);

  /// Body of that confirm: where the [n] records go and how to find them.
  static String recordsArchiveMessage(int n) =>
      _english.recordsArchiveMessage(n);

  /// Confirms archiving.
  static String get recordsArchiveConfirm => _english.recordsArchiveConfirm;

  /// Title of the confirm before [n] records are processed again.
  static String recordsReprocessTitle(int n) =>
      _english.recordsReprocessTitle(n);

  /// Body of that confirm: what processing again does to the [n] records.
  static String recordsReprocessMessage(int n) =>
      _english.recordsReprocessMessage(n);

  /// Confirms processing again.
  static String get recordsReprocessConfirm => _english.recordsReprocessConfirm;

  /// Title of the confirm before exporting with [n] records selected.
  static String recordsExportTitle(int n) => _english.recordsExportTitle(n);

  /// Body of that confirm: an export is the whole project's package.
  static String recordsExportMessage(int n) => _english.recordsExportMessage(n);

  /// Opens the project's export page.
  static String get recordsExportConfirm => _english.recordsExportConfirm;

  /// Snack once [n] records are approved.
  static String recordsApproved(int n) => _english.recordsApproved(n);

  /// Snack or line when [n] records could not be approved.
  static String recordsNotApproved(int n) => _english.recordsNotApproved(n);

  /// Snack once [n] records are archived.
  static String recordsArchived(int n) => _english.recordsArchived(n);

  /// Snack or line when [n] records could not be archived.
  static String recordsNotArchived(int n) => _english.recordsNotArchived(n);

  /// Snack once [n] records are back in the processing queue.
  static String recordsRequeued(int n) => _english.recordsRequeued(n);

  /// Snack or line when [n] records could not be queued again.
  static String recordsNotRequeued(int n) => _english.recordsNotRequeued(n);

  /// Added to that snack while offline: the [n] queued records wait.
  static String recordsRequeuedOffline(int n) =>
      _english.recordsRequeuedOffline(n);

  /// A bulk action's summary when some records changed and some did not:
  /// [done] and [notDone] are the two counted sentences.
  static String recordsBulkOutcome({
    required String done,
    required String notDone,
  }) => _english.recordsBulkOutcome(done: done, notDone: notDone);

  /// A bulk action asked for while another is still running.
  static String get recordsBulkBusy => _english.recordsBulkBusy;

  /// What to do while a bulk action is running.
  static String get recordsBulkBusyAction => _english.recordsBulkBusyAction;

  /// How many validation issues a form is showing.
  static String validationIssueCount(int errors, int warnings) =>
      _english.validationIssueCount(errors, warnings);

  /// Error count for a validation summary.
  static String validationErrorCount(int n) => _english.validationErrorCount(n);

  /// Warning count for a validation summary.
  static String validationWarningCount(int n) =>
      _english.validationWarningCount(n);

  /// Jumps the summary to the first field that has an error.
  static String get validationGoToFirstError =>
      _english.validationGoToFirstError;

  /// Word beside an error, so the state is not colour alone.
  static String get validationErrorLabel => _english.validationErrorLabel;

  /// Word beside a warning, so the state is not colour alone.
  static String get validationWarningLabel => _english.validationWarningLabel;

  /// A required field that is empty.
  static String validationRequired(String label) =>
      _english.validationRequired(label);

  /// A value that is the wrong kind for its field.
  static String validationType(String label) => _english.validationType(label);

  /// A value shorter than the field allows.
  static String validationTooShort(String label) =>
      _english.validationTooShort(label);

  /// A value longer than the field allows.
  static String validationTooLong(String label) =>
      _english.validationTooLong(label);

  /// A value outside the field's numeric range.
  static String validationRange(String label) =>
      _english.validationRange(label);

  /// A value that does not match the field's pattern.
  static String validationPattern(String label) =>
      _english.validationPattern(label);

  /// A choice that is not one of the field's options.
  static String validationOption(String label) =>
      _english.validationOption(label);

  /// A measurement the field's unit cannot hold.
  static String validationUnit(String label) => _english.validationUnit(label);

  /// An identity field left empty.
  static String validationIdentity(String label) =>
      _english.validationIdentity(label);

  /// Evidence the template demands is missing.
  static String get validationEvidence => _english.validationEvidence;

  /// A computed expression that does not parse.
  static String get validationExpression => _english.validationExpression;

  /// What to do when an expression does not parse.
  static String get validationExpressionAction =>
      _english.validationExpressionAction;

  /// An expression names a field the template does not have.
  static String validationUnknownField(String name) =>
      _english.validationUnknownField(name);

  /// Duplicate prompt title.
  static String get duplicatePromptTitle => _english.duplicatePromptTitle;

  /// Writes the new values onto the existing record.
  static String get duplicateOverride => _english.duplicateOverride;

  /// Keeps both records and links them.
  static String get duplicateLinkBoth => _english.duplicateLinkBoth;

  /// Drops the new record.
  static String get duplicateDiscard => _english.duplicateDiscard;

  /// Opens the field-by-field merge.
  static String get duplicateMerge => _english.duplicateMerge;

  /// Headline when two records do not differ.
  static String get duplicateNoDifferenceHeadline =>
      _english.duplicateNoDifferenceHeadline;

  /// Why the duplicate prompt has nothing to compare.
  static String get duplicateNoDifferenceMessage =>
      _english.duplicateNoDifferenceMessage;

  /// Duplicate compare title.
  static String get duplicateCompareTitle => _english.duplicateCompareTitle;

  /// Merge sheet title.
  static String get duplicateMergeTitle => _english.duplicateMergeTitle;

  /// Keeps this record's value for one field.
  static String get duplicateKeepMine => _english.duplicateKeepMine;

  /// Takes the other record's value for one field.
  static String get duplicateTakeTheirs => _english.duplicateTakeTheirs;

  /// Keeps both values for one field as a note.
  static String get duplicateKeepBothNote => _english.duplicateKeepBothNote;

  /// The one question the duplicate prompt asks.
  static String get duplicatePromptQuestion => _english.duplicatePromptQuestion;

  /// The prompt's override option: the comparison completes it.
  static String get duplicateCompareThenUpdate =>
      _english.duplicateCompareThenUpdate;

  /// Goes on with the outcome chosen in the prompt.
  static String get duplicatePromptContinue => _english.duplicatePromptContinue;

  /// Heading of the record that was there first.
  static String get duplicateExistingRecord => _english.duplicateExistingRecord;

  /// Heading of the newer record.
  static String get duplicateNewRecord => _english.duplicateNewRecord;

  /// Heading over the fields two records do not share.
  static String get duplicateDifferingFields =>
      _english.duplicateDifferingFields;

  /// Leaves the comparison for the duplicates list.
  static String get duplicateBackToList => _english.duplicateBackToList;

  /// A pair's row title: both records. [existing] and [incoming] are data.
  static String duplicatePairTitle(String existing, String incoming) =>
      _english.duplicatePairTitle(existing, incoming);

  /// A pair's group: the signal and the template. [template] is data.
  static String duplicatesGroup(String signal, String template) =>
      _english.duplicatesGroup(signal, template);

  /// The existing value, then the new one. The values are data.
  static String duplicateValueChange(String existing, String incoming) =>
      _english.duplicateValueChange(existing, incoming);

  /// One differing field on a pair's row. The values are data.
  static String duplicateDifferenceLine(
    String label,
    String existing,
    String incoming,
  ) => _english.duplicateDifferenceLine(label, existing, incoming);

  /// When and by whom a record was captured, and where. [by] and [place]
  /// are data.
  static String duplicateCaptureDetail(DateTime at, String by, String place) =>
      _english.duplicateCaptureDetail(at, by, place);

  /// Confirm heading before an override.
  static String get duplicateOverrideConfirmTitle =>
      _english.duplicateOverrideConfirmTitle;

  /// Confirm body before an override.
  static String get duplicateOverrideConfirmMessage =>
      _english.duplicateOverrideConfirmMessage;

  /// Carries the newer record's photos onto the survivor of a merge.
  static String get duplicateCarryPhotos => _english.duplicateCarryPhotos;

  /// Explains [duplicateCarryPhotos] with how many photos [n] move.
  static String duplicateCarryPhotosHelp(int n) =>
      _english.duplicateCarryPhotosHelp(n);

  /// Applies the merge sheet's choices.
  static String get duplicateMergeApply => _english.duplicateMergeApply;

  /// The merge choice for one field. [label] is template data.
  static String duplicateMergeKeep(String label) =>
      _english.duplicateMergeKeep(label);

  /// Merge option: the existing record's value.
  static String get duplicateMergeExisting => _english.duplicateMergeExisting;

  /// Merge option: the new record's value.
  static String get duplicateMergeNew => _english.duplicateMergeNew;

  /// Merge option: both values.
  static String get duplicateMergeBoth => _english.duplicateMergeBoth;

  /// Why the merge cannot run yet.
  static String get duplicateMergeChooseAll => _english.duplicateMergeChooseAll;

  /// Both values of a field kept together. The values are data.
  static String duplicateBothValues(String existing, String incoming) =>
      _english.duplicateBothValues(existing, incoming);

  /// Outcome after both records are kept and linked.
  static String get duplicateResolvedKeepBoth =>
      _english.duplicateResolvedKeepBoth;

  /// Outcome after the new record is discarded.
  static String get duplicateResolvedDiscard =>
      _english.duplicateResolvedDiscard;

  /// Outcome after an override.
  static String get duplicateResolvedOverride =>
      _english.duplicateResolvedOverride;

  /// Outcome after a merge.
  static String get duplicateResolvedMerge => _english.duplicateResolvedMerge;

  /// Recycle-bin reason of a discarded duplicate.
  static String get duplicateDiscardedReason =>
      _english.duplicateDiscardedReason;

  /// Recycle-bin reason of a record whose values overrode another.
  static String get duplicateOverriddenReason =>
      _english.duplicateOverriddenReason;

  /// Recycle-bin reason of a record merged into another.
  static String get duplicateMergedReason => _english.duplicateMergedReason;

  /// A pair that is resolved or gone.
  static String get duplicatePairGone => _english.duplicatePairGone;

  /// What to do about [duplicatePairGone].
  static String get duplicatePairGoneRecovery =>
      _english.duplicatePairGoneRecovery;

  /// Runs detection over a whole project.
  static String get duplicatesScan => _english.duplicatesScan;

  /// Outcome of [duplicatesScan]: how many new pairs [n] were queued.
  static String duplicatesScanned(int n) => _english.duplicatesScanned(n);

  /// The sheet that asks which choice a whole group gets.
  static String get duplicatesBulkChoose => _english.duplicatesBulkChoose;

  /// Outcome of a bulk choice over [n] pairs.
  static String duplicatesBulkDone(int n) => _english.duplicatesBulkDone(n);

  /// A record's badge: the record it is linked to. [title] is data.
  static String duplicateLinkedTo(String title) =>
      _english.duplicateLinkedTo(title);

  /// A record's badge: the record it may duplicate. [title] is data.
  static String duplicatePossibleOf(String title) =>
      _english.duplicatePossibleOf(title);

  /// Duplicates review title.
  static String get duplicatesTitle => _english.duplicatesTitle;

  /// Empty duplicates list headline.
  static String get duplicatesEmptyHeadline => _english.duplicatesEmptyHeadline;

  /// Empty duplicates list explanation.
  static String get duplicatesEmptyMessage => _english.duplicatesEmptyMessage;

  /// Clears every remaining pair in one group.
  static String get duplicatesResolveGroup => _english.duplicatesResolveGroup;

  /// Bulk confirm title naming [choice] and how many records [n].
  static String duplicatesBulkTitle(int n, String choice) =>
      _english.duplicatesBulkTitle(n, choice);

  /// Bulk confirm body naming how many records [n] change.
  static String duplicatesBulkMessage(int n) =>
      _english.duplicatesBulkMessage(n);

  /// Types a value that matches none of the candidates.
  static String get conflictTypeOwn => _english.conflictTypeOwn;

  /// Keeps the value typed in [conflictTypeOwn].
  static String get conflictUseTyped => _english.conflictUseTyped;

  /// The reason a person gives for the value they chose.
  static String get conflictReason => _english.conflictReason;

  /// Empty conflict row headline.
  static String get conflictEmptyHeadline => _english.conflictEmptyHeadline;

  /// Empty conflict row explanation.
  static String get conflictEmptyMessage => _english.conflictEmptyMessage;

  /// Unresolved conflict blocks approval and names the field.
  static String conflictBlocksApproval(String label) =>
      _english.conflictBlocksApproval(label);

  /// Verification mode switch title.
  static String get verificationModeTitle => _english.verificationModeTitle;

  /// Shown while verification mode is on.
  static String get verificationModeOn => _english.verificationModeOn;

  /// Shown while verification mode is off.
  static String get verificationModeOff => _english.verificationModeOff;

  /// Status line mark while verification mode is on.
  static String get verificationStatus => _english.verificationStatus;

  /// A value that came from the register.
  static String get verificationFromRegister =>
      _english.verificationFromRegister;

  /// Variance screen title.
  static String get varianceTitle => _english.varianceTitle;

  /// Empty variance list headline.
  static String get varianceEmptyHeadline => _english.varianceEmptyHeadline;

  /// Empty variance list explanation.
  static String get varianceEmptyMessage => _english.varianceEmptyMessage;

  /// A normalised match.
  static String get varianceMatch => _english.varianceMatch;

  /// A genuine difference.
  static String get varianceChanged => _english.varianceChanged;

  /// A register value with nothing found.
  static String get varianceMissing => _english.varianceMissing;

  /// A variance row's detail: its status and both values, which are data.
  static String varianceDetail(String status, String recorded, String found) =>
      _english.varianceDetail(status, recorded, found);

  /// Register rows no record was captured from.
  static String get varianceRegisterNotFound =>
      _english.varianceRegisterNotFound;

  /// Checklist rows never captured.
  static String get varianceChecklistNotCaptured =>
      _english.varianceChecklistNotCaptured;

  /// The variance empty state's next step.
  static String get varianceOpenRecords => _english.varianceOpenRecords;

  /// Quality summary title.
  static String get qualitySummaryTitle => _english.qualitySummaryTitle;

  /// Records that fail validation.
  static String get qualityInvalid => _english.qualityInvalid;

  /// Unresolved duplicate pairs.
  static String get qualityDuplicates => _english.qualityDuplicates;

  /// Unresolved source conflicts.
  static String get qualityConflicts => _english.qualityConflicts;

  /// Records still waiting for review.
  static String get qualityUnreviewed => _english.qualityUnreviewed;

  /// Headline when nothing blocks export.
  static String get qualityCleanHeadline => _english.qualityCleanHeadline;

  /// Explanation when nothing blocks export.
  static String get qualityCleanMessage => _english.qualityCleanMessage;

  /// Review screen title.
  static String get reviewTitle => _english.reviewTitle;

  /// Fields that need a person before approval.
  static String get reviewNeedsAttention => _english.reviewNeedsAttention;

  /// Confident fields, collapsed until opened.
  static String get reviewConfident => _english.reviewConfident;

  /// The confident group's heading, with how many fields it holds.
  static String reviewConfidentGroup(int count) =>
      _english.reviewConfidentGroup(count);

  /// Approves this record and opens the next one.
  static String get reviewApproveNext => _english.reviewApproveNext;

  /// Empty review headline.
  static String get reviewEmptyHeadline => _english.reviewEmptyHeadline;

  /// Empty review explanation.
  static String get reviewEmptyMessage => _english.reviewEmptyMessage;

  /// Shows the captured value.
  static String get reviewUseRaw => _english.reviewUseRaw;

  /// Shows the refined value.
  static String get reviewUseRefined => _english.reviewUseRefined;

  /// Neither side has a value.
  static String get reviewNoSidesHeadline => _english.reviewNoSidesHeadline;

  /// Why the raw or refined toggle has nothing to choose.
  static String get reviewNoSidesMessage => _english.reviewNoSidesMessage;

  /// A value the extractor did not invent.
  static String get reviewNotDetected => _english.reviewNotDetected;

  /// Types the missing value.
  static String get reviewTypeIt => _english.reviewTypeIt;

  /// Photographs the label for the missing value.
  static String get reviewPhotograph => _english.reviewPhotograph;

  /// No missing value to act on.
  static String get reviewNotDetectedEmpty => _english.reviewNotDetectedEmpty;

  /// Opens the evidence for a value.
  static String get reviewShowEvidence => _english.reviewShowEvidence;

  /// Opens the full photo.
  static String get reviewOpenPhoto => _english.reviewOpenPhoto;

  /// Evidence with no photo and no passage.
  static String get reviewEvidenceEmpty => _english.reviewEvidenceEmpty;

  /// Verifies the current value without changing it.
  static String get reviewVerify => _english.reviewVerify;

  /// Verifies every confident field.
  static String get reviewVerifyConfident => _english.reviewVerifyConfident;

  /// Who verified a value, and when.
  static String reviewVerifiedBy(String name) =>
      _english.reviewVerifiedBy(name);

  /// Nothing to verify.
  static String get reviewVerifyEmpty => _english.reviewVerifyEmpty;

  /// Batch position, [index] of [total], both 1-based for [index].
  static String reviewPosition(int index, int total) =>
      _english.reviewPosition(index, total);

  /// Skips this record and keeps what was typed.
  static String get reviewSkip => _english.reviewSkip;

  /// Returns to the previous record.
  static String get reviewBack => _english.reviewBack;

  /// The batch queue is finished.
  static String get reviewQueueDone => _english.reviewQueueDone;

  /// What to do when the queue is finished.
  static String get reviewQueueDoneMessage => _english.reviewQueueDoneMessage;

  /// The batch queue has no records.
  static String get reviewQueueEmpty => _english.reviewQueueEmpty;

  /// Runs processing again.
  static String get reviewReanalyse => _english.reviewReanalyse;

  /// A proposed value offered beside the current one.
  static String get reviewProposal => _english.reviewProposal;

  /// Marks a proposal the person accepts.
  static String get reviewAccept => _english.reviewAccept;

  /// Writes the accepted proposals.
  static String get reviewApplyAccepted => _english.reviewApplyAccepted;

  /// Declines every proposal.
  static String get reviewDeclineAll => _english.reviewDeclineAll;

  /// A verified or typed value that re-analysis must not overwrite.
  static String get reviewOfferedNotApplied => _english.reviewOfferedNotApplied;

  /// No new proposals.
  static String get reviewReanalyseEmpty => _english.reviewReanalyseEmpty;

  /// This record is still in an unresolved duplicate pair.
  static String get reviewBlockedDuplicate => _english.reviewBlockedDuplicate;

  /// Where to clear a block.
  static String get reviewBlockedAction => _english.reviewBlockedAction;

  /// Empty confidence indicator headline.
  static String get reviewNoConfidence => _english.reviewNoConfidence;

  /// Empty confidence indicator explanation.
  static String get reviewNoConfidenceMessage =>
      _english.reviewNoConfidenceMessage;

  /// Audit line when review approves a record.
  static String get reviewApprovedReason => _english.reviewApprovedReason;

  /// Audit line when a person verifies a value without changing it.
  static String get reviewVerifiedReason => _english.reviewVerifiedReason;

  /// Audit line when a person picks the captured or the refined side.
  static String get reviewSideReason => _english.reviewSideReason;

  /// Why review refused a write: the record is approved or in the bin.
  static String get reviewRecordSettled => _english.reviewRecordSettled;

  /// What to do about [reviewRecordSettled].
  static String get reviewRecordSettledAction =>
      _english.reviewRecordSettledAction;

  /// Why review refused a write: the record is not on this device.
  static String get reviewRecordGone => _english.reviewRecordGone;

  /// What to do about [reviewRecordGone].
  static String get reviewRecordGoneAction => _english.reviewRecordGoneAction;

  /// Label of the control that picks which side of a value is final.
  static String get reviewFinalSide => _english.reviewFinalSide;

  /// Moves back to the previous record in the review queue.
  static String get reviewPreviousRecord => _english.reviewPreviousRecord;

  /// The review empty state's next step.
  static String get reviewBackToRecords => _english.reviewBackToRecords;

  /// Snack after verifying [count] values without changing them.
  static String reviewVerifiedCount(int count) =>
      _english.reviewVerifiedCount(count);

  /// A verified value's mark.
  static String get reviewVerified => _english.reviewVerified;

  /// Title of the sheet showing where a value came from.
  static String get reviewEvidenceTitle => _english.reviewEvidenceTitle;

  /// Source label of photo evidence.
  static String get reviewEvidencePhoto => _english.reviewEvidencePhoto;

  /// Source label of document evidence on [page], when known.
  static String reviewEvidenceDocument(int? page) =>
      _english.reviewEvidenceDocument(page);

  /// Source label of transcript evidence.
  static String get reviewEvidenceTranscript =>
      _english.reviewEvidenceTranscript;

  /// The highlighted region on an evidence photo, for a screen reader.
  static String get reviewEvidenceRegion => _english.reviewEvidenceRegion;

  /// Snack after re-analysis was queued.
  static String get reviewReanalyseQueued => _english.reviewReanalyseQueued;

  /// Banner while re-analysis runs.
  static String get reviewReanalysing => _english.reviewReanalysing;

  /// Heading of the proposals re-analysis offers.
  static String get reviewProposalsTitle => _english.reviewProposalsTitle;

  /// One proposal: the [current] value beside the [proposed] one.
  static String reviewProposalLine(String current, String proposed) =>
      _english.reviewProposalLine(current, proposed);

  /// Snack after accepted proposals were written.
  static String reviewProposalsApplied(int count) =>
      _english.reviewProposalsApplied(count);

  /// Meeting create page title.
  static String get meetingTitle => _english.meetingTitle;

  /// Starts a meeting from the prefilled header.
  static String get meetingStart => _english.meetingStart;

  /// Empty meeting headline.
  static String get meetingEmptyHeadline => _english.meetingEmptyHeadline;

  /// Empty meeting explanation.
  static String get meetingEmptyMessage => _english.meetingEmptyMessage;

  /// Header date label.
  static String get meetingDate => _english.meetingDate;

  /// Header start-time label.
  static String get meetingStartTime => _english.meetingStartTime;

  /// Header location label.
  static String get meetingLocation => _english.meetingLocation;

  /// Header secretary label.
  static String get meetingSecretary => _english.meetingSecretary;

  /// Title written when a meeting starts, from the clock's date.
  static String meetingStartedTitle(DateTime when) =>
      _english.meetingStartedTitle(when);

  /// Attachments section.
  static String get meetingAttachments => _english.meetingAttachments;

  /// Adds an attachment.
  static String get meetingAddAttachment => _english.meetingAddAttachment;

  /// Empty attachments headline.
  static String get meetingAttachmentsEmpty => _english.meetingAttachmentsEmpty;

  /// Empty attachments explanation.
  static String get meetingAttachmentsEmptyMessage =>
      _english.meetingAttachmentsEmptyMessage;

  /// Opens an attachment.
  static String get meetingOpenAttachment => _english.meetingOpenAttachment;

  /// Agenda section.
  static String get meetingAgenda => _english.meetingAgenda;

  /// Adds an agenda entry.
  static String get meetingAddAgenda => _english.meetingAddAgenda;

  /// Agenda title field.
  static String get meetingAgendaTitle => _english.meetingAgendaTitle;

  /// Discussion notes under an agenda entry.
  static String get meetingDiscussion => _english.meetingDiscussion;

  /// Moves an entry later.
  static String get meetingMoveDown => _english.meetingMoveDown;

  /// Removes an entry after confirm.
  static String get meetingRemove => _english.meetingRemove;

  /// Confirm title for a removal.
  static String get meetingRemoveTitle => _english.meetingRemoveTitle;

  /// Confirm body for a removal.
  static String get meetingRemoveMessage => _english.meetingRemoveMessage;

  /// Confirm button for a removal.
  static String get meetingRemoveConfirm => _english.meetingRemoveConfirm;

  /// Empty agenda headline.
  static String get meetingAgendaEmpty => _english.meetingAgendaEmpty;

  /// Empty agenda explanation.
  static String get meetingAgendaEmptyMessage =>
      _english.meetingAgendaEmptyMessage;

  /// Attendees section.
  static String get meetingAttendees => _english.meetingAttendees;

  /// Adds an attendee.
  static String get meetingAddAttendee => _english.meetingAddAttendee;

  /// Attendee name field.
  static String get meetingAttendeeName => _english.meetingAttendeeName;

  /// Attendee title field.
  static String get meetingAttendeeRole => _english.meetingAttendeeRole;

  /// Attendee organisation field.
  static String get meetingOrganisation => _english.meetingOrganisation;

  /// Attendee contact field.
  static String get meetingContact => _english.meetingContact;

  /// Marks the person present.
  static String get meetingPresent => _english.meetingPresent;

  /// Marks an apology.
  static String get meetingApology => _english.meetingApology;

  /// How many people are present. Apologies are not included.
  static String meetingAttendanceCount(int count) =>
      _english.meetingAttendanceCount(count);

  /// Accepts a staff suggestion.
  static String get meetingAcceptStaff => _english.meetingAcceptStaff;

  /// Empty attendees headline.
  static String get meetingAttendeesEmpty => _english.meetingAttendeesEmpty;

  /// Empty attendees explanation.
  static String get meetingAttendeesEmptyMessage =>
      _english.meetingAttendeesEmptyMessage;

  /// Attendance sheet section.
  static String get meetingAttendanceSheet => _english.meetingAttendanceSheet;

  /// Photographs the signed sheet.
  static String get meetingPhotographSheet => _english.meetingPhotographSheet;

  /// Accepts the edited rows onto the attendee list.
  static String get meetingAcceptRows => _english.meetingAcceptRows;

  /// A poor read still keeps the photo.
  static String get meetingSheetKept => _english.meetingSheetKept;

  /// Empty attendance headline.
  static String get meetingSheetEmpty => _english.meetingSheetEmpty;

  /// Empty attendance explanation.
  static String get meetingSheetEmptyMessage =>
      _english.meetingSheetEmptyMessage;

  /// Signature column.
  static String get meetingSignature => _english.meetingSignature;

  /// Recording section.
  static String get meetingRecording => _english.meetingRecording;

  /// Starts recording.
  static String get meetingRecord => _english.meetingRecord;

  /// Stops recording.
  static String get meetingStop => _english.meetingStop;

  /// Elapsed recording time.
  static String meetingElapsed(String clock) => _english.meetingElapsed(clock);

  /// Free space while recording.
  static String meetingRemaining(String label) =>
      _english.meetingRemaining(label);

  /// A recording interrupted before stop.
  static String get meetingInterrupted => _english.meetingInterrupted;

  /// Empty recording headline.
  static String get meetingRecordingEmpty => _english.meetingRecordingEmpty;

  /// Empty recording explanation.
  static String get meetingRecordingEmptyMessage =>
      _english.meetingRecordingEmptyMessage;

  /// Decisions section.
  static String get meetingDecisions => _english.meetingDecisions;

  /// Adds a decision.
  static String get meetingAddDecision => _english.meetingAddDecision;

  /// Decision text field.
  static String get meetingDecisionText => _english.meetingDecisionText;

  /// Where a refined decision came from.
  static String get meetingSource => _english.meetingSource;

  /// Empty decisions headline.
  static String get meetingDecisionsEmpty => _english.meetingDecisionsEmpty;

  /// Empty decisions explanation.
  static String get meetingDecisionsEmptyMessage =>
      _english.meetingDecisionsEmptyMessage;

  /// Actions section.
  static String get meetingActions => _english.meetingActions;

  /// Adds an action.
  static String get meetingAddAction => _english.meetingAddAction;

  /// Action text field.
  static String get meetingActionText => _english.meetingActionText;

  /// Owner field.
  static String get meetingOwner => _english.meetingOwner;

  /// Due date field.
  static String get meetingDue => _english.meetingDue;

  /// Picks an owner from the attendees.
  static String get meetingOwnerAttendee => _english.meetingOwnerAttendee;

  /// Picks an owner from the staff dataset.
  static String get meetingOwnerStaff => _english.meetingOwnerStaff;

  /// Action status.
  static String get meetingStatus => _english.meetingStatus;

  /// Empty actions headline.
  static String get meetingActionsEmpty => _english.meetingActionsEmpty;

  /// Empty actions explanation.
  static String get meetingActionsEmptyMessage =>
      _english.meetingActionsEmptyMessage;

  /// Raw notes beside the minutes.
  static String get meetingNotes => _english.meetingNotes;

  /// Refined minutes beside the notes.
  static String get meetingMinutes => _english.meetingMinutes;

  /// Verbatim transcript, never edited here.
  static String get meetingTranscript => _english.meetingTranscript;

  /// Blocks approval and names the action.
  static String meetingActionBlocked(String action) =>
      _english.meetingActionBlocked(action);

  /// Approves the meeting.
  static String get meetingApprove => _english.meetingApprove;

  /// Review page title.
  static String get meetingReviewTitle => _english.meetingReviewTitle;

  /// Empty review headline.
  static String get meetingReviewEmpty => _english.meetingReviewEmpty;

  /// Empty review explanation.
  static String get meetingReviewEmptyMessage =>
      _english.meetingReviewEmptyMessage;

  /// Audit line when a meeting is approved.
  static String get meetingApprovedReason => _english.meetingApprovedReason;

  /// Starts a meeting from a project, or opens the one a record holds.
  static String get meetingStartEntry => _english.meetingStartEntry;

  /// Opens the meeting a record holds.
  static String get meetingOpen => _english.meetingOpen;

  /// Name a project's installed meeting template takes.
  static String get meetingTemplateName => _english.meetingTemplateName;

  /// A header value nothing filled in.
  static String get meetingNotSet => _english.meetingNotSet;

  /// The meeting's date, in this device's time zone.
  static String meetingDay(DateTime at) => _english.meetingDay(at);

  /// The meeting's start time, in this device's time zone.
  static String meetingClock(DateTime at) => _english.meetingClock(at);

  /// The project a meeting would be filed on is gone.
  static String get meetingNoProject => _english.meetingNoProject;

  /// What to do when there is no project to start a meeting on.
  static String get meetingNoProjectMessage => _english.meetingNoProjectMessage;

  /// Returns to the project list.
  static String get meetingBackToProjects => _english.meetingBackToProjects;

  /// Summary section of the review.
  static String get meetingSummary => _english.meetingSummary;

  /// How many decisions the meeting holds.
  static String meetingDecisionsCount(int count) =>
      _english.meetingDecisionsCount(count);

  /// How many actions the meeting holds.
  static String meetingActionsCount(int count) =>
      _english.meetingActionsCount(count);

  /// The raw notes and refined minutes section.
  static String get meetingNotesAndMinutes => _english.meetingNotesAndMinutes;

  /// Refines the minutes from the notes and the transcript.
  static String get meetingRefine => _english.meetingRefine;

  /// Refinement summarises per agenda point, so it needs an agenda.
  static String get meetingRefineNeedsAgenda =>
      _english.meetingRefineNeedsAgenda;

  /// Names what the notes and the transcript do not support.
  static String meetingUnsupported(List<String> names) =>
      _english.meetingUnsupported(names);

  /// One agenda point's line in the refined minutes.
  static String meetingMinutesLine(String title, String summary) =>
      _english.meetingMinutesLine(title, summary);

  /// One transcription run of the recording.
  static String meetingTranscriptVersion(int version) =>
      _english.meetingTranscriptVersion(version);

  /// Parts of a recording one run could not transcribe.
  static String meetingTranscriptGaps(int count) =>
      _english.meetingTranscriptGaps(count);

  /// Transcribes a recording.
  static String get meetingTranscribe => _english.meetingTranscribe;

  /// Transcription progress, one part at a time.
  static String meetingTranscribing(int done, int total) =>
      _english.meetingTranscribing(done, total);

  /// No service can transcribe right now.
  static String get meetingTranscribeUnavailable =>
      _english.meetingTranscribeUnavailable;

  /// Plays a recording in the device's player.
  static String get meetingPlay => _english.meetingPlay;

  /// A take that was interrupted is still on the meeting.
  static String get meetingInterruptedKept => _english.meetingInterruptedKept;

  /// Photographs a handout or a whiteboard.
  static String get meetingPhotographHandout =>
      _english.meetingPhotographHandout;

  /// An attached document.
  static String get meetingDocument => _english.meetingDocument;

  /// An attached photo.
  static String get meetingPhoto => _english.meetingPhoto;

  /// What an attachment is, and its size.
  static String meetingFileDetail(String kind, int bytes) =>
      _english.meetingFileDetail(kind, bytes);

  /// A recording's length and size.
  static String meetingRecordingDetail(Duration length, int bytes) =>
      _english.meetingRecordingDetail(length, bytes);

  /// A cell of the sheet that read with low confidence.
  static String get meetingCheckReading => _english.meetingCheckReading;

  /// A signature was seen on the sheet.
  static String get meetingSigned => _english.meetingSigned;

  /// Whether a person attended or sent apologies.
  static String get meetingAttendance => _english.meetingAttendance;

  /// A staff row offered for a captured name, with its match score.
  static String meetingStaffSuggestion(String name, double score) =>
      _english.meetingStaffSuggestion(name, score);

  /// The staff row a person accepted.
  static String meetingStaffLinked(String name) =>
      _english.meetingStaffLinked(name);

  /// Removes an accepted staff link.
  static String get meetingUnlinkStaff => _english.meetingUnlinkStaff;

  /// One owner a person can pick for an action.
  static String meetingOwnerOption(String name, {required bool staff}) =>
      _english.meetingOwnerOption(name, staff: staff);

  /// Action status: not finished.
  static String get meetingStatusOpen => _english.meetingStatusOpen;

  /// Action status: under way.
  static String get meetingStatusInProgress => _english.meetingStatusInProgress;

  /// Action status: finished.
  static String get meetingStatusDone => _english.meetingStatusDone;

  /// Where a refined decision or action was read from.
  static String meetingSourceLine(String source) =>
      _english.meetingSourceLine(source);

  /// Drag handle of one agenda point.
  static String meetingDrag(String title) => _english.meetingDrag(title);

  /// Moves an entry earlier.
  static String get meetingMoveUp => _english.meetingMoveUp;

  /// Deliverable export page title.
  static String get exportTitle => _english.exportTitle;

  /// Starts the export.
  static String get exportRun => _english.exportRun;

  /// Scope section title.
  static String get exportScope => _english.exportScope;

  /// Approved records only.
  static String get exportScopeApproved => _english.exportScopeApproved;

  /// Every record.
  static String get exportScopeAll => _english.exportScopeAll;

  /// The current context subtree.
  static String get exportScopeContext => _english.exportScopeContext;

  /// A date range.
  static String get exportScopeDates => _english.exportScopeDates;

  /// The records list filter.
  static String get exportScopeFilter => _english.exportScopeFilter;

  /// How many records the scope selects.
  static String exportCount(int count) => _english.exportCount(count);

  /// Options section title.
  static String get exportOptions => _english.exportOptions;

  /// Raw value columns.
  static String get exportRaw => _english.exportRaw;

  /// Refined value columns.
  static String get exportRefined => _english.exportRefined;

  /// Confidence column.
  static String get exportConfidence => _english.exportConfidence;

  /// Evidence column.
  static String get exportEvidence => _english.exportEvidence;

  /// Collapsed extras.
  static String get exportAdvanced => _english.exportAdvanced;

  /// Photo reference mode.
  static String get exportPhotoMode => _english.exportPhotoMode;

  /// CSV delimiter.
  static String get exportDelimiter => _english.exportDelimiter;

  /// Empty export headline.
  static String get exportEmptyHeadline => _english.exportEmptyHeadline;

  /// Empty export explanation.
  static String get exportEmptyMessage => _english.exportEmptyMessage;

  /// Progress: records.
  static String get exportStageRecords => _english.exportStageRecords;

  /// Progress: photos.
  static String get exportStagePhotos => _english.exportStagePhotos;

  /// Progress: reports.
  static String get exportStageReports => _english.exportStageReports;

  /// Progress: archive.
  static String get exportStageArchive => _english.exportStageArchive;

  /// Stops an export and removes partial files.
  static String get exportCancel => _english.exportCancel;

  /// History page title.
  static String get exportHistoryTitle => _english.exportHistoryTitle;

  /// Empty history headline.
  static String get exportHistoryEmpty => _english.exportHistoryEmpty;

  /// Empty history explanation.
  static String get exportHistoryEmptyMessage =>
      _english.exportHistoryEmptyMessage;

  /// Shares a recorded file again.
  static String get exportShare => _english.exportShare;

  /// The recorded file is gone.
  static String get exportMissing => _english.exportMissing;

  /// Offers to run the stored request again.
  static String get exportRerun => _english.exportRerun;

  /// Gate: go fix the records.
  static String get exportFixNow => _english.exportFixNow;

  /// Gate: leave the incomplete ones out.
  static String get exportExclude => _english.exportExclude;

  /// Gate: export and mark the file incomplete.
  static String get exportAnyway => _english.exportAnyway;

  /// Stamp written into an incomplete export.
  static String get exportIncompleteStamp => _english.exportIncompleteStamp;

  /// Why an export with no records in its scope was not written.
  static String get exportEmptyRecovery => _english.exportEmptyRecovery;

  /// Why an export with no file chosen was not written.
  static String get exportNoFormat => _english.exportNoFormat;

  /// Why a history row cannot be run again from its stored request.
  static String get exportReplayMissing => _english.exportReplayMissing;

  /// Export screen: what the export writes.
  static String get exportOutput => _english.exportOutput;

  /// Output choice: chosen reports and data files for readers outside the
  /// app. The project package is [exportFileFormat].
  static String get exportOutputFiles => _english.exportOutputFiles;

  /// Export screen: which files the reports-and-data output writes.
  static String get exportFormats => _english.exportFormats;

  /// File choice: the workbook.
  static String get exportFormatXlsx => _english.exportFormatXlsx;

  /// File choice: one CSV file per template.
  static String get exportFormatCsv => _english.exportFormatCsv;

  /// File choice: full-fidelity JSON.
  static String get exportFormatJson => _english.exportFormatJson;

  /// File choice: the PDF reports.
  static String get exportFormatPdf => _english.exportFormatPdf;

  /// The name of an export scope, by its stored kind.
  static String exportScopeName(String kind) => _english.exportScopeName(kind);

  /// Date-range scope: first capture day included.
  static String get exportScopeFrom => _english.exportScopeFrom;

  /// Date-range scope: last capture day included.
  static String get exportScopeTo => _english.exportScopeTo;

  /// Advanced extra: the data dictionary.
  static String get exportDictionary => _english.exportDictionary;

  /// Workbook photo reference: the file name only.
  static String get exportPhotoFilename => _english.exportPhotoFilename;

  /// Workbook photo reference: the path inside the package.
  static String get exportPhotoRelative => _english.exportPhotoRelative;

  /// Workbook photo reference: the image itself.
  static String get exportPhotoEmbed => _english.exportPhotoEmbed;

  /// Advanced extra: how reports lay out photos.
  static String get exportPdfPhotos => _english.exportPdfPhotos;

  /// Report photo layout: several to a row.
  static String get exportPdfThumbnails => _english.exportPdfThumbnails;

  /// Report photo layout: one to a row.
  static String get exportPdfFull => _english.exportPdfFull;

  /// CSV delimiter choice: comma.
  static String get exportDelimiterComma => _english.exportDelimiterComma;

  /// CSV delimiter choice: semicolon.
  static String get exportDelimiterSemicolon =>
      _english.exportDelimiterSemicolon;

  /// CSV delimiter choice: tab.
  static String get exportDelimiterTab => _english.exportDelimiterTab;

  /// Pre-export gate title, naming how many records need a decision.
  static String exportGateTitle(int n) => _english.exportGateTitle(n);

  /// Pre-export gate message: what is incomplete, unapproved or blocked.
  static String exportGateMessage({
    required int incomplete,
    required int unapproved,
    required int blocked,
  }) => _english.exportGateMessage(
    incomplete: incomplete,
    unapproved: unapproved,
    blocked: blocked,
  );

  /// Gate choice detail: fix the records first.
  static String get exportFixNowHint => _english.exportFixNowHint;

  /// Gate choice detail: export the rest.
  static String exportExcludeHint(int n) => _english.exportExcludeHint(n);

  /// Gate choice detail: export everything, stamped incomplete.
  static String get exportAnywayHint => _english.exportAnywayHint;

  /// History row detail: when, who and how many records.
  static String exportHistoryDetail(String when, String operator, int n) =>
      _english.exportHistoryDetail(when, operator, n);

  /// Report footer page number.
  static String pdfPageOf(int page, int pages) =>
      _english.pdfPageOf(page, pages);

  /// Printed where a photo could not be read.
  static String get pdfMissingPhoto => _english.pdfMissingPhoto;

  /// Report title: one section per record.
  static String get pdfRecordReport => _english.pdfRecordReport;

  /// Report label of when a record was captured.
  static String get pdfCaptured => _english.pdfCaptured;

  /// A field label marked as the raw value.
  static String pdfRaw(String label) => _english.pdfRaw(label);

  /// A field label marked as the refined value.
  static String pdfRefined(String label) => _english.pdfRefined(label);

  /// Report title: a checklist in its predefined order.
  static String get pdfInspectionReport => _english.pdfInspectionReport;

  /// A checklist row never captured.
  static String get pdfNotFound => _english.pdfNotFound;

  /// How many predefined rows a checklist has.
  static String pdfChecklistRows(int n) => _english.pdfChecklistRows(n);

  /// How many checklist rows were not found.
  static String pdfNotFoundCount(int n) => _english.pdfNotFoundCount(n);

  /// How many checklist rows comply.
  static String pdfCompliance(int compliant, int total) =>
      _english.pdfCompliance(compliant, total);

  /// Report title: the project's counts.
  static String get pdfSummaryReport => _english.pdfSummaryReport;

  /// Summary heading: counts by context.
  static String get pdfByContext => _english.pdfByContext;

  /// Summary heading: counts by template.
  static String get pdfByTemplate => _english.pdfByTemplate;

  /// Summary heading: counts by condition.
  static String get pdfByCondition => _english.pdfByCondition;

  /// Summary heading: counts by status.
  static String get pdfByStatus => _english.pdfByStatus;

  /// Summary group of records captured with no context.
  static String get pdfNoContext => _english.pdfNoContext;

  /// Summary group of records with no condition recorded.
  static String get pdfNoCondition => _english.pdfNoCondition;

  /// Summary status group: not processed yet.
  static String get pdfUnprocessed => _english.pdfUnprocessed;

  /// Summary status group: waiting for review.
  static String get pdfNeedsReview => _english.pdfNeedsReview;

  /// Summary status group: approved.
  static String get pdfApproved => _english.pdfApproved;

  /// Report title: as-recorded against as-found.
  static String get pdfVarianceReport => _english.pdfVarianceReport;

  /// Variance section: register items found.
  static String get pdfMatched => _english.pdfMatched;

  /// Variance section: found items the register does not list.
  static String get pdfNotInRegister => _english.pdfNotInRegister;

  /// Report title: meeting minutes.
  static String get pdfMinutesReport => _english.pdfMinutesReport;

  /// Label of an action's due date.
  static String get pdfDue => _english.pdfDue;

  /// An action's status as the register prints it.
  static String pdfActionStatus(String stored) =>
      _english.pdfActionStatus(stored);

  /// A matched register item whose field was found different.
  static String pdfVarianceChanged(
    String field,
    String recorded,
    String found,
  ) => _english.pdfVarianceChanged(field, recorded, found);

  /// A matched register item whose field was found empty.
  static String pdfVarianceEmpty(String field, String recorded) =>
      _english.pdfVarianceEmpty(field, recorded);

  /// Heading of the minutes' photo appendix.
  static String get pdfPhotoAppendix => _english.pdfPhotoAppendix;

  /// Points from the discussion to the photo appendix.
  static String pdfPhotoReference(int n) => _english.pdfPhotoReference(n);

  /// Cover fact: when the export was made.
  static String pdfExportedAt(String when) => _english.pdfExportedAt(when);

  /// Cover fact: who made the export.
  static String pdfExportedBy(String operator) =>
      _english.pdfExportedBy(operator);

  /// Cover fact: which records the export selected.
  static String pdfScope(String scope) => _english.pdfScope(scope);

  /// Types a replacement for a conflict.
  static String get conflictTypeValue => _english.conflictTypeValue;

  /// Leaves a conflict unsettled.
  static String get conflictDecideLater => _english.conflictDecideLater;

  /// Caption replacement label in the conflict editor.
  static String get conflictCaptionLabel => _english.conflictCaptionLabel;

  /// Replacement value chosen by the operator.
  static String get mergeConflictTyped => _english.mergeConflictTyped;

  /// Bundle scope section title.
  /// Password input for an encrypted project package.
  static String get bundlePassword => _english.bundlePassword;

  /// Empty protected bundle password.
  static String get bundlePasswordRequired => _english.bundlePasswordRequired;

  /// Optional password protection for the current package only.
  static String get bundlePasswordOptional => _english.bundlePasswordOptional;

  /// Indicates protection without displaying the password.
  static String get bundlePasswordSet => _english.bundlePasswordSet;

  /// Bundle inclusion scope section.
  static String get bundleScope => _english.bundleScope;

  /// The whole project.
  static String get bundleScopeFull => _english.bundleScopeFull;

  /// A date range of records.
  static String get bundleScopeDates => _english.bundleScopeDates;

  /// The current context subtree.
  static String get bundleScopeContext => _english.bundleScopeContext;

  /// Approved records only.
  static String get bundleScopeApproved => _english.bundleScopeApproved;

  /// Records without their photos.
  static String get bundleScopeData => _english.bundleScopeData;

  /// Estimated bundle size.
  static String bundleSize(String label) => _english.bundleSize(label);

  /// Shares the bundle file.
  static String get bundleShare => _english.bundleShare;

  /// Opens a bundle that arrived from outside the app.
  static String get bundleOpen => _english.bundleOpen;

  /// Merge history title.
  static String get mergeHistoryTitle => _english.mergeHistoryTitle;

  /// Empty merge history.
  static String get mergeHistoryEmpty => _english.mergeHistoryEmpty;

  /// Empty merge history explanation.
  static String get mergeHistoryEmptyMessage =>
      _english.mergeHistoryEmptyMessage;

  /// Undo is still available.
  static String mergeUndoUntil(String when) => _english.mergeUndoUntil(when);

  /// Locale-aware undo deadline and merge provenance.
  static String mergeUndoDeadline(DateTime until) =>
      _english.mergeUndoDeadline(until);

  /// Package identity, import time and outcome in the history list.
  static String mergeHistoryFacts(
    String name,
    String id,
    DateTime at,
    String status,
  ) => _english.mergeHistoryFacts(name, id, at, status);

  /// Count of one durable merge category.
  static String mergeHistoryCount(String key, int n) =>
      _english.mergeHistoryCount(key, n);

  /// Count of one operator resolution.
  static String mergeHistoryResolution(String choice, int n) =>
      _english.mergeHistoryResolution(choice, n);

  /// Undo refuses to discard edits made after a merge.
  static String get mergeUndoChanged => _english.mergeUndoChanged;

  /// Recovery offered when newer work prevents restoring an old snapshot.
  static String get mergeUndoChangedRecovery =>
      _english.mergeUndoChangedRecovery;

  /// Missing, expired or previously undone snapshot.
  static String get mergeUndoUnavailable => _english.mergeUndoUnavailable;

  /// Confirmation after the durable restore commits.
  static String get mergeUndoDone => _english.mergeUndoDone;

  /// Explains exactly what undo restores and retains.
  static String get mergeUndoConfirm => _english.mergeUndoConfirm;

  /// Import page title.
  static String get importTitle => _english.importTitle;

  /// Empty import headline.
  static String get importEmptyHeadline => _english.importEmptyHeadline;

  /// Empty import explanation.
  static String get importEmptyMessage => _english.importEmptyMessage;

  /// The import page's one action: pick a file.
  static String get importChooseFile => _english.importChooseFile;

  /// Shown while a chosen file is checked or read.
  static String get importCheckingFile => _english.importCheckingFile;

  /// Heading over the four kinds of file the import page takes.
  static String get importKindsTitle => _english.importKindsTitle;

  /// A bundle, on the import page.
  static String get importKindBundle => _english.importKindBundle;

  /// Where a bundle goes.
  static String get importBundleLine => _english.importBundleLine;

  /// A reference dataset, on the import page.
  static String get importKindDataset => _english.importKindDataset;

  /// Where a dataset goes.
  static String get importDatasetLine => _english.importDatasetLine;

  /// A template, on the import page.
  static String get importKindTemplate => _english.importKindTemplate;

  /// Where a template goes.
  static String get importTemplateLine => _english.importTemplateLine;

  /// A spreadsheet, on the import page.
  static String get importKindSheet => _english.importKindSheet;

  /// Where a row spreadsheet goes.
  static String get importSheetLine => _english.importSheetLine;

  /// A file the import page does not take.
  static String get importUnsupported => _english.importUnsupported;

  /// Every kind except a bundle is added to the open project.
  static String get importNeedsProject => _english.importNeedsProject;

  /// Recovery for [importNeedsProject].
  static String get importNeedsProjectRecovery =>
      _english.importNeedsProjectRecovery;

  /// Purpose page title.
  static String get importPurposeTitle => _english.importPurposeTitle;

  /// Rows become records.
  static String get importPurposeRecords => _english.importPurposeRecords;

  /// What choosing [importPurposeRecords] does.
  static String get importPurposeRecordsLine =>
      _english.importPurposeRecordsLine;

  /// Rows feed verification.
  static String get importPurposeRegister => _english.importPurposeRegister;

  /// What choosing [importPurposeRegister] does.
  static String get importPurposeRegisterLine =>
      _english.importPurposeRegisterLine;

  /// Mapping and summary pages with no sheet chosen.
  static String get importNoSheetHeadline => _english.importNoSheetHeadline;

  /// Explains [importNoSheetHeadline].
  static String get importNoSheetMessage => _english.importNoSheetMessage;

  /// Mapping page title.
  static String get importMappingTitle => _english.importMappingTitle;

  /// Label of the template the rows are matched onto.
  static String get importMappingTemplate => _english.importMappingTemplate;

  /// Heading over the column-to-field choices.
  static String get importMappingColumns => _english.importMappingColumns;

  /// A header with no field yet.
  static String get importUnmapped => _english.importUnmapped;

  /// A project with no template to match the sheet onto.
  static String get importNoTemplateHeadline =>
      _english.importNoTemplateHeadline;

  /// Explains [importNoTemplateHeadline].
  static String get importNoTemplateMessage => _english.importNoTemplateMessage;

  /// Opens template mapping for the chosen sheet.
  static String get importMakeTemplate => _english.importMakeTemplate;

  /// Heading over the first rows, as they will be read.
  static String get importPreviewTitle => _english.importPreviewTitle;

  /// One spreadsheet row, by its number in the file.
  static String importRow(int row) => _english.importRow(row);

  /// The mapping page's one action.
  static String importRun(int rows) => _english.importRun(rows);

  /// Names the identity field that is still unmapped.
  static String importIdentityMissing(String field) =>
      _english.importIdentityMissing(field);

  /// Shown while the rows are written.
  static String get importWriting => _english.importWriting;

  /// How far the import has got.
  static String importProgress(int done, int total) =>
      _english.importProgress(done, total);

  /// Why a row that matches a record was left alone.
  static String get importKeptExisting => _english.importKeptExisting;

  /// Why a matching row was skipped with no choice made.
  static String get importMatchUnsettled => _english.importMatchUnsettled;

  /// Why a row that repeats an earlier row's identity was not written.
  static String importRepeatsRow(int row) => _english.importRepeatsRow(row);

  /// Every row was written.
  static String get importAllDone => _english.importAllDone;

  /// Opens the project's records after an import.
  static String get importOpenRecords => _english.importOpenRecords;

  /// File name of the rows to correct and import again.
  static String get importFixFileName => _english.importFixFileName;

  /// Column of the rows-to-fix file naming each row's number in the sheet.
  static String get importFixRowColumn => _english.importFixRowColumn;

  /// Column of the rows-to-fix file saying why each row was not written.
  static String get importFixReasonColumn => _english.importFixReasonColumn;

  /// Announced once the rows to fix are saved.
  static String get importFixSaved => _english.importFixSaved;

  /// Summary page title.
  static String get importSummaryTitle => _english.importSummaryTitle;

  /// How many rows were created.
  static String importCreated(int count) => _english.importCreated(count);

  /// How many rows updated a record.
  static String importUpdated(int count) => _english.importUpdated(count);

  /// How many rows were skipped.
  static String importSkipped(int count) => _english.importSkipped(count);

  /// How many rows failed.
  static String importFailed(int count) => _english.importFailed(count);

  /// Re-runs only the failed rows.
  static String get importRetry => _english.importRetry;

  /// Writes the skipped and failed rows.
  static String get importExportProblems => _english.importExportProblems;

  /// Match sheet title.
  static String get importMatchTitle => _english.importMatchTitle;

  /// Says which row matched.
  static String importMatchMessage(int row) => _english.importMatchMessage(row);

  /// Label of the choice on the match sheet.
  static String get importMatchChoice => _english.importMatchChoice;

  /// Leave the existing record unchanged.
  static String get importKeepExisting => _english.importKeepExisting;

  /// Replace the existing record with the row.
  static String get importReplace => _english.importReplace;

  /// Fill only empty fields from the row.
  static String get importMerge => _english.importMerge;

  /// Applies the choice to every later match.
  static String get importApplyToAll => _english.importApplyToAll;

  /// Confirms the match sheet.
  static String get importMatchConfirm => _english.importMatchConfirm;

  /// Settings row for cloud destinations.
  static String get cloudDestinationsTitle => _english.cloudDestinationsTitle;

  /// Settings row explanation.
  static String get cloudDestinationsSubtitle =>
      _english.cloudDestinationsSubtitle;

  /// Destinations page title.
  static String get destinationTitle => _english.destinationTitle;

  /// Empty destinations headline.
  static String get destinationEmptyHeadline =>
      _english.destinationEmptyHeadline;

  /// Empty destinations explanation.
  static String get destinationEmptyMessage => _english.destinationEmptyMessage;

  /// Starts adding a destination.
  static String get destinationAdd => _english.destinationAdd;

  /// Saves a destination after its test succeeds.
  static String get destinationSave => _english.destinationSave;

  /// Runs the probe upload.
  static String get destinationTest => _english.destinationTest;

  /// Removes a destination.
  static String get destinationRemove => _english.destinationRemove;

  /// Removal confirm title.
  static String get destinationRemoveTitle => _english.destinationRemoveTitle;

  /// Removal confirm explanation.
  static String get destinationRemoveMessage =>
      _english.destinationRemoveMessage;

  /// Shown when the probe upload fails, so save stays disabled.
  static String get destinationCheckFailed => _english.destinationCheckFailed;

  /// Label field.
  static String get destinationLabel => _english.destinationLabel;

  /// Folder field.
  static String get destinationFolder => _english.destinationFolder;

  /// Obscured credential field.
  static String get destinationSecret => _english.destinationSecret;

  /// S3 kind label.
  static String get destinationKindS3 => _english.destinationKindS3;

  /// Google Drive kind label.
  static String get destinationKindDrive => _english.destinationKindDrive;

  /// OneDrive kind label.
  static String get destinationKindOneDrive => _english.destinationKindOneDrive;

  /// Dropbox kind label.
  static String get destinationKindDropbox => _english.destinationKindDropbox;

  /// WebDAV kind label.
  static String get destinationKindWebDav => _english.destinationKindWebDav;

  /// Device folder kind label.
  static String get destinationKindLocal => _english.destinationKindLocal;

  /// Title of the sheet that changes a saved destination.
  static String get destinationEdit => _english.destinationEdit;

  /// Row action that opens the destination for editing.
  static String get destinationEditAction => _english.destinationEditAction;

  /// Label of the destination type choice.
  static String get destinationKind => _english.destinationKind;

  /// Submit on the destination form: the probe runs, then the save.
  static String get destinationCheckAndSave => _english.destinationCheckAndSave;

  /// Folder field for an S3 destination: the key prefix.
  static String get destinationBucketFolder => _english.destinationBucketFolder;

  /// Hint on a field that may stay empty.
  static String get destinationOptional => _english.destinationOptional;

  /// Hint on the device folder field.
  static String get destinationLocalFolderHint =>
      _english.destinationLocalFolderHint;

  /// Opens the platform folder picker for a device or card folder.
  static String get destinationChooseFolder => _english.destinationChooseFolder;

  /// S3 access key field.
  static String get destinationAccessKey => _english.destinationAccessKey;

  /// S3 secret key field. Obscured.
  static String get destinationSecretKey => _english.destinationSecretKey;

  /// S3 region field.
  static String get destinationRegion => _english.destinationRegion;

  /// S3 bucket field.
  static String get destinationBucket => _english.destinationBucket;

  /// S3-compatible endpoint field.
  static String get destinationEndpoint => _english.destinationEndpoint;

  /// Hint on the endpoint field.
  static String get destinationEndpointHint => _english.destinationEndpointHint;

  /// WebDAV server address field.
  static String get destinationAddress => _english.destinationAddress;

  /// Hint on the WebDAV address field.
  static String get destinationAddressHint => _english.destinationAddressHint;

  /// Label of the WebDAV sign-in method choice.
  static String get destinationSignInMethod => _english.destinationSignInMethod;

  /// Basic authentication.
  static String get destinationSignInPassword =>
      _english.destinationSignInPassword;

  /// Bearer authentication.
  static String get destinationSignInToken => _english.destinationSignInToken;

  /// WebDAV user name field.
  static String get destinationUsername => _english.destinationUsername;

  /// WebDAV password field. Obscured.
  static String get destinationPassword => _english.destinationPassword;

  /// WebDAV token field. Obscured.
  static String get destinationToken => _english.destinationToken;

  /// Explains that an edit keeps the stored sign-in unless replaced.
  static String get destinationKeepSignIn => _english.destinationKeepSignIn;

  /// Asks for a new provider sign-in when a saved one was revoked.
  static String get destinationSignInAgain => _english.destinationSignInAgain;

  /// Says a provider destination signs in when it is saved.
  static String destinationSignInNote(String provider) =>
      _english.destinationSignInNote(provider);

  /// No browser sign-in is available for this provider.
  static String get destinationSignInUnavailable =>
      _english.destinationSignInUnavailable;

  /// The sign-in that came back was not the one this form started.
  static String get destinationSignInMismatch =>
      _english.destinationSignInMismatch;

  /// Shown instead of an empty remote folder.
  static String get destinationFolderRoot => _english.destinationFolderRoot;

  /// The first half of a removal failed: nothing was removed.
  static String get destinationRemoveNothing =>
      _english.destinationRemoveNothing;

  /// The second half of a removal failed.
  static String get destinationRemoveHalf => _english.destinationRemoveHalf;

  /// Recovery for a failed removal.
  static String get destinationRemoveAgain => _english.destinationRemoveAgain;

  /// An undone removal could not list the destination again.
  static String get destinationRestoreFailed =>
      _english.destinationRestoreFailed;

  /// Recovery for a failed restore.
  static String get destinationAddAgain => _english.destinationAddAgain;

  /// A cancelled removal.
  static String get destinationKept => _english.destinationKept;

  /// Recovery for a cancelled removal.
  static String get destinationKeptRecovery => _english.destinationKeptRecovery;

  /// Snack after a removal, offered with undo.
  static String destinationRemoved(String label) =>
      _english.destinationRemoved(label);

  /// Snack after an undone removal.
  static String destinationRestored(String label) =>
      _english.destinationRestored(label);

  /// Snack after a save.
  static String destinationSaved(String label) =>
      _english.destinationSaved(label);

  /// Snack after a passed connection check.
  static String destinationCheckPassed(String label) =>
      _english.destinationCheckPassed(label);

  /// Row line for the last passed check.
  static String destinationCheckedAt(DateTime at) =>
      _english.destinationCheckedAt(at);

  /// Row line for the last failed check.
  static String destinationCheckFailedAt(String reason) =>
      _english.destinationCheckFailedAt(reason);

  /// Row line while a check runs.
  static String get destinationChecking => _english.destinationChecking;

  /// Headline when this device can hold no destination.
  static String get destinationUnavailableHeadline =>
      _english.destinationUnavailableHeadline;

  /// Message when this device can hold no destination.
  static String get destinationUnavailableMessage =>
      _english.destinationUnavailableMessage;

  /// Confirm sheet title.
  static String get uploadConfirmTitle => _english.uploadConfirmTitle;

  /// Confirm button.
  static String get uploadConfirm => _english.uploadConfirm;

  /// Names the file, its size, the destination and the folder.
  static String uploadConfirmMessage({
    required String name,
    required String size,
    required String destination,
    required String folder,
  }) => _english.uploadConfirmMessage(
    name: name,
    size: size,
    destination: destination,
    folder: folder,
  );

  /// History page title.
  static String get uploadHistoryTitle => _english.uploadHistoryTitle;

  /// Empty history headline.
  static String get uploadHistoryEmptyHeadline =>
      _english.uploadHistoryEmptyHeadline;

  /// Empty history explanation.
  static String get uploadHistoryEmptyMessage =>
      _english.uploadHistoryEmptyMessage;

  /// Retries one failed or interrupted upload.
  static String get uploadRetry => _english.uploadRetry;

  /// History filter label.
  static String get uploadFilter => _english.uploadFilter;

  /// The history filter option that lists every destination.
  static String get uploadFilterAll => _english.uploadFilterAll;

  /// Empty history action: set up where files can go.
  static String get uploadHistoryEmptyAction =>
      _english.uploadHistoryEmptyAction;

  /// Sends a finished file to a destination the person picks.
  static String get uploadToDestination => _english.uploadToDestination;

  /// Title of the sheet that picks the destination.
  static String get uploadPickTitle => _english.uploadPickTitle;

  /// Snack when a confirmed upload starts.
  static String uploadStarted(String destination) =>
      _english.uploadStarted(destination);

  /// Opens the upload history from a snack.
  static String get uploadView => _english.uploadView;

  /// Snack when an upload finished.
  static String uploadSent(String name, String destination) =>
      _english.uploadSent(name, destination);

  /// Snack when an upload ended without the file arriving.
  static String uploadNotSent(String reason) => _english.uploadNotSent(reason);

  /// Snack when the person stopped an upload.
  static String get uploadStopped => _english.uploadStopped;

  /// The file to send is gone or changed size.
  static String get uploadFileMissing => _english.uploadFileMissing;

  /// Recovery for a missing file.
  static String get uploadFileMissingRecovery =>
      _english.uploadFileMissingRecovery;

  /// The destination of a retried upload was removed.
  static String get uploadDestinationGone => _english.uploadDestinationGone;

  /// Recovery for a removed destination.
  static String get uploadDestinationGoneRecovery =>
      _english.uploadDestinationGoneRecovery;

  /// Outcome: the file arrived.
  static String get uploadOutcomeSent => _english.uploadOutcomeSent;

  /// Outcome: the upload failed.
  static String get uploadOutcomeFailed => _english.uploadOutcomeFailed;

  /// Outcome: the upload never finished, for example the app closed.
  static String get uploadOutcomeInterrupted =>
      _english.uploadOutcomeInterrupted;

  /// Outcome: the person stopped it.
  static String get uploadOutcomeStopped => _english.uploadOutcomeStopped;

  /// One history row: outcome, destination, size and start time.
  static String uploadAttemptLine({
    required String outcome,
    required String destination,
    required String size,
    required DateTime startedAt,
  }) => _english.uploadAttemptLine(
    outcome: outcome,
    destination: destination,
    size: size,
    startedAt: startedAt,
  );

  /// A row while its upload runs.
  static String uploadSendingLine({
    required String destination,
    required int percent,
  }) => _english.uploadSendingLine(destination: destination, percent: percent);

  /// Row action that stops a running upload.
  static String get uploadStop => _english.uploadStop;

  /// Row action that shows every field of an attempt.
  static String get uploadDetails => _english.uploadDetails;

  /// Every field of one attempt, for the details dialog.
  static String uploadDetailsMessage({
    required String file,
    required String destination,
    required String folder,
    required String size,
    required DateTime startedAt,
    required DateTime? endedAt,
    required String outcome,
    required String? reason,
  }) => _english.uploadDetailsMessage(
    file: file,
    destination: destination,
    folder: folder,
    size: size,
    startedAt: startedAt,
    endedAt: endedAt,
    outcome: outcome,
    reason: reason,
  );

  /// Privacy screen title.
  static String get privacyScreenTitle => _english.privacyScreenTitle;

  /// Empty privacy headline.
  static String get privacyEmptyHeadline => _english.privacyEmptyHeadline;

  /// Empty privacy explanation.
  static String get privacyEmptyMessage => _english.privacyEmptyMessage;

  /// Section of the privacy page listing analysis calls.
  static String get egressAnalysisSection => _english.egressAnalysisSection;

  /// Section of the privacy page listing uploads and the relay.
  static String get egressUploadsSection => _english.egressUploadsSection;

  /// Notice while offline mode stops every outbound call.
  static String get egressOfflineNotice => _english.egressOfflineNotice;

  /// Analysis row: reading text from photos.
  static String get egressReadText => _english.egressReadText;

  /// Analysis row: filling a record's fields.
  static String get egressExtractFields => _english.egressExtractFields;

  /// Analysis row: tidying captions.
  static String get egressRefineText => _english.egressRefineText;

  /// Analysis row: speech to text.
  static String get egressTranscribe => _english.egressTranscribe;

  /// What one outbound path sends, and where it goes.
  static String egressRow(String sends, String destination) =>
      _english.egressRow(sends, destination);

  /// What an extraction call sends.
  static String get egressSendsText => _english.egressSendsText;

  /// What an image call sends.
  static String get egressSendsImage => _english.egressSendsImage;

  /// What speech sends.
  static String get egressSendsAudio => _english.egressSendsAudio;

  /// What a cloud upload sends.
  static String get egressSendsFile => _english.egressSendsFile;

  /// What the relay sends.
  static String get egressSendsPackage => _english.egressSendsPackage;

  /// Relay row title.
  static String get egressRelay => _english.egressRelay;

  /// Where the relay sends.
  static String get egressRelayServer => _english.egressRelayServer;

  /// Basis written when images stay on the device.
  static String get egressTextOnly => _english.egressTextOnly;

  /// Location section title.
  static String get gpsPrivacyTitle => _english.gpsPrivacyTitle;

  /// GPS stays off until this is on.
  static String get gpsPrivacyCapture => _english.gpsPrivacyCapture;

  /// Where location capture is switched, and its state.
  static String gpsPrivacyCaptureState(bool on) =>
      _english.gpsPrivacyCaptureState(on);

  /// Drops coordinates from exports.
  static String get gpsPrivacyExclude => _english.gpsPrivacyExclude;

  /// What leaving coordinates out covers.
  static String get gpsPrivacyExcludeEffect => _english.gpsPrivacyExcludeEffect;

  /// Removes coordinates already stored.
  static String get gpsPrivacyRemove => _english.gpsPrivacyRemove;

  /// Confirms removing the open project's coordinates.
  static String get gpsPrivacyRemoveTitle => _english.gpsPrivacyRemoveTitle;

  /// What removing coordinates does.
  static String gpsPrivacyRemoveMessage(String project) =>
      _english.gpsPrivacyRemoveMessage(project);

  /// Confirm button for removing coordinates.
  static String get gpsPrivacyRemoveConfirm => _english.gpsPrivacyRemoveConfirm;

  /// How many records lost their coordinates.
  static String gpsPrivacyRemoved(int count) =>
      _english.gpsPrivacyRemoved(count);

  /// Why the removal is not offered.
  static String get gpsPrivacyNoProject => _english.gpsPrivacyNoProject;

  /// Blurs faces in exported photos.
  static String get faceBlurTitle => _english.faceBlurTitle;

  /// What face blurring does, and what happens when it cannot.
  static String get faceBlurEffect => _english.faceBlurEffect;

  /// Redaction editor title and its entry point.
  static String get redactionTitle => _english.redactionTitle;

  /// Records held back because no confirmed consent was captured.
  static String exportConsentOmitted(List<String> ids) =>
      _english.exportConsentOmitted(ids);

  /// Face discovery remains visible for each protected photo.
  static String exportFaceCounts(Map<String, int> counts) =>
      _english.exportFaceCounts(counts);

  /// A saved artifact must be regenerated under the current protections.
  static String get exportPrivacyChanged => _english.exportPrivacyChanged;

  /// How to mark a region.
  static String get redactionHint => _english.redactionHint;

  /// Saves the marked regions.
  static String get redactionSave => _english.redactionSave;

  /// How many regions are hidden.
  static String redactionCount(int count) => _english.redactionCount(count);

  /// After saving the marks.
  static String get redactionSaved => _english.redactionSaved;

  /// Empty redaction editor headline.
  static String get redactionEmptyHeadline => _english.redactionEmptyHeadline;

  /// Empty redaction editor explanation.
  static String get redactionEmptyMessage => _english.redactionEmptyMessage;

  /// Location permission sentence.
  static String get permissionLocation => _english.permissionLocation;

  /// Storage permission sentence.
  static String get permissionStorage => _english.permissionStorage;

  /// Notification permission sentence.
  static String get permissionNotifications => _english.permissionNotifications;

  /// Settings row for privacy.
  static String get privacyTitle => _english.privacyTitle;

  /// Settings row explanation.
  static String get privacySubtitle => _english.privacySubtitle;

  /// Settings row for the organisation server.
  static String get backendSettingsTitle => _english.backendSettingsTitle;

  /// Relay empty state when no project is open.
  static String get relayChooseProject => _english.relayChooseProject;

  /// Relay switch title.
  static String get relayEnable => _english.relayEnable;

  /// Relay switch explanation.
  static String get relayEnableHelp => _english.relayEnableHelp;

  /// Relay shared-key field label.
  static String get relaySharedKey => _english.relaySharedKey;

  /// Relay shared-key guidance.
  static String get relayKeyHelp => _english.relayKeyHelp;

  /// Relay action that queues the whole project as one package.
  static String get relayQueueProject => _english.relayQueueProject;

  /// Relay action that sends queued and fetches incoming packages.
  static String get relaySync => _english.relaySync;

  /// Relay row that previews a received package before merge.
  static String get relayReceivedPackage => _english.relayReceivedPackage;

  /// Optional catalogue ranking, always presented as a person's choice.
  static String get shippedSuggestWithAi => _english.shippedSuggestWithAi;

  /// Badge on a template the AI ranking suggested.
  static String get shippedAiSuggestion => _english.shippedAiSuggestion;

  /// Explanation under the AI ranking.
  static String get shippedAiSuggestionHelp => _english.shippedAiSuggestionHelp;

  /// Deployment-specific address is needed only for self-hosted installations.
  static String get backendServerAddress => _english.backendServerAddress;

  /// Guidance under the server address and organisation fields.
  static String get backendConfigurationHelp =>
      _english.backendConfigurationHelp;

  /// Session state when this device has no backend session.
  static String get backendNotSignedIn => _english.backendNotSignedIn;

  /// Session state when this device holds a backend session.
  static String get backendSignedIn => _english.backendSignedIn;

  /// Label for the cached access grant's expiry.
  static String get backendGrantUntil => _english.backendGrantUntil;

  /// Settings row: the role the organisation gave this account.
  static String get backendRole => _english.backendRole;

  /// A server role as the settings row shows it; an unknown one as sent.
  static String backendRoleName(String role) => _english.backendRoleName(role);

  /// Settings row: how far this device's enrolment has gone.
  static String get backendEnrolment => _english.backendEnrolment;

  /// Enrolment value before the first sign-in.
  static String get backendNotEnrolled => _english.backendNotEnrolled;

  /// Enrolment value while a sign-in is in flight.
  static String get backendEnrolling => _english.backendEnrolling;

  /// Enrolment value once a grant is cached.
  static String get backendEnrolled => _english.backendEnrolled;

  /// Enrolment value after the organisation ended the grant.
  static String get backendRevokedState => _english.backendRevokedState;

  /// Banner when the organisation ended this device's sign-in.
  static String get backendRevoked => _english.backendRevoked;

  /// Secondary action on the first-run sign-in: work starts without it.
  static String get signInLater => _english.signInLater;

  /// Action that ends the backend session on this device.
  static String get signOutAction => _english.signOutAction;

  /// Settings row explanation for the server address and grant.
  static String get backendSettingsSubtitle => _english.backendSettingsSubtitle;

  /// Sign-in screen title.
  static String get signInTitle => _english.signInTitle;

  /// Sign-in action.
  static String get signInAction => _english.signInAction;

  /// Email field.
  static String get signInEmail => _english.signInEmail;

  /// Password field.
  static String get signInPassword => _english.signInPassword;

  /// Organisation field on the sign-in screen.
  static String get signInOrganisation => _english.signInOrganisation;

  /// Quiet line when the server cannot be reached.
  static String get backendUnreachable => _english.backendUnreachable;

  /// Shown when a grant has expired for relay or analysis.
  static String get backendGrantExpired => _english.backendGrantExpired;

  /// Sign-out confirmation title.
  static String get signOutTitle => _english.signOutTitle;

  /// Sign-out warning.
  static String get signOutMessage => _english.signOutMessage;

  /// Relay control title.
  static String get relayTitle => _english.relayTitle;

  /// Relay is waiting for a project manager.
  static String get relayOff => _english.relayOff;

  /// Relay needs a sign-in this device does not hold.
  static String get relaySignInNeeded => _english.relaySignInNeeded;

  /// Action that opens the shared-key form.
  static String get relayAddKey => _english.relayAddKey;

  /// A never-relay project has no send action.
  static String get relayNever => _english.relayNever;

  /// Send action for an enabled relay.
  static String get relaySend => _english.relaySend;

  /// Count of packages waiting to send.
  static String get relayQueued => _english.relayQueued;

  /// Count of packages the server accepted.
  static String get relaySent => _english.relaySent;

  /// Count of packages the server has purged.
  static String get relayPurged => _english.relayPurged;

  /// Trial control that records a problem on this screen.
  static String get frictionLogAction => _english.frictionLogAction;

  /// Optional context the tester adds to a trial report.
  static String get frictionNote => _english.frictionNote;

  /// Explicit consent to attach the current app screen to a local report.
  static String get frictionScreenshot => _english.frictionScreenshot;

  /// Commits the report before dismissing the sheet.
  static String get frictionSave => _english.frictionSave;

  /// Confirms that the trial report is stored on this device.
  static String get frictionSaved => _english.frictionSaved;

  /// Opens the existing workbook and screenshot archive export from settings.
  static String get frictionExport => _english.frictionExport;

  /// A second save cannot begin while the first is writing.
  static String get frictionSaving => _english.frictionSaving;

  /// Named screenshot failure, with a path that keeps the optional note.
  static String get frictionScreenshotFailed =>
      _english.frictionScreenshotFailed;

  /// The tester may save the report without an image.
  static String get frictionScreenshotRecovery =>
      _english.frictionScreenshotRecovery;

  /// Refuses to overwrite a journal that could not be read.
  static String get feedbackJournalInvalid => _english.feedbackJournalInvalid;

  /// A retry keeps the existing local journal in place.
  static String get feedbackJournalRecovery => _english.feedbackJournalRecovery;

  /// Prevents a report archive from quietly omitting a saved attachment.
  static String get feedbackImageMissing => _english.feedbackImageMissing;

  /// Names the recovery without deleting the journal entry.
  static String get feedbackImageRecovery => _english.feedbackImageRecovery;

  /// Component-gallery sample Name.
  static String get gallerySampleName => _english.gallerySampleName;

  /// Component-gallery sample Caption.
  static String get gallerySampleCaption => _english.gallerySampleCaption;

  /// Component-gallery sample Count.
  static String get gallerySampleCount => _english.gallerySampleCount;

  /// Component-gallery sample Email.
  static String get gallerySampleEmail => _english.gallerySampleEmail;

  /// Component-gallery sample Phone.
  static String get gallerySamplePhone => _english.gallerySamplePhone;

  /// Component-gallery sample When.
  static String get gallerySampleWhen => _english.gallerySampleWhen;

  /// Component-gallery sample Grade.
  static String get gallerySampleGrade => _english.gallerySampleGrade;

  /// Component-gallery sample Fuel.
  static String get gallerySampleFuel => _english.gallerySampleFuel;

  /// Component-gallery sample Tags.
  static String get gallerySampleTags => _english.gallerySampleTags;

  /// Component-gallery sample GPS.
  static String get gallerySampleLocation => _english.gallerySampleLocation;

  /// Component-gallery sample Stamp each capture.
  static String get gallerySampleStampCapture =>
      _english.gallerySampleStampCapture;

  /// Component-gallery sample Boiler A.
  static String get gallerySampleBoilerA => _english.gallerySampleBoilerA;

  /// Component-gallery sample Boiler B.
  static String get gallerySampleBoilerB => _english.gallerySampleBoilerB;

  /// Component-gallery sample Open beside this list.
  static String get gallerySampleBesideList => _english.gallerySampleBesideList;

  /// Component-gallery sample Water.
  static String get gallerySampleWater => _english.gallerySampleWater;

  /// Component-gallery sample Steam.
  static String get gallerySampleSteam => _english.gallerySampleSteam;

  /// Component-gallery sample Gas.
  static String get gallerySampleGas => _english.gallerySampleGas;

  /// Component-gallery sample Chip.
  static String get gallerySampleChip => _english.gallerySampleChip;

  /// Component-gallery sample Filter.
  static String get gallerySampleFilter => _english.gallerySampleFilter;

  /// Component-gallery sample List tile.
  static String get gallerySampleListTile => _english.gallerySampleListTile;

  /// Component-gallery sample Secondary line.
  static String get gallerySampleSecondaryLine =>
      _english.gallerySampleSecondaryLine;

  /// Theme surface depth sample.
  static String surfacePreviewLevel(int level) =>
      _english.surfacePreviewLevel(level);

  /// Typography sample.
  static String typeRampSample(String name) => _english.typeRampSample(name);

  /// Explains why a package exceeds the bounded encrypted relay transport.
  static String relayPackageTooLarge(int bytes, int ceiling) =>
      _english.relayPackageTooLarge(bytes, ceiling);

  /// Offers direct sharing or a smaller export when the relay limit is hit.
  static String get relayPackageTooLargeRecovery =>
      _english.relayPackageTooLargeRecovery;

  /// Native biometric authentication rationale, shown only after opting in.
  static String get permissionBiometrics => _english.permissionBiometrics;

  /// Reduces metadata before retrying an oversized package import.
  static String get packageMetadataTooLargeRecovery =>
      _english.packageMetadataTooLargeRecovery;

  /// Default cancelled failure explanation for operator-facing errors.
  static String get failureCancelledMessage => _english.failureCancelledMessage;

  /// Default cancelled failure recovery for operator-facing errors.
  static String get failureCancelledRecovery =>
      _english.failureCancelledRecovery;

  /// Default corruption failure explanation for operator-facing errors.
  static String get failureCorruptionMessage =>
      _english.failureCorruptionMessage;

  /// Default corruption failure recovery for operator-facing errors.
  static String get failureCorruptionRecovery =>
      _english.failureCorruptionRecovery;

  /// Default network failure explanation for operator-facing errors.
  static String get failureNetworkMessage => _english.failureNetworkMessage;

  /// Default network failure recovery for operator-facing errors.
  static String get failureNetworkRecovery => _english.failureNetworkRecovery;

  /// Default permission failure explanation for operator-facing errors.
  static String get failurePermissionMessage =>
      _english.failurePermissionMessage;

  /// Default permission failure recovery for operator-facing errors.
  static String get failurePermissionRecovery =>
      _english.failurePermissionRecovery;

  /// Default provider failure explanation for operator-facing errors.
  static String get failureProviderMessage => _english.failureProviderMessage;

  /// Default provider failure recovery for operator-facing errors.
  static String get failureProviderRecovery => _english.failureProviderRecovery;

  /// Default storage failure explanation for operator-facing errors.
  static String get failureStorageMessage => _english.failureStorageMessage;

  /// Default storage failure recovery for operator-facing errors.
  static String get failureStorageRecovery => _english.failureStorageRecovery;

  /// Default validation failure explanation for operator-facing errors.
  static String get failureValidationMessage =>
      _english.failureValidationMessage;

  /// Default validation failure recovery for operator-facing errors.
  static String get failureValidationRecovery =>
      _english.failureValidationRecovery;

  /// Processing retry failure explanation.
  static String get processingTimeout => _english.processingTimeout;

  /// Processing retry failure explanation.
  static String get processingMalformedResponse =>
      _english.processingMalformedResponse;

  /// Processing retry failure explanation.
  static String get processingStopped => _english.processingStopped;

  /// Operator-facing failure retained through headless execution.
  static String get failureAIIsNotAvailable => _english.failureAIIsNotAvailable;

  /// Operator-facing failure retained through headless execution.
  static String get failureContinueCapturingAnalysisCanWait =>
      _english.failureContinueCapturingAnalysisCanWait;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatPhotoIsNotOnThisDevice =>
      _english.failureThatPhotoIsNotOnThisDevice;

  /// Operator-facing failure retained through headless execution.
  static String get failureCaptureThePhotoAgainThenTryAgain =>
      _english.failureCaptureThePhotoAgainThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatPhotoCouldNotBeReadOn =>
      _english.failureThatPhotoCouldNotBeReadOn;

  /// Operator-facing failure retained through headless execution.
  static String get failureUseAnotherPhotoOrEnterTheValue =>
      _english.failureUseAnotherPhotoOrEnterTheValue;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatPhotoCouldNotBeReadAs =>
      _english.failureThatPhotoCouldNotBeReadAs;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheAnalysisCopyCouldNotBeRead =>
      _english.failureTheAnalysisCopyCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  static String get failureKeepTheRecordAndTryAgain =>
      _english.failureKeepTheRecordAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheAnalysisResponseCouldNotBeRead =>
      _english.failureTheAnalysisResponseCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  static String get failureAnalysisCanWait => _english.failureAnalysisCanWait;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheAnalysisQuotaIsUsedUp =>
      _english.failureTheAnalysisQuotaIsUsedUp;

  /// Operator-facing failure retained through headless execution.
  static String get failureAnalysisIsPausedOnTheServerFor =>
      _english.failureAnalysisIsPausedOnTheServerFor;

  /// Operator-facing failure retained through headless execution.
  static String get failureContinueCapturingAnalysisTriesAgainLater =>
      _english.failureContinueCapturingAnalysisTriesAgainLater;

  /// Operator-facing failure retained through headless execution.
  static String get failureAnalysisAccessIsUnavailableForThisProject =>
      _english.failureAnalysisAccessIsUnavailableForThisProject;

  /// Operator-facing failure retained through headless execution.
  static String get failureContinueCapturingAndCheckOrganisationAccess =>
      _english.failureContinueCapturingAndCheckOrganisationAccess;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheAnalysisMediaIsTooLargeTo =>
      _english.failureTheAnalysisMediaIsTooLargeTo;

  /// Operator-facing failure retained through headless execution.
  static String get failureKeepTheRecordAndCompleteItWithout =>
      _english.failureKeepTheRecordAndCompleteItWithout;

  /// Operator-facing failure retained through headless execution.
  static String get failureSignInWasNotAccepted =>
      _english.failureSignInWasNotAccepted;

  /// Operator-facing failure retained through headless execution.
  static String get failureCheckYourEmailPasswordAndOrganisation =>
      _english.failureCheckYourEmailPasswordAndOrganisation;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheOrganisationEndedThisDeviceSSign =>
      _english.failureTheOrganisationEndedThisDeviceSSign;

  /// Operator-facing failure retained through headless execution.
  static String get failureSignInAgainWhenTheServerIs =>
      _english.failureSignInAgainWhenTheServerIs;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheServerCouldNotCompleteSignIn =>
      _english.failureTheServerCouldNotCompleteSignIn;

  /// Operator-facing failure retained through headless execution.
  static String get failureTryAgainWhenTheServerIsReachable =>
      _english.failureTryAgainWhenTheServerIsReachable;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheSavedSignInCouldNotBe =>
      _english.failureTheSavedSignInCouldNotBe;

  /// Operator-facing failure retained through headless execution.
  static String get failureCheckTheAccountSettingsYourLocalWork =>
      _english.failureCheckTheAccountSettingsYourLocalWork;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterTheOrganisationSHTTPSServerAddress =>
      _english.failureEnterTheOrganisationSHTTPSServerAddress;

  /// Operator-facing failure retained through headless execution.
  static String get failureCheckTheAddressWithYourAdministrator =>
      _english.failureCheckTheAddressWithYourAdministrator;

  /// Operator-facing failure retained through headless execution.
  static String get failureSignOutBeforeChangingOrganisation =>
      _english.failureSignOutBeforeChangingOrganisation;

  /// Operator-facing failure retained through headless execution.
  static String get failureKeepTheCurrentAccountOrSignOut =>
      _english.failureKeepTheCurrentAccountOrSignOut;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheOrganisationServerCouldNotBeReached =>
      _english.failureTheOrganisationServerCouldNotBeReached;

  /// Operator-facing failure retained through headless execution.
  static String get failureContinueWorkingOfflineAndTryAgainLater =>
      _english.failureContinueWorkingOfflineAndTryAgainLater;

  /// Operator-facing failure retained through headless execution.
  static String get failureUseASharedKeyOfAtLeast =>
      _english.failureUseASharedKeyOfAtLeast;

  /// Operator-facing failure retained through headless execution.
  static String get failureAskTheProjectManagerForTheSame =>
      _english.failureAskTheProjectManagerForTheSame;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisProjectIsRegisteredOnTheServer =>
      _english.failureThisProjectIsRegisteredOnTheServer;

  /// Operator-facing failure retained through headless execution.
  static String get failureAskAnAdministratorToAddYouTo =>
      _english.failureAskAnAdministratorToAddYouTo;

  /// Operator-facing failure retained through headless execution.
  static String get failureAddTheSharedProjectKeyFirst =>
      _english.failureAddTheSharedProjectKeyFirst;

  /// Operator-facing failure retained through headless execution.
  static String get failureAskTheProjectManagerForTheKey =>
      _english.failureAskTheProjectManagerForTheKey;

  /// Operator-facing failure retained through headless execution.
  static String get failureRelayCouldNotCompleteThisRequest =>
      _english.failureRelayCouldNotCompleteThisRequest;

  /// Operator-facing failure retained through headless execution.
  static String get failureKeepWorkingLocallyAndTrySyncAgain =>
      _english.failureKeepWorkingLocallyAndTrySyncAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatPasswordDidNotOpenTheBundle =>
      _english.failureThatPasswordDidNotOpenTheBundle;

  /// Operator-facing failure retained through headless execution.
  static String get failureTryThePasswordAgainNothingWasExtracted =>
      _english.failureTryThePasswordAgainNothingWasExtracted;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheProjectMetadataIsTooLargeFor =>
      _english.failureTheProjectMetadataIsTooLargeFor;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseASmallerPackageScope =>
      _english.failureChooseASmallerPackageScope;

  /// Operator-facing failure retained through headless execution.
  static String get failurePasswordProtectionIsUnavailableOnThisDevice =>
      _english.failurePasswordProtectionIsUnavailableOnThisDevice;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenThisPackageOnASupportedDevice =>
      _english.failureOpenThisPackageOnASupportedDevice;

  /// Operator-facing failure retained through headless execution.
  static String get failurePasswordProtectionNeedsBrowserCryptography =>
      _english.failurePasswordProtectionNeedsBrowserCryptography;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenTheAppThroughASecureConnection =>
      _english.failureOpenTheAppThroughASecureConnection;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisBundleNeedsAPassword =>
      _english.failureThisBundleNeedsAPassword;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterItsPasswordToOpenIt =>
      _english.failureEnterItsPasswordToOpenIt;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheBundleContainsASecretAndWas =>
      _english.failureTheBundleContainsASecretAndWas;

  /// Operator-facing failure retained through headless execution.
  static String get failureRemoveTheSecretAndExportTheBundle =>
      _english.failureRemoveTheSecretAndExportTheBundle;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheBundleHasTooManyNestedArchives =>
      _english.failureTheBundleHasTooManyNestedArchives;

  /// Operator-facing failure retained through headless execution.
  static String get failureANestedBundleArchiveCouldNotBe =>
      _english.failureANestedBundleArchiveCouldNotBe;

  /// Operator-facing failure retained through headless execution.
  static String get failureAnEncryptedOrUnsupportedAttachmentCouldNot =>
      _english.failureAnEncryptedOrUnsupportedAttachmentCouldNot;

  /// Operator-facing failure retained through headless execution.
  static String get failureANestedBundleArchiveIsTooLarge =>
      _english.failureANestedBundleArchiveIsTooLarge;

  /// Operator-facing failure retained through headless execution.
  static String get failureANestedBundleEntryHasAnInvalid =>
      _english.failureANestedBundleEntryHasAnInvalid;

  /// Operator-facing failure retained through headless execution.
  static String get failureANestedBundleEntryExceedsItsDeclared =>
      _english.failureANestedBundleEntryExceedsItsDeclared;

  /// Operator-facing failure retained through headless execution.
  static String get failureFinishReadingTheCurrentPackageEntryFirst =>
      _english.failureFinishReadingTheCurrentPackageEntryFirst;

  /// Operator-facing failure retained through headless execution.
  static String get failureThePackageEntryIsMissing =>
      _english.failureThePackageEntryIsMissing;

  /// Operator-facing failure retained through headless execution.
  static String get failureReadThisLargePackageEntryAsA =>
      _english.failureReadThisLargePackageEntryAsA;

  /// Operator-facing failure retained through headless execution.
  static String get failureThePackageEntryChanged =>
      _english.failureThePackageEntryChanged;

  /// Operator-facing failure retained through headless execution.
  static String get failureThePackageEntryChecksumChanged =>
      _english.failureThePackageEntryChecksumChanged;

  /// Operator-facing failure retained through headless execution.
  static String failureNoUploadDestinationIsRegisteredForValue(String value0) =>
      _english.failureNoUploadDestinationIsRegisteredForValue(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAnotherDestination =>
      _english.failureChooseAnotherDestination;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDestinationRefusedTheSignIn =>
      _english.failureTheDestinationRefusedTheSignIn;

  /// Operator-facing failure retained through headless execution.
  static String get failureCheckTheKeyOrSignInAgain =>
      _english.failureCheckTheKeyOrSignInAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatBucketOrFolderWasNotFound =>
      _english.failureThatBucketOrFolderWasNotFound;

  /// Operator-facing failure retained through headless execution.
  static String get failureCheckTheNameAndTryTheConnection =>
      _english.failureCheckTheNameAndTryTheConnection;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDestinationDidNotFinishTheUpload =>
      _english.failureTheDestinationDidNotFinishTheUpload;

  /// Operator-facing failure retained through headless execution.
  static String get failureTryAgain => _english.failureTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheServerRedirectedTheUploadToAnother =>
      _english.failureTheServerRedirectedTheUploadToAnother;

  /// Operator-facing failure retained through headless execution.
  static String get failureCheckTheAddressAndTryAgain =>
      _english.failureCheckTheAddressAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDestinationRejectedTheUpload =>
      _english.failureTheDestinationRejectedTheUpload;

  /// Operator-facing failure retained through headless execution.
  static String get failureCheckTheSettingsAndTryAgain =>
      _english.failureCheckTheSettingsAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheFileCouldNotBeReadWhile =>
      _english.failureTheFileCouldNotBeReadWhile;

  /// Operator-facing failure retained through headless execution.
  static String get failureCheckThatTheFileIsStillOn =>
      _english.failureCheckThatTheFileIsStillOn;

  /// Operator-facing failure retained through headless execution.
  static String get failureUploadsArePausedWhileTheAppIs =>
      _english.failureUploadsArePausedWhileTheAppIs;

  /// Operator-facing failure retained through headless execution.
  static String get failureGoOnlineThenConfirmTheUploadAgain =>
      _english.failureGoOnlineThenConfirmTheUploadAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureUploadsToThisDestinationAreTurnedOff =>
      _english.failureUploadsToThisDestinationAreTurnedOff;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnableTheDestinationOnThePrivacyPage =>
      _english.failureEnableTheDestinationOnThePrivacyPage;

  /// Operator-facing failure retained through headless execution.
  static String get failureCloudSignInCouldNotFinish =>
      _english.failureCloudSignInCouldNotFinish;

  /// Operator-facing failure retained through headless execution.
  static String get failureTrySigningInAgain =>
      _english.failureTrySigningInAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDestinationReturnedTooMuchData =>
      _english.failureTheDestinationReturnedTooMuchData;

  /// Operator-facing failure retained through headless execution.
  static String get failureCheckTheDestinationAddressAndTryAgain =>
      _english.failureCheckTheDestinationAddressAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDestinationCouldNotBeReached =>
      _english.failureTheDestinationCouldNotBeReached;

  /// Operator-facing failure retained through headless execution.
  static String get failureTryAgainWhenYouAreOnline =>
      _english.failureTryAgainWhenYouAreOnline;

  /// Operator-facing failure retained through headless execution.
  static String get failureRemoveTheDestinationAndAddItAgain =>
      _english.failureRemoveTheDestinationAndAddItAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisDestinationSignInChangedDuringThe =>
      _english.failureThisDestinationSignInChangedDuringThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureReviewTheDestinationAndConfirmANew =>
      _english.failureReviewTheDestinationAndConfirmANew;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDestinationDidNotAcceptTheTest =>
      _english.failureTheDestinationDidNotAcceptTheTest;

  /// Operator-facing failure retained through headless execution.
  static String get failureSignInAgainAndRetryTheTest =>
      _english.failureSignInAgainAndRetryTheTest;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDestinationHasNotFinishedTheUpload =>
      _english.failureTheDestinationHasNotFinishedTheUpload;

  /// Operator-facing failure retained through headless execution.
  static String get failureRetryTheUpload => _english.failureRetryTheUpload;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatFolderCannotBeWritten =>
      _english.failureThatFolderCannotBeWritten;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseTheFolderAgain =>
      _english.failureChooseTheFolderAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheFileCouldNotBeWrittenTo =>
      _english.failureTheFileCouldNotBeWrittenTo;

  /// Operator-facing failure retained through headless execution.
  static String get failureFreeSomeSpaceOrChooseTheFolder =>
      _english.failureFreeSomeSpaceOrChooseTheFolder;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisFolderRequiresASupportedSystemFolder =>
      _english.failureThisFolderRequiresASupportedSystemFolder;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAnAccessibleFolderOrAnotherDestination =>
      _english.failureChooseAnAccessibleFolderOrAnotherDestination;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatFolderPathIsNotUsable =>
      _english.failureThatFolderPathIsNotUsable;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheTaptureFolderOnThisDeviceIs =>
      _english.failureTheTaptureFolderOnThisDeviceIs;

  /// Operator-facing failure retained through headless execution.
  static String get failureCheckTheStorageLocationInSettings =>
      _english.failureCheckTheStorageLocationInSettings;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisGoogleDriveSignInIsNo =>
      _english.failureThisGoogleDriveSignInIsNo;

  /// Operator-facing failure retained through headless execution.
  static String get failureSignInToThisDestinationAgain =>
      _english.failureSignInToThisDestinationAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureGoogleDriveNeedsACurrentSignIn =>
      _english.failureGoogleDriveNeedsACurrentSignIn;

  /// Operator-facing failure retained through headless execution.
  static String get failureSignInAgainToAllowFileAccess =>
      _english.failureSignInAgainToAllowFileAccess;

  /// Operator-facing failure retained through headless execution.
  static String get failureNativeGoogleDriveSignInIsUnavailable =>
      _english.failureNativeGoogleDriveSignInIsUnavailable;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDestinationIsStillSavedSignIn =>
      _english.failureTheDestinationIsStillSavedSignIn;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheUploadChunkSizeIsNotUsable =>
      _english.failureTheUploadChunkSizeIsNotUsable;

  /// Operator-facing failure retained through headless execution.
  static String get failureUseTheStandardUploadSettings =>
      _english.failureUseTheStandardUploadSettings;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDestinationReturnedAnUnusableUploadResponse =>
      _english.failureTheDestinationReturnedAnUnusableUploadResponse;

  /// Operator-facing failure retained through headless execution.
  static String get failureTestTheDestinationThenTryTheUpload =>
      _english.failureTestTheDestinationThenTryTheUpload;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheBucketDidNotAcknowledgeTheUploaded =>
      _english.failureTheBucketDidNotAcknowledgeTheUploaded;

  /// Operator-facing failure retained through headless execution.
  static String get failureTestTheDestinationAndTryAgain =>
      _english.failureTestTheDestinationAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheBucketDidNotFinishTheUpload =>
      _english.failureTheBucketDidNotFinishTheUpload;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheBucketRefusedToFinishTheUpload =>
      _english.failureTheBucketRefusedToFinishTheUpload;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheBucketDidNotConfirmTheCompleted =>
      _english.failureTheBucketDidNotConfirmTheCompleted;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDestinationDidNotStartTheUpload =>
      _english.failureTheDestinationDidNotStartTheUpload;

  /// Operator-facing failure retained through headless execution.
  static String get failureTryTheConnectionAgain =>
      _english.failureTryTheConnectionAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisDestinationHasNoSavedSignIn =>
      _english.failureThisDestinationHasNoSavedSignIn;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterTheKeysAndTestTheConnection =>
      _english.failureEnterTheKeysAndTestTheConnection;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheSavedSignInIsNotUsable =>
      _english.failureTheSavedSignInIsNotUsable;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterTheKeysAgain =>
      _english.failureEnterTheKeysAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheBucketSettingsAreIncomplete =>
      _english.failureTheBucketSettingsAreIncomplete;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterTheKeyRegionAndBucket =>
      _english.failureEnterTheKeyRegionAndBucket;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAFilenameWithoutFolderSeparators =>
      _english.failureChooseAFilenameWithoutFolderSeparators;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheFolderCouldNotOpenANew =>
      _english.failureTheFolderCouldNotOpenANew;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheFolderCouldNotPublishTheFile =>
      _english.failureTheFolderCouldNotPublishTheFile;

  /// Operator-facing failure retained through headless execution.
  static String get failureAccessToTheChosenFolderWasLost =>
      _english.failureAccessToTheChosenFolderWasLost;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAnAccessibleFolderAndTryAgain =>
      _english.failureChooseAnAccessibleFolderAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheUploadFilenameIsNotUsable =>
      _english.failureTheUploadFilenameIsNotUsable;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterTheAddressAndSignInThen =>
      _english.failureEnterTheAddressAndSignInThen;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDestinationAddressOrSignInIs =>
      _english.failureTheDestinationAddressOrSignInIs;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterAFullHTTPSAddressAndSign =>
      _english.failureEnterAFullHTTPSAddressAndSign;

  /// Operator-facing failure retained through headless execution.
  static String get failureGoogleDriveSignInCouldNotFinish =>
      _english.failureGoogleDriveSignInCouldNotFinish;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisDestinationNeedsAFreshSignIn =>
      _english.failureThisDestinationNeedsAFreshSignIn;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheUploadCheckpointCouldNotBeSaved =>
      _english.failureTheUploadCheckpointCouldNotBeSaved;

  /// Operator-facing failure retained through headless execution.
  static String get failureCheckSecureStorageThenTryAgain =>
      _english.failureCheckSecureStorageThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatRowIsNoLongerOnThis =>
      _english.failureThatRowIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureRefreshTheListAndTryAgain =>
      _english.failureRefreshTheListAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureADeleteNeedsAReason =>
      _english.failureADeleteNeedsAReason;

  /// Operator-facing failure retained through headless execution.
  static String get failureSayWhyThisRowShouldBeRemoved =>
      _english.failureSayWhyThisRowShouldBeRemoved;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDatabaseCouldNotCompleteThatWrite =>
      _english.failureTheDatabaseCouldNotCompleteThatWrite;

  /// Operator-facing failure retained through headless execution.
  static String get failureFreeUpSpaceOrExportAProject =>
      _english.failureFreeUpSpaceOrExportAProject;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDatabaseIsEncryptedAndTheKey =>
      _english.failureTheDatabaseIsEncryptedAndTheKey;

  /// Operator-facing failure retained through headless execution.
  static String get failureRestoreTheKeyFromABackupThen =>
      _english.failureRestoreTheKeyFromABackupThen;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDatabaseKeyIsMissingOrUnreadable =>
      _english.failureTheDatabaseKeyIsMissingOrUnreadable;

  /// Operator-facing failure retained through headless execution.
  static String get failureTypeDISABLEENCRYPTIONToTurnEncryptionOff =>
      _english.failureTypeDISABLEENCRYPTIONToTurnEncryptionOff;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterTheConfirmationExactlyThenTryAgain =>
      _english.failureEnterTheConfirmationExactlyThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThereIsNoDatabaseToEncrypt =>
      _english.failureThereIsNoDatabaseToEncrypt;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenTheAppOnceSoADatabase =>
      _english.failureOpenTheAppOnceSoADatabase;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDatabaseCouldNotBeEncrypted =>
      _english.failureTheDatabaseCouldNotBeEncrypted;

  /// Operator-facing failure retained through headless execution.
  static String get failureFreeUpSpaceThenTryAgain =>
      _english.failureFreeUpSpaceThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheEncryptedCopyDidNotMatchThe =>
      _english.failureTheEncryptedCopyDidNotMatchThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureTryEncryptingAgainTheOriginalDatabaseWas =>
      _english.failureTryEncryptingAgainTheOriginalDatabaseWas;

  /// Operator-facing failure retained through headless execution.
  static String get failureKeepTheWorkingDatabaseFreeUpSpace =>
      _english.failureKeepTheWorkingDatabaseFreeUpSpace;

  /// Operator-facing failure retained through headless execution.
  static String get failureRestoreTheKeyFromABackupThe =>
      _english.failureRestoreTheKeyFromABackupThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisUpdateWouldDropOrRewriteA =>
      _english.failureThisUpdateWouldDropOrRewriteA;

  /// Operator-facing failure retained through headless execution.
  static String get failureExportYourProjectsThenConfirmTheUpdate =>
      _english.failureExportYourProjectsThenConfirmTheUpdate;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisDeviceCannotBuildTheRecordSearch =>
      _english.failureThisDeviceCannotBuildTheRecordSearch;

  /// Operator-facing failure retained through headless execution.
  static String get failureUpdateTheAppThenOpenItAgain =>
      _english.failureUpdateTheAppThenOpenItAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheFilePathMustStayInsideThe =>
      _english.failureTheFilePathMustStayInsideThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureSaveTheFileUnderTheProjectFolder =>
      _english.failureSaveTheFileUnderTheProjectFolder;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheOriginalCaptionCannotBeChanged =>
      _english.failureTheOriginalCaptionCannotBeChanged;

  /// Operator-facing failure retained through headless execution.
  static String get failureLeaveTheCapturedTextAndWriteA =>
      _english.failureLeaveTheCapturedTextAndWriteA;

  /// Operator-facing failure retained through headless execution.
  static String get failureADuplicatePairNeedsTwoRecords =>
      _english.failureADuplicatePairNeedsTwoRecords;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseBothRecordsAndTryAgain =>
      _english.failureChooseBothRecordsAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureARecordCannotBeADuplicateOf =>
      _english.failureARecordCannotBeADuplicateOf;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseTwoDifferentRecordsAndTryAgain =>
      _english.failureChooseTwoDifferentRecordsAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureADuplicatePairNeedsAProjectA =>
      _english.failureADuplicatePairNeedsAProjectA;

  /// Operator-facing failure retained through headless execution.
  static String get failureRunDetectionAgainThenTryAgain =>
      _english.failureRunDetectionAgainThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureAResolutionNeedsAChoiceAndAn =>
      _english.failureAResolutionNeedsAChoiceAndAn;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseHowToResolveThePairThen =>
      _english.failureChooseHowToResolveThePairThen;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatPairIsNoLongerOnThis =>
      _english.failureThatPairIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureACompletedExportCannotBeChanged =>
      _english.failureACompletedExportCannotBeChanged;

  /// Operator-facing failure retained through headless execution.
  static String get failureRunANewExportInsteadOfRewriting =>
      _english.failureRunANewExportInsteadOfRewriting;

  /// Operator-facing failure retained through headless execution.
  static String get failureAnExportIsRecordedOnlyWhenThe =>
      _english.failureAnExportIsRecordedOnlyWhenThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureFinishWritingTheFileThenRecordThe =>
      _english.failureFinishWritingTheFileThenRecordThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheExportFormatsAreNotInA =>
      _english.failureTheExportFormatsAreNotInA;

  /// Operator-facing failure retained through headless execution.
  static String get failureFixTheFormatsListAndSaveAgain =>
      _english.failureFixTheFormatsListAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheExportFiltersAreNotInA =>
      _english.failureTheExportFiltersAreNotInA;

  /// Operator-facing failure retained through headless execution.
  static String get failureStoreTheQueryNotTheExportedValues =>
      _english.failureStoreTheQueryNotTheExportedValues;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatEntryCouldNotBeRead =>
      _english.failureThatEntryCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  static String get failureChangeItThenSaveAgain =>
      _english.failureChangeItThenSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheMarkedAreaOnThePhotoCould =>
      _english.failureTheMarkedAreaOnThePhotoCould;

  /// Operator-facing failure retained through headless execution.
  static String get failureFixTheRegionObjectAndSaveAgain =>
      _english.failureFixTheRegionObjectAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheMarkedAreaOnThePhotoIs =>
      _english.failureTheMarkedAreaOnThePhotoIs;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatMeetingIsNoLongerOnThis =>
      _english.failureThatMeetingIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheOriginalTranscriptCannotBeChanged =>
      _english.failureTheOriginalTranscriptCannotBeChanged;

  /// Operator-facing failure retained through headless execution.
  static String get failureLeaveTheCapturedTextAndWriteRefined =>
      _english.failureLeaveTheCapturedTextAndWriteRefined;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheMeetingAgendaCouldNotBeRead =>
      _english.failureTheMeetingAgendaCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  static String get failureFixTheAgendaListAndSaveAgain =>
      _english.failureFixTheAgendaListAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheMeetingAgendaIsNotInA =>
      _english.failureTheMeetingAgendaIsNotInA;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheMergeSummaryCouldNotBeRead =>
      _english.failureTheMergeSummaryCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  static String get failureFixTheCountsObjectAndSaveAgain =>
      _english.failureFixTheCountsObjectAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheMergeSummaryIsNotInA =>
      _english.failureTheMergeSummaryIsNotInA;

  /// Operator-facing failure retained through headless execution.
  static String get failureAConflictNeedsAChoiceAndAn =>
      _english.failureAConflictNeedsAChoiceAndAn;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseASideThenResolveAgain =>
      _english.failureChooseASideThenResolveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatConflictIsNoLongerOnThis =>
      _english.failureThatConflictIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatJobIsNoLongerOnThis =>
      _english.failureThatJobIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureRefreshTheQueueAndTryAgain =>
      _english.failureRefreshTheQueueAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureAStoredProviderResponseCannotBeChanged =>
      _english.failureAStoredProviderResponseCannotBeChanged;

  /// Operator-facing failure retained through headless execution.
  static String get failureLeaveTheOriginalResultAndWriteA =>
      _english.failureLeaveTheOriginalResultAndWriteA;

  /// Operator-facing failure retained through headless execution.
  static String get failureARequestSummaryCannotIncludeASecret =>
      _english.failureARequestSummaryCannotIncludeASecret;

  /// Operator-facing failure retained through headless execution.
  static String get failureStoreShapeAndSizeOnlyThenSave =>
      _english.failureStoreShapeAndSizeOnlyThenSave;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheProjectSettingsCouldNotBeRead =>
      _english.failureTheProjectSettingsCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  static String get failureChangeTheSettingsAgainThenSave =>
      _english.failureChangeTheSettingsAgainThenSave;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheProjectSettingsAreNotInA =>
      _english.failureTheProjectSettingsAreNotInA;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatRecordIsNoLongerOnThis =>
      _english.failureThatRecordIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheRecordSContextCouldNotBe =>
      _english.failureTheRecordSContextCouldNotBe;

  /// Operator-facing failure retained through headless execution.
  static String get failureFixTheContextObjectAndSaveAgain =>
      _english.failureFixTheContextObjectAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheRecordSContextIsNotIn =>
      _english.failureTheRecordSContextIsNotIn;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueIsNoLongerOnThis =>
      _english.failureThatValueIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureRefreshTheRecordAndTryAgain =>
      _english.failureRefreshTheRecordAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheOriginalValueCannotBeChanged =>
      _english.failureTheOriginalValueCannotBeChanged;

  /// Operator-facing failure retained through headless execution.
  static String get failureLeaveTheCapturedValueAndWriteA =>
      _english.failureLeaveTheCapturedValueAndWriteA;

  /// Operator-facing failure retained through headless execution.
  static String get failureADatasetImportNeedsASourceFile =>
      _english.failureADatasetImportNeedsASourceFile;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseTheFileAndWhereItBelongs =>
      _english.failureChooseTheFileAndWhereItBelongs;

  /// Operator-facing failure retained through headless execution.
  static String get failureAProjectDatasetNeedsAProject =>
      _english.failureAProjectDatasetNeedsAProject;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseTheProjectThenImportAgain =>
      _english.failureChooseTheProjectThenImportAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureAGlobalDatasetCannotBelongToOne =>
      _english.failureAGlobalDatasetCannotBelongToOne;

  /// Operator-facing failure retained through headless execution.
  static String get failureClearTheProjectThenImportAgain =>
      _english.failureClearTheProjectThenImportAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDatasetColumnsAreNotInA =>
      _english.failureTheDatasetColumnsAreNotInA;

  /// Operator-facing failure retained through headless execution.
  static String get failureFixTheColumnListAndSaveAgain =>
      _english.failureFixTheColumnListAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureAReferenceRowIsNotInA =>
      _english.failureAReferenceRowIsNotInA;

  /// Operator-facing failure retained through headless execution.
  static String get failureFixTheRowValuesAndSaveAgain =>
      _english.failureFixTheRowValuesAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatEntryIsNotInAForm =>
      _english.failureThatEntryIsNotInAForm;

  /// Operator-facing failure retained through headless execution.
  static String get failureAResolutionNeedsAnOperator =>
      _english.failureAResolutionNeedsAnOperator;

  /// Operator-facing failure retained through headless execution.
  static String get failureSignInThenResolveTheVarianceAgain =>
      _english.failureSignInThenResolveTheVarianceAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatVarianceIsNoLongerOnThis =>
      _english.failureThatVarianceIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDatabaseIsBusy =>
      _english.failureTheDatabaseIsBusy;

  /// Operator-facing failure retained through headless execution.
  static String get failureWaitAMomentThenTryTheSave =>
      _english.failureWaitAMomentThenTryTheSave;

  /// Operator-facing failure retained through headless execution.
  static String get failureARecordWithThatIdentityAlreadyExists =>
      _english.failureARecordWithThatIdentityAlreadyExists;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenTheExistingRecordOrChangeThe =>
      _english.failureOpenTheExistingRecordOrChangeThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatPhotoCouldNotBeBlurred =>
      _english.failureThatPhotoCouldNotBeBlurred;

  /// Operator-facing failure retained through headless execution.
  static String get failureADetectedFaceIsOutsideThatPhoto =>
      _english.failureADetectedFaceIsOutsideThatPhoto;

  /// Operator-facing failure retained through headless execution.
  static String get failureFaceDetectionIsUnavailableOnThisDevice =>
      _english.failureFaceDetectionIsUnavailableOnThisDevice;

  /// Operator-facing failure retained through headless execution.
  static String get failureUseAnAndroidOrIOSDeviceTo =>
      _english.failureUseAnAndroidOrIOSDeviceTo;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisPhotoCannotBeCheckedForFaces =>
      _english.failureThisPhotoCannotBeCheckedForFaces;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisPhotoCannotBeProtected =>
      _english.failureThisPhotoCannotBeProtected;

  /// Operator-facing failure retained through headless execution.
  static String get failureAHiddenAreaIsInvalid =>
      _english.failureAHiddenAreaIsInvalid;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisExportFolderAlreadyContainsCompletedFiles =>
      _english.failureThisExportFolderAlreadyContainsCompletedFiles;

  /// Operator-facing failure retained through headless execution.
  static String get failureCreateTheExportInANewVersion =>
      _english.failureCreateTheExportInANewVersion;

  /// Operator-facing failure retained through headless execution.
  static String get failureStreamingTextExportNeedsNativeStorage =>
      _english.failureStreamingTextExportNeedsNativeStorage;

  /// Operator-facing failure retained through headless execution.
  static String get failureTaptureCannotCopyAFileFromThis =>
      _english.failureTaptureCannotCopyAFileFromThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureAddTheFileAgainFromTaptureThen =>
      _english.failureAddTheFileAgainFromTaptureThen;

  /// Operator-facing failure retained through headless execution.
  static String failureTaptureCouldNotWriteToValue(String value0) =>
      _english.failureTaptureCouldNotWriteToValue(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureTaptureCouldNotNameThatStoredFile =>
      _english.failureTaptureCouldNotNameThatStoredFile;

  /// Operator-facing failure retained through headless execution.
  static String get failureTryAgainIfItKeepsHappeningExport =>
      _english.failureTryAgainIfItKeepsHappeningExport;

  /// Operator-facing failure retained through headless execution.
  static String get failureTaptureCouldNotSaveThatOnThis =>
      _english.failureTaptureCouldNotSaveThatOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureFreeSomeSpaceThenTryAgain =>
      _english.failureFreeSomeSpaceThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheCacheCouldNotBeCleanedOn =>
      _english.failureTheCacheCouldNotBeCleanedOn;

  /// Operator-facing failure retained through headless execution.
  static String get failureFreeSpaceOrAllowStorageAccessThen =>
      _english.failureFreeSpaceOrAllowStorageAccessThen;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatImageSizeIsNotValid =>
      _english.failureThatImageSizeIsNotValid;

  /// Operator-facing failure retained through headless execution.
  static String get failureUseTheAppUploadSizeAndTry =>
      _english.failureUseTheAppUploadSizeAndTry;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheReducedCopyCouldNotBeCreated =>
      _english.failureTheReducedCopyCouldNotBeCreated;

  /// Operator-facing failure retained through headless execution.
  static String failureTaptureCouldNotFindValue(String value0) =>
      _english.failureTaptureCouldNotFindValue(value0);

  /// Operator-facing failure retained through headless execution.
  static String failureTaptureCouldNotSaveValue(String value0) =>
      _english.failureTaptureCouldNotSaveValue(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureFreeSomeSpaceThenDownloadAgain =>
      _english.failureFreeSomeSpaceThenDownloadAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenDownloadsOnThisDeviceAndLook =>
      _english.failureOpenDownloadsOnThisDeviceAndLook;

  /// Operator-facing failure retained through headless execution.
  static String get failureOnlyFilesInsideAProjectFolderCan =>
      _english.failureOnlyFilesInsideAProjectFolderCan;

  /// Operator-facing failure retained through headless execution.
  static String get failureLeaveTheFileInPlaceThePurge =>
      _english.failureLeaveTheFileInPlaceThePurge;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatPhotoHasNoUsableNameFor =>
      _english.failureThatPhotoHasNoUsableNameFor;

  /// Operator-facing failure retained through headless execution.
  static String get failureLeaveThePhotoInPlaceThePurge =>
      _english.failureLeaveThePhotoInPlaceThePurge;

  /// Operator-facing failure retained through headless execution.
  static String get failureADeletedRecordSFilesCouldNot =>
      _english.failureADeletedRecordSFilesCouldNot;

  /// Operator-facing failure retained through headless execution.
  static String get failureAllowStorageAccessThePurgeTriesAgain =>
      _english.failureAllowStorageAccessThePurgeTriesAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisExportIsTooLargeForThis =>
      _english.failureThisExportIsTooLargeForThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureExportFewerRecordsOrUseADesktop =>
      _english.failureExportFewerRecordsOrUseADesktop;

  /// Operator-facing failure retained through headless execution.
  static String failureAnExportSourceIsMissingValue(String value0) =>
      _english.failureAnExportSourceIsMissingValue(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureANativeFileSystemIsUnavailable =>
      _english.failureANativeFileSystemIsUnavailable;

  /// Operator-facing failure retained through headless execution.
  static String failureTaptureCouldNotReadValue(String value0) =>
      _english.failureTaptureCouldNotReadValue(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureCaptureOrAddTheFileAgainThen =>
      _english.failureCaptureOrAddTheFileAgainThen;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatProjectIsNoLongerOnThis =>
      _english.failureThatProjectIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenAProjectThenTryAgain =>
      _english.failureOpenAProjectThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureRecreateTheProjectFolderThenTryAgain =>
      _english.failureRecreateTheProjectFolderThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String failureTheFileValueIsEmpty(String value0) =>
      _english.failureTheFileValueIsEmpty(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAFileThatHasContentsAnd =>
      _english.failureChooseAFileThatHasContentsAnd;

  /// Operator-facing failure retained through headless execution.
  static String failureTheFileValueIsNotASupported(String value0) =>
      _english.failureTheFileValueIsNotASupported(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAnImageDocumentSpreadsheetAudioFile =>
      _english.failureChooseAnImageDocumentSpreadsheetAudioFile;

  /// Operator-facing failure retained through headless execution.
  static String failureTheFileValueDoesNotMatchIts(String value0) =>
      _english.failureTheFileValueDoesNotMatchIts(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAFileOfTheExpectedType =>
      _english.failureChooseAFileOfTheExpectedType;

  /// Operator-facing failure retained through headless execution.
  static String failureTheFileValueIsLargerThanThe(
    String value0,
    String value1,
  ) => _english.failureTheFileValueIsLargerThanThe(value0, value1);

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseASmallerFileAndTryAgain =>
      _english.failureChooseASmallerFileAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String failureTheArchiveValueContainsAPathThat(String value0) =>
      _english.failureTheArchiveValueContainsAPathThat(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseADifferentFileAndTryAgain =>
      _english.failureChooseADifferentFileAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String failureTheArchiveValueContainsALinkInstead(String value0) =>
      _english.failureTheArchiveValueContainsALinkInstead(value0);

  /// Operator-facing failure retained through headless execution.
  static String failureTheArchiveValueDeclaresMoreUncompressedData(
    String value0,
  ) => _english.failureTheArchiveValueDeclaresMoreUncompressedData(value0);

  /// Operator-facing failure retained through headless execution.
  static String failureTheFileValueIsNotAnArchive(String value0) =>
      _english.failureTheFileValueIsNotAnArchive(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAZIPBundleOrSpreadsheetAnd =>
      _english.failureChooseAZIPBundleOrSpreadsheetAnd;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseTheFileAgainThenTryAgain =>
      _english.failureChooseTheFileAgainThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThePhotoCouldNotBeSavedOn =>
      _english.failureThePhotoCouldNotBeSavedOn;

  /// Operator-facing failure retained through headless execution.
  static String failureThereIsNotEnoughSpaceToSave(String value0) =>
      _english.failureThereIsNotEnoughSpaceToSave(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureAllowStorageAccessThenTryAgain =>
      _english.failureAllowStorageAccessThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisPhotoCannotBeMarked =>
      _english.failureThisPhotoCannotBeMarked;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisPackageIsTooLargeOrIncomplete =>
      _english.failureThisPackageIsTooLargeOrIncomplete;

  /// Operator-facing failure retained through headless execution.
  static String get failureFinishTheCurrentPackageBeforeOpeningAnother =>
      _english.failureFinishTheCurrentPackageBeforeOpeningAnother;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisPackageIsTooLargeToOpen =>
      _english.failureThisPackageIsTooLargeToOpen;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisPackageCouldNotBeOpened =>
      _english.failureThisPackageCouldNotBeOpened;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenTheFileAgainFromItsOriginal =>
      _english.failureOpenTheFileAgainFromItsOriginal;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatProjectCouldNotBeScanned =>
      _english.failureThatProjectCouldNotBeScanned;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenTheProjectAndTryAgain =>
      _english.failureOpenTheProjectAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheProjectFolderCouldNotBeScanned =>
      _english.failureTheProjectFolderCouldNotBeScanned;

  /// Operator-facing failure retained through headless execution.
  static String get failurePutTheFileBackInTheProject =>
      _english.failurePutTheFileBackInTheProject;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheFileCouldNotBeAdoptedOn =>
      _english.failureTheFileCouldNotBeAdoptedOn;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheMissingFileCouldNotBeFlagged =>
      _english.failureTheMissingFileCouldNotBeFlagged;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatFileRowIsNoLongerOn =>
      _english.failureThatFileRowIsNoLongerOn;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatNameIsNotAValidFolder =>
      _english.failureThatNameIsNotAValidFolder;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseANameWithoutSlashesThatPoint =>
      _english.failureChooseANameWithoutSlashesThatPoint;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseANameWithLettersOrDigits =>
      _english.failureChooseANameWithLettersOrDigits;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheFilePathMustStayInsideThe2 =>
      _english.failureTheFilePathMustStayInsideThe2;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatPhotoIsNoLongerAvailable =>
      _english.failureThatPhotoIsNoLongerAvailable;

  /// Operator-facing failure retained through headless execution.
  static String get failureHiddenAreasChangedTrySendingAgain =>
      _english.failureHiddenAreasChangedTrySendingAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureCheckTheHiddenAreasOnThisEdited =>
      _english.failureCheckTheHiddenAreasOnThisEdited;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenHidePartsBeforeSendingAndSave =>
      _english.failureOpenHidePartsBeforeSendingAndSave;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheProjectFolderCouldNotBeRemoved =>
      _english.failureTheProjectFolderCouldNotBeRemoved;

  /// Operator-facing failure retained through headless execution.
  static String get failureDeleteTheLeftoverFolderThenTryAgain =>
      _english.failureDeleteTheLeftoverFolderThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatProjectIsAlreadyInTheRecycle =>
      _english.failureThatProjectIsAlreadyInTheRecycle;

  /// Operator-facing failure retained through headless execution.
  static String get failureRestoreItFromTheRecycleAreaThen =>
      _english.failureRestoreItFromTheRecycleAreaThen;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheProjectFolderCouldNotBeMoved =>
      _english.failureTheProjectFolderCouldNotBeMoved;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisProjectHasNoFolderOnDisk =>
      _english.failureThisProjectHasNoFolderOnDisk;

  /// Operator-facing failure retained through headless execution.
  static String get failureCreateTheProjectFolderThenTryAgain =>
      _english.failureCreateTheProjectFolderThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheProjectFolderCouldNotBeCreated =>
      _english.failureTheProjectFolderCouldNotBeCreated;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatProjectFolderNameIsNotA =>
      _english.failureThatProjectFolderNameIsNotA;

  /// Operator-facing failure retained through headless execution.
  static String get failureRecreateTheProjectSoItsFolderCan =>
      _english.failureRecreateTheProjectSoItsFolderCan;

  /// Operator-facing failure retained through headless execution.
  static String get failureThereIsNotEnoughFreeSpaceTo =>
      _english.failureThereIsNotEnoughFreeSpaceTo;

  /// Operator-facing failure retained through headless execution.
  static String get failureExportAProjectOrCleanTheCache =>
      _english.failureExportAProjectOrCleanTheCache;

  /// Operator-facing failure retained through headless execution.
  static String get failureTaptureCouldNotReadFreeSpaceOn =>
      _english.failureTaptureCouldNotReadFreeSpaceOn;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisDeviceHasNoFolderTaptureCan =>
      _english.failureThisDeviceHasNoFolderTaptureCan;

  /// Operator-facing failure retained through headless execution.
  static String get failureUseTaptureOnAPhoneTabletOr =>
      _english.failureUseTaptureOnAPhoneTabletOr;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheThumbnailCouldNotBeCreatedOn =>
      _english.failureTheThumbnailCouldNotBeCreatedOn;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatThumbnailSizeIsNotValid =>
      _english.failureThatThumbnailSizeIsNotValid;

  /// Operator-facing failure retained through headless execution.
  static String get failureUseTheAppThumbnailSizeAndTry =>
      _english.failureUseTheAppThumbnailSizeAndTry;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatPhotoCouldNotBeCached =>
      _english.failureThatPhotoCouldNotBeCached;

  /// Operator-facing failure retained through headless execution.
  static String get failureLocationIsOffForThisProject =>
      _english.failureLocationIsOffForThisProject;

  /// Operator-facing failure retained through headless execution.
  static String get failureTurnGPSOnThenTryAgain =>
      _english.failureTurnGPSOnThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureBiometricAuthenticationIsUnavailable =>
      _english.failureBiometricAuthenticationIsUnavailable;

  /// Operator-facing failure retained through headless execution.
  static String get failureUnlockWithYourAppPIN =>
      _english.failureUnlockWithYourAppPIN;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheSecretCouldNotBeSavedOn =>
      _english.failureTheSecretCouldNotBeSavedOn;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheSecretCouldNotBeReadOn =>
      _english.failureTheSecretCouldNotBeReadOn;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheSecretCouldNotBeRemovedFrom =>
      _english.failureTheSecretCouldNotBeRemovedFrom;

  /// Operator-facing failure retained through headless execution.
  static String get failureTypeTheWordsToPlaceOnThis =>
      _english.failureTypeTheWordsToPlaceOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterTextThenSaveThePhoto =>
      _english.failureEnterTextThenSaveThePhoto;

  /// Operator-facing failure retained through headless execution.
  static String get failureDiscardTheInterruptedSessionAndStartAgain =>
      _english.failureDiscardTheInterruptedSessionAndStartAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureOnlyARecordEditCanBeSaved =>
      _english.failureOnlyARecordEditCanBeSaved;

  /// Operator-facing failure retained through headless execution.
  static String get failureGoBackToTheProjectAndPick =>
      _english.failureGoBackToTheProjectAndPick;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheCaptureSessionIsNotValid =>
      _english.failureTheCaptureSessionIsNotValid;

  /// Operator-facing failure retained through headless execution.
  static String get failureCompletePhotoMetadataIsRequiredForA =>
      _english.failureCompletePhotoMetadataIsRequiredForA;

  /// Operator-facing failure retained through headless execution.
  static String get failureThePhotoProjectWasNotFound =>
      _english.failureThePhotoProjectWasNotFound;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatPhotoCouldNotBeReadFrom =>
      _english.failureThatPhotoCouldNotBeReadFrom;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheOriginalPhotoStaysInPlace =>
      _english.failureTheOriginalPhotoStaysInPlace;

  /// Operator-facing failure retained through headless execution.
  static String get failureRevertAnEditedPhotoInstead =>
      _english.failureRevertAnEditedPhotoInstead;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisPhotoAppearsMoreThanOnce =>
      _english.failureThisPhotoAppearsMoreThanOnce;

  /// Operator-facing failure retained through headless execution.
  static String get failureReloadTheCaptureAndTryAgain =>
      _english.failureReloadTheCaptureAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureAnEditedPhotoIsMissingItsOriginal =>
      _english.failureAnEditedPhotoIsMissingItsOriginal;

  /// Operator-facing failure retained through headless execution.
  static String get failureKeepThisCaptureAndRestoreTheOriginal =>
      _english.failureKeepThisCaptureAndRestoreTheOriginal;

  /// Operator-facing failure retained through headless execution.
  static String get failureThesePhotoEditsLoopBackOnThemselves =>
      _english.failureThesePhotoEditsLoopBackOnThemselves;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatFieldIsNotOnThisRecord =>
      _english.failureThatFieldIsNotOnThisRecord;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenTheRecordAndTryAgain =>
      _english.failureOpenTheRecordAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatFieldIsNotAContextLevel =>
      _english.failureThatFieldIsNotAContextLevel;

  /// Operator-facing failure retained through headless execution.
  static String get failurePickALevelFromTheHierarchyAnd =>
      _english.failurePickALevelFromTheHierarchyAnd;

  /// Operator-facing failure retained through headless execution.
  static String get failureAPresetNeedsAName =>
      _english.failureAPresetNeedsAName;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterANameAndTryAgain =>
      _english.failureEnterANameAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureADeleteNeedsAnIdAndA =>
      _english.failureADeleteNeedsAnIdAndA;

  /// Operator-facing failure retained through headless execution.
  static String get failureContextIsNotAvailableYet =>
      _english.failureContextIsNotAvailableYet;

  /// Operator-facing failure retained through headless execution.
  static String get failureRestartTheAppAndTryAgain =>
      _english.failureRestartTheAppAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureAPresetWithThatNameAlreadyExists =>
      _english.failureAPresetWithThatNameAlreadyExists;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAnotherNameOrConfirmOverwrite =>
      _english.failureChooseAnotherNameOrConfirmOverwrite;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheProjectWasNotFound =>
      _english.failureTheProjectWasNotFound;

  /// Operator-facing failure retained through headless execution.
  static String get failureAnExportedRecordIsNoLongerAvailable =>
      _english.failureAnExportedRecordIsNoLongerAvailable;

  /// Operator-facing failure retained through headless execution.
  static String get failureAnExportedPhotoIsNoLongerAvailable =>
      _english.failureAnExportedPhotoIsNoLongerAvailable;

  /// Operator-facing failure retained through headless execution.
  static String get failureASelectedRecordIsMissingRefreshThe =>
      _english.failureASelectedRecordIsMissingRefreshThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureAnExportNeedsAProject =>
      _english.failureAnExportNeedsAProject;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenAProjectAndExportAgain =>
      _english.failureOpenAProjectAndExportAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisExportedPhotoCannotBeRead =>
      _english.failureThisExportedPhotoCannotBeRead;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisPhotoFormatCannotBePackagedSafely =>
      _english.failureThisPhotoFormatCannotBePackagedSafely;

  /// Operator-facing failure retained through headless execution.
  static String get failureProjectFilesAreUnavailableOnThisDevice =>
      _english.failureProjectFilesAreUnavailableOnThisDevice;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenAProjectStoredOnThisDevice =>
      _english.failureOpenAProjectStoredOnThisDevice;

  /// Operator-facing failure retained through headless execution.
  static String get failureWriteYourFeedbackThenSaveAgain =>
      _english.failureWriteYourFeedbackThenSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureNameTheTypeThenSaveAgain =>
      _english.failureNameTheTypeThenSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureChangeOrClearTheFiltersThenTry =>
      _english.failureChangeOrClearTheFiltersThenTry;

  /// Operator-facing failure retained through headless execution.
  static String get failureCloseThisTapFeedbackThenTryAgain =>
      _english.failureCloseThisTapFeedbackThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureCorrectTheHighlightedFieldAndSaveAgain =>
      _english.failureCorrectTheHighlightedFieldAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheTemplateTheseRowsWereMatchedTo =>
      _english.failureTheTemplateTheseRowsWereMatchedTo;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAnotherTemplateAndImportAgain =>
      _english.failureChooseAnotherTemplateAndImportAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureARecordARowMatchedIsNo =>
      _english.failureARecordARowMatchedIsNo;

  /// Operator-facing failure retained through headless execution.
  static String get failureImportTheFileAgainToMatchIt =>
      _english.failureImportTheFileAgainToMatchIt;

  /// Operator-facing failure retained through headless execution.
  static String get failureRecordsCannotBeImportedRightNow =>
      _english.failureRecordsCannotBeImportedRightNow;

  /// Operator-facing failure retained through headless execution.
  static String get failureRestartTaptureThenImportAgain =>
      _english.failureRestartTaptureThenImportAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatFileIsNotInThisMeeting =>
      _english.failureThatFileIsNotInThisMeeting;

  /// Operator-facing failure retained through headless execution.
  static String get failureAddTheFileToTheMeetingAgain =>
      _english.failureAddTheFileToTheMeetingAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureStartTheMeetingAgain =>
      _english.failureStartTheMeetingAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheSnapshotHasBeenPurged =>
      _english.failureTheSnapshotHasBeenPurged;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheMergeCanNoLongerBeUndone =>
      _english.failureTheMergeCanNoLongerBeUndone;

  /// Operator-facing failure retained through headless execution.
  static String get failureTaptureCouldNotLookUpAFile =>
      _english.failureTaptureCouldNotLookUpAFile;

  /// Operator-facing failure retained through headless execution.
  static String get failureAProjectWithThatIdAlreadyExists =>
      _english.failureAProjectWithThatIdAlreadyExists;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenTheExistingProjectOrUseA =>
      _english.failureOpenTheExistingProjectOrUseA;

  /// Operator-facing failure retained through headless execution.
  static String get failureProjectPhotosCannotBeStoredOnThis =>
      _english.failureProjectPhotosCannotBeStoredOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureAddThePhotoOnADeviceThat =>
      _english.failureAddThePhotoOnADeviceThat;

  /// Operator-facing failure retained through headless execution.
  static String get failureAProjectNeedsAName =>
      _english.failureAProjectNeedsAName;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterANameAndSaveAgain =>
      _english.failureEnterANameAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureProjectFilesAreNotAvailableOnThis =>
      _english.failureProjectFilesAreNotAvailableOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureExportFromADeviceThatStoresThis =>
      _english.failureExportFromADeviceThatStoresThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatRecordIsNoLongerInThe =>
      _english.failureThatRecordIsNoLongerInThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureNothingToRemoveItWasRestoredOr =>
      _english.failureNothingToRemoveItWasRestoredOr;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatRecordWasDeletedAgainSoIts =>
      _english.failureThatRecordWasDeletedAgainSoIts;

  /// Operator-facing failure retained through headless execution.
  static String get failureLeaveItThePurgeTakesItOnce =>
      _english.failureLeaveItThePurgeTakesItOnce;

  /// Operator-facing failure retained through headless execution.
  static String get failureAMergeStillNeedsThatDeletedRecord =>
      _english.failureAMergeStillNeedsThatDeletedRecord;

  /// Operator-facing failure retained through headless execution.
  static String get failureSendABundleOrSettleTheMerge =>
      _english.failureSendABundleOrSettleTheMerge;

  /// Operator-facing failure retained through headless execution.
  static String get failureRecordsAreNotAvailableYet =>
      _english.failureRecordsAreNotAvailableYet;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheRecordWasSavedButCouldNot =>
      _english.failureTheRecordWasSavedButCouldNot;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenItFromTheRecordsList =>
      _english.failureOpenItFromTheRecordsList;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatTemplateIsNoLongerOnThis =>
      _english.failureThatTemplateIsNoLongerOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAnotherTemplateAndTryAgain =>
      _english.failureChooseAnotherTemplateAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisRecordAlreadyUsesThatTemplate =>
      _english.failureThisRecordAlreadyUsesThatTemplate;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseADifferentTemplate =>
      _english.failureChooseADifferentTemplate;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatTemplateBelongsToAnotherProject =>
      _english.failureThatTemplateBelongsToAnotherProject;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseATemplateFromThisProject =>
      _english.failureChooseATemplateFromThisProject;

  /// Operator-facing failure retained through headless execution.
  static String get failureARecordNeedsAProjectAndA =>
      _english.failureARecordNeedsAProjectAndA;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAProjectAndATemplateThen =>
      _english.failureChooseAProjectAndATemplateThen;

  /// Operator-facing failure retained through headless execution.
  static String get failureSayWhyTheRecordShouldGoThen =>
      _english.failureSayWhyTheRecordShouldGoThen;

  /// Operator-facing failure retained through headless execution.
  static String get failureAnEditNeedsTheFieldItChanges =>
      _english.failureAnEditNeedsTheFieldItChanges;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAFieldThenSaveAgain =>
      _english.failureChooseAFieldThenSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureARecordGoesToTheRecycleBin =>
      _english.failureARecordGoesToTheRecycleBin;

  /// Operator-facing failure retained through headless execution.
  static String get failureUseDeleteWhichLetsYouUndoIt =>
      _english.failureUseDeleteWhichLetsYouUndoIt;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisRecordIsInTheRecycleBin =>
      _english.failureThisRecordIsInTheRecycleBin;

  /// Operator-facing failure retained through headless execution.
  static String get failureRestoreItFromTheRecycleBinFirst =>
      _english.failureRestoreItFromTheRecycleBinFirst;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisRecordIsNotInTheRecycle =>
      _english.failureThisRecordIsNotInTheRecycle;

  /// Operator-facing failure retained through headless execution.
  static String get failureRefreshTheListItMayAlreadyBe =>
      _english.failureRefreshTheListItMayAlreadyBe;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisRecordHasAStatusThisVersion =>
      _english.failureThisRecordHasAStatusThisVersion;

  /// Operator-facing failure retained through headless execution.
  static String get failureUpdateTheAppThenTryAgain =>
      _english.failureUpdateTheAppThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String failureThisRecordIsAlreadyValue(String value0) =>
      _english.failureThisRecordIsAlreadyValue(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseADifferentStatusOrLeaveIt =>
      _english.failureChooseADifferentStatusOrLeaveIt;

  /// Operator-facing failure retained through headless execution.
  static String failureARecordThatIsValueCannotBe(
    String value0,
    String value1,
  ) => _english.failureARecordThatIsValueCannotBe(value0, value1);

  /// Operator-facing failure retained through headless execution.
  static String get failureRestoreItFromTheRecycleBinBefore =>
      _english.failureRestoreItFromTheRecycleBinBefore;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheCapturedTemplateVersionIsUnavailable =>
      _english.failureTheCapturedTemplateVersionIsUnavailable;

  /// Operator-facing failure retained through headless execution.
  static String get failureRestoreTheOriginalProjectPackageBeforeEditing =>
      _english.failureRestoreTheOriginalProjectPackageBeforeEditing;

  /// Operator-facing failure retained through headless execution.
  static String get failureAQuotedCSVValueIsUnfinished =>
      _english.failureAQuotedCSVValueIsUnfinished;

  /// Operator-facing failure retained through headless execution.
  static String get failureCloseTheQuotedValueAndImportThe =>
      _english.failureCloseTheQuotedValueAndImportThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatFileIsEmpty => _english.failureThatFileIsEmpty;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseACSVWithAHeaderAnd =>
      _english.failureChooseACSVWithAHeaderAnd;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatTableCouldNotBeReadAs =>
      _english.failureThatTableCouldNotBeReadAs;

  /// Operator-facing failure retained through headless execution.
  static String get failureSaveItAsUTFCSVAndTry =>
      _english.failureSaveItAsUTFCSVAndTry;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatCSVCouldNotBeRead =>
      _english.failureThatCSVCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  static String get failureCheckTheFileAndTryAgain =>
      _english.failureCheckTheFileAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseACSVJSONOrXLSXTable =>
      _english.failureChooseACSVJSONOrXLSXTable;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAnotherFileOrSplitThisTable =>
      _english.failureChooseAnotherFileOrSplitThisTable;

  /// Operator-facing failure retained through headless execution.
  static String get failureSaveItAsUTFCSVOrA =>
      _english.failureSaveItAsUTFCSVOrA;

  /// Operator-facing failure retained through headless execution.
  static String get failureJSONDatasetsMustBeAnArrayOf =>
      _english.failureJSONDatasetsMustBeAnArrayOf;

  /// Operator-facing failure retained through headless execution.
  static String get failureWrapTheRowsInAnArrayAnd =>
      _english.failureWrapTheRowsInAnArrayAnd;

  /// Operator-facing failure retained through headless execution.
  static String get failureEveryJSONRowMustBeAnObject =>
      _english.failureEveryJSONRowMustBeAnObject;

  /// Operator-facing failure retained through headless execution.
  static String get failureRemoveNonObjectRowsAndImportThe =>
      _english.failureRemoveNonObjectRowsAndImportThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatFileHasNoColumns =>
      _english.failureThatFileHasNoColumns;

  /// Operator-facing failure retained through headless execution.
  static String get failureAddKeysToTheObjectsAndTry =>
      _english.failureAddKeysToTheObjectsAndTry;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatJSONIsNotValid =>
      _english.failureThatJSONIsNotValid;

  /// Operator-facing failure retained through headless execution.
  static String get failureFixTheJSONArrayAndImportIt =>
      _english.failureFixTheJSONArrayAndImportIt;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatJSONCouldNotBeRead =>
      _english.failureThatJSONCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatWorkbookHasNoSheets =>
      _english.failureThatWorkbookHasNoSheets;

  /// Operator-facing failure retained through headless execution.
  static String get failureChooseAWorkbookWithASheetOf =>
      _english.failureChooseAWorkbookWithASheetOf;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatSheetHasNoHeaderRow =>
      _english.failureThatSheetHasNoHeaderRow;

  /// Operator-facing failure retained through headless execution.
  static String get failureAddAHeaderRowAndTryAgain =>
      _english.failureAddAHeaderRowAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatKeyColumnHasDuplicateValues =>
      _english.failureThatKeyColumnHasDuplicateValues;

  /// Operator-facing failure retained through headless execution.
  static String get failurePickAnotherKeyColumnOrConfirmDuplicates =>
      _english.failurePickAnotherKeyColumnOrConfirmDuplicates;

  /// Operator-facing failure retained through headless execution.
  static String get failureARowNeedsADatasetAndA =>
      _english.failureARowNeedsADatasetAndA;

  /// Operator-facing failure retained through headless execution.
  static String get failureFillThoseFieldsAndSaveAgain =>
      _english.failureFillThoseFieldsAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureADatasetNeedsANameAndA =>
      _english.failureADatasetNeedsANameAndA;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheKeyColumnMustBeOneOf =>
      _english.failureTheKeyColumnMustBeOneOf;

  /// Operator-facing failure retained through headless execution.
  static String get failurePickAKeyFromTheColumnList =>
      _english.failurePickAKeyFromTheColumnList;

  /// Operator-facing failure retained through headless execution.
  static String get failureReferenceDataIsNotAvailableYet =>
      _english.failureReferenceDataIsNotAvailableYet;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatTableHasNoDataColumns =>
      _english.failureThatTableHasNoDataColumns;

  /// Operator-facing failure retained through headless execution.
  static String get failureATemplateNeedsAName =>
      _english.failureATemplateNeedsAName;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenAProjectThenAddTheTemplate =>
      _english.failureOpenAProjectThenAddTheTemplate;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheShippedTemplatesCouldNotBeRead =>
      _english.failureTheShippedTemplatesCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatShippedTemplateIsNotOnThis =>
      _english.failureThatShippedTemplateIsNotOnThis;

  /// Operator-facing failure retained through headless execution.
  static String get failurePickAnotherTemplateFromTheLibrary =>
      _english.failurePickAnotherTemplateFromTheLibrary;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheInheritedFieldGroupsCouldNotBe =>
      _english.failureTheInheritedFieldGroupsCouldNotBe;

  /// Operator-facing failure retained through headless execution.
  static String failureAShippedTemplateIsMissingValue(String value0) =>
      _english.failureAShippedTemplateIsMissingValue(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureReinstallTheAppThenTryAgain =>
      _english.failureReinstallTheAppThenTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureAShippedTemplateUsesAnUnknownSchema =>
      _english.failureAShippedTemplateUsesAnUnknownSchema;

  /// Operator-facing failure retained through headless execution.
  static String get failureAShippedTemplateHasAnInvalidKey =>
      _english.failureAShippedTemplateHasAnInvalidKey;

  /// Operator-facing failure retained through headless execution.
  static String get failureAShippedTemplateNameIsNotA =>
      _english.failureAShippedTemplateNameIsNotA;

  /// Operator-facing failure retained through headless execution.
  static String get failureAShippedTemplateNamesAnUnknownIdentity =>
      _english.failureAShippedTemplateNamesAnUnknownIdentity;

  /// Operator-facing failure retained through headless execution.
  static String get failureAShippedTemplateNamesAnUnknownParent =>
      _english.failureAShippedTemplateNamesAnUnknownParent;

  /// Operator-facing failure retained through headless execution.
  static String get failureAShippedTemplateNamesAnUnknownField =>
      _english.failureAShippedTemplateNamesAnUnknownField;

  /// Operator-facing failure retained through headless execution.
  static String failureAShippedFieldIsMissingValue(String value0) =>
      _english.failureAShippedFieldIsMissingValue(value0);

  /// Operator-facing failure retained through headless execution.
  static String get failureAShippedFieldUsesAnUnknownType =>
      _english.failureAShippedFieldUsesAnUnknownType;

  /// Operator-facing failure retained through headless execution.
  static String get failureAShippedFieldLabelIsNotA =>
      _english.failureAShippedFieldLabelIsNotA;

  /// Operator-facing failure retained through headless execution.
  static String get failureAShippedTemplateCouldNotBeRead =>
      _english.failureAShippedTemplateCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  static String get failureAShippedTemplateNamesAnUnknownRecord =>
      _english.failureAShippedTemplateNamesAnUnknownRecord;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheTemplateOrItsRecordsChangedWhile =>
      _english.failureTheTemplateOrItsRecordsChangedWhile;

  /// Operator-facing failure retained through headless execution.
  static String get failureReviewTheUpdatedChangesAndTryAgain =>
      _english.failureReviewTheUpdatedChangesAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureAFieldNeedsAKey => _english.failureAFieldNeedsAKey;

  /// Operator-facing failure retained through headless execution.
  static String get failureGiveEveryFieldAKeyAndSave =>
      _english.failureGiveEveryFieldAKeyAndSave;

  /// Operator-facing failure retained through headless execution.
  static String get failureEachFieldKeyMustBeUniqueOn =>
      _english.failureEachFieldKeyMustBeUniqueOn;

  /// Operator-facing failure retained through headless execution.
  static String get failureRenameTheDuplicateKeyAndSaveAgain =>
      _english.failureRenameTheDuplicateKeyAndSaveAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueIsNotText =>
      _english.failureThatValueIsNotText;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterTextOrLeaveTheFieldEmpty =>
      _english.failureEnterTextOrLeaveTheFieldEmpty;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueIsNotAWholeNumber =>
      _english.failureThatValueIsNotAWholeNumber;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterAWholeNumberOrLeaveThe =>
      _english.failureEnterAWholeNumberOrLeaveThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueIsNotANumber =>
      _english.failureThatValueIsNotANumber;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterANumberOrLeaveTheField =>
      _english.failureEnterANumberOrLeaveTheField;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatNumberIsOutsideTheAllowedRange =>
      _english.failureThatNumberIsOutsideTheAllowedRange;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterANumberInsideTheRangeOr =>
      _english.failureEnterANumberInsideTheRangeOr;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueIsShorterThanThisField =>
      _english.failureThatValueIsShorterThanThisField;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterALongerValueOrLeaveThe =>
      _english.failureEnterALongerValueOrLeaveThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueIsLongerThanThisField =>
      _english.failureThatValueIsLongerThanThisField;

  /// Operator-facing failure retained through headless execution.
  static String get failureShortenTheValueOrLeaveTheField =>
      _english.failureShortenTheValueOrLeaveTheField;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueDoesNotMatchTheExpected =>
      _english.failureThatValueDoesNotMatchTheExpected;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterAValueInTheExpectedForm =>
      _english.failureEnterAValueInTheExpectedForm;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisFieldSPatternIsNotValid =>
      _english.failureThisFieldSPatternIsNotValid;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenTheTemplateAndCorrectTheField =>
      _english.failureOpenTheTemplateAndCorrectTheField;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueIsNotADate =>
      _english.failureThatValueIsNotADate;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterACalendarDateOrLeaveThe =>
      _english.failureEnterACalendarDateOrLeaveThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueIsNotATimeOf =>
      _english.failureThatValueIsNotATimeOf;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterATimeOrLeaveTheField =>
      _english.failureEnterATimeOrLeaveTheField;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueIsNotADateAnd =>
      _english.failureThatValueIsNotADateAnd;

  /// Operator-facing failure retained through headless execution.
  static String get failureEnterADateAndTimeOrLeave =>
      _english.failureEnterADateAndTimeOrLeave;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueIsNotAYesOr =>
      _english.failureThatValueIsNotAYesOr;

  /// Operator-facing failure retained through headless execution.
  static String get failureSwitchTheFieldOnOrOffOr =>
      _english.failureSwitchTheFieldOnOrOffOr;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueIsNotAChoice =>
      _english.failureThatValueIsNotAChoice;

  /// Operator-facing failure retained through headless execution.
  static String get failurePickAnOptionFromTheListOr =>
      _english.failurePickAnOptionFromTheListOr;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatChoiceIsNotOnTheList =>
      _english.failureThatChoiceIsNotOnTheList;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueIsNotAFilePath =>
      _english.failureThatValueIsNotAFilePath;

  /// Operator-facing failure retained through headless execution.
  static String get failureAttachAFileOrLeaveTheField =>
      _english.failureAttachAFileOrLeaveTheField;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatValueIsNotALocation =>
      _english.failureThatValueIsNotALocation;

  /// Operator-facing failure retained through headless execution.
  static String get failureCaptureAGPSFixOrLeaveThe =>
      _english.failureCaptureAGPSFixOrLeaveThe;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatLocationIsOutsideTheEarth =>
      _english.failureThatLocationIsOutsideTheEarth;

  /// Operator-facing failure retained through headless execution.
  static String get failureCaptureAGPSFixAgainOrLeave =>
      _english.failureCaptureAGPSFixAgainOrLeave;

  /// Operator-facing failure retained through headless execution.
  static String get failureThisFieldTypeHasNoEditorOn =>
      _english.failureThisFieldTypeHasNoEditorOn;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenTheTemplateAndPickAType =>
      _english.failureOpenTheTemplateAndPickAType;

  /// Operator-facing failure retained through headless execution.
  static String get failureConfirmConsentWithTheNamedOperator =>
      _english.failureConfirmConsentWithTheNamedOperator;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatFieldTypeIsNotRecognised =>
      _english.failureThatFieldTypeIsNotRecognised;

  /// Operator-facing failure retained through headless execution.
  static String get failurePickATypeFromTheListAnd =>
      _english.failurePickATypeFromTheListAnd;

  /// Operator-facing failure retained through headless execution.
  static String get failureThatInputModeIsNotRecognised =>
      _english.failureThatInputModeIsNotRecognised;

  /// Operator-facing failure retained through headless execution.
  static String get failurePickAnInputModeFromTheList =>
      _english.failurePickAnInputModeFromTheList;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheSuggestedOrderCouldNotBeRead =>
      _english.failureTheSuggestedOrderCouldNotBeRead;

  /// Operator-facing failure retained through headless execution.
  static String get failureUseTheOnDeviceResultsOrTry =>
      _english.failureUseTheOnDeviceResultsOrTry;

  /// Operator-facing failure retained through headless execution.
  static String get failureOpenTheTemplateListAndTryAgain =>
      _english.failureOpenTheTemplateListAndTryAgain;

  /// Operator-facing failure retained through headless execution.
  static String get failureTheDailyAnalysisLimitIsReached =>
      _english.failureTheDailyAnalysisLimitIsReached;

  /// Operator-facing failure retained through headless execution.
  static String get failureUseTheOnDeviceSuggestionsOrTry =>
      _english.failureUseTheOnDeviceSuggestionsOrTry;

  /// Operator-facing failure retained through headless execution.
  static String get failureExportProtectionsAreUnavailableOnThisDevice =>
      _english.failureExportProtectionsAreUnavailableOnThisDevice;

  /// Operator-facing status for processingDailyCap.
  static String processingDailyCap(int cap, String resetDay) =>
      _english.processingDailyCap(cap, resetDay);

  /// Operator-facing status for processingDailyResetRecovery.
  static String get processingDailyResetRecovery =>
      _english.processingDailyResetRecovery;

  /// Operator-facing status for bundlePasswordInvalid.
  static String get bundlePasswordInvalid => _english.bundlePasswordInvalid;

  /// Operator-facing status for bundlePasswordInvalidRecovery.
  static String get bundlePasswordInvalidRecovery =>
      _english.bundlePasswordInvalidRecovery;

  /// Operator-facing status for incomingBundleBusy.
  static String get incomingBundleBusy => _english.incomingBundleBusy;

  /// Operator-facing status for incomingBundleTooLarge.
  static String get incomingBundleTooLarge => _english.incomingBundleTooLarge;

  /// Operator-facing status for incomingBundleIncomplete.
  static String get incomingBundleIncomplete =>
      _english.incomingBundleIncomplete;

  /// Operator-facing status for incomingBundleUnreadable.
  static String get incomingBundleUnreadable =>
      _english.incomingBundleUnreadable;

  /// Operator-facing status for incomingBundleUnreadableRecovery.
  static String get incomingBundleUnreadableRecovery =>
      _english.incomingBundleUnreadableRecovery;

  /// Operator-facing status for biometricUnavailable.
  static String get biometricUnavailable => _english.biometricUnavailable;

  /// Operator-facing status for biometricPinRecovery.
  static String get biometricPinRecovery => _english.biometricPinRecovery;

  /// Operator-facing status for appLockStorageUnavailable.
  static String get appLockStorageUnavailable =>
      _english.appLockStorageUnavailable;

  /// Operator-facing status for appLockStorageRecovery.
  static String get appLockStorageRecovery => _english.appLockStorageRecovery;

  /// The destination could not be saved.
  static String get cloudDestinationSaveFailed =>
      _english.cloudDestinationSaveFailed;

  /// That destination is no longer listed.
  static String get cloudDestinationMissing => _english.cloudDestinationMissing;

  /// Refresh the list.
  static String get cloudRefreshDestinations =>
      _english.cloudRefreshDestinations;

  /// The upload could not be recorded.
  static String get cloudUploadRecordFailed => _english.cloudUploadRecordFailed;

  /// The upload history could not be updated.
  static String get cloudUploadHistoryUpdateFailed =>
      _english.cloudUploadHistoryUpdateFailed;

  /// The file on this device was not changed.
  static String get cloudUploadHistoryUpdateRecovery =>
      _english.cloudUploadHistoryUpdateRecovery;

  /// Confirm this upload before it can start.
  static String get cloudUploadConfirmationRequired =>
      _english.cloudUploadConfirmationRequired;

  /// Review the file and confirm it.
  static String get cloudUploadConfirmationRecovery =>
      _english.cloudUploadConfirmationRecovery;

  /// That upload is no longer in the history.
  static String get cloudUploadHistoryMissing =>
      _english.cloudUploadHistoryMissing;

  /// Start the upload again.
  static String get cloudUploadRestartRecovery =>
      _english.cloudUploadRestartRecovery;

  /// That preference cannot be stored.
  static String get settingsPreferenceUnsupported =>
      _english.settingsPreferenceUnsupported;

  /// Choose a supported value and save again.
  static String get settingsPreferenceUnsupportedRecovery =>
      _english.settingsPreferenceUnsupportedRecovery;

  /// The preference could not be saved on this device.
  static String get settingsPreferenceSaveFailed =>
      _english.settingsPreferenceSaveFailed;

  /// Try again. Your last change was not stored.
  static String get settingsPreferenceSaveRecovery =>
      _english.settingsPreferenceSaveRecovery;

  /// The saved capture could not be read.
  static String get privacyCaptureUnreadable =>
      _english.privacyCaptureUnreadable;

  /// Recover the capture and try again.
  static String get privacyCaptureRecover => _english.privacyCaptureRecover;

  /// Open a project before removing its location data.
  static String get privacyProjectRequired => _english.privacyProjectRequired;

  /// Choose a project, then try again.
  static String get privacyProjectRequiredRecovery =>
      _english.privacyProjectRequiredRecovery;

  /// This destination sign-in changed.
  static String get cloudSignInChanged => _english.cloudSignInChanged;

  /// This Google Drive sign-in needs renewal.
  static String get cloudGoogleSignInRenewal =>
      _english.cloudGoogleSignInRenewal;

  /// Sign in again.
  static String get cloudSignInAgain => _english.cloudSignInAgain;
}
