import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/src/core/lm_route_definition.dart';
import 'package:lm_flutter_router/src/matcher/lm_route_matcher.dart';

void main() {
  group('LmRouteMatcher', () {
    test('prioritizes static routes over dynamic and wildcard routes', () {
      final userSettings = LmRouteDefinition<void>(
        name: 'user-settings',
        path: '/users/settings',
      );
      final userDetail = LmRouteDefinition<void>(
        name: 'user-detail',
        path: '/users/:id',
      );
      final usersFallback = LmRouteDefinition<void>(
        name: 'users-fallback',
        path: '/users/*',
      );

      final matcher = LmRouteMatcher([usersFallback, userDetail, userSettings]);

      final staticMatch = matcher.match('/users/settings');
      expect(staticMatch.isMatch, isTrue);
      expect(staticMatch.route, same(userSettings));
      expect(staticMatch.routeChain, [same(userSettings)]);
      expect(staticMatch.pathParameters, isEmpty);
      expect(staticMatch.matchedLocation, '/users/settings');
      expect(staticMatch.remaining, isEmpty);

      final dynamicMatch = matcher.match('/users/42');
      expect(dynamicMatch.isMatch, isTrue);
      expect(dynamicMatch.route, same(userDetail));
      expect(dynamicMatch.pathParameters, {'id': '42'});
      expect(dynamicMatch.matchedLocation, '/users/42');

      final wildcardMatch = matcher.match('/users/42/profile');
      expect(wildcardMatch.isMatch, isTrue);
      expect(wildcardMatch.route, same(usersFallback));
      expect(wildcardMatch.pathParameters, {'*': '42/profile'});
      expect(wildcardMatch.matchedLocation, '/users/42/profile');
    });

    test('matches nested route chains and accumulates path parameters', () {
      final orderItem = LmRouteDefinition<void>(
        name: 'order-item',
        path: 'items/:itemId',
      );
      final orderDetail = LmRouteDefinition<void>(
        name: 'order-detail',
        path: ':orderId',
        children: [orderItem],
      );
      final orders = LmRouteDefinition<void>(
        name: 'orders',
        path: '/orders',
        children: [orderDetail],
      );

      final matcher = LmRouteMatcher([orders]);

      final result = matcher.match('/orders/42/items/9');

      expect(result.isMatch, isTrue);
      expect(result.route, same(orderItem));
      expect(result.routeChain, [
        same(orders),
        same(orderDetail),
        same(orderItem),
      ]);
      expect(result.pathParameters, {'orderId': '42', 'itemId': '9'});
      expect(result.matchedLocation, '/orders/42/items/9');
      expect(result.remaining, isEmpty);
    });

    test('returns a clear no-match result', () {
      final matcher = LmRouteMatcher([
        LmRouteDefinition<void>(name: 'orders', path: '/orders'),
      ]);

      final result = matcher.match('/settings');

      expect(result.isMatch, isFalse);
      expect(result.route, isNull);
      expect(result.routeChain, isEmpty);
      expect(result.pathParameters, isEmpty);
      expect(result.matchedLocation, isEmpty);
      expect(result.remaining, '/settings');
    });
  });
}
