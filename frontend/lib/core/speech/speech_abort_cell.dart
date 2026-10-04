/// The main isolate's reference to the shared abort cell a decode worker
/// polls (spec §30.4.2).
///
/// The cell holds the highest job id aborted so far; a decode with id `J`
/// stops once the cell holds `J` or more. Job ids rise with every dispatch
/// and only one decode is in flight, so aborting one job never touches a
/// later one. Creating the cell, storing to it and closing it are the only
/// native calls the main isolate makes (FE-PERF-02).
abstract interface class SpeechAbortCell {
  /// The cell's native address, which a worker borrows (and so retains).
  int get address;

  /// Aborts the in-flight job [jobId] and every earlier one. A [jobId] at
  /// or below one already stored does nothing.
  void abortThrough(int jobId);

  /// Releases the main isolate's reference. The cell itself lives until
  /// every borrowing worker has released it too. Closing twice does
  /// nothing.
  void close();
}
