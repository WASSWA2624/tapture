import 'dart:convert';

import 'package:tapture/core/security/coordinate_policy.dart';

import 'field_def.dart';

/// Shared eligibility for evidence extraction and operator corrections.
abstract final class FieldInputPolicy {
  /// Automatic, operator-only and derived values never become AI targets.
  static bool canExtract(FieldDef field) =>
      (field.inputMode == InputMode.any ||
          field.inputMode == InputMode.aiAllowed) &&
      field.autoFill == null &&
      !_hasStoredSource(field) &&
      field.contextLevel == null &&
      !field.hidden &&
      field.type != FieldType.computed &&
      field.type != FieldType.consent;

  /// Visible business values may be corrected beside their captured original.
  static bool canCorrect(FieldDef field) =>
      !field.hidden &&
      field.type != FieldType.computed &&
      !_reserved.contains(field.fieldKey.trim().toLowerCase()) &&
      !CoordinatePolicy.isField(
        key: field.fieldKey,
        type: field.type.name,
        autoFill: field.autoFill?.name,
        validation: jsonEncode(field.validation),
      );

  static bool _hasStoredSource(FieldDef field) =>
      switch (field.validation['_tapture']) {
        final Map<Object?, Object?> metadata => metadata['autoFill'] != null,
        _ => false,
      };
}

const Set<String> _reserved = <String>{
  'record_uid',
  'record_number',
  'template_key',
  'template_version',
  'captured_by_user_id',
  'captured_by_name',
  'device_id',
  'created_at',
  'updated_at',
  'updated_by_user_id',
  'record_status',
  'sync_state',
};
