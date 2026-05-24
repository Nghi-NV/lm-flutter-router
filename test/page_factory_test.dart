import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/src/modal/lm_modal_presentation.dart';
import 'package:lm_flutter_router/src/transitions/lm_cupertino_sheet_content_page.dart';
import 'package:lm_flutter_router/src/transitions/lm_cupertino_sheet_deep_link.dart';
import 'package:lm_flutter_router/src/transitions/lm_cupertino_sheet_nested.dart';
import 'package:lm_flutter_router/src/transitions/lm_page_factory.dart';
import 'package:lm_flutter_router/src/transitions/lm_transition.dart';

void main() {
  test(
    'LmPageFactory creates named zero-animation pages for no transition routes',
    () {
      final page = LmPageFactory.page(
        key: const ValueKey('home'),
        name: '/home',
        child: const Text('Home'),
        transition: const LmTransition.none(),
      );

      expect(page.name, '/home');
      expect(page, isA<LmNoTransitionPage<void>>());
      expect((page as LmNoTransitionPage<void>).child, isA<StatelessWidget>());
    },
  );

  testWidgets('no transition pages still use Cupertino routes for parity', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(Container(key: key));
    final page = LmPageFactory.page(
      key: const ValueKey('home'),
      name: '/home',
      child: const Text('Home'),
      transition: const LmTransition.none(),
    );

    final route = page.createRoute(key.currentContext!);

    expect(route, isA<LmCupertinoPageRoute<void>>());
    expect(
      (route as LmCupertinoPageRoute<void>).transitionDuration,
      Duration.zero,
    );
    expect(route.reverseTransitionDuration, Duration.zero);
  });

  testWidgets('right slide uses Cupertino route for iOS push parity', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(Container(key: key));
    final page = LmPageFactory.page(
      key: const ValueKey('details'),
      name: '/details',
      child: const Text('Details'),
      transition: const LmTransition.slide(),
    );

    final route = page.createRoute(key.currentContext!);

    expect(route, isA<LmCupertinoPageRoute<void>>());
    expect(route.settings.name, '/details');
    expect(
      (route as LmCupertinoPageRoute<void>).transition.gesturePopEnabled,
      isTrue,
    );
  });

  testWidgets('fade routes keep explicit fade transition', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(Container(key: key));
    final page = LmPageFactory.page(
      key: const ValueKey('fade'),
      name: '/fade',
      child: const Text('Fade'),
      transition: const LmTransition.fade(),
    );

    final route = page.createRoute(key.currentContext!);

    expect(route.settings.name, '/fade');
    expect(route, isA<PageRoute<void>>());
    expect(route, isNot(isA<LmCupertinoPageRoute<void>>()));
  });

  testWidgets('scale routes use gesture-capable scale/fade route', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(Container(key: key));
    final page = LmPageFactory.page(
      key: const ValueKey('scale'),
      name: '/scale',
      child: const Text('Scale'),
      transition: const LmTransition.scale(),
    );

    final route = page.createRoute(key.currentContext!);

    expect(route.settings.name, '/scale');
    expect(route, isA<LmCupertinoPageRoute<void>>());
    expect(
      (route as LmCupertinoPageRoute<void>).transitionDuration,
      const Duration(milliseconds: 260),
    );
    expect(route.transition.gesturePopEnabled, isTrue);
  });

  testWidgets('non-right slide routes still support edge pop gesture', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(Container(key: key));

    for (final from in [
      LmSlideFrom.left,
      LmSlideFrom.top,
      LmSlideFrom.bottom,
    ]) {
      final page = LmPageFactory.page(
        key: ValueKey('slide-$from'),
        name: '/slide-$from',
        child: const Text('Slide'),
        transition: LmTransition.slide(from: from),
      );

      final route = page.createRoute(key.currentContext!);

      expect(route, isA<LmCupertinoPageRoute<void>>());
      expect(
        (route as LmCupertinoPageRoute<void>).transition.gesturePopEnabled,
        isTrue,
      );
    }
  });

  testWidgets('fullscreen modal page routes support edge pop gesture', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(Container(key: key));
    final page = LmPageFactory.page(
      key: const ValueKey('modal'),
      name: '/modal',
      child: const Text('Modal'),
      transition: const LmTransition.fullscreenModal(),
    );

    final route = page.createRoute(key.currentContext!);

    expect(route, isA<LmCupertinoPageRoute<void>>());
    expect((route as LmCupertinoPageRoute<void>).fullscreenDialog, isTrue);
    expect(route.transition.gesturePopEnabled, isTrue);
  });

  testWidgets('hero routes use hero-friendly cupertino route', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(Container(key: key));
    final page = LmPageFactory.page(
      key: const ValueKey('hero'),
      name: '/hero',
      child: const Hero(tag: 'order-42', child: Text('Hero')),
      transition: const LmTransition.hero(),
    );

    final route = page.createRoute(key.currentContext!);

    expect(route, isA<LmCupertinoPageRoute<void>>());
    expect((route as LmCupertinoPageRoute<void>).allowSnapshotting, isFalse);
    expect(route.transition, isA<LmHeroTransition>());
    expect(route.transition.gesturePopEnabled, isTrue);
  });

  testWidgets('cupertino transitions create CupertinoPageRoute', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(Container(key: key));
    final page = LmPageFactory.page(
      key: const ValueKey('ios'),
      name: '/ios',
      child: const Text('iOS'),
      transition: const LmTransition.cupertino(),
    );

    final route = page.createRoute(key.currentContext!);

    expect(route, isA<LmCupertinoPageRoute<void>>());
    expect(route.settings.name, '/ios');
    expect(
      (route as LmCupertinoPageRoute<void>).transitionDuration,
      const Duration(milliseconds: 500),
    );
    expect(route.allowSnapshotting, isTrue);
  });

  testWidgets('cupertino transition can disable interactive pop gesture', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(Container(key: key));
    final page = LmPageFactory.page(
      key: const ValueKey('ios'),
      name: '/ios',
      child: const Text('iOS'),
      transition: const LmTransition.cupertino(gesturePopEnabled: false),
    );

    final route = page.createRoute(key.currentContext!);

    expect(route, isA<LmCupertinoPageRoute<void>>());
    expect(
      (route as LmCupertinoPageRoute<void>).transition.gesturePopEnabled,
      isFalse,
    );
  });

  testWidgets('cupertino predictive back consumes Flutter route progress', (
    tester,
  ) async {
    LmCupertinoPageRoute<void>? route;
    var popGestureStartCount = 0;
    void incrementPopGestureStart() {
      popGestureStartCount += 1;
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Navigator(
          pages: [
            const LmCupertinoPage<void>(
              key: ValueKey('root'),
              name: '/root',
              transition: LmTransition.cupertino(),
              child: Text('Root'),
            ),
            LmCupertinoPage<void>(
              key: ValueKey('detail'),
              name: '/detail',
              transition: LmTransition.cupertino(),
              onPopGestureStart: incrementPopGestureStart,
              child: _CaptureRoute(),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    route = _CaptureRoute.route;
    expect(route?.animation?.value, 1.0);

    route!.handleStartBackGesture(progress: 0.75);

    expect(route.animation?.value, closeTo(0.75, 0.001));
    expect(popGestureStartCount, 1);

    route.handleUpdateBackGestureProgress(progress: 0.35);
    expect(route.animation?.value, closeTo(0.35, 0.001));

    route.handleCancelBackGesture();
    await tester.pumpAndSettle();
  });

  testWidgets('cupertino edge drag scrubs the route animation', (tester) async {
    LmCupertinoPageRoute<void>? route;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Navigator(
          pages: const [
            LmCupertinoPage<void>(
              key: ValueKey('root'),
              name: '/root',
              transition: LmTransition.cupertino(),
              child: Text('Root'),
            ),
            LmCupertinoPage<void>(
              key: ValueKey('detail'),
              name: '/detail',
              transition: LmTransition.cupertino(),
              child: _CaptureRoute(),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    route = _CaptureRoute.route;
    expect(route?.animation?.value, 1.0);

    final gesture = await tester.startGesture(const Offset(40, 300));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();

    expect(route?.animation?.value, lessThan(1.0));
    expect(route?.animation?.value, greaterThan(0.0));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('edge drag scrubs slide, scale, and fullscreen modal routes', (
    tester,
  ) async {
    final transitions = <LmTransition>[
      const LmTransition.slide(from: LmSlideFrom.top),
      const LmTransition.slide(from: LmSlideFrom.bottom),
      const LmTransition.scale(),
      const LmTransition.fullscreenModal(),
    ];
    for (var index = 0; index < transitions.length; index += 1) {
      final transition = transitions[index];
      _CaptureRoute.route = null;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Navigator(
            pages: [
              const LmNoTransitionPage<void>(
                key: ValueKey('root'),
                name: '/root',
                child: Text('Root'),
              ),
              LmPageFactory.page(
                key: ValueKey('detail-$index-${transition.runtimeType}'),
                name: '/detail',
                transition: transition,
                child: const _CaptureRoute(),
              ),
            ],
            onDidRemovePage: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final route = _CaptureRoute.route;
      expect(route, isNotNull);
      expect(route!.animation?.value, 1.0);

      final gesture = await tester.startGesture(const Offset(24, 300));
      await gesture.moveBy(const Offset(120, 0));
      await tester.pump();

      expect(
        route.animation?.value,
        lessThan(1.0),
        reason: 'transition[$index] ${transition.runtimeType}',
      );
      expect(route.animation?.value, greaterThan(0.0));

      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('slide edge drag follows the finger linearly', (tester) async {
    _CaptureRoute.route = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Navigator(
          pages: [
            const LmNoTransitionPage<void>(
              key: ValueKey('root'),
              name: '/root',
              child: Text('Root'),
            ),
            LmPageFactory.page(
              key: const ValueKey('slide-bottom'),
              name: '/slide-bottom',
              transition: const LmTransition.slide(from: LmSlideFrom.bottom),
              child: const _CaptureRoute(),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final route = _CaptureRoute.route;
    expect(route, isNotNull);
    expect(route!.animation?.value, 1.0);

    final gesture = await tester.startGesture(const Offset(24, 300));
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();

    expect(route.animation?.value, closeTo(0.9, 0.001));
    final slide = tester.widget<SlideTransition>(
      find.byType(SlideTransition).last,
    );
    expect(slide.position.value.dx, closeTo(0.0, 0.001));
    expect(slide.position.value.dy, closeTo(0.1, 0.001));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('cupertino edge drag ignores drags outside the edge zone', (
    tester,
  ) async {
    LmCupertinoPageRoute<void>? route;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Navigator(
          pages: const [
            LmCupertinoPage<void>(
              key: ValueKey('root'),
              name: '/root',
              transition: LmTransition.cupertino(),
              child: Text('Root'),
            ),
            LmCupertinoPage<void>(
              key: ValueKey('detail'),
              name: '/detail',
              transition: LmTransition.cupertino(),
              child: _CaptureRoute(),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    route = _CaptureRoute.route;

    final gesture = await tester.startGesture(const Offset(80, 300));
    await gesture.moveBy(const Offset(160, 0));
    await tester.pump();

    expect(route?.animation?.value, 1.0);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('cupertino edge drag owns the Android physical edge', (
    tester,
  ) async {
    LmCupertinoPageRoute<void>? route;
    var popGestureStartCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Navigator(
          pages: [
            const LmCupertinoPage<void>(
              key: ValueKey('root'),
              name: '/root',
              transition: LmTransition.cupertino(),
              child: Text('Root'),
            ),
            LmCupertinoPage<void>(
              key: const ValueKey('detail'),
              name: '/detail',
              transition: const LmTransition.cupertino(),
              onPopGestureStart: () {
                popGestureStartCount += 1;
              },
              child: const _CaptureRoute(),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    route = _CaptureRoute.route;

    final gesture = await tester.startGesture(const Offset(1, 300));
    await gesture.moveBy(const Offset(160, 0));
    await tester.pump();

    expect(popGestureStartCount, 1);
    expect(route?.animation?.value, lessThan(1.0));
    expect(route?.animation?.value, greaterThan(0.0));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('cupertino edge drag on Android starts after OEM edge reserve', (
    tester,
  ) async {
    LmCupertinoPageRoute<void>? route;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Navigator(
          pages: const [
            LmCupertinoPage<void>(
              key: ValueKey('root'),
              name: '/root',
              transition: LmTransition.cupertino(),
              child: Text('Root'),
            ),
            LmCupertinoPage<void>(
              key: ValueKey('detail'),
              name: '/detail',
              transition: LmTransition.cupertino(),
              child: _CaptureRoute(),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    route = _CaptureRoute.route;

    final gesture = await tester.startGesture(const Offset(180, 300));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();

    expect(route?.animation?.value, lessThan(1.0));
    expect(route?.animation?.value, greaterThan(0.0));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  test('LmModalPage stores modal presentation route metadata', () {
    const presentation = LmModalPresentation.actionSheet();
    final page = LmPageFactory.modalPage(
      key: const ValueKey('actions'),
      name: '/orders/42/actions',
      child: const Text('Actions'),
      presentation: presentation,
    );

    expect(page.name, '/orders/42/actions');
    expect(page.presentation, same(presentation));
  });

  testWidgets('modal pages create expected route types and barriers', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(home: SizedBox(key: key)));
    final context = key.currentContext!;

    final dialog = LmPageFactory.modalPage(
      key: const ValueKey('dialog'),
      name: '/dialog',
      child: const Text('Dialog'),
      presentation: const LmModalPresentation.dialog(barrierDismissible: false),
    ).createRoute(context);
    expect(dialog, isA<PageRoute<void>>());
    expect(dialog, isNot(isA<CupertinoDialogRoute<void>>()));
    expect(dialog, isNot(isA<DialogRoute<void>>()));
    expect((dialog as ModalRoute<void>).barrierDismissible, isFalse);

    final cupertinoDialog = LmPageFactory.modalPage(
      key: const ValueKey('cupertino-dialog'),
      name: '/cupertino-dialog',
      child: const Text('Cupertino Dialog'),
      presentation: const LmModalPresentation.cupertinoDialog(),
    ).createRoute(context);
    expect(cupertinoDialog, isA<PageRoute<void>>());
    expect(cupertinoDialog, isNot(isA<CupertinoDialogRoute<void>>()));

    final popover = LmPageFactory.modalPage(
      key: const ValueKey('popover'),
      name: '/popover',
      child: const Text('Popover'),
      presentation: const LmModalPresentation.popover(),
    ).createRoute(context);
    expect(popover, isA<PageRoute<void>>());
    expect(popover, isNot(isA<DialogRoute<void>>()));

    final actionSheet = LmPageFactory.modalPage(
      key: const ValueKey('actions'),
      name: '/actions',
      child: const Text('Actions'),
      presentation: const LmModalPresentation.actionSheet(),
    ).createRoute(context);
    final actionSheetPage = actionSheet as PageRoute<void>;
    expect(actionSheetPage, isNot(isA<CupertinoModalPopupRoute<void>>()));
    expect(actionSheetPage.opaque, isFalse);
    expect(actionSheetPage.barrierDismissible, isTrue);
    expect(
      actionSheetPage.transitionDuration,
      const Duration(milliseconds: 300),
    );
    expect(
      CupertinoDynamicColor.resolve(
        actionSheetPage.barrierColor!,
        context,
      ).toARGB32(),
      const Color(0x33000000).toARGB32(),
    );
    expect(actionSheetPage.delegatedTransition, isNotNull);

    final bottomSheet = LmPageFactory.modalPage(
      key: const ValueKey('bottom-sheet'),
      name: '/bottom-sheet',
      child: const Text('Bottom Sheet'),
      presentation: const LmModalPresentation.bottomSheet(
        fullscreen: true,
        barrierDismissible: false,
      ),
    ).createRoute(context);
    final bottomSheetPage = bottomSheet as PageRoute<void>;
    expect(bottomSheetPage.opaque, isTrue);
    expect(bottomSheetPage.barrierDismissible, isFalse);

    final fullscreen = LmPageFactory.modalPage(
      key: const ValueKey('fullscreen'),
      name: '/fullscreen',
      child: const Text('Fullscreen'),
      presentation: const LmModalPresentation.fullscreenDialog(),
    ).createRoute(context);
    final fullscreenPage = fullscreen as PageRoute<void>;
    expect(fullscreenPage.opaque, isTrue);
    expect(fullscreenPage.barrierDismissible, isFalse);
    expect(
      fullscreenPage.transitionDuration,
      const Duration(milliseconds: 300),
    );
  });

  testWidgets('modal pages honor custom transition descriptors', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(home: SizedBox(key: key)));
    final context = key.currentContext!;

    final dialog =
        LmPageFactory.modalPage(
              key: const ValueKey('dialog'),
              name: '/dialog',
              child: const Text('Dialog'),
              presentation: const LmModalPresentation.dialog(
                transition: LmTransition.scale(
                  beginScale: 0.8,
                  duration: Duration(milliseconds: 123),
                ),
              ),
            ).createRoute(context)
            as PageRoute<void>;
    expect(dialog.transitionDuration, const Duration(milliseconds: 123));

    final noTransitionSheet =
        LmPageFactory.modalPage(
              key: const ValueKey('sheet'),
              name: '/sheet',
              child: const Text('Sheet'),
              presentation: const LmModalPresentation.bottomSheet(
                transition: LmTransition.none(),
              ),
            ).createRoute(context)
            as PageRoute<void>;
    expect(noTransitionSheet.transitionDuration, Duration.zero);
    expect(noTransitionSheet.reverseTransitionDuration, Duration.zero);

    final topPopover =
        LmPageFactory.modalPage(
              key: const ValueKey('popover'),
              name: '/popover',
              child: const Text('Popover'),
              presentation: const LmModalPresentation.popover(
                transition: LmTransition.slide(
                  from: LmSlideFrom.top,
                  duration: Duration(milliseconds: 321),
                ),
              ),
            ).createRoute(context)
            as PageRoute<void>;
    expect(topPopover.transitionDuration, const Duration(milliseconds: 321));
  });

  testWidgets('action sheets use iOS compact margins and width caps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          pages: [
            const MaterialPage<void>(child: SizedBox.shrink()),
            LmPageFactory.modalPage(
              key: const ValueKey('actions'),
              name: '/actions',
              child: const SizedBox(
                key: ValueKey('sheet-content'),
                height: 120,
                child: Text('Actions'),
              ),
              presentation: const LmModalPresentation.actionSheet(
                transition: LmTransition.none(),
              ),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final contentRect = tester.getRect(
      find.byKey(const ValueKey('sheet-content')),
    );
    expect(contentRect.left, greaterThanOrEqualTo(8));
    expect(contentRect.right, lessThanOrEqualTo(382));
    expect(contentRect.bottom, 844);
  });

  testWidgets(
    'wide action sheets stay readable instead of stretching full width',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            pages: [
              const MaterialPage<void>(child: SizedBox.shrink()),
              LmPageFactory.modalPage(
                key: const ValueKey('actions'),
                name: '/actions',
                child: const SizedBox(
                  key: ValueKey('sheet-content'),
                  height: 120,
                  child: Text('Actions'),
                ),
                presentation: const LmModalPresentation.actionSheet(
                  transition: LmTransition.none(),
                ),
              ),
            ],
            onDidRemovePage: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final contentRect = tester.getRect(
        find.byKey(const ValueKey('sheet-content')),
      );
      expect(contentRect.width, lessThanOrEqualTo(414));
      expect(contentRect.center.dx, closeTo(512, 1));
    },
  );

  testWidgets('compact popovers adapt to a bottom sheet presentation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          pages: [
            const MaterialPage<void>(child: SizedBox.shrink()),
            LmPageFactory.modalPage(
              key: const ValueKey('popover'),
              name: '/popover',
              child: const SizedBox(
                key: ValueKey('popover-content'),
                height: 120,
                child: Text('Popover'),
              ),
              presentation: const LmModalPresentation.popover(
                transition: LmTransition.none(),
              ),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final contentRect = tester.getRect(
      find.byKey(const ValueKey('popover-content')),
    );
    expect(contentRect.bottom, 844);
    expect(contentRect.width, lessThanOrEqualTo(374));
  });

  testWidgets('iOS action sheets render frosted material over the backdrop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          pages: [
            const MaterialPage<void>(child: ColoredBox(color: Colors.blue)),
            LmPageFactory.modalPage(
              key: const ValueKey('actions'),
              name: '/actions',
              child: const SizedBox(
                key: ValueKey('sheet-content'),
                height: 120,
                child: Text('Actions'),
              ),
              presentation: const LmModalPresentation.actionSheet(
                transition: LmTransition.none(),
              ),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('custom iOS dialogs render as compact blurred alert material', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          pages: [
            const MaterialPage<void>(child: ColoredBox(color: Colors.blue)),
            LmPageFactory.modalPage(
              key: const ValueKey('dialog'),
              name: '/dialog',
              child: const SizedBox(
                key: ValueKey('dialog-content'),
                height: 80,
                child: Text('Dialog'),
              ),
              presentation: const LmModalPresentation.dialog(
                transition: LmTransition.none(),
              ),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final contentRect = tester.getRect(
      find.byKey(const ValueKey('dialog-content')),
    );
    expect(contentRect.width, lessThanOrEqualTo(270));
    expect(find.byType(CupertinoPopupSurface), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('custom iOS modal barriers resolve darker in dark mode', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final route =
        LmPageFactory.modalPage(
              key: const ValueKey('dialog'),
              name: '/dialog',
              child: const Text('Dialog'),
              presentation: const LmModalPresentation.dialog(
                transition: LmTransition.none(),
              ),
            ).createRoute(context)
            as PageRoute<void>;

    expect(
      CupertinoDynamicColor.resolve(route.barrierColor!, context).toARGB32(),
      const Color(0x7A000000).toARGB32(),
    );
  });

  testWidgets('cupertino modal sheets scale and round the background route', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final route =
        LmPageFactory.modalPage(
              key: const ValueKey('actions'),
              name: '/actions',
              child: const Text('Actions'),
              presentation: const LmModalPresentation.actionSheet(),
            ).createRoute(context)
            as PageRoute<void>;

    final controller = AnimationController(
      vsync: tester,
      value: 1,
      duration: const Duration(milliseconds: 300),
    );
    addTearDown(controller.dispose);

    final delegated = route.delegatedTransition!(
      context,
      kAlwaysCompleteAnimation,
      controller,
      true,
      const Text('Background'),
    );
    await tester.pumpWidget(MaterialApp(home: delegated));

    final scale = tester.widget<Transform>(
      find.byWidgetPredicate(
        (widget) => widget is Transform && widget.transform.storage[0] < 1.0,
      ),
    );
    expect(scale.transform.storage[0], closeTo(0.92, 0.001));
    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
    expect(clip.borderRadius, BorderRadius.circular(12));
    expect(find.text('Background'), findsOneWidget);
  });

  testWidgets('cupertino sheet page transition creates iOS 15 sheet route', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final page = LmPageFactory.page(
      key: const ValueKey('sheet-page'),
      name: '/sheet-page',
      child: const Text('Sheet Page'),
      transition: const LmTransition.cupertinoSheet(),
    );
    final route = page.createRoute(context) as PageRoute<void>;

    expect(route.opaque, isFalse);
    expect(route.barrierColor, const Color(0x00000000));
    expect(route.transitionDuration, const Duration(milliseconds: 300));
    expect(route.delegatedTransition, isNotNull);
  });

  testWidgets('cupertino sheet page uses iOS sheet slide without fade', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final page = LmPageFactory.page(
      key: const ValueKey('sheet-page'),
      name: '/sheet-page',
      child: const Text('Sheet Page'),
      transition: const LmTransition.cupertinoSheet(),
    );
    final route = page.createRoute(context) as PageRoute<void>;
    final transitions = route.buildTransitions(
      context,
      kAlwaysCompleteAnimation,
      kAlwaysDismissedAnimation,
      const Text('Sheet Page'),
    );

    await tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: transitions),
    );

    expect(find.byType(SlideTransition), findsOneWidget);
    expect(find.byType(FadeTransition), findsNothing);
    expect(find.text('Sheet Page'), findsOneWidget);
  });

  testWidgets('cupertino sheet page can disable drag dismiss wrapper', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final page = LmPageFactory.page(
      key: const ValueKey('sheet-page'),
      name: '/sheet-page',
      child: const Text('Sheet Page'),
      transition: const LmTransition.cupertinoSheet(gesturePopEnabled: false),
    );
    final route = page.createRoute(context) as PageRoute<void>;
    final body = route.buildPage(
      context,
      kAlwaysCompleteAnimation,
      kAlwaysDismissedAnimation,
    );

    await tester.pumpWidget(MaterialApp(home: body));

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Listener && widget.onPointerMove != null,
      ),
      findsNothing,
    );
    expect(find.text('Sheet Page'), findsOneWidget);
  });

  testWidgets('stacked cupertino sheets lift the sheet underneath', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          pages: [
            const LmNoTransitionPage<void>(
              key: ValueKey('root'),
              name: '/root',
              child: Text('Root'),
            ),
            LmPageFactory.page(
              key: const ValueKey('lower-sheet'),
              name: '/lower-sheet',
              child: const Text('Lower Sheet'),
              transition: const LmTransition.cupertinoSheet(),
            ),
            LmPageFactory.page(
              key: const ValueKey('upper-sheet'),
              name: '/upper-sheet',
              child: const Text('Upper Sheet'),
              transition: const LmTransition.cupertinoSheet(),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final transforms = tester.widgetList<Transform>(find.byType(Transform));
    expect(
      transforms.map((widget) => widget.transform.storage[13]),
      contains(closeTo(-12, 0.001)),
    );
  });

  testWidgets('sheet content root page does not block edge taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          pages: [
            LmCupertinoSheetContentPage<void>(
              key: const ValueKey('sheet-content-root'),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => taps += 1,
                  child: const Text('Edge action'),
                ),
              ),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edge action'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  test('cupertino sheet deep link maps nested paths to sheet state', () {
    const deepLink = LmCupertinoSheetDeepLink(
      sheetPath: '/lab/cupertino-sheet',
      nestedPath: '/lab/cupertino-sheet/nested',
      nestedPage: 'nested',
    );

    final location = deepLink.normalize(
      Uri.parse('/lab/cupertino-sheet/nested?source=test#section'),
    );

    expect(location, isNotNull);
    expect(location!.path, '/lab/cupertino-sheet');
    expect(location.query, {'source': 'test', 'sheetPage': 'nested'});
    expect(location.fragment, 'section');
    expect(deepLink.isSelected(location), isTrue);
    expect(
      deepLink.restore(location).toString(),
      '/lab/cupertino-sheet/nested?source=test#section',
    );
  });

  test(
    'cupertino sheet nested config builds router-owned nested locations',
    () {
      final config = LmCupertinoSheetNestedConfig(
        sheetPath: '/lab/cupertino-sheet',
        rootPage: LmCupertinoSheetPage(
          id: 'root',
          path: '/lab/cupertino-sheet',
          builder: (context, navigation) => const SizedBox.shrink(),
        ),
        pages: [
          LmCupertinoSheetPage(
            id: 'nested',
            path: '/lab/cupertino-sheet/nested',
            builder: (context, navigation) => const SizedBox.shrink(),
          ),
        ],
      );

      expect(config.pathFor('root'), '/lab/cupertino-sheet');
      expect(config.pathFor('nested'), '/lab/cupertino-sheet?sheetPage=nested');
    },
  );

  testWidgets('bottom modals dismiss from a downward drag on the sheet body', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _ModalHost()));
    await tester.pumpAndSettle();

    expect(find.text('Sheet Body'), findsOneWidget);

    await tester.drag(find.text('Sheet Body'), const Offset(0, 220));
    await tester.pumpAndSettle();

    expect(find.text('Sheet Body'), findsNothing);
  });

  testWidgets('bottom modals settle back after a short downward drag', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _ModalHost()));
    await tester.pumpAndSettle();

    expect(find.text('Sheet Body'), findsOneWidget);

    await tester.drag(find.text('Sheet Body'), const Offset(0, 40));
    await tester.pumpAndSettle();

    expect(find.text('Sheet Body'), findsOneWidget);
  });

  testWidgets('bottom modals scrub the route animation during downward drag', (
    tester,
  ) async {
    ModalRoute<void>? route;
    _CaptureModalRoute.onRoute = (captured) {
      route = captured;
    };
    addTearDown(() {
      _CaptureModalRoute.onRoute = null;
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: _ModalHost(
          child: SizedBox(
            height: 240,
            child: Center(child: _CaptureModalRoute()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(route?.animation?.value, 1.0);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Sheet Body')),
    );
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();

    expect(route?.animation?.value, lessThan(1.0));
    expect(route?.animation?.value, greaterThan(0.0));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('fullscreen modal presentations scrub from an edge pop drag', (
    tester,
  ) async {
    ModalRoute<void>? route;
    _CaptureModalRoute.onRoute = (captured) {
      route = captured;
    };
    addTearDown(() {
      _CaptureModalRoute.onRoute = null;
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: _ModalHost(
          presentation: LmModalPresentation.fullscreenDialog(),
          child: SizedBox.expand(child: Center(child: _CaptureModalRoute())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(route?.animation?.value, 1.0);

    final gesture = await tester.startGesture(const Offset(24, 300));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();

    expect(route?.animation?.value, lessThan(1.0));
    expect(route?.animation?.value, greaterThan(0.0));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('action sheets dismiss from a downward drag on the sheet body', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _ModalHost(
          presentation: LmModalPresentation.actionSheet(),
          child: CupertinoActionSheet(
            title: Text('Sheet Body'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: _noop,
                child: Text('Confirm'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: _noop,
              child: Text('Cancel'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sheet Body'), findsOneWidget);

    await tester.drag(find.text('Sheet Body'), const Offset(0, 220));
    await tester.pumpAndSettle();

    expect(find.text('Sheet Body'), findsNothing);
  });
}

void _noop() {}

final class _CaptureRoute extends StatelessWidget {
  const _CaptureRoute();

  static LmCupertinoPageRoute<void>? route;

  @override
  Widget build(BuildContext context) {
    route = ModalRoute.of<void>(context) as LmCupertinoPageRoute<void>;
    return const Text('Detail');
  }
}

final class _ModalHost extends StatefulWidget {
  const _ModalHost({
    this.presentation = const LmModalPresentation.bottomSheet(),
    this.child = const SizedBox(
      height: 240,
      child: Center(child: Text('Sheet Body')),
    ),
  });

  final LmModalPresentation presentation;
  final Widget child;

  @override
  State<_ModalHost> createState() => _ModalHostState();
}

final class _ModalHostState extends State<_ModalHost> {
  bool _showSheet = true;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      pages: [
        const LmNoTransitionPage<void>(
          key: ValueKey('root'),
          name: '/root',
          child: Text('Root'),
        ),
        if (_showSheet)
          LmModalPage<void>(
            key: const ValueKey('sheet'),
            name: '/sheet',
            presentation: widget.presentation,
            child: widget.child,
          ),
      ],
      onDidRemovePage: (page) {
        if (page.name == '/sheet') {
          setState(() {
            _showSheet = false;
          });
        }
      },
    );
  }
}

final class _CaptureModalRoute extends StatelessWidget {
  const _CaptureModalRoute();

  static void Function(ModalRoute<void> route)? onRoute;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of<void>(context);
    if (route != null) {
      onRoute?.call(route);
    }
    return const Text('Sheet Body');
  }
}
