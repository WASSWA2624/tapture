import 'dart:io';

void deleteEvidence(File original) {
  original.deleteSync();
}

void deleteSibling(String path) {
  final Directory scratch = Directory.systemTemp.createTempSync('scratch-');
  final Directory original = Directory(path);
  original.deleteSync(recursive: true);
  scratch.deleteSync(recursive: true);
}

void deleteAlias() {
  final Directory scratch = Directory.systemTemp.createTempSync('scratch-');
  final Directory alias = Directory(scratch.path);
  alias.deleteSync(recursive: true);
  scratch.deleteSync(recursive: true);
}

void deleteReassigned(String path) {
  Directory scratch = Directory.systemTemp.createTempSync('scratch-');
  scratch = Directory(path);
  scratch.deleteSync(recursive: true);
}

void unguardedCreation(File target) {
  target.createSync(exclusive: true);
  target.deleteSync();
}

void prematureAcknowledgement(File target) {
  var created = true;
  try {
    target.createSync(exclusive: true);
    created = true;
  } finally {
    if (created) {
      target.deleteSync();
    }
  }
}

void disjunctiveGuard(File target, bool failed) {
  var created = false;
  try {
    target.createSync(exclusive: true);
    created = true;
  } finally {
    if (created || failed) {
      target.deleteSync();
    }
  }
}

void borrowedControl(File lease) {
  if (lease.existsSync()) {
    lease.deleteSync();
  }
}

Future<void> deleteNewEvidence(String path) async {
  final File original = await File(path).create(exclusive: true);
  await original.writeAsString('captured evidence');
  original.deleteSync();
}

void deleteSuccessfulWrite(File target) {
  var created = false;
  try {
    target.createSync(exclusive: true);
    created = true;
    target.writeAsStringSync('published');
  } finally {
    if (created) {
      target.deleteSync();
    }
  }
}

void shadowedOwner(Directory original) {
  final Directory scratch = Directory.systemTemp.createTempSync('scratch-');
  void deleteBorrowed(Directory scratch) {
    scratch.deleteSync(recursive: true);
  }

  deleteBorrowed(original);
  scratch.deleteSync(recursive: true);
}

void publishedThenFailure(File target, void Function(File) persist) {
  var created = false;
  try {
    target.createSync(exclusive: true);
    created = true;
    persist(target);
    throw StateError('after publication');
  } on Object {
    if (created) {
      target.deleteSync();
    }
    rethrow;
  }
}

Future<void> escapedMarker(String path, void Function(File) persist) async {
  final File lease = await File(path).create(exclusive: true);
  persist(lease);
  lease.deleteSync();
}
