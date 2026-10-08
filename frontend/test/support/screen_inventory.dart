import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Routed production widgets and their data-backed collection views.
/// Discovery follows widget constructors into their presentation components;
/// a new routed collection therefore needs a fixture without a waiver list.
final class ScreenInventory {
  ScreenInventory._(this.routed, this.collections);

  /// Reads the real router and production presentation sources once per suite.
  factory ScreenInventory.read(Directory root) {
    final Map<String, String> sources = <String, String>{};
    for (final FileSystemEntity entity in Directory(
      '${root.path}/lib/features',
    ).listSync(recursive: true)) {
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          entity.path.replaceAll(r'\', '/').contains('/presentation/')) {
        sources[entity.path] = entity.readAsStringSync();
      }
    }
    return ScreenInventory.fromSources(
      router: File('${root.path}/lib/app/router.dart').readAsStringSync(),
      sources: sources,
    );
  }

  /// In-memory source seam proves discovery over new screens and delegation.
  factory ScreenInventory.fromSources({
    required String router,
    required Map<String, String> sources,
  }) {
    final Map<String, _ScreenClass> classes = <String, _ScreenClass>{};
    final Map<String, Map<String, _ScreenClass>> files =
        <String, Map<String, _ScreenClass>>{};
    for (final MapEntry<String, String> file in sources.entries) {
      final CompilationUnit unit = parseString(content: file.value).unit;
      final Map<String, _ScreenClass> local = <String, _ScreenClass>{};
      for (final ClassDeclaration declaration
          in unit.declarations.whereType<ClassDeclaration>()) {
        if (!_widgetClass.hasMatch(declaration.toSource())) continue;
        // Follow rendered widgets, not constructors in navigation callbacks,
        // export sheets or other intents that open a different screen.
        final ClassBody body = declaration.body;
        final Iterable<ClassMember> members = body is BlockClassBody
            ? body.members
            : const <ClassMember>[];
        final List<MethodDeclaration> rendered = members
            .whereType<MethodDeclaration>()
            .where(
              (MethodDeclaration method) =>
                  method.name.lexeme == 'build' ||
                  method.name.lexeme == 'createState' ||
                  method.returnType?.toSource() == 'Widget',
            )
            .toList();
        final _ScreenClass type = _ScreenClass(
          name: declaration.namePart.typeName.lexeme,
          file: file.key,
          source: rendered
              .map((MethodDeclaration method) => method.toSource())
              .join('\n'),
          hasEmptyCollectionBranch: rendered.any(_hasEmptyCollectionBranch),
        );
        local[type.name] = type;
        if (!type.name.startsWith('_')) classes[type.name] = type;
      }
      files[file.key] = local;
    }
    final Set<String> routed = <String>{
      for (final String called in _calls(router))
        if (classes.containsKey(called)) called,
    };
    final Set<String> collections = <String>{};
    for (final String screen in routed) {
      final List<_ScreenClass> pending = <_ScreenClass>[classes[screen]!];
      final Set<String> visited = <String>{};
      while (pending.isNotEmpty) {
        final _ScreenClass type = pending.removeLast();
        if (!visited.add('${type.file}:${type.name}')) continue;
        if (type.hasEmptyCollectionBranch ||
            _collection.hasMatch(type.source)) {
          collections.add(screen);
        }
        for (final String called in _calls(type.source)) {
          final _ScreenClass? component =
              files[type.file]?[called] ?? classes[called];
          if (component != null) pending.add(component);
        }
      }
    }
    return ScreenInventory._(
      Set<String>.unmodifiable(routed),
      Set<String>.unmodifiable(collections),
    );
  }

  /// Every widget constructor the production router builds.
  final Set<String> routed;

  /// Routes backed by async lists, row builders or empty collection counts.
  final Set<String> collections;

  /// Reports all missing fixtures, rather than only the first new route.
  List<String> missingFixtures(Iterable<String> fixtures) {
    return collections.difference(fixtures.toSet()).toList()..sort();
  }
}

final class _ScreenClass {
  const _ScreenClass({
    required this.name,
    required this.file,
    required this.source,
    required this.hasEmptyCollectionBranch,
  });

  final String name;
  final String file;
  final String source;
  final bool hasEmptyCollectionBranch;
}

bool _hasEmptyCollectionBranch(MethodDeclaration method) {
  final _EmptyCollectionVisitor visitor = _EmptyCollectionVisitor();
  method.accept(visitor);
  return visitor.found;
}

/// A summary or workbook can hold a collection without being `List<T>` itself.
/// Nullable owner/detail states and embedded empty form sections do not make
/// the enclosing route a collection: this follows explicit isEmpty predicates.
final class _EmptyCollectionVisitor extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitNamedArgument(NamedArgument node) {
    _check(node.name.lexeme, node.argumentExpression);
    super.visitNamedArgument(node);
  }

  @override
  void visitRecordLiteralNamedField(RecordLiteralNamedField node) {
    _check(node.name.lexeme, node.fieldExpression);
    super.visitRecordLiteralNamedField(node);
  }

  void _check(String name, Expression expression) {
    if (name == 'isEmpty' &&
        _collectionAbsence.hasMatch(expression.toSource())) {
      found = true;
    }
  }
}

Iterable<String> _calls(String source) =>
    _constructor.allMatches(source).map((RegExpMatch match) => match.group(1)!);

final RegExp _constructor = RegExp(r'\b([A-Za-z_]\w*)\s*(?:<[^;{}]*?>)?\s*\(');
final RegExp _widgetClass = RegExp(
  r'extends\s+(?:ConsumerWidget|ConsumerStatefulWidget|StatelessWidget|'
  r'StatefulWidget|ConsumerState\s*<|State\s*<)',
);
final RegExp _collection = RegExp(
  r'AsyncValueView\s*<\s*List\s*<|PagedListView\s*\(|'
  r'(?:ListView|GridView|SliverList)\.(?:builder|separated)\s*\(|'
  r'\.(?:fields|rows|events|entries|presets|items|levels|templates)\.isEmpty',
);
final RegExp _collectionAbsence = RegExp(r'\.isEmpty\b|==\s*0\b|\b0\s*==');
