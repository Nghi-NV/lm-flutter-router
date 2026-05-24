import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/src/adaptive/lm_adaptive_policy.dart';
import 'package:lm_flutter_router/src/adaptive/lm_branch.dart';
import 'package:lm_flutter_router/src/adaptive/lm_detail_policy.dart';
import 'package:lm_flutter_router/src/adaptive/lm_layout_projector.dart';
import 'package:lm_flutter_router/src/chrome/lm_route_chrome.dart';
import 'package:lm_flutter_router/src/core/lm_location.dart';
import 'package:lm_flutter_router/src/state/lm_branch_state.dart';
import 'package:lm_flutter_router/src/state/lm_navigation_state.dart';
import 'package:lm_flutter_router/src/state/lm_route_node.dart';

void main() {
  group('LmBreakpointPolicy', () {
    test('resolves default layout modes from width', () {
      const policy = LmBreakpointPolicy();

      expect(policy.resolve(599), LmLayoutMode.compact);
      expect(policy.resolve(600), LmLayoutMode.medium);
      expect(policy.resolve(839), LmLayoutMode.medium);
      expect(policy.resolve(840), LmLayoutMode.expanded);
    });

    test('supports custom compact and expanded breakpoints', () {
      const policy = LmBreakpointPolicy(
        compactMaxWidth: 500,
        expandedMinWidth: 900,
      );

      expect(policy.resolve(499), LmLayoutMode.compact);
      expect(policy.resolve(500), LmLayoutMode.medium);
      expect(policy.resolve(899), LmLayoutMode.medium);
      expect(policy.resolve(900), LmLayoutMode.expanded);
    });
  });

  group('LmLayoutProjector', () {
    final orders = routeNode('orders');
    final detail = routeNode(
      'orderDetail',
      detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
    );
    final item = routeNode(
      'orderItem',
      detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
    );

    final state = LmNavigationState(
      activeBranchId: 'orders',
      branches: {
        'orders': LmBranchState(
          branchId: 'orders',
          semanticStack: [orders, detail, item],
        ),
      },
      location: LmLocation(path: '/orders/42/items/9'),
    );

    test('compact projection preserves semantic stack in active branch', () {
      const projector = LmDefaultLayoutProjector();

      final tree = projector.project(state, LmLayoutMode.compact);

      expect(tree.kind, LmRenderedTreeKind.compactStack);
      expect(tree.activeBranchId, 'orders');
      expect(tree.primaryStack, isEmpty);
      expect(tree.secondaryStack, isEmpty);
      expect(tree.compactStack.map((node) => node.name), [
        'orders',
        'orderDetail',
        'orderItem',
      ]);
    });

    test(
      'expanded projection keeps root primary and detail routes secondary',
      () {
        const projector = LmDefaultLayoutProjector();

        final tree = projector.project(state, LmLayoutMode.expanded);

        expect(tree.kind, LmRenderedTreeKind.expandedSplit);
        expect(tree.activeBranchId, 'orders');
        expect(tree.compactStack, isEmpty);
        expect(tree.primaryStack.map((node) => node.name), ['orders']);
        expect(tree.secondaryStack.map((node) => node.name), [
          'orderDetail',
          'orderItem',
        ]);
      },
    );

    test('expanded projection keeps modal detail routes out of panes', () {
      final modalDetail = routeNode(
        'modalDetail',
        detailPolicy: LmDetailPolicy.modalOnExpanded,
      );
      final state = LmNavigationState(
        activeBranchId: 'orders',
        branches: {
          'orders': LmBranchState(
            branchId: 'orders',
            semanticStack: [orders, detail, modalDetail],
          ),
        },
        location: LmLocation(path: '/modalDetail'),
      );

      final tree = const LmDefaultLayoutProjector().project(
        state,
        LmLayoutMode.expanded,
      );

      expect(tree.primaryStack.map((node) => node.name), ['orders']);
      expect(tree.secondaryStack.map((node) => node.name), ['orderDetail']);
      expect(tree.overlayStack, isEmpty);
      expect(tree.modalStack.map((node) => node.name), ['modalDetail']);
    });
  });

  group('chrome metadata', () {
    test('tabbar visibility defaults to inherited and can be overridden', () {
      const defaultChrome = LmRouteChrome();
      const hiddenChrome = LmRouteChrome(
        tabBarVisibility: LmTabBarVisibility.hidden,
      );

      expect(defaultChrome.tabBarVisibility, LmTabBarVisibility.inherited);
      expect(hiddenChrome.tabBarVisibility, LmTabBarVisibility.hidden);
    });
  });

  group('branch metadata', () {
    test('branch switch policy defaults to preserveStack', () {
      const branch = LmBranch(id: 'orders', root: 'ordersRoot', routes: []);

      expect(branch.switchPolicy, LmBranchSwitchPolicy.preserveStack);
    });
  });
}

LmRouteNode routeNode(
  String name, {
  LmDetailPolicy detailPolicy = LmDetailPolicy.pushOnCompact,
}) {
  return LmRouteNode(
    name: name,
    pathPattern: '/$name',
    location: LmLocation(path: '/$name'),
    params: const NoParams(),
    query: const {},
    detailPolicy: detailPolicy,
  );
}

final class NoParams {
  const NoParams();
}
