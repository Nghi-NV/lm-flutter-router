import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_flutter_router/src/modal/lm_modal_presentation.dart';
import 'package:lm_flutter_router/src/modal/lm_modal_route_definition.dart';
import 'package:lm_flutter_router/src/transitions/lm_chrome_transition_binding.dart';
import 'package:lm_flutter_router/src/transitions/lm_transition.dart';
import 'package:lm_flutter_router/src/transitions/lm_transition_policy.dart';

void main() {
  group('LmTransition factories', () {
    test('create typed descriptors with timing metadata', () {
      const none = LmTransition.none();
      expect(none, isA<LmNoTransition>());
      expect(none.duration, Duration.zero);
      expect(none.reverseDuration, Duration.zero);
      expect(none.curve, Curves.linear);
      expect(none.gesturePopEnabled, isFalse);

      const fade = LmTransition.fade();
      expect(fade, isA<LmFadeTransition>());
      expect(fade.duration, const Duration(milliseconds: 200));
      expect(fade.reverseDuration, const Duration(milliseconds: 200));
      expect(fade.curve, Curves.easeInOut);

      const slide = LmTransition.slide(from: LmSlideFrom.left);
      expect(slide, isA<LmSlideTransition>());
      expect((slide as LmSlideTransition).from, LmSlideFrom.left);
      expect(slide.duration, const Duration(milliseconds: 500));
      expect(slide.curve, Curves.easeOutCubic);
      expect(slide.gesturePopEnabled, isTrue);

      const scale = LmTransition.scale();
      expect(scale, isA<LmScaleTransition>());
      expect(scale.duration, const Duration(milliseconds: 260));
      expect((scale as LmScaleTransition).beginScale, 0.94);
      expect(scale.gesturePopEnabled, isTrue);
    });

    test('cupertino and fullscreen modal expose gesture defaults', () {
      const cupertino = LmTransition.cupertino();
      expect(cupertino, isA<LmCupertinoTransition>());
      expect(cupertino.duration, const Duration(milliseconds: 500));
      expect(cupertino.reverseDuration, const Duration(milliseconds: 500));
      expect(cupertino.curve, Curves.easeOutCubic);
      expect(cupertino.gesturePopEnabled, isTrue);
      expect((cupertino as LmCupertinoTransition).gestureEdgeWidth, 56);

      const fullscreen = LmTransition.fullscreenModal();
      expect(fullscreen, isA<LmFullscreenModalTransition>());
      expect(fullscreen.duration, const Duration(milliseconds: 500));
      expect(fullscreen.gesturePopEnabled, isTrue);

      const sheet = LmTransition.cupertinoSheet();
      expect(sheet, isA<LmCupertinoSheetTransition>());
      expect(sheet.duration, const Duration(milliseconds: 300));
      expect(sheet.curve, Curves.fastEaseInToSlowEaseOut);
      expect(sheet.gesturePopEnabled, isTrue);

      const hero = LmTransition.hero();
      expect(hero, isA<LmHeroTransition>());
      expect(hero.duration, const Duration(milliseconds: 500));
      expect(hero.gesturePopEnabled, isTrue);
    });

    test('custom transition carries builder descriptor and metadata', () {
      const custom = LmTransition.custom(
        debugLabel: 'shared-axis',
        duration: Duration(milliseconds: 450),
        reverseDuration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );

      expect(custom, isA<LmCustomTransition>());
      expect((custom as LmCustomTransition).debugLabel, 'shared-axis');
      expect(custom.duration, const Duration(milliseconds: 450));
      expect(custom.reverseDuration, const Duration(milliseconds: 300));
      expect(custom.curve, Curves.easeIn);
      expect(custom.gesturePopEnabled, isFalse);
    });
  });

  test('LmTransitionPolicy resolves route before shell before global', () {
    const global = LmTransition.fade();
    const shell = LmTransition.slide(from: LmSlideFrom.bottom);
    const route = LmTransition.none();

    const globalOnly = LmTransitionPolicy(global: global);
    expect(globalOnly.resolve(), same(global));

    const shellOverride = LmTransitionPolicy(global: global, shell: shell);
    expect(shellOverride.resolve(), same(shell));

    const routeOverride = LmTransitionPolicy(
      global: global,
      shell: shell,
      route: route,
    );
    expect(routeOverride.resolve(), same(route));

    const adaptive = LmTransitionPolicy.adaptive();
    expect(adaptive.resolve(), isA<LmCupertinoTransition>());
  });

  testWidgets('LmTransitionPolicy applies reduced motion from context', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (value) {
            context = value;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    const policy = LmTransitionPolicy(global: LmTransition.cupertino());
    expect(policy.resolve(context: context), isA<LmNoTransition>());

    const reducedFade = LmTransition.fade(duration: Duration(milliseconds: 80));
    const customPolicy = LmTransitionPolicy(
      global: LmTransition.cupertino(),
      reducedMotionTransition: reducedFade,
    );
    expect(customPolicy.resolve(context: context), same(reducedFade));
  });

  testWidgets('LmTransitionPolicy supports custom reduced motion resolver', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (value) {
          context = value;
          return const SizedBox.shrink();
        },
      ),
    );

    final policy = LmTransitionPolicy(
      global: const LmTransition.cupertino(),
      reducedMotionResolver: (_) => true,
    );
    expect(policy.resolve(context: context), isA<LmNoTransition>());
  });

  group('LmModalPresentation factories', () {
    test('create modal descriptors with expected fields', () {
      const dialog = LmModalPresentation.dialog();
      expect(dialog.kind, LmModalPresentationKind.dialog);
      expect(dialog.barrierDismissible, isTrue);
      expect(dialog.usesSafeArea, isTrue);

      const cupertinoDialog = LmModalPresentation.cupertinoDialog();
      expect(cupertinoDialog.kind, LmModalPresentationKind.cupertinoDialog);
      expect(cupertinoDialog.barrierDismissible, isFalse);

      const bottomSheet = LmModalPresentation.bottomSheet();
      expect(bottomSheet.kind, LmModalPresentationKind.bottomSheet);
      expect(bottomSheet.fullscreen, isFalse);
      expect(
        bottomSheet.transition.duration,
        const Duration(milliseconds: 300),
      );
      expect(bottomSheet.transition.curve, Curves.fastEaseInToSlowEaseOut);

      const actionSheet = LmModalPresentation.actionSheet();
      expect(actionSheet.kind, LmModalPresentationKind.actionSheet);
      expect(actionSheet.barrierDismissible, isTrue);
      expect(
        actionSheet.transition.duration,
        const Duration(milliseconds: 300),
      );

      const fullscreenDialog = LmModalPresentation.fullscreenDialog();
      expect(fullscreenDialog.kind, LmModalPresentationKind.fullscreenDialog);
      expect(fullscreenDialog.fullscreen, isTrue);
      expect(fullscreenDialog.transition, isA<LmFullscreenModalTransition>());
      expect(
        fullscreenDialog.transition.duration,
        const Duration(milliseconds: 300),
      );

      const popover = LmModalPresentation.popover(
        barrierDismissible: false,
        usesSafeArea: false,
      );
      expect(popover.kind, LmModalPresentationKind.popover);
      expect(popover.barrierDismissible, isFalse);
      expect(popover.usesSafeArea, isFalse);
    });

    test('LmModalRouteDefinition stores route metadata', () {
      const presentation = LmModalPresentation.actionSheet();
      const transition = LmTransition.slide(from: LmSlideFrom.bottom);

      const definition = LmModalRouteDefinition(
        name: 'orderActions',
        path: '/orders/:orderId/actions',
        presentation: presentation,
        transition: transition,
        restorationId: 'order-actions',
      );

      expect(definition.name, 'orderActions');
      expect(definition.path, '/orders/:orderId/actions');
      expect(definition.presentation, same(presentation));
      expect(definition.transition, same(transition));
      expect(definition.restorationId, 'order-actions');
    });
  });

  test('LmChromeTransitionBinding exposes transition animations', () {
    final primary = kAlwaysCompleteAnimation;
    final secondary = kAlwaysDismissedAnimation;
    final gesture = ValueNotifier<double>(0.4);
    final binding = _FakeChromeTransitionBinding(
      primaryAnimation: primary,
      secondaryAnimation: secondary,
      gestureProgress: gesture,
    );

    expect(binding.primaryAnimation, same(primary));
    expect(binding.secondaryAnimation, same(secondary));
    expect(binding.gestureProgress, same(gesture));
  });
}

final class _FakeChromeTransitionBinding implements LmChromeTransitionBinding {
  const _FakeChromeTransitionBinding({
    required this.primaryAnimation,
    required this.secondaryAnimation,
    required this.gestureProgress,
  });

  @override
  final Animation<double> primaryAnimation;

  @override
  final Animation<double> secondaryAnimation;

  @override
  final ValueListenable<double>? gestureProgress;
}
