import 'package:flutter/widgets.dart';

import '../core/lm_location.dart';
import 'lm_link_normalizer.dart';

final class LmRouteInformationParser
    extends RouteInformationParser<LmLocation> {
  const LmRouteInformationParser({this.linkNormalizer, this.linkRestorer});

  final LmLinkNormalizer? linkNormalizer;
  final LmLinkRestorer? linkRestorer;

  LmLocation parseUri(Uri uri) {
    final normalizer = linkNormalizer;
    if (normalizer == null) {
      return LmLocation.fromUri(uri);
    }
    return normalizer(uri);
  }

  @override
  Future<LmLocation> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return parseUri(routeInformation.uri);
  }

  @override
  RouteInformation? restoreRouteInformation(LmLocation configuration) {
    return RouteInformation(
      uri: linkRestorer?.call(configuration) ?? configuration.toUri(),
    );
  }
}
