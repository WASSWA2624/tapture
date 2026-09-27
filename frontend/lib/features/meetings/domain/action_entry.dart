/// One action. Editing it does not change [source].
final class ActionEntry {
  /// Creates an action. [due] may be missing until somebody sets it.
  const ActionEntry({
    required this.id,
    required this.text,
    this.ownerId,
    this.ownerName = '',
    this.due,
    this.status = ActionStatus.open,
    this.source = '',
  });

  /// Rebuilds an action written by [toJson].
  factory ActionEntry.fromJson(Map<String, Object?> json) {
    final Object? due = json['due'];
    return ActionEntry(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      ownerId: json['ownerId'] as String?,
      ownerName: json['ownerName'] as String? ?? '',
      due: due is String ? DateTime.tryParse(due) : null,
      status: ActionStatus.values.firstWhere(
        (ActionStatus status) => status.name == json['status'],
        orElse: () => ActionStatus.open,
      ),
      source: json['source'] as String? ?? '',
    );
  }

  /// Stable id.
  final String id;

  /// What is to be done, stored as meeting content.
  final String text;

  /// Attendee or staff id of the owner, when one was picked.
  final String? ownerId;

  /// Owner name as shown on the register.
  final String ownerName;

  /// When it is due. Null blocks approval when the template requires it.
  final DateTime? due;

  /// Shared status.
  final ActionStatus status;

  /// The raw passage this was read from. Edits do not change it.
  final String source;

  /// Whether approval may proceed for this action.
  bool get hasOwnerAndDue =>
      (ownerName.trim().isNotEmpty || (ownerId?.isNotEmpty ?? false)) &&
      due != null;

  /// JSON for the meeting document.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'text': text,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'due': due?.toUtc().toIso8601String(),
      'status': status.name,
      'source': source,
    };
  }

  /// One register row: owner, due date and status.
  Map<String, Object?> registerRow() {
    return <String, Object?>{
      'action': text,
      'owner': ownerName,
      'due': due?.toUtc().toIso8601String(),
      'status': status.name,
    };
  }

  /// Returns a copy with the provided fields replaced.
  ActionEntry copyWith({
    String? text,
    String? ownerId,
    String? ownerName,
    DateTime? due,
    ActionStatus? status,
    bool clearOwner = false,
    bool clearDue = false,
  }) {
    return ActionEntry(
      id: id,
      text: text ?? this.text,
      ownerId: clearOwner ? null : (ownerId ?? this.ownerId),
      ownerName: clearOwner ? '' : (ownerName ?? this.ownerName),
      due: clearDue ? null : (due ?? this.due),
      status: status ?? this.status,
      source: source,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActionEntry &&
        other.id == id &&
        other.text == text &&
        other.ownerId == ownerId &&
        other.ownerName == ownerName &&
        other.due == due &&
        other.status == status &&
        other.source == source;
  }

  @override
  int get hashCode =>
      Object.hash(id, text, ownerId, ownerName, due, status, source);
}

/// Where an action sits in the shared status set.
enum ActionStatus {
  /// Not finished.
  open,

  /// Under way.
  inProgress,

  /// Finished.
  done,
}
