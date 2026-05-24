import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/src/core/lm_location.dart';
import 'package:lm_flutter_router/src/core/lm_route_definition.dart';
import 'package:lm_flutter_router/src/modal/lm_modal_route_definition.dart';
import 'package:lm_flutter_router/src/params/lm_codecs.dart';
import 'package:lm_flutter_router/src/params/lm_param_errors.dart';

enum _OrderTab { summary, items }

void main() {
  group('LmLocation', () {
    test(
      'round trips through Uri without losing query, fragment, or extra',
      () {
        final original = LmLocation.fromUri(
          Uri.parse('/orders/42/items?tab=items&page=2#details'),
          extra: const Object(),
        );

        expect(original.path, '/orders/42/items');
        expect(original.query, {'tab': 'items', 'page': '2'});
        expect(original.fragment, 'details');
        expect(original.extra, isA<Object>());

        final roundTrip = LmLocation.fromUri(original.toUri());

        expect(roundTrip.path, original.path);
        expect(roundTrip.query, original.query);
        expect(roundTrip.fragment, original.fragment);
        expect(roundTrip.extra, isNull);
      },
    );

    test('canonical sorts query keys and omits runtime extra', () {
      final location = LmLocation(
        path: '/orders/42',
        query: {'z': 'last', 'a': 'first', 'm': 'middle'},
        fragment: 'line',
        extra: Object(),
      );

      expect(location.canonical, '/orders/42?a=first&m=middle&z=last#line');
    });

    test('query equality and hashCode ignore insertion order', () {
      final left = LmLocation(path: '/orders', query: {'b': '2', 'a': '1'});
      final right = LmLocation(path: '/orders', query: {'a': '1', 'b': '2'});

      expect(left, right);
      expect(left.canonical, right.canonical);
      expect(left.hashCode, right.hashCode);
    });

    test('copyWith creates a new immutable value with stable equality', () {
      final location = LmLocation(path: '/orders', query: {'page': '1'});
      final copied = location.copyWith(path: '/orders/42');

      final expected = LmLocation(path: '/orders/42', query: {'page': '1'});
      expect(copied, expected);
      expect(copied.hashCode, expected.hashCode);
      expect(location.path, '/orders');
    });
  });

  group('route locations', () {
    test('page routes reject null params for dynamic path templates', () {
      final route = LmRouteDefinition<int>.page(
        path: '/orders/:orderId',
        buildPath: (orderId) => '/orders/$orderId',
        build: (context, params) => throw UnimplementedError(),
      );

      expect(
        () => route.location(null),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('requires params'),
          ),
        ),
      );
    });

    test('modal routes reject null params for wildcard path templates', () {
      final route = LmModalRouteDefinition<void>.sheet(
        path: '/files/*',
        build: (context, params) => throw UnimplementedError(),
      );

      expect(() => route.location(null), throwsA(isA<StateError>()));
    });
  });

  group('LmCodecs', () {
    test('encodes and decodes built in scalar values', () {
      expect(LmCodecs.string.encode('abc'), 'abc');
      expect(LmCodecs.string.decode('abc'), 'abc');

      expect(LmCodecs.int.encode(42), '42');
      expect(LmCodecs.int.decode('42'), 42);

      expect(LmCodecs.double.encode(10.5), '10.5');
      expect(LmCodecs.double.decode('10.5'), 10.5);

      expect(LmCodecs.bool.encode(true), 'true');
      expect(LmCodecs.bool.decode('false'), isFalse);

      final value = DateTime.utc(2026, 5, 19, 8, 30);
      expect(
        LmCodecs.dateTimeIso8601.decode(LmCodecs.dateTimeIso8601.encode(value)),
        value,
      );
    });

    test('encodes and decodes enums by name', () {
      final codec = LmCodecs.enumByName(_OrderTab.values);

      expect(codec.encode(_OrderTab.items), 'items');
      expect(codec.decode('summary'), _OrderTab.summary);
    });

    test('throws route aware errors for invalid values and missing params', () {
      expect(
        () => LmCodecs.int.decode(
          'abc',
          routeName: 'OrderDetailRoute',
          paramName: 'orderId',
        ),
        throwsA(
          isA<LmInvalidParamException>()
              .having(
                (error) => error.routeName,
                'routeName',
                'OrderDetailRoute',
              )
              .having((error) => error.paramName, 'paramName', 'orderId')
              .having((error) => error.rawValue, 'rawValue', 'abc'),
        ),
      );

      expect(
        () => LmCodecs.bool.decode(
          'yes',
          routeName: 'OrderListRoute',
          paramName: 'archived',
        ),
        throwsA(isA<LmInvalidParamException>()),
      );

      final codec = LmCodecs.enumByName(_OrderTab.values);
      expect(
        () => codec.decode(
          'history',
          routeName: 'OrderDetailRoute',
          paramName: 'tab',
        ),
        throwsA(
          isA<LmUnknownEnumValueException>()
              .having(
                (error) => error.routeName,
                'routeName',
                'OrderDetailRoute',
              )
              .having((error) => error.paramName, 'paramName', 'tab')
              .having((error) => error.allowedValues, 'allowedValues', [
                'summary',
                'items',
              ]),
        ),
      );

      expect(
        () => LmCodecs.int.decodeRequired(
          null,
          routeName: 'OrderDetailRoute',
          paramName: 'orderId',
        ),
        throwsA(
          isA<LmMissingParamException>()
              .having(
                (error) => error.routeName,
                'routeName',
                'OrderDetailRoute',
              )
              .having((error) => error.paramName, 'paramName', 'orderId'),
        ),
      );
    });
  });
}
