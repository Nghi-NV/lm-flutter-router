import '../core/lm_location.dart';
import '../router/lm_link_normalizer.dart';

/// Maps public nested sheet paths to a single Cupertino sheet page route.
///
/// A sheet page should remain one route visually, while its content can use a
/// nested Navigator. This helper lets apps expose clean deep links such as
/// `/settings/account/security` and normalize them to the owning sheet route
/// with a selected nested page marker.
final class LmCupertinoSheetDeepLink implements LmLinkTransformer {
  const LmCupertinoSheetDeepLink({
    required this.sheetPath,
    required this.nestedPath,
    required this.nestedPage,
    this.queryKey = 'sheetPage',
  });

  final String sheetPath;
  final String nestedPath;
  final String nestedPage;
  final String queryKey;

  @override
  LmLocation? normalize(Uri uri) {
    if (_normalizePath(uri.path) != _normalizePath(nestedPath)) {
      return null;
    }
    return LmLocation(
      path: sheetPath,
      query: {...uri.queryParameters, queryKey: nestedPage},
      fragment: uri.fragment.isEmpty ? null : uri.fragment,
    );
  }

  @override
  Uri? restore(LmLocation location) {
    if (!isSelected(location) ||
        _normalizePath(location.path) != _normalizePath(sheetPath)) {
      return null;
    }
    final query = Map<String, String>.of(location.query)..remove(queryKey);
    return Uri(
      path: publicPath,
      queryParameters: query.isEmpty ? null : query,
      fragment: location.fragment == null || location.fragment!.isEmpty
          ? null
          : location.fragment,
    );
  }

  bool isSelected(LmLocation location) {
    return location.query[queryKey] == nestedPage;
  }

  String get publicPath => _normalizePath(nestedPath);
}

final class LmCupertinoSheetDeepLinks implements LmLinkTransformer {
  const LmCupertinoSheetDeepLinks(this.links);

  final List<LmCupertinoSheetDeepLink> links;

  @override
  LmLocation? normalize(Uri uri) {
    for (final link in links) {
      final location = link.normalize(uri);
      if (location != null) {
        return location;
      }
    }
    return null;
  }

  @override
  Uri? restore(LmLocation location) {
    for (final link in links) {
      final uri = link.restore(location);
      if (uri != null) {
        return uri;
      }
    }
    return null;
  }
}

String _normalizePath(String path) {
  if (path.isEmpty) {
    return '/';
  }
  final withLeadingSlash = path.startsWith('/') ? path : '/$path';
  return withLeadingSlash.length > 1 && withLeadingSlash.endsWith('/')
      ? withLeadingSlash.substring(0, withLeadingSlash.length - 1)
      : withLeadingSlash;
}
