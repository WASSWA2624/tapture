import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/files/blob_store_io.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/logging/logger.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/main.dart' as app;

/// Real native stores owned by one explicitly enabled device measurement.
final class DeviceMetricBootstrap {
  DeviceMetricBootstrap._(
    this.directory,
    this.secrets,
    this.database,
    this.root,
  );

  /// Allocates a unique sandbox without reading the installed app's stores.
  static Future<DeviceMetricBootstrap> create() async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'tapture-device-metrics-',
    );
    final SecureStorage secrets = SecureStorage.namespaced(
      'metrics_${DateTime.now().microsecondsSinceEpoch}',
    );
    final AppDatabase database = AppDatabase.open(
      directoryPath: '${directory.path}/database',
      keyStore: secrets,
    );
    return DeviceMetricBootstrap._(
      directory,
      secrets,
      database,
      StorageRoot(
        documentsDirectory: () async =>
            Directory('${directory.path}/documents'),
      ),
    );
  }

  /// The only directory cleanup may remove.
  final Directory directory;

  /// Real Keystore/Keychain namespace, including the fresh database key.
  final SecureStorage secrets;

  /// Lazy native SQLite database; opening/encryption happen during bootstrap.
  final AppDatabase database;

  /// Actual native file storage restricted to this sandbox.
  final StorageRoot root;
  AsyncCallback? _shutdown;

  /// Measures app bootstrap through the same production entry and providers.
  Future<void> start() async {
    _shutdown = await app.runDeviceMetricsApp(
      database: database,
      secrets: secrets,
      storageRoot: root,
      logger: Logger(persist: true, directoryPath: '${directory.path}/logs'),
      relayStore: folderBlobStore(
        () async => Directory('${directory.path}/relay'),
      ),
      feedbackStore: folderBlobStore(
        () async => Directory('${directory.path}/feedback'),
      ),
    );
  }

  /// Called after unmounting the app; drains maintenance before closing stores.
  Future<void> close() async {
    try {
      await _shutdown?.call();
    } finally {
      try {
        await database.close();
      } finally {
        await secrets.deleteAll();
        if (await directory.exists()) await directory.delete(recursive: true);
      }
    }
  }
}
