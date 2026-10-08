import 'dart:io';

void discardScratch() {
  final Directory scratch = Directory.systemTemp.createTempSync('scratch-');
  try {
    File('${scratch.path}/derived').writeAsStringSync('unpublished');
  } finally {
    scratch.deleteSync(recursive: true);
  }
}

Future<void> discardLease(String path) async {
  final File lease = await File(path).create(exclusive: true);
  void cancel() => lease.deleteSync();
  cancel();
}

void abortWrite(File target) {
  var created = false;
  try {
    target.createSync(exclusive: true);
    created = true;
    target.writeAsStringSync('unpublished');
  } on Object {
    if (created && target.existsSync()) {
      target.deleteSync();
    }
    rethrow;
  }
}
