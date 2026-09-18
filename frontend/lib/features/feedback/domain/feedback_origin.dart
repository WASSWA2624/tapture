/// Where feedback was given from, as the app shell sees it when Feedback is
/// tapped: the screen and route, the open project, and the shell's own
/// switches. The shell builds this; the feature never reads the router
/// itself.
final class FeedbackOrigin {
  /// Creates an origin.
  const FeedbackOrigin({
    required this.screen,
    required this.route,
    required this.routeName,
    required this.connectivity,
    required this.theme,
    required this.environment,
    this.projectId,
  });

  /// Stand-in when the shell cannot say, such as a feedback screen opened
  /// straight from its address.
  static const FeedbackOrigin unknown = FeedbackOrigin(
    screen: 'unknown',
    route: '',
    routeName: '',
    connectivity: 'unknown',
    theme: 'unknown',
    environment: 'unknown',
  );

  /// The screen's name, such as `Projects`.
  final String screen;

  /// The location, with its query, such as `/more/operator`.
  final String route;

  /// The route's declared name, such as `settingsOperator`.
  final String routeName;

  /// `online`, `metered`, `offline` or `offline by choice`.
  final String connectivity;

  /// `light`, `dark`, `outdoor`, or `system (dark)` when following the
  /// device.
  final String theme;

  /// `production` or `development`.
  final String environment;

  /// The open project, when one is open.
  final String? projectId;
}
