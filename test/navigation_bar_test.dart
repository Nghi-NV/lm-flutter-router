import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/src/chrome/lm_navigation_bar.dart';
import 'package:lm_flutter_router/src/chrome/lm_route_chrome.dart';
import 'package:lm_flutter_router/src/core/lm_location.dart';
import 'package:lm_flutter_router/src/delegate/lm_navigation_controller.dart';
import 'package:lm_flutter_router/src/state/lm_branch_state.dart';
import 'package:lm_flutter_router/src/state/lm_navigation_state.dart';
import 'package:lm_flutter_router/src/state/lm_route_node.dart';

void main() {
  testWidgets('LmNavigationBar animates title and back affordance from stack', (
    tester,
  ) async {
    final controller = LmNavigationController(
      initialState: LmNavigationState(
        activeBranchId: 'home',
        branches: {
          'home': LmBranchState(
            branchId: 'home',
            semanticStack: [_node('home', '/', title: 'Home')],
          ),
        },
        location: _location('/'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            LmNavigationBar(controller: controller),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    expect(tester.getTopLeft(find.text('Home')).dx, lessThanOrEqualTo(24));

    controller.push(_node('detail', '/detail', title: 'Detail'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Detail'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('LmNavigationBar exposes accessible back semantics', (
    tester,
  ) async {
    final controller = LmNavigationController(
      initialState: LmNavigationState(
        activeBranchId: 'home',
        branches: {
          'home': LmBranchState(
            branchId: 'home',
            semanticStack: [
              _node('home', '/', title: 'Home'),
              _node('detail', '/detail', title: 'Detail'),
            ],
          ),
        },
        location: _location('/detail'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            LmNavigationBar(controller: controller),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(
      tester.semantics.simulatedAccessibilityTraversal(),
      contains(isSemantics(label: 'Back', isButton: true, isEnabled: true)),
    );
  }, semanticsEnabled: true);

  testWidgets('LmNavigationBar honors route back button chrome metadata', (
    tester,
  ) async {
    final controller = LmNavigationController(
      initialState: LmNavigationState(
        activeBranchId: 'home',
        branches: {
          'home': LmBranchState(
            branchId: 'home',
            semanticStack: [
              _node('home', '/', title: 'Home'),
              _node(
                'detail',
                '/detail',
                title: 'Detail',
                chrome: const LmRouteChrome(showBackButton: false),
              ),
            ],
          ),
        },
        location: _location('/detail'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            LmNavigationBar(controller: controller),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );

    expect(find.text('Detail'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
  });
}

LmRouteNode _node(
  String name,
  String path, {
  required String title,
  LmRouteChrome chrome = const LmRouteChrome(),
}) {
  return LmRouteNode(
    name: name,
    pathPattern: path,
    location: _location(path),
    params: title,
    query: const {},
    chrome: chrome,
  );
}

LmLocation _location(String path) => LmLocation(path: path);
