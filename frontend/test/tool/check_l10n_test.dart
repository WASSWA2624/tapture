import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_l10n.dart';
import '../../tool/generate_pseudo_locale.dart';

void main() {
  test('every shipped locale has every described message and placeholder', () {
    final Map<String, Map<String, Object?>> catalogs =
        <String, Map<String, Object?>>{};
    for (final File file in Directory(
      'lib/core/copy/l10n',
    ).listSync().whereType<File>().where((File f) => f.path.endsWith('.arb'))) {
      final Map<String, Object?> catalog = Map<String, Object?>.from(
        jsonDecode(file.readAsStringSync()) as Map,
      );
      catalogs[catalog['@@locale']! as String] = catalog;
    }
    expect(checkCatalogs(catalogs), isEmpty);
  });
  test('missing messages and broken placeholder metadata all fail', () {
    final List<String> errors = checkCatalogs(<String, Map<String, Object?>>{
      'en': <String, Object?>{
        'title': 'Projects',
        '@title': <String, Object?>{'description': 'The project list.'},
        'count': '{n} records',
        '@count': <String, Object?>{
          'description': 'Record count.',
          'placeholders': <String, Object?>{
            'n': <String, Object?>{'description': 'Number of records.'},
          },
        },
      },
      'xx': <String, Object?>{
        'title': 'Projects',
        '@title': <String, Object?>{},
        'extra': 'Unknown',
      },
    });
    expect(errors, contains('xx: missing count'));
    expect(errors, contains('xx: title needs a translator description'));
    expect(errors, contains('xx: unknown message extra'));
    expect(errors.length, greaterThan(2));
  });
  test('visible literals fail with file and line while user data passes', () {
    final List<String> errors = findWidgetLiterals(r'''
Widget build(BuildContext context) => Column(children: [
  Text('A visible literal'),
  AppBanner(message: 'Try again'),
  const Semantics(label: 'Open the project'),
  Text(name),
  Text('${name} · ${number}'),
  Text(Copy.of(context).navProjects),
]);
''', path: 'fixture.dart');
    expect(errors, hasLength(3));
    expect(
      errors.every((String error) => error.startsWith('fixture.dart:')),
      isTrue,
    );
    expect(findWidgetLiterals("Widget build() => const Text('');"), isEmpty);
  });
  test(
    'nested interpolation conditionals and null fallbacks are visible literals',
    () {
      expect(
        findWidgetLiterals(
          r'''Widget build() => Text('${ok ? "Done" : "Waiting"}');''',
        ),
        isNotEmpty,
      );
      expect(
        findWidgetLiterals(
          r'''Widget build() => Text('${name ?? "Unnamed project"}');''',
        ),
        isNotEmpty,
      );
      expect(
        findWidgetLiterals(
          r"Widget build() => Text('${Copy.of(context).ok}');",
        ),
        isEmpty,
      );
      expect(
        findWidgetLiterals(r"Widget build() => Text('${name ?? otherName}');"),
        isEmpty,
      );
    },
  );
  test(
    'pseudo copy expands 35 percent and preserves ICU and user data slots',
    () {
      const String plain = 'Open this project';
      expect(
        pseudoMessage(plain).runes.length,
        greaterThanOrEqualTo((plain.runes.length * 1.35).ceil()),
      );
      final String count = pseudoMessage(
        '{n, plural, =0{No records} one{One record} other{{n} records}}',
      );
      expect(count, contains('{n, plural,'));
      expect(count, contains('=0{'));
      expect(count, contains('{n}'));
      expect(pseudoMessage('Open {name}'), contains('{name}'));
      expect(pseudoMessage("Don''t remove '{'name'}'"), contains("'{'"));
    },
  );
}
