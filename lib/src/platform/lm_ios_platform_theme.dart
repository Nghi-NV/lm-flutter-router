import 'package:flutter/material.dart';

final class LmIosPlatformTheme {
  const LmIosPlatformTheme._();

  static const TargetPlatform platform = TargetPlatform.iOS;

  static const PageTransitionsTheme pageTransitionsTheme = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData apply(ThemeData theme) {
    return theme.copyWith(
      platform: platform,
      pageTransitionsTheme: pageTransitionsTheme,
    );
  }
}
