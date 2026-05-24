import '../core/lm_route_definition.dart';

final class LmMatchResult {
  const LmMatchResult({
    required this.route,
    required this.routeChain,
    required this.pathParameters,
    required this.matchedLocation,
    required this.remaining,
  });

  const LmMatchResult.noMatch(String location)
    : route = null,
      routeChain = const [],
      pathParameters = const {},
      matchedLocation = '',
      remaining = location;

  final LmRouteDefinition<Object?>? route;
  final List<LmRouteDefinition<Object?>> routeChain;
  final Map<String, String> pathParameters;
  final String matchedLocation;
  final String remaining;

  bool get isMatch => route != null;
}

final class LmRouteMatcher {
  LmRouteMatcher(List<LmRouteDefinition<Object?>> routes) {
    for (final route in routes) {
      _insert(route, _root, const []);
    }
  }

  final _RouteTrieNode _root = _RouteTrieNode();

  LmMatchResult match(String location) {
    final normalizedLocation = _normalizeLocation(location);
    final segments = _splitPath(normalizedLocation);
    final match = _matchFrom(
      node: _root,
      segments: segments,
      index: 0,
      pathParameters: const {},
    );

    if (match == null) {
      return LmMatchResult.noMatch(normalizedLocation);
    }

    return LmMatchResult(
      route: match.chain.last,
      routeChain: match.chain,
      pathParameters: match.pathParameters,
      matchedLocation: _locationFromSegments(
        segments,
        start: 0,
        end: match.consumed,
      ),
      remaining: _locationFromSegments(
        segments,
        start: match.consumed,
        end: segments.length,
      ),
    );
  }

  void _insert(
    LmRouteDefinition<Object?> route,
    _RouteTrieNode start,
    List<LmRouteDefinition<Object?>> parentChain,
  ) {
    var node = start;
    for (final segment in _splitPath(route.path)) {
      if (segment == '*') {
        node = node.wildcardChild ??= _RouteTrieNode();
        break;
      }

      if (segment.startsWith(':')) {
        final parameterName = segment.substring(1);
        node.dynamicChild ??= _DynamicRouteTrieNode(parameterName);
        node = node.dynamicChild!;
      } else {
        node = node.staticChildren.putIfAbsent(segment, _RouteTrieNode.new);
      }
    }

    final chain = [...parentChain, route];
    node.chain = chain;

    for (final child in route.children) {
      _insert(child, node, chain);
    }
  }

  _RouteMatch? _matchFrom({
    required _RouteTrieNode node,
    required List<String> segments,
    required int index,
    required Map<String, String> pathParameters,
  }) {
    var bestMatch = node.chain == null
        ? null
        : _RouteMatch(
            chain: node.chain!,
            pathParameters: pathParameters,
            consumed: index,
          );

    if (index == segments.length) {
      return bestMatch;
    }

    final segment = segments[index];
    final staticChild = node.staticChildren[segment];
    if (staticChild != null) {
      final match = _matchFrom(
        node: staticChild,
        segments: segments,
        index: index + 1,
        pathParameters: pathParameters,
      );
      bestMatch = match ?? bestMatch;
    }

    if (bestMatch?.consumed == segments.length) {
      return bestMatch;
    }

    final dynamicChild = node.dynamicChild;
    if (dynamicChild != null) {
      final match = _matchFrom(
        node: dynamicChild,
        segments: segments,
        index: index + 1,
        pathParameters: {
          ...pathParameters,
          dynamicChild.parameterName: Uri.decodeComponent(segment),
        },
      );
      bestMatch = match ?? bestMatch;
    }

    if (bestMatch?.consumed == segments.length) {
      return bestMatch;
    }

    final wildcardChild = node.wildcardChild;
    if (wildcardChild != null && wildcardChild.chain != null) {
      final wildcardValue = _decodedSegmentsFrom(segments, index);
      return _RouteMatch(
        chain: wildcardChild.chain!,
        pathParameters: {...pathParameters, '*': wildcardValue},
        consumed: segments.length,
      );
    }

    return bestMatch;
  }
}

final class _RouteTrieNode {
  final Map<String, _RouteTrieNode> staticChildren = {};
  _DynamicRouteTrieNode? dynamicChild;
  _RouteTrieNode? wildcardChild;
  List<LmRouteDefinition<Object?>>? chain;
}

final class _DynamicRouteTrieNode extends _RouteTrieNode {
  _DynamicRouteTrieNode(this.parameterName);

  final String parameterName;
}

final class _RouteMatch {
  const _RouteMatch({
    required this.chain,
    required this.pathParameters,
    required this.consumed,
  });

  final List<LmRouteDefinition<Object?>> chain;
  final Map<String, String> pathParameters;
  final int consumed;
}

String _decodedSegmentsFrom(List<String> segments, int start) {
  final buffer = StringBuffer();
  for (var index = start; index < segments.length; index += 1) {
    if (index > start) {
      buffer.write('/');
    }
    buffer.write(Uri.decodeComponent(segments[index]));
  }
  return buffer.toString();
}

String _normalizeLocation(String location) {
  final specialIndex = _firstSpecialIndex(location);
  final pathOnly = specialIndex == -1
      ? location
      : location.substring(0, specialIndex);
  if (pathOnly.isEmpty || pathOnly == '/') {
    return '/';
  }

  final withoutTrailingSlash = pathOnly.length > 1 && pathOnly.endsWith('/')
      ? pathOnly.substring(0, pathOnly.length - 1)
      : pathOnly;
  return withoutTrailingSlash.startsWith('/')
      ? withoutTrailingSlash
      : '/$withoutTrailingSlash';
}

int _firstSpecialIndex(String location) {
  final queryIndex = location.indexOf('?');
  final fragmentIndex = location.indexOf('#');
  if (queryIndex == -1) {
    return fragmentIndex;
  }
  if (fragmentIndex == -1) {
    return queryIndex;
  }
  return queryIndex < fragmentIndex ? queryIndex : fragmentIndex;
}

List<String> _splitPath(String path) {
  final normalizedPath = _normalizeLocation(path);
  if (normalizedPath == '/') {
    return const [];
  }

  final segments = <String>[];
  var segmentStart = 1;
  for (var index = 1; index <= normalizedPath.length; index += 1) {
    if (index != normalizedPath.length &&
        normalizedPath.codeUnitAt(index) != 47) {
      continue;
    }
    if (index > segmentStart) {
      segments.add(normalizedPath.substring(segmentStart, index));
    }
    segmentStart = index + 1;
  }
  return segments;
}

String _locationFromSegments(
  List<String> segments, {
  required int start,
  required int end,
}) {
  if (start >= end) {
    return '';
  }
  final buffer = StringBuffer();
  for (var index = start; index < end; index += 1) {
    buffer
      ..write('/')
      ..write(segments[index]);
  }
  return buffer.toString();
}
