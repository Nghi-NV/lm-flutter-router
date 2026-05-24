import 'package:flutter/widgets.dart';

import '../core/lm_location.dart';
import 'lm_router.dart';

/// Context-bound navigation helper exposed by [LmRouterScope].
///
/// The handle updates router state and reports route information so browser
/// history stays in sync on web:
///
/// ```dart
/// FilledButton(
///   onPressed: () => context.lm.push(OrderRoute(42)),
///   child: const Text('Open order'),
/// );
/// ```
///
/// Use [present] for router-owned modal locations and [pop] for both modal and
/// page-stack back behavior.
final class LmRouterHandle {
  const LmRouterHandle(this.router, [this._context]);

  final LmRouter router;
  final BuildContext? _context;

  Future<void> go(Object location) {
    return _navigate(() => router.go(location));
  }

  Future<void> goPath(String path) => go(path);

  Future<void> push(Object location) {
    return _navigate(() => router.push(location));
  }

  Future<void> pushPath(String path) => push(path);

  Future<void> replace(Object location) {
    return _navigate(() => router.replace(location));
  }

  Future<void> replacePath(String path) => replace(path);

  Future<void> present(Object location) {
    return _navigate(() => router.present(location));
  }

  Future<void> presentPath(String path) => present(path);

  Future<bool> pop() {
    return _navigate(router.pop);
  }

  Future<bool> maybePop() => pop();

  LmLocation get location => router.location;

  bool get canPop => router.controller.canPop;

  Future<void> switchBranch(String branchId) {
    return _navigate(() => router.switchBranch(branchId));
  }

  Future<void> goRoot(Object location) => go(location);

  Future<T> _navigate<T>(Future<T> Function() action) {
    final scopedContext = _context;
    final context = scopedContext != null && scopedContext.mounted
        ? scopedContext
        : router.delegate.navigatorKey.currentContext;
    if (context == null || Router.maybeOf<Object?>(context) == null) {
      return action();
    }
    late final Future<T> result;
    Router.navigate(context, () {
      result = action();
    });
    return result;
  }
}

/// Provides an [LmRouter] to descendants as an ergonomic `context.lm` handle.
///
/// Place the scope inside the `Router` tree so navigation actions can use
/// `Router.navigate` when available:
///
/// ```dart
/// MaterialApp.router(
///   routerConfig: router.config,
///   builder: (context, child) {
///     return LmRouterScope(router: router, child: child!);
///   },
/// );
/// ```
final class LmRouterScope extends InheritedWidget {
  LmRouterScope({required LmRouter router, required super.child, super.key})
    : handle = LmRouterHandle(router);

  final LmRouterHandle handle;

  static LmRouterHandle of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LmRouterScope>();
    if (scope == null) {
      throw StateError(
        'LmRouterScope was not found above this BuildContext. '
        'Wrap the subtree with LmRouterScope(router: router, child: ...).',
      );
    }
    return LmRouterHandle(scope.handle.router, context);
  }

  static LmRouterHandle? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LmRouterScope>();
    if (scope == null) {
      return null;
    }
    return LmRouterHandle(scope.handle.router, context);
  }

  @override
  bool updateShouldNotify(covariant LmRouterScope oldWidget) {
    return handle.router != oldWidget.handle.router;
  }
}

extension LmRouterBuildContext on BuildContext {
  LmRouterHandle get lm => LmRouterScope.of(this);

  LmRouterHandle? get maybeLm => LmRouterScope.maybeOf(this);
}

extension LmRouterScopedBuilder on LmRouter {
  TransitionBuilder scopeBuilder({
    LmRouterChildBuilder? builder,
    bool autoDispose = true,
  }) {
    return _scopedBuilder(builder, autoDispose: autoDispose);
  }

  TransitionBuilder scopedBuilder([LmRouterChildBuilder? builder]) {
    return _scopedBuilder(builder, autoDispose: true);
  }

  TransitionBuilder unownedScopedBuilder([LmRouterChildBuilder? builder]) {
    return _scopedBuilder(builder, autoDispose: false);
  }

  TransitionBuilder _scopedBuilder(
    LmRouterChildBuilder? builder, {
    required bool autoDispose,
  }) {
    return (context, child) {
      final resolvedChild = child ?? const SizedBox.shrink();
      final scoped = LmRouterScope(
        router: this,
        child: builder == null
            ? resolvedChild
            : builder(context, resolvedChild),
      );
      if (!autoDispose) {
        return scoped;
      }
      return _LmRouterLifecycleScope(router: this, child: scoped);
    };
  }
}

final class _LmRouterLifecycleScope extends StatefulWidget {
  const _LmRouterLifecycleScope({required this.router, required this.child});

  final LmRouter router;
  final Widget child;

  @override
  State<_LmRouterLifecycleScope> createState() =>
      _LmRouterLifecycleScopeState();
}

final class _LmRouterLifecycleScopeState
    extends State<_LmRouterLifecycleScope> {
  @override
  void didUpdateWidget(covariant _LmRouterLifecycleScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.dispose();
    }
  }

  @override
  void dispose() {
    widget.router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
