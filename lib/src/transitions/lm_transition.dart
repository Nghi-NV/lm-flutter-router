// ignore_for_file: use_super_parameters

import 'package:flutter/widgets.dart';

typedef LmTransitionBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    );

enum LmSlideFrom { left, right, top, bottom }

sealed class LmTransition {
  const LmTransition({
    required this.duration,
    required this.reverseDuration,
    required this.curve,
    required this.gesturePopEnabled,
  });

  const factory LmTransition.none() = LmNoTransition;

  const factory LmTransition.fade({
    Duration duration,
    Duration? reverseDuration,
    Curve curve,
  }) = LmFadeTransition;

  const factory LmTransition.slide({
    LmSlideFrom from,
    Duration duration,
    Duration? reverseDuration,
    Curve curve,
  }) = LmSlideTransition;

  const factory LmTransition.scale({
    double beginScale,
    Duration duration,
    Duration? reverseDuration,
    Curve curve,
    bool gesturePopEnabled,
  }) = LmScaleTransition;

  const factory LmTransition.cupertino({
    Duration duration,
    Duration? reverseDuration,
    Curve curve,
    bool gesturePopEnabled,
    double gestureEdgeWidth,
  }) = LmCupertinoTransition;

  const factory LmTransition.hero({
    Duration duration,
    Duration? reverseDuration,
    Curve curve,
    bool gesturePopEnabled,
    double gestureEdgeWidth,
  }) = LmHeroTransition;

  const factory LmTransition.fullscreenModal({
    Duration duration,
    Duration? reverseDuration,
    Curve curve,
    bool gesturePopEnabled,
  }) = LmFullscreenModalTransition;

  const factory LmTransition.cupertinoSheet({
    Duration duration,
    Duration? reverseDuration,
    Curve curve,
    bool gesturePopEnabled,
  }) = LmCupertinoSheetTransition;

  const factory LmTransition.custom({
    LmTransitionBuilder? builder,
    String? debugLabel,
    Duration duration,
    Duration? reverseDuration,
    Curve curve,
  }) = LmCustomTransition;

  final Duration duration;
  final Duration reverseDuration;
  final Curve curve;
  final bool gesturePopEnabled;
}

final class LmNoTransition extends LmTransition {
  const LmNoTransition()
    : super(
        duration: Duration.zero,
        reverseDuration: Duration.zero,
        curve: Curves.linear,
        gesturePopEnabled: false,
      );
}

final class LmFadeTransition extends LmTransition {
  const LmFadeTransition({
    Duration duration = const Duration(milliseconds: 200),
    Duration? reverseDuration,
    Curve curve = Curves.easeInOut,
  }) : super(
         duration: duration,
         reverseDuration: reverseDuration ?? duration,
         curve: curve,
         gesturePopEnabled: false,
       );
}

final class LmSlideTransition extends LmTransition {
  const LmSlideTransition({
    this.from = LmSlideFrom.right,
    Duration duration = const Duration(milliseconds: 500),
    Duration? reverseDuration,
    Curve curve = Curves.easeOutCubic,
  }) : super(
         duration: duration,
         reverseDuration: reverseDuration ?? duration,
         curve: curve,
         gesturePopEnabled: true,
       );

  final LmSlideFrom from;
}

final class LmScaleTransition extends LmTransition {
  const LmScaleTransition({
    this.beginScale = 0.94,
    Duration duration = const Duration(milliseconds: 260),
    Duration? reverseDuration,
    Curve curve = Curves.easeOutCubic,
    bool gesturePopEnabled = true,
  }) : super(
         duration: duration,
         reverseDuration: reverseDuration ?? duration,
         curve: curve,
         gesturePopEnabled: gesturePopEnabled,
       );

  final double beginScale;
}

final class LmCupertinoTransition extends LmTransition {
  const LmCupertinoTransition({
    Duration duration = const Duration(milliseconds: 500),
    Duration? reverseDuration,
    Curve curve = Curves.easeOutCubic,
    bool gesturePopEnabled = true,
    this.gestureEdgeWidth = 56,
  }) : super(
         duration: duration,
         reverseDuration: reverseDuration ?? duration,
         curve: curve,
         gesturePopEnabled: gesturePopEnabled,
       );

  final double gestureEdgeWidth;
}

final class LmHeroTransition extends LmTransition {
  const LmHeroTransition({
    Duration duration = const Duration(milliseconds: 500),
    Duration? reverseDuration,
    Curve curve = Curves.easeOutCubic,
    bool gesturePopEnabled = true,
    this.gestureEdgeWidth = 56,
  }) : super(
         duration: duration,
         reverseDuration: reverseDuration ?? duration,
         curve: curve,
         gesturePopEnabled: gesturePopEnabled,
       );

  final double gestureEdgeWidth;
}

final class LmFullscreenModalTransition extends LmTransition {
  const LmFullscreenModalTransition({
    Duration duration = const Duration(milliseconds: 500),
    Duration? reverseDuration,
    Curve curve = Curves.easeOutCubic,
    bool gesturePopEnabled = true,
  }) : super(
         duration: duration,
         reverseDuration: reverseDuration ?? duration,
         curve: curve,
         gesturePopEnabled: gesturePopEnabled,
       );
}

final class LmCupertinoSheetTransition extends LmTransition {
  const LmCupertinoSheetTransition({
    Duration duration = const Duration(milliseconds: 300),
    Duration? reverseDuration,
    Curve curve = Curves.fastEaseInToSlowEaseOut,
    bool gesturePopEnabled = true,
  }) : super(
         duration: duration,
         reverseDuration: reverseDuration ?? duration,
         curve: curve,
         gesturePopEnabled: gesturePopEnabled,
       );
}

final class LmCustomTransition extends LmTransition {
  const LmCustomTransition({
    this.builder,
    this.debugLabel,
    Duration duration = const Duration(milliseconds: 300),
    Duration? reverseDuration,
    Curve curve = Curves.easeInOut,
  }) : super(
         duration: duration,
         reverseDuration: reverseDuration ?? duration,
         curve: curve,
         gesturePopEnabled: false,
       );

  final LmTransitionBuilder? builder;
  final String? debugLabel;
}
