import 'dart:collection';

final class LmLocation {
  factory LmLocation({
    required String path,
    Map<String, String> query = const <String, String>{},
    String? fragment,
    Object? extra,
  }) {
    final normalizedPath = _normalizePath(path);
    final immutableQuery = UnmodifiableMapView<String, String>(
      Map<String, String>.of(query),
    );
    return LmLocation._(
      path: normalizedPath,
      query: immutableQuery,
      fragment: fragment,
      extra: extra,
      canonical: _canonicalFor(normalizedPath, immutableQuery, fragment),
    );
  }

  const LmLocation._({
    required this.path,
    required this.query,
    required this.canonical,
    this.fragment,
    this.extra,
  });

  factory LmLocation.fromUri(Uri uri, {Object? extra}) {
    return LmLocation(
      path: uri.path.isEmpty ? '/' : uri.path,
      query: uri.queryParameters,
      fragment: uri.fragment.isEmpty ? null : uri.fragment,
      extra: extra,
    );
  }

  factory LmLocation.parse(String location, {Object? extra}) {
    return LmLocation.fromUri(Uri.parse(location), extra: extra);
  }

  factory LmLocation.path(
    String path, {
    Map<String, String> query = const <String, String>{},
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

  final String path;
  final Map<String, String> query;
  final String? fragment;
  final Object? extra;
  final String canonical;

  Uri toUri() {
    return Uri(
      path: path,
      queryParameters: query.isEmpty ? null : query,
      fragment: fragment == null || fragment!.isEmpty ? null : fragment,
    );
  }

  @override
  int get hashCode => Object.hash(path, _queryHash(query), fragment, extra);

  @override
  String toString() => 'LmLocation($canonical)';

  static String _canonicalFor(
    String path,
    Map<String, String> query,
    String? fragment,
  ) {
    final sortedQuery = Map<String, String>.fromEntries(
      query.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key)),
    );

    return Uri(
      path: path,
      queryParameters: sortedQuery.isEmpty ? null : sortedQuery,
      fragment: fragment == null || fragment.isEmpty ? null : fragment,
    ).toString();
  }

  LmLocation copyWith({
    String? path,
    Map<String, String>? query,
    Object? extra,
    String? fragment,
    bool clearExtra = false,
    bool clearFragment = false,
  }) {
    return LmLocation(
      path: path ?? this.path,
      query: query ?? this.query,
      fragment: clearFragment ? null : fragment ?? this.fragment,
      extra: clearExtra ? null : extra ?? this.extra,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LmLocation &&
            other.path == path &&
            _mapEquals(other.query, query) &&
            other.fragment == fragment &&
            other.extra == extra;
  }

  static String _normalizePath(String path) {
    if (path.isEmpty) {
      return '/';
    }
    return path.startsWith('/') ? path : '/$path';
  }

  static bool _mapEquals(Map<String, String> left, Map<String, String> right) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value || !right.containsKey(entry.key)) {
        return false;
      }
    }
    return true;
  }

  static int _queryHash(Map<String, String> query) {
    if (query.isEmpty) {
      return 0;
    }
    final entries = query.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return Object.hashAll(
      entries.map((entry) => Object.hash(entry.key, entry.value)),
    );
  }
}
