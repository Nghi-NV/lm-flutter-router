import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../chrome/lm_glass_surface.dart';
import '../modal/lm_modal_presentation.dart';
import 'lm_cupertino_sheet_content_page.dart';
import 'lm_horizontal_back_gesture.dart';
import 'lm_transition.dart';

const bool _lmTraceTransitions = bool.fromEnvironment(
  'LM_ROUTER_TRACE_TRANSITIONS',
);
const double _cupertinoSheetTopInset = 12;
const double _cupertinoSheetInitialHeightFactor = 0.52;
const double _cupertinoSheetPageTopReveal = 44;
const double _cupertinoSheetMinimizedScale = 0.92;
const double _cupertinoSheetCornerRadius = 12;
const double _cupertinoActionSheetCornerRadius = 14;
const double _cupertinoActionSheetHorizontalMargin = 8;
const double _cupertinoActionSheetMaxWidth = 414;
const double _cupertinoPopoverMaxWidth = 420;
const double _cupertinoAlertMaxWidth = 270;
const double _cupertinoWideModalBreakpoint = 600;
const Color _cupertinoSheetBarrierColor = kCupertinoModalBarrierColor;
const Color _cupertinoSheetPageBarrierColor = Color(0x00000000);
const Color _cupertinoSheetOverlayColor = Color(0x14000000);
const Color _cupertinoSheetPageOverlayColor = Color(0x08000000);
const Curve _cupertinoSheetOutgoingCurve = Curves.easeIn;
const Curve _cupertinoSheetTransitionCurve = Curves.fastEaseInToSlowEaseOut;

void _lmTraceTransition(String message) {
  if (!_lmTraceTransitions) {
    return;
  }
  debugPrint('LM_ROUTER_TRACE ${DateTime.now().toIso8601String()} $message');
}

final class LmPageFactory {
  const LmPageFactory._();

  static Page<void> page({
    required LocalKey key,
    required String name,
    required Widget child,
    required LmTransition transition,
    VoidCallback? onPopGestureStart,
  }) {
    final routeChild = _OpaqueRouteSurface(child: child);
    if (transition is LmNoTransition) {
      return LmNoTransitionPage<void>(key: key, name: name, child: routeChild);
    }
    if (transition is LmCupertinoTransition) {
      return LmCupertinoPage<void>(
        key: key,
        name: name,
        child: routeChild,
        transition: transition,
        onPopGestureStart: onPopGestureStart,
      );
    }
    if (transition is LmHeroTransition) {
      return LmCupertinoPage<void>(
        key: key,
        name: name,
        child: routeChild,
        transition: transition,
        allowSnapshotting: false,
        onPopGestureStart: onPopGestureStart,
      );
    }
    if (transition is LmFullscreenModalTransition) {
      return LmCupertinoPage<void>(
        key: key,
        name: name,
        child: routeChild,
        transition: transition,
        fullscreenDialog: true,
        onPopGestureStart: onPopGestureStart,
      );
    }
    if (transition is LmCupertinoSheetTransition) {
      return _LmCupertinoSheetPage<void>(
        key: key,
        name: name,
        child: child,
        transition: transition,
      );
    }
    if (transition is LmSlideTransition || transition is LmScaleTransition) {
      return LmCupertinoPage<void>(
        key: key,
        name: name,
        child: routeChild,
        transition: transition,
        onPopGestureStart: onPopGestureStart,
      );
    }
    return LmTransitionPage<void>(
      key: key,
      name: name,
      child: routeChild,
      transition: transition,
    );
  }

  static LmModalPage<void> modalPage({
    required LocalKey key,
    required String name,
    required Widget child,
    required LmModalPresentation presentation,
    String? restorationId,
  }) {
    return LmModalPage<void>(
      key: key,
      name: name,
      child: child,
      presentation: presentation,
      restorationId: restorationId,
    );
  }
}

final class _LmCupertinoSheetPage<T> extends Page<T> {
  const _LmCupertinoSheetPage({
    required this.child,
    required this.transition,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final LmCupertinoSheetTransition transition;

  @override
  Route<T> createRoute(BuildContext context) {
    return _LmCupertinoSheetPageRoute<T>(
      settings: this,
      child: child,
      transition: transition,
    );
  }
}

final class _OpaqueRouteSurface extends StatelessWidget {
  const _OpaqueRouteSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: child,
      ),
    );
  }
}

final class LmNoTransitionPage<T> extends Page<T> {
  const LmNoTransitionPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return LmCupertinoPageRoute<T>(
      settings: this,
      builder: (_) => child,
      transition: const LmTransition.none(),
    );
  }
}

final class LmCupertinoPage<T> extends Page<T> {
  const LmCupertinoPage({
    required this.child,
    required this.transition,
    this.fullscreenDialog = false,
    this.allowSnapshotting = true,
    this.onPopGestureStart,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final LmTransition transition;
  final bool fullscreenDialog;
  final bool allowSnapshotting;
  final VoidCallback? onPopGestureStart;

  @override
  Route<T> createRoute(BuildContext context) {
    return LmCupertinoPageRoute<T>(
      settings: this,
      builder: (_) => child,
      fullscreenDialog: fullscreenDialog,
      transition: transition,
      allowSnapshotting: allowSnapshotting,
      onPopGestureStart: onPopGestureStart,
    );
  }
}

final class LmCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  LmCupertinoPageRoute({
    required super.builder,
    required this.transition,
    this.onPopGestureStart,
    super.settings,
    super.fullscreenDialog,
    super.allowSnapshotting = true,
  });

  final LmTransition transition;
  final VoidCallback? onPopGestureStart;
  VoidCallback? _traceAnimationListener;
  AnimationStatusListener? _traceStatusListener;
  double? _lastTraceValue;

  @override
  Duration get transitionDuration => transition.duration;

  @override
  Duration get reverseTransitionDuration => transition.reverseDuration;

  @override
  bool get popGestureEnabled {
    if (!transition.gesturePopEnabled) {
      return false;
    }
    if (transition is LmFullscreenModalTransition) {
      if (isFirst || willHandlePopInternally) {
        return false;
      }
      if (popDisposition == RoutePopDisposition.doNotPop) {
        return false;
      }
      return animation?.isCompleted ?? false;
    }
    return super.popGestureEnabled;
  }

  @override
  Widget buildContent(BuildContext context) {
    final content = super.buildContent(context);
    return LmHorizontalBackGestureDetector<T>(
      enabledCallback: () => popGestureEnabled,
      enabledListenable: animation,
      edgeWidth: _gestureEdgeWidthFor(context),
      onStartPopGesture: () => LmHorizontalBackGestureController<T>(
        navigator: navigator!,
        controller: controller!,
        getIsActive: () => isActive,
        getIsCurrent: () => isCurrent,
        onStart: onPopGestureStart,
      ),
      child: content,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    _attachTransitionTrace();
    final linearTransition = popGestureInProgress;
    final customTransitionCurve = linearTransition
        ? Curves.linear
        : transition.curve;
    return switch (transition) {
      LmNoTransition() => child,
      LmSlideTransition(:final from) => SlideTransition(
        position: _curvedRouteAnimation(
          animation,
          customTransitionCurve,
        ).drive(Tween<Offset>(begin: _offsetFor(from), end: Offset.zero)),
        child: child,
      ),
      LmScaleTransition(:final beginScale) => FadeTransition(
        opacity: _curvedRouteAnimation(animation, customTransitionCurve),
        child: ScaleTransition(
          scale: _curvedRouteAnimation(
            animation,
            customTransitionCurve,
          ).drive(Tween<double>(begin: beginScale, end: 1.0)),
          child: child,
        ),
      ),
      LmFullscreenModalTransition() => CupertinoFullscreenDialogTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: linearTransition,
        child: child,
      ),
      _ => CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: linearTransition,
        child: child,
      ),
    };
  }

  @override
  void handleStartBackGesture({double progress = 0.0}) {
    if (!isCurrent) {
      _traceRouteEvent(
        'predictive.start.ignored',
        'progress=$progress reason=not-current',
      );
      return;
    }
    final normalized = _normalizedRouteProgress(progress);
    _traceRouteEvent('predictive.start', 'progress=$progress set=$normalized');
    onPopGestureStart?.call();
    controller?.value = normalized;
    navigator?.didStartUserGesture();
  }

  @override
  void handleUpdateBackGestureProgress({required double progress}) {
    if (!isCurrent) {
      _traceRouteEvent(
        'predictive.update.ignored',
        'progress=$progress reason=not-current',
      );
      return;
    }
    final normalized = _normalizedRouteProgress(progress);
    _traceRouteEvent('predictive.update', 'progress=$progress set=$normalized');
    controller?.value = normalized;
  }

  @override
  void handleCancelBackGesture() {
    final routeController = controller;
    if (routeController == null) {
      _traceRouteEvent('predictive.cancel', 'controller=null');
      navigator?.didStopUserGesture();
      return;
    }
    _traceRouteEvent(
      'predictive.cancel',
      'from=${routeController.value.toStringAsFixed(4)} animateTo=1.0',
    );
    routeController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastEaseInToSlowEaseOut,
    );
    _stopUserGestureAfter(routeController);
  }

  @override
  void handleCommitBackGesture() {
    final routeController = controller;
    _traceRouteEvent(
      'predictive.commit',
      'controller=${routeController?.value.toStringAsFixed(4)} '
          'isCurrent=$isCurrent isAnimating=${routeController?.isAnimating}',
    );
    if (isCurrent) {
      onPopGestureStart?.call();
      navigator?.pop();
    }
    if (routeController == null) {
      navigator?.didStopUserGesture();
      return;
    }
    if (routeController.isAnimating) {
      routeController.animateBack(
        0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.fastEaseInToSlowEaseOut,
      );
      _stopUserGestureAfter(routeController);
      return;
    }
    navigator?.didStopUserGesture();
  }

  double _normalizedRouteProgress(double progress) {
    // Flutter's Android predictive-back transition builder already converts
    // system gesture progress into route-animation progress before calling the
    // route. The route controller must therefore consume this value directly:
    // 1.0 is fully visible and 0.0 is popped off to the right.
    return progress.clamp(0.0, 1.0).toDouble();
  }

  double _gestureEdgeWidthFor(BuildContext context) {
    final edgeWidth = switch (transition) {
      LmCupertinoTransition(:final gestureEdgeWidth) => gestureEdgeWidth,
      LmSlideTransition() => 56.0,
      LmScaleTransition() => 56.0,
      LmHeroTransition(:final gestureEdgeWidth) => gestureEdgeWidth,
      LmFullscreenModalTransition() => 56.0,
      _ => 20.0,
    };
    return _backGestureEdgeWidthFor(context, edgeWidth: edgeWidth);
  }

  void _attachTransitionTrace() {
    if (!_lmTraceTransitions || _traceAnimationListener != null) {
      return;
    }
    final routeController = controller;
    if (routeController == null) {
      return;
    }
    _traceAnimationListener = () {
      final value = routeController.value;
      final previous = _lastTraceValue;
      _lastTraceValue = value;
      final delta = previous == null ? 0.0 : value - previous;
      _traceRouteEvent(
        'frame',
        'value=${value.toStringAsFixed(4)} '
            'delta=${delta.toStringAsFixed(4)} '
            'status=${routeController.status.name} '
            'userGesture=$popGestureInProgress',
      );
    };
    _traceStatusListener = (status) {
      _traceRouteEvent(
        'status',
        'status=${status.name} value=${routeController.value.toStringAsFixed(4)}',
      );
    };
    routeController.addListener(_traceAnimationListener!);
    routeController.addStatusListener(_traceStatusListener!);
    _traceRouteEvent(
      'trace.attach',
      'value=${routeController.value.toStringAsFixed(4)}',
    );
  }

  void _traceRouteEvent(String event, String details) {
    if (!_lmTraceTransitions) {
      return;
    }
    _lmTraceTransition(
      'route=${settings.name ?? '<unnamed>'} event=$event '
      'value=${controller?.value.toStringAsFixed(4)} '
      'isCurrent=$isCurrent isActive=$isActive $details',
    );
  }

  void _stopUserGestureAfter(AnimationController routeController) {
    if (!routeController.isAnimating) {
      navigator?.didStopUserGesture();
      return;
    }
    late final AnimationStatusListener listener;
    listener = (_) {
      routeController.removeStatusListener(listener);
      navigator?.didStopUserGesture();
    };
    routeController.addStatusListener(listener);
  }

  @override
  void dispose() {
    final routeController = controller;
    final listener = _traceAnimationListener;
    if (routeController != null && listener != null) {
      routeController.removeListener(listener);
    }
    final statusListener = _traceStatusListener;
    if (routeController != null && statusListener != null) {
      routeController.removeStatusListener(statusListener);
    }
    super.dispose();
  }
}

final class LmTransitionPage<T> extends Page<T> {
  const LmTransitionPage({
    required this.child,
    required this.transition,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final LmTransition transition;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      transitionDuration: transition.duration,
      reverseTransitionDuration: transition.reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: transition.curve,
          reverseCurve: transition.curve.flipped,
        );
        return switch (transition) {
          LmFadeTransition() => FadeTransition(opacity: curved, child: child),
          LmSlideTransition(:final from) => SlideTransition(
            position: curved.drive(
              Tween<Offset>(begin: _offsetFor(from), end: Offset.zero),
            ),
            child: child,
          ),
          LmScaleTransition(:final beginScale) => FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: curved.drive(Tween<double>(begin: beginScale, end: 1.0)),
              child: child,
            ),
          ),
          LmCupertinoTransition() => SlideTransition(
            position: curved.drive(
              Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero),
            ),
            child: child,
          ),
          LmFullscreenModalTransition() => SlideTransition(
            position: curved.drive(
              Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero),
            ),
            child: child,
          ),
          LmCustomTransition(:final builder) when builder != null => builder(
            context,
            animation,
            secondaryAnimation,
            child,
          ),
          _ => child,
        };
      },
    );
  }
}

Widget _buildTransitionFor({
  required BuildContext context,
  required LmTransition transition,
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
  required Widget child,
}) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: transition.curve,
    reverseCurve: transition.curve.flipped,
  );
  return switch (transition) {
    LmNoTransition() => child,
    LmFadeTransition() => FadeTransition(opacity: curved, child: child),
    LmSlideTransition(:final from) => SlideTransition(
      position: curved.drive(
        Tween<Offset>(begin: _offsetFor(from), end: Offset.zero),
      ),
      child: child,
    ),
    LmScaleTransition(:final beginScale) => FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: curved.drive(Tween<double>(begin: beginScale, end: 1.0)),
        child: child,
      ),
    ),
    LmCupertinoTransition() => SlideTransition(
      position: curved.drive(
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero),
      ),
      child: child,
    ),
    LmFullscreenModalTransition() => SlideTransition(
      position: curved.drive(
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero),
      ),
      child: child,
    ),
    LmCustomTransition(:final builder) when builder != null => builder(
      context,
      animation,
      secondaryAnimation,
      child,
    ),
    _ => child,
  };
}

CurvedAnimation _curvedRouteAnimation(
  Animation<double> animation,
  Curve curve,
) {
  return CurvedAnimation(
    parent: animation,
    curve: curve,
    reverseCurve: curve.flipped,
  );
}

Offset _offsetFor(LmSlideFrom from) {
  return switch (from) {
    LmSlideFrom.left => const Offset(-1, 0),
    LmSlideFrom.right => const Offset(1, 0),
    LmSlideFrom.top => const Offset(0, -1),
    LmSlideFrom.bottom => const Offset(0, 1),
  };
}

double _backGestureEdgeWidthFor(BuildContext context, {double edgeWidth = 56}) {
  if (Theme.of(context).platform == TargetPlatform.android) {
    final routeWidth = MediaQuery.sizeOf(context).width;
    final androidEdgeWidth = math.min(routeWidth * 0.5, 192.0);
    return math
        .max(edgeWidth, androidEdgeWidth)
        .clamp(0.0, double.infinity)
        .toDouble();
  }
  return edgeWidth.clamp(0.0, double.infinity).toDouble();
}

final class LmModalPage<T> extends Page<T> {
  const LmModalPage({
    required this.child,
    required this.presentation,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final LmModalPresentation presentation;

  @override
  Route<T> createRoute(BuildContext context) {
    if (presentation.kind == LmModalPresentationKind.dialog ||
        presentation.kind == LmModalPresentationKind.cupertinoDialog) {
      return _LmPopupModalRoute<T>(
        settings: this,
        child: child,
        presentation: presentation,
      );
    }

    if (presentation.kind == LmModalPresentationKind.popover) {
      return _LmPopupModalRoute<T>(
        settings: this,
        child: child,
        presentation: presentation,
      );
    }

    return _LmBottomModalRoute<T>(
      settings: this,
      child: child,
      presentation: presentation,
    );
  }
}

final class _LmPopupModalRoute<T> extends PageRoute<T> {
  _LmPopupModalRoute({
    required this.child,
    required this.presentation,
    required super.settings,
  }) : super(
         barrierDismissible: presentation.barrierDismissible,
         allowSnapshotting: true,
       );

  final Widget child;
  final LmModalPresentation presentation;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => kCupertinoModalBarrierColor;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => presentation.transition.duration;

  @override
  Duration get reverseTransitionDuration =>
      presentation.transition.reverseDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final content = presentation.usesSafeArea ? SafeArea(child: child) : child;
    if (_usesCompactPopoverSheet(context)) {
      final surface = _CupertinoActionSheetSurface(child: child);
      final aligned = Align(
        alignment: Alignment.bottomCenter,
        child: _cupertinoActionSheetViewport(context: context, child: surface),
      );
      if (!presentation.usesSafeArea) {
        return aligned;
      }
      return SafeArea(top: false, child: aligned);
    }
    if (presentation.kind == LmModalPresentationKind.dialog ||
        presentation.kind == LmModalPresentationKind.cupertinoDialog) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _cupertinoAlertMaxWidth),
          child: _CupertinoPopupMaterialSurface(child: content),
        ),
      );
    }
    if (presentation.kind == LmModalPresentationKind.popover) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _cupertinoPopoverMaxWidth,
          ),
          child: _CupertinoPopoverSurface(child: content),
        ),
      );
    }
    return Center(child: content);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _buildTransitionFor(
      context: context,
      transition: presentation.transition,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }

  bool _usesCompactPopoverSheet(BuildContext context) {
    return presentation.kind == LmModalPresentationKind.popover &&
        MediaQuery.sizeOf(context).width < _cupertinoWideModalBreakpoint;
  }
}

final class _LmBottomModalRoute<T> extends PageRoute<T> {
  _LmBottomModalRoute({
    required this.child,
    required this.presentation,
    required super.settings,
  }) : super(
         barrierDismissible: presentation.barrierDismissible,
         allowSnapshotting: true,
       );

  final Widget child;
  final LmModalPresentation presentation;

  @override
  bool get opaque => presentation.fullscreen;

  @override
  Color? get barrierColor => _cupertinoSheetBarrierColor;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => presentation.transition.duration;

  @override
  Duration get reverseTransitionDuration =>
      presentation.transition.reverseDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    return (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      bool allowSnapshotting,
      Widget? child,
    ) {
      return _CupertinoSheetOutgoingTransition(
        animation: secondaryAnimation,
        endOffset: Offset(0, MediaQuery.viewPaddingOf(context).top),
        overlayColor: _cupertinoSheetOverlayColor,
        child: child ?? const SizedBox.shrink(),
      );
    };
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final modal = _modalContent(context, child);
    if (_supportsHorizontalPopGesture) {
      return LmHorizontalBackGestureDetector<T>(
        enabledCallback: () => _horizontalPopGestureEnabled,
        enabledListenable: animation,
        edgeWidth: _backGestureEdgeWidthFor(context),
        onStartPopGesture: () => LmHorizontalBackGestureController<T>(
          navigator: navigator!,
          controller: controller!,
          getIsActive: () => isActive,
          getIsCurrent: () => isCurrent,
        ),
        child: modal,
      );
    }
    if (_supportsDragDismiss) {
      return _DragDismissibleBottomModal(
        onDragUpdate: dragUpdate,
        onDragEnd: dragEnd,
        child: modal,
      );
    }
    return modal;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _buildTransitionFor(
      context: context,
      transition: presentation.transition,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }

  void dragUpdate(double delta, double height) {
    final routeController = controller;
    if (routeController == null || height <= 0) {
      return;
    }
    routeController.value = (routeController.value - delta / height)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  void dragEnd({required bool shouldDismiss}) {
    final routeController = controller;
    if (shouldDismiss) {
      navigator?.maybePop();
      return;
    }
    routeController?.animateTo(
      1.0,
      duration: _releasedSheetForwardDuration,
      curve: _cupertinoSheetTransitionCurve,
    );
  }

  Widget _modalContent(BuildContext context, Widget child) {
    final shouldBottomAlign =
        presentation.kind == LmModalPresentationKind.actionSheet ||
        (presentation.kind == LmModalPresentationKind.bottomSheet &&
            !presentation.fullscreen);
    final surface = presentation.kind == LmModalPresentationKind.actionSheet
        ? _CupertinoActionSheetSurface(child: child)
        : _CupertinoModalSheetSurface(
            fullscreen: presentation.fullscreen,
            showGrabber: !presentation.fullscreen,
            child: child,
          );
    if (!shouldBottomAlign) {
      final topInset =
          MediaQuery.viewPaddingOf(context).top + _cupertinoSheetTopInset;
      final padded = Padding(
        padding: EdgeInsets.only(top: topInset),
        child: surface,
      );
      return padded;
    }

    final aligned = Align(
      alignment: Alignment.bottomCenter,
      child: presentation.kind == LmModalPresentationKind.actionSheet
          ? _cupertinoActionSheetViewport(context: context, child: surface)
          : _cupertinoSheetViewport(context: context, child: surface),
    );
    if (!presentation.usesSafeArea) {
      return aligned;
    }
    return SafeArea(top: false, child: aligned);
  }

  bool get _supportsDragDismiss {
    if (presentation.fullscreen) {
      return false;
    }
    return presentation.kind == LmModalPresentationKind.actionSheet ||
        presentation.kind == LmModalPresentationKind.bottomSheet;
  }

  bool get _supportsHorizontalPopGesture =>
      presentation.fullscreen && presentation.transition.gesturePopEnabled;

  Duration get _releasedSheetForwardDuration {
    final value = controller?.value ?? 1.0;
    final fraction = (1.0 - value).clamp(0.0, 1.0);
    final millis = math.max(
      (transitionDuration.inMilliseconds * fraction).floor(),
      120,
    );
    return Duration(milliseconds: millis);
  }

  bool get _horizontalPopGestureEnabled {
    if (isFirst || willHandlePopInternally) {
      return false;
    }
    if (popDisposition == RoutePopDisposition.doNotPop) {
      return false;
    }
    return animation?.isCompleted ?? false;
  }
}

final class _LmCupertinoSheetPageRoute<T> extends PageRoute<T> {
  _LmCupertinoSheetPageRoute({
    required this.child,
    required this.transition,
    required super.settings,
  }) : super(barrierDismissible: true, allowSnapshotting: true);

  final Widget child;
  final LmCupertinoSheetTransition transition;
  bool _previousRouteIsCupertinoSheet = false;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => _cupertinoSheetPageBarrierColor;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => transition.duration;

  @override
  Duration get reverseTransitionDuration => transition.reverseDuration;

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    super.didChangePrevious(previousRoute);
    _previousRouteIsCupertinoSheet =
        previousRoute is _LmCupertinoSheetPageRoute<dynamic>;
  }

  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    return (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      bool allowSnapshotting,
      Widget? child,
    ) {
      return _CupertinoSheetOutgoingTransition(
        animation: secondaryAnimation,
        endOffset: _previousRouteIsCupertinoSheet
            ? const Offset(0, -_cupertinoSheetTopInset)
            : Offset(0, MediaQuery.viewPaddingOf(context).top),
        overlayColor: _cupertinoSheetPageOverlayColor,
        child: child ?? const SizedBox.shrink(),
      );
    };
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final modal = Align(
      alignment: Alignment.bottomCenter,
      child: _cupertinoSheetPageViewport(
        context: context,
        topReveal: _cupertinoSheetPageTopReveal,
        child: _CupertinoModalSheetSurface(
          fullscreen: false,
          showGrabber: false,
          child: _CupertinoSheetPageContent(child: child),
        ),
      ),
    );
    if (!transition.gesturePopEnabled) {
      return modal;
    }
    return _DragDismissibleBottomModal(
      onDragUpdate: dragUpdate,
      onDragEnd: dragEnd,
      child: modal,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = navigator?.userGestureInProgress ?? false
        ? Curves.linear
        : transition.curve;
    final curved = CurvedAnimation(
      parent: animation,
      curve: curve,
      reverseCurve: curve.flipped,
    );
    return SlideTransition(
      position: curved.drive(
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero),
      ),
      child: child,
    );
  }

  void dragUpdate(double delta, double height) {
    final routeController = controller;
    if (routeController == null || height <= 0) {
      return;
    }
    routeController.value = (routeController.value - delta / height)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  void dragEnd({required bool shouldDismiss}) {
    if (shouldDismiss) {
      final pop = navigator?.maybePop();
      if (pop == null) {
        _settleSheet();
        return;
      }
      pop.then((didPop) {
        if (!didPop) {
          _settleSheet();
        }
      });
      return;
    }
    _settleSheet();
  }

  void _settleSheet() {
    final routeController = controller;
    routeController?.animateTo(
      1.0,
      duration: _releasedSheetForwardDuration,
      curve: _cupertinoSheetTransitionCurve,
    );
  }

  Duration get _releasedSheetForwardDuration {
    final value = controller?.value ?? 1.0;
    final fraction = (1.0 - value).clamp(0.0, 1.0);
    final millis = math.max(
      (transitionDuration.inMilliseconds * fraction).floor(),
      120,
    );
    return Duration(milliseconds: millis);
  }
}

final class _CupertinoSheetOutgoingTransition extends StatelessWidget {
  const _CupertinoSheetOutgoingTransition({
    required this.animation,
    required this.endOffset,
    required this.overlayColor,
    required this.child,
  });

  final Animation<double> animation;
  final Offset endOffset;
  final Color overlayColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = animation.drive(
      CurveTween(curve: _cupertinoSheetOutgoingCurve),
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final value = curved.value;
        final scale = lerpDouble(1.0, _cupertinoSheetMinimizedScale, value)!;
        final offset = Offset(
          lerpDouble(0, endOffset.dx, value)!,
          lerpDouble(0, endOffset.dy, value)!,
        );
        final radius = lerpDouble(0, _cupertinoSheetCornerRadius, value)!;
        final overlay = overlayColor.withValues(alpha: overlayColor.a * value);
        return Transform.translate(
          offset: offset,
          child: Transform.scale(
            alignment: Alignment.topCenter,
            scale: scale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  child ?? const SizedBox.shrink(),
                  Positioned.fill(
                    child: IgnorePointer(child: ColoredBox(color: overlay)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _cupertinoSheetViewport({
  required BuildContext context,
  required Widget child,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final availableHeight = math.max(
        constraints.maxHeight - _cupertinoSheetTopInset,
        0.0,
      );
      return SizedBox(
        width: constraints.maxWidth,
        height: availableHeight * _cupertinoSheetInitialHeightFactor,
        child: child,
      );
    },
  );
}

Widget _cupertinoActionSheetViewport({
  required BuildContext context,
  required Widget child,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = math
          .min(
            constraints.maxWidth - _cupertinoActionSheetHorizontalMargin * 2,
            _cupertinoActionSheetMaxWidth,
          )
          .clamp(0.0, double.infinity)
          .toDouble();
      final maxHeight = math.max(
        constraints.maxHeight -
            MediaQuery.viewPaddingOf(context).top -
            _cupertinoSheetTopInset,
        0.0,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _cupertinoActionSheetHorizontalMargin,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
          child: child,
        ),
      );
    },
  );
}

Widget _cupertinoSheetPageViewport({
  required BuildContext context,
  required double topReveal,
  required Widget child,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final preferredTopReveal = MediaQuery.viewPaddingOf(context).top + 12;
      final effectiveTopReveal = math.max(preferredTopReveal, topReveal);
      return SizedBox(
        width: constraints.maxWidth,
        height: math.max(constraints.maxHeight - effectiveTopReveal, 0.0),
        child: child,
      );
    },
  );
}

final class _CupertinoSheetPageContent extends StatelessWidget {
  const _CupertinoSheetPageContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LmCupertinoSheetPageSurface(child: child);
  }
}

final class _CupertinoModalSheetSurface extends StatelessWidget {
  const _CupertinoModalSheetSurface({
    required this.fullscreen,
    required this.showGrabber,
    required this.child,
  });

  final bool fullscreen;
  final bool showGrabber;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = LmGlassSurface(
      variant: LmGlassSurfaceVariant.sheet,
      borderRadius: fullscreen
          ? BorderRadius.zero
          : const BorderRadius.vertical(
              top: Radius.circular(_cupertinoSheetCornerRadius),
            ),
      child: child,
    );
    if (fullscreen) {
      return surface;
    }
    if (!showGrabber) {
      return surface;
    }
    return Stack(
      children: [
        surface,
        PositionedDirectional(
          top: 8,
          start: 0,
          end: 0,
          child: IgnorePointer(
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGrey3,
                    context,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const SizedBox(width: 36, height: 4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class _CupertinoPopupMaterialSurface extends StatelessWidget {
  const _CupertinoPopupMaterialSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoPopupSurface(
      child: LmGlassSurface(
        variant: LmGlassSurfaceVariant.alert,
        theme: const LmGlassThemeData(
          enabled: false,
          intensity: LmGlassIntensity.regular,
          blurSigma: 0,
          tintOpacity: 0,
          borderOpacity: 0.18,
          highlightOpacity: 0.10,
        ),
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
    );
  }
}

final class _CupertinoPopoverSurface extends StatelessWidget {
  const _CupertinoPopoverSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LmGlassSurface(
      variant: LmGlassSurfaceVariant.popover,
      borderRadius: BorderRadius.circular(_cupertinoActionSheetCornerRadius),
      child: child,
    );
  }
}

final class _CupertinoActionSheetSurface extends StatelessWidget {
  const _CupertinoActionSheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LmGlassSurface(
      variant: LmGlassSurfaceVariant.actionSheet,
      borderRadius: BorderRadius.circular(_cupertinoActionSheetCornerRadius),
      child: child,
    );
  }
}

final class _DragDismissibleBottomModal extends StatefulWidget {
  const _DragDismissibleBottomModal({
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.child,
  });

  final void Function(double delta, double height) onDragUpdate;
  final void Function({required bool shouldDismiss}) onDragEnd;
  final Widget child;

  @override
  State<_DragDismissibleBottomModal> createState() =>
      _DragDismissibleBottomModalState();
}

final class _DragDismissibleBottomModalState
    extends State<_DragDismissibleBottomModal> {
  static const double _dismissViewportRatio = 0.3;
  static const double _dismissVelocityViewportRatio = 2.0;

  int? _activePointer;
  Duration? _lastPointerTime;
  double? _lastPointerY;
  double _pointerVelocity = 0;
  double _totalPointerDelta = 0;
  double _dragOffset = 0;

  void _handleDragStart() {
    _dragOffset = 0;
  }

  void _handleDragUpdate(double delta) {
    final nextOffset = math.max(0, _dragOffset + delta).toDouble();
    final effectiveDelta = nextOffset - _dragOffset;
    _dragOffset = nextOffset;
    if (effectiveDelta == 0) {
      return;
    }
    final height = context.size?.height ?? 0;
    widget.onDragUpdate(effectiveDelta, height);
  }

  void _handleDragEnd(double velocity) {
    final height = context.size?.height ?? 0;
    final dismissDistance = height * _dismissViewportRatio;
    final dismissVelocity = height * _dismissVelocityViewportRatio;
    final shouldDismiss =
        height > 0 &&
        (_dragOffset >= dismissDistance || velocity >= dismissVelocity);
    widget.onDragEnd(shouldDismiss: shouldDismiss);
    _dragOffset = 0;
  }

  void _handleDragCancel() {
    _handleDragEnd(0);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointer != null) {
      return;
    }
    _activePointer = event.pointer;
    _lastPointerTime = event.timeStamp;
    _lastPointerY = event.position.dy;
    _pointerVelocity = 0;
    _totalPointerDelta = 0;
    _handleDragStart();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    final lastTime = _lastPointerTime;
    final lastY = _lastPointerY;
    _lastPointerTime = event.timeStamp;
    _lastPointerY = event.position.dy;

    final delta = event.delta.dy;
    _totalPointerDelta += delta;
    if (_dragOffset == 0 && _totalPointerDelta <= 6) {
      return;
    }
    if (lastTime != null && lastY != null) {
      final elapsedMicros = (event.timeStamp - lastTime).inMicroseconds;
      if (elapsedMicros > 0) {
        _pointerVelocity =
            (event.position.dy - lastY) / (elapsedMicros / 1000000);
      }
    }
    _handleDragUpdate(delta);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    _activePointer = null;
    if (_dragOffset > 0) {
      _handleDragEnd(_pointerVelocity);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    _activePointer = null;
    _handleDragCancel();
  }

  @override
  Widget build(BuildContext context) {
    final sheet = Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        widthFactor: 1,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: widget.child,
        ),
      ),
    );
    return sheet;
  }
}
