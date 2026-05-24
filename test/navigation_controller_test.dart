import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/src/core/lm_location.dart';
import 'package:lm_flutter_router/src/delegate/lm_navigation_controller.dart';
import 'package:lm_flutter_router/src/delegate/lm_navigation_transaction.dart';
import 'package:lm_flutter_router/src/state/lm_branch_state.dart';
import 'package:lm_flutter_router/src/state/lm_modal_node.dart';
import 'package:lm_flutter_router/src/state/lm_navigation_state.dart';
import 'package:lm_flutter_router/src/state/lm_route_node.dart';

void main() {
  group('LmNavigationController', () {
    test('pushes, replaces, and pops route nodes in the active branch', () {
      final controller = LmNavigationController(
        initialState: LmNavigationState(
          activeBranchId: 'home',
          branches: {
            'home': LmBranchState(
              branchId: 'home',
              semanticStack: [_node('home', '/')],
            ),
          },
          location: _location('/'),
        ),
      );

      controller.push(_node('detail', '/detail'));
      expect(_activeNames(controller), ['home', 'detail']);
      expect(controller.state.location, _location('/detail'));

      controller.replace(_node('edit', '/edit'));
      expect(_activeNames(controller), ['home', 'edit']);
      expect(controller.state.location, _location('/edit'));

      final didPop = controller.pop();
      expect(didPop, isTrue);
      expect(_activeNames(controller), ['home']);
      expect(controller.state.location, _location('/'));
    });

    test('push ignores duplicate top route nodes', () {
      final controller = LmNavigationController(
        initialState: LmNavigationState(
          activeBranchId: 'home',
          branches: {
            'home': LmBranchState(
              branchId: 'home',
              semanticStack: [_node('home', '/')],
            ),
          },
          location: _location('/'),
        ),
      );

      controller.push(_node('detail', '/detail'));
      final versionAfterFirstPush = controller.state.version;
      controller.push(_node('detail', '/detail'));

      expect(_activeNames(controller), ['home', 'detail']);
      expect(controller.state.location, _location('/detail'));
      expect(controller.state.version, versionAfterFirstPush);
    });

    test('push updates the top route when runtime extra changes', () {
      final firstExtra = Object();
      final secondExtra = Object();
      final controller = LmNavigationController(
        initialState: LmNavigationState(
          activeBranchId: 'home',
          branches: {
            'home': LmBranchState(
              branchId: 'home',
              semanticStack: [_node('home', '/')],
            ),
          },
          location: _location('/'),
        ),
      );

      controller.push(_node('detail', '/detail', extra: firstExtra));
      final versionAfterFirstPush = controller.state.version;
      controller.push(_node('detail', '/detail', extra: secondExtra));

      final top = controller.state.branches['home']!.semanticStack.last;
      expect(top.location.extra, same(secondExtra));
      expect(controller.state.location.extra, same(secondExtra));
      expect(controller.state.version, greaterThan(versionAfterFirstPush));
    });

    test('system back dismisses modal before popping route stack', () {
      final controller = LmNavigationController(
        initialState: LmNavigationState(
          activeBranchId: 'orders',
          branches: {
            'orders': LmBranchState(
              branchId: 'orders',
              semanticStack: [
                _node('orders', '/orders'),
                _node('detail', '/orders/42'),
              ],
            ),
          },
          location: _location('/orders/42/actions'),
          modalStack: [
            LmModalNode(
              name: 'actions',
              location: _location('/orders/42/actions'),
            ),
          ],
        ),
      );

      final first = controller.handleBack(
        source: LmNavigationSource.systemBack,
      );
      expect(first, LmBackResult.handled);
      expect(controller.state.modalStack, isEmpty);
      expect(_activeNames(controller), ['orders', 'detail']);

      final second = controller.handleBack(
        source: LmNavigationSource.systemBack,
      );
      expect(second, LmBackResult.handled);
      expect(_activeNames(controller), ['orders']);
      expect(controller.state.location, _location('/orders'));
    });

    test('suppressed system back is consumed once after gesture pop', () {
      final controller = LmNavigationController(
        initialState: LmNavigationState(
          activeBranchId: 'home',
          branches: {
            'home': LmBranchState(
              branchId: 'home',
              semanticStack: [_node('home', '/')],
            ),
          },
          location: _location('/'),
        ),
      );
      addTearDown(controller.dispose);

      controller.suppressNextSystemBack();

      expect(controller.isSystemBackSuppressed, isTrue);
      expect(controller.consumeSuppressedSystemBack(), isTrue);
      expect(controller.isSystemBackSuppressed, isFalse);
      expect(controller.consumeSuppressedSystemBack(), isFalse);
    });

    test('suppressed system back survives slow Android edge completion', () {
      final controller = LmNavigationController(
        initialState: LmNavigationState(
          activeBranchId: 'orders',
          branches: {
            'orders': LmBranchState(
              branchId: 'orders',
              semanticStack: [
                _node('orders', '/orders'),
                _node('detail', '/orders/42'),
              ],
            ),
          },
          location: _location('/orders/42'),
        ),
      );
      addTearDown(controller.dispose);

      controller.suppressNextSystemBack();
      controller.pop();

      expect(controller.state.location, _location('/orders'));
      expect(controller.consumeSuppressedSystemBack(), isTrue);
      expect(controller.consumeSuppressedSystemBack(), isFalse);
    });

    test('new navigation clears stale suppressed system back', () {
      final controller = LmNavigationController(
        initialState: LmNavigationState(
          activeBranchId: 'orders',
          branches: {
            'orders': LmBranchState(
              branchId: 'orders',
              semanticStack: [_node('orders', '/orders')],
            ),
          },
          location: _location('/orders'),
        ),
      );
      addTearDown(controller.dispose);

      controller.suppressNextSystemBack();
      controller.push(_node('detail', '/orders/42'));

      expect(controller.consumeSuppressedSystemBack(), isFalse);
      expect(controller.pop(), isTrue);
      expect(controller.state.location, _location('/orders'));
    });

    test('route navigation clears presented modal stack', () {
      final controller = LmNavigationController(
        initialState: LmNavigationState(
          activeBranchId: 'orders',
          branches: {
            'orders': LmBranchState(
              branchId: 'orders',
              semanticStack: [
                _node('orders', '/orders'),
                _node('detail', '/orders/42'),
              ],
            ),
          },
          location: _location('/orders/42/actions'),
          modalStack: [
            LmModalNode(
              name: 'actions',
              location: _location('/orders/42/actions'),
            ),
          ],
        ),
      );

      controller.go(_node('settings', '/settings'));

      expect(controller.state.modalStack, isEmpty);
      expect(controller.state.location, _location('/settings'));
    });

    test('switches branches while preserving each branch stack', () {
      final controller = LmNavigationController(
        initialState: LmNavigationState(
          activeBranchId: 'home',
          branches: {
            'home': LmBranchState(
              branchId: 'home',
              semanticStack: [_node('home', '/')],
            ),
            'settings': LmBranchState(
              branchId: 'settings',
              semanticStack: [_node('settings', '/settings')],
            ),
          },
          location: _location('/'),
        ),
      );

      controller.push(_node('homeDetail', '/home/detail'));
      controller.switchBranch('settings');
      expect(controller.state.activeBranchId, 'settings');
      expect(controller.state.location, _location('/settings'));

      controller.switchBranch('home');
      expect(controller.state.activeBranchId, 'home');
      expect(_activeNames(controller), ['home', 'homeDetail']);
      expect(controller.state.location, _location('/home/detail'));
    });

    test('switching branches clears presented modal stack', () {
      final controller = LmNavigationController(
        initialState: LmNavigationState(
          activeBranchId: 'home',
          branches: {
            'home': LmBranchState(
              branchId: 'home',
              semanticStack: [_node('home', '/')],
            ),
            'settings': LmBranchState(
              branchId: 'settings',
              semanticStack: [_node('settings', '/settings')],
            ),
          },
          location: _location('/actions'),
          modalStack: [
            LmModalNode(name: 'actions', location: _location('/actions')),
          ],
        ),
      );

      controller.switchBranch('settings');

      expect(controller.state.modalStack, isEmpty);
      expect(controller.state.location, _location('/settings'));
    });
  });

  test('goStack ignores identical stacks to avoid redundant rebuilds', () {
    final stack = [_node('orders', '/orders'), _node('detail', '/orders/42')];
    final controller = LmNavigationController(
      initialState: LmNavigationState(
        activeBranchId: 'orders',
        branches: {
          'orders': LmBranchState(branchId: 'orders', semanticStack: stack),
        },
        location: _location('/orders/42'),
      ),
    );
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    controller.goStack([
      _node('orders', '/orders'),
      _node('detail', '/orders/42'),
    ]);

    expect(notifications, 0);
    expect(controller.state.version, 0);
  });
}

List<String> _activeNames(LmNavigationController controller) {
  return controller
      .state
      .branches[controller.state.activeBranchId]!
      .semanticStack
      .map((node) => node.name)
      .toList();
}

LmRouteNode _node(String name, String path, {Object? extra}) {
  return LmRouteNode(
    name: name,
    pathPattern: path,
    location: _location(path, extra: extra),
    params: const NoParams(),
    query: const {},
  );
}

LmLocation _location(String path, {Object? extra}) =>
    LmLocation(path: path, extra: extra);

final class NoParams {
  const NoParams();
}
