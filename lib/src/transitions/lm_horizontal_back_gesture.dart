import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

final class LmHorizontalBackGestureDetector<T> extends StatefulWidget {
  const LmHorizontalBackGestureDetector({
    required this.enabledCallback,
    required this.edgeWidth,
    required this.onStartPopGesture,
    required this.child,
    super.key,
    this.enabledListenable,
    this.hitTestBehavior = HitTestBehavior.translucent,
  });

  final Widget child;
  final ValueGetter<bool> enabledCallback;
  final Listenable? enabledListenable;
  final double edgeWidth;
  final ValueGetter<LmHorizontalBackGestureController<T>> onStartPopGesture;
  final HitTestBehavior hitTestBehavior;

  @override
  State<LmHorizontalBackGestureDetector<T>> createState() =>
      _LmHorizontalBackGestureDetectorState<T>();
}

final class _LmHorizontalBackGestureDetectorState<T>
    extends State<LmHorizontalBackGestureDetector<T>> {
  LmHorizontalBackGestureController<T>? _backGestureController;
  late final HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    final controller = _backGestureController;
    if (controller != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.navigator.mounted) {
          controller.navigator.didStopUserGesture();
        }
      });
      _backGestureController = null;
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (_backGestureController != null) {
      return;
    }
    _backGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final controller = _backGestureController;
    final width = context.size?.width;
    if (controller == null || width == null || width <= 0) {
      return;
    }
    controller.dragUpdate(
      _convertToLogical((details.primaryDelta ?? 0) / width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    final controller = _backGestureController;
    final width = context.size?.width;
    if (controller == null || width == null || width <= 0) {
      _backGestureController = null;
      return;
    }
    controller.dragEnd(
      _convertToLogical(details.velocity.pixelsPerSecond.dx / width),
    );
    _backGestureController = null;
  }

  void _handleDragCancel() {
    _backGestureController?.dragEnd(0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) {
      _recognizer.addPointer(event);
    }
  }

  double _convertToLogical(double value) {
    return switch (Directionality.of(context)) {
      TextDirection.rtl => -value,
      TextDirection.ltr => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    final listenable = widget.enabledListenable;
    if (listenable == null) {
      return _buildForGestureState(context);
    }
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, child) => _buildForGestureState(context),
    );
  }

  Widget _buildForGestureState(BuildContext context) {
    if (!widget.enabledCallback()) {
      return widget.child;
    }
    final dragAreaWidth = switch (Directionality.of(context)) {
      TextDirection.rtl => MediaQuery.paddingOf(context).right,
      TextDirection.ltr => MediaQuery.paddingOf(context).left,
    };
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: math.max(dragAreaWidth, widget.edgeWidth),
          child: Listener(
            behavior: widget.hitTestBehavior,
            onPointerDown: _handlePointerDown,
          ),
        ),
      ],
    );
  }
}

final class LmHorizontalBackGestureController<T> {
  LmHorizontalBackGestureController({
    required this.navigator,
    required this.controller,
    required this.getIsActive,
    required this.getIsCurrent,
    this.onStart,
  }) {
    onStart?.call();
    navigator.didStartUserGesture();
  }

  final NavigatorState navigator;
  final AnimationController controller;
  final ValueGetter<bool> getIsActive;
  final ValueGetter<bool> getIsCurrent;
  final VoidCallback? onStart;

  void dragUpdate(double delta) {
    controller.value = (controller.value - delta).clamp(0.0, 1.0).toDouble();
  }

  void dragEnd(double velocity) {
    const animationCurve = Curves.fastEaseInToSlowEaseOut;
    final isCurrent = getIsCurrent();
    final bool animateForward;

    if (!isCurrent) {
      animateForward = getIsActive();
    } else if (velocity.abs() >= 1.0) {
      animateForward = velocity <= 0;
    } else {
      animateForward = controller.value > 0.5;
    }

    if (animateForward) {
      controller.animateTo(
        1.0,
        duration: const Duration(milliseconds: 350),
        curve: animationCurve,
      );
    } else {
      if (isCurrent) {
        navigator.pop();
      }
      if (controller.isAnimating) {
        controller.animateBack(
          0.0,
          duration: const Duration(milliseconds: 350),
          curve: animationCurve,
        );
      }
    }

    if (controller.isAnimating) {
      late final AnimationStatusListener listener;
      listener = (_) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(listener);
      };
      controller.addStatusListener(listener);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
