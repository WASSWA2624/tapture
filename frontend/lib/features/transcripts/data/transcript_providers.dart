import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/transcript_repository.dart';
import 'transcript_repository_impl.dart';

/// The transcript store. Tests override it; `main` overrides it with the
/// store over the database opened there, stamped with the device's id. It
/// is kept for the app's life, so a transcript reopened for its remaining
/// audio is restored when its sink finishes.
final Provider<TranscriptRepository> transcriptRepositoryProvider =
    Provider<TranscriptRepository>((Ref ref) {
      return TranscriptRepositoryImpl(
        db: ref.watch(appDatabaseProvider),
        clock: const SystemClock(),
        deviceId: '',
        ids: UuidV7Service(const SystemClock()),
      );
    });
