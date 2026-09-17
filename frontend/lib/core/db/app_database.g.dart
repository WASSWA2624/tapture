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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $TombstonesTable tombstones = $TombstonesTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $DeviceProfileTable deviceProfile = $DeviceProfileTable(this);
  late final Index auditLogHistory = Index(
    'audit_log_history',
    'CREATE INDEX audit_log_history ON audit_log (entity_type, entity_id, at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tombstones,
    auditLog,
    deviceProfile,
    auditLogHistory,
  ];
}
