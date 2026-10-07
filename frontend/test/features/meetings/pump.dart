import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/errors/failure.dart';

const Failure meetingFailed = StorageFailure(
  message: 'Meeting could not be read.',
  recoveryAction: 'Try again.',
);

Future<void> pumpMeeting(WidgetTester tester, Widget child) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(body: SizedBox(width: 800, height: 1400, child: child)),
      ),
    ),
  );
}
