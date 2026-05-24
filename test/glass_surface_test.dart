import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/lm_flutter_router.dart';

void main() {
  testWidgets('LmGlassSurface renders a liquid glass blur layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Stack(
          children: [
            ColoredBox(color: Colors.blue),
            Center(
              child: LmGlassSurface(
                variant: LmGlassSurfaceVariant.panel,
                child: SizedBox(width: 120, height: 56),
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(filter.filter, isA<ImageFilter>());
    expect(find.byType(LmGlassSurface), findsOneWidget);
  });

  testWidgets('LmGlassSurface uses an opaque fallback in high contrast', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: const Center(
            child: LmGlassSurface(
              variant: LmGlassSurfaceVariant.alert,
              child: SizedBox(width: 120, height: 56),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(LmGlassSurface), findsOneWidget);
  });
}
