import 'package:tapture/core/files/file_validation.dart';

/// Where a validated file goes (task 020). The import page applies it; it
/// never asks which importer to use (FE-SIMP-05).
enum ImportFlow {
  /// A project bundle: the merge flow of 114 · Bundles and merge.
  bundle,

  /// A reference dataset: the importer of 105 · Reference data.
  dataset,

  /// A template file: the template import of 009.
  template,

  /// Rows that still need a purpose: records, or a register to verify
  /// against.
  spreadsheet;

  /// The flow for a file the gate accepted as [kind], judged by its
  /// [extension] (lower case, no dot) and the text it opens with, [head].
  ///
  /// A JSON object is a template and a JSON array is a dataset's table; an
  /// XLSX or CSV is rows. Null for a kind this page does not import. [head]
  /// is file content: it is read, never followed (FE-SEC-05).
  static ImportFlow? of({
    required ImportKind kind,
    required String extension,
    required String head,
  }) {
    switch (kind) {
      case ImportKind.bundle:
        return ImportFlow.bundle;
      case ImportKind.spreadsheet:
        if (extension != 'json') {
          return ImportFlow.spreadsheet;
        }
        final String text = head.startsWith('﻿') ? head.substring(1) : head;
        return text.trimLeft().startsWith('{')
            ? ImportFlow.template
            : ImportFlow.dataset;
      case ImportKind.image:
      case ImportKind.document:
      case ImportKind.audio:
        return null;
    }
  }
}
