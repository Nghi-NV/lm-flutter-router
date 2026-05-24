import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lm_flutter_router/lm_flutter_router.dart';
import 'package:lm_flutter_router/lm_flutter_router_advanced.dart'
    show LmDefaultLayoutProjector, LmRouteStateCodec;

import 'domain.dart';
import 'screens.dart';
import 'web_smoke_bridge_stub.dart'
    if (dart.library.js_interop) 'web_smoke_bridge_web.dart';

final class FieldOrdersShell extends StatelessWidget {
  const FieldOrdersShell({
    required this.router,
    required this.repository,
    required this.session,
    required this.diagnostics,
    required this.child,
    super.key,
  });

  final LmRouter router;
  final OrdersRepository repository;
  final SessionStore session;
  final LmRouterDiagnostics diagnostics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    installWebSmokeBridge(context, router);
    return AnimatedBuilder(
      animation: Listenable.merge([router.controller, session]),
      builder: (context, _) {
        final path = router.controller.state.location.path;
        final modalOpen = router.controller.state.modalStack.isNotEmpty;
        if (path == '/login') {
          return Material(child: child);
        }
        return LmAdaptiveChromeScaffold(
          router: router,
          edgeBackGestureEnabled: true,
          edgeWidth: 192,
          bottomBarBuilder: (context, router) =>
              modalOpen ? null : _BottomTabs(router: router),
          sidebarBuilder: (context, router) =>
              _SideMenu(router: router, session: session),
          expandedContentBuilder: (context, child) => Stack(
            children: [
              _ContentWithAppBar(
                router: router,
                appBar: _AppBar.fromRouter(router: router, session: session),
                child: _TabletBody(
                  router: router,
                  repository: repository,
                  child: child,
                ),
              ),
              if (kDebugMode)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    onPressed: () => _openDebugPanel(context),
                    child: const Icon(Icons.bug_report_outlined),
                  ),
                ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  void _openDebugPanel(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoPopupSurface(
        isSurfacePainted: true,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.72,
              child: RouterDebugPanel(router: router, diagnostics: diagnostics),
            ),
          ),
        ),
      ),
    );
  }
}

final class FieldOrdersRouteChrome extends StatelessWidget {
  const FieldOrdersRouteChrome({
    required this.router,
    required this.session,
    required this.title,
    required this.canPop,
    required this.child,
    super.key,
  });

  final LmRouter router;
  final SessionStore session;
  final String title;
  final bool canPop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (_isExpandedViewport(context)) {
      return child;
    }
    return Column(
      children: [
        _AppBar(router: router, session: session, title: title, canPop: canPop),
        Expanded(child: child),
      ],
    );
  }
}

bool _isExpandedViewport(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= 840;
}

final class _ContentWithAppBar extends StatelessWidget {
  const _ContentWithAppBar({
    required this.router,
    required this.appBar,
    required this.child,
  });

  final LmRouter router;
  final Widget appBar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top + 56;
    final stack =
        router
            .controller
            .state
            .branches[router.controller.state.activeBranchId]
            ?.semanticStack ??
        const [];
    final canPop = stack.length > 1;
    final modalOpen = router.controller.state.modalStack.isNotEmpty;
    return Stack(
      children: [
        Positioned.fill(top: topInset, child: child),
        Positioned(left: 0, top: 0, right: 0, child: appBar),
        if (modalOpen)
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: topInset,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: router.pop,
              child: ColoredBox(
                color: CupertinoColors.black.withValues(alpha: 0.54),
              ),
            ),
          ),
        if (canPop && !modalOpen)
          Positioned(
            left: 0,
            top: 0,
            width: 20,
            height: topInset,
            child: _BackHitRegion(router: router),
          ),
      ],
    );
  }
}

final class _BackHitRegion extends StatelessWidget {
  const _BackHitRegion({required this.router});

  final LmRouter router;

  @override
  Widget build(BuildContext context) {
    var dragOffset = 0.0;
    final allowHeaderDrag =
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.fuchsia;
    return GestureDetector(
      key: const ValueKey('shell-back-hit-region'),
      behavior: HitTestBehavior.translucent,
      onTap: router.pop,
      onHorizontalDragStart: allowHeaderDrag
          ? (_) {
              dragOffset = 0;
            }
          : null,
      onHorizontalDragUpdate: allowHeaderDrag
          ? (details) {
              dragOffset += details.primaryDelta ?? 0;
            }
          : null,
      onHorizontalDragEnd: allowHeaderDrag
          ? (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (dragOffset >= 72 || velocity > 450) {
                router.controller.suppressNextSystemBack();
                unawaited(router.pop());
              }
            }
          : null,
      child: const SizedBox.expand(),
    );
  }
}

final class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.router,
    required this.session,
    required this.title,
    required this.canPop,
  });

  factory _AppBar.fromRouter({
    required LmRouter router,
    required SessionStore session,
  }) {
    final path = router.controller.state.location.path;
    final stack =
        router
            .controller
            .state
            .branches[router.controller.state.activeBranchId]
            ?.semanticStack ??
        const [];
    return _AppBar(
      router: router,
      session: session,
      title: _titleFor(path),
      canPop: stack.length > 1,
    );
  }

  final LmRouter router;
  final SessionStore session;
  final String title;
  final bool canPop;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              if (canPop)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: IconButton(
                    key: const ValueKey('back'),
                    tooltip: 'Back',
                    onPressed: router.pop,
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      semanticLabel: 'Back',
                    ),
                  ),
                )
              else
                const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: session.isSignedIn ? 'Signed in' : 'Signed out',
                onPressed: () => unawaited(router.go('/settings')),
                icon: Icon(
                  session.isSignedIn
                      ? Icons.verified_user_outlined
                      : Icons.person_off_outlined,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  static String _titleFor(String path) {
    if (path.startsWith('/orders/') && path.contains('/items/')) {
      return 'Line item';
    }
    if (path.startsWith('/orders/')) {
      return 'Order detail';
    }
    if (path.startsWith('/orders')) {
      return 'Orders';
    }
    if (path.startsWith('/lab')) {
      if (path.startsWith('/lab/heavy')) {
        return 'Heavy View';
      }
      return 'Router Lab';
    }
    if (path.startsWith('/settings')) {
      return 'Settings';
    }
    if (path.startsWith('/login')) {
      return 'Sign in';
    }
    return 'Field Orders';
  }
}

final class _BottomTabs extends StatelessWidget {
  const _BottomTabs({required this.router});

  final LmRouter router;

  @override
  Widget build(BuildContext context) {
    final path = router.controller.state.location.path;
    final index = path.startsWith('/orders')
        ? 1
        : path.startsWith('/lab')
        ? 2
        : path.startsWith('/settings')
        ? 3
        : 0;
    final colorScheme = Theme.of(context).colorScheme;
    return CupertinoTabBar(
      currentIndex: index,
      activeColor: colorScheme.primary,
      inactiveColor: colorScheme.onSurfaceVariant,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.96),
      border: Border(
        top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      onTap: (value) {
        final target = switch (value) {
          0 => '/',
          1 => '/orders',
          2 => '/lab',
          _ => '/settings',
        };
        unawaited(router.go(target));
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Today',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.science_outlined),
          label: 'Lab',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    );
  }
}

final class _SideMenu extends StatelessWidget {
  const _SideMenu({required this.router, required this.session});

  final LmRouter router;
  final SessionStore session;

  @override
  Widget build(BuildContext context) {
    final path = router.controller.state.location.path;
    return Material(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            ListTile(
              title: Text(
                'Field Orders',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(session.isSignedIn ? session.userName : 'Guest'),
            ),
            const SizedBox(height: 8),
            _tile('/', 'Today', Icons.dashboard_outlined, path == '/'),
            _tile(
              '/orders',
              'Orders',
              Icons.inventory_2_outlined,
              path.startsWith('/orders'),
            ),
            _tile(
              '/lab',
              'Router Lab',
              Icons.science_outlined,
              path.startsWith('/lab'),
            ),
            _tile(
              '/settings',
              'Settings',
              Icons.settings_outlined,
              path.startsWith('/settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String path, String label, IconData icon, bool selected) {
    return ListTile(
      selected: selected,
      leading: Icon(icon),
      title: Text(label),
      onTap: () => unawaited(router.go(_routeForPath(path))),
    );
  }

  String _routeForPath(String path) {
    return switch (path) {
      '/orders' => '/orders',
      '/lab' => '/lab',
      '/settings' => '/settings',
      _ => '/',
    };
  }
}

final class _TabletBody extends StatelessWidget {
  const _TabletBody({
    required this.router,
    required this.repository,
    required this.child,
  });

  final LmRouter router;
  final OrdersRepository repository;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = router.controller.state.location.path;
    if (!path.startsWith('/orders')) {
      return child;
    }
    return LmAdaptiveRouterSplitView(
      router: router,
      primaryPane: OrdersListPane(repository: repository),
      emptySecondary: const _OrdersEmptyPane(),
      child: child,
    );
  }
}

final class _OrdersEmptyPane extends StatelessWidget {
  const _OrdersEmptyPane();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 56,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

final class RouterDebugPanel extends StatelessWidget {
  const RouterDebugPanel({
    required this.router,
    required this.diagnostics,
    super.key,
  });

  final LmRouter router;
  final LmRouterDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final state = router.controller.state;
    final branch = state.branches[state.activeBranchId];
    final encoded = const LmRouteStateCodec().encode(state);
    final projection = const LmDefaultLayoutProjector().project(
      state,
      MediaQuery.sizeOf(context).width >= 840
          ? LmLayoutMode.expanded
          : LmLayoutMode.compact,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text('Router Debug', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _mono('location: ${state.location.canonical}'),
        _mono(
          'stack: ${branch?.semanticStack.map((node) => node.name).join(' > ') ?? ''}',
        ),
        _mono(
          'projection: ${projection.kind.name}\n'
          'primary: ${projection.primaryStack.map((e) => e.name).join(' > ')}\n'
          'secondary: ${projection.secondaryStack.map((e) => e.name).join(' > ')}',
        ),
        _mono('restoration: $encoded'),
        const SizedBox(height: 8),
        Text('Recent Events', style: Theme.of(context).textTheme.titleMedium),
        for (final event in diagnostics.events.reversed.take(8))
          ListTile(
            dense: true,
            title: Text(event.type.name),
            subtitle: Text('${event.source.name}: ${event.to.canonical}'),
          ),
      ],
    );
  }

  Widget _mono(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(text, style: const TextStyle(fontFamily: 'monospace')),
        ),
      ),
    );
  }
}
