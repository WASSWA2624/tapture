/// What a ZIP's central directory holds that an import must refuse
/// (FE-SEC-06). [checkZipDirectory] reports the first one it meets.
enum ArchiveProblem {
  /// The bytes are not a readable ZIP directory.
  notArchive,

  /// An entry name is absolute, names a drive, holds `..` or a NUL.
  unsafePath,

  /// An entry is a symbolic link rather than a file.
  link,

  /// The entries declare more uncompressed data than the ceiling allows.
  tooLarge,
}
