import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import 'paths.dart';

/// Checks every locale against the source message and placeholder contract.
List<String> checkCatalogs(Map<String, Map<String, Object?>> catalogs) {
  final Map<String, Object?>? source = catalogs['en'];
  if (source == null) return <String>['Missing English source catalog.'];
  final Set<String> keys = source.keys
      .where((String k) => !k.startsWith('@'))
      .toSet();
  final List<String> problems = <String>[];
  for (final MapEntry<String, Map<String, Object?>> locale
      in catalogs.entries) {
    for (final String key in keys) {
      if (locale.value[key] is! String) {
        problems.add('${locale.key}: missing $key');
      }
      final Object? metadata = locale.value['@$key'];
      if (metadata is! Map ||
          metadata['description'] is! String ||
          (metadata['description']! as String).trim().isEmpty) {
        problems.add('${locale.key}: $key needs a translator description');
        continue;
      }
      final Object? expected = (source['@$key'] as Map?)?['placeholders'];
      final Object? actual = metadata['placeholders'];
      final Set<String> expectedNames = expected is Map
          ? expected.keys.cast<String>().toSet()
          : <String>{};
      final Set<String> actualNames = actual is Map
          ? actual.keys.cast<String>().toSet()
          : <String>{};
      if (expectedNames.difference(actualNames).isNotEmpty ||
          actualNames.difference(expectedNames).isNotEmpty) {
        problems.add('${locale.key}: $key placeholder contract differs');
      }
      for (final String name in actualNames) {
        final Object? placeholder = (actual! as Map)[name];
        if (placeholder is! Map ||
            placeholder['description'] is! String ||
            (placeholder['description']! as String).trim().isEmpty) {
          problems.add('${locale.key}: $key.$name needs a description');
        }
        final Object? expectedPlaceholder = expected is Map
            ? expected[name]
            : null;
        if (placeholder is Map &&
            expectedPlaceholder is Map &&
            placeholder['type'] != expectedPlaceholder['type']) {
          problems.add('${locale.key}: $key.$name type differs');
        }
      }
    }
    for (final String extra
        in locale.value.keys
            .where((String k) => !k.startsWith('@'))
            .toSet()
            .difference(keys)) {
      problems.add('${locale.key}: unknown message $extra');
    }
  }
  return problems;
}

/// Finds visible literals in widget constructor arguments, including composed
/// messages. Empty values, punctuation and dynamic user data remain legal.
List<String> findWidgetLiterals(String source, {String path = 'source.dart'}) {
  final parsed = parseString(content: source, path: path);
  final _Literals visitor = _Literals(path, parsed.lineInfo);
  parsed.unit.accept(visitor);
  return visitor.problems;
}

/// Runs the catalogue and widget checks and reports every violation.
void main() {
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
  final List<String> problems = checkCatalogs(catalogs);
  for (final File file
      in Directory(libRoot)
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (File f) =>
                f.path.endsWith('.dart') &&
                !f.path.contains(
                  '${Platform.pathSeparator}l10n${Platform.pathSeparator}',
                ) &&
                !f.path.endsWith('.g.dart'),
          )) {
    problems.addAll(
      findWidgetLiterals(file.readAsStringSync(), path: file.path),
    );
  }
  for (final String problem in problems) {
    stderr.writeln(problem);
  }
  if (problems.isNotEmpty) exitCode = 1;
}

final class _Literals extends RecursiveAstVisitor<void> {
  _Literals(this.path, this.lineInfo);
  final String path;
  final LineInfo lineInfo;
  final List<String> problems = <String>[];
  static const Set<String> visibleArguments = <String>{
    'label',
    'title',
    'subtitle',
    'headline',
    'message',
    'actionLabel',
    'confirmLabel',
    'cancelLabel',
    'tooltip',
    'semanticLabel',
    'hintText',
    'labelText',
    'helperText',
    'helper',
    'helpText',
    'effect',
    'errorText',
    'description',
    'recoveryAction',
  };
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    check(node.constructorName.type.toSource(), node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null) check(node.methodName.name, node.argumentList);
    super.visitMethodInvocation(node);
  }

  void check(String type, ArgumentList arguments) {
    if (type == 'Text' ||
        type == 'SelectableText' ||
        type.startsWith('App') ||
        type == 'Semantics' ||
        type == 'Tooltip' ||
        type == 'IconButton' ||
        type == 'InputDecoration' ||
        type == 'NavigationDestination' ||
        type == 'NavigationRailDestination') {
      for (final Argument argument in arguments.arguments) {
        final Expression value;
        if (argument is NamedArgument) {
          if (!visibleArguments.contains(argument.name.lexeme)) continue;
          value = argument.argumentExpression;
        } else {
          if (type != 'Text' && type != 'SelectableText') continue;
          value = argument.argumentExpression;
        }
        final _TextSegments segments = _TextSegments();
        value.accept(segments);
        if (segments.segments.any(
          (String text) => RegExp('[A-Za-z]{2}').hasMatch(text),
        )) {
          final int line = lineInfo.getLocation(value.offset).lineNumber;
          problems.add(
            '$path:$line visible widget literal: ${value.toSource()}',
          );
        }
      }
    }
  }
}

final class _TextSegments extends RecursiveAstVisitor<void> {
  final List<String> segments = <String>[];
  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) =>
      segments.add(node.value);
  @override
  void visitInterpolationString(InterpolationString node) =>
      segments.add(node.value);
  @override
  void visitInterpolationExpression(InterpolationExpression node) =>
      node.expression.accept(this);
  @override
  void visitMethodInvocation(MethodInvocation node) {}
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {}
}
