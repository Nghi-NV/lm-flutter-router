import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/lm_flutter_router.dart';

void main() {
  testWidgets('LmRouterScope exposes ergonomic context navigation', (
    tester,
  ) async {
    final router = LmRouter(
      initialLocation: '/',
      routes: [
        LmRouteDefinition<void>(
          name: 'home',
          path: '/',
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Home'),
        ),
        LmRouteDefinition<void>(
          name: 'detail',
          path: '/detail',
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Detail'),
        ),
        LmRouteDefinition<void>(
          name: 'settings',
          path: '/settings',
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Settings'),
        ),
      ],
      modalRoutes: [
        LmModalRouteDefinition<void>(
          name: 'actions',
          path: '/actions',
          presentation: const LmModalPresentation.actionSheet(
            transition: LmTransition.none(),
          ),
          build: (context, params) => const Text('Actions'),
        ),
      ],
    );

    BuildContext? scopedContext;
    await tester.pumpWidget(
      LmRouterScope(
        router: router,
        child: Builder(
          builder: (context) {
            scopedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final context = scopedContext!;
    expect(context.lm.router, same(router));

    await context.lm.push('/detail');
    expect(router.controller.state.location.path, '/detail');

    await context.lm.replace('/settings');
    expect(router.controller.state.location.path, '/settings');

    await context.lm.go('/');
    expect(router.controller.state.location.path, '/');

    await context.lm.present('/actions');
    expect(router.controller.state.modalStack.single.location.path, '/actions');

    expect(await context.lm.pop(), isTrue);
    expect(router.controller.state.modalStack, isEmpty);
  });

  testWidgets('LmRouterScope reports a useful error when missing', (
    tester,
  ) async {
    late BuildContext unscopedContext;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          unscopedContext = context;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(() => unscopedContext.lm, throwsA(isA<StateError>()));
  });

  testWidgets('unowned scopedBuilder does not dispose app-owned routers', (
    tester,
  ) async {
    final router = LmRouter(
      initialLocation: '/',
      routes: [
        LmRouteDefinition<void>(
          name: 'home',
          path: '/',
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Home'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router.config,
        builder: router.unownedScopedBuilder(),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());

    await router.go('/');
    expect(router.location.path, '/');

    router.dispose();
  });

  testWidgets('scopeBuilder can opt out of router disposal with a named flag', (
    tester,
  ) async {
    final router = LmRouter(
      initialLocation: '/',
      routes: [
        LmRouteDefinition<void>(
          name: 'home',
          path: '/',
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Home'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router.config,
        builder: router.scopeBuilder(autoDispose: false),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());

    await router.goPath('/');
    expect(router.location.path, '/');

    router.dispose();
  });

  testWidgets('path aliases make string navigation intent explicit', (
    tester,
  ) async {
    final router = LmRouter(
      initialLocation: '/',
      routes: [
        LmRouteDefinition<void>(
          name: 'home',
          path: '/',
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Home'),
        ),
        LmRouteDefinition<void>(
          name: 'detail',
          path: '/detail',
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Detail'),
        ),
      ],
      modalRoutes: [
        LmModalRouteDefinition<void>.sheet(
          path: '/actions',
          build: (context, params) => const Text('Actions'),
          transition: const LmTransition.none(),
        ),
      ],
    );

    BuildContext? scopedContext;
    await tester.pumpWidget(
      LmRouterScope(
        router: router,
        child: Builder(
          builder: (context) {
            scopedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final handle = scopedContext!.lm;
    await handle.pushPath('/detail');
    expect(router.location.path, '/detail');
    await handle.replacePath('/');
    expect(router.location.path, '/');
    await handle.presentPath('/actions');
    expect(router.controller.state.modalStack.single.location.path, '/actions');
    await handle.pop();
    await handle.goPath('/detail');
    expect(router.location.path, '/detail');

    router.dispose();
  });

  testWidgets('LmRouterKeyboardShortcuts maps Escape to router back', (
    tester,
  ) async {
    final router = LmRouter(
      initialLocation: '/',
      routes: [
        LmRouteDefinition<void>(
          name: 'home',
          path: '/',
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Home'),
        ),
        LmRouteDefinition<void>(
          name: 'detail',
          path: '/detail',
          transition: const LmTransition.none(),
          build: (context, params) => const Text('Detail'),
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LmRouterKeyboardShortcuts(
          router: router,
          child: Focus(
            autofocus: true,
            child: LmRouterScope(
              router: router,
              child: Router<Object>(
                routerDelegate: router.delegate,
                backButtonDispatcher: RootBackButtonDispatcher(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);

    await router.delegate.push('/detail');
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
