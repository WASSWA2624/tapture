import 'package:drift/drift.dart';

import '../columns.dart';

/// Links one durable attachment to its record and any relevant photos.
@TableIndex(name: 'attachment_owners_by_owner', columns: {#ownerType, #ownerId})
class AttachmentOwners extends Table with MergeColumns {
  /// Attachment being linked.
  TextColumn get attachmentId => text()();

  /// `record` or `photo`.
  TextColumn get ownerType => textEnum<AttachmentOwnerType>()();

  /// Record or photo id, according to [ownerType].
  TextColumn get ownerId => text()();

  /// Stable order within one owner.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{attachmentId, ownerType, ownerId},
  ];
}

/// Supported attachment owners.
enum AttachmentOwnerType {
  /// The captured record. Every capture-audio attachment has this link.
  record,

  /// A photo for which the audio is relevant.
  photo,
}
