import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/photo_naming.dart';
import 'package:tapture/core/export/photo_rename.dart';
import 'package:tapture/core/export/renameable_photo.dart';

void main() {
  const PhotoNamingTokens tokens = (
    project: 'Plant',
    recordNumber: '12',
    photoType: 'front',
    sequence: 1,
    context: <String, String>{'site': 'North'},
    serial: null,
    asset: 'A1',
  );

  test('a pattern is sanitised and two photos do not collide', () {
    const PhotoNaming naming = PhotoNaming(
      '{project}-{record}-{type}-{sequence}-{site}',
    );
    final Set<String> taken = <String>{};
    final String first = naming.nameFor(tokens, taken: taken);
    final String second = naming.nameFor(tokens, taken: taken);
    expect(first, 'Plant-12-front-1-North');
    expect(second, isNot(first));
    expect(taken, containsAll(<String>[first, second]));
  });

  test('an empty serial falls back to the asset number', () {
    const PhotoNaming naming = PhotoNaming('{serial}');
    final String name = naming.nameFor(tokens, taken: <String>{});
    expect(name, 'A1');
  });

  test('a rename keeps the original name and updates references', () async {
    final RenameablePhoto photo = RenameablePhoto(
      recordId: 'r1',
      path: 'provisional.jpg',
      type: 'front',
      sequence: 1,
    );
    final PhotoRenamer renamer = PhotoRenamer(<RenameablePhoto>[photo]);
    expect(await renamer.renameForIdentity('r1', identity: '00734'), 1);
    expect(photo.originalName, 'provisional.jpg');
    expect(photo.path, isNot('provisional.jpg'));
    expect(photo.references.single, photo.path);
    expect(photo.history, <String>['provisional.jpg']);
  });
}
