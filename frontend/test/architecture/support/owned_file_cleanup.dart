import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Proves local disposable ownership without trusting a filename or directory.
abstract final class OwnedFileCleanup {
  /// Fresh temporary roots, empty exclusive markers and failed exclusive writes
  /// may clean up their own resources. Aliases and reassigned paths do not qualify.
  static bool permits(MethodInvocation removal) {
    final Expression? target = removal.target;
    if (target is! SimpleIdentifier) return false;
    final String name = target.name;
    final VariableDeclaration? binding = _binding(removal, name);
    if (binding != null) {
      final VariableDeclarationList declarations =
          binding.parent! as VariableDeclarationList;
      final Expression? initializer = binding.initializer;
      if (declarations.isFinal &&
          initializer != null &&
          !_mutated(binding.parent!.parent!, name)) {
        final Expression created = _unwrap(initializer);
        if (created is MethodInvocation &&
            ((declarations.type?.toSource() == 'Directory' &&
                    (created.methodName.name == 'createTemp' ||
                        created.methodName.name == 'createTempSync') &&
                    _isIoType(created.target, 'Directory', created)) ||
                (declarations.type?.toSource() == 'File' &&
                    _exclusive(created) &&
                    _constructs(created.target, 'File') &&
                    _emptyMarker(binding, name)))) {
          return true;
        }
      }
    }
    return _guardedExclusiveWrite(removal, name);
  }

  static bool _guardedExclusiveWrite(MethodInvocation removal, String name) {
    final AstNode owner = _execution(removal);
    if (!_isIoType(removal.target, 'File', removal) || _mutated(owner, name)) {
      return false;
    }
    final _Nodes nodes = _Nodes();
    owner.accept(nodes);
    for (final MethodInvocation create in nodes.calls) {
      if (_execution(create) != owner ||
          create.target is! SimpleIdentifier ||
          (create.target! as SimpleIdentifier).name != name ||
          !_exclusive(create)) {
        continue;
      }
      if (!_failurePath(removal, create, owner)) continue;
      if (!_unescapedWrite(nodes, create, removal, name)) continue;
      final Statement? statement = _statement(create);
      final AstNode? parent = statement?.parent;
      if (statement == null || parent is! Block) continue;
      final int next = parent.statements.indexOf(statement) + 1;
      if (next >= parent.statements.length) continue;
      final Statement acknowledgement = parent.statements[next];
      if (acknowledgement is! ExpressionStatement ||
          acknowledgement.expression is! AssignmentExpression) {
        continue;
      }
      final AssignmentExpression assignment =
          acknowledgement.expression as AssignmentExpression;
      if (assignment.operator.lexeme != '=' ||
          assignment.leftHandSide is! SimpleIdentifier ||
          assignment.rightHandSide is! BooleanLiteral ||
          !(assignment.rightHandSide as BooleanLiteral).value) {
        continue;
      }
      final String flag = (assignment.leftHandSide as SimpleIdentifier).name;
      final VariableDeclaration? binding = _binding(create, flag);
      if (binding?.initializer is! BooleanLiteral ||
          (binding!.initializer! as BooleanLiteral).value ||
          nodes.assignments.where((AssignmentExpression write) {
                return write.leftHandSide is SimpleIdentifier &&
                    (write.leftHandSide as SimpleIdentifier).name == flag;
              }).length !=
              1) {
        continue;
      }
      for (AstNode? at = removal.parent; at != null; at = at.parent) {
        if (at == owner) break;
        if (at is IfStatement &&
            _contains(at.thenStatement, removal) &&
            _requiresFlag(at.expression, flag)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _exclusive(MethodInvocation call) =>
      (call.methodName.name == 'create' ||
          call.methodName.name == 'createSync') &&
      call.argumentList.arguments.any((Argument argument) {
        return argument is NamedArgument &&
            argument.name.lexeme == 'exclusive' &&
            argument.argumentExpression is BooleanLiteral &&
            (argument.argumentExpression as BooleanLiteral).value;
      });

  static bool _emptyMarker(VariableDeclaration binding, String name) {
    final _Nodes nodes = _Nodes();
    binding.parent!.parent!.parent!.accept(nodes);
    return nodes.identifiers.where((node) => node.name == name).every((node) {
      final AstNode? parent = node.parent;
      if (parent is MethodInvocation && identical(parent.target, node)) {
        return const <String>{
          'delete',
          'deleteSync',
          'exists',
          'existsSync',
          'length',
          'lengthSync',
          'stat',
          'statSync',
        }.contains(parent.methodName.name);
      }
      return (parent is PropertyAccess &&
              identical(parent.target, node) &&
              parent.propertyName.name == 'path') ||
          (parent is PrefixedIdentifier &&
              identical(parent.prefix, node) &&
              parent.identifier.name == 'path');
    });
  }

  static bool _failurePath(
    MethodInvocation removal,
    MethodInvocation create,
    AstNode owner,
  ) {
    for (AstNode? at = removal.parent; at != null; at = at.parent) {
      if (at == owner) return false;
      if (at is CatchClause && at.parent is TryStatement) {
        return _contains((at.parent! as TryStatement).body, create);
      }
    }
    return false;
  }

  static bool _unescapedWrite(
    _Nodes nodes,
    MethodInvocation create,
    MethodInvocation removal,
    String name,
  ) => nodes.identifiers
      .where((node) {
        return node.name == name &&
            node.offset > create.end &&
            node.offset < removal.offset;
      })
      .every((node) {
        final AstNode? parent = node.parent;
        return parent is MethodInvocation &&
            identical(parent.target, node) &&
            const <String>{
              'open',
              'openSync',
              'writeAsBytes',
              'writeAsBytesSync',
              'writeAsString',
              'writeAsStringSync',
              'exists',
              'existsSync',
              'stat',
              'statSync',
              'length',
              'lengthSync',
            }.contains(parent.methodName.name);
      });

  static bool _constructs(Expression? expression, String type) {
    if (expression == null) return false;
    final Expression value = _unwrap(expression);
    return (value is InstanceCreationExpression &&
            value.constructorName.type.toSource() == type) ||
        (value is MethodInvocation &&
            value.target == null &&
            value.methodName.name == type);
  }

  static bool _isIoType(Expression? expression, String type, AstNode context) {
    if (expression == null) return false;
    final Expression value = _unwrap(expression);
    if (_constructs(value, type)) return true;
    if (type == 'Directory' && value.toSource() == 'Directory.systemTemp') {
      return true;
    }
    if (value is BinaryExpression && value.operator.lexeme == '??') {
      return _isIoType(value.leftOperand, type, context) &&
          _isIoType(value.rightOperand, type, context);
    }
    if (value is! SimpleIdentifier) return false;
    final VariableDeclaration? binding = _binding(context, value.name);
    if (binding != null) {
      return (binding.parent! as VariableDeclarationList).type?.toSource() ==
          type;
    }
    final _Nodes nodes = _Nodes();
    _execution(context).accept(nodes);
    if (nodes.parameters.any((RegularFormalParameter parameter) {
      return parameter.name?.lexeme == value.name &&
          parameter.type?.toSource().replaceAll('?', '') == type;
    })) {
      return true;
    }
    for (AstNode? at = context.parent; at != null; at = at.parent) {
      if (at is! ClassDeclaration) continue;
      final ClassBody body = at.body;
      if (body is! BlockClassBody) return false;
      return body.members.whereType<FieldDeclaration>().any((field) {
        return field.fields.type?.toSource() == type &&
            field.fields.variables.any(
              (VariableDeclaration variable) =>
                  variable.name.lexeme == value.name,
            );
      });
    }
    return false;
  }

  static VariableDeclaration? _binding(AstNode node, String name) {
    for (AstNode? at = node.parent; at != null; at = at.parent) {
      final FormalParameterList? parameters = switch (at) {
        FunctionExpression(:final parameters) => parameters,
        MethodDeclaration(:final parameters) => parameters,
        ConstructorDeclaration(:final parameters) => parameters,
        _ => null,
      };
      if (parameters?.parameters.any((parameter) {
            return parameter.name?.lexeme == name;
          }) ??
          false) {
        return null;
      }
      if (at is! Block) continue;
      for (final VariableDeclarationStatement statement
          in at.statements.whereType<VariableDeclarationStatement>()) {
        if (statement.offset >= node.offset) continue;
        for (final VariableDeclaration variable
            in statement.variables.variables) {
          if (variable.name.lexeme == name) return variable;
        }
      }
    }
    return null;
  }

  static bool _mutated(AstNode scope, String name) {
    final _Nodes nodes = _Nodes();
    // A declaration's containing block includes any nested signal callback.
    (scope is VariableDeclarationStatement ? scope.parent! : scope).accept(
      nodes,
    );
    return nodes.assignments.any((AssignmentExpression assignment) {
      return assignment.leftHandSide is SimpleIdentifier &&
          (assignment.leftHandSide as SimpleIdentifier).name == name;
    });
  }

  static AstNode _execution(AstNode node) {
    for (AstNode? at = node.parent; at != null; at = at.parent) {
      if (at is FunctionExpression ||
          at is MethodDeclaration ||
          at is ConstructorDeclaration) {
        return at;
      }
    }
    return node.root;
  }

  static Statement? _statement(AstNode node) {
    for (AstNode? at = node.parent; at != null; at = at.parent) {
      if (at is Statement) return at;
    }
    return null;
  }

  static Expression _unwrap(Expression expression) => switch (expression) {
    AwaitExpression(:final expression) => _unwrap(expression),
    ParenthesizedExpression(:final expression) => _unwrap(expression),
    _ => expression,
  };

  static bool _contains(AstNode parent, AstNode child) =>
      parent.offset <= child.offset && parent.end >= child.end;

  static bool _requiresFlag(Expression expression, String name) {
    final Expression value = _unwrap(expression);
    return (value is SimpleIdentifier && value.name == name) ||
        (value is BinaryExpression &&
            value.operator.lexeme == '&&' &&
            (_requiresFlag(value.leftOperand, name) ||
                _requiresFlag(value.rightOperand, name)));
  }
}

final class _Nodes extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> calls = <MethodInvocation>[];
  final List<AssignmentExpression> assignments = <AssignmentExpression>[];
  final List<RegularFormalParameter> parameters = <RegularFormalParameter>[];
  final List<SimpleIdentifier> identifiers = <SimpleIdentifier>[];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    identifiers.add(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    calls.add(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    assignments.add(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    if (node.functionTypedSuffix == null) parameters.add(node);
    super.visitRegularFormalParameter(node);
  }
}
