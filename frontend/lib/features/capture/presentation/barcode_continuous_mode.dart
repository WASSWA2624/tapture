import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

/// Count mode's running tally under the live scanner: how many codes have
/// been counted and each one, newest first, so the last scan is always in
/// view for undo (§25 continuous mode). The scanner screen owns the camera,
/// the repeat window and the undo control.
final class BarcodeContinuousMode extends StatelessWidget {
  /// Creates the tally of [scans], oldest first.
  const BarcodeContinuousMode({required this.scans, super.key});

  /// The codes counted so far, oldest first.
  final List<String> scans;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: scans.length + 1,
      itemBuilder: (BuildContext context, int index) {
        final LocalizedCopy localCopy = Copy.of(context);

        if (index == 0) {
          return AppBanner(
            message: localCopy.barcodeScanCount(scans.length),
            icon: AppIcons.checklist,
            tone: SnackTone.info,
          );
        }
        final int position = scans.length - index;
        return AppListTile(
          title: scans[position],
          subtitle: localCopy.barcodeCountPosition(position + 1),
          dense: true,
        );
      },
    );
  }
}
