import 'package:flutter/cupertino.dart';

import 'lm_horizontal_back_gesture.dart';

const Duration _kSheetContentTransitionDuration = Duration(milliseconds: 300);
const Curve _kSheetContentTransitionCurve = Curves.fastEaseInToSlowEaseOut;
const double _kSheetContentGestureEdgeWidth = 56;

/// A page intended for nested navigation inside an iOS 15-style sheet.
///
/// The page supplies an opaque Cupertino system background so horizontal pushes
/// do not show the previous sheet page's text through the incoming page.
final class LmCupertinoSheetContentPage<T> extends Page<T> {
  const LmCupertinoSheetContentPage({
    required this.child,
    this.duration = _kSheetContentTransitionDuration,
    this.curve = _kSheetContentTransitionCurve,
    this.gesturePopEnabled = true,
    this.gestureEdgeWidth = _kSheetContentGestureEdgeWidth,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool gesturePopEnabled;
  final double gestureEdgeWidth;

  @override
  Route<T> createRoute(BuildContext context) {
    return _LmCupertinoSheetContentPageRoute<T>(
      settings: this,
      child: child,
      duration: duration,
      curve: curve,
      gesturePopEnabled: gesturePopEnabled,
      gestureEdgeWidth: gestureEdgeWidth,
    );
  }
}

final class _LmCupertinoSheetContentPageRoute<T> extends PageRoute<T> {
  _LmCupertinoSheetContentPageRoute({
    required this.child,
    required this.duration,
    required this.curve,
    required this.gesturePopEnabled,
    required this.gestureEdgeWidth,
    required super.settings,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool gesturePopEnabled;
  final double gestureEdgeWidth;

  @override
  bool get opaque => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final content = LmCupertinoSheetPageSurface(child: child);
    if (!gesturePopEnabled) {
      return content;
    }
    return LmHorizontalBackGestureDetector<T>(
      enabledCallback: () => _horizontalPopGestureEnabled,
      enabledListenable: animation,
      edgeWidth: gestureEdgeWidth,
      hitTestBehavior: HitTestBehavior.opaque,
      onStartPopGesture: () => LmHorizontalBackGestureController<T>(
        navigator: navigator!,
        controller: controller!,
        getIsActive: () => isActive,
        getIsCurrent: () => isCurrent,
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
    final transitionCurve = navigator?.userGestureInProgress ?? false
        ? Curves.linear
        : curve;
    final curved = CurvedAnimation(
      parent: animation,
      curve: transitionCurve,
      reverseCurve: transitionCurve.flipped,
    );
    return SlideTransition(
      position: curved.drive(
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero),
      ),
      child: child,
    );
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

/// Opaque adaptive surface for content rendered inside a Cupertino sheet page.
final class LmCupertinoSheetPageSurface extends StatelessWidget {
  const LmCupertinoSheetPageSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = CupertinoDynamicColor.resolve(
      CupertinoColors.systemBackground,
      context,
    );
    return ColoredBox(color: color, child: child);
  }
}
