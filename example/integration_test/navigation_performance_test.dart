import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lm_flutter_router_example/src/field_orders_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('navigation interactions stay within practical frame budget', (
    tester,
  ) async {
    final timings = <FrameTiming>[];
    void collectTimings(List<FrameTiming> values) => timings.addAll(values);
    SchedulerBinding.instance.addTimingsCallback(collectTimings);
    addTearDown(
      () => SchedulerBinding.instance.removeTimingsCallback(collectTimings),
    );

    await tester.pumpWidget(const FieldOrdersApp());
    await tester.pumpAndSettle();
    timings.clear();

    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Minh Tran #1042'));
    await tester.pumpAndSettle();
    await tester.dragFrom(
      const Offset(2, 420),
      const Offset(360, 0),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();
    expect(find.text('Order #1042'), findsNothing);
    expect(find.textContaining('Minh Tran #1042'), findsWidgets);
    await tester.tap(find.textContaining('Minh Tran #1042'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Order #1042'), findsNothing);
    expect(find.textContaining('Minh Tran #1042'), findsWidgets);
    await tester.tap(find.textContaining('Minh Tran #1042'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Order actions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Mark delivered'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Mark delivered'), findsNothing);
    expect(find.text('Order #1042'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lab').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Heavy View'));
    await tester.pumpAndSettle();
    expect(find.text('Heavy View'), findsWidgets);
    expect(find.text('Lumi Music'), findsOneWidget);
    expect(find.text('Night Route'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Heavy View'), findsNothing);
    await tester.tap(find.text('Today').last);
    await tester.pumpAndSettle();

    await tester.pump(const Duration(milliseconds: 250));

    final spans = [
      for (final timing in timings)
        timing.buildDuration + timing.rasterDuration,
    ]..sort();
    expect(spans, isNotEmpty);

    final p90 = spans[(spans.length * 0.9).floor().clamp(0, spans.length - 1)];
    final worst = spans.last;
    // Keep the raw numbers visible in device runs so navigation regressions are
    // not hidden behind a broad pass/fail threshold.
    // ignore: avoid_print
    print(
      'navigation_frame_budget '
      'frames=${spans.length} '
      'p90_ms=${p90.inMicroseconds / 1000} '
      'worst_ms=${worst.inMicroseconds / 1000}',
    );
    // This test is usually run by `flutter test` in debug mode on physical
    // Android devices, where frame timings include debug overhead. It also
    // opens the deliberately dense Router Lab heavy route, so keep the worst
    // threshold broad and use the printed metrics for profile-mode follow-up.
    expect(p90, lessThan(const Duration(milliseconds: 300)));
    expect(worst, lessThan(const Duration(seconds: 3)));
  });
}
