import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/document_assets.dart';
import 'package:tapture/core/device/device.dart';
import 'package:tapture/core/device/platform_facts.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/time/clock.dart';

import '../feedback.dart';

/// Clock the feature stamps and names files with. Tests replace it with a
/// [FixedClock].
final Provider<Clock> feedbackClockProvider = Provider<Clock>((Ref _) {
  return const SystemClock();
});

/// This install's identifier. Production replaces the empty default.
final Provider<String> feedbackDeviceIdProvider = Provider<String>((Ref _) {
  return '';
});

/// Runtime facts captured at launch. Tests keep the stand-in.
final Provider<PlatformFacts> feedbackPlatformFactsProvider =
    Provider<PlatformFacts>((Ref _) {
      return const PlatformFacts.fake();
    });

/// Model and OS this binary reports. Tests keep the stand-in.
final Provider<DeviceDescriptor> feedbackDeviceProvider =
    Provider<DeviceDescriptor>((Ref _) {
      return const DeviceDescriptor.fake();
    });

/// The operator's feedback on this device. Tests and [main] share the
/// in-memory default so suites never open a folder (FE-TEST-03). Production
/// replaces it with [FeedbackRepositoryImpl.platform].
/// Kept alive: the overlay, download and delete all watch it (FE-STATE-09).
final Provider<FeedbackRepository> feedbackRepositoryProvider =
    Provider<FeedbackRepository>((Ref ref) {
      return FeedbackRepositoryImpl.memory(
        clock: ref.watch(feedbackClockProvider),
      );
    });

/// Where a workbook is handed to the operator. Tests keep the fake.
final Provider<DownloadService> feedbackDownloadsProvider =
    Provider<DownloadService>((Ref _) {
      return DownloadService.fake();
    });

/// Camera and library photos for a draft. Tests keep the fake; [main]
/// swaps in the platform picker.
final Provider<PhotoPicker> feedbackPhotosProvider = Provider<PhotoPicker>((
  Ref _,
) {
  return const PhotoPicker.fake();
});

/// Every stored entry, oldest first. Kept alive with the repository.
final StreamProvider<List<FeedbackEntry>> feedbackEntriesProvider =
    StreamProvider<List<FeedbackEntry>>(
      (Ref ref) => ref.watch(feedbackRepositoryProvider).watch(),
      retry: (int _, Object _) => null,
    );

/// The prompts generator every download ships beside the workbook. Null
/// when the asset cannot be read, so a download is never blocked by it.
/// Kept alive: the text never changes while the app runs.
final FutureProvider<String?> feedbackPromptGuideProvider =
    FutureProvider<String?>((Ref _) async {
      try {
        return await rootBundle.loadString(
          DocumentAssets.feedbackPromptsGenerator,
        );
      } on Object {
        return null;
      }
    });
