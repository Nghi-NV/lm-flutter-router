import 'package:flutter/widgets.dart';

import '../adaptive/lm_detail_policy.dart';
import '../chrome/lm_route_chrome.dart';
import 'lm_location.dart';
import '../transitions/lm_transition.dart';

typedef LmRouteParamDecoder<TParams> =
    TParams Function(Map<String, String> pathParameters);

typedef LmRoutePathBuilder<TParams> = String Function(TParams params);
typedef LmRouteWidgetBuilder<TParams> =
    Widget Function(BuildContext context, TParams? params);

/// Describes a semantic page route, including path matching, typed parameter
/// decoding, chrome metadata, adaptive detail behavior, and transition style.
///
/// Use `decode` and `buildPath` together when a route needs strongly typed
/// navigation parameters:
///
/// ```dart
/// final orderRoute = LmRouteDefinition<OrderParams>.page(
///   path: '/orders/:orderId',
///   decode: (path) => OrderParams(int.parse(path['orderId']!)),
///   buildPath: (params) => '/orders/${params.orderId}',
///   build: (context, params) => OrderScreen(orderId: params!.orderId),
/// );
/// ```
///
/// Child routes are semantic children. On compact layouts they can push onto
/// the active stack; on expanded layouts they can be projected into a detail
/// pane by the adaptive router widgets.
final class LmRouteDefinition<TParams> {
  const LmRouteDefinition({
    required this.name,
    required this.path,
    this.decode,
    this.buildPath,
    this.build,
    this.chrome = const LmRouteChrome(),
    this.detailPolicy = LmDetailPolicy.pushOnCompact,
    this.transition = const LmTransition.cupertino(),
    this.children = const [],
  });

  factory LmRouteDefinition.page({
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
    return LmRouteDefinition<TParams>(
      name: name ?? _routeNameFromPath(path),
      path: path,
      decode: decode,
      buildPath: buildPath,
      build: build,
      chrome: chrome,
      detailPolicy: detailPolicy,
      transition: transition,
      children: children,
    );
  }

  final String name;
  final String path;
  final LmRouteParamDecoder<TParams>? decode;
  final LmRoutePathBuilder<TParams>? buildPath;
  final LmRouteWidgetBuilder<TParams>? build;
  final LmRouteChrome chrome;
  final LmDetailPolicy detailPolicy;
  final LmTransition transition;
  final List<LmRouteDefinition<Object?>> children;

  LmLocation location(
    TParams? params, {
    Map<String, String> query = const {},
    String? fragment,
    Object? extra,
  }) {
    final path = params == null
        ? _staticPathForLocation()
        : _buildPathFor(params);
    return LmLocation(
      path: path,
      query: query,
      fragment: fragment,
      extra: extra,
    );
  }

  LmLocation rootLocation({
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

  Object? decodeParams(Map<String, String> pathParameters) {
    return decode?.call(pathParameters);
  }

  Widget buildWidget(BuildContext context, Object? params) {
    final builder = build;
    if (builder == null) {
      throw StateError(
        'Route "$name" cannot build a page because build is missing.',
      );
    }
    return builder(context, params as TParams?);
  }

  String _buildPathFor(TParams params) {
    final builder = buildPath;
    if (builder == null) {
      throw StateError(
        'Route "$name" cannot build a location because buildPath is missing.',
      );
    }
    return builder(params);
  }

  String _staticPathForLocation() {
    if (_pathRequiresParams(path)) {
      throw StateError(
        'Route "$name" requires params to build a location for path "$path".',
      );
    }
    return path;
  }
}

bool _pathRequiresParams(String path) {
  return path
      .split('/')
      .any((segment) => segment.startsWith(':') || segment == '*');
}

String _routeNameFromPath(String path) {
  final normalized = path.trim();
  if (normalized.isEmpty || normalized == '/') {
    return 'root';
  }
  final segments = normalized
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .map((segment) {
        if (segment.startsWith(':')) {
          return segment.substring(1);
        }
        if (segment == '*') {
          return 'wildcard';
        }
        return segment;
      })
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.isEmpty) {
    return 'root';
  }
  return segments.join('.');
}
