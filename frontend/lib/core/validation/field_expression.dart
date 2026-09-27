import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// An expression over one record's fields (task 015, §12.2).
///
/// Comparison, equality, `and` / `or` / `not` and arithmetic. No function
/// calls and no names outside the record. Parse fails when a name is not a
/// field. Evaluation returns null when an operand is missing or the types
/// do not match — never a guess and never an exception.
sealed class FieldExpression {
  const FieldExpression();

  /// Parses [source] against [fieldKeys]. A blank source is a failure.
  static Result<FieldExpression> parse(String source, List<String> fieldKeys) {
    final String trimmed = source.trim();
    if (trimmed.isEmpty) {
      return const FailureResult<FieldExpression>(_unreadable);
    }
    try {
      final _Parser parser = _Parser(trimmed, fieldKeys.toSet());
      final FieldExpression expression = parser.parseExpression();
      parser.skip();
      if (!parser.done) {
        return const FailureResult<FieldExpression>(_unreadable);
      }
      return Success<FieldExpression>(expression);
    } on _ParseFailure catch (error) {
      final String? name = error.name;
      if (name != null) {
        return FailureResult<FieldExpression>(
          ValidationFailure(
            message: Copy.validationUnknownField(name),
            recoveryAction: Copy.validationExpressionAction,
          ),
        );
      }
      return const FailureResult<FieldExpression>(_unreadable);
    }
  }

  /// The value of this expression, or null when it cannot be evaluated.
  Object? read(Map<String, Object?> values);
}

/// Evaluates [expression] against [values]. Missing operands and type
/// mismatches yield null. This never throws.
Object? evaluate(FieldExpression expression, Map<String, Object?> values) {
  try {
    return expression.read(values);
  } on Object {
    return null;
  }
}

const ValidationFailure _unreadable = ValidationFailure(
  message: Copy.validationExpression,
  recoveryAction: Copy.validationExpressionAction,
);

final class _ParseFailure implements Exception {
  const _ParseFailure({this.name});

  final String? name;
}

final class _Parser {
  _Parser(this._source, this._fields);

  final String _source;
  final Set<String> _fields;
  int _index = 0;

  bool get done => _index >= _source.length;

  FieldExpression parseExpression() => _parseOr();

  void skip() {
    while (!done && _space(_source.codeUnitAt(_index))) {
      _index += 1;
    }
  }

  FieldExpression _parseOr() {
    FieldExpression left = _parseAnd();
    while (_word('or') || _op('||')) {
      final FieldExpression right = _parseAnd();
      left = _Or(left, right);
    }
    return left;
  }

  FieldExpression _parseAnd() {
    FieldExpression left = _parseNot();
    while (_word('and') || _op('&&')) {
      final FieldExpression right = _parseNot();
      left = _And(left, right);
    }
    return left;
  }

  FieldExpression _parseNot() {
    skip();
    if (_word('not') || _op('!')) {
      return _Not(_parseNot());
    }
    return _parseComparison();
  }

  FieldExpression _parseComparison() {
    final FieldExpression left = _parseAdd();
    skip();
    const List<String> ops = <String>['==', '!=', '<=', '>=', '<', '>'];
    for (final String op in ops) {
      if (_op(op)) {
        return _Compare(left, op, _parseAdd());
      }
    }
    return left;
  }

  FieldExpression _parseAdd() {
    FieldExpression left = _parseMul();
    while (true) {
      skip();
      if (_op('+')) {
        left = _Math(left, '+', _parseMul());
      } else if (_op('-')) {
        left = _Math(left, '-', _parseMul());
      } else {
        return left;
      }
    }
  }

  FieldExpression _parseMul() {
    FieldExpression left = _parseUnary();
    while (true) {
      skip();
      if (_op('*')) {
        left = _Math(left, '*', _parseUnary());
      } else if (_op('/')) {
        left = _Math(left, '/', _parseUnary());
      } else {
        return left;
      }
    }
  }

  FieldExpression _parseUnary() {
    skip();
    if (_op('-')) {
      return _Negate(_parseUnary());
    }
    return _parsePrimary();
  }

  FieldExpression _parsePrimary() {
    skip();
    if (done) {
      throw const _ParseFailure();
    }
    final int unit = _source.codeUnitAt(_index);
    if (unit == 0x28) {
      _index += 1;
      final FieldExpression inner = parseExpression();
      skip();
      if (done || _source.codeUnitAt(_index) != 0x29) {
        throw const _ParseFailure();
      }
      _index += 1;
      return inner;
    }
    if (unit == 0x27 || unit == 0x22) {
      return _Literal(_string(unit));
    }
    if (unit >= 0x30 && unit <= 0x39) {
      return _Literal(_number());
    }
    final String name = _identifier();
    if (name == 'true') {
      return const _Literal(true);
    }
    if (name == 'false') {
      return const _Literal(false);
    }
    if (name == 'null') {
      return const _Literal(null);
    }
    if (!_fields.contains(name)) {
      throw _ParseFailure(name: name);
    }
    return _Field(name);
  }

  bool _word(String word) {
    skip();
    if (!_source.startsWith(word, _index)) {
      return false;
    }
    final int end = _index + word.length;
    if (end < _source.length && _ident(_source.codeUnitAt(end))) {
      return false;
    }
    _index = end;
    return true;
  }

  bool _op(String op) {
    skip();
    if (!_source.startsWith(op, _index)) {
      return false;
    }
    _index += op.length;
    return true;
  }

  String _identifier() {
    skip();
    final int start = _index;
    if (done || !_identStart(_source.codeUnitAt(_index))) {
      throw const _ParseFailure();
    }
    _index += 1;
    while (!done && _ident(_source.codeUnitAt(_index))) {
      _index += 1;
    }
    return _source.substring(start, _index);
  }

  num _number() {
    final int start = _index;
    while (!done &&
        _source.codeUnitAt(_index) >= 0x30 &&
        _source.codeUnitAt(_index) <= 0x39) {
      _index += 1;
    }
    if (!done && _source.codeUnitAt(_index) == 0x2e) {
      _index += 1;
      while (!done &&
          _source.codeUnitAt(_index) >= 0x30 &&
          _source.codeUnitAt(_index) <= 0x39) {
        _index += 1;
      }
    }
    return num.parse(_source.substring(start, _index));
  }

  String _string(int quote) {
    _index += 1;
    final int start = _index;
    while (!done && _source.codeUnitAt(_index) != quote) {
      _index += 1;
    }
    if (done) {
      throw const _ParseFailure();
    }
    final String text = _source.substring(start, _index);
    _index += 1;
    return text;
  }
}

bool _space(int unit) => unit == 0x20 || unit == 0x09 || unit == 0x0a;

bool _identStart(int unit) =>
    (unit >= 0x41 && unit <= 0x5a) ||
    (unit >= 0x61 && unit <= 0x7a) ||
    unit == 0x5f;

bool _ident(int unit) => _identStart(unit) || (unit >= 0x30 && unit <= 0x39);

final class _Literal extends FieldExpression {
  const _Literal(this.value);

  final Object? value;

  @override
  Object? read(Map<String, Object?> values) => value;
}

final class _Field extends FieldExpression {
  const _Field(this.name);

  final String name;

  @override
  Object? read(Map<String, Object?> values) {
    if (!values.containsKey(name)) {
      return null;
    }
    return values[name];
  }
}

final class _Not extends FieldExpression {
  const _Not(this.inner);

  final FieldExpression inner;

  @override
  Object? read(Map<String, Object?> values) {
    final Object? value = inner.read(values);
    if (value is! bool) {
      return null;
    }
    return !value;
  }
}

final class _Negate extends FieldExpression {
  const _Negate(this.inner);

  final FieldExpression inner;

  @override
  Object? read(Map<String, Object?> values) {
    final Object? value = inner.read(values);
    if (value is! num) {
      return null;
    }
    return -value;
  }
}

final class _Or extends FieldExpression {
  const _Or(this.left, this.right);

  final FieldExpression left;
  final FieldExpression right;

  @override
  Object? read(Map<String, Object?> values) {
    final Object? a = left.read(values);
    final Object? b = right.read(values);
    if (a is! bool || b is! bool) {
      return null;
    }
    return a || b;
  }
}

final class _And extends FieldExpression {
  const _And(this.left, this.right);

  final FieldExpression left;
  final FieldExpression right;

  @override
  Object? read(Map<String, Object?> values) {
    final Object? a = left.read(values);
    final Object? b = right.read(values);
    if (a is! bool || b is! bool) {
      return null;
    }
    return a && b;
  }
}

final class _Compare extends FieldExpression {
  const _Compare(this.left, this.op, this.right);

  final FieldExpression left;
  final String op;
  final FieldExpression right;

  @override
  Object? read(Map<String, Object?> values) {
    final Object? a = left.read(values);
    final Object? b = right.read(values);
    if (a == null || b == null) {
      return null;
    }
    if (op == '==') {
      return _same(a, b);
    }
    if (op == '!=') {
      final bool? same = _same(a, b);
      return same == null ? null : !same;
    }
    if (a is! num || b is! num) {
      return null;
    }
    return switch (op) {
      '<' => a < b,
      '>' => a > b,
      '<=' => a <= b,
      '>=' => a >= b,
      _ => null,
    };
  }
}

bool? _same(Object a, Object b) {
  if (a is num && b is num) {
    return a == b;
  }
  if (a is bool && b is bool) {
    return a == b;
  }
  if (a is String && b is String) {
    return a == b;
  }
  return null;
}

final class _Math extends FieldExpression {
  const _Math(this.left, this.op, this.right);

  final FieldExpression left;
  final String op;
  final FieldExpression right;

  @override
  Object? read(Map<String, Object?> values) {
    final Object? a = left.read(values);
    final Object? b = right.read(values);
    if (a is! num || b is! num) {
      return null;
    }
    if (op == '/' && b == 0) {
      return null;
    }
    return switch (op) {
      '+' => a + b,
      '-' => a - b,
      '*' => a * b,
      '/' => a / b,
      _ => null,
    };
  }
}
