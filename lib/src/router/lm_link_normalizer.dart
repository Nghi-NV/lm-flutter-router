import '../core/lm_location.dart';

typedef LmLinkNormalizer = LmLocation Function(Uri uri);
typedef LmLinkRestorer = Uri Function(LmLocation location);

abstract interface class LmLinkTransformer {
  LmLocation? normalize(Uri uri);

  Uri? restore(LmLocation location);
}

final class LmLinkTransformers {
  const LmLinkTransformers(this.transformers);

  final List<LmLinkTransformer> transformers;

  LmLocation normalize(Uri uri) {
    for (final transformer in transformers) {
      final location = transformer.normalize(uri);
      if (location != null) {
        return location;
      }
    }
    return LmLocation.fromUri(uri);
  }

  Uri restore(LmLocation location) {
    for (final transformer in transformers) {
      final uri = transformer.restore(location);
      if (uri != null) {
        return uri;
      }
    }
    return location.toUri();
  }
}

final class LmCallbackLinkTransformer implements LmLinkTransformer {
  const LmCallbackLinkTransformer({this.normalizeLink, this.restoreLink});

  final LmLocation? Function(Uri uri)? normalizeLink;
  final Uri? Function(LmLocation location)? restoreLink;

  @override
  LmLocation? normalize(Uri uri) => normalizeLink?.call(uri);

  @override
  Uri? restore(LmLocation location) => restoreLink?.call(location);
}
