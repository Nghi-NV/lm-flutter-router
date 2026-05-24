import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/lm_flutter_router.dart';

void main() {
  testWidgets('router fails fast for duplicate routes and modal names', (
    tester,
  ) async {
    LmRouteDefinition<void> page(String name, String path) {
      return LmRouteDefinition<void>.page(
        name: name,
        path: path,
        build: (context, params) => const SizedBox.shrink(),
      );
    }

    expect(
      () => LmRouter(
        initialLocation: '/',
        routes: [page('home', '/'), page('duplicateHome', '/')],
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => LmRouter(
        initialLocation: '/',
        routes: [page('home', '/'), page('home', '/home')],
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => LmRouter(
        initialLocation: '/',
        routes: [page('home', '/')],
        modalRoutes: [
          LmModalRouteDefinition<void>.sheet(
            name: 'actions',
            path: '/actions',
            build: (context, params) => const SizedBox.shrink(),
          ),
          LmModalRouteDefinition<void>.dialog(
            name: 'actions',
            path: '/dialog',
            build: (context, params) => const SizedBox.shrink(),
          ),
        ],
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  testWidgets('public API exports router primitives', (tester) async {
    final router = LmRouter(
      initialLocation: '/',
      branches: const [LmBranch(id: 'home', root: '/')],
      routes: [
        LmRouteDefinition<void>(
          name: 'home',
          path: '/',
          build: (context, params) => const SizedBox.shrink(),
        ),
      ],
    );

    expect(router.config.routerDelegate, same(router.delegate));
    expect(router.parser.parseUri(Uri.parse('/')).path, '/');
    expect(
      _normalizeHost(Uri.parse('https://orders.example')).path,
      '/orders.example',
    );
    expect(LmLocation.path('/').path, '/');
    expect(LmCodecs.int.decode('42'), 42);
    expect(
      router.controller.state.branches['home']!.semanticStack.single.name,
      'home',
    );
    final appRouter = LmRouter.app(
      routes: [
        LmRouteDefinition<void>.page(
          path: '/',
          build: (context, params) => const SizedBox.shrink(),
        ),
      ],
    );
    expect(appRouter.controller.state.location.path, '/');
    expect(appRouter.location.path, '/');
    expect(appRouter.canPop, isFalse);
    expect(LmRouter.platformInitialLocation(), isNotEmpty);
    expect(
      const LmRouteDefinition<void>(name: 'detail', path: '/detail').transition,
      isA<LmCupertinoTransition>(),
    );
    expect(
      LmRouteDefinition<void>.page(
        path: '/page',
        build: (context, params) => const SizedBox.shrink(),
      ).name,
      'page',
    );
    expect(
      LmRouteDefinition<int>.page(
        path: '/orders/:orderId',
        buildPath: (orderId) => '/orders/$orderId',
        build: (context, params) => const SizedBox.shrink(),
      ).location(42).path,
      '/orders/42',
    );
    expect(const LmTransition.cupertino().gesturePopEnabled, isTrue);
    expect(const LmTransition.scale(), isA<LmScaleTransition>());
    expect(const LmTransition.hero(), isA<LmHeroTransition>());
    expect(const LmRouterBackIntent(), isA<LmRouterBackIntent>());
    expect(LmRouterKeyboardShortcuts.defaultShortcuts, isNotEmpty);
    expect(
      LmLocation.parse('/orders/1?tab=items').canonical,
      '/orders/1?tab=items',
    );
    expect(
      LmLocation.path('/orders', query: {'page': '1'}).canonical,
      '/orders?page=1',
    );
    expect(
      LmModalRouteDefinition<void>.sheet(
        path: '/sheet',
        build: (context, params) => const SizedBox.shrink(),
      ).presentation.kind,
      LmModalPresentationKind.bottomSheet,
    );
    expect(
      LmModalRouteDefinition<void>.dialog(
        path: '/dialog',
        build: (context, params) => const SizedBox.shrink(),
      ).presentation.kind,
      LmModalPresentationKind.dialog,
    );
    expect(
      LmModalRouteDefinition<void>.cupertinoDialog(
        path: '/cupertino-dialog',
        build: (context, params) => const SizedBox.shrink(),
      ).presentation.kind,
      LmModalPresentationKind.cupertinoDialog,
    );
    expect(
      LmModalRouteDefinition<void>.actionSheet(
        path: '/action-sheet',
        build: (context, params) => const SizedBox.shrink(),
      ).presentation.kind,
      LmModalPresentationKind.actionSheet,
    );
    expect(
      LmModalRouteDefinition<void>.fullscreenDialog(
        path: '/fullscreen-dialog',
        build: (context, params) => const SizedBox.shrink(),
      ).presentation.kind,
      LmModalPresentationKind.fullscreenDialog,
    );
    expect(
      LmModalRouteDefinition<void>.popover(
        path: '/popover',
        build: (context, params) => const SizedBox.shrink(),
      ).presentation.kind,
      LmModalPresentationKind.popover,
    );
    expect(
      LmModalRouteDefinition<void>.actionSheet(
        path: '/orders/:orderId/actions',
        build: (context, params) => const SizedBox.shrink(),
      ).name,
      'orders.orderId.actions',
    );
    expect(
      LmModalRouteDefinition<int>.actionSheet(
        path: '/orders/:orderId/actions',
        buildPath: (orderId) => '/orders/$orderId/actions',
        build: (context, params) => const SizedBox.shrink(),
      ).location(42).path,
      '/orders/42/actions',
    );
    final simpleRouter = Lm.router(
      routes: [
        Lm.page<void>(
          path: '/',
          build: (context, params) => const SizedBox.shrink(),
        ),
      ],
      modalRoutes: [
        Lm.sheet<void>(
          path: '/sheet',
          build: (context, params) => const SizedBox.shrink(),
        ),
      ],
      branches: [Lm.branch(id: 'home', root: '/')],
      guards: [Lm.guard((context) => const LmGuardAllow())],
      linkTransformers: [
        Lm.links(
          normalize: (uri) =>
              uri.host == 'orders.example' ? LmLocation(path: '/orders') : null,
        ),
      ],
    );
    expect(simpleRouter.location.path, '/');
    expect(Lm.path('/orders').path, '/orders');
    expect(Lm.params({'orderId': '42'}).requiredInt('orderId'), 42);
    expect(router.controller.state.location.path, '/');

    router.dispose();
    appRouter.dispose();
    simpleRouter.dispose();
  });
}

LmLocation _normalizeHost(Uri uri) => LmLocation(path: '/${uri.host}');
