import 'package:flutter_home_page/project/app/models/scroll_result.dart';

abstract class SectionManager {
  /// Called when the active section is scrolled.
  /// [localOffset] is guaranteed to be between 0 and [maxHeight] (inclusive).
  void onScroll(double localOffset);

  /// Called when this section becomes active.
  /// [reverse] indicates if we are entering from the next section (scrolling up).
  /// Returns the initial scroll offset for this section.
  double onActivate(bool reverse);

  /// Called when this section becomes inactive.
  void onDeactivate();

  /// Processes scroll input and returns the result (Consumed, Overflow, or Underflow).
  /// [currentOffset] is the section's last known offset.
  /// [delta] is the raw scroll input delta.
  ScrollResult handleScroll(double currentOffset, double delta);
}
