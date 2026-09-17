import 'dart:convert';

import 'package:tapture/core/constants/app_constants.dart';

/// The local operator identity every capture is attributed to.
///
/// [accountId] is filled by enrolment (498) and is null on every
/// pre-backend install, so signing in later adopts this profile rather
/// than replacing it.
final class OperatorProfile {
  /// Creates a profile. [name] and [initials] are required; [contact] and
  /// [accountId] stay optional until the operator or enrolment fills them.
  const OperatorProfile({
    required this.name,
    required this.initials,
    this.contact,
    this.accountId,
  });

  /// Reconstructs a profile from the device-profile row.
  factory OperatorProfile.fromStored({
    required String name,
    required String preferences,
    String? accountId,
  }) {
    final Map<String, Object?> stored = _decodePreferences(preferences);
    final Object? rawInitials = stored[AppConstants.operator.initialsKey];
    final String initials =
        rawInitials is String && rawInitials.trim().isNotEmpty
        ? rawInitials.trim()
        : initialsFrom(name);
    final Object? rawContact = stored[AppConstants.operator.contactKey];
    final String? contact = rawContact is String && rawContact.trim().isNotEmpty
        ? rawContact.trim()
        : null;
    return OperatorProfile(
      name: name,
      initials: initials,
      contact: contact,
      accountId: accountId,
    );
  }

  /// Display name written onto later captures.
  final String name;

  /// One to three characters, defaulted from [name] and overridable.
  final String initials;

  /// Optional email or phone. Never a secret.
  final String? contact;

  /// Filled by enrolment (498); null on every pre-backend install.
  final String? accountId;

  /// First letter of each word in [name], upper-cased, at most
  /// [AppConstants.operator.initialsMax] characters.
  static String initialsFrom(String name) {
    final List<String> words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return '';
    }
    final String letters = words
        .map((String word) => word[0])
        .join()
        .toUpperCase();
    final int max = AppConstants.operator.initialsMax;
    return letters.length <= max ? letters : letters.substring(0, max);
  }

  /// Whether [name] is present after trim.
  bool get hasName => name.trim().isNotEmpty;

  /// Whether [initials] is one to three characters after trim.
  bool get hasInitials {
    final int length = initials.trim().length;
    return length >= AppConstants.operator.initialsMin &&
        length <= AppConstants.operator.initialsMax;
  }

  /// Writes initials and contact into [existing] without dropping other keys.
  String mergePreferences(String existing) {
    final Map<String, Object?> stored = _decodePreferences(existing);
    stored[AppConstants.operator.initialsKey] = initials.trim();
    final String? value = contact?.trim();
    if (value == null || value.isEmpty) {
      stored.remove(AppConstants.operator.contactKey);
    } else {
      stored[AppConstants.operator.contactKey] = value;
    }
    return jsonEncode(stored);
  }

  /// Returns a copy with the provided fields replaced.
  OperatorProfile copyWith({
    String? name,
    String? initials,
    String? contact,
    String? accountId,
    bool clearContact = false,
    bool clearAccountId = false,
  }) {
    return OperatorProfile(
      name: name ?? this.name,
      initials: initials ?? this.initials,
      contact: clearContact ? null : (contact ?? this.contact),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
    );
  }

  @override
  int get hashCode => Object.hash(name, initials, contact, accountId);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is OperatorProfile &&
            other.name == name &&
            other.initials == initials &&
            other.contact == contact &&
            other.accountId == accountId);
  }
}

Map<String, Object?> _decodePreferences(String raw) {
  if (raw.isEmpty) {
    return <String, Object?>{};
  }
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is Map<String, Object?>) {
      return Map<String, Object?>.from(decoded);
    }
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }
  } on FormatException {
    // A broken map is treated as empty so a save can rewrite it.
  }
  return <String, Object?>{};
}
