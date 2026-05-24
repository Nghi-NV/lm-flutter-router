import 'dart:async';

import 'package:flutter/widgets.dart';

import '../router/lm_router.dart';
import '../state/lm_route_node.dart';
import 'lm_adaptive_policy.dart';
import 'lm_layout_projector.dart';

final class LmAdaptiveRouterSplitView extends StatelessWidget {
  const LmAdaptiveRouterSplitView({
    required this.router,
    required this.primaryPane,
    required this.child,
    this.emptySecondary,
    this.primaryWidth = 360,
    this.divider = const SizedBox(width: 1),
    this.policy = const LmBreakpointPolicy(),
    this.projector = const LmDefaultLayoutProjector(),
    super.key,
  });

  final LmRouter router;
  final Widget primaryPane;
  final Widget child;
  final Widget? emptySecondary;
  final double primaryWidth;
  final Widget divider;
  final LmAdaptiveRoutingPolicy policy;
  final LmLayoutProjector projector;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: router.controller,
      child: primaryPane,
      builder: (context, primaryPaneChild) {
        final modalOpen = router.controller.state.modalStack.isNotEmpty;
        final mode = policy.resolve(MediaQuery.sizeOf(context).width);
        final tree = projector.project(router.controller.state, mode);
        if (tree.kind != LmRenderedTreeKind.expandedSplit) {
          return child;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Row(
              children: [
                SizedBox(
                  width: primaryWidth,
                  child: RepaintBoundary(child: primaryPaneChild),
                ),
                divider,
                Expanded(
                  child: RepaintBoundary(
                    child: _SecondaryPaneNavigator(
                      router: router,
                      stack: tree.secondaryStack,
                      empty: emptySecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (tree.overlayStack.isNotEmpty)
              _OverlayStackNavigator(router: router, stack: tree.overlayStack),
            if (tree.modalStack.isNotEmpty)
              _OverlayStackNavigator(router: router, stack: tree.modalStack),
            if (modalOpen) _ModalOverlayNavigator(router: router),
          ],
        );
      },
    );
  }
}

final class _OverlayStackNavigator extends StatefulWidget {
  const _OverlayStackNavigator({required this.router, required this.stack});

  final LmRouter router;
  final List<LmRouteNode> stack;

  @override
  State<_OverlayStackNavigator> createState() => _OverlayStackNavigatorState();
}

final class _OverlayStackNavigatorState extends State<_OverlayStackNavigator> {
  late final HeroController _heroController = HeroController();

  @override
  Widget build(BuildContext context) {
    return HeroControllerScope(
      controller: _heroController,
      child: Navigator(
        pages: [
          const _OverlayBasePage(),
          for (final node in widget.stack)
            widget.router.delegate.buildProjectedPage(context, node),
        ],
        onDidRemovePage: (page) {
          final pageBelongsToOverlay = widget.stack.any(
            (node) => node.location.canonical == page.name,
          );
          if (pageBelongsToOverlay) {
            unawaited(widget.router.pop());
          }
        },
      ),
    );
  }
}

final class _OverlayBasePage extends Page<void> {
  const _OverlayBasePage()
    : super(key: const ValueKey<String>('lm-overlay-base'));

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
    );
  }
}

final class _ModalOverlayNavigator extends StatefulWidget {
  const _ModalOverlayNavigator({required this.router});

  final LmRouter router;

  @override
  State<_ModalOverlayNavigator> createState() => _ModalOverlayNavigatorState();
}

final class _ModalOverlayNavigatorState extends State<_ModalOverlayNavigator> {
  late final HeroController _heroController = HeroController();

  @override
  Widget build(BuildContext context) {
    return HeroControllerScope(
      controller: _heroController,
      child: Navigator(
        pages: [
          const _ModalOverlayBasePage(),
          for (final node in widget.router.controller.state.modalStack)
            widget.router.delegate.buildProjectedModalPage(context, node),
        ],
        onDidRemovePage: (page) {
          final pageBelongsToModal = widget.router.controller.state.modalStack
              .any((node) => node.location.canonical == page.name);
          if (pageBelongsToModal) {
            unawaited(widget.router.pop());
          }
        },
      ),
    );
  }
}

final class _ModalOverlayBasePage extends Page<void> {
  const _ModalOverlayBasePage()
    : super(key: const ValueKey<String>('lm-modal-overlay-base'));

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
    );
  }
}

final class _SecondaryPaneNavigator extends StatefulWidget {
  const _SecondaryPaneNavigator({
    required this.router,
    required this.stack,
    required this.empty,
  });

  final LmRouter router;
  final List<LmRouteNode> stack;
  final Widget? empty;

  @override
  State<_SecondaryPaneNavigator> createState() =>
      _SecondaryPaneNavigatorState();
}

final class _SecondaryPaneNavigatorState
    extends State<_SecondaryPaneNavigator> {
  late final HeroController _heroController = HeroController();

  @override
  Widget build(BuildContext context) {
    return HeroControllerScope(
      controller: _heroController,
      child: Navigator(
        key: ValueKey<String>(
          'lm-secondary-${widget.router.controller.state.activeBranchId}',
        ),
        pages: [
          _SecondaryPaneBasePage(
            child: widget.empty ?? const SizedBox.shrink(),
          ),
          for (final node in widget.stack)
            widget.router.delegate.buildProjectedPage(context, node),
        ],
        onDidRemovePage: (page) {
          final pageBelongsToSecondary = widget.stack.any(
            (node) => node.location.canonical == page.name,
          );
          if (pageBelongsToSecondary) {
            unawaited(widget.router.pop());
          }
        },
      ),
    );
  }
}

final class _SecondaryPaneBasePage extends Page<void> {
  const _SecondaryPaneBasePage({required this.child})
    : super(key: const ValueKey<String>('lm-secondary-base'));

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
    );
  }
}
