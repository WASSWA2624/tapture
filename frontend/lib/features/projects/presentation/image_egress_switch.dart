import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Per-project switch that keeps images off every extraction request.
final class ImageEgressSwitch extends StatelessWidget {
  /// Creates the switch. A null [holdImages] with no [failure] is empty.
  const ImageEgressSwitch({
    this.holdImages,
    this.failure,
    this.onChanged,
    super.key,
  });

  /// Whether images stay on the device.
  final bool? holdImages;

  /// Why the switch could not be read.
  final Failure? failure;

  /// Flips the switch for this project only.
  final ValueChanged<bool>? onChanged;

  /// Image paths a request may carry. Empty when images are held back.
  static List<String> paths({
    required bool holdImages,
    required List<String> images,
  }) {
    if (holdImages) {
      return const <String>[];
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    final bool? value = holdImages;
    if (value == null) {
      return const AppEmptyState(
        icon: AppIcons.project,
        headline: Copy.imageEgressTitle,
        message: Copy.imageEgressMessage,
      );
    }
    return AppSwitchTile(
      key: const ValueKey<String>('image-egress'),
      title: Copy.imageEgressTitle,
      description: value ? Copy.egressTextOnly : Copy.imageEgressMessage,
      value: value,
      onChanged: (bool next) => onChanged?.call(next),
    );
  }
}
