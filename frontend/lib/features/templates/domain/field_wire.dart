import 'package:tapture/core/errors/failure.dart';

import 'field_def.dart';

/// Canonical field type and input-mode names shared by persistence and JSON.
abstract final class FieldWire {
  /// Wire name stored in the type column.
  static String fieldTypeToWire(FieldType type) {
    return switch (type) {
      FieldType.text => 'text',
      FieldType.longText => 'long_text',
      FieldType.number => 'number',
      FieldType.decimal => 'decimal',
      FieldType.currency => 'currency',
      FieldType.percentage => 'percentage',
      FieldType.date => 'date',
      FieldType.time => 'time',
      FieldType.dateTime => 'date_time',
      FieldType.boolean => 'boolean',
      FieldType.choice => 'choice',
      FieldType.multiChoice => 'multi_choice',
      FieldType.lookup => 'lookup',
      FieldType.barcode => 'barcode',
      FieldType.photoReference => 'photo_reference',
      FieldType.documentReference => 'document_reference',
      FieldType.gpsLocation => 'gps_location',
      FieldType.signature => 'signature',
      FieldType.computed => 'computed',
      FieldType.consent => 'consent',
    };
  }

  /// Reads a stored type name. An unknown name is a defect.
  static FieldType fieldTypeFromWire(String raw) {
    return switch (raw.trim()) {
      '' || 'text' => FieldType.text,
      'long_text' || 'longText' || 'long text' => FieldType.longText,
      'number' => FieldType.number,
      'decimal' => FieldType.decimal,
      'currency' => FieldType.currency,
      'percentage' => FieldType.percentage,
      'date' => FieldType.date,
      'time' => FieldType.time,
      'date_time' || 'dateTime' || 'date-time' => FieldType.dateTime,
      'boolean' => FieldType.boolean,
      'choice' => FieldType.choice,
      'multi_choice' ||
      'multiChoice' ||
      'multi-choice' => FieldType.multiChoice,
      'lookup' => FieldType.lookup,
      'barcode' => FieldType.barcode,
      'photo_reference' || 'photoReference' => FieldType.photoReference,
      'document_reference' ||
      'documentReference' => FieldType.documentReference,
      'gps_location' ||
      'gpsLocation' ||
      'GPS location' => FieldType.gpsLocation,
      'signature' => FieldType.signature,
      'computed' => FieldType.computed,
      'consent' => FieldType.consent,
      _ => throw const StorageFailure(
        message: 'That field type is not recognised.',
        recoveryAction: 'Pick a type from the list and save again.',
      ),
    };
  }

  /// Wire name stored in the input-mode column.
  static String inputModeToWire(InputMode mode) {
    return switch (mode) {
      InputMode.any => 'ANY',
      InputMode.manualOnly => 'MANUAL_ONLY',
      InputMode.aiAllowed => 'AI_ALLOWED',
      InputMode.auto => 'AUTO',
    };
  }

  /// Reads a stored input mode. Empty is [InputMode.any].
  static InputMode inputModeFromWire(String raw) {
    return switch (raw.trim().toUpperCase()) {
      '' || 'ANY' => InputMode.any,
      'MANUAL_ONLY' => InputMode.manualOnly,
      'AI_ALLOWED' => InputMode.aiAllowed,
      'AUTO' => InputMode.auto,
      _ => throw const StorageFailure(
        message: 'That input mode is not recognised.',
        recoveryAction: 'Pick an input mode from the list and save again.',
      ),
    };
  }
}
