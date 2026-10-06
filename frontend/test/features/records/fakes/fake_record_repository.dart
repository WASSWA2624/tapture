import 'dart:async';
import 'dart:convert';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/normalise/search_text.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/domain.dart';

/// In-memory [RecordRepository] with the same semantics as the Drift one
/// (FE-STATE-10), for feature tests that must not open a database.
///
/// Every write honours `record_repository_contract.dart`: status moves are
/// checked with [RecordLifecycle], a delete keeps the record with status
/// deleted and a tombstone, a restore returns the previous status, edits and
/// template changes send an approved record back to review, and every change
/// appends a history line. Paging, sorting and filtering run over the rows
/// held here, so a widget test can scroll 10,000 of them.
final class FakeRecordRepository implements RecordRepository {
  /// Creates an empty repository timed by [clock].
  FakeRecordRepository({
    Clock? clock,
    this.deviceId = 'device-test',
    this.operator = 'Test operator',
  }) : clock = clock ?? FixedClock(DateTime.utc(2026, 9, 17, 8));

  /// Stamps every write. Tests move time by assigning a later clock.
  Clock clock;

  /// Device written into history lines and onto saved records.
  final String deviceId;

  /// Operator written into history lines and approvals.
  final String operator;

  /// When set, every stream emits this as an error and every read fails.
  Failure? readFailure;

  /// When set, every write fails with this before changing anything.
  Failure? writeFailure;

  /// Writes to these records fail with the mapped failure; others succeed.
  final Map<String, Failure> failuresById = <String, Failure>{};

  /// Every successful write, in order: the method name and the record id.
  final List<({String method, String id})> writes =
      <({String method, String id})>[];

  /// Labels [facets] shows for context level keys; the key otherwise.
  final Map<String, String> contextLevelLabels = <String, String>{};

  /// Labels [facets] shows for operator ids; the id otherwise.
  final Map<String, String> operatorLabels = <String, String>{};

  final Map<String, RecordEntry> _entries = <String, RecordEntry>{};
  final Map<String, ({DateTime at, String reason})> _tombs =
      <String, ({DateTime at, String reason})>{};
  final Map<String, List<RecordHistoryEvent>> _history =
      <String, List<RecordHistoryEvent>>{};
  final Map<String, ({String name, List<String> fieldKeys})> _templates =
      <String, ({String name, List<String> fieldKeys})>{};
  final Map<String, String> _projectNames = <String, String>{};
  final Map<String, String> _searchText = <String, String>{};
  final Map<String, RecordFacets> _facets = <String, RecordFacets>{};
  final Map<String, int> _lastNumber = <String, int>{};
  final Map<String, List<RecordEntry>> _ordered = <String, List<RecordEntry>>{};
  final Map<String, String> _bodies = <String, String>{};
  final Set<String> _namedByTest = <String>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _nextRecord = 0;
  int _nextEvent = 0;

  /// The reason a project delete writes on its records' tombstones; such
  /// records are hidden but never listed in the bin (D12).
  static const String projectDeletedReason = 'Project deleted';

  /// How many records are held, deleted ones included.
  int get count => _entries.length;

  /// Every record held, in the order it arrived.
  List<RecordEntry> get entries => <RecordEntry>[
    for (final RecordEntry entry in _entries.values) _out(entry),
  ];

  /// Record [id] as a read returns it, or null.
  RecordEntry? entryOf(String id) {
    final RecordEntry? entry = _entries[id];
    return entry == null ? null : _out(entry);
  }

  /// Whether record [id] carries a tombstone.
  bool isTombstoned(String id) => _tombs.containsKey(id);

  /// Record [id]'s history lines, oldest first; lines written at the same
  /// instant keep the order they were written in.
  List<RecordHistoryEvent> historyOf(String id) {
    final List<RecordHistoryEvent> lines =
        _history[id] ?? const <RecordHistoryEvent>[];
    final List<int> order = List<int>.generate(lines.length, (int i) => i)
      ..sort((int a, int b) {
        final int byTime = lines[a].at.compareTo(lines[b].at);
        return byTime != 0 ? byTime : a.compareTo(b);
      });
    return List<RecordHistoryEvent>.unmodifiable(<RecordHistoryEvent>[
      for (final int index in order) lines[index],
    ]);
  }

  /// Releases the watch streams. Tests call this from `tearDown`.
  void dispose() {
    _changes.close();
  }

  /// Holds [entry] as it is. A missing number gets the project's next one,
  /// an empty name is derived from the values, and a deleted entry gets a
  /// tombstone at [deletedAt] (now when null) with [reason].
  String seedEntry(
    RecordEntry entry, {
    String searchText = '',
    DateTime? deletedAt,
    String reason = 'Deleted',
  }) {
    RecordEntry held = entry.number == null
        ? entry.copyWith(number: _allocate(entry.projectId))
        : entry;
    _raise(held.projectId, held.number!);
    if (held.name.isEmpty) {
      _namedByTest.remove(held.id);
      held = held.copyWith(name: _nameOf(held));
    } else {
      _namedByTest.add(held.id);
    }
    _entries[held.id] = held;
    if (searchText.isNotEmpty) {
      _searchText[held.id] = searchText;
    }
    if (held.status == RecordStatus.deleted) {
      _tombs[held.id] = (at: deletedAt ?? clock.nowUtc(), reason: reason);
    }
    _emit();
    return held.id;
  }

  /// Holds [entry] in the recycle bin, deleted at [deletedAt] for [reason]
  /// from [previous], which a restore returns it to.
  String seedDeleted(
    RecordEntry entry, {
    DateTime? deletedAt,
    String reason = 'Deleted',
    RecordStatus previous = RecordStatus.captured,
  }) {
    final DateTime at = deletedAt ?? clock.nowUtc();
    final String id = seedEntry(
      entry.copyWith(status: RecordStatus.deleted),
      deletedAt: at,
      reason: reason,
    );
    _log(
      id,
      RecordHistoryKind.statusChanged,
      fieldKey: 'status',
      previous: previous.stored,
      next: RecordStatus.deleted.stored,
      reason: reason,
      at: at,
    );
    return id;
  }

  /// Adds [count] plain records to [projectId] at once and returns their
  /// ids: numbers 1 up, names `Record <n>`, one `name` value each.
  List<String> seedMany(
    int count, {
    String projectId = 'project-1',
    String templateId = 'template-1',
    RecordStatus status = RecordStatus.captured,
    DateTime? capturedAt,
  }) {
    final DateTime at = capturedAt ?? clock.nowUtc();
    final List<String> ids = <String>[];
    for (int index = 0; index < count; index++) {
      final int number = _allocate(projectId);
      final String id = '$projectId-record-$number';
      _entries[id] = RecordEntry(
        id: id,
        projectId: projectId,
        templateId: templateId,
        status: status,
        capturedAt: at,
        capturedBy: deviceId,
        updatedAt: at,
        number: number,
        name: 'Record $number',
        values: <RecordValue>[
          RecordValue(fieldKey: 'name', raw: 'Record $number'),
        ],
      );
      ids.add(id);
    }
    _emit();
    return ids;
  }

  /// Declares template [id] with [fieldKeys] in order, for names, facets
  /// and template changes.
  void seedTemplate(
    String id, {
    String name = '',
    List<String> fieldKeys = const <String>[],
  }) {
    _templates[id] = (name: name, fieldKeys: List<String>.of(fieldKeys));
    _emit();
  }

  /// Names project [projectId] in the bin.
  void seedProjectName(String projectId, String name) {
    _projectNames[projectId] = name;
    _emit();
  }

  /// Appends [events] to record [id]'s history as they are.
  void seedHistory(String id, List<RecordHistoryEvent> events) {
    _history.putIfAbsent(id, () => <RecordHistoryEvent>[]).addAll(events);
    _emit();
  }

  /// Makes [facets] what [projectId]'s filter sheet reads, instead of
  /// deriving it from the records held.
  void seedFacets(String projectId, RecordFacets facets) {
    _facets[projectId] = facets;
  }

  /// Extra text record [id] is found by, standing in for transcripts and OCR.
  void seedSearchText(String id, String text) {
    _searchText[id] = text;
    _emit();
  }

  @override
  Stream<RecordEntry?> watchEntry(String id) => _watch(() => entryOf(id));

  @override
  Future<Result<RecordEntry?>> byId(String id) async {
    return _read(() => entryOf(id));
  }

  @override
  Stream<List<RecordSummary>> watchPage(
    String projectId, {
    required RecordFilter filter,
    required RecordSort sort,
    required int offset,
    required int limit,
  }) {
    return _watch(() {
      final List<RecordEntry> rows = _matching(projectId, filter, sort);
      final int start = offset.clamp(0, rows.length);
      final int end = (start + (limit < 0 ? 0 : limit)).clamp(0, rows.length);
      return <RecordSummary>[
        for (final RecordEntry entry in rows.sublist(start, end))
          _out(entry).toSummary(),
      ];
    });
  }

  @override
  Stream<int> watchCount(String projectId, RecordFilter filter) {
    return _watch(
      () => _matching(projectId, filter, RecordSort.newestFirst).length,
    );
  }

  @override
  Future<Result<RecordFacets>> facets(String projectId) async {
    return _read(() => _facets[projectId] ?? _derivedFacets(projectId));
  }

  @override
  Stream<List<RecordHistoryEvent>> watchHistory(String id) {
    return _watch(() => historyOf(id));
  }

  @override
  Stream<List<DeletedRecord>> watchBin() => _watch(_bin);

  @override
  Future<Result<RecordEntry>> save(RecordDraft draft) async {
    final Failure? blocked = writeFailure;
    if (blocked != null) {
      return FailureResult<RecordEntry>(blocked);
    }
    if (draft.projectId.trim().isEmpty || draft.templateId.trim().isEmpty) {
      return const FailureResult<RecordEntry>(_needsProjectAndTemplate);
    }
    String id;
    do {
      id = 'record-${++_nextRecord}';
    } while (_entries.containsKey(id));
    final DateTime now = clock.nowUtc();
    RecordEntry entry = RecordEntry(
      id: id,
      projectId: draft.projectId,
      templateId: draft.templateId,
      status: RecordStatus.draft,
      capturedAt: now,
      capturedBy: deviceId,
      updatedAt: now,
      number: _allocate(draft.projectId),
      values: <RecordValue>[
        for (final MapEntry<String, String> field in draft.fields.entries)
          if (field.key.trim().isNotEmpty && field.value.isNotEmpty)
            RecordValue(
              fieldKey: field.key,
              raw: field.value,
              source: RecordValue.manualSource,
            ),
      ],
      context: Map<String, String>.of(draft.context),
      source: 'manual',
    );
    entry = entry.copyWith(name: _nameOf(entry));
    _entries[id] = entry;
    _log(id, RecordHistoryKind.created, reason: 'Saved by hand');
    _wrote('save', id);
    return Success<RecordEntry>(_out(entry));
  }

  @override
  Future<Result<void>> transition(
    String id,
    RecordStatus to, {
    String? reason,
  }) async {
    final Result<RecordEntry> found = _writable(id);
    if (found case FailureResult<RecordEntry>(:final Failure failure)) {
      return FailureResult<void>(failure);
    }
    final RecordEntry entry = (found as Success<RecordEntry>).value;
    if (to == RecordStatus.deleted) {
      return const FailureResult<void>(_useDelete);
    }
    if (entry.status == RecordStatus.deleted) {
      return const FailureResult<void>(_useRestore);
    }
    final Result<void> legal = RecordLifecycle.check(entry.status, to);
    if (legal is FailureResult<void>) {
      return legal;
    }
    _setStatus(entry, to, reason: reason);
    _wrote('transition', id);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> editValues(
    String id,
    List<RecordValueEdit> edits,
  ) async {
    final Result<RecordEntry> found = _writable(id);
    if (found case FailureResult<RecordEntry>(:final Failure failure)) {
      return FailureResult<void>(failure);
    }
    final RecordEntry entry = (found as Success<RecordEntry>).value;
    final Result<void> editable = RecordLifecycle.checkEditable(entry.status);
    if (editable is FailureResult<void>) {
      return editable;
    }
    for (final RecordValueEdit edit in edits) {
      if (edit.fieldKey.trim().isEmpty) {
        return const FailureResult<void>(_needsField);
      }
    }
    final List<RecordValue> values = List<RecordValue>.of(entry.values);
    bool changed = false;
    for (final RecordValueEdit edit in edits) {
      final int index = values.indexWhere(
        (RecordValue value) => value.fieldKey == edit.fieldKey,
      );
      final RecordValue? current = index < 0 ? null : values[index];
      final String before = current?.display ?? '';
      if (before == edit.value) {
        continue;
      }
      if (current == null) {
        values.add(
          RecordValue(
            fieldKey: edit.fieldKey,
            raw: edit.value,
            source: RecordValue.manualSource,
            verified: true,
          ),
        );
      } else {
        // The edit supersedes an approved value, so the field shows it.
        values[index] = current.copyWith(
          refined: edit.value,
          source: RecordValue.manualSource,
          verified: true,
          clearApproved: true,
        );
      }
      _log(
        id,
        RecordHistoryKind.valueChanged,
        fieldKey: edit.fieldKey,
        previous: before.isEmpty ? null : before,
        next: edit.value,
      );
      changed = true;
    }
    if (!changed) {
      return const Success<void>(null);
    }
    final RecordEntry edited = entry.copyWith(
      values: values,
      updatedAt: clock.nowUtc(),
    );
    _entries[id] = edited.copyWith(name: _nameOf(edited));
    _afterEdit(id, reason: 'Values edited');
    _wrote('editValues', id);
    return const Success<void>(null);
  }

  @override
  Future<Result<TemplateChangePlan>> planTemplateChange(
    String id,
    String templateId,
  ) async {
    final Failure? failure = readFailure;
    if (failure != null) {
      return FailureResult<TemplateChangePlan>(failure);
    }
    return _plan(id, templateId);
  }

  @override
  Future<Result<void>> changeTemplate(String id, String templateId) async {
    final Result<RecordEntry> found = _writable(id);
    if (found case FailureResult<RecordEntry>(:final Failure failure)) {
      return FailureResult<void>(failure);
    }
    final RecordEntry entry = (found as Success<RecordEntry>).value;
    final Result<void> editable = RecordLifecycle.checkEditable(entry.status);
    if (editable is FailureResult<void>) {
      return editable;
    }
    final Result<TemplateChangePlan> planned = _plan(id, templateId);
    if (planned case FailureResult<TemplateChangePlan>(
      :final Failure failure,
    )) {
      return FailureResult<void>(failure);
    }
    final TemplateChangePlan plan =
        (planned as Success<TemplateChangePlan>).value;
    final RecordEntry changed = entry.copyWith(
      templateId: templateId,
      clearTemplateRowId: true,
      updatedAt: clock.nowUtc(),
      values: <RecordValue>[
        for (final RecordValue value in entry.values)
          plan.retired.contains(value.fieldKey)
              ? value.copyWith(retired: true)
              : plan.restored.contains(value.fieldKey)
              ? value.copyWith(retired: false)
              : value,
      ],
    );
    _entries[id] = changed.copyWith(name: _nameOf(changed));
    _log(
      id,
      RecordHistoryKind.templateChanged,
      fieldKey: 'templateId',
      previous: plan.fromTemplateId,
      next: plan.toTemplateId,
    );
    for (final String key in plan.retired) {
      _log(id, RecordHistoryKind.retired, fieldKey: key, previous: 'false');
    }
    for (final String key in plan.restored) {
      _log(id, RecordHistoryKind.retired, fieldKey: key, previous: 'true');
    }
    _afterEdit(id, reason: 'Template changed');
    _wrote('changeTemplate', id);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    final Result<RecordEntry> found = _writable(id);
    if (found case FailureResult<RecordEntry>(:final Failure failure)) {
      return FailureResult<void>(failure);
    }
    final RecordEntry entry = (found as Success<RecordEntry>).value;
    if (reason.trim().isEmpty) {
      return const FailureResult<void>(_needsReason);
    }
    final Result<void> legal = RecordLifecycle.check(
      entry.status,
      RecordStatus.deleted,
    );
    if (legal is FailureResult<void>) {
      return legal;
    }
    _tombs[id] = (at: clock.nowUtc(), reason: reason);
    _setStatus(entry, RecordStatus.deleted, reason: reason);
    _wrote('delete', id);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> restore(String id) async {
    final Result<RecordEntry> found = _writable(id);
    if (found case FailureResult<RecordEntry>(:final Failure failure)) {
      return FailureResult<void>(failure);
    }
    final RecordEntry entry = (found as Success<RecordEntry>).value;
    if (entry.status != RecordStatus.deleted) {
      return const FailureResult<void>(_notInBin);
    }
    RecordStatus? previous;
    for (final RecordHistoryEvent event in historyOf(id).reversed) {
      if (event.kind == RecordHistoryKind.statusChanged &&
          event.next == RecordStatus.deleted.stored) {
        previous = RecordStatus.fromStored(event.previous ?? '');
        break;
      }
    }
    _tombs.remove(id);
    _setStatus(
      entry,
      RecordLifecycle.restoreTarget(RecordStatus.deleted, previous),
      reason: 'Restored',
    );
    _wrote('restore', id);
    return const Success<void>(null);
  }

  // ---------------------------------------------------------------- writes

  Result<RecordEntry> _writable(String id) {
    final Failure? failure = writeFailure ?? failuresById[id];
    if (failure != null) {
      return FailureResult<RecordEntry>(failure);
    }
    final RecordEntry? entry = _entries[id];
    if (entry == null) {
      return const FailureResult<RecordEntry>(_missing);
    }
    return Success<RecordEntry>(entry);
  }

  void _setStatus(RecordEntry entry, RecordStatus to, {String? reason}) {
    final DateTime now = clock.nowUtc();
    _entries[entry.id] = to == RecordStatus.approved
        ? entry.copyWith(
            status: to,
            updatedAt: now,
            approvedAt: now,
            approvedBy: operator,
          )
        : entry.copyWith(status: to, updatedAt: now);
    _log(
      entry.id,
      RecordHistoryKind.statusChanged,
      fieldKey: 'status',
      previous: entry.status.stored,
      next: to.stored,
      reason: reason,
    );
  }

  void _afterEdit(String id, {required String reason}) {
    final RecordEntry entry = _entries[id]!;
    final RecordStatus next = RecordLifecycle.afterEdit(entry.status);
    if (next != entry.status) {
      _setStatus(entry, next, reason: reason);
    }
  }

  Result<TemplateChangePlan> _plan(String id, String templateId) {
    final RecordEntry? entry = _entries[id];
    if (entry == null) {
      return const FailureResult<TemplateChangePlan>(_missing);
    }
    final ({String name, List<String> fieldKeys})? target =
        _templates[templateId];
    if (target == null) {
      return const FailureResult<TemplateChangePlan>(_missingTemplate);
    }
    if (templateId == entry.templateId) {
      return const FailureResult<TemplateChangePlan>(_sameTemplate);
    }
    return Success<TemplateChangePlan>(
      TemplateChangePlan.forValues(
        fromTemplateId: entry.templateId,
        toTemplateId: templateId,
        values: entry.values,
        targetFieldKeys: target.fieldKeys,
      ),
    );
  }

  void _log(
    String id,
    RecordHistoryKind kind, {
    String? fieldKey,
    String? previous,
    String? next,
    String? reason,
    DateTime? at,
  }) {
    final bool flag =
        kind == RecordHistoryKind.retired ||
        kind == RecordHistoryKind.evidenceRemoved;
    _history
        .putIfAbsent(id, () => <RecordHistoryEvent>[])
        .add(
          RecordHistoryEvent(
            id: 'event-${++_nextEvent}',
            at: at ?? clock.nowUtc(),
            kind: kind,
            operator: operator,
            device: deviceId,
            fieldKey: fieldKey,
            previous: previous,
            next: flag ? (previous == 'true' ? 'false' : 'true') : next,
            reason: flag ? kind.name : reason,
          ),
        );
  }

  void _wrote(String method, String id) {
    writes.add((method: method, id: id));
    _emit();
  }

  void _emit() {
    _ordered.clear();
    _bodies.clear();
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  int _allocate(String projectId) {
    final int next = (_lastNumber[projectId] ?? 0) + 1;
    _lastNumber[projectId] = next;
    return next;
  }

  void _raise(String projectId, int number) {
    if ((_lastNumber[projectId] ?? 0) < number) {
      _lastNumber[projectId] = number;
    }
  }

  // ----------------------------------------------------------------- reads

  Future<Result<T>> _read<T>(T Function() read) async {
    final Failure? failure = readFailure;
    if (failure != null) {
      return FailureResult<T>(failure);
    }
    return Success<T>(read());
  }

  Stream<T> _watch<T>(T Function() snapshot) {
    return Stream<T>.multi((MultiStreamController<T> listener) {
      void push() {
        final Failure? failure = readFailure;
        if (failure != null) {
          listener.addError(failure);
        } else {
          listener.add(snapshot());
        }
      }

      push();
      final StreamSubscription<void> changes = _changes.stream.listen(
        (_) => push(),
      );
      listener.onCancel = changes.cancel;
    });
  }

  /// [entry] as a read returns it: with the flags its rows imply.
  RecordEntry _out(RecordEntry entry) {
    final Set<RecordFlag> flags = <RecordFlag>{
      ...entry.flags,
      if (entry.photos.isNotEmpty) RecordFlag.hasPhotos,
      if (entry.values.any((RecordValue value) => value.evidenceRemoved))
        RecordFlag.evidenceRemoved,
    };
    return flags.length == entry.flags.length
        ? entry
        : entry.copyWith(flags: flags);
  }

  bool _listable(RecordEntry entry) =>
      entry.status != RecordStatus.deleted && !_tombs.containsKey(entry.id);

  List<RecordEntry> _matching(
    String projectId,
    RecordFilter filter,
    RecordSort sort,
  ) {
    final String key = jsonEncode(<Object?>[
      projectId,
      filter.toJson(),
      sort.toJson(),
    ]);
    return _ordered.putIfAbsent(key, () {
      final Set<RecordStatus> listed = filter.listedStatuses;
      final List<String> words = <String>[
        for (final String word in searchWords(filter.search))
          if (word.length >= AppConstants.search.minWordLength) word,
      ];
      final List<RecordEntry> rows = <RecordEntry>[
        for (final RecordEntry entry in _entries.values)
          if (entry.projectId == projectId &&
              _listable(entry) &&
              listed.contains(entry.status) &&
              _passes(_out(entry), filter, words))
            entry,
      ];
      return rows..sort((RecordEntry a, RecordEntry b) => _compare(a, b, sort));
    });
  }

  bool _passes(RecordEntry entry, RecordFilter filter, List<String> words) {
    final DateTime? from = filter.capturedFrom;
    final DateTime? to = filter.capturedTo;
    return (filter.templateIds.isEmpty ||
            filter.templateIds.contains(entry.templateId)) &&
        filter.context.entries.every(
          (MapEntry<String, Set<String>> level) =>
              level.value.contains(entry.context[level.key]),
        ) &&
        (from == null || !entry.capturedAt.isBefore(from)) &&
        (to == null || !entry.capturedAt.isAfter(to)) &&
        (filter.operators.isEmpty ||
            filter.operators.contains(entry.capturedBy)) &&
        (filter.conditions.isEmpty ||
            entry.liveValues.any(
              (RecordValue value) =>
                  RecordFilter.conditionFieldKeys.contains(value.fieldKey) &&
                  filter.conditions.contains(value.display),
            )) &&
        entry.flags.containsAll(filter.flags) &&
        (words.isEmpty || words.every(_bodyOf(entry).contains));
  }

  String _bodyOf(RecordEntry entry) {
    return _bodies.putIfAbsent(entry.id, () {
      return foldSearchText(
        <String>[
          entry.name,
          entry.identifier,
          entry.caption,
          for (final RecordValue value in entry.values) ...<String>[
            value.raw,
            value.refined ?? '',
            value.approved ?? '',
          ],
          for (final RecordPhoto photo in entry.photos) photo.caption,
          _searchText[entry.id] ?? '',
        ].join(' '),
      );
    });
  }

  int _compare(RecordEntry a, RecordEntry b, RecordSort sort) {
    final int byKey = switch (sort.key) {
      RecordSortKey.number => (a.number ?? 0).compareTo(b.number ?? 0),
      RecordSortKey.capturedAt => a.capturedAt.compareTo(b.capturedAt),
      RecordSortKey.name => a.name.toLowerCase().compareTo(
        b.name.toLowerCase(),
      ),
    };
    final int order = byKey != 0 ? byKey : a.id.compareTo(b.id);
    return sort.ascending ? order : -order;
  }

  /// The first live value with text, in the template's field order when the
  /// template was seeded, else in value order. A name a test seeded on a
  /// record with no seeded template is kept as it is.
  String _nameOf(RecordEntry entry) {
    final List<String>? keys = _templates[entry.templateId]?.fieldKeys;
    if (keys == null && _namedByTest.contains(entry.id)) {
      return entry.name;
    }
    final Iterable<RecordValue?> ordered = keys == null
        ? entry.liveValues
        : keys.map(entry.valueOf);
    for (final RecordValue? value in ordered) {
      if (value != null && !value.retired && value.hasValue) {
        return value.display;
      }
    }
    return '';
  }

  RecordFacets _derivedFacets(String projectId) {
    final List<RecordEntry> rows = <RecordEntry>[
      for (final RecordEntry entry in _entries.values)
        if (entry.projectId == projectId && _listable(entry)) entry,
    ];
    final Map<String, Set<String>> levels = <String, Set<String>>{};
    for (final RecordEntry entry in rows) {
      entry.context.forEach((String key, String value) {
        if (value.isNotEmpty) {
          levels.putIfAbsent(key, () => <String>{}).add(value);
        }
      });
    }
    return RecordFacets(
      templates: <({String id, String name})>[
        for (final String id in _sorted(
          rows.map((RecordEntry e) => e.templateId),
        ))
          (id: id, name: _templates[id]?.name ?? ''),
      ],
      contextLevels: <({String key, String label, List<String> values})>[
        for (final MapEntry<String, Set<String>> level in levels.entries)
          (
            key: level.key,
            label: contextLevelLabels[level.key] ?? level.key,
            values: _sorted(level.value),
          ),
      ],
      operators: <({String id, String label})>[
        for (final String id in _sorted(
          rows.map((RecordEntry e) => e.capturedBy),
        ))
          (id: id, label: operatorLabels[id] ?? id),
      ],
      conditions: _sorted(<String>[
        for (final RecordEntry entry in rows)
          for (final RecordValue value in entry.liveValues)
            if (RecordFilter.conditionFieldKeys.contains(value.fieldKey) &&
                value.hasValue)
              value.display,
      ]),
      statuses: <RecordStatus>{
        for (final RecordEntry entry in rows) entry.status,
      },
    );
  }

  List<DeletedRecord> _bin() {
    final List<DeletedRecord> rows = <DeletedRecord>[
      for (final RecordEntry entry in _entries.values)
        if (entry.status == RecordStatus.deleted &&
            _tombs[entry.id] != null &&
            _tombs[entry.id]!.reason != projectDeletedReason)
          DeletedRecord(
            summary: _out(entry).toSummary(),
            projectName: _projectNames[entry.projectId] ?? '',
            deletedAt: _tombs[entry.id]!.at,
            reason: _tombs[entry.id]!.reason,
          ),
    ];
    return rows..sort((DeletedRecord a, DeletedRecord b) {
      final int byTime = b.deletedAt.compareTo(a.deletedAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  }
}

List<String> _sorted(Iterable<String> values) =>
    values.toSet().toList()..sort();

const StorageFailure _missing = StorageFailure(
  message: 'That record is no longer on this device.',
  recoveryAction: 'Refresh the list and try again.',
);

const StorageFailure _missingTemplate = StorageFailure(
  message: 'That template is no longer on this device.',
  recoveryAction: 'Choose another template and try again.',
);

const ValidationFailure _sameTemplate = ValidationFailure(
  message: 'This record already uses that template.',
  recoveryAction: 'Choose a different template.',
);

const ValidationFailure _needsProjectAndTemplate = ValidationFailure(
  message: 'A record needs a project and a template.',
  recoveryAction: 'Choose a project and a template, then save again.',
);

const ValidationFailure _needsReason = ValidationFailure(
  message: 'A delete needs a reason.',
  recoveryAction: 'Say why the record should go, then try again.',
);

const ValidationFailure _needsField = ValidationFailure(
  message: 'An edit needs the field it changes.',
  recoveryAction: 'Choose a field, then save again.',
);

const ValidationFailure _useDelete = ValidationFailure(
  message: 'A record goes to the recycle bin only through delete.',
  recoveryAction: 'Use Delete, which lets you undo it.',
);

const ValidationFailure _useRestore = ValidationFailure(
  message: 'This record is in the recycle bin.',
  recoveryAction: 'Restore it from the recycle bin first.',
);

const ValidationFailure _notInBin = ValidationFailure(
  message: 'This record is not in the recycle bin.',
  recoveryAction: 'Refresh the list; it may already be restored.',
);
