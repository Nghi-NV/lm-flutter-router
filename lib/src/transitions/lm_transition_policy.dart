import 'package:flutter/widgets.dart';

import 'lm_transition.dart';

typedef LmReducedMotionResolver = bool Function(BuildContext context);

final class LmTransitionPolicy {
  const LmTransitionPolicy({
    this.route,
    this.shell,
    this.global = const LmTransition.cupertino(),
    this.reducedMotionTransition = const LmTransition.none(),
    this.reducedMotionResolver,
    this.respectMediaQueryDisableAnimations = true,
  });

  const LmTransitionPolicy.adaptive()
    : route = null,
      shell = null,
      global = const LmTransition.cupertino(),
      reducedMotionTransition = const LmTransition.none(),
      reducedMotionResolver = null,
      respectMediaQueryDisableAnimations = true;

  final LmTransition? route;
  final LmTransition? shell;
  final LmTransition global;
  final LmTransition reducedMotionTransition;
  final LmReducedMotionResolver? reducedMotionResolver;
  final bool respectMediaQueryDisableAnimations;

  LmTransition resolve({
    BuildContext? context,
    LmTransition? route,
    LmTransition? shell,
  }) {
    if (context != null && _reduceMotion(context)) {
      return reducedMotionTransition;
    }
    return route ?? this.route ?? shell ?? this.shell ?? global;
  }

  bool _reduceMotion(BuildContext context) {
    final resolver = reducedMotionResolver;
    if (resolver != null && resolver(context)) {
      return true;
    }
    return respectMediaQueryDisableAnimations &&
        MediaQuery.maybeDisableAnimationsOf(context) == true;
  }
}
