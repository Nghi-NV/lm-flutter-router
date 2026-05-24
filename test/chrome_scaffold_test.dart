import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/src/chrome/lm_chrome_scaffold.dart';
import 'package:lm_flutter_router/src/chrome/lm_route_chrome.dart';
import 'package:lm_flutter_router/src/core/lm_location.dart';
import 'package:lm_flutter_router/src/delegate/lm_navigation_controller.dart';
import 'package:lm_flutter_router/src/state/lm_modal_node.dart';
import 'package:lm_flutter_router/src/state/lm_branch_state.dart';
import 'package:lm_flutter_router/src/state/lm_navigation_state.dart';
import 'package:lm_flutter_router/src/state/lm_route_node.dart';

void main() {
  testWidgets('LmChromeScaffold auto hides tabbar on push and shows on pop', (
    tester,
  ) async {
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

    await tester.pumpWidget(
      MaterialApp(
        home: LmChromeScaffold(
          controller: controller,
          body: const Text('Body'),
          bottomNavigationBar: const SizedBox(
            key: ValueKey('tabbar'),
            height: 56,
            child: Text('Tabs'),
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('tabbar'))).dy,
      lessThan(600),
    );

    controller.push(_node('detail', '/detail'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('tabbar')), findsNothing);

    controller.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('tabbar'))).dy,
      lessThan(600),
    );
  });

  testWidgets('LmChromeScaffold collapses tabbar layout space on detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    await tester.pumpWidget(
      MaterialApp(
        home: LmChromeScaffold(
          controller: controller,
          body: const ColoredBox(
            key: ValueKey('body'),
            color: Colors.red,
            child: SizedBox.expand(),
          ),
          bottomNavigationBar: const SizedBox(
            key: ValueKey('tabbar'),
            height: 80,
            child: Text('Tabs'),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('body'))).height, 520);

    controller.push(_node('detail', '/detail'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(const ValueKey('body'))).height, 600);
  });

  testWidgets('LmChromeScaffold honors route tabbar chrome metadata', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = LmNavigationController(
      initialState: LmNavigationState(
        activeBranchId: 'home',
        branches: {
          'home': LmBranchState(
            branchId: 'home',
            semanticStack: [
              _node(
                'home',
                '/',
                chrome: const LmRouteChrome(
                  tabBarVisibility: LmTabBarVisibility.hidden,
                ),
              ),
            ],
          ),
        },
        location: _location('/'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LmChromeScaffold(
          controller: controller,
          body: const SizedBox.expand(key: ValueKey('body')),
          bottomNavigationBar: const SizedBox(
            key: ValueKey('tabbar'),
            height: 80,
            child: Text('Tabs'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('body'))).height, 600);
    expect(find.byKey(const ValueKey('tabbar')), findsNothing);

    controller.push(
      _node(
        'detail',
        '/detail',
        chrome: const LmRouteChrome(
          tabBarVisibility: LmTabBarVisibility.always,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(const ValueKey('body'))).height, 520);
  });

  testWidgets('LmChromeScaffold hides tabbar while router modal is open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    await tester.pumpWidget(
      MaterialApp(
        home: LmChromeScaffold(
          controller: controller,
          body: const SizedBox.expand(key: ValueKey('body')),
          bottomNavigationBar: const SizedBox(
            key: ValueKey('tabbar'),
            height: 80,
            child: Text('Tabs'),
          ),
        ),
      ),
    );

    controller.present(
      LmModalNode(name: 'dialog', location: _location('/dialog')),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tabbar')), findsNothing);
    expect(tester.getSize(find.byKey(const ValueKey('body'))).height, 600);
  });

  testWidgets('LmChromeScaffold can keep tabbar behind router modals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    await tester.pumpWidget(
      MaterialApp(
        home: LmChromeScaffold(
          controller: controller,
          hideBottomBarWhenModalOpen: false,
          body: const SizedBox.expand(key: ValueKey('body')),
          bottomNavigationBar: const SizedBox(
            key: ValueKey('tabbar'),
            height: 80,
            child: Text('Tabs'),
          ),
        ),
      ),
    );

    controller.present(
      LmModalNode(name: 'dialog', location: _location('/dialog')),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tabbar')), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('body'))).height, 520);
  });

  testWidgets('LmChromeScaffold edge swipe pops the active stack', (
    tester,
  ) async {
    final controller = LmNavigationController(
      initialState: LmNavigationState(
        activeBranchId: 'home',
        branches: {
          'home': LmBranchState(
            branchId: 'home',
            semanticStack: [_node('home', '/'), _node('detail', '/detail')],
          ),
        },
        location: _location('/detail'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LmChromeScaffold(
          controller: controller,
          edgeBackGestureEnabled: true,
          edgeBackGesturePlatforms: TargetPlatform.values.toSet(),
          body: const SizedBox.expand(child: Text('Detail')),
        ),
      ),
    );

    await tester.dragFrom(const Offset(2, 300), const Offset(140, 0));
    await tester.pumpAndSettle();

    expect(
      controller.state.branches['home']!.semanticStack.map((node) => node.name),
      ['home'],
    );
  });

  testWidgets('LmChromeScaffold ignores horizontal drags away from the edge', (
    tester,
  ) async {
    final controller = LmNavigationController(
      initialState: LmNavigationState(
        activeBranchId: 'home',
        branches: {
          'home': LmBranchState(
            branchId: 'home',
            semanticStack: [_node('home', '/'), _node('detail', '/detail')],
          ),
        },
        location: _location('/detail'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LmChromeScaffold(
          controller: controller,
          edgeBackGestureEnabled: true,
          edgeBackGesturePlatforms: TargetPlatform.values.toSet(),
          body: const SizedBox.expand(child: Text('Detail')),
        ),
      ),
    );

    await tester.dragFrom(const Offset(70, 300), const Offset(220, 0));
    await tester.pumpAndSettle();

    expect(
      controller.state.branches['home']!.semanticStack.map((node) => node.name),
      ['home', 'detail'],
    );
  });

  testWidgets('LmChromeScaffold edge gesture can start in the header area', (
    tester,
  ) async {
    final controller = LmNavigationController(
      initialState: LmNavigationState(
        activeBranchId: 'home',
        branches: {
          'home': LmBranchState(
            branchId: 'home',
            semanticStack: [_node('home', '/'), _node('detail', '/detail')],
          ),
        },
        location: _location('/detail'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LmChromeScaffold(
          controller: controller,
          edgeBackGestureEnabled: true,
          edgeBackGesturePlatforms: TargetPlatform.values.toSet(),
          body: const SizedBox.expand(child: Text('Detail')),
        ),
      ),
    );

    await tester.dragFrom(const Offset(2, 24), const Offset(140, 0));
    await tester.pumpAndSettle();

    expect(
      controller.state.branches['home']!.semanticStack.map((node) => node.name),
      ['home'],
    );
  });

  testWidgets('LmChromeScaffold edge gesture moves content with the drag', (
    tester,
  ) async {
    final controller = LmNavigationController(
      initialState: LmNavigationState(
        activeBranchId: 'home',
        branches: {
          'home': LmBranchState(
            branchId: 'home',
            semanticStack: [_node('home', '/'), _node('detail', '/detail')],
          ),
        },
        location: _location('/detail'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LmChromeScaffold(
          controller: controller,
          edgeBackGestureEnabled: true,
          edgeBackGesturePlatforms: TargetPlatform.values.toSet(),
          body: const SizedBox.expand(child: Text('Detail')),
        ),
      ),
    );

    final gesture = await tester.startGesture(const Offset(2, 300));
    await gesture.moveBy(const Offset(48, 0));
    await tester.pump();

    final contentTransform = tester
        .widgetList<Transform>(find.byType(Transform))
        .firstWhere((transform) => transform.transform.storage[12] > 0);
    expect(contentTransform.transform.storage[12], closeTo(48, 0.001));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('LmChromeScaffold lets Android system edge back own the edge', (
    tester,
  ) async {
    final controller = LmNavigationController(
      initialState: LmNavigationState(
        activeBranchId: 'home',
        branches: {
          'home': LmBranchState(
            branchId: 'home',
            semanticStack: [_node('home', '/'), _node('detail', '/detail')],
          ),
        },
        location: _location('/detail'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LmChromeScaffold(
          controller: controller,
          edgeBackGestureEnabled: true,
          edgeBackGesturePlatforms: const {},
          body: const SizedBox.expand(child: Text('Detail')),
        ),
      ),
    );

    await tester.dragFrom(const Offset(2, 300), const Offset(220, 0));
    await tester.pumpAndSettle();

    expect(
      controller.state.branches['home']!.semanticStack.map((node) => node.name),
      ['home', 'detail'],
    );
  });

  testWidgets(
    'LmChromeScaffold lets Android route gestures own the edge by default',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
      });
      final controller = LmNavigationController(
        initialState: LmNavigationState(
          activeBranchId: 'home',
          branches: {
            'home': LmBranchState(
              branchId: 'home',
              semanticStack: [_node('home', '/'), _node('detail', '/detail')],
            ),
          },
          location: _location('/detail'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LmChromeScaffold(
            controller: controller,
            edgeBackGestureEnabled: true,
            body: const SizedBox.expand(child: Text('Detail')),
          ),
        ),
      );

      await tester.dragFrom(const Offset(2, 300), const Offset(140, 0));
      await tester.pumpAndSettle();

      expect(
        controller.state.branches['home']!.semanticStack.map(
          (node) => node.name,
        ),
        ['home', 'detail'],
      );
      debugDefaultTargetPlatformOverride = null;
    },
  );
}

LmRouteNode _node(
  String name,
  String path, {
  LmRouteChrome chrome = const LmRouteChrome(),
}) {
  return LmRouteNode(
    name: name,
    pathPattern: path,
    location: _location(path),
    params: null,
    query: const {},
    chrome: chrome,
  );
}

LmLocation _location(String path) => LmLocation(path: path);
