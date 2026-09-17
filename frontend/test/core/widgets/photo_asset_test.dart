import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';

void main() {
  test('cache keys are hash plus edge', () {
    const PhotoAsset photo = PhotoAsset(sha256: 'abc123');
    expect(photo.cacheKey(96), 'abc123_96');
    expect(photo.cacheKey(256), 'abc123_256');
  });

  test('PhotoType labels and icons are unique', () {
    final Set<String> labels = <String>{};
    final Set<String> badges = <String>{};
    final Set<IconData> icons = <IconData>{};
    for (final PhotoType type in PhotoType.values) {
      expect(type.label, isNotEmpty);
      expect(type.badgeLabel, isNotEmpty);
      expect(labels.add(type.label), isTrue, reason: type.name);
      expect(badges.add(type.badgeLabel), isTrue, reason: type.name);
      expect(icons.add(type.icon), isTrue, reason: type.name);
    }
    expect(labels, hasLength(PhotoType.values.length));
  });
}
