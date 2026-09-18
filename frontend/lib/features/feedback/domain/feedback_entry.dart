import 'package:tapture/core/constants/app_constants.dart';

import 'feedback_category.dart';
import 'feedback_context.dart';

/// One piece of feedback the operator wrote, with the context it was
/// written in. Immutable; the operator can delete an entry but never edit
/// one.
final class FeedbackEntry {
  /// Creates an entry.
  const FeedbackEntry({
    required this.id,
    required this.number,
    required this.submittedAtUtc,
    required this.category,
    required this.message,
    required this.hasScreenshot,
    required this.context,
    this.otherCategory,
  });

  /// Reads a stored entry. Returns null when [json] is not an entry, so one
  /// damaged row cannot hide the rest.
  static FeedbackEntry? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final Map<String, Object?> map = Map<String, Object?>.from(json);
    final Object? id = map[_id];
    final Object? number = map[_number];
    final Object? submitted = map[_submittedAt];
    final Object? context = map[_context];
    if (id is! String || id.isEmpty || number is! int || submitted is! String) {
      return null;
    }
    final DateTime? submittedAt = DateTime.tryParse(submitted);
    if (submittedAt == null || context is! Map) {
      return null;
    }
    final Object? other = map[_otherCategory];
    final Object? message = map[_message];
    return FeedbackEntry(
      id: id,
      number: number,
      submittedAtUtc: submittedAt.toUtc(),
      category: FeedbackCategory.fromWire(map[_category]),
      otherCategory: other is String && other.trim().isNotEmpty ? other : null,
      message: message is String ? message : '',
      hasScreenshot: map[_hasScreenshot] == true,
      context: FeedbackContext.fromJson(Map<String, Object?>.from(context)),
    );
  }

  /// Stable identifier, also the screenshot's key.
  final String id;

  /// Sequence number on this device, never reused.
  final int number;

  /// When the entry was saved.
  final DateTime submittedAtUtc;

  /// The kind of feedback.
  final FeedbackCategory category;

  /// The operator's own name for the kind, when [category] is
  /// [FeedbackCategory.other].
  final String? otherCategory;

  /// What the operator wrote.
  final String message;

  /// Whether a screenshot is stored with the entry.
  final bool hasScreenshot;

  /// The moment the entry was written in.
  final FeedbackContext context;

  /// The reference a person quotes: `FBK0000001`.
  String get reference {
    final String digits = number.toString().padLeft(
      AppConstants.userFeedback.idDigits,
      '0',
    );
    return '${AppConstants.userFeedback.idPrefix}$digits';
  }

  /// The category as a workbook shows it, with the operator's own name for
  /// an "other" kind: `Other: Speed`.
  String get categoryLabel {
    final String? other = otherCategory;
    if (category == FeedbackCategory.other && other != null) {
      return '${category.exportLabel}: $other';
    }
    return category.exportLabel;
  }

  /// The stored form, keyed by explicit wire names.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      _id: id,
      _number: number,
      _submittedAt: submittedAtUtc.toUtc().toIso8601String(),
      _category: category.wireName,
      _otherCategory: otherCategory,
      _message: message,
      _hasScreenshot: hasScreenshot,
      _context: context.toJson(),
    };
  }
}

const String _id = 'id';
const String _number = 'number';
const String _submittedAt = 'submitted_at';
const String _category = 'category';
const String _otherCategory = 'other_category';
const String _message = 'message';
const String _hasScreenshot = 'has_screenshot';
const String _context = 'context';
