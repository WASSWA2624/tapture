import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Detects stale declarations and comments while allowing formatter whitespace
/// and optional trailing commas. Findings identify the output and repair.
String? generatedSourceProblem({
  required String path,
  required String expected,
  required String generator,
  String? actual,
}) {
  final String repair = 'Run dart run $generator.';
  if (actual == null) {
    return '$path:1: generated output is missing. $repair';
  }
  final parsed = parseString(content: actual, path: path);
  final expectedParsed = parseString(content: expected);
  final List<({String text, int offset})> found = _tokens(
    parsed.unit.beginToken,
  );
  final List<({String text, int offset})> wanted = _tokens(
    expectedParsed.unit.beginToken,
  );
  final int length = found.length < wanted.length
      ? found.length
      : wanted.length;
  for (int index = 0; index < length; index++) {
    if (found[index].text == wanted[index].text) {
      continue;
    }
    final int line = parsed.lineInfo
        .getLocation(found[index].offset)
        .lineNumber;
    return '$path:$line: generated output is stale. $repair';
  }
  if (found.length != wanted.length) {
    final int offset = length < found.length
        ? found[length].offset
        : actual.length;
    final int line = parsed.lineInfo.getLocation(offset).lineNumber;
    return '$path:$line: generated output is stale. $repair';
  }
  // A comma in a one-element positional record is semantically significant.
  // The canonical AST comparison retains that distinction even though token
  // normalization permits the formatter's optional trailing commas.
  if (parsed.unit.toSource() != expectedParsed.unit.toSource() ||
      _recordShapes(parsed.unit) != _recordShapes(expectedParsed.unit)) {
    return '$path:1: generated output is stale. $repair';
  }
  return null;
}

String _recordShapes(CompilationUnit unit) {
  final _RecordShapeVisitor visitor = _RecordShapeVisitor();
  unit.accept(visitor);
  return visitor.shapes.join(';');
}

final class _RecordShapeVisitor extends RecursiveAstVisitor<void> {
  final List<String> shapes = <String>[];

  @override
  void visitRecordLiteral(RecordLiteral node) {
    shapes.add(
      '${node.fields.length}:'
      '${node.fields.whereType<NamedExpression>().map((NamedExpression field) => field.name.label.name).join(',')}',
    );
    super.visitRecordLiteral(node);
  }
}

List<({String text, int offset})> _tokens(Token first) {
  final List<({String text, int offset})> result =
      <({String text, int offset})>[];
  for (Token token = first; ; token = token.next!) {
    CommentToken? comment = token.precedingComments;
    while (comment != null) {
      result.add((
        text: comment.lexeme.replaceAll('\r\n', '\n'),
        offset: comment.offset,
      ));
      final Token? next = comment.next;
      comment = next is CommentToken ? next : null;
    }
    if (token.isEof) {
      break;
    }
    if (token.lexeme == ',' &&
        const <String>{')', ']', '}'}.contains(token.next?.lexeme)) {
      continue;
    }
    result.add((text: token.lexeme, offset: token.offset));
  }
  return result;
}
