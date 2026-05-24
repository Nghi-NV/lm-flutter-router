import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

enum LmGlassSurfaceVariant {
  bar,
  sidebar,
  panel,
  alert,
  sheet,
  actionSheet,
  popover,
}

enum LmGlassIntensity { subtle, regular, prominent }

final class LmGlassThemeData {
  const LmGlassThemeData({
    required this.enabled,
    required this.intensity,
    required this.blurSigma,
    required this.tintOpacity,
    required this.borderOpacity,
    required this.highlightOpacity,
  });

  const LmGlassThemeData.liquid({
    this.enabled = true,
    this.intensity = LmGlassIntensity.regular,
    this.blurSigma = 28,
    this.tintOpacity = 0.56,
    this.borderOpacity = 0.34,
    this.highlightOpacity = 0.18,
  });

  const LmGlassThemeData.classic()
    : enabled = false,
      intensity = LmGlassIntensity.regular,
      blurSigma = 0,
      tintOpacity = 1,
      borderOpacity = 0,
      highlightOpacity = 0;

  final bool enabled;
  final LmGlassIntensity intensity;
  final double blurSigma;
  final double tintOpacity;
  final double borderOpacity;
  final double highlightOpacity;

  double get resolvedBlurSigma {
    return switch (intensity) {
      LmGlassIntensity.subtle => blurSigma * 0.72,
      LmGlassIntensity.regular => blurSigma,
      LmGlassIntensity.prominent => blurSigma * 1.22,
    };
  }
}

final class LmGlassSurface extends StatelessWidget {
  const LmGlassSurface({
    required this.child,
    this.variant = LmGlassSurfaceVariant.panel,
    this.theme = const LmGlassThemeData.liquid(),
    this.borderRadius,
    this.padding,
    super.key,
  });

  final Widget child;
  final LmGlassSurfaceVariant variant;
  final LmGlassThemeData theme;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? _radiusFor(variant);
    final decoration = _decorationFor(
      context,
      highContrast: _highContrast(context),
    );
    final content = Padding(padding: padding ?? EdgeInsets.zero, child: child);

    if (!theme.enabled || _highContrast(context)) {
      return ClipRRect(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(decoration: decoration, child: content),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: theme.resolvedBlurSigma,
          sigmaY: theme.resolvedBlurSigma,
        ),
        child: DecoratedBox(decoration: decoration, child: content),
      ),
    );
  }

  bool _highContrast(BuildContext context) {
    return MediaQuery.maybeHighContrastOf(context) ?? false;
  }

  BoxDecoration _decorationFor(
    BuildContext context, {
    required bool highContrast,
  }) {
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final tintBase = dark ? Colors.black : Colors.white;
    final strokeBase = dark ? Colors.white : Colors.black;
    final tintOpacity = highContrast ? 0.92 : _tintOpacityFor(variant);
    final borderOpacity = highContrast ? 0.42 : theme.borderOpacity;
    return BoxDecoration(
      color: tintBase.withValues(alpha: tintOpacity),
      border: Border.all(color: strokeBase.withValues(alpha: borderOpacity)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.28 : 0.14),
          blurRadius: _shadowBlurFor(variant),
          offset: const Offset(0, 10),
        ),
      ],
      gradient: highContrast
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: theme.highlightOpacity),
                tintBase.withValues(alpha: 0),
              ],
            ),
    );
  }

  double _tintOpacityFor(LmGlassSurfaceVariant variant) {
    final base = theme.tintOpacity;
    return switch (variant) {
      LmGlassSurfaceVariant.bar => base * 0.82,
      LmGlassSurfaceVariant.sidebar => base * 0.9,
      LmGlassSurfaceVariant.panel => base,
      LmGlassSurfaceVariant.alert => base * 1.12,
      LmGlassSurfaceVariant.sheet => base * 1.08,
      LmGlassSurfaceVariant.actionSheet => base,
      LmGlassSurfaceVariant.popover => base * 1.04,
    }.clamp(0.0, 1.0);
  }

  double _shadowBlurFor(LmGlassSurfaceVariant variant) {
    return switch (variant) {
      LmGlassSurfaceVariant.bar => 22,
      LmGlassSurfaceVariant.sidebar => 18,
      LmGlassSurfaceVariant.panel => 24,
      LmGlassSurfaceVariant.alert => 34,
      LmGlassSurfaceVariant.sheet => 28,
      LmGlassSurfaceVariant.actionSheet => 28,
      LmGlassSurfaceVariant.popover => 30,
    };
  }

  BorderRadius _radiusFor(LmGlassSurfaceVariant variant) {
    return switch (variant) {
      LmGlassSurfaceVariant.bar => BorderRadius.circular(28),
      LmGlassSurfaceVariant.sidebar => BorderRadius.zero,
      LmGlassSurfaceVariant.panel => BorderRadius.circular(24),
      LmGlassSurfaceVariant.alert => BorderRadius.circular(26),
      LmGlassSurfaceVariant.sheet => const BorderRadius.vertical(
        top: Radius.circular(28),
      ),
      LmGlassSurfaceVariant.actionSheet => BorderRadius.circular(24),
      LmGlassSurfaceVariant.popover => BorderRadius.circular(24),
    };
  }
}
