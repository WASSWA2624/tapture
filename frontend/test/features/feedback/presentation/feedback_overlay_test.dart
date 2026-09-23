import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/feedback/feedback.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft.dart';
import 'package:tapture/features/feedback/presentation/feedback_draft_controller.dart';
import 'package:tapture/features/feedback/presentation/feedback_overlay.dart';
import 'package:tapture/features/settings/domain/operator_profile.dart';
import 'package:tapture/features/settings/presentation/operator_profile_screen.dart';

void main() {
  testWidgets('Feedback stays above a dialog and captures the dialog', (
    WidgetTester tester,
  ) async {
    const Color evidence = Color(0xFF13A7C7);
    final _Harness harness = await _pump(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext _) {
                      return const Dialog(
                        shape: RoundedRectangleBorder(),
                        child: ColoredBox(
                          color: evidence,
                          child: SizedBox(
                            width: 220,
                            height: 180,
                            child: Center(child: Text('Target dialog')),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: const Text('Open dialog'),
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Target dialog'), findsOneWidget);

    await _openFeedback(tester, harness);

    expect(find.text('Target dialog'), findsOneWidget);
    expect(find.text(Copy.feedbackGive), findsOneWidget);
    final Uint8List shot = harness.draft!.shots.single.bytes;
    final bool containsDialog =
        await tester.runAsync(() => _containsColor(shot, evidence)) ?? false;
    expect(containsDialog, isTrue);

    await tester.tap(find.byIcon(Icons.feedback_outlined));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackGive), findsNothing);
    expect(find.text('Target dialog'), findsOneWidget);
  });

  testWidgets('Feedback stays above an app popup menu and captures it', (
    WidgetTester tester,
  ) async {
    const Color evidence = Color(0xFFE44D88);
    final _Harness harness = await _pump(
      tester,
      home: Scaffold(
        body: Center(
          child: PopupMenuButton<int>(
            color: evidence,
            shape: const RoundedRectangleBorder(),
            itemBuilder: (BuildContext _) {
              return const <PopupMenuEntry<int>>[
                PopupMenuItem<int>(value: 1, child: Text('App context action')),
              ];
            },
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Open app menu'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open app menu'));
    await tester.pumpAndSettle();
    expect(find.text('App context action'), findsOneWidget);

    await _openFeedback(tester, harness);

    expect(find.text('App context action'), findsOneWidget);
    expect(find.text(Copy.feedbackGive), findsOneWidget);
    final Uint8List shot = harness.draft!.shots.single.bytes;
    final bool containsMenu =
        await tester.runAsync(() => _containsColor(shot, evidence)) ?? false;
    expect(containsMenu, isTrue);
  });
}

Future<_Harness> _pump(WidgetTester tester, {required Widget home}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final ProviderContainer container = ProviderContainer(
    retry: (int _, Object _) => null,
    overrides: <Override>[
      operatorProfileOverride(
        load: () async => const OperatorProfile(name: 'Ada', initials: 'A'),
        save: (OperatorProfile profile) async =>
            Success<OperatorProfile>(profile),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(operatorProfileProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        builder: (BuildContext _, Widget? child) {
          return FeedbackOverlay(
            origin: FeedbackOrigin.unknown,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(container);
}

Future<void> _openFeedback(WidgetTester tester, _Harness harness) async {
  await tester.tap(find.byIcon(Icons.feedback_outlined));
  await tester.runAsync(() async {
    final DateTime deadline = DateTime.now().add(const Duration(seconds: 2));
    while (harness.draft == null && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pumpAndSettle();
  expect(harness.draft, isNotNull);
}

Future<bool> _containsColor(Uint8List png, Color color) async {
  final ui.Codec codec = await ui.instantiateImageCodec(png);
  final ui.FrameInfo frame = await codec.getNextFrame();
  final ui.Image image = frame.image;
  try {
    final ByteData? rgba = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (rgba == null) {
      return false;
    }
    for (int offset = 0; offset < rgba.lengthInBytes; offset += 4) {
      if (rgba.getUint8(offset) == (color.r * 255).round() &&
          rgba.getUint8(offset + 1) == (color.g * 255).round() &&
          rgba.getUint8(offset + 2) == (color.b * 255).round() &&
          rgba.getUint8(offset + 3) == (color.a * 255).round()) {
        return true;
      }
    }
    return false;
  } finally {
    image.dispose();
    codec.dispose();
  }
}

final class _Harness {
  const _Harness(this.container);

  final ProviderContainer container;

  FeedbackDraft? get draft => container.read(feedbackDraftProvider);
}
