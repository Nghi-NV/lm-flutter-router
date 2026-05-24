import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/src/adaptive/lm_branch.dart';
import 'package:lm_flutter_router/src/core/lm.dart';
import 'package:lm_flutter_router/src/core/lm_location.dart';
import 'package:lm_flutter_router/src/core/lm_route_definition.dart';
import 'package:lm_flutter_router/src/core/lm_route_location.dart';
import 'package:lm_flutter_router/src/guards/lm_guard.dart';
import 'package:lm_flutter_router/src/modal/lm_modal_presentation.dart';
import 'package:lm_flutter_router/src/modal/lm_modal_route_definition.dart';
import 'package:lm_flutter_router/src/router/lm_route_information_parser.dart';
import 'package:lm_flutter_router/src/router/lm_router.dart';
import 'package:lm_flutter_router/src/router/lm_router_scope.dart';
import 'package:lm_flutter_router/src/transitions/lm_transition.dart';

void main() {
  group('LmRouteInformationParser', () {
    test('parses and restores canonical locations', () async {
      const parser = LmRouteInformationParser();

      final location = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse('/orders/42?tab=items#section')),
      );

      expect(location.path, '/orders/42');
      expect(location.query, {'tab': 'items'});
      expect(location.fragment, 'section');

      final restored = parser.restoreRouteInformation(location);
      expect(restored!.uri.toString(), '/orders/42?tab=items#section');
    });

    test('normalizes incoming links before route matching', () async {
      final parser = LmRouteInformationParser(
        linkNormalizer: (uri) {
          if (uri.host == 'orders.example.com') {
            return LmLocation(path: '/orders/${uri.pathSegments.single}');
          }
          return LmLocation.fromUri(uri);
        },
      );

      final location = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse('https://orders.example.com/42')),
      );

      expect(location.path, '/orders/42');
    });
  });

  group('LmRouter custom engine', () {
    testWidgets('renders initial route and responds to route information', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/',
        routes: [
          LmRouteDefinition<void>(
            name: 'home',
            path: '/',
            build: (context, params) => const Text('Home'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeData(platform: TargetPlatform.iOS),
          routerConfig: router.config,
        ),
      );

      expect(find.text('Home'), findsOneWidget);

      await router.delegate.setNewRoutePath(
        router.parser.parseUri(Uri.parse('/orders/42')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order Detail'), findsOneWidget);
      expect(router.controller.state.location.path, '/orders/42');
    });

    testWidgets('decodes typed params before building matched pages', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/orders/7',
        routes: [
          LmRouteDefinition<int>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            decode: (params) => int.parse(params['orderId']!),
            build: (context, params) => Text('Order $params'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeData(platform: TargetPlatform.iOS),
          routerConfig: router.config,
        ),
      );

      expect(find.text('Order 7'), findsOneWidget);
    });

    testWidgets('renders notFoundRoute for unmatched deep links', (
      tester,
    ) async {
      late final LmRouter router;
      router = LmRouter(
        initialLocation: '/missing/path',
        notFoundRoute: LmRouteDefinition<void>(
          name: 'notFound',
          path: '/404',
          build: (context, params) =>
              Text('Missing ${router.controller.state.location.path}'),
        ),
        routes: [
          LmRouteDefinition<void>(
            name: 'home',
            path: '/',
            build: (context, params) => const Text('Home'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      expect(_activeRouteNames(router), ['notFound']);
      expect(router.controller.state.location.path, '/missing/path');
      expect(find.text('Missing /missing/path'), findsOneWidget);
    });

    testWidgets('renders notFoundRoute when typed param decoding fails', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/orders/not-an-int',
        notFoundRoute: LmRouteDefinition<void>(
          name: 'notFound',
          path: '/404',
          build: (context, params) => const Text('Bad link'),
        ),
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<int>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            decode: (params) => int.parse(params['orderId']!),
            build: (context, params) => Text('Order $params'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      expect(_activeRouteNames(router).last, 'notFound');
      expect(router.controller.state.location.path, '/orders/not-an-int');
      expect(find.text('Bad link'), findsOneWidget);
      expect(find.text('Order not-an-int'), findsNothing);
    });

    testWidgets(
      'renders notFoundRoute for unknown children under a valid prefix',
      (tester) async {
        final router = LmRouter(
          initialLocation: '/orders/unknown/child',
          notFoundRoute: LmRouteDefinition<void>(
            name: 'notFound',
            path: '/404',
            build: (context, params) => const Text('Missing child'),
          ),
          routes: [
            LmRouteDefinition<void>(
              name: 'orders',
              path: '/orders',
              build: (context, params) => const Text('Orders'),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router.config),
        );

        expect(_activeRouteNames(router), ['notFound']);
        expect(router.controller.state.location.path, '/orders/unknown/child');
        expect(find.text('Missing child'), findsOneWidget);
        expect(find.text('Orders'), findsNothing);
      },
    );

    testWidgets('deep links build a semantic stack that can pop', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/',
        routes: [
          LmRouteDefinition<void>(
            name: 'home',
            path: '/',
            build: (context, params) => const Text('Home'),
          ),
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<int>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            decode: (params) => int.parse(params['orderId']!),
            build: (context, params) => Text('Order $params'),
          ),
          LmRouteDefinition<String>(
            name: 'orderItem',
            path: '/orders/:orderId/items/:itemId',
            decode: (params) => '${params['orderId']}/${params['itemId']}',
            build: (context, params) => Text('Item $params'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      await router.delegate.setNewRoutePath(
        router.parser.parseUri(Uri.parse('/orders/42/items/9')),
      );
      await tester.pumpAndSettle();

      final branch = router
          .controller
          .state
          .branches[router.controller.state.activeBranchId]!;
      expect(branch.semanticStack.map((node) => node.name), [
        'orders',
        'orderDetail',
        'orderItem',
      ]);
      expect(find.text('Item 42/9'), findsOneWidget);

      expect(router.controller.pop(), isTrue);
      await tester.pumpAndSettle();

      expect(router.controller.state.location.path, '/orders/42');
      expect(find.text('Order 42'), findsOneWidget);
    });

    testWidgets('nested child route deep links keep intermediate pages', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/',
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
            children: [
              LmRouteDefinition<int>(
                name: 'orderDetail',
                path: ':orderId',
                decode: (params) => int.parse(params['orderId']!),
                build: (context, params) => Text('Order $params'),
                children: [
                  LmRouteDefinition<String>(
                    name: 'orderItem',
                    path: 'items/:itemId',
                    decode: (params) =>
                        '${params['orderId']}/${params['itemId']}',
                    build: (context, params) => Text('Item $params'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      await router.delegate.setNewRoutePath(
        router.parser.parseUri(Uri.parse('/orders/42/items/9')),
      );
      await tester.pumpAndSettle();

      expect(_activeRouteNames(router), ['orders', 'orderDetail', 'orderItem']);
      expect(
        router
            .controller
            .state
            .branches[router.controller.state.activeBranchId]!
            .semanticStack
            .map((node) => node.location.path),
        ['/orders', '/orders/42', '/orders/42/items/9'],
      );
      expect(find.text('Item 42/9'), findsOneWidget);

      expect(router.controller.pop(), isTrue);
      await tester.pumpAndSettle();

      expect(router.controller.state.location.path, '/orders/42');
      expect(find.text('Order 42'), findsOneWidget);
    });

    testWidgets('programmatic go, push, replace, and pop honor stack intent', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/',
        routes: [
          LmRouteDefinition<void>(
            name: 'home',
            path: '/',
            build: (context, params) => const Text('Home'),
          ),
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
          LmRouteDefinition<void>(
            name: 'orderItem',
            path: '/orders/:orderId/items/:itemId',
            build: (context, params) => const Text('Order Item'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      await router.delegate.go('/orders');
      await tester.pumpAndSettle();
      expect(_activeRouteNames(router), ['orders']);

      await router.delegate.push('/orders/42');
      await tester.pumpAndSettle();
      expect(_activeRouteNames(router), ['orders', 'orderDetail']);

      await router.delegate.push('/orders/42');
      await tester.pumpAndSettle();
      expect(_activeRouteNames(router), ['orders', 'orderDetail']);

      await router.delegate.replace('/orders/42/items/9');
      await tester.pumpAndSettle();
      expect(_activeRouteNames(router), ['orders', 'orderItem']);

      expect(await router.delegate.pop(), isTrue);
      await tester.pumpAndSettle();
      expect(_activeRouteNames(router), ['orders']);
    });

    testWidgets('programmatic navigation reports browser route information', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/',
        routes: [
          LmRouteDefinition<void>(
            name: 'home',
            path: '/',
            transition: const LmTransition.none(),
            build: (context, params) => const Text('Home'),
          ),
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            transition: const LmTransition.none(),
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            transition: const LmTransition.none(),
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
        modalRoutes: [
          LmModalRouteDefinition<void>(
            name: 'orderActions',
            path: '/orders/:orderId/actions',
            presentation: const LmModalPresentation.actionSheet(
              transition: LmTransition.none(),
            ),
            build: (context, params) => const Text('Actions'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));
      await tester.pumpAndSettle();

      await router.delegate.push('/orders/42');
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/orders/42',
      );

      await router.delegate.present('/orders/42/actions');
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/orders/42/actions',
      );

      await router.delegate.pop();
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/orders/42',
      );

      await router.delegate.go('/orders');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.toString(), '/orders');
    });

    testWidgets('serializes rapid push push pop across route transitions', (
      tester,
    ) async {
      const transition = LmTransition.cupertino(
        duration: Duration(milliseconds: 100),
      );
      final router = LmRouter(
        initialLocation: '/orders',
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            transition: transition,
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            transition: transition,
            build: (context, params) => const Text('Order Detail'),
          ),
          LmRouteDefinition<void>(
            name: 'orderItem',
            path: '/orders/:orderId/items/:itemId',
            transition: transition,
            build: (context, params) => const Text('Order Item'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      unawaited(router.delegate.push('/orders/42'));
      unawaited(router.delegate.push('/orders/42/items/9'));
      final popFuture = router.delegate.pop();

      await tester.pump();
      expect(_activeRouteNames(router), ['orders', 'orderDetail']);

      await tester.pump(const Duration(milliseconds: 140));
      await tester.pump();
      expect(_activeRouteNames(router), ['orders', 'orderDetail', 'orderItem']);

      await tester.pump(const Duration(milliseconds: 140));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pump();
      expect(await popFuture, isTrue);
      await tester.pumpAndSettle();

      expect(_activeRouteNames(router), ['orders', 'orderDetail']);
      expect(router.controller.state.location.path, '/orders/42');
    });

    testWidgets('coalesces repeated pop requests while transition is pending', (
      tester,
    ) async {
      const transition = LmTransition.cupertino(
        duration: Duration(milliseconds: 100),
      );
      final router = LmRouter(
        initialLocation: '/orders',
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            transition: transition,
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            transition: transition,
            build: (context, params) => const Text('Order Detail'),
          ),
          LmRouteDefinition<void>(
            name: 'orderItem',
            path: '/orders/:orderId/items/:itemId',
            transition: transition,
            build: (context, params) => const Text('Order Item'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      unawaited(router.delegate.push('/orders/42'));
      unawaited(router.delegate.push('/orders/42/items/9'));
      final firstPop = router.delegate.popRoute();
      final secondPop = router.delegate.popRoute();

      expect(identical(firstPop, secondPop), isTrue);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pump();

      expect(await firstPop, isTrue);
      await tester.pumpAndSettle();

      expect(_activeRouteNames(router), ['orders', 'orderDetail']);
    });

    testWidgets(
      'programmatic navigation accepts typed route location objects',
      (tester) async {
        final router = LmRouter(
          initialLocation: '/',
          routes: [
            LmRouteDefinition<void>(
              name: 'home',
              path: '/',
              build: (context, params) => const Text('Home'),
            ),
            LmRouteDefinition<void>(
              name: 'orders',
              path: '/orders',
              build: (context, params) => const Text('Orders'),
            ),
            LmRouteDefinition<int>(
              name: 'orderDetail',
              path: '/orders/:orderId',
              decode: (params) => int.parse(params['orderId']!),
              build: (context, params) => Text('Order $params'),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router.config),
        );

        await router.delegate.go(const _OrdersRoute());
        await tester.pumpAndSettle();
        expect(_activeRouteNames(router), ['orders']);

        await router.delegate.push(const _OrderDetailRoute(42));
        await tester.pumpAndSettle();
        expect(_activeRouteNames(router), ['orders', 'orderDetail']);
        expect(find.text('Order 42'), findsOneWidget);
      },
    );

    testWidgets('router-owned modals accept typed route location objects', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/orders/42',
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<int>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            decode: (params) => int.parse(params['orderId']!),
            build: (context, params) => Text('Order $params'),
          ),
        ],
        modalRoutes: [
          LmModalRouteDefinition<int>(
            name: 'actions',
            path: '/orders/:orderId/actions',
            presentation: const LmModalPresentation.actionSheet(),
            decode: (params) => int.parse(params['orderId']!),
            build: (context, params) => Text('Actions $params'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      await router.delegate.present(const _OrderActionsRoute(42));
      await tester.pumpAndSettle();

      expect(router.delegate.currentConfiguration?.path, '/orders/42/actions');
      expect(find.text('Actions 42'), findsOneWidget);
    });

    testWidgets('Navigator back removes one semantic page', (tester) async {
      final router = LmRouter(
        initialLocation: '/orders/42/items/9',
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
          LmRouteDefinition<void>(
            name: 'orderItem',
            path: '/orders/:orderId/items/:itemId',
            build: (context, params) => const Text('Order Item'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));
      expect(_activeRouteNames(router), ['orders', 'orderDetail', 'orderItem']);

      router.delegate.navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(_activeRouteNames(router), ['orders', 'orderDetail']);
      expect(router.controller.state.location.path, '/orders/42');
    });

    testWidgets('RouterDelegate popRoute goes through Navigator once', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/orders/42/items/9',
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
          LmRouteDefinition<void>(
            name: 'orderItem',
            path: '/orders/:orderId/items/:itemId',
            build: (context, params) => const Text('Order Item'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      expect(await router.delegate.popRoute(), isTrue);
      await tester.pumpAndSettle();

      expect(_activeRouteNames(router), ['orders', 'orderDetail']);
      expect(router.controller.state.location.path, '/orders/42');
    });

    testWidgets('pop guards can block leaving the current route', (
      tester,
    ) async {
      var allowPop = false;
      final router = LmRouter(
        initialLocation: '/orders/42/edit',
        guards: [
          Lm.popGuard((context) {
            if (context.transaction.from?.path == '/orders/42/edit' &&
                !allowPop) {
              return const LmGuardBlock('unsaved changes');
            }
            return const LmGuardAllow();
          }),
        ],
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
          LmRouteDefinition<void>(
            name: 'orderEdit',
            path: '/orders/:orderId/edit',
            build: (context, params) => const Text('Order Edit'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      expect(await router.delegate.pop(), isFalse);
      await tester.pumpAndSettle();
      expect(router.controller.state.location.path, '/orders/42/edit');
      expect(find.text('Order Edit'), findsOneWidget);

      allowPop = true;
      expect(await router.delegate.pop(), isTrue);
      await tester.pumpAndSettle();
      expect(router.controller.state.location.path, '/orders/42');
      expect(find.text('Order Detail'), findsOneWidget);
    });

    testWidgets(
      'RouterDelegate consumes suppressed system back after gesture',
      (tester) async {
        final router = LmRouter(
          initialLocation: '/orders/42/items/9',
          routes: [
            LmRouteDefinition<void>(
              name: 'orders',
              path: '/orders',
              build: (context, params) => const Text('Orders'),
            ),
            LmRouteDefinition<void>(
              name: 'orderDetail',
              path: '/orders/:orderId',
              build: (context, params) => const Text('Order Detail'),
            ),
            LmRouteDefinition<void>(
              name: 'orderItem',
              path: '/orders/:orderId/items/:itemId',
              build: (context, params) => const Text('Order Item'),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router.config),
        );

        router.controller.suppressNextSystemBack();

        expect(await router.delegate.popRoute(), isTrue);
        await tester.pumpAndSettle();

        expect(_activeRouteNames(router), [
          'orders',
          'orderDetail',
          'orderItem',
        ]);
        expect(router.controller.state.location.path, '/orders/42/items/9');

        expect(await router.delegate.popRoute(), isTrue);
        await tester.pumpAndSettle();

        expect(_activeRouteNames(router), ['orders', 'orderDetail']);
        expect(router.controller.state.location.path, '/orders/42');
      },
    );

    testWidgets('RouterDelegate consumes system back during push transition', (
      tester,
    ) async {
      const transition = LmTransition.cupertino(
        duration: Duration(milliseconds: 100),
      );
      final router = LmRouter(
        initialLocation: '/orders',
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            transition: transition,
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            transition: transition,
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      unawaited(router.delegate.push('/orders/42'));
      await tester.pump();

      expect(await router.delegate.popRoute(), isTrue);
      await tester.pumpAndSettle();

      expect(_activeRouteNames(router), ['orders', 'orderDetail']);
      expect(router.controller.state.location.path, '/orders/42');
    });

    testWidgets('presents router-owned modal pages and dismisses them first', (
      tester,
    ) async {
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
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
        modalRoutes: [
          LmModalRouteDefinition<Map<String, String>>(
            name: 'orderActions',
            path: '/orders/:orderId/actions',
            presentation: const LmModalPresentation.actionSheet(),
            decode: (params) => params,
            build: (context, params) => Text('Actions ${params!['orderId']}'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));
      expect(find.text('Order Detail'), findsOneWidget);

      await router.delegate.present('/orders/42/actions');
      await tester.pumpAndSettle();

      expect(find.text('Actions 42'), findsOneWidget);
      expect(router.controller.state.modalStack.single.name, 'orderActions');
      expect(router.controller.state.location.path, '/orders/42');
      expect(router.delegate.currentConfiguration?.path, '/orders/42/actions');

      expect(await router.delegate.popRoute(), isTrue);
      await tester.pumpAndSettle();

      expect(find.text('Actions 42'), findsNothing);
      expect(find.text('Order Detail'), findsOneWidget);
      expect(router.controller.state.modalStack, isEmpty);
      expect(router.controller.state.location.path, '/orders/42');
      expect(router.delegate.currentConfiguration?.path, '/orders/42');
    });

    testWidgets(
      'nested modal paths dismiss back to the nearest exact page route',
      (tester) async {
        final router = LmRouter(
          initialLocation: '/lab',
          routes: [
            LmRouteDefinition<void>(
              name: 'home',
              path: '/',
              build: (context, params) => const Text('Home'),
            ),
            LmRouteDefinition<void>(
              name: 'lab',
              path: '/lab',
              build: (context, params) => const Text('Lab'),
            ),
          ],
          notFoundRoute: LmRouteDefinition<void>(
            name: 'notFound',
            path: '/404',
            build: (context, params) => const Text('No route'),
          ),
          modalRoutes: [
            LmModalRouteDefinition<void>(
              name: 'labDialog',
              path: '/lab/modal/dialog',
              presentation: const LmModalPresentation.dialog(),
              build: (context, params) => const Text('Dialog'),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));
        await router.delegate.present('/lab/modal/dialog');
        await tester.pumpAndSettle();

        expect(find.text('Dialog'), findsOneWidget);
        expect(router.controller.state.location.path, '/lab');

        expect(await router.delegate.pop(), isTrue);
        await tester.pumpAndSettle();

        expect(find.text('Dialog'), findsNothing);
        expect(find.text('Lab'), findsOneWidget);
        expect(find.textContaining('No route'), findsNothing);
        expect(router.controller.state.location.path, '/lab');
      },
    );

    testWidgets('programmatic modal navigation reports browser route info', (
      tester,
    ) async {
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
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
        modalRoutes: [
          LmModalRouteDefinition<void>(
            name: 'orderActions',
            path: '/orders/:orderId/actions',
            presentation: const LmModalPresentation.actionSheet(),
            build: (context, params) => const Text('Actions'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));
      final handle = LmRouterHandle(router);

      await handle.present('/orders/42/actions');
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.path,
        '/orders/42/actions',
      );

      await handle.pop();
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/orders/42');
    });

    testWidgets('programmatic modal presentation evaluates guards', (
      tester,
    ) async {
      var signedIn = false;
      final router = LmRouter(
        initialLocation: '/orders/42',
        guards: [
          _Guard((context) {
            if (context.current.location.path.endsWith('/actions') &&
                !signedIn) {
              return LmGuardRedirect(LmLocation(path: '/login'));
            }
            return const LmGuardAllow();
          }),
        ],
        routes: [
          LmRouteDefinition<void>(
            name: 'login',
            path: '/login',
            build: (context, params) => const Text('Login'),
          ),
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
        modalRoutes: [
          LmModalRouteDefinition<void>(
            name: 'orderActions',
            path: '/orders/:orderId/actions',
            presentation: const LmModalPresentation.actionSheet(),
            build: (context, params) => const Text('Actions'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      await router.delegate.present('/orders/42/actions');
      await tester.pumpAndSettle();

      expect(router.controller.state.location.path, '/login');
      expect(router.controller.state.modalStack, isEmpty);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Actions'), findsNothing);

      signedIn = true;
      await router.delegate.go('/orders/42');
      await tester.pumpAndSettle();
      await router.delegate.present('/orders/42/actions');
      await tester.pumpAndSettle();

      expect(router.controller.state.location.path, '/orders/42');
      expect(router.controller.state.modalStack.single.name, 'orderActions');
      expect(find.text('Actions'), findsOneWidget);
    });

    testWidgets(
      'initial guarded deep links redirect before protected content is visible',
      (tester) async {
        final router = LmRouter(
          initialLocation: '/orders/42',
          guards: [
            _Guard((context) {
              if (context.current.location.path.startsWith('/orders/')) {
                return LmGuardRedirect(LmLocation(path: '/login'));
              }
              return const LmGuardAllow();
            }),
          ],
          routes: [
            LmRouteDefinition<void>(
              name: 'login',
              path: '/login',
              transition: const LmTransition.none(),
              build: (context, params) => const Text('Login'),
            ),
            LmRouteDefinition<void>(
              name: 'orders',
              path: '/orders/:orderId',
              transition: const LmTransition.none(),
              build: (context, params) => const Text('Protected Order'),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router.config),
        );
        await tester.pumpAndSettle();

        expect(router.controller.state.location.path, '/login');
        expect(find.text('Login'), findsOneWidget);
        expect(find.text('Protected Order'), findsNothing);
      },
    );

    testWidgets('modal deep link guard redirect can land on a normal page', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/orders',
        guards: [
          _Guard((context) {
            if (context.current.location.path.endsWith('/actions')) {
              return LmGuardRedirect(LmLocation(path: '/login'));
            }
            return const LmGuardAllow();
          }),
        ],
        routes: [
          LmRouteDefinition<void>(
            name: 'login',
            path: '/login',
            build: (context, params) => const Text('Login'),
          ),
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
        modalRoutes: [
          LmModalRouteDefinition<void>(
            name: 'orderActions',
            path: '/orders/:orderId/actions',
            presentation: const LmModalPresentation.actionSheet(),
            build: (context, params) => const Text('Actions'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      await router.delegate.go('/orders/42/actions');
      await tester.pumpAndSettle();

      expect(router.controller.state.location.path, '/login');
      expect(router.controller.state.modalStack, isEmpty);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Actions'), findsNothing);
    });

    testWidgets('programmatic modal presentation can stack modals', (
      tester,
    ) async {
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
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
        modalRoutes: [
          LmModalRouteDefinition<void>(
            name: 'orderActions',
            path: '/orders/:orderId/actions',
            presentation: const LmModalPresentation.actionSheet(),
            build: (context, params) => const Text('Actions'),
          ),
          LmModalRouteDefinition<void>(
            name: 'confirm',
            path: '/orders/:orderId/actions/confirm',
            presentation: const LmModalPresentation.dialog(),
            build: (context, params) => const Text('Confirm'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      await router.delegate.present('/orders/42/actions');
      await tester.pumpAndSettle();
      await router.delegate.present('/orders/42/actions/confirm');
      await tester.pumpAndSettle();

      expect(router.controller.state.modalStack.map((node) => node.name), [
        'orderActions',
        'confirm',
      ]);
      expect(router.controller.state.location.path, '/orders/42');
      expect(
        router.delegate.currentConfiguration?.path,
        '/orders/42/actions/confirm',
      );
      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);

      await router.delegate.pop();
      await tester.pumpAndSettle();

      expect(router.controller.state.modalStack.single.name, 'orderActions');
      expect(router.delegate.currentConfiguration?.path, '/orders/42/actions');
    });

    testWidgets('pop guards receive modal dismissal source and can block it', (
      tester,
    ) async {
      LmLocation? guardFrom;
      LmLocation? guardTo;
      final router = LmRouter(
        initialLocation: '/orders/42',
        guards: [
          Lm.popGuard((context) {
            guardFrom = context.transaction.from;
            guardTo = context.transaction.to;
            if (context.transaction.from?.path.endsWith('/actions') ?? false) {
              return const LmGuardBlock('modal still dirty');
            }
            return const LmGuardAllow();
          }),
        ],
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
            transition: const LmTransition.none(),
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
        modalRoutes: [
          LmModalRouteDefinition<void>(
            name: 'orderActions',
            path: '/orders/:orderId/actions',
            presentation: const LmModalPresentation.actionSheet(
              transition: LmTransition.none(),
            ),
            build: (context, params) => const Text('Actions'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));
      await router.delegate.present('/orders/42/actions');
      await tester.pumpAndSettle();

      expect(await router.delegate.pop(), isFalse);
      await tester.pumpAndSettle();

      expect(guardFrom?.path, '/orders/42/actions');
      expect(guardTo?.path, '/orders/42');
      expect(router.controller.state.modalStack.single.name, 'orderActions');
      expect(find.text('Actions'), findsOneWidget);
    });

    testWidgets('deep links to modal routes preserve the background stack', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/orders',
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
        modalRoutes: [
          LmModalRouteDefinition<Map<String, String>>(
            name: 'orderActions',
            path: '/orders/:orderId/actions',
            presentation: const LmModalPresentation.actionSheet(),
            decode: (params) => params,
            build: (context, params) => Text('Actions ${params!['orderId']}'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      await router.delegate.go('/orders/42/actions');
      await tester.pumpAndSettle();

      expect(_activeRouteNames(router), ['orders', 'orderDetail']);
      expect(find.text('Order Detail'), findsOneWidget);
      expect(find.text('Actions 42'), findsOneWidget);
      expect(router.controller.state.modalStack.single.name, 'orderActions');
      expect(router.controller.state.location.path, '/orders/42');
    });

    testWidgets('initial modal deep links preserve browser configuration', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/orders/42/actions',
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
        modalRoutes: [
          LmModalRouteDefinition<Map<String, String>>(
            name: 'orderActions',
            path: '/orders/:orderId/actions',
            presentation: const LmModalPresentation.actionSheet(
              transition: LmTransition.none(),
            ),
            decode: (params) => params,
            build: (context, params) => Text('Actions ${params!['orderId']}'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));
      await tester.pumpAndSettle();

      expect(_activeRouteNames(router), ['orders', 'orderDetail']);
      expect(find.text('Order Detail'), findsOneWidget);
      expect(find.text('Actions 42'), findsOneWidget);
      expect(router.controller.state.location.path, '/orders/42');
      expect(router.controller.state.modalStack.single.name, 'orderActions');
      expect(router.delegate.currentConfiguration?.path, '/orders/42/actions');
    });

    testWidgets('modal params are decoded once and reused during rebuilds', (
      tester,
    ) async {
      var decodeCount = 0;
      final router = LmRouter(
        initialLocation: '/orders',
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
        modalRoutes: [
          LmModalRouteDefinition<Map<String, String>>(
            name: 'orderActions',
            path: '/orders/:orderId/actions',
            presentation: const LmModalPresentation.actionSheet(
              transition: LmTransition.none(),
            ),
            decode: (params) {
              decodeCount += 1;
              return params;
            },
            build: (context, params) => Text('Actions ${params!['orderId']}'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      await router.delegate.go('/orders/42/actions');
      await tester.pumpAndSettle();

      expect(find.text('Actions 42'), findsOneWidget);
      expect(decodeCount, 1);

      router.delegate.notifyListeners();
      await tester.pump();

      expect(find.text('Actions 42'), findsOneWidget);
      expect(decodeCount, 1);
    });

    testWidgets(
      'modal decode failures render notFoundRoute instead of crashing',
      (tester) async {
        final router = LmRouter(
          initialLocation: '/orders/42',
          notFoundRoute: LmRouteDefinition<void>(
            name: 'notFound',
            path: '/404',
            transition: const LmTransition.none(),
            build: (context, params) => const Text('Bad modal link'),
          ),
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
              transition: const LmTransition.none(),
              build: (context, params) => const Text('Order Detail'),
            ),
          ],
          modalRoutes: [
            LmModalRouteDefinition<int>(
              name: 'orderActions',
              path: '/orders/:orderId/actions',
              presentation: const LmModalPresentation.actionSheet(
                transition: LmTransition.none(),
              ),
              decode: (params) => int.parse(params['orderId']!),
              build: (context, params) => Text('Actions $params'),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router.config),
        );

        await router.delegate.go('/orders/not-an-int/actions');
        await tester.pumpAndSettle();

        expect(router.controller.state.modalStack, isEmpty);
        expect(
          router.controller.state.location.path,
          '/orders/not-an-int/actions',
        );
        expect(find.text('Bad modal link'), findsOneWidget);
        expect(find.text('Actions'), findsNothing);
      },
    );

    testWidgets('dragging down action sheet dismisses the modal', (
      tester,
    ) async {
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
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
        modalRoutes: [
          LmModalRouteDefinition<Map<String, String>>(
            name: 'orderActions',
            path: '/orders/:orderId/actions',
            presentation: const LmModalPresentation.actionSheet(),
            decode: (params) => params,
            build: (context, params) => SizedBox(
              height: 240,
              child: Center(child: Text('Actions ${params!['orderId']}')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      await router.delegate.present('/orders/42/actions');
      await tester.pumpAndSettle();
      expect(find.text('Actions 42'), findsOneWidget);

      await tester.dragFrom(const Offset(400, 380), const Offset(0, 180));
      await tester.pumpAndSettle();

      expect(find.text('Actions 42'), findsNothing);
      expect(router.controller.state.modalStack, isEmpty);
      expect(router.controller.state.location.path, '/orders/42');
    });

    testWidgets('iOS edge drag pops cupertino router pages', (tester) async {
      final router = LmRouter(
        initialLocation: '/orders/42',
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            transition: const LmTransition.none(),
            build: (context, params) =>
                const SizedBox.expand(child: Center(child: Text('Orders'))),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            transition: const LmTransition.cupertino(),
            build: (context, params) => const SizedBox.expand(
              child: Center(child: Text('Order Detail')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeData(platform: TargetPlatform.iOS),
          routerConfig: router.config,
        ),
      );
      await tester.pumpAndSettle();

      await tester.dragFrom(
        const Offset(10, 300),
        const Offset(500, 0),
        touchSlopY: 0,
      );
      await tester.pumpAndSettle();

      expect(_activeRouteNames(router), ['orders']);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Order Detail'), findsNothing);
    });

    testWidgets('disabled cupertino edge gesture does not pop', (tester) async {
      final router = LmRouter(
        initialLocation: '/orders/42',
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            transition: const LmTransition.none(),
            build: (context, params) =>
                const SizedBox.expand(child: Center(child: Text('Orders'))),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            transition: const LmTransition.cupertino(gesturePopEnabled: false),
            build: (context, params) => const SizedBox.expand(
              child: Center(child: Text('Order Detail')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));
      await tester.pumpAndSettle();

      await tester.dragFrom(
        const Offset(10, 300),
        const Offset(500, 0),
        touchSlopY: 0,
      );
      await tester.pumpAndSettle();

      expect(_activeRouteNames(router), ['orders', 'orderDetail']);
      expect(find.text('Order Detail'), findsOneWidget);
    });

    testWidgets('applies guards and commits redirected locations', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/',
        guards: [
          _Guard((context) {
            if (context.current.location.path == '/login') {
              return const LmGuardAllow();
            }
            return LmGuardRedirect(LmLocation(path: '/login'));
          }),
        ],
        routes: [
          LmRouteDefinition<void>(
            name: 'home',
            path: '/',
            build: (context, params) => const Text('Home'),
          ),
          LmRouteDefinition<void>(
            name: 'login',
            path: '/login',
            build: (context, params) => const Text('Login'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      await router.delegate.setNewRoutePath(
        router.parser.parseUri(Uri.parse('/orders/42')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      expect(router.controller.state.location.path, '/login');
    });

    testWidgets('ignores stale async guard result after newer navigation', (
      tester,
    ) async {
      final slowGuardCompleter = Completer<LmGuardResult>();
      final router = LmRouter(
        initialLocation: '/',
        guards: [
          _Guard((context) {
            if (context.current.location.path == '/slow') {
              return slowGuardCompleter.future;
            }
            return const LmGuardAllow();
          }),
        ],
        routes: [
          LmRouteDefinition<void>(
            name: 'home',
            path: '/',
            build: (context, params) => const Text('Home'),
          ),
          LmRouteDefinition<void>(
            name: 'slow',
            path: '/slow',
            build: (context, params) => const Text('Slow'),
          ),
          LmRouteDefinition<void>(
            name: 'fast',
            path: '/fast',
            build: (context, params) => const Text('Fast'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      final slowFuture = router.delegate.go('/slow');
      await tester.pump();
      await router.delegate.go('/fast');
      await tester.pumpAndSettle();

      expect(router.controller.state.location.path, '/fast');
      expect(find.text('Fast'), findsOneWidget);

      slowGuardCompleter.complete(const LmGuardAllow());
      await slowFuture;
      await tester.pumpAndSettle();

      expect(router.controller.state.location.path, '/fast');
      expect(find.text('Slow'), findsNothing);
      expect(find.text('Fast'), findsOneWidget);
    });

    testWidgets('branch switch invalidates stale async guard result', (
      tester,
    ) async {
      final slowGuardCompleter = Completer<LmGuardResult>();
      final router = LmRouter(
        initialLocation: '/orders',
        branches: const [
          LmBranch(id: 'orders', root: '/orders'),
          LmBranch(id: 'settings', root: '/settings'),
        ],
        guards: [
          _Guard((context) {
            if (context.current.location.path == '/orders/slow') {
              return slowGuardCompleter.future;
            }
            return const LmGuardAllow();
          }),
        ],
        routes: [
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'slowOrder',
            path: '/orders/slow',
            build: (context, params) => const Text('Slow Order'),
          ),
          LmRouteDefinition<void>(
            name: 'settings',
            path: '/settings',
            build: (context, params) => const Text('Settings'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      final slowFuture = router.delegate.go('/orders/slow');
      await tester.pump();
      await router.switchBranch('settings');
      await tester.pumpAndSettle();

      expect(router.controller.state.activeBranchId, 'settings');
      expect(router.controller.state.location.path, '/settings');

      slowGuardCompleter.complete(const LmGuardAllow());
      await slowFuture;
      await tester.pumpAndSettle();

      expect(router.controller.state.activeBranchId, 'settings');
      expect(router.controller.state.location.path, '/settings');
      expect(find.text('Slow Order'), findsNothing);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('refreshListenable reruns guards for current route', (
      tester,
    ) async {
      var signedIn = true;
      final refresh = ChangeNotifier();
      final router = LmRouter(
        initialLocation: '/orders/42',
        refreshListenable: refresh,
        guards: [
          _Guard((context) {
            if (context.current.location.path.startsWith('/orders/') &&
                !signedIn) {
              return LmGuardRedirect(LmLocation(path: '/login'));
            }
            return const LmGuardAllow();
          }),
        ],
        routes: [
          LmRouteDefinition<void>(
            name: 'home',
            path: '/',
            build: (context, params) => const Text('Home'),
          ),
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
          LmRouteDefinition<void>(
            name: 'login',
            path: '/login',
            build: (context, params) => const Text('Login'),
          ),
        ],
      );
      addTearDown(refresh.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));
      expect(find.text('Order Detail'), findsOneWidget);

      signedIn = false;
      refresh.notifyListeners();
      await tester.pumpAndSettle();

      expect(router.controller.state.location.path, '/login');
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('initializes first-class branch state from branch config', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/orders/42',
        branches: const [
          LmBranch(id: 'home', root: '/'),
          LmBranch(id: 'orders', root: '/orders'),
          LmBranch(id: 'settings', root: '/settings'),
        ],
        routes: [
          LmRouteDefinition<void>(
            name: 'home',
            path: '/',
            build: (context, params) => const Text('Home'),
          ),
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
          LmRouteDefinition<void>(
            name: 'settings',
            path: '/settings',
            build: (context, params) => const Text('Settings'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      expect(router.controller.state.activeBranchId, 'orders');
      expect(router.controller.state.branches.keys, [
        'home',
        'orders',
        'settings',
      ]);
      expect(_activeRouteNames(router), ['orders', 'orderDetail']);
      expect(
        router.controller.state.branches['settings']!.semanticStack.single.name,
        'settings',
      );

      router.controller.switchBranch('settings');
      await tester.pumpAndSettle();

      expect(router.controller.state.activeBranchId, 'settings');
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('runtime navigation switches to the target branch', (
      tester,
    ) async {
      final router = LmRouter(
        initialLocation: '/orders/42',
        branches: const [
          LmBranch(id: 'home', root: '/'),
          LmBranch(id: 'orders', root: '/orders'),
          LmBranch(id: 'lab', root: '/lab'),
          LmBranch(id: 'settings', root: '/settings'),
        ],
        routes: [
          LmRouteDefinition<void>(
            name: 'home',
            path: '/',
            build: (context, params) => const Text('Home'),
          ),
          LmRouteDefinition<void>(
            name: 'orders',
            path: '/orders',
            build: (context, params) => const Text('Orders'),
          ),
          LmRouteDefinition<void>(
            name: 'orderDetail',
            path: '/orders/:orderId',
            build: (context, params) => const Text('Order Detail'),
          ),
          LmRouteDefinition<void>(
            name: 'lab',
            path: '/lab',
            build: (context, params) => const Text('Lab'),
          ),
          LmRouteDefinition<void>(
            name: 'labDetail',
            path: '/lab/detail',
            build: (context, params) => const Text('Lab Detail'),
          ),
          LmRouteDefinition<void>(
            name: 'settings',
            path: '/settings',
            build: (context, params) => const Text('Settings'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config));

      expect(router.controller.state.activeBranchId, 'orders');
      expect(_activeRouteNames(router), ['orders', 'orderDetail']);

      await router.go('/settings');
      await tester.pumpAndSettle();

      expect(router.controller.state.activeBranchId, 'settings');
      expect(_activeRouteNames(router), ['settings']);
      expect(
        router.controller.state.branches['orders']!.semanticStack.map(
          (node) => node.name,
        ),
        ['orders', 'orderDetail'],
      );
      expect(find.text('Settings'), findsOneWidget);

      await router.push('/lab/detail');
      await tester.pumpAndSettle();

      expect(router.controller.state.activeBranchId, 'lab');
      expect(_activeRouteNames(router), ['lab', 'labDetail']);
      expect(
        router.controller.state.branches['settings']!.semanticStack.map(
          (node) => node.name,
        ),
        ['settings'],
      );
      expect(find.text('Lab Detail'), findsOneWidget);
    });
  });
}

List<String> _activeRouteNames(LmRouter router) {
  final branch =
      router.controller.state.branches[router.controller.state.activeBranchId]!;
  return branch.semanticStack.map((node) => node.name).toList();
}

final class _Guard implements LmGuard {
  const _Guard(this._callback);

  final FutureOr<LmGuardResult> Function(LmGuardContext context) _callback;

  @override
  FutureOr<LmGuardResult> canActivate(LmGuardContext context) =>
      _callback(context);
}

final class _OrdersRoute implements LmRouteLocation {
  const _OrdersRoute();

  @override
  LmLocation get location => LmLocation(path: '/orders');
}

final class _OrderDetailRoute implements LmRouteLocation {
  const _OrderDetailRoute(this.orderId);

  final int orderId;

  @override
  LmLocation get location => LmLocation(path: '/orders/$orderId');
}

final class _OrderActionsRoute implements LmRouteLocation {
  const _OrderActionsRoute(this.orderId);

  final int orderId;

  @override
  LmLocation get location => LmLocation(path: '/orders/$orderId/actions');
}
