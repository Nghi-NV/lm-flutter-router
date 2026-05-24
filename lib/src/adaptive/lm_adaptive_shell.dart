import 'package:flutter/widgets.dart';

import 'lm_adaptive_policy.dart';

typedef LmAdaptiveShellBuilder = Widget Function(BuildContext context);

final class LmAdaptiveShell extends StatelessWidget {
  const LmAdaptiveShell({
    required this.compactBuilder,
    required this.expandedBuilder,
    this.mediumBuilder,
    this.policy = const LmBreakpointPolicy(),
    super.key,
  });

  final LmAdaptiveRoutingPolicy policy;
  final LmAdaptiveShellBuilder compactBuilder;
  final LmAdaptiveShellBuilder? mediumBuilder;
  final LmAdaptiveShellBuilder expandedBuilder;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mode = policy.resolve(width);
    return switch (mode) {
      LmLayoutMode.compact => compactBuilder(context),
      LmLayoutMode.medium => (mediumBuilder ?? compactBuilder)(context),
      LmLayoutMode.expanded => expandedBuilder(context),
    };
  }
}
