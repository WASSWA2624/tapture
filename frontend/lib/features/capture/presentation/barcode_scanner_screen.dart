import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/barcode/barcode.dart';
import 'package:tapture/core/camera/camera.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import 'barcode_continuous_mode.dart';
import 'barcode_scanner_controller.dart';

/// One-handed barcode scan inside a visible scan region, with the torch
/// where the device has one and the decoded value held for confirm or
/// rescan (§25). Count mode keeps the scanner open and tallies every code
/// for stock counting, with the last scan undoable.
final class BarcodeScannerScreen extends ConsumerStatefulWidget {
  /// Creates a scanner screen.
  const BarcodeScannerScreen({
    required this.scanner,
    required this.onConfirmed,
    super.key,
  });

  /// Scanner port.
  final BarcodeScannerService scanner;

  /// Confirmed raw value.
  final ValueChanged<String> onConfirmed;

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  BarcodeScannerController get _controller =>
      ref.read(barcodeScannerControllerProvider(widget.scanner).notifier);

  @override
  void initState() {
    super.initState();
    unawaited(_controller.start());
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final BarcodeScanState scan = ref.watch(
      barcodeScannerControllerProvider(widget.scanner),
    );
    final BarcodeScannerService scanner = widget.scanner;
    return AppPage(
      title: localCopy.barcodeTitle,
      compactBar: true,
      scrollable: false,
      inset: false,
      actions: <Widget>[
        if (scan.started && scanner.torchSupported)
          AppIconButton(
            icon: scan.torchOn ? AppIcons.flashOn : AppIcons.flashOff,
            semanticLabel: localCopy.barcodeTorch,
            tooltip: localCopy.barcodeTorch,
            selected: scan.torchOn,
            onPressed: () => unawaited(_controller.toggleTorch()),
          ),
        if (scan.failure == null)
          AppIconButton(
            icon: AppIcons.checklist,
            semanticLabel: localCopy.barcodeCountMode,
            tooltip: localCopy.barcodeCountMode,
            selected: scan.counting,
            onPressed: () => _controller.setCounting(!scan.counting),
          ),
      ],
      footer: _footer(scan),
      body: switch (scan.failure) {
        final failure? => Center(
          child: SingleChildScrollView(
            child: AppErrorState(
              failure: failure,
              onRetry: () => unawaited(_controller.start()),
            ),
          ),
        ),
        null when scan.counting => LayoutBuilder(
          builder: (BuildContext context, BoxConstraints space) => Flex(
            // The tally sits beside the preview when there is more width
            // than height, and under it otherwise.
            direction: space.maxWidth > space.maxHeight
                ? Axis.horizontal
                : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: _Viewfinder(scanner: scanner)),
              Expanded(child: BarcodeContinuousMode(scans: scan.counted)),
            ],
          ),
        ),
        null => _Viewfinder(
          scanner: scanner,
          banner: _banner(scan, localizedCopy: Copy.of(context)),
        ),
      },
    );
  }

  Widget? _footer(BarcodeScanState scan) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (scan.failure != null) {
      return null;
    }
    if (scan.counting) {
      return AppButton(
        label: localCopy.barcodeUndoLast,
        variant: AppButtonVariant.secondary,
        expand: true,
        onPressed: scan.counted.isEmpty ? null : _controller.undoLast,
      );
    }
    final String? code = scan.code;
    if (code == null) {
      return null;
    }
    return ResponsivePair(
      start: AppButton(
        label: localCopy.barcodeRescan,
        variant: AppButtonVariant.secondary,
        expand: true,
        onPressed: _controller.rescan,
      ),
      end: AppPrimaryAction(
        label: localCopy.barcodeConfirm,
        onPressed: () => widget.onConfirmed(code),
      ),
    );
  }
}

/// The held code, or what to do next.
AppBanner _banner(BarcodeScanState scan, {LocalizedCopy? localizedCopy}) {
  final String? code = scan.code;
  if (code != null) {
    return AppBanner(
      message: code,
      icon: AppIcons.success,
      tone: SnackTone.success,
    );
  }
  return scan.unreadable
      ? AppBanner(
          message: (localizedCopy ?? Copy.english).barcodeUnreadable,
          icon: AppIcons.warning,
          tone: SnackTone.warning,
        )
      : AppBanner(
          message: (localizedCopy ?? Copy.english).barcodeNoCode,
          icon: AppIcons.info,
          tone: SnackTone.info,
        );
}

/// The live preview with the scan region drawn over it, and [banner] along
/// its foot.
final class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.scanner, this.banner});

  final BarcodeScannerService scanner;
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    final Widget? foot = banner;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (scanner case final CameraPreviewSurface surface)
          surface.buildPreview(),
        const _ScanRegion(),
        if (foot != null) Align(alignment: Alignment.bottomCenter, child: foot),
      ],
    );
  }
}

/// The square a code is read inside, drawn over the preview where the
/// scanner reads ([BarcodeScannerService.scanRegionShare]).
final class _ScanRegion extends StatelessWidget {
  const _ScanRegion();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side =
            min(constraints.maxWidth, constraints.maxHeight) *
            BarcodeScannerService.scanRegionShare;
        return Center(
          child: SizedBox.square(
            dimension: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.colors.primary,
                  width: Space.x0,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
