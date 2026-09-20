// ignore_for_file: library_private_types_in_public_api

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/project_repository.dart';
import 'current_project.dart';

/// Whether the landing list includes archived projects.
final class ProjectListFilter extends Notifier<bool> {
  /// Starts with archived projects hidden.
  @override
  bool build() => false;

  /// Shows or hides archived projects on the landing list.
  void set(bool value) => state = value;
}

/// Filter the landing list reads. Off by default so archived rows stay
/// hidden until the operator asks.
final NotifierProvider<ProjectListFilter, bool>
projectListShowArchivedProvider = NotifierProvider<ProjectListFilter, bool>(
  ProjectListFilter.new,
  retry: (int _, Object _) => null,
);

/// The project-list search query. Survives a size-class change so the
/// pane can restore what was typed (FE-RESP-03).
final NotifierProvider<_ProjectListSearchQuery, String>
projectListSearchQueryProvider =
    NotifierProvider<_ProjectListSearchQuery, String>(
      _ProjectListSearchQuery.new,
      retry: (int _, Object _) => null,
    );

/// [projectListProvider] narrowed to a case-insensitive, accent-folded
/// match on the project name.
final Provider<AsyncValue<List<ProjectListRow>>> projectListFilteredProvider =
    Provider<AsyncValue<List<ProjectListRow>>>((Ref ref) {
      final String query = ref.watch(projectListSearchQueryProvider);
      final AsyncValue<List<ProjectListRow>> list = ref.watch(
        projectListProvider,
      );
      final String needle = _foldProjectSearch(query.trim());
      if (needle.isEmpty) {
        return list;
      }
      return list.whenData((List<ProjectListRow> rows) {
        return <ProjectListRow>[
          for (final ProjectListRow row in rows)
            if (_foldProjectSearch(row.project.name).contains(needle)) row,
        ];
      });
    });

/// Case-folds [input] and strips common Latin diacritics so "Café"
/// matches "cafe" without a new package.
String _foldProjectSearch(String input) {
  String text = input.toLowerCase();
  text = text.replaceAll('ß', 'ss');
  text = text.replaceAll('æ', 'ae');
  text = text.replaceAll('œ', 'oe');
  final StringBuffer out = StringBuffer();
  for (final int rune in text.runes) {
    if (rune >= 0x0300 && rune <= 0x036F) {
      continue;
    }
    out.writeCharCode(_baseLetter(rune));
  }
  return out.toString();
}

class _ProjectListSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  /// Replaces the query. The field owns debounce; this stores the last emit.
  void set(String value) => state = value;
}

int _baseLetter(int rune) {
  if (rune < 0x00C0) {
    return rune;
  }
  if (rune >= 0x00E0 && rune <= 0x00E5) {
    return 0x61;
  }
  if (rune == 0x00E7) {
    return 0x63;
  }
  if (rune >= 0x00E8 && rune <= 0x00EB) {
    return 0x65;
  }
  if (rune >= 0x00EC && rune <= 0x00EF) {
    return 0x69;
  }
  if (rune == 0x00F1) {
    return 0x6E;
  }
  if (rune >= 0x00F2 && rune <= 0x00F6) {
    return 0x6F;
  }
  if (rune == 0x00F8) {
    return 0x6F;
  }
  if (rune >= 0x00F9 && rune <= 0x00FC) {
    return 0x75;
  }
  if (rune == 0x00FD || rune == 0x00FF) {
    return 0x79;
  }
  if (rune >= 0x0100 && rune <= 0x0105) {
    return 0x61;
  }
  if (rune >= 0x0106 && rune <= 0x010D) {
    return 0x63;
  }
  if (rune >= 0x010E && rune <= 0x0111) {
    return 0x64;
  }
  if (rune >= 0x0112 && rune <= 0x011B) {
    return 0x65;
  }
  if (rune >= 0x011C && rune <= 0x0123) {
    return 0x67;
  }
  if (rune >= 0x0124 && rune <= 0x0127) {
    return 0x68;
  }
  if (rune >= 0x0128 && rune <= 0x0131) {
    return 0x69;
  }
  if (rune >= 0x0134 && rune <= 0x0135) {
    return 0x6A;
  }
  if (rune >= 0x0136 && rune <= 0x0138) {
    return 0x6B;
  }
  if (rune >= 0x0139 && rune <= 0x0142) {
    return 0x6C;
  }
  if (rune >= 0x0143 && rune <= 0x014B) {
    return 0x6E;
  }
  if (rune >= 0x014C && rune <= 0x0151) {
    return 0x6F;
  }
  if (rune >= 0x0154 && rune <= 0x0159) {
    return 0x72;
  }
  if (rune >= 0x015A && rune <= 0x0161) {
    return 0x73;
  }
  if (rune >= 0x0162 && rune <= 0x0167) {
    return 0x74;
  }
  if (rune >= 0x0168 && rune <= 0x0173) {
    return 0x75;
  }
  if (rune >= 0x0174 && rune <= 0x0175) {
    return 0x77;
  }
  if (rune >= 0x0176 && rune <= 0x0178) {
    return 0x79;
  }
  if (rune >= 0x0179 && rune <= 0x017E) {
    return 0x7A;
  }
  return rune;
}
