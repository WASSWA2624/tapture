/// A person's answer to one merge conflict (task 076, W21): keep what this
/// device holds, or take what arrived. Merge never picks for them.
enum ConflictChoice {
  /// Keep this device's value; for a deletion, keep the record here.
  mine,

  /// Take the incoming value; for a deletion, follow the other device.
  theirs,
}
