import '../core/lm_location.dart';
import '../adaptive/lm_detail_policy.dart';
import '../chrome/lm_route_chrome.dart';

final class LmRouteNode {
  LmRouteNode({
    required this.name,
    required this.pathPattern,
    required this.location,
    required this.params,
    required Map<String, String> query,
    this.chrome = const LmRouteChrome(),
    this.detailPolicy = LmDetailPolicy.pushOnCompact,
  }) : query = Map.unmodifiable(query);

  final String name;
  final String pathPattern;
  final LmLocation location;
  final Object? params;
  final Map<String, String> query;
  final LmRouteChrome chrome;
  final LmDetailPolicy detailPolicy;
}
