import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import '../../tool/release_gate.dart';

void main() {
  test('a passing table is a zero exit and a failed backend blocks the release', () {
    final Directory out = Directory.systemTemp.createTempSync('gate');
    final Map<String, String> passed = <String, String>{
      for (final String gate in releaseGates) gate: 'passed',
    };
    expect(
      writeReleaseRecord(
        tag: '1.0.0',
        rows: evaluateGates(outcomes: passed),
        out: out,
      ),
      0,
    );
    final Map<String, String> backendDown = <String, String>{...passed}
      ..['backend-contract'] = 'contract mismatch';
    final int blocked = writeReleaseRecord(
      tag: '1.0.1',
      rows: evaluateGates(outcomes: backendDown),
      out: out,
    );
    expect(blocked, 1);
    final String record = File('${out.path}/release-record-1.0.1.md').readAsStringSync();
    expect(record.contains('backend-contract'), isTrue);
    expect(record.contains('contract mismatch'), isTrue);
  });

  test('a skipped gate fails unless it is waived, and the offline gate can block alone', () {
    final Directory out = Directory.systemTemp.createTempSync('gate-waive');
    final Map<String, String> skipped = <String, String>{
      for (final String gate in releaseGates) gate: 'passed',
    }..['secret-scan'] = 'skipped';
    final List<GateRow> failed = evaluateGates(outcomes: skipped);
    expect(
      writeReleaseRecord(tag: '1.0.2', rows: failed, out: out),
      1,
    );
    final List<GateRow> waived = evaluateGates(
      outcomes: skipped,
      waivers: const <String, String>{'secret-scan': 'scanner host was down'},
    );
    expect(writeReleaseRecord(tag: '1.0.3', rows: waived, out: out), 0);
    expect(
      File('${out.path}/release-record-1.0.3.md').readAsStringSync(),
      contains('scanner host was down'),
    );
    final Map<String, String> offline = <String, String>{
      for (final String gate in releaseGates) gate: 'passed',
    }..['signin-proxy-offline'] = 'capture blocked';
    expect(
      writeReleaseRecord(
        tag: '1.0.4',
        rows: evaluateGates(outcomes: offline),
        out: out,
      ),
      1,
    );
  });
}
