import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
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
    this.blurSigma = 24,
    this.tintOpacity = 0.30,
    this.borderOpacity = 0.12,
    this.highlightOpacity = 0.34,
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
    final highContrast = _highContrast(context);
    final decoration = _decorationFor(context, highContrast: highContrast);
    final content = Padding(padding: padding ?? EdgeInsets.zero, child: child);
    final blurFilter = ImageFilter.blur(
      sigmaX: theme.resolvedBlurSigma,
      sigmaY: theme.resolvedBlurSigma,
    );
    final backdropGroup = BackdropGroup.of(context);
    if (!theme.enabled || highContrast) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    final inner = ClipRRect(
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: backdropGroup == null
          ? BackdropFilter(
              filter: blurFilter,
              child: DecoratedBox(decoration: decoration, child: content),
            )
          : BackdropFilter.grouped(
              filter: blurFilter,
              child: DecoratedBox(decoration: decoration, child: content),
            ),
    );

    final shadow = _shadowDecorationFor(context, highContrast: highContrast);
    if (shadow == null) {
      return inner;
    }
    return DecoratedBox(decoration: shadow, child: inner);
  }

  bool _highContrast(BuildContext context) {
    return MediaQuery.maybeHighContrastOf(context) ?? false;
  }

  BoxDecoration _decorationFor(
    BuildContext context, {
    required bool highContrast,
  }) {
    final brightness =
        CupertinoTheme.maybeBrightnessOf(context) ??
        Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final tintBase = highContrast
        ? scheme.surface
        : dark
        ? Colors.black
        : Colors.white;
    final strokeBase = highContrast ? scheme.onSurface : Colors.white;
    final tintOpacity = highContrast ? 1.0 : _tintOpacityFor(variant);
    final borderOpacity = highContrast ? 0.62 : theme.borderOpacity;
    return BoxDecoration(
      color: tintBase.withValues(alpha: tintOpacity),
      border: Border.all(color: strokeBase.withValues(alpha: borderOpacity)),
      gradient: highContrast
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: theme.highlightOpacity),
                Colors.white.withValues(alpha: theme.highlightOpacity * 0.22),
                tintBase.withValues(alpha: 0),
              ],
              stops: const [0, 0.48, 1],
            ),
    );
  }

  BoxDecoration? _shadowDecorationFor(
    BuildContext context, {
    required bool highContrast,
  }) {
    if (!theme.enabled || highContrast) {
      return null;
    }
    final brightness =
        CupertinoTheme.maybeBrightnessOf(context) ??
        Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: borderRadius ?? _radiusFor(variant),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.20 : 0.13),
          blurRadius: _shadowBlurFor(variant),
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  double _tintOpacityFor(LmGlassSurfaceVariant variant) {
    final base = theme.tintOpacity;
    if (!theme.enabled) {
      return base.clamp(0.0, 1.0);
    }
    return switch (variant) {
      LmGlassSurfaceVariant.bar => base * 0.82,
      LmGlassSurfaceVariant.sidebar => base * 0.88,
      LmGlassSurfaceVariant.panel => base * 0.86,
      LmGlassSurfaceVariant.alert => base * 0.96,
      LmGlassSurfaceVariant.sheet => base * 0.94,
      LmGlassSurfaceVariant.actionSheet => base * 0.88,
      LmGlassSurfaceVariant.popover => base * 0.86,
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
