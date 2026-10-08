import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Follows local disposable handles and paths to their actual consumers.
final class OwnedResourceFlow {
  OwnedResourceFlow(
    AstNode context, {
    required this.findBinding,
    required this.ownsDirectory,
  }) : unit = context.root as CompilationUnit;

  final CompilationUnit unit;
  final VariableDeclaration? Function(AstNode, String) findBinding;
  final bool Function(Expression, AstNode) ownsDirectory;
  final Set<String> _checking = <String>{};

  bool directory(VariableDeclaration binding) => _directoryUses(
    binding.parent!.parent!.parent!,
    binding.name.lexeme,
    binding: binding,
  );

  bool marker(VariableDeclaration binding) {
    final Expression created = _unwrap(binding.initializer!);
    if (created is! MethodInvocation) return false;
    final Expression? path = _constructorArgument(created.target, 'File');
    if (path == null) return false;
    final String? origin = _ownedChild(path);
    if (origin == null) return false;
    final AstNode scope = binding.parent!.parent!.parent!;
    final _FlowNodes nodes = _nodes(scope);
    // A second handle built from the original path is just as significant as
    // a handle built from marker.path. Follow both, including String aliases.
    for (final Expression expression in <Expression>[
      ...nodes.strings,
      ...nodes.identifiers,
    ]) {
      if (_canonical(expression) == origin &&
          !_within(expression, path) &&
          !_pathUse(expression, allowWrite: false)) {
        return false;
      }
    }
    return _fileUses(scope, binding.name.lexeme, allowWrite: false);
  }

  bool _directoryUses(
    AstNode scope,
    String name, {
    VariableDeclaration? binding,
  }) => _nodes(scope).identifiers
      .where((node) {
        return node.name == name &&
            (binding == null || findBinding(node, name) == binding);
      })
      .every((node) {
        final AstNode? parent = node.parent;
        if (parent is MethodInvocation && identical(parent.target, node)) {
          return const <String>{
            'createTemp',
            'createTempSync',
            'delete',
            'deleteSync',
            'exists',
            'existsSync',
          }.contains(parent.methodName.name);
        }
        final Expression? path = _pathAccess(node);
        if (path != null) {
          final AstNode? interpolation = path.parent;
          if (interpolation is! InterpolationExpression ||
              interpolation.parent is! StringInterpolation) {
            return false;
          }
          final StringInterpolation child =
              interpolation.parent! as StringInterpolation;
          return _ownedChild(child) != null &&
              _pathUse(child, allowWrite: true);
        }
        return _privateDirectoryField(node);
      });

  bool _privateDirectoryField(SimpleIdentifier value) {
    final AstNode? arguments = value.parent;
    if (arguments is! ArgumentList) return false;
    final String? type = _constructorType(arguments.parent);
    if (type == null || !type.startsWith('_')) return false;
    final ClassDeclaration? declaration = unit.declarations
        .whereType<ClassDeclaration>()
        .where((node) => node.namePart.typeName.lexeme == type)
        .firstOrNull;
    if (declaration?.body is! BlockClassBody) return false;
    final BlockClassBody body = declaration!.body as BlockClassBody;
    final ConstructorDeclaration? constructor = body.members
        .whereType<ConstructorDeclaration>()
        .where((node) => node.name == null)
        .firstOrNull;
    final int index = arguments.arguments.indexOf(value);
    if (constructor == null ||
        index >= constructor.parameters.parameters.length) {
      return false;
    }
    final FormalParameter parameter = constructor.parameters.parameters[index];
    if (parameter is! FieldFormalParameter) return false;
    final String field = parameter.name.lexeme;
    final String key = '$type.$field';
    if (!_checking.add(key)) return false;
    final bool safe = _directoryUses(body, field);
    _checking.remove(key);
    return safe;
  }

  bool _fileUses(AstNode scope, String name, {required bool allowWrite}) {
    final String key = '${scope.offset}:$name:$allowWrite';
    if (!_checking.add(key)) return false;
    final bool safe = _nodes(scope).identifiers
        .where((node) => node.name == name)
        .every((node) {
          final AstNode? parent = node.parent;
          if (parent is MethodInvocation && identical(parent.target, node)) {
            final String method = parent.methodName.name;
            if (const <String>{
              'delete',
              'deleteSync',
              'exists',
              'existsSync',
              'length',
              'lengthSync',
              'stat',
              'statSync',
            }.contains(method)) {
              return true;
            }
            if (!allowWrite) return false;
            return const <String>{
              'open',
              'openSync',
              'openRead',
              'readAsBytes',
              'readAsBytesSync',
              'readAsString',
              'readAsStringSync',
              'writeAsBytes',
              'writeAsBytesSync',
              'writeAsString',
              'writeAsStringSync',
            }.contains(method);
          }
          final Expression? path = _pathAccess(node);
          if (path != null) return _pathUse(path, allowWrite: allowWrite);
          return allowWrite && _privateFileReader(node);
        });
    _checking.remove(key);
    return safe;
  }

  bool _pathUse(Expression value, {required bool allowWrite}) {
    AstNode at = value;
    while (at.parent is ParenthesizedExpression ||
        at.parent is AsExpression ||
        at.parent is PostfixExpression) {
      at = at.parent!;
    }
    final AstNode? parent = at.parent;
    if (parent is VariableDeclaration && identical(parent.initializer, at)) {
      final VariableDeclarationList list =
          parent.parent! as VariableDeclarationList;
      if (!list.isFinal) return false;
      final String name = parent.name.lexeme;
      return _nodes(parent.parent!.parent!.parent!).identifiers
          .where((node) => findBinding(node, name) == parent)
          .every((node) => _pathUse(node, allowWrite: allowWrite));
    }
    if (parent is ArgumentList) {
      final String? type = _constructorType(parent.parent);
      if (type == 'File' && parent.arguments.first == at) {
        return _constructedFile(parent.parent!, allowWrite: allowWrite);
      }
      if (allowWrite &&
          (type == 'InputFileStream' || type == 'FileHandle') &&
          _importsArchive()) {
        return true;
      }
      if (allowWrite && type != null && type.startsWith('_')) {
        return _privatePathSink(at, parent, type);
      }
      return false;
    }
    if (parent is ListLiteral || parent is MapLiteralEntry) {
      return _workerMessage(at, parent!);
    }
    return false;
  }

  bool _constructedFile(AstNode construction, {required bool allowWrite}) {
    final AstNode? parent = construction.parent;
    if (parent is MethodInvocation &&
        identical(parent.target, construction) &&
        (parent.methodName.name == 'create' ||
            parent.methodName.name == 'createSync')) {
      AstNode result = parent;
      if (result.parent is AwaitExpression) result = result.parent!;
      final AstNode? assigned = result.parent;
      if (assigned is! VariableDeclaration ||
          !(assigned.parent! as VariableDeclarationList).isFinal) {
        return false;
      }
      return _fileUses(
        assigned.parent!.parent!.parent!,
        assigned.name.lexeme,
        allowWrite: allowWrite,
      );
    }
    if (parent is VariableDeclaration) {
      final VariableDeclarationList list =
          parent.parent! as VariableDeclarationList;
      return list.isFinal &&
          _fileUses(
            parent.parent!.parent!.parent!,
            parent.name.lexeme,
            allowWrite: allowWrite,
          );
    }
    if (parent is MethodInvocation && identical(parent.target, construction)) {
      return (allowWrite &&
              const <String>{
                'writeAsStringSync',
                'writeAsBytesSync',
                'writeAsString',
                'writeAsBytes',
              }.contains(parent.methodName.name)) ||
          const <String>{
            'exists',
            'existsSync',
            'length',
            'lengthSync',
            'stat',
            'statSync',
          }.contains(parent.methodName.name);
    }
    return false;
  }

  bool _privatePathSink(AstNode value, ArgumentList arguments, String type) {
    final ClassDeclaration? declaration = unit.declarations
        .whereType<ClassDeclaration>()
        .where((node) => node.namePart.typeName.lexeme == type)
        .firstOrNull;
    if (declaration?.body is! BlockClassBody) return false;
    final BlockClassBody body = declaration!.body as BlockClassBody;
    final ConstructorDeclaration? constructor = body.members
        .whereType<ConstructorDeclaration>()
        .where((node) => node.name == null)
        .firstOrNull;
    final int index = arguments.arguments.indexOf(value as Expression);
    if (constructor == null ||
        index >= constructor.parameters.parameters.length) {
      return false;
    }
    final String? name = constructor.parameters.parameters[index].name?.lexeme;
    if (name == null) return false;
    return _nodes(constructor).identifiers
        .where((node) => node.name == name)
        .every((node) => _pathUse(node, allowWrite: true));
  }

  bool _privateFileReader(SimpleIdentifier value) {
    final AstNode? arguments = value.parent;
    if (arguments is! ArgumentList || arguments.parent is! MethodInvocation) {
      return false;
    }
    final MethodInvocation call = arguments.parent! as MethodInvocation;
    final FunctionBody? body = _localBody(call.methodName.name);
    final FormalParameterList? parameters = _localParameters(
      call.methodName.name,
    );
    final int index = arguments.arguments.indexOf(value);
    if (body == null ||
        parameters == null ||
        index >= parameters.parameters.length) {
      return false;
    }
    final String? name = parameters.parameters[index].name?.lexeme;
    if (name == null) return false;
    return _nodes(body).identifiers.where((node) => node.name == name).every((
      node,
    ) {
      final AstNode? parent = node.parent;
      if (parent is MethodInvocation && identical(parent.target, node)) {
        return const <String>{
              'openSync',
              'openRead',
              'lengthSync',
              'existsSync',
            }.contains(parent.methodName.name) &&
            !parent.argumentList.arguments.any((argument) {
              return argument is NamedArgument &&
                  argument.name.lexeme == 'mode' &&
                  argument.argumentExpression.toSource() != 'FileMode.read';
            });
      }
      final Expression? path = _pathAccess(node);
      if (path == null || path.parent is! ArgumentList) return false;
      return _constructorType(path.parent!.parent) == 'InputFileStream' &&
          _importsArchive();
    });
  }

  bool _workerMessage(AstNode value, AstNode container) {
    final String slot;
    final AstNode message;
    if (container is ListLiteral) {
      slot = container.elements.indexOf(value as CollectionElement).toString();
      message = container;
    } else if (container is MapLiteralEntry) {
      slot = container.key.toSource();
      message = container.parent!;
    } else {
      return false;
    }
    final AstNode? arguments = message.parent;
    if (arguments is! ArgumentList || arguments.parent is! MethodInvocation) {
      return false;
    }
    final MethodInvocation run = arguments.parent! as MethodInvocation;
    if (run.methodName.name != 'runIsolate' ||
        arguments.arguments.length < 2 ||
        arguments.arguments[1] != message ||
        arguments.arguments.first is! SimpleIdentifier ||
        !_imports('package:tapture/core/concurrency/isolate_runner.dart')) {
      return false;
    }
    return _workerRead(
      (arguments.arguments.first as SimpleIdentifier).name,
      0,
      slot,
    );
  }

  bool _workerRead(String function, int parameter, String slot) {
    final FunctionBody? body = _localBody(function);
    final FormalParameterList? parameters = _localParameters(function);
    if (body == null ||
        parameters == null ||
        parameter >= parameters.parameters.length) {
      return false;
    }
    final String? name = parameters.parameters[parameter].name?.lexeme;
    final String key = '$function:$parameter:$slot';
    if (name == null || !_checking.add(key)) return false;
    final bool safe = _nodes(body).identifiers
        .where((node) => node.name == name)
        .every((node) {
          final AstNode? parent = node.parent;
          if (parent is IndexExpression && identical(parent.target, node)) {
            return parent.index.toSource() != slot || _leaseRead(parent);
          }
          if (parent is ArgumentList && parent.parent is MethodInvocation) {
            final MethodInvocation call = parent.parent! as MethodInvocation;
            if (call.target != null) return false;
            return _workerRead(
              call.methodName.name,
              parent.arguments.indexOf(node),
              slot,
            );
          }
          return false;
        });
    _checking.remove(key);
    return safe;
  }

  bool _leaseRead(Expression indexed) {
    AstNode at = indexed;
    while (at.parent is AsExpression ||
        at.parent is PostfixExpression ||
        at.parent is ParenthesizedExpression) {
      at = at.parent!;
    }
    if (at.parent is! ArgumentList ||
        _constructorType(at.parent!.parent) != 'File') {
      return false;
    }
    final AstNode? named = at.parent!.parent!.parent;
    return named is NamedArgument &&
        named.name.lexeme == 'lease' &&
        named.parent is ArgumentList &&
        _constructorType(named.parent!.parent) == 'WorkerCancellation' &&
        _imports('package:tapture/core/concurrency/worker_cancellation.dart') &&
        !unit.declarations.whereType<ClassDeclaration>().any(
          (node) => node.namePart.typeName.lexeme == 'WorkerCancellation',
        );
  }

  String? _ownedChild(Expression value) {
    final Expression path = _unwrap(value);
    if (path is SimpleIdentifier) {
      final VariableDeclaration? binding = findBinding(path, path.name);
      if (binding == null ||
          binding.initializer == null ||
          !(binding.parent! as VariableDeclarationList).isFinal) {
        return null;
      }
      return _ownedChild(binding.initializer!);
    }
    if (path is! StringInterpolation) return null;
    final List<InterpolationElement> parts = path.elements.where((element) {
      return element is! InterpolationString || element.value.isNotEmpty;
    }).toList();
    if (parts.length != 2 ||
        parts.first is! InterpolationExpression ||
        parts.last is! InterpolationString) {
      return null;
    }
    final Expression root = (parts.first as InterpolationExpression).expression;
    final String suffix = (parts.last as InterpolationString).value;
    final Expression? receiver = _pathReceiver(root);
    if (receiver == null ||
        !ownsDirectory(receiver, path) ||
        !suffix.startsWith('/') ||
        suffix.length < 2 ||
        suffix.split(RegExp(r'[/\\]')).any((part) => part == '..')) {
      return null;
    }
    return _canonical(path);
  }

  String? _canonical(Expression value) {
    final Expression path = _unwrap(value);
    if (path is SimpleIdentifier) {
      final VariableDeclaration? binding = findBinding(path, path.name);
      if (binding?.initializer == null ||
          !(binding!.parent! as VariableDeclarationList).isFinal) {
        return null;
      }
      return _canonical(binding.initializer!);
    }
    if (path is StringInterpolation) return path.toSource();
    return null;
  }

  FunctionBody? _localBody(String name) {
    final _FlowNodes nodes = _nodes(unit);
    return nodes.functions
            .where((node) => node.name.lexeme == name)
            .map((node) => node.functionExpression.body)
            .firstOrNull ??
        nodes.methods
            .where((node) => node.name.lexeme == name)
            .map((node) => node.body)
            .firstOrNull;
  }

  FormalParameterList? _localParameters(String name) {
    final _FlowNodes nodes = _nodes(unit);
    return nodes.functions
            .where((node) => node.name.lexeme == name)
            .map((node) => node.functionExpression.parameters)
            .firstOrNull ??
        nodes.methods
            .where((node) => node.name.lexeme == name)
            .map((node) => node.parameters)
            .firstOrNull;
  }

  bool _imports(String uri) => unit.directives.whereType<ImportDirective>().any(
    (directive) => directive.uri.stringValue == uri,
  );

  bool _importsArchive() => _imports('package:archive/archive_io.dart');

  static Expression? _pathAccess(SimpleIdentifier node) {
    final AstNode? parent = node.parent;
    return switch (parent) {
      PrefixedIdentifier(:final prefix, :final identifier)
          when identical(prefix, node) && identifier.name == 'path' =>
        parent,
      PropertyAccess(:final target, :final propertyName)
          when identical(target, node) && propertyName.name == 'path' =>
        parent,
      _ => null,
    };
  }

  static Expression? _pathReceiver(Expression value) => switch (value) {
    PrefixedIdentifier(:final prefix, :final identifier)
        when identifier.name == 'path' =>
      prefix,
    PropertyAccess(:final target, :final propertyName)
        when propertyName.name == 'path' =>
      target,
    _ => null,
  };

  static String? _constructorType(AstNode? value) => switch (value) {
    InstanceCreationExpression(:final constructorName) =>
      constructorName.type.toSource(),
    MethodInvocation(:final target, :final methodName) when target == null =>
      methodName.name,
    _ => null,
  };

  static Expression? _constructorArgument(Expression? value, String type) {
    if (_constructorType(value) != type) return null;
    final Argument? first = switch (value) {
      InstanceCreationExpression(:final argumentList) =>
        argumentList.arguments.firstOrNull,
      MethodInvocation(:final argumentList) =>
        argumentList.arguments.firstOrNull,
      _ => null,
    };
    return first is Expression ? first : null;
  }

  static Expression _unwrap(Expression value) => switch (value) {
    AwaitExpression(:final expression) => _unwrap(expression),
    ParenthesizedExpression(:final expression) => _unwrap(expression),
    _ => value,
  };

  static bool _within(AstNode value, AstNode container) =>
      value.offset >= container.offset && value.end <= container.end;

  static _FlowNodes _nodes(AstNode node) {
    final _FlowNodes nodes = _FlowNodes();
    node.accept(nodes);
    return nodes;
  }
}

final class _FlowNodes extends RecursiveAstVisitor<void> {
  final List<SimpleIdentifier> identifiers = <SimpleIdentifier>[];
  final List<StringInterpolation> strings = <StringInterpolation>[];
  final List<FunctionDeclaration> functions = <FunctionDeclaration>[];
  final List<MethodDeclaration> methods = <MethodDeclaration>[];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    identifiers.add(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    strings.add(node);
    super.visitStringInterpolation(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    functions.add(node);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    methods.add(node);
    super.visitMethodDeclaration(node);
  }
}
