abstract class SectionManager {
  /// The maximum scroll height of this section.
  double get maxHeight;

  /// Called when the active section is scrolled.
  /// [localOffset] is guaranteed to be between 0 and [maxHeight] (inclusive).
  void onScroll(double localOffset);

  /// Called when this section becomes active.
  void onActivate();

  /// Called when this section becomes inactive.
  void onDeactivate();
}
