part of 'app_chip.dart';

/// Lays [AppChip]s out in a wrapping row or a horizontal scroller.
///
/// Neither mode clips a label: wrap gives the next line, scroll keeps the
/// full string in the scroll extent.
class AppChipRow extends StatelessWidget {
  /// Creates a chip row. [scrollable] false wraps; true scrolls sideways.
  const AppChipRow({super.key, required this.chips, this.scrollable = false});

  /// Chips to show, in order.
  final List<AppChip> chips;

  /// When true, chips stay on one line and the row scrolls. When false,
  /// they wrap.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < chips.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: Space.x1),
              chips[i],
            ],
          ],
        ),
      );
    }
    return Wrap(spacing: Space.x1, runSpacing: Space.x2, children: chips);
  }
}
