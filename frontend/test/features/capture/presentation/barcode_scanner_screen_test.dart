import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/barcode/barcode.dart';
import 'package:tapture/core/camera/camera.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/feedback/haptics.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/capture/presentation/barcode_scanner_screen.dart';

import '../../../support/fakes/fake_barcode_scanner_service.dart';
import '../../../support/pump_app.dart';

const BarcodeHit _first = BarcodeHit(rawValue: 'A-100', format: 'code128');
const BarcodeHit _second = BarcodeHit(rawValue: 'B-200', format: 'qr');

void main() {
  late List<String> played;
  late List<String> confirmed;

  Future<void> open(WidgetTester tester, BarcodeScannerService scanner) async {
    played = <String>[];
    confirmed = <String>[];
    await pumpApp(
      tester,
      BarcodeScannerScreen(scanner: scanner, onConfirmed: confirmed.add),
      overrides: <Override>[
        hapticsProvider.overrideWithValue(Haptics.fake(played: played)),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with no code yet it asks the operator to point at one', (
    WidgetTester tester,
  ) async {
    final FakeBarcodeScannerService scanner = FakeBarcodeScannerService();
    addTearDown(scanner.dispose);
    await open(tester, scanner);

    expect(find.text(Copy.barcodeNoCode), findsOneWidget);
    expect(find.text(Copy.barcodeConfirm), findsNothing);
    expect(scanner.startCalls, 1);
  });

  testWidgets('only the first code shows and one haptic fires', (
    WidgetTester tester,
  ) async {
    final FakeBarcodeScannerService scanner = FakeBarcodeScannerService();
    addTearDown(scanner.dispose);
    await open(tester, scanner);

    scanner
      ..emit(_first)
      ..emit(_second);
    await tester.pumpAndSettle();

    expect(find.text(_first.rawValue), findsOneWidget);
    expect(find.text(_second.rawValue), findsNothing);
    expect(played, <String>['selection']);
  });

  testWidgets('confirm returns the code', (WidgetTester tester) async {
    final FakeBarcodeScannerService scanner = FakeBarcodeScannerService(
      hits: const <BarcodeHit>[_first],
    );
    addTearDown(scanner.dispose);
    await open(tester, scanner);

    await tester.tap(find.text(Copy.barcodeConfirm));
    await tester.pumpAndSettle();

    expect(confirmed, <String>[_first.rawValue]);
  });

  testWidgets('rescan clears the code', (WidgetTester tester) async {
    final FakeBarcodeScannerService scanner = FakeBarcodeScannerService(
      hits: const <BarcodeHit>[_first],
    );
    addTearDown(scanner.dispose);
    await open(tester, scanner);

    await tester.tap(find.text(Copy.barcodeRescan));
    await tester.pumpAndSettle();

    expect(find.text(_first.rawValue), findsNothing);
    expect(find.text(Copy.barcodeNoCode), findsOneWidget);
    expect(find.text(Copy.barcodeConfirm), findsNothing);

    scanner.emit(_second);
    await tester.pumpAndSettle();
    expect(find.text(_second.rawValue), findsOneWidget);
    expect(played, <String>['selection', 'selection']);
  });

  testWidgets('an unreadable code says so and scanning carries on', (
    WidgetTester tester,
  ) async {
    final FakeBarcodeScannerService scanner = FakeBarcodeScannerService();
    addTearDown(scanner.dispose);
    await open(tester, scanner);

    scanner.fail(ProviderFailure(message: Copy.barcodeUnreadable));
    await tester.pumpAndSettle();
    expect(find.text(Copy.barcodeUnreadable), findsOneWidget);

    scanner.emit(_first);
    await tester.pumpAndSettle();
    expect(find.text(_first.rawValue), findsOneWidget);
  });

  testWidgets('the torch is hidden when unsupported', (
    WidgetTester tester,
  ) async {
    final FakeBarcodeScannerService scanner = FakeBarcodeScannerService(
      torchSupported: false,
    );
    addTearDown(scanner.dispose);
    await open(tester, scanner);

    expect(find.widgetWithText(AppButton, Copy.barcodeTorch), findsNothing);
  });

  testWidgets('the torch toggles and shows its state where supported', (
    WidgetTester tester,
  ) async {
    final FakeBarcodeScannerService scanner = FakeBarcodeScannerService();
    addTearDown(scanner.dispose);
    await open(tester, scanner);
    Semantics torch() => tester.widget<Semantics>(
      find.ancestor(
        of: find.widgetWithText(AppButton, Copy.barcodeTorch),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is Semantics && widget.properties.toggled != null,
        ),
      ),
    );
    expect(torch().properties.toggled, isFalse);

    await tester.tap(find.widgetWithText(AppButton, Copy.barcodeTorch));
    await tester.pumpAndSettle();

    expect(scanner.torchOn, isTrue);
    expect(torch().properties.toggled, isTrue);
  });

  testWidgets('a preview-surface scanner shows its preview', (
    WidgetTester tester,
  ) async {
    final FakeBarcodeScannerService inner = FakeBarcodeScannerService();
    addTearDown(inner.dispose);
    await open(tester, _SurfaceScanner(inner));

    expect(find.byKey(_SurfaceScanner.previewKey), findsOneWidget);
  });

  testWidgets('a refused scanner shows the unavailable message', (
    WidgetTester tester,
  ) async {
    final FakeBarcodeScannerService scanner = FakeBarcodeScannerService(
      startFailure: PermissionFailure(
        message: Copy.barcodeUnavailable,
        recoveryAction: Copy.barcodeAllowCamera,
      ),
    );
    addTearDown(scanner.dispose);
    await open(tester, scanner);

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(Copy.barcodeUnavailable), findsOneWidget);
    expect(find.text(Copy.barcodeAllowCamera), findsOneWidget);

    await tester.tap(find.text(Copy.tryAgain));
    await tester.pumpAndSettle();
    expect(scanner.startCalls, 2);
  });

  testWidgets('an unsupported platform shows the unavailable message', (
    WidgetTester tester,
  ) async {
    await open(tester, const BarcodeScannerService.unavailable());

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(Copy.barcodeUnavailable), findsOneWidget);
  });

  testWidgets('count mode tallies each new code once and undo takes the last '
      'back', (WidgetTester tester) async {
    final FakeBarcodeScannerService scanner = FakeBarcodeScannerService();
    addTearDown(scanner.dispose);
    await open(tester, scanner);

    await tester.tap(find.widgetWithText(AppButton, Copy.barcodeCountMode));
    await tester.pumpAndSettle();
    scanner
      ..emit(_first)
      ..emit(_first)
      ..emit(_second);
    await tester.pumpAndSettle();

    expect(find.text(Copy.barcodeScanCount(2)), findsOneWidget);
    expect(find.text(_first.rawValue), findsOneWidget);
    expect(find.text(_second.rawValue), findsOneWidget);
    expect(find.text(Copy.barcodeConfirm), findsNothing);
    expect(played, <String>['selection', 'selection']);

    await tester.tap(find.text(Copy.barcodeUndoLast));
    await tester.pumpAndSettle();

    expect(find.text(Copy.barcodeScanCount(1)), findsOneWidget);
    expect(find.text(_second.rawValue), findsNothing);
    expect(find.byType(BarcodeScannerScreen), findsOneWidget);
    expect(confirmed, isEmpty);
  });

  testWidgets('fifty distinct codes count fifty without leaving the screen', (
    WidgetTester tester,
  ) async {
    final FakeBarcodeScannerService scanner = FakeBarcodeScannerService();
    addTearDown(scanner.dispose);
    await open(tester, scanner);
    await tester.tap(find.widgetWithText(AppButton, Copy.barcodeCountMode));
    await tester.pumpAndSettle();

    for (int item = 0; item < 50; item++) {
      scanner.emit(BarcodeHit(rawValue: 'ITEM-$item', format: 'code128'));
    }
    await tester.pumpAndSettle();
    expect(find.text(Copy.barcodeScanCount(50)), findsOneWidget);

    await tester.tap(find.text(Copy.barcodeUndoLast));
    await tester.pumpAndSettle();
    expect(find.text(Copy.barcodeScanCount(49)), findsOneWidget);
    expect(find.byType(BarcodeScannerScreen), findsOneWidget);
  });

  testWidgets('leaving the scanner stops it', (WidgetTester tester) async {
    final FakeBarcodeScannerService scanner = FakeBarcodeScannerService();
    addTearDown(scanner.dispose);
    await open(tester, scanner);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(scanner.stopCalls, 1);
  });
}

/// A scanner that hands the screen a preview, as the device scanner does.
final class _SurfaceScanner
    implements BarcodeScannerService, CameraPreviewSurface {
  _SurfaceScanner(this._inner);

  static const Key previewKey = ValueKey<String>('scanner-preview');

  final FakeBarcodeScannerService _inner;

  @override
  Widget buildPreview() =>
      const ColoredBox(key: previewKey, color: Color(0xFF000000));

  @override
  bool get torchSupported => _inner.torchSupported;
  @override
  bool get torchOn => _inner.torchOn;
  @override
  Stream<BarcodeHit> get hits => _inner.hits;
  @override
  Future<Result<void>> start() => _inner.start();
  @override
  Future<Result<void>> stop() => _inner.stop();
  @override
  Future<void> setTorch(bool on) => _inner.setTorch(on);
}
