import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/lm_flutter_router.dart';

void main() {
  testWidgets('LmAdaptiveChromeScaffold uses bottom bar on compact layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = _router();

    await tester.pumpWidget(
      MaterialApp(
        home: LmAdaptiveChromeScaffold(
          router: router,
          bottomBarBuilder: (context, router) => const SizedBox(
            key: ValueKey('bottom-bar'),
            height: 64,
            child: Text('Bottom tabs'),
          ),
          sidebarBuilder: (context, router) => const Text('Tablet sidebar'),
          child: const Text('Body'),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('bottom-bar')), findsOneWidget);
    expect(find.text('Tablet sidebar'), findsNothing);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('LmAdaptiveChromeScaffold uses sidebar on expanded layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = _router();

    await tester.pumpWidget(
      MaterialApp(
        home: LmAdaptiveChromeScaffold(
          router: router,
          sidebarWidth: 280,
          bottomBarBuilder: (context, router) => const Text('Bottom tabs'),
          sidebarBuilder: (context, router) => const SizedBox(
            key: ValueKey('sidebar'),
            child: Text('Tablet sidebar'),
          ),
          child: const SizedBox.expand(key: ValueKey('content')),
        ),
      ),
    );

    expect(find.text('Bottom tabs'), findsNothing);
    expect(find.byKey(const ValueKey('sidebar')), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('sidebar'))).width, 280);
    expect(find.byKey(const ValueKey('content')), findsOneWidget);
  });

  testWidgets('LmAdaptiveChromeScaffold uses sidebar on medium layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = _router();

    await tester.pumpWidget(
      MaterialApp(
        home: LmAdaptiveChromeScaffold(
          router: router,
          sidebarOnMedium: true,
          bottomBarBuilder: (context, router) => const Text('Bottom tabs'),
          sidebarBuilder: (context, router) => const Text('Tablet sidebar'),
          mediumContentBuilder: (context, child) => Column(
            children: [
              const Text('Tablet header'),
              Expanded(child: child),
            ],
          ),
          child: const Text('Body'),
        ),
      ),
    );

    expect(find.text('Bottom tabs'), findsNothing);
    expect(find.text('Tablet sidebar'), findsOneWidget);
    expect(find.text('Tablet header'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('LmAdaptiveChromeScaffold lets expanded content be wrapped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = _router();

    await tester.pumpWidget(
      MaterialApp(
        home: LmAdaptiveChromeScaffold(
          router: router,
          sidebarBuilder: (context, router) => const Text('Sidebar'),
          expandedContentBuilder: (context, child) => Column(
            children: [
              const Text('Custom tablet header'),
              Expanded(child: child),
            ],
          ),
          child: const Text('Body'),
        ),
      ),
    );

    expect(find.text('Custom tablet header'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('LmAdaptiveChromeScaffold can glass-wrap custom bottom chrome', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = _router();

    await tester.pumpWidget(
      MaterialApp(
        home: LmAdaptiveChromeScaffold(
          router: router,
          glass: const LmGlassThemeData.liquid(),
          bottomBarBuilder: (context, router) => const SizedBox(
            key: ValueKey('bottom-bar'),
            height: 64,
            child: Text('Bottom tabs'),
          ),
          child: const Text('Body'),
        ),
      ),
    );

    expect(find.byType(LmGlassSurface), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-bar')), findsOneWidget);
  });

  testWidgets('LmAdaptiveChromeScaffold can glass-wrap custom sidebar chrome', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = _router();

    await tester.pumpWidget(
      MaterialApp(
        home: LmAdaptiveChromeScaffold(
          router: router,
          glass: const LmGlassThemeData.liquid(),
          sidebarBuilder: (context, router) => const SizedBox(
            key: ValueKey('sidebar'),
            child: Text('Tablet sidebar'),
          ),
          child: const Text('Body'),
        ),
      ),
    );

    expect(find.byType(LmGlassSurface), findsOneWidget);
    expect(find.byKey(const ValueKey('sidebar')), findsOneWidget);
  });
}

LmRouter _router() {
  return LmRouter(
    initialLocation: '/',
    routes: [
      LmRouteDefinition<void>(
        name: 'home',
        path: '/',
        build: (context, params) => const Text('Home'),
      ),
    ],
  );
}
