import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/feedback/feedback.dart';
import 'package:tapture/features/feedback/presentation/download_feedback_controller.dart';
import 'package:tapture/features/feedback/presentation/download_feedback_view.dart';
import 'package:tapture/features/feedback/presentation/feedback_providers.dart';

import '../../../support/factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          feedbackClockProvider.overrideWith((Ref _) => clock),
          feedbackRepositoryProvider.overrideWith((Ref _) => repo),
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
}

Future<({ProviderContainer container, FeedbackEntry saved})> _ready({
  required DownloadService downloads,
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
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      feedbackClockProvider.overrideWith((Ref _) => clock),
      feedbackRepositoryProvider.overrideWith((Ref _) => repo),
      feedbackDownloadsProvider.overrideWith((Ref _) => downloads),
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
