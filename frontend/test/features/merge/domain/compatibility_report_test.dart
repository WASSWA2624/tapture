import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/domain.dart';

void main() {
  TemplateMatch match(
    String id, {
    String? localId,
    List<CompatibilityIssue> issues = const <CompatibilityIssue>[],
  }) {
    return TemplateMatch(
      incomingId: id,
      name: id,
      templateKey: 'pump',
      localId: localId,
      issues: <({CompatibilityIssue issue, String field})>[
        for (final CompatibilityIssue issue in issues)
          (issue: issue, field: 'Serial'),
      ],
    );
  }

  test('no issues is compatible', () {
    final CompatibilityReport report = CompatibilityReport(<TemplateMatch>[
      match('a', localId: 'x'),
    ]);
    expect(report.status, CompatibilityStatus.compatible);
    expect(report.canMerge, isTrue);
  });

  test('a warning is compatible with differences, and still merges', () {
    final CompatibilityReport report = CompatibilityReport(<TemplateMatch>[
      match('a', localId: 'x'),
      match(
        'b',
        localId: 'y',
        issues: <CompatibilityIssue>[CompatibilityIssue.changedLabel],
      ),
    ]);
    expect(report.status, CompatibilityStatus.compatibleWithDifferences);
    expect(report.canMerge, isTrue);
  });

  test('one blocker makes the whole report incompatible', () {
    final CompatibilityReport report = CompatibilityReport(<TemplateMatch>[
      match(
        'a',
        localId: 'x',
        issues: <CompatibilityIssue>[CompatibilityIssue.otherVersion],
      ),
      match('b', issues: <CompatibilityIssue>[CompatibilityIssue.noMatch]),
    ]);
    expect(report.status, CompatibilityStatus.incompatible);
    expect(report.canMerge, isFalse);
  });

  test('the mapping holds only matched templates', () {
    final CompatibilityReport report = CompatibilityReport(<TemplateMatch>[
      match('a', localId: 'x'),
      match('b'),
    ]);
    expect(report.mapping, <String, String>{'a': 'x'});
  });
}
