// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TombstonesTable extends Tombstones
    with TableInfo<$TombstonesTable, Tombstone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedByDeviceMeta = const VerificationMeta(
    'deletedByDevice',
  );
  @override
  late final GeneratedColumn<String> deletedByDevice = GeneratedColumn<String>(
    'deleted_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    entityType,
    entityId,
    deletedAt,
    deletedByDevice,
    reason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tombstone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    if (data.containsKey('deleted_by_device')) {
      context.handle(
        _deletedByDeviceMeta,
        deletedByDevice.isAcceptableOrUnknown(
          data['deleted_by_device']!,
          _deletedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deletedByDeviceMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entityType, entityId},
  ];
  @override
  Tombstone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tombstone(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
      deletedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_by_device'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
    );
  }

  @override
  $TombstonesTable createAlias(String alias) {
    return $TombstonesTable(attachedDatabase, alias);
  }
}

class Tombstone extends DataClass implements Insertable<Tombstone> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// The table the deleted row belonged to.
  final String entityType;

  /// Merge id of the deleted row.
  final String entityId;

  /// When the delete was written.
  final DateTime deletedAt;

  /// Device that wrote the delete.
  final String deletedByDevice;

  /// Why the row was removed.
  final String reason;
  const Tombstone({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.entityType,
    required this.entityId,
    required this.deletedAt,
    required this.deletedByDevice,
    required this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    map['deleted_by_device'] = Variable<String>(deletedByDevice);
    map['reason'] = Variable<String>(reason);
    return map;
  }

  TombstonesCompanion toCompanion(bool nullToAbsent) {
    return TombstonesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      entityType: Value(entityType),
      entityId: Value(entityId),
      deletedAt: Value(deletedAt),
      deletedByDevice: Value(deletedByDevice),
      reason: Value(reason),
    );
  }

  factory Tombstone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tombstone(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
      deletedByDevice: serializer.fromJson<String>(json['deletedByDevice']),
      reason: serializer.fromJson<String>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
      'deletedByDevice': serializer.toJson<String>(deletedByDevice),
      'reason': serializer.toJson<String>(reason),
    };
  }

  Tombstone copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? entityType,
    String? entityId,
    DateTime? deletedAt,
    String? deletedByDevice,
    String? reason,
  }) => Tombstone(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    deletedAt: deletedAt ?? this.deletedAt,
    deletedByDevice: deletedByDevice ?? this.deletedByDevice,
    reason: reason ?? this.reason,
  );
  Tombstone copyWithCompanion(TombstonesCompanion data) {
    return Tombstone(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deletedByDevice: data.deletedByDevice.present
          ? data.deletedByDevice.value
          : this.deletedByDevice,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tombstone(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deletedByDevice: $deletedByDevice, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    entityType,
    entityId,
    deletedAt,
    deletedByDevice,
    reason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tombstone &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.deletedAt == this.deletedAt &&
          other.deletedByDevice == this.deletedByDevice &&
          other.reason == this.reason);
}

class TombstonesCompanion extends UpdateCompanion<Tombstone> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<DateTime> deletedAt;
  final Value<String> deletedByDevice;
  final Value<String> reason;
  final Value<int> rowid;
  const TombstonesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deletedByDevice = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TombstonesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String entityType,
    required String entityId,
    required DateTime deletedAt,
    required String deletedByDevice,
    required String reason,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       entityType = Value(entityType),
       entityId = Value(entityId),
       deletedAt = Value(deletedAt),
       deletedByDevice = Value(deletedByDevice),
       reason = Value(reason);
  static Insertable<Tombstone> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<DateTime>? deletedAt,
    Expression<String>? deletedByDevice,
    Expression<String>? reason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deletedByDevice != null) 'deleted_by_device': deletedByDevice,
      if (reason != null) 'reason': reason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TombstonesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<DateTime>? deletedAt,
    Value<String>? deletedByDevice,
    Value<String>? reason,
    Value<int>? rowid,
  }) {
    return TombstonesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedByDevice: deletedByDevice ?? this.deletedByDevice,
      reason: reason ?? this.reason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deletedByDevice.present) {
      map['deleted_by_device'] = Variable<String>(deletedByDevice.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TombstonesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deletedByDevice: $deletedByDevice, ')
          ..write('reason: $reason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AuditAction, String> action =
      GeneratedColumn<String>(
        'action',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AuditAction>($AuditLogTable.$converteraction);
  static const VerificationMeta _fieldKeyMeta = const VerificationMeta(
    'fieldKey',
  );
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
    'field_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _previousValueMeta = const VerificationMeta(
    'previousValue',
  );
  @override
  late final GeneratedColumn<String> previousValue = GeneratedColumn<String>(
    'previous_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newValueMeta = const VerificationMeta(
    'newValue',
  );
  @override
  late final GeneratedColumn<String> newValue = GeneratedColumn<String>(
    'new_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operatorMeta = const VerificationMeta(
    'operator',
  );
  @override
  late final GeneratedColumn<String> operator = GeneratedColumn<String>(
    'operator',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceMeta = const VerificationMeta('device');
  @override
  late final GeneratedColumn<String> device = GeneratedColumn<String>(
    'device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    entityType,
    entityId,
    action,
    fieldKey,
    previousValue,
    newValue,
    reason,
    operator,
    device,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('field_key')) {
      context.handle(
        _fieldKeyMeta,
        fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta),
      );
    }
    if (data.containsKey('previous_value')) {
      context.handle(
        _previousValueMeta,
        previousValue.isAcceptableOrUnknown(
          data['previous_value']!,
          _previousValueMeta,
        ),
      );
    }
    if (data.containsKey('new_value')) {
      context.handle(
        _newValueMeta,
        newValue.isAcceptableOrUnknown(data['new_value']!, _newValueMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('operator')) {
      context.handle(
        _operatorMeta,
        operator.isAcceptableOrUnknown(data['operator']!, _operatorMeta),
      );
    } else if (isInserting) {
      context.missing(_operatorMeta);
    }
    if (data.containsKey('device')) {
      context.handle(
        _deviceMeta,
        device.isAcceptableOrUnknown(data['device']!, _deviceMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      action: $AuditLogTable.$converteraction.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}action'],
        )!,
      ),
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      ),
      previousValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_value'],
      ),
      newValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_value'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      operator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operator'],
      )!,
      device: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AuditAction, String, String> $converteraction =
      const EnumNameConverter<AuditAction>(AuditAction.values);
}

class AuditLogData extends DataClass implements Insertable<AuditLogData> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// The table the changed row belongs to.
  final String entityType;

  /// Merge id of the changed row.
  final String entityId;

  /// What happened to the row or field.
  final AuditAction action;

  /// Field that changed, when this row is a field-level change.
  final String? fieldKey;

  /// Value before the change. Written only here, never to a log sink.
  final String? previousValue;

  /// Value after the change. Written only here, never to a log sink.
  final String? newValue;

  /// Why the change was made, when known.
  final String? reason;

  /// Operator name copied from the device profile at write time.
  final String operator;

  /// Device that wrote the change.
  final String device;

  /// When the change was written.
  final DateTime at;
  const AuditLogData({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.fieldKey,
    this.previousValue,
    this.newValue,
    this.reason,
    required this.operator,
    required this.device,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    {
      map['action'] = Variable<String>(
        $AuditLogTable.$converteraction.toSql(action),
      );
    }
    if (!nullToAbsent || fieldKey != null) {
      map['field_key'] = Variable<String>(fieldKey);
    }
    if (!nullToAbsent || previousValue != null) {
      map['previous_value'] = Variable<String>(previousValue);
    }
    if (!nullToAbsent || newValue != null) {
      map['new_value'] = Variable<String>(newValue);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['operator'] = Variable<String>(operator);
    map['device'] = Variable<String>(device);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      fieldKey: fieldKey == null && nullToAbsent
          ? const Value.absent()
          : Value(fieldKey),
      previousValue: previousValue == null && nullToAbsent
          ? const Value.absent()
          : Value(previousValue),
      newValue: newValue == null && nullToAbsent
          ? const Value.absent()
          : Value(newValue),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      operator: Value(operator),
      device: Value(device),
      at: Value(at),
    );
  }

  factory AuditLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogData(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: $AuditLogTable.$converteraction.fromJson(
        serializer.fromJson<String>(json['action']),
      ),
      fieldKey: serializer.fromJson<String?>(json['fieldKey']),
      previousValue: serializer.fromJson<String?>(json['previousValue']),
      newValue: serializer.fromJson<String?>(json['newValue']),
      reason: serializer.fromJson<String?>(json['reason']),
      operator: serializer.fromJson<String>(json['operator']),
      device: serializer.fromJson<String>(json['device']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(
        $AuditLogTable.$converteraction.toJson(action),
      ),
      'fieldKey': serializer.toJson<String?>(fieldKey),
      'previousValue': serializer.toJson<String?>(previousValue),
      'newValue': serializer.toJson<String?>(newValue),
      'reason': serializer.toJson<String?>(reason),
      'operator': serializer.toJson<String>(operator),
      'device': serializer.toJson<String>(device),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  AuditLogData copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? entityType,
    String? entityId,
    AuditAction? action,
    Value<String?> fieldKey = const Value.absent(),
    Value<String?> previousValue = const Value.absent(),
    Value<String?> newValue = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    String? operator,
    String? device,
    DateTime? at,
  }) => AuditLogData(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    action: action ?? this.action,
    fieldKey: fieldKey.present ? fieldKey.value : this.fieldKey,
    previousValue: previousValue.present
        ? previousValue.value
        : this.previousValue,
    newValue: newValue.present ? newValue.value : this.newValue,
    reason: reason.present ? reason.value : this.reason,
    operator: operator ?? this.operator,
    device: device ?? this.device,
    at: at ?? this.at,
  );
  AuditLogData copyWithCompanion(AuditLogCompanion data) {
    return AuditLogData(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      previousValue: data.previousValue.present
          ? data.previousValue.value
          : this.previousValue,
      newValue: data.newValue.present ? data.newValue.value : this.newValue,
      reason: data.reason.present ? data.reason.value : this.reason,
      operator: data.operator.present ? data.operator.value : this.operator,
      device: data.device.present ? data.device.value : this.device,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogData(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('previousValue: $previousValue, ')
          ..write('newValue: $newValue, ')
          ..write('reason: $reason, ')
          ..write('operator: $operator, ')
          ..write('device: $device, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    entityType,
    entityId,
    action,
    fieldKey,
    previousValue,
    newValue,
    reason,
    operator,
    device,
    at,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogData &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.fieldKey == this.fieldKey &&
          other.previousValue == this.previousValue &&
          other.newValue == this.newValue &&
          other.reason == this.reason &&
          other.operator == this.operator &&
          other.device == this.device &&
          other.at == this.at);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogData> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<AuditAction> action;
  final Value<String?> fieldKey;
  final Value<String?> previousValue;
  final Value<String?> newValue;
  final Value<String?> reason;
  final Value<String> operator;
  final Value<String> device;
  final Value<DateTime> at;
  final Value<int> rowid;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.previousValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.reason = const Value.absent(),
    this.operator = const Value.absent(),
    this.device = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String entityType,
    required String entityId,
    required AuditAction action,
    this.fieldKey = const Value.absent(),
    this.previousValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.reason = const Value.absent(),
    required String operator,
    required String device,
    required DateTime at,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       entityType = Value(entityType),
       entityId = Value(entityId),
       action = Value(action),
       operator = Value(operator),
       device = Value(device),
       at = Value(at);
  static Insertable<AuditLogData> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? fieldKey,
    Expression<String>? previousValue,
    Expression<String>? newValue,
    Expression<String>? reason,
    Expression<String>? operator,
    Expression<String>? device,
    Expression<DateTime>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (fieldKey != null) 'field_key': fieldKey,
      if (previousValue != null) 'previous_value': previousValue,
      if (newValue != null) 'new_value': newValue,
      if (reason != null) 'reason': reason,
      if (operator != null) 'operator': operator,
      if (device != null) 'device': device,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<AuditAction>? action,
    Value<String?>? fieldKey,
    Value<String?>? previousValue,
    Value<String?>? newValue,
    Value<String?>? reason,
    Value<String>? operator,
    Value<String>? device,
    Value<DateTime>? at,
    Value<int>? rowid,
  }) {
    return AuditLogCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      fieldKey: fieldKey ?? this.fieldKey,
      previousValue: previousValue ?? this.previousValue,
      newValue: newValue ?? this.newValue,
      reason: reason ?? this.reason,
      operator: operator ?? this.operator,
      device: device ?? this.device,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(
        $AuditLogTable.$converteraction.toSql(action.value),
      );
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (previousValue.present) {
      map['previous_value'] = Variable<String>(previousValue.value);
    }
    if (newValue.present) {
      map['new_value'] = Variable<String>(newValue.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (operator.present) {
      map['operator'] = Variable<String>(operator.value);
    }
    if (device.present) {
      map['device'] = Variable<String>(device.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('previousValue: $previousValue, ')
          ..write('newValue: $newValue, ')
          ..write('reason: $reason, ')
          ..write('operator: $operator, ')
          ..write('device: $device, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceProfileTable extends DeviceProfile
    with TableInfo<$DeviceProfileTable, DeviceProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operatorNameMeta = const VerificationMeta(
    'operatorName',
  );
  @override
  late final GeneratedColumn<String> operatorName = GeneratedColumn<String>(
    'operator_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _preferencesMeta = const VerificationMeta(
    'preferences',
  );
  @override
  late final GeneratedColumn<String> preferences = GeneratedColumn<String>(
    'preferences',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    deviceId,
    operatorName,
    preferences,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('operator_name')) {
      context.handle(
        _operatorNameMeta,
        operatorName.isAcceptableOrUnknown(
          data['operator_name']!,
          _operatorNameMeta,
        ),
      );
    }
    if (data.containsKey('preferences')) {
      context.handle(
        _preferencesMeta,
        preferences.isAcceptableOrUnknown(
          data['preferences']!,
          _preferencesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      operatorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operator_name'],
      )!,
      preferences: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferences'],
      )!,
    );
  }

  @override
  $DeviceProfileTable createAlias(String alias) {
    return $DeviceProfileTable(attachedDatabase, alias);
  }
}

class DeviceProfileRow extends DataClass
    implements Insertable<DeviceProfileRow> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// Stable device identifier minted by [deviceId].
  final String deviceId;

  /// Display name of the operator on this device.
  final String operatorName;

  /// Preferences JSON. An object, stored as text.
  final String preferences;
  const DeviceProfileRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.deviceId,
    required this.operatorName,
    required this.preferences,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['device_id'] = Variable<String>(deviceId);
    map['operator_name'] = Variable<String>(operatorName);
    map['preferences'] = Variable<String>(preferences);
    return map;
  }

  DeviceProfileCompanion toCompanion(bool nullToAbsent) {
    return DeviceProfileCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      deviceId: Value(deviceId),
      operatorName: Value(operatorName),
      preferences: Value(preferences),
    );
  }

  factory DeviceProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceProfileRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      operatorName: serializer.fromJson<String>(json['operatorName']),
      preferences: serializer.fromJson<String>(json['preferences']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'deviceId': serializer.toJson<String>(deviceId),
      'operatorName': serializer.toJson<String>(operatorName),
      'preferences': serializer.toJson<String>(preferences),
    };
  }

  DeviceProfileRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? deviceId,
    String? operatorName,
    String? preferences,
  }) => DeviceProfileRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    deviceId: deviceId ?? this.deviceId,
    operatorName: operatorName ?? this.operatorName,
    preferences: preferences ?? this.preferences,
  );
  DeviceProfileRow copyWithCompanion(DeviceProfileCompanion data) {
    return DeviceProfileRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      operatorName: data.operatorName.present
          ? data.operatorName.value
          : this.operatorName,
      preferences: data.preferences.present
          ? data.preferences.value
          : this.preferences,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceProfileRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('deviceId: $deviceId, ')
          ..write('operatorName: $operatorName, ')
          ..write('preferences: $preferences')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    deviceId,
    operatorName,
    preferences,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceProfileRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.deviceId == this.deviceId &&
          other.operatorName == this.operatorName &&
          other.preferences == this.preferences);
}

class DeviceProfileCompanion extends UpdateCompanion<DeviceProfileRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> deviceId;
  final Value<String> operatorName;
  final Value<String> preferences;
  final Value<int> rowid;
  const DeviceProfileCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.operatorName = const Value.absent(),
    this.preferences = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceProfileCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String deviceId,
    this.operatorName = const Value.absent(),
    this.preferences = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       deviceId = Value(deviceId);
  static Insertable<DeviceProfileRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? deviceId,
    Expression<String>? operatorName,
    Expression<String>? preferences,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (deviceId != null) 'device_id': deviceId,
      if (operatorName != null) 'operator_name': operatorName,
      if (preferences != null) 'preferences': preferences,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceProfileCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? deviceId,
    Value<String>? operatorName,
    Value<String>? preferences,
    Value<int>? rowid,
  }) {
    return DeviceProfileCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      deviceId: deviceId ?? this.deviceId,
      operatorName: operatorName ?? this.operatorName,
      preferences: preferences ?? this.preferences,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (operatorName.present) {
      map['operator_name'] = Variable<String>(operatorName.value);
    }
    if (preferences.present) {
      map['preferences'] = Variable<String>(preferences.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceProfileCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('deviceId: $deviceId, ')
          ..write('operatorName: $operatorName, ')
          ..write('preferences: $preferences, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientMeta = const VerificationMeta('client');
  @override
  late final GeneratedColumn<String> client = GeneratedColumn<String>(
    'client',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ProjectStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ProjectStatus>($ProjectsTable.$converterstatus);
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderNameMeta = const VerificationMeta(
    'folderName',
  );
  @override
  late final GeneratedColumn<String> folderName = GeneratedColumn<String>(
    'folder_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingsMeta = const VerificationMeta(
    'settings',
  );
  @override
  late final GeneratedColumn<String> settings = GeneratedColumn<String>(
    'settings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    name,
    client,
    status,
    startedAt,
    completedAt,
    folderName,
    settings,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('client')) {
      context.handle(
        _clientMeta,
        client.isAcceptableOrUnknown(data['client']!, _clientMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('folder_name')) {
      context.handle(
        _folderNameMeta,
        folderName.isAcceptableOrUnknown(data['folder_name']!, _folderNameMeta),
      );
    } else if (isInserting) {
      context.missing(_folderNameMeta);
    }
    if (data.containsKey('settings')) {
      context.handle(
        _settingsMeta,
        settings.isAcceptableOrUnknown(data['settings']!, _settingsMeta),
      );
    } else if (isInserting) {
      context.missing(_settingsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      client: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client'],
      )!,
      status: $ProjectsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      folderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_name'],
      )!,
      settings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ProjectStatus, String, String> $converterstatus =
      const EnumNameConverter<ProjectStatus>(ProjectStatus.values);
}

class Project extends DataClass implements Insertable<Project> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// Display name. Changing this must not rewrite [folderName].
  final String name;

  /// Client or organisation the project is for.
  final String client;

  /// Active, archived or deleted. The list filters on this column.
  final ProjectStatus status;

  /// When fieldwork started, if known.
  final DateTime? startedAt;

  /// When fieldwork finished, if known.
  final DateTime? completedAt;

  /// On-disk folder. Stored at creation and never recomputed on read.
  final String folderName;

  /// Project settings JSON. An object, validated before it is stored.
  final String settings;
  const Project({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.name,
    required this.client,
    required this.status,
    this.startedAt,
    this.completedAt,
    required this.folderName,
    required this.settings,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['name'] = Variable<String>(name);
    map['client'] = Variable<String>(client);
    {
      map['status'] = Variable<String>(
        $ProjectsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['folder_name'] = Variable<String>(folderName);
    map['settings'] = Variable<String>(settings);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      name: Value(name),
      client: Value(client),
      status: Value(status),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      folderName: Value(folderName),
      settings: Value(settings),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      name: serializer.fromJson<String>(json['name']),
      client: serializer.fromJson<String>(json['client']),
      status: $ProjectsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      folderName: serializer.fromJson<String>(json['folderName']),
      settings: serializer.fromJson<String>(json['settings']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'name': serializer.toJson<String>(name),
      'client': serializer.toJson<String>(client),
      'status': serializer.toJson<String>(
        $ProjectsTable.$converterstatus.toJson(status),
      ),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'folderName': serializer.toJson<String>(folderName),
      'settings': serializer.toJson<String>(settings),
    };
  }

  Project copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? name,
    String? client,
    ProjectStatus? status,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    String? folderName,
    String? settings,
  }) => Project(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    name: name ?? this.name,
    client: client ?? this.client,
    status: status ?? this.status,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    folderName: folderName ?? this.folderName,
    settings: settings ?? this.settings,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      name: data.name.present ? data.name.value : this.name,
      client: data.client.present ? data.client.value : this.client,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      folderName: data.folderName.present
          ? data.folderName.value
          : this.folderName,
      settings: data.settings.present ? data.settings.value : this.settings,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('name: $name, ')
          ..write('client: $client, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('folderName: $folderName, ')
          ..write('settings: $settings')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    name,
    client,
    status,
    startedAt,
    completedAt,
    folderName,
    settings,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.name == this.name &&
          other.client == this.client &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.folderName == this.folderName &&
          other.settings == this.settings);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> name;
  final Value<String> client;
  final Value<ProjectStatus> status;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  final Value<String> folderName;
  final Value<String> settings;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.name = const Value.absent(),
    this.client = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.folderName = const Value.absent(),
    this.settings = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String name,
    this.client = const Value.absent(),
    required ProjectStatus status,
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    required String folderName,
    required String settings,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       name = Value(name),
       status = Value(status),
       folderName = Value(folderName),
       settings = Value(settings);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? name,
    Expression<String>? client,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? folderName,
    Expression<String>? settings,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (name != null) 'name': name,
      if (client != null) 'client': client,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (folderName != null) 'folder_name': folderName,
      if (settings != null) 'settings': settings,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? name,
    Value<String>? client,
    Value<ProjectStatus>? status,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? completedAt,
    Value<String>? folderName,
    Value<String>? settings,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      name: name ?? this.name,
      client: client ?? this.client,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      folderName: folderName ?? this.folderName,
      settings: settings ?? this.settings,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (client.present) {
      map['client'] = Variable<String>(client.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ProjectsTable.$converterstatus.toSql(status.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (folderName.present) {
      map['folder_name'] = Variable<String>(folderName.value);
    }
    if (settings.present) {
      map['settings'] = Variable<String>(settings.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('name: $name, ')
          ..write('client: $client, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('folderName: $folderName, ')
          ..write('settings: $settings, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContextTable extends Context with TableInfo<$ContextTable, ContextData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContextTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldKeyMeta = const VerificationMeta(
    'fieldKey',
  );
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
    'field_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    projectId,
    level,
    fieldKey,
    label,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'context_definitions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContextData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('field_key')) {
      context.handle(
        _fieldKeyMeta,
        fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {projectId, level},
  ];
  @override
  ContextData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContextData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
    );
  }

  @override
  $ContextTable createAlias(String alias) {
    return $ContextTable(attachedDatabase, alias);
  }
}

class ContextData extends DataClass implements Insertable<ContextData> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// Project that owns this level.
  final String projectId;

  /// Hierarchy order. Unique together with [projectId].
  final int level;

  /// Template field key this level binds to.
  final String fieldKey;

  /// Operator-facing name for the level.
  final String label;
  const ContextData({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.projectId,
    required this.level,
    required this.fieldKey,
    required this.label,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['project_id'] = Variable<String>(projectId);
    map['level'] = Variable<int>(level);
    map['field_key'] = Variable<String>(fieldKey);
    map['label'] = Variable<String>(label);
    return map;
  }

  ContextCompanion toCompanion(bool nullToAbsent) {
    return ContextCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      projectId: Value(projectId),
      level: Value(level),
      fieldKey: Value(fieldKey),
      label: Value(label),
    );
  }

  factory ContextData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContextData(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      projectId: serializer.fromJson<String>(json['projectId']),
      level: serializer.fromJson<int>(json['level']),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      label: serializer.fromJson<String>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'projectId': serializer.toJson<String>(projectId),
      'level': serializer.toJson<int>(level),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'label': serializer.toJson<String>(label),
    };
  }

  ContextData copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? projectId,
    int? level,
    String? fieldKey,
    String? label,
  }) => ContextData(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    projectId: projectId ?? this.projectId,
    level: level ?? this.level,
    fieldKey: fieldKey ?? this.fieldKey,
    label: label ?? this.label,
  );
  ContextData copyWithCompanion(ContextCompanion data) {
    return ContextData(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      level: data.level.present ? data.level.value : this.level,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContextData(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('level: $level, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    projectId,
    level,
    fieldKey,
    label,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContextData &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.projectId == this.projectId &&
          other.level == this.level &&
          other.fieldKey == this.fieldKey &&
          other.label == this.label);
}

class ContextCompanion extends UpdateCompanion<ContextData> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> projectId;
  final Value<int> level;
  final Value<String> fieldKey;
  final Value<String> label;
  final Value<int> rowid;
  const ContextCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.projectId = const Value.absent(),
    this.level = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContextCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String projectId,
    required int level,
    required String fieldKey,
    required String label,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       projectId = Value(projectId),
       level = Value(level),
       fieldKey = Value(fieldKey),
       label = Value(label);
  static Insertable<ContextData> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? projectId,
    Expression<int>? level,
    Expression<String>? fieldKey,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (projectId != null) 'project_id': projectId,
      if (level != null) 'level': level,
      if (fieldKey != null) 'field_key': fieldKey,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContextCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? projectId,
    Value<int>? level,
    Value<String>? fieldKey,
    Value<String>? label,
    Value<int>? rowid,
  }) {
    return ContextCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      projectId: projectId ?? this.projectId,
      level: level ?? this.level,
      fieldKey: fieldKey ?? this.fieldKey,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContextCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('level: $level, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContextStateTable extends ContextState
    with TableInfo<$ContextStateTable, ContextStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContextStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setAtMeta = const VerificationMeta('setAt');
  @override
  late final GeneratedColumn<DateTime> setAt = GeneratedColumn<DateTime>(
    'set_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    projectId,
    level,
    value,
    setAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'context_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContextStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('set_at')) {
      context.handle(
        _setAtMeta,
        setAt.isAcceptableOrUnknown(data['set_at']!, _setAtMeta),
      );
    } else if (isInserting) {
      context.missing(_setAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {projectId, level},
  ];
  @override
  ContextStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContextStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      setAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}set_at'],
      )!,
    );
  }

  @override
  $ContextStateTable createAlias(String alias) {
    return $ContextStateTable(attachedDatabase, alias);
  }
}

class ContextStateRow extends DataClass implements Insertable<ContextStateRow> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// Project that owns this pin.
  final String projectId;

  /// Hierarchy order matching [Context.level].
  final int level;

  /// Pinned value. Written here, never to a log sink.
  final String value;

  /// When this level was last set.
  final DateTime setAt;
  const ContextStateRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.projectId,
    required this.level,
    required this.value,
    required this.setAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['project_id'] = Variable<String>(projectId);
    map['level'] = Variable<int>(level);
    map['value'] = Variable<String>(value);
    map['set_at'] = Variable<DateTime>(setAt);
    return map;
  }

  ContextStateCompanion toCompanion(bool nullToAbsent) {
    return ContextStateCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      projectId: Value(projectId),
      level: Value(level),
      value: Value(value),
      setAt: Value(setAt),
    );
  }

  factory ContextStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContextStateRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      projectId: serializer.fromJson<String>(json['projectId']),
      level: serializer.fromJson<int>(json['level']),
      value: serializer.fromJson<String>(json['value']),
      setAt: serializer.fromJson<DateTime>(json['setAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'projectId': serializer.toJson<String>(projectId),
      'level': serializer.toJson<int>(level),
      'value': serializer.toJson<String>(value),
      'setAt': serializer.toJson<DateTime>(setAt),
    };
  }

  ContextStateRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? projectId,
    int? level,
    String? value,
    DateTime? setAt,
  }) => ContextStateRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    projectId: projectId ?? this.projectId,
    level: level ?? this.level,
    value: value ?? this.value,
    setAt: setAt ?? this.setAt,
  );
  ContextStateRow copyWithCompanion(ContextStateCompanion data) {
    return ContextStateRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      level: data.level.present ? data.level.value : this.level,
      value: data.value.present ? data.value.value : this.value,
      setAt: data.setAt.present ? data.setAt.value : this.setAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContextStateRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('level: $level, ')
          ..write('value: $value, ')
          ..write('setAt: $setAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    projectId,
    level,
    value,
    setAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContextStateRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.projectId == this.projectId &&
          other.level == this.level &&
          other.value == this.value &&
          other.setAt == this.setAt);
}

class ContextStateCompanion extends UpdateCompanion<ContextStateRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> projectId;
  final Value<int> level;
  final Value<String> value;
  final Value<DateTime> setAt;
  final Value<int> rowid;
  const ContextStateCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.projectId = const Value.absent(),
    this.level = const Value.absent(),
    this.value = const Value.absent(),
    this.setAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContextStateCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String projectId,
    required int level,
    required String value,
    required DateTime setAt,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       projectId = Value(projectId),
       level = Value(level),
       value = Value(value),
       setAt = Value(setAt);
  static Insertable<ContextStateRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? projectId,
    Expression<int>? level,
    Expression<String>? value,
    Expression<DateTime>? setAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (projectId != null) 'project_id': projectId,
      if (level != null) 'level': level,
      if (value != null) 'value': value,
      if (setAt != null) 'set_at': setAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContextStateCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? projectId,
    Value<int>? level,
    Value<String>? value,
    Value<DateTime>? setAt,
    Value<int>? rowid,
  }) {
    return ContextStateCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      projectId: projectId ?? this.projectId,
      level: level ?? this.level,
      value: value ?? this.value,
      setAt: setAt ?? this.setAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (setAt.present) {
      map['set_at'] = Variable<DateTime>(setAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContextStateCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('level: $level, ')
          ..write('value: $value, ')
          ..write('setAt: $setAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContextPresetsTable extends ContextPresets
    with TableInfo<$ContextPresetsTable, ContextPreset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContextPresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valuesMeta = const VerificationMeta('values');
  @override
  late final GeneratedColumn<String> values = GeneratedColumn<String>(
    'values',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    name,
    projectId,
    values,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'context_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContextPreset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('values')) {
      context.handle(
        _valuesMeta,
        values.isAcceptableOrUnknown(data['values']!, _valuesMeta),
      );
    } else if (isInserting) {
      context.missing(_valuesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContextPreset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContextPreset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      values: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}values'],
      )!,
    );
  }

  @override
  $ContextPresetsTable createAlias(String alias) {
    return $ContextPresetsTable(attachedDatabase, alias);
  }
}

class ContextPreset extends DataClass implements Insertable<ContextPreset> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// Operator-facing name of the snapshot.
  final String name;

  /// Project that owns this snapshot.
  final String projectId;

  /// Values JSON. An object, stored as text.
  final String values;
  const ContextPreset({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.name,
    required this.projectId,
    required this.values,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['name'] = Variable<String>(name);
    map['project_id'] = Variable<String>(projectId);
    map['values'] = Variable<String>(values);
    return map;
  }

  ContextPresetsCompanion toCompanion(bool nullToAbsent) {
    return ContextPresetsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      name: Value(name),
      projectId: Value(projectId),
      values: Value(values),
    );
  }

  factory ContextPreset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContextPreset(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      name: serializer.fromJson<String>(json['name']),
      projectId: serializer.fromJson<String>(json['projectId']),
      values: serializer.fromJson<String>(json['values']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'name': serializer.toJson<String>(name),
      'projectId': serializer.toJson<String>(projectId),
      'values': serializer.toJson<String>(values),
    };
  }

  ContextPreset copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? name,
    String? projectId,
    String? values,
  }) => ContextPreset(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    name: name ?? this.name,
    projectId: projectId ?? this.projectId,
    values: values ?? this.values,
  );
  ContextPreset copyWithCompanion(ContextPresetsCompanion data) {
    return ContextPreset(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      name: data.name.present ? data.name.value : this.name,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      values: data.values.present ? data.values.value : this.values,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContextPreset(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('name: $name, ')
          ..write('projectId: $projectId, ')
          ..write('values: $values')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    name,
    projectId,
    values,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContextPreset &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.name == this.name &&
          other.projectId == this.projectId &&
          other.values == this.values);
}

class ContextPresetsCompanion extends UpdateCompanion<ContextPreset> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> name;
  final Value<String> projectId;
  final Value<String> values;
  final Value<int> rowid;
  const ContextPresetsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.name = const Value.absent(),
    this.projectId = const Value.absent(),
    this.values = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContextPresetsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String name,
    required String projectId,
    required String values,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       name = Value(name),
       projectId = Value(projectId),
       values = Value(values);
  static Insertable<ContextPreset> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? name,
    Expression<String>? projectId,
    Expression<String>? values,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (name != null) 'name': name,
      if (projectId != null) 'project_id': projectId,
      if (values != null) 'values': values,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContextPresetsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? name,
    Value<String>? projectId,
    Value<String>? values,
    Value<int>? rowid,
  }) {
    return ContextPresetsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      name: name ?? this.name,
      projectId: projectId ?? this.projectId,
      values: values ?? this.values,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (values.present) {
      map['values'] = Variable<String>(values.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContextPresetsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('name: $name, ')
          ..write('projectId: $projectId, ')
          ..write('values: $values, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, Template> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceFilePathMeta = const VerificationMeta(
    'sourceFilePath',
  );
  @override
  late final GeneratedColumn<String> sourceFilePath = GeneratedColumn<String>(
    'source_file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sheetNameMeta = const VerificationMeta(
    'sheetName',
  );
  @override
  late final GeneratedColumn<String> sheetName = GeneratedColumn<String>(
    'sheet_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headerRowMeta = const VerificationMeta(
    'headerRow',
  );
  @override
  late final GeneratedColumn<int> headerRow = GeneratedColumn<int>(
    'header_row',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _identityFieldsMeta = const VerificationMeta(
    'identityFields',
  );
  @override
  late final GeneratedColumn<String> identityFields = GeneratedColumn<String>(
    'identity_fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _detectionMeta = const VerificationMeta(
    'detection',
  );
  @override
  late final GeneratedColumn<String> detection = GeneratedColumn<String>(
    'detection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    projectId,
    name,
    kind,
    source,
    sourceFilePath,
    sheetName,
    headerRow,
    identityFields,
    detection,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<Template> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_file_path')) {
      context.handle(
        _sourceFilePathMeta,
        sourceFilePath.isAcceptableOrUnknown(
          data['source_file_path']!,
          _sourceFilePathMeta,
        ),
      );
    }
    if (data.containsKey('sheet_name')) {
      context.handle(
        _sheetNameMeta,
        sheetName.isAcceptableOrUnknown(data['sheet_name']!, _sheetNameMeta),
      );
    }
    if (data.containsKey('header_row')) {
      context.handle(
        _headerRowMeta,
        headerRow.isAcceptableOrUnknown(data['header_row']!, _headerRowMeta),
      );
    }
    if (data.containsKey('identity_fields')) {
      context.handle(
        _identityFieldsMeta,
        identityFields.isAcceptableOrUnknown(
          data['identity_fields']!,
          _identityFieldsMeta,
        ),
      );
    }
    if (data.containsKey('detection')) {
      context.handle(
        _detectionMeta,
        detection.isAcceptableOrUnknown(data['detection']!, _detectionMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Template map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Template(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_file_path'],
      ),
      sheetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sheet_name'],
      ),
      headerRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}header_row'],
      ),
      identityFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_fields'],
      )!,
      detection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detection'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class Template extends DataClass implements Insertable<Template> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// Owning project, or null when this row is a shipped template.
  final String? projectId;

  /// Display name.
  final String name;

  /// Kind of thing this template captures, stored as data.
  final String kind;

  /// Where the template came from (shipped, imported, built).
  final String source;

  /// Imported workbook path, when [source] is an import.
  final String? sourceFilePath;

  /// Imported sheet name, stored as data, never interpolated into a query.
  final String? sheetName;

  /// 1-based header row in the imported sheet, when known.
  final int? headerRow;

  /// Identity field keys JSON, stored as text.
  final String identityFields;

  /// Detection profile JSON, stored as text.
  final String detection;

  /// Structural version. Captured records keep the value they were taken at.
  final int version;
  const Template({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    this.projectId,
    required this.name,
    required this.kind,
    required this.source,
    this.sourceFilePath,
    this.sheetName,
    this.headerRow,
    required this.identityFields,
    required this.detection,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceFilePath != null) {
      map['source_file_path'] = Variable<String>(sourceFilePath);
    }
    if (!nullToAbsent || sheetName != null) {
      map['sheet_name'] = Variable<String>(sheetName);
    }
    if (!nullToAbsent || headerRow != null) {
      map['header_row'] = Variable<int>(headerRow);
    }
    map['identity_fields'] = Variable<String>(identityFields);
    map['detection'] = Variable<String>(detection);
    map['version'] = Variable<int>(version);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      name: Value(name),
      kind: Value(kind),
      source: Value(source),
      sourceFilePath: sourceFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceFilePath),
      sheetName: sheetName == null && nullToAbsent
          ? const Value.absent()
          : Value(sheetName),
      headerRow: headerRow == null && nullToAbsent
          ? const Value.absent()
          : Value(headerRow),
      identityFields: Value(identityFields),
      detection: Value(detection),
      version: Value(version),
    );
  }

  factory Template.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Template(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      source: serializer.fromJson<String>(json['source']),
      sourceFilePath: serializer.fromJson<String?>(json['sourceFilePath']),
      sheetName: serializer.fromJson<String?>(json['sheetName']),
      headerRow: serializer.fromJson<int?>(json['headerRow']),
      identityFields: serializer.fromJson<String>(json['identityFields']),
      detection: serializer.fromJson<String>(json['detection']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'projectId': serializer.toJson<String?>(projectId),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'source': serializer.toJson<String>(source),
      'sourceFilePath': serializer.toJson<String?>(sourceFilePath),
      'sheetName': serializer.toJson<String?>(sheetName),
      'headerRow': serializer.toJson<int?>(headerRow),
      'identityFields': serializer.toJson<String>(identityFields),
      'detection': serializer.toJson<String>(detection),
      'version': serializer.toJson<int>(version),
    };
  }

  Template copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    Value<String?> projectId = const Value.absent(),
    String? name,
    String? kind,
    String? source,
    Value<String?> sourceFilePath = const Value.absent(),
    Value<String?> sheetName = const Value.absent(),
    Value<int?> headerRow = const Value.absent(),
    String? identityFields,
    String? detection,
    int? version,
  }) => Template(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    projectId: projectId.present ? projectId.value : this.projectId,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    source: source ?? this.source,
    sourceFilePath: sourceFilePath.present
        ? sourceFilePath.value
        : this.sourceFilePath,
    sheetName: sheetName.present ? sheetName.value : this.sheetName,
    headerRow: headerRow.present ? headerRow.value : this.headerRow,
    identityFields: identityFields ?? this.identityFields,
    detection: detection ?? this.detection,
    version: version ?? this.version,
  );
  Template copyWithCompanion(TemplatesCompanion data) {
    return Template(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      source: data.source.present ? data.source.value : this.source,
      sourceFilePath: data.sourceFilePath.present
          ? data.sourceFilePath.value
          : this.sourceFilePath,
      sheetName: data.sheetName.present ? data.sheetName.value : this.sheetName,
      headerRow: data.headerRow.present ? data.headerRow.value : this.headerRow,
      identityFields: data.identityFields.present
          ? data.identityFields.value
          : this.identityFields,
      detection: data.detection.present ? data.detection.value : this.detection,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Template(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('source: $source, ')
          ..write('sourceFilePath: $sourceFilePath, ')
          ..write('sheetName: $sheetName, ')
          ..write('headerRow: $headerRow, ')
          ..write('identityFields: $identityFields, ')
          ..write('detection: $detection, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    projectId,
    name,
    kind,
    source,
    sourceFilePath,
    sheetName,
    headerRow,
    identityFields,
    detection,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Template &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.source == this.source &&
          other.sourceFilePath == this.sourceFilePath &&
          other.sheetName == this.sheetName &&
          other.headerRow == this.headerRow &&
          other.identityFields == this.identityFields &&
          other.detection == this.detection &&
          other.version == this.version);
}

class TemplatesCompanion extends UpdateCompanion<Template> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String?> projectId;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> source;
  final Value<String?> sourceFilePath;
  final Value<String?> sheetName;
  final Value<int?> headerRow;
  final Value<String> identityFields;
  final Value<String> detection;
  final Value<int> version;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceFilePath = const Value.absent(),
    this.sheetName = const Value.absent(),
    this.headerRow = const Value.absent(),
    this.identityFields = const Value.absent(),
    this.detection = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    this.projectId = const Value.absent(),
    required String name,
    required String kind,
    required String source,
    this.sourceFilePath = const Value.absent(),
    this.sheetName = const Value.absent(),
    this.headerRow = const Value.absent(),
    this.identityFields = const Value.absent(),
    this.detection = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       name = Value(name),
       kind = Value(kind),
       source = Value(source);
  static Insertable<Template> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? projectId,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? source,
    Expression<String>? sourceFilePath,
    Expression<String>? sheetName,
    Expression<int>? headerRow,
    Expression<String>? identityFields,
    Expression<String>? detection,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (source != null) 'source': source,
      if (sourceFilePath != null) 'source_file_path': sourceFilePath,
      if (sheetName != null) 'sheet_name': sheetName,
      if (headerRow != null) 'header_row': headerRow,
      if (identityFields != null) 'identity_fields': identityFields,
      if (detection != null) 'detection': detection,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String?>? projectId,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? source,
    Value<String?>? sourceFilePath,
    Value<String?>? sheetName,
    Value<int?>? headerRow,
    Value<String>? identityFields,
    Value<String>? detection,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return TemplatesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      source: source ?? this.source,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      sheetName: sheetName ?? this.sheetName,
      headerRow: headerRow ?? this.headerRow,
      identityFields: identityFields ?? this.identityFields,
      detection: detection ?? this.detection,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceFilePath.present) {
      map['source_file_path'] = Variable<String>(sourceFilePath.value);
    }
    if (sheetName.present) {
      map['sheet_name'] = Variable<String>(sheetName.value);
    }
    if (headerRow.present) {
      map['header_row'] = Variable<int>(headerRow.value);
    }
    if (identityFields.present) {
      map['identity_fields'] = Variable<String>(identityFields.value);
    }
    if (detection.present) {
      map['detection'] = Variable<String>(detection.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('source: $source, ')
          ..write('sourceFilePath: $sourceFilePath, ')
          ..write('sheetName: $sheetName, ')
          ..write('headerRow: $headerRow, ')
          ..write('identityFields: $identityFields, ')
          ..write('detection: $detection, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplateFieldsTable extends TemplateFields
    with TableInfo<$TemplateFieldsTable, TemplateField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldKeyMeta = const VerificationMeta(
    'fieldKey',
  );
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
    'field_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputColumnMeta = const VerificationMeta(
    'outputColumn',
  );
  @override
  late final GeneratedColumn<String> outputColumn = GeneratedColumn<String>(
    'output_column',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRequiredMeta = const VerificationMeta(
    'isRequired',
  );
  @override
  late final GeneratedColumn<bool> isRequired = GeneratedColumn<bool>(
    'required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("required" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _inputModeMeta = const VerificationMeta(
    'inputMode',
  );
  @override
  late final GeneratedColumn<String> inputMode = GeneratedColumn<String>(
    'input_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _stickableMeta = const VerificationMeta(
    'stickable',
  );
  @override
  late final GeneratedColumn<bool> stickable = GeneratedColumn<bool>(
    'stickable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("stickable" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _contextLevelMeta = const VerificationMeta(
    'contextLevel',
  );
  @override
  late final GeneratedColumn<int> contextLevel = GeneratedColumn<int>(
    'context_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoFillMeta = const VerificationMeta(
    'autoFill',
  );
  @override
  late final GeneratedColumn<bool> autoFill = GeneratedColumn<bool>(
    'auto_fill',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_fill" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _defaultValueMeta = const VerificationMeta(
    'defaultValue',
  );
  @override
  late final GeneratedColumn<String> defaultValue = GeneratedColumn<String>(
    'default_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optionsMeta = const VerificationMeta(
    'options',
  );
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
    'options',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validationMeta = const VerificationMeta(
    'validation',
  );
  @override
  late final GeneratedColumn<String> validation = GeneratedColumn<String>(
    'validation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _lookupMeta = const VerificationMeta('lookup');
  @override
  late final GeneratedColumn<String> lookup = GeneratedColumn<String>(
    'lookup',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _refineMeta = const VerificationMeta('refine');
  @override
  late final GeneratedColumn<bool> refine = GeneratedColumn<bool>(
    'refine',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("refine" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    templateId,
    fieldKey,
    label,
    type,
    outputColumn,
    isRequired,
    inputMode,
    stickable,
    contextLevel,
    autoFill,
    defaultValue,
    options,
    unit,
    validation,
    lookup,
    refine,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateField> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('field_key')) {
      context.handle(
        _fieldKeyMeta,
        fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('output_column')) {
      context.handle(
        _outputColumnMeta,
        outputColumn.isAcceptableOrUnknown(
          data['output_column']!,
          _outputColumnMeta,
        ),
      );
    }
    if (data.containsKey('required')) {
      context.handle(
        _isRequiredMeta,
        isRequired.isAcceptableOrUnknown(data['required']!, _isRequiredMeta),
      );
    }
    if (data.containsKey('input_mode')) {
      context.handle(
        _inputModeMeta,
        inputMode.isAcceptableOrUnknown(data['input_mode']!, _inputModeMeta),
      );
    }
    if (data.containsKey('stickable')) {
      context.handle(
        _stickableMeta,
        stickable.isAcceptableOrUnknown(data['stickable']!, _stickableMeta),
      );
    }
    if (data.containsKey('context_level')) {
      context.handle(
        _contextLevelMeta,
        contextLevel.isAcceptableOrUnknown(
          data['context_level']!,
          _contextLevelMeta,
        ),
      );
    }
    if (data.containsKey('auto_fill')) {
      context.handle(
        _autoFillMeta,
        autoFill.isAcceptableOrUnknown(data['auto_fill']!, _autoFillMeta),
      );
    }
    if (data.containsKey('default_value')) {
      context.handle(
        _defaultValueMeta,
        defaultValue.isAcceptableOrUnknown(
          data['default_value']!,
          _defaultValueMeta,
        ),
      );
    }
    if (data.containsKey('options')) {
      context.handle(
        _optionsMeta,
        options.isAcceptableOrUnknown(data['options']!, _optionsMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('validation')) {
      context.handle(
        _validationMeta,
        validation.isAcceptableOrUnknown(data['validation']!, _validationMeta),
      );
    }
    if (data.containsKey('lookup')) {
      context.handle(
        _lookupMeta,
        lookup.isAcceptableOrUnknown(data['lookup']!, _lookupMeta),
      );
    }
    if (data.containsKey('refine')) {
      context.handle(
        _refineMeta,
        refine.isAcceptableOrUnknown(data['refine']!, _refineMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {templateId, fieldKey},
  ];
  @override
  TemplateField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateField(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      outputColumn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_column'],
      ),
      isRequired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}required'],
      )!,
      inputMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_mode'],
      )!,
      stickable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}stickable'],
      )!,
      contextLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}context_level'],
      ),
      autoFill: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_fill'],
      )!,
      defaultValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_value'],
      ),
      options: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      validation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}validation'],
      )!,
      lookup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lookup'],
      )!,
      refine: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}refine'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TemplateFieldsTable createAlias(String alias) {
    return $TemplateFieldsTable(attachedDatabase, alias);
  }
}

class TemplateField extends DataClass implements Insertable<TemplateField> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// Template this field belongs to.
  final String templateId;

  /// Stable key within the template. Duplicate keys are a unique constraint.
  final String fieldKey;

  /// Operator-facing label, stored as data.
  final String label;

  /// Field type name, stored as data.
  final String type;

  /// Spreadsheet column or generated header this field writes to.
  final String? outputColumn;

  /// Whether a first capture must fill this field.
  ///
  /// Dart cannot name a companion field `required`, so the SQL column is
  /// `required` and the getter is [isRequired].
  final bool isRequired;

  /// How the value is entered.
  final String inputMode;

  /// Whether the last value sticks onto the next record.
  final bool stickable;

  /// Context hierarchy level this field binds to, when it does.
  final int? contextLevel;

  /// Whether capture copies this value from context or a previous record.
  final bool autoFill;

  /// Default written when the operator leaves the field empty.
  final String? defaultValue;

  /// Choice options JSON. An object or array, validated on write.
  final String options;

  /// Unit label, when the type has one.
  final String? unit;

  /// Validation JSON. An object or array, validated on write.
  final String validation;

  /// Lookup JSON. An object or array, validated on write.
  final String lookup;

  /// Whether AI may propose a refined value beside the raw one.
  final bool refine;

  /// List order. Reads sort by this, then [label].
  final int sortOrder;
  const TemplateField({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.templateId,
    required this.fieldKey,
    required this.label,
    required this.type,
    this.outputColumn,
    required this.isRequired,
    required this.inputMode,
    required this.stickable,
    this.contextLevel,
    required this.autoFill,
    this.defaultValue,
    required this.options,
    this.unit,
    required this.validation,
    required this.lookup,
    required this.refine,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['template_id'] = Variable<String>(templateId);
    map['field_key'] = Variable<String>(fieldKey);
    map['label'] = Variable<String>(label);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || outputColumn != null) {
      map['output_column'] = Variable<String>(outputColumn);
    }
    map['required'] = Variable<bool>(isRequired);
    map['input_mode'] = Variable<String>(inputMode);
    map['stickable'] = Variable<bool>(stickable);
    if (!nullToAbsent || contextLevel != null) {
      map['context_level'] = Variable<int>(contextLevel);
    }
    map['auto_fill'] = Variable<bool>(autoFill);
    if (!nullToAbsent || defaultValue != null) {
      map['default_value'] = Variable<String>(defaultValue);
    }
    map['options'] = Variable<String>(options);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['validation'] = Variable<String>(validation);
    map['lookup'] = Variable<String>(lookup);
    map['refine'] = Variable<bool>(refine);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TemplateFieldsCompanion toCompanion(bool nullToAbsent) {
    return TemplateFieldsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      templateId: Value(templateId),
      fieldKey: Value(fieldKey),
      label: Value(label),
      type: Value(type),
      outputColumn: outputColumn == null && nullToAbsent
          ? const Value.absent()
          : Value(outputColumn),
      isRequired: Value(isRequired),
      inputMode: Value(inputMode),
      stickable: Value(stickable),
      contextLevel: contextLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(contextLevel),
      autoFill: Value(autoFill),
      defaultValue: defaultValue == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultValue),
      options: Value(options),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      validation: Value(validation),
      lookup: Value(lookup),
      refine: Value(refine),
      sortOrder: Value(sortOrder),
    );
  }

  factory TemplateField.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateField(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      templateId: serializer.fromJson<String>(json['templateId']),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      label: serializer.fromJson<String>(json['label']),
      type: serializer.fromJson<String>(json['type']),
      outputColumn: serializer.fromJson<String?>(json['outputColumn']),
      isRequired: serializer.fromJson<bool>(json['isRequired']),
      inputMode: serializer.fromJson<String>(json['inputMode']),
      stickable: serializer.fromJson<bool>(json['stickable']),
      contextLevel: serializer.fromJson<int?>(json['contextLevel']),
      autoFill: serializer.fromJson<bool>(json['autoFill']),
      defaultValue: serializer.fromJson<String?>(json['defaultValue']),
      options: serializer.fromJson<String>(json['options']),
      unit: serializer.fromJson<String?>(json['unit']),
      validation: serializer.fromJson<String>(json['validation']),
      lookup: serializer.fromJson<String>(json['lookup']),
      refine: serializer.fromJson<bool>(json['refine']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'templateId': serializer.toJson<String>(templateId),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'label': serializer.toJson<String>(label),
      'type': serializer.toJson<String>(type),
      'outputColumn': serializer.toJson<String?>(outputColumn),
      'isRequired': serializer.toJson<bool>(isRequired),
      'inputMode': serializer.toJson<String>(inputMode),
      'stickable': serializer.toJson<bool>(stickable),
      'contextLevel': serializer.toJson<int?>(contextLevel),
      'autoFill': serializer.toJson<bool>(autoFill),
      'defaultValue': serializer.toJson<String?>(defaultValue),
      'options': serializer.toJson<String>(options),
      'unit': serializer.toJson<String?>(unit),
      'validation': serializer.toJson<String>(validation),
      'lookup': serializer.toJson<String>(lookup),
      'refine': serializer.toJson<bool>(refine),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TemplateField copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? templateId,
    String? fieldKey,
    String? label,
    String? type,
    Value<String?> outputColumn = const Value.absent(),
    bool? isRequired,
    String? inputMode,
    bool? stickable,
    Value<int?> contextLevel = const Value.absent(),
    bool? autoFill,
    Value<String?> defaultValue = const Value.absent(),
    String? options,
    Value<String?> unit = const Value.absent(),
    String? validation,
    String? lookup,
    bool? refine,
    int? sortOrder,
  }) => TemplateField(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    templateId: templateId ?? this.templateId,
    fieldKey: fieldKey ?? this.fieldKey,
    label: label ?? this.label,
    type: type ?? this.type,
    outputColumn: outputColumn.present ? outputColumn.value : this.outputColumn,
    isRequired: isRequired ?? this.isRequired,
    inputMode: inputMode ?? this.inputMode,
    stickable: stickable ?? this.stickable,
    contextLevel: contextLevel.present ? contextLevel.value : this.contextLevel,
    autoFill: autoFill ?? this.autoFill,
    defaultValue: defaultValue.present ? defaultValue.value : this.defaultValue,
    options: options ?? this.options,
    unit: unit.present ? unit.value : this.unit,
    validation: validation ?? this.validation,
    lookup: lookup ?? this.lookup,
    refine: refine ?? this.refine,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TemplateField copyWithCompanion(TemplateFieldsCompanion data) {
    return TemplateField(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      label: data.label.present ? data.label.value : this.label,
      type: data.type.present ? data.type.value : this.type,
      outputColumn: data.outputColumn.present
          ? data.outputColumn.value
          : this.outputColumn,
      isRequired: data.isRequired.present
          ? data.isRequired.value
          : this.isRequired,
      inputMode: data.inputMode.present ? data.inputMode.value : this.inputMode,
      stickable: data.stickable.present ? data.stickable.value : this.stickable,
      contextLevel: data.contextLevel.present
          ? data.contextLevel.value
          : this.contextLevel,
      autoFill: data.autoFill.present ? data.autoFill.value : this.autoFill,
      defaultValue: data.defaultValue.present
          ? data.defaultValue.value
          : this.defaultValue,
      options: data.options.present ? data.options.value : this.options,
      unit: data.unit.present ? data.unit.value : this.unit,
      validation: data.validation.present
          ? data.validation.value
          : this.validation,
      lookup: data.lookup.present ? data.lookup.value : this.lookup,
      refine: data.refine.present ? data.refine.value : this.refine,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateField(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('templateId: $templateId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('label: $label, ')
          ..write('type: $type, ')
          ..write('outputColumn: $outputColumn, ')
          ..write('isRequired: $isRequired, ')
          ..write('inputMode: $inputMode, ')
          ..write('stickable: $stickable, ')
          ..write('contextLevel: $contextLevel, ')
          ..write('autoFill: $autoFill, ')
          ..write('defaultValue: $defaultValue, ')
          ..write('options: $options, ')
          ..write('unit: $unit, ')
          ..write('validation: $validation, ')
          ..write('lookup: $lookup, ')
          ..write('refine: $refine, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    templateId,
    fieldKey,
    label,
    type,
    outputColumn,
    isRequired,
    inputMode,
    stickable,
    contextLevel,
    autoFill,
    defaultValue,
    options,
    unit,
    validation,
    lookup,
    refine,
    sortOrder,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateField &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.templateId == this.templateId &&
          other.fieldKey == this.fieldKey &&
          other.label == this.label &&
          other.type == this.type &&
          other.outputColumn == this.outputColumn &&
          other.isRequired == this.isRequired &&
          other.inputMode == this.inputMode &&
          other.stickable == this.stickable &&
          other.contextLevel == this.contextLevel &&
          other.autoFill == this.autoFill &&
          other.defaultValue == this.defaultValue &&
          other.options == this.options &&
          other.unit == this.unit &&
          other.validation == this.validation &&
          other.lookup == this.lookup &&
          other.refine == this.refine &&
          other.sortOrder == this.sortOrder);
}

class TemplateFieldsCompanion extends UpdateCompanion<TemplateField> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> templateId;
  final Value<String> fieldKey;
  final Value<String> label;
  final Value<String> type;
  final Value<String?> outputColumn;
  final Value<bool> isRequired;
  final Value<String> inputMode;
  final Value<bool> stickable;
  final Value<int?> contextLevel;
  final Value<bool> autoFill;
  final Value<String?> defaultValue;
  final Value<String> options;
  final Value<String?> unit;
  final Value<String> validation;
  final Value<String> lookup;
  final Value<bool> refine;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const TemplateFieldsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.templateId = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.label = const Value.absent(),
    this.type = const Value.absent(),
    this.outputColumn = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.inputMode = const Value.absent(),
    this.stickable = const Value.absent(),
    this.contextLevel = const Value.absent(),
    this.autoFill = const Value.absent(),
    this.defaultValue = const Value.absent(),
    this.options = const Value.absent(),
    this.unit = const Value.absent(),
    this.validation = const Value.absent(),
    this.lookup = const Value.absent(),
    this.refine = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateFieldsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String templateId,
    required String fieldKey,
    required String label,
    required String type,
    this.outputColumn = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.inputMode = const Value.absent(),
    this.stickable = const Value.absent(),
    this.contextLevel = const Value.absent(),
    this.autoFill = const Value.absent(),
    this.defaultValue = const Value.absent(),
    this.options = const Value.absent(),
    this.unit = const Value.absent(),
    this.validation = const Value.absent(),
    this.lookup = const Value.absent(),
    this.refine = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       templateId = Value(templateId),
       fieldKey = Value(fieldKey),
       label = Value(label),
       type = Value(type),
       sortOrder = Value(sortOrder);
  static Insertable<TemplateField> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? templateId,
    Expression<String>? fieldKey,
    Expression<String>? label,
    Expression<String>? type,
    Expression<String>? outputColumn,
    Expression<bool>? isRequired,
    Expression<String>? inputMode,
    Expression<bool>? stickable,
    Expression<int>? contextLevel,
    Expression<bool>? autoFill,
    Expression<String>? defaultValue,
    Expression<String>? options,
    Expression<String>? unit,
    Expression<String>? validation,
    Expression<String>? lookup,
    Expression<bool>? refine,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (templateId != null) 'template_id': templateId,
      if (fieldKey != null) 'field_key': fieldKey,
      if (label != null) 'label': label,
      if (type != null) 'type': type,
      if (outputColumn != null) 'output_column': outputColumn,
      if (isRequired != null) 'required': isRequired,
      if (inputMode != null) 'input_mode': inputMode,
      if (stickable != null) 'stickable': stickable,
      if (contextLevel != null) 'context_level': contextLevel,
      if (autoFill != null) 'auto_fill': autoFill,
      if (defaultValue != null) 'default_value': defaultValue,
      if (options != null) 'options': options,
      if (unit != null) 'unit': unit,
      if (validation != null) 'validation': validation,
      if (lookup != null) 'lookup': lookup,
      if (refine != null) 'refine': refine,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateFieldsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? templateId,
    Value<String>? fieldKey,
    Value<String>? label,
    Value<String>? type,
    Value<String?>? outputColumn,
    Value<bool>? isRequired,
    Value<String>? inputMode,
    Value<bool>? stickable,
    Value<int?>? contextLevel,
    Value<bool>? autoFill,
    Value<String?>? defaultValue,
    Value<String>? options,
    Value<String?>? unit,
    Value<String>? validation,
    Value<String>? lookup,
    Value<bool>? refine,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return TemplateFieldsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      templateId: templateId ?? this.templateId,
      fieldKey: fieldKey ?? this.fieldKey,
      label: label ?? this.label,
      type: type ?? this.type,
      outputColumn: outputColumn ?? this.outputColumn,
      isRequired: isRequired ?? this.isRequired,
      inputMode: inputMode ?? this.inputMode,
      stickable: stickable ?? this.stickable,
      contextLevel: contextLevel ?? this.contextLevel,
      autoFill: autoFill ?? this.autoFill,
      defaultValue: defaultValue ?? this.defaultValue,
      options: options ?? this.options,
      unit: unit ?? this.unit,
      validation: validation ?? this.validation,
      lookup: lookup ?? this.lookup,
      refine: refine ?? this.refine,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (outputColumn.present) {
      map['output_column'] = Variable<String>(outputColumn.value);
    }
    if (isRequired.present) {
      map['required'] = Variable<bool>(isRequired.value);
    }
    if (inputMode.present) {
      map['input_mode'] = Variable<String>(inputMode.value);
    }
    if (stickable.present) {
      map['stickable'] = Variable<bool>(stickable.value);
    }
    if (contextLevel.present) {
      map['context_level'] = Variable<int>(contextLevel.value);
    }
    if (autoFill.present) {
      map['auto_fill'] = Variable<bool>(autoFill.value);
    }
    if (defaultValue.present) {
      map['default_value'] = Variable<String>(defaultValue.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (validation.present) {
      map['validation'] = Variable<String>(validation.value);
    }
    if (lookup.present) {
      map['lookup'] = Variable<String>(lookup.value);
    }
    if (refine.present) {
      map['refine'] = Variable<bool>(refine.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateFieldsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('templateId: $templateId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('label: $label, ')
          ..write('type: $type, ')
          ..write('outputColumn: $outputColumn, ')
          ..write('isRequired: $isRequired, ')
          ..write('inputMode: $inputMode, ')
          ..write('stickable: $stickable, ')
          ..write('contextLevel: $contextLevel, ')
          ..write('autoFill: $autoFill, ')
          ..write('defaultValue: $defaultValue, ')
          ..write('options: $options, ')
          ..write('unit: $unit, ')
          ..write('validation: $validation, ')
          ..write('lookup: $lookup, ')
          ..write('refine: $refine, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplateRowsTable extends TemplateRows
    with TableInfo<$TemplateRowsTable, TemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputRowNumberMeta = const VerificationMeta(
    'outputRowNumber',
  );
  @override
  late final GeneratedColumn<int> outputRowNumber = GeneratedColumn<int>(
    'output_row_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identifierMeta = const VerificationMeta(
    'identifier',
  );
  @override
  late final GeneratedColumn<String> identifier = GeneratedColumn<String>(
    'identifier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aliasesMeta = const VerificationMeta(
    'aliases',
  );
  @override
  late final GeneratedColumn<String> aliases = GeneratedColumn<String>(
    'aliases',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _foundStatusMeta = const VerificationMeta(
    'foundStatus',
  );
  @override
  late final GeneratedColumn<String> foundStatus = GeneratedColumn<String>(
    'found_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('missing'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    templateId,
    outputRowNumber,
    identifier,
    label,
    aliases,
    metadata,
    foundStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('output_row_number')) {
      context.handle(
        _outputRowNumberMeta,
        outputRowNumber.isAcceptableOrUnknown(
          data['output_row_number']!,
          _outputRowNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outputRowNumberMeta);
    }
    if (data.containsKey('identifier')) {
      context.handle(
        _identifierMeta,
        identifier.isAcceptableOrUnknown(data['identifier']!, _identifierMeta),
      );
    } else if (isInserting) {
      context.missing(_identifierMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('aliases')) {
      context.handle(
        _aliasesMeta,
        aliases.isAcceptableOrUnknown(data['aliases']!, _aliasesMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('found_status')) {
      context.handle(
        _foundStatusMeta,
        foundStatus.isAcceptableOrUnknown(
          data['found_status']!,
          _foundStatusMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      outputRowNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_row_number'],
      )!,
      identifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identifier'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      aliases: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aliases'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      )!,
      foundStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}found_status'],
      )!,
    );
  }

  @override
  $TemplateRowsTable createAlias(String alias) {
    return $TemplateRowsTable(attachedDatabase, alias);
  }
}

class TemplateRow extends DataClass implements Insertable<TemplateRow> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// Template this row belongs to.
  final String templateId;

  /// Original spreadsheet row number, kept for write-back.
  final int outputRowNumber;

  /// Stable identifier within the template.
  final String identifier;

  /// Operator-facing label, stored as data.
  final String label;

  /// Alias list JSON. An object or array, validated on write.
  final String aliases;

  /// Extra row JSON. An object or array, validated on write.
  final String metadata;

  /// Found / missing status for the capture checklist.
  final String foundStatus;
  const TemplateRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.templateId,
    required this.outputRowNumber,
    required this.identifier,
    required this.label,
    required this.aliases,
    required this.metadata,
    required this.foundStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['template_id'] = Variable<String>(templateId);
    map['output_row_number'] = Variable<int>(outputRowNumber);
    map['identifier'] = Variable<String>(identifier);
    map['label'] = Variable<String>(label);
    map['aliases'] = Variable<String>(aliases);
    map['metadata'] = Variable<String>(metadata);
    map['found_status'] = Variable<String>(foundStatus);
    return map;
  }

  TemplateRowsCompanion toCompanion(bool nullToAbsent) {
    return TemplateRowsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      templateId: Value(templateId),
      outputRowNumber: Value(outputRowNumber),
      identifier: Value(identifier),
      label: Value(label),
      aliases: Value(aliases),
      metadata: Value(metadata),
      foundStatus: Value(foundStatus),
    );
  }

  factory TemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      templateId: serializer.fromJson<String>(json['templateId']),
      outputRowNumber: serializer.fromJson<int>(json['outputRowNumber']),
      identifier: serializer.fromJson<String>(json['identifier']),
      label: serializer.fromJson<String>(json['label']),
      aliases: serializer.fromJson<String>(json['aliases']),
      metadata: serializer.fromJson<String>(json['metadata']),
      foundStatus: serializer.fromJson<String>(json['foundStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'templateId': serializer.toJson<String>(templateId),
      'outputRowNumber': serializer.toJson<int>(outputRowNumber),
      'identifier': serializer.toJson<String>(identifier),
      'label': serializer.toJson<String>(label),
      'aliases': serializer.toJson<String>(aliases),
      'metadata': serializer.toJson<String>(metadata),
      'foundStatus': serializer.toJson<String>(foundStatus),
    };
  }

  TemplateRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? templateId,
    int? outputRowNumber,
    String? identifier,
    String? label,
    String? aliases,
    String? metadata,
    String? foundStatus,
  }) => TemplateRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    templateId: templateId ?? this.templateId,
    outputRowNumber: outputRowNumber ?? this.outputRowNumber,
    identifier: identifier ?? this.identifier,
    label: label ?? this.label,
    aliases: aliases ?? this.aliases,
    metadata: metadata ?? this.metadata,
    foundStatus: foundStatus ?? this.foundStatus,
  );
  TemplateRow copyWithCompanion(TemplateRowsCompanion data) {
    return TemplateRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      outputRowNumber: data.outputRowNumber.present
          ? data.outputRowNumber.value
          : this.outputRowNumber,
      identifier: data.identifier.present
          ? data.identifier.value
          : this.identifier,
      label: data.label.present ? data.label.value : this.label,
      aliases: data.aliases.present ? data.aliases.value : this.aliases,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      foundStatus: data.foundStatus.present
          ? data.foundStatus.value
          : this.foundStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('templateId: $templateId, ')
          ..write('outputRowNumber: $outputRowNumber, ')
          ..write('identifier: $identifier, ')
          ..write('label: $label, ')
          ..write('aliases: $aliases, ')
          ..write('metadata: $metadata, ')
          ..write('foundStatus: $foundStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    templateId,
    outputRowNumber,
    identifier,
    label,
    aliases,
    metadata,
    foundStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.templateId == this.templateId &&
          other.outputRowNumber == this.outputRowNumber &&
          other.identifier == this.identifier &&
          other.label == this.label &&
          other.aliases == this.aliases &&
          other.metadata == this.metadata &&
          other.foundStatus == this.foundStatus);
}

class TemplateRowsCompanion extends UpdateCompanion<TemplateRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> templateId;
  final Value<int> outputRowNumber;
  final Value<String> identifier;
  final Value<String> label;
  final Value<String> aliases;
  final Value<String> metadata;
  final Value<String> foundStatus;
  final Value<int> rowid;
  const TemplateRowsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.templateId = const Value.absent(),
    this.outputRowNumber = const Value.absent(),
    this.identifier = const Value.absent(),
    this.label = const Value.absent(),
    this.aliases = const Value.absent(),
    this.metadata = const Value.absent(),
    this.foundStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateRowsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String templateId,
    required int outputRowNumber,
    required String identifier,
    required String label,
    this.aliases = const Value.absent(),
    this.metadata = const Value.absent(),
    this.foundStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       templateId = Value(templateId),
       outputRowNumber = Value(outputRowNumber),
       identifier = Value(identifier),
       label = Value(label);
  static Insertable<TemplateRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? templateId,
    Expression<int>? outputRowNumber,
    Expression<String>? identifier,
    Expression<String>? label,
    Expression<String>? aliases,
    Expression<String>? metadata,
    Expression<String>? foundStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (templateId != null) 'template_id': templateId,
      if (outputRowNumber != null) 'output_row_number': outputRowNumber,
      if (identifier != null) 'identifier': identifier,
      if (label != null) 'label': label,
      if (aliases != null) 'aliases': aliases,
      if (metadata != null) 'metadata': metadata,
      if (foundStatus != null) 'found_status': foundStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateRowsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? templateId,
    Value<int>? outputRowNumber,
    Value<String>? identifier,
    Value<String>? label,
    Value<String>? aliases,
    Value<String>? metadata,
    Value<String>? foundStatus,
    Value<int>? rowid,
  }) {
    return TemplateRowsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      templateId: templateId ?? this.templateId,
      outputRowNumber: outputRowNumber ?? this.outputRowNumber,
      identifier: identifier ?? this.identifier,
      label: label ?? this.label,
      aliases: aliases ?? this.aliases,
      metadata: metadata ?? this.metadata,
      foundStatus: foundStatus ?? this.foundStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (outputRowNumber.present) {
      map['output_row_number'] = Variable<int>(outputRowNumber.value);
    }
    if (identifier.present) {
      map['identifier'] = Variable<String>(identifier.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (aliases.present) {
      map['aliases'] = Variable<String>(aliases.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (foundStatus.present) {
      map['found_status'] = Variable<String>(foundStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateRowsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('templateId: $templateId, ')
          ..write('outputRowNumber: $outputRowNumber, ')
          ..write('identifier: $identifier, ')
          ..write('label: $label, ')
          ..write('aliases: $aliases, ')
          ..write('metadata: $metadata, ')
          ..write('foundStatus: $foundStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordsTable extends Records with TableInfo<$RecordsTable, RecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateRowIdMeta = const VerificationMeta(
    'templateRowId',
  );
  @override
  late final GeneratedColumn<String> templateRowId = GeneratedColumn<String>(
    'template_row_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processingModeMeta = const VerificationMeta(
    'processingMode',
  );
  @override
  late final GeneratedColumn<String> processingMode = GeneratedColumn<String>(
    'processing_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextJsonMeta = const VerificationMeta(
    'contextJson',
  );
  @override
  late final GeneratedColumn<String> contextJson = GeneratedColumn<String>(
    'context_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identityHashMeta = const VerificationMeta(
    'identityHash',
  );
  @override
  late final GeneratedColumn<String> identityHash = GeneratedColumn<String>(
    'identity_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedByMeta = const VerificationMeta(
    'capturedBy',
  );
  @override
  late final GeneratedColumn<String> capturedBy = GeneratedColumn<String>(
    'captured_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gpsLatMeta = const VerificationMeta('gpsLat');
  @override
  late final GeneratedColumn<double> gpsLat = GeneratedColumn<double>(
    'gps_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsLonMeta = const VerificationMeta('gpsLon');
  @override
  late final GeneratedColumn<double> gpsLon = GeneratedColumn<double>(
    'gps_lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedAtMeta = const VerificationMeta(
    'approvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> approvedAt = GeneratedColumn<DateTime>(
    'approved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedByMeta = const VerificationMeta(
    'approvedBy',
  );
  @override
  late final GeneratedColumn<String> approvedBy = GeneratedColumn<String>(
    'approved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    projectId,
    templateId,
    templateRowId,
    status,
    processingMode,
    contextJson,
    identityHash,
    source,
    capturedAt,
    capturedBy,
    gpsLat,
    gpsLon,
    approvedAt,
    approvedBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'records';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('template_row_id')) {
      context.handle(
        _templateRowIdMeta,
        templateRowId.isAcceptableOrUnknown(
          data['template_row_id']!,
          _templateRowIdMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('processing_mode')) {
      context.handle(
        _processingModeMeta,
        processingMode.isAcceptableOrUnknown(
          data['processing_mode']!,
          _processingModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processingModeMeta);
    }
    if (data.containsKey('context_json')) {
      context.handle(
        _contextJsonMeta,
        contextJson.isAcceptableOrUnknown(
          data['context_json']!,
          _contextJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contextJsonMeta);
    }
    if (data.containsKey('identity_hash')) {
      context.handle(
        _identityHashMeta,
        identityHash.isAcceptableOrUnknown(
          data['identity_hash']!,
          _identityHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identityHashMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('captured_by')) {
      context.handle(
        _capturedByMeta,
        capturedBy.isAcceptableOrUnknown(data['captured_by']!, _capturedByMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedByMeta);
    }
    if (data.containsKey('gps_lat')) {
      context.handle(
        _gpsLatMeta,
        gpsLat.isAcceptableOrUnknown(data['gps_lat']!, _gpsLatMeta),
      );
    }
    if (data.containsKey('gps_lon')) {
      context.handle(
        _gpsLonMeta,
        gpsLon.isAcceptableOrUnknown(data['gps_lon']!, _gpsLonMeta),
      );
    }
    if (data.containsKey('approved_at')) {
      context.handle(
        _approvedAtMeta,
        approvedAt.isAcceptableOrUnknown(data['approved_at']!, _approvedAtMeta),
      );
    }
    if (data.containsKey('approved_by')) {
      context.handle(
        _approvedByMeta,
        approvedBy.isAcceptableOrUnknown(data['approved_by']!, _approvedByMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      templateRowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_row_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      processingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}processing_mode'],
      )!,
      contextJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_json'],
      )!,
      identityHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_hash'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      capturedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}captured_by'],
      )!,
      gpsLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_lat'],
      ),
      gpsLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_lon'],
      ),
      approvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}approved_at'],
      ),
      approvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by'],
      ),
    );
  }

  @override
  $RecordsTable createAlias(String alias) {
    return $RecordsTable(attachedDatabase, alias);
  }
}

class RecordRow extends DataClass implements Insertable<RecordRow> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// Project this record belongs to.
  final String projectId;

  /// Template used at capture.
  final String templateId;

  /// Predefined checklist row, when the capture was against one.
  final String? templateRowId;

  /// Lifecycle status. Stored as text so this table does not import Flutter.
  final String status;

  /// How the record is processed (manual, on-device, online).
  final String processingMode;

  /// Context values in force at capture. An object, stored as text.
  final String contextJson;

  /// Hash of identity fields, so two devices can recognise the same record.
  final String identityHash;

  /// Where the record came from (capture, import, duplicate).
  final String source;

  /// When the operator captured it.
  final DateTime capturedAt;

  /// Operator who captured it.
  final String capturedBy;

  /// GPS latitude at capture, when known.
  final double? gpsLat;

  /// GPS longitude at capture, when known.
  final double? gpsLon;

  /// When the record was approved, if it has been.
  final DateTime? approvedAt;

  /// Operator who approved it.
  final String? approvedBy;
  const RecordRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.projectId,
    required this.templateId,
    this.templateRowId,
    required this.status,
    required this.processingMode,
    required this.contextJson,
    required this.identityHash,
    required this.source,
    required this.capturedAt,
    required this.capturedBy,
    this.gpsLat,
    this.gpsLon,
    this.approvedAt,
    this.approvedBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['project_id'] = Variable<String>(projectId);
    map['template_id'] = Variable<String>(templateId);
    if (!nullToAbsent || templateRowId != null) {
      map['template_row_id'] = Variable<String>(templateRowId);
    }
    map['status'] = Variable<String>(status);
    map['processing_mode'] = Variable<String>(processingMode);
    map['context_json'] = Variable<String>(contextJson);
    map['identity_hash'] = Variable<String>(identityHash);
    map['source'] = Variable<String>(source);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['captured_by'] = Variable<String>(capturedBy);
    if (!nullToAbsent || gpsLat != null) {
      map['gps_lat'] = Variable<double>(gpsLat);
    }
    if (!nullToAbsent || gpsLon != null) {
      map['gps_lon'] = Variable<double>(gpsLon);
    }
    if (!nullToAbsent || approvedAt != null) {
      map['approved_at'] = Variable<DateTime>(approvedAt);
    }
    if (!nullToAbsent || approvedBy != null) {
      map['approved_by'] = Variable<String>(approvedBy);
    }
    return map;
  }

  RecordsCompanion toCompanion(bool nullToAbsent) {
    return RecordsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      projectId: Value(projectId),
      templateId: Value(templateId),
      templateRowId: templateRowId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateRowId),
      status: Value(status),
      processingMode: Value(processingMode),
      contextJson: Value(contextJson),
      identityHash: Value(identityHash),
      source: Value(source),
      capturedAt: Value(capturedAt),
      capturedBy: Value(capturedBy),
      gpsLat: gpsLat == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsLat),
      gpsLon: gpsLon == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsLon),
      approvedAt: approvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedAt),
      approvedBy: approvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedBy),
    );
  }

  factory RecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      projectId: serializer.fromJson<String>(json['projectId']),
      templateId: serializer.fromJson<String>(json['templateId']),
      templateRowId: serializer.fromJson<String?>(json['templateRowId']),
      status: serializer.fromJson<String>(json['status']),
      processingMode: serializer.fromJson<String>(json['processingMode']),
      contextJson: serializer.fromJson<String>(json['contextJson']),
      identityHash: serializer.fromJson<String>(json['identityHash']),
      source: serializer.fromJson<String>(json['source']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      capturedBy: serializer.fromJson<String>(json['capturedBy']),
      gpsLat: serializer.fromJson<double?>(json['gpsLat']),
      gpsLon: serializer.fromJson<double?>(json['gpsLon']),
      approvedAt: serializer.fromJson<DateTime?>(json['approvedAt']),
      approvedBy: serializer.fromJson<String?>(json['approvedBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'projectId': serializer.toJson<String>(projectId),
      'templateId': serializer.toJson<String>(templateId),
      'templateRowId': serializer.toJson<String?>(templateRowId),
      'status': serializer.toJson<String>(status),
      'processingMode': serializer.toJson<String>(processingMode),
      'contextJson': serializer.toJson<String>(contextJson),
      'identityHash': serializer.toJson<String>(identityHash),
      'source': serializer.toJson<String>(source),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'capturedBy': serializer.toJson<String>(capturedBy),
      'gpsLat': serializer.toJson<double?>(gpsLat),
      'gpsLon': serializer.toJson<double?>(gpsLon),
      'approvedAt': serializer.toJson<DateTime?>(approvedAt),
      'approvedBy': serializer.toJson<String?>(approvedBy),
    };
  }

  RecordRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? projectId,
    String? templateId,
    Value<String?> templateRowId = const Value.absent(),
    String? status,
    String? processingMode,
    String? contextJson,
    String? identityHash,
    String? source,
    DateTime? capturedAt,
    String? capturedBy,
    Value<double?> gpsLat = const Value.absent(),
    Value<double?> gpsLon = const Value.absent(),
    Value<DateTime?> approvedAt = const Value.absent(),
    Value<String?> approvedBy = const Value.absent(),
  }) => RecordRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    projectId: projectId ?? this.projectId,
    templateId: templateId ?? this.templateId,
    templateRowId: templateRowId.present
        ? templateRowId.value
        : this.templateRowId,
    status: status ?? this.status,
    processingMode: processingMode ?? this.processingMode,
    contextJson: contextJson ?? this.contextJson,
    identityHash: identityHash ?? this.identityHash,
    source: source ?? this.source,
    capturedAt: capturedAt ?? this.capturedAt,
    capturedBy: capturedBy ?? this.capturedBy,
    gpsLat: gpsLat.present ? gpsLat.value : this.gpsLat,
    gpsLon: gpsLon.present ? gpsLon.value : this.gpsLon,
    approvedAt: approvedAt.present ? approvedAt.value : this.approvedAt,
    approvedBy: approvedBy.present ? approvedBy.value : this.approvedBy,
  );
  RecordRow copyWithCompanion(RecordsCompanion data) {
    return RecordRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      templateRowId: data.templateRowId.present
          ? data.templateRowId.value
          : this.templateRowId,
      status: data.status.present ? data.status.value : this.status,
      processingMode: data.processingMode.present
          ? data.processingMode.value
          : this.processingMode,
      contextJson: data.contextJson.present
          ? data.contextJson.value
          : this.contextJson,
      identityHash: data.identityHash.present
          ? data.identityHash.value
          : this.identityHash,
      source: data.source.present ? data.source.value : this.source,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      capturedBy: data.capturedBy.present
          ? data.capturedBy.value
          : this.capturedBy,
      gpsLat: data.gpsLat.present ? data.gpsLat.value : this.gpsLat,
      gpsLon: data.gpsLon.present ? data.gpsLon.value : this.gpsLon,
      approvedAt: data.approvedAt.present
          ? data.approvedAt.value
          : this.approvedAt,
      approvedBy: data.approvedBy.present
          ? data.approvedBy.value
          : this.approvedBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('templateId: $templateId, ')
          ..write('templateRowId: $templateRowId, ')
          ..write('status: $status, ')
          ..write('processingMode: $processingMode, ')
          ..write('contextJson: $contextJson, ')
          ..write('identityHash: $identityHash, ')
          ..write('source: $source, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('capturedBy: $capturedBy, ')
          ..write('gpsLat: $gpsLat, ')
          ..write('gpsLon: $gpsLon, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('approvedBy: $approvedBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    projectId,
    templateId,
    templateRowId,
    status,
    processingMode,
    contextJson,
    identityHash,
    source,
    capturedAt,
    capturedBy,
    gpsLat,
    gpsLon,
    approvedAt,
    approvedBy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.projectId == this.projectId &&
          other.templateId == this.templateId &&
          other.templateRowId == this.templateRowId &&
          other.status == this.status &&
          other.processingMode == this.processingMode &&
          other.contextJson == this.contextJson &&
          other.identityHash == this.identityHash &&
          other.source == this.source &&
          other.capturedAt == this.capturedAt &&
          other.capturedBy == this.capturedBy &&
          other.gpsLat == this.gpsLat &&
          other.gpsLon == this.gpsLon &&
          other.approvedAt == this.approvedAt &&
          other.approvedBy == this.approvedBy);
}

class RecordsCompanion extends UpdateCompanion<RecordRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> projectId;
  final Value<String> templateId;
  final Value<String?> templateRowId;
  final Value<String> status;
  final Value<String> processingMode;
  final Value<String> contextJson;
  final Value<String> identityHash;
  final Value<String> source;
  final Value<DateTime> capturedAt;
  final Value<String> capturedBy;
  final Value<double?> gpsLat;
  final Value<double?> gpsLon;
  final Value<DateTime?> approvedAt;
  final Value<String?> approvedBy;
  final Value<int> rowid;
  const RecordsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.projectId = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateRowId = const Value.absent(),
    this.status = const Value.absent(),
    this.processingMode = const Value.absent(),
    this.contextJson = const Value.absent(),
    this.identityHash = const Value.absent(),
    this.source = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.capturedBy = const Value.absent(),
    this.gpsLat = const Value.absent(),
    this.gpsLon = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String projectId,
    required String templateId,
    this.templateRowId = const Value.absent(),
    required String status,
    required String processingMode,
    required String contextJson,
    required String identityHash,
    required String source,
    required DateTime capturedAt,
    required String capturedBy,
    this.gpsLat = const Value.absent(),
    this.gpsLon = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       projectId = Value(projectId),
       templateId = Value(templateId),
       status = Value(status),
       processingMode = Value(processingMode),
       contextJson = Value(contextJson),
       identityHash = Value(identityHash),
       source = Value(source),
       capturedAt = Value(capturedAt),
       capturedBy = Value(capturedBy);
  static Insertable<RecordRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? projectId,
    Expression<String>? templateId,
    Expression<String>? templateRowId,
    Expression<String>? status,
    Expression<String>? processingMode,
    Expression<String>? contextJson,
    Expression<String>? identityHash,
    Expression<String>? source,
    Expression<DateTime>? capturedAt,
    Expression<String>? capturedBy,
    Expression<double>? gpsLat,
    Expression<double>? gpsLon,
    Expression<DateTime>? approvedAt,
    Expression<String>? approvedBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (projectId != null) 'project_id': projectId,
      if (templateId != null) 'template_id': templateId,
      if (templateRowId != null) 'template_row_id': templateRowId,
      if (status != null) 'status': status,
      if (processingMode != null) 'processing_mode': processingMode,
      if (contextJson != null) 'context_json': contextJson,
      if (identityHash != null) 'identity_hash': identityHash,
      if (source != null) 'source': source,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (capturedBy != null) 'captured_by': capturedBy,
      if (gpsLat != null) 'gps_lat': gpsLat,
      if (gpsLon != null) 'gps_lon': gpsLon,
      if (approvedAt != null) 'approved_at': approvedAt,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? projectId,
    Value<String>? templateId,
    Value<String?>? templateRowId,
    Value<String>? status,
    Value<String>? processingMode,
    Value<String>? contextJson,
    Value<String>? identityHash,
    Value<String>? source,
    Value<DateTime>? capturedAt,
    Value<String>? capturedBy,
    Value<double?>? gpsLat,
    Value<double?>? gpsLon,
    Value<DateTime?>? approvedAt,
    Value<String?>? approvedBy,
    Value<int>? rowid,
  }) {
    return RecordsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      projectId: projectId ?? this.projectId,
      templateId: templateId ?? this.templateId,
      templateRowId: templateRowId ?? this.templateRowId,
      status: status ?? this.status,
      processingMode: processingMode ?? this.processingMode,
      contextJson: contextJson ?? this.contextJson,
      identityHash: identityHash ?? this.identityHash,
      source: source ?? this.source,
      capturedAt: capturedAt ?? this.capturedAt,
      capturedBy: capturedBy ?? this.capturedBy,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLon: gpsLon ?? this.gpsLon,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (templateRowId.present) {
      map['template_row_id'] = Variable<String>(templateRowId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (processingMode.present) {
      map['processing_mode'] = Variable<String>(processingMode.value);
    }
    if (contextJson.present) {
      map['context_json'] = Variable<String>(contextJson.value);
    }
    if (identityHash.present) {
      map['identity_hash'] = Variable<String>(identityHash.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (capturedBy.present) {
      map['captured_by'] = Variable<String>(capturedBy.value);
    }
    if (gpsLat.present) {
      map['gps_lat'] = Variable<double>(gpsLat.value);
    }
    if (gpsLon.present) {
      map['gps_lon'] = Variable<double>(gpsLon.value);
    }
    if (approvedAt.present) {
      map['approved_at'] = Variable<DateTime>(approvedAt.value);
    }
    if (approvedBy.present) {
      map['approved_by'] = Variable<String>(approvedBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('templateId: $templateId, ')
          ..write('templateRowId: $templateRowId, ')
          ..write('status: $status, ')
          ..write('processingMode: $processingMode, ')
          ..write('contextJson: $contextJson, ')
          ..write('identityHash: $identityHash, ')
          ..write('source: $source, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('capturedBy: $capturedBy, ')
          ..write('gpsLat: $gpsLat, ')
          ..write('gpsLon: $gpsLon, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordFieldsTable extends RecordFields
    with TableInfo<$RecordFieldsTable, RecordField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldKeyMeta = const VerificationMeta(
    'fieldKey',
  );
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
    'field_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueRawMeta = const VerificationMeta(
    'valueRaw',
  );
  @override
  late final GeneratedColumn<String> valueRaw = GeneratedColumn<String>(
    'value_raw',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueRefinedMeta = const VerificationMeta(
    'valueRefined',
  );
  @override
  late final GeneratedColumn<String> valueRefined = GeneratedColumn<String>(
    'value_refined',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueFinalMeta = const VerificationMeta(
    'valueFinal',
  );
  @override
  late final GeneratedColumn<String> valueFinal = GeneratedColumn<String>(
    'value_final',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verifiedMeta = const VerificationMeta(
    'verified',
  );
  @override
  late final GeneratedColumn<bool> verified = GeneratedColumn<bool>(
    'verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _verifiedByMeta = const VerificationMeta(
    'verifiedBy',
  );
  @override
  late final GeneratedColumn<String> verifiedBy = GeneratedColumn<String>(
    'verified_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
    'verified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    recordId,
    fieldKey,
    valueRaw,
    valueRefined,
    valueFinal,
    confidence,
    source,
    verified,
    verifiedBy,
    verifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'record_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordField> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('field_key')) {
      context.handle(
        _fieldKeyMeta,
        fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('value_raw')) {
      context.handle(
        _valueRawMeta,
        valueRaw.isAcceptableOrUnknown(data['value_raw']!, _valueRawMeta),
      );
    }
    if (data.containsKey('value_refined')) {
      context.handle(
        _valueRefinedMeta,
        valueRefined.isAcceptableOrUnknown(
          data['value_refined']!,
          _valueRefinedMeta,
        ),
      );
    }
    if (data.containsKey('value_final')) {
      context.handle(
        _valueFinalMeta,
        valueFinal.isAcceptableOrUnknown(data['value_final']!, _valueFinalMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('verified')) {
      context.handle(
        _verifiedMeta,
        verified.isAcceptableOrUnknown(data['verified']!, _verifiedMeta),
      );
    }
    if (data.containsKey('verified_by')) {
      context.handle(
        _verifiedByMeta,
        verifiedBy.isAcceptableOrUnknown(data['verified_by']!, _verifiedByMeta),
      );
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {recordId, fieldKey},
  ];
  @override
  RecordField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordField(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      )!,
      valueRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_raw'],
      ),
      valueRefined: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_refined'],
      ),
      valueFinal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_final'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      verified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}verified'],
      )!,
      verifiedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verified_by'],
      ),
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}verified_at'],
      ),
    );
  }

  @override
  $RecordFieldsTable createAlias(String alias) {
    return $RecordFieldsTable(attachedDatabase, alias);
  }
}

class RecordField extends DataClass implements Insertable<RecordField> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// Record this value belongs to.
  final String recordId;

  /// Template field key this value fills.
  final String fieldKey;

  /// Original captured value. Written once at insert, never updated.
  final String? valueRaw;

  /// Refined value written beside the original, never over it.
  final String? valueRefined;

  /// Approved value used for export and search.
  final String? valueFinal;

  /// Confidence of a proposed refinement, when one exists.
  final double? confidence;

  /// Where this value came from (typed, lookup, extraction).
  final String source;

  /// Whether an operator has verified the final value.
  final bool verified;

  /// Operator who verified it.
  final String? verifiedBy;

  /// When it was verified.
  final DateTime? verifiedAt;
  const RecordField({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.recordId,
    required this.fieldKey,
    this.valueRaw,
    this.valueRefined,
    this.valueFinal,
    this.confidence,
    required this.source,
    required this.verified,
    this.verifiedBy,
    this.verifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['record_id'] = Variable<String>(recordId);
    map['field_key'] = Variable<String>(fieldKey);
    if (!nullToAbsent || valueRaw != null) {
      map['value_raw'] = Variable<String>(valueRaw);
    }
    if (!nullToAbsent || valueRefined != null) {
      map['value_refined'] = Variable<String>(valueRefined);
    }
    if (!nullToAbsent || valueFinal != null) {
      map['value_final'] = Variable<String>(valueFinal);
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    map['source'] = Variable<String>(source);
    map['verified'] = Variable<bool>(verified);
    if (!nullToAbsent || verifiedBy != null) {
      map['verified_by'] = Variable<String>(verifiedBy);
    }
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<DateTime>(verifiedAt);
    }
    return map;
  }

  RecordFieldsCompanion toCompanion(bool nullToAbsent) {
    return RecordFieldsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      recordId: Value(recordId),
      fieldKey: Value(fieldKey),
      valueRaw: valueRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(valueRaw),
      valueRefined: valueRefined == null && nullToAbsent
          ? const Value.absent()
          : Value(valueRefined),
      valueFinal: valueFinal == null && nullToAbsent
          ? const Value.absent()
          : Value(valueFinal),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      source: Value(source),
      verified: Value(verified),
      verifiedBy: verifiedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedBy),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
    );
  }

  factory RecordField.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordField(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      recordId: serializer.fromJson<String>(json['recordId']),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      valueRaw: serializer.fromJson<String?>(json['valueRaw']),
      valueRefined: serializer.fromJson<String?>(json['valueRefined']),
      valueFinal: serializer.fromJson<String?>(json['valueFinal']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      source: serializer.fromJson<String>(json['source']),
      verified: serializer.fromJson<bool>(json['verified']),
      verifiedBy: serializer.fromJson<String?>(json['verifiedBy']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'recordId': serializer.toJson<String>(recordId),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'valueRaw': serializer.toJson<String?>(valueRaw),
      'valueRefined': serializer.toJson<String?>(valueRefined),
      'valueFinal': serializer.toJson<String?>(valueFinal),
      'confidence': serializer.toJson<double?>(confidence),
      'source': serializer.toJson<String>(source),
      'verified': serializer.toJson<bool>(verified),
      'verifiedBy': serializer.toJson<String?>(verifiedBy),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
    };
  }

  RecordField copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? recordId,
    String? fieldKey,
    Value<String?> valueRaw = const Value.absent(),
    Value<String?> valueRefined = const Value.absent(),
    Value<String?> valueFinal = const Value.absent(),
    Value<double?> confidence = const Value.absent(),
    String? source,
    bool? verified,
    Value<String?> verifiedBy = const Value.absent(),
    Value<DateTime?> verifiedAt = const Value.absent(),
  }) => RecordField(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    recordId: recordId ?? this.recordId,
    fieldKey: fieldKey ?? this.fieldKey,
    valueRaw: valueRaw.present ? valueRaw.value : this.valueRaw,
    valueRefined: valueRefined.present ? valueRefined.value : this.valueRefined,
    valueFinal: valueFinal.present ? valueFinal.value : this.valueFinal,
    confidence: confidence.present ? confidence.value : this.confidence,
    source: source ?? this.source,
    verified: verified ?? this.verified,
    verifiedBy: verifiedBy.present ? verifiedBy.value : this.verifiedBy,
    verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
  );
  RecordField copyWithCompanion(RecordFieldsCompanion data) {
    return RecordField(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      valueRaw: data.valueRaw.present ? data.valueRaw.value : this.valueRaw,
      valueRefined: data.valueRefined.present
          ? data.valueRefined.value
          : this.valueRefined,
      valueFinal: data.valueFinal.present
          ? data.valueFinal.value
          : this.valueFinal,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      source: data.source.present ? data.source.value : this.source,
      verified: data.verified.present ? data.verified.value : this.verified,
      verifiedBy: data.verifiedBy.present
          ? data.verifiedBy.value
          : this.verifiedBy,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordField(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('recordId: $recordId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('valueRaw: $valueRaw, ')
          ..write('valueRefined: $valueRefined, ')
          ..write('valueFinal: $valueFinal, ')
          ..write('confidence: $confidence, ')
          ..write('source: $source, ')
          ..write('verified: $verified, ')
          ..write('verifiedBy: $verifiedBy, ')
          ..write('verifiedAt: $verifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    recordId,
    fieldKey,
    valueRaw,
    valueRefined,
    valueFinal,
    confidence,
    source,
    verified,
    verifiedBy,
    verifiedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordField &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.recordId == this.recordId &&
          other.fieldKey == this.fieldKey &&
          other.valueRaw == this.valueRaw &&
          other.valueRefined == this.valueRefined &&
          other.valueFinal == this.valueFinal &&
          other.confidence == this.confidence &&
          other.source == this.source &&
          other.verified == this.verified &&
          other.verifiedBy == this.verifiedBy &&
          other.verifiedAt == this.verifiedAt);
}

class RecordFieldsCompanion extends UpdateCompanion<RecordField> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> recordId;
  final Value<String> fieldKey;
  final Value<String?> valueRaw;
  final Value<String?> valueRefined;
  final Value<String?> valueFinal;
  final Value<double?> confidence;
  final Value<String> source;
  final Value<bool> verified;
  final Value<String?> verifiedBy;
  final Value<DateTime?> verifiedAt;
  final Value<int> rowid;
  const RecordFieldsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.recordId = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.valueRaw = const Value.absent(),
    this.valueRefined = const Value.absent(),
    this.valueFinal = const Value.absent(),
    this.confidence = const Value.absent(),
    this.source = const Value.absent(),
    this.verified = const Value.absent(),
    this.verifiedBy = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordFieldsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String recordId,
    required String fieldKey,
    this.valueRaw = const Value.absent(),
    this.valueRefined = const Value.absent(),
    this.valueFinal = const Value.absent(),
    this.confidence = const Value.absent(),
    required String source,
    this.verified = const Value.absent(),
    this.verifiedBy = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       recordId = Value(recordId),
       fieldKey = Value(fieldKey),
       source = Value(source);
  static Insertable<RecordField> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? recordId,
    Expression<String>? fieldKey,
    Expression<String>? valueRaw,
    Expression<String>? valueRefined,
    Expression<String>? valueFinal,
    Expression<double>? confidence,
    Expression<String>? source,
    Expression<bool>? verified,
    Expression<String>? verifiedBy,
    Expression<DateTime>? verifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (recordId != null) 'record_id': recordId,
      if (fieldKey != null) 'field_key': fieldKey,
      if (valueRaw != null) 'value_raw': valueRaw,
      if (valueRefined != null) 'value_refined': valueRefined,
      if (valueFinal != null) 'value_final': valueFinal,
      if (confidence != null) 'confidence': confidence,
      if (source != null) 'source': source,
      if (verified != null) 'verified': verified,
      if (verifiedBy != null) 'verified_by': verifiedBy,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordFieldsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? recordId,
    Value<String>? fieldKey,
    Value<String?>? valueRaw,
    Value<String?>? valueRefined,
    Value<String?>? valueFinal,
    Value<double?>? confidence,
    Value<String>? source,
    Value<bool>? verified,
    Value<String?>? verifiedBy,
    Value<DateTime?>? verifiedAt,
    Value<int>? rowid,
  }) {
    return RecordFieldsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      recordId: recordId ?? this.recordId,
      fieldKey: fieldKey ?? this.fieldKey,
      valueRaw: valueRaw ?? this.valueRaw,
      valueRefined: valueRefined ?? this.valueRefined,
      valueFinal: valueFinal ?? this.valueFinal,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      verified: verified ?? this.verified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (valueRaw.present) {
      map['value_raw'] = Variable<String>(valueRaw.value);
    }
    if (valueRefined.present) {
      map['value_refined'] = Variable<String>(valueRefined.value);
    }
    if (valueFinal.present) {
      map['value_final'] = Variable<String>(valueFinal.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (verified.present) {
      map['verified'] = Variable<bool>(verified.value);
    }
    if (verifiedBy.present) {
      map['verified_by'] = Variable<String>(verifiedBy.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordFieldsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('recordId: $recordId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('valueRaw: $valueRaw, ')
          ..write('valueRefined: $valueRefined, ')
          ..write('valueFinal: $valueFinal, ')
          ..write('confidence: $confidence, ')
          ..write('source: $source, ')
          ..write('verified: $verified, ')
          ..write('verifiedBy: $verifiedBy, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotosTable extends Photos with TableInfo<$PhotosTable, Photo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _captureSessionIdMeta = const VerificationMeta(
    'captureSessionId',
  );
  @override
  late final GeneratedColumn<String> captureSessionId = GeneratedColumn<String>(
    'capture_session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalFilenameMeta = const VerificationMeta(
    'originalFilename',
  );
  @override
  late final GeneratedColumn<String> originalFilename = GeneratedColumn<String>(
    'original_filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storedFilenameMeta = const VerificationMeta(
    'storedFilename',
  );
  @override
  late final GeneratedColumn<String> storedFilename = GeneratedColumn<String>(
    'stored_filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoTypeMeta = const VerificationMeta(
    'photoType',
  );
  @override
  late final GeneratedColumn<String> photoType = GeneratedColumn<String>(
    'photo_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gpsLatMeta = const VerificationMeta('gpsLat');
  @override
  late final GeneratedColumn<double> gpsLat = GeneratedColumn<double>(
    'gps_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsLonMeta = const VerificationMeta('gpsLon');
  @override
  late final GeneratedColumn<double> gpsLon = GeneratedColumn<double>(
    'gps_lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    projectId,
    recordId,
    captureSessionId,
    originalFilename,
    storedFilename,
    relativePath,
    photoType,
    sortOrder,
    width,
    height,
    fileSize,
    mimeType,
    sha256,
    capturedAt,
    gpsLat,
    gpsLon,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Photo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    }
    if (data.containsKey('capture_session_id')) {
      context.handle(
        _captureSessionIdMeta,
        captureSessionId.isAcceptableOrUnknown(
          data['capture_session_id']!,
          _captureSessionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_captureSessionIdMeta);
    }
    if (data.containsKey('original_filename')) {
      context.handle(
        _originalFilenameMeta,
        originalFilename.isAcceptableOrUnknown(
          data['original_filename']!,
          _originalFilenameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalFilenameMeta);
    }
    if (data.containsKey('stored_filename')) {
      context.handle(
        _storedFilenameMeta,
        storedFilename.isAcceptableOrUnknown(
          data['stored_filename']!,
          _storedFilenameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storedFilenameMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('photo_type')) {
      context.handle(
        _photoTypeMeta,
        photoType.isAcceptableOrUnknown(data['photo_type']!, _photoTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_photoTypeMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('gps_lat')) {
      context.handle(
        _gpsLatMeta,
        gpsLat.isAcceptableOrUnknown(data['gps_lat']!, _gpsLatMeta),
      );
    }
    if (data.containsKey('gps_lon')) {
      context.handle(
        _gpsLonMeta,
        gpsLon.isAcceptableOrUnknown(data['gps_lon']!, _gpsLonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {projectId, sha256},
  ];
  @override
  Photo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Photo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      ),
      captureSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capture_session_id'],
      )!,
      originalFilename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_filename'],
      )!,
      storedFilename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stored_filename'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      photoType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_type'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      gpsLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_lat'],
      ),
      gpsLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_lon'],
      ),
    );
  }

  @override
  $PhotosTable createAlias(String alias) {
    return $PhotosTable(attachedDatabase, alias);
  }
}

class Photo extends DataClass implements Insertable<Photo> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// Project this file belongs to.
  final String projectId;

  /// Record this photo is filed on, or null while it is still unfiled.
  final String? recordId;

  /// Capture session that produced the file.
  final String captureSessionId;

  /// Filename as imported or captured, stored as data.
  final String originalFilename;

  /// Filename under the project folder.
  final String storedFilename;

  /// Path relative to the project folder.
  final String relativePath;

  /// Photo type name, stored as text so this table does not import Flutter.
  final String photoType;

  /// Order within the record or session.
  final int sortOrder;

  /// Pixel width of the stored file.
  final int width;

  /// Pixel height of the stored file.
  final int height;

  /// Size of the stored file in bytes.
  final int fileSize;

  /// MIME type of the stored file.
  final String mimeType;

  /// Content hash. Merge identity for the file.
  final String sha256;

  /// When the photo was captured. Written once at insert.
  final DateTime capturedAt;

  /// GPS latitude at capture, when location recording is on.
  final double? gpsLat;

  /// GPS longitude at capture, when location recording is on.
  final double? gpsLon;
  const Photo({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.projectId,
    this.recordId,
    required this.captureSessionId,
    required this.originalFilename,
    required this.storedFilename,
    required this.relativePath,
    required this.photoType,
    required this.sortOrder,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.mimeType,
    required this.sha256,
    required this.capturedAt,
    this.gpsLat,
    this.gpsLon,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['project_id'] = Variable<String>(projectId);
    if (!nullToAbsent || recordId != null) {
      map['record_id'] = Variable<String>(recordId);
    }
    map['capture_session_id'] = Variable<String>(captureSessionId);
    map['original_filename'] = Variable<String>(originalFilename);
    map['stored_filename'] = Variable<String>(storedFilename);
    map['relative_path'] = Variable<String>(relativePath);
    map['photo_type'] = Variable<String>(photoType);
    map['sort_order'] = Variable<int>(sortOrder);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['file_size'] = Variable<int>(fileSize);
    map['mime_type'] = Variable<String>(mimeType);
    map['sha256'] = Variable<String>(sha256);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    if (!nullToAbsent || gpsLat != null) {
      map['gps_lat'] = Variable<double>(gpsLat);
    }
    if (!nullToAbsent || gpsLon != null) {
      map['gps_lon'] = Variable<double>(gpsLon);
    }
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      projectId: Value(projectId),
      recordId: recordId == null && nullToAbsent
          ? const Value.absent()
          : Value(recordId),
      captureSessionId: Value(captureSessionId),
      originalFilename: Value(originalFilename),
      storedFilename: Value(storedFilename),
      relativePath: Value(relativePath),
      photoType: Value(photoType),
      sortOrder: Value(sortOrder),
      width: Value(width),
      height: Value(height),
      fileSize: Value(fileSize),
      mimeType: Value(mimeType),
      sha256: Value(sha256),
      capturedAt: Value(capturedAt),
      gpsLat: gpsLat == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsLat),
      gpsLon: gpsLon == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsLon),
    );
  }

  factory Photo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Photo(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      projectId: serializer.fromJson<String>(json['projectId']),
      recordId: serializer.fromJson<String?>(json['recordId']),
      captureSessionId: serializer.fromJson<String>(json['captureSessionId']),
      originalFilename: serializer.fromJson<String>(json['originalFilename']),
      storedFilename: serializer.fromJson<String>(json['storedFilename']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      photoType: serializer.fromJson<String>(json['photoType']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sha256: serializer.fromJson<String>(json['sha256']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      gpsLat: serializer.fromJson<double?>(json['gpsLat']),
      gpsLon: serializer.fromJson<double?>(json['gpsLon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'projectId': serializer.toJson<String>(projectId),
      'recordId': serializer.toJson<String?>(recordId),
      'captureSessionId': serializer.toJson<String>(captureSessionId),
      'originalFilename': serializer.toJson<String>(originalFilename),
      'storedFilename': serializer.toJson<String>(storedFilename),
      'relativePath': serializer.toJson<String>(relativePath),
      'photoType': serializer.toJson<String>(photoType),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'fileSize': serializer.toJson<int>(fileSize),
      'mimeType': serializer.toJson<String>(mimeType),
      'sha256': serializer.toJson<String>(sha256),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'gpsLat': serializer.toJson<double?>(gpsLat),
      'gpsLon': serializer.toJson<double?>(gpsLon),
    };
  }

  Photo copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? projectId,
    Value<String?> recordId = const Value.absent(),
    String? captureSessionId,
    String? originalFilename,
    String? storedFilename,
    String? relativePath,
    String? photoType,
    int? sortOrder,
    int? width,
    int? height,
    int? fileSize,
    String? mimeType,
    String? sha256,
    DateTime? capturedAt,
    Value<double?> gpsLat = const Value.absent(),
    Value<double?> gpsLon = const Value.absent(),
  }) => Photo(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    projectId: projectId ?? this.projectId,
    recordId: recordId.present ? recordId.value : this.recordId,
    captureSessionId: captureSessionId ?? this.captureSessionId,
    originalFilename: originalFilename ?? this.originalFilename,
    storedFilename: storedFilename ?? this.storedFilename,
    relativePath: relativePath ?? this.relativePath,
    photoType: photoType ?? this.photoType,
    sortOrder: sortOrder ?? this.sortOrder,
    width: width ?? this.width,
    height: height ?? this.height,
    fileSize: fileSize ?? this.fileSize,
    mimeType: mimeType ?? this.mimeType,
    sha256: sha256 ?? this.sha256,
    capturedAt: capturedAt ?? this.capturedAt,
    gpsLat: gpsLat.present ? gpsLat.value : this.gpsLat,
    gpsLon: gpsLon.present ? gpsLon.value : this.gpsLon,
  );
  Photo copyWithCompanion(PhotosCompanion data) {
    return Photo(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      captureSessionId: data.captureSessionId.present
          ? data.captureSessionId.value
          : this.captureSessionId,
      originalFilename: data.originalFilename.present
          ? data.originalFilename.value
          : this.originalFilename,
      storedFilename: data.storedFilename.present
          ? data.storedFilename.value
          : this.storedFilename,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      photoType: data.photoType.present ? data.photoType.value : this.photoType,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      gpsLat: data.gpsLat.present ? data.gpsLat.value : this.gpsLat,
      gpsLon: data.gpsLon.present ? data.gpsLon.value : this.gpsLon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Photo(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('recordId: $recordId, ')
          ..write('captureSessionId: $captureSessionId, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('storedFilename: $storedFilename, ')
          ..write('relativePath: $relativePath, ')
          ..write('photoType: $photoType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fileSize: $fileSize, ')
          ..write('mimeType: $mimeType, ')
          ..write('sha256: $sha256, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('gpsLat: $gpsLat, ')
          ..write('gpsLon: $gpsLon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    projectId,
    recordId,
    captureSessionId,
    originalFilename,
    storedFilename,
    relativePath,
    photoType,
    sortOrder,
    width,
    height,
    fileSize,
    mimeType,
    sha256,
    capturedAt,
    gpsLat,
    gpsLon,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Photo &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.projectId == this.projectId &&
          other.recordId == this.recordId &&
          other.captureSessionId == this.captureSessionId &&
          other.originalFilename == this.originalFilename &&
          other.storedFilename == this.storedFilename &&
          other.relativePath == this.relativePath &&
          other.photoType == this.photoType &&
          other.sortOrder == this.sortOrder &&
          other.width == this.width &&
          other.height == this.height &&
          other.fileSize == this.fileSize &&
          other.mimeType == this.mimeType &&
          other.sha256 == this.sha256 &&
          other.capturedAt == this.capturedAt &&
          other.gpsLat == this.gpsLat &&
          other.gpsLon == this.gpsLon);
}

class PhotosCompanion extends UpdateCompanion<Photo> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> projectId;
  final Value<String?> recordId;
  final Value<String> captureSessionId;
  final Value<String> originalFilename;
  final Value<String> storedFilename;
  final Value<String> relativePath;
  final Value<String> photoType;
  final Value<int> sortOrder;
  final Value<int> width;
  final Value<int> height;
  final Value<int> fileSize;
  final Value<String> mimeType;
  final Value<String> sha256;
  final Value<DateTime> capturedAt;
  final Value<double?> gpsLat;
  final Value<double?> gpsLon;
  final Value<int> rowid;
  const PhotosCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.projectId = const Value.absent(),
    this.recordId = const Value.absent(),
    this.captureSessionId = const Value.absent(),
    this.originalFilename = const Value.absent(),
    this.storedFilename = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.photoType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.gpsLat = const Value.absent(),
    this.gpsLon = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotosCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String projectId,
    this.recordId = const Value.absent(),
    required String captureSessionId,
    required String originalFilename,
    required String storedFilename,
    required String relativePath,
    required String photoType,
    required int sortOrder,
    required int width,
    required int height,
    required int fileSize,
    required String mimeType,
    required String sha256,
    required DateTime capturedAt,
    this.gpsLat = const Value.absent(),
    this.gpsLon = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       projectId = Value(projectId),
       captureSessionId = Value(captureSessionId),
       originalFilename = Value(originalFilename),
       storedFilename = Value(storedFilename),
       relativePath = Value(relativePath),
       photoType = Value(photoType),
       sortOrder = Value(sortOrder),
       width = Value(width),
       height = Value(height),
       fileSize = Value(fileSize),
       mimeType = Value(mimeType),
       sha256 = Value(sha256),
       capturedAt = Value(capturedAt);
  static Insertable<Photo> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? projectId,
    Expression<String>? recordId,
    Expression<String>? captureSessionId,
    Expression<String>? originalFilename,
    Expression<String>? storedFilename,
    Expression<String>? relativePath,
    Expression<String>? photoType,
    Expression<int>? sortOrder,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? fileSize,
    Expression<String>? mimeType,
    Expression<String>? sha256,
    Expression<DateTime>? capturedAt,
    Expression<double>? gpsLat,
    Expression<double>? gpsLon,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (projectId != null) 'project_id': projectId,
      if (recordId != null) 'record_id': recordId,
      if (captureSessionId != null) 'capture_session_id': captureSessionId,
      if (originalFilename != null) 'original_filename': originalFilename,
      if (storedFilename != null) 'stored_filename': storedFilename,
      if (relativePath != null) 'relative_path': relativePath,
      if (photoType != null) 'photo_type': photoType,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (fileSize != null) 'file_size': fileSize,
      if (mimeType != null) 'mime_type': mimeType,
      if (sha256 != null) 'sha256': sha256,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (gpsLat != null) 'gps_lat': gpsLat,
      if (gpsLon != null) 'gps_lon': gpsLon,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotosCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? projectId,
    Value<String?>? recordId,
    Value<String>? captureSessionId,
    Value<String>? originalFilename,
    Value<String>? storedFilename,
    Value<String>? relativePath,
    Value<String>? photoType,
    Value<int>? sortOrder,
    Value<int>? width,
    Value<int>? height,
    Value<int>? fileSize,
    Value<String>? mimeType,
    Value<String>? sha256,
    Value<DateTime>? capturedAt,
    Value<double?>? gpsLat,
    Value<double?>? gpsLon,
    Value<int>? rowid,
  }) {
    return PhotosCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      projectId: projectId ?? this.projectId,
      recordId: recordId ?? this.recordId,
      captureSessionId: captureSessionId ?? this.captureSessionId,
      originalFilename: originalFilename ?? this.originalFilename,
      storedFilename: storedFilename ?? this.storedFilename,
      relativePath: relativePath ?? this.relativePath,
      photoType: photoType ?? this.photoType,
      sortOrder: sortOrder ?? this.sortOrder,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      sha256: sha256 ?? this.sha256,
      capturedAt: capturedAt ?? this.capturedAt,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLon: gpsLon ?? this.gpsLon,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (captureSessionId.present) {
      map['capture_session_id'] = Variable<String>(captureSessionId.value);
    }
    if (originalFilename.present) {
      map['original_filename'] = Variable<String>(originalFilename.value);
    }
    if (storedFilename.present) {
      map['stored_filename'] = Variable<String>(storedFilename.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (photoType.present) {
      map['photo_type'] = Variable<String>(photoType.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (gpsLat.present) {
      map['gps_lat'] = Variable<double>(gpsLat.value);
    }
    if (gpsLon.present) {
      map['gps_lon'] = Variable<double>(gpsLon.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('recordId: $recordId, ')
          ..write('captureSessionId: $captureSessionId, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('storedFilename: $storedFilename, ')
          ..write('relativePath: $relativePath, ')
          ..write('photoType: $photoType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fileSize: $fileSize, ')
          ..write('mimeType: $mimeType, ')
          ..write('sha256: $sha256, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('gpsLat: $gpsLat, ')
          ..write('gpsLon: $gpsLon, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AttachmentKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AttachmentKind>($AttachmentsTable.$converterkind);
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    projectId,
    relativePath,
    mimeType,
    fileSize,
    sha256,
    kind,
    durationMs,
    pageCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {projectId, sha256},
  ];
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      kind: $AttachmentsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      ),
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AttachmentKind, String, String> $converterkind =
      const EnumNameConverter<AttachmentKind>(AttachmentKind.values);
}

class Attachment extends DataClass implements Insertable<Attachment> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// Project this file belongs to.
  final String projectId;

  /// Path relative to the project folder.
  final String relativePath;

  /// MIME type of the stored file.
  final String mimeType;

  /// Size of the stored file in bytes.
  final int fileSize;

  /// Content hash. Merge identity for the file.
  final String sha256;

  /// Document or audio.
  final AttachmentKind kind;

  /// Duration for audio, in milliseconds.
  final int? durationMs;

  /// Page count for documents, when the format reports one.
  final int? pageCount;
  const Attachment({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.projectId,
    required this.relativePath,
    required this.mimeType,
    required this.fileSize,
    required this.sha256,
    required this.kind,
    this.durationMs,
    this.pageCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['project_id'] = Variable<String>(projectId);
    map['relative_path'] = Variable<String>(relativePath);
    map['mime_type'] = Variable<String>(mimeType);
    map['file_size'] = Variable<int>(fileSize);
    map['sha256'] = Variable<String>(sha256);
    {
      map['kind'] = Variable<String>(
        $AttachmentsTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || pageCount != null) {
      map['page_count'] = Variable<int>(pageCount);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      projectId: Value(projectId),
      relativePath: Value(relativePath),
      mimeType: Value(mimeType),
      fileSize: Value(fileSize),
      sha256: Value(sha256),
      kind: Value(kind),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      pageCount: pageCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pageCount),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      projectId: serializer.fromJson<String>(json['projectId']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      sha256: serializer.fromJson<String>(json['sha256']),
      kind: $AttachmentsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      pageCount: serializer.fromJson<int?>(json['pageCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'projectId': serializer.toJson<String>(projectId),
      'relativePath': serializer.toJson<String>(relativePath),
      'mimeType': serializer.toJson<String>(mimeType),
      'fileSize': serializer.toJson<int>(fileSize),
      'sha256': serializer.toJson<String>(sha256),
      'kind': serializer.toJson<String>(
        $AttachmentsTable.$converterkind.toJson(kind),
      ),
      'durationMs': serializer.toJson<int?>(durationMs),
      'pageCount': serializer.toJson<int?>(pageCount),
    };
  }

  Attachment copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? projectId,
    String? relativePath,
    String? mimeType,
    int? fileSize,
    String? sha256,
    AttachmentKind? kind,
    Value<int?> durationMs = const Value.absent(),
    Value<int?> pageCount = const Value.absent(),
  }) => Attachment(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    projectId: projectId ?? this.projectId,
    relativePath: relativePath ?? this.relativePath,
    mimeType: mimeType ?? this.mimeType,
    fileSize: fileSize ?? this.fileSize,
    sha256: sha256 ?? this.sha256,
    kind: kind ?? this.kind,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    pageCount: pageCount.present ? pageCount.value : this.pageCount,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      kind: data.kind.present ? data.kind.value : this.kind,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('relativePath: $relativePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('sha256: $sha256, ')
          ..write('kind: $kind, ')
          ..write('durationMs: $durationMs, ')
          ..write('pageCount: $pageCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    projectId,
    relativePath,
    mimeType,
    fileSize,
    sha256,
    kind,
    durationMs,
    pageCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.projectId == this.projectId &&
          other.relativePath == this.relativePath &&
          other.mimeType == this.mimeType &&
          other.fileSize == this.fileSize &&
          other.sha256 == this.sha256 &&
          other.kind == this.kind &&
          other.durationMs == this.durationMs &&
          other.pageCount == this.pageCount);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> projectId;
  final Value<String> relativePath;
  final Value<String> mimeType;
  final Value<int> fileSize;
  final Value<String> sha256;
  final Value<AttachmentKind> kind;
  final Value<int?> durationMs;
  final Value<int?> pageCount;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.projectId = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.kind = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String projectId,
    required String relativePath,
    required String mimeType,
    required int fileSize,
    required String sha256,
    required AttachmentKind kind,
    this.durationMs = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       projectId = Value(projectId),
       relativePath = Value(relativePath),
       mimeType = Value(mimeType),
       fileSize = Value(fileSize),
       sha256 = Value(sha256),
       kind = Value(kind);
  static Insertable<Attachment> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? projectId,
    Expression<String>? relativePath,
    Expression<String>? mimeType,
    Expression<int>? fileSize,
    Expression<String>? sha256,
    Expression<String>? kind,
    Expression<int>? durationMs,
    Expression<int>? pageCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (projectId != null) 'project_id': projectId,
      if (relativePath != null) 'relative_path': relativePath,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileSize != null) 'file_size': fileSize,
      if (sha256 != null) 'sha256': sha256,
      if (kind != null) 'kind': kind,
      if (durationMs != null) 'duration_ms': durationMs,
      if (pageCount != null) 'page_count': pageCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? projectId,
    Value<String>? relativePath,
    Value<String>? mimeType,
    Value<int>? fileSize,
    Value<String>? sha256,
    Value<AttachmentKind>? kind,
    Value<int?>? durationMs,
    Value<int?>? pageCount,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      projectId: projectId ?? this.projectId,
      relativePath: relativePath ?? this.relativePath,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      sha256: sha256 ?? this.sha256,
      kind: kind ?? this.kind,
      durationMs: durationMs ?? this.durationMs,
      pageCount: pageCount ?? this.pageCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $AttachmentsTable.$converterkind.toSql(kind.value),
      );
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('relativePath: $relativePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('sha256: $sha256, ')
          ..write('kind: $kind, ')
          ..write('durationMs: $durationMs, ')
          ..write('pageCount: $pageCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CaptionsTable extends Captions with TableInfo<$CaptionsTable, Caption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CaptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuidV7,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByDeviceMeta = const VerificationMeta(
    'updatedByDevice',
  );
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
    'updated_by_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<int> rev = GeneratedColumn<int>(
    'rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CaptionOwnerType, String>
  ownerType = GeneratedColumn<String>(
    'owner_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<CaptionOwnerType>($CaptionsTable.$converterownerType);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textRawMeta = const VerificationMeta(
    'textRaw',
  );
  @override
  late final GeneratedColumn<String> textRaw = GeneratedColumn<String>(
    'text_raw',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textRefinedMeta = const VerificationMeta(
    'textRefined',
  );
  @override
  late final GeneratedColumn<String> textRefined = GeneratedColumn<String>(
    'text_refined',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CaptionInputMode, String>
  inputMode = GeneratedColumn<String>(
    'input_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<CaptionInputMode>($CaptionsTable.$converterinputMode);
  static const VerificationMeta _refinedAtMeta = const VerificationMeta(
    'refinedAt',
  );
  @override
  late final GeneratedColumn<DateTime> refinedAt = GeneratedColumn<DateTime>(
    'refined_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    ownerType,
    ownerId,
    textRaw,
    textRefined,
    inputMode,
    refinedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'captions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Caption> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
        _updatedByDeviceMeta,
        updatedByDevice.isAcceptableOrUnknown(
          data['updated_by_device']!,
          _updatedByDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
        _revMeta,
        rev.isAcceptableOrUnknown(data['rev']!, _revMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('text_raw')) {
      context.handle(
        _textRawMeta,
        textRaw.isAcceptableOrUnknown(data['text_raw']!, _textRawMeta),
      );
    } else if (isInserting) {
      context.missing(_textRawMeta);
    }
    if (data.containsKey('text_refined')) {
      context.handle(
        _textRefinedMeta,
        textRefined.isAcceptableOrUnknown(
          data['text_refined']!,
          _textRefinedMeta,
        ),
      );
    }
    if (data.containsKey('refined_at')) {
      context.handle(
        _refinedAtMeta,
        refinedAt.isAcceptableOrUnknown(data['refined_at']!, _refinedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Caption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Caption(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device'],
      )!,
      rev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rev'],
      )!,
      ownerType: $CaptionsTable.$converterownerType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}owner_type'],
        )!,
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      textRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_raw'],
      )!,
      textRefined: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_refined'],
      ),
      inputMode: $CaptionsTable.$converterinputMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}input_mode'],
        )!,
      ),
      refinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}refined_at'],
      ),
    );
  }

  @override
  $CaptionsTable createAlias(String alias) {
    return $CaptionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CaptionOwnerType, String, String>
  $converterownerType = const EnumNameConverter<CaptionOwnerType>(
    CaptionOwnerType.values,
  );
  static JsonTypeConverter2<CaptionInputMode, String, String>
  $converterinputMode = const EnumNameConverter<CaptionInputMode>(
    CaptionInputMode.values,
  );
}

class Caption extends DataClass implements Insertable<Caption> {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  final String id;

  /// When the row was first written. Later updates leave this alone.
  final DateTime createdAt;

  /// When the row last changed. The write helper advances this.
  final DateTime updatedAt;

  /// Device that last wrote the row.
  final String updatedByDevice;

  /// Monotonic write counter. The write helper adds one on every update.
  final int rev;

  /// Record or photo.
  final CaptionOwnerType ownerType;

  /// Merge id of the record or photo this caption describes.
  final String ownerId;

  /// Original caption as entered. Written once at insert, never updated.
  final String textRaw;

  /// Refined caption written beside the original, never over it.
  final String? textRefined;

  /// Typed or spoken.
  final CaptionInputMode inputMode;

  /// When a refined value was written, if one has been.
  final DateTime? refinedAt;
  const Caption({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.ownerType,
    required this.ownerId,
    required this.textRaw,
    this.textRefined,
    required this.inputMode,
    this.refinedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    {
      map['owner_type'] = Variable<String>(
        $CaptionsTable.$converterownerType.toSql(ownerType),
      );
    }
    map['owner_id'] = Variable<String>(ownerId);
    map['text_raw'] = Variable<String>(textRaw);
    if (!nullToAbsent || textRefined != null) {
      map['text_refined'] = Variable<String>(textRefined);
    }
    {
      map['input_mode'] = Variable<String>(
        $CaptionsTable.$converterinputMode.toSql(inputMode),
      );
    }
    if (!nullToAbsent || refinedAt != null) {
      map['refined_at'] = Variable<DateTime>(refinedAt);
    }
    return map;
  }

  CaptionsCompanion toCompanion(bool nullToAbsent) {
    return CaptionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      ownerType: Value(ownerType),
      ownerId: Value(ownerId),
      textRaw: Value(textRaw),
      textRefined: textRefined == null && nullToAbsent
          ? const Value.absent()
          : Value(textRefined),
      inputMode: Value(inputMode),
      refinedAt: refinedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(refinedAt),
    );
  }

  factory Caption.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Caption(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      ownerType: $CaptionsTable.$converterownerType.fromJson(
        serializer.fromJson<String>(json['ownerType']),
      ),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      textRaw: serializer.fromJson<String>(json['textRaw']),
      textRefined: serializer.fromJson<String?>(json['textRefined']),
      inputMode: $CaptionsTable.$converterinputMode.fromJson(
        serializer.fromJson<String>(json['inputMode']),
      ),
      refinedAt: serializer.fromJson<DateTime?>(json['refinedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'rev': serializer.toJson<int>(rev),
      'ownerType': serializer.toJson<String>(
        $CaptionsTable.$converterownerType.toJson(ownerType),
      ),
      'ownerId': serializer.toJson<String>(ownerId),
      'textRaw': serializer.toJson<String>(textRaw),
      'textRefined': serializer.toJson<String?>(textRefined),
      'inputMode': serializer.toJson<String>(
        $CaptionsTable.$converterinputMode.toJson(inputMode),
      ),
      'refinedAt': serializer.toJson<DateTime?>(refinedAt),
    };
  }

  Caption copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    CaptionOwnerType? ownerType,
    String? ownerId,
    String? textRaw,
    Value<String?> textRefined = const Value.absent(),
    CaptionInputMode? inputMode,
    Value<DateTime?> refinedAt = const Value.absent(),
  }) => Caption(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    ownerType: ownerType ?? this.ownerType,
    ownerId: ownerId ?? this.ownerId,
    textRaw: textRaw ?? this.textRaw,
    textRefined: textRefined.present ? textRefined.value : this.textRefined,
    inputMode: inputMode ?? this.inputMode,
    refinedAt: refinedAt.present ? refinedAt.value : this.refinedAt,
  );
  Caption copyWithCompanion(CaptionsCompanion data) {
    return Caption(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      ownerType: data.ownerType.present ? data.ownerType.value : this.ownerType,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      textRaw: data.textRaw.present ? data.textRaw.value : this.textRaw,
      textRefined: data.textRefined.present
          ? data.textRefined.value
          : this.textRefined,
      inputMode: data.inputMode.present ? data.inputMode.value : this.inputMode,
      refinedAt: data.refinedAt.present ? data.refinedAt.value : this.refinedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Caption(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('textRaw: $textRaw, ')
          ..write('textRefined: $textRefined, ')
          ..write('inputMode: $inputMode, ')
          ..write('refinedAt: $refinedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    ownerType,
    ownerId,
    textRaw,
    textRefined,
    inputMode,
    refinedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Caption &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.ownerType == this.ownerType &&
          other.ownerId == this.ownerId &&
          other.textRaw == this.textRaw &&
          other.textRefined == this.textRefined &&
          other.inputMode == this.inputMode &&
          other.refinedAt == this.refinedAt);
}

class CaptionsCompanion extends UpdateCompanion<Caption> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<CaptionOwnerType> ownerType;
  final Value<String> ownerId;
  final Value<String> textRaw;
  final Value<String?> textRefined;
  final Value<CaptionInputMode> inputMode;
  final Value<DateTime?> refinedAt;
  final Value<int> rowid;
  const CaptionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.ownerType = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.textRaw = const Value.absent(),
    this.textRefined = const Value.absent(),
    this.inputMode = const Value.absent(),
    this.refinedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CaptionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required CaptionOwnerType ownerType,
    required String ownerId,
    required String textRaw,
    this.textRefined = const Value.absent(),
    required CaptionInputMode inputMode,
    this.refinedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       ownerType = Value(ownerType),
       ownerId = Value(ownerId),
       textRaw = Value(textRaw),
       inputMode = Value(inputMode);
  static Insertable<Caption> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? ownerType,
    Expression<String>? ownerId,
    Expression<String>? textRaw,
    Expression<String>? textRefined,
    Expression<String>? inputMode,
    Expression<DateTime>? refinedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (ownerType != null) 'owner_type': ownerType,
      if (ownerId != null) 'owner_id': ownerId,
      if (textRaw != null) 'text_raw': textRaw,
      if (textRefined != null) 'text_refined': textRefined,
      if (inputMode != null) 'input_mode': inputMode,
      if (refinedAt != null) 'refined_at': refinedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CaptionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<CaptionOwnerType>? ownerType,
    Value<String>? ownerId,
    Value<String>? textRaw,
    Value<String?>? textRefined,
    Value<CaptionInputMode>? inputMode,
    Value<DateTime?>? refinedAt,
    Value<int>? rowid,
  }) {
    return CaptionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId ?? this.ownerId,
      textRaw: textRaw ?? this.textRaw,
      textRefined: textRefined ?? this.textRefined,
      inputMode: inputMode ?? this.inputMode,
      refinedAt: refinedAt ?? this.refinedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (rev.present) {
      map['rev'] = Variable<int>(rev.value);
    }
    if (ownerType.present) {
      map['owner_type'] = Variable<String>(
        $CaptionsTable.$converterownerType.toSql(ownerType.value),
      );
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (textRaw.present) {
      map['text_raw'] = Variable<String>(textRaw.value);
    }
    if (textRefined.present) {
      map['text_refined'] = Variable<String>(textRefined.value);
    }
    if (inputMode.present) {
      map['input_mode'] = Variable<String>(
        $CaptionsTable.$converterinputMode.toSql(inputMode.value),
      );
    }
    if (refinedAt.present) {
      map['refined_at'] = Variable<DateTime>(refinedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaptionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('textRaw: $textRaw, ')
          ..write('textRefined: $textRefined, ')
          ..write('inputMode: $inputMode, ')
          ..write('refinedAt: $refinedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $TombstonesTable tombstones = $TombstonesTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $DeviceProfileTable deviceProfile = $DeviceProfileTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $ContextTable context = $ContextTable(this);
  late final $ContextStateTable contextState = $ContextStateTable(this);
  late final $ContextPresetsTable contextPresets = $ContextPresetsTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $TemplateFieldsTable templateFields = $TemplateFieldsTable(this);
  late final $TemplateRowsTable templateRows = $TemplateRowsTable(this);
  late final $RecordsTable records = $RecordsTable(this);
  late final $RecordFieldsTable recordFields = $RecordFieldsTable(this);
  late final $PhotosTable photos = $PhotosTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $CaptionsTable captions = $CaptionsTable(this);
  late final Index auditLogHistory = Index(
    'audit_log_history',
    'CREATE INDEX audit_log_history ON audit_log (entity_type, entity_id, at)',
  );
  late final Index projectsByStatus = Index(
    'projects_by_status',
    'CREATE INDEX projects_by_status ON projects (status, updated_at)',
  );
  late final Index templateRowsByIdentifier = Index(
    'template_rows_by_identifier',
    'CREATE INDEX template_rows_by_identifier ON template_rows (template_id, identifier)',
  );
  late final Index recordsByProjectStatus = Index(
    'records_by_project_status',
    'CREATE INDEX records_by_project_status ON records (project_id, status)',
  );
  late final Index recordsByIdentityHash = Index(
    'records_by_identity_hash',
    'CREATE INDEX records_by_identity_hash ON records (identity_hash)',
  );
  late final Index recordsByCapturedAt = Index(
    'records_by_captured_at',
    'CREATE INDEX records_by_captured_at ON records (captured_at)',
  );
  late final Index recordsByTemplate = Index(
    'records_by_template',
    'CREATE INDEX records_by_template ON records (template_id)',
  );
  late final Index recordFieldsByFinal = Index(
    'record_fields_by_final',
    'CREATE INDEX record_fields_by_final ON record_fields (field_key, value_final)',
  );
  late final Index captionsByOwner = Index(
    'captions_by_owner',
    'CREATE INDEX captions_by_owner ON captions (owner_type, owner_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tombstones,
    auditLog,
    deviceProfile,
    projects,
    context,
    contextState,
    contextPresets,
    templates,
    templateFields,
    templateRows,
    records,
    recordFields,
    photos,
    attachments,
    captions,
    auditLogHistory,
    projectsByStatus,
    templateRowsByIdentifier,
    recordsByProjectStatus,
    recordsByIdentityHash,
    recordsByCapturedAt,
    recordsByTemplate,
    recordFieldsByFinal,
    captionsByOwner,
  ];
}
