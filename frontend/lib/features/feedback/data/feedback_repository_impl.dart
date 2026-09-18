import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_context.dart';
import '../domain/feedback_entry.dart';
import '../domain/feedback_repository.dart';
import '../domain/removed_feedback.dart';

/// On-device [FeedbackRepository]: a JSON index and PNG screenshots in a
/// [BlobStore]. Feedback is never sent anywhere (FE-SEC-10).
final class FeedbackRepositoryImpl implements FeedbackRepository {
  /// Creates a repository over a [BlobStore].
  FeedbackRepositoryImpl({
    required this._store,
    required this._clock,
    required this._ids,
  });

  /// Durable store named for this install.
  factory FeedbackRepositoryImpl.platform({
    required Clock clock,
    required IdService ids,
  }) {
    return FeedbackRepositoryImpl(
      store: BlobStore.platform(AppConstants.userFeedback.storeName),
      clock: clock,
      ids: ids,
    );
  }

  /// In-memory stand-in so tests never touch a folder or IndexedDB
  /// (FE-TEST-03, FE-STATE-10).
  factory FeedbackRepositoryImpl.memory({
    Clock clock = const SystemClock(),
    IdService? ids,
    Map<String, Uint8List>? backing,
    bool failWrites = false,
  }) {
    return FeedbackRepositoryImpl(
      store: BlobStore.memory(backing: backing, failWrites: failWrites),
      clock: clock,
      ids: ids ?? UuidV7Service.sequence(clock),
    );
  }

  final BlobStore _store;
  final Clock _clock;
  final IdService _ids;

  final StreamController<List<FeedbackEntry>> _updates =
      StreamController<List<FeedbackEntry>>.broadcast();

  List<FeedbackEntry> _entries = <FeedbackEntry>[];
  int _nextNumber = 1;
  bool _loaded = false;

  @override
  Stream<List<FeedbackEntry>> watch() async* {
    await _load();
    yield _snapshot();
    yield* _updates.stream;
  }

  @override
  Future<Result<FeedbackEntry>> add({
    required FeedbackCategory category,
    required String message,
    required FeedbackContext context,
    String? otherCategory,
    Uint8List? screenshot,
    List<Uint8List> screenshots = const <Uint8List>[],
  }) async {
    await _load();
    final String trimmed = message.trim();
    if (trimmed.isEmpty) {
      return const FailureResult<FeedbackEntry>(
        ValidationFailure(
          message: Copy.feedbackMessageRequired,
          recoveryAction: 'Write your feedback, then save again.',
        ),
      );
    }
    final String? other = otherCategory?.trim();
    if (category == FeedbackCategory.other &&
        (other == null || other.isEmpty)) {
      return const FailureResult<FeedbackEntry>(
        ValidationFailure(
          message: Copy.feedbackOtherRequired,
          recoveryAction: 'Name the type, then save again.',
        ),
      );
    }
    final String id = _ids.newId();
    final List<Uint8List> shots = <Uint8List>[
      if (screenshot != null && screenshot.isNotEmpty) screenshot,
      for (final Uint8List extra in screenshots)
        if (extra.isNotEmpty) extra,
    ];
    final bool hasScreenshot = shots.isNotEmpty;
    for (int index = 0; index < shots.length; index++) {
      final Result<void> written = await _store.write(
        _shotKey(id, index),
        shots[index],
      );
      if (written is FailureResult<void>) {
        for (int undo = 0; undo < index; undo++) {
          await _store.remove(_shotKey(id, undo));
        }
        return FailureResult<FeedbackEntry>(written.failure);
      }
    }
    final FeedbackEntry entry = FeedbackEntry(
      id: id,
      number: _nextNumber,
      submittedAtUtc: _clock.nowUtc(),
      category: category,
      otherCategory: category == FeedbackCategory.other ? other : null,
      message: trimmed,
      hasScreenshot: hasScreenshot,
      screenshotCount: shots.length,
      context: context,
    );
    final List<FeedbackEntry> next = <FeedbackEntry>[..._entries, entry];
    final int nextNumber = _nextNumber + 1;
    final Result<void> indexed = await _writeIndex(
      entries: next,
      nextNumber: nextNumber,
    );
    if (indexed is FailureResult<void>) {
      if (hasScreenshot) {
        for (int index = 0; index < shots.length; index++) {
          await _store.remove(_shotKey(id, index));
        }
      }
      return FailureResult<FeedbackEntry>(indexed.failure);
    }
    _entries = next;
    _nextNumber = nextNumber;
    _emit();
    return Success<FeedbackEntry>(entry);
  }

  @override
  Future<Result<Uint8List?>> screenshot(String id) async {
    await _load();
    return _store.read(_shotKey(id, 0));
  }

  @override
  Future<Result<List<Uint8List>>> screenshots(String id) async {
    await _load();
    FeedbackEntry? entry;
    for (final FeedbackEntry row in _entries) {
      if (row.id == id) {
        entry = row;
        break;
      }
    }
    final int count =
        entry?.screenshotCount ?? (entry?.hasScreenshot == true ? 1 : 0);
    if (count <= 0) {
      final Result<Uint8List?> first = await _store.read(_shotKey(id, 0));
      return switch (first) {
        FailureResult<Uint8List?>(:final Failure failure) =>
          FailureResult<List<Uint8List>>(failure),
        Success<Uint8List?>(:final Uint8List? value)
            when value != null && value.isNotEmpty =>
          Success<List<Uint8List>>(<Uint8List>[value]),
        Success<Uint8List?>() => const Success<List<Uint8List>>(<Uint8List>[]),
      };
    }
    final List<Uint8List> shots = <Uint8List>[];
    for (int index = 0; index < count; index++) {
      final Result<Uint8List?> read = await _store.read(_shotKey(id, index));
      switch (read) {
        case FailureResult<Uint8List?>(:final Failure failure):
          return FailureResult<List<Uint8List>>(failure);
        case Success<Uint8List?>(:final Uint8List? value):
          if (value != null && value.isNotEmpty) {
            shots.add(value);
          }
      }
    }
    return Success<List<Uint8List>>(shots);
  }

  @override
  Future<Result<List<RemovedFeedback>>> remove(Set<String> ids) async {
    await _load();
    if (ids.isEmpty) {
      return const Success<List<RemovedFeedback>>(<RemovedFeedback>[]);
    }
    final List<RemovedFeedback> removed = <RemovedFeedback>[];
    for (final FeedbackEntry entry in _entries) {
      if (!ids.contains(entry.id)) {
        continue;
      }
      Uint8List? png;
      final List<Uint8List> extra = <Uint8List>[];
      final int count = entry.screenshotCount > 0 ? entry.screenshotCount : 1;
      for (int index = 0; index < count; index++) {
        final Result<Uint8List?> read = await _store.read(
          _shotKey(entry.id, index),
        );
        switch (read) {
          case FailureResult<Uint8List?>(:final Failure failure):
            return FailureResult<List<RemovedFeedback>>(failure);
          case Success<Uint8List?>(:final Uint8List? value):
            if (value == null || value.isEmpty) {
              continue;
            }
            if (png == null) {
              png = value;
            } else {
              extra.add(value);
            }
        }
      }
      removed.add(
        RemovedFeedback(entry: entry, screenshot: png, extraShots: extra),
      );
    }
    final List<FeedbackEntry> next = <FeedbackEntry>[
      for (final FeedbackEntry entry in _entries)
        if (!ids.contains(entry.id)) entry,
    ];
    final Result<void> indexed = await _writeIndex(
      entries: next,
      nextNumber: _nextNumber,
    );
    if (indexed is FailureResult<void>) {
      return FailureResult<List<RemovedFeedback>>(indexed.failure);
    }
    for (final RemovedFeedback item in removed) {
      final int count = item.entry.screenshotCount > 0
          ? item.entry.screenshotCount
          : 1;
      for (int index = 0; index < count; index++) {
        final Result<void> gone = await _store.remove(
          _shotKey(item.entry.id, index),
        );
        if (gone is FailureResult<void>) {
          return FailureResult<List<RemovedFeedback>>(gone.failure);
        }
      }
    }
    _entries = next;
    _emit();
    return Success<List<RemovedFeedback>>(removed);
  }

  @override
  Future<Result<void>> restore(List<RemovedFeedback> removed) async {
    await _load();
    if (removed.isEmpty) {
      return const Success<void>(null);
    }
    final Map<String, FeedbackEntry> byId = <String, FeedbackEntry>{
      for (final FeedbackEntry entry in _entries) entry.id: entry,
    };
    for (final RemovedFeedback item in removed) {
      final List<Uint8List> shots = <Uint8List>[
        if (item.screenshot != null && item.screenshot!.isNotEmpty)
          item.screenshot!,
        ...item.extraShots.where((Uint8List bytes) => bytes.isNotEmpty),
      ];
      for (int index = 0; index < shots.length; index++) {
        final Result<void> written = await _store.write(
          _shotKey(item.entry.id, index),
          shots[index],
        );
        if (written is FailureResult<void>) {
          return written;
        }
      }
      byId[item.entry.id] = item.entry;
    }
    final List<FeedbackEntry> next = byId.values.toList()
      ..sort(
        (FeedbackEntry a, FeedbackEntry b) => a.number.compareTo(b.number),
      );
    int nextNumber = _nextNumber;
    for (final FeedbackEntry entry in next) {
      if (entry.number >= nextNumber) {
        nextNumber = entry.number + 1;
      }
    }
    final Result<void> indexed = await _writeIndex(
      entries: next,
      nextNumber: nextNumber,
    );
    if (indexed is FailureResult<void>) {
      return indexed;
    }
    _entries = next;
    _nextNumber = nextNumber;
    _emit();
    return const Success<void>(null);
  }

  Future<void> _load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    final Result<Uint8List?> read = await _store.read(_indexKey);
    switch (read) {
      case FailureResult<Uint8List?>():
        _entries = <FeedbackEntry>[];
        _nextNumber = 1;
        return;
      case Success<Uint8List?>(:final Uint8List? value):
        if (value == null || value.isEmpty) {
          _entries = <FeedbackEntry>[];
          _nextNumber = 1;
          return;
        }
        _readIndex(value);
    }
  }

  void _readIndex(Uint8List bytes) {
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      _entries = <FeedbackEntry>[];
      _nextNumber = 1;
      return;
    }
    if (decoded is! Map) {
      _entries = <FeedbackEntry>[];
      _nextNumber = 1;
      return;
    }
    final Map<String, Object?> map = Map<String, Object?>.from(decoded);
    final List<FeedbackEntry> entries = <FeedbackEntry>[];
    final Object? raw = map[_entriesKey];
    if (raw is List) {
      for (final Object? row in raw) {
        final FeedbackEntry? entry = FeedbackEntry.fromJson(row);
        if (entry != null) {
          entries.add(entry);
        }
      }
    }
    entries.sort(
      (FeedbackEntry a, FeedbackEntry b) => a.number.compareTo(b.number),
    );
    final Object? number = map[_nextNumberKey];
    int next = number is int
        ? number
        : number is num
        ? number.round()
        : 1;
    for (final FeedbackEntry entry in entries) {
      if (entry.number >= next) {
        next = entry.number + 1;
      }
    }
    if (next < 1) {
      next = 1;
    }
    _entries = entries;
    _nextNumber = next;
  }

  Future<Result<void>> _writeIndex({
    required List<FeedbackEntry> entries,
    required int nextNumber,
  }) {
    final List<int> bytes = utf8.encode(
      jsonEncode(<String, Object?>{
        _nextNumberKey: nextNumber,
        _entriesKey: <Map<String, Object?>>[
          for (final FeedbackEntry entry in entries) entry.toJson(),
        ],
      }),
    );
    return _store.write(_indexKey, Uint8List.fromList(bytes));
  }

  void _emit() {
    if (!_updates.isClosed) {
      _updates.add(_snapshot());
    }
  }

  List<FeedbackEntry> _snapshot() => List<FeedbackEntry>.unmodifiable(_entries);
}

String _shotKey(String id, [int index = 0]) {
  if (index <= 0) {
    return 'shots/$id.png';
  }
  return 'shots/$id-${index + 1}.png';
}

const String _indexKey = 'index.json';
const String _nextNumberKey = 'next_number';
const String _entriesKey = 'entries';
