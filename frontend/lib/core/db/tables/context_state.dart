part of 'context.dart';

/// The value currently pinned at one context level for a project.
@DataClassName('ContextStateRow')
class ContextState extends Table with MergeColumns {
  /// Project that owns this pin.
  TextColumn get projectId => text()();

  /// Hierarchy order matching [Context.level].
  IntColumn get level => integer()();

  /// Pinned value. Written here, never to a log sink.
  TextColumn get value => text()();

  /// When this level was last set.
  DateTimeColumn get setAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{projectId, level},
  ];
}
