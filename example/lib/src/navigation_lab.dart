import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lm_flutter_router/lm_flutter_router.dart';

final labCupertinoSheetConfig = LmCupertinoSheetNestedConfig(
  sheetPath: '/lab/cupertino-sheet',
  rootPage: LmCupertinoSheetPage(
    id: 'root',
    path: '/lab/cupertino-sheet',
    builder: (context, navigation) => _CupertinoSheetDemoPage(
      title: 'iOS 15 sheet page',
      body:
          'This is a single sheet page transition. The previous route scales '
          'and rounds behind the sheet while page content navigates inside '
          'this sheet.',
      primaryLabel: 'Dismiss sheet',
      primaryIcon: Icons.keyboard_arrow_down,
      onPrimary: navigation.dismiss,
      secondaryLabel: 'Push page above sheet',
      secondaryIcon: Icons.layers_outlined,
      onSecondary: () => navigation.push('nested'),
    ),
  ),
  pages: [
    LmCupertinoSheetPage(
      id: 'nested',
      path: '/lab/cupertino-sheet/nested',
      builder: (context, navigation) => _CupertinoSheetDemoPage(
        title: 'Nested sheet page',
        body:
            'This page is pushed inside the same sheet container, matching '
            'the CupertinoModalSheetPage + nested navigator pattern from '
            'smooth_sheets.',
        primaryLabel: 'Dismiss sheet',
        primaryIcon: Icons.keyboard_arrow_down,
        onPrimary: navigation.dismiss,
        secondaryLabel: 'Back to first sheet',
        secondaryIcon: Icons.arrow_back_ios_new,
        onSecondary: navigation.popToRoot,
      ),
    ),
  ],
);

final class NavigationLabScreen extends StatelessWidget {
  const NavigationLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.lm;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 84, 20, 28),
      children: [
        Text('Router Lab', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Exercise every router operation, transition, modal presentation, '
          'tab switch, hidden tab bar route, and deep-link friendly path.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        _Section(
          title: 'Navigation',
          children: [
            _LabAction(
              label: 'Implementation Reference',
              icon: Icons.menu_book_outlined,
              onTap: () => unawaited(router.push('/lab/reference')),
            ),
            _LabAction(
              label: 'Go to Orders',
              icon: Icons.inventory_2_outlined,
              onTap: () => unawaited(router.go('/orders')),
            ),
            _LabAction(
              label: 'Push Cupertino',
              icon: Icons.arrow_forward_ios,
              onTap: () =>
                  unawaited(router.push(labTransitionPath('cupertino'))),
            ),
            _LabAction(
              label: 'Replace with Fade',
              icon: Icons.swap_horiz,
              onTap: () => unawaited(router.replace(labTransitionPath('fade'))),
            ),
            _LabAction(
              label: 'Pop current route',
              icon: Icons.arrow_back_ios_new,
              onTap: router.pop,
            ),
            _LabAction(
              label: 'Open Heavy View',
              icon: Icons.view_agenda_outlined,
              onTap: () => unawaited(router.push('/lab/heavy')),
            ),
            _LabAction(
              label: 'iOS 26 Glass Lab',
              icon: Icons.auto_awesome,
              onTap: () => unawaited(router.push('/lab/glass')),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _Section(
          title: 'Page transitions',
          children: [
            const _TransitionButton(kind: 'none', label: 'None'),
            const _TransitionButton(kind: 'fade', label: 'Fade'),
            _TransitionButton(kind: 'slide-left', label: 'Slide left'),
            _TransitionButton(kind: 'slide-right', label: 'Slide right'),
            _TransitionButton(kind: 'slide-top', label: 'Slide top'),
            _TransitionButton(kind: 'slide-bottom', label: 'Slide bottom'),
            _TransitionButton(kind: 'cupertino', label: 'Cupertino'),
            _TransitionButton(kind: 'fullscreen', label: 'Fullscreen modal'),
            _TransitionButton(kind: 'cupertino-sheet', label: 'iOS 15 sheet'),
            const _TransitionButton(kind: 'scale', label: 'Scale'),
            const _HeroTransitionButton(),
          ],
        ),
        const SizedBox(height: 18),
        _Section(
          title: 'Modal presentations',
          children: [
            const _ModalButton(kind: 'dialog', label: 'Dialog'),
            _ModalButton(kind: 'cupertino-dialog', label: 'Cupertino dialog'),
            _ModalButton(kind: 'bottom-sheet', label: 'Cupertino sheet'),
            _ModalButton(kind: 'action-sheet', label: 'Cupertino action sheet'),
            _ModalButton(kind: 'fullscreen-dialog', label: 'Fullscreen dialog'),
            const _ModalButton(kind: 'popover', label: 'Popover'),
          ],
        ),
      ],
    );
  }
}

final class RouterReferenceScreen extends StatelessWidget {
  const RouterReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.lm;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 84, 20, 28),
      children: [
        Text(
          'Implementation Reference',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Copy these patterns when wiring the package into a real app. Each '
          'section links to a live route or modal in this example.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        _ReferencePattern(
          title: 'Minimal app setup',
          summary:
              'Use Lm.platformRouter for web/deep-link startup and wrap the '
              'app with router.scopedBuilder so context.lm works everywhere.',
          code: '''
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final router = Lm.platformRouter(routes: routes);

  runApp(MaterialApp.router(
    routerConfig: router.config,
    builder: router.scopedBuilder(),
  ));
}''',
          actions: [
            _LabAction(
              label: 'Open Lab root',
              icon: Icons.science_outlined,
              onTap: () => unawaited(router.go('/lab')),
            ),
          ],
        ),
        _ReferencePattern(
          title: 'Typed route params',
          summary:
              'Keep decoding and path building next to the route declaration. '
              'Call location(...) from buttons instead of hand-assembling URLs.',
          code: '''
final orderRoute = Lm.page<int>(
  path: '/orders/:orderId',
  decode: (params) => Lm.params(params).requiredInt('orderId'),
  buildPath: (orderId) => '/orders/\$orderId',
  build: (context, orderId) => OrderDetailScreen(orderId: orderId!),
);

context.lm.push(orderRoute.location(1042));''',
          actions: [
            _LabAction(
              label: 'Open order 1042',
              icon: Icons.inventory_2_outlined,
              onTap: () => unawaited(router.go('/orders/1042')),
            ),
            _LabAction(
              label: 'Open line item',
              icon: Icons.list_alt_outlined,
              onTap: () => unawaited(router.go('/orders/1042/items/9')),
            ),
          ],
        ),
        _ReferencePattern(
          title: 'Branches and split view',
          summary:
              'Declare branch ownership once. Path navigation then switches '
              'branches automatically while preserving other branch stacks.',
          code: '''
final router = Lm.router(
  branches: [
    Lm.branch(id: 'orders', root: '/orders'),
    Lm.branch(id: 'settings', root: '/settings'),
  ],
  routes: routes,
);

LmAdaptiveRouterSplitView(
  router: router,
  primaryPane: const OrdersListPane(),
  child: child,
);''',
          actions: [
            _LabAction(
              label: 'Jump to Settings',
              icon: Icons.settings_outlined,
              onTap: () => unawaited(router.go('/settings')),
            ),
            _LabAction(
              label: 'Return to Orders',
              icon: Icons.swap_horiz,
              onTap: () => unawaited(router.go('/orders')),
            ),
          ],
        ),
        _ReferencePattern(
          title: 'Router-owned modals',
          summary:
              'Declare sheets/dialogs as modal routes so browser history, '
              'system back, restoration, and guards all see the same state.',
          code: '''
Lm.actionSheet<int>(
  path: '/orders/:orderId/actions',
  decode: (params) => Lm.params(params).requiredInt('orderId'),
  buildPath: (orderId) => '/orders/\$orderId/actions',
  build: (context, orderId) => OrderActionsSheet(orderId: orderId!),
);

context.lm.present('/orders/1042/actions');''',
          actions: [
            _LabAction(
              label: 'Action sheet',
              icon: Icons.ios_share_outlined,
              onTap: () => unawaited(router.present('/orders/1042/actions')),
            ),
            _LabAction(
              label: 'Bottom sheet',
              icon: Icons.vertical_align_bottom,
              onTap: () => unawaited(router.present('/orders/1042/reschedule')),
            ),
          ],
        ),
        _ReferencePattern(
          title: 'Guards and return-to login',
          summary:
              'Guards redirect protected URLs to login while preserving the '
              'attempted destination in returnTo.',
          code: '''
Lm.guard((context) {
  final protected = context.transaction.to.path.startsWith('/orders/');
  if (!protected || session.isSignedIn) {
    return const LmGuardAllow();
  }
  return LmGuardRedirect.toLogin('/login', context);
});''',
          actions: [
            _LabAction(
              label: 'Protected link',
              icon: Icons.lock_outline,
              onTap: () => unawaited(router.go('/orders/1047')),
            ),
          ],
        ),
        _ReferencePattern(
          title: 'Deep links and URL migration',
          summary:
              'Use Lm.links for external URLs or legacy formats. The example '
              'maps https://field-orders.example/o/1042 to /orders/1042.',
          code: '''
Lm.links(
  normalize: (uri) => uri.host == 'field-orders.example'
      ? Lm.path('/orders/\${uri.pathSegments.last}')
      : null,
);''',
          actions: [
            _LabAction(
              label: 'External order URL',
              icon: Icons.link,
              onTap: () =>
                  unawaited(router.go('https://field-orders.example/o/1042')),
            ),
            _LabAction(
              label: 'Nested sheet deep link',
              icon: Icons.layers_outlined,
              onTap: () => unawaited(router.go('/lab/cupertino-sheet/nested')),
            ),
          ],
        ),
        _ReferencePattern(
          title: 'Performance reference',
          summary:
              'Use the heavy music route to check transitions against blur, '
              'long lists, nested scroll, and fixed overlays.',
          code: '''
cd example
./tool/router_perf_gate.sh
flutter build web --dart-define=LM_ROUTER_WEB_SMOKE=true
node tool/web_perf_smoke.mjs''',
          actions: [
            _LabAction(
              label: 'Open Heavy View',
              icon: Icons.view_agenda_outlined,
              onTap: () => unawaited(router.push('/lab/heavy')),
            ),
          ],
        ),
      ],
    );
  }
}

final class _ReferencePattern extends StatelessWidget {
  const _ReferencePattern({
    required this.title,
    required this.summary,
    required this.code,
    required this.actions,
  });

  final String title;
  final String summary;
  final String code;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(summary),
            const SizedBox(height: 12),
            _ReferenceSnippet(code: code),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ),
      ),
    );
  }
}

final class _ReferenceSnippet extends StatelessWidget {
  const _ReferenceSnippet({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: Text(
          code.trim(),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }
}

final class LabTransitionDetailScreen extends StatelessWidget {
  const LabTransitionDetailScreen({
    required this.kind,
    required this.title,
    super.key,
  });

  final String kind;
  final String title;

  @override
  Widget build(BuildContext context) {
    final router = context.lm;
    if (kind == 'cupertino-sheet') {
      return LmCupertinoSheetNavigator.bound(config: labCupertinoSheetConfig);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 84, 20, 28),
      children: [
        Hero(
          tag: 'lab-hero-transition',
          child: Icon(
            kind == 'hero' ? Icons.view_in_ar : Icons.auto_awesome_motion,
            size: 42,
            color: _accent(context),
          ),
        ),
        const SizedBox(height: 14),
        Text('$title detail', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Route path: /lab/$kind. This page hides the bottom tab bar and uses '
          'the selected transition so swipe, Android back, app-bar back, and '
          'programmatic pop can be checked in the same flow.',
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: router.pop,
          icon: const Icon(Icons.arrow_back_ios_new),
          label: const Text('Pop back to Lab'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () =>
              unawaited(router.push(labTransitionPath('cupertino'))),
          icon: const Icon(Icons.layers_outlined),
          label: const Text('Push another Cupertino route'),
        ),
      ],
    );
  }
}

final class _CupertinoSheetDemoPage extends StatelessWidget {
  const _CupertinoSheetDemoPage({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondary,
  });

  final String title;
  final String body;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final IconData secondaryIcon;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 560;
          final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 20.0;
          final topPadding = compact ? 18.0 : 24.0;
          final sectionGap = compact ? 14.0 : 20.0;
          final controlGap = compact ? 10.0 : 12.0;
          final bottomPadding = MediaQuery.paddingOf(context).bottom + 20;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: compact ? 6 : 8),
                  Text(body),
                  SizedBox(height: sectionGap),
                  FilledButton.icon(
                    onPressed: onPrimary,
                    icon: Icon(primaryIcon, size: 20),
                    label: Text(primaryLabel),
                  ),
                  SizedBox(height: controlGap),
                  OutlinedButton.icon(
                    onPressed: onSecondary,
                    icon: Icon(secondaryIcon, size: 20),
                    label: Text(secondaryLabel),
                  ),
                  SizedBox(height: compact ? 18 : 24),
                  Text(
                    'Drag down slowly to scrub the sheet with your finger.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

final class LabHeavyViewScreen extends StatelessWidget {
  const LabHeavyViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff111827), Color(0xff13251f), Color(0xff050505)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: -90,
            top: 18,
            child: _BlurredOrb(color: Color(0xff30d158), size: 240),
          ),
          const Positioned(
            right: -80,
            top: 180,
            child: _BlurredOrb(color: Color(0xff8b5cf6), size: 220),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 84, 16, 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _MusicHeader(),
                const SizedBox(height: 18),
                _MusicShelf(
                  title: 'Made for this route',
                  itemCount: 24,
                  cardBuilder: (index) => _AlbumCard(index: index),
                ),
                const SizedBox(height: 22),
                _MusicShelf(
                  title: 'Heavy blur playlists',
                  itemCount: 18,
                  cardBuilder: (index) => _BlurredPlaylistCard(index: index),
                ),
                const SizedBox(height: 22),
                Text(
                  'Queue for performance sampling',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (var index = 0; index < 72; index += 1)
                  _TrackRow(index: index),
              ],
            ),
          ),
          const Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: _NowPlayingBar(),
          ),
        ],
      ),
    );
  }
}

final class LabGlassViewScreen extends StatelessWidget {
  const LabGlassViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        const Positioned.fill(child: _DispatchMapScene()),
        Positioned.fill(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 74, 18, 142 + bottomInset),
            children: [
              const _DispatchHero(),
              const SizedBox(height: 12),
              const _DispatchRouteCard(),
              const SizedBox(height: 12),
              const _DispatchStatusPanel(),
              const SizedBox(height: 12),
              const _DispatchMetricGrid(),
              const SizedBox(height: 12),
              const _DispatchFilterBar(),
              const SizedBox(height: 12),
              _GlassModalButtons(),
            ],
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _DispatchBottomBar(),
        ),
      ],
    );
  }
}

final class _GlassModalButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final router = context.lm;
    final prefix = router.location.path.startsWith('/lab/glass')
        ? '/lab/glass/modal'
        : '/lab/modal';
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _LabAction(
          label: 'Reassign crew',
          icon: Icons.manage_accounts_outlined,
          onTap: () =>
              unawaited(router.present(labModalPath('dialog', prefix))),
        ),
        _LabAction(
          label: 'Stop detail',
          icon: Icons.vertical_align_bottom,
          onTap: () =>
              unawaited(router.present(labModalPath('bottom-sheet', prefix))),
        ),
        _LabAction(
          label: 'Route actions',
          icon: Icons.ios_share,
          onTap: () =>
              unawaited(router.present(labModalPath('action-sheet', prefix))),
        ),
        _LabAction(
          label: 'Stop preview',
          icon: Icons.web_asset_outlined,
          onTap: () =>
              unawaited(router.present(labModalPath('popover', prefix))),
        ),
      ],
    );
  }
}

final class _DispatchMapScene extends StatelessWidget {
  const _DispatchMapScene();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffdbeafe), Color(0xfff8fafc), Color(0xffd1fae5)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DispatchMapPainter())),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.64),
                    Colors.white.withValues(alpha: 0.38),
                    Colors.white.withValues(alpha: 0.24),
                  ],
                  stops: const [0, 0.42, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: 252,
            child: _MapMarker(
              color: const Color(0xff2563eb),
              offset: const Offset(0, 0),
            ),
          ),
          Positioned(
            right: 36,
            top: 356,
            child: _MapMarker(
              color: const Color(0xff059669),
              offset: const Offset(0, 0),
            ),
          ),
          Positioned(
            left: 78,
            bottom: 330,
            child: _MapMarker(
              color: const Color(0xfff97316),
              offset: const Offset(0, 0),
            ),
          ),
          Positioned(
            right: 78,
            bottom: 288,
            child: _MapMarker(
              color: const Color(0xffdb2777),
              offset: const Offset(0, 0),
            ),
          ),
        ],
      ),
    );
  }
}

final class _DispatchHero extends StatelessWidget {
  const _DispatchHero();

  @override
  Widget build(BuildContext context) {
    return LmGlassSurface(
      variant: LmGlassSurfaceVariant.popover,
      theme: const LmGlassThemeData.liquid(
        intensity: LmGlassIntensity.subtle,
        tintOpacity: 0.28,
        borderOpacity: 0.06,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dispatch Command',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xff0f172a),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Live field routing with glass controls over a real operations map.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xff334155),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _DispatchStatusPanel extends StatelessWidget {
  const _DispatchStatusPanel();

  @override
  Widget build(BuildContext context) {
    return LmGlassSurface(
      variant: LmGlassSurfaceVariant.panel,
      theme: const LmGlassThemeData.liquid(
        intensity: LmGlassIntensity.prominent,
        tintOpacity: 0.34,
        borderOpacity: 0.08,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: Color(0xff2563eb)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'North route is ahead of schedule',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xff0f172a),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '4 crews are moving through priority stops while controls stay readable above the map.',
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _GlassChip(label: 'Live route'),
                _GlassChip(label: 'ETA 18m'),
                _GlassChip(label: '4 crews'),
                _GlassChip(label: 'Priority'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _DispatchMetricGrid extends StatelessWidget {
  const _DispatchMetricGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _DispatchMetricCard(
            value: '18m',
            label: 'next arrival',
            icon: Icons.timer_outlined,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _DispatchMetricCard(
            value: '94%',
            label: 'on-time',
            icon: Icons.verified_outlined,
          ),
        ),
      ],
    );
  }
}

final class _DispatchMetricCard extends StatelessWidget {
  const _DispatchMetricCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return LmGlassSurface(
      variant: LmGlassSurfaceVariant.popover,
      theme: const LmGlassThemeData.liquid(
        intensity: LmGlassIntensity.regular,
        tintOpacity: 0.30,
        borderOpacity: 0.08,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xff1d4ed8)),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xff0f172a),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xff334155))),
          ],
        ),
      ),
    );
  }
}

final class _DispatchFilterBar extends StatelessWidget {
  const _DispatchFilterBar();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _GlassChip(label: 'All stops'),
        _GlassChip(label: 'Exceptions'),
        _GlassChip(label: 'Crew 2'),
        _GlassChip(label: 'North zone'),
      ],
    );
  }
}

final class _DispatchRouteCard extends StatelessWidget {
  const _DispatchRouteCard();

  @override
  Widget build(BuildContext context) {
    return LmGlassSurface(
      variant: LmGlassSurfaceVariant.actionSheet,
      theme: const LmGlassThemeData.liquid(
        intensity: LmGlassIntensity.regular,
        tintOpacity: 0.32,
        borderOpacity: 0.08,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xff1d4ed8),
              foregroundColor: Colors.white,
              child: Text('42'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Minh Tran #1042',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xff0f172a),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Powerline inspection - 2.4 km away',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xff334155)),
          ],
        ),
      ),
    );
  }
}

final class _DispatchBottomBar extends StatelessWidget {
  const _DispatchBottomBar();

  @override
  Widget build(BuildContext context) {
    return LmGlassSurface(
      variant: LmGlassSurfaceVariant.bar,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      theme: const LmGlassThemeData.liquid(
        intensity: LmGlassIntensity.prominent,
        tintOpacity: 0.30,
        borderOpacity: 0.08,
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.near_me, color: Color(0xff2563eb)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Live dispatch',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              FilledButton.icon(
                onPressed: () => unawaited(context.lm.pop()),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return LmGlassSurface(
      variant: LmGlassSurfaceVariant.bar,
      theme: const LmGlassThemeData.liquid(
        intensity: LmGlassIntensity.subtle,
        tintOpacity: 0.26,
        borderOpacity: 0.10,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

final class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.color, required this.offset});

  final Color color;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.16),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: SizedBox.square(
          dimension: 18,
          child: Center(
            child: SizedBox.square(
              dimension: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.86),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _DispatchMapPainter extends CustomPainter {
  const _DispatchMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _paintMapBase(canvas, size);
    _paintBlocks(canvas, size);
    _paintRoads(canvas, size);
    _paintRoute(canvas, size);
    _paintZones(canvas, size);
  }

  void _paintMapBase(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xffeef6f8),
    );

    final river = Path()
      ..moveTo(size.width * 0.72, -20)
      ..cubicTo(
        size.width * 0.92,
        size.height * 0.18,
        size.width * 0.62,
        size.height * 0.34,
        size.width * 0.88,
        size.height * 0.55,
      )
      ..cubicTo(
        size.width * 1.06,
        size.height * 0.70,
        size.width * 0.74,
        size.height * 0.84,
        size.width * 0.96,
        size.height + 40,
      )
      ..lineTo(size.width + 80, size.height + 80)
      ..lineTo(size.width + 80, -80)
      ..close();
    canvas.drawPath(
      river,
      Paint()..color = const Color(0xffbfdbfe).withValues(alpha: 0.24),
    );
  }

  void _paintBlocks(Canvas canvas, Size size) {
    final blockPaint = Paint()..color = Colors.white.withValues(alpha: 0.36);
    final greenPaint = Paint()
      ..color = const Color(0xff86efac).withValues(alpha: 0.16);
    const blockWidth = 88.0;
    const blockHeight = 54.0;
    for (var row = 0; row < size.height / 96; row += 1) {
      for (var col = 0; col < size.width / 118 + 1; col += 1) {
        final x = col * 118.0 + (row.isOdd ? -34.0 : 20.0);
        final y = row * 96.0 + 42.0;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, blockWidth, blockHeight),
          const Radius.circular(16),
        );
        canvas.drawRRect(rect, (row + col) % 5 == 0 ? greenPaint : blockPaint);
      }
    }
  }

  void _paintRoads(Canvas canvas, Size size) {
    final major = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = const Color(0xffcbd5e1).withValues(alpha: 0.25)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var y = 96.0; y < size.height; y += 128) {
      canvas.drawLine(Offset(-20, y), Offset(size.width + 20, y - 44), major);
      canvas.drawLine(Offset(-20, y), Offset(size.width + 20, y - 44), minor);
    }
    for (var x = 42.0; x < size.width; x += 124) {
      canvas.drawLine(Offset(x, -20), Offset(x + 72, size.height + 20), major);
      canvas.drawLine(Offset(x, -20), Offset(x + 72, size.height + 20), minor);
    }
  }

  void _paintRoute(Canvas canvas, Size size) {
    final route = Path()
      ..moveTo(size.width * 0.14, size.height * 0.19)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.28,
        size.width * 0.44,
        size.height * 0.20,
        size.width * 0.58,
        size.height * 0.34,
      )
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.50,
        size.width * 0.32,
        size.height * 0.57,
        size.width * 0.22,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.87,
        size.width * 0.70,
        size.height * 0.78,
        size.width * 0.80,
        size.height * 0.90,
      );

    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xff60a5fa).withValues(alpha: 0.16)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xff2563eb).withValues(alpha: 0.70)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintZones(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.72, size.height * 0.32),
        width: 170,
        height: 92,
      ),
      Paint()..color = const Color(0xfff59e0b).withValues(alpha: 0.10),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.32, size.height * 0.68),
        width: 210,
        height: 118,
      ),
      Paint()..color = const Color(0xffe11d48).withValues(alpha: 0.08),
    );
    final dotPaint = Paint()
      ..color = const Color(0xff0f172a).withValues(alpha: 0.04);
    for (var index = 0; index < 12; index += 1) {
      final center = Offset(
        (index * 73 % size.width).toDouble(),
        180 + (index * 137 % (size.height - 220)).toDouble(),
      );
      canvas.drawCircle(center, 5 + (index % 3) * 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final class _BlurredOrb extends StatelessWidget {
  const _BlurredOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 42, sigmaY: 42),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.26),
          ),
        ),
      ),
    );
  }
}

final class _MusicHeader extends StatelessWidget {
  const _MusicHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const _AlbumArt(index: 99, size: 108),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lumi Music',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xff7ddf95),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Heavy View',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'A music streaming route with blur layers, album art, '
                        'horizontal shelves, and a long playback queue.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _MusicShelf extends StatelessWidget {
  const _MusicShelf({
    required this.title,
    required this.itemCount,
    required this.cardBuilder,
  });

  final String title;
  final int itemCount;
  final Widget Function(int index) cardBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => cardBuilder(index),
          ),
        ),
      ],
    );
  }
}

final class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 144,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AlbumArt(index: index, size: 144),
          const SizedBox(height: 8),
          Text(
            _albumTitle(index),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _artistName(index),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

final class _BlurredPlaylistCard extends StatelessWidget {
  const _BlurredPlaylistCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AlbumArt(index: index + 40, size: 96),
                  const Spacer(),
                  Text(
                    'Blur Mix ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${24 + index} tracks with glass panels',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _AlbumArt extends StatelessWidget {
  const _AlbumArt({required this.index, required this.size});

  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = _palette(index);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            ),
            CustomPaint(painter: _AlbumWavePainter(seed: index)),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.graphic_eq,
                  color: Colors.white.withValues(alpha: 0.82),
                  size: size * 0.22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: index.isEven ? 0.08 : 0.04),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: ListTile(
            dense: true,
            leading: _AlbumArt(index: index + 80, size: 42),
            title: Text(
              _trackTitle(index),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${_artistName(index)} · ${2 + index % 4}:${(11 + index * 7) % 60}'
                  .padRight(5, '0'),
              style: const TextStyle(color: Colors.white60),
            ),
            trailing: Icon(
              index % 5 == 0 ? Icons.favorite : Icons.more_horiz,
              color: index % 5 == 0 ? const Color(0xff7ddf95) : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}

final class _NowPlayingBar extends StatelessWidget {
  const _NowPlayingBar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.50),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const _AlbumArt(index: 7, size: 48),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Night Route',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Glass City Ensemble',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                ),
                IconButton.filled(
                  onPressed: () {},
                  icon: const Icon(Icons.pause),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xff7ddf95),
                    foregroundColor: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _AlbumWavePainter extends CustomPainter {
  const _AlbumWavePainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.035;
    for (var ring = 0; ring < 6; ring += 1) {
      final inset = size.width * (0.12 + ring * 0.075);
      final rect = Rect.fromLTWH(
        inset,
        inset + ((seed + ring) % 5) * 2,
        size.width - inset * 2,
        size.height - inset * 2,
      );
      canvas.drawArc(rect, 0.6 + ring * 0.2, 4.2, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AlbumWavePainter oldDelegate) =>
      oldDelegate.seed != seed;
}

List<Color> _palette(int index) {
  const palettes = [
    [Color(0xff7c3aed), Color(0xff06b6d4)],
    [Color(0xff059669), Color(0xfff59e0b)],
    [Color(0xffdc2626), Color(0xfff97316)],
    [Color(0xff2563eb), Color(0xff14b8a6)],
    [Color(0xffbe185d), Color(0xff6366f1)],
    [Color(0xff0f766e), Color(0xff84cc16)],
  ];
  return palettes[index % palettes.length];
}

String _albumTitle(int index) {
  const titles = [
    'Midnight Surface',
    'Glass Commute',
    'After Hours Map',
    'Signal Bloom',
    'Low Light Pulse',
    'Sunday Buffer',
  ];
  return titles[index % titles.length];
}

String _artistName(int index) {
  const artists = [
    'Glass City Ensemble',
    'Narrow Lane',
    'Route Static',
    'Velvet Console',
    'Blue Station',
    'North Pane',
  ];
  return artists[index % artists.length];
}

String _trackTitle(int index) {
  const tracks = [
    'Night Route',
    'Warm Cache',
    'Split Pane',
    'Frame Budget',
    'Blurred Queue',
    'Native Drift',
    'Fast Back',
    'Cold Launch',
  ];
  return '${tracks[index % tracks.length]} ${index + 1}';
}

final class LabModalContent extends StatelessWidget {
  const LabModalContent({
    required this.kind,
    required this.modalPath,
    super.key,
  });

  final String kind;
  final String modalPath;

  @override
  Widget build(BuildContext context) {
    final router = context.lm;
    final isGlass = modalPath.startsWith('/lab/glass/modal');
    final title = isGlass
        ? _glassTitleFromKind(kind)
        : '${_titleFromKind(kind)} presentation';

    if (kind == 'action-sheet') {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                isGlass
                    ? 'Choose a route-level action while the live dispatch map '
                          'stays visible behind the glass surface.'
                    : 'Route-owned action sheets dim the background and use '
                          'frosted iOS popup material.',
                style: CupertinoTheme.of(context).textTheme.textStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: () => unawaited(router.pop()),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      );
    }

    if (kind == 'bottom-sheet') {
      return Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    isGlass
                        ? 'Review the next service stop, customer note, and '
                              'arrival window without leaving dispatch.'
                        : 'iOS 15 style sheet page with a top gap, rounded '
                              'surface, stacked background scale, light '
                              'barrier, and drag-to-dismiss.',
                  ),
                  const SizedBox(height: 20),
                  CupertinoButton.filled(
                    onPressed: () => unawaited(router.pop()),
                    child: const Text('Dismiss'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Drag down anywhere on this sheet to return to the map.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (kind == 'fullscreen-dialog') {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            onPressed: router.pop,
            icon: const Icon(Icons.close),
          ),
        ),
        body: _CupertinoModalPanel(
          kind: kind,
          title: title,
          modalPath: modalPath,
          isGlass: isGlass,
          centered: false,
        ),
      );
    }

    return _CupertinoModalPanel(
      kind: kind,
      title: title,
      modalPath: modalPath,
      isGlass: isGlass,
    );
  }
}

final class _CupertinoModalPanel extends StatelessWidget {
  const _CupertinoModalPanel({
    required this.kind,
    required this.title,
    required this.modalPath,
    required this.isGlass,
    this.centered = true,
  });

  final String kind;
  final String title;
  final String modalPath;
  final bool isGlass;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final router = context.lm;
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;
    final panel = Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            textAlign: centered ? TextAlign.center : TextAlign.start,
          ),
          const SizedBox(height: 8),
          Text(
            isGlass
                ? 'Keep route context visible while making a dispatch decision.'
                : 'Back dismisses the modal before popping the page stack.',
            style: textStyle,
            textAlign: centered ? TextAlign.center : TextAlign.start,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () => unawaited(router.pop()),
              child: const Text('Dismiss'),
            ),
          ),
        ],
      ),
    );
    if (!centered) {
      return panel;
    }
    final widthConstrained = IntrinsicWidth(child: panel);
    if (!isGlass) {
      return widthConstrained;
    }
    return LmGlassSurface(
      variant: kind == 'popover'
          ? LmGlassSurfaceVariant.popover
          : LmGlassSurfaceVariant.alert,
      child: widthConstrained,
    );
  }
}

final class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: children),
          ],
        ),
      ),
    );
  }
}

final class _TransitionButton extends StatelessWidget {
  const _TransitionButton({required this.kind, required this.label});

  final String kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _LabAction(
      label: label,
      icon: Icons.animation,
      onTap: () => unawaited(context.lm.push(labTransitionPath(kind))),
    );
  }
}

final class _HeroTransitionButton extends StatelessWidget {
  const _HeroTransitionButton();

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Hero(
        tag: 'lab-hero-transition',
        child: Icon(Icons.view_in_ar, size: 18, color: _accent(context)),
      ),
      label: const Text('Hero'),
      onPressed: () => unawaited(context.lm.push(labTransitionPath('hero'))),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

final class _ModalButton extends StatelessWidget {
  const _ModalButton({required this.kind, required this.label});

  final String kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _LabAction(
      label: label,
      icon: Icons.open_in_new,
      onTap: () => unawaited(context.lm.present(labModalPath(kind))),
    );
  }
}

final class _LabAction extends StatelessWidget {
  const _LabAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;

String _titleFromKind(String kind) {
  return switch (kind) {
    'none' => 'None',
    'fade' => 'Fade',
    'slide-left' => 'Slide left',
    'slide-right' => 'Slide right',
    'slide-top' => 'Slide top',
    'slide-bottom' => 'Slide bottom',
    'cupertino' => 'Cupertino',
    'fullscreen' => 'Fullscreen modal',
    'cupertino-sheet' => 'iOS 15 sheet',
    'scale' => 'Scale',
    'hero' => 'Hero',
    'dialog' => 'Dialog',
    'cupertino-dialog' => 'Cupertino dialog',
    'bottom-sheet' => 'Cupertino sheet',
    'action-sheet' => 'Cupertino action sheet',
    'fullscreen-dialog' => 'Fullscreen dialog',
    'popover' => 'Popover',
    _ => kind,
  };
}

String _glassTitleFromKind(String kind) {
  return switch (kind) {
    'dialog' => 'Reassign crew',
    'bottom-sheet' => 'Stop detail',
    'action-sheet' => 'Route actions',
    'fullscreen-dialog' => 'Escalate stop',
    'popover' => 'Stop preview',
    _ => 'Glass ${_titleFromKind(kind)}',
  };
}

String labTransitionPath(String kind) => '/lab/$kind';

String labModalPath(String kind, [String prefix = '/lab/modal']) {
  return '$prefix/$kind';
}
