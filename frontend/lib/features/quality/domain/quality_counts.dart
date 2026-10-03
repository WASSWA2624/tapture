/// What still blocks a clean export of one project (task 015).
///
/// [invalid] comes from the validation engine, [duplicates] from the
/// duplicates table, [conflicts] from the unresolved merge conflicts and
/// [unreviewed] from the record statuses; a clean project is all zeros.
typedef QualityCounts = ({
  int invalid,
  int duplicates,
  int conflicts,
  int unreviewed,
});

/// Whether [counts] leaves nothing to clear.
bool isExportReady(QualityCounts counts) {
  return counts.invalid == 0 &&
      counts.duplicates == 0 &&
      counts.conflicts == 0 &&
      counts.unreviewed == 0;
}
