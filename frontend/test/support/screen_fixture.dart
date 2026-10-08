/// A real route and the repository state needed to exercise its collection.
final class ScreenFixture {
  const ScreenFixture(
    this.screen,
    this.location, {
    this.project = true,
    this.template = false,
    this.record = false,
    this.dataset = false,
    this.action,
  });

  final String screen;
  final String location;
  final bool project;
  final bool template;
  final bool record;
  final bool dataset;
  final String? action;
}
