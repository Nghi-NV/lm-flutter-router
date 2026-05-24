import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lm_flutter_router/lm_flutter_router.dart';

import 'domain.dart';
import 'navigation_lab.dart';
import 'screens.dart';
import 'shell.dart';
import 'web_smoke_bridge_stub.dart'
    if (dart.library.js_interop) 'web_smoke_bridge_web.dart';

final class FieldOrdersApp extends StatefulWidget {
  const FieldOrdersApp({this.initialLocation, super.key});

  final String? initialLocation;

  @override
  State<FieldOrdersApp> createState() => _FieldOrdersAppState();
}

final class _FieldOrdersAppState extends State<FieldOrdersApp> {
  late final OrdersRepository repository;
  late final SessionStore session;
  late final LmRouterDiagnostics diagnostics;
  late final LmRouter router;

  @override
  void initState() {
    super.initState();
    repository = OrdersRepository();
    session = SessionStore();
    diagnostics = LmRouterDiagnostics();
    router = Lm.router(
      initialLocation:
          widget.initialLocation ?? LmRouter.platformInitialLocation(),
      guards: [
        Lm.guard((context) {
          final path = context.current.location.path;
          final protected = path.startsWith('/orders/');
          if (!protected || session.isSignedIn) {
            return const LmGuardAllow();
          }
          return LmGuardRedirect.toLogin('/login', context);
        }),
      ],
      linkTransformers: [
        Lm.links(
          normalize: (uri) {
            if (uri.fragment.startsWith('/')) {
              return LmLocation.parse(uri.fragment);
            }
            if (uri.host == 'field-orders.example' &&
                uri.pathSegments.length == 2 &&
                uri.pathSegments.first == 'o') {
              return Lm.path('/orders/${uri.pathSegments.last}');
            }
            return null;
          },
        ),
        labCupertinoSheetConfig,
      ],
      diagnostics: diagnostics,
      branches: [
        Lm.branch(id: 'dashboard', root: '/'),
        Lm.branch(id: 'orders', root: '/orders'),
        Lm.branch(id: 'lab', root: '/lab'),
        Lm.branch(id: 'settings', root: '/settings'),
      ],
      notFoundRoute: Lm.page<void>(
        path: '/404',
        transition: const LmTransition.cupertino(),
        build: (context, params) => _withChrome(
          title: 'Not found',
          canPop: true,
          child: NotFoundScreen(
            title: 'No route for ${router.controller.state.location.canonical}',
          ),
        ),
      ),
      routes: [
        Lm.page<void>(
          path: '/',
          transition: const LmTransition.none(),
          build: (context, params) => _withChrome(
            title: 'Field Orders',
            canPop: false,
            child: DashboardScreen(repository: repository),
          ),
        ),
        Lm.page<void>(
          path: '/orders',
          transition: const LmTransition.none(),
          build: (context, params) => _withChrome(
            title: 'Orders',
            canPop: false,
            child: OrdersScreen(repository: repository),
          ),
        ),
        Lm.page<OrderParams>(
          path: '/orders/:orderId',
          transition: const LmTransition.cupertino(),
          detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
          chrome: const LmRouteChrome(
            tabBarVisibility: LmTabBarVisibility.hidden,
          ),
          decode: OrderParams.decode,
          buildPath: (params) => orderPath(params.orderId),
          build: (context, params) => _withChrome(
            title: 'Order detail',
            canPop: true,
            child: OrderDetailScreen(
              repository: repository,
              orderId: params!.orderId,
            ),
          ),
        ),
        Lm.page<OrderItemParams>(
          path: '/orders/:orderId/items/:itemId',
          transition: const LmTransition.cupertino(),
          detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
          chrome: const LmRouteChrome(
            tabBarVisibility: LmTabBarVisibility.hidden,
          ),
          decode: OrderItemParams.decode,
          buildPath: (params) => orderItemPath(params.orderId, params.itemId),
          build: (context, params) => _withChrome(
            title: 'Line item',
            canPop: true,
            child: OrderItemScreen(
              repository: repository,
              orderId: params!.orderId,
              itemId: params.itemId,
            ),
          ),
        ),
        Lm.page<void>(
          path: '/lab',
          transition: const LmTransition.none(),
          build: (context, params) => _withChrome(
            title: 'Router Lab',
            canPop: false,
            child: const NavigationLabScreen(),
          ),
        ),
        Lm.page<void>(
          path: '/lab/reference',
          transition: const LmTransition.cupertino(),
          chrome: const LmRouteChrome(
            tabBarVisibility: LmTabBarVisibility.hidden,
          ),
          build: (context, params) => _withChrome(
            title: 'Implementation Reference',
            canPop: true,
            child: const RouterReferenceScreen(),
          ),
        ),
        Lm.page<void>(
          path: '/lab/heavy',
          transition: const LmTransition.cupertino(),
          chrome: const LmRouteChrome(
            tabBarVisibility: LmTabBarVisibility.hidden,
          ),
          build: (context, params) => _withChrome(
            title: 'Heavy View',
            canPop: true,
            child: const LabHeavyViewScreen(),
          ),
        ),
        Lm.page<void>(
          path: '/lab/glass',
          transition: const LmTransition.cupertino(),
          chrome: const LmRouteChrome(
            tabBarVisibility: LmTabBarVisibility.hidden,
          ),
          build: (context, params) => _withChrome(
            title: 'iOS 26 Glass Lab',
            canPop: true,
            child: const LabGlassViewScreen(),
          ),
        ),
        _labTransitionRoute(
          path: '/lab/none',
          kind: 'none',
          title: 'None',
          transition: const LmTransition.none(),
        ),
        _labTransitionRoute(
          path: '/lab/fade',
          kind: 'fade',
          title: 'Fade',
          transition: const LmTransition.fade(),
        ),
        _labTransitionRoute(
          path: '/lab/slide-left',
          kind: 'slide-left',
          title: 'Slide left',
          transition: const LmTransition.slide(from: LmSlideFrom.left),
        ),
        _labTransitionRoute(
          path: '/lab/slide-right',
          kind: 'slide-right',
          title: 'Slide right',
          transition: const LmTransition.slide(),
        ),
        _labTransitionRoute(
          path: '/lab/slide-top',
          kind: 'slide-top',
          title: 'Slide top',
          transition: const LmTransition.slide(from: LmSlideFrom.top),
        ),
        _labTransitionRoute(
          path: '/lab/slide-bottom',
          kind: 'slide-bottom',
          title: 'Slide bottom',
          transition: const LmTransition.slide(from: LmSlideFrom.bottom),
        ),
        _labTransitionRoute(
          path: '/lab/cupertino',
          kind: 'cupertino',
          title: 'Cupertino',
          transition: const LmTransition.cupertino(),
        ),
        _labTransitionRoute(
          path: '/lab/fullscreen',
          kind: 'fullscreen',
          title: 'Fullscreen modal',
          transition: const LmTransition.fullscreenModal(),
        ),
        _labTransitionRoute(
          path: '/lab/cupertino-sheet',
          kind: 'cupertino-sheet',
          title: 'iOS 15 sheet',
          transition: const LmTransition.cupertinoSheet(),
        ),
        _labTransitionRoute(
          path: '/lab/scale',
          kind: 'scale',
          title: 'Scale',
          transition: const LmTransition.scale(),
        ),
        _labTransitionRoute(
          path: '/lab/hero',
          kind: 'hero',
          title: 'Hero',
          transition: const LmTransition.hero(),
        ),
        Lm.page<void>(
          path: '/settings',
          transition: const LmTransition.none(),
          build: (context, params) => _withChrome(
            title: 'Settings',
            canPop: false,
            child: SettingsScreen(
              session: session,
              onSignOut: () {
                session.signOut();
                unawaited(router.go('/'));
              },
            ),
          ),
        ),
        Lm.page<void>(
          path: '/login',
          transition: const LmTransition.fullscreenModal(),
          build: (context, params) => LoginScreen(
            returnTo: router.location.query['returnTo'],
            onSignIn: () {
              session.signIn();
              final returnTo = router.location.query['returnTo'];
              unawaited(
                returnTo == null ? router.go('/') : router.go(returnTo),
              );
            },
          ),
        ),
      ],
      modalRoutes: [
        Lm.actionSheet<OrderParams>(
          path: '/orders/:orderId/actions',
          decode: OrderParams.decode,
          buildPath: (params) => orderActionsPath(params.orderId),
          build: (context, params) => OrderActionsSheet(
            repository: repository,
            orderId: params!.orderId,
          ),
        ),
        Lm.sheet<OrderParams>(
          path: '/orders/:orderId/reschedule',
          decode: OrderParams.decode,
          buildPath: (params) => orderReschedulePath(params.orderId),
          build: (context, params) => OrderRescheduleSheet(
            repository: repository,
            orderId: params!.orderId,
          ),
        ),
        Lm.dialog<void>(
          path: '/lab/modal/dialog',
          build: (context, params) => const LabModalContent(kind: 'dialog'),
        ),
        Lm.cupertinoDialog<void>(
          path: '/lab/modal/cupertino-dialog',
          build: (context, params) =>
              const LabModalContent(kind: 'cupertino-dialog'),
        ),
        Lm.sheet<void>(
          path: '/lab/modal/bottom-sheet',
          build: (context, params) =>
              const LabModalContent(kind: 'bottom-sheet'),
        ),
        Lm.actionSheet<void>(
          path: '/lab/modal/action-sheet',
          build: (context, params) =>
              const LabModalContent(kind: 'action-sheet'),
        ),
        Lm.fullscreenDialog<void>(
          path: '/lab/modal/fullscreen-dialog',
          build: (context, params) =>
              const LabModalContent(kind: 'fullscreen-dialog'),
        ),
        Lm.popover<void>(
          path: '/lab/modal/popover',
          build: (context, params) => const LabModalContent(kind: 'popover'),
        ),
      ],
    );
  }

  LmRouteDefinition<void> _labTransitionRoute({
    required String path,
    required String kind,
    required String title,
    required LmTransition transition,
  }) {
    return Lm.page<void>(
      path: path,
      transition: transition,
      chrome: const LmRouteChrome(tabBarVisibility: LmTabBarVisibility.hidden),
      build: (context, params) => _withChrome(
        title: title,
        canPop: true,
        child: LabTransitionDetailScreen(kind: kind, title: title),
      ),
    );
  }

  Widget _withChrome({
    required String title,
    required bool canPop,
    required Widget child,
  }) {
    return Builder(
      builder: (context) {
        installWebSmokeBridge(context, router);
        return child;
      },
    );
  }

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Field Orders',
          theme: LmIosPlatformTheme.apply(
            ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xff2563eb),
              ),
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              useMaterial3: true,
            ),
          ),
          routerConfig: router.config,
          builder: router.scopedBuilder(
            (context, child) => Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => FieldOrdersShell(
                    router: router,
                    repository: repository,
                    session: session,
                    diagnostics: diagnostics,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String orderPath(int orderId) => '/orders/$orderId';

String orderItemPath(int orderId, int itemId) =>
    '/orders/$orderId/items/$itemId';

String orderActionsPath(int orderId) => '/orders/$orderId/actions';

String orderReschedulePath(int orderId) => '/orders/$orderId/reschedule';

final class OrderParams {
  const OrderParams(this.orderId);

  final int orderId;

  static OrderParams decode(Map<String, String> params) {
    return OrderParams(Lm.params(params).requiredInt('orderId'));
  }
}

final class OrderItemParams {
  const OrderItemParams(this.orderId, this.itemId);

  final int orderId;
  final int itemId;

  static OrderItemParams decode(Map<String, String> params) {
    final path = Lm.params(params);
    return OrderItemParams(
      path.requiredInt('orderId'),
      path.requiredInt('itemId'),
    );
  }
}
