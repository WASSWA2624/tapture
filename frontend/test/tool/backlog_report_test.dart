import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import '../../tool/backlog_report.dart';

void main() {
  test('groups unticked tasks and keeps a waiver and a friction entry', () {
    final Directory plan = Directory.systemTemp.createTempSync('plan');
    Directory('${plan.path}/01-setup').createSync();
    File('${plan.path}/01-setup/001.md').writeAsStringSync(
      '# 01 — Setup\n\n- [ ] First task\nbecause: waiting on a design\n- [ ] Bare task\n',
    );
    Directory('${plan.path}/02-later').createSync();
    File('${plan.path}/02-later/002.md').writeAsStringSync(
      '# 02 — Later\n\n- [x] Done\n- [ ] Second task\nbecause: after the first\n',
    );
    final File friction = File('${plan.path}/friction.md')
      ..writeAsStringSync('- 2026-09-01 | Capture | slow save | after indexing\n');
    final File record = File('${plan.path}/release.md')
      ..writeAsStringSync('| secret-scan | waived | scanner host was down |\n');
    final List<BacklogItem> items = collectBacklog(
      plan: plan,
      friction: friction,
      releaseRecord: record,
    );
    writeBacklog(items, out: plan);
    final String report = File('${plan.path}/backlog.md').readAsStringSync();
    expect(report.indexOf('## 01'), lessThan(report.indexOf('## 02')));
    expect(report.contains('First task'), isTrue);
    expect(report.contains('waiting on a design'), isTrue);
    expect(report.contains('defect: no deferral reason'), isTrue);
    expect(report.contains('slow save'), isTrue);
    expect(report.contains('secret-scan'), isTrue);
    expect(report.contains('scanner host was down'), isTrue);
    expect(report.contains('Done'), isFalse);
  });
}
