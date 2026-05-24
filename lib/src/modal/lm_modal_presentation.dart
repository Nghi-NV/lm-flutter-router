// ignore_for_file: use_super_parameters

import 'package:flutter/widgets.dart';

import '../transitions/lm_transition.dart';

enum LmModalPresentationKind {
  dialog,
  cupertinoDialog,
  bottomSheet,
  actionSheet,
  fullscreenDialog,
  popover,
}

final class LmModalPresentation {
  const LmModalPresentation._({
    required this.kind,
    required this.barrierDismissible,
    required this.usesSafeArea,
    required this.fullscreen,
    required this.transition,
  });

  const factory LmModalPresentation.dialog({
    bool barrierDismissible,
    bool usesSafeArea,
    LmTransition transition,
  }) = _LmDialogPresentation;

  const factory LmModalPresentation.cupertinoDialog({
    bool barrierDismissible,
    bool usesSafeArea,
    LmTransition transition,
  }) = _LmCupertinoDialogPresentation;

  const factory LmModalPresentation.bottomSheet({
    bool barrierDismissible,
    bool usesSafeArea,
    bool fullscreen,
    LmTransition transition,
  }) = _LmBottomSheetPresentation;

  const factory LmModalPresentation.actionSheet({
    bool barrierDismissible,
    bool usesSafeArea,
    LmTransition transition,
  }) = _LmActionSheetPresentation;

  const factory LmModalPresentation.fullscreenDialog({
    bool barrierDismissible,
    bool usesSafeArea,
    LmTransition transition,
  }) = _LmFullscreenDialogPresentation;

  const factory LmModalPresentation.popover({
    bool barrierDismissible,
    bool usesSafeArea,
    LmTransition transition,
  }) = _LmPopoverPresentation;

  final LmModalPresentationKind kind;
  final bool barrierDismissible;
  final bool usesSafeArea;
  final bool fullscreen;
  final LmTransition transition;
}

final class _LmDialogPresentation extends LmModalPresentation {
  const _LmDialogPresentation({
    bool barrierDismissible = true,
    bool usesSafeArea = true,
    LmTransition transition = const LmTransition.fade(),
  }) : super._(
         kind: LmModalPresentationKind.dialog,
         barrierDismissible: barrierDismissible,
         usesSafeArea: usesSafeArea,
         fullscreen: false,
         transition: transition,
       );
}

final class _LmCupertinoDialogPresentation extends LmModalPresentation {
  const _LmCupertinoDialogPresentation({
    bool barrierDismissible = false,
    bool usesSafeArea = true,
    LmTransition transition = const LmTransition.fade(),
  }) : super._(
         kind: LmModalPresentationKind.cupertinoDialog,
         barrierDismissible: barrierDismissible,
         usesSafeArea: usesSafeArea,
         fullscreen: false,
         transition: transition,
       );
}

final class _LmBottomSheetPresentation extends LmModalPresentation {
  const _LmBottomSheetPresentation({
    bool barrierDismissible = true,
    bool usesSafeArea = true,
    bool fullscreen = false,
    LmTransition transition = const LmTransition.slide(
      from: LmSlideFrom.bottom,
      duration: Duration(milliseconds: 300),
      curve: Curves.fastEaseInToSlowEaseOut,
    ),
  }) : super._(
         kind: LmModalPresentationKind.bottomSheet,
         barrierDismissible: barrierDismissible,
         usesSafeArea: usesSafeArea,
         fullscreen: fullscreen,
         transition: transition,
       );
}

final class _LmActionSheetPresentation extends LmModalPresentation {
  const _LmActionSheetPresentation({
    bool barrierDismissible = true,
    bool usesSafeArea = true,
    LmTransition transition = const LmTransition.slide(
      from: LmSlideFrom.bottom,
      duration: Duration(milliseconds: 300),
      curve: Curves.fastEaseInToSlowEaseOut,
    ),
  }) : super._(
         kind: LmModalPresentationKind.actionSheet,
         barrierDismissible: barrierDismissible,
         usesSafeArea: usesSafeArea,
         fullscreen: false,
         transition: transition,
       );
}

final class _LmFullscreenDialogPresentation extends LmModalPresentation {
  const _LmFullscreenDialogPresentation({
    bool barrierDismissible = false,
    bool usesSafeArea = true,
    LmTransition transition = const LmTransition.fullscreenModal(
      duration: Duration(milliseconds: 300),
      curve: Curves.fastEaseInToSlowEaseOut,
    ),
  }) : super._(
         kind: LmModalPresentationKind.fullscreenDialog,
         barrierDismissible: barrierDismissible,
         usesSafeArea: usesSafeArea,
         fullscreen: true,
         transition: transition,
       );
}

final class _LmPopoverPresentation extends LmModalPresentation {
  const _LmPopoverPresentation({
    bool barrierDismissible = true,
    bool usesSafeArea = true,
    LmTransition transition = const LmTransition.fade(),
  }) : super._(
         kind: LmModalPresentationKind.popover,
         barrierDismissible: barrierDismissible,
         usesSafeArea: usesSafeArea,
         fullscreen: false,
         transition: transition,
       );
}
