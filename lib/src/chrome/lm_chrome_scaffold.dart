import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../delegate/lm_navigation_controller.dart';
import '../router/lm_router_scope.dart';
import 'lm_route_chrome.dart';

final class LmChromeScaffold extends StatelessWidget {
  const LmChromeScaffold({
    required this.controller,
    required this.body,
    this.bottomNavigationBar,
    this.duration = const Duration(milliseconds: 220),
    this.edgeBackGestureEnabled = false,
    this.edgeStartInset = 0,
    this.edgeWidth = 20,
    this.edgeTopInset = 0,
    this.popDistance = 72,
    this.edgeBackGesturePlatforms,
    this.hideBottomBarWhenModalOpen = true,
    super.key,
  });

  final LmNavigationController controller;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Duration duration;
  final bool edgeBackGestureEnabled;
  final double edgeStartInset;
  final double edgeWidth;
  final double edgeTopInset;
  final double popDistance;
  final Set<TargetPlatform>? edgeBackGesturePlatforms;
  final bool hideBottomBarWhenModalOpen;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final tabbar = bottomNavigationBar;
        final showTabBar = _shouldShowTabBar();
        final scaffoldBody = edgeBackGestureEnabled && _usesAppEdgeBackGesture()
            ? _EdgeBackGesture(
                controller: controller,
                edgeStartInset: edgeStartInset,
                edgeWidth: edgeWidth,
                edgeTopInset: edgeTopInset,
                popDistance: popDistance,
                child: body,
              )
            : body;
        return Scaffold(
          body: scaffoldBody,
          bottomNavigationBar: tabbar == null || !showTabBar
              ? null
              : _AnimatedTabBarVisibility(duration: duration, child: tabbar),
        );
      },
    );
  }

  bool _shouldShowTabBar() {
    if (hideBottomBarWhenModalOpen && controller.state.modalStack.isNotEmpty) {
      return false;
    }
    final branch = controller.state.branches[controller.state.activeBranchId];
    if (branch == null) {
      return true;
    }
    final current = branch.semanticStack.isEmpty
        ? null
        : branch.semanticStack.last;
    return switch (current?.chrome.tabBarVisibility ??
        LmTabBarVisibility.inherited) {
      LmTabBarVisibility.always => true,
      LmTabBarVisibility.rootOnly => branch.semanticStack.length <= 1,
      LmTabBarVisibility.hidden => false,
      LmTabBarVisibility.inherited => branch.semanticStack.length <= 1,
    };
  }

  bool _usesAppEdgeBackGesture() {
    final platforms =
        edgeBackGesturePlatforms ??
        const {
          TargetPlatform.macOS,
          TargetPlatform.linux,
          TargetPlatform.windows,
        };
    return platforms.contains(defaultTargetPlatform);
  }
}

final class _EdgeBackGesture extends StatefulWidget {
  const _EdgeBackGesture({
    required this.controller,
    required this.edgeStartInset,
    required this.edgeWidth,
    required this.edgeTopInset,
    required this.popDistance,
    required this.child,
  });

  final LmNavigationController controller;
  final double edgeStartInset;
  final double edgeWidth;
  final double edgeTopInset;
  final double popDistance;
  final Widget child;

  @override
  State<_EdgeBackGesture> createState() => _EdgeBackGestureState();
}

final class _EdgeBackGestureState extends State<_EdgeBackGesture> {
  double _dragOffset = 0;
  bool _tracking = false;

  @override
  Widget build(BuildContext context) {
    final gestureWidth = (widget.edgeWidth - widget.edgeStartInset)
        .clamp(0.0, double.infinity)
        .toDouble();
    final visualOffset = _tracking
        ? _dragOffset.clamp(0.0, widget.popDistance).toDouble()
        : 0.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.translate(
          offset: Offset(visualOffset, 0),
          child: widget.child,
        ),
        if (_canPop() && gestureWidth > 0)
          Positioned(
            left: widget.edgeStartInset,
            top: widget.edgeTopInset,
            bottom: 0,
            width: gestureWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) {
                _tracking = true;
                _dragOffset = 0;
              },
              onHorizontalDragUpdate: (details) {
                if (!_tracking) {
                  return;
                }
                setState(() {
                  _dragOffset += details.primaryDelta ?? 0;
                });
              },
              onHorizontalDragEnd: (details) {
                if (!_tracking) {
                  return;
                }
                final velocity = details.primaryVelocity ?? 0;
                final shouldPop =
                    _dragOffset >= widget.popDistance || velocity > 450;
                setState(() {
                  _tracking = false;
                  _dragOffset = 0;
                });
                if (shouldPop) {
                  _pop();
                }
              },
              onHorizontalDragCancel: () {
                setState(() {
                  _tracking = false;
                  _dragOffset = 0;
                });
              },
            ),
          ),
      ],
    );
  }

  void _pop() {
    widget.controller.suppressNextSystemBack();
    final handle = LmRouterScope.maybeOf(context);
    if (handle == null) {
      widget.controller.pop();
      return;
    }
    unawaited(handle.pop());
  }

  bool _canPop() {
    final branch = widget
        .controller
        .state
        .branches[widget.controller.state.activeBranchId];
    return (branch?.semanticStack.length ?? 0) > 1;
  }
}

final class _AnimatedTabBarVisibility extends StatelessWidget {
  const _AnimatedTabBarVisibility({
    required this.duration,
    required this.child,
  });

  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
    );
  }
}
