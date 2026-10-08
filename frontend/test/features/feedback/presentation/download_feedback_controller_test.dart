import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/concurrency/concurrency.dart';
import 'package:tapture/core/constants/document_assets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/copy/l10n/app_localizations_en.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/feedback/feedback.dart';
import 'package:tapture/features/feedback/presentation/download_feedback_controller.dart';
import 'package:tapture/features/feedback/presentation/download_feedback_view.dart';
import 'package:tapture/features/feedback/presentation/feedback_browser.dart';
import 'package:tapture/features/feedback/presentation/feedback_providers.dart';

import '../../../support/factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'download failure semantics survive controls and locale changes',
    (WidgetTester tester) async {
      final LocalizedMessage message = Copy.messages.feedbackShotsFull;
      final Failure failure = ValidationFailure(localizedMessage: message);
      final ready = await _ready(
        downloads: DownloadService.fake(),
        encoder: (FeedbackArchive _, CancellationToken _) async =>
            FailureResult<Uint8List>(failure),
      );
      final DownloadFeedbackController controller = ready.container.read(
        downloadFeedbackControllerProvider.notifier,
      );
      expect(
        await controller.download(<FeedbackEntry>[ready.saved]),
        isA<FailureResult<String?>>(),
      );
      expect(
        ready.container.read(downloadFeedbackControllerProvider).error,
        message.fallback,
      );
      controller.toggleMoreFilters();
      expect(
        ready.container
            .read(downloadFeedbackControllerProvider)
            .localizedError
            ?.toJson(),
        message.toJson(),
      );
      Future<void> show(Locale locale) => tester.pumpWidget(
        UncontrolledProviderScope(
          container: ready.container,
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildTheme(brightness: Brightness.light),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Consumer(
                  builder: (BuildContext context, WidgetRef ref, Widget? _) {
                    final DownloadFeedbackView view = ref.watch(
                      downloadFeedbackControllerProvider,
                    );
                    return FeedbackBrowser(
                      all: <FeedbackEntry>[ready.saved],
                      matching: <FeedbackEntry>[ready.saved],
                      visible: view.visible,
                      filter: view.filter,
                      clock: ref.watch(feedbackClockProvider),
                      moreFilters: view.moreFilters,
                      onFilter: controller.setFilter,
                      onToggleMoreFilters: controller.toggleMoreFilters,
                      onShowMore: controller.showMore,
                      error: view.error,
                      localizedError: view.localizedError,
                      tile: (FeedbackEntry _, int _) => const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await show(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text(message.fallback), findsOneWidget);
      await show(const Locale('en', 'XA'));
      await tester.pumpAndSettle();
      expect(
        find.text(LocalizedCopy(AppLocalizationsEnXa()).resolve(message)),
        findsOneWidget,
      );
      expect(find.text(message.fallback), findsNothing);
      expect(
        ready.container.read(downloadFeedbackControllerProvider).error,
        message.fallback,
      );
      controller.setFilter(const FeedbackFilter());
      await tester.pumpAndSettle();
      expect(
        ready.container.read(downloadFeedbackControllerProvider).error,
        isNull,
      );
      expect(
        ready.container.read(downloadFeedbackControllerProvider).localizedError,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'a download ships the workbook, the images and the prompts guide',
    () async {
      final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 18, 7, 2));
      final FeedbackRepositoryImpl repo = FeedbackRepositoryImpl.memory(
        clock: clock,
      );
      final FeedbackEntry saved = _ok(
        await repo.add(
          category: FeedbackCategory.error,
          message: 'The list is slow',
          context: aFeedbackEntry().context,
          screenshots: <Uint8List>[aFeedbackPng, aFeedbackPng],
        ),
      );
      Uint8List? zipped;
      final String guide = File(
        DocumentAssets.feedbackPromptsGenerator,
      ).readAsStringSync();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          feedbackClockProvider.overrideWith((Ref _) => clock),
          feedbackRepositoryProvider.overrideWith((Ref _) => repo),
          feedbackPromptGuideProvider.overrideWith((Ref _) async => guide),
          feedbackDownloadsProvider.overrideWith(
            (Ref _) => DownloadService.fake(
              onSave: (String _, Uint8List bytes, String _) => zipped = bytes,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final ProviderSubscription<Object?> screen = container.listen(
        downloadFeedbackControllerProvider,
        (Object? _, Object? _) {},
      );
      addTearDown(screen.close);

      _ok(
        await container
            .read(downloadFeedbackControllerProvider.notifier)
            .download(<FeedbackEntry>[saved]),
      );

      final Archive zip = ZipDecoder().decodeBytes(zipped!);
      final List<String> names = <String>[
        for (final ArchiveFile file in zip.files)
          if (file.isFile) file.name,
      ];
      expect(names, contains(FeedbackArchive.guideFileName));
      expect(
        utf8.decode(zip.findFile(FeedbackArchive.guideFileName)!.content),
        guide,
      );
      expect(names, contains('screenshots/${saved.reference}.png'));
      expect(names, contains('screenshots/${saved.reference}-2.png'));
      expect(
        names.where((String name) => name.endsWith('.xlsx')),
        hasLength(1),
      );
    },
  );

  test('a cancelled saveAs leaves the controller idle with no error', () async {
    final ({ProviderContainer container, FeedbackEntry saved}) ready =
        await _ready(
          downloads: DownloadService.fake(
            canChooseLocation: true,
            saveAsCancel: true,
          ),
        );

    final Result<String?> result = await ready.container
        .read(downloadFeedbackControllerProvider.notifier)
        .download(<FeedbackEntry>[ready.saved], chooseLocation: true);
    final DownloadFeedbackView view = ready.container.read(
      downloadFeedbackControllerProvider,
    );

    expect(
      result.fold((Failure failure) => failure, (_) => null),
      isA<CancelledFailure>(),
    );
    expect(view.busy, isFalse);
    expect(view.error, isNull);
  });

  test('a successful saveAs returns the archive name', () async {
    String? savedAs;
    final ({ProviderContainer container, FeedbackEntry saved}) ready =
        await _ready(
          downloads: DownloadService.fake(
            canChooseLocation: true,
            onSaveAs: (String name, Uint8List _, String _) => savedAs = name,
          ),
        );

    final String? name = _ok(
      await ready.container
          .read(downloadFeedbackControllerProvider.notifier)
          .download(<FeedbackEntry>[ready.saved], chooseLocation: true),
    );

    expect(savedAs, isNotNull);
    expect(name, savedAs);
    expect(name, endsWith('.zip'));
  });

  test('a failed worker leaves evidence intact and a retry succeeds', () async {
    bool refuse = true;
    int downloads = 0;
    const StorageFailure failure = StorageFailure(
      message: 'The archive could not be created.',
      recoveryAction: 'Free some space, then try again.',
    );
    final ({ProviderContainer container, FeedbackEntry saved}) ready =
        await _ready(
          downloads: DownloadService.fake(
            onSave: (String _, Uint8List _, String _) => downloads++,
          ),
          encoder: (FeedbackArchive archive, CancellationToken cancel) async {
            if (refuse) return const FailureResult<Uint8List>(failure);
            return runIsolate(FeedbackArchive.encode, archive, cancel: cancel);
          },
        );
    final DownloadFeedbackController controller = ready.container.read(
      downloadFeedbackControllerProvider.notifier,
    );

    expect(
      await controller.download(<FeedbackEntry>[ready.saved]),
      isA<FailureResult<String?>>(),
    );
    expect(downloads, 0);
    expect(
      ready.container.read(downloadFeedbackControllerProvider).busy,
      isFalse,
    );
    expect(
      ready.container.read(downloadFeedbackControllerProvider).error,
      failure.message,
    );
    expect(
      await ready.container.read(feedbackRepositoryProvider).watch().first,
      <FeedbackEntry>[ready.saved],
    );

    refuse = false;
    _ok(await controller.download(<FeedbackEntry>[ready.saved]));
    expect(downloads, 1);
    expect(
      ready.container.read(downloadFeedbackControllerProvider).error,
      isNull,
    );
  });
}

Future<({ProviderContainer container, FeedbackEntry saved})> _ready({
  required DownloadService downloads,
  FeedbackArchiveEncoder? encoder,
}) async {
  final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 18, 7, 2));
  final FeedbackRepositoryImpl repo = FeedbackRepositoryImpl.memory(
    clock: clock,
  );
  final FeedbackEntry saved = _ok(
    await repo.add(
      category: FeedbackCategory.error,
      message: 'The list is slow',
      context: aFeedbackEntry().context,
    ),
  );
  final String guide = File(
    DocumentAssets.feedbackPromptsGenerator,
  ).readAsStringSync();
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      feedbackClockProvider.overrideWith((Ref _) => clock),
      feedbackRepositoryProvider.overrideWith((Ref _) => repo),
      feedbackPromptGuideProvider.overrideWith((Ref _) async => guide),
      feedbackDownloadsProvider.overrideWith((Ref _) => downloads),
      if (encoder != null)
        feedbackArchiveEncoderProvider.overrideWith((Ref _) => encoder),
    ],
  );
  addTearDown(container.dispose);
  final ProviderSubscription<Object?> screen = container.listen(
    downloadFeedbackControllerProvider,
    (Object? _, Object? _) {},
  );
  addTearDown(screen.close);
  return (container: container, saved: saved);
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
