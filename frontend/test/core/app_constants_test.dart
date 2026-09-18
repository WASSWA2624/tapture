import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';

void main() {
  test('the contract page size and long edge are the nested values', () {
    expect(AppConstants.listPageSize, 50);
    expect(AppConstants.imageLongEdge, 1600);
    expect(AppConstants.listPageSize, AppConstants.lists.pageSize);
    expect(AppConstants.imageLongEdge, AppConstants.images.longEdge);
  });

  test('motion and debounce sit in a human range and stay ordered', () {
    expect(AppConstants.motion.short.inMilliseconds, inInclusiveRange(50, 250));
    expect(
      AppConstants.motion.medium.inMilliseconds,
      inInclusiveRange(150, 500),
    );
    expect(AppConstants.motion.long.inMilliseconds, inInclusiveRange(300, 800));
    expect(AppConstants.motion.short < AppConstants.motion.medium, isTrue);
    expect(AppConstants.motion.medium < AppConstants.motion.long, isTrue);
    expect(
      AppConstants.interaction.debounce.inMilliseconds,
      inInclusiveRange(100, 800),
    );
    expect(
      AppConstants.feedback.snack.inMilliseconds,
      inInclusiveRange(2000, 8000),
    );
  });

  test('list, image and cache numbers sit in a sane range', () {
    expect(AppConstants.lists.pageSize, inInclusiveRange(10, 200));
    expect(AppConstants.images.longEdge, inInclusiveRange(800, 4096));
    expect(AppConstants.images.quality, inInclusiveRange(1, 100));
    expect(AppConstants.images.thumbnailQuality, inInclusiveRange(1, 100));
    expect(AppConstants.images.thumbnailEdge, inInclusiveRange(48, 256));
    expect(AppConstants.images.previewEdge, inInclusiveRange(128, 1024));
    expect(
      AppConstants.images.thumbnailEdge < AppConstants.images.previewEdge,
      isTrue,
    );
    expect(AppConstants.images.concurrentDecodes, inInclusiveRange(1, 8));
    expect(AppConstants.images.cacheMaxAge.inDays, inInclusiveRange(1, 365));
    expect(AppConstants.images.cacheMaxBytes, greaterThan(1024 * 1024));
  });

  test('retention and confidence stay ordered and inside their scale', () {
    expect(AppConstants.retention.days, inInclusiveRange(1, 90));
    expect(AppConstants.confidence.medium, inInclusiveRange(0.0, 1.0));
    expect(AppConstants.confidence.high, inInclusiveRange(0.0, 1.0));
    expect(
      AppConstants.confidence.medium < AppConstants.confidence.high,
      isTrue,
    );
  });

  test('logging, storage and processing limits stay usable', () {
    expect(AppConstants.logging.bufferSize, inInclusiveRange(50, 5000));
    expect(AppConstants.logging.rotationCount, inInclusiveRange(1, 20));
    expect(AppConstants.logging.retentionDays, inInclusiveRange(1, 90));
    expect(AppConstants.logging.rebuildThreshold, inInclusiveRange(2, 200));
    expect(
      AppConstants.storage.criticalBytes < AppConstants.storage.lowBytes,
      isTrue,
    );
    expect(AppConstants.storage.criticalBytes, greaterThan(0));
    expect(AppConstants.processing.extractionImageCap, inInclusiveRange(5, 32));
    expect(
      AppConstants.processing.perceptualHashDistance,
      inInclusiveRange(1, 32),
    );
    expect(
      AppConstants.hashing.chunkBytes,
      inInclusiveRange(4 * 1024, 1024 * 1024),
    );
    expect(AppConstants.operator.initialsMin, 1);
    expect(AppConstants.operator.initialsMax, 3);
    expect(
      AppConstants.operator.initialsMin < AppConstants.operator.initialsMax,
      isTrue,
    );
    expect(AppConstants.operator.initialsKey, isNotEmpty);
    expect(AppConstants.operator.contactKey, isNotEmpty);
    expect(
      AppConstants.operator.initialsKey,
      isNot(AppConstants.operator.contactKey),
    );
    expect(AppConstants.lock.pinMin, 4);
    expect(AppConstants.lock.pinMax, 8);
    expect(AppConstants.lock.pinMin < AppConstants.lock.pinMax, isTrue);
    expect(AppConstants.lock.saltBytes, inInclusiveRange(8, 64));
    expect(AppConstants.lock.backoff, isNotEmpty);
    for (int i = 1; i < AppConstants.lock.backoff.length; i++) {
      expect(
        AppConstants.lock.backoff[i - 1] < AppConstants.lock.backoff[i],
        isTrue,
      );
    }
  });

  test('folder and import ceilings stay below hostile sizes', () {
    expect(AppConstants.folders.maxSegmentLength, inInclusiveRange(16, 255));
    expect(AppConstants.folders.idSuffixLength, inInclusiveRange(2, 16));
    expect(AppConstants.folders.defaultStrategy, isNotEmpty);
    expect(AppConstants.imports.sniffHeaderBytes, inInclusiveRange(8, 4096));
    expect(
      AppConstants.imports.imageMaxBytes,
      greaterThan(AppConstants.imports.sniffHeaderBytes),
    );
    expect(
      AppConstants.imports.documentMaxBytes,
      greaterThan(AppConstants.imports.sniffHeaderBytes),
    );
    expect(
      AppConstants.imports.spreadsheetMaxBytes,
      greaterThan(AppConstants.imports.sniffHeaderBytes),
    );
    expect(
      AppConstants.imports.audioMaxBytes,
      greaterThan(AppConstants.imports.sniffHeaderBytes),
    );
    expect(
      AppConstants.imports.bundleMaxBytes,
      greaterThan(AppConstants.imports.imageMaxBytes),
    );
    expect(
      AppConstants.imports.archiveUncompressedMaxBytes,
      greaterThan(AppConstants.imports.bundleMaxBytes),
    );
  });

  test('no two storage key names collide', () {
    final List<String> keys = <String>[
      AppConstants.secrets.pinSalt,
      AppConstants.secrets.pinHash,
      AppConstants.secrets.pinBackoff,
      AppConstants.secrets.providerCredential,
      AppConstants.secrets.relayProject,
      AppConstants.secrets.cloudAccess,
      AppConstants.secrets.cloudRefresh,
      AppConstants.secrets.databaseEncryption,
      AppConstants.preferences.themeMode,
      AppConstants.preferences.firstRun,
    ];

    expect(keys.every((String key) => key.isNotEmpty), isTrue);
    expect(keys.toSet(), hasLength(keys.length));
  });
}
