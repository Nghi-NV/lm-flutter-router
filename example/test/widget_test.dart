import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router_example/src/field_orders_app.dart';

void main() {
  testWidgets('example app renders the field orders dashboard', (tester) async {
    await tester.pumpWidget(const FieldOrdersApp());
    await tester.pumpAndSettle();

    expect(find.text('Field Orders'), findsWidgets);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Priority Orders'), findsOneWidget);
  });

  testWidgets('example normalizes external deep links to order detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FieldOrdersApp(
        initialLocation: 'https://field-orders.example/o/1042',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order #1042'), findsWidgets);
    expect(find.text('Order detail'), findsOneWidget);
  });

  testWidgets('example renders a not-found screen for unknown links', (
    tester,
  ) async {
    await tester.pumpWidget(const FieldOrdersApp(initialLocation: '/unknown'));
    await tester.pumpAndSettle();

    expect(find.text('No route for /unknown'), findsOneWidget);
  });

  testWidgets('router lab exposes navigation and animation demos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FieldOrdersApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lab').last);
    await tester.pumpAndSettle();

    expect(find.text('Router Lab'), findsWidgets);
    expect(find.text('Implementation Reference'), findsOneWidget);
    expect(find.text('Go to Orders'), findsOneWidget);
    expect(find.text('Push Cupertino'), findsOneWidget);
    expect(find.text('Replace with Fade'), findsOneWidget);
    expect(find.text('Pop current route'), findsOneWidget);
    expect(find.text('Open Heavy View'), findsOneWidget);
    expect(find.text('iOS 26 Glass Lab'), findsOneWidget);
    expect(find.text('None'), findsOneWidget);
    expect(find.text('Fade'), findsOneWidget);
    expect(find.text('Slide left'), findsOneWidget);
    expect(find.text('Slide right'), findsOneWidget);
    expect(find.text('Slide top'), findsOneWidget);
    expect(find.text('Slide bottom'), findsOneWidget);
    expect(find.text('Cupertino'), findsOneWidget);
    expect(find.text('Fullscreen modal'), findsOneWidget);
    expect(find.text('iOS 15 sheet'), findsOneWidget);
    expect(find.text('Scale'), findsOneWidget);
    expect(find.text('Hero'), findsOneWidget);

    await tester.tap(find.text('Push Cupertino'));
    await tester.pumpAndSettle();

    expect(find.text('Cupertino detail'), findsOneWidget);
    expect(find.byType(CupertinoTabBar), findsNothing);

    await tester.tap(find.text('Pop back to Lab'));
    await tester.pumpAndSettle();

    expect(find.text('Cupertino detail'), findsNothing);
    expect(find.text('Router Lab'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Dialog'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Dialog'), findsOneWidget);
    expect(find.text('Cupertino dialog'), findsOneWidget);
    expect(find.text('Cupertino sheet'), findsOneWidget);
    expect(find.text('Cupertino action sheet'), findsOneWidget);
    expect(find.text('Fullscreen dialog'), findsOneWidget);
    expect(find.text('Popover'), findsOneWidget);

    await tester.ensureVisible(find.text('Cupertino action sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cupertino action sheet'));
    await _pumpModalTransition(tester);

    expect(find.text('Cupertino action sheet presentation'), findsOneWidget);
    expect(find.textContaining('frosted iOS popup material'), findsOneWidget);
  });

  testWidgets('implementation reference documents copyable router patterns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const FieldOrdersApp(initialLocation: '/lab/reference'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Implementation Reference'), findsWidgets);
    expect(find.text('Minimal app setup'), findsOneWidget);
    expect(find.text('Typed route params'), findsOneWidget);
    expect(
      find.textContaining('WidgetsFlutterBinding.ensureInitialized'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Branches and split view'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Branches and split view'), findsOneWidget);
    expect(find.textContaining('LmAdaptiveRouterSplitView'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Router-owned modals'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Router-owned modals'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Guards and return-to login'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Guards and return-to login'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Deep links and URL migration'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Deep links and URL migration'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Performance reference'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Performance reference'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Action sheet'),
      -360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Action sheet'));
    await _pumpModalTransition(tester);

    expect(find.text('Mark delivered'), findsOneWidget);
  });

  testWidgets('router lab exposes iOS 15 sheet as a page transition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FieldOrdersApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lab').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('iOS 15 sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('iOS 15 sheet'));
    await _pumpModalTransition(tester);

    expect(find.text('iOS 15 sheet page'), findsOneWidget);
    expect(find.textContaining('single sheet page transition'), findsOneWidget);
    expect(find.textContaining('Drag down slowly'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('iOS 15 sheet page')).dy,
      inInclusiveRange(60, 96),
    );
    final pushNestedSheet = find.widgetWithText(
      OutlinedButton,
      'Push page above sheet',
    );
    await tester.ensureVisible(pushNestedSheet);
    await tester.pumpAndSettle();
    await tester.tap(pushNestedSheet);
    await tester.pumpAndSettle();
    expect(find.text('Nested sheet page'), findsOneWidget);
    expect(
      find.textContaining('inside the same sheet container'),
      findsOneWidget,
    );

    final gesture = await tester.startGesture(const Offset(4, 180));
    await gesture.moveBy(const Offset(260, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('iOS 15 sheet page'), findsOneWidget);
    expect(find.text('Nested sheet page'), findsNothing);
  });

  testWidgets('router lab opens nested iOS sheet page from deep link', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const FieldOrdersApp(initialLocation: '/lab/cupertino-sheet/nested'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nested sheet page'), findsOneWidget);
    expect(
      find.textContaining('inside the same sheet container'),
      findsOneWidget,
    );

    final gesture = await tester.startGesture(const Offset(4, 180));
    await gesture.moveBy(const Offset(260, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('iOS 15 sheet page'), findsOneWidget);
    expect(find.text('Nested sheet page'), findsNothing);
  });

  testWidgets('router lab heavy view builds a dense route target', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const FieldOrdersApp(initialLocation: '/lab/heavy'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heavy View'), findsWidgets);
    expect(find.text('Lumi Music'), findsOneWidget);
    expect(find.text('Made for this route'), findsOneWidget);
    expect(find.text('Heavy blur playlists'), findsOneWidget);
    expect(find.text('Night Route'), findsOneWidget);
    expect(find.text('Night Route 1'), findsOneWidget);
    expect(find.byType(CupertinoTabBar), findsNothing);
  });

  testWidgets('router lab glass view exposes visible iOS 26 glass surfaces', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const FieldOrdersApp(initialLocation: '/lab/glass'),
    );
    await tester.pumpAndSettle();

    expect(find.text('iOS 26 Glass Lab'), findsWidgets);
    expect(find.text('Prominent panel'), findsOneWidget);
    expect(find.text('Floating glass bar'), findsOneWidget);
    expect(find.text('Glass action sheet'), findsOneWidget);
    expect(find.byType(CupertinoTabBar), findsNothing);
  });

  testWidgets('top app bar title aligns left when there is no back button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FieldOrdersApp());
    await tester.pumpAndSettle();

    final titleLeft = tester.getTopLeft(find.text('Field Orders').first).dx;
    expect(titleLeft, lessThanOrEqualTo(24));
  });

  testWidgets('expanded layout keeps shell and list visible on detail push', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const FieldOrdersApp(initialLocation: '/orders/1042'),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Field Orders'), findsWidgets);
    expect(find.text('Orders'), findsWidgets);
    expect(find.textContaining('Minh Tran #1042'), findsWidgets);
    expect(find.text('Order #1042'), findsOneWidget);
    expect(find.text('Order detail'), findsOneWidget);
  });

  testWidgets('expanded split detail has pane back button that pops detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const FieldOrdersApp(initialLocation: '/orders/1042'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order #1042'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Order #1042'), findsNothing);
    expect(find.textContaining('Minh Tran #1042'), findsWidgets);
  });

  testWidgets(
    'expanded direct action sheet deep link shows modal over detail',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const FieldOrdersApp(initialLocation: '/orders/1042/actions'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order #1042'), findsWidgets);
      expect(find.text('Mark delivered'), findsOneWidget);
    },
  );

  testWidgets(
    'expanded layout handles rapid detail item selection without flicker',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const FieldOrdersApp(initialLocation: '/orders'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Minh Tran #1042').first);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.textContaining('An Pham #1047').first);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.textContaining('Minh Tran #1042').first);
      await tester.pumpAndSettle();

      expect(find.text('Field Orders'), findsWidgets);
      expect(find.textContaining('Minh Tran #1042'), findsWidgets);
      expect(find.textContaining('An Pham #1047'), findsWidgets);
      expect(find.text('Order #1042'), findsOneWidget);
      expect(find.text('Order #1047'), findsNothing);
    },
  );

  testWidgets('compact back control pops detail and restores bottom tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FieldOrdersApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Minh Tran #1042').first);
    await tester.pumpAndSettle();

    expect(find.text('Order #1042'), findsOneWidget);
    expect(find.byType(CupertinoTabBar), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Order #1042'), findsNothing);
    expect(find.byType(CupertinoTabBar).hitTestable(), findsOneWidget);
    expect(find.text('Orders'), findsWidgets);
  });

  testWidgets(
    'compact iOS-style edge swipe pops detail and restores bottom tabs',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const FieldOrdersApp(initialLocation: '/orders/1042'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order #1042'), findsOneWidget);
      expect(find.byType(CupertinoTabBar), findsNothing);

      await tester.dragFrom(
        const Offset(2, 420),
        const Offset(360, 0),
        touchSlopY: 0,
      );
      await tester.pumpAndSettle();

      expect(find.text('Order #1042'), findsNothing);
      expect(find.byType(CupertinoTabBar).hitTestable(), findsOneWidget);
      expect(find.text('Orders'), findsWidgets);
    },
  );

  testWidgets('Android system back pops detail before exiting the app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const FieldOrdersApp(initialLocation: '/orders/1042'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order #1042'), findsOneWidget);
    expect(find.byType(CupertinoTabBar), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Order #1042'), findsNothing);
    expect(find.byType(CupertinoTabBar).hitTestable(), findsOneWidget);
    expect(find.text('Orders'), findsWidgets);
  });

  testWidgets('order action sheet is presented above the app chrome', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FieldOrdersApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Minh Tran #1042').first);
    await tester.pumpAndSettle();
    final headerTopBeforeSheet = tester
        .getTopLeft(find.text('Order detail'))
        .dy;
    await tester.tap(find.text('Order actions'));
    await _pumpModalTransition(tester);

    expect(find.text('Mark delivered'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Mark delivered')).dy, greaterThan(420));
    expect(
      tester.getTopLeft(find.text('Order detail')).dy,
      closeTo(headerTopBeforeSheet, 8),
    );
    await tester.tapAt(Offset(200, headerTopBeforeSheet + 10));
    await _pumpModalTransition(tester);
    expect(find.text('Mark delivered'), findsNothing);
  });

  testWidgets('expanded order action sheet keeps split content mounted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FieldOrdersApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Minh Tran #1042').first);
    await tester.pumpAndSettle();
    expect(find.text('Order #1042'), findsOneWidget);

    await tester.tap(find.text('Order actions'));
    await _pumpModalTransition(tester);

    expect(find.text('Mark delivered'), findsOneWidget);
    expect(find.text('Order #1042'), findsWidgets);
    expect(find.textContaining('Minh Tran #1042'), findsWidgets);
  });

  testWidgets('system back dismisses action sheet before popping detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FieldOrdersApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Minh Tran #1042').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Order actions'));
    await _pumpModalTransition(tester);

    await tester.binding.handlePopRoute();
    await _pumpModalTransition(tester);

    expect(find.text('Mark delivered'), findsNothing);
    expect(find.text('Order #1042'), findsOneWidget);
    expect(find.text('Order detail'), findsOneWidget);
  });

  testWidgets('action sheet link dismisses and navigates to the line item', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FieldOrdersApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Minh Tran #1042').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Order actions'));
    await _pumpModalTransition(tester);
    await tester.tap(find.text('Open shared item link'));
    await _pumpModalTransition(tester);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Open shared item link'), findsNothing);
    expect(find.text('Outdoor camera kit'), findsOneWidget);
    expect(find.text('Line item'), findsOneWidget);
  });

  testWidgets('router-owned bottom sheet is presented from action sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FieldOrdersApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Minh Tran #1042').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Order actions'));
    await _pumpModalTransition(tester);
    await tester.tap(find.text('Reschedule'));
    await _pumpModalTransition(tester);
    await tester.pump(const Duration(milliseconds: 600));
    await _pumpModalTransition(tester);

    expect(find.text('Choose a new window'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Choose a new window')).dy,
      greaterThan(420),
    );
    expect(find.text('Order detail'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _pumpModalTransition(tester);

    expect(find.text('Choose a new window'), findsNothing);
    expect(find.text('Order #1042'), findsOneWidget);
  });

  testWidgets(
    'example exposes semantics for navigation and modal controls',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const FieldOrdersApp());
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Field Orders'), findsWidgets);
      expect(find.bySemanticsLabel('Orders'), findsWidgets);
      expect(find.bySemanticsLabel('Lab'), findsWidgets);

      await tester.tap(find.text('Orders').last);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Minh Tran #1042').first);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(find.bySemanticsLabel('Order actions'), findsOneWidget);

      await tester.tap(find.text('Order actions'));
      await _pumpModalTransition(tester);

      expect(find.bySemanticsLabel('Mark delivered'), findsOneWidget);
      expect(find.bySemanticsLabel('Reschedule'), findsOneWidget);
      expect(find.bySemanticsLabel('Cancel'), findsOneWidget);
      expect(
        tester.semantics.simulatedAccessibilityTraversal(),
        containsAll(<Matcher>[isSemantics(label: 'Cancel')]),
      );
    },
    semanticsEnabled: true,
  );

  testWidgets('example supports basic keyboard focus traversal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FieldOrdersApp());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, isNotNull);
  });
}

Future<void> _pumpModalTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1000));
}
