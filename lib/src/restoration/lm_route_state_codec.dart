import '../core/lm_location.dart';
import '../adaptive/lm_detail_policy.dart';
import '../chrome/lm_route_chrome.dart';
import '../state/lm_branch_state.dart';
import '../state/lm_modal_node.dart';
import '../state/lm_navigation_state.dart';
import '../state/lm_route_node.dart';

final class LmRouteStateCodec {
  const LmRouteStateCodec({this.schemaVersion = 1});

  final int schemaVersion;

  Map<String, Object?> encode(LmNavigationState state) {
    return {
      'schemaVersion': schemaVersion,
      'activeBranchId': state.activeBranchId,
      'location': state.location.canonical,
      'version': state.version,
      'branches': {
        for (final entry in state.branches.entries)
          entry.key: _encodeBranch(entry.value),
      },
      'modalStack': state.modalStack.map(_encodeModal).toList(),
    };
  }

  LmNavigationState decode(Map<String, Object?> json) {
    final encodedVersion = json['schemaVersion'];
    if (encodedVersion != schemaVersion) {
      throw LmRestoreException(
        'Unsupported route state schema version $encodedVersion.',
      );
    }

    final branchesJson = _asMap(json['branches'], 'branches');
    return LmNavigationState(
      activeBranchId: _asString(json['activeBranchId'], 'activeBranchId'),
      branches: {
        for (final entry in branchesJson.entries)
          entry.key: _decodeBranch(entry.key, _asMap(entry.value, entry.key)),
      },
      location: _decodeLocation(_asString(json['location'], 'location')),
      modalStack: [
        for (final item in _asList(json['modalStack'], 'modalStack'))
          _decodeModal(_asMap(item, 'modalStack item')),
      ],
      version: _asInt(json['version'], 'version'),
    );
  }

  Map<String, Object?> _encodeBranch(LmBranchState branch) {
    return {
      'branchId': branch.branchId,
      'semanticStack': branch.semanticStack.map(_encodeNode).toList(),
      'secondaryStack': branch.secondaryStack.map(_encodeNode).toList(),
    };
  }

  LmBranchState _decodeBranch(String key, Map<String, Object?> json) {
    return LmBranchState(
      branchId: (json['branchId'] as String?) ?? key,
      semanticStack: [
        for (final item in _asList(json['semanticStack'], 'semanticStack'))
          _decodeNode(_asMap(item, 'semanticStack item')),
      ],
      secondaryStack: [
        for (final item in _asList(json['secondaryStack'], 'secondaryStack'))
          _decodeNode(_asMap(item, 'secondaryStack item')),
      ],
    );
  }

  Map<String, Object?> _encodeNode(LmRouteNode node) {
    return {
      'name': node.name,
      'pathPattern': node.pathPattern,
      'location': node.location.canonical,
      'params': _jsonSafe(node.params, 'params for route ${node.name}'),
      'query': node.query,
      'chrome': _encodeChrome(node.chrome),
      'detailPolicy': node.detailPolicy.name,
    };
  }

  LmRouteNode _decodeNode(Map<String, Object?> json) {
    final location = _decodeLocation(_asString(json['location'], 'location'));
    return LmRouteNode(
      name: _asString(json['name'], 'name'),
      pathPattern: _asString(json['pathPattern'], 'pathPattern'),
      location: location,
      params: json['params'],
      query: Map<String, String>.from(_asMap(json['query'], 'query')),
      chrome: _decodeChrome(json['chrome']),
      detailPolicy: _decodeDetailPolicy(json['detailPolicy']),
    );
  }

  Map<String, Object?> _encodeChrome(LmRouteChrome chrome) {
    return {
      'title': chrome.title,
      'largeTitle': chrome.largeTitle,
      'showBackButton': chrome.showBackButton,
      'tabBarVisibility': chrome.tabBarVisibility.name,
    };
  }

  Map<String, Object?> _encodeModal(LmModalNode node) {
    return {
      'name': node.name,
      'location': node.location.canonical,
      'params': _jsonSafe(node.params, 'params for modal ${node.name}'),
      'query': node.query,
    };
  }

  LmModalNode _decodeModal(Map<String, Object?> json) {
    return LmModalNode(
      name: _asString(json['name'], 'name'),
      location: _decodeLocation(_asString(json['location'], 'location')),
      params: json['params'],
      query: Map<String, String>.from(_asMap(json['query'], 'query')),
    );
  }

  LmLocation _decodeLocation(String value) {
    return LmLocation.fromUri(Uri.parse(value));
  }

  static Map<String, Object?> _asMap(Object? value, String field) {
    if (value is Map) {
      return Map<String, Object?>.from(value);
    }
    throw LmRestoreException('Expected $field to be a map.');
  }

  static List<Object?> _asList(Object? value, String field) {
    if (value == null) {
      return const [];
    }
    if (value is List) {
      return value;
    }
    throw LmRestoreException('Expected $field to be a list.');
  }

  static String _asString(Object? value, String field) {
    if (value is String) {
      return value;
    }
    throw LmRestoreException('Expected $field to be a string.');
  }

  static int _asInt(Object? value, String field) {
    if (value is int) {
      return value;
    }
    throw LmRestoreException('Expected $field to be an int.');
  }

  static LmDetailPolicy _decodeDetailPolicy(Object? value) {
    if (value is! String) {
      return LmDetailPolicy.pushOnCompact;
    }
    for (final policy in LmDetailPolicy.values) {
      if (policy.name == value) {
        return policy;
      }
    }
    return LmDetailPolicy.pushOnCompact;
  }

  static LmRouteChrome _decodeChrome(Object? value) {
    if (value is! Map) {
      return const LmRouteChrome();
    }
    final json = Map<String, Object?>.from(value);
    return LmRouteChrome(
      title: json['title'] as String?,
      largeTitle: json['largeTitle'] as bool?,
      showBackButton: json['showBackButton'] as bool?,
      tabBarVisibility: _decodeTabBarVisibility(json['tabBarVisibility']),
    );
  }

  static LmTabBarVisibility _decodeTabBarVisibility(Object? value) {
    if (value is! String) {
      return LmTabBarVisibility.inherited;
    }
    for (final visibility in LmTabBarVisibility.values) {
      if (visibility.name == value) {
        return visibility;
      }
    }
    return LmTabBarVisibility.inherited;
  }

  static Object? _jsonSafe(Object? value, String field) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is List) {
      return [
        for (var index = 0; index < value.length; index += 1)
          _jsonSafe(value[index], '$field[$index]'),
      ];
    }
    if (value is Map) {
      final result = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          throw LmRestoreException('Expected $field map keys to be strings.');
        }
        result[key] = _jsonSafe(entry.value, '$field.$key');
      }
      return result;
    }
    throw LmRestoreException(
      'Expected $field to be JSON-safe, got ${value.runtimeType}.',
    );
  }
}

final class LmRestoreException implements Exception {
  const LmRestoreException(this.message);

  final String message;

  @override
  String toString() => 'LmRestoreException: $message';
}
