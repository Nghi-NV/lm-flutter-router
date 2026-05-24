import '../core/lm_location.dart';

enum LmNavigationSource {
  programmaticGo,
  programmaticPush,
  programmaticReplace,
  programmaticPop,
  deepLink,
  browserBack,
  systemBack,
  gestureBack,
  restore,
  guardRedirect,
}

final class LmNavigationTransaction {
  const LmNavigationTransaction({
    required this.id,
    required this.source,
    required this.from,
    required this.to,
    required this.startedAt,
  });

  final int id;
  final LmNavigationSource source;
  final LmLocation? from;
  final LmLocation to;
  final DateTime startedAt;

  LmNavigationTransaction redirectTo(LmLocation location) {
    return LmNavigationTransaction(
      id: id,
      source: LmNavigationSource.guardRedirect,
      from: from,
      to: location,
      startedAt: startedAt,
    );
  }
}
