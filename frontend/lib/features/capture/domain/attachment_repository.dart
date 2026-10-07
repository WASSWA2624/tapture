import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';

/// Recovery port for database-owned audio and document attachments.
abstract interface class AttachmentRepository {
  /// Independently deleted attachments whose project and at least one owner live.
  Stream<List<DeletedEntity>> watchDeleted();

  /// Restores only this attachment after checking its parent and durable bytes.
  Future<Result<void>> restore(String id);
}
