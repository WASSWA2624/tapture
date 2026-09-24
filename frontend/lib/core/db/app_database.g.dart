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
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
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
    deviceId,
    operatorName,
    preferences,
    accountId,
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
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
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
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
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

  /// Backend account id, filled by enrolment. Null on every pre-backend install.
  final String? accountId;
  const DeviceProfileRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.deviceId,
    required this.operatorName,
    required this.preferences,
    this.accountId,
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
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
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
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
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
      accountId: serializer.fromJson<String?>(json['accountId']),
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
      'accountId': serializer.toJson<String?>(accountId),
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
    Value<String?> accountId = const Value.absent(),
  }) => DeviceProfileRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    deviceId: deviceId ?? this.deviceId,
    operatorName: operatorName ?? this.operatorName,
    preferences: preferences ?? this.preferences,
    accountId: accountId.present ? accountId.value : this.accountId,
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
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
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
          ..write('preferences: $preferences, ')
          ..write('accountId: $accountId')
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
    accountId,
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
          other.preferences == this.preferences &&
          other.accountId == this.accountId);
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
  final Value<String?> accountId;
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
    this.accountId = const Value.absent(),
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
    this.accountId = const Value.absent(),
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
    Expression<String>? accountId,
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
      if (accountId != null) 'account_id': accountId,
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
    Value<String?>? accountId,
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
      accountId: accountId ?? this.accountId,
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
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
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
          ..write('accountId: $accountId, ')
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
  static const VerificationMeta _pinnedAtMeta = const VerificationMeta(
    'pinnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pinnedAt = GeneratedColumn<DateTime>(
    'pinned_at',
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
    name,
    client,
    status,
    startedAt,
    completedAt,
    folderName,
    settings,
    pinnedAt,
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
    if (data.containsKey('pinned_at')) {
      context.handle(
        _pinnedAtMeta,
        pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta),
      );
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
      pinnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pinned_at'],
      ),
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

  /// When this project was pinned. Null means unpinned. A pin is not work,
  /// so writes to this column must not stamp [updatedAt] or [rev].
  final DateTime? pinnedAt;
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
    this.pinnedAt,
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
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt);
    }
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
      pinnedAt: pinnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedAt),
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
      pinnedAt: serializer.fromJson<DateTime?>(json['pinnedAt']),
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
      'pinnedAt': serializer.toJson<DateTime?>(pinnedAt),
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
    Value<DateTime?> pinnedAt = const Value.absent(),
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
    pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
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
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
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
          ..write('settings: $settings, ')
          ..write('pinnedAt: $pinnedAt')
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
    pinnedAt,
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
          other.settings == this.settings &&
          other.pinnedAt == this.pinnedAt);
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
  final Value<DateTime?> pinnedAt;
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
    this.pinnedAt = const Value.absent(),
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
    this.pinnedAt = const Value.absent(),
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
    Expression<DateTime>? pinnedAt,
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
      if (pinnedAt != null) 'pinned_at': pinnedAt,
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
    Value<DateTime?>? pinnedAt,
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
      pinnedAt: pinnedAt ?? this.pinnedAt,
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
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt.value);
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
          ..write('pinnedAt: $pinnedAt, ')
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
  static const VerificationMeta _rowMatchStrategyMeta = const VerificationMeta(
    'rowMatchStrategy',
  );
  @override
  late final GeneratedColumn<String> rowMatchStrategy = GeneratedColumn<String>(
    'row_match_strategy',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rowMatchScoreMeta = const VerificationMeta(
    'rowMatchScore',
  );
  @override
  late final GeneratedColumn<double> rowMatchScore = GeneratedColumn<double>(
    'row_match_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
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
    rowMatchStrategy,
    rowMatchScore,
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
    if (data.containsKey('row_match_strategy')) {
      context.handle(
        _rowMatchStrategyMeta,
        rowMatchStrategy.isAcceptableOrUnknown(
          data['row_match_strategy']!,
          _rowMatchStrategyMeta,
        ),
      );
    }
    if (data.containsKey('row_match_score')) {
      context.handle(
        _rowMatchScoreMeta,
        rowMatchScore.isAcceptableOrUnknown(
          data['row_match_score']!,
          _rowMatchScoreMeta,
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
      rowMatchStrategy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_match_strategy'],
      ),
      rowMatchScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}row_match_score'],
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

  /// How processing resolved [templateRowId], when it proposed one.
  final String? rowMatchStrategy;

  /// Confidence reported by the row matching strategy.
  final double? rowMatchScore;

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
    this.rowMatchStrategy,
    this.rowMatchScore,
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
    if (!nullToAbsent || rowMatchStrategy != null) {
      map['row_match_strategy'] = Variable<String>(rowMatchStrategy);
    }
    if (!nullToAbsent || rowMatchScore != null) {
      map['row_match_score'] = Variable<double>(rowMatchScore);
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
      rowMatchStrategy: rowMatchStrategy == null && nullToAbsent
          ? const Value.absent()
          : Value(rowMatchStrategy),
      rowMatchScore: rowMatchScore == null && nullToAbsent
          ? const Value.absent()
          : Value(rowMatchScore),
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
      rowMatchStrategy: serializer.fromJson<String?>(json['rowMatchStrategy']),
      rowMatchScore: serializer.fromJson<double?>(json['rowMatchScore']),
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
      'rowMatchStrategy': serializer.toJson<String?>(rowMatchStrategy),
      'rowMatchScore': serializer.toJson<double?>(rowMatchScore),
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
    Value<String?> rowMatchStrategy = const Value.absent(),
    Value<double?> rowMatchScore = const Value.absent(),
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
    rowMatchStrategy: rowMatchStrategy.present
        ? rowMatchStrategy.value
        : this.rowMatchStrategy,
    rowMatchScore: rowMatchScore.present
        ? rowMatchScore.value
        : this.rowMatchScore,
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
      rowMatchStrategy: data.rowMatchStrategy.present
          ? data.rowMatchStrategy.value
          : this.rowMatchStrategy,
      rowMatchScore: data.rowMatchScore.present
          ? data.rowMatchScore.value
          : this.rowMatchScore,
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
          ..write('rowMatchStrategy: $rowMatchStrategy, ')
          ..write('rowMatchScore: $rowMatchScore, ')
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
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    projectId,
    templateId,
    templateRowId,
    rowMatchStrategy,
    rowMatchScore,
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
  ]);
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
          other.rowMatchStrategy == this.rowMatchStrategy &&
          other.rowMatchScore == this.rowMatchScore &&
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
  final Value<String?> rowMatchStrategy;
  final Value<double?> rowMatchScore;
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
    this.rowMatchStrategy = const Value.absent(),
    this.rowMatchScore = const Value.absent(),
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
    this.rowMatchStrategy = const Value.absent(),
    this.rowMatchScore = const Value.absent(),
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
    Expression<String>? rowMatchStrategy,
    Expression<double>? rowMatchScore,
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
      if (rowMatchStrategy != null) 'row_match_strategy': rowMatchStrategy,
      if (rowMatchScore != null) 'row_match_score': rowMatchScore,
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
    Value<String?>? rowMatchStrategy,
    Value<double?>? rowMatchScore,
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
      rowMatchStrategy: rowMatchStrategy ?? this.rowMatchStrategy,
      rowMatchScore: rowMatchScore ?? this.rowMatchScore,
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
    if (rowMatchStrategy.present) {
      map['row_match_strategy'] = Variable<String>(rowMatchStrategy.value);
    }
    if (rowMatchScore.present) {
      map['row_match_score'] = Variable<double>(rowMatchScore.value);
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
          ..write('rowMatchStrategy: $rowMatchStrategy, ')
          ..write('rowMatchScore: $rowMatchScore, ')
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
  static const VerificationMeta _confidenceBandMeta = const VerificationMeta(
    'confidenceBand',
  );
  @override
  late final GeneratedColumn<String> confidenceBand = GeneratedColumn<String>(
    'confidence_band',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promptVersionMeta = const VerificationMeta(
    'promptVersion',
  );
  @override
  late final GeneratedColumn<String> promptVersion = GeneratedColumn<String>(
    'prompt_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    confidenceBand,
    source,
    method,
    provider,
    model,
    promptVersion,
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
    if (data.containsKey('confidence_band')) {
      context.handle(
        _confidenceBandMeta,
        confidenceBand.isAcceptableOrUnknown(
          data['confidence_band']!,
          _confidenceBandMeta,
        ),
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
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('prompt_version')) {
      context.handle(
        _promptVersionMeta,
        promptVersion.isAcceptableOrUnknown(
          data['prompt_version']!,
          _promptVersionMeta,
        ),
      );
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
      confidenceBand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence_band'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      ),
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      promptVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_version'],
      ),
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

  /// Shared confidence band at the time this proposal was written.
  final String? confidenceBand;

  /// Where this value came from (typed, lookup, extraction).
  final String source;

  /// Extraction method, such as local OCR or provider extraction.
  final String? method;

  /// Provider id when an online service proposed the value.
  final String? provider;

  /// Provider model when one was involved.
  final String? model;

  /// Prompt or local-rule version that produced the proposal.
  final String? promptVersion;

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
    this.confidenceBand,
    required this.source,
    this.method,
    this.provider,
    this.model,
    this.promptVersion,
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
    if (!nullToAbsent || confidenceBand != null) {
      map['confidence_band'] = Variable<String>(confidenceBand);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || method != null) {
      map['method'] = Variable<String>(method);
    }
    if (!nullToAbsent || provider != null) {
      map['provider'] = Variable<String>(provider);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || promptVersion != null) {
      map['prompt_version'] = Variable<String>(promptVersion);
    }
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
      confidenceBand: confidenceBand == null && nullToAbsent
          ? const Value.absent()
          : Value(confidenceBand),
      source: Value(source),
      method: method == null && nullToAbsent
          ? const Value.absent()
          : Value(method),
      provider: provider == null && nullToAbsent
          ? const Value.absent()
          : Value(provider),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      promptVersion: promptVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(promptVersion),
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
      confidenceBand: serializer.fromJson<String?>(json['confidenceBand']),
      source: serializer.fromJson<String>(json['source']),
      method: serializer.fromJson<String?>(json['method']),
      provider: serializer.fromJson<String?>(json['provider']),
      model: serializer.fromJson<String?>(json['model']),
      promptVersion: serializer.fromJson<String?>(json['promptVersion']),
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
      'confidenceBand': serializer.toJson<String?>(confidenceBand),
      'source': serializer.toJson<String>(source),
      'method': serializer.toJson<String?>(method),
      'provider': serializer.toJson<String?>(provider),
      'model': serializer.toJson<String?>(model),
      'promptVersion': serializer.toJson<String?>(promptVersion),
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
    Value<String?> confidenceBand = const Value.absent(),
    String? source,
    Value<String?> method = const Value.absent(),
    Value<String?> provider = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<String?> promptVersion = const Value.absent(),
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
    confidenceBand: confidenceBand.present
        ? confidenceBand.value
        : this.confidenceBand,
    source: source ?? this.source,
    method: method.present ? method.value : this.method,
    provider: provider.present ? provider.value : this.provider,
    model: model.present ? model.value : this.model,
    promptVersion: promptVersion.present
        ? promptVersion.value
        : this.promptVersion,
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
      confidenceBand: data.confidenceBand.present
          ? data.confidenceBand.value
          : this.confidenceBand,
      source: data.source.present ? data.source.value : this.source,
      method: data.method.present ? data.method.value : this.method,
      provider: data.provider.present ? data.provider.value : this.provider,
      model: data.model.present ? data.model.value : this.model,
      promptVersion: data.promptVersion.present
          ? data.promptVersion.value
          : this.promptVersion,
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
          ..write('confidenceBand: $confidenceBand, ')
          ..write('source: $source, ')
          ..write('method: $method, ')
          ..write('provider: $provider, ')
          ..write('model: $model, ')
          ..write('promptVersion: $promptVersion, ')
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
    confidenceBand,
    source,
    method,
    provider,
    model,
    promptVersion,
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
          other.confidenceBand == this.confidenceBand &&
          other.source == this.source &&
          other.method == this.method &&
          other.provider == this.provider &&
          other.model == this.model &&
          other.promptVersion == this.promptVersion &&
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
  final Value<String?> confidenceBand;
  final Value<String> source;
  final Value<String?> method;
  final Value<String?> provider;
  final Value<String?> model;
  final Value<String?> promptVersion;
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
    this.confidenceBand = const Value.absent(),
    this.source = const Value.absent(),
    this.method = const Value.absent(),
    this.provider = const Value.absent(),
    this.model = const Value.absent(),
    this.promptVersion = const Value.absent(),
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
    this.confidenceBand = const Value.absent(),
    required String source,
    this.method = const Value.absent(),
    this.provider = const Value.absent(),
    this.model = const Value.absent(),
    this.promptVersion = const Value.absent(),
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
    Expression<String>? confidenceBand,
    Expression<String>? source,
    Expression<String>? method,
    Expression<String>? provider,
    Expression<String>? model,
    Expression<String>? promptVersion,
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
      if (confidenceBand != null) 'confidence_band': confidenceBand,
      if (source != null) 'source': source,
      if (method != null) 'method': method,
      if (provider != null) 'provider': provider,
      if (model != null) 'model': model,
      if (promptVersion != null) 'prompt_version': promptVersion,
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
    Value<String?>? confidenceBand,
    Value<String>? source,
    Value<String?>? method,
    Value<String?>? provider,
    Value<String?>? model,
    Value<String?>? promptVersion,
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
      confidenceBand: confidenceBand ?? this.confidenceBand,
      source: source ?? this.source,
      method: method ?? this.method,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      promptVersion: promptVersion ?? this.promptVersion,
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
    if (confidenceBand.present) {
      map['confidence_band'] = Variable<String>(confidenceBand.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (promptVersion.present) {
      map['prompt_version'] = Variable<String>(promptVersion.value);
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
          ..write('confidenceBand: $confidenceBand, ')
          ..write('source: $source, ')
          ..write('method: $method, ')
          ..write('provider: $provider, ')
          ..write('model: $model, ')
          ..write('promptVersion: $promptVersion, ')
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
  static const VerificationMeta _derivedFromMeta = const VerificationMeta(
    'derivedFrom',
  );
  @override
  late final GeneratedColumn<String> derivedFrom = GeneratedColumn<String>(
    'derived_from',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rotationDegreesMeta = const VerificationMeta(
    'rotationDegrees',
  );
  @override
  late final GeneratedColumn<int> rotationDegrees = GeneratedColumn<int>(
    'rotation_degrees',
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
    derivedFrom,
    rotationDegrees,
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
    if (data.containsKey('derived_from')) {
      context.handle(
        _derivedFromMeta,
        derivedFrom.isAcceptableOrUnknown(
          data['derived_from']!,
          _derivedFromMeta,
        ),
      );
    }
    if (data.containsKey('rotation_degrees')) {
      context.handle(
        _rotationDegreesMeta,
        rotationDegrees.isAcceptableOrUnknown(
          data['rotation_degrees']!,
          _rotationDegreesMeta,
        ),
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
      derivedFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}derived_from'],
      ),
      rotationDegrees: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rotation_degrees'],
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

  /// Parent photo when this row is an edit. Null marks an original.
  final String? derivedFrom;

  /// Display rotation in degrees. Null is the original orientation.
  final int? rotationDegrees;
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
    this.derivedFrom,
    this.rotationDegrees,
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
    if (!nullToAbsent || derivedFrom != null) {
      map['derived_from'] = Variable<String>(derivedFrom);
    }
    if (!nullToAbsent || rotationDegrees != null) {
      map['rotation_degrees'] = Variable<int>(rotationDegrees);
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
      derivedFrom: derivedFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(derivedFrom),
      rotationDegrees: rotationDegrees == null && nullToAbsent
          ? const Value.absent()
          : Value(rotationDegrees),
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
      derivedFrom: serializer.fromJson<String?>(json['derivedFrom']),
      rotationDegrees: serializer.fromJson<int?>(json['rotationDegrees']),
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
      'derivedFrom': serializer.toJson<String?>(derivedFrom),
      'rotationDegrees': serializer.toJson<int?>(rotationDegrees),
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
    Value<String?> derivedFrom = const Value.absent(),
    Value<int?> rotationDegrees = const Value.absent(),
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
    derivedFrom: derivedFrom.present ? derivedFrom.value : this.derivedFrom,
    rotationDegrees: rotationDegrees.present
        ? rotationDegrees.value
        : this.rotationDegrees,
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
      derivedFrom: data.derivedFrom.present
          ? data.derivedFrom.value
          : this.derivedFrom,
      rotationDegrees: data.rotationDegrees.present
          ? data.rotationDegrees.value
          : this.rotationDegrees,
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
          ..write('gpsLon: $gpsLon, ')
          ..write('derivedFrom: $derivedFrom, ')
          ..write('rotationDegrees: $rotationDegrees')
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
    derivedFrom,
    rotationDegrees,
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
          other.gpsLon == this.gpsLon &&
          other.derivedFrom == this.derivedFrom &&
          other.rotationDegrees == this.rotationDegrees);
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
  final Value<String?> derivedFrom;
  final Value<int?> rotationDegrees;
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
    this.derivedFrom = const Value.absent(),
    this.rotationDegrees = const Value.absent(),
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
    this.derivedFrom = const Value.absent(),
    this.rotationDegrees = const Value.absent(),
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
    Expression<String>? derivedFrom,
    Expression<int>? rotationDegrees,
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
      if (derivedFrom != null) 'derived_from': derivedFrom,
      if (rotationDegrees != null) 'rotation_degrees': rotationDegrees,
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
    Value<String?>? derivedFrom,
    Value<int?>? rotationDegrees,
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
      derivedFrom: derivedFrom ?? this.derivedFrom,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
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
    if (derivedFrom.present) {
      map['derived_from'] = Variable<String>(derivedFrom.value);
    }
    if (rotationDegrees.present) {
      map['rotation_degrees'] = Variable<int>(rotationDegrees.value);
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
          ..write('derivedFrom: $derivedFrom, ')
          ..write('rotationDegrees: $rotationDegrees, ')
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

class $AttachmentOwnersTable extends AttachmentOwners
    with TableInfo<$AttachmentOwnersTable, AttachmentOwner> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentOwnersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  @override
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
    'attachment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AttachmentOwnerType, String>
  ownerType =
      GeneratedColumn<String>(
        'owner_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AttachmentOwnerType>(
        $AttachmentOwnersTable.$converterownerType,
      );
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
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    attachmentId,
    ownerType,
    ownerId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachment_owners';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentOwner> instance, {
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
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {attachmentId, ownerType, ownerId},
  ];
  @override
  AttachmentOwner map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentOwner(
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
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_id'],
      )!,
      ownerType: $AttachmentOwnersTable.$converterownerType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}owner_type'],
        )!,
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AttachmentOwnersTable createAlias(String alias) {
    return $AttachmentOwnersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AttachmentOwnerType, String, String>
  $converterownerType = const EnumNameConverter<AttachmentOwnerType>(
    AttachmentOwnerType.values,
  );
}

class AttachmentOwner extends DataClass implements Insertable<AttachmentOwner> {
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

  /// Attachment being linked.
  final String attachmentId;

  /// `record` or `photo`.
  final AttachmentOwnerType ownerType;

  /// Record or photo id, according to [ownerType].
  final String ownerId;

  /// Stable order within one owner.
  final int sortOrder;
  const AttachmentOwner({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.attachmentId,
    required this.ownerType,
    required this.ownerId,
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
    map['attachment_id'] = Variable<String>(attachmentId);
    {
      map['owner_type'] = Variable<String>(
        $AttachmentOwnersTable.$converterownerType.toSql(ownerType),
      );
    }
    map['owner_id'] = Variable<String>(ownerId);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AttachmentOwnersCompanion toCompanion(bool nullToAbsent) {
    return AttachmentOwnersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      attachmentId: Value(attachmentId),
      ownerType: Value(ownerType),
      ownerId: Value(ownerId),
      sortOrder: Value(sortOrder),
    );
  }

  factory AttachmentOwner.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentOwner(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      attachmentId: serializer.fromJson<String>(json['attachmentId']),
      ownerType: $AttachmentOwnersTable.$converterownerType.fromJson(
        serializer.fromJson<String>(json['ownerType']),
      ),
      ownerId: serializer.fromJson<String>(json['ownerId']),
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
      'attachmentId': serializer.toJson<String>(attachmentId),
      'ownerType': serializer.toJson<String>(
        $AttachmentOwnersTable.$converterownerType.toJson(ownerType),
      ),
      'ownerId': serializer.toJson<String>(ownerId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AttachmentOwner copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? attachmentId,
    AttachmentOwnerType? ownerType,
    String? ownerId,
    int? sortOrder,
  }) => AttachmentOwner(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    attachmentId: attachmentId ?? this.attachmentId,
    ownerType: ownerType ?? this.ownerType,
    ownerId: ownerId ?? this.ownerId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AttachmentOwner copyWithCompanion(AttachmentOwnersCompanion data) {
    return AttachmentOwner(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      ownerType: data.ownerType.present ? data.ownerType.value : this.ownerType,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentOwner(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('sortOrder: $sortOrder')
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
    attachmentId,
    ownerType,
    ownerId,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentOwner &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.attachmentId == this.attachmentId &&
          other.ownerType == this.ownerType &&
          other.ownerId == this.ownerId &&
          other.sortOrder == this.sortOrder);
}

class AttachmentOwnersCompanion extends UpdateCompanion<AttachmentOwner> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> attachmentId;
  final Value<AttachmentOwnerType> ownerType;
  final Value<String> ownerId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AttachmentOwnersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.attachmentId = const Value.absent(),
    this.ownerType = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentOwnersCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String attachmentId,
    required AttachmentOwnerType ownerType,
    required String ownerId,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       attachmentId = Value(attachmentId),
       ownerType = Value(ownerType),
       ownerId = Value(ownerId);
  static Insertable<AttachmentOwner> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? attachmentId,
    Expression<String>? ownerType,
    Expression<String>? ownerId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (ownerType != null) 'owner_type': ownerType,
      if (ownerId != null) 'owner_id': ownerId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentOwnersCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? attachmentId,
    Value<AttachmentOwnerType>? ownerType,
    Value<String>? ownerId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return AttachmentOwnersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      attachmentId: attachmentId ?? this.attachmentId,
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId ?? this.ownerId,
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
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (ownerType.present) {
      map['owner_type'] = Variable<String>(
        $AttachmentOwnersTable.$converterownerType.toSql(ownerType.value),
      );
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
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
    return (StringBuffer('AttachmentOwnersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('sortOrder: $sortOrder, ')
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

class $CaptureSessionsTable extends CaptureSessions
    with TableInfo<$CaptureSessionsTable, CaptureSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CaptureSessionsTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
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
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'capture_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaptureSession> instance, {
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
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CaptureSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaptureSession(
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
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  $CaptureSessionsTable createAlias(String alias) {
    return $CaptureSessionsTable(attachedDatabase, alias);
  }
}

class CaptureSession extends DataClass implements Insertable<CaptureSession> {
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

  /// Project whose unfinished capture this row restores.
  final String projectId;

  /// Serialised capture session object.
  final String payloadJson;
  const CaptureSession({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.projectId,
    required this.payloadJson,
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
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  CaptureSessionsCompanion toCompanion(bool nullToAbsent) {
    return CaptureSessionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      projectId: Value(projectId),
      payloadJson: Value(payloadJson),
    );
  }

  factory CaptureSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaptureSession(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      projectId: serializer.fromJson<String>(json['projectId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
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
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  CaptureSession copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? projectId,
    String? payloadJson,
  }) => CaptureSession(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    projectId: projectId ?? this.projectId,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  CaptureSession copyWithCompanion(CaptureSessionsCompanion data) {
    return CaptureSession(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaptureSession(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('payloadJson: $payloadJson')
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
    payloadJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaptureSession &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.projectId == this.projectId &&
          other.payloadJson == this.payloadJson);
}

class CaptureSessionsCompanion extends UpdateCompanion<CaptureSession> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> projectId;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const CaptureSessionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.projectId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CaptureSessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String projectId,
    required String payloadJson,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       projectId = Value(projectId),
       payloadJson = Value(payloadJson);
  static Insertable<CaptureSession> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? projectId,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (projectId != null) 'project_id': projectId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CaptureSessionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? projectId,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return CaptureSessionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      projectId: projectId ?? this.projectId,
      payloadJson: payloadJson ?? this.payloadJson,
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
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaptureSessionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReferenceTable extends Reference
    with TableInfo<$ReferenceTable, ReferenceDatasetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReferenceTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<ReferenceScope, String> scope =
      GeneratedColumn<String>(
        'scope',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReferenceScope>($ReferenceTable.$converterscope);
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
  static const VerificationMeta _keyColumnMeta = const VerificationMeta(
    'keyColumn',
  );
  @override
  late final GeneratedColumn<String> keyColumn = GeneratedColumn<String>(
    'key_column',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _columnsMeta = const VerificationMeta(
    'columns',
  );
  @override
  late final GeneratedColumn<String> columns = GeneratedColumn<String>(
    'columns',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceFileMeta = const VerificationMeta(
    'sourceFile',
  );
  @override
  late final GeneratedColumn<String> sourceFile = GeneratedColumn<String>(
    'source_file',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowCountMeta = const VerificationMeta(
    'rowCount',
  );
  @override
  late final GeneratedColumn<int> rowCount = GeneratedColumn<int>(
    'row_count',
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
    name,
    scope,
    projectId,
    keyColumn,
    columns,
    sourceFile,
    importedAt,
    rowCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reference_datasets';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReferenceDatasetRow> instance, {
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
    }
    if (data.containsKey('key_column')) {
      context.handle(
        _keyColumnMeta,
        keyColumn.isAcceptableOrUnknown(data['key_column']!, _keyColumnMeta),
      );
    } else if (isInserting) {
      context.missing(_keyColumnMeta);
    }
    if (data.containsKey('columns')) {
      context.handle(
        _columnsMeta,
        columns.isAcceptableOrUnknown(data['columns']!, _columnsMeta),
      );
    } else if (isInserting) {
      context.missing(_columnsMeta);
    }
    if (data.containsKey('source_file')) {
      context.handle(
        _sourceFileMeta,
        sourceFile.isAcceptableOrUnknown(data['source_file']!, _sourceFileMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceFileMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('row_count')) {
      context.handle(
        _rowCountMeta,
        rowCount.isAcceptableOrUnknown(data['row_count']!, _rowCountMeta),
      );
    } else if (isInserting) {
      context.missing(_rowCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReferenceDatasetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReferenceDatasetRow(
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
      scope: $ReferenceTable.$converterscope.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}scope'],
        )!,
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      keyColumn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_column'],
      )!,
      columns: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}columns'],
      )!,
      sourceFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_file'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      rowCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_count'],
      )!,
    );
  }

  @override
  $ReferenceTable createAlias(String alias) {
    return $ReferenceTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReferenceScope, String, String> $converterscope =
      const EnumNameConverter<ReferenceScope>(ReferenceScope.values);
}

class ReferenceDatasetRow extends DataClass
    implements Insertable<ReferenceDatasetRow> {
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

  /// Operator-facing name of the dataset.
  final String name;

  /// Global or project.
  final ReferenceScope scope;

  /// Owning project when [scope] is project.
  final String? projectId;

  /// Column used as the lookup key.
  final String keyColumn;

  /// Column names JSON, in import order. An array, stored as text.
  final String columns;

  /// Source path or name, stored as data, never interpolated into a query.
  final String sourceFile;

  /// When this import was written.
  final DateTime importedAt;

  /// Number of rows currently stored for this dataset.
  final int rowCount;
  const ReferenceDatasetRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.name,
    required this.scope,
    this.projectId,
    required this.keyColumn,
    required this.columns,
    required this.sourceFile,
    required this.importedAt,
    required this.rowCount,
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
    {
      map['scope'] = Variable<String>(
        $ReferenceTable.$converterscope.toSql(scope),
      );
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['key_column'] = Variable<String>(keyColumn);
    map['columns'] = Variable<String>(columns);
    map['source_file'] = Variable<String>(sourceFile);
    map['imported_at'] = Variable<DateTime>(importedAt);
    map['row_count'] = Variable<int>(rowCount);
    return map;
  }

  ReferenceCompanion toCompanion(bool nullToAbsent) {
    return ReferenceCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      name: Value(name),
      scope: Value(scope),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      keyColumn: Value(keyColumn),
      columns: Value(columns),
      sourceFile: Value(sourceFile),
      importedAt: Value(importedAt),
      rowCount: Value(rowCount),
    );
  }

  factory ReferenceDatasetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReferenceDatasetRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      name: serializer.fromJson<String>(json['name']),
      scope: $ReferenceTable.$converterscope.fromJson(
        serializer.fromJson<String>(json['scope']),
      ),
      projectId: serializer.fromJson<String?>(json['projectId']),
      keyColumn: serializer.fromJson<String>(json['keyColumn']),
      columns: serializer.fromJson<String>(json['columns']),
      sourceFile: serializer.fromJson<String>(json['sourceFile']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      rowCount: serializer.fromJson<int>(json['rowCount']),
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
      'scope': serializer.toJson<String>(
        $ReferenceTable.$converterscope.toJson(scope),
      ),
      'projectId': serializer.toJson<String?>(projectId),
      'keyColumn': serializer.toJson<String>(keyColumn),
      'columns': serializer.toJson<String>(columns),
      'sourceFile': serializer.toJson<String>(sourceFile),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'rowCount': serializer.toJson<int>(rowCount),
    };
  }

  ReferenceDatasetRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? name,
    ReferenceScope? scope,
    Value<String?> projectId = const Value.absent(),
    String? keyColumn,
    String? columns,
    String? sourceFile,
    DateTime? importedAt,
    int? rowCount,
  }) => ReferenceDatasetRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    name: name ?? this.name,
    scope: scope ?? this.scope,
    projectId: projectId.present ? projectId.value : this.projectId,
    keyColumn: keyColumn ?? this.keyColumn,
    columns: columns ?? this.columns,
    sourceFile: sourceFile ?? this.sourceFile,
    importedAt: importedAt ?? this.importedAt,
    rowCount: rowCount ?? this.rowCount,
  );
  ReferenceDatasetRow copyWithCompanion(ReferenceCompanion data) {
    return ReferenceDatasetRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      name: data.name.present ? data.name.value : this.name,
      scope: data.scope.present ? data.scope.value : this.scope,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      keyColumn: data.keyColumn.present ? data.keyColumn.value : this.keyColumn,
      columns: data.columns.present ? data.columns.value : this.columns,
      sourceFile: data.sourceFile.present
          ? data.sourceFile.value
          : this.sourceFile,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      rowCount: data.rowCount.present ? data.rowCount.value : this.rowCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceDatasetRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('name: $name, ')
          ..write('scope: $scope, ')
          ..write('projectId: $projectId, ')
          ..write('keyColumn: $keyColumn, ')
          ..write('columns: $columns, ')
          ..write('sourceFile: $sourceFile, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowCount: $rowCount')
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
    scope,
    projectId,
    keyColumn,
    columns,
    sourceFile,
    importedAt,
    rowCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferenceDatasetRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.name == this.name &&
          other.scope == this.scope &&
          other.projectId == this.projectId &&
          other.keyColumn == this.keyColumn &&
          other.columns == this.columns &&
          other.sourceFile == this.sourceFile &&
          other.importedAt == this.importedAt &&
          other.rowCount == this.rowCount);
}

class ReferenceCompanion extends UpdateCompanion<ReferenceDatasetRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> name;
  final Value<ReferenceScope> scope;
  final Value<String?> projectId;
  final Value<String> keyColumn;
  final Value<String> columns;
  final Value<String> sourceFile;
  final Value<DateTime> importedAt;
  final Value<int> rowCount;
  final Value<int> rowid;
  const ReferenceCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.name = const Value.absent(),
    this.scope = const Value.absent(),
    this.projectId = const Value.absent(),
    this.keyColumn = const Value.absent(),
    this.columns = const Value.absent(),
    this.sourceFile = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReferenceCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String name,
    required ReferenceScope scope,
    this.projectId = const Value.absent(),
    required String keyColumn,
    required String columns,
    required String sourceFile,
    required DateTime importedAt,
    required int rowCount,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       name = Value(name),
       scope = Value(scope),
       keyColumn = Value(keyColumn),
       columns = Value(columns),
       sourceFile = Value(sourceFile),
       importedAt = Value(importedAt),
       rowCount = Value(rowCount);
  static Insertable<ReferenceDatasetRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? name,
    Expression<String>? scope,
    Expression<String>? projectId,
    Expression<String>? keyColumn,
    Expression<String>? columns,
    Expression<String>? sourceFile,
    Expression<DateTime>? importedAt,
    Expression<int>? rowCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (name != null) 'name': name,
      if (scope != null) 'scope': scope,
      if (projectId != null) 'project_id': projectId,
      if (keyColumn != null) 'key_column': keyColumn,
      if (columns != null) 'columns': columns,
      if (sourceFile != null) 'source_file': sourceFile,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowCount != null) 'row_count': rowCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReferenceCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? name,
    Value<ReferenceScope>? scope,
    Value<String?>? projectId,
    Value<String>? keyColumn,
    Value<String>? columns,
    Value<String>? sourceFile,
    Value<DateTime>? importedAt,
    Value<int>? rowCount,
    Value<int>? rowid,
  }) {
    return ReferenceCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      name: name ?? this.name,
      scope: scope ?? this.scope,
      projectId: projectId ?? this.projectId,
      keyColumn: keyColumn ?? this.keyColumn,
      columns: columns ?? this.columns,
      sourceFile: sourceFile ?? this.sourceFile,
      importedAt: importedAt ?? this.importedAt,
      rowCount: rowCount ?? this.rowCount,
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
    if (scope.present) {
      map['scope'] = Variable<String>(
        $ReferenceTable.$converterscope.toSql(scope.value),
      );
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (keyColumn.present) {
      map['key_column'] = Variable<String>(keyColumn.value);
    }
    if (columns.present) {
      map['columns'] = Variable<String>(columns.value);
    }
    if (sourceFile.present) {
      map['source_file'] = Variable<String>(sourceFile.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (rowCount.present) {
      map['row_count'] = Variable<int>(rowCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('name: $name, ')
          ..write('scope: $scope, ')
          ..write('projectId: $projectId, ')
          ..write('keyColumn: $keyColumn, ')
          ..write('columns: $columns, ')
          ..write('sourceFile: $sourceFile, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowCount: $rowCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReferenceRowsTable extends ReferenceRows
    with TableInfo<$ReferenceRowsTable, ReferenceLookupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReferenceRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _datasetIdMeta = const VerificationMeta(
    'datasetId',
  );
  @override
  late final GeneratedColumn<String> datasetId = GeneratedColumn<String>(
    'dataset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyValueMeta = const VerificationMeta(
    'keyValue',
  );
  @override
  late final GeneratedColumn<String> keyValue = GeneratedColumn<String>(
    'key_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyNormalisedMeta = const VerificationMeta(
    'keyNormalised',
  );
  @override
  late final GeneratedColumn<String> keyNormalised = GeneratedColumn<String>(
    'key_normalised',
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
    datasetId,
    keyValue,
    keyNormalised,
    values,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reference_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReferenceLookupRow> instance, {
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
    if (data.containsKey('dataset_id')) {
      context.handle(
        _datasetIdMeta,
        datasetId.isAcceptableOrUnknown(data['dataset_id']!, _datasetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_datasetIdMeta);
    }
    if (data.containsKey('key_value')) {
      context.handle(
        _keyValueMeta,
        keyValue.isAcceptableOrUnknown(data['key_value']!, _keyValueMeta),
      );
    } else if (isInserting) {
      context.missing(_keyValueMeta);
    }
    if (data.containsKey('key_normalised')) {
      context.handle(
        _keyNormalisedMeta,
        keyNormalised.isAcceptableOrUnknown(
          data['key_normalised']!,
          _keyNormalisedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keyNormalisedMeta);
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
  ReferenceLookupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReferenceLookupRow(
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
      datasetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dataset_id'],
      )!,
      keyValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_value'],
      )!,
      keyNormalised: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_normalised'],
      )!,
      values: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}values'],
      )!,
    );
  }

  @override
  $ReferenceRowsTable createAlias(String alias) {
    return $ReferenceRowsTable(attachedDatabase, alias);
  }
}

class ReferenceLookupRow extends DataClass
    implements Insertable<ReferenceLookupRow> {
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

  /// Dataset this row belongs to.
  final String datasetId;

  /// Key as imported, stored as data.
  final String keyValue;

  /// Folded [keyValue] used for indexed lookup.
  final String keyNormalised;

  /// Cell values JSON. An object, stored as text.
  final String values;
  const ReferenceLookupRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.datasetId,
    required this.keyValue,
    required this.keyNormalised,
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
    map['dataset_id'] = Variable<String>(datasetId);
    map['key_value'] = Variable<String>(keyValue);
    map['key_normalised'] = Variable<String>(keyNormalised);
    map['values'] = Variable<String>(values);
    return map;
  }

  ReferenceRowsCompanion toCompanion(bool nullToAbsent) {
    return ReferenceRowsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      datasetId: Value(datasetId),
      keyValue: Value(keyValue),
      keyNormalised: Value(keyNormalised),
      values: Value(values),
    );
  }

  factory ReferenceLookupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReferenceLookupRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      datasetId: serializer.fromJson<String>(json['datasetId']),
      keyValue: serializer.fromJson<String>(json['keyValue']),
      keyNormalised: serializer.fromJson<String>(json['keyNormalised']),
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
      'datasetId': serializer.toJson<String>(datasetId),
      'keyValue': serializer.toJson<String>(keyValue),
      'keyNormalised': serializer.toJson<String>(keyNormalised),
      'values': serializer.toJson<String>(values),
    };
  }

  ReferenceLookupRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? datasetId,
    String? keyValue,
    String? keyNormalised,
    String? values,
  }) => ReferenceLookupRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    datasetId: datasetId ?? this.datasetId,
    keyValue: keyValue ?? this.keyValue,
    keyNormalised: keyNormalised ?? this.keyNormalised,
    values: values ?? this.values,
  );
  ReferenceLookupRow copyWithCompanion(ReferenceRowsCompanion data) {
    return ReferenceLookupRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      datasetId: data.datasetId.present ? data.datasetId.value : this.datasetId,
      keyValue: data.keyValue.present ? data.keyValue.value : this.keyValue,
      keyNormalised: data.keyNormalised.present
          ? data.keyNormalised.value
          : this.keyNormalised,
      values: data.values.present ? data.values.value : this.values,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceLookupRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('datasetId: $datasetId, ')
          ..write('keyValue: $keyValue, ')
          ..write('keyNormalised: $keyNormalised, ')
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
    datasetId,
    keyValue,
    keyNormalised,
    values,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferenceLookupRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.datasetId == this.datasetId &&
          other.keyValue == this.keyValue &&
          other.keyNormalised == this.keyNormalised &&
          other.values == this.values);
}

class ReferenceRowsCompanion extends UpdateCompanion<ReferenceLookupRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> datasetId;
  final Value<String> keyValue;
  final Value<String> keyNormalised;
  final Value<String> values;
  final Value<int> rowid;
  const ReferenceRowsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.datasetId = const Value.absent(),
    this.keyValue = const Value.absent(),
    this.keyNormalised = const Value.absent(),
    this.values = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReferenceRowsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String datasetId,
    required String keyValue,
    required String keyNormalised,
    required String values,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       datasetId = Value(datasetId),
       keyValue = Value(keyValue),
       keyNormalised = Value(keyNormalised),
       values = Value(values);
  static Insertable<ReferenceLookupRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? datasetId,
    Expression<String>? keyValue,
    Expression<String>? keyNormalised,
    Expression<String>? values,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (datasetId != null) 'dataset_id': datasetId,
      if (keyValue != null) 'key_value': keyValue,
      if (keyNormalised != null) 'key_normalised': keyNormalised,
      if (values != null) 'values': values,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReferenceRowsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? datasetId,
    Value<String>? keyValue,
    Value<String>? keyNormalised,
    Value<String>? values,
    Value<int>? rowid,
  }) {
    return ReferenceRowsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      datasetId: datasetId ?? this.datasetId,
      keyValue: keyValue ?? this.keyValue,
      keyNormalised: keyNormalised ?? this.keyNormalised,
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
    if (datasetId.present) {
      map['dataset_id'] = Variable<String>(datasetId.value);
    }
    if (keyValue.present) {
      map['key_value'] = Variable<String>(keyValue.value);
    }
    if (keyNormalised.present) {
      map['key_normalised'] = Variable<String>(keyNormalised.value);
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
    return (StringBuffer('ReferenceRowsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('datasetId: $datasetId, ')
          ..write('keyValue: $keyValue, ')
          ..write('keyNormalised: $keyNormalised, ')
          ..write('values: $values, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProcessingTable extends Processing
    with TableInfo<$ProcessingTable, ProcessingJobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcessingTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ProcessingJobStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ProcessingJobStatus>($ProcessingTable.$converterstatus);
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leaseExpiresAtMeta = const VerificationMeta(
    'leaseExpiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> leaseExpiresAt =
      GeneratedColumn<DateTime>(
        'lease_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _skipReasonMeta = const VerificationMeta(
    'skipReason',
  );
  @override
  late final GeneratedColumn<String> skipReason = GeneratedColumn<String>(
    'skip_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rejectionsMeta = const VerificationMeta(
    'rejections',
  );
  @override
  late final GeneratedColumn<String> rejections = GeneratedColumn<String>(
    'rejections',
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
    recordId,
    stage,
    status,
    attempts,
    lastError,
    queuedAt,
    startedAt,
    finishedAt,
    provider,
    model,
    leaseExpiresAt,
    skipReason,
    rejections,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'processing_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProcessingJobRow> instance, {
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
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('lease_expires_at')) {
      context.handle(
        _leaseExpiresAtMeta,
        leaseExpiresAt.isAcceptableOrUnknown(
          data['lease_expires_at']!,
          _leaseExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('skip_reason')) {
      context.handle(
        _skipReasonMeta,
        skipReason.isAcceptableOrUnknown(data['skip_reason']!, _skipReasonMeta),
      );
    }
    if (data.containsKey('rejections')) {
      context.handle(
        _rejectionsMeta,
        rejections.isAcceptableOrUnknown(data['rejections']!, _rejectionsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcessingJobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessingJobRow(
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
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage'],
      )!,
      status: $ProcessingTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      leaseExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lease_expires_at'],
      ),
      skipReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skip_reason'],
      ),
      rejections: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejections'],
      ),
    );
  }

  @override
  $ProcessingTable createAlias(String alias) {
    return $ProcessingTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ProcessingJobStatus, String, String>
  $converterstatus = const EnumNameConverter<ProcessingJobStatus>(
    ProcessingJobStatus.values,
  );
}

class ProcessingJobRow extends DataClass
    implements Insertable<ProcessingJobRow> {
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

  /// Record this job will process.
  final String recordId;

  /// Last stage the runner reached, stored as data.
  final String stage;

  /// queued, running, completed or failed.
  final ProcessingJobStatus status;

  /// How many times this job has been retried.
  final int attempts;

  /// Last failure reason, when one exists. Stored as data.
  final String? lastError;

  /// When the job entered the queue.
  final DateTime queuedAt;

  /// When a runner claimed it, if it has been claimed.
  final DateTime? startedAt;

  /// When the job last finished, if it has.
  final DateTime? finishedAt;

  /// Provider name, when an online stage ran.
  final String? provider;

  /// Model name, when an online stage ran.
  final String? model;

  /// When a claim stops being owned by the runner that took it.
  ///
  /// A later claim releases a running job whose lease is already past, so a
  /// killed runner does not lose the job.
  final DateTime? leaseExpiresAt;

  /// Why the online stage was not called, when it was skipped.
  final String? skipReason;

  /// Rejection reasons JSON. An array of strings, stored as text.
  final String? rejections;
  const ProcessingJobRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.recordId,
    required this.stage,
    required this.status,
    required this.attempts,
    this.lastError,
    required this.queuedAt,
    this.startedAt,
    this.finishedAt,
    this.provider,
    this.model,
    this.leaseExpiresAt,
    this.skipReason,
    this.rejections,
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
    map['stage'] = Variable<String>(stage);
    {
      map['status'] = Variable<String>(
        $ProcessingTable.$converterstatus.toSql(status),
      );
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['queued_at'] = Variable<DateTime>(queuedAt);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    if (!nullToAbsent || provider != null) {
      map['provider'] = Variable<String>(provider);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || leaseExpiresAt != null) {
      map['lease_expires_at'] = Variable<DateTime>(leaseExpiresAt);
    }
    if (!nullToAbsent || skipReason != null) {
      map['skip_reason'] = Variable<String>(skipReason);
    }
    if (!nullToAbsent || rejections != null) {
      map['rejections'] = Variable<String>(rejections);
    }
    return map;
  }

  ProcessingCompanion toCompanion(bool nullToAbsent) {
    return ProcessingCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      recordId: Value(recordId),
      stage: Value(stage),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      queuedAt: Value(queuedAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      provider: provider == null && nullToAbsent
          ? const Value.absent()
          : Value(provider),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      leaseExpiresAt: leaseExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(leaseExpiresAt),
      skipReason: skipReason == null && nullToAbsent
          ? const Value.absent()
          : Value(skipReason),
      rejections: rejections == null && nullToAbsent
          ? const Value.absent()
          : Value(rejections),
    );
  }

  factory ProcessingJobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessingJobRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      recordId: serializer.fromJson<String>(json['recordId']),
      stage: serializer.fromJson<String>(json['stage']),
      status: $ProcessingTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      provider: serializer.fromJson<String?>(json['provider']),
      model: serializer.fromJson<String?>(json['model']),
      leaseExpiresAt: serializer.fromJson<DateTime?>(json['leaseExpiresAt']),
      skipReason: serializer.fromJson<String?>(json['skipReason']),
      rejections: serializer.fromJson<String?>(json['rejections']),
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
      'stage': serializer.toJson<String>(stage),
      'status': serializer.toJson<String>(
        $ProcessingTable.$converterstatus.toJson(status),
      ),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'provider': serializer.toJson<String?>(provider),
      'model': serializer.toJson<String?>(model),
      'leaseExpiresAt': serializer.toJson<DateTime?>(leaseExpiresAt),
      'skipReason': serializer.toJson<String?>(skipReason),
      'rejections': serializer.toJson<String?>(rejections),
    };
  }

  ProcessingJobRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? recordId,
    String? stage,
    ProcessingJobStatus? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    DateTime? queuedAt,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> finishedAt = const Value.absent(),
    Value<String?> provider = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<DateTime?> leaseExpiresAt = const Value.absent(),
    Value<String?> skipReason = const Value.absent(),
    Value<String?> rejections = const Value.absent(),
  }) => ProcessingJobRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    recordId: recordId ?? this.recordId,
    stage: stage ?? this.stage,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    queuedAt: queuedAt ?? this.queuedAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    provider: provider.present ? provider.value : this.provider,
    model: model.present ? model.value : this.model,
    leaseExpiresAt: leaseExpiresAt.present
        ? leaseExpiresAt.value
        : this.leaseExpiresAt,
    skipReason: skipReason.present ? skipReason.value : this.skipReason,
    rejections: rejections.present ? rejections.value : this.rejections,
  );
  ProcessingJobRow copyWithCompanion(ProcessingCompanion data) {
    return ProcessingJobRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      stage: data.stage.present ? data.stage.value : this.stage,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      provider: data.provider.present ? data.provider.value : this.provider,
      model: data.model.present ? data.model.value : this.model,
      leaseExpiresAt: data.leaseExpiresAt.present
          ? data.leaseExpiresAt.value
          : this.leaseExpiresAt,
      skipReason: data.skipReason.present
          ? data.skipReason.value
          : this.skipReason,
      rejections: data.rejections.present
          ? data.rejections.value
          : this.rejections,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessingJobRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('recordId: $recordId, ')
          ..write('stage: $stage, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('provider: $provider, ')
          ..write('model: $model, ')
          ..write('leaseExpiresAt: $leaseExpiresAt, ')
          ..write('skipReason: $skipReason, ')
          ..write('rejections: $rejections')
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
    stage,
    status,
    attempts,
    lastError,
    queuedAt,
    startedAt,
    finishedAt,
    provider,
    model,
    leaseExpiresAt,
    skipReason,
    rejections,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessingJobRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.recordId == this.recordId &&
          other.stage == this.stage &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.queuedAt == this.queuedAt &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.provider == this.provider &&
          other.model == this.model &&
          other.leaseExpiresAt == this.leaseExpiresAt &&
          other.skipReason == this.skipReason &&
          other.rejections == this.rejections);
}

class ProcessingCompanion extends UpdateCompanion<ProcessingJobRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> recordId;
  final Value<String> stage;
  final Value<ProcessingJobStatus> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> queuedAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<String?> provider;
  final Value<String?> model;
  final Value<DateTime?> leaseExpiresAt;
  final Value<String?> skipReason;
  final Value<String?> rejections;
  final Value<int> rowid;
  const ProcessingCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.recordId = const Value.absent(),
    this.stage = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.provider = const Value.absent(),
    this.model = const Value.absent(),
    this.leaseExpiresAt = const Value.absent(),
    this.skipReason = const Value.absent(),
    this.rejections = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProcessingCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String recordId,
    required String stage,
    required ProcessingJobStatus status,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime queuedAt,
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.provider = const Value.absent(),
    this.model = const Value.absent(),
    this.leaseExpiresAt = const Value.absent(),
    this.skipReason = const Value.absent(),
    this.rejections = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       recordId = Value(recordId),
       stage = Value(stage),
       status = Value(status),
       queuedAt = Value(queuedAt);
  static Insertable<ProcessingJobRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? recordId,
    Expression<String>? stage,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? queuedAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<String>? provider,
    Expression<String>? model,
    Expression<DateTime>? leaseExpiresAt,
    Expression<String>? skipReason,
    Expression<String>? rejections,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (recordId != null) 'record_id': recordId,
      if (stage != null) 'stage': stage,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (provider != null) 'provider': provider,
      if (model != null) 'model': model,
      if (leaseExpiresAt != null) 'lease_expires_at': leaseExpiresAt,
      if (skipReason != null) 'skip_reason': skipReason,
      if (rejections != null) 'rejections': rejections,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProcessingCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? recordId,
    Value<String>? stage,
    Value<ProcessingJobStatus>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime>? queuedAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<String?>? provider,
    Value<String?>? model,
    Value<DateTime?>? leaseExpiresAt,
    Value<String?>? skipReason,
    Value<String?>? rejections,
    Value<int>? rowid,
  }) {
    return ProcessingCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      recordId: recordId ?? this.recordId,
      stage: stage ?? this.stage,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      queuedAt: queuedAt ?? this.queuedAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      leaseExpiresAt: leaseExpiresAt ?? this.leaseExpiresAt,
      skipReason: skipReason ?? this.skipReason,
      rejections: rejections ?? this.rejections,
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
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ProcessingTable.$converterstatus.toSql(status.value),
      );
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (leaseExpiresAt.present) {
      map['lease_expires_at'] = Variable<DateTime>(leaseExpiresAt.value);
    }
    if (skipReason.present) {
      map['skip_reason'] = Variable<String>(skipReason.value);
    }
    if (rejections.present) {
      map['rejections'] = Variable<String>(rejections.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcessingCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('recordId: $recordId, ')
          ..write('stage: $stage, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('provider: $provider, ')
          ..write('model: $model, ')
          ..write('leaseExpiresAt: $leaseExpiresAt, ')
          ..write('skipReason: $skipReason, ')
          ..write('rejections: $rejections, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProcessingResultsTable extends ProcessingResults
    with TableInfo<$ProcessingResultsTable, ProcessingResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcessingResultsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestSummaryMeta = const VerificationMeta(
    'requestSummary',
  );
  @override
  late final GeneratedColumn<String> requestSummary = GeneratedColumn<String>(
    'request_summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawResponseMeta = const VerificationMeta(
    'rawResponse',
  );
  @override
  late final GeneratedColumn<String> rawResponse = GeneratedColumn<String>(
    'raw_response',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parsedOkMeta = const VerificationMeta(
    'parsedOk',
  );
  @override
  late final GeneratedColumn<bool> parsedOk = GeneratedColumn<bool>(
    'parsed_ok',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("parsed_ok" IN (0, 1))',
    ),
  );
  static const VerificationMeta _tokensOrCostMeta = const VerificationMeta(
    'tokensOrCost',
  );
  @override
  late final GeneratedColumn<String> tokensOrCost = GeneratedColumn<String>(
    'tokens_or_cost',
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
    jobId,
    requestSummary,
    rawResponse,
    parsedOk,
    tokensOrCost,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'processing_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProcessingResult> instance, {
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
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('request_summary')) {
      context.handle(
        _requestSummaryMeta,
        requestSummary.isAcceptableOrUnknown(
          data['request_summary']!,
          _requestSummaryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestSummaryMeta);
    }
    if (data.containsKey('raw_response')) {
      context.handle(
        _rawResponseMeta,
        rawResponse.isAcceptableOrUnknown(
          data['raw_response']!,
          _rawResponseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawResponseMeta);
    }
    if (data.containsKey('parsed_ok')) {
      context.handle(
        _parsedOkMeta,
        parsedOk.isAcceptableOrUnknown(data['parsed_ok']!, _parsedOkMeta),
      );
    } else if (isInserting) {
      context.missing(_parsedOkMeta);
    }
    if (data.containsKey('tokens_or_cost')) {
      context.handle(
        _tokensOrCostMeta,
        tokensOrCost.isAcceptableOrUnknown(
          data['tokens_or_cost']!,
          _tokensOrCostMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcessingResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessingResult(
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
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      requestSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_summary'],
      )!,
      rawResponse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_response'],
      )!,
      parsedOk: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}parsed_ok'],
      )!,
      tokensOrCost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tokens_or_cost'],
      ),
    );
  }

  @override
  $ProcessingResultsTable createAlias(String alias) {
    return $ProcessingResultsTable(attachedDatabase, alias);
  }
}

class ProcessingResult extends DataClass
    implements Insertable<ProcessingResult> {
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

  /// Job this result belongs to. Several rows may share a job across retries.
  final String jobId;

  /// Shape and size of the request. Never a key or bearer token.
  final String requestSummary;

  /// Provider output as it arrived. Written once.
  final String rawResponse;

  /// Whether the response parsed against the template schema.
  final bool parsedOk;

  /// Token count or cost figure, when the provider reported one.
  final String? tokensOrCost;
  const ProcessingResult({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.jobId,
    required this.requestSummary,
    required this.rawResponse,
    required this.parsedOk,
    this.tokensOrCost,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['job_id'] = Variable<String>(jobId);
    map['request_summary'] = Variable<String>(requestSummary);
    map['raw_response'] = Variable<String>(rawResponse);
    map['parsed_ok'] = Variable<bool>(parsedOk);
    if (!nullToAbsent || tokensOrCost != null) {
      map['tokens_or_cost'] = Variable<String>(tokensOrCost);
    }
    return map;
  }

  ProcessingResultsCompanion toCompanion(bool nullToAbsent) {
    return ProcessingResultsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      jobId: Value(jobId),
      requestSummary: Value(requestSummary),
      rawResponse: Value(rawResponse),
      parsedOk: Value(parsedOk),
      tokensOrCost: tokensOrCost == null && nullToAbsent
          ? const Value.absent()
          : Value(tokensOrCost),
    );
  }

  factory ProcessingResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessingResult(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      jobId: serializer.fromJson<String>(json['jobId']),
      requestSummary: serializer.fromJson<String>(json['requestSummary']),
      rawResponse: serializer.fromJson<String>(json['rawResponse']),
      parsedOk: serializer.fromJson<bool>(json['parsedOk']),
      tokensOrCost: serializer.fromJson<String?>(json['tokensOrCost']),
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
      'jobId': serializer.toJson<String>(jobId),
      'requestSummary': serializer.toJson<String>(requestSummary),
      'rawResponse': serializer.toJson<String>(rawResponse),
      'parsedOk': serializer.toJson<bool>(parsedOk),
      'tokensOrCost': serializer.toJson<String?>(tokensOrCost),
    };
  }

  ProcessingResult copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? jobId,
    String? requestSummary,
    String? rawResponse,
    bool? parsedOk,
    Value<String?> tokensOrCost = const Value.absent(),
  }) => ProcessingResult(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    jobId: jobId ?? this.jobId,
    requestSummary: requestSummary ?? this.requestSummary,
    rawResponse: rawResponse ?? this.rawResponse,
    parsedOk: parsedOk ?? this.parsedOk,
    tokensOrCost: tokensOrCost.present ? tokensOrCost.value : this.tokensOrCost,
  );
  ProcessingResult copyWithCompanion(ProcessingResultsCompanion data) {
    return ProcessingResult(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      requestSummary: data.requestSummary.present
          ? data.requestSummary.value
          : this.requestSummary,
      rawResponse: data.rawResponse.present
          ? data.rawResponse.value
          : this.rawResponse,
      parsedOk: data.parsedOk.present ? data.parsedOk.value : this.parsedOk,
      tokensOrCost: data.tokensOrCost.present
          ? data.tokensOrCost.value
          : this.tokensOrCost,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessingResult(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('jobId: $jobId, ')
          ..write('requestSummary: $requestSummary, ')
          ..write('rawResponse: $rawResponse, ')
          ..write('parsedOk: $parsedOk, ')
          ..write('tokensOrCost: $tokensOrCost')
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
    jobId,
    requestSummary,
    rawResponse,
    parsedOk,
    tokensOrCost,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessingResult &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.jobId == this.jobId &&
          other.requestSummary == this.requestSummary &&
          other.rawResponse == this.rawResponse &&
          other.parsedOk == this.parsedOk &&
          other.tokensOrCost == this.tokensOrCost);
}

class ProcessingResultsCompanion extends UpdateCompanion<ProcessingResult> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> jobId;
  final Value<String> requestSummary;
  final Value<String> rawResponse;
  final Value<bool> parsedOk;
  final Value<String?> tokensOrCost;
  final Value<int> rowid;
  const ProcessingResultsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.jobId = const Value.absent(),
    this.requestSummary = const Value.absent(),
    this.rawResponse = const Value.absent(),
    this.parsedOk = const Value.absent(),
    this.tokensOrCost = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProcessingResultsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String jobId,
    required String requestSummary,
    required String rawResponse,
    required bool parsedOk,
    this.tokensOrCost = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       jobId = Value(jobId),
       requestSummary = Value(requestSummary),
       rawResponse = Value(rawResponse),
       parsedOk = Value(parsedOk);
  static Insertable<ProcessingResult> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? jobId,
    Expression<String>? requestSummary,
    Expression<String>? rawResponse,
    Expression<bool>? parsedOk,
    Expression<String>? tokensOrCost,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (jobId != null) 'job_id': jobId,
      if (requestSummary != null) 'request_summary': requestSummary,
      if (rawResponse != null) 'raw_response': rawResponse,
      if (parsedOk != null) 'parsed_ok': parsedOk,
      if (tokensOrCost != null) 'tokens_or_cost': tokensOrCost,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProcessingResultsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? jobId,
    Value<String>? requestSummary,
    Value<String>? rawResponse,
    Value<bool>? parsedOk,
    Value<String?>? tokensOrCost,
    Value<int>? rowid,
  }) {
    return ProcessingResultsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      jobId: jobId ?? this.jobId,
      requestSummary: requestSummary ?? this.requestSummary,
      rawResponse: rawResponse ?? this.rawResponse,
      parsedOk: parsedOk ?? this.parsedOk,
      tokensOrCost: tokensOrCost ?? this.tokensOrCost,
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
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (requestSummary.present) {
      map['request_summary'] = Variable<String>(requestSummary.value);
    }
    if (rawResponse.present) {
      map['raw_response'] = Variable<String>(rawResponse.value);
    }
    if (parsedOk.present) {
      map['parsed_ok'] = Variable<bool>(parsedOk.value);
    }
    if (tokensOrCost.present) {
      map['tokens_or_cost'] = Variable<String>(tokensOrCost.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcessingResultsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('jobId: $jobId, ')
          ..write('requestSummary: $requestSummary, ')
          ..write('rawResponse: $rawResponse, ')
          ..write('parsedOk: $parsedOk, ')
          ..write('tokensOrCost: $tokensOrCost, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OcrCacheEntriesTable extends OcrCacheEntries
    with TableInfo<$OcrCacheEntriesTable, OcrCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OcrCacheEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _perceptualHashMeta = const VerificationMeta(
    'perceptualHash',
  );
  @override
  late final GeneratedColumn<String> perceptualHash = GeneratedColumn<String>(
    'perceptual_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recognisedTextMeta = const VerificationMeta(
    'recognisedText',
  );
  @override
  late final GeneratedColumn<String> recognisedText = GeneratedColumn<String>(
    'recognised_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blocksJsonMeta = const VerificationMeta(
    'blocksJson',
  );
  @override
  late final GeneratedColumn<String> blocksJson = GeneratedColumn<String>(
    'blocks_json',
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
    contentHash,
    perceptualHash,
    recognisedText,
    blocksJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ocr_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<OcrCacheEntry> instance, {
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
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('perceptual_hash')) {
      context.handle(
        _perceptualHashMeta,
        perceptualHash.isAcceptableOrUnknown(
          data['perceptual_hash']!,
          _perceptualHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_perceptualHashMeta);
    }
    if (data.containsKey('recognised_text')) {
      context.handle(
        _recognisedTextMeta,
        recognisedText.isAcceptableOrUnknown(
          data['recognised_text']!,
          _recognisedTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recognisedTextMeta);
    }
    if (data.containsKey('blocks_json')) {
      context.handle(
        _blocksJsonMeta,
        blocksJson.isAcceptableOrUnknown(data['blocks_json']!, _blocksJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_blocksJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OcrCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OcrCacheEntry(
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
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      perceptualHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}perceptual_hash'],
      )!,
      recognisedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recognised_text'],
      )!,
      blocksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blocks_json'],
      )!,
    );
  }

  @override
  $OcrCacheEntriesTable createAlias(String alias) {
    return $OcrCacheEntriesTable(attachedDatabase, alias);
  }
}

class OcrCacheEntry extends DataClass implements Insertable<OcrCacheEntry> {
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

  /// SHA-256 of the image bytes this row was read from.
  final String contentHash;

  /// Difference hash, stored as hex, for near-duplicate lookup.
  final String perceptualHash;

  /// Recognised text. Stored as data, never executed.
  final String recognisedText;

  /// Blocks and bounding boxes as a JSON array.
  final String blocksJson;
  const OcrCacheEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.contentHash,
    required this.perceptualHash,
    required this.recognisedText,
    required this.blocksJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['content_hash'] = Variable<String>(contentHash);
    map['perceptual_hash'] = Variable<String>(perceptualHash);
    map['recognised_text'] = Variable<String>(recognisedText);
    map['blocks_json'] = Variable<String>(blocksJson);
    return map;
  }

  OcrCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return OcrCacheEntriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      contentHash: Value(contentHash),
      perceptualHash: Value(perceptualHash),
      recognisedText: Value(recognisedText),
      blocksJson: Value(blocksJson),
    );
  }

  factory OcrCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OcrCacheEntry(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      perceptualHash: serializer.fromJson<String>(json['perceptualHash']),
      recognisedText: serializer.fromJson<String>(json['recognisedText']),
      blocksJson: serializer.fromJson<String>(json['blocksJson']),
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
      'contentHash': serializer.toJson<String>(contentHash),
      'perceptualHash': serializer.toJson<String>(perceptualHash),
      'recognisedText': serializer.toJson<String>(recognisedText),
      'blocksJson': serializer.toJson<String>(blocksJson),
    };
  }

  OcrCacheEntry copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? contentHash,
    String? perceptualHash,
    String? recognisedText,
    String? blocksJson,
  }) => OcrCacheEntry(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    contentHash: contentHash ?? this.contentHash,
    perceptualHash: perceptualHash ?? this.perceptualHash,
    recognisedText: recognisedText ?? this.recognisedText,
    blocksJson: blocksJson ?? this.blocksJson,
  );
  OcrCacheEntry copyWithCompanion(OcrCacheEntriesCompanion data) {
    return OcrCacheEntry(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      perceptualHash: data.perceptualHash.present
          ? data.perceptualHash.value
          : this.perceptualHash,
      recognisedText: data.recognisedText.present
          ? data.recognisedText.value
          : this.recognisedText,
      blocksJson: data.blocksJson.present
          ? data.blocksJson.value
          : this.blocksJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OcrCacheEntry(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('contentHash: $contentHash, ')
          ..write('perceptualHash: $perceptualHash, ')
          ..write('recognisedText: $recognisedText, ')
          ..write('blocksJson: $blocksJson')
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
    contentHash,
    perceptualHash,
    recognisedText,
    blocksJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OcrCacheEntry &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.contentHash == this.contentHash &&
          other.perceptualHash == this.perceptualHash &&
          other.recognisedText == this.recognisedText &&
          other.blocksJson == this.blocksJson);
}

class OcrCacheEntriesCompanion extends UpdateCompanion<OcrCacheEntry> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> contentHash;
  final Value<String> perceptualHash;
  final Value<String> recognisedText;
  final Value<String> blocksJson;
  final Value<int> rowid;
  const OcrCacheEntriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.perceptualHash = const Value.absent(),
    this.recognisedText = const Value.absent(),
    this.blocksJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OcrCacheEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String contentHash,
    required String perceptualHash,
    required String recognisedText,
    required String blocksJson,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       contentHash = Value(contentHash),
       perceptualHash = Value(perceptualHash),
       recognisedText = Value(recognisedText),
       blocksJson = Value(blocksJson);
  static Insertable<OcrCacheEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? contentHash,
    Expression<String>? perceptualHash,
    Expression<String>? recognisedText,
    Expression<String>? blocksJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (contentHash != null) 'content_hash': contentHash,
      if (perceptualHash != null) 'perceptual_hash': perceptualHash,
      if (recognisedText != null) 'recognised_text': recognisedText,
      if (blocksJson != null) 'blocks_json': blocksJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OcrCacheEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? contentHash,
    Value<String>? perceptualHash,
    Value<String>? recognisedText,
    Value<String>? blocksJson,
    Value<int>? rowid,
  }) {
    return OcrCacheEntriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      contentHash: contentHash ?? this.contentHash,
      perceptualHash: perceptualHash ?? this.perceptualHash,
      recognisedText: recognisedText ?? this.recognisedText,
      blocksJson: blocksJson ?? this.blocksJson,
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
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (perceptualHash.present) {
      map['perceptual_hash'] = Variable<String>(perceptualHash.value);
    }
    if (recognisedText.present) {
      map['recognised_text'] = Variable<String>(recognisedText.value);
    }
    if (blocksJson.present) {
      map['blocks_json'] = Variable<String>(blocksJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OcrCacheEntriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('contentHash: $contentHash, ')
          ..write('perceptualHash: $perceptualHash, ')
          ..write('recognisedText: $recognisedText, ')
          ..write('blocksJson: $blocksJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FieldEvidenceTable extends FieldEvidence
    with TableInfo<$FieldEvidenceTable, FieldEvidenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FieldEvidenceTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _recordFieldIdMeta = const VerificationMeta(
    'recordFieldId',
  );
  @override
  late final GeneratedColumn<String> recordFieldId = GeneratedColumn<String>(
    'record_field_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FieldEvidenceSource, String>
  sourceType =
      GeneratedColumn<String>(
        'source_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FieldEvidenceSource>(
        $FieldEvidenceTable.$convertersourceType,
      );
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<String> photoId = GeneratedColumn<String>(
    'photo_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snippetMeta = const VerificationMeta(
    'snippet',
  );
  @override
  late final GeneratedColumn<String> snippet = GeneratedColumn<String>(
    'snippet',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    recordFieldId,
    sourceType,
    photoId,
    documentId,
    page,
    region,
    snippet,
    confidence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'field_evidence';
  @override
  VerificationContext validateIntegrity(
    Insertable<FieldEvidenceRow> instance, {
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
    if (data.containsKey('record_field_id')) {
      context.handle(
        _recordFieldIdMeta,
        recordFieldId.isAcceptableOrUnknown(
          data['record_field_id']!,
          _recordFieldIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordFieldIdMeta);
    }
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    if (data.containsKey('snippet')) {
      context.handle(
        _snippetMeta,
        snippet.isAcceptableOrUnknown(data['snippet']!, _snippetMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FieldEvidenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FieldEvidenceRow(
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
      recordFieldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_field_id'],
      )!,
      sourceType: $FieldEvidenceTable.$convertersourceType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source_type'],
        )!,
      ),
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      ),
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      ),
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      ),
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      ),
      snippet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snippet'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
    );
  }

  @override
  $FieldEvidenceTable createAlias(String alias) {
    return $FieldEvidenceTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FieldEvidenceSource, String, String>
  $convertersourceType = const EnumNameConverter<FieldEvidenceSource>(
    FieldEvidenceSource.values,
  );
}

class FieldEvidenceRow extends DataClass
    implements Insertable<FieldEvidenceRow> {
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

  /// Record field this evidence supports.
  final String recordFieldId;

  /// Photo, document or transcript.
  final FieldEvidenceSource sourceType;

  /// Photo this region came from, when [sourceType] is photo.
  final String? photoId;

  /// Document this page came from, when [sourceType] is document.
  final String? documentId;

  /// Document page number, when known.
  final int? page;

  /// Bounding box JSON. An object, stored as text.
  final String? region;

  /// Transcript segment or OCR snippet, stored as data.
  final String? snippet;

  /// Confidence of the extraction, when the provider reported one.
  final double? confidence;
  const FieldEvidenceRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.recordFieldId,
    required this.sourceType,
    this.photoId,
    this.documentId,
    this.page,
    this.region,
    this.snippet,
    this.confidence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['record_field_id'] = Variable<String>(recordFieldId);
    {
      map['source_type'] = Variable<String>(
        $FieldEvidenceTable.$convertersourceType.toSql(sourceType),
      );
    }
    if (!nullToAbsent || photoId != null) {
      map['photo_id'] = Variable<String>(photoId);
    }
    if (!nullToAbsent || documentId != null) {
      map['document_id'] = Variable<String>(documentId);
    }
    if (!nullToAbsent || page != null) {
      map['page'] = Variable<int>(page);
    }
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    if (!nullToAbsent || snippet != null) {
      map['snippet'] = Variable<String>(snippet);
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    return map;
  }

  FieldEvidenceCompanion toCompanion(bool nullToAbsent) {
    return FieldEvidenceCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      recordFieldId: Value(recordFieldId),
      sourceType: Value(sourceType),
      photoId: photoId == null && nullToAbsent
          ? const Value.absent()
          : Value(photoId),
      documentId: documentId == null && nullToAbsent
          ? const Value.absent()
          : Value(documentId),
      page: page == null && nullToAbsent ? const Value.absent() : Value(page),
      region: region == null && nullToAbsent
          ? const Value.absent()
          : Value(region),
      snippet: snippet == null && nullToAbsent
          ? const Value.absent()
          : Value(snippet),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
    );
  }

  factory FieldEvidenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FieldEvidenceRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      recordFieldId: serializer.fromJson<String>(json['recordFieldId']),
      sourceType: $FieldEvidenceTable.$convertersourceType.fromJson(
        serializer.fromJson<String>(json['sourceType']),
      ),
      photoId: serializer.fromJson<String?>(json['photoId']),
      documentId: serializer.fromJson<String?>(json['documentId']),
      page: serializer.fromJson<int?>(json['page']),
      region: serializer.fromJson<String?>(json['region']),
      snippet: serializer.fromJson<String?>(json['snippet']),
      confidence: serializer.fromJson<double?>(json['confidence']),
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
      'recordFieldId': serializer.toJson<String>(recordFieldId),
      'sourceType': serializer.toJson<String>(
        $FieldEvidenceTable.$convertersourceType.toJson(sourceType),
      ),
      'photoId': serializer.toJson<String?>(photoId),
      'documentId': serializer.toJson<String?>(documentId),
      'page': serializer.toJson<int?>(page),
      'region': serializer.toJson<String?>(region),
      'snippet': serializer.toJson<String?>(snippet),
      'confidence': serializer.toJson<double?>(confidence),
    };
  }

  FieldEvidenceRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? recordFieldId,
    FieldEvidenceSource? sourceType,
    Value<String?> photoId = const Value.absent(),
    Value<String?> documentId = const Value.absent(),
    Value<int?> page = const Value.absent(),
    Value<String?> region = const Value.absent(),
    Value<String?> snippet = const Value.absent(),
    Value<double?> confidence = const Value.absent(),
  }) => FieldEvidenceRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    recordFieldId: recordFieldId ?? this.recordFieldId,
    sourceType: sourceType ?? this.sourceType,
    photoId: photoId.present ? photoId.value : this.photoId,
    documentId: documentId.present ? documentId.value : this.documentId,
    page: page.present ? page.value : this.page,
    region: region.present ? region.value : this.region,
    snippet: snippet.present ? snippet.value : this.snippet,
    confidence: confidence.present ? confidence.value : this.confidence,
  );
  FieldEvidenceRow copyWithCompanion(FieldEvidenceCompanion data) {
    return FieldEvidenceRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      recordFieldId: data.recordFieldId.present
          ? data.recordFieldId.value
          : this.recordFieldId,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      page: data.page.present ? data.page.value : this.page,
      region: data.region.present ? data.region.value : this.region,
      snippet: data.snippet.present ? data.snippet.value : this.snippet,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FieldEvidenceRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('recordFieldId: $recordFieldId, ')
          ..write('sourceType: $sourceType, ')
          ..write('photoId: $photoId, ')
          ..write('documentId: $documentId, ')
          ..write('page: $page, ')
          ..write('region: $region, ')
          ..write('snippet: $snippet, ')
          ..write('confidence: $confidence')
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
    recordFieldId,
    sourceType,
    photoId,
    documentId,
    page,
    region,
    snippet,
    confidence,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FieldEvidenceRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.recordFieldId == this.recordFieldId &&
          other.sourceType == this.sourceType &&
          other.photoId == this.photoId &&
          other.documentId == this.documentId &&
          other.page == this.page &&
          other.region == this.region &&
          other.snippet == this.snippet &&
          other.confidence == this.confidence);
}

class FieldEvidenceCompanion extends UpdateCompanion<FieldEvidenceRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> recordFieldId;
  final Value<FieldEvidenceSource> sourceType;
  final Value<String?> photoId;
  final Value<String?> documentId;
  final Value<int?> page;
  final Value<String?> region;
  final Value<String?> snippet;
  final Value<double?> confidence;
  final Value<int> rowid;
  const FieldEvidenceCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.recordFieldId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.photoId = const Value.absent(),
    this.documentId = const Value.absent(),
    this.page = const Value.absent(),
    this.region = const Value.absent(),
    this.snippet = const Value.absent(),
    this.confidence = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FieldEvidenceCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String recordFieldId,
    required FieldEvidenceSource sourceType,
    this.photoId = const Value.absent(),
    this.documentId = const Value.absent(),
    this.page = const Value.absent(),
    this.region = const Value.absent(),
    this.snippet = const Value.absent(),
    this.confidence = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       recordFieldId = Value(recordFieldId),
       sourceType = Value(sourceType);
  static Insertable<FieldEvidenceRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? recordFieldId,
    Expression<String>? sourceType,
    Expression<String>? photoId,
    Expression<String>? documentId,
    Expression<int>? page,
    Expression<String>? region,
    Expression<String>? snippet,
    Expression<double>? confidence,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (recordFieldId != null) 'record_field_id': recordFieldId,
      if (sourceType != null) 'source_type': sourceType,
      if (photoId != null) 'photo_id': photoId,
      if (documentId != null) 'document_id': documentId,
      if (page != null) 'page': page,
      if (region != null) 'region': region,
      if (snippet != null) 'snippet': snippet,
      if (confidence != null) 'confidence': confidence,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FieldEvidenceCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? recordFieldId,
    Value<FieldEvidenceSource>? sourceType,
    Value<String?>? photoId,
    Value<String?>? documentId,
    Value<int?>? page,
    Value<String?>? region,
    Value<String?>? snippet,
    Value<double?>? confidence,
    Value<int>? rowid,
  }) {
    return FieldEvidenceCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      recordFieldId: recordFieldId ?? this.recordFieldId,
      sourceType: sourceType ?? this.sourceType,
      photoId: photoId ?? this.photoId,
      documentId: documentId ?? this.documentId,
      page: page ?? this.page,
      region: region ?? this.region,
      snippet: snippet ?? this.snippet,
      confidence: confidence ?? this.confidence,
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
    if (recordFieldId.present) {
      map['record_field_id'] = Variable<String>(recordFieldId.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(
        $FieldEvidenceTable.$convertersourceType.toSql(sourceType.value),
      );
    }
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (snippet.present) {
      map['snippet'] = Variable<String>(snippet.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FieldEvidenceCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('recordFieldId: $recordFieldId, ')
          ..write('sourceType: $sourceType, ')
          ..write('photoId: $photoId, ')
          ..write('documentId: $documentId, ')
          ..write('page: $page, ')
          ..write('region: $region, ')
          ..write('snippet: $snippet, ')
          ..write('confidence: $confidence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DuplicatesTable extends Duplicates
    with TableInfo<$DuplicatesTable, DuplicatePair> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DuplicatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _leftRecordIdMeta = const VerificationMeta(
    'leftRecordId',
  );
  @override
  late final GeneratedColumn<String> leftRecordId = GeneratedColumn<String>(
    'left_record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rightRecordIdMeta = const VerificationMeta(
    'rightRecordId',
  );
  @override
  late final GeneratedColumn<String> rightRecordId = GeneratedColumn<String>(
    'right_record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signalMeta = const VerificationMeta('signal');
  @override
  late final GeneratedColumn<String> signal = GeneratedColumn<String>(
    'signal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DuplicatePairStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DuplicatePairStatus>($DuplicatesTable.$converterstatus);
  static const VerificationMeta _resolutionMeta = const VerificationMeta(
    'resolution',
  );
  @override
  late final GeneratedColumn<String> resolution = GeneratedColumn<String>(
    'resolution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedByMeta = const VerificationMeta(
    'resolvedBy',
  );
  @override
  late final GeneratedColumn<String> resolvedBy = GeneratedColumn<String>(
    'resolved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
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
    projectId,
    leftRecordId,
    rightRecordId,
    signal,
    score,
    status,
    resolution,
    resolvedBy,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'duplicates';
  @override
  VerificationContext validateIntegrity(
    Insertable<DuplicatePair> instance, {
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
    if (data.containsKey('left_record_id')) {
      context.handle(
        _leftRecordIdMeta,
        leftRecordId.isAcceptableOrUnknown(
          data['left_record_id']!,
          _leftRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_leftRecordIdMeta);
    }
    if (data.containsKey('right_record_id')) {
      context.handle(
        _rightRecordIdMeta,
        rightRecordId.isAcceptableOrUnknown(
          data['right_record_id']!,
          _rightRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rightRecordIdMeta);
    }
    if (data.containsKey('signal')) {
      context.handle(
        _signalMeta,
        signal.isAcceptableOrUnknown(data['signal']!, _signalMeta),
      );
    } else if (isInserting) {
      context.missing(_signalMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('resolution')) {
      context.handle(
        _resolutionMeta,
        resolution.isAcceptableOrUnknown(data['resolution']!, _resolutionMeta),
      );
    }
    if (data.containsKey('resolved_by')) {
      context.handle(
        _resolvedByMeta,
        resolvedBy.isAcceptableOrUnknown(data['resolved_by']!, _resolvedByMeta),
      );
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DuplicatePair map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DuplicatePair(
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
      leftRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}left_record_id'],
      )!,
      rightRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}right_record_id'],
      )!,
      signal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signal'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      status: $DuplicatesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      resolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution'],
      ),
      resolvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_by'],
      ),
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $DuplicatesTable createAlias(String alias) {
    return $DuplicatesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DuplicatePairStatus, String, String>
  $converterstatus = const EnumNameConverter<DuplicatePairStatus>(
    DuplicatePairStatus.values,
  );
}

class DuplicatePair extends DataClass implements Insertable<DuplicatePair> {
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

  /// Project both records belong to.
  final String projectId;

  /// Lower record id of the ordered pair.
  final String leftRecordId;

  /// Higher record id of the ordered pair.
  final String rightRecordId;

  /// Detection signal that ranked this pair, stored as data.
  final String signal;

  /// Combined score from detection. A proposal, never a decision.
  final double score;

  /// unresolved or resolved. The review list filters on this column.
  final DuplicatePairStatus status;

  /// Human choice. Null until a person resolves the pair.
  final String? resolution;

  /// Operator who resolved it.
  final String? resolvedBy;

  /// When it was resolved.
  final DateTime? resolvedAt;
  const DuplicatePair({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.projectId,
    required this.leftRecordId,
    required this.rightRecordId,
    required this.signal,
    required this.score,
    required this.status,
    this.resolution,
    this.resolvedBy,
    this.resolvedAt,
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
    map['left_record_id'] = Variable<String>(leftRecordId);
    map['right_record_id'] = Variable<String>(rightRecordId);
    map['signal'] = Variable<String>(signal);
    map['score'] = Variable<double>(score);
    {
      map['status'] = Variable<String>(
        $DuplicatesTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || resolution != null) {
      map['resolution'] = Variable<String>(resolution);
    }
    if (!nullToAbsent || resolvedBy != null) {
      map['resolved_by'] = Variable<String>(resolvedBy);
    }
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    return map;
  }

  DuplicatesCompanion toCompanion(bool nullToAbsent) {
    return DuplicatesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      projectId: Value(projectId),
      leftRecordId: Value(leftRecordId),
      rightRecordId: Value(rightRecordId),
      signal: Value(signal),
      score: Value(score),
      status: Value(status),
      resolution: resolution == null && nullToAbsent
          ? const Value.absent()
          : Value(resolution),
      resolvedBy: resolvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedBy),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory DuplicatePair.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DuplicatePair(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      projectId: serializer.fromJson<String>(json['projectId']),
      leftRecordId: serializer.fromJson<String>(json['leftRecordId']),
      rightRecordId: serializer.fromJson<String>(json['rightRecordId']),
      signal: serializer.fromJson<String>(json['signal']),
      score: serializer.fromJson<double>(json['score']),
      status: $DuplicatesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      resolution: serializer.fromJson<String?>(json['resolution']),
      resolvedBy: serializer.fromJson<String?>(json['resolvedBy']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
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
      'leftRecordId': serializer.toJson<String>(leftRecordId),
      'rightRecordId': serializer.toJson<String>(rightRecordId),
      'signal': serializer.toJson<String>(signal),
      'score': serializer.toJson<double>(score),
      'status': serializer.toJson<String>(
        $DuplicatesTable.$converterstatus.toJson(status),
      ),
      'resolution': serializer.toJson<String?>(resolution),
      'resolvedBy': serializer.toJson<String?>(resolvedBy),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
    };
  }

  DuplicatePair copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? projectId,
    String? leftRecordId,
    String? rightRecordId,
    String? signal,
    double? score,
    DuplicatePairStatus? status,
    Value<String?> resolution = const Value.absent(),
    Value<String?> resolvedBy = const Value.absent(),
    Value<DateTime?> resolvedAt = const Value.absent(),
  }) => DuplicatePair(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    projectId: projectId ?? this.projectId,
    leftRecordId: leftRecordId ?? this.leftRecordId,
    rightRecordId: rightRecordId ?? this.rightRecordId,
    signal: signal ?? this.signal,
    score: score ?? this.score,
    status: status ?? this.status,
    resolution: resolution.present ? resolution.value : this.resolution,
    resolvedBy: resolvedBy.present ? resolvedBy.value : this.resolvedBy,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  DuplicatePair copyWithCompanion(DuplicatesCompanion data) {
    return DuplicatePair(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      leftRecordId: data.leftRecordId.present
          ? data.leftRecordId.value
          : this.leftRecordId,
      rightRecordId: data.rightRecordId.present
          ? data.rightRecordId.value
          : this.rightRecordId,
      signal: data.signal.present ? data.signal.value : this.signal,
      score: data.score.present ? data.score.value : this.score,
      status: data.status.present ? data.status.value : this.status,
      resolution: data.resolution.present
          ? data.resolution.value
          : this.resolution,
      resolvedBy: data.resolvedBy.present
          ? data.resolvedBy.value
          : this.resolvedBy,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DuplicatePair(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('leftRecordId: $leftRecordId, ')
          ..write('rightRecordId: $rightRecordId, ')
          ..write('signal: $signal, ')
          ..write('score: $score, ')
          ..write('status: $status, ')
          ..write('resolution: $resolution, ')
          ..write('resolvedBy: $resolvedBy, ')
          ..write('resolvedAt: $resolvedAt')
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
    leftRecordId,
    rightRecordId,
    signal,
    score,
    status,
    resolution,
    resolvedBy,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DuplicatePair &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.projectId == this.projectId &&
          other.leftRecordId == this.leftRecordId &&
          other.rightRecordId == this.rightRecordId &&
          other.signal == this.signal &&
          other.score == this.score &&
          other.status == this.status &&
          other.resolution == this.resolution &&
          other.resolvedBy == this.resolvedBy &&
          other.resolvedAt == this.resolvedAt);
}

class DuplicatesCompanion extends UpdateCompanion<DuplicatePair> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> projectId;
  final Value<String> leftRecordId;
  final Value<String> rightRecordId;
  final Value<String> signal;
  final Value<double> score;
  final Value<DuplicatePairStatus> status;
  final Value<String?> resolution;
  final Value<String?> resolvedBy;
  final Value<DateTime?> resolvedAt;
  final Value<int> rowid;
  const DuplicatesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.projectId = const Value.absent(),
    this.leftRecordId = const Value.absent(),
    this.rightRecordId = const Value.absent(),
    this.signal = const Value.absent(),
    this.score = const Value.absent(),
    this.status = const Value.absent(),
    this.resolution = const Value.absent(),
    this.resolvedBy = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DuplicatesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String projectId,
    required String leftRecordId,
    required String rightRecordId,
    required String signal,
    required double score,
    required DuplicatePairStatus status,
    this.resolution = const Value.absent(),
    this.resolvedBy = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       projectId = Value(projectId),
       leftRecordId = Value(leftRecordId),
       rightRecordId = Value(rightRecordId),
       signal = Value(signal),
       score = Value(score),
       status = Value(status);
  static Insertable<DuplicatePair> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? projectId,
    Expression<String>? leftRecordId,
    Expression<String>? rightRecordId,
    Expression<String>? signal,
    Expression<double>? score,
    Expression<String>? status,
    Expression<String>? resolution,
    Expression<String>? resolvedBy,
    Expression<DateTime>? resolvedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (projectId != null) 'project_id': projectId,
      if (leftRecordId != null) 'left_record_id': leftRecordId,
      if (rightRecordId != null) 'right_record_id': rightRecordId,
      if (signal != null) 'signal': signal,
      if (score != null) 'score': score,
      if (status != null) 'status': status,
      if (resolution != null) 'resolution': resolution,
      if (resolvedBy != null) 'resolved_by': resolvedBy,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DuplicatesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? projectId,
    Value<String>? leftRecordId,
    Value<String>? rightRecordId,
    Value<String>? signal,
    Value<double>? score,
    Value<DuplicatePairStatus>? status,
    Value<String?>? resolution,
    Value<String?>? resolvedBy,
    Value<DateTime?>? resolvedAt,
    Value<int>? rowid,
  }) {
    return DuplicatesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      projectId: projectId ?? this.projectId,
      leftRecordId: leftRecordId ?? this.leftRecordId,
      rightRecordId: rightRecordId ?? this.rightRecordId,
      signal: signal ?? this.signal,
      score: score ?? this.score,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
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
    if (leftRecordId.present) {
      map['left_record_id'] = Variable<String>(leftRecordId.value);
    }
    if (rightRecordId.present) {
      map['right_record_id'] = Variable<String>(rightRecordId.value);
    }
    if (signal.present) {
      map['signal'] = Variable<String>(signal.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $DuplicatesTable.$converterstatus.toSql(status.value),
      );
    }
    if (resolution.present) {
      map['resolution'] = Variable<String>(resolution.value);
    }
    if (resolvedBy.present) {
      map['resolved_by'] = Variable<String>(resolvedBy.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DuplicatesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('leftRecordId: $leftRecordId, ')
          ..write('rightRecordId: $rightRecordId, ')
          ..write('signal: $signal, ')
          ..write('score: $score, ')
          ..write('status: $status, ')
          ..write('resolution: $resolution, ')
          ..write('resolvedBy: $resolvedBy, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VariancesTable extends Variances
    with TableInfo<$VariancesTable, Variance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VariancesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _registerValueMeta = const VerificationMeta(
    'registerValue',
  );
  @override
  late final GeneratedColumn<String> registerValue = GeneratedColumn<String>(
    'register_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _foundValueMeta = const VerificationMeta(
    'foundValue',
  );
  @override
  late final GeneratedColumn<String> foundValue = GeneratedColumn<String>(
    'found_value',
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
  static const VerificationMeta _resolvedByMeta = const VerificationMeta(
    'resolvedBy',
  );
  @override
  late final GeneratedColumn<String> resolvedBy = GeneratedColumn<String>(
    'resolved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
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
    projectId,
    recordId,
    fieldKey,
    registerValue,
    foundValue,
    status,
    resolvedBy,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'variances';
  @override
  VerificationContext validateIntegrity(
    Insertable<Variance> instance, {
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
    if (data.containsKey('register_value')) {
      context.handle(
        _registerValueMeta,
        registerValue.isAcceptableOrUnknown(
          data['register_value']!,
          _registerValueMeta,
        ),
      );
    }
    if (data.containsKey('found_value')) {
      context.handle(
        _foundValueMeta,
        foundValue.isAcceptableOrUnknown(data['found_value']!, _foundValueMeta),
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
    if (data.containsKey('resolved_by')) {
      context.handle(
        _resolvedByMeta,
        resolvedBy.isAcceptableOrUnknown(data['resolved_by']!, _resolvedByMeta),
      );
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Variance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Variance(
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
      )!,
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      )!,
      registerValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}register_value'],
      ),
      foundValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}found_value'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      resolvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_by'],
      ),
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $VariancesTable createAlias(String alias) {
    return $VariancesTable(attachedDatabase, alias);
  }
}

class Variance extends DataClass implements Insertable<Variance> {
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

  /// Project this variance belongs to. The review list filters on it.
  final String projectId;

  /// Record the two values were taken from.
  final String recordId;

  /// Template field key that differs.
  final String fieldKey;

  /// Value as recorded, stored as data.
  final String? registerValue;

  /// Value as found, stored as data.
  final String? foundValue;

  /// Queue or classification status, stored as text.
  final String status;

  /// Operator who resolved it.
  final String? resolvedBy;

  /// When it was resolved.
  final DateTime? resolvedAt;
  const Variance({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.projectId,
    required this.recordId,
    required this.fieldKey,
    this.registerValue,
    this.foundValue,
    required this.status,
    this.resolvedBy,
    this.resolvedAt,
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
    map['record_id'] = Variable<String>(recordId);
    map['field_key'] = Variable<String>(fieldKey);
    if (!nullToAbsent || registerValue != null) {
      map['register_value'] = Variable<String>(registerValue);
    }
    if (!nullToAbsent || foundValue != null) {
      map['found_value'] = Variable<String>(foundValue);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || resolvedBy != null) {
      map['resolved_by'] = Variable<String>(resolvedBy);
    }
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    return map;
  }

  VariancesCompanion toCompanion(bool nullToAbsent) {
    return VariancesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      projectId: Value(projectId),
      recordId: Value(recordId),
      fieldKey: Value(fieldKey),
      registerValue: registerValue == null && nullToAbsent
          ? const Value.absent()
          : Value(registerValue),
      foundValue: foundValue == null && nullToAbsent
          ? const Value.absent()
          : Value(foundValue),
      status: Value(status),
      resolvedBy: resolvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedBy),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory Variance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Variance(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      projectId: serializer.fromJson<String>(json['projectId']),
      recordId: serializer.fromJson<String>(json['recordId']),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      registerValue: serializer.fromJson<String?>(json['registerValue']),
      foundValue: serializer.fromJson<String?>(json['foundValue']),
      status: serializer.fromJson<String>(json['status']),
      resolvedBy: serializer.fromJson<String?>(json['resolvedBy']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
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
      'recordId': serializer.toJson<String>(recordId),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'registerValue': serializer.toJson<String?>(registerValue),
      'foundValue': serializer.toJson<String?>(foundValue),
      'status': serializer.toJson<String>(status),
      'resolvedBy': serializer.toJson<String?>(resolvedBy),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
    };
  }

  Variance copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? projectId,
    String? recordId,
    String? fieldKey,
    Value<String?> registerValue = const Value.absent(),
    Value<String?> foundValue = const Value.absent(),
    String? status,
    Value<String?> resolvedBy = const Value.absent(),
    Value<DateTime?> resolvedAt = const Value.absent(),
  }) => Variance(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    projectId: projectId ?? this.projectId,
    recordId: recordId ?? this.recordId,
    fieldKey: fieldKey ?? this.fieldKey,
    registerValue: registerValue.present
        ? registerValue.value
        : this.registerValue,
    foundValue: foundValue.present ? foundValue.value : this.foundValue,
    status: status ?? this.status,
    resolvedBy: resolvedBy.present ? resolvedBy.value : this.resolvedBy,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  Variance copyWithCompanion(VariancesCompanion data) {
    return Variance(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      registerValue: data.registerValue.present
          ? data.registerValue.value
          : this.registerValue,
      foundValue: data.foundValue.present
          ? data.foundValue.value
          : this.foundValue,
      status: data.status.present ? data.status.value : this.status,
      resolvedBy: data.resolvedBy.present
          ? data.resolvedBy.value
          : this.resolvedBy,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Variance(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('recordId: $recordId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('registerValue: $registerValue, ')
          ..write('foundValue: $foundValue, ')
          ..write('status: $status, ')
          ..write('resolvedBy: $resolvedBy, ')
          ..write('resolvedAt: $resolvedAt')
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
    recordId,
    fieldKey,
    registerValue,
    foundValue,
    status,
    resolvedBy,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Variance &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.projectId == this.projectId &&
          other.recordId == this.recordId &&
          other.fieldKey == this.fieldKey &&
          other.registerValue == this.registerValue &&
          other.foundValue == this.foundValue &&
          other.status == this.status &&
          other.resolvedBy == this.resolvedBy &&
          other.resolvedAt == this.resolvedAt);
}

class VariancesCompanion extends UpdateCompanion<Variance> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> projectId;
  final Value<String> recordId;
  final Value<String> fieldKey;
  final Value<String?> registerValue;
  final Value<String?> foundValue;
  final Value<String> status;
  final Value<String?> resolvedBy;
  final Value<DateTime?> resolvedAt;
  final Value<int> rowid;
  const VariancesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.projectId = const Value.absent(),
    this.recordId = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.registerValue = const Value.absent(),
    this.foundValue = const Value.absent(),
    this.status = const Value.absent(),
    this.resolvedBy = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VariancesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String projectId,
    required String recordId,
    required String fieldKey,
    this.registerValue = const Value.absent(),
    this.foundValue = const Value.absent(),
    required String status,
    this.resolvedBy = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       projectId = Value(projectId),
       recordId = Value(recordId),
       fieldKey = Value(fieldKey),
       status = Value(status);
  static Insertable<Variance> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? projectId,
    Expression<String>? recordId,
    Expression<String>? fieldKey,
    Expression<String>? registerValue,
    Expression<String>? foundValue,
    Expression<String>? status,
    Expression<String>? resolvedBy,
    Expression<DateTime>? resolvedAt,
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
      if (fieldKey != null) 'field_key': fieldKey,
      if (registerValue != null) 'register_value': registerValue,
      if (foundValue != null) 'found_value': foundValue,
      if (status != null) 'status': status,
      if (resolvedBy != null) 'resolved_by': resolvedBy,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VariancesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? projectId,
    Value<String>? recordId,
    Value<String>? fieldKey,
    Value<String?>? registerValue,
    Value<String?>? foundValue,
    Value<String>? status,
    Value<String?>? resolvedBy,
    Value<DateTime?>? resolvedAt,
    Value<int>? rowid,
  }) {
    return VariancesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      projectId: projectId ?? this.projectId,
      recordId: recordId ?? this.recordId,
      fieldKey: fieldKey ?? this.fieldKey,
      registerValue: registerValue ?? this.registerValue,
      foundValue: foundValue ?? this.foundValue,
      status: status ?? this.status,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
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
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (registerValue.present) {
      map['register_value'] = Variable<String>(registerValue.value);
    }
    if (foundValue.present) {
      map['found_value'] = Variable<String>(foundValue.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (resolvedBy.present) {
      map['resolved_by'] = Variable<String>(resolvedBy.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VariancesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('recordId: $recordId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('registerValue: $registerValue, ')
          ..write('foundValue: $foundValue, ')
          ..write('status: $status, ')
          ..write('resolvedBy: $resolvedBy, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeetingsTable extends Meetings
    with TableInfo<$MeetingsTable, MeetingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeetingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<DateTime> startAt = GeneratedColumn<DateTime>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<DateTime> endAt = GeneratedColumn<DateTime>(
    'end_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chairMeta = const VerificationMeta('chair');
  @override
  late final GeneratedColumn<String> chair = GeneratedColumn<String>(
    'chair',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _secretaryMeta = const VerificationMeta(
    'secretary',
  );
  @override
  late final GeneratedColumn<String> secretary = GeneratedColumn<String>(
    'secretary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _agendaMeta = const VerificationMeta('agenda');
  @override
  late final GeneratedColumn<String> agenda = GeneratedColumn<String>(
    'agenda',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transcriptRawMeta = const VerificationMeta(
    'transcriptRaw',
  );
  @override
  late final GeneratedColumn<String> transcriptRaw = GeneratedColumn<String>(
    'transcript_raw',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesRefinedMeta = const VerificationMeta(
    'minutesRefined',
  );
  @override
  late final GeneratedColumn<String> minutesRefined = GeneratedColumn<String>(
    'minutes_refined',
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
    recordId,
    title,
    startAt,
    endAt,
    chair,
    secretary,
    agenda,
    transcriptRaw,
    minutesRefined,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meetings';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeetingRow> instance, {
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    }
    if (data.containsKey('chair')) {
      context.handle(
        _chairMeta,
        chair.isAcceptableOrUnknown(data['chair']!, _chairMeta),
      );
    }
    if (data.containsKey('secretary')) {
      context.handle(
        _secretaryMeta,
        secretary.isAcceptableOrUnknown(data['secretary']!, _secretaryMeta),
      );
    }
    if (data.containsKey('agenda')) {
      context.handle(
        _agendaMeta,
        agenda.isAcceptableOrUnknown(data['agenda']!, _agendaMeta),
      );
    } else if (isInserting) {
      context.missing(_agendaMeta);
    }
    if (data.containsKey('transcript_raw')) {
      context.handle(
        _transcriptRawMeta,
        transcriptRaw.isAcceptableOrUnknown(
          data['transcript_raw']!,
          _transcriptRawMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transcriptRawMeta);
    }
    if (data.containsKey('minutes_refined')) {
      context.handle(
        _minutesRefinedMeta,
        minutesRefined.isAcceptableOrUnknown(
          data['minutes_refined']!,
          _minutesRefinedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeetingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeetingRow(
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
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at'],
      )!,
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at'],
      ),
      chair: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chair'],
      )!,
      secretary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secretary'],
      )!,
      agenda: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agenda'],
      )!,
      transcriptRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcript_raw'],
      )!,
      minutesRefined: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}minutes_refined'],
      ),
    );
  }

  @override
  $MeetingsTable createAlias(String alias) {
    return $MeetingsTable(attachedDatabase, alias);
  }
}

class MeetingRow extends DataClass implements Insertable<MeetingRow> {
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

  /// Record this meeting is filed on.
  final String recordId;

  /// Operator-facing title, stored as data.
  final String title;

  /// When the meeting started.
  final DateTime startAt;

  /// When the meeting ended, if it has.
  final DateTime? endAt;

  /// Chair as captured, stored as data.
  final String chair;

  /// Secretary as captured, stored as data.
  final String secretary;

  /// Agenda items JSON. An array, stored as text.
  final String agenda;

  /// Verbatim transcript. Written once at insert, never updated.
  final String transcriptRaw;

  /// Refined minutes written beside the transcript, never over it.
  final String? minutesRefined;
  const MeetingRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.recordId,
    required this.title,
    required this.startAt,
    this.endAt,
    required this.chair,
    required this.secretary,
    required this.agenda,
    required this.transcriptRaw,
    this.minutesRefined,
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
    map['title'] = Variable<String>(title);
    map['start_at'] = Variable<DateTime>(startAt);
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<DateTime>(endAt);
    }
    map['chair'] = Variable<String>(chair);
    map['secretary'] = Variable<String>(secretary);
    map['agenda'] = Variable<String>(agenda);
    map['transcript_raw'] = Variable<String>(transcriptRaw);
    if (!nullToAbsent || minutesRefined != null) {
      map['minutes_refined'] = Variable<String>(minutesRefined);
    }
    return map;
  }

  MeetingsCompanion toCompanion(bool nullToAbsent) {
    return MeetingsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      recordId: Value(recordId),
      title: Value(title),
      startAt: Value(startAt),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      chair: Value(chair),
      secretary: Value(secretary),
      agenda: Value(agenda),
      transcriptRaw: Value(transcriptRaw),
      minutesRefined: minutesRefined == null && nullToAbsent
          ? const Value.absent()
          : Value(minutesRefined),
    );
  }

  factory MeetingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeetingRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      recordId: serializer.fromJson<String>(json['recordId']),
      title: serializer.fromJson<String>(json['title']),
      startAt: serializer.fromJson<DateTime>(json['startAt']),
      endAt: serializer.fromJson<DateTime?>(json['endAt']),
      chair: serializer.fromJson<String>(json['chair']),
      secretary: serializer.fromJson<String>(json['secretary']),
      agenda: serializer.fromJson<String>(json['agenda']),
      transcriptRaw: serializer.fromJson<String>(json['transcriptRaw']),
      minutesRefined: serializer.fromJson<String?>(json['minutesRefined']),
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
      'title': serializer.toJson<String>(title),
      'startAt': serializer.toJson<DateTime>(startAt),
      'endAt': serializer.toJson<DateTime?>(endAt),
      'chair': serializer.toJson<String>(chair),
      'secretary': serializer.toJson<String>(secretary),
      'agenda': serializer.toJson<String>(agenda),
      'transcriptRaw': serializer.toJson<String>(transcriptRaw),
      'minutesRefined': serializer.toJson<String?>(minutesRefined),
    };
  }

  MeetingRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? recordId,
    String? title,
    DateTime? startAt,
    Value<DateTime?> endAt = const Value.absent(),
    String? chair,
    String? secretary,
    String? agenda,
    String? transcriptRaw,
    Value<String?> minutesRefined = const Value.absent(),
  }) => MeetingRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    recordId: recordId ?? this.recordId,
    title: title ?? this.title,
    startAt: startAt ?? this.startAt,
    endAt: endAt.present ? endAt.value : this.endAt,
    chair: chair ?? this.chair,
    secretary: secretary ?? this.secretary,
    agenda: agenda ?? this.agenda,
    transcriptRaw: transcriptRaw ?? this.transcriptRaw,
    minutesRefined: minutesRefined.present
        ? minutesRefined.value
        : this.minutesRefined,
  );
  MeetingRow copyWithCompanion(MeetingsCompanion data) {
    return MeetingRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      title: data.title.present ? data.title.value : this.title,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      chair: data.chair.present ? data.chair.value : this.chair,
      secretary: data.secretary.present ? data.secretary.value : this.secretary,
      agenda: data.agenda.present ? data.agenda.value : this.agenda,
      transcriptRaw: data.transcriptRaw.present
          ? data.transcriptRaw.value
          : this.transcriptRaw,
      minutesRefined: data.minutesRefined.present
          ? data.minutesRefined.value
          : this.minutesRefined,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeetingRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('recordId: $recordId, ')
          ..write('title: $title, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('chair: $chair, ')
          ..write('secretary: $secretary, ')
          ..write('agenda: $agenda, ')
          ..write('transcriptRaw: $transcriptRaw, ')
          ..write('minutesRefined: $minutesRefined')
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
    title,
    startAt,
    endAt,
    chair,
    secretary,
    agenda,
    transcriptRaw,
    minutesRefined,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeetingRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.recordId == this.recordId &&
          other.title == this.title &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.chair == this.chair &&
          other.secretary == this.secretary &&
          other.agenda == this.agenda &&
          other.transcriptRaw == this.transcriptRaw &&
          other.minutesRefined == this.minutesRefined);
}

class MeetingsCompanion extends UpdateCompanion<MeetingRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> recordId;
  final Value<String> title;
  final Value<DateTime> startAt;
  final Value<DateTime?> endAt;
  final Value<String> chair;
  final Value<String> secretary;
  final Value<String> agenda;
  final Value<String> transcriptRaw;
  final Value<String?> minutesRefined;
  final Value<int> rowid;
  const MeetingsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.recordId = const Value.absent(),
    this.title = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.chair = const Value.absent(),
    this.secretary = const Value.absent(),
    this.agenda = const Value.absent(),
    this.transcriptRaw = const Value.absent(),
    this.minutesRefined = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeetingsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String recordId,
    required String title,
    required DateTime startAt,
    this.endAt = const Value.absent(),
    this.chair = const Value.absent(),
    this.secretary = const Value.absent(),
    required String agenda,
    required String transcriptRaw,
    this.minutesRefined = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       recordId = Value(recordId),
       title = Value(title),
       startAt = Value(startAt),
       agenda = Value(agenda),
       transcriptRaw = Value(transcriptRaw);
  static Insertable<MeetingRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? recordId,
    Expression<String>? title,
    Expression<DateTime>? startAt,
    Expression<DateTime>? endAt,
    Expression<String>? chair,
    Expression<String>? secretary,
    Expression<String>? agenda,
    Expression<String>? transcriptRaw,
    Expression<String>? minutesRefined,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (recordId != null) 'record_id': recordId,
      if (title != null) 'title': title,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (chair != null) 'chair': chair,
      if (secretary != null) 'secretary': secretary,
      if (agenda != null) 'agenda': agenda,
      if (transcriptRaw != null) 'transcript_raw': transcriptRaw,
      if (minutesRefined != null) 'minutes_refined': minutesRefined,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeetingsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? recordId,
    Value<String>? title,
    Value<DateTime>? startAt,
    Value<DateTime?>? endAt,
    Value<String>? chair,
    Value<String>? secretary,
    Value<String>? agenda,
    Value<String>? transcriptRaw,
    Value<String?>? minutesRefined,
    Value<int>? rowid,
  }) {
    return MeetingsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      recordId: recordId ?? this.recordId,
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      chair: chair ?? this.chair,
      secretary: secretary ?? this.secretary,
      agenda: agenda ?? this.agenda,
      transcriptRaw: transcriptRaw ?? this.transcriptRaw,
      minutesRefined: minutesRefined ?? this.minutesRefined,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<DateTime>(endAt.value);
    }
    if (chair.present) {
      map['chair'] = Variable<String>(chair.value);
    }
    if (secretary.present) {
      map['secretary'] = Variable<String>(secretary.value);
    }
    if (agenda.present) {
      map['agenda'] = Variable<String>(agenda.value);
    }
    if (transcriptRaw.present) {
      map['transcript_raw'] = Variable<String>(transcriptRaw.value);
    }
    if (minutesRefined.present) {
      map['minutes_refined'] = Variable<String>(minutesRefined.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeetingsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('recordId: $recordId, ')
          ..write('title: $title, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('chair: $chair, ')
          ..write('secretary: $secretary, ')
          ..write('agenda: $agenda, ')
          ..write('transcriptRaw: $transcriptRaw, ')
          ..write('minutesRefined: $minutesRefined, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendeesTable extends Attendees
    with TableInfo<$AttendeesTable, MeetingAttendee> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendeesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _meetingIdMeta = const VerificationMeta(
    'meetingId',
  );
  @override
  late final GeneratedColumn<String> meetingId = GeneratedColumn<String>(
    'meeting_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _organisationMeta = const VerificationMeta(
    'organisation',
  );
  @override
  late final GeneratedColumn<String> organisation = GeneratedColumn<String>(
    'organisation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contactMeta = const VerificationMeta(
    'contact',
  );
  @override
  late final GeneratedColumn<String> contact = GeneratedColumn<String>(
    'contact',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _signaturePresentMeta = const VerificationMeta(
    'signaturePresent',
  );
  @override
  late final GeneratedColumn<bool> signaturePresent = GeneratedColumn<bool>(
    'signature_present',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("signature_present" IN (0, 1))',
    ),
  );
  static const VerificationMeta _matchedStaffIdMeta = const VerificationMeta(
    'matchedStaffId',
  );
  @override
  late final GeneratedColumn<String> matchedStaffId = GeneratedColumn<String>(
    'matched_staff_id',
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
    meetingId,
    name,
    title,
    organisation,
    contact,
    signaturePresent,
    matchedStaffId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendees';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeetingAttendee> instance, {
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
    if (data.containsKey('meeting_id')) {
      context.handle(
        _meetingIdMeta,
        meetingId.isAcceptableOrUnknown(data['meeting_id']!, _meetingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_meetingIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('organisation')) {
      context.handle(
        _organisationMeta,
        organisation.isAcceptableOrUnknown(
          data['organisation']!,
          _organisationMeta,
        ),
      );
    }
    if (data.containsKey('contact')) {
      context.handle(
        _contactMeta,
        contact.isAcceptableOrUnknown(data['contact']!, _contactMeta),
      );
    }
    if (data.containsKey('signature_present')) {
      context.handle(
        _signaturePresentMeta,
        signaturePresent.isAcceptableOrUnknown(
          data['signature_present']!,
          _signaturePresentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_signaturePresentMeta);
    }
    if (data.containsKey('matched_staff_id')) {
      context.handle(
        _matchedStaffIdMeta,
        matchedStaffId.isAcceptableOrUnknown(
          data['matched_staff_id']!,
          _matchedStaffIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeetingAttendee map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeetingAttendee(
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
      meetingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meeting_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      organisation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organisation'],
      )!,
      contact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact'],
      )!,
      signaturePresent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}signature_present'],
      )!,
      matchedStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matched_staff_id'],
      ),
    );
  }

  @override
  $AttendeesTable createAlias(String alias) {
    return $AttendeesTable(attachedDatabase, alias);
  }
}

class MeetingAttendee extends DataClass implements Insertable<MeetingAttendee> {
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

  /// Meeting this person belongs to.
  final String meetingId;

  /// Name as captured, stored as data. A staff match never overwrites it.
  final String name;

  /// Role or job title as captured, stored as data.
  final String title;

  /// Organisation as captured, stored as data.
  final String organisation;

  /// Contact as captured, stored as data. Personal; never logged.
  final String contact;

  /// Whether a signature was present on the sheet.
  final bool signaturePresent;

  /// Staff dataset row the operator accepted, when they did.
  final String? matchedStaffId;
  const MeetingAttendee({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.meetingId,
    required this.name,
    required this.title,
    required this.organisation,
    required this.contact,
    required this.signaturePresent,
    this.matchedStaffId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['meeting_id'] = Variable<String>(meetingId);
    map['name'] = Variable<String>(name);
    map['title'] = Variable<String>(title);
    map['organisation'] = Variable<String>(organisation);
    map['contact'] = Variable<String>(contact);
    map['signature_present'] = Variable<bool>(signaturePresent);
    if (!nullToAbsent || matchedStaffId != null) {
      map['matched_staff_id'] = Variable<String>(matchedStaffId);
    }
    return map;
  }

  AttendeesCompanion toCompanion(bool nullToAbsent) {
    return AttendeesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      meetingId: Value(meetingId),
      name: Value(name),
      title: Value(title),
      organisation: Value(organisation),
      contact: Value(contact),
      signaturePresent: Value(signaturePresent),
      matchedStaffId: matchedStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedStaffId),
    );
  }

  factory MeetingAttendee.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeetingAttendee(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      meetingId: serializer.fromJson<String>(json['meetingId']),
      name: serializer.fromJson<String>(json['name']),
      title: serializer.fromJson<String>(json['title']),
      organisation: serializer.fromJson<String>(json['organisation']),
      contact: serializer.fromJson<String>(json['contact']),
      signaturePresent: serializer.fromJson<bool>(json['signaturePresent']),
      matchedStaffId: serializer.fromJson<String?>(json['matchedStaffId']),
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
      'meetingId': serializer.toJson<String>(meetingId),
      'name': serializer.toJson<String>(name),
      'title': serializer.toJson<String>(title),
      'organisation': serializer.toJson<String>(organisation),
      'contact': serializer.toJson<String>(contact),
      'signaturePresent': serializer.toJson<bool>(signaturePresent),
      'matchedStaffId': serializer.toJson<String?>(matchedStaffId),
    };
  }

  MeetingAttendee copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? meetingId,
    String? name,
    String? title,
    String? organisation,
    String? contact,
    bool? signaturePresent,
    Value<String?> matchedStaffId = const Value.absent(),
  }) => MeetingAttendee(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    meetingId: meetingId ?? this.meetingId,
    name: name ?? this.name,
    title: title ?? this.title,
    organisation: organisation ?? this.organisation,
    contact: contact ?? this.contact,
    signaturePresent: signaturePresent ?? this.signaturePresent,
    matchedStaffId: matchedStaffId.present
        ? matchedStaffId.value
        : this.matchedStaffId,
  );
  MeetingAttendee copyWithCompanion(AttendeesCompanion data) {
    return MeetingAttendee(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      meetingId: data.meetingId.present ? data.meetingId.value : this.meetingId,
      name: data.name.present ? data.name.value : this.name,
      title: data.title.present ? data.title.value : this.title,
      organisation: data.organisation.present
          ? data.organisation.value
          : this.organisation,
      contact: data.contact.present ? data.contact.value : this.contact,
      signaturePresent: data.signaturePresent.present
          ? data.signaturePresent.value
          : this.signaturePresent,
      matchedStaffId: data.matchedStaffId.present
          ? data.matchedStaffId.value
          : this.matchedStaffId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeetingAttendee(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('meetingId: $meetingId, ')
          ..write('name: $name, ')
          ..write('title: $title, ')
          ..write('organisation: $organisation, ')
          ..write('contact: $contact, ')
          ..write('signaturePresent: $signaturePresent, ')
          ..write('matchedStaffId: $matchedStaffId')
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
    meetingId,
    name,
    title,
    organisation,
    contact,
    signaturePresent,
    matchedStaffId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeetingAttendee &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.meetingId == this.meetingId &&
          other.name == this.name &&
          other.title == this.title &&
          other.organisation == this.organisation &&
          other.contact == this.contact &&
          other.signaturePresent == this.signaturePresent &&
          other.matchedStaffId == this.matchedStaffId);
}

class AttendeesCompanion extends UpdateCompanion<MeetingAttendee> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> meetingId;
  final Value<String> name;
  final Value<String> title;
  final Value<String> organisation;
  final Value<String> contact;
  final Value<bool> signaturePresent;
  final Value<String?> matchedStaffId;
  final Value<int> rowid;
  const AttendeesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.meetingId = const Value.absent(),
    this.name = const Value.absent(),
    this.title = const Value.absent(),
    this.organisation = const Value.absent(),
    this.contact = const Value.absent(),
    this.signaturePresent = const Value.absent(),
    this.matchedStaffId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendeesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String meetingId,
    required String name,
    this.title = const Value.absent(),
    this.organisation = const Value.absent(),
    this.contact = const Value.absent(),
    required bool signaturePresent,
    this.matchedStaffId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       meetingId = Value(meetingId),
       name = Value(name),
       signaturePresent = Value(signaturePresent);
  static Insertable<MeetingAttendee> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? meetingId,
    Expression<String>? name,
    Expression<String>? title,
    Expression<String>? organisation,
    Expression<String>? contact,
    Expression<bool>? signaturePresent,
    Expression<String>? matchedStaffId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (meetingId != null) 'meeting_id': meetingId,
      if (name != null) 'name': name,
      if (title != null) 'title': title,
      if (organisation != null) 'organisation': organisation,
      if (contact != null) 'contact': contact,
      if (signaturePresent != null) 'signature_present': signaturePresent,
      if (matchedStaffId != null) 'matched_staff_id': matchedStaffId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendeesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? meetingId,
    Value<String>? name,
    Value<String>? title,
    Value<String>? organisation,
    Value<String>? contact,
    Value<bool>? signaturePresent,
    Value<String?>? matchedStaffId,
    Value<int>? rowid,
  }) {
    return AttendeesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      meetingId: meetingId ?? this.meetingId,
      name: name ?? this.name,
      title: title ?? this.title,
      organisation: organisation ?? this.organisation,
      contact: contact ?? this.contact,
      signaturePresent: signaturePresent ?? this.signaturePresent,
      matchedStaffId: matchedStaffId ?? this.matchedStaffId,
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
    if (meetingId.present) {
      map['meeting_id'] = Variable<String>(meetingId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (organisation.present) {
      map['organisation'] = Variable<String>(organisation.value);
    }
    if (contact.present) {
      map['contact'] = Variable<String>(contact.value);
    }
    if (signaturePresent.present) {
      map['signature_present'] = Variable<bool>(signaturePresent.value);
    }
    if (matchedStaffId.present) {
      map['matched_staff_id'] = Variable<String>(matchedStaffId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendeesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('meetingId: $meetingId, ')
          ..write('name: $name, ')
          ..write('title: $title, ')
          ..write('organisation: $organisation, ')
          ..write('contact: $contact, ')
          ..write('signaturePresent: $signaturePresent, ')
          ..write('matchedStaffId: $matchedStaffId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeetingActionsTable extends MeetingActions
    with TableInfo<$MeetingActionsTable, MeetingAction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeetingActionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _meetingIdMeta = const VerificationMeta(
    'meetingId',
  );
  @override
  late final GeneratedColumn<String> meetingId = GeneratedColumn<String>(
    'meeting_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerNameMeta = const VerificationMeta(
    'ownerName',
  );
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
    'owner_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedByDevice,
    rev,
    meetingId,
    action,
    ownerName,
    dueDate,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meeting_actions';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeetingAction> instance, {
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
    if (data.containsKey('meeting_id')) {
      context.handle(
        _meetingIdMeta,
        meetingId.isAcceptableOrUnknown(data['meeting_id']!, _meetingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_meetingIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('owner_name')) {
      context.handle(
        _ownerNameMeta,
        ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerNameMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeetingAction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeetingAction(
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
      meetingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meeting_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      ownerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_name'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $MeetingActionsTable createAlias(String alias) {
    return $MeetingActionsTable(attachedDatabase, alias);
  }
}

class MeetingAction extends DataClass implements Insertable<MeetingAction> {
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

  /// Meeting this action belongs to.
  final String meetingId;

  /// Action text as captured, stored as data.
  final String action;

  /// Owner name as captured, stored as data.
  final String ownerName;

  /// When the action is due.
  final DateTime dueDate;

  /// Lifecycle status, stored as text.
  final String status;
  const MeetingAction({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.meetingId,
    required this.action,
    required this.ownerName,
    required this.dueDate,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['meeting_id'] = Variable<String>(meetingId);
    map['action'] = Variable<String>(action);
    map['owner_name'] = Variable<String>(ownerName);
    map['due_date'] = Variable<DateTime>(dueDate);
    map['status'] = Variable<String>(status);
    return map;
  }

  MeetingActionsCompanion toCompanion(bool nullToAbsent) {
    return MeetingActionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      meetingId: Value(meetingId),
      action: Value(action),
      ownerName: Value(ownerName),
      dueDate: Value(dueDate),
      status: Value(status),
    );
  }

  factory MeetingAction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeetingAction(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      meetingId: serializer.fromJson<String>(json['meetingId']),
      action: serializer.fromJson<String>(json['action']),
      ownerName: serializer.fromJson<String>(json['ownerName']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
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
      'meetingId': serializer.toJson<String>(meetingId),
      'action': serializer.toJson<String>(action),
      'ownerName': serializer.toJson<String>(ownerName),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'status': serializer.toJson<String>(status),
    };
  }

  MeetingAction copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? meetingId,
    String? action,
    String? ownerName,
    DateTime? dueDate,
    String? status,
  }) => MeetingAction(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    meetingId: meetingId ?? this.meetingId,
    action: action ?? this.action,
    ownerName: ownerName ?? this.ownerName,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
  );
  MeetingAction copyWithCompanion(MeetingActionsCompanion data) {
    return MeetingAction(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      meetingId: data.meetingId.present ? data.meetingId.value : this.meetingId,
      action: data.action.present ? data.action.value : this.action,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeetingAction(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('meetingId: $meetingId, ')
          ..write('action: $action, ')
          ..write('ownerName: $ownerName, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status')
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
    meetingId,
    action,
    ownerName,
    dueDate,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeetingAction &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.meetingId == this.meetingId &&
          other.action == this.action &&
          other.ownerName == this.ownerName &&
          other.dueDate == this.dueDate &&
          other.status == this.status);
}

class MeetingActionsCompanion extends UpdateCompanion<MeetingAction> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> meetingId;
  final Value<String> action;
  final Value<String> ownerName;
  final Value<DateTime> dueDate;
  final Value<String> status;
  final Value<int> rowid;
  const MeetingActionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.meetingId = const Value.absent(),
    this.action = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeetingActionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String meetingId,
    required String action,
    required String ownerName,
    required DateTime dueDate,
    required String status,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       meetingId = Value(meetingId),
       action = Value(action),
       ownerName = Value(ownerName),
       dueDate = Value(dueDate),
       status = Value(status);
  static Insertable<MeetingAction> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? meetingId,
    Expression<String>? action,
    Expression<String>? ownerName,
    Expression<DateTime>? dueDate,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (meetingId != null) 'meeting_id': meetingId,
      if (action != null) 'action': action,
      if (ownerName != null) 'owner_name': ownerName,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeetingActionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? meetingId,
    Value<String>? action,
    Value<String>? ownerName,
    Value<DateTime>? dueDate,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return MeetingActionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      meetingId: meetingId ?? this.meetingId,
      action: action ?? this.action,
      ownerName: ownerName ?? this.ownerName,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
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
    if (meetingId.present) {
      map['meeting_id'] = Variable<String>(meetingId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeetingActionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('meetingId: $meetingId, ')
          ..write('action: $action, ')
          ..write('ownerName: $ownerName, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExportsTable extends Exports with TableInfo<$ExportsTable, ExportRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExportsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatsMeta = const VerificationMeta(
    'formats',
  );
  @override
  late final GeneratedColumn<String> formats = GeneratedColumn<String>(
    'formats',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filtersMeta = const VerificationMeta(
    'filters',
  );
  @override
  late final GeneratedColumn<String> filters = GeneratedColumn<String>(
    'filters',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordCountMeta = const VerificationMeta(
    'recordCount',
  );
  @override
  late final GeneratedColumn<int> recordCount = GeneratedColumn<int>(
    'record_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
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
    version,
    formats,
    filters,
    recordCount,
    filePath,
    fileHash,
    createdBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exports';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExportRow> instance, {
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('formats')) {
      context.handle(
        _formatsMeta,
        formats.isAcceptableOrUnknown(data['formats']!, _formatsMeta),
      );
    } else if (isInserting) {
      context.missing(_formatsMeta);
    }
    if (data.containsKey('filters')) {
      context.handle(
        _filtersMeta,
        filters.isAcceptableOrUnknown(data['filters']!, _filtersMeta),
      );
    } else if (isInserting) {
      context.missing(_filtersMeta);
    }
    if (data.containsKey('record_count')) {
      context.handle(
        _recordCountMeta,
        recordCount.isAcceptableOrUnknown(
          data['record_count']!,
          _recordCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordCountMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    } else if (isInserting) {
      context.missing(_fileHashMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {projectId, version},
  ];
  @override
  ExportRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExportRow(
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
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      formats: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formats'],
      )!,
      filters: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filters'],
      )!,
      recordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_count'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
    );
  }

  @override
  $ExportsTable createAlias(String alias) {
    return $ExportsTable(attachedDatabase, alias);
  }
}

class ExportRow extends DataClass implements Insertable<ExportRow> {
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

  /// Project this export belongs to.
  final String projectId;

  /// Per-project sequence. Successive exports increment this.
  final int version;

  /// Formats written, as a JSON array.
  final String formats;

  /// Query that selected the records. An object, never the exported values.
  final String filters;

  /// How many records the file contains.
  final int recordCount;

  /// Path of the finished file. Written once at insert.
  final String filePath;

  /// Hash of the finished file. Written once at insert.
  final String fileHash;

  /// Operator who produced the file.
  final String createdBy;
  const ExportRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.projectId,
    required this.version,
    required this.formats,
    required this.filters,
    required this.recordCount,
    required this.filePath,
    required this.fileHash,
    required this.createdBy,
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
    map['version'] = Variable<int>(version);
    map['formats'] = Variable<String>(formats);
    map['filters'] = Variable<String>(filters);
    map['record_count'] = Variable<int>(recordCount);
    map['file_path'] = Variable<String>(filePath);
    map['file_hash'] = Variable<String>(fileHash);
    map['created_by'] = Variable<String>(createdBy);
    return map;
  }

  ExportsCompanion toCompanion(bool nullToAbsent) {
    return ExportsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      projectId: Value(projectId),
      version: Value(version),
      formats: Value(formats),
      filters: Value(filters),
      recordCount: Value(recordCount),
      filePath: Value(filePath),
      fileHash: Value(fileHash),
      createdBy: Value(createdBy),
    );
  }

  factory ExportRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExportRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      projectId: serializer.fromJson<String>(json['projectId']),
      version: serializer.fromJson<int>(json['version']),
      formats: serializer.fromJson<String>(json['formats']),
      filters: serializer.fromJson<String>(json['filters']),
      recordCount: serializer.fromJson<int>(json['recordCount']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileHash: serializer.fromJson<String>(json['fileHash']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
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
      'version': serializer.toJson<int>(version),
      'formats': serializer.toJson<String>(formats),
      'filters': serializer.toJson<String>(filters),
      'recordCount': serializer.toJson<int>(recordCount),
      'filePath': serializer.toJson<String>(filePath),
      'fileHash': serializer.toJson<String>(fileHash),
      'createdBy': serializer.toJson<String>(createdBy),
    };
  }

  ExportRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? projectId,
    int? version,
    String? formats,
    String? filters,
    int? recordCount,
    String? filePath,
    String? fileHash,
    String? createdBy,
  }) => ExportRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    projectId: projectId ?? this.projectId,
    version: version ?? this.version,
    formats: formats ?? this.formats,
    filters: filters ?? this.filters,
    recordCount: recordCount ?? this.recordCount,
    filePath: filePath ?? this.filePath,
    fileHash: fileHash ?? this.fileHash,
    createdBy: createdBy ?? this.createdBy,
  );
  ExportRow copyWithCompanion(ExportsCompanion data) {
    return ExportRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      version: data.version.present ? data.version.value : this.version,
      formats: data.formats.present ? data.formats.value : this.formats,
      filters: data.filters.present ? data.filters.value : this.filters,
      recordCount: data.recordCount.present
          ? data.recordCount.value
          : this.recordCount,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExportRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('version: $version, ')
          ..write('formats: $formats, ')
          ..write('filters: $filters, ')
          ..write('recordCount: $recordCount, ')
          ..write('filePath: $filePath, ')
          ..write('fileHash: $fileHash, ')
          ..write('createdBy: $createdBy')
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
    version,
    formats,
    filters,
    recordCount,
    filePath,
    fileHash,
    createdBy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExportRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.projectId == this.projectId &&
          other.version == this.version &&
          other.formats == this.formats &&
          other.filters == this.filters &&
          other.recordCount == this.recordCount &&
          other.filePath == this.filePath &&
          other.fileHash == this.fileHash &&
          other.createdBy == this.createdBy);
}

class ExportsCompanion extends UpdateCompanion<ExportRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> projectId;
  final Value<int> version;
  final Value<String> formats;
  final Value<String> filters;
  final Value<int> recordCount;
  final Value<String> filePath;
  final Value<String> fileHash;
  final Value<String> createdBy;
  final Value<int> rowid;
  const ExportsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.projectId = const Value.absent(),
    this.version = const Value.absent(),
    this.formats = const Value.absent(),
    this.filters = const Value.absent(),
    this.recordCount = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExportsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String projectId,
    required int version,
    required String formats,
    required String filters,
    required int recordCount,
    required String filePath,
    required String fileHash,
    required String createdBy,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       projectId = Value(projectId),
       version = Value(version),
       formats = Value(formats),
       filters = Value(filters),
       recordCount = Value(recordCount),
       filePath = Value(filePath),
       fileHash = Value(fileHash),
       createdBy = Value(createdBy);
  static Insertable<ExportRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? projectId,
    Expression<int>? version,
    Expression<String>? formats,
    Expression<String>? filters,
    Expression<int>? recordCount,
    Expression<String>? filePath,
    Expression<String>? fileHash,
    Expression<String>? createdBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (projectId != null) 'project_id': projectId,
      if (version != null) 'version': version,
      if (formats != null) 'formats': formats,
      if (filters != null) 'filters': filters,
      if (recordCount != null) 'record_count': recordCount,
      if (filePath != null) 'file_path': filePath,
      if (fileHash != null) 'file_hash': fileHash,
      if (createdBy != null) 'created_by': createdBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExportsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? projectId,
    Value<int>? version,
    Value<String>? formats,
    Value<String>? filters,
    Value<int>? recordCount,
    Value<String>? filePath,
    Value<String>? fileHash,
    Value<String>? createdBy,
    Value<int>? rowid,
  }) {
    return ExportsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      projectId: projectId ?? this.projectId,
      version: version ?? this.version,
      formats: formats ?? this.formats,
      filters: filters ?? this.filters,
      recordCount: recordCount ?? this.recordCount,
      filePath: filePath ?? this.filePath,
      fileHash: fileHash ?? this.fileHash,
      createdBy: createdBy ?? this.createdBy,
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
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (formats.present) {
      map['formats'] = Variable<String>(formats.value);
    }
    if (filters.present) {
      map['filters'] = Variable<String>(filters.value);
    }
    if (recordCount.present) {
      map['record_count'] = Variable<int>(recordCount.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExportsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('projectId: $projectId, ')
          ..write('version: $version, ')
          ..write('formats: $formats, ')
          ..write('filters: $filters, ')
          ..write('recordCount: $recordCount, ')
          ..write('filePath: $filePath, ')
          ..write('fileHash: $fileHash, ')
          ..write('createdBy: $createdBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MergeTable extends Merge with TableInfo<$MergeTable, MergeSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MergeTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _bundleNameMeta = const VerificationMeta(
    'bundleName',
  );
  @override
  late final GeneratedColumn<String> bundleName = GeneratedColumn<String>(
    'bundle_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceDeviceMeta = const VerificationMeta(
    'sourceDevice',
  );
  @override
  late final GeneratedColumn<String> sourceDevice = GeneratedColumn<String>(
    'source_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countsMeta = const VerificationMeta('counts');
  @override
  late final GeneratedColumn<String> counts = GeneratedColumn<String>(
    'counts',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _undoSnapshotPathMeta = const VerificationMeta(
    'undoSnapshotPath',
  );
  @override
  late final GeneratedColumn<String> undoSnapshotPath = GeneratedColumn<String>(
    'undo_snapshot_path',
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
    bundleName,
    sourceDevice,
    importedAt,
    counts,
    status,
    undoSnapshotPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merge_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<MergeSession> instance, {
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
    if (data.containsKey('bundle_name')) {
      context.handle(
        _bundleNameMeta,
        bundleName.isAcceptableOrUnknown(data['bundle_name']!, _bundleNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bundleNameMeta);
    }
    if (data.containsKey('source_device')) {
      context.handle(
        _sourceDeviceMeta,
        sourceDevice.isAcceptableOrUnknown(
          data['source_device']!,
          _sourceDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceDeviceMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('counts')) {
      context.handle(
        _countsMeta,
        counts.isAcceptableOrUnknown(data['counts']!, _countsMeta),
      );
    } else if (isInserting) {
      context.missing(_countsMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('undo_snapshot_path')) {
      context.handle(
        _undoSnapshotPathMeta,
        undoSnapshotPath.isAcceptableOrUnknown(
          data['undo_snapshot_path']!,
          _undoSnapshotPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_undoSnapshotPathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MergeSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MergeSession(
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
      bundleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bundle_name'],
      )!,
      sourceDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_device'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      counts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counts'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      undoSnapshotPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}undo_snapshot_path'],
      )!,
    );
  }

  @override
  $MergeTable createAlias(String alias) {
    return $MergeTable(attachedDatabase, alias);
  }
}

class MergeSession extends DataClass implements Insertable<MergeSession> {
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

  /// Bundle file name, stored as data.
  final String bundleName;

  /// Device the bundle came from.
  final String sourceDevice;

  /// When the bundle was imported.
  final DateTime importedAt;

  /// Per-category counts JSON. An object, stored as text.
  final String counts;

  /// imported, undone or failed, stored as text.
  final String status;

  /// Path of the pre-apply snapshot used by undo.
  final String undoSnapshotPath;
  const MergeSession({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.bundleName,
    required this.sourceDevice,
    required this.importedAt,
    required this.counts,
    required this.status,
    required this.undoSnapshotPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['bundle_name'] = Variable<String>(bundleName);
    map['source_device'] = Variable<String>(sourceDevice);
    map['imported_at'] = Variable<DateTime>(importedAt);
    map['counts'] = Variable<String>(counts);
    map['status'] = Variable<String>(status);
    map['undo_snapshot_path'] = Variable<String>(undoSnapshotPath);
    return map;
  }

  MergeCompanion toCompanion(bool nullToAbsent) {
    return MergeCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      bundleName: Value(bundleName),
      sourceDevice: Value(sourceDevice),
      importedAt: Value(importedAt),
      counts: Value(counts),
      status: Value(status),
      undoSnapshotPath: Value(undoSnapshotPath),
    );
  }

  factory MergeSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MergeSession(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      bundleName: serializer.fromJson<String>(json['bundleName']),
      sourceDevice: serializer.fromJson<String>(json['sourceDevice']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      counts: serializer.fromJson<String>(json['counts']),
      status: serializer.fromJson<String>(json['status']),
      undoSnapshotPath: serializer.fromJson<String>(json['undoSnapshotPath']),
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
      'bundleName': serializer.toJson<String>(bundleName),
      'sourceDevice': serializer.toJson<String>(sourceDevice),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'counts': serializer.toJson<String>(counts),
      'status': serializer.toJson<String>(status),
      'undoSnapshotPath': serializer.toJson<String>(undoSnapshotPath),
    };
  }

  MergeSession copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? bundleName,
    String? sourceDevice,
    DateTime? importedAt,
    String? counts,
    String? status,
    String? undoSnapshotPath,
  }) => MergeSession(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    bundleName: bundleName ?? this.bundleName,
    sourceDevice: sourceDevice ?? this.sourceDevice,
    importedAt: importedAt ?? this.importedAt,
    counts: counts ?? this.counts,
    status: status ?? this.status,
    undoSnapshotPath: undoSnapshotPath ?? this.undoSnapshotPath,
  );
  MergeSession copyWithCompanion(MergeCompanion data) {
    return MergeSession(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      bundleName: data.bundleName.present
          ? data.bundleName.value
          : this.bundleName,
      sourceDevice: data.sourceDevice.present
          ? data.sourceDevice.value
          : this.sourceDevice,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      counts: data.counts.present ? data.counts.value : this.counts,
      status: data.status.present ? data.status.value : this.status,
      undoSnapshotPath: data.undoSnapshotPath.present
          ? data.undoSnapshotPath.value
          : this.undoSnapshotPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MergeSession(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('bundleName: $bundleName, ')
          ..write('sourceDevice: $sourceDevice, ')
          ..write('importedAt: $importedAt, ')
          ..write('counts: $counts, ')
          ..write('status: $status, ')
          ..write('undoSnapshotPath: $undoSnapshotPath')
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
    bundleName,
    sourceDevice,
    importedAt,
    counts,
    status,
    undoSnapshotPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MergeSession &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.bundleName == this.bundleName &&
          other.sourceDevice == this.sourceDevice &&
          other.importedAt == this.importedAt &&
          other.counts == this.counts &&
          other.status == this.status &&
          other.undoSnapshotPath == this.undoSnapshotPath);
}

class MergeCompanion extends UpdateCompanion<MergeSession> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> bundleName;
  final Value<String> sourceDevice;
  final Value<DateTime> importedAt;
  final Value<String> counts;
  final Value<String> status;
  final Value<String> undoSnapshotPath;
  final Value<int> rowid;
  const MergeCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.bundleName = const Value.absent(),
    this.sourceDevice = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.counts = const Value.absent(),
    this.status = const Value.absent(),
    this.undoSnapshotPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MergeCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String bundleName,
    required String sourceDevice,
    required DateTime importedAt,
    required String counts,
    required String status,
    required String undoSnapshotPath,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       bundleName = Value(bundleName),
       sourceDevice = Value(sourceDevice),
       importedAt = Value(importedAt),
       counts = Value(counts),
       status = Value(status),
       undoSnapshotPath = Value(undoSnapshotPath);
  static Insertable<MergeSession> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? bundleName,
    Expression<String>? sourceDevice,
    Expression<DateTime>? importedAt,
    Expression<String>? counts,
    Expression<String>? status,
    Expression<String>? undoSnapshotPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (bundleName != null) 'bundle_name': bundleName,
      if (sourceDevice != null) 'source_device': sourceDevice,
      if (importedAt != null) 'imported_at': importedAt,
      if (counts != null) 'counts': counts,
      if (status != null) 'status': status,
      if (undoSnapshotPath != null) 'undo_snapshot_path': undoSnapshotPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MergeCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? bundleName,
    Value<String>? sourceDevice,
    Value<DateTime>? importedAt,
    Value<String>? counts,
    Value<String>? status,
    Value<String>? undoSnapshotPath,
    Value<int>? rowid,
  }) {
    return MergeCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      bundleName: bundleName ?? this.bundleName,
      sourceDevice: sourceDevice ?? this.sourceDevice,
      importedAt: importedAt ?? this.importedAt,
      counts: counts ?? this.counts,
      status: status ?? this.status,
      undoSnapshotPath: undoSnapshotPath ?? this.undoSnapshotPath,
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
    if (bundleName.present) {
      map['bundle_name'] = Variable<String>(bundleName.value);
    }
    if (sourceDevice.present) {
      map['source_device'] = Variable<String>(sourceDevice.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (counts.present) {
      map['counts'] = Variable<String>(counts.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (undoSnapshotPath.present) {
      map['undo_snapshot_path'] = Variable<String>(undoSnapshotPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MergeCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('bundleName: $bundleName, ')
          ..write('sourceDevice: $sourceDevice, ')
          ..write('importedAt: $importedAt, ')
          ..write('counts: $counts, ')
          ..write('status: $status, ')
          ..write('undoSnapshotPath: $undoSnapshotPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MergeConflictsTable extends MergeConflicts
    with TableInfo<$MergeConflictsTable, MergeConflict> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MergeConflictsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _mineValueMeta = const VerificationMeta(
    'mineValue',
  );
  @override
  late final GeneratedColumn<String> mineValue = GeneratedColumn<String>(
    'mine_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _theirsValueMeta = const VerificationMeta(
    'theirsValue',
  );
  @override
  late final GeneratedColumn<String> theirsValue = GeneratedColumn<String>(
    'theirs_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mineMetaMeta = const VerificationMeta(
    'mineMeta',
  );
  @override
  late final GeneratedColumn<String> mineMeta = GeneratedColumn<String>(
    'mine_meta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _theirsMetaMeta = const VerificationMeta(
    'theirsMeta',
  );
  @override
  late final GeneratedColumn<String> theirsMeta = GeneratedColumn<String>(
    'theirs_meta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolutionMeta = const VerificationMeta(
    'resolution',
  );
  @override
  late final GeneratedColumn<String> resolution = GeneratedColumn<String>(
    'resolution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedByMeta = const VerificationMeta(
    'resolvedBy',
  );
  @override
  late final GeneratedColumn<String> resolvedBy = GeneratedColumn<String>(
    'resolved_by',
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
    sessionId,
    entityType,
    entityId,
    fieldKey,
    mineValue,
    theirsValue,
    mineMeta,
    theirsMeta,
    resolution,
    resolvedAt,
    resolvedBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merge_conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<MergeConflict> instance, {
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
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
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
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('mine_value')) {
      context.handle(
        _mineValueMeta,
        mineValue.isAcceptableOrUnknown(data['mine_value']!, _mineValueMeta),
      );
    } else if (isInserting) {
      context.missing(_mineValueMeta);
    }
    if (data.containsKey('theirs_value')) {
      context.handle(
        _theirsValueMeta,
        theirsValue.isAcceptableOrUnknown(
          data['theirs_value']!,
          _theirsValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_theirsValueMeta);
    }
    if (data.containsKey('mine_meta')) {
      context.handle(
        _mineMetaMeta,
        mineMeta.isAcceptableOrUnknown(data['mine_meta']!, _mineMetaMeta),
      );
    } else if (isInserting) {
      context.missing(_mineMetaMeta);
    }
    if (data.containsKey('theirs_meta')) {
      context.handle(
        _theirsMetaMeta,
        theirsMeta.isAcceptableOrUnknown(data['theirs_meta']!, _theirsMetaMeta),
      );
    } else if (isInserting) {
      context.missing(_theirsMetaMeta);
    }
    if (data.containsKey('resolution')) {
      context.handle(
        _resolutionMeta,
        resolution.isAcceptableOrUnknown(data['resolution']!, _resolutionMeta),
      );
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    if (data.containsKey('resolved_by')) {
      context.handle(
        _resolvedByMeta,
        resolvedBy.isAcceptableOrUnknown(data['resolved_by']!, _resolvedByMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MergeConflict map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MergeConflict(
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
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      )!,
      mineValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mine_value'],
      )!,
      theirsValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theirs_value'],
      )!,
      mineMeta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mine_meta'],
      )!,
      theirsMeta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theirs_meta'],
      )!,
      resolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution'],
      ),
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
      resolvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_by'],
      ),
    );
  }

  @override
  $MergeConflictsTable createAlias(String alias) {
    return $MergeConflictsTable(attachedDatabase, alias);
  }
}

class MergeConflict extends DataClass implements Insertable<MergeConflict> {
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

  /// Session that produced this conflict.
  final String sessionId;

  /// Table the entity belongs to.
  final String entityType;

  /// Merge id of the entity.
  final String entityId;

  /// Field that differs.
  final String fieldKey;

  /// Local value as stored, never normalised.
  final String mineValue;

  /// Incoming value as stored, never normalised.
  final String theirsValue;

  /// Local provenance JSON. An object, stored as text.
  final String mineMeta;

  /// Incoming provenance JSON. An object, stored as text.
  final String theirsMeta;

  /// Human choice. Null until a person resolves it.
  final String? resolution;

  /// When it was resolved.
  final DateTime? resolvedAt;

  /// Operator who resolved it.
  final String? resolvedBy;
  const MergeConflict({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.sessionId,
    required this.entityType,
    required this.entityId,
    required this.fieldKey,
    required this.mineValue,
    required this.theirsValue,
    required this.mineMeta,
    required this.theirsMeta,
    this.resolution,
    this.resolvedAt,
    this.resolvedBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['rev'] = Variable<int>(rev);
    map['session_id'] = Variable<String>(sessionId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['field_key'] = Variable<String>(fieldKey);
    map['mine_value'] = Variable<String>(mineValue);
    map['theirs_value'] = Variable<String>(theirsValue);
    map['mine_meta'] = Variable<String>(mineMeta);
    map['theirs_meta'] = Variable<String>(theirsMeta);
    if (!nullToAbsent || resolution != null) {
      map['resolution'] = Variable<String>(resolution);
    }
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    if (!nullToAbsent || resolvedBy != null) {
      map['resolved_by'] = Variable<String>(resolvedBy);
    }
    return map;
  }

  MergeConflictsCompanion toCompanion(bool nullToAbsent) {
    return MergeConflictsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      sessionId: Value(sessionId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      fieldKey: Value(fieldKey),
      mineValue: Value(mineValue),
      theirsValue: Value(theirsValue),
      mineMeta: Value(mineMeta),
      theirsMeta: Value(theirsMeta),
      resolution: resolution == null && nullToAbsent
          ? const Value.absent()
          : Value(resolution),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      resolvedBy: resolvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedBy),
    );
  }

  factory MergeConflict.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MergeConflict(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      mineValue: serializer.fromJson<String>(json['mineValue']),
      theirsValue: serializer.fromJson<String>(json['theirsValue']),
      mineMeta: serializer.fromJson<String>(json['mineMeta']),
      theirsMeta: serializer.fromJson<String>(json['theirsMeta']),
      resolution: serializer.fromJson<String?>(json['resolution']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
      resolvedBy: serializer.fromJson<String?>(json['resolvedBy']),
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
      'sessionId': serializer.toJson<String>(sessionId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'mineValue': serializer.toJson<String>(mineValue),
      'theirsValue': serializer.toJson<String>(theirsValue),
      'mineMeta': serializer.toJson<String>(mineMeta),
      'theirsMeta': serializer.toJson<String>(theirsMeta),
      'resolution': serializer.toJson<String?>(resolution),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
      'resolvedBy': serializer.toJson<String?>(resolvedBy),
    };
  }

  MergeConflict copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? sessionId,
    String? entityType,
    String? entityId,
    String? fieldKey,
    String? mineValue,
    String? theirsValue,
    String? mineMeta,
    String? theirsMeta,
    Value<String?> resolution = const Value.absent(),
    Value<DateTime?> resolvedAt = const Value.absent(),
    Value<String?> resolvedBy = const Value.absent(),
  }) => MergeConflict(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    sessionId: sessionId ?? this.sessionId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    fieldKey: fieldKey ?? this.fieldKey,
    mineValue: mineValue ?? this.mineValue,
    theirsValue: theirsValue ?? this.theirsValue,
    mineMeta: mineMeta ?? this.mineMeta,
    theirsMeta: theirsMeta ?? this.theirsMeta,
    resolution: resolution.present ? resolution.value : this.resolution,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    resolvedBy: resolvedBy.present ? resolvedBy.value : this.resolvedBy,
  );
  MergeConflict copyWithCompanion(MergeConflictsCompanion data) {
    return MergeConflict(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      rev: data.rev.present ? data.rev.value : this.rev,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      mineValue: data.mineValue.present ? data.mineValue.value : this.mineValue,
      theirsValue: data.theirsValue.present
          ? data.theirsValue.value
          : this.theirsValue,
      mineMeta: data.mineMeta.present ? data.mineMeta.value : this.mineMeta,
      theirsMeta: data.theirsMeta.present
          ? data.theirsMeta.value
          : this.theirsMeta,
      resolution: data.resolution.present
          ? data.resolution.value
          : this.resolution,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      resolvedBy: data.resolvedBy.present
          ? data.resolvedBy.value
          : this.resolvedBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MergeConflict(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('sessionId: $sessionId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('mineValue: $mineValue, ')
          ..write('theirsValue: $theirsValue, ')
          ..write('mineMeta: $mineMeta, ')
          ..write('theirsMeta: $theirsMeta, ')
          ..write('resolution: $resolution, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('resolvedBy: $resolvedBy')
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
    sessionId,
    entityType,
    entityId,
    fieldKey,
    mineValue,
    theirsValue,
    mineMeta,
    theirsMeta,
    resolution,
    resolvedAt,
    resolvedBy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MergeConflict &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.sessionId == this.sessionId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.fieldKey == this.fieldKey &&
          other.mineValue == this.mineValue &&
          other.theirsValue == this.theirsValue &&
          other.mineMeta == this.mineMeta &&
          other.theirsMeta == this.theirsMeta &&
          other.resolution == this.resolution &&
          other.resolvedAt == this.resolvedAt &&
          other.resolvedBy == this.resolvedBy);
}

class MergeConflictsCompanion extends UpdateCompanion<MergeConflict> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> sessionId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> fieldKey;
  final Value<String> mineValue;
  final Value<String> theirsValue;
  final Value<String> mineMeta;
  final Value<String> theirsMeta;
  final Value<String?> resolution;
  final Value<DateTime?> resolvedAt;
  final Value<String?> resolvedBy;
  final Value<int> rowid;
  const MergeConflictsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.mineValue = const Value.absent(),
    this.theirsValue = const Value.absent(),
    this.mineMeta = const Value.absent(),
    this.theirsMeta = const Value.absent(),
    this.resolution = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.resolvedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MergeConflictsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String sessionId,
    required String entityType,
    required String entityId,
    required String fieldKey,
    required String mineValue,
    required String theirsValue,
    required String mineMeta,
    required String theirsMeta,
    this.resolution = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.resolvedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       sessionId = Value(sessionId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       fieldKey = Value(fieldKey),
       mineValue = Value(mineValue),
       theirsValue = Value(theirsValue),
       mineMeta = Value(mineMeta),
       theirsMeta = Value(theirsMeta);
  static Insertable<MergeConflict> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? sessionId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? fieldKey,
    Expression<String>? mineValue,
    Expression<String>? theirsValue,
    Expression<String>? mineMeta,
    Expression<String>? theirsMeta,
    Expression<String>? resolution,
    Expression<DateTime>? resolvedAt,
    Expression<String>? resolvedBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (rev != null) 'rev': rev,
      if (sessionId != null) 'session_id': sessionId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (fieldKey != null) 'field_key': fieldKey,
      if (mineValue != null) 'mine_value': mineValue,
      if (theirsValue != null) 'theirs_value': theirsValue,
      if (mineMeta != null) 'mine_meta': mineMeta,
      if (theirsMeta != null) 'theirs_meta': theirsMeta,
      if (resolution != null) 'resolution': resolution,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (resolvedBy != null) 'resolved_by': resolvedBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MergeConflictsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? sessionId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? fieldKey,
    Value<String>? mineValue,
    Value<String>? theirsValue,
    Value<String>? mineMeta,
    Value<String>? theirsMeta,
    Value<String?>? resolution,
    Value<DateTime?>? resolvedAt,
    Value<String?>? resolvedBy,
    Value<int>? rowid,
  }) {
    return MergeConflictsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      sessionId: sessionId ?? this.sessionId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      fieldKey: fieldKey ?? this.fieldKey,
      mineValue: mineValue ?? this.mineValue,
      theirsValue: theirsValue ?? this.theirsValue,
      mineMeta: mineMeta ?? this.mineMeta,
      theirsMeta: theirsMeta ?? this.theirsMeta,
      resolution: resolution ?? this.resolution,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
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
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (mineValue.present) {
      map['mine_value'] = Variable<String>(mineValue.value);
    }
    if (theirsValue.present) {
      map['theirs_value'] = Variable<String>(theirsValue.value);
    }
    if (mineMeta.present) {
      map['mine_meta'] = Variable<String>(mineMeta.value);
    }
    if (theirsMeta.present) {
      map['theirs_meta'] = Variable<String>(theirsMeta.value);
    }
    if (resolution.present) {
      map['resolution'] = Variable<String>(resolution.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (resolvedBy.present) {
      map['resolved_by'] = Variable<String>(resolvedBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MergeConflictsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('sessionId: $sessionId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('mineValue: $mineValue, ')
          ..write('theirsValue: $theirsValue, ')
          ..write('mineMeta: $mineMeta, ')
          ..write('theirsMeta: $theirsMeta, ')
          ..write('resolution: $resolution, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('resolvedBy: $resolvedBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, VersionVectorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _seenRevMeta = const VerificationMeta(
    'seenRev',
  );
  @override
  late final GeneratedColumn<int> seenRev = GeneratedColumn<int>(
    'seen_rev',
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
    entityType,
    entityId,
    deviceId,
    seenRev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'version_vectors';
  @override
  VerificationContext validateIntegrity(
    Insertable<VersionVectorRow> instance, {
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
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('seen_rev')) {
      context.handle(
        _seenRevMeta,
        seenRev.isAcceptableOrUnknown(data['seen_rev']!, _seenRevMeta),
      );
    } else if (isInserting) {
      context.missing(_seenRevMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entityType, entityId, deviceId},
  ];
  @override
  VersionVectorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VersionVectorRow(
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
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      seenRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seen_rev'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class VersionVectorRow extends DataClass
    implements Insertable<VersionVectorRow> {
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

  /// Table the entity belongs to.
  final String entityType;

  /// Merge id of the entity.
  final String entityId;

  /// Replica that produced [seenRev].
  final String deviceId;

  /// Highest entity revision seen from [deviceId].
  final int seenRev;
  const VersionVectorRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDevice,
    required this.rev,
    required this.entityType,
    required this.entityId,
    required this.deviceId,
    required this.seenRev,
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
    map['device_id'] = Variable<String>(deviceId);
    map['seen_rev'] = Variable<int>(seenRev);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDevice: Value(updatedByDevice),
      rev: Value(rev),
      entityType: Value(entityType),
      entityId: Value(entityId),
      deviceId: Value(deviceId),
      seenRev: Value(seenRev),
    );
  }

  factory VersionVectorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VersionVectorRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      rev: serializer.fromJson<int>(json['rev']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      seenRev: serializer.fromJson<int>(json['seenRev']),
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
      'deviceId': serializer.toJson<String>(deviceId),
      'seenRev': serializer.toJson<int>(seenRev),
    };
  }

  VersionVectorRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByDevice,
    int? rev,
    String? entityType,
    String? entityId,
    String? deviceId,
    int? seenRev,
  }) => VersionVectorRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDevice: updatedByDevice ?? this.updatedByDevice,
    rev: rev ?? this.rev,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    deviceId: deviceId ?? this.deviceId,
    seenRev: seenRev ?? this.seenRev,
  );
  VersionVectorRow copyWithCompanion(SyncStateCompanion data) {
    return VersionVectorRow(
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
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      seenRev: data.seenRev.present ? data.seenRev.value : this.seenRev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VersionVectorRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('deviceId: $deviceId, ')
          ..write('seenRev: $seenRev')
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
    deviceId,
    seenRev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VersionVectorRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.rev == this.rev &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.deviceId == this.deviceId &&
          other.seenRev == this.seenRev);
}

class SyncStateCompanion extends UpdateCompanion<VersionVectorRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> updatedByDevice;
  final Value<int> rev;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> deviceId;
  final Value<int> seenRev;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.rev = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.seenRev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedByDevice,
    this.rev = const Value.absent(),
    required String entityType,
    required String entityId,
    required String deviceId,
    required int seenRev,
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDevice = Value(updatedByDevice),
       entityType = Value(entityType),
       entityId = Value(entityId),
       deviceId = Value(deviceId),
       seenRev = Value(seenRev);
  static Insertable<VersionVectorRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedByDevice,
    Expression<int>? rev,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? deviceId,
    Expression<int>? seenRev,
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
      if (deviceId != null) 'device_id': deviceId,
      if (seenRev != null) 'seen_rev': seenRev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? updatedByDevice,
    Value<int>? rev,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? deviceId,
    Value<int>? seenRev,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      rev: rev ?? this.rev,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      deviceId: deviceId ?? this.deviceId,
      seenRev: seenRev ?? this.seenRev,
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
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (seenRev.present) {
      map['seen_rev'] = Variable<int>(seenRev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('rev: $rev, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('deviceId: $deviceId, ')
          ..write('seenRev: $seenRev, ')
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
  late final $AttachmentOwnersTable attachmentOwners = $AttachmentOwnersTable(
    this,
  );
  late final $CaptionsTable captions = $CaptionsTable(this);
  late final $CaptureSessionsTable captureSessions = $CaptureSessionsTable(
    this,
  );
  late final $ReferenceTable reference = $ReferenceTable(this);
  late final $ReferenceRowsTable referenceRows = $ReferenceRowsTable(this);
  late final $ProcessingTable processing = $ProcessingTable(this);
  late final $ProcessingResultsTable processingResults =
      $ProcessingResultsTable(this);
  late final $OcrCacheEntriesTable ocrCacheEntries = $OcrCacheEntriesTable(
    this,
  );
  late final $FieldEvidenceTable fieldEvidence = $FieldEvidenceTable(this);
  late final $DuplicatesTable duplicates = $DuplicatesTable(this);
  late final $VariancesTable variances = $VariancesTable(this);
  late final $MeetingsTable meetings = $MeetingsTable(this);
  late final $AttendeesTable attendees = $AttendeesTable(this);
  late final $MeetingActionsTable meetingActions = $MeetingActionsTable(this);
  late final $ExportsTable exports = $ExportsTable(this);
  late final $MergeTable merge = $MergeTable(this);
  late final $MergeConflictsTable mergeConflicts = $MergeConflictsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
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
  late final Index attachmentOwnersByOwner = Index(
    'attachment_owners_by_owner',
    'CREATE INDEX attachment_owners_by_owner ON attachment_owners (owner_type, owner_id)',
  );
  late final Index captionsByOwner = Index(
    'captions_by_owner',
    'CREATE INDEX captions_by_owner ON captions (owner_type, owner_id)',
  );
  late final Index referenceRowsByKey = Index(
    'reference_rows_by_key',
    'CREATE UNIQUE INDEX reference_rows_by_key ON reference_rows (dataset_id, key_value)',
  );
  late final Index referenceRowsByNormalised = Index(
    'reference_rows_by_normalised',
    'CREATE INDEX reference_rows_by_normalised ON reference_rows (dataset_id, key_normalised)',
  );
  late final Index processingJobsByStatus = Index(
    'processing_jobs_by_status',
    'CREATE INDEX processing_jobs_by_status ON processing_jobs (status, queued_at)',
  );
  late final Index ocrCacheByHash = Index(
    'ocr_cache_by_hash',
    'CREATE INDEX ocr_cache_by_hash ON ocr_cache (content_hash)',
  );
  late final Index fieldEvidenceByField = Index(
    'field_evidence_by_field',
    'CREATE INDEX field_evidence_by_field ON field_evidence (record_field_id)',
  );
  late final Index duplicatesByPair = Index(
    'duplicates_by_pair',
    'CREATE UNIQUE INDEX duplicates_by_pair ON duplicates (left_record_id, right_record_id)',
  );
  late final Index duplicatesByProjectStatus = Index(
    'duplicates_by_project_status',
    'CREATE INDEX duplicates_by_project_status ON duplicates (project_id, status)',
  );
  late final Index variancesByField = Index(
    'variances_by_field',
    'CREATE UNIQUE INDEX variances_by_field ON variances (record_id, field_key)',
  );
  late final Index variancesByProjectStatus = Index(
    'variances_by_project_status',
    'CREATE INDEX variances_by_project_status ON variances (project_id, status)',
  );
  late final Index meetingActionsByMeetingStatus = Index(
    'meeting_actions_by_meeting_status',
    'CREATE INDEX meeting_actions_by_meeting_status ON meeting_actions (meeting_id, status)',
  );
  late final Index exportsByProjectCreated = Index(
    'exports_by_project_created',
    'CREATE INDEX exports_by_project_created ON exports (project_id, created_at)',
  );
  late final Index mergeConflictsBySessionResolution = Index(
    'merge_conflicts_by_session_resolution',
    'CREATE INDEX merge_conflicts_by_session_resolution ON merge_conflicts (session_id, resolution)',
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
    attachmentOwners,
    captions,
    captureSessions,
    reference,
    referenceRows,
    processing,
    processingResults,
    ocrCacheEntries,
    fieldEvidence,
    duplicates,
    variances,
    meetings,
    attendees,
    meetingActions,
    exports,
    merge,
    mergeConflicts,
    syncState,
    auditLogHistory,
    projectsByStatus,
    templateRowsByIdentifier,
    recordsByProjectStatus,
    recordsByIdentityHash,
    recordsByCapturedAt,
    recordsByTemplate,
    recordFieldsByFinal,
    attachmentOwnersByOwner,
    captionsByOwner,
    referenceRowsByKey,
    referenceRowsByNormalised,
    processingJobsByStatus,
    ocrCacheByHash,
    fieldEvidenceByField,
    duplicatesByPair,
    duplicatesByProjectStatus,
    variancesByField,
    variancesByProjectStatus,
    meetingActionsByMeetingStatus,
    exportsByProjectCreated,
    mergeConflictsBySessionResolution,
  ];
}
