import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/settings/settings.dart' show SettingKeys;

import 'raw_refined_toggle.dart' show ValueSide;

/// Remembers the latest raw-or-refined choice (task 016 step 2).
final class ReviewSideMemory extends Notifier<ValueSide> {
  @override
  ValueSide build() {
    return ValueSide.fromStored(
      ref.watch(projectSettingsStoreProvider).read(SettingKeys.reviewValueSide),
    );
  }

  /// Makes [side] the starting side of every later field.
  Future<void> remember(ValueSide side) async {
    state = side;
    await ref
        .read(projectSettingsStoreProvider)
        .write(SettingKeys.reviewValueSide, side.name);
  }
}
