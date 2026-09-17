import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/widgets/global_error_page.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/logging/logger.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/error_boundary.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/onboarding/presentation/first_run_screen.dart';

void main() {
  testWidgets(
    'a throwing subtree shows the recovery page, three actions, and no way to destroy work',
    (WidgetTester tester) async {
      var openedBin = false;

      await _pumpThrowing(tester, onOpenRecycleBin: () => openedBin = true);

      expect(tester.takeException(), isA<StateError>());
      expect(find.byType(GlobalErrorPage), findsOneWidget);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text(Copy.workStillOnDevice), findsOneWidget);
      expect(find.text(Copy.restart), findsOneWidget);
      expect(find.text(Copy.exportLog), findsOneWidget);
      expect(find.text(Copy.openRecycleBin), findsOneWidget);
      expect(find.text(Copy.tryAgain), findsNothing);
      expect(find.text(Copy.clear), findsNothing);
      expect(find.text(Copy.discard), findsNothing);
      expect(
        find.textContaining(RegExp(r'clear data|reinstall|\breset\b|purge')),
        findsNothing,
      );
      expect(
        tester
            .widgetList<AppButton>(find.byType(AppButton))
            .any(
              (AppButton button) =>
                  button.variant == AppButtonVariant.destructive,
            ),
        isFalse,
      );

      await tester.tap(find.text(Copy.openRecycleBin));
      await tester.pump();
      expect(openedBin, isTrue);
    },
  );

  testWidgets('restart remounts under the same scope and keeps unsaved state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const _RestartHarness(),
        ),
      ),
    );

    expect(find.byType(ProviderScope), findsOneWidget);
    await tester.tap(find.text('keep'));
    await tester.pump();
    expect(find.text('typed draft'), findsOneWidget);

    await tester.tap(find.text('crash'));
    await tester.pump();
    expect(tester.takeException(), isA<StateError>());
    expect(find.byType(GlobalErrorPage), findsOneWidget);

    await tester.tap(find.text(Copy.restart));
    await tester.pump();

    expect(find.byType(GlobalErrorPage), findsNothing);
    expect(find.text('typed draft'), findsOneWidget);
    expect(find.byType(ProviderScope), findsOneWidget);
  });

  testWidgets(
    'export writes a shareable file with no record values or credentials',
    (WidgetTester tester) async {
      final Logger previous = Logger.current;
      addTearDown(() => Logger.current = previous);

      final Directory into = Directory.systemTemp.createTempSync(
        'tapture-076-',
      );
      addTearDown(() {
        try {
          if (into.existsSync()) {
            into.deleteSync(recursive: true);
          }
        } on FileSystemException {
          // Windows can keep the export handle until the isolate exits.
        }
      });

      final File yaml = File('tool/secret_patterns.yaml');
      expect(yaml.existsSync(), isTrue);
      final Logger logger = Logger(patternsYaml: yaml.readAsStringSync());
      Logger.current = logger;
      logger.info('net', 'sk-abcdefghijklmnopqrstuvwxyz12');
      logger.info('net', 'caption: field notes');
      logger.info('net', 'transcript: spoken words');

      File? shared;
      await _pumpThrowing(
        tester,
        exportDirectory: into,
        shareFile: (File file) async => shared = file,
        writeLog: _writeLogSync,
      );
      expect(tester.takeException(), isA<StateError>());

      await tester.tap(find.text(Copy.exportLog));
      await tester.pump();

      expect(shared, isNotNull);
      expect(shared!.existsSync(), isTrue);
      expect(shared!.parent.path, into.path);
      final String body = shared!.readAsStringSync();
      expect(body, contains('[redacted:provider_key]'));
      expect(body, isNot(contains('field notes')));
      expect(body, isNot(contains('spoken words')));
      expect(body, isNot(contains('sk-abcdefghijklmnopqrstuvwxyz12')));
    },
  );

  testWidgets('TaptureApp wraps the router in ErrorBoundary', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          firstRunCompletedOverride(),
          networkOnlineOverride(),
        ],
        child: const TaptureApp(),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(ErrorBoundary), findsOneWidget);
    expect(find.byType(TaptureApp), findsOneWidget);
  });
}

final NotifierProvider<_UnsavedDraft, String> _unsavedDraftProvider =
    NotifierProvider<_UnsavedDraft, String>(_UnsavedDraft.new);

class _UnsavedDraft extends Notifier<String> {
  @override
  String build() => '';

  void write(String value) => state = value;
}

class _RestartHarness extends StatefulWidget {
  const _RestartHarness();

  @override
  State<_RestartHarness> createState() => _RestartHarnessState();
}

class _RestartHarnessState extends State<_RestartHarness> {
  var _shouldThrow = false;

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      fallback: (Failure failure, VoidCallback retry) {
        return GlobalErrorPage(
          failure: failure,
          onRestart: () {
            _shouldThrow = false;
            retry();
          },
          onOpenRecycleBin: () {},
        );
      },
      child: Consumer(
        builder: (BuildContext _, WidgetRef ref, Widget? _) {
          if (_shouldThrow) {
            throw StateError('boom');
          }
          return Column(
            children: <Widget>[
              Text(ref.watch(_unsavedDraftProvider)),
              TextButton(
                onPressed: () {
                  ref.read(_unsavedDraftProvider.notifier).write('typed draft');
                },
                child: const Text('keep'),
              ),
              TextButton(
                onPressed: () => setState(() => _shouldThrow = true),
                child: const Text('crash'),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<Result<File>> _writeLogSync(Directory into) {
  return Future<Result<File>>.value(
    Result.capture(() {
      if (!into.existsSync()) {
        into.createSync(recursive: true);
      }
      final File file = File('${into.path}/${Logger.current.exportFileName}');
      file.writeAsStringSync(Logger.current.buffer.join('\n'));
      return file;
    }),
  );
}

Future<void> _pumpThrowing(
  WidgetTester tester, {
  VoidCallback? onOpenRecycleBin,
  Directory? exportDirectory,
  Future<void> Function(File file)? shareFile,
  Future<Result<File>> Function(Directory into)? writeLog,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 900);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: ErrorBoundary(
          fallback: (Failure failure, VoidCallback retry) {
            return GlobalErrorPage(
              failure: failure,
              onRestart: retry,
              onOpenRecycleBin: onOpenRecycleBin ?? () {},
              exportDirectory: exportDirectory,
              shareFile: shareFile,
              writeLog: writeLog,
            );
          },
          child: Builder(
            builder: (BuildContext _) {
              throw StateError('boom');
            },
          ),
        ),
      ),
    ),
  );
}
