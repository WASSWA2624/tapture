import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/gallery/widget_gallery_screen.dart';

/// Public catalogue widgets declared under `lib/core/widgets/`.
final RegExp _widgetClass = RegExp(
  r'^class ([A-Z][A-Za-z0-9]*)(?:<[^>]+>)? extends '
  r'(?:Stateless|Stateful|Consumer)Widget\b',
);

void main() {
  test('the gallery route is debug-only /_gallery', () {
    expect(WidgetGalleryScreen.route, '/_gallery');
  });

  test('every public catalogue widget has a gallery entry', () {
    final String gallery = File(
      'lib/core/widgets/gallery/widget_gallery_screen.dart',
    ).readAsStringSync();
    final List<String> missing = <String>[];
    for (final String name in _catalogueWidgets()) {
      if (name == 'WidgetGalleryScreen') {
        continue;
      }
      if (!RegExp('\\b$name\\b').hasMatch(gallery)) {
        missing.add(name);
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'catalogue widgets with no gallery entry: ${missing.join(', ')} '
          '(FE-CONS-03)',
    );
  });

  test('gallery chrome uses Copy, not a synonym', () {
    expect(Copy.galleryTitle, isNotEmpty);
    expect(Copy.galleryTheme, isNot(contains('helper')));
  });
}

/// First public widget class in every hand-written file under core/widgets.
List<String> _catalogueWidgets() {
  final Directory root = Directory('lib/core/widgets');
  final List<String> names = <String>[];
  for (final File file
      in root
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (File file) =>
                file.path.endsWith('.dart') &&
                file.uri.pathSegments.last.split('.').length == 2,
          )) {
    for (final String line in file.readAsLinesSync()) {
      final Match? match = _widgetClass.firstMatch(line.trimLeft());
      if (match != null) {
        names.add(match.group(1)!);
      }
    }
  }
  names.sort();
  return names;
}
