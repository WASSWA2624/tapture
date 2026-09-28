import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/record_thumb.dart';

import '../../support/a11y_matchers.dart';

const String _frontPath = 'projects/boiler/photos/front.jpg';
const String _serialPath = 'projects/boiler/photos/serial.jpg';

void main() {
  late Directory dir;
  late File thumb;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tapture_record_thumb_');
    thumb = File('${dir.path}/front_96.png')
      ..writeAsBytesSync(img.encodePng(img.Image(width: 4, height: 4)));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets(
    'it draws the cached list thumbnail and never opens the original',
    (WidgetTester tester) async {
      final _RecordingThumbnails thumbnails = _RecordingThumbnails(
        <String, Result<String>>{_frontPath: Success<String>(thumb.path)},
      );
      await _pump(
        tester,
        thumbnails,
        const RecordThumb(sha256: 'sha-front', storagePath: _frontPath),
      );
      await tester.pump();

      expect(thumbnails.calls, <_ThumbCall>[
        (
          sha256: 'sha-front',
          storagePath: _frontPath,
          edge: AppConstants.images.thumbnailEdge,
        ),
      ]);
      final AppPhotoThumb drawn = _drawn(tester);
      expect(drawn.photo.sha256, 'sha-front');
      expect(drawn.photo.thumbPath, thumb.path);
      expect(drawn.photo.sourcePath, isEmpty);
      expect(_imageFilePaths(tester), <String>[thumb.path]);
      expect(find.text(Copy.missingPhoto), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('it is blank while the thumbnail loads, then shows it', (
    WidgetTester tester,
  ) async {
    final Completer<Result<String>> pending = Completer<Result<String>>();
    final _RecordingThumbnails thumbnails = _RecordingThumbnails(
      const <String, Result<String>>{},
      pending: pending,
    );
    await _pump(
      tester,
      thumbnails,
      const RecordThumb(sha256: 'sha-front', storagePath: _frontPath),
    );

    expect(_drawn(tester).photo.thumbPath, isEmpty);
    expect(find.byType(Image), findsNothing);
    expect(find.text(Copy.missingPhoto), findsNothing);

    pending.complete(Success<String>(thumb.path));
    await tester.pump();

    expect(_drawn(tester).photo.thumbPath, thumb.path);
    expect(_imageFilePaths(tester), <String>[thumb.path]);
  });

  testWidgets('a photo the service cannot read shows Missing photo', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _RecordingThumbnails(const <String, Result<String>>{}),
      const RecordThumb(sha256: 'sha-gone', storagePath: _frontPath),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(Copy.missingPhoto), findsOneWidget);
    expect(find.byIcon(AppIcons.brokenFile), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(
      find.byType(AppPhotoThumb),
      hasSemanticLabel(Copy.missingPhotoNamed(Copy.photo)),
    );
  });

  testWidgets('a cached thumbnail whose file is gone shows Missing photo', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _RecordingThumbnails(<String, Result<String>>{
        _frontPath: Success<String>('${dir.path}/deleted_96.png'),
      }),
      const RecordThumb(sha256: 'sha-front', storagePath: _frontPath),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(Copy.missingPhoto), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a thumbnail service that throws shows Missing photo', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _RecordingThumbnails(const <String, Result<String>>{}, throws: true),
      const RecordThumb(sha256: 'sha-front', storagePath: _frontPath),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(Copy.missingPhoto), findsOneWidget);
  });

  testWidgets('tap opens and long-press selects', (WidgetTester tester) async {
    int taps = 0;
    int longPresses = 0;
    await _pump(
      tester,
      _RecordingThumbnails(<String, Result<String>>{
        _frontPath: Success<String>(thumb.path),
      }),
      RecordThumb(
        sha256: 'sha-front',
        storagePath: _frontPath,
        onTap: () => taps++,
        onLongPress: () => longPresses++,
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(RecordThumb));
    await tester.pump();
    expect(taps, 1);
    expect(longPresses, 0);

    await tester.longPress(find.byType(RecordThumb));
    await tester.pump();
    expect(taps, 1);
    expect(longPresses, 1);
  });

  testWidgets('without callbacks it is an image, not a button', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _RecordingThumbnails(<String, Result<String>>{
        _frontPath: Success<String>(thumb.path),
      }),
      const RecordThumb(sha256: 'sha-front', storagePath: _frontPath),
    );
    await tester.pump();

    expect(find.byType(InkWell), findsNothing);
    expect(
      tester.getSemantics(find.byType(AppPhotoThumb)),
      isSemantics(isImage: true, isButton: false),
    );
  });

  testWidgets('a selected thumb shows a tick and is read as selected', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _RecordingThumbnails(<String, Result<String>>{
        _frontPath: Success<String>(thumb.path),
      }),
      RecordThumb(
        sha256: 'sha-front',
        storagePath: _frontPath,
        hasCaption: true,
        selected: true,
        onTap: () {},
        onLongPress: () {},
      ),
    );
    await tester.pump();

    expect(_drawn(tester).selected, isTrue);
    expect(find.byIcon(AppIcons.check), findsOneWidget);
    expect(find.byIcon(AppIcons.caption), findsOneWidget);
    expect(
      find.byType(AppPhotoThumb),
      hasSemanticLabel('Photo, captioned, selected'),
    );
    expect(
      tester.getSemantics(find.byType(AppPhotoThumb)),
      isSemantics(isSelected: true, isButton: true, isImage: true),
    );
  });

  testWidgets('an unselected thumb shows no tick', (WidgetTester tester) async {
    await _pump(
      tester,
      _RecordingThumbnails(<String, Result<String>>{
        _frontPath: Success<String>(thumb.path),
      }),
      RecordThumb(sha256: 'sha-front', storagePath: _frontPath, onTap: () {}),
    );
    await tester.pump();

    expect(_drawn(tester).selected, isFalse);
    expect(find.byIcon(AppIcons.check), findsNothing);
    expect(
      tester.getSemantics(find.byType(AppPhotoThumb)),
      isSemantics(isSelected: false),
    );
  });

  testWidgets('the semantic label names the photo and keeps its states', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _RecordingThumbnails(<String, Result<String>>{
        _frontPath: Success<String>(thumb.path),
      }),
      Column(
        children: <Widget>[
          RecordThumb(
            key: const ValueKey<String>('named'),
            sha256: 'sha-front',
            storagePath: _frontPath,
            hasCaption: true,
            semanticLabel: 'Photo 1 of 2',
            onTap: () {},
          ),
          const RecordThumb(
            key: ValueKey<String>('named-missing'),
            sha256: 'sha-serial',
            storagePath: _serialPath,
            semanticLabel: 'Photo 2 of 2',
          ),
        ],
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('named')),
      hasSemanticLabel('Photo 1 of 2, captioned'),
    );
    expect(
      find.byKey(const ValueKey<String>('named-missing')),
      hasSemanticLabel(Copy.missingPhotoNamed('Photo 2 of 2')),
    );
  });

  testWidgets('the default edge is a 48dp target and a small one grows to it', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _pump(
      tester,
      _RecordingThumbnails(<String, Result<String>>{
        _frontPath: Success<String>(thumb.path),
      }),
      Column(
        children: <Widget>[
          RecordThumb(
            key: const ValueKey<String>('default'),
            sha256: 'sha-front',
            storagePath: _frontPath,
            onTap: () {},
          ),
          RecordThumb(
            key: const ValueKey<String>('small'),
            sha256: 'sha-front',
            storagePath: _frontPath,
            size: Space.x6,
            onTap: () {},
          ),
        ],
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const ValueKey<String>('default'))),
      const Size.square(Sizes.minTapTarget),
    );
    expect(find.byKey(const ValueKey<String>('small')), meetsTapTarget());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('the size sets the layout edge', (WidgetTester tester) async {
    final double edge = AppConstants.images.thumbnailEdge.toDouble();
    await _pump(
      tester,
      _RecordingThumbnails(<String, Result<String>>{
        _frontPath: Success<String>(thumb.path),
      }),
      RecordThumb(sha256: 'sha-front', storagePath: _frontPath, size: edge),
    );
    await tester.pump();

    expect(tester.getSize(find.byType(RecordThumb)), Size.square(edge));
  });

  testWidgets('quarter turns rotate the image the way it was saved', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _RecordingThumbnails(<String, Result<String>>{
        _frontPath: Success<String>(thumb.path),
      }),
      const Column(
        children: <Widget>[
          RecordThumb(
            key: ValueKey<String>('upright'),
            sha256: 'sha-front',
            storagePath: _frontPath,
          ),
          RecordThumb(
            key: ValueKey<String>('turned'),
            sha256: 'sha-front',
            storagePath: _frontPath,
            quarterTurns: 1,
          ),
        ],
      ),
    );
    await tester.pump();

    final Finder upright = find.byKey(const ValueKey<String>('upright'));
    final Finder turned = find.byKey(const ValueKey<String>('turned'));
    expect(
      find.descendant(of: upright, matching: find.byType(RotatedBox)),
      findsNothing,
    );
    final Finder rotation = find.descendant(
      of: turned,
      matching: find.byType(RotatedBox),
    );
    expect(tester.widget<RotatedBox>(rotation).quarterTurns, 1);
    expect(
      tester
          .widget<AppPhotoThumb>(
            find.descendant(of: turned, matching: find.byType(AppPhotoThumb)),
          )
          .quarterTurns,
      1,
    );
    expect(
      find.descendant(of: rotation, matching: find.byType(Image)),
      findsOneWidget,
    );
  });

  testWidgets('every turn of one photo shares one cached thumbnail request', (
    WidgetTester tester,
  ) async {
    final _RecordingThumbnails thumbnails = _RecordingThumbnails(
      <String, Result<String>>{_frontPath: Success<String>(thumb.path)},
    );
    await _pump(
      tester,
      thumbnails,
      const Row(
        children: <Widget>[
          RecordThumb(sha256: 'sha-front', storagePath: _frontPath),
          RecordThumb(
            sha256: 'sha-front',
            storagePath: _frontPath,
            quarterTurns: 2,
          ),
        ],
      ),
    );
    await tester.pump();

    expect(thumbnails.calls, hasLength(1));
    expect(_imageFilePaths(tester), <String>[thumb.path, thumb.path]);
  });

  testWidgets('a new photo asks for its own thumbnail', (
    WidgetTester tester,
  ) async {
    final File serial = File('${dir.path}/serial_96.png')
      ..writeAsBytesSync(thumb.readAsBytesSync());
    final _RecordingThumbnails thumbnails =
        _RecordingThumbnails(<String, Result<String>>{
          _frontPath: Success<String>(thumb.path),
          _serialPath: Success<String>(serial.path),
        });
    await _pump(
      tester,
      thumbnails,
      const RecordThumb(sha256: 'sha-front', storagePath: _frontPath),
    );
    await tester.pump();
    expect(_drawn(tester).photo.thumbPath, thumb.path);

    await _pump(
      tester,
      thumbnails,
      const RecordThumb(sha256: 'sha-serial', storagePath: _serialPath),
    );
    await tester.pump();

    expect(
      thumbnails.calls.map((_ThumbCall call) => call.storagePath),
      <String>[_frontPath, _serialPath],
    );
    expect(_drawn(tester).photo.sha256, 'sha-serial');
    expect(_drawn(tester).photo.thumbPath, serial.path);
  });

  testWidgets('the thumbnail request is dropped when no thumb shows it', (
    WidgetTester tester,
  ) async {
    final _RecordingThumbnails thumbnails = _RecordingThumbnails(
      <String, Result<String>>{_frontPath: Success<String>(thumb.path)},
    );
    await _pump(
      tester,
      thumbnails,
      const RecordThumb(sha256: 'sha-front', storagePath: _frontPath),
    );
    await tester.pump();
    await _pump(tester, thumbnails, const SizedBox.shrink());
    await tester.pump();
    await _pump(
      tester,
      thumbnails,
      const RecordThumb(sha256: 'sha-front', storagePath: _frontPath),
    );
    await tester.pump();

    expect(thumbnails.calls, hasLength(2));
    expect(_drawn(tester).photo.thumbPath, thumb.path);
  });
}

/// One thumbnail request, as the service received it.
typedef _ThumbCall = ({String sha256, String storagePath, int edge});

/// A hand-written [PhotoThumbnails] that records every request and answers
/// from [_answers] by storage path, or from [pending] when given.
final class _RecordingThumbnails implements PhotoThumbnails {
  _RecordingThumbnails(this._answers, {this.pending, this.throws = false});

  final Map<String, Result<String>> _answers;

  /// Answers every request once completed, so a test sees loading first.
  final Completer<Result<String>>? pending;

  /// Whether every request throws instead of answering.
  final bool throws;

  final List<_ThumbCall> calls = <_ThumbCall>[];

  @override
  Future<Result<Uint8List>> bytesFor({
    required String sha256,
    required String storagePath,
    required int edge,
  }) async {
    throw UnimplementedError('record thumbs read paths on this platform');
  }

  @override
  Future<Result<String>> pathFor({
    required String sha256,
    required String storagePath,
    required int edge,
  }) async {
    calls.add((sha256: sha256, storagePath: storagePath, edge: edge));
    if (throws) {
      throw const FileSystemException('thumbnail cache unreadable');
    }
    final Completer<Result<String>>? wait = pending;
    if (wait != null) {
      return wait.future;
    }
    return _answers[storagePath] ??
        const FailureResult<String>(StorageFailure());
  }
}

Future<void> _pump(
  WidgetTester tester,
  PhotoThumbnails thumbnails,
  Widget child,
) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        photoThumbnailsProvider.overrideWithValue(thumbnails),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

AppPhotoThumb _drawn(WidgetTester tester) {
  return tester.widget<AppPhotoThumb>(find.byType(AppPhotoThumb));
}

List<String> _imageFilePaths(WidgetTester tester) {
  final List<String> paths = <String>[];
  for (final Image image in tester.widgetList<Image>(find.byType(Image))) {
    ImageProvider<Object> provider = image.image;
    if (provider is ResizeImage) {
      provider = provider.imageProvider;
    }
    if (provider is FileImage) {
      paths.add(provider.file.path);
    }
  }
  return paths;
}
