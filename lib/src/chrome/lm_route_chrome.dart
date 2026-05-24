enum LmTabBarVisibility { always, rootOnly, hidden, inherited }

final class LmRouteChrome {
  const LmRouteChrome({
    this.title,
    this.largeTitle,
    this.showBackButton,
    this.tabBarVisibility = LmTabBarVisibility.inherited,
  });

  final String? title;
  final bool? largeTitle;
  final bool? showBackButton;
  final LmTabBarVisibility tabBarVisibility;
}

final class LmNavigationBarPolicy {
  const LmNavigationBarPolicy({
    required this.largeTitle,
    required this.animateTitle,
    required this.animateBackButton,
    required this.syncWithGesturePop,
  });

  const LmNavigationBarPolicy.ios({
    this.largeTitle = true,
    this.animateTitle = true,
    this.animateBackButton = true,
    this.syncWithGesturePop = true,
  });

  final bool largeTitle;
  final bool animateTitle;
  final bool animateBackButton;
  final bool syncWithGesturePop;
}
