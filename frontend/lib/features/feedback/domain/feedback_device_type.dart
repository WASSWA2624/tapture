/// The kind of device an entry was written on.
enum FeedbackDeviceType {
  /// A touch phone.
  mobile('mobile', 'Mobile'),

  /// A touch tablet.
  tablet('tablet', 'Tablet'),

  /// A desktop, natively or in a desktop browser.
  desktop('desktop', 'Desktop');

  const FeedbackDeviceType(this.wireName, this.exportLabel);

  /// Stored name. Never renamed.
  final String wireName;

  /// Name in an exported workbook.
  final String exportLabel;

  /// The type stored as [name], or [mobile] for one this build does not
  /// know.
  static FeedbackDeviceType fromWire(Object? name) {
    for (final FeedbackDeviceType type in values) {
      if (type.wireName == name) {
        return type;
      }
    }
    return mobile;
  }
}
