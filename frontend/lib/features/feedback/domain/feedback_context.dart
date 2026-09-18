import 'feedback_device_type.dart';
import 'feedback_origin.dart';
import 'feedback_submitter.dart';

/// Everything known about the moment feedback was given: who, where in the
/// app, on what device, in what window and in what state. Stored beside the
/// entry so an export can say it without asking the device again.
///
/// Nothing here leaves the device unless the operator exports it
/// (FE-SEC-10). No hardware identifier is kept (FE-SEC-07).
final class FeedbackContext {
  /// Creates a context.
  const FeedbackContext({
    required this.capturedAtUtc,
    required this.submitter,
    required this.screen,
    required this.route,
    required this.routeName,
    required this.platform,
    required this.deviceType,
    required this.appVersion,
    required this.environment,
    required this.locale,
    required this.timeZone,
    required this.utcOffsetMinutes,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.devicePixelRatio,
    required this.displayWidth,
    required this.displayHeight,
    required this.orientation,
    required this.breakpoint,
    required this.theme,
    required this.textScale,
    required this.connectivity,
    required this.userAgent,
    this.operatorName,
    this.operatorInitials,
    this.operatorContact,
    this.accountId,
    this.pageUrl,
    this.projectId,
    this.addresses = const <String>[],
    this.deviceId,
    this.deviceModel,
    this.osVersion,
  });

  /// Reads a stored context. Missing keys fall back rather than failing, so
  /// an entry written by an older build still opens.
  factory FeedbackContext.fromJson(Map<String, Object?> json) {
    return FeedbackContext(
      capturedAtUtc: _date(json[_capturedAt]),
      submitter: FeedbackSubmitter.fromWire(json[_submitter]),
      operatorName: _optional(json[_operatorName]),
      operatorInitials: _optional(json[_operatorInitials]),
      operatorContact: _optional(json[_operatorContact]),
      accountId: _optional(json[_accountId]),
      screen: _text(json[_screen]),
      route: _text(json[_route]),
      routeName: _text(json[_routeName]),
      pageUrl: _optional(json[_pageUrl]),
      projectId: _optional(json[_projectId]),
      platform: _text(json[_platform]),
      deviceType: FeedbackDeviceType.fromWire(json[_deviceType]),
      appVersion: _text(json[_appVersion]),
      environment: _text(json[_environment]),
      locale: _text(json[_locale]),
      timeZone: _text(json[_timeZone]),
      utcOffsetMinutes: _number(json[_utcOffset]).round(),
      viewportWidth: _number(json[_viewportWidth]),
      viewportHeight: _number(json[_viewportHeight]),
      devicePixelRatio: _number(json[_pixelRatio], fallback: 1),
      displayWidth: _number(json[_displayWidth]),
      displayHeight: _number(json[_displayHeight]),
      orientation: _text(json[_orientation]),
      breakpoint: _text(json[_breakpoint]),
      theme: _text(json[_theme]),
      textScale: _number(json[_textScale], fallback: 1),
      connectivity: _text(json[_connectivity]),
      userAgent: _text(json[_userAgent]),
      addresses: <String>[
        for (final Object? address in _list(json[_addresses]))
          if (address is String) address,
      ],
      deviceId: _optional(json[_deviceId]),
      deviceModel: _optional(json[_deviceModel]),
      osVersion: _optional(json[_osVersion]),
    );
  }

  /// Device clock when Feedback was tapped.
  final DateTime capturedAtUtc;

  /// Who wrote the entry.
  final FeedbackSubmitter submitter;

  /// The operator's name, when one is set.
  final String? operatorName;

  /// The operator's initials, when set.
  final String? operatorInitials;

  /// The operator's email or phone, when set. Never a secret.
  final String? operatorContact;

  /// The enrolled account, once the device has signed in.
  final String? accountId;

  /// See [FeedbackOrigin.screen].
  final String screen;

  /// See [FeedbackOrigin.route].
  final String route;

  /// See [FeedbackOrigin.routeName].
  final String routeName;

  /// The browser's address; null on a device.
  final String? pageUrl;

  /// See [FeedbackOrigin.projectId].
  final String? projectId;

  /// `web`, `android`, `ios`, `windows`, `macos` or `linux`.
  final String platform;

  /// Phone, tablet or desktop.
  final FeedbackDeviceType deviceType;

  /// The app version this binary was built as.
  final String appVersion;

  /// See [FeedbackOrigin.environment].
  final String environment;

  /// The interface locale, such as `en` or `en_UG`.
  final String locale;

  /// The zone name, such as `Africa/Kampala` or `EAT`.
  final String timeZone;

  /// How far the zone was ahead of UTC, in minutes.
  final int utcOffsetMinutes;

  /// Window width in logical pixels.
  final double viewportWidth;

  /// Window height in logical pixels.
  final double viewportHeight;

  /// Physical pixels per logical pixel.
  final double devicePixelRatio;

  /// Display width in logical pixels.
  final double displayWidth;

  /// Display height in logical pixels.
  final double displayHeight;

  /// `portrait` or `landscape`.
  final String orientation;

  /// The size class: `compact`, `medium` or `expanded`.
  final String breakpoint;

  /// See [FeedbackOrigin.theme].
  final String theme;

  /// Body text scale; 1 is the default.
  final double textScale;

  /// See [FeedbackOrigin.connectivity].
  final String connectivity;

  /// The browser's user agent, or the Dart runtime's.
  final String userAgent;

  /// Local network addresses; empty in a browser.
  final List<String> addresses;

  /// This install's identifier.
  final String? deviceId;

  /// The device model, or the OS name where no model is reported.
  final String? deviceModel;

  /// The operating system version.
  final String? osVersion;

  /// The stored form, keyed by explicit wire names.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      _capturedAt: capturedAtUtc.toUtc().toIso8601String(),
      _submitter: submitter.wireName,
      _operatorName: operatorName,
      _operatorInitials: operatorInitials,
      _operatorContact: operatorContact,
      _accountId: accountId,
      _screen: screen,
      _route: route,
      _routeName: routeName,
      _pageUrl: pageUrl,
      _projectId: projectId,
      _platform: platform,
      _deviceType: deviceType.wireName,
      _appVersion: appVersion,
      _environment: environment,
      _locale: locale,
      _timeZone: timeZone,
      _utcOffset: utcOffsetMinutes,
      _viewportWidth: viewportWidth,
      _viewportHeight: viewportHeight,
      _pixelRatio: devicePixelRatio,
      _displayWidth: displayWidth,
      _displayHeight: displayHeight,
      _orientation: orientation,
      _breakpoint: breakpoint,
      _theme: theme,
      _textScale: textScale,
      _connectivity: connectivity,
      _userAgent: userAgent,
      _addresses: addresses,
      _deviceId: deviceId,
      _deviceModel: deviceModel,
      _osVersion: osVersion,
    };
  }
}

const String _capturedAt = 'captured_at';
const String _submitter = 'submitted_by';
const String _operatorName = 'operator_name';
const String _operatorInitials = 'operator_initials';
const String _operatorContact = 'operator_contact';
const String _accountId = 'account_id';
const String _screen = 'screen';
const String _route = 'route';
const String _routeName = 'route_name';
const String _pageUrl = 'page_url';
const String _projectId = 'project_id';
const String _platform = 'platform';
const String _deviceType = 'device_type';
const String _appVersion = 'app_version';
const String _environment = 'environment';
const String _locale = 'locale';
const String _timeZone = 'time_zone';
const String _utcOffset = 'utc_offset_minutes';
const String _viewportWidth = 'viewport_width';
const String _viewportHeight = 'viewport_height';
const String _pixelRatio = 'device_pixel_ratio';
const String _displayWidth = 'display_width';
const String _displayHeight = 'display_height';
const String _orientation = 'orientation';
const String _breakpoint = 'breakpoint';
const String _theme = 'theme';
const String _textScale = 'text_scale';
const String _connectivity = 'connectivity';
const String _userAgent = 'user_agent';
const String _addresses = 'addresses';
const String _deviceId = 'device_id';
const String _deviceModel = 'device_model';
const String _osVersion = 'os_version';

String _text(Object? value) => value is String ? value : '';

String? _optional(Object? value) {
  return value is String && value.trim().isNotEmpty ? value : null;
}

double _number(Object? value, {double fallback = 0}) {
  return value is num ? value.toDouble() : fallback;
}

List<Object?> _list(Object? value) {
  return value is List ? List<Object?>.of(value) : const <Object?>[];
}

DateTime _date(Object? value) {
  final DateTime? parsed = value is String ? DateTime.tryParse(value) : null;
  return (parsed ?? DateTime.utc(1970)).toUtc();
}
