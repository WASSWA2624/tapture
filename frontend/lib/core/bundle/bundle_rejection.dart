/// Why a project package was refused, one value per check, so the message
/// names the check that failed (FE-SEC-06, task 019).
enum BundleRejection {
  /// Larger than this device opens.
  tooLarge,

  /// Not a ZIP, or not a Tapture package.
  notAPackage,

  /// An entry name leaves the package, or is a link.
  unsafePath,

  /// An entry the package needs, or one its manifest lists, is missing.
  missingEntry,

  /// The manifest or a table could not be read.
  unreadable,

  /// Written by a newer version of the package format.
  unknownFormatVersion,

  /// An entry's bytes do not match its checksum, or an entry is unlisted.
  checksumMismatch,
}
