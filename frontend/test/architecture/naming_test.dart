import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/naming/domain_names.dart';

/// The application's own sources, which must use only the names in
/// [DomainNames].
final Directory _lib = Directory('lib');

/// The twelve specification concepts, keyed the way [DomainNames] spells them.
const Map<String, String> _canonical = <String, String>{
  'project': DomainNames.project,
  'templateDef': DomainNames.templateDef,
  'fieldDef': DomainNames.fieldDef,
  'recordEntry': DomainNames.recordEntry,
  'fieldValue': DomainNames.fieldValue,
  'captureSession': DomainNames.captureSession,
  'photoAsset': DomainNames.photoAsset,
  'contextState': DomainNames.contextState,
  'referenceDataset': DomainNames.referenceDataset,
  'processingJob': DomainNames.processingJob,
  'bundle': DomainNames.bundle,
  'mergeSession': DomainNames.mergeSession,
};

/// Near-synonyms a type may not be named, and the [DomainNames] entry that
/// displaces each one.
///
/// Matched as a whole identifier, not as a substring, so `ReferenceDataset`
/// and `FieldValue` stay legal while `RecordData` does not.
const Map<String, String> _synonyms = <String, String>{
  'ProjectModel': DomainNames.project,
  'ProjectData': DomainNames.project,
  'ProjectInfo': DomainNames.project,
  'ProjectItem': DomainNames.project,
  'TemplateModel': DomainNames.templateDef,
  'TemplateData': DomainNames.templateDef,
  'TemplateInfo': DomainNames.templateDef,
  'TemplateItem': DomainNames.templateDef,
  'FieldModel': DomainNames.fieldDef,
  'FieldData': DomainNames.fieldDef,
  'FieldInfo': DomainNames.fieldDef,
  'FieldItem': DomainNames.fieldDef,
  'RecordModel': DomainNames.recordEntry,
  'RecordData': DomainNames.recordEntry,
  'RecordInfo': DomainNames.recordEntry,
  'RecordItem': DomainNames.recordEntry,
  'FieldValueModel': DomainNames.fieldValue,
  'CaptureSessionModel': DomainNames.captureSession,
  'CaptureData': DomainNames.captureSession,
  'PhotoItem': DomainNames.photoAsset,
  'PhotoModel': DomainNames.photoAsset,
  'PhotoData': DomainNames.photoAsset,
  'PhotoInfo': DomainNames.photoAsset,
  'ContextModel': DomainNames.contextState,
  'ContextData': DomainNames.contextState,
  'ContextInfo': DomainNames.contextState,
  'ReferenceData': DomainNames.referenceDataset,
  'DatasetModel': DomainNames.referenceDataset,
  'ProcessingJobModel': DomainNames.processingJob,
  'JobModel': DomainNames.processingJob,
  'BundleModel': DomainNames.bundle,
  'BundleData': DomainNames.bundle,
  'MergeModel': DomainNames.mergeSession,
  'MergeSessionModel': DomainNames.mergeSession,
};

/// The type declarations this test recognises, in the same order as
/// `tool/check_naming.dart`: longer spellings first so `mixin class` is not
/// read as a mixin.
final List<RegExp> _typeDeclarations = <RegExp>[
  RegExp(
    r'^(?:(?:abstract|base|final|interface|sealed|mixin)\s+)*'
    r'class\s+([A-Za-z_$][A-Za-z0-9_$]*)',
  ),
  RegExp(r'^enum\s+([A-Za-z_$][A-Za-z0-9_$]*)'),
  RegExp(r'^extension\s+type\s+(?:const\s+)?([A-Za-z_$][A-Za-z0-9_$]*)'),
  RegExp(r'^extension\s+(?!type\b|on\b)([A-Za-z_$][A-Za-z0-9_$]*)'),
  RegExp(r'^(?:base\s+)?mixin\s+(?!class\b)([A-Za-z_$][A-Za-z0-9_$]*)'),
  RegExp(r'^typedef\s+([A-Za-z_$][A-Za-z0-9_$]*)'),
];

void main() {
  group('DomainNames', () {
    test('resolves all twelve concepts', () {
      expect(_canonical.length, 12);
      expect(_canonical.values.toSet(), hasLength(12));
      expect(_canonical.values, <String>[
        'Project',
        'TemplateDef',
        'FieldDef',
        'RecordEntry',
        'FieldValue',
        'CaptureSession',
        'PhotoAsset',
        'ContextState',
        'ReferenceDataset',
        'ProcessingJob',
        'Bundle',
        'MergeSession',
      ]);
    });
  });

  group('the shipped sources', () {
    test('declare no synonym', () {
      expect(_findSynonyms(_lib), isEmpty);
    });
  });

  group('a compliant tree', () {
    test(
      'keeps ReferenceDataset, FieldValue and the other canonical names',
      () {
        final Directory root = _tree(<String, String>{
          'reference_dataset.dart': '''
class ReferenceDataset {
  const ReferenceDataset();
}
''',
          'field_value.dart': '''
class FieldValue {
  const FieldValue();
}
''',
          'capture_session.dart': '''
class CaptureSession {
  const CaptureSession();
}
''',
          'app_theme.dart': '''
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme();

  ThemeData light() {
    const IconData glyph = Icons.camera;
    return ThemeData(useMaterial3: true);
  }
}
''',
        });

        expect(_findSynonyms(root), isEmpty);
      },
    );
  });

  group('a tree that uses a synonym', () {
    test('RecordModel names RecordEntry in the message', () {
      final Directory root = _tree(<String, String>{
        'record_model.dart': 'class RecordModel {}\n',
      });

      final List<_Violation> found = _findSynonyms(root);

      expect(found, hasLength(1));
      expect(found.single.file, 'lib/record_model.dart');
      expect(found.single.line, 1);
      expect(found.single.name, 'RecordModel');
      expect(found.single.canonical, DomainNames.recordEntry);
    });

    test('PhotoItem names PhotoAsset in the message', () {
      final Directory root = _tree(<String, String>{
        'photo_item.dart': 'class PhotoItem {}\n',
      });

      final List<_Violation> found = _findSynonyms(root);

      expect(found, hasLength(1));
      expect(found.single.file, 'lib/photo_item.dart');
      expect(found.single.line, 1);
      expect(found.single.name, 'PhotoItem');
      expect(found.single.canonical, DomainNames.photoAsset);
    });

    test('TemplateData names TemplateDef in the message', () {
      final Directory root = _tree(<String, String>{
        'template_data.dart': 'class TemplateData {}\n',
      });

      final List<_Violation> found = _findSynonyms(root);

      expect(found, hasLength(1));
      expect(found.single.file, 'lib/template_data.dart');
      expect(found.single.line, 1);
      expect(found.single.name, 'TemplateData');
      expect(found.single.canonical, DomainNames.templateDef);
    });

    test('RecordData fails as a whole camel-case word, not a substring', () {
      final Directory root = _tree(<String, String>{
        'record_data.dart': 'class RecordData {}\n',
      });

      expect(_findSynonyms(root).single.canonical, DomainNames.recordEntry);
    });

    test('every synonym is reported, not only the first', () {
      final Directory root = _tree(<String, String>{
        'record_model.dart': 'class RecordModel {}\n',
        'photo_item.dart': 'class PhotoItem {}\n',
        'template_data.dart': 'class TemplateData {}\n',
      });

      final List<_Violation> found = _findSynonyms(root);

      expect(found, hasLength(3));
      expect(found.map((_Violation v) => v.name).toSet(), <String>{
        'RecordModel',
        'PhotoItem',
        'TemplateData',
      });
    });

    test('a use of Flutter ThemeData is never a declaration', () {
      final Directory root = _tree(<String, String>{
        'app_theme.dart': '''
import 'package:flutter/material.dart';

class AppTheme {
  ThemeData light() => ThemeData.dark();
}
''',
      });

      expect(_findSynonyms(root), isEmpty);
    });
  });
}

/// A synonym declared under [root], with the file, line and the name that
/// should have been used.
typedef _Violation = ({String file, int line, String name, String canonical});

/// Reports every type under [root] whose name is a near-synonym of a
/// [DomainNames] entry.
///
/// Only declarations are read, never uses, which is why Flutter's `ThemeData`
/// and `IconData` are never reported.
List<_Violation> _findSynonyms(Directory root) {
  if (!root.existsSync()) {
    return const <_Violation>[];
  }
  final List<_Violation> found = <_Violation>[];
  for (final File file in _sources(root)) {
    final List<String> lines = file.readAsLinesSync();
    for (int index = 0; index < lines.length; index++) {
      final String? name = _declaredType(lines[index]);
      if (name == null) {
        continue;
      }
      final String bare = name.replaceFirst(RegExp(r'^[_$]+'), '');
      final String? canonical = _synonyms[bare];
      if (canonical == null) {
        continue;
      }
      found.add((
        file: 'lib/${_relative(root, file)}',
        line: index + 1,
        name: name,
        canonical: canonical,
      ));
    }
  }
  return found;
}

/// The type [line] declares, or null when it declares none.
String? _declaredType(String line) {
  final String trimmed = line.trimLeft();
  if (trimmed.startsWith('//')) {
    return null;
  }
  for (final RegExp pattern in _typeDeclarations) {
    final Match? match = pattern.firstMatch(trimmed);
    if (match != null) {
      return match.group(1);
    }
  }
  return null;
}

/// Hand-written Dart sources under [root], so generated output is left alone.
List<File> _sources(Directory root) {
  final List<File> sources = <File>[
    for (final FileSystemEntity entity in root.listSync(recursive: true))
      if (entity is File && _isHandWrittenDart(_basename(entity.uri))) entity,
  ];
  return sources..sort((File a, File b) => a.path.compareTo(b.path));
}

/// Whether [name] is a Dart file somebody wrote rather than generated.
bool _isHandWrittenDart(String name) {
  return name.endsWith('.dart') && name.split('.').length == 2;
}

/// Writes a throwaway `lib/` holding [files], keyed by their path inside it.
Directory _tree(Map<String, String> files) {
  final Directory root = Directory.systemTemp.createTempSync('tapture_vocab_');
  addTearDown(() => root.deleteSync(recursive: true));
  final Directory sources = Directory('${root.path}/lib')
    ..createSync(recursive: true);
  for (final MapEntry<String, String> file in files.entries) {
    File('${sources.path}/${file.key}').writeAsStringSync(file.value);
  }
  return sources;
}

/// Where [file] sits under [root], with forward slashes.
String _relative(Directory root, File file) {
  final String from = root.path.replaceAll(r'\', '/');
  final String to = file.path.replaceAll(r'\', '/');
  final String prefix = from.endsWith('/') ? from : '$from/';
  return to.startsWith(prefix) ? to.substring(prefix.length) : to;
}

/// The last segment of a URI's path.
String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}
