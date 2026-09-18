part of 'feedback_workbook.dart';

/// What a column needs to know about the row beyond the entry itself.
final class _Row {
  const _Row({required this.local, this.screenshotRow});

  /// The submission time on the downloading device's wall clock.
  final DateTime local;

  /// Zero-based row of this entry's picture on the screenshot sheet.
  final int? screenshotRow;
}

/// One column of the feedback sheet: its header and how to fill it.
final class _Column {
  const _Column(this.spec, this.cell);

  final XlsxColumn spec;
  final XlsxCell Function(FeedbackEntry entry, _Row row) cell;
}

_Column _text(
  String header,
  double width,
  String? Function(FeedbackEntry entry) value, {
  bool wrap = false,
}) {
  return _Column(
    XlsxColumn(header, width: width, wrap: wrap),
    (FeedbackEntry entry, _Row _) => XlsxCell.textOrEmpty(value(entry)),
  );
}

/// A column the organisation's other exports carry that this device has no
/// value for yet: account details the backend holds (specification Part XI).
/// Kept, empty, so every export has the same columns in the same place.
_Column _blank(String header, double width, {bool wrap = false}) {
  return _Column(
    XlsxColumn(header, width: width, wrap: wrap),
    (FeedbackEntry _, _Row _) => XlsxCell.empty,
  );
}

/// The feedback sheet's columns: the shared layout first, in its order, then
/// the context only Tapture records.
List<_Column> _columns({required String localHeader}) {
  return <_Column>[
    _text(_idHeader, XlsxColumn.defaultWidth, (FeedbackEntry e) => e.reference),
    _Column(
      XlsxColumn(localHeader, width: _dateWidth),
      (FeedbackEntry _, _Row row) => XlsxCell.dateTime(row.local),
    ),
    _text(
      'Submitted At (UTC)',
      26,
      (FeedbackEntry e) => _iso(e.submittedAtUtc),
    ),
    _text('Category', 18, (FeedbackEntry e) => e.categoryLabel),
    _text('Feedback', 60, (FeedbackEntry e) => e.message, wrap: true),
    _text(
      'Submitted By',
      XlsxColumn.defaultWidth,
      (FeedbackEntry e) => e.context.submitter.exportLabel,
    ),
    _text('User Email', 30, (FeedbackEntry e) => _email(e)),
    _text('User Name', 24, (FeedbackEntry e) => e.context.operatorName),
    _text(
      'User ID',
      XlsxColumn.defaultWidth,
      (FeedbackEntry e) => e.context.accountId,
    ),
    _blank('Position Title', 20),
    _blank('Roles', 30, wrap: true),
    _blank('Permissions', 60, wrap: true),
    _blank('Tenant', 24),
    _blank('Tenant ID', XlsxColumn.defaultWidth),
    _blank('Facility', 24),
    _blank('Facility ID', XlsxColumn.defaultWidth),
    _blank('Subscription Plan', 22),
    _blank('Plan Code', XlsxColumn.defaultWidth),
    _blank('Plan Tier', 14),
    _blank('Subscription Status', 20),
    _text(_screenHeader, _screenWidth, (FeedbackEntry e) => e.context.screen),
    _text('Route', 32, (FeedbackEntry e) => e.context.route, wrap: true),
    _text('Route Name', 20, (FeedbackEntry e) => e.context.routeName),
    _text('Page URL', 40, (FeedbackEntry e) => e.context.pageUrl, wrap: true),
    _text('Platform', 12, (FeedbackEntry e) => e.context.platform),
    _text(
      'Device Type',
      14,
      (FeedbackEntry e) => e.context.deviceType.exportLabel,
    ),
    _text('App Version', 14, (FeedbackEntry e) => e.context.appVersion),
    _text('Environment', 14, (FeedbackEntry e) => e.context.environment),
    _text('Locale', 10, (FeedbackEntry e) => e.context.locale),
    _text('Time Zone', 24, (FeedbackEntry e) => _zone(e)),
    _text('Viewport (px)', 18, (FeedbackEntry e) => _viewport(e)),
    _text('Display (px)', 18, (FeedbackEntry e) => _display(e)),
    _text('Orientation', 12, (FeedbackEntry e) => e.context.orientation),
    _text('Breakpoint', 12, (FeedbackEntry e) => e.context.breakpoint),
    _text('Theme', 14, (FeedbackEntry e) => e.context.theme),
    _Column(
      const XlsxColumn('Text Scale', width: 10),
      (FeedbackEntry e, _Row _) => XlsxCell.number(e.context.textScale),
    ),
    _text('Connectivity', 16, (FeedbackEntry e) => e.context.connectivity),
    _text(
      'Device Clock (UTC)',
      26,
      (FeedbackEntry e) => _iso(e.context.capturedAtUtc),
    ),
    _text(
      'User Agent',
      40,
      (FeedbackEntry e) => e.context.userAgent,
      wrap: true,
    ),
    _text(
      'IP Address',
      18,
      (FeedbackEntry e) => e.context.addresses.join(', '),
      wrap: true,
    ),
    _Column(
      const XlsxColumn(_screenshotHeader, width: 18),
      (FeedbackEntry _, _Row row) => _screenshotLink(row.screenshotRow),
    ),
    _text('User Initials', 12, (FeedbackEntry e) => e.context.operatorInitials),
    _text('Project ID', 24, (FeedbackEntry e) => e.context.projectId),
    _text('Device ID', 38, (FeedbackEntry e) => e.context.deviceId),
    _text('Device Model', 18, (FeedbackEntry e) => e.context.deviceModel),
    _text(
      'OS Version',
      30,
      (FeedbackEntry e) => e.context.osVersion,
      wrap: true,
    ),
  ];
}

XlsxCell _screenshotLink(int? row) {
  if (row == null) {
    return XlsxCell.empty;
  }
  return XlsxCell.link(
    _viewScreenshot,
    linkSheet: _screenshotSheetName,
    linkCell: XlsxSheet.cellName(row, _imageColumn),
  );
}

/// `2026-09-15T21:40:52.998Z`: UTC to the millisecond.
String _iso(DateTime value) {
  return DateTime.fromMillisecondsSinceEpoch(
    value.millisecondsSinceEpoch,
    isUtc: true,
  ).toIso8601String();
}

/// The operator's contact when it is an email address.
String? _email(FeedbackEntry entry) {
  final String? contact = entry.context.operatorContact;
  return contact != null && contact.contains('@') ? contact : null;
}

/// `EAT (UTC+03:00)`.
String _zone(FeedbackEntry entry) {
  final int minutes = entry.context.utcOffsetMinutes;
  final String sign = minutes < 0 ? '-' : '+';
  final int whole = minutes.abs();
  final String offset = 'UTC$sign${_two(whole ~/ 60)}:${_two(whole % 60)}';
  final String zone = entry.context.timeZone;
  return zone.isEmpty ? offset : '$zone ($offset)';
}

/// `1280x585 @1.5x`.
String _viewport(FeedbackEntry entry) {
  final String size = _size(
    entry.context.viewportWidth,
    entry.context.viewportHeight,
  );
  return '$size @${_ratio(entry.context.devicePixelRatio)}x';
}

/// `853x480`.
String _display(FeedbackEntry entry) {
  return _size(entry.context.displayWidth, entry.context.displayHeight);
}

String _size(double width, double height) {
  return '${width.round()}x${height.round()}';
}

/// A pixel ratio without trailing zeros: `1`, `1.5`, `2.75`.
String _ratio(double value) {
  final String fixed = value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

const String _idHeader = 'Feedback ID';
const String _screenHeader = 'Screen';
const String _screenshotHeader = 'Screenshot';
const String _viewScreenshot = 'View screenshot';
const double _dateWidth = 22;
const double _screenWidth = 24;
