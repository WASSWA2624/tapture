import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'document_picker.dart';

const MethodChannel _filesChannel = MethodChannel('com.tapture.app/files');

/// Android and iOS use the files channel, which copies the chosen document
/// into the app's cache; desktop uses a native file dialog.
DocumentPicker platformDocumentPicker() => const _IoDocumentPicker();

final class _IoDocumentPicker implements DocumentPicker {
  const _IoDocumentPicker();

  @override
  bool get canPick => true;

  @override
  Future<Result<PickedDocument>> pick({
    required List<String> extensions,
    required String mimeType,
    int? maxBytes,
  }) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return await _channelPick(extensions, mimeType);
      }
      final ProcessResult result;
      if (Platform.isWindows) {
        result = await Process.run(
          'powershell.exe',
          windowsDocumentArguments(extensions),
        );
      } else if (Platform.isMacOS) {
        result = await Process.run(
          'osascript',
          macDocumentArguments(extensions),
        );
      } else {
        result = await Process.run(
          'zenity',
          linuxDocumentArguments(extensions),
        );
      }
      return await _fromProcess(result);
    } on Failure catch (failure) {
      return FailureResult<PickedDocument>(failure);
    } on Object {
      return const FailureResult<PickedDocument>(_failed);
    }
  }
}

/// PowerShell arguments for a one-file open dialog limited to [extensions].
List<String> windowsDocumentArguments(List<String> extensions) {
  final String patterns = extensions.map((String e) => '*.$e').join(';');
  return <String>[
    '-NoProfile',
    '-NonInteractive',
    '-Command',
    'Add-Type -AssemblyName System.Windows.Forms; '
        '\$d = New-Object System.Windows.Forms.OpenFileDialog; '
        "\$d.Filter = '$patterns|$patterns'; "
        '\$d.Multiselect = \$false; '
        'if (\$d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { '
        '\$d.FileName }',
  ];
}

/// AppleScript arguments for a file chooser limited to [extensions].
List<String> macDocumentArguments(List<String> extensions) {
  final String types = extensions.map((String e) => '"$e"').join(', ');
  return <String>['-e', 'POSIX path of (choose file of type {$types})'];
}

/// Zenity arguments for a file chooser limited to [extensions].
List<String> linuxDocumentArguments(List<String> extensions) {
  return <String>[
    '--file-selection',
    '--file-filter=${extensions.map((String e) => '*.$e').join(' ')}',
  ];
}

Future<Result<PickedDocument>> _channelPick(
  List<String> extensions,
  String mimeType,
) async {
  try {
    final Map<Object?, Object?>? picked = await _filesChannel
        .invokeMapMethod<Object?, Object?>('pickDocument', <String, Object>{
          'mimeType': mimeType,
          'extensions': extensions,
        });
    final Object? path = picked?['path'];
    if (path is! String || path.isEmpty) {
      return const FailureResult<PickedDocument>(CancelledFailure());
    }
    return _describe(File(path), picked?['name']);
  } on PlatformException catch (error) {
    if (error.code == 'cancelled') {
      return const FailureResult<PickedDocument>(CancelledFailure());
    }
    return const FailureResult<PickedDocument>(_failed);
  }
}

Future<Result<PickedDocument>> _fromProcess(ProcessResult result) async {
  final Object? stdout = result.stdout;
  if (result.exitCode != 0 || stdout is! String || stdout.trim().isEmpty) {
    return const FailureResult<PickedDocument>(CancelledFailure());
  }
  return _describe(File(stdout.trim()), null);
}

Future<Result<PickedDocument>> _describe(File file, Object? name) async {
  if (!file.existsSync()) {
    return const FailureResult<PickedDocument>(_failed);
  }
  final String shown = name is String && name.isNotEmpty
      ? name
      : file.uri.pathSegments.last;
  return Success<PickedDocument>(PickedFile(file, shown, await file.length()));
}

const StorageFailure _failed = StorageFailure(
  message: Copy.documentPickFailed,
  recoveryAction: Copy.tryAgain,
);
