import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'folder_picker.dart';

const MethodChannel _filesChannel = MethodChannel('com.tapture.app/files');

/// Android uses the files channel; desktop uses a native folder dialog.
FolderPicker platformFolderPicker() => const _IoFolderPicker();

final class _IoFolderPicker implements FolderPicker {
  const _IoFolderPicker();

  @override
  bool get canPick => true;

  @override
  Future<Result<String?>> pick() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return _channelPick();
      }
      if (Platform.isWindows) {
        return _windowsPick();
      }
      if (Platform.isMacOS) {
        return _macPick();
      }
      return _linuxPick();
    } on Failure catch (failure) {
      return FailureResult<String?>(failure);
    } on Object {
      return const FailureResult<String?>(_failed);
    }
  }
}

Future<Result<String?>> _channelPick() async {
  try {
    final Object? path = await _filesChannel.invokeMethod<Object>(
      'pickDirectory',
    );
    if (path is String && path.isNotEmpty) {
      return Success<String?>(path);
    }
    return const FailureResult<String?>(CancelledFailure());
  } on PlatformException catch (error) {
    if (error.code == 'cancelled') {
      return const FailureResult<String?>(CancelledFailure());
    }
    return const FailureResult<String?>(_failed);
  }
}

Future<Result<String?>> _windowsPick() async {
  final ProcessResult result = await Process.run('powershell.exe', <String>[
    '-NoProfile',
    '-NonInteractive',
    '-Command',
    'Add-Type -AssemblyName System.Windows.Forms; '
        '\$d = New-Object System.Windows.Forms.FolderBrowserDialog; '
        '\$d.ShowNewFolderButton = \$true; '
        'if (\$d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { '
        '\$d.SelectedPath }',
  ]);
  return _processPath(result);
}

Future<Result<String?>> _macPick() async {
  final ProcessResult result = await Process.run('osascript', <String>[
    '-e',
    'POSIX path of (choose folder)',
  ]);
  if (result.exitCode != 0) {
    return const FailureResult<String?>(CancelledFailure());
  }
  return _processPath(result);
}

Future<Result<String?>> _linuxPick() async {
  final ProcessResult result = await Process.run('zenity', <String>[
    '--file-selection',
    '--directory',
  ]);
  if (result.exitCode != 0) {
    return const FailureResult<String?>(CancelledFailure());
  }
  return _processPath(result);
}

Result<String?> _processPath(ProcessResult result) {
  final Object? stdout = result.stdout;
  if (stdout is! String) {
    return const FailureResult<String?>(_failed);
  }
  final String path = stdout.trim();
  if (path.isEmpty) {
    return const FailureResult<String?>(CancelledFailure());
  }
  return Success<String?>(path);
}

const ProviderFailure _failed = ProviderFailure(
  message: Copy.settingsStorageRoot,
  recoveryAction: Copy.tryAgain,
);
