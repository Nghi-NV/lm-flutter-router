enum LmLayoutMode { compact, medium, expanded }

abstract interface class LmAdaptiveRoutingPolicy {
  LmLayoutMode resolve(double width);
}

final class LmBreakpointPolicy implements LmAdaptiveRoutingPolicy {
  const LmBreakpointPolicy({
    this.compactMaxWidth = 600,
    this.expandedMinWidth = 840,
  }) : assert(compactMaxWidth <= expandedMinWidth);

  final double compactMaxWidth;
  final double expandedMinWidth;

  @override
  LmLayoutMode resolve(double width) {
    if (width < compactMaxWidth) {
      return LmLayoutMode.compact;
    }
    if (width < expandedMinWidth) {
      return LmLayoutMode.medium;
    }
    return LmLayoutMode.expanded;
  }
}
