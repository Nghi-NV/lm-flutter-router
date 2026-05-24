import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/lm_flutter_router_advanced.dart';

void main() {
  testWidgets('LmAdaptiveRouterSplitView renders projected secondary routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = LmRouter(
      initialLocation: '/orders/42',
      routes: [
        LmRouteDefinition<void>(
          name: 'orders',
          path: '/orders',
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Root orders page'),
        ),
        LmRouteDefinition<void>(
          name: 'orderDetail',
          path: '/orders/:orderId',
          detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
          transition: const LmTransition.cupertino(),
          build: (context, params) => const Text('Projected detail'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LmAdaptiveRouterSplitView(
          router: router,
          primaryPane: const Text('Stable list pane'),
          emptySecondary: const Text('No selection'),
          child: Router<LmLocation>(
            routerDelegate: router.delegate,
            routeInformationParser: router.parser,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stable list pane'), findsOneWidget);
    expect(find.text('Projected detail'), findsOneWidget);
    expect(find.text('Root orders page'), findsNothing);

    final context = tester.element(find.byType(LmAdaptiveRouterSplitView));
    final node = router
        .controller
        .state
        .branches[router.controller.state.activeBranchId]!
        .semanticStack
        .last;
    final projectedPage = router.delegate.buildProjectedPage(context, node);
    expect(
      projectedPage.createRoute(context),
      isA<LmCupertinoPageRoute<void>>(),
    );
  });

  testWidgets(
    'LmAdaptiveRouterSplitView keeps split mounted while modal is open',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = LmRouter(
        initialLocation: '/orders/42',
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
        modalRoutes: [
          LmModalRouteDefinition<void>(
            name: 'actions',
            path: '/orders/:orderId/actions',
            presentation: const LmModalPresentation.actionSheet(),
            build: (context, params) => const Text('Actions'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LmAdaptiveRouterSplitView(
            router: router,
            primaryPane: const Text('Stable list pane'),
            emptySecondary: const Text('No selection'),
            child: Router<LmLocation>(
              routerDelegate: router.delegate,
              routeInformationParser: router.parser,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await router.delegate.present('/orders/42/actions');
      await tester.pumpAndSettle();

      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Stable list pane'), findsOneWidget);
      expect(find.text('Order Detail'), findsWidgets);
    },
  );

  testWidgets('expanded split owns hero controllers for nested navigators', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = LmRouter(
      initialLocation: '/orders/42',
      routes: [
        LmRouteDefinition<void>(
          name: 'orders',
          path: '/orders',
          build: (context, params) => const Text('Orders'),
        ),
        LmRouteDefinition<void>(
          name: 'orderDetail',
          path: '/orders/:orderId',
          detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
          transition: const LmTransition.hero(),
          build: (context, params) =>
              const Hero(tag: 'order-42', child: Text('Order Hero')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LmAdaptiveRouterSplitView(
          router: router,
          primaryPane: const Hero(
            tag: 'order-42',
            child: Text('Stable list pane'),
          ),
          emptySecondary: const Text('No selection'),
          child: Router<LmLocation>(
            routerDelegate: router.delegate,
            routeInformationParser: router.parser,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final heroScopeElements = find
        .ancestor(
          of: find.text('Order Hero'),
          matching: find.byType(HeroControllerScope),
        )
        .evaluate()
        .toList();
    final nearestHeroScope =
        heroScopeElements.last.widget as HeroControllerScope;
    expect(nearestHeroScope.controller, isNotNull);
    expect(find.text('Order Hero'), findsOneWidget);
  });

  testWidgets('expanded split keeps primary pane out of secondary rebuilds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var primaryBuilds = 0;
    final router = LmRouter(
      initialLocation: '/orders/42',
      routes: [
        LmRouteDefinition<void>(
          name: 'orders',
          path: '/orders',
          build: (context, params) => const Text('Orders'),
        ),
        LmRouteDefinition<void>(
          name: 'orderDetail',
          path: '/orders/:orderId',
          detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Order detail'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LmAdaptiveRouterSplitView(
          router: router,
          primaryPane: _BuildCounter(
            onBuild: () {
              primaryBuilds += 1;
            },
            child: const Text('Stable list pane'),
          ),
          emptySecondary: const Text('No selection'),
          child: Router<LmLocation>(
            routerDelegate: router.delegate,
            routeInformationParser: router.parser,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(primaryBuilds, 1);

    await router.delegate.go('/orders/43');
    await tester.pumpAndSettle();

    expect(find.text('Stable list pane'), findsOneWidget);
    expect(primaryBuilds, 1);

    final primaryBoundary = find.ancestor(
      of: find.text('Stable list pane'),
      matching: find.byType(RepaintBoundary),
    );
    final secondaryBoundary = find.ancestor(
      of: find.text('Order detail'),
      matching: find.byType(RepaintBoundary),
    );
    expect(primaryBoundary, findsAtLeastNWidgets(1));
    expect(secondaryBoundary, findsAtLeastNWidgets(1));
  });

  testWidgets('expanded split animates first secondary push from empty pane', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = LmRouter(
      initialLocation: '/orders',
      routes: [
        LmRouteDefinition<void>(
          name: 'orders',
          path: '/orders',
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Orders'),
        ),
        LmRouteDefinition<void>(
          name: 'orderDetail',
          path: '/orders/:orderId',
          detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
          transition: const LmTransition.cupertino(),
          build: (context, params) => const Text('Order detail'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LmAdaptiveRouterSplitView(
          router: router,
          primaryPane: const Text('Stable list pane'),
          emptySecondary: const Text('No selection'),
          child: Router<LmLocation>(
            routerDelegate: router.delegate,
            routeInformationParser: router.parser,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No selection'), findsOneWidget);

    await router.delegate.go('/orders/42');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(find.text('No selection'), findsOneWidget);
    expect(find.text('Order detail'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Order detail'), findsOneWidget);

    await router.delegate.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(find.text('No selection'), findsOneWidget);
    expect(find.text('Order detail'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('No selection'), findsOneWidget);
    expect(find.text('Order detail'), findsNothing);
  });

  testWidgets('expanded split renders non-secondary routes above the split', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = LmRouter(
      initialLocation: '/orders/42/edit',
      routes: [
        LmRouteDefinition<void>(
          name: 'orders',
          path: '/orders',
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Orders'),
        ),
        LmRouteDefinition<void>(
          name: 'orderDetail',
          path: '/orders/:orderId',
          detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Order detail'),
        ),
        LmRouteDefinition<void>(
          name: 'orderEdit',
          path: '/orders/:orderId/edit',
          detailPolicy: LmDetailPolicy.pushOnCompact,
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Order edit'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LmAdaptiveRouterSplitView(
          router: router,
          primaryPane: const Text('Stable list pane'),
          emptySecondary: const Text('No selection'),
          child: Router<LmLocation>(
            routerDelegate: router.delegate,
            routeInformationParser: router.parser,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stable list pane'), findsOneWidget);
    expect(find.text('Order detail'), findsOneWidget);
    expect(find.text('Order edit'), findsOneWidget);
  });

  testWidgets('expanded split accepts a custom layout projector', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = LmRouter(
      initialLocation: '/orders/42',
      routes: [
        LmRouteDefinition<void>(
          name: 'orders',
          path: '/orders',
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Orders'),
        ),
        LmRouteDefinition<void>(
          name: 'orderDetail',
          path: '/orders/:orderId',
          detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Order detail'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LmAdaptiveRouterSplitView(
          router: router,
          projector: const _EmptySecondaryProjector(),
          primaryPane: const Text('Stable list pane'),
          emptySecondary: const Text('Custom empty'),
          child: Router<LmLocation>(
            routerDelegate: router.delegate,
            routeInformationParser: router.parser,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stable list pane'), findsOneWidget);
    expect(find.text('Custom empty'), findsOneWidget);
    expect(find.text('Order detail'), findsNothing);
  });

  testWidgets('replaceSecondary keeps only the latest secondary route', (
    tester,
  ) async {
    final state = LmNavigationState(
      activeBranchId: 'orders',
      location: LmLocation(path: '/orders/42/items/9'),
      branches: {
        'orders': LmBranchState(
          branchId: 'orders',
          semanticStack: [
            LmRouteNode(
              name: 'orders',
              pathPattern: '/orders',
              location: LmLocation(path: '/orders'),
              params: null,
              query: const {},
            ),
            LmRouteNode(
              name: 'orderDetail',
              pathPattern: '/orders/:orderId',
              location: LmLocation(path: '/orders/42'),
              params: null,
              query: const {},
              detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
            ),
            LmRouteNode(
              name: 'itemDetail',
              pathPattern: '/orders/:orderId/items/:itemId',
              location: LmLocation(path: '/orders/42/items/9'),
              params: null,
              query: const {},
              detailPolicy: LmDetailPolicy.replaceSecondary,
            ),
          ],
        ),
      },
    );

    final tree = const LmDefaultLayoutProjector().project(
      state,
      LmLayoutMode.expanded,
    );

    expect(tree.secondaryStack.map((node) => node.name), ['itemDetail']);
  });
}

final class _EmptySecondaryProjector implements LmLayoutProjector {
  const _EmptySecondaryProjector();

  @override
  LmRenderedTree project(LmNavigationState state, LmLayoutMode layoutMode) {
    return LmRenderedTree(
      kind: LmRenderedTreeKind.expandedSplit,
      activeBranchId: state.activeBranchId,
      primaryStack: state.branches[state.activeBranchId]?.semanticStack ?? [],
    );
  }
}

final class _BuildCounter extends StatelessWidget {
  const _BuildCounter({required this.onBuild, required this.child});

  final VoidCallback onBuild;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return child;
  }
}
