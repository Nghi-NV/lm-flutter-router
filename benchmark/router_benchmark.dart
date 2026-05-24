import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/lm_flutter_router_advanced.dart';

void main() {
  test('router benchmark smoke', () async {
    final routes = [
      for (var i = 0; i < 1000; i++)
        LmRouteDefinition<void>(name: 'static$i', path: '/static/$i'),
      LmRouteDefinition<void>(
        name: 'orderItem',
        path: '/orders/:orderId/items/:itemId',
      ),
      LmRouteDefinition<void>(name: 'fallback', path: '/fallback/*'),
    ];

    final matcher = LmRouteMatcher(routes);
    final stopwatch = Stopwatch();

    final staticTime = _measure(stopwatch, () {
      matcher.match('/static/999');
    });

    final dynamicTime = _measure(stopwatch, () {
      matcher.match('/orders/42/items/9');
    });

    final guardPipeline = LmGuardPipeline(
      guards: [
        _BenchmarkGuard((_) => const LmGuardAllow()),
        _BenchmarkGuard((_) async => const LmGuardAllow()),
      ],
    );

    final guardTime = await _measureAsync(stopwatch, () {
      return guardPipeline.evaluate(
        LmNavigationTransaction(
          id: 1,
          source: LmNavigationSource.deepLink,
          from: null,
          to: LmLocation(path: '/orders/42/items/9'),
          startedAt: DateTime.now(),
        ),
      );
    });

    // Keep output simple so CI can parse it if needed.
    // ignore: avoid_print
    print('static_match_us=$staticTime');
    // ignore: avoid_print
    print('dynamic_match_us=$dynamicTime');
    // ignore: avoid_print
    print('guard_pipeline_us=$guardTime');

    expect(staticTime, lessThan(150));
    expect(dynamicTime, lessThan(150));
    expect(guardTime, lessThan(500));
  });
}

int _measure(Stopwatch stopwatch, void Function() run) {
  stopwatch
    ..reset()
    ..start();
  for (var i = 0; i < 10000; i++) {
    run();
  }
  stopwatch.stop();
  return stopwatch.elapsedMicroseconds ~/ 10000;
}

Future<int> _measureAsync(
  Stopwatch stopwatch,
  Future<void> Function() run,
) async {
  stopwatch
    ..reset()
    ..start();
  for (var i = 0; i < 1000; i++) {
    await run();
  }
  stopwatch.stop();
  return stopwatch.elapsedMicroseconds ~/ 1000;
}

final class _BenchmarkGuard implements LmGuard {
  const _BenchmarkGuard(this.callback);

  final FutureOr<LmGuardResult> Function(LmGuardContext context) callback;

  @override
  FutureOr<LmGuardResult> canActivate(LmGuardContext context) {
    return callback(context);
  }
}
