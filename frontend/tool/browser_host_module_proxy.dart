import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Works around Flutter's browser-test `host.dart.js` routing collision.
/// Supplies only the three original compiler modules through loopback CDP and
/// corrects the SDK's unescaped Windows test selector before its bootstrap.
Future<void> main(List<String> arguments) async {
  try {
    final _Options options = _Options.parse(arguments);
    if (options.help) {
      stdout.writeln(_usage);
      return;
    }
    if (options.selfTest) {
      await _runSelfTests();
      return;
    }
    final Map<String, Uint8List> modules = await _readModules(
      Directory(options.compileDirectory!),
    );
    if (options.validateOnly) {
      stdout.writeln('Validated ${modules.length} original host modules.');
      return;
    }
    final _ModuleProxy proxy = await _ModuleProxy.connect(
      options.debugPort!,
      modules,
    );
    try {
      await proxy.start();
      stdout.writeln('Browser host module proxy ready.');
      await proxy.done;
    } finally {
      await proxy.close();
    }
  } on Object catch (error) {
    stderr.writeln('Browser host module proxy failed: $error');
    exitCode = 1;
  }
}

const String _usage =
    'dart run tool/browser_host_module_proxy.dart '
    '--debug-port <port> --compile-dir <directory>\n'
    'Use --validate-only with --compile-dir to check compiler artifacts.\n'
    'Use --self-test to check bounded compiler manifest fixtures.';

const List<String> _moduleIds = <String>[
  'packages/tapture/app/feedback_host.dart',
  'packages/tapture/app/widgets/incoming_bundle_host.dart',
  'packages/tapture/core/speech/speech_engine_host.dart',
];

// The SDK injects a Windows path directly into a JavaScript string literal.
// Correct only that literal's exact value for the current test document; an
// unrelated requested selector remains a test-discovery error (task 143).
const String _windowsSelectorScript = r'''
(() => {
  const path = window.location.pathname;
  if (window.location.protocol !== 'http:' ||
      !['127.0.0.1', 'localhost', '[::1]'].includes(window.location.hostname) ||
      path === '/static/index.html' || !path.endsWith('.html')) return;
  const expected = decodeURIComponent(path.slice(1, -5)) + '.dart';
  const escapes = {b: '\b', f: '\f', n: '\n', r: '\r', t: '\t', v: '\v', 0: '\0'};
  const windowsLiteral = expected.replaceAll('/', '\\')
      .replace(/\\([\s\S])/g, (_, next) => escapes[next] ?? next);
  const normalize = value => value === expected || value === windowsLiteral
      ? expected : value;
  let requestedTestSelector = window.testSelector;
  let selected = normalize(requestedTestSelector);
  Object.defineProperty(window, 'testSelector', {
    configurable: true,
    get() { return selected; },
    set(value) {
      requestedTestSelector = value;
      selected = normalize(requestedTestSelector);
    }
  });
})();
''';

final class _Options {
  const _Options({
    this.debugPort,
    this.compileDirectory,
    this.help = false,
    this.validateOnly = false,
    this.selfTest = false,
  });

  final int? debugPort;
  final String? compileDirectory;
  final bool help;
  final bool validateOnly;
  final bool selfTest;

  static _Options parse(List<String> arguments) {
    if (arguments.contains('--self-test')) {
      if (arguments.length != 1) {
        throw const FormatException('--self-test accepts no other arguments.');
      }
      return const _Options(selfTest: true);
    }
    int? port;
    String? directory;
    bool validate = false;
    for (int index = 0; index < arguments.length; index++) {
      switch (arguments[index]) {
        case '--help':
          return const _Options(help: true);
        case '--validate-only':
          validate = true;
        case '--debug-port':
          if (++index >= arguments.length) throw const FormatException(_usage);
          port = int.tryParse(arguments[index]);
          if (port == null || port < 1 || port > 65535) {
            throw const FormatException(
              'Debug port must be between 1 and 65535.',
            );
          }
        case '--compile-dir':
          if (++index >= arguments.length) throw const FormatException(_usage);
          directory = arguments[index];
        default:
          throw FormatException('Unknown argument: ${arguments[index]}');
      }
    }
    if (directory == null || (!validate && port == null)) {
      throw const FormatException(_usage);
    }
    return _Options(
      debugPort: port,
      compileDirectory: directory,
      validateOnly: validate,
    );
  }
}

Future<Map<String, Uint8List>> _readModules(Directory directory) async {
  final Directory resolved = Directory(await directory.resolveSymbolicLinks());
  final List<File> sources = <File>[];
  await for (final FileSystemEntity entity in resolved.list(
    followLinks: false,
  )) {
    if (entity is File && entity.path.endsWith('.sources')) sources.add(entity);
  }
  if (sources.length != 1) {
    throw StateError(
      'Compile directory must contain exactly one .sources file.',
    );
  }
  final File source = sources.single;
  final File manifestFile = File(
    '${source.path.substring(0, source.path.length - '.sources'.length)}.json',
  );
  final Map<String, Object?> manifest = _object(
    jsonDecode(await manifestFile.readAsString()),
  );
  final Map<String, Uint8List> modules = <String, Uint8List>{};
  final RandomAccessFile input = await source.open();
  try {
    final int length = await input.length();
    for (final String id in _moduleIds) {
      final String key = '$id.lib.js';
      // A focused suite need not compile every allowlisted application module.
      // Intercept only its present modules, retaining the same exact paths.
      if (!manifest.containsKey(key) && !manifest.containsKey('/$key')) {
        continue;
      }
      final Map<String, Object?> entry = _object(
        manifest[key] ?? manifest['/$key'],
      );
      final Object? ranges = entry['code'];
      if (ranges is! List<Object?> ||
          ranges.length != 2 ||
          ranges[0] is! int ||
          ranges[1] is! int) {
        throw FormatException('Invalid compiler code range for $key.');
      }
      final int start = ranges[0]! as int;
      final int end = ranges[1]! as int;
      if (start < 0 || end <= start || end > length) {
        throw FormatException(
          'Compiler code range is outside .sources for $key.',
        );
      }
      await input.setPosition(start);
      final Uint8List code = await input.read(end - start);
      if (code.length != end - start) {
        throw FormatException('Compiler bytes are incomplete for $key.');
      }
      final String text = utf8.decode(code);
      final RegExp identity = RegExp(
        '^// Module: ${RegExp.escape(id)}'
        r'\r?$',
        multiLine: true,
      );
      if (!RegExp(r'\bdefine\s*\(').hasMatch(text) ||
          !identity.hasMatch(text)) {
        throw FormatException(
          'Compiler AMD module identity does not match $id.',
        );
      }
      modules['/$id.js'] = code;
    }
  } finally {
    await input.close();
  }
  if (modules.isEmpty) {
    throw StateError('No allowlisted host module is present in the manifest.');
  }
  return Map<String, Uint8List>.unmodifiable(modules);
}

Future<void> _runSelfTests() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'tapture-browser-host-proxy-',
  );
  final String speech = _moduleIds.last;
  const String unrelated = 'packages/tapture/core/unrelated.dart';
  int passed = 0;
  Future<void> verify(String name, Future<void> Function() body) async {
    await body().timeout(const Duration(seconds: 5));
    passed++;
    stdout.writeln('PASS $name');
  }

  try {
    await verify('allowlisted subset retains exact original bytes', () async {
      final String code = _fixtureCode(speech);
      await _writeModuleFixture(directory, <String, String>{speech: code});
      final Map<String, Uint8List> modules = await _readModules(directory);
      if (modules.length != 1 ||
          utf8.decode(modules['/$speech.js'] ?? Uint8List(0)) != code) {
        throw StateError('Subset did not retain the original compiler module.');
      }
    });
    await verify('all three allowlisted modules remain valid', () async {
      final Map<String, String> code = <String, String>{
        for (final String id in _moduleIds) id: _fixtureCode(id),
      };
      await _writeModuleFixture(directory, code);
      final Map<String, Uint8List> modules = await _readModules(directory);
      if (modules.length != code.length ||
          code.entries.any(
            (MapEntry<String, String> entry) =>
                utf8.decode(modules['/${entry.key}.js'] ?? Uint8List(0)) !=
                entry.value,
          )) {
        throw StateError('Full manifest did not retain the original modules.');
      }
    });
    await verify('malformed present byte range is rejected', () async {
      await _writeModuleFixture(
        directory,
        <String, String>{speech: _fixtureCode(speech)},
        overrides: <String, Object?>{
          '/$speech.lib.js': <String, Object?>{
            'code': <int>[0, 0],
          },
        },
      );
      await _expectModuleRejection<FormatException>(directory);
    });
    await verify('wrong present module identity is rejected', () async {
      await _writeModuleFixture(directory, <String, String>{
        speech: _fixtureCode(unrelated),
      });
      await _expectModuleRejection<FormatException>(directory);
    });
    await verify('present module without AMD definition is rejected', () async {
      await _writeModuleFixture(directory, <String, String>{
        speech: '// Module: $speech\n',
      });
      await _expectModuleRejection<FormatException>(directory);
    });
    await verify('unrelated modules cannot expand the allowlist', () async {
      await _writeModuleFixture(directory, <String, String>{
        speech: _fixtureCode(speech),
        unrelated: _fixtureCode(unrelated),
      });
      final Map<String, Uint8List> modules = await _readModules(directory);
      if (modules.length != 1 || !modules.containsKey('/$speech.js')) {
        throw StateError('An unrelated module escaped the allowlist.');
      }
    });
    await verify('unrelated-only manifest is rejected', () async {
      await _writeModuleFixture(directory, <String, String>{
        unrelated: _fixtureCode(unrelated),
      });
      await _expectModuleRejection<StateError>(directory);
    });
    await verify('malformed present metadata is rejected', () async {
      await _writeModuleFixture(
        directory,
        <String, String>{speech: _fixtureCode(speech)},
        overrides: <String, Object?>{'/$speech.lib.js': null},
      );
      await _expectModuleRejection<FormatException>(directory);
    });
    stdout.writeln('Browser host module proxy self-tests: $passed passed.');
  } finally {
    final String temporaryRoot = await Directory.systemTemp
        .resolveSymbolicLinks();
    final String fixturePath = await directory.resolveSymbolicLinks();
    String normalize(String path) =>
        Platform.isWindows ? path.toLowerCase() : path;
    if (normalize(Directory(fixturePath).parent.path) !=
        normalize(temporaryRoot)) {
      throw StateError(
        'Fixture cleanup must remain within the temporary root.',
      );
    }
    await directory.delete(recursive: true);
  }
}

String _fixtureCode(String id) =>
    '// Generated by DDC: UTF-8 fixture é\n'
    '// Module: $id\n'
    'define([], function() {});\n';

Future<void> _writeModuleFixture(
  Directory directory,
  Map<String, String> modules, {
  Map<String, Object?> overrides = const <String, Object?>{},
}) async {
  final BytesBuilder source = BytesBuilder(copy: false);
  final Map<String, Object?> manifest = <String, Object?>{};
  for (final MapEntry<String, String> entry in modules.entries) {
    final int start = source.length;
    source.add(utf8.encode(entry.value));
    manifest['/${entry.key}.lib.js'] = <String, Object?>{
      'code': <int>[start, source.length],
    };
  }
  manifest.addAll(overrides);
  await File.fromUri(
    directory.uri.resolve('out.sources'),
  ).writeAsBytes(source.takeBytes(), flush: true);
  await File.fromUri(
    directory.uri.resolve('out.json'),
  ).writeAsString(jsonEncode(manifest), flush: true);
}

Future<void> _expectModuleRejection<T extends Object>(
  Directory directory,
) async {
  try {
    await _readModules(directory);
  } on Object catch (error) {
    if (error is T) return;
    rethrow;
  }
  throw StateError('Invalid fixture was accepted; expected $T.');
}

Map<String, Object?> _object(Object? value) {
  if (value is! Map<String, Object?>) {
    throw const FormatException('Expected a JSON object.');
  }
  return value;
}

bool _isLoopback(Uri uri) =>
    uri.host == '127.0.0.1' || uri.host == 'localhost' || uri.host == '::1';

final class _ModuleProxy {
  _ModuleProxy(this._socket, this._modules) {
    // Events can fail while start() is still configuring the initial targets.
    // Keep that failure observable through done without an unhandled future.
    _completion.future.ignore();
    _socket.listen(
      _receive,
      onError: (Object error) => _fail(error),
      onDone: _closed,
    );
  }

  final WebSocket _socket;
  final Map<String, Uint8List> _modules;
  final Map<int, Completer<Map<String, Object?>>> _pending =
      <int, Completer<Map<String, Object?>>>{};
  final Map<String, Future<void>> _sessions = <String, Future<void>>{};
  final Set<String> _targets = <String>{};
  final Completer<void> _completion = Completer<void>();
  int _nextId = 0;
  int _pageCount = 0;

  Future<void> get done => _completion.future;

  static Future<_ModuleProxy> connect(
    int port,
    Map<String, Uint8List> modules,
  ) async {
    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..findProxy = (Uri _) => 'DIRECT';
    late Uri debugger;
    try {
      final HttpClientRequest request = await client.getUrl(
        Uri.parse('http://127.0.0.1:$port/json/version'),
      );
      request.followRedirects = false;
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw StateError(
          'CDP version endpoint returned ${response.statusCode}.',
        );
      }
      final Map<String, Object?> version = _object(
        jsonDecode(await response.transform(utf8.decoder).join()),
      );
      debugger = Uri.parse(version['webSocketDebuggerUrl']! as String);
      if (debugger.scheme != 'ws' ||
          !_isLoopback(debugger) ||
          debugger.port != port) {
        throw StateError(
          'CDP debugger must stay on the requested loopback port.',
        );
      }
    } finally {
      client.close(force: true);
    }
    return _ModuleProxy(
      await WebSocket.connect(
        debugger.toString(),
      ).timeout(const Duration(seconds: 10)),
      modules,
    );
  }

  Future<void> start() async {
    await _send('Target.setAutoAttach', <String, Object?>{
      'autoAttach': true,
      'waitForDebuggerOnStart': true,
      'flatten': true,
    });
    final Map<String, Object?> targets = await _send('Target.getTargets');
    for (final Object? value in targets['targetInfos']! as List<Object?>) {
      final Map<String, Object?> target = _object(value);
      final String id = target['targetId']! as String;
      if (target['type'] != 'page' || _targets.contains(id)) continue;
      final Map<String, Object?> attached = await _send(
        'Target.attachToTarget',
        <String, Object?>{'targetId': id, 'flatten': true},
      );
      await _configure(attached['sessionId']! as String, target);
    }
    await Future.wait(_sessions.values);
    if (_pageCount == 0) {
      throw StateError('No browser page target is available.');
    }
  }

  Future<void> _configure(String session, Map<String, Object?> target) =>
      _sessions.putIfAbsent(session, () async {
        _targets.add(target['targetId']! as String);
        if (target['type'] == 'page') _pageCount++;
        if (target['type'] == 'page' || target['type'] == 'iframe') {
          await _send('Network.enable', const <String, Object?>{}, session);
          await _send('Network.setCacheDisabled', <String, Object?>{
            'cacheDisabled': true,
          }, session);
          if (Platform.isWindows) {
            await _send('Page.enable', const <String, Object?>{}, session);
            await _send(
              'Page.addScriptToEvaluateOnNewDocument',
              <String, Object?>{
                'source': _windowsSelectorScript,
                'runImmediately': true,
              },
              session,
            );
          }
          await _send('Fetch.enable', <String, Object?>{
            'patterns': <Map<String, Object?>>[
              for (final String path in _modules.keys)
                <String, Object?>{
                  'urlPattern': '*$path',
                  'requestStage': 'Request',
                },
            ],
          }, session);
          // Related iframe targets also pause before any module executes.
          await _send('Target.setAutoAttach', <String, Object?>{
            'autoAttach': true,
            'waitForDebuggerOnStart': true,
            'flatten': true,
          }, session);
        }
        await _send(
          'Runtime.runIfWaitingForDebugger',
          const <String, Object?>{},
          session,
        );
      });

  Future<Map<String, Object?>> _send(
    String method, [
    Map<String, Object?> parameters = const <String, Object?>{},
    String? session,
  ]) async {
    final int id = ++_nextId;
    final Completer<Map<String, Object?>> reply =
        Completer<Map<String, Object?>>();
    _pending[id] = reply;
    _socket.add(
      jsonEncode(<String, Object?>{
        'id': id,
        'method': method,
        'params': parameters,
        'sessionId': ?session,
      }),
    );
    try {
      return await reply.future.timeout(const Duration(seconds: 10));
    } finally {
      _pending.remove(id);
    }
  }

  void _receive(Object? frame) {
    try {
      final Map<String, Object?> message = _object(
        jsonDecode(frame! as String),
      );
      final Object? id = message['id'];
      if (id is int) {
        final Completer<Map<String, Object?>>? reply = _pending[id];
        if (reply == null) return;
        if (message.containsKey('error')) {
          reply.completeError(
            StateError('CDP request failed: ${message['error']}'),
          );
        } else {
          reply.complete(_object(message['result']));
        }
        return;
      }
      unawaited(_event(message).catchError((Object error) => _fail(error)));
    } on Object catch (error) {
      _fail(error);
    }
  }

  Future<void> _event(Map<String, Object?> message) async {
    if (message['method'] == 'Target.attachedToTarget') {
      final Map<String, Object?> parameters = _object(message['params']);
      await _configure(
        parameters['sessionId']! as String,
        _object(parameters['targetInfo']),
      );
    } else if (message['method'] == 'Fetch.requestPaused') {
      final Map<String, Object?> parameters = _object(message['params']);
      final Uri uri = Uri.parse(
        _object(parameters['request'])['url']! as String,
      );
      final String session = message['sessionId']! as String;
      final Uint8List? code = _isLoopback(uri) && uri.scheme == 'http'
          ? _modules[uri.path]
          : null;
      if (code == null) {
        await _send('Fetch.continueRequest', <String, Object?>{
          'requestId': parameters['requestId'],
        }, session);
        return;
      }
      await _send('Fetch.fulfillRequest', <String, Object?>{
        'requestId': parameters['requestId'],
        'responseCode': HttpStatus.ok,
        'responseHeaders': <Map<String, String>>[
          <String, String>{'name': 'Content-Type', 'value': 'text/javascript'},
          <String, String>{'name': 'Cache-Control', 'value': 'no-store'},
        ],
        'body': base64.encode(code),
      }, session);
    }
  }

  void _fail(Object error) {
    if (!_completion.isCompleted) _completion.completeError(error);
  }

  void _closed() {
    for (final Completer<Map<String, Object?>> reply in _pending.values) {
      if (!reply.isCompleted) {
        reply.completeError(StateError('CDP socket closed.'));
      }
    }
    if (!_completion.isCompleted) _completion.complete();
  }

  Future<void> close() => _socket.close();
}
