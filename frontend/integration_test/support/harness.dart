import 'dart:io';

import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/export/csv_writer.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/context/data/context_record_writer.dart';
import 'package:tapture/features/context/data/context_repository_impl.dart';
import 'package:tapture/features/meetings/data/meeting_repository_impl.dart';
import 'package:tapture/features/records/data/record_repository_impl.dart';
import 'package:tapture/features/records/domain/record_entry.dart';
import 'package:tapture/features/records/domain/record_value.dart';

import '../../test/features/records/data/record_read_seeds.dart';
import '../../test/support/fakes.dart';
import '../../test/support/matchers.dart';

/// A clock a test moves. Every stamp in the booted app reads it.
final class TestClock implements Clock {
  /// Starts at [start].
  TestClock(DateTime start) : _now = start.toUtc();

  DateTime _now;

  @override
  Duration offset = Duration.zero;

  /// Moves the clock forward.
  void advance(Duration by) {
    _now = _now.add(by);
  }

  @override
  DateTime nowUtc() => _now;

  @override
  DateTime today() {
    final DateTime local = nowUtc().add(offset);
    return DateTime.utc(local.year, local.month, local.day);
  }
}

/// The real app's database and services, with the network refused.
final class TestApp {
  TestApp._({
    required this.db,
    required this.clock,
    required this.ai,
    required this.backend,
    required this.socket,
    required this.records,
    required this.meetings,
    required this.context,
    required this.contextRecords,
    required this._callsAtBoot,
  });

  /// In-memory database.
  final AppDatabase db;

  /// Clock the stores stamp with.
  final TestClock clock;

  /// Fake analysis. It never leaves the device.
  final FakeAiService ai;

  /// Fake organisation server.
  final FakeBackend backend;

  /// Counts and refuses every real connection: dart:io HTTP clients and raw
  /// sockets are routed to it while any test app is booted.
  final SocketGuard socket;

  final int _callsAtBoot;

  /// Records store.
  final RecordRepositoryImpl records;

  /// Meetings store.
  final MeetingRepositoryImpl meetings;

  /// Project context.
  final ContextRepositoryImpl context;

  /// Per-record context writes.
  final ContextRecordWriter contextRecords;

  /// Real outbound attempts since this app booted, from any code in the
  /// process. Zero is the offline contract.
  int get outboundCallCount => socket.calls - _callsAtBoot;

  /// Closes the database.
  Future<void> dispose() => db.close();

  /// Saves one draft and returns the stored entry.
  Future<RecordEntry> capture({
    Map<String, String>? fields,
    Map<String, String>? context,
    String templateId = 'template-1',
  }) async {
    final RecordEntry saved = valueOf(
      await records.save((
        projectId: 'project-1',
        templateId: templateId,
        fields: fields ?? const <String, String>{'serial': 'A-1'},
        context: context ?? const <String, String>{},
      )),
    );
    return saved;
  }

  /// Moves a draft through review to approved and reads it back.
  Future<RecordEntry> approve(String id) async {
    valueOf(await records.transition(id, RecordStatus.needsReview));
    valueOf(await records.transition(id, RecordStatus.approved));
    final RecordEntry? loaded = valueOf(await records.byId(id));
    if (loaded == null) {
      throw StateError('The record was not in the database.');
    }
    return loaded;
  }

  /// One export row rebuilt from the database, not from screen state.
  ExportRecord rowOf(RecordEntry entry) {
    return ExportRecord(
      id: entry.id,
      number: '${entry.number ?? ''}',
      templateId: entry.templateId,
      templateName: 'Meters',
      status: entry.status.name,
      approved: entry.status == RecordStatus.approved,
      values: <ExportValue>[
        for (final RecordValue value in entry.values)
          (
            key: value.fieldKey,
            label: value.fieldKey,
            type: 'text',
            raw: value.raw,
            refined: value.refined,
            finalText: value.display,
            unit: null,
            code: null,
            confidence: null,
            evidence: null,
          ),
      ],
    );
  }

  /// Builds the CSV the export writers emit for [rows].
  String csvFor(List<ExportRecord> rows) {
    return CsvWriter.write(_request(rows)).values.single;
  }

  ExportRequest _request(List<ExportRecord> rows) {
    return ExportRequest(
      projectId: 'project-1',
      formats: <ExportFormat>{ExportFormat.csv},
      scope: (
        kind: ExportScopeKind.all,
        context: null,
        from: null,
        to: null,
        filter: null,
      ),
      columns: (raw: true, refined: true, confidence: false, evidence: false),
      extras: (
        dictionary: false,
        photoIndex: false,
        photoMode: 'filename',
        pdfPhotos: 'thumbnail',
        delimiter: ',',
      ),
      records: rows,
    );
  }
}

/// Boots the app against an in-memory database. The network stays refused.
Future<TestApp> bootTestApp({DateTime? now}) async {
  final TestClock clock = TestClock(now ?? DateTime.utc(2026, 9, 28));
  final AppDatabase db = AppDatabase.memory();
  final IdService ids = UuidV7Service.sequence(clock);
  _refuseNetwork();
  await seedProjectRow(db, 'project-1', name: 'Field');
  await seedTemplateRow(
    db,
    'template-1',
    projectId: 'project-1',
    name: 'Meters',
    fields: <String>['serial', 'district', 'site'],
    identity: <String>['serial'],
  );
  return TestApp._(
    db: db,
    clock: clock,
    ai: FakeAiService(),
    backend: FakeBackend(),
    socket: _network,
    callsAtBoot: _network.calls,
    records: RecordRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
      operatorName: () => 'Ada',
    ),
    meetings: MeetingRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
    ),
    context: ContextRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
    ),
    contextRecords: ContextRecordWriter(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
      operator: 'Ada',
    ),
  );
}

/// The guard every booted app shares: the network is refused process-wide,
/// so a call from any layer is counted, not only one a fake reports.
final SocketGuard _network = SocketGuard();

bool _refusing = false;

/// Routes dart:io HTTP connections and raw sockets to [_network], once.
void _refuseNetwork() {
  if (_refusing) {
    return;
  }
  _refusing = true;
  HttpOverrides.global = _RefusedHttp();
  IOOverrides.global = _RefusedSockets();
}

/// Every HTTP client connects through [_network], which refuses it.
final class _RefusedHttp extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionFactory = (Uri url, String? _, int? _) async =>
          _network.block(url.host);
  }
}

/// Raw socket connections are refused through [_network].
final class _RefusedSockets extends IOOverrides {
  @override
  Future<Socket> socketConnect(
    Object? host,
    int port, {
    Object? sourceAddress,
    int sourcePort = 0,
    Duration? timeout,
  }) async => _network.block('$host:$port');

  @override
  Future<ConnectionTask<Socket>> socketStartConnect(
    Object? host,
    int port, {
    Object? sourceAddress,
    int sourcePort = 0,
  }) async => _network.block('$host:$port');
}
