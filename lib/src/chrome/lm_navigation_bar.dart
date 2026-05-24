import 'dart:async';

import 'package:flutter/material.dart';

import '../delegate/lm_navigation_controller.dart';
import '../router/lm_router_scope.dart';
import '../state/lm_route_node.dart';

typedef LmRouteTitleResolver = String Function(LmRouteNode node);

final class LmNavigationBar extends StatelessWidget {
  const LmNavigationBar({
    required this.controller,
    this.titleResolver = _defaultTitleResolver,
    this.duration = const Duration(milliseconds: 220),
    super.key,
  });

  final LmNavigationController controller;
  final LmRouteTitleResolver titleResolver;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final stack = controller
            .state
            .branches[controller.state.activeBranchId]
            ?.semanticStack;
        final current = stack == null || stack.isEmpty ? null : stack.last;
        final canPop =
            (stack?.length ?? 0) > 1 && current?.chrome.showBackButton != false;
        final title = current == null ? '' : titleResolver(current);

        return SafeArea(
          bottom: false,
          child: SizedBox(
            height: 44,
            child: canPop
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedSwitcher(
                          duration: duration,
                          child: IconButton(
                            key: const ValueKey('back'),
                            tooltip: 'Back',
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              semanticLabel: 'Back',
                            ),
                            onPressed: () {
                              final handle = LmRouterScope.maybeOf(context);
                              if (handle == null) {
                                controller.pop();
                                return;
                              }
                              unawaited(handle.pop());
                            },
                          ),
                        ),
                      ),
                      _AnimatedTitle(
                        title: title,
                        duration: duration,
                        alignment: Alignment.center,
                      ),
                    ],
                  )
                : _AnimatedTitle(
                    title: title,
                    duration: duration,
                    alignment: Alignment.centerLeft,
                  ),
          ),
        );
      },
    );
  }

  static String _defaultTitleResolver(LmRouteNode node) {
    final params = node.params;
    final chromeTitle = node.chrome.title;
    if (chromeTitle != null && chromeTitle.isNotEmpty) {
      return chromeTitle;
    }
    return params is String ? params : node.name;
  }
}

final class _AnimatedTitle extends StatelessWidget {
  const _AnimatedTitle({
    required this.title,
    required this.duration,
    required this.alignment,
  });

  final String title;
  final Duration duration;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: alignment == Alignment.centerLeft
            ? const EdgeInsetsDirectional.only(start: 16, end: 16)
            : EdgeInsets.zero,
        child: AnimatedSwitcher(
          duration: duration,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: animation.drive(
                  Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero),
                ),
                child: child,
              ),
            );
          },
          child: Text(
            title,
            key: ValueKey<String>(title),
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
