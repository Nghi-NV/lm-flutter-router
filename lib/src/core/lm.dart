import 'dart:async';

import 'package:flutter/widgets.dart';

import '../adaptive/lm_branch.dart';
import '../adaptive/lm_detail_policy.dart';
import '../chrome/lm_route_chrome.dart';
import '../diagnostics/lm_router_diagnostics.dart';
import '../guards/lm_guard.dart';
import '../modal/lm_modal_route_definition.dart';
import '../params/lm_codecs.dart';
import '../router/lm_link_normalizer.dart';
import '../router/lm_router.dart';
import '../transitions/lm_transition.dart';
import '../transitions/lm_transition_policy.dart';
import 'lm_location.dart';
import 'lm_route_definition.dart';

/// Short factory namespace for the common router setup surface.
///
/// Prefer this in app code when defining routes:
///
/// ```dart
/// final router = Lm.router(
///   routes: [
///     Lm.page(path: '/', build: (context, _) => const HomeScreen()),
///     Lm.page(path: '/orders/:id', build: (context, _) => const OrderScreen()),
///   ],
/// );
/// ```
abstract final class Lm {
  static LmRouter router({
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
    return LmRouter.app(
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

  static LmRouter platformRouter({
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
    return LmRouter.platformApp(
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

  static LmRouteDefinition<TParams> page<TParams>({
    String? name,
    required String path,
    required LmRouteWidgetBuilder<TParams> build,
    LmRouteParamDecoder<TParams>? decode,
    LmRoutePathBuilder<TParams>? buildPath,
    LmRouteChrome chrome = const LmRouteChrome(),
    LmDetailPolicy detailPolicy = LmDetailPolicy.pushOnCompact,
    LmTransition transition = const LmTransition.cupertino(),
    List<LmRouteDefinition<Object?>> children = const [],
  }) {
    return LmRouteDefinition<TParams>.page(
      name: name,
      path: path,
      build: build,
      decode: decode,
      buildPath: buildPath,
      chrome: chrome,
      detailPolicy: detailPolicy,
      transition: transition,
      children: children,
    );
  }

  static LmModalRouteDefinition<TParams> dialog<TParams>({
    String? name,
    required String path,
    LmModalRouteParamDecoder<TParams>? decode,
    LmRoutePathBuilder<TParams>? buildPath,
    required LmModalRouteWidgetBuilder<TParams> build,
    LmTransition? transition,
    String? restorationId,
    bool barrierDismissible = true,
    bool usesSafeArea = true,
  }) {
    return LmModalRouteDefinition<TParams>.dialog(
      name: name,
      path: path,
      decode: decode,
      buildPath: buildPath,
      build: build,
      transition: transition,
      restorationId: restorationId,
      barrierDismissible: barrierDismissible,
      usesSafeArea: usesSafeArea,
    );
  }

  static LmModalRouteDefinition<TParams> cupertinoDialog<TParams>({
    String? name,
    required String path,
    LmModalRouteParamDecoder<TParams>? decode,
    LmRoutePathBuilder<TParams>? buildPath,
    required LmModalRouteWidgetBuilder<TParams> build,
    LmTransition? transition,
    String? restorationId,
    bool barrierDismissible = false,
    bool usesSafeArea = true,
  }) {
    return LmModalRouteDefinition<TParams>.cupertinoDialog(
      name: name,
      path: path,
      decode: decode,
      buildPath: buildPath,
      build: build,
      transition: transition,
      restorationId: restorationId,
      barrierDismissible: barrierDismissible,
      usesSafeArea: usesSafeArea,
    );
  }

  static LmModalRouteDefinition<TParams> sheet<TParams>({
    String? name,
    required String path,
    LmModalRouteParamDecoder<TParams>? decode,
    LmRoutePathBuilder<TParams>? buildPath,
    required LmModalRouteWidgetBuilder<TParams> build,
    LmTransition? transition,
    String? restorationId,
    bool barrierDismissible = true,
    bool usesSafeArea = true,
    bool fullscreen = false,
  }) {
    return LmModalRouteDefinition<TParams>.sheet(
      name: name,
      path: path,
      decode: decode,
      buildPath: buildPath,
      build: build,
      transition: transition,
      restorationId: restorationId,
      barrierDismissible: barrierDismissible,
      usesSafeArea: usesSafeArea,
      fullscreen: fullscreen,
    );
  }

  static LmModalRouteDefinition<TParams> actionSheet<TParams>({
    String? name,
    required String path,
    LmModalRouteParamDecoder<TParams>? decode,
    LmRoutePathBuilder<TParams>? buildPath,
    required LmModalRouteWidgetBuilder<TParams> build,
    LmTransition? transition,
    String? restorationId,
    bool barrierDismissible = true,
    bool usesSafeArea = true,
  }) {
    return LmModalRouteDefinition<TParams>.actionSheet(
      name: name,
      path: path,
      decode: decode,
      buildPath: buildPath,
      build: build,
      transition: transition,
      restorationId: restorationId,
      barrierDismissible: barrierDismissible,
      usesSafeArea: usesSafeArea,
    );
  }

  static LmModalRouteDefinition<TParams> fullscreenDialog<TParams>({
    String? name,
    required String path,
    LmModalRouteParamDecoder<TParams>? decode,
    LmRoutePathBuilder<TParams>? buildPath,
    required LmModalRouteWidgetBuilder<TParams> build,
    LmTransition? transition,
    String? restorationId,
    bool barrierDismissible = false,
    bool usesSafeArea = true,
  }) {
    return LmModalRouteDefinition<TParams>.fullscreenDialog(
      name: name,
      path: path,
      decode: decode,
      buildPath: buildPath,
      build: build,
      transition: transition,
      restorationId: restorationId,
      barrierDismissible: barrierDismissible,
      usesSafeArea: usesSafeArea,
    );
  }

  static LmModalRouteDefinition<TParams> popover<TParams>({
    String? name,
    required String path,
    LmModalRouteParamDecoder<TParams>? decode,
    LmRoutePathBuilder<TParams>? buildPath,
    required LmModalRouteWidgetBuilder<TParams> build,
    LmTransition? transition,
    String? restorationId,
    bool barrierDismissible = true,
    bool usesSafeArea = true,
  }) {
    return LmModalRouteDefinition<TParams>.popover(
      name: name,
      path: path,
      decode: decode,
      buildPath: buildPath,
      build: build,
      transition: transition,
      restorationId: restorationId,
      barrierDismissible: barrierDismissible,
      usesSafeArea: usesSafeArea,
    );
  }

  static LmBranch branch({
    required String id,
    required Object root,
    List<Object> routes = const [],
    LmBranchSwitchPolicy switchPolicy = LmBranchSwitchPolicy.preserveStack,
  }) {
    return LmBranch(
      id: id,
      root: root,
      routes: routes,
      switchPolicy: switchPolicy,
    );
  }

  static LmLocation path(
    String path, {
    Map<String, String> query = const {},
    String? fragment,
    Object? extra,
  }) {
    return LmLocation(
      path: path,
      query: query,
      fragment: fragment,
      extra: extra,
    );
  }

  static LmLinkTransformer links({
    LmLocation? Function(Uri uri)? normalize,
    Uri? Function(LmLocation location)? restore,
  }) {
    return LmCallbackLinkTransformer(
      normalizeLink: normalize,
      restoreLink: restore,
    );
  }

  static LmGuard guard(
    FutureOr<LmGuardResult> Function(LmGuardContext context) canActivate,
  ) {
    return LmCallbackGuard(canActivate);
  }

  static LmGuard popGuard(
    FutureOr<LmGuardResult> Function(LmGuardContext context) canPop, {
    FutureOr<LmGuardResult> Function(LmGuardContext context)? canActivate,
  }) {
    return LmCallbackPopGuard(canActivate: canActivate, canPop: canPop);
  }

  static LmPathParams params(
    Map<String, String> pathParams, {
    String routeName = '<unknown route>',
  }) {
    return LmPathParams(pathParams, routeName: routeName);
  }
}

final class LmPathParams {
  const LmPathParams(this._pathParams, {this.routeName = '<unknown route>'});

  final Map<String, String> _pathParams;
  final String routeName;

  String requiredString(String name) {
    return LmCodecs.string.decodeRequired(
      _pathParams[name],
      routeName: routeName,
      paramName: name,
    );
  }

  int requiredInt(String name) {
    return LmCodecs.int.decodeRequired(
      _pathParams[name],
      routeName: routeName,
      paramName: name,
    );
  }

  double requiredDouble(String name) {
    return LmCodecs.double.decodeRequired(
      _pathParams[name],
      routeName: routeName,
      paramName: name,
    );
  }

  bool requiredBool(String name) {
    return LmCodecs.bool.decodeRequired(
      _pathParams[name],
      routeName: routeName,
      paramName: name,
    );
  }

  DateTime requiredDateTimeIso8601(String name) {
    return LmCodecs.dateTimeIso8601.decodeRequired(
      _pathParams[name],
      routeName: routeName,
      paramName: name,
    );
  }

  T requiredEnum<T extends Enum>(String name, List<T> values) {
    return LmCodecs.enumByName(
      values,
    ).decodeRequired(_pathParams[name], routeName: routeName, paramName: name);
  }
}
