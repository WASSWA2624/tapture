import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/files/files.dart';

void main() {
  test('the memory fake round-trips a string across two instances', () async {
    final Map<String, String> backing = <String, String>{};
    final TextStore first = TextStore.memory(backing);
    await first.write('outdoor');

    final TextStore restarted = TextStore.memory(backing);
    expect(restarted.read(), 'outdoor');
    expect(backing[AppConstants.preferences.themeMode], 'outdoor');
  });

  test('the first-run store round-trips a flag across two instances', () async {
    final Map<String, String> backing = <String, String>{};
    final TextStore first = TextStore.firstRun(backing);
    await first.write('completed=1&name=Ada&startProject=0');

    final TextStore restarted = TextStore.firstRun(backing);
    expect(restarted.read(), 'completed=1&name=Ada&startProject=0');
    expect(
      backing[AppConstants.preferences.firstRun],
      'completed=1&name=Ada&startProject=0',
    );
  });

  test('a file store survives a restart', () async {
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture-prefs-',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final String path = '${directory.path}/theme.mode';
    final TextStore first = TextStore.file(path: path);
    await first.write('dark');

    final TextStore restarted = TextStore.file(path: path);
    expect(restarted.read(), 'dark');
    expect(File(path).readAsStringSync(), 'dark');
  });
}
