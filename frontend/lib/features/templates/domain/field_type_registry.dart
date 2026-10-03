import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/consent_stamp.dart';

import 'field_def.dart';

/// Describes each §12.1 field type by its four behaviours: editor, validator,
/// normaliser and storage-and-export form.
///
/// Capture, review, validation and export read behaviour from here instead
/// of switching on the type. Presentation supplies an editor builder for
/// each [FieldEditorKind]; this library never imports a widget.
abstract final class FieldTypeRegistry {
  /// Every registered type, in §12.1 order.
  static List<FieldType> get types => FieldType.values;

  /// The four behaviours of [type].
  ///
  /// Exhaustive on [FieldType]: adding a type without an entry here does
  /// not compile.
  static FieldTypeBehaviours of(FieldType type) {
    return switch (type) {
      FieldType.text || FieldType.longText || FieldType.barcode => (
        editor: FieldEditorKind.appTextField,
        validator: _validateText,
        normaliser: _normaliseText,
        storageForm: StorageForm.text,
      ),
      FieldType.number => (
        editor: FieldEditorKind.appNumberField,
        validator: _validateInteger,
        normaliser: _normaliseInteger,
        storageForm: StorageForm.integer,
      ),
      FieldType.decimal || FieldType.currency || FieldType.percentage => (
        editor: FieldEditorKind.appNumberField,
        validator: _validateDecimal,
        normaliser: _normaliseDecimal,
        storageForm: StorageForm.decimal,
      ),
      FieldType.date => (
        editor: FieldEditorKind.appDateField,
        validator: _validateDate,
        normaliser: _normaliseDate,
        storageForm: StorageForm.date,
      ),
      FieldType.time => (
        editor: FieldEditorKind.appDateField,
        validator: _validateTime,
        normaliser: _normaliseTime,
        storageForm: StorageForm.time,
      ),
      FieldType.dateTime => (
        editor: FieldEditorKind.appDateField,
        validator: _validateDateTime,
        normaliser: _normaliseDateTime,
        storageForm: StorageForm.dateTime,
      ),
      FieldType.boolean => (
        editor: FieldEditorKind.appSwitchTile,
        validator: _validateBoolean,
        normaliser: _normaliseBoolean,
        storageForm: StorageForm.boolean,
      ),
      FieldType.choice || FieldType.lookup => (
        editor: FieldEditorKind.appChoiceField,
        validator: _validateChoice,
        normaliser: _normaliseChoice,
        storageForm: type == FieldType.lookup
            ? StorageForm.lookupKey
            : StorageForm.choice,
      ),
      FieldType.multiChoice => (
        editor: FieldEditorKind.appMultiChoiceField,
        validator: _validateMultiChoice,
        normaliser: _normaliseMultiChoice,
        storageForm: StorageForm.multiChoice,
      ),
      FieldType.photoReference || FieldType.documentReference => (
        editor: FieldEditorKind.appTextField,
        validator: _validatePaths,
        normaliser: _normalisePaths,
        storageForm: StorageForm.pathList,
      ),
      FieldType.gpsLocation => (
        editor: FieldEditorKind.gpsStamp,
        validator: _validateGps,
        normaliser: _normaliseGps,
        storageForm: StorageForm.geoPoint,
      ),
      FieldType.signature => (
        editor: FieldEditorKind.signaturePad,
        validator: _validateText,
        normaliser: _normaliseText,
        storageForm: StorageForm.imagePath,
      ),
      FieldType.computed => (
        editor: FieldEditorKind.computedReadOnly,
        validator: _validateComputed,
        normaliser: _normaliseComputed,
        storageForm: StorageForm.computed,
      ),
      FieldType.consent => (
        editor: FieldEditorKind.appConsentField,
        validator: _validateConsent,
        normaliser: _normaliseConsent,
        storageForm: StorageForm.text,
      ),
    };
  }

  /// Whether [type] reuses a catalogue field. Signature, GPS and computed
  /// do not — they are declared here and built later (135, 170).
  static bool usesCatalogueEditor(FieldType type) {
    return of(type).editor.usesCatalogue;
  }

  /// Runs the type's validator. Empty values pass; requiredness is task 170.
  static Result<void> validate({
    required FieldType type,
    required Object? value,
    required FieldDef field,
  }) {
    return of(type).validator(value, field);
  }

  /// Coerces [value] into the type's stored form, or null when it cannot.
  static Object? normalise({
    required FieldType type,
    required Object? value,
    required FieldDef field,
  }) {
    return of(type).normaliser(value, field);
  }

  /// Asks presentation for the editor [type] named. Domain never builds it.
  static Result<T> editor<T extends Object>({
    required FieldType type,
    required Map<FieldEditorKind, FieldEditorBuilder<T>> builders,
    required FieldDef field,
    required Object? value,
    required void Function(Object? value) onChanged,
  }) {
    final FieldEditorBuilder<T>? builder = builders[of(type).editor];
    if (builder == null) {
      return FailureResult<T>(_missingEditor);
    }
    return Success<T>(
      builder(field: field, value: value, onChanged: onChanged),
    );
  }
}

/// Catalogue widget this kind names, or a later non-catalogue control.
enum FieldEditorKind {
  /// AppTextField — text, long text, barcode, photo and document paths.
  appTextField,

  /// AppNumberField — number, decimal, currency, percentage.
  appNumberField,

  /// AppDateField — date, time and date-time.
  appDateField,

  /// AppSwitchTile — boolean.
  appSwitchTile,

  /// AppConsentField — attributed confirmation stored with its UTC timestamp.
  appConsentField,

  /// AppChoiceField — choice and lookup.
  appChoiceField,

  /// AppMultiChoiceField — multi-choice.
  appMultiChoiceField,

  /// Drawn on screen; stored as an image beside the record's evidence.
  signaturePad,

  /// Filled by the GPS stamp of task 135.
  gpsStamp,

  /// Read-only; evaluated by task 170.
  computedReadOnly;

  /// Whether presentation can bind this kind to a catalogue widget.
  bool get usesCatalogue {
    return switch (this) {
      FieldEditorKind.signaturePad ||
      FieldEditorKind.gpsStamp ||
      FieldEditorKind.computedReadOnly => false,
      FieldEditorKind.appTextField ||
      FieldEditorKind.appNumberField ||
      FieldEditorKind.appDateField ||
      FieldEditorKind.appSwitchTile ||
      FieldEditorKind.appConsentField ||
      FieldEditorKind.appChoiceField ||
      FieldEditorKind.appMultiChoiceField => true,
    };
  }

  /// Catalogue class name, or null when presentation supplies its own builder.
  String? get catalogueWidget {
    return switch (this) {
      FieldEditorKind.appTextField => 'AppTextField',
      FieldEditorKind.appNumberField => 'AppNumberField',
      FieldEditorKind.appDateField => 'AppDateField',
      FieldEditorKind.appSwitchTile => 'AppSwitchTile',
      FieldEditorKind.appConsentField => 'AppConsentField',
      FieldEditorKind.appChoiceField => 'AppChoiceField',
      FieldEditorKind.appMultiChoiceField => 'AppMultiChoiceField',
      FieldEditorKind.signaturePad ||
      FieldEditorKind.gpsStamp ||
      FieldEditorKind.computedReadOnly => null,
    };
  }
}

/// How a value is stored and what export writers receive.
enum StorageForm {
  /// UTF-8 string. Identifiers stay text.
  text,

  /// Whole number.
  integer,

  /// Fractional number, including currency and percentage amounts.
  decimal,

  /// Calendar date with no time of day.
  date,

  /// Time of day.
  time,

  /// Instant with a date and a time of day.
  dateTime,

  /// True or false.
  boolean,

  /// One option code.
  choice,

  /// Zero or more option codes.
  multiChoice,

  /// Key into a reference dataset.
  lookupKey,

  /// Photo or document paths.
  pathList,

  /// Latitude, longitude and optional accuracy.
  geoPoint,

  /// Signature image path beside the record's evidence.
  imagePath,

  /// Evaluated expression result; no stored input of its own.
  computed,
}

/// The four behaviours one [FieldType] publishes.
typedef FieldTypeBehaviours = ({
  FieldEditorKind editor,
  FieldValidator validator,
  FieldNormaliser normaliser,
  StorageForm storageForm,
});

/// Shape check for a captured value. Null or empty passes.
typedef FieldValidator = Result<void> Function(Object? value, FieldDef field);

/// Coerces a captured value into the type's stored form.
typedef FieldNormaliser = Object? Function(Object? value, FieldDef field);

/// Presentation builder for one [FieldEditorKind]. Returns a widget object.
typedef FieldEditorBuilder<T extends Object> =
    T Function({
      required FieldDef field,
      required Object? value,
      required void Function(Object? value) onChanged,
    });

final ValidationFailure _notText = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatValueIsNotText,
  localizedRecovery: DomainCopy.messages.failureEnterTextOrLeaveTheFieldEmpty,
);

final ValidationFailure _notANumber = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatValueIsNotAWholeNumber,
  localizedRecovery: DomainCopy.messages.failureEnterAWholeNumberOrLeaveThe,
);

final ValidationFailure _notADecimal = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatValueIsNotANumber,
  localizedRecovery: DomainCopy.messages.failureEnterANumberOrLeaveTheField,
);

final ValidationFailure _outOfRange = ValidationFailure(
  localizedMessage:
      DomainCopy.messages.failureThatNumberIsOutsideTheAllowedRange,
  localizedRecovery: DomainCopy.messages.failureEnterANumberInsideTheRangeOr,
);

final ValidationFailure _tooShort = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatValueIsShorterThanThisField,
  localizedRecovery: DomainCopy.messages.failureEnterALongerValueOrLeaveThe,
);

final ValidationFailure _tooLong = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatValueIsLongerThanThisField,
  localizedRecovery: DomainCopy.messages.failureShortenTheValueOrLeaveTheField,
);

final ValidationFailure _patternMismatch = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatValueDoesNotMatchTheExpected,
  localizedRecovery: DomainCopy.messages.failureEnterAValueInTheExpectedForm,
);

final ValidationFailure _badPattern = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThisFieldSPatternIsNotValid,
  localizedRecovery:
      DomainCopy.messages.failureOpenTheTemplateAndCorrectTheField,
);

final ValidationFailure _notADate = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatValueIsNotADate,
  localizedRecovery: DomainCopy.messages.failureEnterACalendarDateOrLeaveThe,
);

final ValidationFailure _notATime = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatValueIsNotATimeOf,
  localizedRecovery: DomainCopy.messages.failureEnterATimeOrLeaveTheField,
);

final ValidationFailure _notADateTime = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatValueIsNotADateAnd,
  localizedRecovery: DomainCopy.messages.failureEnterADateAndTimeOrLeave,
);

final ValidationFailure _notABoolean = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatValueIsNotAYesOr,
  localizedRecovery: DomainCopy.messages.failureSwitchTheFieldOnOrOffOr,
);

final ValidationFailure _notAChoice = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatValueIsNotAChoice,
  localizedRecovery: DomainCopy.messages.failurePickAnOptionFromTheListOr,
);

final ValidationFailure _notOnList = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatChoiceIsNotOnTheList,
  localizedRecovery: DomainCopy.messages.failurePickAnOptionFromTheListOr,
);

final ValidationFailure _notAPath = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatValueIsNotAFilePath,
  localizedRecovery: DomainCopy.messages.failureAttachAFileOrLeaveTheField,
);

final ValidationFailure _notALocation = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatValueIsNotALocation,
  localizedRecovery: DomainCopy.messages.failureCaptureAGPSFixOrLeaveThe,
);

final ValidationFailure _locationOutOfRange = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThatLocationIsOutsideTheEarth,
  localizedRecovery: DomainCopy.messages.failureCaptureAGPSFixAgainOrLeave,
);

final ValidationFailure _missingEditor = ValidationFailure(
  localizedMessage: DomainCopy.messages.failureThisFieldTypeHasNoEditorOn,
  localizedRecovery: DomainCopy.messages.failureOpenTheTemplateAndPickAType,
);

const String _minKey = 'min';
const String _maxKey = 'max';
const String _minLengthKey = 'minLength';
const String _minLengthSnake = 'min_length';
const String _maxLengthKey = 'maxLength';
const String _maxLengthSnake = 'max_length';
const String _patternKey = 'pattern';
const String _codeKey = 'code';
const String _labelKey = 'label';
const String _latitudeKey = 'latitude';
const String _longitudeKey = 'longitude';
const String _accuracyKey = 'accuracy';

const double _minLatitude = -90;
const double _maxLatitude = 90;
const double _minLongitude = -180;
const double _maxLongitude = 180;

const Set<String> _trueTokens = <String>{'true', '1', 'yes', 'y'};
const Set<String> _falseTokens = <String>{'false', '0', 'no', 'n'};

final RegExp _timePattern = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');
final RegExp _dateOnlyPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

const int _maxHour = 23;
const int _maxMinute = 59;
const int _maxSecond = 59;

Result<void> _validateText(Object? value, FieldDef field) {
  if (!_holdsText(field.type)) {
    return FailureResult<void>(_notText);
  }
  if (_isBlank(value)) {
    return const Success<void>(null);
  }
  final String? text = _asTrimmed(value);
  if (text == null) {
    return FailureResult<void>(_notText);
  }
  return _textRules(text, field);
}

Result<void> _validateConsent(Object? value, FieldDef field) {
  if (_isBlank(value) || ConsentStamp.parse(value) != null) {
    return const Success<void>(null);
  }
  return FailureResult<void>(
    ValidationFailure(
      localizedMessage:
          DomainCopy.messages.failureConfirmConsentWithTheNamedOperator,
    ),
  );
}

Object? _normaliseConsent(Object? value, FieldDef field) =>
    ConsentStamp.parse(value)?.toJson();

Object? _normaliseText(Object? value, FieldDef field) {
  if (!_holdsText(field.type)) {
    return null;
  }
  if (value is String) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return _asTrimmed(value);
}

Result<void> _validateInteger(Object? value, FieldDef field) {
  if (field.type != FieldType.number) {
    return FailureResult<void>(_notANumber);
  }
  if (_isBlank(value)) {
    return const Success<void>(null);
  }
  final int? parsed = _asInt(value);
  if (parsed == null) {
    return FailureResult<void>(_notANumber);
  }
  return _inRange(parsed, field);
}

Object? _normaliseInteger(Object? value, FieldDef field) {
  if (field.type != FieldType.number) {
    return null;
  }
  return _asInt(value);
}

Result<void> _validateDecimal(Object? value, FieldDef field) {
  if (!_holdsDecimal(field.type)) {
    return FailureResult<void>(_notADecimal);
  }
  if (_isBlank(value)) {
    return const Success<void>(null);
  }
  final num? parsed = _asNum(value);
  if (parsed == null) {
    return FailureResult<void>(_notADecimal);
  }
  return _inRange(parsed, field);
}

Object? _normaliseDecimal(Object? value, FieldDef field) {
  if (!_holdsDecimal(field.type)) {
    return null;
  }
  return _asNum(value);
}

Result<void> _validateDate(Object? value, FieldDef field) {
  if (field.type != FieldType.date) {
    return FailureResult<void>(_notADate);
  }
  if (_isBlank(value)) {
    return const Success<void>(null);
  }
  return _asDate(value) == null
      ? FailureResult<void>(_notADate)
      : const Success<void>(null);
}

Object? _normaliseDate(Object? value, FieldDef field) {
  if (field.type != FieldType.date) {
    return null;
  }
  final DateTime? parsed = _asDate(value);
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

Result<void> _validateTime(Object? value, FieldDef field) {
  if (field.type != FieldType.time) {
    return FailureResult<void>(_notATime);
  }
  if (_isBlank(value)) {
    return const Success<void>(null);
  }
  return _asTime(value) == null
      ? FailureResult<void>(_notATime)
      : const Success<void>(null);
}

Object? _normaliseTime(Object? value, FieldDef field) {
  if (field.type != FieldType.time) {
    return null;
  }
  return _asTime(value);
}

Result<void> _validateDateTime(Object? value, FieldDef field) {
  if (field.type != FieldType.dateTime) {
    return FailureResult<void>(_notADateTime);
  }
  if (_isBlank(value)) {
    return const Success<void>(null);
  }
  return _asDateTime(value) == null
      ? FailureResult<void>(_notADateTime)
      : const Success<void>(null);
}

Object? _normaliseDateTime(Object? value, FieldDef field) {
  if (field.type != FieldType.dateTime) {
    return null;
  }
  return _asDateTime(value);
}

Result<void> _validateBoolean(Object? value, FieldDef field) {
  if (field.type != FieldType.boolean) {
    return FailureResult<void>(_notABoolean);
  }
  if (_isBlank(value)) {
    return const Success<void>(null);
  }
  return _asBool(value) == null
      ? FailureResult<void>(_notABoolean)
      : const Success<void>(null);
}

Object? _normaliseBoolean(Object? value, FieldDef field) {
  if (field.type != FieldType.boolean) {
    return null;
  }
  return _asBool(value);
}

Result<void> _validateChoice(Object? value, FieldDef field) {
  if (field.type != FieldType.choice && field.type != FieldType.lookup) {
    return FailureResult<void>(_notAChoice);
  }
  if (_isBlank(value)) {
    return const Success<void>(null);
  }
  if (_asTrimmed(value) == null) {
    return FailureResult<void>(_notAChoice);
  }
  if (field.options.isEmpty) {
    return const Success<void>(null);
  }
  return _choiceCode(value, field.options) == null
      ? FailureResult<void>(_notOnList)
      : const Success<void>(null);
}

Object? _normaliseChoice(Object? value, FieldDef field) {
  if (field.type != FieldType.choice && field.type != FieldType.lookup) {
    return null;
  }
  if (field.options.isEmpty) {
    return _asTrimmed(value);
  }
  return _choiceCode(value, field.options);
}

Result<void> _validateMultiChoice(Object? value, FieldDef field) {
  if (field.type != FieldType.multiChoice) {
    return FailureResult<void>(_notAChoice);
  }
  if (_isBlank(value)) {
    return const Success<void>(null);
  }
  for (final Object? item in _asItems(value)) {
    if (_isBlank(item)) {
      continue;
    }
    if (field.options.isEmpty) {
      if (_asTrimmed(item) == null) {
        return FailureResult<void>(_notAChoice);
      }
      continue;
    }
    if (_choiceCode(item, field.options) == null) {
      return FailureResult<void>(_notOnList);
    }
  }
  return const Success<void>(null);
}

Object? _normaliseMultiChoice(Object? value, FieldDef field) {
  if (field.type != FieldType.multiChoice) {
    return null;
  }
  if (_isBlank(value)) {
    return const <String>[];
  }
  final List<String> codes = <String>[];
  for (final Object? item in _asItems(value)) {
    if (_isBlank(item)) {
      continue;
    }
    final String? code = field.options.isEmpty
        ? _asTrimmed(item)
        : _choiceCode(item, field.options);
    if (code != null) {
      codes.add(code);
    }
  }
  return codes;
}

Result<void> _validatePaths(Object? value, FieldDef field) {
  if (field.type != FieldType.photoReference &&
      field.type != FieldType.documentReference) {
    return FailureResult<void>(_notAPath);
  }
  if (_isBlank(value)) {
    return const Success<void>(null);
  }
  for (final Object? item in _asItems(value)) {
    final String? path = _asTrimmed(item);
    if (path == null) {
      return FailureResult<void>(_notAPath);
    }
    final Result<void> length = _lengthOk(path, field);
    if (length is FailureResult<void>) {
      return length;
    }
  }
  return const Success<void>(null);
}

Object? _normalisePaths(Object? value, FieldDef field) {
  if (field.type != FieldType.photoReference &&
      field.type != FieldType.documentReference) {
    return null;
  }
  if (_isBlank(value)) {
    return const <String>[];
  }
  final List<String> paths = <String>[];
  for (final Object? item in _asItems(value)) {
    final String? path = _asTrimmed(item);
    if (path != null) {
      paths.add(path);
    }
  }
  return paths;
}

Result<void> _validateGps(Object? value, FieldDef field) {
  if (field.type != FieldType.gpsLocation) {
    return FailureResult<void>(_notALocation);
  }
  if (_isBlank(value)) {
    return const Success<void>(null);
  }
  final Map<String, Object?>? map = _asStringKeyMap(value);
  if (map == null) {
    return FailureResult<void>(_notALocation);
  }
  final double? latitude = _asDouble(map[_latitudeKey]);
  final double? longitude = _asDouble(map[_longitudeKey]);
  if (latitude == null || longitude == null) {
    return FailureResult<void>(_notALocation);
  }
  if (latitude < _minLatitude ||
      latitude > _maxLatitude ||
      longitude < _minLongitude ||
      longitude > _maxLongitude) {
    return FailureResult<void>(_locationOutOfRange);
  }
  final Object? accuracy = map[_accuracyKey];
  if (accuracy != null && _asDouble(accuracy) == null) {
    return FailureResult<void>(_notALocation);
  }
  return _inRange(_asDouble(accuracy), field);
}

Object? _normaliseGps(Object? value, FieldDef field) {
  if (field.type != FieldType.gpsLocation) {
    return null;
  }
  final Map<String, Object?>? map = _asStringKeyMap(value);
  if (map == null) {
    return null;
  }
  final double? latitude = _asDouble(map[_latitudeKey]);
  final double? longitude = _asDouble(map[_longitudeKey]);
  if (latitude == null || longitude == null) {
    return null;
  }
  final Map<String, double> point = <String, double>{
    _latitudeKey: latitude,
    _longitudeKey: longitude,
  };
  final double? accuracy = _asDouble(map[_accuracyKey]);
  if (accuracy != null) {
    point[_accuracyKey] = accuracy;
  }
  return point;
}

Result<void> _validateComputed(Object? value, FieldDef field) {
  // Task 170 evaluates the expression. Incomplete inputs stay null (§34).
  final bool accepted = field.type == FieldType.computed || value == null;
  return accepted && field.type == FieldType.computed
      ? const Success<void>(null)
      : FailureResult<void>(_notText);
}

Object? _normaliseComputed(Object? value, FieldDef field) {
  if (field.type != FieldType.computed) {
    return null;
  }
  return value;
}

bool _holdsText(FieldType type) {
  return type == FieldType.text ||
      type == FieldType.longText ||
      type == FieldType.barcode ||
      type == FieldType.signature ||
      type == FieldType.consent;
}

bool _holdsDecimal(FieldType type) {
  return type == FieldType.decimal ||
      type == FieldType.currency ||
      type == FieldType.percentage;
}

bool _isBlank(Object? value) {
  if (value == null) {
    return true;
  }
  if (value is String) {
    return value.trim().isEmpty;
  }
  if (value is Iterable<Object?>) {
    return value.isEmpty;
  }
  if (value is Map) {
    return value.isEmpty;
  }
  return false;
}

String? _asTrimmed(Object? value) {
  if (value is! String) {
    return null;
  }
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value % 1 == 0 ? value.toInt() : null;
  }
  if (value is String) {
    final String trimmed = value.trim();
    final int? whole = int.tryParse(trimmed);
    if (whole != null) {
      return whole;
    }
    final num? parsed = num.tryParse(trimmed);
    if (parsed != null && parsed % 1 == 0) {
      return parsed.toInt();
    }
  }
  return null;
}

num? _asNum(Object? value) {
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value.trim());
  }
  return null;
}

double? _asDouble(Object? value) {
  final num? parsed = _asNum(value);
  return parsed?.toDouble();
}

bool? _asBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final String? text = _asTrimmed(value)?.toLowerCase();
  if (text == null) {
    return null;
  }
  if (_trueTokens.contains(text)) {
    return true;
  }
  if (_falseTokens.contains(text)) {
    return false;
  }
  return null;
}

DateTime? _asDate(Object? value) {
  if (value is DateTime) {
    return DateTime(value.year, value.month, value.day);
  }
  final String? text = _asTrimmed(value);
  if (text == null) {
    return null;
  }
  final Match? match = _dateOnlyPattern.firstMatch(text);
  if (match != null) {
    final int year = int.parse(match.group(1)!);
    final int month = int.parse(match.group(2)!);
    final int day = int.parse(match.group(3)!);
    final DateTime built = DateTime(year, month, day);
    if (built.year != year || built.month != month || built.day != day) {
      return null;
    }
    return built;
  }
  return DateTime.tryParse(text);
}

String? _asTime(Object? value) {
  if (value is DateTime) {
    return _formatTime(value.hour, value.minute, value.second);
  }
  final String? text = _asTrimmed(value);
  if (text == null) {
    return null;
  }
  final Match? match = _timePattern.firstMatch(text);
  if (match == null) {
    return null;
  }
  return _clockTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3) ?? '0'),
  );
}

String? _clockTime(int hours, int minutes, int seconds) {
  if (hours > _maxHour || minutes > _maxMinute || seconds > _maxSecond) {
    return null;
  }
  if (hours < 0 || minutes < 0 || seconds < 0) {
    return null;
  }
  return _formatTime(hours, minutes, seconds);
}

String _formatTime(int hours, int minutes, int seconds) {
  return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}

DateTime? _asDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }
  final String? text = _asTrimmed(value);
  if (text == null) {
    return null;
  }
  return DateTime.tryParse(text);
}

Map<String, Object?>? _asStringKeyMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return <String, Object?>{
      for (final MapEntry<dynamic, dynamic> entry in value.entries)
        entry.key.toString(): entry.value,
    };
  }
  return null;
}

Iterable<Object?> _asItems(Object? value) {
  if (value is Iterable<Object?>) {
    return value;
  }
  return <Object?>[value];
}

String? _choiceCode(Object? value, List<Object> options) {
  final String? text = _asTrimmed(value);
  if (text == null) {
    return null;
  }
  for (final ({String code, String label}) option in _optionsOf(options)) {
    if (option.code == text || option.label == text) {
      return option.code;
    }
  }
  final String lower = text.toLowerCase();
  for (final ({String code, String label}) option in _optionsOf(options)) {
    if (option.code.toLowerCase() == lower ||
        option.label.toLowerCase() == lower) {
      return option.code;
    }
  }
  return null;
}

Iterable<({String code, String label})> _optionsOf(List<Object> options) sync* {
  for (final Object option in options) {
    if (option is String) {
      final String trimmed = option.trim();
      if (trimmed.isNotEmpty) {
        yield (code: trimmed, label: trimmed);
      }
      continue;
    }
    final Map<String, Object?>? map = _asStringKeyMap(option);
    if (map == null) {
      continue;
    }
    final String? code =
        _asTrimmed(map[_codeKey]) ?? _asTrimmed(map[_labelKey]);
    final String? label = _asTrimmed(map[_labelKey]) ?? code;
    if (code != null && label != null) {
      yield (code: code, label: label);
    }
  }
}

Result<void> _textRules(String text, FieldDef field) {
  final Result<void> length = _lengthOk(text, field);
  if (length is FailureResult<void>) {
    return length;
  }
  return _matchPattern(text, field.validation[_patternKey]);
}

Result<void> _lengthOk(String text, FieldDef field) {
  final int? minLength = _ruleInt(field, _minLengthKey, _minLengthSnake);
  if (minLength != null && text.length < minLength) {
    return FailureResult<void>(_tooShort);
  }
  final int? maxLength = _ruleInt(field, _maxLengthKey, _maxLengthSnake);
  if (maxLength != null && text.length > maxLength) {
    return FailureResult<void>(_tooLong);
  }
  return const Success<void>(null);
}

Result<void> _matchPattern(String text, Object? pattern) {
  if (pattern is! String || pattern.isEmpty) {
    return const Success<void>(null);
  }
  try {
    if (RegExp(pattern).hasMatch(text)) {
      return const Success<void>(null);
    }
    return FailureResult<void>(_patternMismatch);
  } on FormatException {
    return FailureResult<void>(_badPattern);
  }
}

Result<void> _inRange(num? value, FieldDef field) {
  if (value == null) {
    return const Success<void>(null);
  }
  final num? min = _ruleNum(field, _minKey, _minKey);
  final num? max = _ruleNum(field, _maxKey, _maxKey);
  if (min != null && value < min) {
    return FailureResult<void>(_outOfRange);
  }
  if (max != null && value > max) {
    return FailureResult<void>(_outOfRange);
  }
  return const Success<void>(null);
}

Object? _rule(FieldDef field, String camel, String snake) {
  return field.validation[camel] ?? field.validation[snake];
}

int? _ruleInt(FieldDef field, String camel, String snake) {
  return _asInt(_rule(field, camel, snake));
}

num? _ruleNum(FieldDef field, String camel, String snake) {
  return _asNum(_rule(field, camel, snake));
}
