import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/src/adaptive/lm_detail_policy.dart';
import 'package:lm_flutter_router/src/adaptive/lm_branch.dart';
import 'package:lm_flutter_router/src/chrome/lm_route_chrome.dart';
import 'package:lm_flutter_router/src/core/lm_route_definition.dart';
import 'package:lm_flutter_router/src/core/lm_location.dart';
import 'package:lm_flutter_router/src/delegate/lm_navigation_transaction.dart';
import 'package:lm_flutter_router/src/diagnostics/lm_navigation_event.dart';
import 'package:lm_flutter_router/src/diagnostics/lm_router_diagnostics.dart';
import 'package:lm_flutter_router/src/guards/lm_guard.dart';
import 'package:lm_flutter_router/src/modal/lm_modal_route_definition.dart';
import 'package:lm_flutter_router/src/router/lm_router.dart';
import 'package:lm_flutter_router/src/restoration/lm_route_state_codec.dart';
import 'package:lm_flutter_router/src/state/lm_branch_state.dart';
import 'package:lm_flutter_router/src/state/lm_modal_node.dart';
import 'package:lm_flutter_router/src/state/lm_navigation_state.dart';
import 'package:lm_flutter_router/src/state/lm_route_node.dart';
import 'package:lm_flutter_router/src/transitions/lm_transition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LmRouteStateCodec serializes and restores navigation state', () {
    final state = LmNavigationState(
      activeBranchId: 'orders',
      branches: {
        'orders': LmBranchState(
          branchId: 'orders',
          semanticStack: [
            _node('orders', '/orders'),
            _node(
              'orderDetail',
              '/orders/42',
              params: 42,
              chrome: const LmRouteChrome(
                title: 'Order 42',
                largeTitle: false,
                showBackButton: true,
                tabBarVisibility: LmTabBarVisibility.hidden,
              ),
              detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
            ),
          ],
        ),
      },
      location: _location('/orders/42'),
      modalStack: [
        LmModalNode(
          name: 'actions',
          location: _location('/orders/42/actions?mode=quick'),
          params: const {'orderId': '42'},
          query: const {'mode': 'quick'},
        ),
      ],
      version: 3,
    );

    const codec = LmRouteStateCodec(schemaVersion: 1);
    final encoded = codec.encode(state);
    final restored = codec.decode(encoded);

    expect(restored.activeBranchId, 'orders');
    expect(restored.location, _location('/orders/42'));
    expect(restored.version, 3);
    expect(
      restored.branches['orders']!.semanticStack.map((node) => node.name),
      ['orders', 'orderDetail'],
    );
    expect(restored.modalStack.single.name, 'actions');
    expect(
      restored.branches['orders']!.semanticStack.last.detailPolicy,
      LmDetailPolicy.secondaryPaneOnExpanded,
    );
    expect(
      restored.modalStack.single.location,
      _location('/orders/42/actions?mode=quick'),
    );
    expect(restored.modalStack.single.query, {'mode': 'quick'});
    expect(restored.branches['orders']!.semanticStack.last.params, 42);
    expect(
      restored.branches['orders']!.semanticStack.last.chrome.title,
      'Order 42',
    );
    expect(
      restored.branches['orders']!.semanticStack.last.chrome.tabBarVisibility,
      LmTabBarVisibility.hidden,
    );
    expect(restored.modalStack.single.params, {'orderId': '42'});
  });

  test('LmRouterDiagnostics records emitted navigation events', () {
    final diagnostics = LmRouterDiagnostics();
    final events = <LmNavigationEvent>[];
    diagnostics.addListener(events.add);

    final event = LmNavigationEvent(
      type: LmNavigationEventType.navigateCommit,
      source: LmNavigationSource.programmaticPush,
      from: _location('/orders'),
      to: _location('/orders/42'),
      result: LmNavigationResult.committed,
      duration: const Duration(milliseconds: 12),
    );

    diagnostics.emit(event);

    expect(events, [event]);
    expect(diagnostics.events, [event]);
  });

  test('LmRouterDiagnostics keeps only the newest maxEvents entries', () {
    final diagnostics = LmRouterDiagnostics(maxEvents: 2);

    for (var i = 0; i < 3; i += 1) {
      diagnostics.emit(
        LmNavigationEvent(
          type: LmNavigationEventType.navigateCommit,
          source: LmNavigationSource.programmaticPush,
          from: _location('/'),
          to: _location('/$i'),
          result: LmNavigationResult.committed,
          duration: Duration.zero,
        ),
      );
    }

    expect(diagnostics.events.map((event) => event.to.path), ['/1', '/2']);
  });

  test('LmRouter emits structured diagnostics for push and pop', () async {
    final diagnostics = LmRouterDiagnostics();
    final router = LmRouter(
      initialLocation: '/orders',
      diagnostics: diagnostics,
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
    );

    await router.delegate.push('/orders/42');
    await router.delegate.pop();

    expect(diagnostics.events.map((event) => event.type), [
      LmNavigationEventType.navigateStart,
      LmNavigationEventType.navigateCommit,
      LmNavigationEventType.navigateStart,
      LmNavigationEventType.navigateCommit,
    ]);
    expect(diagnostics.events[0].source, LmNavigationSource.programmaticPush);
    expect(diagnostics.events[0].from, _location('/orders'));
    expect(diagnostics.events[0].to, _location('/orders/42'));
    expect(diagnostics.events[1].result, LmNavigationResult.committed);
    expect(diagnostics.events[2].source, LmNavigationSource.programmaticPop);
    expect(diagnostics.events[2].from, _location('/orders/42'));
    expect(diagnostics.events[2].to, _location('/orders'));
    expect(diagnostics.events[3].source, LmNavigationSource.programmaticPop);
    expect(diagnostics.events[3].from, _location('/orders/42'));
    expect(diagnostics.events[3].to, _location('/orders'));
  });

  test('LmRouter emits diagnostics for blocked guard decisions', () async {
    final diagnostics = LmRouterDiagnostics();
    final router = LmRouter(
      initialLocation: '/orders',
      diagnostics: diagnostics,
      guards: [
        _Guard((context) {
          if (context.current.location.path == '/orders/42') {
            return const LmGuardBlock('locked');
          }
          return const LmGuardAllow();
        }),
      ],
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
    );

    await router.delegate.push('/orders/42');

    expect(router.controller.state.location.path, '/orders');
    expect(diagnostics.events.map((event) => event.type), [
      LmNavigationEventType.navigateStart,
      LmNavigationEventType.guardBlock,
      LmNavigationEventType.navigateCancel,
    ]);
    expect(diagnostics.events[1].result, LmNavigationResult.blocked);
    expect(diagnostics.events[1].error, 'locked');
    expect(diagnostics.events[2].result, LmNavigationResult.blocked);
  });

  test('LmRouter emits diagnostics for modal and branch navigation', () async {
    final diagnostics = LmRouterDiagnostics();
    final router = LmRouter(
      initialLocation: '/',
      diagnostics: diagnostics,
      branches: const [
        LmBranch(id: 'home', root: '/'),
        LmBranch(id: 'settings', root: '/settings'),
      ],
      routes: [
        LmRouteDefinition<void>(
          name: 'home',
          path: '/',
          transition: const LmTransition.none(),
        ),
        LmRouteDefinition<void>(
          name: 'settings',
          path: '/settings',
          transition: const LmTransition.none(),
        ),
      ],
      modalRoutes: [
        LmModalRouteDefinition<void>.sheet(
          name: 'actions',
          path: '/actions',
          build: (context, params) => throw UnimplementedError(),
          transition: const LmTransition.none(),
        ),
      ],
    );

    await router.present('/actions');
    await router.pop();
    await router.switchBranch('settings');

    expect(
      diagnostics.events.map((event) => event.type),
      containsAllInOrder([
        LmNavigationEventType.modalPush,
        LmNavigationEventType.modalPop,
        LmNavigationEventType.branchSwitch,
      ]),
    );
  });

  test('LmRouter emits navigateError when a guard throws', () async {
    final diagnostics = LmRouterDiagnostics();
    final router = LmRouter(
      initialLocation: '/orders',
      diagnostics: diagnostics,
      guards: [
        _AsyncGuard((context) {
          throw StateError('guard exploded');
        }),
      ],
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
    );

    await router.push('/orders/42');

    expect(router.location.path, '/orders');
    expect(
      diagnostics.events.map((event) => event.type),
      contains(LmNavigationEventType.navigateError),
    );
    expect(
      diagnostics.events
          .lastWhere(
            (event) => event.type == LmNavigationEventType.navigateError,
          )
          .error,
      isA<StateError>(),
    );
  });

  test('LmRouteStateCodec rejects params that are not JSON-safe', () {
    final state = LmNavigationState(
      activeBranchId: 'orders',
      branches: {
        'orders': LmBranchState(
          branchId: 'orders',
          semanticStack: [_node('orders', '/orders', params: Object())],
        ),
      },
      location: _location('/orders'),
    );

    expect(
      () => const LmRouteStateCodec().encode(state),
      throwsA(isA<LmRestoreException>()),
    );
  });
}

LmRouteNode _node(
  String name,
  String path, {
  Object? params,
  LmRouteChrome chrome = const LmRouteChrome(),
  LmDetailPolicy detailPolicy = LmDetailPolicy.pushOnCompact,
}) {
  return LmRouteNode(
    name: name,
    pathPattern: path,
    location: _location(path),
    params: params,
    query: const {},
    chrome: chrome,
    detailPolicy: detailPolicy,
  );
}

LmLocation _location(String path) => LmLocation.fromUri(Uri.parse(path));

final class _Guard implements LmGuard {
  const _Guard(this._canActivate);

  final LmGuardResult Function(LmGuardContext context) _canActivate;

  @override
  LmGuardResult canActivate(LmGuardContext context) => _canActivate(context);
}

final class _AsyncGuard implements LmGuard {
  const _AsyncGuard(this._canActivate);

  final Future<LmGuardResult> Function(LmGuardContext context) _canActivate;

  @override
  Future<LmGuardResult> canActivate(LmGuardContext context) {
    return _canActivate(context);
  }
}
