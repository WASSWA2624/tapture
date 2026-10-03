import 'dart:convert';

import 'package:tapture/core/copy/localized_message.dart';

/// The outcome of a destination's last connection check, kept on its row
/// as [DestinationCheck.encode] so the list can say when it last worked or
/// why it did not (task 021 step 2).
final class DestinationCheck {
  /// Records a check at [at]. [reason] is the plain-language failure, or
  /// null when the probe upload succeeded.
  const DestinationCheck({required this.at, this.reason, this.localizedReason});

  /// When the check ran, in UTC.
  final DateTime at;

  /// Why the check failed, or null when it passed.
  final String? reason;

  /// Serializable semantic reason, independently of the English audit string.
  final LocalizedMessage? localizedReason;

  /// Whether the probe upload succeeded.
  bool get passed => reason == null;

  /// Reads a stored outcome. Anything else, including nothing, is null.
  static DestinationCheck? decode(String? stored) {
    if (stored == null || stored.isEmpty) {
      return null;
    }
    try {
      final Object? json = jsonDecode(stored);
      if (json is! Map) {
        return null;
      }
      final Object? at = json['at'];
      final Object? reason = json['reason'];
      final Object? localized = json['localizedReason'];
      final DateTime? when = at is String ? DateTime.tryParse(at) : null;
      if (when == null) {
        return null;
      }
      return DestinationCheck(
        at: when.toUtc(),
        reason: reason is String && reason.isNotEmpty ? reason : null,
        localizedReason: _message(localized),
      );
    } on FormatException {
      return null;
    }
  }

  /// The stored form of this outcome.
  String encode() {
    return jsonEncode(<String, Object?>{
      'at': at.toUtc().toIso8601String(),
      'reason': ?reason,
      'localizedReason': ?localizedReason?.toJson(),
    });
  }

  static LocalizedMessage? _message(Object? value) {
    try {
      return value is Map
          ? LocalizedMessage.fromJson(value.cast<String, Object?>())
          : null;
    } on Object {
      // A legacy English reason remains usable if optional metadata is damaged.
      return null;
    }
  }
}
