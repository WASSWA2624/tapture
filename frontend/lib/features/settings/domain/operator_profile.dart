import 'dart:convert';

import 'package:tapture/core/constants/app_constants.dart';

/// The local operator identity every capture is attributed to.
///
/// [accountId] is filled by enrolment (498) and is null on every
/// pre-backend install, so signing in later adopts this profile rather
/// than replacing it.
final class OperatorProfile {
  /// Creates a profile. [name] and [initials] are required; [email],
  /// [phone] and [accountId] stay optional until the operator or
  /// enrolment fills them.
  const OperatorProfile({
    required this.name,
    required this.initials,
    this.email,
    this.phone,
    this.accountId,
  });

  /// Reconstructs a profile from the device-profile row.
  ///
  /// When both email and phone are empty, a leftover contact key
  /// migrates: a value containing `@` becomes email, otherwise phone.
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
    String? email = _optionalText(stored[AppConstants.operator.emailKey]);
    String? phone = _optionalText(stored[AppConstants.operator.phoneKey]);
    if (email == null && phone == null) {
      final String? legacy = _optionalText(
        stored[AppConstants.operator.contactKey],
      );
      if (legacy != null) {
        if (legacy.contains('@')) {
          email = legacy;
        } else {
          phone = legacy;
        }
      }
    }
    return OperatorProfile(
      name: name,
      initials: initials,
      email: email,
      phone: phone,
      accountId: accountId,
    );
  }

  /// Display name written onto later captures.
  final String name;

  /// One to three characters, defaulted from [name] and overridable.
  final String initials;

  /// Optional email. Never a secret.
  final String? email;

  /// Optional phone. Never a secret.
  final String? phone;

  /// Filled by enrolment (498); null on every pre-backend install.
  final String? accountId;

  /// Email if set, otherwise phone. Feedback still has one contact column.
  String? get contact {
    final String? mail = email?.trim();
    if (mail != null && mail.isNotEmpty) {
      return mail;
    }
    final String? tel = phone?.trim();
    if (tel != null && tel.isNotEmpty) {
      return tel;
    }
    return null;
  }

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

  /// Writes initials, email and phone into [existing] without dropping
  /// other keys, and stops writing the legacy contact key.
  String mergePreferences(String existing) {
    final Map<String, Object?> stored = _decodePreferences(existing);
    stored[AppConstants.operator.initialsKey] = initials.trim();
    _writeOptional(stored, AppConstants.operator.emailKey, email);
    _writeOptional(stored, AppConstants.operator.phoneKey, phone);
    stored.remove(AppConstants.operator.contactKey);
    return jsonEncode(stored);
  }

  /// Returns a copy with the provided fields replaced.
  OperatorProfile copyWith({
    String? name,
    String? initials,
    String? email,
    String? phone,
    String? accountId,
    bool clearEmail = false,
    bool clearPhone = false,
    bool clearAccountId = false,
  }) {
    return OperatorProfile(
      name: name ?? this.name,
      initials: initials ?? this.initials,
      email: clearEmail ? null : (email ?? this.email),
      phone: clearPhone ? null : (phone ?? this.phone),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
    );
  }

  @override
  int get hashCode => Object.hash(name, initials, email, phone, accountId);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is OperatorProfile &&
            other.name == name &&
            other.initials == initials &&
            other.email == email &&
            other.phone == phone &&
            other.accountId == accountId);
  }
}

String? _optionalText(Object? raw) {
  if (raw is String && raw.trim().isNotEmpty) {
    return raw.trim();
  }
  return null;
}

void _writeOptional(Map<String, Object?> stored, String key, String? value) {
  final String? trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    stored.remove(key);
  } else {
    stored[key] = trimmed;
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
