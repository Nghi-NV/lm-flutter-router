import 'package:flutter/widgets.dart';

import '../adaptive/lm_branch.dart';
import '../core/lm_location.dart';
import '../core/lm_route_definition.dart';
import '../delegate/lm_navigation_controller.dart';
import '../diagnostics/lm_router_diagnostics.dart';
import '../guards/lm_guard.dart';
import '../modal/lm_modal_route_definition.dart';
import '../transitions/lm_transition_policy.dart';
import 'lm_link_normalizer.dart';
import 'lm_route_information_parser.dart';
import 'lm_router_delegate.dart';

typedef LmRouterChildBuilder =
    Widget Function(BuildContext context, Widget child);

/// Owns the route parser, delegate, browser route-information provider, and
/// [RouterConfig] used by `MaterialApp.router`.
///
/// Create one router for the app shell and keep it alive for the lifetime of
/// the application:
///
/// ```dart
/// final router = LmRouter.app(
///   routes: [
///     LmRouteDefinition<void>.page(
///       path: '/',
///       build: (context, _) => const HomeScreen(),
///     ),
///   ],
/// );
///
/// MaterialApp.router(
///   routerConfig: router.config,
///   builder: router.scopedBuilder(),
/// );
/// ```
///
/// For widget-level navigation, wrap the shell with [LmRouterScope] and use
/// `context.lm.push(...)`, `context.lm.present(...)`, or `context.lm.pop()`.
final class LmRouter {
  LmRouter({
    required String initialLocation,
    required List<LmRouteDefinition<Object?>> routes,
    List<LmModalRouteDefinition<Object?>> modalRoutes = const [],
    List<LmBranch> branches = const [],
    List<LmGuard> guards = const [],
    LmRouteDefinition<Object?>? notFoundRoute,
    List<LmLinkTransformer> linkTransformers = const [],
    Listenable? refreshListenable,
    LmRouterDiagnostics? diagnostics,
    LmTransitionPolicy transitionPolicy = const LmTransitionPolicy.adaptive(),
  }) : parser = LmRouteInformationParser(
         linkNormalizer: _normalizerFor(linkTransformers),
         linkRestorer: _restorerFor(linkTransformers),
       ),
       routeInformationProvider = PlatformRouteInformationProvider(
         initialRouteInformation: RouteInformation(
           uri: Uri.parse(initialLocation),
         ),
       ),
       delegate = LmRouterDelegate(
         routes: routes,
         modalRoutes: modalRoutes,
         branches: branches,
         initialLocation: _initialLocationFor(
           initialLocation,
           _normalizerFor(linkTransformers),
         ),
         guards: guards,
         notFoundRoute: notFoundRoute,
         refreshListenable: refreshListenable,
         diagnostics: diagnostics,
         transitionPolicy: transitionPolicy,
       ) {
    routeInformationProvider.addListener(_handlePlatformRouteInformation);
    delegate.addListener(_reportRouteInformation);
    config = RouterConfig<LmLocation>(
      routeInformationProvider: routeInformationProvider,
      routeInformationParser: parser,
      routerDelegate: delegate,
      backButtonDispatcher: RootBackButtonDispatcher(),
    );
  }

  factory LmRouter.app({
    String initialLocation = '/',
    required List<LmRouteDefinition<Object?>> routes,
    List<LmModalRouteDefinition<Object?>> modalRoutes = const [],
    List<LmBranch> branches = const [],
    List<LmGuard> guards = const [],
    LmRouteDefinition<Object?>? notFoundRoute,
    List<LmLinkTransformer> linkTransformers = const [],
    Listenable? refreshListenable,
    LmRouterDiagnostics? diagnostics,
    LmTransitionPolicy transitionPolicy = const LmTransitionPolicy.adaptive(),
  }) {
    return LmRouter(
      initialLocation: initialLocation,
      routes: routes,
      modalRoutes: modalRoutes,
      branches: branches,
      guards: guards,
      notFoundRoute: notFoundRoute,
      linkTransformers: linkTransformers,
      refreshListenable: refreshListenable,
      diagnostics: diagnostics,
      transitionPolicy: transitionPolicy,
    );
  }

  factory LmRouter.platformApp({
    required List<LmRouteDefinition<Object?>> routes,
    List<LmModalRouteDefinition<Object?>> modalRoutes = const [],
    List<LmBranch> branches = const [],
    List<LmGuard> guards = const [],
    LmRouteDefinition<Object?>? notFoundRoute,
    List<LmLinkTransformer> linkTransformers = const [],
    Listenable? refreshListenable,
    LmRouterDiagnostics? diagnostics,
    LmTransitionPolicy transitionPolicy = const LmTransitionPolicy.adaptive(),
  }) {
    return LmRouter.app(
      initialLocation: platformInitialLocation(),
      routes: routes,
      modalRoutes: modalRoutes,
      branches: branches,
      guards: guards,
      notFoundRoute: notFoundRoute,
      linkTransformers: linkTransformers,
      refreshListenable: refreshListenable,
      diagnostics: diagnostics,
      transitionPolicy: transitionPolicy,
    );
  }

  /// Advanced route-information parser used by [config].
  final LmRouteInformationParser parser;

  /// Advanced router delegate used by [config].
  ///
  /// App code should prefer [go], [push], [replace], [present], [pop], and
  /// [switchBranch] so guards, diagnostics, and platform reporting stay aligned.
  final LmRouterDelegate delegate;

  /// Advanced route-information provider used by [config].
  final PlatformRouteInformationProvider routeInformationProvider;
  late final RouterConfig<LmLocation> config;
  bool _isConsumingPlatformRouteInformation = false;
  bool _isDisposed = false;

  /// Read-only state holder for widgets that need to observe routing state.
  ///
  /// App code should not mutate this controller directly; use the router
  /// navigation methods instead.
  LmNavigationController get controller => delegate.controller;

  LmLocation get location => controller.state.location;

  bool get canPop => controller.canPop;

  Future<void> go(Object location) => delegate.go(location);

  Future<void> goPath(String path) => go(path);

  Future<void> push(Object location) => delegate.push(location);

  Future<void> pushPath(String path) => push(path);

  Future<void> replace(Object location) => delegate.replace(location);

  Future<void> replacePath(String path) => replace(path);

  Future<void> present(Object location) => delegate.present(location);

  Future<void> presentPath(String path) => present(path);

  Future<bool> pop() => delegate.pop();

  Future<void> switchBranch(String branchId) => delegate.switchBranch(branchId);

  /// Releases router-owned listeners and delegate resources.
  ///
  /// Apps that keep one router singleton for the app lifetime usually do not
  /// need to call this. Widgets or tests that create routers dynamically should
  /// dispose them when the owning object unmounts.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    routeInformationProvider.removeListener(_handlePlatformRouteInformation);
    delegate.removeListener(_reportRouteInformation);
    delegate.dispose();
  }

  static String platformInitialLocation() {
    final base = Uri.base;
    final uri = base.scheme == 'http' || base.scheme == 'https'
        ? base
        : _platformRouteUri();
    final query = uri.hasQuery ? '?${uri.query}' : '';
    final fragment = uri.hasFragment ? '#${uri.fragment}' : '';
    return '${uri.path.isEmpty ? '/' : uri.path}$query$fragment';
  }

  void _handlePlatformRouteInformation() {
    _isConsumingPlatformRouteInformation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isConsumingPlatformRouteInformation = false;
    });
  }

  static Uri _platformRouteUri() {
    final platformRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (platformRoute.isEmpty || platformRoute == '/') {
      return Uri(path: '/');
    }
    return Uri.parse(platformRoute);
  }

  void _reportRouteInformation() {
    if (_isConsumingPlatformRouteInformation) {
      return;
    }
    final configuration = delegate.currentConfiguration;
    if (configuration == null) {
      return;
    }
    final routeInformation = parser.restoreRouteInformation(configuration);
    if (routeInformation == null) {
      return;
    }
    if (routeInformationProvider.value.uri == routeInformation.uri) {
      return;
    }
    routeInformationProvider.routerReportsNewRouteInformation(
      routeInformation,
      type: RouteInformationReportingType.navigate,
    );
  }

  static LmLocation _initialLocationFor(
    String initialLocation,
    LmLinkNormalizer linkNormalizer,
  ) {
    final uri = Uri.parse(initialLocation);
    return linkNormalizer(uri);
  }

  static LmLinkNormalizer _normalizerFor(List<LmLinkTransformer> transformers) {
    return (uri) {
      for (final transformer in transformers) {
        final location = transformer.normalize(uri);
        if (location != null) {
          return location;
        }
      }
      return LmLocation.fromUri(uri);
    };
  }

  static LmLinkRestorer _restorerFor(List<LmLinkTransformer> transformers) {
    return (location) {
      for (final transformer in transformers) {
        final uri = transformer.restore(location);
        if (uri != null) {
          return uri;
        }
      }
      return location.toUri();
    };
  }
}
