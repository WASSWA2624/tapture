import 'dart:io';

import 'paths.dart';

/// The words a type name may not be built out of
/// (`frontend/.rules/02-coding-standards.md`, FE-CODE-03). Each of them
/// describes nothing, so a type wearing one has not been named yet.
const List<String> _bannedWords = <String>[
  'manager',
  'helper',
  'util',
  'data',
  'info',
  'item',
];

/// The suffix `frontend/.rules/01-structure.md` (FE-STR-07) gives the files
/// that declare providers. Everything public such a file declares is a
/// provider, which is what lets this checker recognise one without knowing
/// anything about the state library.
const String _providerFile = '_providers.dart';

/// The suffix FE-CODE-02 gives every provider's name.
const String _providerSuffix = 'Provider';

/// What a `class` declaration is called in a report, and the one kind of type
/// FE-STR-06 allows only one of per file.
const String _classKind = 'class';

/// A file name in snake_case: lowercase words joined by single underscores.
final RegExp _snakeCase = RegExp(r'^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$');

/// A variable name in lowerCamelCase.
final RegExp _lowerCamelCase = RegExp(r'^[a-z][A-Za-z0-9]*$');

/// One word of a camel-case name. The first branch takes an acronym run —
/// `HTTP` out of `HTTPServer` — and the second an ordinary word, so a name
/// splits into the words it was built from. That is what makes `RecordData`
/// two words and `ReferenceDataset` two different ones.
final RegExp _camelWord = RegExp(r'[A-Z]+(?![a-z])|[A-Z]?[a-z0-9]+');

/// An identifier, used to pick the name out of a variable declaration.
final RegExp _identifier = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*');

/// A top-level variable, up to whatever ends its name.
final RegExp _variableDeclaration = RegExp(
  r'^(?:late\s+)?(?:final|const|var)\b([^=;{]*)',
);

/// The type declarations this checker recognises, in the order it tries them:
/// `mixin class` and `extension type` have to be read before the plainer
/// `mixin` and `extension` whose spelling they begin with.
final List<({String kind, RegExp pattern})>
_typeDeclarations = <({String kind, RegExp pattern})>[
  (
    kind: _classKind,
    pattern: RegExp(
      r'^(?:(?:abstract|base|final|interface|sealed|mixin)\s+)*'
      r'class\s+([A-Za-z_$][A-Za-z0-9_$]*)',
    ),
  ),
  (kind: 'enum', pattern: RegExp(r'^enum\s+([A-Za-z_$][A-Za-z0-9_$]*)')),
  (
    kind: 'extension type',
    pattern: RegExp(
      r'^extension\s+type\s+(?:const\s+)?([A-Za-z_$][A-Za-z0-9_$]*)',
    ),
  ),
  (
    kind: 'extension',
    pattern: RegExp(r'^extension\s+(?!type\b|on\b)([A-Za-z_$][A-Za-z0-9_$]*)'),
  ),
  (
    kind: 'mixin',
    pattern: RegExp(
      r'^(?:base\s+)?mixin\s+(?!class\b)([A-Za-z_$][A-Za-z0-9_$]*)',
    ),
  ),
  (kind: 'typedef', pattern: RegExp(r'^typedef\s+([A-Za-z_$][A-Za-z0-9_$]*)')),
];

/// One thing wrong with a name, and the file and line that has to change.
typedef _Violation = ({String file, int line, String message});

/// One declaration read out of a source file: where it sits, what it is
/// called, and what kind of thing it is.
typedef _Declaration = ({int line, String name, String kind});

/// The top-level declarations one file makes, split into the types and the
/// variables, because the rules ask a different question of each.
typedef _Declarations = ({
  List<_Declaration> types,
  List<_Declaration> variables,
});

/// Checks file names and type names, printing one line per violation.
///
/// Takes the directory of Dart sources to scan, defaulting to `lib/`. Exits 0
/// when every name agrees with the rules and 1 on any violation.
Future<int> main(List<String> args) async {
  final Directory root = Directory(args.isEmpty ? libRoot : args.first);
  final List<File> sources = _sources(root);
  final List<_Violation> violations = _findViolations(root, sources);
  for (final _Violation violation in violations) {
    stderr.writeln('${violation.file}:${violation.line}: ${violation.message}');
  }
  stdout.writeln(
    violations.isEmpty
        ? 'naming: ${sources.length} files, names and types in agreement'
        : 'naming: ${violations.length} violation(s)',
  );
  exitCode = violations.isEmpty ? 0 : 1;
  return exitCode;
}

/// Reports every name under [root] that breaks a rule: a file not written in
/// snake_case, a file whose first public type is not the type it is named
/// after, a second public class sharing a file, a provider that does not read
/// as one, and a type built out of a word FE-CODE-03 bans.
///
/// Reports all of them, so one run says everything that has to change.
List<_Violation> _findViolations(Directory root, List<File> sources) {
  if (!root.existsSync()) {
    return <_Violation>[
      (
        file: _displayRoot(root),
        line: 0,
        message: 'there is no directory here to check',
      ),
    ];
  }
  return <_Violation>[
    for (final File source in sources)
      ..._fileViolations(
        '${_displayRoot(root)}/${_relative(root, source)}',
        _basename(source.uri),
        source.readAsStringSync(),
      ),
  ];
}

/// Reports every rule one file breaks. [path] is how the file is named in a
/// report, [name] is its own file name, and [source] is what it holds.
Iterable<_Violation> _fileViolations(
  String path,
  String name,
  String source,
) sync* {
  final String stem = name.substring(0, name.length - '.dart'.length);
  final bool isSnakeCase = _snakeCase.hasMatch(stem);
  if (!isSnakeCase) {
    yield (
      file: path,
      line: 0,
      message:
          'a source file is named in snake_case (FE-CODE-02), and this one '
          'is not',
    );
  }

  final _Declarations declarations = _readDeclarations(
    _withoutCommentsAndStrings(source),
  );
  yield* _typeNameViolations(
    path,
    isSnakeCase ? _pascalCase(stem) : null,
    declarations.types,
  );
  yield* _providerViolations(path, name, declarations.variables);
  yield* _bannedWordViolations(path, declarations.types);
}

/// Reports the file being named after something other than the type it holds,
/// and any public class beyond the first (FE-STR-06).
///
/// [expected] is the type the file's name says it holds, or null when the file
/// name is not one a type name can be read out of. A file called
/// `capture-session.dart` has already been reported for its name, and inventing
/// a type called `Capture-session` to hold it to would say nothing true.
Iterable<_Violation> _typeNameViolations(
  String path,
  String? expected,
  List<_Declaration> types,
) sync* {
  final List<_Declaration> public = types
      .where((_Declaration type) => !type.name.startsWith('_'))
      .toList();
  if (public.isEmpty) {
    return;
  }
  final _Declaration primary = public.first;
  if (expected != null && primary.name != expected) {
    yield (
      file: path,
      line: primary.line,
      message:
          'this file is named for $expected and declares ${primary.name} '
          'first; a file is named after the type it holds (FE-STR-06)',
    );
  }
  final Iterable<_Declaration> extras = public
      .where((_Declaration type) => type.kind == _classKind)
      .skip(1);
  for (final _Declaration extra in extras) {
    yield (
      file: path,
      line: extra.line,
      message:
          '${extra.name} is a second public class in this file, and a second '
          'public class means a second file (FE-STR-06)',
    );
  }
}

/// Reports a provider whose name does not read as one (FE-CODE-02).
///
/// A public top-level variable is a provider when it sits in a
/// `_providers.dart` file, which is where FE-STR-07 puts providers, or when
/// its name already claims to be one. A private variable is a file's own
/// business.
Iterable<_Violation> _providerViolations(
  String path,
  String name,
  List<_Declaration> variables,
) sync* {
  final bool inProviderFile = name.endsWith(_providerFile);
  for (final _Declaration variable in variables) {
    if (variable.name.startsWith('_')) {
      continue;
    }
    final bool claimsToBeOne = variable.name.toLowerCase().endsWith(
      _providerSuffix.toLowerCase(),
    );
    if (!inProviderFile && !claimsToBeOne) {
      continue;
    }
    if (!_lowerCamelCase.hasMatch(variable.name)) {
      yield (
        file: path,
        line: variable.line,
        message:
            '${variable.name} is a provider, and a provider is named in '
            'lowerCamelCase (FE-CODE-02)',
      );
      continue;
    }
    if (!variable.name.endsWith(_providerSuffix)) {
      yield (
        file: path,
        line: variable.line,
        message: inProviderFile
            ? '${variable.name} sits in a $_providerFile file, so it is a '
                  'provider, and a provider ends in $_providerSuffix '
                  '(FE-CODE-02)'
            : '${variable.name} reads as a provider and does not end in '
                  '$_providerSuffix (FE-CODE-02)',
      );
    }
  }
}

/// Reports a type built out of a banned word (FE-CODE-03).
///
/// Only declarations are read, never uses, which is why Flutter's `ThemeData`
/// and `IconData` are never reported: this repository does not declare them,
/// and a rule about how we name our types has nothing to say about how
/// somebody else named theirs.
Iterable<_Violation> _bannedWordViolations(
  String path,
  List<_Declaration> types,
) sync* {
  for (final _Declaration type in types) {
    final String? banned = _bannedWordIn(type.name);
    if (banned == null) {
      continue;
    }
    yield (
      file: path,
      line: type.line,
      message:
          'the ${type.kind} ${type.name} is built out of the banned word '
          "'$banned', which describes nothing; name it from the domain "
          'vocabulary instead (FE-CODE-03)',
    );
  }
}

/// The banned word [name] is built out of, or null when it is built out of
/// none.
///
/// The name is read as the words it is made of rather than as characters, so
/// `ReferenceDataset` keeps its name and `RecordData` does not. A plural
/// counts: `Items` is `item` wearing an s.
String? _bannedWordIn(String name) {
  final String bare = name.replaceFirst(RegExp(r'^[_$]+'), '');
  for (final Match match in _camelWord.allMatches(bare)) {
    final String word = (match.group(0) ?? '').toLowerCase();
    final String singular = word.endsWith('s')
        ? word.substring(0, word.length - 1)
        : word;
    if (_bannedWords.contains(word)) {
      return word;
    }
    if (_bannedWords.contains(singular)) {
      return singular;
    }
  }
  return null;
}

/// Reads the top-level declarations out of [code], which has already had its
/// comments and string literals blanked out.
///
/// Only what sits outside every pair of braces counts: a field called `data`
/// or a local called `helper` is inside a class or a function body, and these
/// rules are about the names a file publishes.
_Declarations _readDeclarations(String code) {
  final List<String> lines = code.split('\n');
  final List<int> depths = _depthAtLineStart(code);
  final List<_Declaration> types = <_Declaration>[];
  final List<_Declaration> variables = <_Declaration>[];
  for (int index = 0; index < lines.length; index++) {
    if (index < depths.length && depths[index] != 0) {
      continue;
    }
    final _Declaration? type = _readType(lines[index], index + 1);
    if (type != null) {
      types.add(type);
      continue;
    }
    final _Declaration? variable = _readVariable(lines[index], index + 1);
    if (variable != null) {
      variables.add(variable);
    }
  }
  return (types: types, variables: variables);
}

/// The type [line] declares, or null when it declares none. [number] is the
/// line's own number, counted from one.
_Declaration? _readType(String line, int number) {
  for (final ({String kind, RegExp pattern}) declaration in _typeDeclarations) {
    final Match? match = declaration.pattern.firstMatch(line);
    if (match != null) {
      return (line: number, name: match.group(1) ?? '', kind: declaration.kind);
    }
  }
  return null;
}

/// The variable [line] declares, or null when it declares none.
///
/// The name is the last identifier before whatever ends the declaration, which
/// is what leaves `captureSessionProvider` rather than the type in front of it.
_Declaration? _readVariable(String line, int number) {
  final Match? match = _variableDeclaration.firstMatch(line);
  if (match == null) {
    return null;
  }
  final List<Match> identifiers = _identifier
      .allMatches(match.group(1) ?? '')
      .toList();
  if (identifiers.isEmpty) {
    return null;
  }
  return (
    line: number,
    name: identifiers.last.group(0) ?? '',
    kind: 'variable',
  );
}

/// How deep in braces each line of [code] begins.
///
/// A stray closing brace holds the count at zero rather than driving it
/// negative, so one confusing line cannot make the rest of a file look like it
/// is all top-level.
List<int> _depthAtLineStart(String code) {
  final List<int> depths = <int>[0];
  int depth = 0;
  for (int index = 0; index < code.length; index++) {
    switch (code[index]) {
      case '{':
        depth++;
      case '}':
        depth = depth > 0 ? depth - 1 : 0;
      case '\n':
        depths.add(depth);
    }
  }
  return depths;
}

/// [source] with every comment and string literal replaced by spaces.
///
/// Line and column positions survive, so a violation still points at the line
/// it came from, while a brace inside a string, or a `class` written in a
/// comment, stops being mistaken for code.
String _withoutCommentsAndStrings(String source) {
  final StringBuffer buffer = StringBuffer();
  int index = 0;
  while (index < source.length) {
    final int? end = _commentEnd(source, index) ?? _stringEnd(source, index);
    if (end == null) {
      buffer.write(source[index]);
      index++;
      continue;
    }
    _blank(buffer, source.substring(index, end));
    index = end;
  }
  return buffer.toString();
}

/// Where the comment starting at [index] ends, or null when none starts there.
int? _commentEnd(String source, int index) {
  if (source.startsWith('//', index)) {
    final int newline = source.indexOf('\n', index);
    return newline == -1 ? source.length : newline;
  }
  if (!source.startsWith('/*', index)) {
    return null;
  }
  int depth = 0;
  int at = index;
  while (at < source.length) {
    if (source.startsWith('/*', at)) {
      depth++;
      at += 2;
    } else if (source.startsWith('*/', at)) {
      depth--;
      at += 2;
      if (depth == 0) {
        return at;
      }
    } else {
      at++;
    }
  }
  return source.length;
}

/// Where the string literal starting at [index] ends, or null when none starts
/// there.
///
/// Reads the raw prefix, both quote characters, triple quotes and escapes, so
/// a quote inside a string does not end it and the rest of the file does not
/// then read as one long literal.
int? _stringEnd(String source, int index) {
  int at = index;
  final bool isRaw = source[at] == 'r';
  if (isRaw) {
    at++;
  }
  if (at >= source.length || (source[at] != "'" && source[at] != '"')) {
    return null;
  }
  final String quote = source[at];
  final String delimiter = source.startsWith(quote * 3, at) ? quote * 3 : quote;
  at += delimiter.length;
  while (at < source.length) {
    if (!isRaw && source[at] == r'\') {
      at += 2;
      continue;
    }
    if (source.startsWith(delimiter, at)) {
      return at + delimiter.length;
    }
    at++;
  }
  return source.length;
}

/// Appends as many spaces as [text] has characters, keeping its newlines so
/// line numbers do not move.
void _blank(StringBuffer buffer, String text) {
  for (int index = 0; index < text.length; index++) {
    buffer.write(text[index] == '\n' ? '\n' : ' ');
  }
}

/// The Dart sources under [root], sorted, so a report reads in the order
/// somebody would walk the tree.
///
/// Generator output is left out: it is committed (FE-CODE-13), but nobody
/// chose its names, so the naming rules have nothing to say to it.
List<File> _sources(Directory root) {
  if (!root.existsSync()) {
    return <File>[];
  }
  final List<File> sources = <File>[
    for (final FileSystemEntity entity in root.listSync(recursive: true))
      if (entity is File && _isHandWrittenDart(_basename(entity.uri))) entity,
  ];
  return sources..sort((File a, File b) => a.path.compareTo(b.path));
}

/// Whether [name] is a Dart file somebody wrote rather than generated.
///
/// Generator output carries a second extension — `project_dao.g.dart`,
/// `project.freezed.dart` — which is what tells the two apart.
bool _isHandWrittenDart(String name) {
  return name.endsWith('.dart') && name.split('.').length == 2;
}

/// The snake_case [stem] as the type name a file of that name holds.
String _pascalCase(String stem) {
  return stem
      .split('_')
      .where((String word) => word.isNotEmpty)
      .map((String word) => word[0].toUpperCase() + word.substring(1))
      .join();
}

/// Where [file] sits under [root], with forward slashes whatever the host
/// writes its paths with.
String _relative(Directory root, File file) {
  final String from = _forwardSlashed(root.path);
  final String to = _forwardSlashed(file.path);
  return to.startsWith('$from/') ? to.substring(from.length + 1) : to;
}

/// The scanned folder's own name, without whatever path was used to reach it.
String _displayRoot(Directory root) => _basename(root.uri);

/// The last segment of a URI's path, so the host's separator never has to be
/// spelled out.
String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}

/// [path] written with forward slashes, so comparing two of them does not
/// depend on which separator the host used.
String _forwardSlashed(String path) {
  final String slashed = path.replaceAll(r'\', '/');
  return slashed.endsWith('/')
      ? slashed.substring(0, slashed.length - 1)
      : slashed;
}
