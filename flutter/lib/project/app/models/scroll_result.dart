abstract class ScrollResult {
  const ScrollResult();
}

class ScrollConsumed extends ScrollResult {
  final double newOffset;
  const ScrollConsumed(this.newOffset);
}

class ScrollOverflow extends ScrollResult {
  final double overflowAmount;
  const ScrollOverflow(this.overflowAmount);
}

class ScrollUnderflow extends ScrollResult {
  final double underflowAmount;
  const ScrollUnderflow(this.underflowAmount);
}
