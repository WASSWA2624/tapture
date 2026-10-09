import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.g.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.g.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'XA'),
  ];

  /// Why a protected record value cannot be corrected.
  ///
  /// In en, this message translates to:
  /// **'This field is read-only.'**
  String get recordFieldReadOnly;

  /// Explains rejection of a field protected by its source or stored value.
  ///
  /// In en, this message translates to:
  /// **'{fieldKey} is protected from extraction.'**
  String processingProtectedField(String fieldKey);

  /// Processing review reason when the owning captured shape cannot be resolved.
  ///
  /// In en, this message translates to:
  /// **'The captured template version is unavailable. Review the saved evidence.'**
  String get processingCapturedTemplateUnavailable;

  /// Explicit audited correction of an eligible automatically populated field.
  ///
  /// In en, this message translates to:
  /// **'Correct value'**
  String get recordCorrectAutomaticValue;

  /// Searches Manual form field labels and stable keys.
  ///
  /// In en, this message translates to:
  /// **'Search fields'**
  String get captureSearchFields;

  /// Field source/status for operator entry.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get captureFieldManual;

  /// Field source/status for system filling.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get captureFieldAutomatic;

  /// Field source/status for inherited context values.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get captureFieldContext;

  /// Field source/status for evidence extraction eligibility.
  ///
  /// In en, this message translates to:
  /// **'From photos and caption'**
  String get captureFieldProcessing;

  /// Pending field source that requires the authoritative first-save instant or sequence.
  ///
  /// In en, this message translates to:
  /// **'Filled when saved'**
  String get captureFieldFilledAtSave;

  /// Unavailable automatic source without a fabricated value.
  ///
  /// In en, this message translates to:
  /// **'Unavailable on this device'**
  String get captureFieldUnavailable;

  /// Explains existing template-owned source and input-mode controls.
  ///
  /// In en, this message translates to:
  /// **'Choose automatic filling, manual entry or extraction from photos and captions. Automatic and manual-only fields stay out of processing.'**
  String get fieldSourceHelp;

  /// Honest availability helper without a weather or hardware fallback.
  ///
  /// In en, this message translates to:
  /// **'Automatic temperature is unavailable; enter it manually.'**
  String get captureTemperatureUnavailable;

  /// Template-opted-in native local interface address source.
  ///
  /// In en, this message translates to:
  /// **'Local network address'**
  String get fieldAutoFillLocalAddress;

  /// Validation recovery for a non-text local-address source.
  ///
  /// In en, this message translates to:
  /// **'Use a text field for a local network address.'**
  String get fieldSourceAddressNeedsText;

  /// Capture overflow action opening optional template fields.
  ///
  /// In en, this message translates to:
  /// **'Manual form'**
  String get captureManualForm;

  /// Collapsed local export summary heading.
  ///
  /// In en, this message translates to:
  /// **'Package details'**
  String get projectExportDetails;

  /// Canonical native project archive destination; never claims Downloads.
  ///
  /// In en, this message translates to:
  /// **'Project export folder'**
  String get projectExportDestination;

  /// Browser-controlled public archive destination.
  ///
  /// In en, this message translates to:
  /// **'Browser downloads'**
  String get projectExportBrowserDestination;

  /// Explicit desktop action opening the stored project archive.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get projectExportOpen;

  /// Collapsed source and integrity details for one speech model.
  ///
  /// In en, this message translates to:
  /// **'Model details'**
  String get settingsSpeechModelDetails;

  /// Concise state and localized size for one speech model.
  ///
  /// In en, this message translates to:
  /// **'{state} · {size}'**
  String settingsSpeechModelSummary(String state, String size);

  /// Explicit secondary action saving inline server/account configuration.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get backendConfigure;

  /// Collapsed complete AI custody, billing and secondary status details.
  ///
  /// In en, this message translates to:
  /// **'Connection details'**
  String get aiConnectionDetails;

  /// Neutral helper; complete custody and billing explanations remain in Connection details.
  ///
  /// In en, this message translates to:
  /// **'Your server handles AI access and keys.'**
  String get aiCustodySummary;

  /// Provider trademark attribution, shown inside Connection details.
  ///
  /// In en, this message translates to:
  /// **'Gemini is a trademark of Google LLC. OpenAI and xAI marks belong to their respective owners.'**
  String get aiProviderAttribution;

  /// Secondary AI settings action opening optional backend setup.
  ///
  /// In en, this message translates to:
  /// **'Server and account'**
  String get aiServerAndAccount;

  /// Collapsed photo storage settings section.
  ///
  /// In en, this message translates to:
  /// **'Photo files'**
  String get settingsPhotoFiles;

  /// Collapsed project context defaults section.
  ///
  /// In en, this message translates to:
  /// **'Project contexts'**
  String get settingsProjectContexts;

  /// Current localized photo quality and folder selection.
  ///
  /// In en, this message translates to:
  /// **'{quality} · {folders}'**
  String settingsPhotoFilesSummary(String quality, String folders);

  /// Current localized context clearing interval and movement distance, or localized Off.
  ///
  /// In en, this message translates to:
  /// **'Clear after: {autoClear} · Movement: {movement}'**
  String settingsProjectContextsSummary(String autoClear, String movement);

  /// Local image recognition has no browser implementation.
  ///
  /// In en, this message translates to:
  /// **'On-device photo reading is unavailable in this browser. Review fields manually or enable online analysis.'**
  String get ocrBrowserUnavailable;

  /// Stated absence when a value was not found.
  ///
  /// In en, this message translates to:
  /// **'Not detected'**
  String get notDetected;

  /// How many records a list holds. Zero is a stated absence, not a blank.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No records} one{1 record} other{{count} records}}'**
  String recordsCount(int count);

  /// How many fields a template holds. Zero is a stated absence, not a blank.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No fields} one{1 field} other{{count} fields}}'**
  String fieldsCount(int count);

  /// Clears the named field.
  ///
  /// In en, this message translates to:
  /// **'Clear {label}'**
  String clearField(Object label);

  /// Reveals a hidden field such as a PIN, named for its label.
  ///
  /// In en, this message translates to:
  /// **'Show {label}'**
  String showField(Object label);

  /// Hides a revealed field again, named for its label.
  ///
  /// In en, this message translates to:
  /// **'Hide {label}'**
  String hideField(Object label);

  /// The camera or photo library was refused.
  ///
  /// In en, this message translates to:
  /// **'Allow the camera or photos to attach one. Everything else still works.'**
  String get photoNoAccess;

  /// The browser display picker was refused.
  ///
  /// In en, this message translates to:
  /// **'Allow screen capture to attach another window. Everything else still works.'**
  String get displayNoAccess;

  /// The device has no camera the app can open.
  ///
  /// In en, this message translates to:
  /// **'No camera is available on this device.'**
  String get photoNoCamera;

  /// The picker failed for a reason it did not name.
  ///
  /// In en, this message translates to:
  /// **'That photo could not be added. Try another.'**
  String get photoPickFailed;

  /// The display picker failed for a reason it did not name.
  ///
  /// In en, this message translates to:
  /// **'That window could not be captured. Try another.'**
  String get displayCaptureFailed;

  /// Starts dictation into a field, named for its label.
  ///
  /// In en, this message translates to:
  /// **'Speak into {label}'**
  String dictateInto(Object label);

  /// Stops dictation into a field, named for its label.
  ///
  /// In en, this message translates to:
  /// **'Stop speaking into {label}'**
  String stopDictating(Object label);

  /// The platform has no recogniser this app can reach.
  ///
  /// In en, this message translates to:
  /// **'Voice input is not available here. Type instead.'**
  String get dictationUnavailable;

  /// The microphone was refused.
  ///
  /// In en, this message translates to:
  /// **'Allow the microphone to speak into a field. Typing still works.'**
  String get dictationNoMicrophone;

  /// The recogniser heard nothing it could use.
  ///
  /// In en, this message translates to:
  /// **'Nothing was heard. Tap the microphone and speak again.'**
  String get dictationNothingHeard;

  /// The recogniser needs a connection it does not have.
  ///
  /// In en, this message translates to:
  /// **'Voice input needs a connection on this device. Type instead.'**
  String get dictationNeedsConnection;

  /// Offline by choice, and this device cannot recognise speech locally.
  ///
  /// In en, this message translates to:
  /// **'You are working offline, and this device cannot recognise speech without a connection. Type instead.'**
  String get dictationOfflineOnly;

  /// The recogniser stopped for a reason it did not name.
  ///
  /// In en, this message translates to:
  /// **'Voice input stopped. Try again, or type instead.'**
  String get dictationFailed;

  /// The on-device speech engine is missing or could not start.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is not available in this version of the app.'**
  String get speechUnavailable;

  /// The on-device speech model file is absent.
  ///
  /// In en, this message translates to:
  /// **'The speech model is not installed on this device.'**
  String get speechModelMissing;

  /// What to do when the on-device speech model is absent.
  ///
  /// In en, this message translates to:
  /// **'Reinstall the app, or import the model in Settings.'**
  String get speechModelMissingRecovery;

  /// The on-device speech model failed its size, header or checksum check.
  ///
  /// In en, this message translates to:
  /// **'The speech model file is damaged, so it was not used.'**
  String get speechModelDamaged;

  /// What to do when the on-device speech model is damaged.
  ///
  /// In en, this message translates to:
  /// **'Reinstall the app, or import the model again in Settings.'**
  String get speechModelDamagedRecovery;

  /// The processor, memory or browser cannot run the on-device speech engine.
  ///
  /// In en, this message translates to:
  /// **'This device cannot run speech recognition.'**
  String get speechDeviceUnsupported;

  /// The on-device speech model could not be loaded for lack of memory.
  ///
  /// In en, this message translates to:
  /// **'There is not enough free memory to load the speech model.'**
  String get speechLowMemory;

  /// What to do when memory is too low for the on-device speech model.
  ///
  /// In en, this message translates to:
  /// **'Close other apps, then try again.'**
  String get speechLowMemoryRecovery;

  /// The on-device speech engine failed on one stretch of audio.
  ///
  /// In en, this message translates to:
  /// **'Part of the speech could not be turned into text. The audio is kept.'**
  String get speechTranscriptionFailed;

  /// The voice language has no on-device speech model.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition on this device does not support the chosen voice language.'**
  String get speechLanguageUnsupported;

  /// The on-device speech engine stopped or was closed mid-task.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition stopped unexpectedly. Try again.'**
  String get speechEngineStopped;

  /// An imported file matches no known speech model.
  ///
  /// In en, this message translates to:
  /// **'This file is not a speech model the app recognises.'**
  String get speechImportUnknown;

  /// What to do when an imported file is not a known speech model.
  ///
  /// In en, this message translates to:
  /// **'Choose one of the model files named in Settings.'**
  String get speechImportUnknownRecovery;

  /// A transcript or part of one could not be written to the device's database.
  ///
  /// In en, this message translates to:
  /// **'The transcript could not be saved on this device.'**
  String get transcriptSaveFailed;

  /// A transcript segment skipped ahead or contradicted one already saved.
  ///
  /// In en, this message translates to:
  /// **'Part of the transcript arrived out of order and was not saved.'**
  String get transcriptSegmentOutOfOrder;

  /// An edit was refused because the transcript is still being recorded or finished.
  ///
  /// In en, this message translates to:
  /// **'This transcript is still being recorded. Edit it once the recording has finished.'**
  String get transcriptStillRecording;

  /// A value filled in rather than typed.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled'**
  String get autoFilled;

  /// A number outside the allowed range.
  ///
  /// In en, this message translates to:
  /// **'Out of range'**
  String get outOfRange;

  /// Selects every visible option in a multi-choice sheet.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// Clears a selection or a field.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Dismisses the named chip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss {label}'**
  String dismissChip(Object label);

  /// Dismisses a banner or other unnamed surface.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Backs out of a confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Acknowledges an alert.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Title of the unsaved-changes confirm.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// Body of the unsaved-changes confirm.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes.'**
  String get unsavedChanges;

  /// Confirms discarding unsaved edits.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Heading over a list of invalid fields.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Fix this field} other{Fix these fields}}'**
  String fixFields(int count);

  /// One invalid field in a validation summary. [label] is template content.
  ///
  /// In en, this message translates to:
  /// **'{label}: {error}'**
  String fieldError(Object label, Object error);

  /// Label of a field that must be filled before Save.
  ///
  /// In en, this message translates to:
  /// **'{label} (required)'**
  String fieldLabelRequired(Object label);

  /// Label of a field that may be left empty.
  ///
  /// In en, this message translates to:
  /// **'{label} (optional)'**
  String fieldLabelOptional(Object label);

  /// Announced summary of invalid fields.
  ///
  /// In en, this message translates to:
  /// **'{heading}. {errorsjoin}'**
  String validationAnnouncement(Object heading, Object errorsjoin);

  /// Placeholder when a cached thumb file is missing.
  ///
  /// In en, this message translates to:
  /// **'Missing photo'**
  String get missingPhoto;

  /// Semantic name of a thumbnail's selection checkbox.
  ///
  /// In en, this message translates to:
  /// **'Select photo'**
  String get photoSelect;

  /// A stored photo's file could not be read for its thumbnail.
  ///
  /// In en, this message translates to:
  /// **'That photo could not be read from this device.'**
  String get photoUnreadable;

  /// Recovery for [photoUnreadable].
  ///
  /// In en, this message translates to:
  /// **'Capture the photo again, then try again.'**
  String get photoUnreadableRecovery;

  /// Semantic name of a missing thumb, including its type.
  ///
  /// In en, this message translates to:
  /// **'Missing photo, {type}'**
  String missingPhotoNamed(Object type);

  /// Fallback type name when a photo has none.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// Crop action on the photo viewer.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get photoCrop;

  /// Semantic name of a crop frame corner handle.
  ///
  /// In en, this message translates to:
  /// **'Crop corner, drag to resize'**
  String get photoCropCorner;

  /// Semantic name of the crop frame body.
  ///
  /// In en, this message translates to:
  /// **'Crop frame, drag to move'**
  String get photoCropFrame;

  /// Rotate the visible photo a quarter turn.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get photoRotate;

  /// Open freehand drawing.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get photoDraw;

  /// Remove the latest stroke.
  ///
  /// In en, this message translates to:
  /// **'Undo drawing'**
  String get photoUndoDraw;

  /// Remove every stroke.
  ///
  /// In en, this message translates to:
  /// **'Clear drawing'**
  String get photoClearDraw;

  /// Name of a markup ink, read beside its swatch (FE-A11Y-05).
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get markupInk;

  /// Name of a markup ink, read beside its swatch (FE-A11Y-05).
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get markupInkYellow;

  /// Name of a markup ink, read beside its swatch (FE-A11Y-05).
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get markupInkWhite;

  /// Name of a markup ink, read beside its swatch (FE-A11Y-05).
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get markupInkBlack;

  /// Name of a markup ink, read beside its swatch (FE-A11Y-05).
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get markupInkBlue;

  /// Name of a markup ink, read beside its swatch (FE-A11Y-05).
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get markupInkGreen;

  /// Label of the markup ink swatches.
  ///
  /// In en, this message translates to:
  /// **'Ink'**
  String get markupInkLabel;

  /// Label of the markup size choice.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get markupSize;

  /// Switches the dark backing behind typed text on a photo.
  ///
  /// In en, this message translates to:
  /// **'Dark backing'**
  String get markupBacking;

  /// What the dark backing does.
  ///
  /// In en, this message translates to:
  /// **'Keeps the words readable on a busy photo.'**
  String get markupBackingDescription;

  /// How to place typed text on a photo.
  ///
  /// In en, this message translates to:
  /// **'Drag the photo to move the words.'**
  String get markupTypeHint;

  /// The thinnest stroke or smallest text.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get markupSizeSmall;

  /// The middle stroke or text size.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get markupSizeMedium;

  /// The thickest stroke or largest text.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get markupSizeLarge;

  /// How many photos are in the tray.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No photos} one{1 photo} other{{count} photos}}'**
  String capturePhotoCount(int count);

  /// Badge while a photo is still being prepared.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get capturePhotoProcessing;

  /// Clears a derived crop or typed copy.
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get photoRevert;

  /// The preview's caption line when a photo has none.
  ///
  /// In en, this message translates to:
  /// **'No caption yet'**
  String get photoNoCaption;

  /// Opens the caption editor in the photo preview.
  ///
  /// In en, this message translates to:
  /// **'Edit caption'**
  String get photoCaptionEdit;

  /// Removes a photo's caption in the preview.
  ///
  /// In en, this message translates to:
  /// **'Delete caption'**
  String get photoCaptionDelete;

  /// What deleting a caption does.
  ///
  /// In en, this message translates to:
  /// **'The caption is removed from this photo. You can undo it.'**
  String get photoCaptionDeleteMessage;

  /// Confirms a caption was removed, beside Undo.
  ///
  /// In en, this message translates to:
  /// **'Caption deleted.'**
  String get photoCaptionDeleted;

  /// Types words onto a derived copy of a photo.
  ///
  /// In en, this message translates to:
  /// **'Type on this photo'**
  String get photoTypeOn;

  /// Semantic name of a thumb: type, missing, caption and selection.
  ///
  /// In en, this message translates to:
  /// **', captioned'**
  String get photoThumbLabel;

  /// Semantic name of a thumb: type, missing, caption and selection.
  ///
  /// In en, this message translates to:
  /// **', selected'**
  String get photoThumbLabelSelected;

  /// Facing the subject.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get photoFront;

  /// Reverse of the subject.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get photoBack;

  /// Serial number plate or stamp.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get photoSerial;

  /// Manufacturer rating plate.
  ///
  /// In en, this message translates to:
  /// **'Rating plate'**
  String get photoRatingPlate;

  /// Short overlay for a rating plate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get photoRatingPlateBadge;

  /// Visible damage.
  ///
  /// In en, this message translates to:
  /// **'Damage'**
  String get photoDamage;

  /// Control or breaker panel.
  ///
  /// In en, this message translates to:
  /// **'Panel'**
  String get photoPanel;

  /// Site or room context.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get photoLocation;

  /// People present at a meeting.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get photoAttendance;

  /// Short overlay for attendance.
  ///
  /// In en, this message translates to:
  /// **'Attend'**
  String get photoAttendanceBadge;

  /// A page or scanned document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get photoDocument;

  /// Short overlay for a document.
  ///
  /// In en, this message translates to:
  /// **'Doc'**
  String get photoDocumentBadge;

  /// Any other photo type.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get photoOther;

  /// A progress step that finished.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stepDone;

  /// A progress step that is in progress.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get stepRunning;

  /// A progress step that has not started.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get stepWaiting;

  /// A failed step or record.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Announced name of a progress row.
  ///
  /// In en, this message translates to:
  /// **'{label}, {state}'**
  String progressAnnouncement(Object label, Object state);

  /// Announced name of a progress row.
  ///
  /// In en, this message translates to:
  /// **'{label}, {state}, {detail}'**
  String progressAnnouncementValue(Object label, Object state, Object detail);

  /// Saved locally, not yet captured.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// Evidence is on the record.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get statusCaptured;

  /// Waiting for processing.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get statusQueued;

  /// A processing job is running.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statusProcessing;

  /// Extraction finished.
  ///
  /// In en, this message translates to:
  /// **'Extracted'**
  String get statusExtracted;

  /// A person must look at this record.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get statusNeedsReview;

  /// A person has accepted the record.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// Kept for history.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get statusArchived;

  /// Marked gone.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get statusDeleted;

  /// Headline when a list has nothing to show.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyHeadline;

  /// Body when a list has nothing to show.
  ///
  /// In en, this message translates to:
  /// **'When there is something to show, it will appear here.'**
  String get emptyMessage;

  /// A control or page that is still working.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// Busy adverb on an action that is still running.
  ///
  /// In en, this message translates to:
  /// **'loading'**
  String get busy;

  /// Named action that is still running.
  ///
  /// In en, this message translates to:
  /// **'{label}, {busy}'**
  String busyAction(Object label, Object busy);

  /// Retries a failed load.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Persists the current form or record.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Reverses the last destructive action.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Developer gallery title.
  ///
  /// In en, this message translates to:
  /// **'Widget gallery'**
  String get galleryTitle;

  /// Theme-mode switcher.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get galleryTheme;

  /// Simulated-width switcher.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get galleryWidth;

  /// Text-scale switcher.
  ///
  /// In en, this message translates to:
  /// **'Text scale'**
  String get galleryTextScale;

  /// Token family heading.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get galleryTokens;

  /// Layout family heading.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get galleryLayout;

  /// Button family heading.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get galleryButtons;

  /// Field family heading.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get galleryFields;

  /// Container family heading.
  ///
  /// In en, this message translates to:
  /// **'Containers'**
  String get galleryContainers;

  /// State family heading.
  ///
  /// In en, this message translates to:
  /// **'States'**
  String get galleryStates;

  /// Feedback family heading.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get galleryFeedback;

  /// Light appearance.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get galleryLight;

  /// Dark appearance.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get galleryDark;

  /// Outdoor appearance.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get galleryOutdoor;

  /// Compact width.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get galleryCompact;

  /// Medium width.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get galleryMedium;

  /// Expanded width.
  ///
  /// In en, this message translates to:
  /// **'Expanded'**
  String get galleryExpanded;

  /// Default text scale.
  ///
  /// In en, this message translates to:
  /// **'100%'**
  String get galleryScale100;

  /// Double text scale.
  ///
  /// In en, this message translates to:
  /// **'200%'**
  String get galleryScale200;

  /// Product name in chrome and the system window.
  ///
  /// In en, this message translates to:
  /// **'Tapture'**
  String get appName;

  /// Prompt on list-pane and picker search fields.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// What to change when a search matches nothing.
  ///
  /// In en, this message translates to:
  /// **'Change the search.'**
  String get searchNoMatchMessage;

  /// The filter button on a search field, with how many filters are on.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get searchFilters;

  /// The filter button on a search field, with how many filters are on.
  ///
  /// In en, this message translates to:
  /// **'Filters ({active})'**
  String searchFiltersFilters(int active);

  /// Turns every filter of a list off.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get searchClearFilters;

  /// What to change when a search and its filters match nothing.
  ///
  /// In en, this message translates to:
  /// **'Change the search or clear the filters.'**
  String get searchFilterNoMatchMessage;

  /// Semantic name of the title-bar overflow control.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get overflowMenu;

  /// Shell destination: the project list.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get navProjects;

  /// Headline when the project list has nothing to show.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get projectsEmptyHeadline;

  /// Body when the project list has nothing to show.
  ///
  /// In en, this message translates to:
  /// **'Create a project to start capturing.'**
  String get projectsEmptyMessage;

  /// Primary empty-state action on the project list.
  ///
  /// In en, this message translates to:
  /// **'Create a project'**
  String get projectsCreate;

  /// Headline when a wide layout has projects but none is open.
  ///
  /// In en, this message translates to:
  /// **'Choose a project'**
  String get projectsPickHeadline;

  /// Body when a wide layout has projects but none is open.
  ///
  /// In en, this message translates to:
  /// **'Select a project from the list.'**
  String get projectsPickMessage;

  /// Headline when the project search matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No matching projects'**
  String get projectsNoMatchHeadline;

  /// Body when the project search matches nothing.
  ///
  /// In en, this message translates to:
  /// **'Try a different name, or create a project.'**
  String get projectsNoMatchMessage;

  /// Search prompt for names, descriptions, and organisations.
  ///
  /// In en, this message translates to:
  /// **'Search projects'**
  String get projectSearchHint;

  /// Secondary filter-sheet title.
  ///
  /// In en, this message translates to:
  /// **'Project filters'**
  String get projectFiltersTitle;

  /// Status filter heading.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get projectStatusFilter;

  /// Pin-state filter heading.
  ///
  /// In en, this message translates to:
  /// **'Pinned state'**
  String get projectPinFilter;

  /// Human label for a pin filter wire name.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get projectPinFilterLabel;

  /// Human label for a pin filter wire name.
  ///
  /// In en, this message translates to:
  /// **'Unpinned'**
  String get projectPinFilterLabelUnpinned;

  /// Human label for a pin filter wire name.
  ///
  /// In en, this message translates to:
  /// **'All projects'**
  String get projectPinFilterLabelAllProjects;

  /// Commits project filter choices.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get projectApplyFilters;

  /// Semantic status for a project that stays at the top of the list.
  ///
  /// In en, this message translates to:
  /// **'Pinned project'**
  String get pinnedProject;

  /// Project-home template association count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No templates attached} one{1 template attached} other{{count} templates attached}}'**
  String projectTemplateCount(int count);

  /// Opens the project package file picker directly from Projects (task 143).
  ///
  /// In en, this message translates to:
  /// **'Import a Project'**
  String get projectsImport;

  /// Duplicate action that opens the create form from an existing project.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get projectsDuplicate;

  /// Overflow command that returns to the project list from a project home.
  ///
  /// In en, this message translates to:
  /// **'All projects'**
  String get projectAllProjects;

  /// Overflow command that opens the create form from a project home.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectNew;

  /// Hides a finished project from the active list.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get projectArchive;

  /// Restores an archived project to the active list.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get projectUnarchive;

  /// Soft-deletes a project after typed confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get projectDelete;

  /// Row menu label. The confirm dialog keeps [projectDelete].
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get projectDeleteMenu;

  /// Title of the delete confirmation, naming the project.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String projectDeleteTitle(Object name);

  /// Body of the delete confirmation, naming counts and retention.
  ///
  /// In en, this message translates to:
  /// **'This hides {recordsCountrecords} and {filesCountfiles}. You can restore them for {days} days. Nothing is removed yet.'**
  String projectDeleteMessage(
    Object recordsCountrecords,
    Object filesCountfiles,
    int days,
  );

  /// How many files a delete would hide.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no files} one{1 file} other{{count} files}}'**
  String filesCount(int count);

  /// Typed-name field on the delete confirmation.
  ///
  /// In en, this message translates to:
  /// **'Type the project name'**
  String get projectDeleteTypeName;

  /// Alternative on the delete confirmation: export before deleting.
  ///
  /// In en, this message translates to:
  /// **'Export first'**
  String get projectExportFirst;

  /// Filter that reveals archived projects on the landing list.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get projectShowArchived;

  /// Pins a project to the top of the list.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get projectPin;

  /// Removes a project from the top of the list.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get projectUnpin;

  /// Opens the rename dialog for a project.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get projectRename;

  /// Title of the rename dialog.
  ///
  /// In en, this message translates to:
  /// **'Rename project'**
  String get projectRenameTitle;

  /// Body of the rename dialog. The folder on disk stays put.
  ///
  /// In en, this message translates to:
  /// **'The folder on disk stays put.'**
  String get projectRenameMessage;

  /// Hands a copy of a project file to another app.
  ///
  /// In en, this message translates to:
  /// **'Open with'**
  String get projectOpenWith;

  /// Saves a copy of a project file on the web, where no app can be launched.
  ///
  /// In en, this message translates to:
  /// **'Download a copy'**
  String get projectDownloadCopy;

  /// Shown when Open with is asked for a project that has no file.
  ///
  /// In en, this message translates to:
  /// **'This project has no spreadsheet, document or PDF to open yet.'**
  String get projectNothingToOpen;

  /// What to do when there is nothing to open.
  ///
  /// In en, this message translates to:
  /// **'Import a template workbook or export the project, then try again.'**
  String get projectNothingToOpenRecovery;

  /// Title when the hand-off to another app failed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file'**
  String get projectOpenFailedTitle;

  /// Body when the hand-off failed.
  ///
  /// In en, this message translates to:
  /// **'Tapture could not hand the file to another app.'**
  String get projectOpenFailed;

  /// Body when the named file could not be handed off.
  ///
  /// In en, this message translates to:
  /// **'Tapture could not hand {fileName} to another app.'**
  String projectOpenFailedNamed(Object fileName);

  /// Recovery when the hand-off failed.
  ///
  /// In en, this message translates to:
  /// **'Free some space, then try again.'**
  String get projectOpenFailedRecovery;

  /// When no installed app can open the file type.
  ///
  /// In en, this message translates to:
  /// **'No app on this device can open that file.'**
  String get projectOpenNoApp;

  /// Recovery when no reader is installed.
  ///
  /// In en, this message translates to:
  /// **'Install a reader for this file type, then try again.'**
  String get projectOpenNoAppRecovery;

  /// When storage permission was refused before writing the copy.
  ///
  /// In en, this message translates to:
  /// **'Tapture needs storage access to open a copy of this file.'**
  String get projectOpenPermission;

  /// Recovery when storage permission was refused.
  ///
  /// In en, this message translates to:
  /// **'Allow storage access, then try again.'**
  String get projectOpenPermissionRecovery;

  /// Title of the create-project form.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get projectCreateTitle;

  /// Title of the create form when it is copying another project.
  ///
  /// In en, this message translates to:
  /// **'Duplicate project'**
  String get projectDuplicateTitle;

  /// Required name field on the create form.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get projectName;

  /// Optional longer note on the create form.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get projectDescription;

  /// Optional organisation field on the create form.
  ///
  /// In en, this message translates to:
  /// **'Organisation'**
  String get projectOrganisation;

  /// Title of the read-only project page, and the menu item that opens it.
  ///
  /// In en, this message translates to:
  /// **'Project details'**
  String get projectEditTitle;

  /// Title of the form that changes a project's details.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get projectEditFormTitle;

  /// Primary action on the project details page.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get projectEditDetails;

  /// A project detail nobody has filled in.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get projectValueNotSet;

  /// When the project was created, on its details page.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get projectCreatedAt;

  /// When the project last changed, on its details page.
  ///
  /// In en, this message translates to:
  /// **'Last changed'**
  String get projectUpdatedAt;

  /// Heading over the template whose fields the context levels come from.
  ///
  /// In en, this message translates to:
  /// **'Suggest levels from'**
  String get contextLevelSource;

  /// Title of the per-project settings form.
  ///
  /// In en, this message translates to:
  /// **'Project settings'**
  String get projectSettingsTitle;

  /// Confirms that the project details form was stored.
  ///
  /// In en, this message translates to:
  /// **'Project saved'**
  String get projectSaved;

  /// Confirms that the project settings form was stored.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get projectSettingsSaved;

  /// When fieldwork started.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get projectStartsOn;

  /// When fieldwork finished.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get projectEndsOn;

  /// Open or archived status on the details form.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get projectStatus;

  /// Status choice: the project is open.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get projectStatusActive;

  /// Status choice: the project is archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get projectStatusArchived;

  /// AI override on the project settings form.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get projectAiEnabled;

  /// What turning AI off does.
  ///
  /// In en, this message translates to:
  /// **'Turn off to keep this project fully manual.'**
  String get projectAiEnabledEffect;

  /// Image-egress override on the project settings form.
  ///
  /// In en, this message translates to:
  /// **'Do not send images'**
  String get projectDoNotSendImages;

  /// What turning image egress off does.
  ///
  /// In en, this message translates to:
  /// **'Providers never see photo bytes from this project.'**
  String get projectDoNotSendImagesEffect;

  /// Refined-columns override on the project settings form.
  ///
  /// In en, this message translates to:
  /// **'Refined columns'**
  String get projectRefineColumns;

  /// High-confidence threshold on the project settings form.
  ///
  /// In en, this message translates to:
  /// **'High confidence'**
  String get projectConfidenceHigh;

  /// Medium-confidence threshold on the project settings form.
  ///
  /// In en, this message translates to:
  /// **'Medium confidence'**
  String get projectConfidenceMedium;

  /// Inherit the app-level value for this switch.
  ///
  /// In en, this message translates to:
  /// **'Use app default'**
  String get projectUseAppDefault;

  /// Affirmative override on a three-way choice.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get projectOn;

  /// Negative override on a three-way choice.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get projectOff;

  /// Names the app-level value a row is changing.
  ///
  /// In en, this message translates to:
  /// **'App default: {value}'**
  String projectAppDefault(Object value);

  /// Headline when the details form has no open project.
  ///
  /// In en, this message translates to:
  /// **'No project open'**
  String get projectEditEmptyHeadline;

  /// Body when the details form has no open project.
  ///
  /// In en, this message translates to:
  /// **'Open a project to edit its details.'**
  String get projectEditEmptyMessage;

  /// Headline when the settings form has no open project.
  ///
  /// In en, this message translates to:
  /// **'No project open'**
  String get projectSettingsEmptyHeadline;

  /// Body when the settings form has no open project.
  ///
  /// In en, this message translates to:
  /// **'Open a project to change its settings.'**
  String get projectSettingsEmptyMessage;

  /// Suggested name for a duplicated project, editable before commit.
  ///
  /// In en, this message translates to:
  /// **'{name} (copy)'**
  String projectCopyName(Object name);

  /// Counts and unprocessed records on one project list row.
  ///
  /// In en, this message translates to:
  /// **'{recordsCountrecords} · {unprocessedCountunprocessed}'**
  String projectListSubtitle(
    Object recordsCountrecords,
    Object unprocessedCountunprocessed,
  );

  /// Position of one captured record on the project list.
  ///
  /// In en, this message translates to:
  /// **'Record {position}'**
  String projectRecordPosition(int position);

  /// Empty project records list.
  ///
  /// In en, this message translates to:
  /// **'No records here'**
  String get projectRecordsEmptyHeadline;

  /// Explains an empty project records filter.
  ///
  /// In en, this message translates to:
  /// **'Captured records for this filter appear here.'**
  String get projectRecordsEmptyMessage;

  /// Prompt on the project home search: what it looks through.
  ///
  /// In en, this message translates to:
  /// **'Search records'**
  String get projectRecordsSearchHint;

  /// Title of a project's records filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Record filters'**
  String get projectRecordFiltersTitle;

  /// The record-status facet of a project's records filters.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get projectRecordStatusFilter;

  /// A project home search that matched no record, naming the query.
  ///
  /// In en, this message translates to:
  /// **'No records match.'**
  String get projectRecordsNoMatch;

  /// A project home search that matched no record, naming the query.
  ///
  /// In en, this message translates to:
  /// **'No records match \"{shown}\".'**
  String projectRecordsNoMatchNoRecordsMatch(Object shown);

  /// A choice sheet search that matched no option, naming the query.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches.'**
  String get choiceNoMatch;

  /// A choice sheet search that matched no option, naming the query.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{shown}\".'**
  String choiceNoMatchNothingMatches(Object shown);

  /// Overflow command that writes a project export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get projectExport;

  /// Title of the project export screen.
  ///
  /// In en, this message translates to:
  /// **'Export project'**
  String get projectExportTitle;

  /// Empty export screen.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export'**
  String get projectExportEmptyHeadline;

  /// Explains that a project needs a record before export.
  ///
  /// In en, this message translates to:
  /// **'Capture a record before exporting this project.'**
  String get projectExportEmptyMessage;

  /// Shares a finished export.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get projectExportShare;

  /// Names the file that was stored.
  ///
  /// In en, this message translates to:
  /// **'Saved {fileName}.'**
  String projectExportSaved(Object fileName);

  /// Says the share sheet reaches other apps (Android and iOS).
  ///
  /// In en, this message translates to:
  /// **'Send the file to email, chat and other apps on this device.'**
  String get projectExportShareHint;

  /// Export summary section: the project itself.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get exportSectionProject;

  /// Export summary section: records by status.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get exportSectionRecords;

  /// Export summary section: records per template.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get exportSectionTemplates;

  /// Export summary section: the file the export writes.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get exportSectionFile;

  /// Audio clips filed on the exported records.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No audio clips} one{1 audio clip} other{{count} audio clips}}'**
  String exportAudioClips(int count);

  /// When the exported records were captured. [first] and [last] are
  ///    locale-formatted dates; one date when they are the same day.
  ///
  /// In en, this message translates to:
  /// **'Captured {first}'**
  String exportCapturedBetween(Object first);

  /// When the exported records were captured. [first] and [last] are
  ///    locale-formatted dates; one date when they are the same day.
  ///
  /// In en, this message translates to:
  /// **'Captured {first} to {last}'**
  String exportCapturedBetweenCapturedTo(Object first, Object last);

  /// Exported records not processed yet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unprocessed records} one{1 unprocessed record} other{{count} unprocessed records}}'**
  String exportUnprocessedCount(int count);

  /// Exported records waiting for a person to review.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No records need review} one{1 record needs review} other{{count} records need review}}'**
  String exportNeedsReviewCount(int count);

  /// Exported records already approved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No approved records} one{1 approved record} other{{count} approved records}}'**
  String exportApprovedCount(int count);

  /// The export's file format.
  ///
  /// In en, this message translates to:
  /// **'Project package (.zip)'**
  String get exportFileFormat;

  /// What the package holds, for another Tapture app and for a reader.
  ///
  /// In en, this message translates to:
  /// **'Everything another Tapture app needs to open this project: records, photos, audio, templates, context, reference data and project settings, with a workbook of the records. Unsaved capture drafts stay on this device.'**
  String get exportFileColumns;

  /// How big the package is expected to be, before it is written.
  ///
  /// In en, this message translates to:
  /// **'About {fileSizebytes}'**
  String exportPackageSize(Object fileSizebytes);

  /// Where the export file is saved: the Exports folder under [place], the
  ///    short Downloads label.
  ///
  /// In en, this message translates to:
  /// **'Saved to {place} › Exports'**
  String exportSavedTo(Object place);

  /// Shown while the workbook is written.
  ///
  /// In en, this message translates to:
  /// **'Writing the export'**
  String get projectExportProgress;

  /// Stops an export before a file is kept.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get projectExportCancel;

  /// Edits one captured record.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get recordEdit;

  /// Label of the optional project photo on the create and edit screens.
  ///
  /// In en, this message translates to:
  /// **'Project photo (optional)'**
  String get projectPhoto;

  /// Picks a photo for a project that has none.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get projectPhotoAdd;

  /// Picks another photo for a project that has one.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get projectPhotoChange;

  /// Takes the photo off a project.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get projectPhotoRemove;

  /// Title of the page that edits a saved record's photos and captions.
  ///
  /// In en, this message translates to:
  /// **'Edit record'**
  String get recordEditTitle;

  /// Saves an edited record's photos, captions and audio.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get recordEditSave;

  /// Confirms an edited record was saved.
  ///
  /// In en, this message translates to:
  /// **'Record updated.'**
  String get recordEditSaved;

  /// Edit sheet for a record with nothing to edit.
  ///
  /// In en, this message translates to:
  /// **'No fields to edit'**
  String get recordEditNoFieldsHeadline;

  /// What to do when a record has no editable field.
  ///
  /// In en, this message translates to:
  /// **'Add fields to this record\'\'s template, then edit the record here.'**
  String get recordEditNoFieldsMessage;

  /// Archives one captured record. The photos stay on the device.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get recordDelete;

  /// Confirm copy for archiving a captured record.
  ///
  /// In en, this message translates to:
  /// **'The photos stay on this device. The record leaves this list.'**
  String get recordArchiveMessage;

  /// Title of a record's page when no value names it.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordDetailTitle;

  /// A record with no caption, on its page.
  ///
  /// In en, this message translates to:
  /// **'No caption'**
  String get recordNoCaption;

  /// A template field the record holds no value for.
  ///
  /// In en, this message translates to:
  /// **'Not entered'**
  String get recordFieldEmpty;

  /// Record page section: its field values.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get recordSectionFields;

  /// Opens the template-field editor from a record's page.
  ///
  /// In en, this message translates to:
  /// **'Edit fields'**
  String get recordEditFields;

  /// When a record was captured. [when] is a locale-formatted date and time.
  ///
  /// In en, this message translates to:
  /// **'Captured {when}'**
  String recordCapturedAt(Object when);

  /// A record's page after it was deleted elsewhere.
  ///
  /// In en, this message translates to:
  /// **'This record is no longer here'**
  String get recordGoneHeadline;

  /// What to do when a record's page has nothing to show.
  ///
  /// In en, this message translates to:
  /// **'It was deleted or is not on this device. Go back to the list.'**
  String get recordGoneMessage;

  /// Primary action on the open-project home when a record already exists.
  ///
  /// In en, this message translates to:
  /// **'Continue capturing'**
  String get continueCapturing;

  /// Home primary action before the first record.
  ///
  /// In en, this message translates to:
  /// **'Start capturing'**
  String get captureStart;

  /// Primary project-home action when the project has no templates.
  ///
  /// In en, this message translates to:
  /// **'Add template'**
  String get projectAddTemplate;

  /// Secondary project-home action to capture evidence before adding a template.
  ///
  /// In en, this message translates to:
  /// **'Capture now'**
  String get projectCaptureNow;

  /// Nonselectable project menu heading above transcription, meetings and quality summary.
  ///
  /// In en, this message translates to:
  /// **'Capture and review'**
  String get projectMenuCaptureReview;

  /// Nonselectable project menu heading above templates, datasets and context configuration.
  ///
  /// In en, this message translates to:
  /// **'Project setup'**
  String get projectMenuSetup;

  /// Nonselectable project menu heading above export, package merging and opening in another app.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get projectMenuExchange;

  /// Nonselectable project menu heading above project details, settings and lifecycle actions.
  ///
  /// In en, this message translates to:
  /// **'Manage project'**
  String get projectMenuManage;

  /// Home primary action after at least one record.
  ///
  /// In en, this message translates to:
  /// **'Capture more'**
  String get captureMore;

  /// Headline when the project home has no open project.
  ///
  /// In en, this message translates to:
  /// **'No project open'**
  String get homeEmptyHeadline;

  /// Body when the project home has no open project.
  ///
  /// In en, this message translates to:
  /// **'Open a project to see what to do next.'**
  String get homeEmptyMessage;

  /// Shell destination: capture. Visually dominant in the four-destination bar.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get navCapture;

  /// Shell destination: the records list.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get navRecords;

  /// Shell destination: settings and the rest.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navMore;

  /// Compact navigation control opening secondary destinations.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMoreMenu;

  /// Pinned-template destination the status line opens.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get navTemplates;

  /// Project-scoped template list. The app-wide list keeps [navTemplates].
  ///
  /// In en, this message translates to:
  /// **'Project templates'**
  String get projectTemplatesTitle;

  /// Project datasets destination.
  ///
  /// In en, this message translates to:
  /// **'Datasets'**
  String get navDatasets;

  /// Headline when a project has no reference datasets.
  ///
  /// In en, this message translates to:
  /// **'No datasets yet'**
  String get datasetsEmptyHeadline;

  /// Body when the dataset list is empty.
  ///
  /// In en, this message translates to:
  /// **'Import a CSV, spreadsheet or JSON table to prefill capture fields.'**
  String get datasetsEmptyMessage;

  /// Empty-state / primary action that starts an import.
  ///
  /// In en, this message translates to:
  /// **'Import dataset'**
  String get datasetsImport;

  /// Title of the key-column confirmation screen.
  ///
  /// In en, this message translates to:
  /// **'Choose the key column'**
  String get datasetsKeyTitle;

  /// Explains the key-column choice.
  ///
  /// In en, this message translates to:
  /// **'The key uniquely identifies each row for lookup.'**
  String get datasetsKeyMessage;

  /// Confirms saving despite duplicate keys.
  ///
  /// In en, this message translates to:
  /// **'Save with duplicates'**
  String get datasetsAllowDuplicates;

  /// Saves the import after a unique key is chosen.
  ///
  /// In en, this message translates to:
  /// **'Save dataset'**
  String get datasetsSaveImport;

  /// Duplicate-key warning with count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 duplicate key value} other{{count} duplicate key values}}'**
  String datasetsDuplicateCount(int count);

  /// Sample colliding values.
  ///
  /// In en, this message translates to:
  /// **'Examples: {valuesjoin}'**
  String datasetsCollidingValues(Object valuesjoin);

  /// List subtitle: rows · source · date. [importedAt] is shown in local time.
  ///
  /// In en, this message translates to:
  /// **'{datasetsRowCountrows} · {source} · {dateFormatyMMMdformat}'**
  String datasetListSubtitle(
    Object datasetsRowCountrows,
    Object source,
    Object dateFormatyMMMdformat,
  );

  /// How many rows a dataset holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 row} other{{count} rows}}'**
  String datasetsRowCount(int count);

  /// Dataset source label.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get datasetSourceLabel;

  /// Dataset source label.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet'**
  String get datasetSourceLabelSpreadsheet;

  /// Dataset source label.
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get datasetSourceLabelJSON;

  /// Dataset source label.
  ///
  /// In en, this message translates to:
  /// **'On device'**
  String get datasetSourceLabelOnDevice;

  /// Browser search hint.
  ///
  /// In en, this message translates to:
  /// **'Search rows'**
  String get datasetsSearchHint;

  /// Choose visible columns on a narrow screen.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get datasetsColumns;

  /// Row edit title.
  ///
  /// In en, this message translates to:
  /// **'Edit row'**
  String get datasetsEditRow;

  /// Save row edits.
  ///
  /// In en, this message translates to:
  /// **'Save row'**
  String get datasetsSaveRow;

  /// Add-row sheet title.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get datasetsAddRow;

  /// Lookup picker title.
  ///
  /// In en, this message translates to:
  /// **'Choose a match'**
  String get datasetsPickMatch;

  /// Lookup binding screen title.
  ///
  /// In en, this message translates to:
  /// **'Lookup binding'**
  String get datasetsLookupBinding;

  /// Save lookup binding.
  ///
  /// In en, this message translates to:
  /// **'Save binding'**
  String get datasetsSaveBinding;

  /// No datasets available for binding.
  ///
  /// In en, this message translates to:
  /// **'No datasets in this project'**
  String get datasetsBindingEmptyHeadline;

  /// Binding empty body.
  ///
  /// In en, this message translates to:
  /// **'Import a dataset before binding this field.'**
  String get datasetsBindingEmptyMessage;

  /// Fuzzy matching switch.
  ///
  /// In en, this message translates to:
  /// **'Allow fuzzy matches'**
  String get datasetsFuzzyEnabled;

  /// No-match behaviour label.
  ///
  /// In en, this message translates to:
  /// **'When nothing matches'**
  String get datasetsOnNoMatch;

  /// Mark a row added on device in the browser.
  ///
  /// In en, this message translates to:
  /// **'Added on device'**
  String get datasetsAddedOnDevice;

  /// Export dataset action.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get datasetsExport;

  /// Headline when the dataset browser has no rows.
  ///
  /// In en, this message translates to:
  /// **'No rows'**
  String get datasetsBrowserEmptyHeadline;

  /// Body when the dataset browser has no rows.
  ///
  /// In en, this message translates to:
  /// **'This dataset has no rows to show.'**
  String get datasetsBrowserEmptyMessage;

  /// Headline when a dataset search or lookup matches no row.
  ///
  /// In en, this message translates to:
  /// **'No matching rows'**
  String get datasetsNoMatchHeadline;

  /// Body when a dataset search matches no row.
  ///
  /// In en, this message translates to:
  /// **'No row matches that search. Clear it to see every row.'**
  String get datasetsNoMatchMessage;

  /// Body when a lookup finds no row to pick.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this dataset matches. The typed value stays as it is.'**
  String get datasetsPickNoMatchMessage;

  /// Clears the dataset search.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get datasetsClearSearch;

  /// Headline when no project is open for a dataset screen.
  ///
  /// In en, this message translates to:
  /// **'Open a project first'**
  String get datasetsNoProjectHeadline;

  /// Body when no project is open for a dataset screen.
  ///
  /// In en, this message translates to:
  /// **'Datasets belong to a project. Open one to import or browse its tables.'**
  String get datasetsNoProjectMessage;

  /// Key-screen headline before a file is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a table to import'**
  String get datasetsPickHeadline;

  /// Key-screen body before a file is chosen.
  ///
  /// In en, this message translates to:
  /// **'Pick a CSV, spreadsheet or JSON file. You choose its key column next.'**
  String get datasetsPickMessage;

  /// Starts choosing a table file.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get datasetsPickFile;

  /// Progress step while a table file is read.
  ///
  /// In en, this message translates to:
  /// **'Reading the table'**
  String get datasetsReading;

  /// How much of a table file has been read.
  ///
  /// In en, this message translates to:
  /// **'{percent}% read'**
  String datasetsReadProgress(int percent);

  /// A key-column row: its duplicate count and first values.
  ///
  /// In en, this message translates to:
  /// **'{count} · {shown}'**
  String datasetsColumnSummary(Object count, Object shown);

  /// Warning under a non-unique key: the count, the colliding values and
  ///    the way forward.
  ///
  /// In en, this message translates to:
  /// **' {datasetsCollidingValuescolliding}.'**
  String datasetsDuplicateWarning(Object datasetsCollidingValuescolliding);

  /// Warning under a non-unique key: the count, the colliding values and
  ///    the way forward.
  ///
  /// In en, this message translates to:
  /// **'{datasetsDuplicateCountn}.{values} Pick another key column, or save the dataset with duplicates.'**
  String datasetsDuplicateWarningPickAnotherKeyColumn(
    Object datasetsDuplicateCountn,
    Object values,
  );

  /// Confirm heading before a dataset with duplicate keys is saved.
  ///
  /// In en, this message translates to:
  /// **'Save with duplicate keys?'**
  String get datasetsDuplicatesConfirmTitle;

  /// Confirm body naming the key column and how many values repeat.
  ///
  /// In en, this message translates to:
  /// **'The key column {column} has {datasetsDuplicateCountn}. A lookup on a repeated key asks which row to use.'**
  String datasetsDuplicatesConfirm(
    Object column,
    Object datasetsDuplicateCountn,
  );

  /// Browser action: export the dataset as CSV.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get datasetsExportCsv;

  /// Browser action: export the dataset as JSON.
  ///
  /// In en, this message translates to:
  /// **'Export as JSON'**
  String get datasetsExportJson;

  /// Shown while a dataset export is written.
  ///
  /// In en, this message translates to:
  /// **'Exporting the dataset'**
  String get datasetsExporting;

  /// Label of the visible-columns choice.
  ///
  /// In en, this message translates to:
  /// **'Columns to show'**
  String get datasetsVisibleColumns;

  /// Headline when a browsed dataset is no longer stored.
  ///
  /// In en, this message translates to:
  /// **'Dataset not found'**
  String get datasetsMissingHeadline;

  /// Body when a browsed dataset is no longer stored.
  ///
  /// In en, this message translates to:
  /// **'This dataset is no longer on this device.'**
  String get datasetsMissingMessage;

  /// Export refused because no project is open to write it into.
  ///
  /// In en, this message translates to:
  /// **'Open a project before exporting this dataset.'**
  String get datasetsExportNoProject;

  /// What to do when no project is open for an export.
  ///
  /// In en, this message translates to:
  /// **'Open the project and try again.'**
  String get datasetsExportNoProjectRecovery;

  /// Headline when an edited row is no longer stored.
  ///
  /// In en, this message translates to:
  /// **'Row not found'**
  String get datasetsRowMissingHeadline;

  /// Body when an edited row is no longer stored.
  ///
  /// In en, this message translates to:
  /// **'This row is no longer in the dataset.'**
  String get datasetsRowMissingMessage;

  /// Headline when the add-row sheet has no dataset to add to.
  ///
  /// In en, this message translates to:
  /// **'No dataset bound'**
  String get datasetsAddRowNoDatasetHeadline;

  /// Body when the add-row sheet has no dataset to add to.
  ///
  /// In en, this message translates to:
  /// **'Bind this field to a dataset before adding rows from capture.'**
  String get datasetsAddRowNoDatasetMessage;

  /// A lookup fill target the template does not define.
  ///
  /// In en, this message translates to:
  /// **'Unknown fill target \"{target}\".'**
  String lookupUnknownTarget(Object target);

  /// A lookup fill target two dataset columns write.
  ///
  /// In en, this message translates to:
  /// **'Fill target \"{target}\" is mapped more than once.'**
  String lookupTargetTwice(Object target);

  /// Binding screen: pick a dataset before saving.
  ///
  /// In en, this message translates to:
  /// **'Pick a dataset before saving the binding.'**
  String get lookupPickDataset;

  /// An imported template whose lookup cannot be accepted.
  ///
  /// In en, this message translates to:
  /// **'Fix the lookup fills in the template file and import it again.'**
  String get lookupImportRecovery;

  /// Binding screen: one dataset column chosen for two fields.
  ///
  /// In en, this message translates to:
  /// **'Column \"{column}\" is chosen for two fields. Pick one field for it.'**
  String lookupColumnTwice(Object column);

  /// Binding screen: a fuzzy threshold as a percentage.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String lookupThresholdLabel(int percent);

  /// Binding screen: the dataset's key column.
  ///
  /// In en, this message translates to:
  /// **'Key column'**
  String get lookupKeyColumn;

  /// Binding screen: the ordered match columns.
  ///
  /// In en, this message translates to:
  /// **'Match on'**
  String get lookupMatchColumns;

  /// Binding screen: the order match columns are tried in.
  ///
  /// In en, this message translates to:
  /// **'The key column only'**
  String get lookupMatchOrder;

  /// Binding screen: a template field no dataset column fills.
  ///
  /// In en, this message translates to:
  /// **'Not filled'**
  String get lookupNotFilled;

  /// Binding screen: heading over the fill mapping.
  ///
  /// In en, this message translates to:
  /// **'Fill these fields'**
  String get lookupFills;

  /// Binding screen: the lowest fuzzy score offered, in percent.
  ///
  /// In en, this message translates to:
  /// **'Suggest matches scoring at least'**
  String get lookupFuzzyThreshold;

  /// Binding screen: saving turns the field into a lookup field.
  ///
  /// In en, this message translates to:
  /// **'Saving makes this field a lookup field.'**
  String get lookupBecomesLookup;

  /// Binding screen: the field is no longer on the template.
  ///
  /// In en, this message translates to:
  /// **'Field not found'**
  String get lookupFieldMissingHeadline;

  /// Binding screen: body when the field is no longer on the template.
  ///
  /// In en, this message translates to:
  /// **'This field is no longer on the template.'**
  String get lookupFieldMissingMessage;

  /// No-match behaviour: leave the bound fields empty.
  ///
  /// In en, this message translates to:
  /// **'Leave empty'**
  String get lookupNoMatchLeaveEmpty;

  /// No-match behaviour: offer to add a row.
  ///
  /// In en, this message translates to:
  /// **'Offer to add a row'**
  String get lookupNoMatchPromptAdd;

  /// No-match behaviour: warn only.
  ///
  /// In en, this message translates to:
  /// **'Warn'**
  String get lookupNoMatchWarn;

  /// Field editor entry that opens the lookup binding.
  ///
  /// In en, this message translates to:
  /// **'Bind to dataset'**
  String get templatesBindDataset;

  /// Headline when the template list is empty.
  ///
  /// In en, this message translates to:
  /// **'No templates yet'**
  String get templatesEmptyHeadline;

  /// Body when the template list is empty. The next action is the library.
  ///
  /// In en, this message translates to:
  /// **'Pick a shipped template to start capturing, or create a blank template.'**
  String get templatesEmptyMessage;

  /// Empty-state action that opens the shipped-library picker.
  ///
  /// In en, this message translates to:
  /// **'Pick a shipped template'**
  String get templatesPickLibrary;

  /// Primary action that opens the blank-template form.
  ///
  /// In en, this message translates to:
  /// **'Create a blank template'**
  String get templatesCreate;

  /// Renames a template from its row menu.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get templatesEdit;

  /// Opens upload and library choices on the template list.
  ///
  /// In en, this message translates to:
  /// **'Add templates'**
  String get templatesAddChoices;

  /// The add action once the project already has a template.
  ///
  /// In en, this message translates to:
  /// **'Add more templates'**
  String get templatesAddMore;

  /// Empty project template list. The add action sits in the footer.
  ///
  /// In en, this message translates to:
  /// **'Add templates to start capturing. Create a blank template when none fits.'**
  String get templatesAddEmptyMessage;

  /// Uploads a template file.
  ///
  /// In en, this message translates to:
  /// **'Upload a template'**
  String get templatesUpload;

  /// Attaches a template that already exists.
  ///
  /// In en, this message translates to:
  /// **'Use an existing template'**
  String get templatesUseExisting;

  /// Search on the template list matched nothing.
  ///
  /// In en, this message translates to:
  /// **'No matching templates'**
  String get templatesNoMatch;

  /// Title of the template list's filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Template filters'**
  String get templateFiltersTitle;

  /// The template-kind facet of the template list's filters.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get templateKindFilter;

  /// A template that names no kind, as a filter option.
  ///
  /// In en, this message translates to:
  /// **'No kind'**
  String get templateKindNone;

  /// Search on the field list matched nothing.
  ///
  /// In en, this message translates to:
  /// **'No matching fields'**
  String get fieldsNoMatch;

  /// Title of a template field list's filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Field filters'**
  String get fieldFiltersTitle;

  /// The required, recommended or optional facet of the field filters.
  ///
  /// In en, this message translates to:
  /// **'Requirement'**
  String get fieldRequirednessFilter;

  /// How a project chooses a template when capture starts.
  ///
  /// In en, this message translates to:
  /// **'Template choice'**
  String get templateChoiceLabel;

  /// Use the only template, and ask when there are several.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get templateChoiceAuto;

  /// Suggest a template and let the operator confirm.
  ///
  /// In en, this message translates to:
  /// **'Suggest'**
  String get templateChoiceSuggest;

  /// Always ask which template to use.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get templateChoiceManual;

  /// Title of the blank-template form.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get templatesCreateTitle;

  /// Opens the field list for a template.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get templatesOpen;

  /// Overflow command that writes a template out. Task 100 owns the screen.
  ///
  /// In en, this message translates to:
  /// **'Export template'**
  String get templatesExport;

  /// Overflow command that reads a template JSON into this project.
  ///
  /// In en, this message translates to:
  /// **'Import template'**
  String get templatesImport;

  /// Empty import destination: no file was given.
  ///
  /// In en, this message translates to:
  /// **'No template file'**
  String get templatesImportEmptyHeadline;

  /// Empty import destination explanation.
  ///
  /// In en, this message translates to:
  /// **'Choose a template file to add it to this project.'**
  String get templatesImportEmptyMessage;

  /// Rejected because schema_version is missing or not this app's version.
  ///
  /// In en, this message translates to:
  /// **'That template file uses a schema this app does not read.'**
  String get templatesImportUnknownSchema;

  /// Recovery for an unknown schema version.
  ///
  /// In en, this message translates to:
  /// **'Export the template again from this version of Tapture.'**
  String get templatesImportUnknownSchemaRecovery;

  /// Rejected because the JSON is not a template object.
  ///
  /// In en, this message translates to:
  /// **'That file is not a template.'**
  String get templatesImportInvalid;

  /// Recovery for an invalid template JSON.
  ///
  /// In en, this message translates to:
  /// **'Choose a template file and try again.'**
  String get templatesImportInvalidRecovery;

  /// Rejected because two fields share a key.
  ///
  /// In en, this message translates to:
  /// **'Each field key must be unique on a template.'**
  String get templatesImportDuplicateField;

  /// Recovery for a duplicate field key.
  ///
  /// In en, this message translates to:
  /// **'Rename the duplicate key and export again.'**
  String get templatesImportDuplicateFieldRecovery;

  /// The chosen spreadsheet is encrypted.
  ///
  /// In en, this message translates to:
  /// **'That spreadsheet is locked with a password.'**
  String get workbookPassword;

  /// Recovery for a password-protected spreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Unlock it, save a copy, and choose the copy.'**
  String get workbookPasswordRecovery;

  /// The chosen spreadsheet could not be parsed.
  ///
  /// In en, this message translates to:
  /// **'That spreadsheet could not be read.'**
  String get workbookCorrupt;

  /// Recovery for a corrupt spreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Keep the original. Export a copy and try again.'**
  String get workbookCorruptRecovery;

  /// Title of the spreadsheet column-mapping screen.
  ///
  /// In en, this message translates to:
  /// **'Map columns'**
  String get xlsxMappingTitle;

  /// Headline when no spreadsheet was given.
  ///
  /// In en, this message translates to:
  /// **'No spreadsheet'**
  String get xlsxMappingEmptyHeadline;

  /// Body when the mapping screen has no file to read.
  ///
  /// In en, this message translates to:
  /// **'Choose a spreadsheet to map its columns onto a template.'**
  String get xlsxMappingEmptyMessage;

  /// Primary action that creates the template from the confirmed mapping.
  ///
  /// In en, this message translates to:
  /// **'Create template'**
  String get xlsxMappingConfirm;

  /// Overflow command that omits one spreadsheet column.
  ///
  /// In en, this message translates to:
  /// **'Skip this column'**
  String get xlsxMappingSkip;

  /// Overflow command that brings a skipped column back.
  ///
  /// In en, this message translates to:
  /// **'Include this column'**
  String get xlsxMappingInclude;

  /// Subtitle when the operator has skipped a column.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get xlsxMappingSkipped;

  /// Proposed field shown on the right of a mapping row.
  ///
  /// In en, this message translates to:
  /// **'{field} · {type} · {rule}'**
  String xlsxMappingProposal(Object field, Object type, Object rule);

  /// Proposed label when a spreadsheet column has no header.
  ///
  /// In en, this message translates to:
  /// **'Column {column}'**
  String xlsxMappingUntitled(Object column);

  /// Template name when the sheet tab is blank.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet'**
  String get xlsxMappingDefaultName;

  /// The chosen spreadsheet vanished before confirm.
  ///
  /// In en, this message translates to:
  /// **'That spreadsheet is no longer on this device.'**
  String get xlsxMappingMissing;

  /// Recovery when the chosen spreadsheet is missing.
  ///
  /// In en, this message translates to:
  /// **'Choose the spreadsheet again, then try again.'**
  String get xlsxMappingMissingRecovery;

  /// A copy of this name is already in the project templates folder.
  ///
  /// In en, this message translates to:
  /// **'A copy of that spreadsheet is already in this project.'**
  String get xlsxMappingExists;

  /// Recovery when the destination copy already exists.
  ///
  /// In en, this message translates to:
  /// **'Rename the spreadsheet, then try again.'**
  String get xlsxMappingExistsRecovery;

  /// Title of the per-row aliases screen.
  ///
  /// In en, this message translates to:
  /// **'Row aliases'**
  String get rowAliasesTitle;

  /// Headline when the template has no checklist rows to name.
  ///
  /// In en, this message translates to:
  /// **'No rows to name'**
  String get rowAliasesEmptyHeadline;

  /// Body when the aliases list is empty.
  ///
  /// In en, this message translates to:
  /// **'Import spreadsheet rows first, then add the local names that should match them.'**
  String get rowAliasesEmptyMessage;

  /// Field label for a row's aliases.
  ///
  /// In en, this message translates to:
  /// **'Aliases'**
  String get rowAliasesField;

  /// Hint showing how local names are written.
  ///
  /// In en, this message translates to:
  /// **'BP machine, BP'**
  String get rowAliasesHint;

  /// Overflow command that reads aliases from one spreadsheet column.
  ///
  /// In en, this message translates to:
  /// **'Import from a column'**
  String get rowAliasesImport;

  /// Field label for the alias column letter.
  ///
  /// In en, this message translates to:
  /// **'Alias column'**
  String get rowAliasesColumn;

  /// Refuses a letter that does not name a column in the selected workbook.
  ///
  /// In en, this message translates to:
  /// **'That column is not in the spreadsheet.'**
  String get rowAliasesInvalidColumn;

  /// Recovery for an invalid alias column letter.
  ///
  /// In en, this message translates to:
  /// **'Enter a column letter shown in the spreadsheet.'**
  String get rowAliasesInvalidColumnRecovery;

  /// Stated absence when a row has no aliases yet.
  ///
  /// In en, this message translates to:
  /// **'No aliases yet'**
  String get rowAliasesNone;

  /// Title of the capture checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklistTitle;

  /// Spreadsheet column that identifies one predefined checklist row.
  ///
  /// In en, this message translates to:
  /// **'Identifier column'**
  String get checklistIdentifierColumn;

  /// Spreadsheet column that names one predefined checklist row.
  ///
  /// In en, this message translates to:
  /// **'Label column'**
  String get checklistLabelColumn;

  /// Spreadsheet column that groups checklist rows by place or context.
  ///
  /// In en, this message translates to:
  /// **'Context column'**
  String get checklistContextColumn;

  /// Opens workbook mapping for an existing template's checklist.
  ///
  /// In en, this message translates to:
  /// **'Import rows'**
  String get checklistImportRows;

  /// A checklist requires both identifying and display columns.
  ///
  /// In en, this message translates to:
  /// **'Choose an identifier and a label column.'**
  String get checklistMappingIncomplete;

  /// Recovery when a checklist mapping is incomplete.
  ///
  /// In en, this message translates to:
  /// **'Confirm both columns before importing the rows.'**
  String get checklistMappingRecovery;

  /// Headline when the template has no predefined rows.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the checklist'**
  String get checklistEmptyHeadline;

  /// Body when the checklist is empty.
  ///
  /// In en, this message translates to:
  /// **'Import spreadsheet rows to see what is still missing.'**
  String get checklistEmptyMessage;

  /// Status word for a row that has been found.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get checklistFound;

  /// Status word for a row that is still missing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get checklistMissing;

  /// Group name when a row has no room or context.
  ///
  /// In en, this message translates to:
  /// **'Ungrouped'**
  String get checklistUngrouped;

  /// Group heading: the room name and how many rows have been found.
  ///
  /// In en, this message translates to:
  /// **'{group} · Found {found} of {total}'**
  String checklistProgress(Object group, int found, int total);

  /// Title of the detection-profile screen.
  ///
  /// In en, this message translates to:
  /// **'Detection'**
  String get detectionProfileTitle;

  /// What the detection profile decides.
  ///
  /// In en, this message translates to:
  /// **'A photo is matched to this template from these signals. A negative keyword rules it out.'**
  String get detectionProfileExplain;

  /// Headline when no template is open.
  ///
  /// In en, this message translates to:
  /// **'No template to configure'**
  String get detectionProfileEmptyHeadline;

  /// Body when the detection screen has no template.
  ///
  /// In en, this message translates to:
  /// **'Open a template first, then set how a photo is matched to it.'**
  String get detectionProfileEmptyMessage;

  /// Field label for vision object classes.
  ///
  /// In en, this message translates to:
  /// **'Object classes'**
  String get detectionProfileClasses;

  /// Field label for OCR keywords.
  ///
  /// In en, this message translates to:
  /// **'Keywords'**
  String get detectionProfileKeywords;

  /// Section for identifier patterns reused from field validation.
  ///
  /// In en, this message translates to:
  /// **'Identifier patterns'**
  String get detectionProfilePatterns;

  /// Section for datasets already bound on lookup fields.
  ///
  /// In en, this message translates to:
  /// **'Linked datasets'**
  String get detectionProfileDatasets;

  /// Field label for keywords that exclude this template.
  ///
  /// In en, this message translates to:
  /// **'Negative keywords'**
  String get detectionProfileNegative;

  /// Hint on a comma-separated signal list.
  ///
  /// In en, this message translates to:
  /// **'Separate with a comma'**
  String get detectionProfileHint;

  /// Shown when no field has a validation pattern to reuse.
  ///
  /// In en, this message translates to:
  /// **'Identifier patterns come from field validation. Add a pattern on a field first.'**
  String get detectionProfileNoPatterns;

  /// Shown when no lookup field names a dataset.
  ///
  /// In en, this message translates to:
  /// **'Linked datasets come from lookup fields. Bind a lookup first.'**
  String get detectionProfileNoDatasets;

  /// The template vanished before the profile was saved.
  ///
  /// In en, this message translates to:
  /// **'That template is no longer on this device.'**
  String get detectionProfileMissing;

  /// Recovery when the template is missing.
  ///
  /// In en, this message translates to:
  /// **'Open the template list and try again.'**
  String get detectionProfileMissingRecovery;

  /// Soft-deletes a template no record uses.
  ///
  /// In en, this message translates to:
  /// **'Delete template'**
  String get templatesDelete;

  /// Title of the delete confirmation, naming the template.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String templatesDeleteTitle(Object name);

  /// Body of the delete confirmation, naming field and record counts.
  ///
  /// In en, this message translates to:
  /// **'This hides {fieldsCountfields}. {recordsCountrecords} stay on this template.'**
  String templatesDeleteMessage(
    Object fieldsCountfields,
    Object recordsCountrecords,
  );

  /// Field-list destination after create, duplicate or open. Task 094 owns it.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get templateFieldsTitle;

  /// Primary action that opens the add-field flow. Task 095 owns the sheet.
  ///
  /// In en, this message translates to:
  /// **'Add a field'**
  String get templatesAddField;

  /// Heading of one field row on the new-template page.
  ///
  /// In en, this message translates to:
  /// **'Field {n}'**
  String templateFieldRowTitle(int n);

  /// Removes one field row from the new-template page.
  ///
  /// In en, this message translates to:
  /// **'Remove this field'**
  String get templateFieldRowRemove;

  /// Opens the editor for one field. Task 095 owns the sheet.
  ///
  /// In en, this message translates to:
  /// **'Edit field'**
  String get templatesEditField;

  /// Removes a field from the template and retires its values.
  ///
  /// In en, this message translates to:
  /// **'Delete field'**
  String get templatesDeleteField;

  /// Title of the field-delete confirmation, naming the field.
  ///
  /// In en, this message translates to:
  /// **'Delete {label}?'**
  String templatesDeleteFieldTitle(Object label);

  /// Body of the field-delete confirmation, naming the value count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No records hold a value. The field leaves this template. Existing values stay and export as retired.} one{1 record holds a value. That value stays and exports as retired.} other{{count} records hold a value. Those values stay and export as retired.}}'**
  String templatesDeleteFieldMessage(int count);

  /// Headline when a template has no fields.
  ///
  /// In en, this message translates to:
  /// **'No fields yet'**
  String get templatesFieldsEmptyHeadline;

  /// Body when the field list is empty. The next action is adding one.
  ///
  /// In en, this message translates to:
  /// **'Add a field so this template can capture.'**
  String get templatesFieldsEmptyMessage;

  /// REQUIRED badge on a field row.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// Field filled by a calculation.
  ///
  /// In en, this message translates to:
  /// **'Calculated'**
  String get fieldCalculated;

  /// Field the detection profile can fill from a photo.
  ///
  /// In en, this message translates to:
  /// **'From photos'**
  String get fieldFromPhotos;

  /// Field-list subtitle: type, then any of required, calculated, from photos.
  ///
  /// In en, this message translates to:
  /// **'Context level {contextLevel}'**
  String fieldRowSubtitle(Object contextLevel);

  /// Field-list subtitle: type, then any of required, calculated, from photos.
  ///
  /// In en, this message translates to:
  /// **'Pinned context'**
  String get fieldRowSubtitlePinnedContext;

  /// The value a field takes when nothing fills it, on its field row.
  ///
  /// In en, this message translates to:
  /// **'Default: {value}'**
  String fieldRowDefault(Object value);

  /// RECOMMENDED badge on a field row.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get fieldRecommended;

  /// OPTIONAL badge on a field row.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get fieldOptional;

  /// Moves [label] one place earlier in capture and export order.
  ///
  /// In en, this message translates to:
  /// **'Move {label} up'**
  String fieldMoveUp(Object label);

  /// Moves [label] one place later in capture and export order.
  ///
  /// In en, this message translates to:
  /// **'Move {label} down'**
  String fieldMoveDown(Object label);

  /// Drag handle that reorders [label].
  ///
  /// In en, this message translates to:
  /// **'Reorder {label}'**
  String fieldReorder(Object label);

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get fieldTypeLabel;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Long text'**
  String get fieldTypeLabelLongText;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get fieldTypeLabelNumber;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Decimal'**
  String get fieldTypeLabelDecimal;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get fieldTypeLabelCurrency;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get fieldTypeLabelPercentage;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldTypeLabelDate;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get fieldTypeLabelTime;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get fieldTypeLabelDateAndTime;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Boolean'**
  String get fieldTypeLabelBoolean;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Choice'**
  String get fieldTypeLabelChoice;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Multi-choice'**
  String get fieldTypeLabelMultiChoice;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Lookup'**
  String get fieldTypeLabelLookup;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get fieldTypeLabelBarcode;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Photo reference'**
  String get fieldTypeLabelPhotoReference;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Document reference'**
  String get fieldTypeLabelDocumentReference;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'GPS location'**
  String get fieldTypeLabelGPSLocation;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get fieldTypeLabelSignature;

  /// Operator-facing name of a §12.1 field type.
  ///
  /// In en, this message translates to:
  /// **'Computed'**
  String get fieldTypeLabelComputed;

  /// Label of the field being added or edited. Template content follows.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get fieldLabel;

  /// Type picker on the add-field sheet.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fieldType;

  /// Three-way requiredness question on the add-field sheet.
  ///
  /// In en, this message translates to:
  /// **'Required?'**
  String get fieldRequiredness;

  /// Collapsed section that holds every §12.2 attribute the add flow defaults.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get fieldAdvanced;

  /// Reveals the collapsed Advanced section.
  ///
  /// In en, this message translates to:
  /// **'Show advanced'**
  String get fieldAdvancedShow;

  /// Hides the Advanced section again.
  ///
  /// In en, this message translates to:
  /// **'Hide advanced'**
  String get fieldAdvancedHide;

  /// Lets the user keep a two-fact label after the warning.
  ///
  /// In en, this message translates to:
  /// **'Keep anyway'**
  String get fieldKeepAnyway;

  /// Warns that a label packs two facts (§13.1) without blocking the save.
  ///
  /// In en, this message translates to:
  /// **'This label packs two facts. Split it into two fields, or keep this one anyway.'**
  String get fieldTwoFactsWarning;

  /// Default written when the operator leaves the field empty.
  ///
  /// In en, this message translates to:
  /// **'Default value'**
  String get fieldDefaultValue;

  /// Displayed and exported unit, for example kg.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get fieldUnit;

  /// One short line of guidance shown under the field.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get fieldHelp;

  /// Who may write the field.
  ///
  /// In en, this message translates to:
  /// **'Who may fill it'**
  String get fieldInputMode;

  /// [InputMode.any].
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get fieldInputAny;

  /// [InputMode.manualOnly].
  ///
  /// In en, this message translates to:
  /// **'A person only'**
  String get fieldInputManual;

  /// [InputMode.aiAllowed].
  ///
  /// In en, this message translates to:
  /// **'AI may propose'**
  String get fieldInputAi;

  /// [InputMode.auto].
  ///
  /// In en, this message translates to:
  /// **'Filled by the app'**
  String get fieldInputAuto;

  /// Whether the field may be pinned as context.
  ///
  /// In en, this message translates to:
  /// **'Pin as context'**
  String get fieldStickable;

  /// Context hierarchy level, when this field is a level of that hierarchy.
  ///
  /// In en, this message translates to:
  /// **'Context level'**
  String get fieldContextLevel;

  /// System fill source.
  ///
  /// In en, this message translates to:
  /// **'Fill automatically'**
  String get fieldAutoFill;

  /// No automatic fill.
  ///
  /// In en, this message translates to:
  /// **'Do not fill'**
  String get fieldAutoFillNone;

  /// Operator-facing name of an [AutoFill] source.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get fieldAutoFillLabel;

  /// Operator-facing name of an [AutoFill] source.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get fieldAutoFillLabelToday;

  /// Operator-facing name of an [AutoFill] source.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get fieldAutoFillLabelTimeOfDay;

  /// Operator-facing name of an [AutoFill] source.
  ///
  /// In en, this message translates to:
  /// **'Next in sequence'**
  String get fieldAutoFillLabelNextInSequence;

  /// Operator-facing name of an [AutoFill] source.
  ///
  /// In en, this message translates to:
  /// **'Signed-in operator'**
  String get fieldAutoFillLabelSignedInOperator;

  /// Operator-facing name of an [AutoFill] source.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get fieldAutoFillLabelThisDevice;

  /// Operator-facing name of an [AutoFill] source.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get fieldAutoFillLabelCurrentLocation;

  /// Operator-facing name of an [AutoFill] source.
  ///
  /// In en, this message translates to:
  /// **'Pinned context'**
  String get fieldAutoFillLabelPinnedContext;

  /// Store an AI-refined companion beside the raw value.
  ///
  /// In en, this message translates to:
  /// **'Store a refined companion'**
  String get fieldRefine;

  /// Whether the field participates in duplicate detection.
  ///
  /// In en, this message translates to:
  /// **'Use for duplicates'**
  String get fieldIdentity;

  /// Expression that makes the field required.
  ///
  /// In en, this message translates to:
  /// **'Required when'**
  String get fieldRequiredWhen;

  /// Plain-language reading of a required-when expression.
  ///
  /// In en, this message translates to:
  /// **'Required when {reading}'**
  String fieldRequiredWhenPreview(Object reading);

  /// Keeps the field out of capture and export; values stay.
  ///
  /// In en, this message translates to:
  /// **'Hide from capture and export'**
  String get fieldHidden;

  /// Explains that hide is not a delete.
  ///
  /// In en, this message translates to:
  /// **'Values already captured stay on the record.'**
  String get fieldHiddenHelp;

  /// Validation editor heading.
  ///
  /// In en, this message translates to:
  /// **'Validation'**
  String get fieldValidationTitle;

  /// Headline when no validation rule is set.
  ///
  /// In en, this message translates to:
  /// **'No validation yet'**
  String get fieldValidationEmptyHeadline;

  /// Body when the validation editor is empty.
  ///
  /// In en, this message translates to:
  /// **'Add a pattern, length, range or required-with rule.'**
  String get fieldValidationEmptyMessage;

  /// Pattern picker.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get fieldPattern;

  /// No pattern.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get fieldPatternNone;

  /// Ready-made serial pattern.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get fieldPatternSerial;

  /// Ready-made asset-tag pattern.
  ///
  /// In en, this message translates to:
  /// **'Asset tag'**
  String get fieldPatternAssetTag;

  /// Ready-made registration pattern.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get fieldPatternRegistration;

  /// Custom regular expression.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get fieldPatternCustom;

  /// Live box that tries the current validation against a sample.
  ///
  /// In en, this message translates to:
  /// **'Try a value'**
  String get fieldPatternTest;

  /// Sample matches the rule.
  ///
  /// In en, this message translates to:
  /// **'That value is allowed.'**
  String get fieldPatternTestPass;

  /// Minimum length.
  ///
  /// In en, this message translates to:
  /// **'Shortest'**
  String get fieldMinLength;

  /// Maximum length.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get fieldMaxLength;

  /// Inclusive lower bound.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get fieldRangeMin;

  /// Inclusive upper bound.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get fieldRangeMax;

  /// Another field that must be filled with this one.
  ///
  /// In en, this message translates to:
  /// **'Required with'**
  String get fieldRequiredWith;

  /// Choice-options editor heading.
  ///
  /// In en, this message translates to:
  /// **'Choices'**
  String get fieldOptionsTitle;

  /// Headline when a choice field has no options.
  ///
  /// In en, this message translates to:
  /// **'No choices yet'**
  String get fieldOptionsEmptyHeadline;

  /// Body when the options editor is empty.
  ///
  /// In en, this message translates to:
  /// **'Add a choice so capture has something to pick.'**
  String get fieldOptionsEmptyMessage;

  /// Label of a new choice.
  ///
  /// In en, this message translates to:
  /// **'Choice name'**
  String get fieldOptionLabel;

  /// Adds a choice to the list.
  ///
  /// In en, this message translates to:
  /// **'Add a choice'**
  String get fieldOptionAdd;

  /// Retires a choice without rewriting stored codes.
  ///
  /// In en, this message translates to:
  /// **'Retire choice'**
  String get fieldOptionRetire;

  /// Badge on a retired choice.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get fieldOptionRetired;

  /// Headline when the add sheet cannot find the template.
  ///
  /// In en, this message translates to:
  /// **'No template to edit'**
  String get fieldAddEmptyHeadline;

  /// Body when the add sheet has no template.
  ///
  /// In en, this message translates to:
  /// **'Open the template list and pick a template first.'**
  String get fieldAddEmptyMessage;

  /// Title of the bulk requiredness screen.
  ///
  /// In en, this message translates to:
  /// **'Required columns'**
  String get requiredColumnsTitle;

  /// Headline when the template has no fields to re-scope.
  ///
  /// In en, this message translates to:
  /// **'No columns to set'**
  String get requiredColumnsEmptyHeadline;

  /// Body when the required-columns list is empty.
  ///
  /// In en, this message translates to:
  /// **'Add a field first, then choose what this project insists on.'**
  String get requiredColumnsEmptyMessage;

  /// Hide toggle on a required-columns row.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get requiredColumnHide;

  /// Reveals an inherited §13.3 group.
  ///
  /// In en, this message translates to:
  /// **'Show group'**
  String get requiredColumnShowGroup;

  /// Collapses an inherited §13.3 group.
  ///
  /// In en, this message translates to:
  /// **'Hide group'**
  String get requiredColumnHideGroup;

  /// Heading for fields that do not sit in a named group.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get requiredColumnUngrouped;

  /// Screen-reader name of the three-radio grid for [label].
  ///
  /// In en, this message translates to:
  /// **'Required? · {label}'**
  String requiredColumnRadios(Object label);

  /// One radio cell: field [label] and the requiredness [mark].
  ///
  /// In en, this message translates to:
  /// **'{label}, {mark}'**
  String requiredColumnCell(Object label, Object mark);

  /// Reminder of the shipped requiredness after the user moves it.
  ///
  /// In en, this message translates to:
  /// **'Shipped as {mark}'**
  String requiredColumnShipped(Object mark);

  /// Operator-facing name of a field group.
  ///
  /// In en, this message translates to:
  /// **'templates.groups.{group}.{group}'**
  String requiredColumnGroup(Object group);

  /// Title of the identity-fields screen.
  ///
  /// In en, this message translates to:
  /// **'Identity fields'**
  String get identityFieldsTitle;

  /// What changing the identity set does.
  ///
  /// In en, this message translates to:
  /// **'These fields decide whether two records are the same thing.'**
  String get identityFieldsExplain;

  /// Headline when the template has no fields to mark as identity.
  ///
  /// In en, this message translates to:
  /// **'No fields to mark'**
  String get identityFieldsEmptyHeadline;

  /// Body when the identity list is empty.
  ///
  /// In en, this message translates to:
  /// **'Add a field first, then choose which ones identify a record.'**
  String get identityFieldsEmptyMessage;

  /// Title of the output-column mapping screen.
  ///
  /// In en, this message translates to:
  /// **'Output columns'**
  String get outputMappingTitle;

  /// Headline when the template has no fields to map.
  ///
  /// In en, this message translates to:
  /// **'No columns to map'**
  String get outputMappingEmptyHeadline;

  /// Body when the output-mapping list is empty.
  ///
  /// In en, this message translates to:
  /// **'Add a field first, then choose where each one writes.'**
  String get outputMappingEmptyMessage;

  /// Why two fields cannot share an output column.
  ///
  /// In en, this message translates to:
  /// **'Two fields cannot write to the same column.'**
  String get outputMappingDuplicate;

  /// What to do after a duplicate output column is refused.
  ///
  /// In en, this message translates to:
  /// **'Give each field its own column, then save.'**
  String get outputMappingDuplicateRecovery;

  /// Hint on a template built in the app, whose headers are generated.
  ///
  /// In en, this message translates to:
  /// **'Headers are generated from the field labels. You can change them.'**
  String get outputMappingBuiltHint;

  /// Hint on a template imported from a workbook.
  ///
  /// In en, this message translates to:
  /// **'These letters came from the workbook. You can change them.'**
  String get outputMappingImportedHint;

  /// Title of the template-migration screen.
  ///
  /// In en, this message translates to:
  /// **'Move records'**
  String get templateMigrationTitle;

  /// What staying on a captured version means.
  ///
  /// In en, this message translates to:
  /// **'Records stay on the version they were captured under until you move them.'**
  String get templateMigrationExplain;

  /// Headline when every record is already on the current version.
  ///
  /// In en, this message translates to:
  /// **'Nothing to move'**
  String get templateMigrationEmptyHeadline;

  /// Body when no record is behind the current template version.
  ///
  /// In en, this message translates to:
  /// **'Every record is already on this template version.'**
  String get templateMigrationEmptyMessage;

  /// Added-fields section on the migration screen.
  ///
  /// In en, this message translates to:
  /// **'Added fields'**
  String get templateMigrationAdded;

  /// Removed-fields section on the migration screen.
  ///
  /// In en, this message translates to:
  /// **'Removed fields'**
  String get templateMigrationRemoved;

  /// Retyped-fields section on the migration screen.
  ///
  /// In en, this message translates to:
  /// **'Retyped fields'**
  String get templateMigrationRetyped;

  /// Confirm heading before records move.
  ///
  /// In en, this message translates to:
  /// **'Move these records?'**
  String get templateMigrationConfirmTitle;

  /// Confirm body: how many records move, in one write, or none do.
  ///
  /// In en, this message translates to:
  /// **'This moves {recordsCountrecords} to the new version in one step. Values of removed fields are kept and retired.'**
  String templateMigrationConfirm(Object recordsCountrecords);

  /// How many records are behind the current template version.
  ///
  /// In en, this message translates to:
  /// **'{recordsCountrecords} on an earlier version'**
  String templateMigrationBehind(Object recordsCountrecords);

  /// Records whose captured version is no longer known on this device.
  ///
  /// In en, this message translates to:
  /// **'{recordsCountrecords} were captured under a version this device no longer has. Their values for fields not on the current template are listed under Values that will retire.'**
  String templateMigrationUnresolved(Object recordsCountrecords);

  /// Section of stored values the move retires for unresolved records.
  ///
  /// In en, this message translates to:
  /// **'Values that will retire'**
  String get templateMigrationRetiring;

  /// Primary action that starts the confirmed move.
  ///
  /// In en, this message translates to:
  /// **'Move records'**
  String get templateMigrationAction;

  /// Suggested name when duplicating [name].
  ///
  /// In en, this message translates to:
  /// **'{name} (copy)'**
  String templateCopyName(Object name);

  /// Field and record counts on one template list row.
  ///
  /// In en, this message translates to:
  /// **'{fieldsCountfields} · {recordsCountrecords}'**
  String templateListSubtitle(
    Object fieldsCountfields,
    Object recordsCountrecords,
  );

  /// Title of the shipped-library picker.
  ///
  /// In en, this message translates to:
  /// **'Shipped templates'**
  String get templatesLibraryTitle;

  /// Headline when the packed library could not be listed.
  ///
  /// In en, this message translates to:
  /// **'No shipped templates'**
  String get templatesLibraryEmptyHeadline;

  /// Body when the packed library is empty. Next action is a blank template.
  ///
  /// In en, this message translates to:
  /// **'Create a blank template to start capturing.'**
  String get templatesLibraryEmptyMessage;

  /// Copies the previewed library entry into the open project.
  ///
  /// In en, this message translates to:
  /// **'Add to this project'**
  String get templatesAdd;

  /// Adds a shipped template that this project does not have yet.
  ///
  /// In en, this message translates to:
  /// **'Add to project'**
  String get templatesAddToProject;

  /// Makes another editable copy of a template already on the project.
  ///
  /// In en, this message translates to:
  /// **'Create a custom copy'**
  String get templatesCustomCopy;

  /// Visible association on a shipped template already copied in.
  ///
  /// In en, this message translates to:
  /// **'Added to this project'**
  String get shippedAddedToProject;

  /// Search hint on the shipped template library, which ranks a name, a code
  ///    or a plain description of the work.
  ///
  /// In en, this message translates to:
  /// **'Search or describe your work'**
  String get shippedLibrarySearchHint;

  /// Heading of a catalogue area. [code] and [title] are catalogue data.
  ///
  /// In en, this message translates to:
  /// **'{code} · {title}'**
  String shippedAreaTitle(Object code, Object title);

  /// Heading of a catalogue category. [code] and [title] are catalogue data.
  ///
  /// In en, this message translates to:
  /// **'{code} — {title}'**
  String shippedCatalogueCategoryTitle(Object code, Object title);

  /// A collapsible catalogue category with how many templates it lists.
  ///
  /// In en, this message translates to:
  /// **'{shippedCatalogueCategoryTitlecodetitle} · {count}'**
  String shippedCategoryHeading(
    Object shippedCatalogueCategoryTitlecodetitle,
    int count,
  );

  /// Row subtitle of a catalogue template: its code, its record type and how
  ///    many fields it holds. [code] and [recordType] are catalogue data.
  ///
  /// In en, this message translates to:
  /// **'{code} · {recordType} · {fieldsCountfields}'**
  String shippedCatalogueSubtitle(
    Object code,
    Object recordType,
    Object fieldsCountfields,
  );

  /// Title of the shipped library's filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Library filters'**
  String get shippedFiltersTitle;

  /// The area facet of the shipped library's filters.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get shippedAreaFilter;

  /// The record-type facet of the shipped library's filters.
  ///
  /// In en, this message translates to:
  /// **'Record type'**
  String get shippedRecordTypeFilter;

  /// The tier facet of the shipped library's filters.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get shippedTierFilter;

  /// Operator-facing name of a catalogue rollout tier.
  ///
  /// In en, this message translates to:
  /// **'Foundation'**
  String get shippedTierLabel;

  /// Operator-facing name of a catalogue rollout tier.
  ///
  /// In en, this message translates to:
  /// **'Expansion'**
  String get shippedTierLabelExpansion;

  /// Operator-facing name of a catalogue rollout tier.
  ///
  /// In en, this message translates to:
  /// **'Specialist'**
  String get shippedTierLabelSpecialist;

  /// Operator-facing name of a catalogue template's suggested privacy.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get shippedPrivacyLabel;

  /// Operator-facing name of a catalogue template's suggested privacy.
  ///
  /// In en, this message translates to:
  /// **'Confidential'**
  String get shippedPrivacyLabelConfidential;

  /// Operator-facing name of a catalogue template's suggested privacy.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get shippedPrivacyLabelRestricted;

  /// Preview row naming the catalogue category a template sits in.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get shippedCategoryLabel;

  /// Preview row naming a catalogue template's record type.
  ///
  /// In en, this message translates to:
  /// **'Record type'**
  String get shippedRecordTypeLabel;

  /// Preview row giving a catalogue template's privacy and tier.
  ///
  /// In en, this message translates to:
  /// **'Suggested privacy and tier'**
  String get shippedPrivacyTierLabel;

  /// A catalogue template's suggested privacy beside its tier.
  ///
  /// In en, this message translates to:
  /// **'{shippedPrivacyLabelprivacy} · {shippedTierLabelrollout}'**
  String shippedPrivacyTier(
    Object shippedPrivacyLabelprivacy,
    Object shippedTierLabelrollout,
  );

  /// Preview row: how evidence for the record type is captured.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get shippedCaptureLabel;

  /// Preview row: what AI may do for the record type.
  ///
  /// In en, this message translates to:
  /// **'AI assistance'**
  String get shippedAiAssistanceLabel;

  /// Preview row: what the record type produces.
  ///
  /// In en, this message translates to:
  /// **'Outputs'**
  String get shippedOutputsLabel;

  /// Preview row: what a reviewer checks before approval.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get shippedReviewLabel;

  /// Preview subtitle of one field: its type and suggested requiredness.
  ///
  /// In en, this message translates to:
  /// **'{fieldTypeLabeltype} · {requiredness}'**
  String shippedFieldSubtitle(Object fieldTypeLabeltype, Object requiredness);

  /// Empty result for the shipped library search.
  ///
  /// In en, this message translates to:
  /// **'No templates match.'**
  String get shippedLibraryNoMatch;

  /// Empty result for the shipped library search.
  ///
  /// In en, this message translates to:
  /// **'No templates match \"{shown}\".'**
  String shippedLibraryNoMatchNoTemplatesMatch(Object shown);

  /// Resolves a packed localisation key at render time (FE-L10N-07).
  ///
  /// In en, this message translates to:
  /// **'item_'**
  String get shippedLabel;

  /// Resolves a packed localisation key at render time (FE-L10N-07).
  ///
  /// In en, this message translates to:
  /// **' {wordsindex}'**
  String shippedLabelValue(Object wordsindex);

  /// Resolves a packed localisation key at render time (FE-L10N-07).
  ///
  /// In en, this message translates to:
  /// **'{text0toUpperCase}{textsubstring1}'**
  String shippedLabelValue2(Object text0toUpperCase, Object textsubstring1);

  /// Unprocessed-queue destination the status line opens.
  ///
  /// In en, this message translates to:
  /// **'Unprocessed'**
  String get navQueue;

  /// Export-history destination the project home opens.
  ///
  /// In en, this message translates to:
  /// **'Exports'**
  String get navExports;

  /// Why the operator name is asked.
  ///
  /// In en, this message translates to:
  /// **'Used on every record you capture from this device.'**
  String get operatorNameUse;

  /// Label of the operator name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get operatorName;

  /// Settings screen for the local operator identity.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get operatorProfileTitle;

  /// Initials field on the operator profile.
  ///
  /// In en, this message translates to:
  /// **'Initials'**
  String get operatorInitials;

  /// Combined contact label when email and phone are shown as one value.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get operatorContact;

  /// Optional email field on the operator profile.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get operatorEmail;

  /// Optional phone field on the operator profile.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get operatorPhone;

  /// Name failed the non-empty rule.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get nameRequired;

  /// A typed email is missing the @ that marks it as an address.
  ///
  /// In en, this message translates to:
  /// **'Include an @ in the email'**
  String get emailNeedsAt;

  /// Initials failed the one-to-three-character rule.
  ///
  /// In en, this message translates to:
  /// **'Use one to three characters'**
  String get initialsLength;

  /// Status line when no project is open.
  ///
  /// In en, this message translates to:
  /// **'No project'**
  String get statusNoProject;

  /// Status line when no context is pinned.
  ///
  /// In en, this message translates to:
  /// **'No context'**
  String get statusNoContext;

  /// Context hierarchy screen title.
  ///
  /// In en, this message translates to:
  /// **'Project contexts'**
  String get contextHierarchyTitle;

  /// Empty hierarchy.
  ///
  /// In en, this message translates to:
  /// **'No context levels'**
  String get contextHierarchyEmptyHeadline;

  /// Empty hierarchy body.
  ///
  /// In en, this message translates to:
  /// **'Add field keys from a template to build a hierarchy, or leave none.'**
  String get contextHierarchyEmptyMessage;

  /// Add a level.
  ///
  /// In en, this message translates to:
  /// **'Add level'**
  String get contextAddLevel;

  /// One saved or proposed level and its stable field key.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {fieldKey}'**
  String contextLevelRow(int level, Object fieldKey);

  /// Accepts all unambiguous template-declared levels.
  ///
  /// In en, this message translates to:
  /// **'Use template levels'**
  String get contextUseTemplateLevels;

  /// Template loading failure on context setup.
  ///
  /// In en, this message translates to:
  /// **'Template levels could not load'**
  String get contextTemplateFailureHeadline;

  /// Recovery text after template-level loading fails.
  ///
  /// In en, this message translates to:
  /// **'Try again. Your saved context has not changed.'**
  String get contextTemplateFailureMessage;

  /// No project template exists yet.
  ///
  /// In en, this message translates to:
  /// **'No project templates'**
  String get contextNoTemplatesHeadline;

  /// Explains how a project gains fields that can become levels.
  ///
  /// In en, this message translates to:
  /// **'Attach or create a template before choosing context fields.'**
  String get contextNoTemplatesMessage;

  /// Opens the contextual Templates route.
  ///
  /// In en, this message translates to:
  /// **'Add templates'**
  String get contextOpenTemplates;

  /// Templates exist but do not declare a hierarchy.
  ///
  /// In en, this message translates to:
  /// **'No template levels declared'**
  String get contextNoDeclaredLevelsHeadline;

  /// Explains how to declare template levels.
  ///
  /// In en, this message translates to:
  /// **'Set a positive context level on template fields, or add levels manually.'**
  String get contextNoDeclaredLevelsMessage;

  /// Every available field is already part of the hierarchy.
  ///
  /// In en, this message translates to:
  /// **'No fields available'**
  String get contextNoEligibleFieldsHeadline;

  /// Explains why the manual picker has no remaining fields.
  ///
  /// In en, this message translates to:
  /// **'Every template field is already used as a context level.'**
  String get contextNoEligibleFieldsMessage;

  /// Conflicting level metadata requires explicit correction.
  ///
  /// In en, this message translates to:
  /// **'Template levels conflict'**
  String get contextTemplateConflictHeadline;

  /// Names template declaration conflicts without guessing through them.
  ///
  /// In en, this message translates to:
  /// **'Resolve these declarations in Templates: {conflicts}.'**
  String contextTemplateConflictMessage(Object conflicts);

  /// Save hierarchy.
  ///
  /// In en, this message translates to:
  /// **'Save levels'**
  String get contextSaveHierarchy;

  /// Context picker sheet title prefix.
  ///
  /// In en, this message translates to:
  /// **'Set {label}'**
  String contextPickerTitle(Object label);

  /// Recent values section.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get contextRecents;

  /// Dataset search section.
  ///
  /// In en, this message translates to:
  /// **'From dataset'**
  String get contextDatasetSearch;

  /// Free-text confirm.
  ///
  /// In en, this message translates to:
  /// **'Use this value'**
  String get contextUseValue;

  /// Label of the picker's free-text field.
  ///
  /// In en, this message translates to:
  /// **'Type a value'**
  String get contextTypeValue;

  /// A pin with no value in the pinned-fields sheet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get contextValueNotSet;

  /// Removes a pinned value in its picker.
  ///
  /// In en, this message translates to:
  /// **'Clear pin'**
  String get contextClearPin;

  /// A pinned field and its value on the context bar; both are data.
  ///
  /// In en, this message translates to:
  /// **'{field}: {value}'**
  String contextPinnedValue(Object field, Object value);

  /// Pin fields sheet.
  ///
  /// In en, this message translates to:
  /// **'Pinned fields'**
  String get contextPinnedTitle;

  /// Pin empty.
  ///
  /// In en, this message translates to:
  /// **'No pinnable context fields'**
  String get contextPinnedEmptyHeadline;

  /// Pin empty body.
  ///
  /// In en, this message translates to:
  /// **'Mark fields as pinned context on a template to reuse them during capture.'**
  String get contextPinnedEmptyMessage;

  /// Pin empty body when the project already has a template.
  ///
  /// In en, this message translates to:
  /// **'Mark a field as pinnable'**
  String get contextMarkPinnable;

  /// Why pinned context is useful.
  ///
  /// In en, this message translates to:
  /// **'Pinned context is reused on each new record until you change it.'**
  String get contextPinnedRelevance;

  /// Cascade confirm title.
  ///
  /// In en, this message translates to:
  /// **'Clear lower levels?'**
  String get contextCascadeTitle;

  /// Cascade confirm body in the specification's wording.
  ///
  ///    [named] is each lower level and its current value. Level names and
  ///    values are operator data, not catalogue keys (FE-L10N-07).
  ///
  /// In en, this message translates to:
  /// **'Change {levelLabel} to {newValue}? {andnamed} will be cleared.'**
  String contextCascadeMessage(
    Object levelLabel,
    Object newValue,
    Object andnamed,
  );

  /// Cascade confirm action.
  ///
  /// In en, this message translates to:
  /// **'Clear and continue'**
  String get contextCascadeConfirm;

  /// Preset list title.
  ///
  /// In en, this message translates to:
  /// **'Context presets'**
  String get contextPresetsTitle;

  /// Preset empty.
  ///
  /// In en, this message translates to:
  /// **'No presets yet'**
  String get contextPresetsEmptyHeadline;

  /// Preset empty body — next action is to apply a preset.
  ///
  /// In en, this message translates to:
  /// **'Save the current context, then apply the preset in one tap.'**
  String get contextPresetsEmptyMessage;

  /// Save preset.
  ///
  /// In en, this message translates to:
  /// **'Save preset'**
  String get contextPresetSave;

  /// Apply preset.
  ///
  /// In en, this message translates to:
  /// **'Apply preset'**
  String get contextPresetApply;

  /// Opens the preset list from the context bar.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get contextPresetsChip;

  /// The preset list row on the context levels screen.
  ///
  /// In en, this message translates to:
  /// **'Save the current values, or switch rooms in one tap.'**
  String get contextPresetsHint;

  /// Name field of the save-preset sheet.
  ///
  /// In en, this message translates to:
  /// **'Preset name'**
  String get contextPresetName;

  /// After a preset was applied; [name] is data.
  ///
  /// In en, this message translates to:
  /// **'Switched to {name}.'**
  String contextPresetApplied(Object name);

  /// After a preset was saved; [name] is data.
  ///
  /// In en, this message translates to:
  /// **'Saved preset {name}.'**
  String contextPresetSaved(Object name);

  /// Deletes one preset from its row menu.
  ///
  /// In en, this message translates to:
  /// **'Delete preset'**
  String get contextPresetDelete;

  /// Confirms a preset delete; [name] is data.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? Values already set stay as they are.'**
  String contextPresetDeleteMessage(Object name);

  /// Stored reason for a preset deleted from the list.
  ///
  /// In en, this message translates to:
  /// **'Deleted from the list.'**
  String get contextPresetDeleteReason;

  /// Duplicate preset name.
  ///
  /// In en, this message translates to:
  /// **'Replace preset?'**
  String get contextPresetOverwriteTitle;

  /// Duplicate preset body.
  ///
  /// In en, this message translates to:
  /// **'A preset with that name already exists. Replace it?'**
  String get contextPresetOverwriteMessage;

  /// Confirms replacing a preset of the same name.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get contextPresetReplace;

  /// Auto-clear undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get contextAutoClearUndo;

  /// Auto-clear toast.
  ///
  /// In en, this message translates to:
  /// **'Cleared {label} after idle.'**
  String contextAutoClearMessage(Object label);

  /// Movement prompt title.
  ///
  /// In en, this message translates to:
  /// **'Confirm context'**
  String get contextMovementTitle;

  /// Movement prompt body.
  ///
  /// In en, this message translates to:
  /// **'You have moved. Is the current context still correct?'**
  String get contextMovementMessage;

  /// Opens the lowest level's picker from the movement prompt.
  ///
  /// In en, this message translates to:
  /// **'Change context'**
  String get contextMovementChange;

  /// Pin chip marker.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get contextPinMarker;

  /// A context level with no value on Capture's bar; [level] is data.
  ///
  /// In en, this message translates to:
  /// **'Set {level}'**
  String contextSetLevel(Object level);

  /// A context level and its value on Capture's bar; both are data.
  ///
  /// In en, this message translates to:
  /// **'{level}: {value}'**
  String contextLevelValue(Object level, Object value);

  /// Opens the project's context levels from Capture's bar.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get contextManage;

  /// Opens the project's context levels when it has none yet.
  ///
  /// In en, this message translates to:
  /// **'Set up context'**
  String get contextSetUp;

  /// Remove one hierarchy level.
  ///
  /// In en, this message translates to:
  /// **'Remove level'**
  String get contextRemoveLevel;

  /// Semantic name of a level's drag handle; [level] is data.
  ///
  /// In en, this message translates to:
  /// **'Drag {level} to reorder'**
  String contextDragLevel(Object level);

  /// Idle auto-clear switch. Off until the operator turns it on.
  ///
  /// In en, this message translates to:
  /// **'Clear the lowest level when idle'**
  String get settingsContextAutoClear;

  /// Why auto-clear stays off.
  ///
  /// In en, this message translates to:
  /// **'Off until you turn it on. Clears only the lowest level, and you can undo.'**
  String get settingsContextAutoClearEffect;

  /// Idle interval row.
  ///
  /// In en, this message translates to:
  /// **'After {minutes} minutes with no change.'**
  String settingsContextIdleSubtitle(int minutes);

  /// Movement confirmation switch. Off until the operator turns it on.
  ///
  /// In en, this message translates to:
  /// **'Confirm context after movement'**
  String get settingsContextMovement;

  /// Why the movement prompt stays off, and that it does not edit context.
  ///
  /// In en, this message translates to:
  /// **'Off until you turn it on. Asks you to confirm. It does not change context. Needs GPS and location already allowed.'**
  String get settingsContextMovementEffect;

  /// Distance row.
  ///
  /// In en, this message translates to:
  /// **'After {metres} metres.'**
  String settingsContextDistanceSubtitle(int metres);

  /// Idle interval choice: how long the context waits before clearing.
  ///
  /// In en, this message translates to:
  /// **'Clear context after'**
  String get settingsContextIdle;

  /// What the idle interval changes.
  ///
  /// In en, this message translates to:
  /// **'How long with no change before the lowest level clears.'**
  String get settingsContextIdleEffect;

  /// One idle interval, in minutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 minute} other{{count} minutes}}'**
  String settingsContextIdleOption(int count);

  /// Movement distance choice: how far a move is before Tapture asks.
  ///
  /// In en, this message translates to:
  /// **'Ask when I move'**
  String get settingsContextDistance;

  /// What the movement distance changes.
  ///
  /// In en, this message translates to:
  /// **'How far you move before Tapture asks you to confirm the context.'**
  String get settingsContextDistanceEffect;

  /// One movement distance, in metres.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 metre} other{{count} metres}}'**
  String settingsContextDistanceOption(int count);

  /// Capture screen title.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get captureTitle;

  /// Primary save that also enqueues analysis.
  ///
  /// In en, this message translates to:
  /// **'Save and process'**
  String get captureSaveAndAnalyse;

  /// Why Save and process is off while the device is offline.
  ///
  /// In en, this message translates to:
  /// **'Save raw now. Process it once this device is online.'**
  String get captureProcessNeedsNetwork;

  /// Raw save with no processing.
  ///
  /// In en, this message translates to:
  /// **'Save raw'**
  String get captureSaveRaw;

  /// Empty tray headline.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get captureNoPhotosHeadline;

  /// Empty tray body — evidence is the only requirement.
  ///
  /// In en, this message translates to:
  /// **'Add a photo, import a file, or type a caption to start.'**
  String get captureNoPhotosMessage;

  /// Project selector on the capture surface.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get captureProjectLabel;

  /// Capture is open and projects exist, but none is selected.
  ///
  /// In en, this message translates to:
  /// **'Choose a project to start capturing.'**
  String get captureChooseProject;

  /// Capture is open and there is no project to file it under.
  ///
  /// In en, this message translates to:
  /// **'Create a project before capturing.'**
  String get captureCreateProjectFirst;

  /// Why capture needs a project, under the no-project headline.
  ///
  /// In en, this message translates to:
  /// **'Every photo and record is filed under a project.'**
  String get captureNoProjectMessage;

  /// A project is open, but it has no template to capture against.
  ///
  /// In en, this message translates to:
  /// **'Add a template before capturing.'**
  String get captureNeedsTemplate;

  /// More fields expander.
  ///
  /// In en, this message translates to:
  /// **'More fields'**
  String get captureMoreFields;

  /// Camera permission reason before the system prompt.
  ///
  /// In en, this message translates to:
  /// **'Tapture needs the camera to photograph equipment and documents.'**
  String get captureCameraReason;

  /// Open system settings after a permanent camera refusal.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get captureOpenCameraSettings;

  /// Asks the system for the camera after the reason is shown.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get captureAllowCamera;

  /// Title of the full-screen live camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get captureCameraTitle;

  /// Keep a photo despite a quality warning.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get captureKeepPhoto;

  /// Retake after a quality warning.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get captureRetakePhoto;

  /// Document mode toggle on the live camera.
  ///
  /// In en, this message translates to:
  /// **'Document mode'**
  String get captureDocumentMode;

  /// Document mode found the page and offers the straightened copy.
  ///
  /// In en, this message translates to:
  /// **'Page edge found. A straightened copy is ready.'**
  String get capturePageBoundaryFound;

  /// Use the perspective-corrected copy beside the original.
  ///
  /// In en, this message translates to:
  /// **'Use corrected'**
  String get captureUseCorrected;

  /// Document mode could not straighten the page.
  ///
  /// In en, this message translates to:
  /// **'The page could not be straightened. The original is kept.'**
  String get captureCorrectionFailed;

  /// Document mode found no page boundary.
  ///
  /// In en, this message translates to:
  /// **'No page edge found. Captured as a normal photo.'**
  String get captureNoPageBoundary;

  /// Flash control label while the flash stays off.
  ///
  /// In en, this message translates to:
  /// **'Flash off'**
  String get captureFlashOff;

  /// Flash control label while the device decides.
  ///
  /// In en, this message translates to:
  /// **'Flash auto'**
  String get captureFlashAuto;

  /// Flash control label while the flash fires.
  ///
  /// In en, this message translates to:
  /// **'Flash on'**
  String get captureFlashOn;

  /// Grid control semantic label.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get captureGrid;

  /// Focus indicator semantic label.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get captureFocus;

  /// Zoom-out control label.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get captureZoomOut;

  /// Zoom-in control label.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get captureZoomIn;

  /// Gallery import action.
  ///
  /// In en, this message translates to:
  /// **'Import photos'**
  String get captureImportGallery;

  /// Document import action.
  ///
  /// In en, this message translates to:
  /// **'Import document'**
  String get captureImportDocument;

  /// Import cannot start before the document store is available.
  ///
  /// In en, this message translates to:
  /// **'Documents are not available on this device.'**
  String get captureDocumentsUnavailable;

  /// Recovery for unavailable document storage.
  ///
  /// In en, this message translates to:
  /// **'Try again after reopening the app.'**
  String get captureDocumentsUnavailableRecovery;

  /// Try another file recovery.
  ///
  /// In en, this message translates to:
  /// **'Try another file'**
  String get tryAnotherFile;

  /// PDF bytes were not a valid document.
  ///
  /// In en, this message translates to:
  /// **'That PDF could not be read.'**
  String get pdfInvalid;

  /// Names an imported document whose contents cannot be safely read.
  ///
  /// In en, this message translates to:
  /// **'The contents of {filename} could not be read.'**
  String captureDocumentInvalid(Object filename);

  /// Requested page is outside the document.
  ///
  /// In en, this message translates to:
  /// **'That page is not in the document.'**
  String get pdfPageMissing;

  /// Moves through lazily rendered document pages.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get pdfPreviousPage;

  /// Moves through lazily rendered document pages.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get pdfNextPage;

  /// Barcode scanner unavailable on this build.
  ///
  /// In en, this message translates to:
  /// **'Barcode scanning is not available on this device.'**
  String get barcodeUnavailable;

  /// Recovery for a refused scanner camera; typing still works meanwhile.
  ///
  /// In en, this message translates to:
  /// **'Allow the camera in settings to scan, or type the code.'**
  String get barcodeAllowCamera;

  /// Confirm a decoded barcode.
  ///
  /// In en, this message translates to:
  /// **'Use this code'**
  String get barcodeConfirm;

  /// Scan again after a decode.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get barcodeRescan;

  /// No code in the region yet.
  ///
  /// In en, this message translates to:
  /// **'Point at a barcode'**
  String get barcodeNoCode;

  /// Title of the barcode scanner screen.
  ///
  /// In en, this message translates to:
  /// **'Scan a code'**
  String get barcodeTitle;

  /// Torch toggle on the barcode scanner.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get barcodeTorch;

  /// Unreadable code.
  ///
  /// In en, this message translates to:
  /// **'That code could not be read.'**
  String get barcodeUnreadable;

  /// Continuous mode running count.
  ///
  /// In en, this message translates to:
  /// **'Scanned {n}'**
  String barcodeScanCount(int n);

  /// A counted code's place in the continuous-mode tally.
  ///
  /// In en, this message translates to:
  /// **'Scan {n}'**
  String barcodeCountPosition(int n);

  /// Continuous-mode toggle on the barcode scanner.
  ///
  /// In en, this message translates to:
  /// **'Count items'**
  String get barcodeCountMode;

  /// Undo last continuous scan.
  ///
  /// In en, this message translates to:
  /// **'Undo last'**
  String get barcodeUndoLast;

  /// Identifier matched a project record.
  ///
  /// In en, this message translates to:
  /// **'Open record'**
  String get identifierMatchRecord;

  /// Identifier matched a reference row.
  ///
  /// In en, this message translates to:
  /// **'Use reference'**
  String get identifierMatchReference;

  /// Identifier matched nothing — start a new record.
  ///
  /// In en, this message translates to:
  /// **'New record'**
  String get identifierNewRecord;

  /// Several records share the identifier.
  ///
  /// In en, this message translates to:
  /// **'Several matches'**
  String get identifierDuplicates;

  /// Record caption field label.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get captureRecordCaption;

  /// Photo group on the capture surface.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get capturePhotosSection;

  /// Audio group on the capture surface.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get captureAudioSection;

  /// Removes one draft photo from the capture tray.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get captureRemovePhoto;

  /// Adds the typed caption to every photo, when none is ticked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Add to the photo} other{Add to all {count} photos}}'**
  String captionAddToAll(int count);

  /// Adds the typed caption to the ticked photos only.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Add to 1 ticked photo} other{Add to {count} ticked photos}}'**
  String captionAddToTicked(int count);

  /// Says how many photos a caption was just added to.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Added to the photo} other{Added to {count} photos}}'**
  String captionAdded(int count);

  /// Append caption mode.
  ///
  /// In en, this message translates to:
  /// **'Append'**
  String get captionAppend;

  /// Replace caption mode.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get captionReplace;

  /// Microphone permission reason.
  ///
  /// In en, this message translates to:
  /// **'Tapture needs the microphone for spoken notes on an explicit tap.'**
  String get captureMicReason;

  /// Voice input listening state.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get captureListening;

  /// Audio recorder start.
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get captureRecordAudio;

  /// Caption recorder start when a speech model is ready: records the audio and writes down the words on this device.
  ///
  /// In en, this message translates to:
  /// **'Record and transcribe'**
  String get captureRecordTranscribe;

  /// Audio recorder pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get capturePauseAudio;

  /// Audio recorder stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get captureStopAudio;

  /// Audio recorder unavailable.
  ///
  /// In en, this message translates to:
  /// **'Audio recording is not available on this device.'**
  String get audioRecorderUnavailable;

  /// Refusal when another recording already holds the microphone.
  ///
  /// In en, this message translates to:
  /// **'The microphone is in use by another recording. Stop it first, then try again.'**
  String get microphoneBusy;

  /// The recorder refused to start a take.
  ///
  /// In en, this message translates to:
  /// **'Recording could not start.'**
  String get audioStartFailed;

  /// Recovery for [audioStartFailed].
  ///
  /// In en, this message translates to:
  /// **'Try again. Nothing already captured was lost.'**
  String get audioStartFailedRecovery;

  /// A browser take refused more audio at its length cap.
  ///
  /// In en, this message translates to:
  /// **'This recording reached the longest take this browser can keep. Everything captured so far is kept.'**
  String get audioTakeLimitReached;

  /// Recovery for [audioTakeLimitReached].
  ///
  /// In en, this message translates to:
  /// **'Stop this recording, then start a new one to continue.'**
  String get audioTakeLimitReachedRecovery;

  /// A recording path that would leave the storage folder.
  ///
  /// In en, this message translates to:
  /// **'The recording must be saved inside the project folder.'**
  String get audioPathOutsideStorage;

  /// Microphone permission failure and recovery.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission was not granted.'**
  String get audioPermissionDenied;

  /// Tells the operator how to grant microphone access.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access in system settings, then try again.'**
  String get audioPermissionRecovery;

  /// Recorder phase and elapsed time.
  ///
  /// In en, this message translates to:
  /// **'Requesting microphone permission'**
  String get audioRecorderStatus;

  /// Recorder phase and elapsed time.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get audioRecorderStatusRecording;

  /// Recorder phase and elapsed time.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get audioRecorderStatusPaused;

  /// Recorder phase and elapsed time.
  ///
  /// In en, this message translates to:
  /// **'Saving audio'**
  String get audioRecorderStatusSavingAudio;

  /// Recorder phase and elapsed time.
  ///
  /// In en, this message translates to:
  /// **'Audio failed'**
  String get audioRecorderStatusAudioFailed;

  /// Recorder phase and elapsed time.
  ///
  /// In en, this message translates to:
  /// **'Audio saved'**
  String get audioRecorderStatusAudioSaved;

  /// Recorder phase and elapsed time.
  ///
  /// In en, this message translates to:
  /// **'Audio ready'**
  String get audioRecorderStatusAudioReady;

  /// Recording bar control that starts a recording with a live transcript.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get liveTranscriptStart;

  /// Recording bar control that discards the recording in progress.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get liveTranscriptCancel;

  /// Recording bar status while the microphone opens.
  ///
  /// In en, this message translates to:
  /// **'Opening the microphone'**
  String get liveTranscriptStatusStarting;

  /// Recording bar status while audio is recorded and transcribed.
  ///
  /// In en, this message translates to:
  /// **'Recording and transcribing'**
  String get liveTranscriptStatusListening;

  /// Recording bar status while the recording is paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get liveTranscriptStatusPaused;

  /// Recording bar status while the recording is closed and the transcript completes.
  ///
  /// In en, this message translates to:
  /// **'Finishing the transcript'**
  String get liveTranscriptStatusFinishing;

  /// Transcript view before any words are recognised.
  ///
  /// In en, this message translates to:
  /// **'Speak, and the words appear here.'**
  String get liveTranscriptEmpty;

  /// Transcript view control that scrolls back to the newest words.
  ///
  /// In en, this message translates to:
  /// **'Jump to latest'**
  String get liveTranscriptJumpToLatest;

  /// Accessible name of the transcript view.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcriptViewLabel;

  /// Recording bar status once the audio is saved while the last words are still being transcribed.
  ///
  /// In en, this message translates to:
  /// **'Saved. Finishing the transcript.'**
  String get liveTranscriptStatusDraining;

  /// Recording bar status once the recording and its transcript are saved.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device'**
  String get liveTranscriptStatusSaved;

  /// Recording bar status after the app went to the background during a recording.
  ///
  /// In en, this message translates to:
  /// **'Paused while Tapture was in the background. Everything so far is saved.'**
  String get liveTranscriptStatusPausedBackground;

  /// Recording bar status after a call or another app took the audio.
  ///
  /// In en, this message translates to:
  /// **'Paused by another app or a call.'**
  String get liveTranscriptStatusPausedInterruption;

  /// Recording bar status after the microphone was unplugged or switched off.
  ///
  /// In en, this message translates to:
  /// **'The microphone was turned off. What was recorded is saved.'**
  String get liveTranscriptMicLost;

  /// Recording bar status after microphone access was withdrawn during a recording.
  ///
  /// In en, this message translates to:
  /// **'Microphone access was turned off. What was recorded is saved. Allow access to go on, or stop to keep it.'**
  String get liveTranscriptPermissionRevoked;

  /// Button that retries filing a stopped recording and its transcript.
  ///
  /// In en, this message translates to:
  /// **'Try saving again'**
  String get liveTranscriptRetrySave;

  /// Button that opens the transcript just saved.
  ///
  /// In en, this message translates to:
  /// **'Open transcript'**
  String get liveTranscriptOpen;

  /// Title of the confirmation before a recording in progress is discarded.
  ///
  /// In en, this message translates to:
  /// **'Discard this recording?'**
  String get liveTranscriptCancelTitle;

  /// Message of the confirmation before a recording in progress is discarded.
  ///
  /// In en, this message translates to:
  /// **'It is not added here. The audio file stays in the project folder.'**
  String get liveTranscriptCancelMessage;

  /// Notice while a recording is kept without a live transcript.
  ///
  /// In en, this message translates to:
  /// **'Recording without a live transcript: no speech model is available.'**
  String get liveTranscriptAudioOnly;

  /// Notice while transcription lags behind the recording.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{The transcript is catching up. Recording goes on.} one{The transcript is 1 minute behind. Recording goes on.} other{The transcript is {minutes} minutes behind. Recording goes on.}}'**
  String liveTranscriptBehind(int minutes);

  /// Notice when part of a recording is left untranscribed.
  ///
  /// In en, this message translates to:
  /// **'A part could not be transcribed. Its audio is kept.'**
  String get liveTranscriptUtteranceSkipped;

  /// Notice while transcript text waits to be saved.
  ///
  /// In en, this message translates to:
  /// **'The transcript could not be saved yet. The recording is kept, and saving is tried again.'**
  String get liveTranscriptUnsaved;

  /// Notice when a recording stops at the session length limit.
  ///
  /// In en, this message translates to:
  /// **'The recording reached the longest length allowed and was saved.'**
  String get liveTranscriptSessionLimit;

  /// Notice when a recording stops because storage ran out.
  ///
  /// In en, this message translates to:
  /// **'Storage is full, so recording stopped. What was recorded is saved.'**
  String get liveTranscriptStorageStop;

  /// Notice when storage runs low during a recording.
  ///
  /// In en, this message translates to:
  /// **'Storage is running low. Recording goes on.'**
  String get liveTranscriptStorageLow;

  /// Heading of the transcripts heard from a record's or meeting's audio.
  ///
  /// In en, this message translates to:
  /// **'Transcripts'**
  String get liveTranscriptListTitle;

  /// Name of a transcript that has not been named.
  ///
  /// In en, this message translates to:
  /// **'Untitled transcript'**
  String get liveTranscriptUntitled;

  /// When a transcript was recorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded {when}'**
  String liveTranscriptRowWhen(Object when);

  /// When a transcript was recorded, then the start of its text.
  ///
  /// In en, this message translates to:
  /// **'{when} · {preview}'**
  String liveTranscriptRowDetail(Object when, Object preview);

  /// Marks a transcript whose text was edited beside the original.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get liveTranscriptEdited;

  /// Marks a transcript whose recording ended before it was finished.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get liveTranscriptInterrupted;

  /// Marks a transcript still being recorded.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get liveTranscriptRecording;

  /// Badge saying speech is turned into text on this device, without the network.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get speechOfflineBadge;

  /// Headline of the Transcribe screen when no speech model can run.
  ///
  /// In en, this message translates to:
  /// **'Live transcription needs a speech model on this device.'**
  String get liveTranscriptUnavailable;

  /// What to do when live transcription is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Open Settings, Language, to check the speech model.'**
  String get liveTranscriptUnavailableRecovery;

  /// More menu entry: the transcript history.
  ///
  /// In en, this message translates to:
  /// **'Transcripts'**
  String get navTranscripts;

  /// Title of the transcript history.
  ///
  /// In en, this message translates to:
  /// **'Transcripts'**
  String get transcriptsTitle;

  /// Opens the Transcribe screen to record a new transcript.
  ///
  /// In en, this message translates to:
  /// **'New transcription'**
  String get transcriptsNew;

  /// Headline of the transcript history with no transcripts.
  ///
  /// In en, this message translates to:
  /// **'No transcripts yet'**
  String get transcriptsEmptyHeadline;

  /// Message of the transcript history with no transcripts.
  ///
  /// In en, this message translates to:
  /// **'Record speech and Tapture writes it down on this device. No connection is needed.'**
  String get transcriptsEmptyMessage;

  /// Headline when a transcript search matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No matching transcripts'**
  String get transcriptsNoMatchHeadline;

  /// Prompt of the transcript history search field.
  ///
  /// In en, this message translates to:
  /// **'Search transcripts'**
  String get transcriptsSearchHint;

  /// Headline of the Transcribe screen with no project open.
  ///
  /// In en, this message translates to:
  /// **'Open a project to transcribe'**
  String get transcriptsNoProject;

  /// Why a project is needed before transcribing.
  ///
  /// In en, this message translates to:
  /// **'Recordings and transcripts are saved in the project folder.'**
  String get transcriptsNoProjectMessage;

  /// Title of the screen that records and transcribes speech, and its project menu entry.
  ///
  /// In en, this message translates to:
  /// **'Transcribe'**
  String get transcribeTitle;

  /// Title of one transcript's page.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcriptDetailTitle;

  /// Headline when an opened transcript no longer exists.
  ///
  /// In en, this message translates to:
  /// **'This transcript is not on this device'**
  String get transcriptMissing;

  /// Why an opened transcript is missing.
  ///
  /// In en, this message translates to:
  /// **'It was discarded, or it belongs to a project that is not here.'**
  String get transcriptMissingMessage;

  /// Marks a transcript heard from a capture's recording.
  ///
  /// In en, this message translates to:
  /// **'From a capture'**
  String get transcriptOriginCapture;

  /// Marks a transcript heard from a meeting's recording.
  ///
  /// In en, this message translates to:
  /// **'From a meeting'**
  String get transcriptOriginMeeting;

  /// Marks a transcript recorded on the Transcribe screen.
  ///
  /// In en, this message translates to:
  /// **'Transcription'**
  String get transcriptOriginStandalone;

  /// Notice on a transcript whose recording ended before it was finished.
  ///
  /// In en, this message translates to:
  /// **'Interrupted. What was heard is kept.'**
  String get transcriptStatusInterrupted;

  /// The operator's edit of a transcript, kept beside the original.
  ///
  /// In en, this message translates to:
  /// **'Edited text'**
  String get transcriptEditedLabel;

  /// The transcript exactly as it was heard, never changed.
  ///
  /// In en, this message translates to:
  /// **'Original, as heard'**
  String get transcriptOriginalLabel;

  /// Saves the edited transcript beside the original.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get transcriptSaveEdit;

  /// Confirms an edited transcript was saved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved. The original transcript is kept.'**
  String get transcriptEditSaved;

  /// Removes the edit and shows the transcript as heard.
  ///
  /// In en, this message translates to:
  /// **'Go back to the original'**
  String get transcriptRevert;

  /// Title of the confirmation before an edit is removed.
  ///
  /// In en, this message translates to:
  /// **'Go back to the original transcript?'**
  String get transcriptRevertTitle;

  /// What removing a transcript edit does.
  ///
  /// In en, this message translates to:
  /// **'Your changes are removed. The original stays as it was recorded.'**
  String get transcriptRevertMessage;

  /// Confirms removing a transcript edit.
  ///
  /// In en, this message translates to:
  /// **'Use original'**
  String get transcriptRevertConfirm;

  /// Confirms a transcript edit was removed.
  ///
  /// In en, this message translates to:
  /// **'The original transcript is back.'**
  String get transcriptReverted;

  /// Gives a transcript a new title.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get transcriptRename;

  /// Field for a transcript's title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get transcriptTitleLabel;

  /// The language a transcript was heard in.
  ///
  /// In en, this message translates to:
  /// **'Language: {language}'**
  String transcriptLanguage(Object language);

  /// The speech model that heard a transcript.
  ///
  /// In en, this message translates to:
  /// **'Speech model: {model}'**
  String transcriptModel(Object model);

  /// How long a transcript's recording is.
  ///
  /// In en, this message translates to:
  /// **'Recording {minutes}:{seconds}'**
  String transcriptAudioLength(Object minutes, Object seconds);

  /// A transcript whose recording is not filed on this device.
  ///
  /// In en, this message translates to:
  /// **'The recording was not kept on this device.'**
  String get transcriptNoAudio;

  /// How many parts of a transcript's recording are left untranscribed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All of the recording is transcribed.} one{One part of the recording is not transcribed yet.} other{{count} parts of the recording are not transcribed yet.}}'**
  String transcriptGaps(int count);

  /// Transcribes the parts of a recording left untranscribed, on this device.
  ///
  /// In en, this message translates to:
  /// **'Finish the transcript'**
  String get transcriptFinish;

  /// Confirms the rest of a recording was transcribed.
  ///
  /// In en, this message translates to:
  /// **'The transcript is finished.'**
  String get transcriptFinished;

  /// On a record page, writes down the words of its audio clips that have no transcript yet, on this device.
  ///
  /// In en, this message translates to:
  /// **'Transcribe on this device'**
  String get transcriptTranscribeOnDevice;

  /// Audio evidence association sheet.
  ///
  /// In en, this message translates to:
  /// **'Use audio with'**
  String get captureAudioScopeTitle;

  /// Associates the clip with the most recent/current photo.
  ///
  /// In en, this message translates to:
  /// **'Current photo'**
  String get captureAudioCurrentPhoto;

  /// Associates the clip with the selected photos.
  ///
  /// In en, this message translates to:
  /// **'Selected photos ({count})'**
  String captureAudioSelectedPhotos(int count);

  /// Associates the clip with every photo.
  ///
  /// In en, this message translates to:
  /// **'All photos ({count})'**
  String captureAudioAllPhotos(int count);

  /// Number of durable clips in this capture.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 audio clip attached} other{{count} audio clips attached}}'**
  String captureAudioCount(int count);

  /// Delete photo confirm title.
  ///
  /// In en, this message translates to:
  /// **'Delete this photo?'**
  String get captureDeletePhotoTitle;

  /// Delete photo confirm body.
  ///
  /// In en, this message translates to:
  /// **'It leaves the tray now. The file stays until the retention purge so you can undo.'**
  String get captureDeletePhotoMessage;

  /// Undo delete snack.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get captureUndoDelete;

  /// Photo deleted snack.
  ///
  /// In en, this message translates to:
  /// **'Photo deleted'**
  String get capturePhotoDeleted;

  /// Move photos action.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get captureMovePhotos;

  /// Recovery prompt title.
  ///
  /// In en, this message translates to:
  /// **'Resume capture?'**
  String get captureRecoveryTitle;

  /// Recovery prompt with photo count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{An interrupted session has no photos yet.} one{An interrupted session has 1 photo.} other{An interrupted session has {count} photos.}}'**
  String captureRecoveryMessage(int count);

  /// Resume interrupted session.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get captureResume;

  /// Discard interrupted session.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get captureDiscard;

  /// A discarded session, offered back through Undo.
  ///
  /// In en, this message translates to:
  /// **'Session discarded. Its photos stay recoverable.'**
  String get captureSessionDiscarded;

  /// Rapid mode title.
  ///
  /// In en, this message translates to:
  /// **'Rapid mode'**
  String get captureRapidMode;

  /// One saved item in the rapid-mode list, numbered from 1.
  ///
  /// In en, this message translates to:
  /// **'Item {number}'**
  String captureRapidItem(int number);

  /// A saved rapid-mode item's line: its photo count, then its caption.
  ///
  /// In en, this message translates to:
  /// **'{photosCountphotos} · {caption}'**
  String captureRapidSummary(Object photosCountphotos, Object caption);

  /// Rapid mode's one-tap action: save this item raw and start the next.
  ///
  /// In en, this message translates to:
  /// **'Save and next item'**
  String get captureRapidNext;

  /// Rapid mode's secondary action: queue every item of the run.
  ///
  /// In en, this message translates to:
  /// **'Process all ({count})'**
  String captureRapidProcessAll(int count);

  /// Rapid mode queued the run for processing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 item queued for processing} other{{count} items queued for processing}}'**
  String captureRapidQueued(int count);

  /// Rapid mode before any item is saved.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get captureRapidEmptyHeadline;

  /// What to do first in rapid mode.
  ///
  /// In en, this message translates to:
  /// **'Take photos of the first item, then save it to start the next.'**
  String get captureRapidEmptyMessage;

  /// The photos of the item being captured in rapid mode.
  ///
  /// In en, this message translates to:
  /// **'This item: {photosCountphotos}'**
  String captureRapidCurrent(Object photosCountphotos);

  /// Storage warning, naming the free space left.
  ///
  /// In en, this message translates to:
  /// **'Space is getting low: {free} left. Capture carries on.'**
  String captureStorageLow(Object free);

  /// Storage stop, naming the free space left and the way out.
  ///
  /// In en, this message translates to:
  /// **'Only {free} left, not enough for a new photo. Export a project or clean the cache to make room.'**
  String captureStorageFull(Object free);

  /// Storage stop offers export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get captureStorageExport;

  /// A project with no templates still captures; this offers adding one.
  ///
  /// In en, this message translates to:
  /// **'This project has no templates yet. You can capture now and add one later.'**
  String get captureNoTemplates;

  /// Template picker title.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get capturePickTemplate;

  /// Pin template for this session.
  ///
  /// In en, this message translates to:
  /// **'Pin for session'**
  String get capturePinSession;

  /// A template was pinned to the current context level.
  ///
  /// In en, this message translates to:
  /// **'This template is now used here every time.'**
  String get captureTemplatePinned;

  /// Pin template for this context level.
  ///
  /// In en, this message translates to:
  /// **'Pin for context'**
  String get capturePinContext;

  /// Multi-select count.
  ///
  /// In en, this message translates to:
  /// **'Selected {n}'**
  String captureSelectedCount(int n);

  /// Select all photos.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get captureSelectAll;

  /// Clear photo selection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get captureClearSelection;

  /// Add photo to tray.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get captureAddPhoto;

  /// Sheet title for adding a photo.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get captureAddSheetTitle;

  /// Camera action on the add-photo sheet.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get captureTakePhoto;

  /// Library action on the add-photo sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose from this device'**
  String get captureChoosePhoto;

  /// Quality blur advisory.
  ///
  /// In en, this message translates to:
  /// **'This photo looks blurry.'**
  String get captureQualityBlur;

  /// Quality dark advisory.
  ///
  /// In en, this message translates to:
  /// **'This photo looks dark.'**
  String get captureQualityDark;

  /// Quality overexposed advisory.
  ///
  /// In en, this message translates to:
  /// **'This photo looks overexposed.'**
  String get captureQualityBright;

  /// Quality small-text advisory.
  ///
  /// In en, this message translates to:
  /// **'Small text may be hard to read.'**
  String get captureQualitySmallText;

  /// Saved announcement for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get captureSaved;

  /// Saving announcement.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get captureSaving;

  /// Save failed announcement.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get captureSaveFailed;

  /// Raw evidence committed, but the local processing job did not enqueue.
  ///
  /// In en, this message translates to:
  /// **'The capture was saved, but processing could not be queued.'**
  String get captureEnqueueFailed;

  /// A save with nothing to save.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo or a caption before saving.'**
  String get captureNeedsEvidence;

  /// What to do about [captureNeedsEvidence].
  ///
  /// In en, this message translates to:
  /// **'Add evidence, then try again.'**
  String get captureNeedsEvidenceRecovery;

  /// A reorder that would drop photos.
  ///
  /// In en, this message translates to:
  /// **'The photo order is incomplete.'**
  String get captureOrderIncomplete;

  /// What to do about [captureOrderIncomplete].
  ///
  /// In en, this message translates to:
  /// **'Keep every photo in the tray and try again.'**
  String get captureOrderIncompleteRecovery;

  /// A capture change the device could not store.
  ///
  /// In en, this message translates to:
  /// **'That change could not be saved.'**
  String get captureChangeNotSaved;

  /// What to do about [captureChangeNotSaved].
  ///
  /// In en, this message translates to:
  /// **'Try again. Nothing already captured was lost.'**
  String get captureChangeNotSavedRecovery;

  /// Editing a saved record where no record store is available.
  ///
  /// In en, this message translates to:
  /// **'Saved records cannot be edited on this device.'**
  String get captureRecordsUnavailable;

  /// What to do about [captureRecordsUnavailable].
  ///
  /// In en, this message translates to:
  /// **'Open the record on a device that stores records.'**
  String get captureRecordsUnavailableRecovery;

  /// Status line when no template is pinned.
  ///
  /// In en, this message translates to:
  /// **'No template'**
  String get statusNoTemplate;

  /// Project and context together on the status line.
  ///
  /// In en, this message translates to:
  /// **'{project} · {context}'**
  String statusWhere(Object project, Object context);

  /// Unmetered path.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get networkOnline;

  /// Metered path.
  ///
  /// In en, this message translates to:
  /// **'Metered'**
  String get networkMetered;

  /// Radio is down; not an operator choice.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get networkOffline;

  /// The operator forced offline.
  ///
  /// In en, this message translates to:
  /// **'Offline by choice'**
  String get networkOfflineByChoice;

  /// Manual offline switch title.
  ///
  /// In en, this message translates to:
  /// **'Stay offline'**
  String get settingsOfflineTitle;

  /// What keeps working while the switch is on.
  ///
  /// In en, this message translates to:
  /// **'Everything still works except sending.'**
  String get settingsOfflineEffect;

  /// How many records still need processing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 unprocessed} one{1 unprocessed} other{{count} unprocessed}}'**
  String unprocessedCount(int count);

  /// Why work continues without a network. Not an error.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Captures stay on this device.'**
  String get offlineWorking;

  /// Title of the last-resort crash recovery screen.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Reassurance that a crash did not wipe local work.
  ///
  /// In en, this message translates to:
  /// **'Your work is still on this device.'**
  String get workStillOnDevice;

  /// Remounts the failed subtree under the existing provider scope.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// Writes the diagnostics buffer to a shareable file.
  ///
  /// In en, this message translates to:
  /// **'Export log'**
  String get exportLog;

  /// Opens the recycle bin.
  ///
  /// In en, this message translates to:
  /// **'Recycle bin'**
  String get openRecycleBin;

  /// Title of the page an unknown path opens.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// Why an unknown path shows no screen. [path] is shown as given.
  ///
  /// In en, this message translates to:
  /// **'The page \"{path}\" is not in Tapture.'**
  String notFoundMessage(Object path);

  /// Recovery for an unknown path. Try again opens Projects.
  ///
  /// In en, this message translates to:
  /// **'Try again to go back to Projects.'**
  String get notFoundRecovery;

  /// Window and task-switcher title of the development install.
  ///
  /// In en, this message translates to:
  /// **'Tapture Dev'**
  String get appNameDev;

  /// Settings root title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings index group headings.
  ///
  /// In en, this message translates to:
  /// **'Profile and capture'**
  String get settingsGroupProfileCapture;

  /// Settings for AI and visual appearance.
  ///
  /// In en, this message translates to:
  /// **'Intelligence and appearance'**
  String get settingsGroupIntelligenceAppearance;

  /// Settings for durable storage and access protection.
  ///
  /// In en, this message translates to:
  /// **'Storage and security'**
  String get settingsGroupStorageSecurity;

  /// Product information settings group.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsGroupAbout;

  /// Operator tile supporting line.
  ///
  /// In en, this message translates to:
  /// **'Name, initials and contact on this device.'**
  String get settingsOperatorSubtitle;

  /// Capture tile supporting line.
  ///
  /// In en, this message translates to:
  /// **'Camera, dates, location and how new files are named.'**
  String get settingsCaptureSubtitle;

  /// Capture settings: the row and its page share this title, and it is
  ///    not the Capture destination's name.
  ///
  /// In en, this message translates to:
  /// **'Capture defaults'**
  String get settingsCaptureTitle;

  /// Relay row under Settings.
  ///
  /// In en, this message translates to:
  /// **'Send changes between this project\'\'s devices.'**
  String get settingsRelaySubtitle;

  /// AI section title. The screen arrives in a later phase.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get settingsAiTitle;

  /// AI tile supporting line.
  ///
  /// In en, this message translates to:
  /// **'When and how proposals run.'**
  String get settingsAiSubtitle;

  /// Language section title. The screen arrives in a later phase.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// Language tile supporting line.
  ///
  /// In en, this message translates to:
  /// **'App and voice.'**
  String get settingsLanguageSubtitle;

  /// The language screens and messages are shown in.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// Why the app language offers one choice today.
  ///
  /// In en, this message translates to:
  /// **'English. Screens and messages use this language.'**
  String get settingsAppLanguageEffect;

  /// The language dictation listens for.
  ///
  /// In en, this message translates to:
  /// **'Voice language'**
  String get settingsVoiceLanguage;

  /// Heading of the on-device speech settings on the Language screen.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition'**
  String get settingsSpeechSection;

  /// Which engine turns speech into text: the app's own on-device model.
  ///
  /// In en, this message translates to:
  /// **'On this device: {model}.'**
  String settingsSpeechEngineWhisper(Object model);

  /// Which engine turns speech into text: the operating system's recogniser, kept on the device.
  ///
  /// In en, this message translates to:
  /// **'Speech is turned into text by this device’s own speech service, on the device only.'**
  String get settingsSpeechEnginePlatform;

  /// No engine can turn speech into text on this device now.
  ///
  /// In en, this message translates to:
  /// **'Voice input is not available on this device yet.'**
  String get settingsSpeechEngineNone;

  /// Name of the speed-or-accuracy speech setting.
  ///
  /// In en, this message translates to:
  /// **'Transcription quality'**
  String get settingsSpeechQuality;

  /// What the transcription quality setting changes.
  ///
  /// In en, this message translates to:
  /// **'Automatic chooses a model that fits this device.'**
  String get settingsSpeechQualityEffect;

  /// Quality choice: the device decides.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settingsSpeechQualityAuto;

  /// Quality choice: always the fast model.
  ///
  /// In en, this message translates to:
  /// **'Faster, uses less battery'**
  String get settingsSpeechQualityFast;

  /// Quality choice: the largest model the device can hold.
  ///
  /// In en, this message translates to:
  /// **'More accurate, needs a stronger device'**
  String get settingsSpeechQualityAccurate;

  /// Heading of the list of speech model files.
  ///
  /// In en, this message translates to:
  /// **'Speech models'**
  String get settingsSpeechModels;

  /// Name of the smallest, quickest speech model.
  ///
  /// In en, this message translates to:
  /// **'Fast model'**
  String get settingsSpeechModelFast;

  /// Name of the middle speech model.
  ///
  /// In en, this message translates to:
  /// **'Balanced model'**
  String get settingsSpeechModelBalanced;

  /// Name of the largest, most accurate speech model.
  ///
  /// In en, this message translates to:
  /// **'Accurate model'**
  String get settingsSpeechModelAccurate;

  /// Name of the small model that notices when someone speaks.
  ///
  /// In en, this message translates to:
  /// **'Voice detector'**
  String get settingsSpeechModelVad;

  /// Where a speech model came from: the app itself.
  ///
  /// In en, this message translates to:
  /// **'Included with the app'**
  String get settingsSpeechModelBundled;

  /// Where a speech model came from: a file the operator imported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get settingsSpeechModelImported;

  /// Where a speech model comes from: not in the app, only by import.
  ///
  /// In en, this message translates to:
  /// **'Import only'**
  String get settingsSpeechModelImportOnly;

  /// A speech model file is on this device and has not been checked this session.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get settingsSpeechModelPresent;

  /// A speech model file matched its published size and fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Checked'**
  String get settingsSpeechModelVerified;

  /// A speech model file is not on this device.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get settingsSpeechModelMissing;

  /// A speech model file failed a check.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get settingsSpeechModelDamaged;

  /// Marks the speech model that turns speech into text now.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get settingsSpeechModelInUse;

  /// A speech model row's supporting line: where it came from, its state and its size.
  ///
  /// In en, this message translates to:
  /// **'{origin} · {state} · {size}'**
  String settingsSpeechModelDetail(Object origin, Object state, Object size);

  /// Warns that a speech model does not fit this device now.
  ///
  /// In en, this message translates to:
  /// **'Too large for the memory this device has free. A smaller model is used.'**
  String get settingsSpeechTooLarge;

  /// Checks a speech model file against its published fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get settingsSpeechVerify;

  /// A speech model passed its check.
  ///
  /// In en, this message translates to:
  /// **'The {model} matches its published file.'**
  String settingsSpeechVerified(Object model);

  /// A speech model failed its check.
  ///
  /// In en, this message translates to:
  /// **'The {model} does not match its published file. Import it again or reinstall the app.'**
  String settingsSpeechVerifyMismatch(Object model);

  /// Picks a speech model file to add to this device.
  ///
  /// In en, this message translates to:
  /// **'Import a speech model'**
  String get settingsSpeechImport;

  /// An imported speech model passed its check and was added.
  ///
  /// In en, this message translates to:
  /// **'The {model} was checked and added.'**
  String settingsSpeechImported(Object model);

  /// Removes an imported speech model from this device.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get settingsSpeechRemove;

  /// Title of the confirmation before an imported speech model is removed.
  ///
  /// In en, this message translates to:
  /// **'Remove the {model}?'**
  String settingsSpeechRemoveTitle(Object model);

  /// What removing an imported speech model does.
  ///
  /// In en, this message translates to:
  /// **'Its file is deleted from this device. Speech uses a smaller model until you import it again.'**
  String get settingsSpeechRemoveMessage;

  /// An imported speech model was removed.
  ///
  /// In en, this message translates to:
  /// **'The {model} was removed.'**
  String settingsSpeechRemoved(Object model);

  /// Voice-language names, each in its own language's usual English name.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// French.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// Swahili.
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get languageSwahili;

  /// Portuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languagePortuguese;

  /// Spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// Arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// Appearance section title.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceTitle;

  /// Appearance tile supporting line.
  ///
  /// In en, this message translates to:
  /// **'System, light, dark or outdoor.'**
  String get settingsAppearanceSubtitle;

  /// Follow the device light or dark setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// Always the light palette.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// Always the dark palette.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// High-contrast outdoor palettes; still follows the device.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get themeModeOutdoor;

  /// Storage section title.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorageTitle;

  /// Storage tile supporting line.
  ///
  /// In en, this message translates to:
  /// **'Space used, cache and how long files stay.'**
  String get settingsStorageSubtitle;

  /// Specification "Data" section. Copy rejects the word "data".
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get settingsFilesTitle;

  /// Files tile supporting line.
  ///
  /// In en, this message translates to:
  /// **'Import, export, uploads and merges.'**
  String get settingsFilesSubtitle;

  /// Files row that opens the open project's exports.
  ///
  /// In en, this message translates to:
  /// **'Save the open project as a package or spreadsheet.'**
  String get settingsFilesExportSubtitle;

  /// Files row that brings a package or spreadsheet in.
  ///
  /// In en, this message translates to:
  /// **'Bring in a project package or a spreadsheet.'**
  String get settingsFilesImportSubtitle;

  /// Files row that opens the open project's merge.
  ///
  /// In en, this message translates to:
  /// **'Combine a package from another device into the open project.'**
  String get settingsFilesMergeSubtitle;

  /// Why export and merge are not offered with no project open.
  ///
  /// In en, this message translates to:
  /// **'Open a project to export it or merge into it.'**
  String get settingsFilesNoProject;

  /// Files row for past uploads.
  ///
  /// In en, this message translates to:
  /// **'What was sent to each destination.'**
  String get settingsFilesUploadsSubtitle;

  /// Security section title. The screen arrives in a later phase.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurityTitle;

  /// Security tile supporting line.
  ///
  /// In en, this message translates to:
  /// **'App lock and export encryption.'**
  String get settingsSecuritySubtitle;

  /// About section title.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// About tile supporting line.
  ///
  /// In en, this message translates to:
  /// **'Version and licences.'**
  String get settingsAboutSubtitle;

  /// Templates row under Settings.
  ///
  /// In en, this message translates to:
  /// **'Create, import and edit this project\'\'s templates.'**
  String get settingsTemplatesSubtitle;

  /// Unprocessed row under Settings.
  ///
  /// In en, this message translates to:
  /// **'Records waiting to be processed.'**
  String get settingsQueueSubtitle;

  /// Camera default row.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get settingsCamera;

  /// Effect of the camera default.
  ///
  /// In en, this message translates to:
  /// **'Used at the start of the next session.'**
  String get settingsCameraEffect;

  /// Label for the photo camera default.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get settingsCameraPhoto;

  /// Document camera default.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get settingsCameraDocument;

  /// Auto-filled dates row.
  ///
  /// In en, this message translates to:
  /// **'Fill dates automatically'**
  String get settingsAutoFillDates;

  /// Effect of auto-filled dates.
  ///
  /// In en, this message translates to:
  /// **'New captures get today without asking.'**
  String get settingsAutoFillDatesEffect;

  /// GPS row.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get settingsGps;

  /// Why GPS stays off until a person turns it on (FE-SEC-07).
  ///
  /// In en, this message translates to:
  /// **'Off until you turn it on, so a location is never stored by accident.'**
  String get settingsGpsWhyOff;

  /// Photo quality row.
  ///
  /// In en, this message translates to:
  /// **'Photo quality'**
  String get settingsPhotoQuality;

  /// Effect of photo quality.
  ///
  /// In en, this message translates to:
  /// **'Higher quality makes larger files.'**
  String get settingsPhotoQualityEffect;

  /// Standard JPEG quality label.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get settingsQualityStandard;

  /// Smaller JPEG quality label.
  ///
  /// In en, this message translates to:
  /// **'Smaller files'**
  String get settingsQualitySmaller;

  /// Folder strategy row.
  ///
  /// In en, this message translates to:
  /// **'Photo folders'**
  String get settingsFolderStrategy;

  /// Folder strategy applies only to files not yet written.
  ///
  /// In en, this message translates to:
  /// **'Applies to new files only. Existing files stay put.'**
  String get settingsFolderStrategyNewFilesOnly;

  /// Folder strategy: group by context.
  ///
  /// In en, this message translates to:
  /// **'By context'**
  String get settingsFolderByContext;

  /// Folder strategy: group by template.
  ///
  /// In en, this message translates to:
  /// **'By template'**
  String get settingsFolderByTemplate;

  /// Folder strategy: group by capture date.
  ///
  /// In en, this message translates to:
  /// **'By date'**
  String get settingsFolderByDate;

  /// Folder strategy: no extra folders.
  ///
  /// In en, this message translates to:
  /// **'One folder'**
  String get settingsFolderFlat;

  /// Naming pattern row.
  ///
  /// In en, this message translates to:
  /// **'File names'**
  String get settingsNamingPattern;

  /// Sheet title when editing the naming pattern.
  ///
  /// In en, this message translates to:
  /// **'File name pattern'**
  String get settingsNamingEdit;

  /// Effect of the naming pattern.
  ///
  /// In en, this message translates to:
  /// **'How a new photo file is named.'**
  String get settingsNamingPatternEffect;

  /// Camera row, including the current value and its effect.
  ///
  /// In en, this message translates to:
  /// **'{label}. {settingsCameraEffect}'**
  String settingsCameraSubtitle(Object label, Object settingsCameraEffect);

  /// Photo-quality row, including the current value and its effect.
  ///
  /// In en, this message translates to:
  /// **'{label}. {settingsPhotoQualityEffect}'**
  String settingsPhotoQualitySubtitle(
    Object label,
    Object settingsPhotoQualityEffect,
  );

  /// Naming-pattern row, including the current value and its effect.
  ///
  /// In en, this message translates to:
  /// **'{pattern}. {settingsNamingPatternEffect}'**
  String settingsNamingSubtitle(
    Object pattern,
    Object settingsNamingPatternEffect,
  );

  /// Folder strategy row, including the new-files-only statement.
  ///
  /// In en, this message translates to:
  /// **'{strategy}. {settingsFolderStrategyNewFilesOnly}'**
  String settingsFolderStrategySubtitle(
    Object strategy,
    Object settingsFolderStrategyNewFilesOnly,
  );

  /// Projects group on the storage screen.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get settingsProjectsHeader;

  /// Free-space group on the storage screen.
  ///
  /// In en, this message translates to:
  /// **'Free space'**
  String get settingsHeadroomHeader;

  /// Retention group on the storage screen.
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get settingsRetentionHeader;

  /// Storage-root row name.
  ///
  /// In en, this message translates to:
  /// **'Storage folder'**
  String get settingsStorageRoot;

  /// Snack after a new storage folder is saved: files move there on restart.
  ///
  /// In en, this message translates to:
  /// **'Saved. Tapture uses the new folder the next time it opens.'**
  String get settingsStorageRootAfterRestart;

  /// Total volume label.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get settingsVolumeTotal;

  /// Used volume label.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get settingsVolumeUsed;

  /// Available volume label.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get settingsVolumeAvailable;

  /// The three volume figures on one line.
  ///
  /// In en, this message translates to:
  /// **'{settingsVolumeTotal} {total} · {settingsVolumeUsed} {used} · {settingsVolumeAvailable} {available}'**
  String settingsVolumeFigures(
    Object settingsVolumeTotal,
    Object total,
    Object settingsVolumeUsed,
    Object used,
    Object settingsVolumeAvailable,
    Object available,
  );

  /// Headroom is ample.
  ///
  /// In en, this message translates to:
  /// **'Plenty of space'**
  String get settingsHeadroomAmple;

  /// Headroom is low.
  ///
  /// In en, this message translates to:
  /// **'Space is getting low'**
  String get settingsHeadroomLow;

  /// Headroom is critical.
  ///
  /// In en, this message translates to:
  /// **'Not enough space for a new photo'**
  String get settingsHeadroomCritical;

  /// Clear-cache row.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearCache;

  /// Effect of clearing the cache.
  ///
  /// In en, this message translates to:
  /// **'Removes derived copies only. Originals stay.'**
  String get settingsClearCacheEffect;

  /// Cache row with the current size.
  ///
  /// In en, this message translates to:
  /// **'{settingsCache} · {size}. {settingsClearCacheEffect}'**
  String settingsCacheSize(
    Object settingsCache,
    Object size,
    Object settingsClearCacheEffect,
  );

  /// Retention row with the current window.
  ///
  /// In en, this message translates to:
  /// **'{settingsRetentionDaysdays}. {settingsRetentionEffect}'**
  String settingsRetentionSubtitle(
    Object settingsRetentionDaysdays,
    Object settingsRetentionEffect,
  );

  /// Confirm title for clearing the cache.
  ///
  /// In en, this message translates to:
  /// **'Clear the cache?'**
  String get settingsClearCacheTitle;

  /// Confirm body for clearing the cache.
  ///
  /// In en, this message translates to:
  /// **'Thumbnails and upload copies will be removed. Original photos stay.'**
  String get settingsClearCacheMessage;

  /// Storage row, and the page, that checks files against their records.
  ///
  /// In en, this message translates to:
  /// **'Check files'**
  String get storageCheckTitle;

  /// What checking files does.
  ///
  /// In en, this message translates to:
  /// **'Find files with no record and records whose file is gone. Nothing is deleted.'**
  String get storageCheckSubtitle;

  /// Heading over the check of the database's own references.
  ///
  /// In en, this message translates to:
  /// **'Records and references'**
  String get storageCheckDatabaseHeader;

  /// Every reference in the database resolves.
  ///
  /// In en, this message translates to:
  /// **'Every record, value and file reference is whole.'**
  String get storageCheckDatabaseClean;

  /// One broken reference: the table it sits in and the row's id.
  ///
  /// In en, this message translates to:
  /// **'{table} · {id}'**
  String storageCheckFindingRow(Object table, Object id);

  /// Heading over the open project's file check.
  ///
  /// In en, this message translates to:
  /// **'Files in {project}'**
  String storageCheckProjectHeader(Object project);

  /// No project is open, so there is no folder to check.
  ///
  /// In en, this message translates to:
  /// **'Open a project to check its files.'**
  String get storageCheckNoProject;

  /// The open project's folder and its records agree.
  ///
  /// In en, this message translates to:
  /// **'Every file has its record, and every record has its file.'**
  String get storageCheckFilesClean;

  /// The file check cannot run where the app keeps no project files.
  ///
  /// In en, this message translates to:
  /// **'This device keeps no project folder, so its files can\'\'t be checked.'**
  String get storageCheckFilesUnavailable;

  /// What to do when the file check cannot run here.
  ///
  /// In en, this message translates to:
  /// **'Check the files on the phone, tablet or computer that took them.'**
  String get storageCheckFilesUnavailableAction;

  /// Heading over files no record points at.
  ///
  /// In en, this message translates to:
  /// **'Files with no record'**
  String get storageCheckStrayHeader;

  /// A stray file: its size and what tapping it does.
  ///
  /// In en, this message translates to:
  /// **'{size} · Tap to attach it to a record.'**
  String storageCheckStraySubtitle(Object size);

  /// Heading over records whose file is gone.
  ///
  /// In en, this message translates to:
  /// **'Records whose file is gone'**
  String get storageCheckMissingHeader;

  /// A record whose file is gone, before it is marked.
  ///
  /// In en, this message translates to:
  /// **'Tap to mark the file as missing. The record stays.'**
  String get storageCheckMissingSubtitle;

  /// Confirm title for marking a file as missing.
  ///
  /// In en, this message translates to:
  /// **'Mark the file as missing?'**
  String get storageCheckFlagTitle;

  /// Confirm body for marking a file as missing.
  ///
  /// In en, this message translates to:
  /// **'The record and its other evidence stay. Its history notes that this file is gone.'**
  String get storageCheckFlagMessage;

  /// Confirm action for marking a file as missing.
  ///
  /// In en, this message translates to:
  /// **'Mark as missing'**
  String get storageCheckFlagConfirm;

  /// Outcome after marking a file as missing.
  ///
  /// In en, this message translates to:
  /// **'Marked as missing.'**
  String get storageCheckFlagged;

  /// Sheet title for attaching a stray file to a record.
  ///
  /// In en, this message translates to:
  /// **'Attach to a record'**
  String get storageCheckAttachTitle;

  /// Outcome after attaching a stray file.
  ///
  /// In en, this message translates to:
  /// **'File attached to the record.'**
  String get storageCheckAttached;

  /// The project has no record to attach a file to.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get storageCheckNoRecords;

  /// Why a stray file cannot be attached yet.
  ///
  /// In en, this message translates to:
  /// **'Capture a record in this project, then attach the file to it.'**
  String get storageCheckNoRecordsMessage;

  /// Retention row.
  ///
  /// In en, this message translates to:
  /// **'Keep deleted files'**
  String get settingsRetention;

  /// Effect of the retention window.
  ///
  /// In en, this message translates to:
  /// **'How long a deleted file can be restored.'**
  String get settingsRetentionEffect;

  /// Retention window in days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 days} one{1 day} other{{count} days}}'**
  String settingsRetentionDays(int count);

  /// Documents breakdown label.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get settingsDocuments;

  /// Audio breakdown label.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get settingsAudio;

  /// Exports breakdown label.
  ///
  /// In en, this message translates to:
  /// **'Exports'**
  String get settingsExports;

  /// Cache usage row title.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get settingsCache;

  /// Empty storage headline.
  ///
  /// In en, this message translates to:
  /// **'No project folders yet'**
  String get settingsStorageEmptyHeadline;

  /// Empty storage next step.
  ///
  /// In en, this message translates to:
  /// **'Space used appears here once a project has files.'**
  String get settingsStorageEmptyMessage;

  /// A file size shown on the storage screen.
  ///
  /// In en, this message translates to:
  /// **'{bytes} B'**
  String fileSize(int bytes);

  /// A file size shown on the storage screen.
  ///
  /// In en, this message translates to:
  /// **'{byteskround} KB'**
  String fileSizeKB(Object byteskround);

  /// A file size shown on the storage screen.
  ///
  /// In en, this message translates to:
  /// **'{byteskk} MB'**
  String fileSizeMB(Object byteskk);

  /// A file size shown on the storage screen.
  ///
  /// In en, this message translates to:
  /// **'{byteskk} GB'**
  String fileSizeGB(Object byteskk);

  /// Per-project breakdown on one line.
  ///
  /// In en, this message translates to:
  /// **'Photos {photos} · {settingsDocuments} {documents} · {settingsAudio} {audio} · {settingsExports} {exports}'**
  String settingsProjectUse(
    Object photos,
    Object settingsDocuments,
    Object documents,
    Object settingsAudio,
    Object audio,
    Object settingsExports,
    Object exports,
  );

  /// Version row.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Build-number row.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get settingsBuild;

  /// Licences row.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get settingsLicences;

  /// Effect of the licences row.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences used in this app.'**
  String get settingsLicencesEffect;

  /// About row linking the development plan.
  ///
  /// In en, this message translates to:
  /// **'Development plan'**
  String get settingsPlanLink;

  /// About row linking the product specification.
  ///
  /// In en, this message translates to:
  /// **'Specification'**
  String get settingsSpecLink;

  /// A link was copied because no browser can be opened from here.
  ///
  /// In en, this message translates to:
  /// **'Link copied. Paste it into a browser to open it.'**
  String get settingsLinkCopied;

  /// Empty settings headline.
  ///
  /// In en, this message translates to:
  /// **'No settings yet'**
  String get settingsEmptyHeadline;

  /// Empty settings next step.
  ///
  /// In en, this message translates to:
  /// **'Settings for this device will appear here.'**
  String get settingsEmptyMessage;

  /// Empty capture-settings headline.
  ///
  /// In en, this message translates to:
  /// **'No capture defaults yet'**
  String get settingsCaptureEmptyHeadline;

  /// Empty capture-settings next step.
  ///
  /// In en, this message translates to:
  /// **'Camera, dates and GPS will appear here.'**
  String get settingsCaptureEmptyMessage;

  /// Empty about headline.
  ///
  /// In en, this message translates to:
  /// **'No version yet'**
  String get settingsAboutEmptyHeadline;

  /// Empty about next step.
  ///
  /// In en, this message translates to:
  /// **'The version and licences will appear here.'**
  String get settingsAboutEmptyMessage;

  /// Unlock-gate title.
  ///
  /// In en, this message translates to:
  /// **'Unlock Tapture'**
  String get appLockUnlockTitle;

  /// Settings title for the PIN lock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLockTitle;

  /// PIN field.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get appLockPin;

  /// Current PIN when changing or removing the lock.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get appLockCurrentPin;

  /// New PIN when setting or changing the lock.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get appLockNewPin;

  /// Confirm-PIN field.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get appLockConfirmPin;

  /// Sets the lock for the first time.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get appLockSet;

  /// Replaces the stored PIN.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get appLockChange;

  /// Turns the lock off.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get appLockRemove;

  /// Unlock-gate submit.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get appLockUnlock;

  /// Offers the device biometric path when it is enrolled.
  ///
  /// In en, this message translates to:
  /// **'Unlock with this device'**
  String get appLockBiometrics;

  /// Effect of setting a PIN.
  ///
  /// In en, this message translates to:
  /// **'Required the next time the app opens or returns.'**
  String get appLockSetEffect;

  /// Effect of removing the PIN.
  ///
  /// In en, this message translates to:
  /// **'The next open will not ask for a PIN.'**
  String get appLockRemoveEffect;

  /// Confirm title before the PIN is removed.
  ///
  /// In en, this message translates to:
  /// **'Remove the PIN?'**
  String get appLockRemoveConfirmTitle;

  /// Helper under the current-PIN field while the lock is on.
  ///
  /// In en, this message translates to:
  /// **'Needed to change or remove the PIN.'**
  String get appLockCurrentPinHelper;

  /// Remove was chosen with the current-PIN field empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN, then remove it.'**
  String get appLockRemoveNeedsPin;

  /// Stated when the lock is armed.
  ///
  /// In en, this message translates to:
  /// **'App lock is on.'**
  String get appLockOn;

  /// Stated when no PIN is stored.
  ///
  /// In en, this message translates to:
  /// **'App lock is off. Set a PIN to require it on launch and resume.'**
  String get appLockOff;

  /// PIN shape.
  ///
  /// In en, this message translates to:
  /// **'Use 4 to 8 digits.'**
  String get appLockPinLength;

  /// Confirm field does not match.
  ///
  /// In en, this message translates to:
  /// **'The two PINs do not match.'**
  String get appLockPinMismatch;

  /// Submitted PIN does not match the stored hash.
  ///
  /// In en, this message translates to:
  /// **'That PIN does not match.'**
  String get appLockWrongPin;

  /// Recovery path. Does not offer a wipe (FE-SIMP-09).
  ///
  /// In en, this message translates to:
  /// **'Nobody can reset this PIN. Your files stay on this device. Nothing here deletes them.'**
  String get appLockRecovery;

  /// Closes a dialog or panel without acting.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// The floating feedback control: its label, tooltip and semantic name.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// How the floating feedback control behaves, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Opens the feedback options. Drag to move it.'**
  String get feedbackButtonHint;

  /// Opens the form to write feedback.
  ///
  /// In en, this message translates to:
  /// **'Give us feedback'**
  String get feedbackGive;

  /// Opens the filter to download feedback as a spreadsheet and screenshots.
  ///
  /// In en, this message translates to:
  /// **'Download feedback'**
  String get feedbackDownload;

  /// Opens the filter to delete feedback.
  ///
  /// In en, this message translates to:
  /// **'Delete feedback'**
  String get feedbackDelete;

  /// Where feedback goes. Nothing is sent (FE-SEC-10).
  ///
  /// In en, this message translates to:
  /// **'Saved on this device only. Nothing is sent anywhere.'**
  String get feedbackStaysOnDevice;

  /// Feedback type: anything that is not one of the others.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get feedbackCategoryGeneral;

  /// Feedback type: something that works but could work better.
  ///
  /// In en, this message translates to:
  /// **'Improvement'**
  String get feedbackCategoryImprovement;

  /// Feedback type: something is wrong.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get feedbackCategoryError;

  /// Feedback type: an idea.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get feedbackCategorySuggestion;

  /// Feedback type: the operator names it.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackCategoryOther;

  /// Who wrote an entry: enrolled with the organisation.
  ///
  /// In en, this message translates to:
  /// **'Signed-in user'**
  String get feedbackSubmitterSignedIn;

  /// Who wrote an entry: a named local operator.
  ///
  /// In en, this message translates to:
  /// **'Local operator'**
  String get feedbackSubmitterLocal;

  /// Who wrote an entry: no name was set.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get feedbackSubmitterAnonymous;

  /// Device kind: a touch phone.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get feedbackDeviceMobile;

  /// Device kind: a touch tablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get feedbackDeviceTablet;

  /// Device kind: a desktop, natively or in a desktop browser.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get feedbackDeviceDesktop;

  /// Label of the feedback type choice.
  ///
  /// In en, this message translates to:
  /// **'Type of feedback'**
  String get feedbackType;

  /// Label of the field that names an "other" type.
  ///
  /// In en, this message translates to:
  /// **'What kind of feedback is it?'**
  String get feedbackOtherType;

  /// The "other" type was chosen but not named.
  ///
  /// In en, this message translates to:
  /// **'Say what kind of feedback it is'**
  String get feedbackOtherRequired;

  /// Label of the feedback text.
  ///
  /// In en, this message translates to:
  /// **'Your feedback'**
  String get feedbackMessage;

  /// Prompt inside the empty feedback text.
  ///
  /// In en, this message translates to:
  /// **'What happened, or what would make this better?'**
  String get feedbackMessageHint;

  /// The feedback text was empty.
  ///
  /// In en, this message translates to:
  /// **'Write your feedback'**
  String get feedbackMessageRequired;

  /// Attaches the screenshot taken when Feedback was tapped.
  ///
  /// In en, this message translates to:
  /// **'Attach screenshot'**
  String get feedbackAttachScreenshot;

  /// Continues a feedback draft started on another screen.
  ///
  /// In en, this message translates to:
  /// **'Continue feedback'**
  String get feedbackContinue;

  /// Adds a screenshot of the screen currently under the overlay.
  ///
  /// In en, this message translates to:
  /// **'Screenshot current screen'**
  String get feedbackAddScreen;

  /// Opt-in so Screenshot current screen includes the Give us feedback chrome.
  ///    Short enough to stay on one line beside its checkbox at 360 dp.
  ///
  /// In en, this message translates to:
  /// **'Include feedback UI'**
  String get feedbackIncludeUi;

  /// Opens the browser display picker for another window or OS surface.
  ///
  /// In en, this message translates to:
  /// **'Screenshot external window'**
  String get feedbackAddWindow;

  /// Stops the shared window so later taps open the picker again.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing window'**
  String get feedbackStopSharing;

  /// Non-colour signal that Screenshot external window is live.
  ///
  /// In en, this message translates to:
  /// **'Sharing a window. Each tap adds a screenshot.'**
  String get feedbackSharingWindow;

  /// Label of a still taken from another window.
  ///
  /// In en, this message translates to:
  /// **'External window'**
  String get feedbackOtherWindow;

  /// Opens the device camera for a photo to attach.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get feedbackTakePhoto;

  /// Opens the device library for photos to attach.
  ///
  /// In en, this message translates to:
  /// **'Choose photos'**
  String get feedbackChoosePhoto;

  /// How to capture another Tapture screen when other windows cannot be
  ///    shared.
  ///
  /// In en, this message translates to:
  /// **'Another screen: tap Continue later, open it, then tap Screenshot current screen in the bar.'**
  String get feedbackShotTipScreens;

  /// How to attach a system screenshot of another app.
  ///
  /// In en, this message translates to:
  /// **'Another app: take a screenshot with your device, then add it with Choose photos.'**
  String get feedbackShotTipApps;

  /// The attach checkbox, counting the images it covers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Attach 1 image} other{Attach {count} images}}'**
  String feedbackAttachImages(int count);

  /// How many images a kept draft holds, for the compact bar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 image} other{{count} images}}'**
  String feedbackImageCount(int count);

  /// Semantic name of a larger attached-photo preview.
  ///
  /// In en, this message translates to:
  /// **'Photo preview'**
  String get feedbackShotPreview;

  /// Discards the in-progress feedback draft.
  ///
  /// In en, this message translates to:
  /// **'Discard draft'**
  String get feedbackDiscardDraft;

  /// Title of the discard-draft confirm.
  ///
  /// In en, this message translates to:
  /// **'Discard this feedback?'**
  String get feedbackDiscardDraftTitle;

  /// Body of the discard-draft confirm, naming the image count (FE-SIMP-07).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{This feedback will be cleared.} one{This feedback and its 1 image will be cleared.} other{This feedback and its {count} images will be cleared.}}'**
  String feedbackDiscardDraftMessage(int count);

  /// Collapses the feedback form so the rest of the app stays usable.
  ///
  /// In en, this message translates to:
  /// **'Continue later'**
  String get feedbackContinueLater;

  /// Compact bar while a draft is kept across screens.
  ///
  /// In en, this message translates to:
  /// **'Opens the feedback you started. Keep typing or speaking here.'**
  String get feedbackDraftBarHint;

  /// Announced when a screenshot of [screen] was added to the draft.
  ///
  /// In en, this message translates to:
  /// **'Added a screenshot of {screen}'**
  String feedbackShotAdded(Object screen);

  /// The draft already holds as many photos as it will take.
  ///
  /// In en, this message translates to:
  /// **'Remove a photo before adding another.'**
  String get feedbackShotsFull;

  /// What the screenshot shows, named for the screen it was taken on.
  ///
  /// In en, this message translates to:
  /// **'Screenshot of {screen}'**
  String feedbackScreenshotOf(Object screen);

  /// The draft holds no screenshot or photo yet.
  ///
  /// In en, this message translates to:
  /// **'No images yet'**
  String get feedbackNoScreenshot;

  /// Semantic name of the screenshot preview.
  ///
  /// In en, this message translates to:
  /// **'Screenshot preview'**
  String get feedbackScreenshotPreview;

  /// Saves the feedback entry.
  ///
  /// In en, this message translates to:
  /// **'Save feedback'**
  String get feedbackSave;

  /// Announced once the entry is durable.
  ///
  /// In en, this message translates to:
  /// **'Feedback saved on this device.'**
  String get feedbackSaved;

  /// Filter: feedback types.
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get feedbackTypes;

  /// Filter: earliest submission.
  ///
  /// In en, this message translates to:
  /// **'Submitted from'**
  String get feedbackFrom;

  /// Filter: latest submission.
  ///
  /// In en, this message translates to:
  /// **'Submitted to'**
  String get feedbackTo;

  /// The date range runs backwards.
  ///
  /// In en, this message translates to:
  /// **'The start is after the end. Swap them or clear one.'**
  String get feedbackRangeBackwards;

  /// Filter: screens feedback was given on.
  ///
  /// In en, this message translates to:
  /// **'Screens'**
  String get feedbackScreens;

  /// Filter: platforms.
  ///
  /// In en, this message translates to:
  /// **'Platforms'**
  String get feedbackPlatforms;

  /// Filter: device types.
  ///
  /// In en, this message translates to:
  /// **'Device types'**
  String get feedbackDeviceTypes;

  /// Filter: who submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted by'**
  String get feedbackSubmittedBy;

  /// Filter: whether a screenshot is attached.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get feedbackScreenshot;

  /// Screenshot filter: either way.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get feedbackScreenshotAny;

  /// Screenshot filter: attached.
  ///
  /// In en, this message translates to:
  /// **'With'**
  String get feedbackScreenshotWith;

  /// Screenshot filter: not attached.
  ///
  /// In en, this message translates to:
  /// **'Without'**
  String get feedbackScreenshotWithout;

  /// Prompt on the feedback text search.
  ///
  /// In en, this message translates to:
  /// **'Search the feedback text'**
  String get feedbackSearch;

  /// Resets every feedback filter.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get feedbackClearFilters;

  /// How many entries the filters let through.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{matching} of 1 entry matches} other{{matching} of {count} entries match}}'**
  String feedbackMatching(int count, int matching);

  /// Downloads the matching entries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to download} one{Download 1 entry} other{Download {count} entries}}'**
  String feedbackDownloadCount(int count);

  /// The browser took the download.
  ///
  /// In en, this message translates to:
  /// **'Download started.'**
  String get feedbackDownloadStarted;

  /// The archive was written to [location] on this device.
  ///
  /// In en, this message translates to:
  /// **'Saved to {location}'**
  String feedbackDownloadedTo(Object location);

  /// Shared Downloads subfolder on Android and desktop. The › mirrors with
  ///    the surrounding line in right-to-left layouts (FE-L10N-05).
  ///
  /// In en, this message translates to:
  /// **'Downloads › Tapture'**
  String get downloadsTaptureFolder;

  /// Where archives land, before anything is downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloads go to {place}'**
  String feedbackDownloadsGoTo(Object place);

  /// Opens the system Downloads view or the Tapture folder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get feedbackOpenFolder;

  /// Opens the system picker so the archive can be saved anywhere.
  ///
  /// In en, this message translates to:
  /// **'Save to a folder'**
  String get feedbackSaveToFolder;

  /// Warning when [place] could not be opened.
  ///
  /// In en, this message translates to:
  /// **'The folder could not be opened. Look in {place}.'**
  String feedbackOpenFolderFailed(Object place);

  /// Nothing has been written yet.
  ///
  /// In en, this message translates to:
  /// **'No feedback yet'**
  String get feedbackEmptyHeadline;

  /// Next step when nothing has been written (FE-SIMP-11).
  ///
  /// In en, this message translates to:
  /// **'Tap Feedback on any screen to write the first entry.'**
  String get feedbackEmptyMessage;

  /// The filters let nothing through.
  ///
  /// In en, this message translates to:
  /// **'No feedback matches'**
  String get feedbackNoMatchHeadline;

  /// Next step when the filters let nothing through.
  ///
  /// In en, this message translates to:
  /// **'Change or clear the filters to see more.'**
  String get feedbackNoMatchMessage;

  /// How many entries are ticked for deletion.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None selected} one{1 selected} other{{count} selected}}'**
  String feedbackSelected(int count);

  /// Deletes the ticked entries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Select entries to delete} one{Delete 1 entry} other{Delete {count} entries}}'**
  String feedbackDeleteCount(int count);

  /// Title of the delete confirm, naming the count (FE-SIMP-07).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Delete 1 feedback entry?} other{Delete {count} feedback entries?}}'**
  String feedbackDeleteTitle(int count);

  /// Body of the delete confirm, naming the consequence (FE-SIMP-07).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{It and its screenshot are removed from this device for good. You can undo straight after.} other{They and their screenshots are removed from this device for good. You can undo straight after.}}'**
  String feedbackDeleteMessage(int count);

  /// Announced once the entries are gone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 feedback entry deleted} other{{count} feedback entries deleted}}'**
  String feedbackDeleted(int count);

  /// Loads the next page of entries.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get feedbackShowMore;

  /// One entry's facts on a list row: type, when and where.
  ///
  /// In en, this message translates to:
  /// **'{type} · {when} · {screen}'**
  String feedbackEntryFacts(Object type, Object when, Object screen);

  /// One entry's title on a list row: number, Feedback ID and message.
  ///
  /// In en, this message translates to:
  /// **'{number}. {reference} · {message}'**
  String feedbackEntryTitle(Object number, Object reference, Object message);

  /// Remaining backoff after a failed unlock.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Wait 1 second before trying again.} other{Wait {count} seconds before trying again.}}'**
  String appLockWait(num count);

  /// Queue screen title.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get queueTitle;

  /// Unprocessed count label.
  ///
  /// In en, this message translates to:
  /// **'Unprocessed'**
  String get queueUnprocessed;

  /// Queued count label.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queueQueued;

  /// Failed count label.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get queueFailed;

  /// Today's online request and image totals against the project cap.
  ///
  /// In en, this message translates to:
  /// **'{requests} of {cap} online requests today, {images} images sent'**
  String queueUsage(int requests, int cap, int images);

  /// Unprocessed records, as a complete message.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unprocessed records} one{1 unprocessed record} other{{count} unprocessed records}}'**
  String queueUnprocessedCount(int count);

  /// Records waiting in the queue, as a complete message.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No records queued} one{1 record queued} other{{count} records queued}}'**
  String queueQueuedCount(int count);

  /// Failed jobs, as a complete message.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No failed jobs} one{1 failed job} other{{count} failed jobs}}'**
  String queueFailedCount(int count);

  /// Context groups in the queue.
  ///
  /// In en, this message translates to:
  /// **'By context'**
  String get queueGroupsTitle;

  /// Process every waiting record.
  ///
  /// In en, this message translates to:
  /// **'Process all'**
  String get queueProcessAll;

  /// Process the records in one group.
  ///
  /// In en, this message translates to:
  /// **'Process selected'**
  String get queueProcessSelected;

  /// Empty queue title.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting'**
  String get queueEmptyHeadline;

  /// Empty queue explanation.
  ///
  /// In en, this message translates to:
  /// **'Captured records appear here when they are ready to process.'**
  String get queueEmptyMessage;

  /// Failures list title.
  ///
  /// In en, this message translates to:
  /// **'Failed jobs'**
  String get queueFailedTitle;

  /// Retry one failed job.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get queueRetry;

  /// What a screen reader calls the retry control on [record]'s row.
  ///
  /// In en, this message translates to:
  /// **'Retry {record}'**
  String queueRetryLabel(Object record);

  /// Stop the batch that is running.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get queueCancel;

  /// Why a cancelled batch stopped. Finished work is kept.
  ///
  /// In en, this message translates to:
  /// **'Stopped. The rest stay in the queue.'**
  String get queueCancelled;

  /// End-of-run summary, then why the run stopped early when it did.
  ///
  /// In en, this message translates to:
  /// **'{succeeded} succeeded, {failed} failed'**
  String queueSummary(int succeeded, int failed);

  /// End-of-run summary, then why the run stopped early when it did.
  ///
  /// In en, this message translates to:
  /// **'{counts}. {detail}'**
  String queueSummaryValue(Object counts, Object detail);

  /// A running batch: records finished so far, then what the current one is
  ///    doing when known.
  ///
  /// In en, this message translates to:
  /// **'Processing: {done} done, {failed} failed'**
  String queueProgress(int done, int failed);

  /// A running batch: records finished so far, then what the current one is
  ///    doing when known.
  ///
  /// In en, this message translates to:
  /// **'{counts}. Now: {stage}'**
  String queueProgressNow(Object counts, Object stage);

  /// Asks before the first online call of a session.
  ///
  /// In en, this message translates to:
  /// **'Send for analysis?'**
  String get egressTitle;

  /// Confirms the preview.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get egressSend;

  /// Why a batch stopped when its egress preview was declined.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. The records stay in the queue.'**
  String get egressDecline;

  /// What the preview says will be included.
  ///
  /// In en, this message translates to:
  /// **'{images} compressed images, about {size}. Captions, field names, on-device text, context and predefined row labels are included.'**
  String egressBody(int images, Object size);

  /// Device-held key screen title.
  ///
  /// In en, this message translates to:
  /// **'Provider key'**
  String get apiKeyTitle;

  /// States that device custody is the exception.
  ///
  /// In en, this message translates to:
  /// **'This key lives on this device only. The usual arrangement is for the organisation\'\'s backend to hold it.'**
  String get apiKeyCustody;

  /// Key field label.
  ///
  /// In en, this message translates to:
  /// **'Provider key'**
  String get apiKeyLabel;

  /// Saves the key into secure storage.
  ///
  /// In en, this message translates to:
  /// **'Save key'**
  String get apiKeySave;

  /// Removes the key and clears the selection.
  ///
  /// In en, this message translates to:
  /// **'Remove key'**
  String get apiKeyRemove;

  /// Runs the smallest connection test.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get apiKeyTest;

  /// Shown once the key is stored and hidden.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device'**
  String get apiKeySaved;

  /// Confirm title before the device key is removed.
  ///
  /// In en, this message translates to:
  /// **'Remove the provider key?'**
  String get apiKeyRemoveTitle;

  /// What removing the device key changes.
  ///
  /// In en, this message translates to:
  /// **'The key is deleted from this device, and AI goes back to your organisation\'\'s provider.'**
  String get apiKeyRemoveMessage;

  /// Test connection succeeded.
  ///
  /// In en, this message translates to:
  /// **'Connection succeeded.'**
  String get apiKeySuccess;

  /// The key was rejected.
  ///
  /// In en, this message translates to:
  /// **'The key was rejected.'**
  String get apiKeyAuthFailed;

  /// The test could not reach the network.
  ///
  /// In en, this message translates to:
  /// **'The network is not available.'**
  String get apiKeyNetworkFailed;

  /// The provider answered the test with an error of its own.
  ///
  /// In en, this message translates to:
  /// **'The provider answered with an error. Try again later.'**
  String get apiKeyTestFailed;

  /// Registry-driven AI controls.
  ///
  /// In en, this message translates to:
  /// **'Operation'**
  String get aiOperation;

  /// Provider choice field.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get aiProvider;

  /// Model choice field.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get aiModel;

  /// Operator-facing label for an AI operation id.
  ///
  /// In en, this message translates to:
  /// **'Read text'**
  String get aiOperationLabel;

  /// Operator-facing label for an AI operation id.
  ///
  /// In en, this message translates to:
  /// **'Extract fields'**
  String get aiOperationLabelExtractFields;

  /// Operator-facing label for an AI operation id.
  ///
  /// In en, this message translates to:
  /// **'Refine text'**
  String get aiOperationLabelRefineText;

  /// Operator-facing label for an AI operation id.
  ///
  /// In en, this message translates to:
  /// **'Transcribe audio'**
  String get aiOperationLabelTranscribeAudio;

  /// Credential custody and live availability explanation.
  ///
  /// In en, this message translates to:
  /// **'The organisation backend holds the provider key.'**
  String get aiCustodyTheOrganisationBackendHolds;

  /// Credential custody and live availability explanation.
  ///
  /// In en, this message translates to:
  /// **'This provider uses a device-held credential when enabled by an administrator.'**
  String get aiCustodyThisProviderUsesA;

  /// Credential custody and live availability explanation.
  ///
  /// In en, this message translates to:
  /// **'{owner} This provider is currently unavailable.'**
  String aiCustodyThisProviderIsCurrently(Object owner);

  /// Saved choice fallback explanation.
  ///
  /// In en, this message translates to:
  /// **'The saved provider or model is unavailable. Choose explicitly before analysis can continue.'**
  String get aiSelectionFallback;

  /// Provider test could not run because the descriptor is unavailable.
  ///
  /// In en, this message translates to:
  /// **'This provider is not available. Processing will remain queued.'**
  String get aiProviderUnavailable;

  /// Provider and model do not support the selected operation.
  ///
  /// In en, this message translates to:
  /// **'Choose a provider and model that support this operation.'**
  String get aiSelectionInvalid;

  /// Template question.
  ///
  /// In en, this message translates to:
  /// **'What is this?'**
  String get templateChoiceTitle;

  /// Pins the choice to the current place.
  ///
  /// In en, this message translates to:
  /// **'Use this template for the rest of this location'**
  String get templateChoicePin;

  /// No templates to offer.
  ///
  /// In en, this message translates to:
  /// **'No templates'**
  String get templateChoiceEmptyHeadline;

  /// Why the choice sheet is empty.
  ///
  /// In en, this message translates to:
  /// **'Add a template before choosing one.'**
  String get templateChoiceEmptyMessage;

  /// The third choice when the shortlist is not enough.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get templateChoiceOther;

  /// The step detail when no template was chosen. The record stays queued.
  ///
  /// In en, this message translates to:
  /// **'No template chosen. The record stays in the queue.'**
  String get templateChoiceSkipped;

  /// The chosen template could not be applied to the record.
  ///
  /// In en, this message translates to:
  /// **'That template could not be applied.'**
  String get templateChoiceApplyFailed;

  /// What to do when the chosen template could not be applied.
  ///
  /// In en, this message translates to:
  /// **'Process the record again and choose once more.'**
  String get templateChoiceApplyRecovery;

  /// A record an unattended run set aside for an operator's template
  ///    choice.
  ///
  /// In en, this message translates to:
  /// **'Waiting for someone to choose its template.'**
  String get templateChoiceWaiting;

  /// A record read on the device, its online work left for later.
  ///
  /// In en, this message translates to:
  /// **'Read on this device'**
  String get processReadOnDevice;

  /// Preparing images.
  ///
  /// In en, this message translates to:
  /// **'Preparing images'**
  String get processPreparing;

  /// On-device reading.
  ///
  /// In en, this message translates to:
  /// **'Reading text on device'**
  String get processReading;

  /// Template detection.
  ///
  /// In en, this message translates to:
  /// **'Identifying template'**
  String get processDetecting;

  /// Online extraction.
  ///
  /// In en, this message translates to:
  /// **'Extracting fields'**
  String get processExtracting;

  /// Validation.
  ///
  /// In en, this message translates to:
  /// **'Checking values'**
  String get processChecking;

  /// Local notification title. Counts only.
  ///
  /// In en, this message translates to:
  /// **'Processing finished'**
  String get processingNotificationTitle;

  /// Local notification body. Counts only.
  ///
  /// In en, this message translates to:
  /// **'{succeeded} succeeded, {failed} failed'**
  String processingNotificationBody(int succeeded, int failed);

  /// A document the picker could not hand over.
  ///
  /// In en, this message translates to:
  /// **'That file could not be opened.'**
  String get documentPickFailed;

  /// A chosen file above what this device can open in one piece.
  ///
  /// In en, this message translates to:
  /// **'That file is {fileSizebytes}; this device opens files up to {fileSizeceiling}.'**
  String documentTooLarge(Object fileSizebytes, Object fileSizeceiling);

  /// What to do about a file that is too large.
  ///
  /// In en, this message translates to:
  /// **'Open it in the Tapture app on a phone or computer instead.'**
  String get documentTooLargeRecovery;

  /// A stored export that is no longer where the app wrote it.
  ///
  /// In en, this message translates to:
  /// **'That export is no longer on this device.'**
  String get storedFileMissing;

  /// A package whose project is gone.
  ///
  /// In en, this message translates to:
  /// **'That project is no longer on this device.'**
  String get packageProjectMissing;

  /// A package larger than this device writes or opens.
  ///
  /// In en, this message translates to:
  /// **'This project package would be {fileSizebytes}; this device handles packages up to {fileSizeceiling}.'**
  String packageTooLarge(Object fileSizebytes, Object fileSizeceiling);

  /// What to do about a package that is too large.
  ///
  /// In en, this message translates to:
  /// **'Export from the Tapture app on a phone or computer, which handles larger packages.'**
  String get packageTooLargeRecovery;

  /// A package that could not be written.
  ///
  /// In en, this message translates to:
  /// **'The project package could not be written.'**
  String get packageWriteFailed;

  /// Why a package was refused; [check] is the failed check's name.
  ///
  /// In en, this message translates to:
  /// **'This package is larger than this device can open.'**
  String get packageRejected;

  /// Why a package was refused; [check] is the failed check's name.
  ///
  /// In en, this message translates to:
  /// **'This file is not a Tapture project package.'**
  String get packageRejectedThisFileIsNot;

  /// Why a package was refused; [check] is the failed check's name.
  ///
  /// In en, this message translates to:
  /// **'This package holds a file that would land outside its project.'**
  String get packageRejectedThisPackageHoldsA;

  /// Why a package was refused; [check] is the failed check's name.
  ///
  /// In en, this message translates to:
  /// **'This package is missing a file it lists.'**
  String get packageRejectedThisPackageIsMissing;

  /// Why a package was refused; [check] is the failed check's name.
  ///
  /// In en, this message translates to:
  /// **'Part of this package could not be read.'**
  String get packageRejectedPartOfThisPackage;

  /// Why a package was refused; [check] is the failed check's name.
  ///
  /// In en, this message translates to:
  /// **'This package was made by a newer version of Tapture.'**
  String get packageRejectedThisPackageWasMade;

  /// Why a package was refused; [check] is the failed check's name.
  ///
  /// In en, this message translates to:
  /// **'This package was changed after it was made: a file does not match its checksum.'**
  String get packageRejectedThisPackageWasChanged;

  /// Why a package was refused; [check] is the failed check's name.
  ///
  /// In en, this message translates to:
  /// **'This package could not be opened.'**
  String get packageRejectedThisPackageCouldNot;

  /// What to do about a refused package.
  ///
  /// In en, this message translates to:
  /// **'Nothing was imported. Export the project again on the other device, or update Tapture for a newer package.'**
  String get packageRejectedRecovery;

  /// The row under the Template select that opens the guide.
  ///
  /// In en, this message translates to:
  /// **'What to capture'**
  String get captureGuideTitle;

  /// What the photos should show; the template's fields follow.
  ///
  /// In en, this message translates to:
  /// **'Photos should show'**
  String get captureGuidePhotos;

  /// What to say or type in the caption; the template's fields follow.
  ///
  /// In en, this message translates to:
  /// **'Say or type in the caption'**
  String get captureGuideCaption;

  /// Closes the caption panel of the guide.
  ///
  /// In en, this message translates to:
  /// **'Hide the caption guide'**
  String get captureGuideClose;

  /// Shown while a chosen package is opened and checked.
  ///
  /// In en, this message translates to:
  /// **'Checking the package…'**
  String get importChecking;

  /// Title of the sheet that describes a package before it is imported.
  ///
  /// In en, this message translates to:
  /// **'Import a project'**
  String get importSheetTitle;

  /// Where and when the package was made. [device] is package data.
  ///
  /// In en, this message translates to:
  /// **'Exported {when} on {deviceisEmptyanother}'**
  String importFrom(Object when, Object deviceisEmptyanother);

  /// What the package holds.
  ///
  /// In en, this message translates to:
  /// **'{recordsCountrecords} · {photosCountphotos} · {fileSizebytes}'**
  String importHolds(
    Object recordsCountrecords,
    Object photosCountphotos,
    Object fileSizebytes,
  );

  /// How many photos a package or a count covers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No photos} one{1 photo} other{{count} photos}}'**
  String photosCount(int count);

  /// Primary action of the import sheet.
  ///
  /// In en, this message translates to:
  /// **'Import as a new project'**
  String get importAsNewProject;

  /// Secondary action of the import sheet: merge into a project here.
  ///
  /// In en, this message translates to:
  /// **'Merge into a project…'**
  String get importMergeInto;

  /// Shown while a package's files are copied in.
  ///
  /// In en, this message translates to:
  /// **'Importing the project…'**
  String get importCopying;

  /// Announced once the project is in.
  ///
  /// In en, this message translates to:
  /// **'Project imported: {recordsCountrecords}'**
  String importDone(Object recordsCountrecords);

  /// A package whose project was deleted on this device is refused.
  ///
  /// In en, this message translates to:
  /// **'This project was deleted on this device. A merge never brings back what was deleted.'**
  String get importProjectDeletedHere;

  /// Recovery for [importProjectDeletedHere].
  ///
  /// In en, this message translates to:
  /// **'Restore the project from the recycle bin, or import on another device.'**
  String get importProjectDeletedHereRecovery;

  /// A package whose project is already here does not import a second copy.
  ///
  /// In en, this message translates to:
  /// **'This project is already on this device.'**
  String get importProjectAlreadyHere;

  /// Recovery for [importProjectAlreadyHere].
  ///
  /// In en, this message translates to:
  /// **'Merge the package into it instead.'**
  String get importProjectAlreadyHereRecovery;

  /// Too little room for the package's files.
  ///
  /// In en, this message translates to:
  /// **'There is not enough free space on this device for this package.'**
  String get importNoRoom;

  /// Recovery for [importNoRoom].
  ///
  /// In en, this message translates to:
  /// **'Free some space, then import again.'**
  String get importNoRoomRecovery;

  /// A file in the package did not arrive as it left.
  ///
  /// In en, this message translates to:
  /// **'A file in this package did not copy correctly.'**
  String get importFileChanged;

  /// Recovery for any import or merge that stopped part way.
  ///
  /// In en, this message translates to:
  /// **'Nothing was changed. Try again, or export the package again.'**
  String get importFailedRecovery;

  /// Project home overflow item and the merge screen's title.
  ///
  /// In en, this message translates to:
  /// **'Merge a package'**
  String get mergePackage;

  /// Title of the sheet that chooses which project a package merges into.
  ///
  /// In en, this message translates to:
  /// **'Merge into which project?'**
  String get mergeTargetTitle;

  /// No local project can take the package.
  ///
  /// In en, this message translates to:
  /// **'No project on this device uses the templates this package needs.'**
  String get mergeTargetNone;

  /// A compatibility status, as its pill reads.
  ///
  /// In en, this message translates to:
  /// **'Compatible'**
  String get compatibilityStatus;

  /// A compatibility status, as its pill reads.
  ///
  /// In en, this message translates to:
  /// **'Compatible, with differences'**
  String get compatibilityStatusCompatibleWithDifferences;

  /// A compatibility status, as its pill reads.
  ///
  /// In en, this message translates to:
  /// **'Not compatible'**
  String get compatibilityStatusNotCompatible;

  /// One named compatibility finding. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'No matching template here'**
  String get compatibilityIssue;

  /// One named compatibility finding. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'{field} holds values but is not in the template here'**
  String compatibilityIssueHoldsValuesButIs(Object field);

  /// One named compatibility finding. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'{field} here cannot hold the incoming values'**
  String compatibilityIssueHereCannotHoldThe(Object field);

  /// One named compatibility finding. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'Another version of the template'**
  String get compatibilityIssueAnotherVersionOfThe;

  /// One named compatibility finding. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'Only here: {field}'**
  String compatibilityIssueOnlyHere(Object field);

  /// One named compatibility finding. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'{field} is required on one side only'**
  String compatibilityIssueIsRequiredOnOne(Object field);

  /// One named compatibility finding. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'{field} has another label here'**
  String compatibilityIssueHasAnotherLabelHere(Object field);

  /// One named compatibility finding. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'{field} offers other choices here'**
  String compatibilityIssueOffersOtherChoicesHere(Object field);

  /// One named compatibility finding. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'{field} has another type here'**
  String compatibilityIssueHasAnotherTypeHere(Object field);

  /// One named compatibility finding. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'{field} is not in the template here, and holds no values'**
  String compatibilityIssueIsNotInThe(Object field);

  /// A template's line in the compatibility report. [name] is template data.
  ///
  /// In en, this message translates to:
  /// **'{name}: {compatibilityStatusstatus}'**
  String compatibilityTemplate(Object name, Object compatibilityStatusstatus);

  /// The merge preview's count headings (specification §48.1).
  ///
  /// In en, this message translates to:
  /// **'New records'**
  String get mergeCount;

  /// The merge preview's count headings (specification §48.1).
  ///
  /// In en, this message translates to:
  /// **'Records this merge changes'**
  String get mergeCountRecordsThisMergeChanges;

  /// The merge preview's count headings (specification §48.1).
  ///
  /// In en, this message translates to:
  /// **'New photos'**
  String get mergeCountNewPhotos;

  /// The merge preview's count headings (specification §48.1).
  ///
  /// In en, this message translates to:
  /// **'Photos already on this device'**
  String get mergeCountPhotosAlreadyOnThis;

  /// The merge preview's count headings (specification §48.1).
  ///
  /// In en, this message translates to:
  /// **'Deletions to apply'**
  String get mergeCountDeletionsToApply;

  /// The merge preview's count headings (specification §48.1).
  ///
  /// In en, this message translates to:
  /// **'Conflicts to settle'**
  String get mergeCountConflictsToSettle;

  /// The merge preview's count headings (specification §48.1).
  ///
  /// In en, this message translates to:
  /// **'Possible duplicates'**
  String get mergeCountPossibleDuplicates;

  /// The merge preview's count headings (specification §48.1).
  ///
  /// In en, this message translates to:
  /// **'Values kept as on this device'**
  String get mergeCountValuesKeptAsOn;

  /// The merge preview's count headings (specification §48.1).
  ///
  /// In en, this message translates to:
  /// **'Already in another project here'**
  String get mergeCountAlreadyInAnotherProject;

  /// The merge preview's count headings (specification §48.1).
  ///
  /// In en, this message translates to:
  /// **'{label}: {n}'**
  String mergeCountValue(Object label, int n);

  /// Primary merge action while conflicts remain.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Settle 1 conflict} other{Settle {count} conflicts}}'**
  String mergeSettleConflicts(int count);

  /// Primary merge action once every conflict is settled.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get mergeApply;

  /// Shown while a merge is written.
  ///
  /// In en, this message translates to:
  /// **'Merging…'**
  String get mergeApplying;

  /// Announced once a merge is written.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get mergeDone;

  /// A second merge of the same package.
  ///
  /// In en, this message translates to:
  /// **'Nothing to merge: this project already holds everything in the package.'**
  String get mergeNothing;

  /// Switch on the merge preview that runs the duplicate check.
  ///
  /// In en, this message translates to:
  /// **'Check for possible duplicates'**
  String get mergeCheckDuplicates;

  /// Helper under [mergeCheckDuplicates].
  ///
  /// In en, this message translates to:
  /// **'Lists incoming records that look like ones already here. You decide for each.'**
  String get mergeCheckDuplicatesHelper;

  /// Shown while the duplicate check runs.
  ///
  /// In en, this message translates to:
  /// **'Looking for duplicates…'**
  String get mergeCheckingDuplicates;

  /// Title of the conflict screen, as "Conflict 3 of 7".
  ///
  /// In en, this message translates to:
  /// **'Conflict {index} of {total}'**
  String conflictProgress(int index, int total);

  /// What a conflict is about. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get conflictKind;

  /// What a conflict is about. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get conflictKindStatus;

  /// What a conflict is about. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'Deleted on the other device'**
  String get conflictKindDeletedOnTheOther;

  /// What a conflict is about. [field] is template data.
  ///
  /// In en, this message translates to:
  /// **'Deleted on this device'**
  String get conflictKindDeletedOnThisDevice;

  /// Explains a deletion conflict.
  ///
  /// In en, this message translates to:
  /// **'The other device deleted this, but it was changed here since.'**
  String get conflictDeletionTheOtherDeviceDeleted;

  /// Explains a deletion conflict.
  ///
  /// In en, this message translates to:
  /// **'This device deleted this, but the other device changed it since.'**
  String get conflictDeletionThisDeviceDeletedThis;

  /// Heading of this device's side of a conflict.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get conflictThisDevice;

  /// Heading of the incoming side of a conflict.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get conflictIncoming;

  /// Who last wrote a side, and when. [device] is data.
  ///
  /// In en, this message translates to:
  /// **' · {dateFormatyMMMdadd}'**
  String conflictWrittenBy(Object dateFormatyMMMdadd);

  /// Who last wrote a side, and when. [device] is data.
  ///
  /// In en, this message translates to:
  /// **'{deviceisEmptyUnknown}{when}'**
  String conflictWrittenByValue(Object deviceisEmptyUnknown, Object when);

  /// A side of a deletion conflict.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get conflictDeleted;

  /// An empty value on one side.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get conflictEmpty;

  /// Keeps this device's side of one conflict.
  ///
  /// In en, this message translates to:
  /// **'Keep this device\'\'s'**
  String get conflictKeepMine;

  /// Takes the incoming side of one conflict.
  ///
  /// In en, this message translates to:
  /// **'Take incoming'**
  String get conflictTakeIncoming;

  /// Second control: keep this device's side of every remaining conflict.
  ///
  /// In en, this message translates to:
  /// **'Keep this device\'\'s for all {n}'**
  String mergeKeepAllMine(int n);

  /// Second control: take the incoming side of every remaining conflict.
  ///
  /// In en, this message translates to:
  /// **'Take incoming for all {n}'**
  String mergeTakeAllIncoming(int n);

  /// Confirms a bulk choice with its count.
  ///
  /// In en, this message translates to:
  /// **'the incoming value'**
  String get mergeBulkConfirm;

  /// Confirms a bulk choice with its count.
  ///
  /// In en, this message translates to:
  /// **'this device\'\'s value'**
  String get mergeBulkConfirmThisDeviceSValue;

  /// Confirms a bulk choice with its count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Use {side} for 1 conflict?} other{Use {side} for all {count} conflicts?}}'**
  String mergeBulkConfirmForConflictOtherFor(int count, Object side);

  /// Title of the possible-duplicate view.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get duplicateTitle;

  /// Why a pair was listed.
  ///
  /// In en, this message translates to:
  /// **'Same identity fields'**
  String get duplicateSignal;

  /// Why a pair was listed.
  ///
  /// In en, this message translates to:
  /// **'Same photo'**
  String get duplicateSignalSamePhoto;

  /// Why a pair was listed.
  ///
  /// In en, this message translates to:
  /// **'Identical photo'**
  String get duplicateSignalIdenticalPhoto;

  /// Why a pair was listed.
  ///
  /// In en, this message translates to:
  /// **'Nearly the same photo'**
  String get duplicateSignalNearlyTheSamePhoto;

  /// Why a pair was listed.
  ///
  /// In en, this message translates to:
  /// **'Same checklist row'**
  String get duplicateSignalSameChecklistRow;

  /// Why a pair was listed.
  ///
  /// In en, this message translates to:
  /// **'Same name, place and time'**
  String get duplicateSignalSameNamePlaceAnd;

  /// Why a pair was listed.
  ///
  /// In en, this message translates to:
  /// **'Same place, close in time, similar caption'**
  String get duplicateSignalSamePlaceCloseIn;

  /// Keeps both records: the default.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get duplicateKeepBoth;

  /// Leaves the incoming record out of the merge.
  ///
  /// In en, this message translates to:
  /// **'Don\'\'t import this record'**
  String get duplicateSkipIncoming;

  /// Marks a pair whose incoming record is left out.
  ///
  /// In en, this message translates to:
  /// **'Not imported'**
  String get duplicateSkipped;

  /// Heading of the incoming side of a pair.
  ///
  /// In en, this message translates to:
  /// **'Incoming record'**
  String get duplicateIncoming;

  /// Heading of the local side of a pair.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get duplicateHere;

  /// Empty state when the merge screen opens with no package.
  ///
  /// In en, this message translates to:
  /// **'No package open'**
  String get mergeNoPackageHeadline;

  /// Explains [mergeNoPackageHeadline].
  ///
  /// In en, this message translates to:
  /// **'Choose Merge a package from the project menu to pick one.'**
  String get mergeNoPackageMessage;

  /// Heading over the compatibility report.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get mergeTemplatesHeading;

  /// Heading over the preview's counts.
  ///
  /// In en, this message translates to:
  /// **'What the merge does'**
  String get mergeCountsHeading;

  /// Shown when a template blocks the merge.
  ///
  /// In en, this message translates to:
  /// **'This package cannot merge into this project until its templates match.'**
  String get mergeBlocked;

  /// A record with no caption, in the preview's lists.
  ///
  /// In en, this message translates to:
  /// **'Record …{short}'**
  String mergeRecordUnnamed(Object short);

  /// A conflict's line in the preview: the record, then what differs.
  ///
  /// In en, this message translates to:
  /// **'{record} · {about}'**
  String mergeConflictLine(Object record, Object about);

  /// A settled conflict's side, under its line.
  ///
  /// In en, this message translates to:
  /// **'Taking incoming'**
  String get mergeConflictChosen;

  /// A settled conflict's side, under its line.
  ///
  /// In en, this message translates to:
  /// **'Keeping this device\'\'s'**
  String get mergeConflictChosenKeepingThisDeviceS;

  /// A conflict not settled yet.
  ///
  /// In en, this message translates to:
  /// **'Not settled yet'**
  String get mergeConflictOpen;

  /// The project details that differ in the package, kept as on this device.
  ///
  /// In en, this message translates to:
  /// **'Project details kept as on this device: {labelsjoin}'**
  String mergeProjectKept(Object labelsjoin);

  /// The deletion side of a conflict that was changed rather than deleted.
  ///
  /// In en, this message translates to:
  /// **'Kept and changed'**
  String get conflictChanged;

  /// The duplicate pair view's field line. [label] and [value] are data.
  ///
  /// In en, this message translates to:
  /// **'{label}: {valueisEmptyconflictEmpty}'**
  String duplicateField(Object label, Object valueisEmptyconflictEmpty);

  /// Prompt on a records list's search field: what it looks through.
  ///
  /// In en, this message translates to:
  /// **'Search records'**
  String get recordsSearchHint;

  /// A record's list title when nothing names it yet: its [number], or no
  ///    number at all before one is allocated.
  ///
  /// In en, this message translates to:
  /// **'Untitled record'**
  String get recordsUntitled;

  /// A record's list title when nothing names it yet: its [number], or no
  ///    number at all before one is allocated.
  ///
  /// In en, this message translates to:
  /// **'Record {number}'**
  String recordsUntitledRecord(Object number);

  /// A project with no records yet.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get recordsEmptyHeadline;

  /// Where a project's records come from.
  ///
  /// In en, this message translates to:
  /// **'Records you capture in this project appear here.'**
  String get recordsEmptyMessage;

  /// The next action on an empty records list.
  ///
  /// In en, this message translates to:
  /// **'Capture a record'**
  String get recordsEmptyAction;

  /// A records search or filter that matched nothing, naming the [query].
  ///
  /// In en, this message translates to:
  /// **'No records match.'**
  String get recordsNoMatch;

  /// A records search or filter that matched nothing, naming the [query].
  ///
  /// In en, this message translates to:
  /// **'No records match \"{shown}\".'**
  String recordsNoMatchNoRecordsMatch(Object shown);

  /// Empties a records search that matched nothing.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get recordsClearSearch;

  /// Empties a records search and turns its filters off, together.
  ///
  /// In en, this message translates to:
  /// **'Clear search and filters'**
  String get recordsClearAll;

  /// The records list with no project open.
  ///
  /// In en, this message translates to:
  /// **'No project open'**
  String get recordsNoProjectHeadline;

  /// Why the records list is empty without a project.
  ///
  /// In en, this message translates to:
  /// **'Records belong to a project. Open one to see its records.'**
  String get recordsNoProjectMessage;

  /// The next action when no project is open.
  ///
  /// In en, this message translates to:
  /// **'Open a project'**
  String get recordsOpenProject;

  /// Title of a records list's filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Record filters'**
  String get recordsFiltersTitle;

  /// The status facet of the records filters.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get recordsFilterStatus;

  /// The template facet of the records filters.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get recordsFilterTemplate;

  /// The earliest capture date the records filters keep.
  ///
  /// In en, this message translates to:
  /// **'Captured from'**
  String get recordsFilterFrom;

  /// The latest capture date the records filters keep.
  ///
  /// In en, this message translates to:
  /// **'Captured until'**
  String get recordsFilterTo;

  /// The operator facet of the records filters.
  ///
  /// In en, this message translates to:
  /// **'Captured by'**
  String get recordsFilterOperator;

  /// The condition facet of the records filters.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get recordsFilterCondition;

  /// The quality-flag facet of the records filters.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get recordsFilterFlags;

  /// Quality flag: the record has at least one photo.
  ///
  /// In en, this message translates to:
  /// **'Has photos'**
  String get recordsFlagHasPhotos;

  /// Quality flag: the record may duplicate another.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get recordsFlagHasDuplicate;

  /// Quality flag: a merge left a conflict on the record.
  ///
  /// In en, this message translates to:
  /// **'Merge conflict'**
  String get recordsFlagHasConflict;

  /// Quality flag: a value changed after the record was approved.
  ///
  /// In en, this message translates to:
  /// **'Changed since approval'**
  String get recordsFlagHasVariance;

  /// Quality flag: a value lost every photo it was read from.
  ///
  /// In en, this message translates to:
  /// **'Evidence removed'**
  String get recordsFlagEvidenceRemoved;

  /// Quality flag: the record arrived in a package from another device.
  ///
  /// In en, this message translates to:
  /// **'From another device'**
  String get recordsFlagMerged;

  /// The filter sheet of a project with no records.
  ///
  /// In en, this message translates to:
  /// **'Nothing to filter yet'**
  String get recordsFiltersEmptyHeadline;

  /// What fills the filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Capture records in this project, then narrow them down here.'**
  String get recordsFiltersEmptyMessage;

  /// A template whose name is not on this device.
  ///
  /// In en, this message translates to:
  /// **'Unnamed template'**
  String get recordsTemplateUnnamed;

  /// Active-filter chip for a template. [name] is template content.
  ///
  /// In en, this message translates to:
  /// **'Template: {name}'**
  String recordsChipTemplate(Object name);

  /// Active-filter chip for who captured the records. [name] is data the
  ///    operator entered.
  ///
  /// In en, this message translates to:
  /// **'Captured by {name}'**
  String recordsChipOperator(Object name);

  /// Active-filter chip for a condition code. [code] is template content.
  ///
  /// In en, this message translates to:
  /// **'Condition: {code}'**
  String recordsChipCondition(Object code);

  /// Active-filter chip for one context value: the [level] it sits at and
  ///    the [value]. Both are template content.
  ///
  /// In en, this message translates to:
  /// **'{level}: {value}'**
  String recordsChipContext(Object level, Object value);

  /// Active-filter chip for the capture date range, in [locale]'s format.
  ///
  /// In en, this message translates to:
  /// **'{formatformatfrom} – {formatformatto}'**
  String recordsChipDates(Object formatformatfrom, Object formatformatto);

  /// Active-filter chip for the capture date range, in [locale]'s format.
  ///
  /// In en, this message translates to:
  /// **'From {formatformatfrom}'**
  String recordsChipDatesFrom(Object formatformatfrom);

  /// Active-filter chip for the capture date range, in [locale]'s format.
  ///
  /// In en, this message translates to:
  /// **'Until {formatformatto}'**
  String recordsChipDatesUntil(Object formatformatto);

  /// Title of the records sort choice.
  ///
  /// In en, this message translates to:
  /// **'Sort records'**
  String get recordsSortTitle;

  /// The sort control, naming the [current] order.
  ///
  /// In en, this message translates to:
  /// **'Sort: {current}'**
  String recordsSortLabel(Object current);

  /// Highest record number first, the newest capture on top.
  ///
  /// In en, this message translates to:
  /// **'Number, highest first'**
  String get recordsSortNumberDescending;

  /// Lowest record number first.
  ///
  /// In en, this message translates to:
  /// **'Number, lowest first'**
  String get recordsSortNumberAscending;

  /// Latest capture first.
  ///
  /// In en, this message translates to:
  /// **'Captured, newest first'**
  String get recordsSortCapturedDescending;

  /// Earliest capture first.
  ///
  /// In en, this message translates to:
  /// **'Captured, oldest first'**
  String get recordsSortCapturedAscending;

  /// Names in alphabetical order.
  ///
  /// In en, this message translates to:
  /// **'Name, A to Z'**
  String get recordsSortNameAscending;

  /// Names in reverse alphabetical order.
  ///
  /// In en, this message translates to:
  /// **'Name, Z to A'**
  String get recordsSortNameDescending;

  /// Leaves the page of a record that is not on this device for the list.
  ///
  /// In en, this message translates to:
  /// **'Back to the list'**
  String get recordDetailBackToList;

  /// Above a record in the recycle bin: why it cannot be changed, and what
  ///    to do first.
  ///
  /// In en, this message translates to:
  /// **'This record is in the recycle bin. Restore it to change it again.'**
  String get recordDetailDeletedNotice;

  /// Sends the record shown to review, the step before it is approved.
  ///
  /// In en, this message translates to:
  /// **'Send to review'**
  String get recordDetailSendToReview;

  /// Once the record shown waits for review.
  ///
  /// In en, this message translates to:
  /// **'Record sent to review'**
  String get recordDetailSentToReview;

  /// Menu row that brings the record shown back from the archive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive record'**
  String get recordDetailUnarchive;

  /// Once the record shown is back from the archive.
  ///
  /// In en, this message translates to:
  /// **'Record back from the archive'**
  String get recordDetailUnarchived;

  /// Opens the page that edits the record's photos, captions and audio.
  ///
  /// In en, this message translates to:
  /// **'Edit photos and captions'**
  String get recordDetailEditPhotos;

  /// A status move asked for while another is still being written.
  ///
  /// In en, this message translates to:
  /// **'A change to this record is still being saved.'**
  String get recordDetailBusy;

  /// What to do about [recordDetailBusy].
  ///
  /// In en, this message translates to:
  /// **'Wait for it to finish, then try again.'**
  String get recordDetailBusyAction;

  /// A record with no values and no fields to fill.
  ///
  /// In en, this message translates to:
  /// **'This record has no values yet.'**
  String get recordDetailNoValues;

  /// Heading over the context in force when the record was captured.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get recordDetailContextTitle;

  /// A record captured with no context in force.
  ///
  /// In en, this message translates to:
  /// **'No context was set when this record was captured.'**
  String get recordDetailContextEmpty;

  /// Heading over the count of the record's values by where they came from.
  ///
  /// In en, this message translates to:
  /// **'Where the values came from'**
  String get recordDetailProvenanceTitle;

  /// How many of the record's values came from one source, or carry one
  ///    mark.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No values} one{1 value} other{{count} values}}'**
  String recordDetailValuesCount(int count);

  /// The values a person confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by a person'**
  String get recordDetailVerified;

  /// The providers, models and methods that read the record's values.
  ///
  /// In en, this message translates to:
  /// **'Read by'**
  String get recordDetailReadBy;

  /// Heading over when the record was captured, changed, approved and
  ///    exported.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get recordDetailDatesTitle;

  /// When the record was captured, and on which device.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get recordDetailCaptured;

  /// When the record last changed.
  ///
  /// In en, this message translates to:
  /// **'Last changed'**
  String get recordDetailUpdated;

  /// When the record was last approved, and by whom.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get recordDetailApproved;

  /// When the record was last exported.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get recordDetailExported;

  /// A record that has never been exported.
  ///
  /// In en, this message translates to:
  /// **'Not exported yet'**
  String get recordDetailNotExported;

  /// When something happened to the record, [at] in local time, and who or
  ///    which device did it ([by], data) when that is known.
  ///
  /// In en, this message translates to:
  /// **'{when} · {who}'**
  String recordDetailWhen(Object when, Object who);

  /// One of the record's photos by its 1-based [position] among [total].
  ///
  /// In en, this message translates to:
  /// **'Photo {position} of {total}'**
  String recordPhotoPosition(int position, int total);

  /// A value typed by a person, or corrected by hand.
  ///
  /// In en, this message translates to:
  /// **'Typed'**
  String get recordSourceTyped;

  /// A value read from a photo's text on this device.
  ///
  /// In en, this message translates to:
  /// **'Read from photo'**
  String get recordSourceOcr;

  /// A value an AI model read from a photo.
  ///
  /// In en, this message translates to:
  /// **'AI from photo'**
  String get recordSourceAiPhoto;

  /// A value an AI model read from captions or spoken notes.
  ///
  /// In en, this message translates to:
  /// **'AI from notes'**
  String get recordSourceAiText;

  /// A value spoken aloud and written down.
  ///
  /// In en, this message translates to:
  /// **'Dictated'**
  String get recordSourceSpeech;

  /// A value scanned from a barcode or QR code.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get recordSourceBarcode;

  /// A value looked up in a reference list.
  ///
  /// In en, this message translates to:
  /// **'Looked up'**
  String get recordSourceLookup;

  /// A value taken from the context in force at capture.
  ///
  /// In en, this message translates to:
  /// **'From context'**
  String get recordSourceContext;

  /// A value the template filled in by default.
  ///
  /// In en, this message translates to:
  /// **'Filled in'**
  String get recordSourceDefault;

  /// A value that arrived in an imported table or package.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get recordSourceImported;

  /// A reading the processing was sure of.
  ///
  /// In en, this message translates to:
  /// **'High confidence'**
  String get recordBandHigh;

  /// A reading the processing was fairly sure of.
  ///
  /// In en, this message translates to:
  /// **'Medium confidence'**
  String get recordBandMedium;

  /// A reading a person should check.
  ///
  /// In en, this message translates to:
  /// **'Low confidence'**
  String get recordBandLow;

  /// A confidence with no stored band: [score], 0 to 1, as a percentage.
  ///
  /// In en, this message translates to:
  /// **'{numberFormatpercentPatternformat} confidence'**
  String recordBandScore(Object numberFormatpercentPatternformat);

  /// A band's words with its [score], 0 to 1, as a percentage beside them.
  ///
  /// In en, this message translates to:
  /// **'{band}, {numberFormatpercentPatternformat}'**
  String recordBandWithScore(
    Object band,
    Object numberFormatpercentPatternformat,
  );

  /// Title of a record's history page.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get recordHistoryTitle;

  /// A record whose history has no lines yet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get recordHistoryEmptyHeadline;

  /// What an empty history will hold, and the next step.
  ///
  /// In en, this message translates to:
  /// **'Captures, processing runs, edits, approvals, merges and exports of this record appear here. Go back to the record to change it.'**
  String get recordHistoryEmptyMessage;

  /// Leaves an empty history for its record.
  ///
  /// In en, this message translates to:
  /// **'Back to the record'**
  String get recordHistoryBackToRecord;

  /// When a history line was written, by whom and on which device, under
  ///    the line. [at] is local time; [operator] and [device] are data and
  ///    either may be blank.
  ///
  /// In en, this message translates to:
  /// **'On {device}'**
  String recordHistoryByline(Object device);

  /// When a history line was written, by whom and on which device, under
  ///    the line. [at] is local time; [operator] and [device] are data and
  ///    either may be blank.
  ///
  /// In en, this message translates to:
  /// **'{operator} on {device}'**
  String recordHistoryBylineOn(Object operator, Object device);

  /// When a history line was written, by whom and on which device, under
  ///    the line. [at] is local time; [operator] and [device] are data and
  ///    either may be blank.
  ///
  /// In en, this message translates to:
  /// **'{time} · {who}'**
  String recordHistoryBylineValue(Object time, Object who);

  /// A record captured on a device.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get recordHistoryCaptured;

  /// A record made by hand, which starts as a draft.
  ///
  /// In en, this message translates to:
  /// **'Created by hand'**
  String get recordHistoryCreatedByHand;

  /// Value [label] written or corrected from [previous] to [next]; all
  ///    three are data. A first value shows alone, and a value taken away
  ///    says so.
  ///
  /// In en, this message translates to:
  /// **'{label} changed'**
  String recordHistoryValue(Object label);

  /// Value [label] written or corrected from [previous] to [next]; all
  ///    three are data. A first value shows alone, and a value taken away
  ///    says so.
  ///
  /// In en, this message translates to:
  /// **'{label}: {next}'**
  String recordHistoryValueValue(Object label, Object next);

  /// Value [label] written or corrected from [previous] to [next]; all
  ///    three are data. A first value shows alone, and a value taken away
  ///    says so.
  ///
  /// In en, this message translates to:
  /// **'{label} cleared'**
  String recordHistoryValueCleared(Object label);

  /// Value [label] written or corrected from [previous] to [next]; all
  ///    three are data. A first value shows alone, and a value taken away
  ///    says so.
  ///
  /// In en, this message translates to:
  /// **'{label}: {previous} → {next}'**
  String recordHistoryValueValue2(Object label, Object previous, Object next);

  /// The caption of a record or of one of its photos, as the label of
  ///    [recordHistoryValue].
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get recordHistoryCaption;

  /// A status move from [previous] to [next], both status names. Only the
  ///    new status shows when the old one is not known.
  ///
  /// In en, this message translates to:
  /// **'Status: {next}'**
  String recordHistoryStatus(Object next);

  /// A status move from [previous] to [next], both status names. Only the
  ///    new status shows when the old one is not known.
  ///
  /// In en, this message translates to:
  /// **'{previous} → {next}'**
  String recordHistoryStatusValue(Object previous, Object next);

  /// A photo added to the record after capture, or during it.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get recordHistoryPhotoAdded;

  /// A photo taken off the record. Its file stays until the purge.
  ///
  /// In en, this message translates to:
  /// **'Photo removed'**
  String get recordHistoryPhotoRemoved;

  /// The record moved from template [previous] to [next] (names, data).
  ///    Either name is blank when that template is not on this device.
  ///
  /// In en, this message translates to:
  /// **'Template changed'**
  String get recordHistoryTemplate;

  /// The record moved from template [previous] to [next] (names, data).
  ///    Either name is blank when that template is not on this device.
  ///
  /// In en, this message translates to:
  /// **'Template: {next}'**
  String recordHistoryTemplateTemplate(Object next);

  /// The record moved from template [previous] to [next] (names, data).
  ///    Either name is blank when that template is not on this device.
  ///
  /// In en, this message translates to:
  /// **'Template: {previous} → {next}'**
  String recordHistoryTemplateTemplate2(Object previous, Object next);

  /// Stands in for the name of a template that is not on this device.
  ///
  /// In en, this message translates to:
  /// **'A template not on this device'**
  String get recordHistoryTemplateGone;

  /// A processing run that finished, with the [provider] and [model] it
  ///    used (data) when they are known.
  ///
  /// In en, this message translates to:
  /// **' by {provider}'**
  String recordHistoryProcessed(Object provider);

  /// A processing run that finished, with the [provider] and [model] it
  ///    used (data) when they are known.
  ///
  /// In en, this message translates to:
  /// **' ({model})'**
  String recordHistoryProcessedValue(Object model);

  /// A processing run that finished, with the [provider] and [model] it
  ///    used (data) when they are known.
  ///
  /// In en, this message translates to:
  /// **'Processed{by}{using}'**
  String recordHistoryProcessedProcessed(Object by, Object using);

  /// A processing run that stopped for good after [attempts] tries; zero
  ///    when the count is not known.
  ///
  /// In en, this message translates to:
  /// **'Processing failed'**
  String get recordHistoryProcessingFailed;

  /// A processing run that stopped for good after [attempts] tries; zero
  ///    when the count is not known.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Processing failed after 1 attempt} other{Processing failed after {count} attempts}}'**
  String recordHistoryProcessingFailedOtherAttempts(int count);

  /// A record that arrived in [package], a package file name (data).
  ///
  /// In en, this message translates to:
  /// **'Imported from a package'**
  String get recordHistoryImported;

  /// A record that arrived in [package], a package file name (data).
  ///
  /// In en, this message translates to:
  /// **'Imported from {package}'**
  String recordHistoryImportedImportedFrom(Object package);

  /// A record changed by merging [package], a package file name (data).
  ///
  /// In en, this message translates to:
  /// **'Merged from a package'**
  String get recordHistoryMerged;

  /// A record changed by merging [package], a package file name (data).
  ///
  /// In en, this message translates to:
  /// **'Merged from {package}'**
  String recordHistoryMergedMergedFrom(Object package);

  /// A record included in export [version], stored as `v<number>`.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get recordHistoryExported;

  /// A record included in export [version], stored as `v<number>`.
  ///
  /// In en, this message translates to:
  /// **'Exported in export {version}'**
  String recordHistoryExportedExportedInExport(Object version);

  /// Value [label] (data) lost every photo it was read from. The value is
  ///    kept.
  ///
  /// In en, this message translates to:
  /// **'{label}: evidence removed'**
  String recordHistoryEvidenceRemoved(Object label);

  /// Value [label] (data) has a photo it was read from again.
  ///
  /// In en, this message translates to:
  /// **'{label}: evidence restored'**
  String recordHistoryEvidenceRestored(Object label);

  /// Value [label] (data) kept as retired by a template change.
  ///
  /// In en, this message translates to:
  /// **'{label} retired'**
  String recordHistoryRetired(Object label);

  /// Retired value [label] (data) that a template change mapped again.
  ///
  /// In en, this message translates to:
  /// **'{label} mapped again'**
  String recordHistoryMappedAgain(Object label);

  /// The record matched to a row of its template's checklist.
  ///
  /// In en, this message translates to:
  /// **'Matched to a checklist row'**
  String get recordHistoryRowMatched;

  /// A photo file of the record was found missing from this device.
  ///
  /// In en, this message translates to:
  /// **'A photo file is missing'**
  String get recordHistoryFileMissing;

  /// Any other change the audit table holds for the record.
  ///
  /// In en, this message translates to:
  /// **'Record changed'**
  String get recordHistoryOther;

  /// Title of the sheet that shows one history line whole.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get recordHistoryLineTitle;

  /// Label of the value or status a change replaced.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get recordHistoryBefore;

  /// Label of the value or status a change wrote.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get recordHistoryAfter;

  /// Label of when a change was written.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get recordHistoryWhen;

  /// Label of who wrote a change.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get recordHistoryOperator;

  /// Label of the device a change was written on.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get recordHistoryDevice;

  /// Label of why a change was made.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get recordHistoryReason;

  /// Stands in for an operator or device the audit row does not hold.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get recordHistoryNotRecorded;

  /// Stands in for a value that was empty before or after a change.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get recordHistoryEmptyValue;

  /// Title of the page that edits a saved record's values.
  ///
  /// In en, this message translates to:
  /// **'Edit values'**
  String get recordValuesEditTitle;

  /// Title of the one-value sheet when the caller does not name the field.
  ///
  /// In en, this message translates to:
  /// **'Edit value'**
  String get recordValueEditTitle;

  /// Above the values of an approved record: what saving a change does.
  ///
  /// In en, this message translates to:
  /// **'This record is approved. Saving a change sends it back to review.'**
  String get recordEditApprovedNotice;

  /// Marks a value its record's template no longer has. It is kept, and it
  ///    cannot be edited or removed.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get recordValueRetired;

  /// Heading over the values a record keeps after its template dropped them.
  ///
  /// In en, this message translates to:
  /// **'Retired values'**
  String get recordRetiredValuesTitle;

  /// Why retired values cannot be edited.
  ///
  /// In en, this message translates to:
  /// **'This record\'\'s template no longer has these fields. Their values are kept as they were and can\'\'t be edited.'**
  String get recordRetiredValuesMessage;

  /// Marks a value whose source photos were all removed. The value is kept.
  ///
  /// In en, this message translates to:
  /// **'Evidence removed'**
  String get recordValueEvidenceRemoved;

  /// Shown when a record's template is no longer on this device.
  ///
  /// In en, this message translates to:
  /// **'This record\'\'s template is no longer on this device. Its values are kept; change its template to edit them.'**
  String get recordTemplateMissingNotice;

  /// The edit page of a record that sits in the recycle bin.
  ///
  /// In en, this message translates to:
  /// **'This record is in the recycle bin'**
  String get recordEditDeletedHeadline;

  /// What to do before editing a record in the recycle bin.
  ///
  /// In en, this message translates to:
  /// **'Restore it from the recycle bin, then change its values.'**
  String get recordEditDeletedMessage;

  /// The one-value sheet for a field the record's template no longer has.
  ///
  /// In en, this message translates to:
  /// **'This field is not on the record'**
  String get recordFieldMissingHeadline;

  /// What to do when the one-value sheet has no field to show.
  ///
  /// In en, this message translates to:
  /// **'The record\'\'s template no longer has this field. Go back to the record.'**
  String get recordFieldMissingMessage;

  /// Why a saved value cannot be emptied: the captured original always
  ///    stays, so an empty edit would show it again (FE-SEC-08).
  ///
  /// In en, this message translates to:
  /// **'A saved value cannot be emptied. Type the corrected value instead.'**
  String get recordValueCannotEmpty;

  /// Snack once [n] values are saved. [backToReview] adds that the record,
  ///    which was approved, is waiting for review again.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 value saved} other{{count} values saved}}'**
  String recordValuesSaved(int count);

  /// Snack once [n] values are saved. [backToReview] adds that the record,
  ///    which was approved, is waiting for review again.
  ///
  /// In en, this message translates to:
  /// **'{saved}. The record is back in review.'**
  String recordValuesSavedTheRecordIsBack(Object saved);

  /// Snack once [n] values are saved. [backToReview] adds that the record,
  ///    which was approved, is waiting for review again.
  ///
  /// In en, this message translates to:
  /// **'{saved}.'**
  String recordValuesSavedValue(Object saved);

  /// Title of the offer to process a record again after photos were added.
  ///
  /// In en, this message translates to:
  /// **'Process this record again?'**
  String get recordPhotosProcessTitle;

  /// Body of that offer: what processing the [n] added photos does, and
  ///    that values already on the record stay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{You added 1 photo. Processing again reads it and fills fields that are still empty. Values already on the record stay as they are.} other{You added {count} photos. Processing again reads them and fills fields that are still empty. Values already on the record stay as they are.}}'**
  String recordPhotosProcessMessage(int count);

  /// Confirms processing the record again.
  ///
  /// In en, this message translates to:
  /// **'Process again'**
  String get recordPhotosProcessConfirm;

  /// Snack once the record is back in the processing queue.
  ///
  /// In en, this message translates to:
  /// **'Record queued for processing.'**
  String get recordPhotosProcessQueued;

  /// Title of the sheet that moves a record to another template.
  ///
  /// In en, this message translates to:
  /// **'Change template'**
  String get recordTemplateChangeTitle;

  /// Names the template the record is on now. [name] is data.
  ///
  /// In en, this message translates to:
  /// **'Now on {name}'**
  String recordTemplateChangeCurrent(Object name);

  /// Heading over the templates the record can move to.
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get recordTemplateChangeChoose;

  /// Shown before a template is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a template to see what happens to each value before anything changes.'**
  String get recordTemplateChangeHint;

  /// Heading over the values whose field the chosen template also has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 value carried over} other{{count} values carried over}}'**
  String recordTemplateChangeMapped(int count);

  /// Heading over the values the chosen template has no field for.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 value kept as retired} other{{count} values kept as retired}}'**
  String recordTemplateChangeRetired(int count);

  /// Heading over the chosen template's fields the record has no value for.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 field starts empty} other{{count} fields start empty}}'**
  String recordTemplateChangeAdded(int count);

  /// Heading over retired values whose field the chosen template has again.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 retired value comes back} other{{count} retired values come back}}'**
  String recordTemplateChangeRestored(int count);

  /// Why retiring a value loses nothing.
  ///
  /// In en, this message translates to:
  /// **'Retired values stay on the record and are never deleted. They come back if the record moves to a template with their field.'**
  String get recordTemplateChangeRetiredNotice;

  /// When the move changes no value at all.
  ///
  /// In en, this message translates to:
  /// **'No value changes: the record has no values for this template to take over, and the template has no fields.'**
  String get recordTemplateChangeNoValues;

  /// Above the preview of an approved record: what applying does.
  ///
  /// In en, this message translates to:
  /// **'This record is approved. Changing its template sends it back to review.'**
  String get recordTemplateChangeApprovedNotice;

  /// Applies the move.
  ///
  /// In en, this message translates to:
  /// **'Change template'**
  String get recordTemplateChangeApply;

  /// Snack once the record is on its new template. [backToReview] adds that
  ///    the record, which was approved, is waiting for review again.
  ///
  /// In en, this message translates to:
  /// **'Template changed. The record is back in review.'**
  String get recordTemplateChanged;

  /// Snack once the record is on its new template. [backToReview] adds that
  ///    the record, which was approved, is waiting for review again.
  ///
  /// In en, this message translates to:
  /// **'Template changed.'**
  String get recordTemplateChangedTemplateChanged;

  /// No other template to move the record to.
  ///
  /// In en, this message translates to:
  /// **'No other template'**
  String get recordTemplateChangeEmptyHeadline;

  /// What to do when the project has no other template.
  ///
  /// In en, this message translates to:
  /// **'This project has only the template this record uses. Add another template to the project, then move the record to it.'**
  String get recordTemplateChangeEmptyMessage;

  /// Opens the project's templates from the empty state.
  ///
  /// In en, this message translates to:
  /// **'Open templates'**
  String get recordTemplateChangeEmptyAction;

  /// The record to move is no longer on this device.
  ///
  /// In en, this message translates to:
  /// **'This record is no longer on this device'**
  String get recordTemplateChangeGoneHeadline;

  /// What to do when the record to move is gone.
  ///
  /// In en, this message translates to:
  /// **'Close this sheet and pick another record.'**
  String get recordTemplateChangeGoneMessage;

  /// What to do when Change template is pressed before a template is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a template under Move to, then apply.'**
  String get recordTemplateChangeChooseAction;

  /// A second press while the record is already moving.
  ///
  /// In en, this message translates to:
  /// **'This record is already moving to that template.'**
  String get recordTemplateChangeApplying;

  /// What to do while the record is already moving.
  ///
  /// In en, this message translates to:
  /// **'Wait a moment, then check the record.'**
  String get recordTemplateChangeApplyingAction;

  /// Names the delete control for [n] records, for its tooltip and screen
  ///    readers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Delete record} other{Delete {count} records}}'**
  String recordsDeleteLabel(int count);

  /// Title of the confirm before [n] records move to the recycle bin.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Delete 1 record?} other{Delete {count} records?}}'**
  String recordsDeleteTitle(int count);

  /// Body of that confirm: where the [records] go, and for how many [days]
  ///    they can still be restored whole.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{It moves to the recycle bin, where you can restore it for {window}. Its photos stay on this device until then.} other{They move to the recycle bin, where you can restore them for {window}. Their photos stay on this device until then.}}'**
  String recordsDeleteMessage(int count, Object window);

  /// Confirms the move to the recycle bin.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get recordsDeleteConfirm;

  /// Snack once [n] records are in the recycle bin. Undo sits beside it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record deleted} other{{count} records deleted}}'**
  String recordsDeleted(int count);

  /// Snack or line when [n] records could not be deleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record could not be deleted} other{{count} records could not be deleted}}'**
  String recordsNotDeleted(int count);

  /// Snack when some records were deleted and some were not. Undo brings
  ///    back the [deleted] ones.
  ///
  /// In en, this message translates to:
  /// **'{recordsDeleteddeleted}. {recordsNotDeletedfailed}.'**
  String recordsDeletedPartly(
    Object recordsDeleteddeleted,
    Object recordsNotDeletedfailed,
  );

  /// Snack once [n] records are back from the recycle bin.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record restored} other{{count} records restored}}'**
  String recordsRestored(int count);

  /// Snack or line when [n] records could not be restored.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record could not be restored} other{{count} records could not be restored}}'**
  String recordsNotRestored(int count);

  /// Title of the recycle bin page.
  ///
  /// In en, this message translates to:
  /// **'Recycle bin'**
  String get recycleBinTitle;

  /// Storage settings row that opens the recycle bin.
  ///
  /// In en, this message translates to:
  /// **'Restore a deleted record before it is removed for good.'**
  String get recycleBinSettingsSubtitle;

  /// The line above the recycle bin list: how long a deleted record stays
  ///    restorable, [days] being the operator's window.
  ///
  /// In en, this message translates to:
  /// **'Deleted records stay here for {settingsRetentionDaysdays}, then they are removed for good.'**
  String recycleBinKeptFor(Object settingsRetentionDaysdays);

  /// Headline of an empty recycle bin.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the recycle bin'**
  String get recycleBinEmptyHeadline;

  /// What an empty recycle bin is for, and the way a record gets back out:
  ///    a deleted record waits here for [days].
  ///
  /// In en, this message translates to:
  /// **'A record you delete waits here for {settingsRetentionDaysdays}. Restore it from here to put it back in its list.'**
  String recycleBinEmptyMessage(Object settingsRetentionDaysdays);

  /// How long a record in the recycle bin has before the purge removes it
  ///    for good: [days] whole days, 0 once its window has run out.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Deletes today} one{Deletes in 1 day} other{Deletes in {count} days}}'**
  String recycleBinDaysLeft(int count);

  /// Tooltip of a recycle bin row's restore control.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get recycleBinRestore;

  /// Screen-reader name of the restore control on the row of record
  ///    [name], which is the record's own text (FE-L10N-07).
  ///
  /// In en, this message translates to:
  /// **'Restore {name}'**
  String recycleBinRestoreLabel(Object name);

  /// A restore asked for while the same record is being restored.
  ///
  /// In en, this message translates to:
  /// **'This record is already being restored.'**
  String get recycleBinRestoring;

  /// What to do while a record is being restored.
  ///
  /// In en, this message translates to:
  /// **'Wait a moment, then look for it in its list.'**
  String get recycleBinRestoringAction;

  /// The action that removes everything in the recycle bin now.
  ///
  /// In en, this message translates to:
  /// **'Empty recycle bin'**
  String get recycleBinEmpty;

  /// Title of the strong confirm before [n] records are removed for good.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Remove 1 record for good?} other{Remove {count} records for good?}}'**
  String recycleBinEmptyTitle(int count);

  /// Body of that confirm: what goes, that it cannot be undone, and what
  ///    stays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{The record in the recycle bin and its photos are removed from this device now. This cannot be undone. A record a merge still needs stays until it has been shared.} other{All {count} records in the recycle bin and their photos are removed from this device now. This cannot be undone. Records a merge still needs stay until they have been shared.}}'**
  String recycleBinEmptyWarning(int count);

  /// Label of the field the operator types [n] into to confirm.
  ///
  /// In en, this message translates to:
  /// **'Type {n} to confirm'**
  String recycleBinEmptyTypeCount(int n);

  /// Confirms emptying the recycle bin.
  ///
  /// In en, this message translates to:
  /// **'Remove for good'**
  String get recycleBinEmptyConfirm;

  /// Why Empty recycle bin cannot be pressed on this device.
  ///
  /// In en, this message translates to:
  /// **'Emptying is not available on this device. Each record is removed for good once its days run out.'**
  String get recycleBinEmptyUnavailable;

  /// What to do when emptying is not available.
  ///
  /// In en, this message translates to:
  /// **'Restore what you need before its days run out.'**
  String get recycleBinEmptyUnavailableAction;

  /// An empty-now asked for while the recycle bin is being emptied.
  ///
  /// In en, this message translates to:
  /// **'The recycle bin is already being emptied.'**
  String get recycleBinEmptying;

  /// What to do while the recycle bin is being emptied.
  ///
  /// In en, this message translates to:
  /// **'Wait for it to finish.'**
  String get recycleBinEmptyingAction;

  /// Snack after emptying the recycle bin: how many records were [purged],
  ///    how many were [kept] because a merge still needs them, and how many
  ///    [failed] and stay for the next try.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No records removed} one{1 record removed for good} other{{count} records removed for good}}'**
  String recycleBinEmptied(int count);

  /// Snack after emptying the recycle bin: how many records were [purged],
  ///    how many were [kept] because a merge still needs them, and how many
  ///    [failed] and stay for the next try.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 kept because a merge still needs it} other{{count} kept because a merge still needs them}}'**
  String recycleBinEmptiedOtherKeptBecauseA(int count);

  /// Snack after emptying the recycle bin: how many records were [purged],
  ///    how many were [kept] because a merge still needs them, and how many
  ///    [failed] and stay for the next try.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 could not be removed} other{{count} could not be removed}}'**
  String recycleBinEmptiedOtherCouldNotBe(int count);

  /// The bulk action bar's count of ticked records.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 selected} other{{count} selected}}'**
  String recordsSelectedCount(int count);

  /// Unticks every record and leaves selection mode.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get recordsClearSelection;

  /// Ticks every record the list has shown.
  ///
  /// In en, this message translates to:
  /// **'Select all shown'**
  String get recordsSelectAllShown;

  /// Names the bulk approve control for [n] records.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Approve record} other{Approve {count} records}}'**
  String recordsApproveLabel(int count);

  /// Names the bulk archive control for [n] records.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Archive record} other{Archive {count} records}}'**
  String recordsArchiveLabel(int count);

  /// Names the bulk process-again control for [n] records.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Process record again} other{Process {count} records again}}'**
  String recordsReprocessLabel(int count);

  /// Names the bulk export control for [n] records.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Export record} other{Export {count} records}}'**
  String recordsExportLabel(int count);

  /// Title of the confirm before [n] records are archived.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Archive 1 record?} other{Archive {count} records?}}'**
  String recordsArchiveTitle(int count);

  /// Body of that confirm: where the [n] records go and how to find them.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{It leaves the records list and default exports, and keeps its values and photos. Filter by Archived to find it again.} other{They leave the records list and default exports, and keep their values and photos. Filter by Archived to find them again.}}'**
  String recordsArchiveMessage(int count);

  /// Confirms archiving.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get recordsArchiveConfirm;

  /// Title of the confirm before [n] records are processed again.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Process 1 record again?} other{Process {count} records again?}}'**
  String recordsReprocessTitle(int count);

  /// Body of that confirm: what processing again does to the [n] records.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{It goes back to the processing queue and is read again from the first step, with the other records waiting in this project. Values it already has are kept. If it was approved, it needs review again.} other{They go back to the processing queue and are read again from the first step, with the other records waiting in this project. Values they already have are kept. Approved ones need review again.}}'**
  String recordsReprocessMessage(int count);

  /// Confirms processing again.
  ///
  /// In en, this message translates to:
  /// **'Process again'**
  String get recordsReprocessConfirm;

  /// Title of the confirm before exporting with [n] records selected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Export the project with this record?} other{Export the project with these {count} records?}}'**
  String recordsExportTitle(int count);

  /// Body of that confirm: an export is the whole project's package.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{An export is one package of the whole project: every record in it, this one included, with their photos. You choose where it goes once it is written.} other{An export is one package of the whole project: every record in it, the {count} selected included, with their photos. You choose where it goes once it is written.}}'**
  String recordsExportMessage(int count);

  /// Opens the project's export page.
  ///
  /// In en, this message translates to:
  /// **'Open export'**
  String get recordsExportConfirm;

  /// Snack once [n] records are approved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record approved} other{{count} records approved}}'**
  String recordsApproved(int count);

  /// Snack or line when [n] records could not be approved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record could not be approved} other{{count} records could not be approved}}'**
  String recordsNotApproved(int count);

  /// Snack once [n] records are archived.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record archived} other{{count} records archived}}'**
  String recordsArchived(int count);

  /// Snack or line when [n] records could not be archived.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record could not be archived} other{{count} records could not be archived}}'**
  String recordsNotArchived(int count);

  /// Snack once [n] records are back in the processing queue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record queued to process again} other{{count} records queued to process again}}'**
  String recordsRequeued(int count);

  /// Snack or line when [n] records could not be queued again.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record could not be queued} other{{count} records could not be queued}}'**
  String recordsNotRequeued(int count);

  /// Added to that snack while offline: the [n] queued records wait.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{It waits in the processing queue; process it from there once you are online.} other{They wait in the processing queue; process them from there once you are online.}}'**
  String recordsRequeuedOffline(int count);

  /// A bulk action's summary when some records changed and some did not:
  ///    [done] and [notDone] are the two counted sentences.
  ///
  /// In en, this message translates to:
  /// **'{done}. {notDone}.'**
  String recordsBulkOutcome(Object done, Object notDone);

  /// A bulk action asked for while another is still running.
  ///
  /// In en, this message translates to:
  /// **'Another bulk action is running.'**
  String get recordsBulkBusy;

  /// What to do while a bulk action is running.
  ///
  /// In en, this message translates to:
  /// **'Wait for it to finish, then try again.'**
  String get recordsBulkBusyAction;

  /// How many validation issues a form is showing.
  ///
  /// In en, this message translates to:
  /// **'{validationErrorCounterrors}, {validationWarningCountwarnings}'**
  String validationIssueCount(
    Object validationErrorCounterrors,
    Object validationWarningCountwarnings,
  );

  /// Error count for a validation summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 error} other{{count} errors}}'**
  String validationErrorCount(int count);

  /// Warning count for a validation summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 warning} other{{count} warnings}}'**
  String validationWarningCount(int count);

  /// Jumps the summary to the first field that has an error.
  ///
  /// In en, this message translates to:
  /// **'Go to the first error'**
  String get validationGoToFirstError;

  /// Word beside an error, so the state is not colour alone.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get validationErrorLabel;

  /// Word beside a warning, so the state is not colour alone.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get validationWarningLabel;

  /// A required field that is empty.
  ///
  /// In en, this message translates to:
  /// **'{label} is required.'**
  String validationRequired(Object label);

  /// A value that is the wrong kind for its field.
  ///
  /// In en, this message translates to:
  /// **'{label} is not a valid value for this field.'**
  String validationType(Object label);

  /// A value shorter than the field allows.
  ///
  /// In en, this message translates to:
  /// **'{label} is too short.'**
  String validationTooShort(Object label);

  /// A value longer than the field allows.
  ///
  /// In en, this message translates to:
  /// **'{label} is too long.'**
  String validationTooLong(Object label);

  /// A value outside the field's numeric range.
  ///
  /// In en, this message translates to:
  /// **'{label} is outside the allowed range.'**
  String validationRange(Object label);

  /// A value that does not match the field's pattern.
  ///
  /// In en, this message translates to:
  /// **'{label} does not match the expected pattern.'**
  String validationPattern(Object label);

  /// A choice that is not one of the field's options.
  ///
  /// In en, this message translates to:
  /// **'{label} is not one of the allowed choices.'**
  String validationOption(Object label);

  /// A measurement the field's unit cannot hold.
  ///
  /// In en, this message translates to:
  /// **'{label} is not in a unit this field can store.'**
  String validationUnit(Object label);

  /// An identity field left empty.
  ///
  /// In en, this message translates to:
  /// **'{label} identifies the record and is required.'**
  String validationIdentity(Object label);

  /// Evidence the template demands is missing.
  ///
  /// In en, this message translates to:
  /// **'This record needs its evidence before it can be approved.'**
  String get validationEvidence;

  /// A computed expression that does not parse.
  ///
  /// In en, this message translates to:
  /// **'That expression could not be read.'**
  String get validationExpression;

  /// What to do when an expression does not parse.
  ///
  /// In en, this message translates to:
  /// **'Use fields on this template, comparisons and arithmetic only.'**
  String get validationExpressionAction;

  /// An expression names a field the template does not have.
  ///
  /// In en, this message translates to:
  /// **'Required when names \"{name}\", which this template does not have.'**
  String validationUnknownField(Object name);

  /// Duplicate prompt title.
  ///
  /// In en, this message translates to:
  /// **'This may be a duplicate'**
  String get duplicatePromptTitle;

  /// Writes the new values onto the existing record.
  ///
  /// In en, this message translates to:
  /// **'Update the existing record'**
  String get duplicateOverride;

  /// Keeps both records and links them.
  ///
  /// In en, this message translates to:
  /// **'Keep both and link them'**
  String get duplicateLinkBoth;

  /// Drops the new record.
  ///
  /// In en, this message translates to:
  /// **'Discard the new record'**
  String get duplicateDiscard;

  /// Opens the field-by-field merge.
  ///
  /// In en, this message translates to:
  /// **'Merge field by field'**
  String get duplicateMerge;

  /// Headline when two records do not differ.
  ///
  /// In en, this message translates to:
  /// **'Nothing differs'**
  String get duplicateNoDifferenceHeadline;

  /// Why the duplicate prompt has nothing to compare.
  ///
  /// In en, this message translates to:
  /// **'These records hold the same values.'**
  String get duplicateNoDifferenceMessage;

  /// Duplicate compare title.
  ///
  /// In en, this message translates to:
  /// **'Compare records'**
  String get duplicateCompareTitle;

  /// Merge sheet title.
  ///
  /// In en, this message translates to:
  /// **'Merge fields'**
  String get duplicateMergeTitle;

  /// Keeps this record's value for one field.
  ///
  /// In en, this message translates to:
  /// **'Keep mine'**
  String get duplicateKeepMine;

  /// Takes the other record's value for one field.
  ///
  /// In en, this message translates to:
  /// **'Take theirs'**
  String get duplicateTakeTheirs;

  /// Keeps both values for one field as a note.
  ///
  /// In en, this message translates to:
  /// **'Keep both as a note'**
  String get duplicateKeepBothNote;

  /// The one question the duplicate prompt asks.
  ///
  /// In en, this message translates to:
  /// **'What should happen to these two records?'**
  String get duplicatePromptQuestion;

  /// The prompt's override option: the comparison completes it.
  ///
  /// In en, this message translates to:
  /// **'Compare, then update the existing record'**
  String get duplicateCompareThenUpdate;

  /// Goes on with the outcome chosen in the prompt.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get duplicatePromptContinue;

  /// Heading of the record that was there first.
  ///
  /// In en, this message translates to:
  /// **'Existing record'**
  String get duplicateExistingRecord;

  /// Heading of the newer record.
  ///
  /// In en, this message translates to:
  /// **'New record'**
  String get duplicateNewRecord;

  /// Heading over the fields two records do not share.
  ///
  /// In en, this message translates to:
  /// **'Fields that differ'**
  String get duplicateDifferingFields;

  /// Leaves the comparison for the duplicates list.
  ///
  /// In en, this message translates to:
  /// **'Back to duplicates'**
  String get duplicateBackToList;

  /// A pair's row title: both records. [existing] and [incoming] are data.
  ///
  /// In en, this message translates to:
  /// **'{existing} and {incoming}'**
  String duplicatePairTitle(Object existing, Object incoming);

  /// A pair's group: the signal and the template. [template] is data.
  ///
  /// In en, this message translates to:
  /// **'{signal} · {template}'**
  String duplicatesGroup(Object signal, Object template);

  /// The existing value, then the new one. The values are data.
  ///
  /// In en, this message translates to:
  /// **'{existingisEmptyconflictEmpty} → {incomingisEmptyconflictEmpty}'**
  String duplicateValueChange(
    Object existingisEmptyconflictEmpty,
    Object incomingisEmptyconflictEmpty,
  );

  /// One differing field on a pair's row. The values are data.
  ///
  /// In en, this message translates to:
  /// **'{label}: {duplicateValueChangeexistingincoming}'**
  String duplicateDifferenceLine(
    Object label,
    Object duplicateValueChangeexistingincoming,
  );

  /// Confirm heading before an override.
  ///
  /// In en, this message translates to:
  /// **'Update the existing record?'**
  String get duplicateOverrideConfirmTitle;

  /// Confirm body before an override.
  ///
  /// In en, this message translates to:
  /// **'The existing record takes the new values and photos. The values it replaces stay in its history, and the new record goes to the recycle bin.'**
  String get duplicateOverrideConfirmMessage;

  /// Carries the newer record's photos onto the survivor of a merge.
  ///
  /// In en, this message translates to:
  /// **'Keep the new record\'\'s photos'**
  String get duplicateCarryPhotos;

  /// Explains [duplicateCarryPhotos] with how many photos [n] move.
  ///
  /// In en, this message translates to:
  /// **'{photosCountn} move to the existing record.'**
  String duplicateCarryPhotosHelp(Object photosCountn);

  /// Applies the merge sheet's choices.
  ///
  /// In en, this message translates to:
  /// **'Merge records'**
  String get duplicateMergeApply;

  /// The merge choice for one field. [label] is template data.
  ///
  /// In en, this message translates to:
  /// **'Keep for {label}'**
  String duplicateMergeKeep(Object label);

  /// Merge option: the existing record's value.
  ///
  /// In en, this message translates to:
  /// **'Existing'**
  String get duplicateMergeExisting;

  /// Merge option: the new record's value.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get duplicateMergeNew;

  /// Merge option: both values.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get duplicateMergeBoth;

  /// Why the merge cannot run yet.
  ///
  /// In en, this message translates to:
  /// **'Choose a value for each field.'**
  String get duplicateMergeChooseAll;

  /// Both values of a field kept together. The values are data.
  ///
  /// In en, this message translates to:
  /// **'{existing} / {incoming}'**
  String duplicateBothValues(Object existing, Object incoming);

  /// Outcome after both records are kept and linked.
  ///
  /// In en, this message translates to:
  /// **'Both records kept and linked'**
  String get duplicateResolvedKeepBoth;

  /// Outcome after the new record is discarded.
  ///
  /// In en, this message translates to:
  /// **'New record moved to the recycle bin'**
  String get duplicateResolvedDiscard;

  /// Outcome after an override.
  ///
  /// In en, this message translates to:
  /// **'Existing record updated'**
  String get duplicateResolvedOverride;

  /// Outcome after a merge.
  ///
  /// In en, this message translates to:
  /// **'Records merged'**
  String get duplicateResolvedMerge;

  /// Recycle-bin reason of a discarded duplicate.
  ///
  /// In en, this message translates to:
  /// **'Discarded as a duplicate'**
  String get duplicateDiscardedReason;

  /// Recycle-bin reason of a record whose values overrode another.
  ///
  /// In en, this message translates to:
  /// **'Its values updated an existing record'**
  String get duplicateOverriddenReason;

  /// Recycle-bin reason of a record merged into another.
  ///
  /// In en, this message translates to:
  /// **'Merged into an existing record'**
  String get duplicateMergedReason;

  /// A pair that is resolved or gone.
  ///
  /// In en, this message translates to:
  /// **'That pair is no longer waiting for a choice.'**
  String get duplicatePairGone;

  /// What to do about [duplicatePairGone].
  ///
  /// In en, this message translates to:
  /// **'Go back to the duplicates list; it shows what is left.'**
  String get duplicatePairGoneRecovery;

  /// Runs detection over a whole project.
  ///
  /// In en, this message translates to:
  /// **'Check for duplicates'**
  String get duplicatesScan;

  /// Outcome of [duplicatesScan]: how many new pairs [n] were queued.
  ///
  /// In en, this message translates to:
  /// **'No new duplicate pairs'**
  String get duplicatesScanned;

  /// Outcome of [duplicatesScan]: how many new pairs [n] were queued.
  ///
  /// In en, this message translates to:
  /// **'1 new duplicate pair'**
  String get duplicatesScannedNewDuplicatePair;

  /// Outcome of [duplicatesScan]: how many new pairs [n] were queued.
  ///
  /// In en, this message translates to:
  /// **'{n} new duplicate pairs'**
  String duplicatesScannedNewDuplicatePairs(int n);

  /// The sheet that asks which choice a whole group gets.
  ///
  /// In en, this message translates to:
  /// **'Choose one outcome for the group'**
  String get duplicatesBulkChoose;

  /// Outcome of a bulk choice over [n] pairs.
  ///
  /// In en, this message translates to:
  /// **'1 pair resolved'**
  String get duplicatesBulkDone;

  /// Outcome of a bulk choice over [n] pairs.
  ///
  /// In en, this message translates to:
  /// **'{n} pairs resolved'**
  String duplicatesBulkDonePairsResolved(int n);

  /// A record's badge: the record it is linked to. [title] is data.
  ///
  /// In en, this message translates to:
  /// **'Linked to {title}'**
  String duplicateLinkedTo(Object title);

  /// A record's badge: the record it may duplicate. [title] is data.
  ///
  /// In en, this message translates to:
  /// **'May duplicate {title}'**
  String duplicatePossibleOf(Object title);

  /// Duplicates review title.
  ///
  /// In en, this message translates to:
  /// **'Duplicates'**
  String get duplicatesTitle;

  /// Empty duplicates list headline.
  ///
  /// In en, this message translates to:
  /// **'No duplicate pairs'**
  String get duplicatesEmptyHeadline;

  /// Empty duplicates list explanation.
  ///
  /// In en, this message translates to:
  /// **'Pairs appear here when two records look like the same thing.'**
  String get duplicatesEmptyMessage;

  /// Clears every remaining pair in one group.
  ///
  /// In en, this message translates to:
  /// **'Resolve this group'**
  String get duplicatesResolveGroup;

  /// Bulk confirm title naming [choice] and how many records [n].
  ///
  /// In en, this message translates to:
  /// **'{choice} for {n} records?'**
  String duplicatesBulkTitle(Object choice, int n);

  /// Bulk confirm body naming how many records [n] change.
  ///
  /// In en, this message translates to:
  /// **'This changes {n} records. The other groups stay as they are.'**
  String duplicatesBulkMessage(int n);

  /// Types a value that matches none of the candidates.
  ///
  /// In en, this message translates to:
  /// **'Type a different value'**
  String get conflictTypeOwn;

  /// Keeps the value typed in [conflictTypeOwn].
  ///
  /// In en, this message translates to:
  /// **'Use the typed value'**
  String get conflictUseTyped;

  /// The reason a person gives for the value they chose.
  ///
  /// In en, this message translates to:
  /// **'Why this value'**
  String get conflictReason;

  /// Empty conflict row headline.
  ///
  /// In en, this message translates to:
  /// **'No candidates'**
  String get conflictEmptyHeadline;

  /// Empty conflict row explanation.
  ///
  /// In en, this message translates to:
  /// **'Nothing was proposed for this field.'**
  String get conflictEmptyMessage;

  /// Unresolved conflict blocks approval and names the field.
  ///
  /// In en, this message translates to:
  /// **'{label} still has a conflict. Resolve it before approving.'**
  String conflictBlocksApproval(Object label);

  /// Verification mode switch title.
  ///
  /// In en, this message translates to:
  /// **'Verification mode'**
  String get verificationModeTitle;

  /// Shown while verification mode is on.
  ///
  /// In en, this message translates to:
  /// **'Capture confirms the register instead of starting a blank record.'**
  String get verificationModeOn;

  /// Shown while verification mode is off.
  ///
  /// In en, this message translates to:
  /// **'Capture starts a new record.'**
  String get verificationModeOff;

  /// Status line mark while verification mode is on.
  ///
  /// In en, this message translates to:
  /// **'Verifying'**
  String get verificationStatus;

  /// A value that came from the register.
  ///
  /// In en, this message translates to:
  /// **'From the register'**
  String get verificationFromRegister;

  /// Variance screen title.
  ///
  /// In en, this message translates to:
  /// **'Variances'**
  String get varianceTitle;

  /// Empty variance list headline.
  ///
  /// In en, this message translates to:
  /// **'No variances'**
  String get varianceEmptyHeadline;

  /// Empty variance list explanation.
  ///
  /// In en, this message translates to:
  /// **'Differences between the register and what was found appear here.'**
  String get varianceEmptyMessage;

  /// A normalised match.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get varianceMatch;

  /// A genuine difference.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get varianceChanged;

  /// A register value with nothing found.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get varianceMissing;

  /// A variance row's detail: its status and both values, which are data.
  ///
  /// In en, this message translates to:
  /// **'{status} · {recordedisEmptyconflictEmpty} → {foundisEmptyconflictEmpty}'**
  String varianceDetail(
    Object status,
    Object recordedisEmptyconflictEmpty,
    Object foundisEmptyconflictEmpty,
  );

  /// Register rows no record was captured from.
  ///
  /// In en, this message translates to:
  /// **'Register rows not found'**
  String get varianceRegisterNotFound;

  /// Checklist rows never captured.
  ///
  /// In en, this message translates to:
  /// **'Checklist rows not captured'**
  String get varianceChecklistNotCaptured;

  /// The variance empty state's next step.
  ///
  /// In en, this message translates to:
  /// **'Open records'**
  String get varianceOpenRecords;

  /// Quality summary title.
  ///
  /// In en, this message translates to:
  /// **'Data quality'**
  String get qualitySummaryTitle;

  /// Records that fail validation.
  ///
  /// In en, this message translates to:
  /// **'Invalid records'**
  String get qualityInvalid;

  /// Unresolved duplicate pairs.
  ///
  /// In en, this message translates to:
  /// **'Duplicate pairs'**
  String get qualityDuplicates;

  /// Unresolved source conflicts.
  ///
  /// In en, this message translates to:
  /// **'Unresolved conflicts'**
  String get qualityConflicts;

  /// Records still waiting for review.
  ///
  /// In en, this message translates to:
  /// **'Unreviewed records'**
  String get qualityUnreviewed;

  /// Headline when nothing blocks export.
  ///
  /// In en, this message translates to:
  /// **'Ready to export'**
  String get qualityCleanHeadline;

  /// Explanation when nothing blocks export.
  ///
  /// In en, this message translates to:
  /// **'Nothing here still blocks a clean export.'**
  String get qualityCleanMessage;

  /// Review screen title.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewTitle;

  /// Fields that need a person before approval.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get reviewNeedsAttention;

  /// Confident fields, collapsed until opened.
  ///
  /// In en, this message translates to:
  /// **'Confident'**
  String get reviewConfident;

  /// The confident group's heading, with how many fields it holds.
  ///
  /// In en, this message translates to:
  /// **'Confident ({count})'**
  String reviewConfidentGroup(int count);

  /// Approves this record and opens the next one.
  ///
  /// In en, this message translates to:
  /// **'Approve and next'**
  String get reviewApproveNext;

  /// Empty review headline.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review'**
  String get reviewEmptyHeadline;

  /// Empty review explanation.
  ///
  /// In en, this message translates to:
  /// **'Records that need a person appear here.'**
  String get reviewEmptyMessage;

  /// Shows the captured value.
  ///
  /// In en, this message translates to:
  /// **'Use captured'**
  String get reviewUseRaw;

  /// Shows the refined value.
  ///
  /// In en, this message translates to:
  /// **'Use refined'**
  String get reviewUseRefined;

  /// Neither side has a value.
  ///
  /// In en, this message translates to:
  /// **'No values yet'**
  String get reviewNoSidesHeadline;

  /// Why the raw or refined toggle has nothing to choose.
  ///
  /// In en, this message translates to:
  /// **'This field has neither a captured nor a refined value.'**
  String get reviewNoSidesMessage;

  /// A value the extractor did not invent.
  ///
  /// In en, this message translates to:
  /// **'Not detected'**
  String get reviewNotDetected;

  /// Types the missing value.
  ///
  /// In en, this message translates to:
  /// **'Type it'**
  String get reviewTypeIt;

  /// Photographs the label for the missing value.
  ///
  /// In en, this message translates to:
  /// **'Photograph the label'**
  String get reviewPhotograph;

  /// No missing value to act on.
  ///
  /// In en, this message translates to:
  /// **'Nothing is missing'**
  String get reviewNotDetectedEmpty;

  /// Opens the evidence for a value.
  ///
  /// In en, this message translates to:
  /// **'Show evidence'**
  String get reviewShowEvidence;

  /// Opens the full photo.
  ///
  /// In en, this message translates to:
  /// **'Open photo'**
  String get reviewOpenPhoto;

  /// Evidence with no photo and no passage.
  ///
  /// In en, this message translates to:
  /// **'No evidence linked'**
  String get reviewEvidenceEmpty;

  /// Verifies the current value without changing it.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get reviewVerify;

  /// Verifies every confident field.
  ///
  /// In en, this message translates to:
  /// **'Verify confident fields'**
  String get reviewVerifyConfident;

  /// Who verified a value, and when.
  ///
  /// In en, this message translates to:
  /// **'Verified by {name}'**
  String reviewVerifiedBy(Object name);

  /// Nothing to verify.
  ///
  /// In en, this message translates to:
  /// **'Nothing to verify'**
  String get reviewVerifyEmpty;

  /// Batch position, [index] of [total], both 1-based for [index].
  ///
  /// In en, this message translates to:
  /// **'{index} of {total}'**
  String reviewPosition(int index, int total);

  /// Skips this record and keeps what was typed.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get reviewSkip;

  /// Returns to the previous record.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get reviewBack;

  /// The batch queue is finished.
  ///
  /// In en, this message translates to:
  /// **'Review is finished'**
  String get reviewQueueDone;

  /// What to do when the queue is finished.
  ///
  /// In en, this message translates to:
  /// **'Every record in this set has been seen.'**
  String get reviewQueueDoneMessage;

  /// The batch queue has no records.
  ///
  /// In en, this message translates to:
  /// **'No records in this review'**
  String get reviewQueueEmpty;

  /// Runs processing again.
  ///
  /// In en, this message translates to:
  /// **'Re-analyse'**
  String get reviewReanalyse;

  /// A proposed value offered beside the current one.
  ///
  /// In en, this message translates to:
  /// **'Proposed'**
  String get reviewProposal;

  /// Marks a proposal the person accepts.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get reviewAccept;

  /// Writes the accepted proposals.
  ///
  /// In en, this message translates to:
  /// **'Apply accepted'**
  String get reviewApplyAccepted;

  /// Declines every proposal.
  ///
  /// In en, this message translates to:
  /// **'Decline all'**
  String get reviewDeclineAll;

  /// A verified or typed value that re-analysis must not overwrite.
  ///
  /// In en, this message translates to:
  /// **'Offered, not applied'**
  String get reviewOfferedNotApplied;

  /// No new proposals.
  ///
  /// In en, this message translates to:
  /// **'No new proposals'**
  String get reviewReanalyseEmpty;

  /// This record is still in an unresolved duplicate pair.
  ///
  /// In en, this message translates to:
  /// **'This record is part of an unresolved duplicate.'**
  String get reviewBlockedDuplicate;

  /// Where to clear a block.
  ///
  /// In en, this message translates to:
  /// **'Fix the named field, then approve again.'**
  String get reviewBlockedAction;

  /// Empty confidence indicator headline.
  ///
  /// In en, this message translates to:
  /// **'No confidence'**
  String get reviewNoConfidence;

  /// Empty confidence indicator explanation.
  ///
  /// In en, this message translates to:
  /// **'This value has no confidence band yet.'**
  String get reviewNoConfidenceMessage;

  /// Audit line when review approves a record.
  ///
  /// In en, this message translates to:
  /// **'Approved in review.'**
  String get reviewApprovedReason;

  /// Audit line when a person verifies a value without changing it.
  ///
  /// In en, this message translates to:
  /// **'Verified in review.'**
  String get reviewVerifiedReason;

  /// Audit line when a person picks the captured or the refined side.
  ///
  /// In en, this message translates to:
  /// **'Final side chosen in review.'**
  String get reviewSideReason;

  /// Why review refused a write: the record is approved or in the bin.
  ///
  /// In en, this message translates to:
  /// **'This record is approved or in the recycle bin.'**
  String get reviewRecordSettled;

  /// What to do about [reviewRecordSettled].
  ///
  /// In en, this message translates to:
  /// **'Send it back to review from its record page, then try again.'**
  String get reviewRecordSettledAction;

  /// Why review refused a write: the record is not on this device.
  ///
  /// In en, this message translates to:
  /// **'That record is no longer on this device.'**
  String get reviewRecordGone;

  /// What to do about [reviewRecordGone].
  ///
  /// In en, this message translates to:
  /// **'Go back to the records list and open another record.'**
  String get reviewRecordGoneAction;

  /// Label of the control that picks which side of a value is final.
  ///
  /// In en, this message translates to:
  /// **'Final value'**
  String get reviewFinalSide;

  /// Moves back to the previous record in the review queue.
  ///
  /// In en, this message translates to:
  /// **'Previous record'**
  String get reviewPreviousRecord;

  /// The review empty state's next step.
  ///
  /// In en, this message translates to:
  /// **'Back to records'**
  String get reviewBackToRecords;

  /// Snack after verifying [count] values without changing them.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 value verified} other{{count} values verified}}'**
  String reviewVerifiedCount(int count);

  /// A verified value's mark.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get reviewVerified;

  /// Title of the sheet showing where a value came from.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get reviewEvidenceTitle;

  /// Source label of photo evidence.
  ///
  /// In en, this message translates to:
  /// **'From a photo'**
  String get reviewEvidencePhoto;

  /// Source label of document evidence on [page], when known.
  ///
  /// In en, this message translates to:
  /// **'From a document'**
  String get reviewEvidenceDocument;

  /// Source label of document evidence on [page], when known.
  ///
  /// In en, this message translates to:
  /// **'From a document, page {page}'**
  String reviewEvidenceDocumentFromADocumentPage(Object page);

  /// Source label of transcript evidence.
  ///
  /// In en, this message translates to:
  /// **'From a transcript'**
  String get reviewEvidenceTranscript;

  /// The highlighted region on an evidence photo, for a screen reader.
  ///
  /// In en, this message translates to:
  /// **'Where the value was read'**
  String get reviewEvidenceRegion;

  /// Snack after re-analysis was queued.
  ///
  /// In en, this message translates to:
  /// **'Queued for re-analysis. New values are offered here when it finishes.'**
  String get reviewReanalyseQueued;

  /// Banner while re-analysis runs.
  ///
  /// In en, this message translates to:
  /// **'Re-analysing. Nothing changes until you accept a proposal.'**
  String get reviewReanalysing;

  /// Heading of the proposals re-analysis offers.
  ///
  /// In en, this message translates to:
  /// **'Proposed values'**
  String get reviewProposalsTitle;

  /// One proposal: the [current] value beside the [proposed] one.
  ///
  /// In en, this message translates to:
  /// **'Now: {currentisEmptyrecordFieldEmpty} · Proposed: {proposed}'**
  String reviewProposalLine(
    Object currentisEmptyrecordFieldEmpty,
    Object proposed,
  );

  /// Snack after accepted proposals were written.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 proposal applied} other{{count} proposals applied}}'**
  String reviewProposalsApplied(int count);

  /// Meeting create page title.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get meetingTitle;

  /// Starts a meeting from the prefilled header.
  ///
  /// In en, this message translates to:
  /// **'Start meeting'**
  String get meetingStart;

  /// Empty meeting headline.
  ///
  /// In en, this message translates to:
  /// **'No meeting yet'**
  String get meetingEmptyHeadline;

  /// Empty meeting explanation.
  ///
  /// In en, this message translates to:
  /// **'Date, time, location and secretary fill in from this project.'**
  String get meetingEmptyMessage;

  /// Header date label.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get meetingDate;

  /// Header start-time label.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get meetingStartTime;

  /// Header location label.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get meetingLocation;

  /// Header secretary label.
  ///
  /// In en, this message translates to:
  /// **'Secretary'**
  String get meetingSecretary;

  /// Title written when a meeting starts, from the clock's date.
  ///
  /// In en, this message translates to:
  /// **'Meeting {whenyear}-{month}-{day}'**
  String meetingStartedTitle(Object whenyear, Object month, Object day);

  /// Attachments section.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get meetingAttachments;

  /// Adds an attachment.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get meetingAddAttachment;

  /// Empty attachments headline.
  ///
  /// In en, this message translates to:
  /// **'No attachments'**
  String get meetingAttachmentsEmpty;

  /// Empty attachments explanation.
  ///
  /// In en, this message translates to:
  /// **'Agendas, reports, handouts and whiteboard photos land here.'**
  String get meetingAttachmentsEmptyMessage;

  /// Opens an attachment.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get meetingOpenAttachment;

  /// Agenda section.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get meetingAgenda;

  /// Adds an agenda entry.
  ///
  /// In en, this message translates to:
  /// **'Add agenda item'**
  String get meetingAddAgenda;

  /// Agenda title field.
  ///
  /// In en, this message translates to:
  /// **'Agenda item'**
  String get meetingAgendaTitle;

  /// Discussion notes under an agenda entry.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get meetingDiscussion;

  /// Moves an entry later.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get meetingMoveDown;

  /// Removes an entry after confirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get meetingRemove;

  /// Confirm title for a removal.
  ///
  /// In en, this message translates to:
  /// **'Remove this?'**
  String get meetingRemoveTitle;

  /// Confirm body for a removal.
  ///
  /// In en, this message translates to:
  /// **'This leaves the meeting.'**
  String get meetingRemoveMessage;

  /// Confirm button for a removal.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get meetingRemoveConfirm;

  /// Empty agenda headline.
  ///
  /// In en, this message translates to:
  /// **'No agenda yet'**
  String get meetingAgendaEmpty;

  /// Empty agenda explanation.
  ///
  /// In en, this message translates to:
  /// **'Add the items you will discuss, in the order you want them.'**
  String get meetingAgendaEmptyMessage;

  /// Attendees section.
  ///
  /// In en, this message translates to:
  /// **'Attendees'**
  String get meetingAttendees;

  /// Adds an attendee.
  ///
  /// In en, this message translates to:
  /// **'Add attendee'**
  String get meetingAddAttendee;

  /// Attendee name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get meetingAttendeeName;

  /// Attendee title field.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get meetingAttendeeRole;

  /// Attendee organisation field.
  ///
  /// In en, this message translates to:
  /// **'Organisation'**
  String get meetingOrganisation;

  /// Attendee contact field.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get meetingContact;

  /// Marks the person present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get meetingPresent;

  /// Marks an apology.
  ///
  /// In en, this message translates to:
  /// **'Apology'**
  String get meetingApology;

  /// How many people are present. Apologies are not included.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 present} other{{count} present}}'**
  String meetingAttendanceCount(int count);

  /// Accepts a staff suggestion.
  ///
  /// In en, this message translates to:
  /// **'Link staff'**
  String get meetingAcceptStaff;

  /// Empty attendees headline.
  ///
  /// In en, this message translates to:
  /// **'No attendees yet'**
  String get meetingAttendeesEmpty;

  /// Empty attendees explanation.
  ///
  /// In en, this message translates to:
  /// **'Add who is present, and record apologies separately.'**
  String get meetingAttendeesEmptyMessage;

  /// Attendance sheet section.
  ///
  /// In en, this message translates to:
  /// **'Attendance sheet'**
  String get meetingAttendanceSheet;

  /// Photographs the signed sheet.
  ///
  /// In en, this message translates to:
  /// **'Photograph the sheet'**
  String get meetingPhotographSheet;

  /// Accepts the edited rows onto the attendee list.
  ///
  /// In en, this message translates to:
  /// **'Add these attendees'**
  String get meetingAcceptRows;

  /// A poor read still keeps the photo.
  ///
  /// In en, this message translates to:
  /// **'The photo stays attached. Type the names if the reading is wrong.'**
  String get meetingSheetKept;

  /// Empty attendance headline.
  ///
  /// In en, this message translates to:
  /// **'No attendance sheet'**
  String get meetingSheetEmpty;

  /// Empty attendance explanation.
  ///
  /// In en, this message translates to:
  /// **'Photograph the signed sheet, then check each name before adding it.'**
  String get meetingSheetEmptyMessage;

  /// Signature column.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get meetingSignature;

  /// Recording section.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get meetingRecording;

  /// Starts recording.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get meetingRecord;

  /// Stops recording.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get meetingStop;

  /// Elapsed recording time.
  ///
  /// In en, this message translates to:
  /// **'Elapsed {clock}'**
  String meetingElapsed(Object clock);

  /// Free space while recording.
  ///
  /// In en, this message translates to:
  /// **'{label} free'**
  String meetingRemaining(Object label);

  /// A recording interrupted before stop.
  ///
  /// In en, this message translates to:
  /// **'Recording interrupted'**
  String get meetingInterrupted;

  /// Empty recording headline.
  ///
  /// In en, this message translates to:
  /// **'No recording'**
  String get meetingRecordingEmpty;

  /// Empty recording explanation.
  ///
  /// In en, this message translates to:
  /// **'A recording stays on the meeting, including one that was interrupted.'**
  String get meetingRecordingEmptyMessage;

  /// Decisions section.
  ///
  /// In en, this message translates to:
  /// **'Decisions'**
  String get meetingDecisions;

  /// Adds a decision.
  ///
  /// In en, this message translates to:
  /// **'Add decision'**
  String get meetingAddDecision;

  /// Decision text field.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get meetingDecisionText;

  /// Where a refined decision came from.
  ///
  /// In en, this message translates to:
  /// **'From the notes'**
  String get meetingSource;

  /// Empty decisions headline.
  ///
  /// In en, this message translates to:
  /// **'No decisions yet'**
  String get meetingDecisionsEmpty;

  /// Empty decisions explanation.
  ///
  /// In en, this message translates to:
  /// **'Decisions from the minutes or typed here are listed together.'**
  String get meetingDecisionsEmptyMessage;

  /// Actions section.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get meetingActions;

  /// Adds an action.
  ///
  /// In en, this message translates to:
  /// **'Add action'**
  String get meetingAddAction;

  /// Action text field.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get meetingActionText;

  /// Owner field.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get meetingOwner;

  /// Due date field.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get meetingDue;

  /// Picks an owner from the attendees.
  ///
  /// In en, this message translates to:
  /// **'Owner from attendees'**
  String get meetingOwnerAttendee;

  /// Picks an owner from the staff dataset.
  ///
  /// In en, this message translates to:
  /// **'Owner from staff'**
  String get meetingOwnerStaff;

  /// Action status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get meetingStatus;

  /// Empty actions headline.
  ///
  /// In en, this message translates to:
  /// **'No actions yet'**
  String get meetingActionsEmpty;

  /// Empty actions explanation.
  ///
  /// In en, this message translates to:
  /// **'Actions keep an owner, a due date and a status.'**
  String get meetingActionsEmptyMessage;

  /// Raw notes beside the minutes.
  ///
  /// In en, this message translates to:
  /// **'Raw notes'**
  String get meetingNotes;

  /// Refined minutes beside the notes.
  ///
  /// In en, this message translates to:
  /// **'Refined minutes'**
  String get meetingMinutes;

  /// Verbatim transcript, never edited here.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get meetingTranscript;

  /// Blocks approval and names the action.
  ///
  /// In en, this message translates to:
  /// **'{action} needs an owner and a due date before it can be approved.'**
  String meetingActionBlocked(Object action);

  /// Approves the meeting.
  ///
  /// In en, this message translates to:
  /// **'Approve meeting'**
  String get meetingApprove;

  /// Review page title.
  ///
  /// In en, this message translates to:
  /// **'Review meeting'**
  String get meetingReviewTitle;

  /// Empty review headline.
  ///
  /// In en, this message translates to:
  /// **'No meeting to review'**
  String get meetingReviewEmpty;

  /// Empty review explanation.
  ///
  /// In en, this message translates to:
  /// **'Open a meeting to see attendance, decisions and actions.'**
  String get meetingReviewEmptyMessage;

  /// Audit line when a meeting is approved.
  ///
  /// In en, this message translates to:
  /// **'Approved in review.'**
  String get meetingApprovedReason;

  /// Starts a meeting from a project, or opens the one a record holds.
  ///
  /// In en, this message translates to:
  /// **'Start a meeting'**
  String get meetingStartEntry;

  /// Opens the meeting a record holds.
  ///
  /// In en, this message translates to:
  /// **'Open meeting'**
  String get meetingOpen;

  /// Name a project's installed meeting template takes.
  ///
  /// In en, this message translates to:
  /// **'Meeting notes capture'**
  String get meetingTemplateName;

  /// A header value nothing filled in.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get meetingNotSet;

  /// The project a meeting would be filed on is gone.
  ///
  /// In en, this message translates to:
  /// **'This project is no longer here'**
  String get meetingNoProject;

  /// What to do when there is no project to start a meeting on.
  ///
  /// In en, this message translates to:
  /// **'Open a project, then start the meeting from it.'**
  String get meetingNoProjectMessage;

  /// Returns to the project list.
  ///
  /// In en, this message translates to:
  /// **'Back to projects'**
  String get meetingBackToProjects;

  /// Summary section of the review.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get meetingSummary;

  /// How many decisions the meeting holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No decisions} one{1 decision} other{{count} decisions}}'**
  String meetingDecisionsCount(int count);

  /// How many actions the meeting holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No actions} one{1 action} other{{count} actions}}'**
  String meetingActionsCount(int count);

  /// The raw notes and refined minutes section.
  ///
  /// In en, this message translates to:
  /// **'Notes and minutes'**
  String get meetingNotesAndMinutes;

  /// Refines the minutes from the notes and the transcript.
  ///
  /// In en, this message translates to:
  /// **'Refine minutes'**
  String get meetingRefine;

  /// Refinement summarises per agenda point, so it needs an agenda.
  ///
  /// In en, this message translates to:
  /// **'Add the agenda first, so each point gets its own summary.'**
  String get meetingRefineNeedsAgenda;

  /// Names what the notes and the transcript do not support.
  ///
  /// In en, this message translates to:
  /// **'Not in the notes or transcript: {namesjoin}. Check these before approving.'**
  String meetingUnsupported(Object namesjoin);

  /// One agenda point's line in the refined minutes.
  ///
  /// In en, this message translates to:
  /// **'{title}: {summary}'**
  String meetingMinutesLine(Object title, Object summary);

  /// One transcription run of the recording.
  ///
  /// In en, this message translates to:
  /// **'Transcript, run {version}'**
  String meetingTranscriptVersion(int version);

  /// Marks an older transcription run of a meeting recording made by an online service; it is read-only.
  ///
  /// In en, this message translates to:
  /// **'Online transcription'**
  String get meetingTranscriptCloudVersion;

  /// Parts of a recording one run could not transcribe.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 part could not be transcribed} other{{count} parts could not be transcribed}}'**
  String meetingTranscriptGaps(int count);

  /// Transcribes a recording.
  ///
  /// In en, this message translates to:
  /// **'Transcribe'**
  String get meetingTranscribe;

  /// Transcription progress, one part at a time.
  ///
  /// In en, this message translates to:
  /// **'Transcribing part {done} of {total}'**
  String meetingTranscribing(int done, int total);

  /// No service can transcribe right now.
  ///
  /// In en, this message translates to:
  /// **'Transcription is not available right now. The recording stays on the meeting.'**
  String get meetingTranscribeUnavailable;

  /// Plays a recording in the device's player.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get meetingPlay;

  /// A take that was interrupted is still on the meeting.
  ///
  /// In en, this message translates to:
  /// **'Recording interrupted. What was recorded is kept on the meeting.'**
  String get meetingInterruptedKept;

  /// Photographs a handout or a whiteboard.
  ///
  /// In en, this message translates to:
  /// **'Photograph a handout'**
  String get meetingPhotographHandout;

  /// An attached document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get meetingDocument;

  /// An attached photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get meetingPhoto;

  /// What an attachment is, and its size.
  ///
  /// In en, this message translates to:
  /// **'{kind} · {fileSizebytes}'**
  String meetingFileDetail(Object kind, Object fileSizebytes);

  /// A recording's length and size.
  ///
  /// In en, this message translates to:
  /// **'{minutes}:{seconds} · {fileSizebytes}'**
  String meetingRecordingDetail(
    Object minutes,
    Object seconds,
    Object fileSizebytes,
  );

  /// A cell of the sheet that read with low confidence.
  ///
  /// In en, this message translates to:
  /// **'Check this: the sheet was hard to read here.'**
  String get meetingCheckReading;

  /// A signature was seen on the sheet.
  ///
  /// In en, this message translates to:
  /// **'Signed on the sheet'**
  String get meetingSigned;

  /// Whether a person attended or sent apologies.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get meetingAttendance;

  /// A staff row offered for a captured name, with its match score.
  ///
  /// In en, this message translates to:
  /// **'Staff list: {name} ({score100round}% match)'**
  String meetingStaffSuggestion(Object name, Object score100round);

  /// The staff row a person accepted.
  ///
  /// In en, this message translates to:
  /// **'Linked to staff: {name}'**
  String meetingStaffLinked(Object name);

  /// Removes an accepted staff link.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get meetingUnlinkStaff;

  /// One owner a person can pick for an action.
  ///
  /// In en, this message translates to:
  /// **'{name} · Staff'**
  String meetingOwnerOption(Object name);

  /// One owner a person can pick for an action.
  ///
  /// In en, this message translates to:
  /// **'{name} · Attendee'**
  String meetingOwnerOptionAttendee(Object name);

  /// Action status: not finished.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get meetingStatusOpen;

  /// Action status: under way.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get meetingStatusInProgress;

  /// Action status: finished.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get meetingStatusDone;

  /// Where a refined decision or action was read from.
  ///
  /// In en, this message translates to:
  /// **'{meetingSource}: {source}'**
  String meetingSourceLine(Object meetingSource, Object source);

  /// Drag handle of one agenda point.
  ///
  /// In en, this message translates to:
  /// **'Drag {titletrimisEmpty} to reorder'**
  String meetingDrag(Object titletrimisEmpty);

  /// Moves an entry earlier.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get meetingMoveUp;

  /// Deliverable export page title.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportTitle;

  /// Starts the export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportRun;

  /// Scope section title.
  ///
  /// In en, this message translates to:
  /// **'What to include'**
  String get exportScope;

  /// Approved records only.
  ///
  /// In en, this message translates to:
  /// **'Approved only'**
  String get exportScopeApproved;

  /// Every record.
  ///
  /// In en, this message translates to:
  /// **'All records'**
  String get exportScopeAll;

  /// The current context subtree.
  ///
  /// In en, this message translates to:
  /// **'Current context'**
  String get exportScopeContext;

  /// A date range.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get exportScopeDates;

  /// The records list filter.
  ///
  /// In en, this message translates to:
  /// **'Current filter'**
  String get exportScopeFilter;

  /// How many records the scope selects.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String exportCount(int count);

  /// Options section title.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get exportOptions;

  /// Raw value columns.
  ///
  /// In en, this message translates to:
  /// **'Raw columns'**
  String get exportRaw;

  /// Refined value columns.
  ///
  /// In en, this message translates to:
  /// **'Refined columns'**
  String get exportRefined;

  /// Confidence column.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get exportConfidence;

  /// Evidence column.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get exportEvidence;

  /// Collapsed extras.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get exportAdvanced;

  /// Photo reference mode.
  ///
  /// In en, this message translates to:
  /// **'Photo reference'**
  String get exportPhotoMode;

  /// CSV delimiter.
  ///
  /// In en, this message translates to:
  /// **'Delimiter'**
  String get exportDelimiter;

  /// Empty export headline.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export'**
  String get exportEmptyHeadline;

  /// Empty export explanation.
  ///
  /// In en, this message translates to:
  /// **'This scope has no records yet.'**
  String get exportEmptyMessage;

  /// Progress: records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get exportStageRecords;

  /// Progress: photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get exportStagePhotos;

  /// Progress: reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get exportStageReports;

  /// Progress: archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get exportStageArchive;

  /// Stops an export and removes partial files.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get exportCancel;

  /// History page title.
  ///
  /// In en, this message translates to:
  /// **'Export history'**
  String get exportHistoryTitle;

  /// Empty history headline.
  ///
  /// In en, this message translates to:
  /// **'No exports yet'**
  String get exportHistoryEmpty;

  /// Empty history explanation.
  ///
  /// In en, this message translates to:
  /// **'A finished export is kept here, with who made it and what it held.'**
  String get exportHistoryEmptyMessage;

  /// Shares a recorded file again.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get exportShare;

  /// The recorded file is gone.
  ///
  /// In en, this message translates to:
  /// **'That file is no longer on this device.'**
  String get exportMissing;

  /// Offers to run the stored request again.
  ///
  /// In en, this message translates to:
  /// **'Run this export again'**
  String get exportRerun;

  /// Gate: go fix the records.
  ///
  /// In en, this message translates to:
  /// **'Fix now'**
  String get exportFixNow;

  /// Gate: leave the incomplete ones out.
  ///
  /// In en, this message translates to:
  /// **'Leave them out'**
  String get exportExclude;

  /// Gate: export and mark the file incomplete.
  ///
  /// In en, this message translates to:
  /// **'Export anyway'**
  String get exportAnyway;

  /// Stamp written into an incomplete export.
  ///
  /// In en, this message translates to:
  /// **'Marked incomplete'**
  String get exportIncompleteStamp;

  /// Why an export with no records in its scope was not written.
  ///
  /// In en, this message translates to:
  /// **'Choose a scope with records.'**
  String get exportEmptyRecovery;

  /// Why an export with no file chosen was not written.
  ///
  /// In en, this message translates to:
  /// **'Choose an output format.'**
  String get exportNoFormat;

  /// Why a history row cannot be run again from its stored request.
  ///
  /// In en, this message translates to:
  /// **'This export is no longer available.'**
  String get exportReplayMissing;

  /// Export screen: what the export writes.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get exportOutput;

  /// Output choice: chosen reports and data files for readers outside the
  ///    app. The project package is [exportFileFormat].
  ///
  /// In en, this message translates to:
  /// **'Reports and data files'**
  String get exportOutputFiles;

  /// Export screen: which files the reports-and-data output writes.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get exportFormats;

  /// File choice: the workbook.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet (.xlsx)'**
  String get exportFormatXlsx;

  /// File choice: one CSV file per template.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get exportFormatCsv;

  /// File choice: full-fidelity JSON.
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get exportFormatJson;

  /// File choice: the PDF reports.
  ///
  /// In en, this message translates to:
  /// **'PDF reports'**
  String get exportFormatPdf;

  /// Date-range scope: first capture day included.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get exportScopeFrom;

  /// Date-range scope: last capture day included.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get exportScopeTo;

  /// Advanced extra: the data dictionary.
  ///
  /// In en, this message translates to:
  /// **'Data dictionary'**
  String get exportDictionary;

  /// Workbook photo reference: the file name only.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get exportPhotoFilename;

  /// Workbook photo reference: the path inside the package.
  ///
  /// In en, this message translates to:
  /// **'Path in the package'**
  String get exportPhotoRelative;

  /// Workbook photo reference: the image itself.
  ///
  /// In en, this message translates to:
  /// **'Embedded image'**
  String get exportPhotoEmbed;

  /// Advanced extra: how reports lay out photos.
  ///
  /// In en, this message translates to:
  /// **'Report photos'**
  String get exportPdfPhotos;

  /// Report photo layout: several to a row.
  ///
  /// In en, this message translates to:
  /// **'Thumbnails'**
  String get exportPdfThumbnails;

  /// Report photo layout: one to a row.
  ///
  /// In en, this message translates to:
  /// **'Full size'**
  String get exportPdfFull;

  /// CSV delimiter choice: comma.
  ///
  /// In en, this message translates to:
  /// **'Comma'**
  String get exportDelimiterComma;

  /// CSV delimiter choice: semicolon.
  ///
  /// In en, this message translates to:
  /// **'Semicolon'**
  String get exportDelimiterSemicolon;

  /// CSV delimiter choice: tab.
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get exportDelimiterTab;

  /// Pre-export gate title, naming how many records need a decision.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record needs attention} other{{count} records need attention}}'**
  String exportGateTitle(int count);

  /// Gate choice detail: fix the records first.
  ///
  /// In en, this message translates to:
  /// **'Open the records that need attention. Nothing is exported.'**
  String get exportFixNowHint;

  /// Gate choice detail: export the rest.
  ///
  /// In en, this message translates to:
  /// **'Export the other {recordsCountntoLowerCase}.'**
  String exportExcludeHint(Object recordsCountntoLowerCase);

  /// Gate choice detail: export everything, stamped incomplete.
  ///
  /// In en, this message translates to:
  /// **'Every file says it is incomplete.'**
  String get exportAnywayHint;

  /// Report footer page number.
  ///
  /// In en, this message translates to:
  /// **'{page} of {pages}'**
  String pdfPageOf(int page, int pages);

  /// Printed where a photo could not be read.
  ///
  /// In en, this message translates to:
  /// **'Missing photo'**
  String get pdfMissingPhoto;

  /// Report title: one section per record.
  ///
  /// In en, this message translates to:
  /// **'Record report'**
  String get pdfRecordReport;

  /// Report label of when a record was captured.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get pdfCaptured;

  /// A field label marked as the raw value.
  ///
  /// In en, this message translates to:
  /// **'{label} (raw)'**
  String pdfRaw(Object label);

  /// A field label marked as the refined value.
  ///
  /// In en, this message translates to:
  /// **'{label} (refined)'**
  String pdfRefined(Object label);

  /// Report title: a checklist in its predefined order.
  ///
  /// In en, this message translates to:
  /// **'Inspection report'**
  String get pdfInspectionReport;

  /// A checklist row never captured.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get pdfNotFound;

  /// How many predefined rows a checklist has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 checklist row} other{{count} checklist rows}}'**
  String pdfChecklistRows(int count);

  /// How many checklist rows were not found.
  ///
  /// In en, this message translates to:
  /// **'{n} not found'**
  String pdfNotFoundCount(int n);

  /// How many checklist rows comply.
  ///
  /// In en, this message translates to:
  /// **'Compliant: {compliant} of {total}'**
  String pdfCompliance(int compliant, int total);

  /// Report title: the project's counts.
  ///
  /// In en, this message translates to:
  /// **'Project summary'**
  String get pdfSummaryReport;

  /// Summary heading: counts by context.
  ///
  /// In en, this message translates to:
  /// **'By context'**
  String get pdfByContext;

  /// Summary heading: counts by template.
  ///
  /// In en, this message translates to:
  /// **'By template'**
  String get pdfByTemplate;

  /// Summary heading: counts by condition.
  ///
  /// In en, this message translates to:
  /// **'By condition'**
  String get pdfByCondition;

  /// Summary heading: counts by status.
  ///
  /// In en, this message translates to:
  /// **'By status'**
  String get pdfByStatus;

  /// Summary group of records captured with no context.
  ///
  /// In en, this message translates to:
  /// **'No context'**
  String get pdfNoContext;

  /// Summary group of records with no condition recorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get pdfNoCondition;

  /// Summary status group: not processed yet.
  ///
  /// In en, this message translates to:
  /// **'Unprocessed'**
  String get pdfUnprocessed;

  /// Summary status group: waiting for review.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get pdfNeedsReview;

  /// Summary status group: approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get pdfApproved;

  /// Report title: as-recorded against as-found.
  ///
  /// In en, this message translates to:
  /// **'Variance report'**
  String get pdfVarianceReport;

  /// Variance section: register items found.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get pdfMatched;

  /// Variance section: found items the register does not list.
  ///
  /// In en, this message translates to:
  /// **'Not in register'**
  String get pdfNotInRegister;

  /// Report title: meeting minutes.
  ///
  /// In en, this message translates to:
  /// **'Meeting minutes'**
  String get pdfMinutesReport;

  /// Report title: the transcripts heard on the device from the exported records' audio.
  ///
  /// In en, this message translates to:
  /// **'Transcripts'**
  String get pdfTranscriptReport;

  /// Heading of a transcript's raw text, exactly as the device heard it.
  ///
  /// In en, this message translates to:
  /// **'{title} (as heard)'**
  String pdfTranscriptHeard(Object title);

  /// Heading of the operator's edit of a transcript, printed beside the raw text and never as recorded speech.
  ///
  /// In en, this message translates to:
  /// **'{title} (edited)'**
  String pdfTranscriptEdited(Object title);

  /// Label of an action's due date.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get pdfDue;

  /// An action's status as the register prints it.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get pdfActionStatus;

  /// An action's status as the register prints it.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get pdfActionStatusDone;

  /// An action's status as the register prints it.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get pdfActionStatusOpen;

  /// A matched register item whose field was found different.
  ///
  /// In en, this message translates to:
  /// **'{field}: {recorded} recorded, {found} found'**
  String pdfVarianceChanged(Object field, Object recorded, Object found);

  /// A matched register item whose field was found empty.
  ///
  /// In en, this message translates to:
  /// **'{field}: {recorded} recorded, not found'**
  String pdfVarianceEmpty(Object field, Object recorded);

  /// Heading of the minutes' photo appendix.
  ///
  /// In en, this message translates to:
  /// **'Photo appendix'**
  String get pdfPhotoAppendix;

  /// Points from the discussion to the photo appendix.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{See 1 photo in the photo appendix.} other{See {count} photos in the photo appendix.}}'**
  String pdfPhotoReference(int count);

  /// Cover fact: when the export was made.
  ///
  /// In en, this message translates to:
  /// **'Exported {when}'**
  String pdfExportedAt(Object when);

  /// Cover fact: who made the export.
  ///
  /// In en, this message translates to:
  /// **'Exported by {operator}'**
  String pdfExportedBy(Object operator);

  /// Cover fact: which records the export selected.
  ///
  /// In en, this message translates to:
  /// **'Records: {scope}'**
  String pdfScope(Object scope);

  /// Types a replacement for a conflict.
  ///
  /// In en, this message translates to:
  /// **'Type a value'**
  String get conflictTypeValue;

  /// Leaves a conflict unsettled.
  ///
  /// In en, this message translates to:
  /// **'Decide later'**
  String get conflictDecideLater;

  /// Caption replacement label in the conflict editor.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get conflictCaptionLabel;

  /// Replacement value chosen by the operator.
  ///
  /// In en, this message translates to:
  /// **'Use the entered value'**
  String get mergeConflictTyped;

  /// Bundle scope section title.
  ///    Password input for an encrypted project package.
  ///
  /// In en, this message translates to:
  /// **'Bundle password'**
  String get bundlePassword;

  /// Empty protected bundle password.
  ///
  /// In en, this message translates to:
  /// **'Enter the bundle password.'**
  String get bundlePasswordRequired;

  /// Optional password protection for the current package only.
  ///
  /// In en, this message translates to:
  /// **'Set a bundle password (optional)'**
  String get bundlePasswordOptional;

  /// Indicates protection without displaying the password.
  ///
  /// In en, this message translates to:
  /// **'Bundle password set'**
  String get bundlePasswordSet;

  /// Bundle inclusion scope section.
  ///
  /// In en, this message translates to:
  /// **'What to include'**
  String get bundleScope;

  /// The whole project.
  ///
  /// In en, this message translates to:
  /// **'Full project'**
  String get bundleScopeFull;

  /// A date range of records.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get bundleScopeDates;

  /// The current context subtree.
  ///
  /// In en, this message translates to:
  /// **'Current context'**
  String get bundleScopeContext;

  /// Approved records only.
  ///
  /// In en, this message translates to:
  /// **'Approved only'**
  String get bundleScopeApproved;

  /// Records without their photos.
  ///
  /// In en, this message translates to:
  /// **'Data without photos'**
  String get bundleScopeData;

  /// Estimated bundle size.
  ///
  /// In en, this message translates to:
  /// **'About {label}'**
  String bundleSize(Object label);

  /// Shares the bundle file.
  ///
  /// In en, this message translates to:
  /// **'Share bundle'**
  String get bundleShare;

  /// Opens a bundle that arrived from outside the app.
  ///
  /// In en, this message translates to:
  /// **'Open bundle'**
  String get bundleOpen;

  /// Merge history title.
  ///
  /// In en, this message translates to:
  /// **'Merge history'**
  String get mergeHistoryTitle;

  /// Empty merge history.
  ///
  /// In en, this message translates to:
  /// **'No merges yet'**
  String get mergeHistoryEmpty;

  /// Empty merge history explanation.
  ///
  /// In en, this message translates to:
  /// **'A merge is kept here with its source, counts and how long undo lasts.'**
  String get mergeHistoryEmptyMessage;

  /// Undo is still available.
  ///
  /// In en, this message translates to:
  /// **'Undo until {when}'**
  String mergeUndoUntil(Object when);

  /// Package identity, import time and outcome in the history list.
  ///
  /// In en, this message translates to:
  /// **'{name} · {id} · {dateFormatyMMMdadd} · {switchstatusapplied}'**
  String mergeHistoryFacts(
    Object name,
    Object id,
    Object dateFormatyMMMdadd,
    Object switchstatusapplied,
  );

  /// Count of one durable merge category.
  ///
  /// In en, this message translates to:
  /// **'{switchkeyrecords}: {n}'**
  String mergeHistoryCount(Object switchkeyrecords, int n);

  /// Count of one operator resolution.
  ///
  /// In en, this message translates to:
  /// **'{switchchoicemine}: {n}'**
  String mergeHistoryResolution(Object switchchoicemine, int n);

  /// Undo refuses to discard edits made after a merge.
  ///
  /// In en, this message translates to:
  /// **'This merge has later changes.'**
  String get mergeUndoChanged;

  /// Recovery offered when newer work prevents restoring an old snapshot.
  ///
  /// In en, this message translates to:
  /// **'Keep the later changes, or undo the newer merge first.'**
  String get mergeUndoChangedRecovery;

  /// Missing, expired or previously undone snapshot.
  ///
  /// In en, this message translates to:
  /// **'This merge can no longer be undone.'**
  String get mergeUndoUnavailable;

  /// Confirmation after the durable restore commits.
  ///
  /// In en, this message translates to:
  /// **'Merge undone'**
  String get mergeUndoDone;

  /// Explains exactly what undo restores and retains.
  ///
  /// In en, this message translates to:
  /// **'Restore the values from before this merge. Incoming evidence stays in the recycle area.'**
  String get mergeUndoConfirm;

  /// Import page title.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importTitle;

  /// Empty import headline.
  ///
  /// In en, this message translates to:
  /// **'No file yet'**
  String get importEmptyHeadline;

  /// Empty import explanation.
  ///
  /// In en, this message translates to:
  /// **'Choose a bundle, a spreadsheet, a dataset or a template. Tapture checks it and opens the step that fits.'**
  String get importEmptyMessage;

  /// The import page's one action: pick a file.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get importChooseFile;

  /// Shown while a chosen file is checked or read.
  ///
  /// In en, this message translates to:
  /// **'Checking the file…'**
  String get importCheckingFile;

  /// Heading over the four kinds of file the import page takes.
  ///
  /// In en, this message translates to:
  /// **'What each file opens'**
  String get importKindsTitle;

  /// A bundle, on the import page.
  ///
  /// In en, this message translates to:
  /// **'Bundle (.zip)'**
  String get importKindBundle;

  /// Where a bundle goes.
  ///
  /// In en, this message translates to:
  /// **'Checked, then added as a project or merged into one.'**
  String get importBundleLine;

  /// A reference dataset, on the import page.
  ///
  /// In en, this message translates to:
  /// **'Reference dataset (.json)'**
  String get importKindDataset;

  /// Where a dataset goes.
  ///
  /// In en, this message translates to:
  /// **'A table of reference rows opens the dataset importer.'**
  String get importDatasetLine;

  /// A template, on the import page.
  ///
  /// In en, this message translates to:
  /// **'Template (.json)'**
  String get importKindTemplate;

  /// Where a template goes.
  ///
  /// In en, this message translates to:
  /// **'A template file is checked, then added to the open project.'**
  String get importTemplateLine;

  /// A spreadsheet, on the import page.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet (.xlsx or .csv)'**
  String get importKindSheet;

  /// Where a row spreadsheet goes.
  ///
  /// In en, this message translates to:
  /// **'Asks whether its rows are records or a register to check against.'**
  String get importSheetLine;

  /// A file the import page does not take.
  ///
  /// In en, this message translates to:
  /// **'Tapture cannot import this kind of file.'**
  String get importUnsupported;

  /// Every kind except a bundle is added to the open project.
  ///
  /// In en, this message translates to:
  /// **'Open a project first. A spreadsheet, dataset or template is added to the open project.'**
  String get importNeedsProject;

  /// Recovery for [importNeedsProject].
  ///
  /// In en, this message translates to:
  /// **'Open the project from the list, then import the file again.'**
  String get importNeedsProjectRecovery;

  /// Purpose page title.
  ///
  /// In en, this message translates to:
  /// **'What is this sheet?'**
  String get importPurposeTitle;

  /// Rows become records.
  ///
  /// In en, this message translates to:
  /// **'Records to hold'**
  String get importPurposeRecords;

  /// What choosing [importPurposeRecords] does.
  ///
  /// In en, this message translates to:
  /// **'Each row becomes a record on one of this project’s templates.'**
  String get importPurposeRecordsLine;

  /// Rows feed verification.
  ///
  /// In en, this message translates to:
  /// **'Register to verify against'**
  String get importPurposeRegister;

  /// What choosing [importPurposeRegister] does.
  ///
  /// In en, this message translates to:
  /// **'The rows become a reference dataset that verification checks what you find against. No records are made.'**
  String get importPurposeRegisterLine;

  /// Mapping and summary pages with no sheet chosen.
  ///
  /// In en, this message translates to:
  /// **'No sheet chosen'**
  String get importNoSheetHeadline;

  /// Explains [importNoSheetHeadline].
  ///
  /// In en, this message translates to:
  /// **'Choose a spreadsheet on the import page first.'**
  String get importNoSheetMessage;

  /// Mapping page title.
  ///
  /// In en, this message translates to:
  /// **'Match columns'**
  String get importMappingTitle;

  /// Label of the template the rows are matched onto.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get importMappingTemplate;

  /// Heading over the column-to-field choices.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get importMappingColumns;

  /// A header with no field yet.
  ///
  /// In en, this message translates to:
  /// **'Not matched'**
  String get importUnmapped;

  /// A project with no template to match the sheet onto.
  ///
  /// In en, this message translates to:
  /// **'No template to match'**
  String get importNoTemplateHeadline;

  /// Explains [importNoTemplateHeadline].
  ///
  /// In en, this message translates to:
  /// **'This project has no template yet. Make one from this sheet’s columns, then import its rows.'**
  String get importNoTemplateMessage;

  /// Opens template mapping for the chosen sheet.
  ///
  /// In en, this message translates to:
  /// **'Make a template from this sheet'**
  String get importMakeTemplate;

  /// Heading over the first rows, as they will be read.
  ///
  /// In en, this message translates to:
  /// **'First rows, as they will be read'**
  String get importPreviewTitle;

  /// One spreadsheet row, by its number in the file.
  ///
  /// In en, this message translates to:
  /// **'Row {row}'**
  String importRow(int row);

  /// The mapping page's one action.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Import 1 row} other{Import {count} rows}}'**
  String importRun(int count);

  /// Names the identity field that is still unmapped.
  ///
  /// In en, this message translates to:
  /// **'{field} is an identity field and still needs a column.'**
  String importIdentityMissing(Object field);

  /// Shown while the rows are written.
  ///
  /// In en, this message translates to:
  /// **'Importing the rows'**
  String get importWriting;

  /// How far the import has got.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} rows'**
  String importProgress(int done, int total);

  /// Why a row that matches a record was left alone.
  ///
  /// In en, this message translates to:
  /// **'Kept the record already here.'**
  String get importKeptExisting;

  /// Why a matching row was skipped with no choice made.
  ///
  /// In en, this message translates to:
  /// **'Matches a record already here, and no choice was made.'**
  String get importMatchUnsettled;

  /// Why a row that repeats an earlier row's identity was not written.
  ///
  /// In en, this message translates to:
  /// **'Repeats the identity of row {row} in this file.'**
  String importRepeatsRow(int row);

  /// Every row was written.
  ///
  /// In en, this message translates to:
  /// **'Every row was imported.'**
  String get importAllDone;

  /// Opens the project's records after an import.
  ///
  /// In en, this message translates to:
  /// **'Open records'**
  String get importOpenRecords;

  /// File name of the rows to correct and import again.
  ///
  /// In en, this message translates to:
  /// **'rows-to-fix.csv'**
  String get importFixFileName;

  /// Column of the rows-to-fix file naming each row's number in the sheet.
  ///
  /// In en, this message translates to:
  /// **'Row in sheet'**
  String get importFixRowColumn;

  /// Column of the rows-to-fix file saying why each row was not written.
  ///
  /// In en, this message translates to:
  /// **'Why it was not imported'**
  String get importFixReasonColumn;

  /// Announced once the rows to fix are saved.
  ///
  /// In en, this message translates to:
  /// **'Rows to fix saved.'**
  String get importFixSaved;

  /// Summary page title.
  ///
  /// In en, this message translates to:
  /// **'Import summary'**
  String get importSummaryTitle;

  /// How many rows were created.
  ///
  /// In en, this message translates to:
  /// **'{count} created'**
  String importCreated(int count);

  /// How many rows updated a record.
  ///
  /// In en, this message translates to:
  /// **'{count} updated'**
  String importUpdated(int count);

  /// How many rows were skipped.
  ///
  /// In en, this message translates to:
  /// **'{count} skipped'**
  String importSkipped(int count);

  /// How many rows failed.
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String importFailed(int count);

  /// Re-runs only the failed rows.
  ///
  /// In en, this message translates to:
  /// **'Retry failures'**
  String get importRetry;

  /// Writes the skipped and failed rows.
  ///
  /// In en, this message translates to:
  /// **'Export rows to fix'**
  String get importExportProblems;

  /// Match sheet title.
  ///
  /// In en, this message translates to:
  /// **'This row matches a record'**
  String get importMatchTitle;

  /// Says which row matched.
  ///
  /// In en, this message translates to:
  /// **'Row {row} has the same identity as a record already in this project.'**
  String importMatchMessage(int row);

  /// Label of the choice on the match sheet.
  ///
  /// In en, this message translates to:
  /// **'What to do with it'**
  String get importMatchChoice;

  /// Leave the existing record unchanged.
  ///
  /// In en, this message translates to:
  /// **'Keep existing'**
  String get importKeepExisting;

  /// Replace the existing record with the row.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get importReplace;

  /// Fill only empty fields from the row.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get importMerge;

  /// Applies the choice to every later match.
  ///
  /// In en, this message translates to:
  /// **'Use this choice for every later match'**
  String get importApplyToAll;

  /// Confirms the match sheet.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get importMatchConfirm;

  /// Settings row for cloud destinations.
  ///
  /// In en, this message translates to:
  /// **'Upload destinations'**
  String get cloudDestinationsTitle;

  /// Settings row explanation.
  ///
  /// In en, this message translates to:
  /// **'Where a finished file can be sent, when you confirm it.'**
  String get cloudDestinationsSubtitle;

  /// Destinations page title.
  ///
  /// In en, this message translates to:
  /// **'Upload destinations'**
  String get destinationTitle;

  /// Empty destinations headline.
  ///
  /// In en, this message translates to:
  /// **'No destinations yet'**
  String get destinationEmptyHeadline;

  /// Empty destinations explanation.
  ///
  /// In en, this message translates to:
  /// **'Add a bucket, a folder or a drive you sign in to. Nothing is sent until you confirm it.'**
  String get destinationEmptyMessage;

  /// Starts adding a destination.
  ///
  /// In en, this message translates to:
  /// **'Add a destination'**
  String get destinationAdd;

  /// Saves a destination after its test succeeds.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get destinationSave;

  /// Runs the probe upload.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get destinationTest;

  /// Removes a destination.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get destinationRemove;

  /// Removal confirm title.
  ///
  /// In en, this message translates to:
  /// **'Remove this destination?'**
  String get destinationRemoveTitle;

  /// Removal confirm explanation.
  ///
  /// In en, this message translates to:
  /// **'The destination and its saved sign-in are both deleted.'**
  String get destinationRemoveMessage;

  /// Shown when the probe upload fails, so save stays disabled.
  ///
  /// In en, this message translates to:
  /// **'The connection test did not succeed, so this destination was not saved.'**
  String get destinationCheckFailed;

  /// Label field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get destinationLabel;

  /// Folder field.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get destinationFolder;

  /// Obscured credential field.
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get destinationSecret;

  /// S3 kind label.
  ///
  /// In en, this message translates to:
  /// **'S3 bucket'**
  String get destinationKindS3;

  /// Google Drive kind label.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get destinationKindDrive;

  /// OneDrive kind label.
  ///
  /// In en, this message translates to:
  /// **'OneDrive'**
  String get destinationKindOneDrive;

  /// Dropbox kind label.
  ///
  /// In en, this message translates to:
  /// **'Dropbox'**
  String get destinationKindDropbox;

  /// WebDAV kind label.
  ///
  /// In en, this message translates to:
  /// **'WebDAV'**
  String get destinationKindWebDav;

  /// Device folder kind label.
  ///
  /// In en, this message translates to:
  /// **'Folder on this device'**
  String get destinationKindLocal;

  /// Title of the sheet that changes a saved destination.
  ///
  /// In en, this message translates to:
  /// **'Edit destination'**
  String get destinationEdit;

  /// Row action that opens the destination for editing.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get destinationEditAction;

  /// Label of the destination type choice.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get destinationKind;

  /// Submit on the destination form: the probe runs, then the save.
  ///
  /// In en, this message translates to:
  /// **'Check and save'**
  String get destinationCheckAndSave;

  /// Folder field for an S3 destination: the key prefix.
  ///
  /// In en, this message translates to:
  /// **'Folder in the bucket'**
  String get destinationBucketFolder;

  /// Hint on a field that may stay empty.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get destinationOptional;

  /// Hint on the device folder field.
  ///
  /// In en, this message translates to:
  /// **'A folder inside the Tapture folder, or choose one'**
  String get destinationLocalFolderHint;

  /// Opens the platform folder picker for a device or card folder.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get destinationChooseFolder;

  /// S3 access key field.
  ///
  /// In en, this message translates to:
  /// **'Access key'**
  String get destinationAccessKey;

  /// S3 secret key field. Obscured.
  ///
  /// In en, this message translates to:
  /// **'Secret key'**
  String get destinationSecretKey;

  /// S3 region field.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get destinationRegion;

  /// S3 bucket field.
  ///
  /// In en, this message translates to:
  /// **'Bucket'**
  String get destinationBucket;

  /// S3-compatible endpoint field.
  ///
  /// In en, this message translates to:
  /// **'Endpoint'**
  String get destinationEndpoint;

  /// Hint on the endpoint field.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for Amazon S3'**
  String get destinationEndpointHint;

  /// WebDAV server address field.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get destinationAddress;

  /// Hint on the WebDAV address field.
  ///
  /// In en, this message translates to:
  /// **'https://files.example.org/dav/'**
  String get destinationAddressHint;

  /// Label of the WebDAV sign-in method choice.
  ///
  /// In en, this message translates to:
  /// **'Sign-in method'**
  String get destinationSignInMethod;

  /// Basic authentication.
  ///
  /// In en, this message translates to:
  /// **'Name and password'**
  String get destinationSignInPassword;

  /// Bearer authentication.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get destinationSignInToken;

  /// WebDAV user name field.
  ///
  /// In en, this message translates to:
  /// **'User name'**
  String get destinationUsername;

  /// WebDAV password field. Obscured.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get destinationPassword;

  /// WebDAV token field. Obscured.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get destinationToken;

  /// Explains that an edit keeps the stored sign-in unless replaced.
  ///
  /// In en, this message translates to:
  /// **'Leave the sign-in fields empty to keep the saved sign-in.'**
  String get destinationKeepSignIn;

  /// Asks for a new provider sign-in when a saved one was revoked.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get destinationSignInAgain;

  /// Says a provider destination signs in when it is saved.
  ///
  /// In en, this message translates to:
  /// **'You sign in to {provider} when you save. Tapture can reach only the files it creates there.'**
  String destinationSignInNote(Object provider);

  /// No browser sign-in is available for this provider.
  ///
  /// In en, this message translates to:
  /// **'Signing in to this provider is not available on this device.'**
  String get destinationSignInUnavailable;

  /// The sign-in that came back was not the one this form started.
  ///
  /// In en, this message translates to:
  /// **'The sign-in did not finish. Try saving again.'**
  String get destinationSignInMismatch;

  /// Shown instead of an empty remote folder.
  ///
  /// In en, this message translates to:
  /// **'the top folder'**
  String get destinationFolderRoot;

  /// The first half of a removal failed: nothing was removed.
  ///
  /// In en, this message translates to:
  /// **'The destination and its sign-in are both still saved.'**
  String get destinationRemoveNothing;

  /// The second half of a removal failed.
  ///
  /// In en, this message translates to:
  /// **'The sign-in was removed, but the destination is still listed.'**
  String get destinationRemoveHalf;

  /// Recovery for a failed removal.
  ///
  /// In en, this message translates to:
  /// **'Try removing it again.'**
  String get destinationRemoveAgain;

  /// An undone removal could not list the destination again.
  ///
  /// In en, this message translates to:
  /// **'The destination could not be put back.'**
  String get destinationRestoreFailed;

  /// Recovery for a failed restore.
  ///
  /// In en, this message translates to:
  /// **'Add it again.'**
  String get destinationAddAgain;

  /// A cancelled removal.
  ///
  /// In en, this message translates to:
  /// **'The destination was kept.'**
  String get destinationKept;

  /// Recovery for a cancelled removal.
  ///
  /// In en, this message translates to:
  /// **'Remove it later if you still want to.'**
  String get destinationKeptRecovery;

  /// Snack after a removal, offered with undo.
  ///
  /// In en, this message translates to:
  /// **'{label} was removed.'**
  String destinationRemoved(Object label);

  /// Snack after an undone removal.
  ///
  /// In en, this message translates to:
  /// **'{label} is back.'**
  String destinationRestored(Object label);

  /// Snack after a save.
  ///
  /// In en, this message translates to:
  /// **'{label} was saved.'**
  String destinationSaved(Object label);

  /// Snack after a passed connection check.
  ///
  /// In en, this message translates to:
  /// **'The connection to {label} works.'**
  String destinationCheckPassed(Object label);

  /// Row line for the last passed check.
  ///
  /// In en, this message translates to:
  /// **'Checked {dateFormatyMMMdformat}'**
  String destinationCheckedAt(Object dateFormatyMMMdformat);

  /// Row line for the last failed check.
  ///
  /// In en, this message translates to:
  /// **'Check failed: {reason}'**
  String destinationCheckFailedAt(Object reason);

  /// Row line while a check runs.
  ///
  /// In en, this message translates to:
  /// **'Checking the connection…'**
  String get destinationChecking;

  /// Headline when this device can hold no destination.
  ///
  /// In en, this message translates to:
  /// **'Uploads are sent from a device'**
  String get destinationUnavailableHeadline;

  /// Message when this device can hold no destination.
  ///
  /// In en, this message translates to:
  /// **'Open Tapture on a phone or computer to add a destination.'**
  String get destinationUnavailableMessage;

  /// Confirm sheet title.
  ///
  /// In en, this message translates to:
  /// **'Send this file?'**
  String get uploadConfirmTitle;

  /// Confirm button.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get uploadConfirm;

  /// Names the file, its size, the destination and the folder.
  ///
  /// In en, this message translates to:
  /// **'{name} ({size}) will be sent to {destination}, in {folder}.'**
  String uploadConfirmMessage(
    Object name,
    Object size,
    Object destination,
    Object folder,
  );

  /// History page title.
  ///
  /// In en, this message translates to:
  /// **'Uploads'**
  String get uploadHistoryTitle;

  /// Empty history headline.
  ///
  /// In en, this message translates to:
  /// **'No uploads yet'**
  String get uploadHistoryEmptyHeadline;

  /// Empty history explanation.
  ///
  /// In en, this message translates to:
  /// **'A file appears here after you confirm sending it.'**
  String get uploadHistoryEmptyMessage;

  /// Retries one failed or interrupted upload.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get uploadRetry;

  /// History filter label.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get uploadFilter;

  /// The history filter option that lists every destination.
  ///
  /// In en, this message translates to:
  /// **'All destinations'**
  String get uploadFilterAll;

  /// Empty history action: set up where files can go.
  ///
  /// In en, this message translates to:
  /// **'Set up a destination'**
  String get uploadHistoryEmptyAction;

  /// Sends a finished file to a destination the person picks.
  ///
  /// In en, this message translates to:
  /// **'Upload to a destination'**
  String get uploadToDestination;

  /// Title of the sheet that picks the destination.
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get uploadPickTitle;

  /// Snack when a confirmed upload starts.
  ///
  /// In en, this message translates to:
  /// **'Sending to {destination}. Follow it under Uploads.'**
  String uploadStarted(Object destination);

  /// Opens the upload history from a snack.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get uploadView;

  /// Snack when an upload finished.
  ///
  /// In en, this message translates to:
  /// **'{name} was sent to {destination}.'**
  String uploadSent(Object name, Object destination);

  /// Snack when an upload ended without the file arriving.
  ///
  /// In en, this message translates to:
  /// **'Not sent. {reason}'**
  String uploadNotSent(Object reason);

  /// Snack when the person stopped an upload.
  ///
  /// In en, this message translates to:
  /// **'The upload was stopped. The file on this device is unchanged.'**
  String get uploadStopped;

  /// The file to send is gone or changed size.
  ///
  /// In en, this message translates to:
  /// **'The file is no longer on this device as it was exported.'**
  String get uploadFileMissing;

  /// Recovery for a missing file.
  ///
  /// In en, this message translates to:
  /// **'Export it again, then send it.'**
  String get uploadFileMissingRecovery;

  /// The destination of a retried upload was removed.
  ///
  /// In en, this message translates to:
  /// **'That destination was removed.'**
  String get uploadDestinationGone;

  /// Recovery for a removed destination.
  ///
  /// In en, this message translates to:
  /// **'Send the file again from its export.'**
  String get uploadDestinationGoneRecovery;

  /// Outcome: the file arrived.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get uploadOutcomeSent;

  /// Outcome: the upload failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get uploadOutcomeFailed;

  /// Outcome: the upload never finished, for example the app closed.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get uploadOutcomeInterrupted;

  /// Outcome: the person stopped it.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get uploadOutcomeStopped;

  /// One history row: outcome, destination, size and start time.
  ///
  /// In en, this message translates to:
  /// **'{outcome} · {destination} · {size} · {when}'**
  String uploadAttemptLine(
    Object outcome,
    Object destination,
    Object size,
    Object when,
  );

  /// A row while its upload runs.
  ///
  /// In en, this message translates to:
  /// **'Sending to {destination} · {percent}%'**
  String uploadSendingLine(Object destination, int percent);

  /// Row action that stops a running upload.
  ///
  /// In en, this message translates to:
  /// **'Stop upload'**
  String get uploadStop;

  /// Row action that shows every field of an attempt.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get uploadDetails;

  /// Every field of one attempt, for the details dialog.
  ///
  /// In en, this message translates to:
  /// **'\nReason: {reason}'**
  String uploadDetailsMessage(Object reason);

  /// Every field of one attempt, for the details dialog.
  ///
  /// In en, this message translates to:
  /// **'File: {file}\nDestination: {destination}\nFolder: {folder}\nSize: {size}\nStarted: {whenstartedAt}\nEnded: {ended}\nOutcome: {outcome}{because}'**
  String uploadDetailsMessageFileDestinationFolderSize(
    Object file,
    Object destination,
    Object folder,
    Object size,
    Object whenstartedAt,
    Object ended,
    Object outcome,
    Object because,
  );

  /// Privacy screen title.
  ///
  /// In en, this message translates to:
  /// **'What leaves this device'**
  String get privacyScreenTitle;

  /// Empty privacy headline.
  ///
  /// In en, this message translates to:
  /// **'Nothing is set up to send'**
  String get privacyEmptyHeadline;

  /// Empty privacy explanation.
  ///
  /// In en, this message translates to:
  /// **'Analysis providers and upload destinations appear here when they are added.'**
  String get privacyEmptyMessage;

  /// Section of the privacy page listing analysis calls.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get egressAnalysisSection;

  /// Section of the privacy page listing uploads and the relay.
  ///
  /// In en, this message translates to:
  /// **'Uploads'**
  String get egressUploadsSection;

  /// Notice while offline mode stops every outbound call.
  ///
  /// In en, this message translates to:
  /// **'Offline mode is on, so nothing leaves this device.'**
  String get egressOfflineNotice;

  /// Analysis row: reading text from photos.
  ///
  /// In en, this message translates to:
  /// **'Reading text from photos'**
  String get egressReadText;

  /// Analysis row: filling a record's fields.
  ///
  /// In en, this message translates to:
  /// **'Filling fields from a record'**
  String get egressExtractFields;

  /// Analysis row: tidying captions.
  ///
  /// In en, this message translates to:
  /// **'Tidying captions'**
  String get egressRefineText;

  /// Analysis row: speech to text.
  ///
  /// In en, this message translates to:
  /// **'Turning speech into text'**
  String get egressTranscribe;

  /// What one outbound path sends, and where it goes.
  ///
  /// In en, this message translates to:
  /// **'{sends} · to {destination}'**
  String egressRow(Object sends, Object destination);

  /// What an extraction call sends.
  ///
  /// In en, this message translates to:
  /// **'Text only'**
  String get egressSendsText;

  /// What an image call sends.
  ///
  /// In en, this message translates to:
  /// **'An image'**
  String get egressSendsImage;

  /// What speech sends.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get egressSendsAudio;

  /// What a cloud upload sends.
  ///
  /// In en, this message translates to:
  /// **'A file'**
  String get egressSendsFile;

  /// What the relay sends.
  ///
  /// In en, this message translates to:
  /// **'Encrypted project packages'**
  String get egressSendsPackage;

  /// Relay row title.
  ///
  /// In en, this message translates to:
  /// **'Relay for this project'**
  String get egressRelay;

  /// Where the relay sends.
  ///
  /// In en, this message translates to:
  /// **'the organisation server'**
  String get egressRelayServer;

  /// Basis written when images stay on the device.
  ///
  /// In en, this message translates to:
  /// **'Text only, on-device OCR'**
  String get egressTextOnly;

  /// Location section title.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get gpsPrivacyTitle;

  /// GPS stays off until this is on.
  ///
  /// In en, this message translates to:
  /// **'Save location with captures'**
  String get gpsPrivacyCapture;

  /// Where location capture is switched, and its state.
  ///
  /// In en, this message translates to:
  /// **'On. Change it in capture settings.'**
  String get gpsPrivacyCaptureState;

  /// Where location capture is switched, and its state.
  ///
  /// In en, this message translates to:
  /// **'Off. Change it in capture settings.'**
  String get gpsPrivacyCaptureStateOffChangeItIn;

  /// Drops coordinates from exports.
  ///
  /// In en, this message translates to:
  /// **'Leave coordinates out of exports'**
  String get gpsPrivacyExclude;

  /// What leaving coordinates out covers.
  ///
  /// In en, this message translates to:
  /// **'Exports carry no location fields and no location in photo details.'**
  String get gpsPrivacyExcludeEffect;

  /// Removes coordinates already stored.
  ///
  /// In en, this message translates to:
  /// **'Remove saved coordinates'**
  String get gpsPrivacyRemove;

  /// Confirms removing the open project's coordinates.
  ///
  /// In en, this message translates to:
  /// **'Remove saved coordinates?'**
  String get gpsPrivacyRemoveTitle;

  /// What removing coordinates does.
  ///
  /// In en, this message translates to:
  /// **'Every record and photo in {project} loses its saved location. The history records who removed them and when.'**
  String gpsPrivacyRemoveMessage(Object project);

  /// Confirm button for removing coordinates.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get gpsPrivacyRemoveConfirm;

  /// How many records lost their coordinates.
  ///
  /// In en, this message translates to:
  /// **'{recordsCountcount} changed. No saved coordinates remain.'**
  String gpsPrivacyRemoved(Object recordsCountcount);

  /// Why the removal is not offered.
  ///
  /// In en, this message translates to:
  /// **'Open a project to remove its saved coordinates.'**
  String get gpsPrivacyNoProject;

  /// Blurs faces in exported photos.
  ///
  /// In en, this message translates to:
  /// **'Blur faces in exported photos'**
  String get faceBlurTitle;

  /// What face blurring does, and what happens when it cannot.
  ///
  /// In en, this message translates to:
  /// **'A photo whose faces cannot be checked on this device stays out of the export.'**
  String get faceBlurEffect;

  /// Redaction editor title and its entry point.
  ///
  /// In en, this message translates to:
  /// **'Hide parts before sending'**
  String get redactionTitle;

  /// Records held back because no confirmed consent was captured.
  ///
  /// In en, this message translates to:
  /// **'Omitted without consent: {idsjoin}'**
  String exportConsentOmitted(Object idsjoin);

  /// A saved artifact must be regenerated under the current protections.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings changed. Export a new file before sharing.'**
  String get exportPrivacyChanged;

  /// How to mark a region.
  ///
  /// In en, this message translates to:
  /// **'Drag across anything that must not be sent. The photo itself does not change.'**
  String get redactionHint;

  /// Saves the marked regions.
  ///
  /// In en, this message translates to:
  /// **'Save hidden areas'**
  String get redactionSave;

  /// How many regions are hidden.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing hidden yet} one{1 area hidden} other{{count} areas hidden}}'**
  String redactionCount(int count);

  /// After saving the marks.
  ///
  /// In en, this message translates to:
  /// **'Saved. These areas are covered in every copy sent for analysis.'**
  String get redactionSaved;

  /// Empty redaction editor headline.
  ///
  /// In en, this message translates to:
  /// **'No photo to mark'**
  String get redactionEmptyHeadline;

  /// Empty redaction editor explanation.
  ///
  /// In en, this message translates to:
  /// **'Open a photo from a record, then mark what to hide.'**
  String get redactionEmptyMessage;

  /// Location permission sentence.
  ///
  /// In en, this message translates to:
  /// **'Tapture saves a location only when you turn location on for a project.'**
  String get permissionLocation;

  /// Storage permission sentence.
  ///
  /// In en, this message translates to:
  /// **'Tapture opens photos and files you choose to import.'**
  String get permissionStorage;

  /// Notification permission sentence.
  ///
  /// In en, this message translates to:
  /// **'Tapture tells you when a batch of analysis finishes.'**
  String get permissionNotifications;

  /// Settings row for privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// Settings row explanation.
  ///
  /// In en, this message translates to:
  /// **'What can leave this device, and what never does.'**
  String get privacySubtitle;

  /// Settings row for the organisation server.
  ///
  /// In en, this message translates to:
  /// **'Organisation'**
  String get backendSettingsTitle;

  /// Relay empty state when no project is open.
  ///
  /// In en, this message translates to:
  /// **'Open a project to exchange changes with its other devices.'**
  String get relayChooseProject;

  /// Relay switch title.
  ///
  /// In en, this message translates to:
  /// **'Enable relay'**
  String get relayEnable;

  /// Relay switch explanation.
  ///
  /// In en, this message translates to:
  /// **'Encrypted packages pass through the organisation server temporarily.'**
  String get relayEnableHelp;

  /// Relay shared-key field label.
  ///
  /// In en, this message translates to:
  /// **'Shared project key'**
  String get relaySharedKey;

  /// Relay shared-key guidance.
  ///
  /// In en, this message translates to:
  /// **'Use the same key of at least 16 characters on each device. Exchange it separately; it never goes to the server.'**
  String get relayKeyHelp;

  /// Relay action that queues the whole project as one package.
  ///
  /// In en, this message translates to:
  /// **'Queue project package'**
  String get relayQueueProject;

  /// Relay action that sends queued and fetches incoming packages.
  ///
  /// In en, this message translates to:
  /// **'Sync relay'**
  String get relaySync;

  /// Relay row that previews a received package before merge.
  ///
  /// In en, this message translates to:
  /// **'Preview received changes'**
  String get relayReceivedPackage;

  /// Optional catalogue ranking, always presented as a person's choice.
  ///
  /// In en, this message translates to:
  /// **'Suggest with AI'**
  String get shippedSuggestWithAi;

  /// Badge on a template the AI ranking suggested.
  ///
  /// In en, this message translates to:
  /// **'AI suggestion'**
  String get shippedAiSuggestion;

  /// Explanation under the AI ranking.
  ///
  /// In en, this message translates to:
  /// **'Suggested order only. Preview and choose the templates you want.'**
  String get shippedAiSuggestionHelp;

  /// Deployment-specific address is needed only for self-hosted installations.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get backendServerAddress;

  /// Guidance under the server address and organisation fields.
  ///
  /// In en, this message translates to:
  /// **'Use the HTTPS address supplied by your administrator. Leave Organisation empty when this server hosts one organisation.'**
  String get backendConfigurationHelp;

  /// Session state when this device has no backend session.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get backendNotSignedIn;

  /// Session state when this device holds a backend session.
  ///
  /// In en, this message translates to:
  /// **'Signed in on this device'**
  String get backendSignedIn;

  /// Label for the cached access grant's expiry.
  ///
  /// In en, this message translates to:
  /// **'Cached access until'**
  String get backendGrantUntil;

  /// Settings row: the role the organisation gave this account.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get backendRole;

  /// A server role as the settings row shows it; an unknown one as sent.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get backendRoleName;

  /// A server role as the settings row shows it; an unknown one as sent.
  ///
  /// In en, this message translates to:
  /// **'Project manager'**
  String get backendRoleNameProjectManager;

  /// A server role as the settings row shows it; an unknown one as sent.
  ///
  /// In en, this message translates to:
  /// **'Reviewer'**
  String get backendRoleNameReviewer;

  /// A server role as the settings row shows it; an unknown one as sent.
  ///
  /// In en, this message translates to:
  /// **'Field operator'**
  String get backendRoleNameFieldOperator;

  /// Settings row: how far this device's enrolment has gone.
  ///
  /// In en, this message translates to:
  /// **'Enrolment'**
  String get backendEnrolment;

  /// Enrolment value before the first sign-in.
  ///
  /// In en, this message translates to:
  /// **'Not enrolled'**
  String get backendNotEnrolled;

  /// Enrolment value while a sign-in is in flight.
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get backendEnrolling;

  /// Enrolment value once a grant is cached.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get backendEnrolled;

  /// Enrolment value after the organisation ended the grant.
  ///
  /// In en, this message translates to:
  /// **'Ended by the organisation'**
  String get backendRevokedState;

  /// Banner when the organisation ended this device's sign-in.
  ///
  /// In en, this message translates to:
  /// **'The organisation ended this device’s sign-in. Sign in again when the server is reachable. Work on this device continues.'**
  String get backendRevoked;

  /// Secondary action on the first-run sign-in: work starts without it.
  ///
  /// In en, this message translates to:
  /// **'Continue without signing in'**
  String get signInLater;

  /// Action that ends the backend session on this device.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutAction;

  /// Settings row explanation for the server address and grant.
  ///
  /// In en, this message translates to:
  /// **'The server this device is enrolled with.'**
  String get backendSettingsSubtitle;

  /// Sign-in screen title.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// Sign-in action.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInAction;

  /// Email field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signInEmail;

  /// Password field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signInPassword;

  /// Organisation field on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Organisation'**
  String get signInOrganisation;

  /// Quiet line when the server cannot be reached.
  ///
  /// In en, this message translates to:
  /// **'The server cannot be reached. Work on this device continues.'**
  String get backendUnreachable;

  /// Shown when a grant has expired for relay or analysis.
  ///
  /// In en, this message translates to:
  /// **'The saved sign-in has expired for relay, analysis and role changes.'**
  String get backendGrantExpired;

  /// Sign-out confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutTitle;

  /// Sign-out warning.
  ///
  /// In en, this message translates to:
  /// **'Signing back in needs a connection to the server.'**
  String get signOutMessage;

  /// Relay control title.
  ///
  /// In en, this message translates to:
  /// **'Change relay'**
  String get relayTitle;

  /// Relay is waiting for a project manager.
  ///
  /// In en, this message translates to:
  /// **'Relay is off until a project manager enables it.'**
  String get relayOff;

  /// Relay needs a sign-in this device does not hold.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use the relay. Work on this device continues.'**
  String get relaySignInNeeded;

  /// Action that opens the shared-key form.
  ///
  /// In en, this message translates to:
  /// **'Add shared key'**
  String get relayAddKey;

  /// A never-relay project has no send action.
  ///
  /// In en, this message translates to:
  /// **'This project never uses the relay.'**
  String get relayNever;

  /// Send action for an enabled relay.
  ///
  /// In en, this message translates to:
  /// **'Send changes'**
  String get relaySend;

  /// Count of packages waiting to send.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get relayQueued;

  /// Count of packages the server accepted.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get relaySent;

  /// Count of packages the server has purged.
  ///
  /// In en, this message translates to:
  /// **'Purged'**
  String get relayPurged;

  /// Trial control that records a problem on this screen.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong here'**
  String get frictionLogAction;

  /// Optional context the tester adds to a trial report.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get frictionNote;

  /// Explicit consent to attach the current app screen to a local report.
  ///
  /// In en, this message translates to:
  /// **'Include a screenshot'**
  String get frictionScreenshot;

  /// Commits the report before dismissing the sheet.
  ///
  /// In en, this message translates to:
  /// **'Save report'**
  String get frictionSave;

  /// Confirms that the trial report is stored on this device.
  ///
  /// In en, this message translates to:
  /// **'Report saved on this device.'**
  String get frictionSaved;

  /// Opens the existing workbook and screenshot archive export from settings.
  ///
  /// In en, this message translates to:
  /// **'Export field trial log'**
  String get frictionExport;

  /// A second save cannot begin while the first is writing.
  ///
  /// In en, this message translates to:
  /// **'Your report is being saved.'**
  String get frictionSaving;

  /// Named screenshot failure, with a path that keeps the optional note.
  ///
  /// In en, this message translates to:
  /// **'The screenshot could not be captured.'**
  String get frictionScreenshotFailed;

  /// The tester may save the report without an image.
  ///
  /// In en, this message translates to:
  /// **'Try again or turn off the screenshot and save the report.'**
  String get frictionScreenshotRecovery;

  /// Refuses to overwrite a journal that could not be read.
  ///
  /// In en, this message translates to:
  /// **'Your saved feedback could not be read.'**
  String get feedbackJournalInvalid;

  /// A retry keeps the existing local journal in place.
  ///
  /// In en, this message translates to:
  /// **'Try again. Keep the saved files so they can be recovered.'**
  String get feedbackJournalRecovery;

  /// Prevents a report archive from quietly omitting a saved attachment.
  ///
  /// In en, this message translates to:
  /// **'A saved feedback image is missing.'**
  String get feedbackImageMissing;

  /// Names the recovery without deleting the journal entry.
  ///
  /// In en, this message translates to:
  /// **'Restore the saved image, then export the feedback again.'**
  String get feedbackImageRecovery;

  /// _and.
  ///
  /// In en, this message translates to:
  /// **'{named0} and {named1}'**
  String copyAnd(Object named0, Object named1);

  /// _and.
  ///
  /// In en, this message translates to:
  /// **'{namedsublist0} and {namedlast}'**
  String copyAndAnd(Object namedsublist0, Object namedlast);

  /// Sample interface name in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get gallerySampleName;

  /// Sample interface caption in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get gallerySampleCaption;

  /// Sample interface count in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get gallerySampleCount;

  /// Sample interface email in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get gallerySampleEmail;

  /// Sample interface phone in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get gallerySamplePhone;

  /// Sample interface when in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get gallerySampleWhen;

  /// Sample interface grade in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get gallerySampleGrade;

  /// Sample interface fuel in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get gallerySampleFuel;

  /// Sample interface tags in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get gallerySampleTags;

  /// Sample interface gps in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gallerySampleLocation;

  /// Sample interface stamp each capture in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Stamp each capture'**
  String get gallerySampleStampCapture;

  /// Sample interface boiler a in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Boiler A'**
  String get gallerySampleBoilerA;

  /// Sample interface boiler b in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Boiler B'**
  String get gallerySampleBoilerB;

  /// Sample interface open beside this list in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Open beside this list'**
  String get gallerySampleBesideList;

  /// Sample interface water in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get gallerySampleWater;

  /// Sample interface steam in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Steam'**
  String get gallerySampleSteam;

  /// Sample interface gas in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get gallerySampleGas;

  /// Sample interface chip in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Chip'**
  String get gallerySampleChip;

  /// Sample interface filter in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get gallerySampleFilter;

  /// Sample interface list tile in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'List tile'**
  String get gallerySampleListTile;

  /// Sample interface secondary line in the component gallery, not actual user data.
  ///
  /// In en, this message translates to:
  /// **'Secondary line'**
  String get gallerySampleSecondaryLine;

  /// Surface-level example in the theme gallery.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String surfacePreviewLevel(int level);

  /// Typography role sample in the theme gallery.
  ///
  /// In en, this message translates to:
  /// **'The {name} role — Tap it. It\'\'s data.'**
  String typeRampSample(String name);

  /// Localized application message for importAnotherDevice. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'another device'**
  String get importAnotherDevice;

  /// Localized application message for conflictUnknownDevice. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get conflictUnknownDevice;

  /// Localized application message for recordValueSource. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String recordValueSource(String source);

  /// Localized application message for recycleDeletedWhen. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'Deleted {when}'**
  String recycleDeletedWhen(String when);

  /// Localized application message for exportIncompleteCount. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'{count} incomplete'**
  String exportIncompleteCount(int count);

  /// Localized application message for exportUnapprovedCount. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'{count} not approved'**
  String exportUnapprovedCount(int count);

  /// Localized application message for exportBlockedMeetingCount. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'{count} with meeting actions missing an owner or due date, which stay out'**
  String exportBlockedMeetingCount(int count);

  /// Localized application message for exportFaceCount. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'{id}: {count} faces'**
  String exportFaceCount(String id, int count);

  /// Localized application message for mergeHistoryStatus. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'{status, select, applied{Merged} undone{Undone} imported{Imported} other{Failed}}'**
  String mergeHistoryStatus(String status);

  /// Localized application message for mergeHistoryCategory. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'{category, select, records{New records} updated_records{Updated records} photos{New photos} photos_here{Photos already here} files{Files} deletions{Deletions} conflicts{Conflicts} kept{Values kept} elsewhere{Already in another project} duplicates{Possible duplicates} skipped{Skipped records} other{{category}}}'**
  String mergeHistoryCategory(String category);

  /// Localized application message for mergeHistoryChoice. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'{choice, select, mine{Kept this device’s value} theirs{Used incoming value} typed{Entered a replacement} keepBoth{Kept both templates} other{Waiting for a decision}}'**
  String mergeHistoryChoice(String choice);

  /// Localized application message for relayPackageTooLarge. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'This encrypted package would be {bytes}; relay accepts packages up to {ceiling}.'**
  String relayPackageTooLarge(String bytes, String ceiling);

  /// Localized application message for relayPackageTooLargeRecovery. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'Share the exported package directly or export a smaller selection.'**
  String get relayPackageTooLargeRecovery;

  /// Localized application message for permissionBiometrics. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'Tapture uses biometrics only when you choose biometric app unlock.'**
  String get permissionBiometrics;

  /// Localized application message for packageMetadataTooLargeRecovery. User names, identifiers and values remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'Choose a smaller package scope on the exporting device, then open the new package.'**
  String get packageMetadataTooLargeRecovery;

  /// Default cancelled failure explanation for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'The action was cancelled.'**
  String get failureCancelledMessage;

  /// Default cancelled failure recovery for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'Start the action again if you still need it.'**
  String get failureCancelledRecovery;

  /// Default corruption failure explanation for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'This file or row could not be read.'**
  String get failureCorruptionMessage;

  /// Default corruption failure recovery for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'Keep the original. Export a copy and try opening it again.'**
  String get failureCorruptionRecovery;

  /// Default network failure explanation for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'The network is not available. Work on this device is saved.'**
  String get failureNetworkMessage;

  /// Default network failure recovery for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'Keep capturing. Processing will retry when you are back online.'**
  String get failureNetworkRecovery;

  /// Default permission failure explanation for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'Tapture does not have permission to do that.'**
  String get failurePermissionMessage;

  /// Default permission failure recovery for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'Allow the permission in settings, then try again.'**
  String get failurePermissionRecovery;

  /// Default provider failure explanation for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'A service this screen uses failed.'**
  String get failureProviderMessage;

  /// Default provider failure recovery for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'Try again. Nothing already captured was lost.'**
  String get failureProviderRecovery;

  /// Default storage failure explanation for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'The photo could not be saved on this device.'**
  String get failureStorageMessage;

  /// Default storage failure recovery for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'Free up space or export a project, then try again.'**
  String get failureStorageRecovery;

  /// Default validation failure explanation for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'That value is not valid.'**
  String get failureValidationMessage;

  /// Default validation failure recovery for operator-facing errors.
  ///
  /// In en, this message translates to:
  /// **'Correct the highlighted field and save again.'**
  String get failureValidationRecovery;

  /// Processing retry failure explanation for processingTimeout.
  ///
  /// In en, this message translates to:
  /// **'The provider did not answer in time.'**
  String get processingTimeout;

  /// Processing retry failure explanation for processingMalformedResponse.
  ///
  /// In en, this message translates to:
  /// **'The provider response could not be read.'**
  String get processingMalformedResponse;

  /// Processing retry failure explanation for processingStopped.
  ///
  /// In en, this message translates to:
  /// **'Processing stopped.'**
  String get processingStopped;

  /// Operator-facing unavailable AI explanation.
  ///
  /// In en, this message translates to:
  /// **'AI is not available.'**
  String get failureAIIsNotAvailable;

  /// Operator-facing unavailable AI explanation.
  ///
  /// In en, this message translates to:
  /// **'Continue capturing. Analysis can wait.'**
  String get failureContinueCapturingAnalysisCanWait;

  /// Operator-facing failure from lib/core/ai/ocr_service.dart.
  ///
  /// In en, this message translates to:
  /// **'That photo is not on this device.'**
  String get failureThatPhotoIsNotOnThisDevice;

  /// Operator-facing failure from lib/core/ai/ocr_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Capture the photo again, then try again.'**
  String get failureCaptureThePhotoAgainThenTryAgain;

  /// Operator-facing failure from lib/core/ai/ocr_service.dart.
  ///
  /// In en, this message translates to:
  /// **'That photo could not be read on this device.'**
  String get failureThatPhotoCouldNotBeReadOn;

  /// Operator-facing failure from lib/core/ai/ocr_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Use another photo or enter the value by hand.'**
  String get failureUseAnotherPhotoOrEnterTheValue;

  /// Operator-facing failure from lib/core/ai/ocr_service.dart.
  ///
  /// In en, this message translates to:
  /// **'That photo could not be read as an image.'**
  String get failureThatPhotoCouldNotBeReadAs;

  /// Operator-facing failure from lib/core/ai/proxy_ai_service.dart.
  ///
  /// In en, this message translates to:
  /// **'The analysis copy could not be read.'**
  String get failureTheAnalysisCopyCouldNotBeRead;

  /// Operator-facing failure from lib/core/ai/proxy_ai_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Keep the record and try again.'**
  String get failureKeepTheRecordAndTryAgain;

  /// Operator-facing failure from lib/core/ai/proxy_ai_service.dart.
  ///
  /// In en, this message translates to:
  /// **'The analysis response could not be read.'**
  String get failureTheAnalysisResponseCouldNotBeRead;

  /// Operator-facing failure from lib/core/ai/proxy_ai_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Analysis can wait.'**
  String get failureAnalysisCanWait;

  /// Operator-facing failure from lib/core/ai/proxy_ai_service.dart.
  ///
  /// In en, this message translates to:
  /// **'The analysis quota is used up.'**
  String get failureTheAnalysisQuotaIsUsedUp;

  /// Operator-facing failure from lib/core/ai/proxy_ai_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Analysis is paused on the server for a moment.'**
  String get failureAnalysisIsPausedOnTheServerFor;

  /// Operator-facing failure from lib/core/ai/proxy_ai_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Continue capturing. Analysis tries again later.'**
  String get failureContinueCapturingAnalysisTriesAgainLater;

  /// Operator-facing failure from lib/core/ai/proxy_ai_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Analysis access is unavailable for this project.'**
  String get failureAnalysisAccessIsUnavailableForThisProject;

  /// Operator-facing failure from lib/core/ai/proxy_ai_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Continue capturing and check organisation access.'**
  String get failureContinueCapturingAndCheckOrganisationAccess;

  /// Operator-facing failure from lib/core/ai/proxy_ai_service.dart.
  ///
  /// In en, this message translates to:
  /// **'The analysis media is too large to send.'**
  String get failureTheAnalysisMediaIsTooLargeTo;

  /// Operator-facing failure from lib/core/ai/proxy_ai_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Keep the record and complete it without analysis.'**
  String get failureKeepTheRecordAndCompleteItWithout;

  /// Operator-facing failure from lib/core/backend/backend_api_client.dart.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was not accepted.'**
  String get failureSignInWasNotAccepted;

  /// Operator-facing failure from lib/core/backend/backend_api_client.dart.
  ///
  /// In en, this message translates to:
  /// **'Check your email, password and organisation.'**
  String get failureCheckYourEmailPasswordAndOrganisation;

  /// Operator-facing failure from lib/core/backend/backend_api_client.dart.
  ///
  /// In en, this message translates to:
  /// **'The organisation ended this device’s sign-in.'**
  String get failureTheOrganisationEndedThisDeviceSSign;

  /// Operator-facing failure from lib/core/backend/backend_api_client.dart.
  ///
  /// In en, this message translates to:
  /// **'Sign in again when the server is reachable. Work on this device continues.'**
  String get failureSignInAgainWhenTheServerIs;

  /// Operator-facing failure from lib/core/backend/backend_api_client.dart.
  ///
  /// In en, this message translates to:
  /// **'The server could not complete sign-in.'**
  String get failureTheServerCouldNotCompleteSignIn;

  /// Operator-facing failure from lib/core/backend/backend_api_client.dart.
  ///
  /// In en, this message translates to:
  /// **'Try again when the server is reachable. Work on this device continues.'**
  String get failureTryAgainWhenTheServerIsReachable;

  /// Operator-facing failure from lib/core/backend/backend_session.dart.
  ///
  /// In en, this message translates to:
  /// **'The saved sign-in could not be read.'**
  String get failureTheSavedSignInCouldNotBe;

  /// Operator-facing failure from lib/core/backend/backend_session.dart.
  ///
  /// In en, this message translates to:
  /// **'Check the account settings. Your local work is unchanged.'**
  String get failureCheckTheAccountSettingsYourLocalWork;

  /// Operator-facing failure from lib/core/backend/backend_session.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter the organisation’s HTTPS server address.'**
  String get failureEnterTheOrganisationSHTTPSServerAddress;

  /// Operator-facing failure from lib/core/backend/backend_session.dart.
  ///
  /// In en, this message translates to:
  /// **'Check the address with your administrator.'**
  String get failureCheckTheAddressWithYourAdministrator;

  /// Operator-facing failure from lib/core/backend/backend_session.dart.
  ///
  /// In en, this message translates to:
  /// **'Sign out before changing organisation.'**
  String get failureSignOutBeforeChangingOrganisation;

  /// Operator-facing failure from lib/core/backend/backend_session.dart.
  ///
  /// In en, this message translates to:
  /// **'Keep the current account or sign out first.'**
  String get failureKeepTheCurrentAccountOrSignOut;

  /// Operator-facing failure from lib/core/backend/backend_transport.dart.
  ///
  /// In en, this message translates to:
  /// **'The organisation server could not be reached.'**
  String get failureTheOrganisationServerCouldNotBeReached;

  /// Operator-facing failure from lib/core/backend/backend_transport.dart.
  ///
  /// In en, this message translates to:
  /// **'Continue working offline and try again later.'**
  String get failureContinueWorkingOfflineAndTryAgainLater;

  /// Operator-facing failure from lib/core/backend/relay_queue.dart.
  ///
  /// In en, this message translates to:
  /// **'Use a shared key of at least 16 characters.'**
  String get failureUseASharedKeyOfAtLeast;

  /// Operator-facing failure from lib/core/backend/relay_queue.dart.
  ///
  /// In en, this message translates to:
  /// **'Ask the project manager for the same key used on the other devices.'**
  String get failureAskTheProjectManagerForTheSame;

  /// Operator-facing failure from lib/core/backend/relay_queue.dart.
  ///
  /// In en, this message translates to:
  /// **'This project is registered on the server to others.'**
  String get failureThisProjectIsRegisteredOnTheServer;

  /// Operator-facing failure from lib/core/backend/relay_queue.dart.
  ///
  /// In en, this message translates to:
  /// **'Ask an administrator to add you to it. Work on this device continues.'**
  String get failureAskAnAdministratorToAddYouTo;

  /// Operator-facing failure from lib/core/backend/relay_queue.dart.
  ///
  /// In en, this message translates to:
  /// **'Add the shared project key first.'**
  String get failureAddTheSharedProjectKeyFirst;

  /// Operator-facing failure from lib/core/backend/relay_queue.dart.
  ///
  /// In en, this message translates to:
  /// **'Ask the project manager for the key.'**
  String get failureAskTheProjectManagerForTheKey;

  /// Operator-facing failure from lib/core/backend/relay_queue.dart.
  ///
  /// In en, this message translates to:
  /// **'Relay could not complete this request.'**
  String get failureRelayCouldNotCompleteThisRequest;

  /// Operator-facing failure from lib/core/backend/relay_queue.dart.
  ///
  /// In en, this message translates to:
  /// **'Keep working locally and try Sync again.'**
  String get failureKeepWorkingLocallyAndTrySyncAgain;

  /// Operator-facing failure from lib/core/bundle/bundle_encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'That password did not open the bundle.'**
  String get failureThatPasswordDidNotOpenTheBundle;

  /// Operator-facing failure from lib/core/bundle/bundle_encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'Try the password again. Nothing was extracted.'**
  String get failureTryThePasswordAgainNothingWasExtracted;

  /// Operator-facing failure from lib/core/bundle/bundle_json.dart.
  ///
  /// In en, this message translates to:
  /// **'The project metadata is too large for one package.'**
  String get failureTheProjectMetadataIsTooLargeFor;

  /// Operator-facing failure from lib/core/bundle/bundle_json.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a smaller package scope.'**
  String get failureChooseASmallerPackageScope;

  /// Operator-facing failure from lib/core/bundle/bundle_password_key_stub.dart.
  ///
  /// In en, this message translates to:
  /// **'Password protection is unavailable on this device.'**
  String get failurePasswordProtectionIsUnavailableOnThisDevice;

  /// Operator-facing failure from lib/core/bundle/bundle_password_key_stub.dart.
  ///
  /// In en, this message translates to:
  /// **'Open this package on a supported device.'**
  String get failureOpenThisPackageOnASupportedDevice;

  /// Operator-facing failure from lib/core/bundle/bundle_password_key_web.dart.
  ///
  /// In en, this message translates to:
  /// **'Password protection needs browser cryptography.'**
  String get failurePasswordProtectionNeedsBrowserCryptography;

  /// Operator-facing failure from lib/core/bundle/bundle_password_key_web.dart.
  ///
  /// In en, this message translates to:
  /// **'Open the app through a secure connection.'**
  String get failureOpenTheAppThroughASecureConnection;

  /// Operator-facing failure from lib/core/bundle/bundle_reader.dart.
  ///
  /// In en, this message translates to:
  /// **'This bundle needs a password.'**
  String get failureThisBundleNeedsAPassword;

  /// Operator-facing failure from lib/core/bundle/bundle_reader.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter its password to open it.'**
  String get failureEnterItsPasswordToOpenIt;

  /// Operator-facing failure from lib/core/bundle/bundle_redaction.dart.
  ///
  /// In en, this message translates to:
  /// **'The bundle contains a secret and was not written.'**
  String get failureTheBundleContainsASecretAndWas;

  /// Operator-facing failure from lib/core/bundle/bundle_redaction.dart.
  ///
  /// In en, this message translates to:
  /// **'Remove the secret and export the bundle again.'**
  String get failureRemoveTheSecretAndExportTheBundle;

  /// Operator-facing failure from lib/core/bundle/bundle_redaction.dart.
  ///
  /// In en, this message translates to:
  /// **'The bundle has too many nested archives.'**
  String get failureTheBundleHasTooManyNestedArchives;

  /// Operator-facing failure from lib/core/bundle/bundle_redaction.dart.
  ///
  /// In en, this message translates to:
  /// **'A nested bundle archive could not be safely checked.'**
  String get failureANestedBundleArchiveCouldNotBe;

  /// Operator-facing failure from lib/core/bundle/bundle_redaction.dart.
  ///
  /// In en, this message translates to:
  /// **'An encrypted or unsupported attachment could not be checked.'**
  String get failureAnEncryptedOrUnsupportedAttachmentCouldNot;

  /// Operator-facing failure from lib/core/bundle/bundle_redaction.dart.
  ///
  /// In en, this message translates to:
  /// **'A nested bundle archive is too large.'**
  String get failureANestedBundleArchiveIsTooLarge;

  /// Operator-facing failure from lib/core/bundle/bundle_redaction.dart.
  ///
  /// In en, this message translates to:
  /// **'A nested bundle entry has an invalid size.'**
  String get failureANestedBundleEntryHasAnInvalid;

  /// Operator-facing failure from lib/core/bundle/bundle_redaction.dart.
  ///
  /// In en, this message translates to:
  /// **'A nested bundle entry exceeds its declared size.'**
  String get failureANestedBundleEntryExceedsItsDeclared;

  /// Operator-facing failure from lib/core/bundle/native_bundle_entries.dart.
  ///
  /// In en, this message translates to:
  /// **'Finish reading the current package entry first.'**
  String get failureFinishReadingTheCurrentPackageEntryFirst;

  /// Operator-facing failure from lib/core/bundle/native_bundle_entries.dart.
  ///
  /// In en, this message translates to:
  /// **'The package entry is missing.'**
  String get failureThePackageEntryIsMissing;

  /// Operator-facing failure from lib/core/bundle/native_bundle_entries.dart.
  ///
  /// In en, this message translates to:
  /// **'Read this large package entry as a stream.'**
  String get failureReadThisLargePackageEntryAsA;

  /// Operator-facing failure from lib/core/bundle/native_bundle_entries.dart.
  ///
  /// In en, this message translates to:
  /// **'The package entry changed.'**
  String get failureThePackageEntryChanged;

  /// Operator-facing failure from lib/core/bundle/native_bundle_entries.dart.
  ///
  /// In en, this message translates to:
  /// **'The package entry checksum changed.'**
  String get failureThePackageEntryChecksumChanged;

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'No upload destination is registered for {value0}.'**
  String failureNoUploadDestinationIsRegisteredForValue(String value0);

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose another destination.'**
  String get failureChooseAnotherDestination;

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The destination refused the sign-in.'**
  String get failureTheDestinationRefusedTheSignIn;

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Check the key or sign in again.'**
  String get failureCheckTheKeyOrSignInAgain;

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'That bucket or folder was not found.'**
  String get failureThatBucketOrFolderWasNotFound;

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Check the name and try the connection again.'**
  String get failureCheckTheNameAndTryTheConnection;

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The destination did not finish the upload.'**
  String get failureTheDestinationDidNotFinishTheUpload;

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Try again.'**
  String get failureTryAgain;

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The server redirected the upload to another host.'**
  String get failureTheServerRedirectedTheUploadToAnother;

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Check the address and try again.'**
  String get failureCheckTheAddressAndTryAgain;

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The destination rejected the upload.'**
  String get failureTheDestinationRejectedTheUpload;

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Check the settings and try again.'**
  String get failureCheckTheSettingsAndTryAgain;

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The file could not be read while it was being sent.'**
  String get failureTheFileCouldNotBeReadWhile;

  /// Operator-facing failure from lib/core/cloud/cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Check that the file is still on this device, then retry.'**
  String get failureCheckThatTheFileIsStillOn;

  /// Operator-facing failure from lib/core/cloud/cloud_operation_policy.dart.
  ///
  /// In en, this message translates to:
  /// **'Uploads are paused while the app is offline.'**
  String get failureUploadsArePausedWhileTheAppIs;

  /// Operator-facing failure from lib/core/cloud/cloud_operation_policy.dart.
  ///
  /// In en, this message translates to:
  /// **'Go online, then confirm the upload again.'**
  String get failureGoOnlineThenConfirmTheUploadAgain;

  /// Operator-facing failure from lib/core/cloud/cloud_operation_policy.dart.
  ///
  /// In en, this message translates to:
  /// **'Uploads to this destination are turned off.'**
  String get failureUploadsToThisDestinationAreTurnedOff;

  /// Operator-facing failure from lib/core/cloud/cloud_operation_policy.dart.
  ///
  /// In en, this message translates to:
  /// **'Enable the destination on the privacy page first.'**
  String get failureEnableTheDestinationOnThePrivacyPage;

  /// Operator-facing failure from lib/core/cloud/cloud_sign_in_io.dart.
  ///
  /// In en, this message translates to:
  /// **'Cloud sign-in could not finish.'**
  String get failureCloudSignInCouldNotFinish;

  /// Operator-facing failure from lib/core/cloud/cloud_sign_in_io.dart.
  ///
  /// In en, this message translates to:
  /// **'Try signing in again.'**
  String get failureTrySigningInAgain;

  /// Operator-facing failure from lib/core/cloud/cloud_transport_io.dart.
  ///
  /// In en, this message translates to:
  /// **'The destination returned too much data.'**
  String get failureTheDestinationReturnedTooMuchData;

  /// Operator-facing failure from lib/core/cloud/cloud_transport_io.dart.
  ///
  /// In en, this message translates to:
  /// **'Check the destination address and try again.'**
  String get failureCheckTheDestinationAddressAndTryAgain;

  /// Operator-facing failure from lib/core/cloud/cloud_transport_io.dart.
  ///
  /// In en, this message translates to:
  /// **'The destination could not be reached.'**
  String get failureTheDestinationCouldNotBeReached;

  /// Operator-facing failure from lib/core/cloud/cloud_transport_io.dart.
  ///
  /// In en, this message translates to:
  /// **'Try again when you are online.'**
  String get failureTryAgainWhenYouAreOnline;

  /// Operator-facing failure from lib/core/cloud/destination_secrets.dart.
  ///
  /// In en, this message translates to:
  /// **'Remove the destination and add it again.'**
  String get failureRemoveTheDestinationAndAddItAgain;

  /// Operator-facing failure from lib/core/cloud/destination_secrets.dart.
  ///
  /// In en, this message translates to:
  /// **'This destination sign-in changed during the upload.'**
  String get failureThisDestinationSignInChangedDuringThe;

  /// Operator-facing failure from lib/core/cloud/destination_secrets.dart.
  ///
  /// In en, this message translates to:
  /// **'Review the destination and confirm a new upload.'**
  String get failureReviewTheDestinationAndConfirmANew;

  /// Operator-facing failure from lib/core/cloud/google_drive_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The destination did not accept the test file.'**
  String get failureTheDestinationDidNotAcceptTheTest;

  /// Operator-facing failure from lib/core/cloud/google_drive_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Sign in again and retry the test.'**
  String get failureSignInAgainAndRetryTheTest;

  /// Operator-facing failure from lib/core/cloud/google_drive_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The destination has not finished the upload.'**
  String get failureTheDestinationHasNotFinishedTheUpload;

  /// Operator-facing failure from lib/core/cloud/google_drive_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Retry the upload.'**
  String get failureRetryTheUpload;

  /// Operator-facing failure from lib/core/cloud/local_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'That folder cannot be written.'**
  String get failureThatFolderCannotBeWritten;

  /// Operator-facing failure from lib/core/cloud/local_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose the folder again.'**
  String get failureChooseTheFolderAgain;

  /// Operator-facing failure from lib/core/cloud/local_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The file could not be written to that folder.'**
  String get failureTheFileCouldNotBeWrittenTo;

  /// Operator-facing failure from lib/core/cloud/local_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Free some space or choose the folder again.'**
  String get failureFreeSomeSpaceOrChooseTheFolder;

  /// Operator-facing failure from lib/core/cloud/local_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'This folder requires a supported system folder grant.'**
  String get failureThisFolderRequiresASupportedSystemFolder;

  /// Operator-facing failure from lib/core/cloud/local_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose an accessible folder or another destination.'**
  String get failureChooseAnAccessibleFolderOrAnotherDestination;

  /// Operator-facing failure from lib/core/cloud/local_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'That folder path is not usable.'**
  String get failureThatFolderPathIsNotUsable;

  /// Operator-facing failure from lib/core/cloud/local_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The Tapture folder on this device is not available.'**
  String get failureTheTaptureFolderOnThisDeviceIs;

  /// Operator-facing failure from lib/core/cloud/local_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Check the storage location in Settings.'**
  String get failureCheckTheStorageLocationInSettings;

  /// Operator-facing failure from lib/core/cloud/native_google_authorization.dart.
  ///
  /// In en, this message translates to:
  /// **'This Google Drive sign-in is no longer available.'**
  String get failureThisGoogleDriveSignInIsNo;

  /// Operator-facing failure from lib/core/cloud/native_google_authorization.dart.
  ///
  /// In en, this message translates to:
  /// **'Sign in to this destination again.'**
  String get failureSignInToThisDestinationAgain;

  /// Operator-facing failure from lib/core/cloud/native_google_client_io.dart.
  ///
  /// In en, this message translates to:
  /// **'Google Drive needs a current sign-in for this account.'**
  String get failureGoogleDriveNeedsACurrentSignIn;

  /// Operator-facing failure from lib/core/cloud/native_google_client_io.dart.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to allow file access.'**
  String get failureSignInAgainToAllowFileAccess;

  /// Operator-facing failure from lib/core/cloud/native_google_client_stub.dart.
  ///
  /// In en, this message translates to:
  /// **'Native Google Drive sign-in is unavailable.'**
  String get failureNativeGoogleDriveSignInIsUnavailable;

  /// Operator-facing failure from lib/core/cloud/oauth_destination_client.dart.
  ///
  /// In en, this message translates to:
  /// **'The destination is still saved. Sign in, then try the upload.'**
  String get failureTheDestinationIsStillSavedSignIn;

  /// Operator-facing failure from lib/core/cloud/oauth_upload_session.dart.
  ///
  /// In en, this message translates to:
  /// **'The upload chunk size is not usable.'**
  String get failureTheUploadChunkSizeIsNotUsable;

  /// Operator-facing failure from lib/core/cloud/oauth_upload_session.dart.
  ///
  /// In en, this message translates to:
  /// **'Use the standard upload settings.'**
  String get failureUseTheStandardUploadSettings;

  /// Operator-facing failure from lib/core/cloud/oauth_upload_session.dart.
  ///
  /// In en, this message translates to:
  /// **'The destination returned an unusable upload response.'**
  String get failureTheDestinationReturnedAnUnusableUploadResponse;

  /// Operator-facing failure from lib/core/cloud/oauth_upload_session.dart.
  ///
  /// In en, this message translates to:
  /// **'Test the destination, then try the upload again.'**
  String get failureTestTheDestinationThenTryTheUpload;

  /// Operator-facing failure from lib/core/cloud/s3_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The bucket did not acknowledge the uploaded part.'**
  String get failureTheBucketDidNotAcknowledgeTheUploaded;

  /// Operator-facing failure from lib/core/cloud/s3_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Test the destination and try again.'**
  String get failureTestTheDestinationAndTryAgain;

  /// Operator-facing failure from lib/core/cloud/s3_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The bucket did not finish the upload.'**
  String get failureTheBucketDidNotFinishTheUpload;

  /// Operator-facing failure from lib/core/cloud/s3_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The bucket refused to finish the upload.'**
  String get failureTheBucketRefusedToFinishTheUpload;

  /// Operator-facing failure from lib/core/cloud/s3_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The bucket did not confirm the completed upload.'**
  String get failureTheBucketDidNotConfirmTheCompleted;

  /// Operator-facing failure from lib/core/cloud/s3_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The destination did not start the upload.'**
  String get failureTheDestinationDidNotStartTheUpload;

  /// Operator-facing failure from lib/core/cloud/s3_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Try the connection again.'**
  String get failureTryTheConnectionAgain;

  /// Operator-facing failure from lib/core/cloud/s3_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'This destination has no saved sign-in.'**
  String get failureThisDestinationHasNoSavedSignIn;

  /// Operator-facing failure from lib/core/cloud/s3_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter the keys and test the connection.'**
  String get failureEnterTheKeysAndTestTheConnection;

  /// Operator-facing failure from lib/core/cloud/s3_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The saved sign-in is not usable.'**
  String get failureTheSavedSignInIsNotUsable;

  /// Operator-facing failure from lib/core/cloud/s3_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter the keys again.'**
  String get failureEnterTheKeysAgain;

  /// Operator-facing failure from lib/core/cloud/s3_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The bucket settings are incomplete.'**
  String get failureTheBucketSettingsAreIncomplete;

  /// Operator-facing failure from lib/core/cloud/s3_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter the key, region and bucket.'**
  String get failureEnterTheKeyRegionAndBucket;

  /// Operator-facing failure from lib/core/cloud/scoped_folder_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a filename without folder separators.'**
  String get failureChooseAFilenameWithoutFolderSeparators;

  /// Operator-facing failure from lib/core/cloud/scoped_folder_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The folder could not open a new file.'**
  String get failureTheFolderCouldNotOpenANew;

  /// Operator-facing failure from lib/core/cloud/scoped_folder_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The folder could not publish the file.'**
  String get failureTheFolderCouldNotPublishTheFile;

  /// Operator-facing failure from lib/core/cloud/scoped_folder_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Access to the chosen folder was lost.'**
  String get failureAccessToTheChosenFolderWasLost;

  /// Operator-facing failure from lib/core/cloud/scoped_folder_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose an accessible folder and try again.'**
  String get failureChooseAnAccessibleFolderAndTryAgain;

  /// Operator-facing failure from lib/core/cloud/webdav_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The upload filename is not usable.'**
  String get failureTheUploadFilenameIsNotUsable;

  /// Operator-facing failure from lib/core/cloud/webdav_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter the address and sign-in, then test it.'**
  String get failureEnterTheAddressAndSignInThen;

  /// Operator-facing failure from lib/core/cloud/webdav_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'The destination address or sign-in is not usable.'**
  String get failureTheDestinationAddressOrSignInIs;

  /// Operator-facing failure from lib/core/cloud/webdav_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter a full HTTPS address and sign-in again.'**
  String get failureEnterAFullHTTPSAddressAndSign;

  /// Operator-facing failure from lib/core/cloud/worker_cloud_destination.dart.
  ///
  /// In en, this message translates to:
  /// **'Google Drive sign-in could not finish.'**
  String get failureGoogleDriveSignInCouldNotFinish;

  /// Operator-facing failure from lib/core/cloud/worker_cloud_destination_io.dart.
  ///
  /// In en, this message translates to:
  /// **'This destination needs a fresh sign-in.'**
  String get failureThisDestinationNeedsAFreshSignIn;

  /// Operator-facing failure from lib/core/cloud/worker_cloud_destination_io.dart.
  ///
  /// In en, this message translates to:
  /// **'The upload checkpoint could not be saved in time.'**
  String get failureTheUploadCheckpointCouldNotBeSaved;

  /// Operator-facing failure from lib/core/cloud/worker_cloud_destination_io.dart.
  ///
  /// In en, this message translates to:
  /// **'Check secure storage, then try again.'**
  String get failureCheckSecureStorageThenTryAgain;

  /// Operator-facing failure from lib/core/db/base_dao.dart.
  ///
  /// In en, this message translates to:
  /// **'That row is no longer on this device.'**
  String get failureThatRowIsNoLongerOnThis;

  /// Operator-facing failure from lib/core/db/base_dao.dart.
  ///
  /// In en, this message translates to:
  /// **'Refresh the list and try again.'**
  String get failureRefreshTheListAndTryAgain;

  /// Operator-facing failure from lib/core/db/base_dao.dart.
  ///
  /// In en, this message translates to:
  /// **'A delete needs a reason.'**
  String get failureADeleteNeedsAReason;

  /// Operator-facing failure from lib/core/db/base_dao.dart.
  ///
  /// In en, this message translates to:
  /// **'Say why this row should be removed, then try again.'**
  String get failureSayWhyThisRowShouldBeRemoved;

  /// Operator-facing failure from lib/core/db/base_dao.dart.
  ///
  /// In en, this message translates to:
  /// **'The database could not complete that write.'**
  String get failureTheDatabaseCouldNotCompleteThatWrite;

  /// Operator-facing failure from lib/core/db/base_dao.dart.
  ///
  /// In en, this message translates to:
  /// **'Free up space or export a project, then try again.'**
  String get failureFreeUpSpaceOrExportAProject;

  /// Operator-facing failure from lib/core/db/encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'The database is encrypted and the key is missing.'**
  String get failureTheDatabaseIsEncryptedAndTheKey;

  /// Operator-facing failure from lib/core/db/encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'Restore the key from a backup, then open the app again.'**
  String get failureRestoreTheKeyFromABackupThen;

  /// Operator-facing failure from lib/core/db/encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'The database key is missing or unreadable.'**
  String get failureTheDatabaseKeyIsMissingOrUnreadable;

  /// Operator-facing failure from lib/core/db/encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'Type DISABLE ENCRYPTION to turn encryption off.'**
  String get failureTypeDISABLEENCRYPTIONToTurnEncryptionOff;

  /// Operator-facing failure from lib/core/db/encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter the confirmation exactly, then try again.'**
  String get failureEnterTheConfirmationExactlyThenTryAgain;

  /// Operator-facing failure from lib/core/db/encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'There is no database to encrypt.'**
  String get failureThereIsNoDatabaseToEncrypt;

  /// Operator-facing failure from lib/core/db/encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'Open the app once so a database is created, then try again.'**
  String get failureOpenTheAppOnceSoADatabase;

  /// Operator-facing failure from lib/core/db/encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'The database could not be encrypted.'**
  String get failureTheDatabaseCouldNotBeEncrypted;

  /// Operator-facing failure from lib/core/db/encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'Free up space, then try again.'**
  String get failureFreeUpSpaceThenTryAgain;

  /// Operator-facing failure from lib/core/db/encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'The encrypted copy did not match the original.'**
  String get failureTheEncryptedCopyDidNotMatchThe;

  /// Operator-facing failure from lib/core/db/encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'Try encrypting again. The original database was not changed.'**
  String get failureTryEncryptingAgainTheOriginalDatabaseWas;

  /// Operator-facing failure from lib/core/db/encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'Keep the working database. Free up space, then close again.'**
  String get failureKeepTheWorkingDatabaseFreeUpSpace;

  /// Operator-facing failure from lib/core/db/encryption.dart.
  ///
  /// In en, this message translates to:
  /// **'Restore the key from a backup. The encrypted database was not changed.'**
  String get failureRestoreTheKeyFromABackupThe;

  /// Operator-facing failure from lib/core/db/migrations.dart.
  ///
  /// In en, this message translates to:
  /// **'This update would drop or rewrite a column.'**
  String get failureThisUpdateWouldDropOrRewriteA;

  /// Operator-facing failure from lib/core/db/migrations.dart.
  ///
  /// In en, this message translates to:
  /// **'Export your projects, then confirm the update.'**
  String get failureExportYourProjectsThenConfirmTheUpdate;

  /// Operator-facing failure from lib/core/db/record_schema.dart.
  ///
  /// In en, this message translates to:
  /// **'This device cannot build the record search index.'**
  String get failureThisDeviceCannotBuildTheRecordSearch;

  /// Operator-facing failure from lib/core/db/record_schema.dart.
  ///
  /// In en, this message translates to:
  /// **'Update the app, then open it again.'**
  String get failureUpdateTheAppThenOpenItAgain;

  /// Operator-facing failure from lib/core/db/tables/attachments.dart.
  ///
  /// In en, this message translates to:
  /// **'The file path must stay inside the project folder.'**
  String get failureTheFilePathMustStayInsideThe;

  /// Operator-facing failure from lib/core/db/tables/attachments.dart.
  ///
  /// In en, this message translates to:
  /// **'Save the file under the project folder and try again.'**
  String get failureSaveTheFileUnderTheProjectFolder;

  /// Operator-facing failure from lib/core/db/tables/captions.dart.
  ///
  /// In en, this message translates to:
  /// **'The original caption cannot be changed.'**
  String get failureTheOriginalCaptionCannotBeChanged;

  /// Operator-facing failure from lib/core/db/tables/captions.dart.
  ///
  /// In en, this message translates to:
  /// **'Leave the captured text and write a refined one.'**
  String get failureLeaveTheCapturedTextAndWriteA;

  /// Operator-facing failure from lib/core/db/tables/duplicates.dart.
  ///
  /// In en, this message translates to:
  /// **'A duplicate pair needs two records.'**
  String get failureADuplicatePairNeedsTwoRecords;

  /// Operator-facing failure from lib/core/db/tables/duplicates.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose both records and try again.'**
  String get failureChooseBothRecordsAndTryAgain;

  /// Operator-facing failure from lib/core/db/tables/duplicates.dart.
  ///
  /// In en, this message translates to:
  /// **'A record cannot be a duplicate of itself.'**
  String get failureARecordCannotBeADuplicateOf;

  /// Operator-facing failure from lib/core/db/tables/duplicates.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose two different records and try again.'**
  String get failureChooseTwoDifferentRecordsAndTryAgain;

  /// Operator-facing failure from lib/core/db/tables/duplicates.dart.
  ///
  /// In en, this message translates to:
  /// **'A duplicate pair needs a project, a signal and a score.'**
  String get failureADuplicatePairNeedsAProjectA;

  /// Operator-facing failure from lib/core/db/tables/duplicates.dart.
  ///
  /// In en, this message translates to:
  /// **'Run detection again, then try again.'**
  String get failureRunDetectionAgainThenTryAgain;

  /// Operator-facing failure from lib/core/db/tables/duplicates.dart.
  ///
  /// In en, this message translates to:
  /// **'A resolution needs a choice and an operator.'**
  String get failureAResolutionNeedsAChoiceAndAn;

  /// Operator-facing failure from lib/core/db/tables/duplicates.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose how to resolve the pair, then try again.'**
  String get failureChooseHowToResolveThePairThen;

  /// Operator-facing failure from lib/core/db/tables/duplicates.dart.
  ///
  /// In en, this message translates to:
  /// **'That pair is no longer on this device.'**
  String get failureThatPairIsNoLongerOnThis;

  /// Operator-facing failure from lib/core/db/tables/exports.dart.
  ///
  /// In en, this message translates to:
  /// **'A completed export cannot be changed.'**
  String get failureACompletedExportCannotBeChanged;

  /// Operator-facing failure from lib/core/db/tables/exports.dart.
  ///
  /// In en, this message translates to:
  /// **'Run a new export instead of rewriting this one.'**
  String get failureRunANewExportInsteadOfRewriting;

  /// Operator-facing failure from lib/core/db/tables/exports.dart.
  ///
  /// In en, this message translates to:
  /// **'An export is recorded only when the file is finished.'**
  String get failureAnExportIsRecordedOnlyWhenThe;

  /// Operator-facing failure from lib/core/db/tables/exports.dart.
  ///
  /// In en, this message translates to:
  /// **'Finish writing the file, then record the export.'**
  String get failureFinishWritingTheFileThenRecordThe;

  /// Operator-facing failure from lib/core/db/tables/exports.dart.
  ///
  /// In en, this message translates to:
  /// **'The export formats are not in a form Tapture can store.'**
  String get failureTheExportFormatsAreNotInA;

  /// Operator-facing failure from lib/core/db/tables/exports.dart.
  ///
  /// In en, this message translates to:
  /// **'Fix the formats list and save again.'**
  String get failureFixTheFormatsListAndSaveAgain;

  /// Operator-facing failure from lib/core/db/tables/exports.dart.
  ///
  /// In en, this message translates to:
  /// **'The export filters are not in a form Tapture can store.'**
  String get failureTheExportFiltersAreNotInA;

  /// Operator-facing failure from lib/core/db/tables/exports.dart.
  ///
  /// In en, this message translates to:
  /// **'Store the query, not the exported values.'**
  String get failureStoreTheQueryNotTheExportedValues;

  /// Operator-facing failure from lib/core/db/tables/exports.dart.
  ///
  /// In en, this message translates to:
  /// **'That entry could not be read.'**
  String get failureThatEntryCouldNotBeRead;

  /// Operator-facing failure from lib/core/db/tables/exports.dart.
  ///
  /// In en, this message translates to:
  /// **'Change it, then save again.'**
  String get failureChangeItThenSaveAgain;

  /// Operator-facing failure from lib/core/db/tables/field_evidence.dart.
  ///
  /// In en, this message translates to:
  /// **'The marked area on the photo could not be read.'**
  String get failureTheMarkedAreaOnThePhotoCould;

  /// Operator-facing failure from lib/core/db/tables/field_evidence.dart.
  ///
  /// In en, this message translates to:
  /// **'Fix the region object and save again.'**
  String get failureFixTheRegionObjectAndSaveAgain;

  /// Operator-facing failure from lib/core/db/tables/field_evidence.dart.
  ///
  /// In en, this message translates to:
  /// **'The marked area on the photo is not in a form Tapture can store.'**
  String get failureTheMarkedAreaOnThePhotoIs;

  /// Operator-facing failure from lib/core/db/tables/meetings.dart.
  ///
  /// In en, this message translates to:
  /// **'That meeting is no longer on this device.'**
  String get failureThatMeetingIsNoLongerOnThis;

  /// Operator-facing failure from lib/core/db/tables/meetings.dart.
  ///
  /// In en, this message translates to:
  /// **'The original transcript cannot be changed.'**
  String get failureTheOriginalTranscriptCannotBeChanged;

  /// Operator-facing failure from lib/core/db/tables/meetings.dart.
  ///
  /// In en, this message translates to:
  /// **'Leave the captured text and write refined minutes.'**
  String get failureLeaveTheCapturedTextAndWriteRefined;

  /// Operator-facing failure from lib/core/db/tables/meetings.dart.
  ///
  /// In en, this message translates to:
  /// **'The meeting agenda could not be read.'**
  String get failureTheMeetingAgendaCouldNotBeRead;

  /// Operator-facing failure from lib/core/db/tables/meetings.dart.
  ///
  /// In en, this message translates to:
  /// **'Fix the agenda list and save again.'**
  String get failureFixTheAgendaListAndSaveAgain;

  /// Operator-facing failure from lib/core/db/tables/meetings.dart.
  ///
  /// In en, this message translates to:
  /// **'The meeting agenda is not in a form Tapture can store.'**
  String get failureTheMeetingAgendaIsNotInA;

  /// Operator-facing failure from lib/core/db/tables/merge.dart.
  ///
  /// In en, this message translates to:
  /// **'The merge summary could not be read.'**
  String get failureTheMergeSummaryCouldNotBeRead;

  /// Operator-facing failure from lib/core/db/tables/merge.dart.
  ///
  /// In en, this message translates to:
  /// **'Fix the counts object and save again.'**
  String get failureFixTheCountsObjectAndSaveAgain;

  /// Operator-facing failure from lib/core/db/tables/merge.dart.
  ///
  /// In en, this message translates to:
  /// **'The merge summary is not in a form Tapture can store.'**
  String get failureTheMergeSummaryIsNotInA;

  /// Operator-facing failure from lib/core/db/tables/merge_conflicts.dart.
  ///
  /// In en, this message translates to:
  /// **'A conflict needs a choice and an operator.'**
  String get failureAConflictNeedsAChoiceAndAn;

  /// Operator-facing failure from lib/core/db/tables/merge_conflicts.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a side, then resolve again.'**
  String get failureChooseASideThenResolveAgain;

  /// Operator-facing failure from lib/core/db/tables/merge_conflicts.dart.
  ///
  /// In en, this message translates to:
  /// **'That conflict is no longer on this device.'**
  String get failureThatConflictIsNoLongerOnThis;

  /// Operator-facing failure from lib/core/db/tables/processing.dart.
  ///
  /// In en, this message translates to:
  /// **'That job is no longer on this device.'**
  String get failureThatJobIsNoLongerOnThis;

  /// Operator-facing failure from lib/core/db/tables/processing.dart.
  ///
  /// In en, this message translates to:
  /// **'Refresh the queue and try again.'**
  String get failureRefreshTheQueueAndTryAgain;

  /// Operator-facing failure from lib/core/db/tables/processing.dart.
  ///
  /// In en, this message translates to:
  /// **'A stored provider response cannot be changed.'**
  String get failureAStoredProviderResponseCannotBeChanged;

  /// Operator-facing failure from lib/core/db/tables/processing.dart.
  ///
  /// In en, this message translates to:
  /// **'Leave the original result and write a new one.'**
  String get failureLeaveTheOriginalResultAndWriteA;

  /// Operator-facing failure from lib/core/db/tables/processing.dart.
  ///
  /// In en, this message translates to:
  /// **'A request summary cannot include a secret.'**
  String get failureARequestSummaryCannotIncludeASecret;

  /// Operator-facing failure from lib/core/db/tables/processing.dart.
  ///
  /// In en, this message translates to:
  /// **'Store shape and size only, then save again.'**
  String get failureStoreShapeAndSizeOnlyThenSave;

  /// Operator-facing failure from lib/core/db/tables/projects.dart.
  ///
  /// In en, this message translates to:
  /// **'The project settings could not be read.'**
  String get failureTheProjectSettingsCouldNotBeRead;

  /// Operator-facing failure from lib/core/db/tables/projects.dart.
  ///
  /// In en, this message translates to:
  /// **'Change the settings again, then save.'**
  String get failureChangeTheSettingsAgainThenSave;

  /// Operator-facing failure from lib/core/db/tables/projects.dart.
  ///
  /// In en, this message translates to:
  /// **'The project settings are not in a form Tapture can store.'**
  String get failureTheProjectSettingsAreNotInA;

  /// Operator-facing failure from lib/core/db/tables/records.dart.
  ///
  /// In en, this message translates to:
  /// **'That record is no longer on this device.'**
  String get failureThatRecordIsNoLongerOnThis;

  /// Operator-facing failure from lib/core/db/tables/records.dart.
  ///
  /// In en, this message translates to:
  /// **'The record\'\'s context could not be read.'**
  String get failureTheRecordSContextCouldNotBe;

  /// Operator-facing failure from lib/core/db/tables/records.dart.
  ///
  /// In en, this message translates to:
  /// **'Fix the context object and save again.'**
  String get failureFixTheContextObjectAndSaveAgain;

  /// Operator-facing failure from lib/core/db/tables/records.dart.
  ///
  /// In en, this message translates to:
  /// **'The record\'\'s context is not in a form Tapture can store.'**
  String get failureTheRecordSContextIsNotIn;

  /// Operator-facing failure from lib/core/db/tables/record_fields.dart.
  ///
  /// In en, this message translates to:
  /// **'That value is no longer on this device.'**
  String get failureThatValueIsNoLongerOnThis;

  /// Operator-facing failure from lib/core/db/tables/record_fields.dart.
  ///
  /// In en, this message translates to:
  /// **'Refresh the record and try again.'**
  String get failureRefreshTheRecordAndTryAgain;

  /// Operator-facing failure from lib/core/db/tables/record_fields.dart.
  ///
  /// In en, this message translates to:
  /// **'The original value cannot be changed.'**
  String get failureTheOriginalValueCannotBeChanged;

  /// Operator-facing failure from lib/core/db/tables/record_fields.dart.
  ///
  /// In en, this message translates to:
  /// **'Leave the captured value and write a refined one.'**
  String get failureLeaveTheCapturedValueAndWriteA;

  /// Operator-facing failure from lib/core/db/tables/reference.dart.
  ///
  /// In en, this message translates to:
  /// **'A dataset import needs a source file and a scope.'**
  String get failureADatasetImportNeedsASourceFile;

  /// Operator-facing failure from lib/core/db/tables/reference.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose the file and where it belongs, then import again.'**
  String get failureChooseTheFileAndWhereItBelongs;

  /// Operator-facing failure from lib/core/db/tables/reference.dart.
  ///
  /// In en, this message translates to:
  /// **'A project dataset needs a project.'**
  String get failureAProjectDatasetNeedsAProject;

  /// Operator-facing failure from lib/core/db/tables/reference.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose the project, then import again.'**
  String get failureChooseTheProjectThenImportAgain;

  /// Operator-facing failure from lib/core/db/tables/reference.dart.
  ///
  /// In en, this message translates to:
  /// **'A global dataset cannot belong to one project.'**
  String get failureAGlobalDatasetCannotBelongToOne;

  /// Operator-facing failure from lib/core/db/tables/reference.dart.
  ///
  /// In en, this message translates to:
  /// **'Clear the project, then import again.'**
  String get failureClearTheProjectThenImportAgain;

  /// Operator-facing failure from lib/core/db/tables/reference.dart.
  ///
  /// In en, this message translates to:
  /// **'The dataset columns are not in a form Tapture can store.'**
  String get failureTheDatasetColumnsAreNotInA;

  /// Operator-facing failure from lib/core/db/tables/reference.dart.
  ///
  /// In en, this message translates to:
  /// **'Fix the column list and save again.'**
  String get failureFixTheColumnListAndSaveAgain;

  /// Operator-facing failure from lib/core/db/tables/reference.dart.
  ///
  /// In en, this message translates to:
  /// **'A reference row is not in a form Tapture can store.'**
  String get failureAReferenceRowIsNotInA;

  /// Operator-facing failure from lib/core/db/tables/reference.dart.
  ///
  /// In en, this message translates to:
  /// **'Fix the row values and save again.'**
  String get failureFixTheRowValuesAndSaveAgain;

  /// Operator-facing failure from lib/core/db/tables/template_fields.dart.
  ///
  /// In en, this message translates to:
  /// **'That entry is not in a form Tapture can store.'**
  String get failureThatEntryIsNotInAForm;

  /// Operator-facing failure from lib/core/db/tables/variances.dart.
  ///
  /// In en, this message translates to:
  /// **'A resolution needs an operator.'**
  String get failureAResolutionNeedsAnOperator;

  /// Operator-facing failure from lib/core/db/tables/variances.dart.
  ///
  /// In en, this message translates to:
  /// **'Sign in, then resolve the variance again.'**
  String get failureSignInThenResolveTheVarianceAgain;

  /// Operator-facing failure from lib/core/db/tables/variances.dart.
  ///
  /// In en, this message translates to:
  /// **'That variance is no longer on this device.'**
  String get failureThatVarianceIsNoLongerOnThis;

  /// Operator-facing failure from lib/core/db/transactions.dart.
  ///
  /// In en, this message translates to:
  /// **'The database is busy.'**
  String get failureTheDatabaseIsBusy;

  /// Operator-facing failure from lib/core/db/transactions.dart.
  ///
  /// In en, this message translates to:
  /// **'Wait a moment, then try the save again.'**
  String get failureWaitAMomentThenTryTheSave;

  /// Operator-facing failure from lib/core/db/transactions.dart.
  ///
  /// In en, this message translates to:
  /// **'A record with that identity already exists.'**
  String get failureARecordWithThatIdentityAlreadyExists;

  /// Operator-facing failure from lib/core/db/transactions.dart.
  ///
  /// In en, this message translates to:
  /// **'Open the existing record, or change the identity.'**
  String get failureOpenTheExistingRecordOrChangeThe;

  /// Operator-facing failure from lib/core/export/face_blur.dart.
  ///
  /// In en, this message translates to:
  /// **'That photo could not be blurred.'**
  String get failureThatPhotoCouldNotBeBlurred;

  /// Operator-facing failure from lib/core/export/face_blur.dart.
  ///
  /// In en, this message translates to:
  /// **'A detected face is outside that photo.'**
  String get failureADetectedFaceIsOutsideThatPhoto;

  /// Operator-facing failure from lib/core/export/face_detector.dart.
  ///
  /// In en, this message translates to:
  /// **'Face detection is unavailable on this device.'**
  String get failureFaceDetectionIsUnavailableOnThisDevice;

  /// Operator-facing failure from lib/core/export/face_detector.dart.
  ///
  /// In en, this message translates to:
  /// **'Use an Android or iOS device to blur faces.'**
  String get failureUseAnAndroidOrIOSDeviceTo;

  /// Operator-facing failure from lib/core/export/face_detector.dart.
  ///
  /// In en, this message translates to:
  /// **'This photo cannot be checked for faces.'**
  String get failureThisPhotoCannotBeCheckedForFaces;

  /// Operator-facing failure from lib/core/export/image_redaction.dart.
  ///
  /// In en, this message translates to:
  /// **'This photo cannot be protected.'**
  String get failureThisPhotoCannotBeProtected;

  /// Operator-facing failure from lib/core/export/image_redaction.dart.
  ///
  /// In en, this message translates to:
  /// **'A hidden area is invalid.'**
  String get failureAHiddenAreaIsInvalid;

  /// Operator-facing failure from lib/core/export/text_export_writer_io.dart.
  ///
  /// In en, this message translates to:
  /// **'This export folder already contains completed files.'**
  String get failureThisExportFolderAlreadyContainsCompletedFiles;

  /// Operator-facing failure from lib/core/export/text_export_writer_io.dart.
  ///
  /// In en, this message translates to:
  /// **'Create the export in a new version folder.'**
  String get failureCreateTheExportInANewVersion;

  /// Operator-facing failure from lib/core/export/text_export_writer_stub.dart.
  ///
  /// In en, this message translates to:
  /// **'Streaming text export needs native storage.'**
  String get failureStreamingTextExportNeedsNativeStorage;

  /// Operator-facing failure from lib/core/files/blob_file_writer.dart.
  ///
  /// In en, this message translates to:
  /// **'Tapture cannot copy a file from this device here.'**
  String get failureTaptureCannotCopyAFileFromThis;

  /// Operator-facing failure from lib/core/files/blob_file_writer.dart.
  ///
  /// In en, this message translates to:
  /// **'Add the file again from Tapture, then try again.'**
  String get failureAddTheFileAgainFromTaptureThen;

  /// Operator-facing failure from lib/core/files/blob_file_writer.dart.
  ///
  /// In en, this message translates to:
  /// **'Tapture could not write to {value0}.'**
  String failureTaptureCouldNotWriteToValue(String value0);

  /// Operator-facing failure from lib/core/files/blob_store.dart.
  ///
  /// In en, this message translates to:
  /// **'Tapture could not name that stored file.'**
  String get failureTaptureCouldNotNameThatStoredFile;

  /// Operator-facing failure from lib/core/files/blob_store.dart.
  ///
  /// In en, this message translates to:
  /// **'Try again. If it keeps happening, export the log.'**
  String get failureTryAgainIfItKeepsHappeningExport;

  /// Operator-facing failure from lib/core/files/blob_store.dart.
  ///
  /// In en, this message translates to:
  /// **'Tapture could not save that on this device.'**
  String get failureTaptureCouldNotSaveThatOnThis;

  /// Operator-facing failure from lib/core/files/blob_store.dart.
  ///
  /// In en, this message translates to:
  /// **'Free some space, then try again.'**
  String get failureFreeSomeSpaceThenTryAgain;

  /// Operator-facing failure from lib/core/files/cache_cleanup.dart.
  ///
  /// In en, this message translates to:
  /// **'The cache could not be cleaned on this device.'**
  String get failureTheCacheCouldNotBeCleanedOn;

  /// Operator-facing failure from lib/core/files/cache_cleanup.dart.
  ///
  /// In en, this message translates to:
  /// **'Free space or allow storage access, then try again.'**
  String get failureFreeSpaceOrAllowStorageAccessThen;

  /// Operator-facing failure from lib/core/files/compressed_copy.dart.
  ///
  /// In en, this message translates to:
  /// **'That image size is not valid.'**
  String get failureThatImageSizeIsNotValid;

  /// Operator-facing failure from lib/core/files/compressed_copy.dart.
  ///
  /// In en, this message translates to:
  /// **'Use the app upload size and try again.'**
  String get failureUseTheAppUploadSizeAndTry;

  /// Operator-facing failure from lib/core/files/compressed_copy.dart.
  ///
  /// In en, this message translates to:
  /// **'The reduced copy could not be created on this device.'**
  String get failureTheReducedCopyCouldNotBeCreated;

  /// Operator-facing failure from lib/core/files/compressed_copy.dart.
  ///
  /// In en, this message translates to:
  /// **'Tapture could not find {value0}.'**
  String failureTaptureCouldNotFindValue(String value0);

  /// Operator-facing failure from lib/core/files/download_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Tapture could not save {value0}.'**
  String failureTaptureCouldNotSaveValue(String value0);

  /// Operator-facing failure from lib/core/files/download_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Free some space, then download again.'**
  String get failureFreeSomeSpaceThenDownloadAgain;

  /// Operator-facing failure from lib/core/files/download_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Open Downloads on this device and look in Tapture.'**
  String get failureOpenDownloadsOnThisDeviceAndLook;

  /// Operator-facing failure from lib/core/files/evidence_purge.dart.
  ///
  /// In en, this message translates to:
  /// **'Only files inside a project folder can be removed for good.'**
  String get failureOnlyFilesInsideAProjectFolderCan;

  /// Operator-facing failure from lib/core/files/evidence_purge.dart.
  ///
  /// In en, this message translates to:
  /// **'Leave the file in place; the purge will skip it.'**
  String get failureLeaveTheFileInPlaceThePurge;

  /// Operator-facing failure from lib/core/files/evidence_purge.dart.
  ///
  /// In en, this message translates to:
  /// **'That photo has no usable name for its cached copies.'**
  String get failureThatPhotoHasNoUsableNameFor;

  /// Operator-facing failure from lib/core/files/evidence_purge.dart.
  ///
  /// In en, this message translates to:
  /// **'Leave the photo in place; the purge will skip it.'**
  String get failureLeaveThePhotoInPlaceThePurge;

  /// Operator-facing failure from lib/core/files/evidence_purge_io.dart.
  ///
  /// In en, this message translates to:
  /// **'A deleted record’s files could not be removed from this device.'**
  String get failureADeletedRecordSFilesCouldNot;

  /// Operator-facing failure from lib/core/files/evidence_purge_io.dart.
  ///
  /// In en, this message translates to:
  /// **'Allow storage access; the purge tries again next launch.'**
  String get failureAllowStorageAccessThePurgeTriesAgain;

  /// Operator-facing failure from lib/core/files/export_archive.dart.
  ///
  /// In en, this message translates to:
  /// **'This export is too large for this browser.'**
  String get failureThisExportIsTooLargeForThis;

  /// Operator-facing failure from lib/core/files/export_archive.dart.
  ///
  /// In en, this message translates to:
  /// **'Export fewer records or use a desktop device.'**
  String get failureExportFewerRecordsOrUseADesktop;

  /// Operator-facing failure from lib/core/files/export_archive_io.dart.
  ///
  /// In en, this message translates to:
  /// **'An export source is missing: {value0}'**
  String failureAnExportSourceIsMissingValue(String value0);

  /// Operator-facing failure from lib/core/files/export_archive_stub.dart.
  ///
  /// In en, this message translates to:
  /// **'A native file system is unavailable.'**
  String get failureANativeFileSystemIsUnavailable;

  /// Operator-facing failure from lib/core/files/file_reader.dart.
  ///
  /// In en, this message translates to:
  /// **'Tapture could not read {value0}.'**
  String failureTaptureCouldNotReadValue(String value0);

  /// Operator-facing failure from lib/core/files/file_reader.dart.
  ///
  /// In en, this message translates to:
  /// **'Capture or add the file again, then try again.'**
  String get failureCaptureOrAddTheFileAgainThen;

  /// Operator-facing failure from lib/core/files/file_relocation.dart.
  ///
  /// In en, this message translates to:
  /// **'That project is no longer on this device.'**
  String get failureThatProjectIsNoLongerOnThis;

  /// Operator-facing failure from lib/core/files/file_relocation.dart.
  ///
  /// In en, this message translates to:
  /// **'Open a project, then try again.'**
  String get failureOpenAProjectThenTryAgain;

  /// Operator-facing failure from lib/core/files/file_relocation.dart.
  ///
  /// In en, this message translates to:
  /// **'Recreate the project folder, then try again.'**
  String get failureRecreateTheProjectFolderThenTryAgain;

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'The file {value0} is empty.'**
  String failureTheFileValueIsEmpty(String value0);

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a file that has contents and try again.'**
  String get failureChooseAFileThatHasContentsAnd;

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'The file {value0} is not a supported type.'**
  String failureTheFileValueIsNotASupported(String value0);

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose an image, document, spreadsheet, audio file or bundle and try again.'**
  String get failureChooseAnImageDocumentSpreadsheetAudioFile;

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'The file {value0} does not match its type.'**
  String failureTheFileValueDoesNotMatchIts(String value0);

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a file of the expected type and try again.'**
  String get failureChooseAFileOfTheExpectedType;

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'The file {value0} is larger than the allowed size for a {value1}.'**
  String failureTheFileValueIsLargerThanThe(String value0, String value1);

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a smaller file and try again.'**
  String get failureChooseASmallerFileAndTryAgain;

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'The archive {value0} contains a path that leaves the folder.'**
  String failureTheArchiveValueContainsAPathThat(String value0);

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a different file and try again.'**
  String get failureChooseADifferentFileAndTryAgain;

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'The archive {value0} contains a link instead of a file.'**
  String failureTheArchiveValueContainsALinkInstead(String value0);

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'The archive {value0} declares more uncompressed data than is allowed.'**
  String failureTheArchiveValueDeclaresMoreUncompressedData(String value0);

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'The file {value0} is not an archive.'**
  String failureTheFileValueIsNotAnArchive(String value0);

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a ZIP bundle or spreadsheet and try again.'**
  String get failureChooseAZIPBundleOrSpreadsheetAnd;

  /// Operator-facing failure from lib/core/files/file_validation.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose the file again, then try again.'**
  String get failureChooseTheFileAgainThenTryAgain;

  /// Operator-facing failure from lib/core/files/file_writer_io.dart.
  ///
  /// In en, this message translates to:
  /// **'The photo could not be saved on this device.'**
  String get failureThePhotoCouldNotBeSavedOn;

  /// Operator-facing failure from lib/core/files/file_writer_io.dart.
  ///
  /// In en, this message translates to:
  /// **'There is not enough space to save {value0}.'**
  String failureThereIsNotEnoughSpaceToSave(String value0);

  /// Operator-facing failure from lib/core/files/file_writer_io.dart.
  ///
  /// In en, this message translates to:
  /// **'Allow storage access, then try again.'**
  String get failureAllowStorageAccessThenTryAgain;

  /// Operator-facing failure from lib/core/files/image_resize.dart.
  ///
  /// In en, this message translates to:
  /// **'This photo cannot be marked.'**
  String get failureThisPhotoCannotBeMarked;

  /// Operator-facing failure from lib/core/files/incoming_bundle_service_io.dart.
  ///
  /// In en, this message translates to:
  /// **'This package is too large or incomplete.'**
  String get failureThisPackageIsTooLargeOrIncomplete;

  /// Operator-facing failure from lib/core/files/incoming_bundle_service_io.dart.
  ///
  /// In en, this message translates to:
  /// **'Finish the current package before opening another.'**
  String get failureFinishTheCurrentPackageBeforeOpeningAnother;

  /// Operator-facing failure from lib/core/files/incoming_bundle_service_io.dart.
  ///
  /// In en, this message translates to:
  /// **'This package is too large to open.'**
  String get failureThisPackageIsTooLargeToOpen;

  /// Operator-facing failure from lib/core/files/incoming_bundle_service_io.dart.
  ///
  /// In en, this message translates to:
  /// **'This package could not be opened.'**
  String get failureThisPackageCouldNotBeOpened;

  /// Operator-facing failure from lib/core/files/incoming_bundle_service_io.dart.
  ///
  /// In en, this message translates to:
  /// **'Open the file again from its original location.'**
  String get failureOpenTheFileAgainFromItsOriginal;

  /// Operator-facing failure from lib/core/files/orphan_scanner.dart.
  ///
  /// In en, this message translates to:
  /// **'That project could not be scanned.'**
  String get failureThatProjectCouldNotBeScanned;

  /// Operator-facing failure from lib/core/files/orphan_scanner.dart.
  ///
  /// In en, this message translates to:
  /// **'Open the project and try again.'**
  String get failureOpenTheProjectAndTryAgain;

  /// Operator-facing failure from lib/core/files/orphan_scanner.dart.
  ///
  /// In en, this message translates to:
  /// **'The project folder could not be scanned on this device.'**
  String get failureTheProjectFolderCouldNotBeScanned;

  /// Operator-facing failure from lib/core/files/orphan_scanner.dart.
  ///
  /// In en, this message translates to:
  /// **'Put the file back in the project folder, then try again.'**
  String get failurePutTheFileBackInTheProject;

  /// Operator-facing failure from lib/core/files/orphan_scanner.dart.
  ///
  /// In en, this message translates to:
  /// **'The file could not be adopted on this device.'**
  String get failureTheFileCouldNotBeAdoptedOn;

  /// Operator-facing failure from lib/core/files/orphan_scanner.dart.
  ///
  /// In en, this message translates to:
  /// **'The missing file could not be flagged on this device.'**
  String get failureTheMissingFileCouldNotBeFlagged;

  /// Operator-facing failure from lib/core/files/orphan_scanner.dart.
  ///
  /// In en, this message translates to:
  /// **'That file row is no longer on this device.'**
  String get failureThatFileRowIsNoLongerOn;

  /// Operator-facing failure from lib/core/files/path_sanitizer.dart.
  ///
  /// In en, this message translates to:
  /// **'That name is not a valid folder.'**
  String get failureThatNameIsNotAValidFolder;

  /// Operator-facing failure from lib/core/files/path_sanitizer.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a name without slashes that point elsewhere.'**
  String get failureChooseANameWithoutSlashesThatPoint;

  /// Operator-facing failure from lib/core/files/path_sanitizer.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a name with letters or digits.'**
  String get failureChooseANameWithLettersOrDigits;

  /// Operator-facing failure from lib/core/files/path_sanitizer.dart.
  ///
  /// In en, this message translates to:
  /// **'The file path must stay inside the storage folder.'**
  String get failureTheFilePathMustStayInsideThe2;

  /// Operator-facing failure from lib/core/files/photo_privacy_service.dart.
  ///
  /// In en, this message translates to:
  /// **'That photo is no longer available.'**
  String get failureThatPhotoIsNoLongerAvailable;

  /// Operator-facing failure from lib/core/files/photo_privacy_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Hidden areas changed. Try sending again.'**
  String get failureHiddenAreasChangedTrySendingAgain;

  /// Operator-facing failure from lib/core/files/photo_privacy_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Check the hidden areas on this edited photo before sending it.'**
  String get failureCheckTheHiddenAreasOnThisEdited;

  /// Operator-facing failure from lib/core/files/photo_privacy_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Open Hide parts before sending and save the areas for this version.'**
  String get failureOpenHidePartsBeforeSendingAndSave;

  /// Operator-facing failure from lib/core/files/project_folders.dart.
  ///
  /// In en, this message translates to:
  /// **'The project folder could not be removed from this device.'**
  String get failureTheProjectFolderCouldNotBeRemoved;

  /// Operator-facing failure from lib/core/files/project_folders.dart.
  ///
  /// In en, this message translates to:
  /// **'Delete the leftover folder, then try again.'**
  String get failureDeleteTheLeftoverFolderThenTryAgain;

  /// Operator-facing failure from lib/core/files/project_folders.dart.
  ///
  /// In en, this message translates to:
  /// **'That project is already in the recycle area on this device.'**
  String get failureThatProjectIsAlreadyInTheRecycle;

  /// Operator-facing failure from lib/core/files/project_folders.dart.
  ///
  /// In en, this message translates to:
  /// **'Restore it from the recycle area, then try again.'**
  String get failureRestoreItFromTheRecycleAreaThen;

  /// Operator-facing failure from lib/core/files/project_folders.dart.
  ///
  /// In en, this message translates to:
  /// **'The project folder could not be moved to the recycle area.'**
  String get failureTheProjectFolderCouldNotBeMoved;

  /// Operator-facing failure from lib/core/files/project_folders.dart.
  ///
  /// In en, this message translates to:
  /// **'This project has no folder on disk yet.'**
  String get failureThisProjectHasNoFolderOnDisk;

  /// Operator-facing failure from lib/core/files/project_folders.dart.
  ///
  /// In en, this message translates to:
  /// **'Create the project folder, then try again.'**
  String get failureCreateTheProjectFolderThenTryAgain;

  /// Operator-facing failure from lib/core/files/project_folders.dart.
  ///
  /// In en, this message translates to:
  /// **'The project folder could not be created on this device.'**
  String get failureTheProjectFolderCouldNotBeCreated;

  /// Operator-facing failure from lib/core/files/project_folders.dart.
  ///
  /// In en, this message translates to:
  /// **'That project folder name is not a valid folder.'**
  String get failureThatProjectFolderNameIsNotA;

  /// Operator-facing failure from lib/core/files/project_folders.dart.
  ///
  /// In en, this message translates to:
  /// **'Recreate the project so its folder can be rebuilt.'**
  String get failureRecreateTheProjectSoItsFolderCan;

  /// Operator-facing failure from lib/core/files/storage_guard.dart.
  ///
  /// In en, this message translates to:
  /// **'There is not enough free space to take another photo.'**
  String get failureThereIsNotEnoughFreeSpaceTo;

  /// Operator-facing failure from lib/core/files/storage_guard.dart.
  ///
  /// In en, this message translates to:
  /// **'Export a project or clean the cache, then try again.'**
  String get failureExportAProjectOrCleanTheCache;

  /// Operator-facing failure from lib/core/files/storage_guard.dart.
  ///
  /// In en, this message translates to:
  /// **'Tapture could not read free space on this device.'**
  String get failureTaptureCouldNotReadFreeSpaceOn;

  /// Operator-facing failure from lib/core/files/storage_root.dart.
  ///
  /// In en, this message translates to:
  /// **'This device has no folder Tapture can keep project files in.'**
  String get failureThisDeviceHasNoFolderTaptureCan;

  /// Operator-facing failure from lib/core/files/storage_root.dart.
  ///
  /// In en, this message translates to:
  /// **'Use Tapture on a phone, tablet or computer to keep files.'**
  String get failureUseTaptureOnAPhoneTabletOr;

  /// Operator-facing failure from lib/core/files/thumbnail_cache.dart.
  ///
  /// In en, this message translates to:
  /// **'The thumbnail could not be created on this device.'**
  String get failureTheThumbnailCouldNotBeCreatedOn;

  /// Operator-facing failure from lib/core/files/thumbnail_cache.dart.
  ///
  /// In en, this message translates to:
  /// **'That thumbnail size is not valid.'**
  String get failureThatThumbnailSizeIsNotValid;

  /// Operator-facing failure from lib/core/files/thumbnail_cache.dart.
  ///
  /// In en, this message translates to:
  /// **'Use the app thumbnail size and try again.'**
  String get failureUseTheAppThumbnailSizeAndTry;

  /// Operator-facing failure from lib/core/files/thumbnail_cache.dart.
  ///
  /// In en, this message translates to:
  /// **'That photo could not be cached.'**
  String get failureThatPhotoCouldNotBeCached;

  /// Operator-facing failure from lib/core/permissions/permissions_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Location is off for this project.'**
  String get failureLocationIsOffForThisProject;

  /// Operator-facing failure from lib/core/permissions/permissions_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Turn GPS on, then try again.'**
  String get failureTurnGPSOnThenTryAgain;

  /// Operator-facing failure from lib/core/security/biometric_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is unavailable.'**
  String get failureBiometricAuthenticationIsUnavailable;

  /// Operator-facing failure from lib/core/security/biometric_service.dart.
  ///
  /// In en, this message translates to:
  /// **'Unlock with your app PIN.'**
  String get failureUnlockWithYourAppPIN;

  /// Operator-facing failure from lib/core/security/secure_storage.dart.
  ///
  /// In en, this message translates to:
  /// **'The secret could not be saved on this device.'**
  String get failureTheSecretCouldNotBeSavedOn;

  /// Operator-facing failure from lib/core/security/secure_storage.dart.
  ///
  /// In en, this message translates to:
  /// **'The secret could not be read on this device.'**
  String get failureTheSecretCouldNotBeReadOn;

  /// Operator-facing failure from lib/core/security/secure_storage.dart.
  ///
  /// In en, this message translates to:
  /// **'The secret could not be removed from this device.'**
  String get failureTheSecretCouldNotBeRemovedFrom;

  /// Operator-facing failure from lib/core/widgets/photo_markup.dart.
  ///
  /// In en, this message translates to:
  /// **'Type the words to place on this photo.'**
  String get failureTypeTheWordsToPlaceOnThis;

  /// Operator-facing failure from lib/core/widgets/photo_markup.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter text, then save the photo.'**
  String get failureEnterTextThenSaveThePhoto;

  /// Operator-facing failure from lib/features/capture/data/capture_persistence_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Discard the interrupted session and start again.'**
  String get failureDiscardTheInterruptedSessionAndStartAgain;

  /// Operator-facing failure from lib/features/capture/data/capture_record_writer.dart.
  ///
  /// In en, this message translates to:
  /// **'Only a record edit can be saved here.'**
  String get failureOnlyARecordEditCanBeSaved;

  /// Operator-facing failure from lib/features/capture/data/capture_record_writer.dart.
  ///
  /// In en, this message translates to:
  /// **'Go back to the project and pick another record.'**
  String get failureGoBackToTheProjectAndPick;

  /// Operator-facing failure from lib/features/capture/data/drift_capture_persistence.dart.
  ///
  /// In en, this message translates to:
  /// **'The capture session is not valid.'**
  String get failureTheCaptureSessionIsNotValid;

  /// Operator-facing failure from lib/features/capture/data/drift_photo_repository.dart.
  ///
  /// In en, this message translates to:
  /// **'Complete photo metadata is required for a new capture.'**
  String get failureCompletePhotoMetadataIsRequiredForA;

  /// Operator-facing failure from lib/features/capture/data/drift_photo_repository.dart.
  ///
  /// In en, this message translates to:
  /// **'The photo project was not found.'**
  String get failureThePhotoProjectWasNotFound;

  /// Operator-facing failure from lib/features/capture/data/drift_photo_repository.dart.
  ///
  /// In en, this message translates to:
  /// **'That photo could not be read from this device.'**
  String get failureThatPhotoCouldNotBeReadFrom;

  /// Operator-facing failure from lib/features/capture/data/drift_photo_repository.dart.
  ///
  /// In en, this message translates to:
  /// **'The original photo stays in place.'**
  String get failureTheOriginalPhotoStaysInPlace;

  /// Operator-facing failure from lib/features/capture/data/drift_photo_repository.dart.
  ///
  /// In en, this message translates to:
  /// **'Revert an edited photo instead.'**
  String get failureRevertAnEditedPhotoInstead;

  /// Operator-facing failure from lib/features/capture/domain/photo_derivation.dart.
  ///
  /// In en, this message translates to:
  /// **'This photo appears more than once.'**
  String get failureThisPhotoAppearsMoreThanOnce;

  /// Operator-facing failure from lib/features/capture/domain/photo_derivation.dart.
  ///
  /// In en, this message translates to:
  /// **'Reload the capture and try again.'**
  String get failureReloadTheCaptureAndTryAgain;

  /// Operator-facing failure from lib/features/capture/domain/photo_derivation.dart.
  ///
  /// In en, this message translates to:
  /// **'An edited photo is missing its original.'**
  String get failureAnEditedPhotoIsMissingItsOriginal;

  /// Operator-facing failure from lib/features/capture/domain/photo_derivation.dart.
  ///
  /// In en, this message translates to:
  /// **'Keep this capture and restore the original photo.'**
  String get failureKeepThisCaptureAndRestoreTheOriginal;

  /// Operator-facing failure from lib/features/capture/domain/photo_derivation.dart.
  ///
  /// In en, this message translates to:
  /// **'These photo edits loop back on themselves.'**
  String get failureThesePhotoEditsLoopBackOnThemselves;

  /// Operator-facing failure from lib/features/context/data/context_record_writer.dart.
  ///
  /// In en, this message translates to:
  /// **'That field is not on this record.'**
  String get failureThatFieldIsNotOnThisRecord;

  /// Operator-facing failure from lib/features/context/data/context_record_writer.dart.
  ///
  /// In en, this message translates to:
  /// **'Open the record and try again.'**
  String get failureOpenTheRecordAndTryAgain;

  /// Operator-facing failure from lib/features/context/data/context_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'That field is not a context level.'**
  String get failureThatFieldIsNotAContextLevel;

  /// Operator-facing failure from lib/features/context/data/context_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Pick a level from the hierarchy and try again.'**
  String get failurePickALevelFromTheHierarchyAnd;

  /// Operator-facing failure from lib/features/context/data/context_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'A preset needs a name.'**
  String get failureAPresetNeedsAName;

  /// Operator-facing failure from lib/features/context/data/context_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter a name and try again.'**
  String get failureEnterANameAndTryAgain;

  /// Operator-facing failure from lib/features/context/data/context_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'A delete needs an id and a reason.'**
  String get failureADeleteNeedsAnIdAndA;

  /// Operator-facing failure from lib/features/context/data/context_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Context is not available yet.'**
  String get failureContextIsNotAvailableYet;

  /// Operator-facing failure from lib/features/context/data/context_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Restart the app and try again.'**
  String get failureRestartTheAppAndTryAgain;

  /// Operator-facing failure from lib/features/context/domain/context_repository.dart.
  ///
  /// In en, this message translates to:
  /// **'A preset with that name already exists.'**
  String get failureAPresetWithThatNameAlreadyExists;

  /// Operator-facing failure from lib/features/context/domain/context_repository.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose another name, or confirm overwrite.'**
  String get failureChooseAnotherNameOrConfirmOverwrite;

  /// Operator-facing failure from lib/features/exports/data/deliverable_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'The project was not found.'**
  String get failureTheProjectWasNotFound;

  /// Operator-facing failure from lib/features/exports/data/export_privacy.dart.
  ///
  /// In en, this message translates to:
  /// **'An exported record is no longer available.'**
  String get failureAnExportedRecordIsNoLongerAvailable;

  /// Operator-facing failure from lib/features/exports/data/export_privacy.dart.
  ///
  /// In en, this message translates to:
  /// **'An exported photo is no longer available.'**
  String get failureAnExportedPhotoIsNoLongerAvailable;

  /// Operator-facing failure from lib/features/exports/data/export_record_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A selected record is missing. Refresh the export.'**
  String get failureASelectedRecordIsMissingRefreshThe;

  /// Operator-facing failure from lib/features/exports/data/export_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'An export needs a project.'**
  String get failureAnExportNeedsAProject;

  /// Operator-facing failure from lib/features/exports/data/export_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Open a project and export again.'**
  String get failureOpenAProjectAndExportAgain;

  /// Operator-facing failure from lib/features/exports/data/export_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'This exported photo cannot be read.'**
  String get failureThisExportedPhotoCannotBeRead;

  /// Operator-facing failure from lib/features/exports/data/export_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'This photo format cannot be packaged safely.'**
  String get failureThisPhotoFormatCannotBePackagedSafely;

  /// Operator-facing failure from lib/features/exports/presentation/export_workflow_controller.dart.
  ///
  /// In en, this message translates to:
  /// **'Project files are unavailable on this device.'**
  String get failureProjectFilesAreUnavailableOnThisDevice;

  /// Operator-facing failure from lib/features/exports/presentation/export_workflow_controller.dart.
  ///
  /// In en, this message translates to:
  /// **'Open a project stored on this device and try again.'**
  String get failureOpenAProjectStoredOnThisDevice;

  /// Operator-facing failure from lib/features/feedback/data/feedback_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Write your feedback, then save again.'**
  String get failureWriteYourFeedbackThenSaveAgain;

  /// Operator-facing failure from lib/features/feedback/data/feedback_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Name the type, then save again.'**
  String get failureNameTheTypeThenSaveAgain;

  /// Operator-facing failure from lib/features/feedback/presentation/download_feedback_controller.dart.
  ///
  /// In en, this message translates to:
  /// **'Change or clear the filters, then try again.'**
  String get failureChangeOrClearTheFiltersThenTry;

  /// Operator-facing failure from lib/features/feedback/presentation/give_feedback_controller.dart.
  ///
  /// In en, this message translates to:
  /// **'Close this, tap Feedback, then try again.'**
  String get failureCloseThisTapFeedbackThenTryAgain;

  /// Operator-facing failure from lib/features/feedback/presentation/give_feedback_controller.dart.
  ///
  /// In en, this message translates to:
  /// **'Correct the highlighted field and save again.'**
  String get failureCorrectTheHighlightedFieldAndSaveAgain;

  /// Operator-facing failure from lib/features/import/data/record_import_store_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'The template these rows were matched to is no longer here.'**
  String get failureTheTemplateTheseRowsWereMatchedTo;

  /// Operator-facing failure from lib/features/import/data/record_import_store_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose another template and import again.'**
  String get failureChooseAnotherTemplateAndImportAgain;

  /// Operator-facing failure from lib/features/import/data/record_import_store_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'A record a row matched is no longer on this device.'**
  String get failureARecordARowMatchedIsNo;

  /// Operator-facing failure from lib/features/import/data/record_import_store_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Import the file again to match it afresh.'**
  String get failureImportTheFileAgainToMatchIt;

  /// Operator-facing failure from lib/features/import/data/record_import_store_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Records cannot be imported right now.'**
  String get failureRecordsCannotBeImportedRightNow;

  /// Operator-facing failure from lib/features/import/data/record_import_store_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Restart Tapture, then import again.'**
  String get failureRestartTaptureThenImportAgain;

  /// Operator-facing failure from lib/features/meetings/data/meeting_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'That file is not in this meeting’s project folder.'**
  String get failureThatFileIsNotInThisMeeting;

  /// Operator-facing failure from lib/features/meetings/data/meeting_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Add the file to the meeting again.'**
  String get failureAddTheFileToTheMeetingAgain;

  /// Operator-facing failure from lib/features/meetings/data/meeting_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Start the meeting again.'**
  String get failureStartTheMeetingAgain;

  /// Operator-facing failure from lib/features/merge/domain/merge_undo.dart.
  ///
  /// In en, this message translates to:
  /// **'The snapshot has been purged.'**
  String get failureTheSnapshotHasBeenPurged;

  /// Operator-facing failure from lib/features/merge/domain/merge_undo.dart.
  ///
  /// In en, this message translates to:
  /// **'The merge can no longer be undone.'**
  String get failureTheMergeCanNoLongerBeUndone;

  /// Operator-facing failure from lib/features/projects/data/project_openable_file_lookup_io.dart.
  ///
  /// In en, this message translates to:
  /// **'Tapture could not look up a file for this project.'**
  String get failureTaptureCouldNotLookUpAFile;

  /// Operator-facing failure from lib/features/projects/data/project_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'A project with that id already exists.'**
  String get failureAProjectWithThatIdAlreadyExists;

  /// Operator-facing failure from lib/features/projects/data/project_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Open the existing project or use a new id.'**
  String get failureOpenTheExistingProjectOrUseA;

  /// Operator-facing failure from lib/features/projects/data/project_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Project photos cannot be stored on this device.'**
  String get failureProjectPhotosCannotBeStoredOnThis;

  /// Operator-facing failure from lib/features/projects/data/project_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Add the photo on a device that stores files.'**
  String get failureAddThePhotoOnADeviceThat;

  /// Operator-facing failure from lib/features/projects/data/project_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'A project needs a name.'**
  String get failureAProjectNeedsAName;

  /// Operator-facing failure from lib/features/projects/data/project_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter a name and save again.'**
  String get failureEnterANameAndSaveAgain;

  /// Operator-facing failure from lib/features/projects/presentation/project_export_screen.dart.
  ///
  /// In en, this message translates to:
  /// **'Project files are not available on this device.'**
  String get failureProjectFilesAreNotAvailableOnThis;

  /// Operator-facing failure from lib/features/projects/presentation/project_export_screen.dart.
  ///
  /// In en, this message translates to:
  /// **'Export from a device that stores this project.'**
  String get failureExportFromADeviceThatStoresThis;

  /// Operator-facing failure from lib/features/records/data/record_purge_store.dart.
  ///
  /// In en, this message translates to:
  /// **'That record is no longer in the recycle bin.'**
  String get failureThatRecordIsNoLongerInThe;

  /// Operator-facing failure from lib/features/records/data/record_purge_store.dart.
  ///
  /// In en, this message translates to:
  /// **'Nothing to remove; it was restored or already removed.'**
  String get failureNothingToRemoveItWasRestoredOr;

  /// Operator-facing failure from lib/features/records/data/record_purge_store.dart.
  ///
  /// In en, this message translates to:
  /// **'That record was deleted again, so its retention starts over.'**
  String get failureThatRecordWasDeletedAgainSoIts;

  /// Operator-facing failure from lib/features/records/data/record_purge_store.dart.
  ///
  /// In en, this message translates to:
  /// **'Leave it; the purge takes it once its new window passes.'**
  String get failureLeaveItThePurgeTakesItOnce;

  /// Operator-facing failure from lib/features/records/data/record_purge_store.dart.
  ///
  /// In en, this message translates to:
  /// **'A merge still needs that deleted record.'**
  String get failureAMergeStillNeedsThatDeletedRecord;

  /// Operator-facing failure from lib/features/records/data/record_purge_store.dart.
  ///
  /// In en, this message translates to:
  /// **'Send a bundle or settle the merge, then try again.'**
  String get failureSendABundleOrSettleTheMerge;

  /// Operator-facing failure from lib/features/records/data/record_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Records are not available yet.'**
  String get failureRecordsAreNotAvailableYet;

  /// Operator-facing failure from lib/features/records/data/record_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'The record was saved but could not be opened.'**
  String get failureTheRecordWasSavedButCouldNot;

  /// Operator-facing failure from lib/features/records/data/record_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Open it from the records list.'**
  String get failureOpenItFromTheRecordsList;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'That template is no longer on this device.'**
  String get failureThatTemplateIsNoLongerOnThis;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose another template and try again.'**
  String get failureChooseAnotherTemplateAndTryAgain;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'This record already uses that template.'**
  String get failureThisRecordAlreadyUsesThatTemplate;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a different template.'**
  String get failureChooseADifferentTemplate;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'That template belongs to another project.'**
  String get failureThatTemplateBelongsToAnotherProject;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a template from this project.'**
  String get failureChooseATemplateFromThisProject;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'A record needs a project and a template.'**
  String get failureARecordNeedsAProjectAndA;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a project and a template, then save again.'**
  String get failureChooseAProjectAndATemplateThen;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'Say why the record should go, then try again.'**
  String get failureSayWhyTheRecordShouldGoThen;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'An edit needs the field it changes.'**
  String get failureAnEditNeedsTheFieldItChanges;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a field, then save again.'**
  String get failureChooseAFieldThenSaveAgain;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'A record goes to the recycle bin only through delete.'**
  String get failureARecordGoesToTheRecycleBin;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'Use Delete, which lets you undo it.'**
  String get failureUseDeleteWhichLetsYouUndoIt;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'This record is in the recycle bin.'**
  String get failureThisRecordIsInTheRecycleBin;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'Restore it from the recycle bin first.'**
  String get failureRestoreItFromTheRecycleBinFirst;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'This record is not in the recycle bin.'**
  String get failureThisRecordIsNotInTheRecycle;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'Refresh the list; it may already be restored.'**
  String get failureRefreshTheListItMayAlreadyBe;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'This record has a status this version of the app does not know.'**
  String get failureThisRecordHasAStatusThisVersion;

  /// Operator-facing failure from lib/features/records/data/record_writes.dart.
  ///
  /// In en, this message translates to:
  /// **'Update the app, then try again.'**
  String get failureUpdateTheAppThenTryAgain;

  /// Operator-facing failure from lib/features/records/domain/record_lifecycle.dart.
  ///
  /// In en, this message translates to:
  /// **'This record is already {value0}.'**
  String failureThisRecordIsAlreadyValue(String value0);

  /// Operator-facing failure from lib/features/records/domain/record_lifecycle.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a different status, or leave it as it is.'**
  String get failureChooseADifferentStatusOrLeaveIt;

  /// Operator-facing failure from lib/features/records/domain/record_lifecycle.dart.
  ///
  /// In en, this message translates to:
  /// **'A record that is {value0} cannot be {value1}.'**
  String failureARecordThatIsValueCannotBe(String value0, String value1);

  /// Operator-facing failure from lib/features/records/domain/record_lifecycle.dart.
  ///
  /// In en, this message translates to:
  /// **'Restore it from the recycle bin before changing it.'**
  String get failureRestoreItFromTheRecycleBinBefore;

  /// Operator-facing failure from lib/features/records/presentation/record_edit_controller.dart.
  ///
  /// In en, this message translates to:
  /// **'The captured template version is unavailable.'**
  String get failureTheCapturedTemplateVersionIsUnavailable;

  /// Operator-facing failure from lib/features/records/presentation/record_edit_controller.dart.
  ///
  /// In en, this message translates to:
  /// **'Restore the original project package before editing these values.'**
  String get failureRestoreTheOriginalProjectPackageBeforeEditing;

  /// Operator-facing failure from lib/features/reference/data/dataset_csv_import.dart.
  ///
  /// In en, this message translates to:
  /// **'A quoted CSV value is unfinished.'**
  String get failureAQuotedCSVValueIsUnfinished;

  /// Operator-facing failure from lib/features/reference/data/dataset_csv_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Close the quoted value and import the file again.'**
  String get failureCloseTheQuotedValueAndImportThe;

  /// Operator-facing failure from lib/features/reference/data/dataset_csv_import.dart.
  ///
  /// In en, this message translates to:
  /// **'That file is empty.'**
  String get failureThatFileIsEmpty;

  /// Operator-facing failure from lib/features/reference/data/dataset_csv_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a CSV with a header and rows.'**
  String get failureChooseACSVWithAHeaderAnd;

  /// Operator-facing failure from lib/features/reference/data/dataset_csv_import.dart.
  ///
  /// In en, this message translates to:
  /// **'That table could not be read as text.'**
  String get failureThatTableCouldNotBeReadAs;

  /// Operator-facing failure from lib/features/reference/data/dataset_csv_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Save it as UTF-8 CSV and try again.'**
  String get failureSaveItAsUTFCSVAndTry;

  /// Operator-facing failure from lib/features/reference/data/dataset_csv_import.dart.
  ///
  /// In en, this message translates to:
  /// **'That CSV could not be read.'**
  String get failureThatCSVCouldNotBeRead;

  /// Operator-facing failure from lib/features/reference/data/dataset_csv_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Check the file and try again.'**
  String get failureCheckTheFileAndTryAgain;

  /// Operator-facing failure from lib/features/reference/data/dataset_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a CSV, JSON or XLSX table within the import size limit.'**
  String get failureChooseACSVJSONOrXLSXTable;

  /// Operator-facing failure from lib/features/reference/data/dataset_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose another file or split this table into smaller files.'**
  String get failureChooseAnotherFileOrSplitThisTable;

  /// Operator-facing failure from lib/features/reference/data/dataset_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Save it as UTF-8 CSV or a JSON array and try again.'**
  String get failureSaveItAsUTFCSVOrA;

  /// Operator-facing failure from lib/features/reference/data/dataset_json_import.dart.
  ///
  /// In en, this message translates to:
  /// **'JSON datasets must be an array of objects.'**
  String get failureJSONDatasetsMustBeAnArrayOf;

  /// Operator-facing failure from lib/features/reference/data/dataset_json_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Wrap the rows in an array and try again.'**
  String get failureWrapTheRowsInAnArrayAnd;

  /// Operator-facing failure from lib/features/reference/data/dataset_json_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Every JSON row must be an object.'**
  String get failureEveryJSONRowMustBeAnObject;

  /// Operator-facing failure from lib/features/reference/data/dataset_json_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Remove non-object rows and import the file again.'**
  String get failureRemoveNonObjectRowsAndImportThe;

  /// Operator-facing failure from lib/features/reference/data/dataset_json_import.dart.
  ///
  /// In en, this message translates to:
  /// **'That file has no columns.'**
  String get failureThatFileHasNoColumns;

  /// Operator-facing failure from lib/features/reference/data/dataset_json_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Add keys to the objects and try again.'**
  String get failureAddKeysToTheObjectsAndTry;

  /// Operator-facing failure from lib/features/reference/data/dataset_json_import.dart.
  ///
  /// In en, this message translates to:
  /// **'That JSON is not valid.'**
  String get failureThatJSONIsNotValid;

  /// Operator-facing failure from lib/features/reference/data/dataset_json_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Fix the JSON array and import it again.'**
  String get failureFixTheJSONArrayAndImportIt;

  /// Operator-facing failure from lib/features/reference/data/dataset_json_import.dart.
  ///
  /// In en, this message translates to:
  /// **'That JSON could not be read.'**
  String get failureThatJSONCouldNotBeRead;

  /// Operator-facing failure from lib/features/reference/data/dataset_xlsx_import.dart.
  ///
  /// In en, this message translates to:
  /// **'That workbook has no sheets.'**
  String get failureThatWorkbookHasNoSheets;

  /// Operator-facing failure from lib/features/reference/data/dataset_xlsx_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Choose a workbook with a sheet of data.'**
  String get failureChooseAWorkbookWithASheetOf;

  /// Operator-facing failure from lib/features/reference/data/dataset_xlsx_import.dart.
  ///
  /// In en, this message translates to:
  /// **'That sheet has no header row.'**
  String get failureThatSheetHasNoHeaderRow;

  /// Operator-facing failure from lib/features/reference/data/dataset_xlsx_import.dart.
  ///
  /// In en, this message translates to:
  /// **'Add a header row and try again.'**
  String get failureAddAHeaderRowAndTryAgain;

  /// Operator-facing failure from lib/features/reference/data/reference_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'That key column has duplicate values.'**
  String get failureThatKeyColumnHasDuplicateValues;

  /// Operator-facing failure from lib/features/reference/data/reference_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Pick another key column, or confirm duplicates are expected.'**
  String get failurePickAnotherKeyColumnOrConfirmDuplicates;

  /// Operator-facing failure from lib/features/reference/data/reference_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'A row needs a dataset and a key.'**
  String get failureARowNeedsADatasetAndA;

  /// Operator-facing failure from lib/features/reference/data/reference_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Fill those fields and save again.'**
  String get failureFillThoseFieldsAndSaveAgain;

  /// Operator-facing failure from lib/features/reference/data/reference_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'A dataset needs a name and a key column.'**
  String get failureADatasetNeedsANameAndA;

  /// Operator-facing failure from lib/features/reference/data/reference_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'The key column must be one of the dataset columns.'**
  String get failureTheKeyColumnMustBeOneOf;

  /// Operator-facing failure from lib/features/reference/data/reference_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Pick a key from the column list.'**
  String get failurePickAKeyFromTheColumnList;

  /// Operator-facing failure from lib/features/reference/data/reference_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Reference data is not available yet.'**
  String get failureReferenceDataIsNotAvailableYet;

  /// Operator-facing failure from lib/features/reference/domain/dataset_import_draft.dart.
  ///
  /// In en, this message translates to:
  /// **'That table has no data columns.'**
  String get failureThatTableHasNoDataColumns;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A template needs a name.'**
  String get failureATemplateNeedsAName;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'Open a project, then add the template.'**
  String get failureOpenAProjectThenAddTheTemplate;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'The shipped templates could not be read.'**
  String get failureTheShippedTemplatesCouldNotBeRead;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'That shipped template is not on this device.'**
  String get failureThatShippedTemplateIsNotOnThis;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'Pick another template from the library.'**
  String get failurePickAnotherTemplateFromTheLibrary;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'The inherited field groups could not be read.'**
  String get failureTheInheritedFieldGroupsCouldNotBe;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A shipped template is missing \"{value0}\".'**
  String failureAShippedTemplateIsMissingValue(String value0);

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'Reinstall the app, then try again.'**
  String get failureReinstallTheAppThenTryAgain;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A shipped template uses an unknown schema.'**
  String get failureAShippedTemplateUsesAnUnknownSchema;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A shipped template has an invalid key.'**
  String get failureAShippedTemplateHasAnInvalidKey;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A shipped template name is not a localisation key.'**
  String get failureAShippedTemplateNameIsNotA;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A shipped template names an unknown identity field.'**
  String get failureAShippedTemplateNamesAnUnknownIdentity;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A shipped template names an unknown parent.'**
  String get failureAShippedTemplateNamesAnUnknownParent;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A shipped template names an unknown field group.'**
  String get failureAShippedTemplateNamesAnUnknownField;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A shipped field is missing \"{value0}\".'**
  String failureAShippedFieldIsMissingValue(String value0);

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A shipped field uses an unknown type.'**
  String get failureAShippedFieldUsesAnUnknownType;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A shipped field label is not a localisation key.'**
  String get failureAShippedFieldLabelIsNotA;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A shipped template could not be read.'**
  String get failureAShippedTemplateCouldNotBeRead;

  /// Operator-facing failure from lib/features/templates/data/shipped_template_loader.dart.
  ///
  /// In en, this message translates to:
  /// **'A shipped template names an unknown record type.'**
  String get failureAShippedTemplateNamesAnUnknownRecord;

  /// Operator-facing failure from lib/features/templates/data/template_migration_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'The template or its records changed while you reviewed the migration.'**
  String get failureTheTemplateOrItsRecordsChangedWhile;

  /// Operator-facing failure from lib/features/templates/data/template_migration_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Review the updated changes and try again.'**
  String get failureReviewTheUpdatedChangesAndTryAgain;

  /// Operator-facing failure from lib/features/templates/data/template_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'A field needs a key.'**
  String get failureAFieldNeedsAKey;

  /// Operator-facing failure from lib/features/templates/data/template_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Give every field a key and save again.'**
  String get failureGiveEveryFieldAKeyAndSave;

  /// Operator-facing failure from lib/features/templates/data/template_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Each field key must be unique on a template.'**
  String get failureEachFieldKeyMustBeUniqueOn;

  /// Operator-facing failure from lib/features/templates/data/template_repository_impl.dart.
  ///
  /// In en, this message translates to:
  /// **'Rename the duplicate key and save again.'**
  String get failureRenameTheDuplicateKeyAndSaveAgain;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That value is not text.'**
  String get failureThatValueIsNotText;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter text, or leave the field empty.'**
  String get failureEnterTextOrLeaveTheFieldEmpty;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That value is not a whole number.'**
  String get failureThatValueIsNotAWholeNumber;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number, or leave the field empty.'**
  String get failureEnterAWholeNumberOrLeaveThe;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That value is not a number.'**
  String get failureThatValueIsNotANumber;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter a number, or leave the field empty.'**
  String get failureEnterANumberOrLeaveTheField;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That number is outside the allowed range.'**
  String get failureThatNumberIsOutsideTheAllowedRange;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter a number inside the range, or leave the field empty.'**
  String get failureEnterANumberInsideTheRangeOr;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That value is shorter than this field allows.'**
  String get failureThatValueIsShorterThanThisField;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter a longer value, or leave the field empty.'**
  String get failureEnterALongerValueOrLeaveThe;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That value is longer than this field allows.'**
  String get failureThatValueIsLongerThanThisField;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Shorten the value, or leave the field empty.'**
  String get failureShortenTheValueOrLeaveTheField;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That value does not match the expected pattern.'**
  String get failureThatValueDoesNotMatchTheExpected;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter a value in the expected form, or leave the field empty.'**
  String get failureEnterAValueInTheExpectedForm;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'This field\'\'s pattern is not valid.'**
  String get failureThisFieldSPatternIsNotValid;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Open the template and correct the field\'\'s pattern.'**
  String get failureOpenTheTemplateAndCorrectTheField;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That value is not a date.'**
  String get failureThatValueIsNotADate;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter a calendar date, or leave the field empty.'**
  String get failureEnterACalendarDateOrLeaveThe;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That value is not a time of day.'**
  String get failureThatValueIsNotATimeOf;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter a time, or leave the field empty.'**
  String get failureEnterATimeOrLeaveTheField;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That value is not a date and time.'**
  String get failureThatValueIsNotADateAnd;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Enter a date and time, or leave the field empty.'**
  String get failureEnterADateAndTimeOrLeave;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That value is not a yes or no.'**
  String get failureThatValueIsNotAYesOr;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Switch the field on or off, or leave it unset.'**
  String get failureSwitchTheFieldOnOrOffOr;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That value is not a choice.'**
  String get failureThatValueIsNotAChoice;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Pick an option from the list, or leave the field empty.'**
  String get failurePickAnOptionFromTheListOr;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That choice is not on the list.'**
  String get failureThatChoiceIsNotOnTheList;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That value is not a file path.'**
  String get failureThatValueIsNotAFilePath;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Attach a file, or leave the field empty.'**
  String get failureAttachAFileOrLeaveTheField;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That value is not a location.'**
  String get failureThatValueIsNotALocation;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Capture a GPS fix, or leave the field empty.'**
  String get failureCaptureAGPSFixOrLeaveThe;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'That location is outside the earth.'**
  String get failureThatLocationIsOutsideTheEarth;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Capture a GPS fix again, or leave the field empty.'**
  String get failureCaptureAGPSFixAgainOrLeave;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'This field type has no editor on this screen.'**
  String get failureThisFieldTypeHasNoEditorOn;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Open the template and pick a type this screen supports.'**
  String get failureOpenTheTemplateAndPickAType;

  /// Operator-facing failure from lib/features/templates/domain/field_type_registry.dart.
  ///
  /// In en, this message translates to:
  /// **'Confirm consent with the named operator.'**
  String get failureConfirmConsentWithTheNamedOperator;

  /// Operator-facing failure from lib/features/templates/domain/field_wire.dart.
  ///
  /// In en, this message translates to:
  /// **'That field type is not recognised.'**
  String get failureThatFieldTypeIsNotRecognised;

  /// Operator-facing failure from lib/features/templates/domain/field_wire.dart.
  ///
  /// In en, this message translates to:
  /// **'Pick a type from the list and save again.'**
  String get failurePickATypeFromTheListAnd;

  /// Operator-facing failure from lib/features/templates/domain/field_wire.dart.
  ///
  /// In en, this message translates to:
  /// **'That input mode is not recognised.'**
  String get failureThatInputModeIsNotRecognised;

  /// Operator-facing failure from lib/features/templates/domain/field_wire.dart.
  ///
  /// In en, this message translates to:
  /// **'Pick an input mode from the list and save again.'**
  String get failurePickAnInputModeFromTheList;

  /// Operator-facing failure from lib/features/templates/domain/shipped_template_suggestions.dart.
  ///
  /// In en, this message translates to:
  /// **'The suggested order could not be read.'**
  String get failureTheSuggestedOrderCouldNotBeRead;

  /// Operator-facing failure from lib/features/templates/domain/shipped_template_suggestions.dart.
  ///
  /// In en, this message translates to:
  /// **'Use the on-device results or try again.'**
  String get failureUseTheOnDeviceResultsOrTry;

  /// Operator-facing failure from lib/features/templates/presentation/identity_fields_screen.dart.
  ///
  /// In en, this message translates to:
  /// **'Open the template list and try again.'**
  String get failureOpenTheTemplateListAndTryAgain;

  /// Operator-facing failure from lib/features/templates/presentation/shipped_suggestions_controller.dart.
  ///
  /// In en, this message translates to:
  /// **'The daily analysis limit is reached.'**
  String get failureTheDailyAnalysisLimitIsReached;

  /// Operator-facing failure from lib/features/templates/presentation/shipped_suggestions_controller.dart.
  ///
  /// In en, this message translates to:
  /// **'Use the on-device suggestions or try tomorrow.'**
  String get failureUseTheOnDeviceSuggestionsOrTry;

  /// Operator-facing failure from lib/main.dart.
  ///
  /// In en, this message translates to:
  /// **'Export protections are unavailable on this device.'**
  String get failureExportProtectionsAreUnavailableOnThisDevice;

  /// Operator-facing status for processingDailyCap.
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s limit of {cap} online requests is used. It resets at 00:00 UTC on {resetDay}.'**
  String processingDailyCap(int cap, String resetDay);

  /// Operator-facing status for processingDailyResetRecovery.
  ///
  /// In en, this message translates to:
  /// **'Processing will be available after the daily reset.'**
  String get processingDailyResetRecovery;

  /// Operator-facing status for bundlePasswordInvalid.
  ///
  /// In en, this message translates to:
  /// **'That password did not open the bundle.'**
  String get bundlePasswordInvalid;

  /// Operator-facing status for bundlePasswordInvalidRecovery.
  ///
  /// In en, this message translates to:
  /// **'Try the password again. Nothing was extracted.'**
  String get bundlePasswordInvalidRecovery;

  /// Operator-facing status for incomingBundleBusy.
  ///
  /// In en, this message translates to:
  /// **'Finish the current package before opening another.'**
  String get incomingBundleBusy;

  /// Operator-facing status for incomingBundleTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This package is too large to open.'**
  String get incomingBundleTooLarge;

  /// Operator-facing status for incomingBundleIncomplete.
  ///
  /// In en, this message translates to:
  /// **'This package is too large or incomplete.'**
  String get incomingBundleIncomplete;

  /// Operator-facing status for incomingBundleUnreadable.
  ///
  /// In en, this message translates to:
  /// **'This package could not be opened.'**
  String get incomingBundleUnreadable;

  /// Operator-facing status for incomingBundleUnreadableRecovery.
  ///
  /// In en, this message translates to:
  /// **'Open the file again from its original location.'**
  String get incomingBundleUnreadableRecovery;

  /// Operator-facing status for biometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is unavailable.'**
  String get biometricUnavailable;

  /// Operator-facing status for biometricPinRecovery.
  ///
  /// In en, this message translates to:
  /// **'Unlock with your app PIN.'**
  String get biometricPinRecovery;

  /// Operator-facing status for appLockStorageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The app lock could not be read on this device.'**
  String get appLockStorageUnavailable;

  /// Operator-facing status for appLockStorageRecovery.
  ///
  /// In en, this message translates to:
  /// **'Try unlocking again when secure storage is available.'**
  String get appLockStorageRecovery;

  /// The destination could not be saved.
  ///
  /// In en, this message translates to:
  /// **'The destination could not be saved.'**
  String get cloudDestinationSaveFailed;

  /// That destination is no longer listed.
  ///
  /// In en, this message translates to:
  /// **'That destination is no longer listed.'**
  String get cloudDestinationMissing;

  /// Refresh the list.
  ///
  /// In en, this message translates to:
  /// **'Refresh the list.'**
  String get cloudRefreshDestinations;

  /// The upload could not be recorded.
  ///
  /// In en, this message translates to:
  /// **'The upload could not be recorded.'**
  String get cloudUploadRecordFailed;

  /// The upload history could not be updated.
  ///
  /// In en, this message translates to:
  /// **'The upload history could not be updated.'**
  String get cloudUploadHistoryUpdateFailed;

  /// The file on this device was not changed.
  ///
  /// In en, this message translates to:
  /// **'The file on this device was not changed.'**
  String get cloudUploadHistoryUpdateRecovery;

  /// Confirm this upload before it can start.
  ///
  /// In en, this message translates to:
  /// **'Confirm this upload before it can start.'**
  String get cloudUploadConfirmationRequired;

  /// Review the file and confirm it.
  ///
  /// In en, this message translates to:
  /// **'Review the file and confirm it.'**
  String get cloudUploadConfirmationRecovery;

  /// That upload is no longer in the history.
  ///
  /// In en, this message translates to:
  /// **'That upload is no longer in the history.'**
  String get cloudUploadHistoryMissing;

  /// Start the upload again.
  ///
  /// In en, this message translates to:
  /// **'Start the upload again.'**
  String get cloudUploadRestartRecovery;

  /// That preference cannot be stored.
  ///
  /// In en, this message translates to:
  /// **'That preference cannot be stored.'**
  String get settingsPreferenceUnsupported;

  /// Choose a supported value and save again.
  ///
  /// In en, this message translates to:
  /// **'Choose a supported value and save again.'**
  String get settingsPreferenceUnsupportedRecovery;

  /// The preference could not be saved on this device.
  ///
  /// In en, this message translates to:
  /// **'The preference could not be saved on this device.'**
  String get settingsPreferenceSaveFailed;

  /// Try again. Your last change was not stored.
  ///
  /// In en, this message translates to:
  /// **'Try again. Your last change was not stored.'**
  String get settingsPreferenceSaveRecovery;

  /// The saved capture could not be read.
  ///
  /// In en, this message translates to:
  /// **'The saved capture could not be read.'**
  String get privacyCaptureUnreadable;

  /// Recover the capture and try again.
  ///
  /// In en, this message translates to:
  /// **'Recover the capture and try again.'**
  String get privacyCaptureRecover;

  /// Open a project before removing its location data.
  ///
  /// In en, this message translates to:
  /// **'Open a project before removing its location data.'**
  String get privacyProjectRequired;

  /// Choose a project, then try again.
  ///
  /// In en, this message translates to:
  /// **'Choose a project, then try again.'**
  String get privacyProjectRequiredRecovery;

  /// This destination sign-in changed.
  ///
  /// In en, this message translates to:
  /// **'This destination sign-in changed.'**
  String get cloudSignInChanged;

  /// This Google Drive sign-in needs renewal.
  ///
  /// In en, this message translates to:
  /// **'This Google Drive sign-in needs renewal.'**
  String get cloudGoogleSignInRenewal;

  /// Sign in again.
  ///
  /// In en, this message translates to:
  /// **'Sign in again.'**
  String get cloudSignInAgain;

  /// File choice: an editable Word report.
  ///
  /// In en, this message translates to:
  /// **'Word document (DOCX)'**
  String get exportFormatDocx;

  /// File choice: a UTF-8 record report.
  ///
  /// In en, this message translates to:
  /// **'Plain text (TXT)'**
  String get exportFormatTxt;

  /// A saved server credential status; never shows the key.
  ///
  /// In en, this message translates to:
  /// **'Encrypted on the organisation server'**
  String get serverApiKeySaved;

  /// Explains encrypted personal credential custody.
  ///
  /// In en, this message translates to:
  /// **'Your key is encrypted on the organisation server. Requests use your provider account; no automatic billing-account switch.'**
  String get serverApiKeyCustody;

  /// A provider request has an uncertain billing result.
  ///
  /// In en, this message translates to:
  /// **'This request may have been charged. Its result is unavailable. Review before starting a new attempt.'**
  String get aiRequestUncertain;

  /// The selected managed billing account.
  ///
  /// In en, this message translates to:
  /// **'Organisation-managed account'**
  String get aiManagedAccount;

  /// The selected personal billing account.
  ///
  /// In en, this message translates to:
  /// **'Your {provider} account'**
  String aiPersonalAccount(String provider);

  /// Explicit AI request budget control.
  ///
  /// In en, this message translates to:
  /// **'Maximum cost per request'**
  String get aiSpendingLimit;

  /// Explains request budgets and escalation approval.
  ///
  /// In en, this message translates to:
  /// **'Budget units configured by your organisation. Higher-cost models require explicit approval.'**
  String get aiSpendingLimitHint;

  /// Confirmation when deleting a personal server credential.
  ///
  /// In en, this message translates to:
  /// **'Delete your encrypted provider key from the organisation server. Analysis for this account stops until a key is saved again.'**
  String get serverCredentialRemoveMessage;

  /// Processing review and retry control.
  ///
  /// In en, this message translates to:
  /// **'Analysis findings'**
  String get processingFindingsTitle;

  /// Processing review and retry control.
  ///
  /// In en, this message translates to:
  /// **'Retry analysis?'**
  String get processingRetryChargeTitle;

  /// Processing review and retry control.
  ///
  /// In en, this message translates to:
  /// **'The previous request may have been charged. Retrying starts a new request and may spend more.'**
  String get processingRetryChargeBody;

  /// Processing review and retry control.
  ///
  /// In en, this message translates to:
  /// **'Approve retry'**
  String get processingRetryChargeConfirm;

  /// Processing usage and cost display.
  ///
  /// In en, this message translates to:
  /// **'Reserved cost: {amount} {unit} (spending ceiling)'**
  String processingReservedCost(String amount, String unit);

  /// Processing usage and cost display.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} reported token} other{{count} reported tokens}}'**
  String processingTokens(int count);

  /// Explicit processing consent for the provider, model, billing account and spending ceiling.
  ///
  /// In en, this message translates to:
  /// **'Provider: {provider}. Model: {model}. Billing: {account}. Approved request limit: {limit}.'**
  String processingEgressSelection(
    String provider,
    String model,
    String account,
    String limit,
  );

  /// Explicit processing consent for the provider, model, billing account and spending ceiling.
  ///
  /// In en, this message translates to:
  /// **'Managed account'**
  String get processingEgressManaged;

  /// Explicit processing consent for the provider, model, billing account and spending ceiling.
  ///
  /// In en, this message translates to:
  /// **'Your server-held key'**
  String get processingEgressPersonal;

  /// Explicit processing consent for the provider, model, billing account and spending ceiling.
  ///
  /// In en, this message translates to:
  /// **'configured server limit'**
  String get processingEgressLimitDefault;

  /// Visible configured spending ceiling for the selected provider model before approval.
  ///
  /// In en, this message translates to:
  /// **'This model reserves up to {amount} {unit} per request.'**
  String aiModelCostCeiling(String amount, String unit);

  /// Collapsed help on the generic import page explaining supported file types.
  ///
  /// In en, this message translates to:
  /// **'Supported files'**
  String get importSupportedFiles;

  /// Creates an editable saved library copy from an immutable shipped template.
  ///
  /// In en, this message translates to:
  /// **'Customize a copy'**
  String get templatesCustomizeCopy;

  /// Heading for editable templates saved in the global custom library.
  ///
  /// In en, this message translates to:
  /// **'My templates'**
  String get templatesMyTemplates;

  /// Confirmation after a durable template tombstone, accompanied by Undo.
  ///
  /// In en, this message translates to:
  /// **'Template deleted'**
  String get templatesDeleted;

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'Empty deleted records ({count})'**
  String recycleEmptyRecords(int count);

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get recycleTypeProject;

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recycleTypeRecord;

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get recycleTypePhoto;

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get recycleTypeDocument;

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get recycleTypeAudio;

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get recycleRestored;

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'Restore the deleted parent first.'**
  String get recycleParentDeleted;

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'Restore the project or record from the Recycle bin, then try again.'**
  String get recycleParentDeletedRecovery;

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'{type} · {details}'**
  String recycleEntitySubtitle(String type, String details);

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'The project folder could not be restored.'**
  String get recycleFolderRestoreFailed;

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'Check storage access and resolve any existing folder with the same name, then try again.'**
  String get recycleFolderRestoreRecovery;

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'Supported providers'**
  String get aiSupportedProviders;

  /// Field workflow recovery and compact settings control.
  ///
  /// In en, this message translates to:
  /// **'Spending limit'**
  String get aiCostControls;

  /// Collapsed AI cost controls showing the saved explicit maximum per request.
  ///
  /// In en, this message translates to:
  /// **'Per request: {amount} configured'**
  String aiRequestLimitSummary(String amount);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'XA':
            return AppLocalizationsEnXa();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
