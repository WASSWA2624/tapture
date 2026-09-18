import 'feedback_category.dart';
import 'feedback_device_type.dart';
import 'feedback_entry.dart';
import 'feedback_screenshot_filter.dart';
import 'feedback_submitter.dart';

/// Which feedback a download or a delete applies to. An empty set means
/// "any" for that facet, so the default filter lets everything through.
final class FeedbackFilter {
  /// Creates a filter. [fromUtc] and [toUtc] are both inclusive.
  const FeedbackFilter({
    this.categories = const <FeedbackCategory>{},
    this.fromUtc,
    this.toUtc,
    this.screens = const <String>{},
    this.platforms = const <String>{},
    this.deviceTypes = const <FeedbackDeviceType>{},
    this.submitters = const <FeedbackSubmitter>{},
    this.screenshot = FeedbackScreenshotFilter.any,
    this.search = '',
  });

  /// Types to keep; empty keeps every type.
  final Set<FeedbackCategory> categories;

  /// Earliest submission kept, or null for no lower bound.
  final DateTime? fromUtc;

  /// Latest submission kept, or null for no upper bound.
  final DateTime? toUtc;

  /// Screens to keep; empty keeps every screen.
  final Set<String> screens;

  /// Platforms to keep; empty keeps every platform.
  final Set<String> platforms;

  /// Device types to keep; empty keeps every type.
  final Set<FeedbackDeviceType> deviceTypes;

  /// Submitters to keep; empty keeps everyone.
  final Set<FeedbackSubmitter> submitters;

  /// Whether a screenshot must be attached, absent, or either.
  final FeedbackScreenshotFilter screenshot;

  /// Text the message, the named type or the reference must contain,
  /// ignoring case. Blank matches everything.
  final String search;

  /// Whether this filter lets every entry through.
  bool get isEmpty {
    return categories.isEmpty &&
        fromUtc == null &&
        toUtc == null &&
        screens.isEmpty &&
        platforms.isEmpty &&
        deviceTypes.isEmpty &&
        submitters.isEmpty &&
        screenshot == FeedbackScreenshotFilter.any &&
        search.trim().isEmpty;
  }

  /// Whether the range ends before it starts, which matches nothing.
  bool get isRangeBackwards {
    final DateTime? from = fromUtc;
    final DateTime? to = toUtc;
    return from != null && to != null && from.isAfter(to);
  }

  /// Whether [entry] passes every facet.
  bool matches(FeedbackEntry entry) {
    final DateTime at = entry.submittedAtUtc;
    final DateTime? from = fromUtc;
    final DateTime? to = toUtc;
    if (from != null && at.isBefore(from)) {
      return false;
    }
    if (to != null && at.isAfter(to)) {
      return false;
    }
    return _admits(categories, entry.category) &&
        _admits(screens, entry.context.screen) &&
        _admits(platforms, entry.context.platform) &&
        _admits(deviceTypes, entry.context.deviceType) &&
        _admits(submitters, entry.context.submitter) &&
        screenshot.admits(hasScreenshot: entry.hasScreenshot) &&
        _mentions(entry);
  }

  /// The entries [matches] keeps, newest first.
  List<FeedbackEntry> apply(Iterable<FeedbackEntry> entries) {
    return newestFirst(entries.where(matches));
  }

  /// A copy with the given facets replaced. [clearFrom] and [clearTo] drop a
  /// bound, since null already means "unchanged".
  FeedbackFilter copyWith({
    Set<FeedbackCategory>? categories,
    DateTime? fromUtc,
    DateTime? toUtc,
    bool clearFrom = false,
    bool clearTo = false,
    Set<String>? screens,
    Set<String>? platforms,
    Set<FeedbackDeviceType>? deviceTypes,
    Set<FeedbackSubmitter>? submitters,
    FeedbackScreenshotFilter? screenshot,
    String? search,
  }) {
    return FeedbackFilter(
      categories: categories ?? this.categories,
      fromUtc: clearFrom ? null : (fromUtc ?? this.fromUtc),
      toUtc: clearTo ? null : (toUtc ?? this.toUtc),
      screens: screens ?? this.screens,
      platforms: platforms ?? this.platforms,
      deviceTypes: deviceTypes ?? this.deviceTypes,
      submitters: submitters ?? this.submitters,
      screenshot: screenshot ?? this.screenshot,
      search: search ?? this.search,
    );
  }

  /// [entries] sorted newest first, then by number for a stable order.
  static List<FeedbackEntry> newestFirst(Iterable<FeedbackEntry> entries) {
    return entries.toList()..sort((FeedbackEntry a, FeedbackEntry b) {
      final int byTime = b.submittedAtUtc.compareTo(a.submittedAtUtc);
      return byTime != 0 ? byTime : b.number.compareTo(a.number);
    });
  }

  /// The distinct screens in [entries], sorted, for the screen facet.
  static List<String> screensIn(Iterable<FeedbackEntry> entries) {
    return _distinct(entries.map((FeedbackEntry e) => e.context.screen));
  }

  /// The distinct platforms in [entries], sorted, for the platform facet.
  static List<String> platformsIn(Iterable<FeedbackEntry> entries) {
    return _distinct(entries.map((FeedbackEntry e) => e.context.platform));
  }

  bool _mentions(FeedbackEntry entry) {
    final String needle = search.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    return entry.message.toLowerCase().contains(needle) ||
        (entry.otherCategory ?? '').toLowerCase().contains(needle) ||
        entry.reference.toLowerCase().contains(needle);
  }
}

bool _admits<T>(Set<T> allowed, T value) {
  return allowed.isEmpty || allowed.contains(value);
}

List<String> _distinct(Iterable<String> values) {
  return values.where((String value) => value.isNotEmpty).toSet().toList()
    ..sort();
}
