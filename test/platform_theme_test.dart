import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/lm_flutter_router.dart';

void main() {
  test('LmIosPlatformTheme applies iOS platform behavior to every target', () {
    final theme = LmIosPlatformTheme.apply(ThemeData(useMaterial3: true));

    expect(theme.platform, TargetPlatform.iOS);
    for (final platform in TargetPlatform.values) {
      expect(
        theme.pageTransitionsTheme.builders[platform],
        isA<CupertinoPageTransitionsBuilder>(),
      );
    }
  });
}
