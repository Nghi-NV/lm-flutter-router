import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/src/core/lm_location.dart';
import 'package:lm_flutter_router/src/delegate/lm_navigation_transaction.dart';
import 'package:lm_flutter_router/src/guards/lm_guard.dart';
import 'package:lm_flutter_router/src/guards/lm_guard_pipeline.dart';
import 'package:lm_flutter_router/src/state/lm_branch_state.dart';
import 'package:lm_flutter_router/src/state/lm_modal_node.dart';
import 'package:lm_flutter_router/src/state/lm_navigation_state.dart';
import 'package:lm_flutter_router/src/state/lm_route_node.dart';

void main() {
  group('navigation state', () {
    test('defensively exposes immutable collections', () {
      final root = LmRouteNode(
        name: 'home',
        pathPattern: '/',
        location: _location('/'),
        params: const NoParams(),
        query: const {},
      );
      final modal = LmModalNode(
        name: 'settingsDialog',
        location: _location('/settings/dialog'),
      );
      final state = LmNavigationState(
        activeBranchId: 'home',
        branches: {
          'home': LmBranchState(branchId: 'home', semanticStack: [root]),
        },
        location: _location('/'),
        modalStack: [modal],
        version: 1,
      );

      expect(
        () => state.branches['orders'] = LmBranchState(
          branchId: 'orders',
          semanticStack: [root],
        ),
        throwsUnsupportedError,
      );
      expect(() => state.modalStack.add(modal), throwsUnsupportedError);
      expect(
        () => state.branches['home']!.semanticStack.add(root),
        throwsUnsupportedError,
      );
    });
  });

  group('LmGuardPipeline', () {
    test('allows when every guard allows', () async {
      final pipeline = LmGuardPipeline(
        guards: [
          _Guard((_) => const LmGuardAllow()),
          _Guard((_) async => const LmGuardAllow()),
        ],
      );

      final result = await pipeline.evaluate(_transaction('/from', '/to'));

      expect(result, isA<LmGuardAllowed>());
      expect(result.transaction.to, _location('/to'));
    });

    test('blocks on first blocking guard', () async {
      final pipeline = LmGuardPipeline(
        guards: [
          _Guard((_) => const LmGuardAllow()),
          _Guard((_) => const LmGuardBlock('signed-out')),
          _Guard((_) => fail('guard after block should not run')),
        ],
      );

      final result = await pipeline.evaluate(_transaction('/from', '/admin'));

      expect(result, isA<LmGuardBlocked>());
      expect((result as LmGuardBlocked).reason, 'signed-out');
      expect(result.transaction.to, _location('/admin'));
    });

    test('redirect preserves original intent by default', () async {
      final pipeline = LmGuardPipeline(
        guards: [
          _Guard((context) {
            if (context.current.location.path == '/login') {
              return const LmGuardAllow();
            }
            return LmGuardRedirect(_location('/login'));
          }),
        ],
      );
      final initial = _transaction('/home', '/orders/42', id: 7);

      final result = await pipeline.evaluate(initial);

      expect(result, isA<LmGuardAllowed>());
      expect(result.transaction.source, LmNavigationSource.guardRedirect);
      expect(result.transaction.from, _location('/home'));
      expect(result.transaction.to, _location('/login'));
      expect(result.originalIntent, initial.to);
    });

    test('login redirect encodes returnTo query', () async {
      final pipeline = LmGuardPipeline(
        guards: [
          _Guard((context) {
            if (context.current.location.path == '/login') {
              return const LmGuardAllow();
            }
            return LmGuardRedirect.toLogin('/login', context);
          }),
        ],
      );
      final initial = _transaction('/home', '/orders/42?tab=items');

      final result = await pipeline.evaluate(initial);

      expect(result, isA<LmGuardAllowed>());
      expect(result.transaction.to.path, '/login');
      expect(result.transaction.to.query['returnTo'], '/orders/42?tab=items');
    });

    test('detects redirect loops before max redirects is exceeded', () async {
      final pipeline = LmGuardPipeline(
        maxRedirects: 8,
        guards: [
          _Guard((context) {
            if (context.current.location.path == '/a') {
              return LmGuardRedirect(_location('/b'));
            }
            return LmGuardRedirect(_location('/a'));
          }),
        ],
      );

      final result = await pipeline.evaluate(_transaction('/home', '/a'));

      expect(result, isA<LmGuardRedirectLoop>());
      expect((result as LmGuardRedirectLoop).locations, [
        _location('/a'),
        _location('/b'),
        _location('/a'),
      ]);
    });

    test('runs async guards sequentially in declaration order', () async {
      final order = <String>[];
      final firstCompleter = Completer<void>();
      final pipeline = LmGuardPipeline(
        guards: [
          _Guard((_) async {
            order.add('first-start');
            await firstCompleter.future;
            order.add('first-end');
            return const LmGuardAllow();
          }),
          _Guard((_) async {
            order.add('second');
            return const LmGuardAllow();
          }),
        ],
      );

      final future = pipeline.evaluate(_transaction('/home', '/settings'));
      await Future<void>.delayed(Duration.zero);

      expect(order, ['first-start']);
      firstCompleter.complete();
      final result = await future;

      expect(result, isA<LmGuardAllowed>());
      expect(order, ['first-start', 'first-end', 'second']);
    });
  });
}

LmNavigationTransaction _transaction(String from, String to, {int id = 1}) {
  return LmNavigationTransaction(
    id: id,
    source: LmNavigationSource.programmaticGo,
    from: _location(from),
    to: _location(to),
    startedAt: DateTime.utc(2026, 1, 1),
  );
}

LmLocation _location(String value) => LmLocation.fromUri(Uri.parse(value));

final class _Guard implements LmGuard {
  const _Guard(this._callback);

  final FutureOr<LmGuardResult> Function(LmGuardContext context) _callback;

  @override
  FutureOr<LmGuardResult> canActivate(LmGuardContext context) =>
      _callback(context);
}

final class NoParams {
  const NoParams();
}
