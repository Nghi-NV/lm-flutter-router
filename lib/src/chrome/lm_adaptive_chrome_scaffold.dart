import 'package:flutter/material.dart';

import '../adaptive/lm_adaptive_policy.dart';
import '../adaptive/lm_adaptive_shell.dart';
import '../router/lm_router.dart';
import 'lm_chrome_scaffold.dart';
import 'lm_glass_surface.dart';

typedef LmAdaptiveChromeWidgetBuilder =
    Widget? Function(BuildContext context, LmRouter router);

typedef LmAdaptiveChromeContentBuilder =
    Widget Function(BuildContext context, Widget child);

final class LmAdaptiveChromeScaffold extends StatelessWidget {
  const LmAdaptiveChromeScaffold({
    required this.router,
    required this.child,
    this.bottomBarBuilder,
    this.sidebarBuilder,
    this.compactContentBuilder,
    this.mediumContentBuilder,
    this.expandedContentBuilder,
    this.glass,
    this.sidebarOnMedium = false,
    this.sidebarWidth = 248,
    this.sidebarDivider = const VerticalDivider(width: 1),
    this.policy = const LmBreakpointPolicy(),
    this.duration = const Duration(milliseconds: 220),
    this.edgeBackGestureEnabled = false,
    this.edgeStartInset = 0,
    this.edgeWidth = 20,
    this.edgeTopInset = 0,
    this.popDistance = 72,
    this.edgeBackGesturePlatforms,
    this.hideBottomBarWhenModalOpen = true,
    super.key,
  });

  final LmRouter router;
  final Widget child;
  final LmAdaptiveChromeWidgetBuilder? bottomBarBuilder;
  final LmAdaptiveChromeWidgetBuilder? sidebarBuilder;
  final LmAdaptiveChromeContentBuilder? compactContentBuilder;
  final LmAdaptiveChromeContentBuilder? mediumContentBuilder;
  final LmAdaptiveChromeContentBuilder? expandedContentBuilder;
  final LmGlassThemeData? glass;
  final bool sidebarOnMedium;
  final double sidebarWidth;
  final Widget sidebarDivider;
  final LmAdaptiveRoutingPolicy policy;
  final Duration duration;
  final bool edgeBackGestureEnabled;
  final double edgeStartInset;
  final double edgeWidth;
  final double edgeTopInset;
  final double popDistance;
  final Set<TargetPlatform>? edgeBackGesturePlatforms;
  final bool hideBottomBarWhenModalOpen;

  @override
  Widget build(BuildContext context) {
    return LmAdaptiveShell(
      policy: policy,
      compactBuilder: _buildCompact,
      mediumBuilder: _buildMedium,
      expandedBuilder: _buildExpanded,
    );
  }

  Widget _buildCompact(BuildContext context) {
    return LmChromeScaffold(
      controller: router.controller,
      body: _wrapContent(context, child, compactContentBuilder),
      bottomNavigationBar: _wrapGlass(
        bottomBarBuilder?.call(context, router),
        LmGlassSurfaceVariant.bar,
      ),
      duration: duration,
      edgeBackGestureEnabled: edgeBackGestureEnabled,
      edgeStartInset: edgeStartInset,
      edgeWidth: edgeWidth,
      edgeTopInset: edgeTopInset,
      popDistance: popDistance,
      edgeBackGesturePlatforms: edgeBackGesturePlatforms,
      hideBottomBarWhenModalOpen: hideBottomBarWhenModalOpen,
    );
  }

  Widget _buildMedium(BuildContext context) {
    if (!sidebarOnMedium || sidebarBuilder == null) {
      return _buildCompact(context);
    }
    return _buildSidebarLayout(context, mediumContentBuilder);
  }

  Widget _buildExpanded(BuildContext context) {
    if (sidebarBuilder == null) {
      return _wrapContent(context, child, expandedContentBuilder);
    }
    return _buildSidebarLayout(context, expandedContentBuilder);
  }

  Widget _buildSidebarLayout(
    BuildContext context,
    LmAdaptiveChromeContentBuilder? contentBuilder,
  ) {
    final sidebar = _wrapGlass(
      sidebarBuilder?.call(context, router),
      LmGlassSurfaceVariant.sidebar,
    );
    final content = _wrapContent(context, child, contentBuilder);
    if (sidebar == null) {
      return content;
    }
    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: sidebarWidth, child: sidebar),
          sidebarDivider,
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _wrapContent(
    BuildContext context,
    Widget child,
    LmAdaptiveChromeContentBuilder? builder,
  ) {
    return builder == null ? child : builder(context, child);
  }

  Widget? _wrapGlass(Widget? child, LmGlassSurfaceVariant variant) {
    final glassTheme = glass;
    if (child == null || glassTheme == null) {
      return child;
    }
    return LmGlassSurface(variant: variant, theme: glassTheme, child: child);
  }
}
