import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/src/adaptive/lm_adaptive_policy.dart';
import 'package:lm_flutter_router/src/adaptive/lm_adaptive_shell.dart';

void main() {
  testWidgets(
    'LmAdaptiveShell chooses compact and expanded builders by width',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 800)),
            child: LmAdaptiveShell(
              compactBuilder: (context) => const Text('compact'),
              expandedBuilder: (context) => const Text('expanded'),
            ),
          ),
        ),
      );

      expect(find.text('compact'), findsOneWidget);
      expect(find.text('expanded'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1024, 800)),
            child: LmAdaptiveShell(
              compactBuilder: (context) => const Text('compact'),
              expandedBuilder: (context) => const Text('expanded'),
            ),
          ),
        ),
      );

      expect(find.text('expanded'), findsOneWidget);
      expect(find.text('compact'), findsNothing);
    },
  );

  testWidgets('LmAdaptiveShell can use a custom adaptive policy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(700, 800)),
          child: LmAdaptiveShell(
            policy: const LmBreakpointPolicy(
              compactMaxWidth: 720,
              expandedMinWidth: 900,
            ),
            compactBuilder: (context) => const Text('compact'),
            mediumBuilder: (context) => const Text('medium'),
            expandedBuilder: (context) => const Text('expanded'),
          ),
        ),
      ),
    );

    expect(find.text('compact'), findsOneWidget);
  });
}
