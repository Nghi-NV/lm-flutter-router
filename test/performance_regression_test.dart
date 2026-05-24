import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/src/core/lm_route_definition.dart';
import 'package:lm_flutter_router/src/modal/lm_modal_presentation.dart';
import 'package:lm_flutter_router/src/modal/lm_modal_route_definition.dart';
import 'package:lm_flutter_router/src/router/lm_router.dart';
import 'package:lm_flutter_router/src/transitions/lm_transition.dart';

void main() {
  testWidgets('router hot path stays allocation-light under route pressure', (
    tester,
  ) async {
    final router = LmRouter(
      initialLocation: '/orders',
      routes: [
        LmRouteDefinition<void>(
          name: 'orders',
          path: '/orders',
          transition: const LmTransition.none(),
        ),
        LmRouteDefinition<void>(
          name: 'orderDetail',
          path: '/orders/:orderId',
          transition: const LmTransition.none(),
        ),
        LmRouteDefinition<void>(
          name: 'orderItem',
          path: '/orders/:orderId/items/:itemId',
          transition: const LmTransition.none(),
        ),
        for (var index = 0; index < 120; index += 1)
          LmRouteDefinition<void>(
            name: 'static$index',
            path: '/static/$index',
            transition: const LmTransition.none(),
          ),
      ],
    );

    for (var index = 0; index < 50; index += 1) {
      await router.delegate.go('/orders/${index % 10}/items/$index');
    }

    final uniqueStopwatch = Stopwatch()..start();
    for (var index = 0; index < 500; index += 1) {
      await router.delegate.go(
        '/orders/${index % 100}/items/$index?revision=$index',
      );
    }
    uniqueStopwatch.stop();

    final repeatedStopwatch = Stopwatch()..start();
    for (var index = 0; index < 500; index += 1) {
      await router.delegate.go('/orders/42/items/9');
    }
    repeatedStopwatch.stop();

    final uniqueAverageMicros = uniqueStopwatch.elapsedMicroseconds / 500.0;
    final repeatedAverageMicros = repeatedStopwatch.elapsedMicroseconds / 500.0;

    expect(
      uniqueAverageMicros,
      lessThan(500),
      reason:
          'Unique deep-link stack construction should stay comfortably below '
          'a frame budget even with many registered routes.',
    );
    expect(
      repeatedAverageMicros,
      lessThan(150),
      reason: 'Repeated routes should hit router caches.',
    );
  });

  testWidgets('router hot-path caches stay bounded under route pressure', (
    tester,
  ) async {
    final router = LmRouter(
      initialLocation: '/orders',
      routes: [
        LmRouteDefinition<void>(
          name: 'orders',
          path: '/orders',
          transition: const LmTransition.none(),
        ),
        LmRouteDefinition<void>(
          name: 'orderDetail',
          path: '/orders/:orderId',
          transition: const LmTransition.none(),
        ),
      ],
      modalRoutes: [
        LmModalRouteDefinition<void>(
          name: 'orderActions',
          path: '/orders/:orderId/actions',
          presentation: const LmModalPresentation.actionSheet(
            transition: LmTransition.none(),
          ),
        ),
      ],
    );

    for (var index = 0; index < 400; index += 1) {
      await router.delegate.go('/orders/$index?revision=$index');
    }

    expect(
      router.delegate.debugStackCacheSize,
      lessThanOrEqualTo(256),
      reason: 'Semantic stack cache must stay bounded in long sessions.',
    );

    for (var index = 0; index < 400; index += 1) {
      await router.delegate.go('/orders/$index/actions');
      await router.delegate.pop();
    }

    expect(
      router.delegate.debugStackCacheSize,
      lessThanOrEqualTo(256),
      reason: 'Modal background stack caching must stay bounded.',
    );
    expect(
      router.delegate.debugModalMatchCacheSize,
      lessThanOrEqualTo(256),
      reason: 'Modal match cache must stay bounded in long sessions.',
    );
  });
}
