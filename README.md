# lm_flutter_router

A typed adaptive Flutter router with a custom `RouterDelegate` engine.

`lm_flutter_router` owns route parsing, matching, typed params, navigation state, guards, redirects, adaptive mobile/tablet projection, transitions, modal presentation metadata, state snapshot codecs, and diagnostics. It does not depend on `go_router`.

## Features

- Custom `RouteInformationParser` and `RouterDelegate`.
- Typed route definitions with path params and page builders.
- Segment-trie route matcher with static, dynamic, wildcard, and nested route support.
- Immutable navigation state with branch stacks and modal stacks.
- Programmatic `go`, `push`, `replace`, `pop`, branch switching, and system-back handling.
- Guard pipeline with async guards, redirects, preserved intent, loop detection, and stale navigation handling.
- Adaptive layout policy and shell widget for compact, medium, and expanded layouts.
- Compact/expanded projection model for mobile stacks and tablet split panes.
- Transition descriptors, page factory, `CupertinoPageRoute` support, scale
  and hero-friendly page transitions, iOS-style modal primitives, and chrome
  metadata.
- Route state snapshot codec and navigation diagnostics events.

## Quick Start

Add the package to your Flutter app:

```yaml
dependencies:
  lm_flutter_router: ^0.0.1
```

```dart
import 'package:flutter/material.dart';
import 'package:lm_flutter_router/lm_flutter_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final router = Lm.platformRouter(
    routes: [
      Lm.page<void>(
        path: '/',
        build: (context, params) => const Text('Home'),
      ),
      Lm.page<int>(
        path: '/orders/:orderId',
        decode: (params) => Lm.params(params).requiredInt('orderId'),
        buildPath: (orderId) => '/orders/$orderId',
        build: (context, orderId) => Text('Order $orderId'),
      ),
    ],
  );

  runApp(
    MaterialApp.router(
      routerConfig: router.config,
      builder: router.scopeBuilder(autoDispose: false),
    ),
  );
}
```

`router.scopeBuilder(autoDispose: false)` provides `context.lm` to descendants
without taking ownership of the router. Use this when the router is owned by a
longer-lived object such as an app singleton, provider, or state-management
container.

Use `router.scopedBuilder()` when the router is created by the same widget
subtree and should be disposed automatically when that subtree unmounts.
`router.unownedScopedBuilder()` is kept as a compatibility alias for
`router.scopeBuilder(autoDispose: false)`.

Routes use iOS-style Cupertino push transitions by default. Set
`transition: const LmTransition.none()` explicitly for tab roots or shell routes
that should switch without page animation.

## Modals

Use the named modal factories for common presentations:

```dart
final router = Lm.router(
  routes: routes,
  modalRoutes: [
    Lm.actionSheet<int>(
      path: '/orders/:orderId/actions',
      decode: (params) => Lm.params(params).requiredInt('orderId'),
      build: (context, orderId) => OrderActionsSheet(orderId: orderId!),
    ),
    Lm.sheet<void>(
      path: '/filters',
      build: (context, _) => const FiltersSheet(),
    ),
  ],
);
```

Available modal factories are `dialog`, `cupertinoDialog`, `sheet`,
`actionSheet`, `fullscreenDialog`, and `popover`.

## Deep Links

If incoming URLs already match app paths, no deep-link config is needed. Use
`linkTransformers` for external, legacy, or reusable route families:

```dart
final router = Lm.router(
  linkTransformers: [
    Lm.links(
      normalize: (uri) => uri.host == 'field-orders.example'
          ? Lm.path('/orders/${uri.pathSegments.last}')
          : null,
    ),
    cupertinoSheetConfig,
  ],
  routes: routes,
);
```

## Guards

```dart
final router = Lm.router(
  guards: [
    Lm.guard((context) {
      final protected = context.transaction.to.path.startsWith('/orders/');
      if (!protected || authStore.isSignedIn) {
        return const LmGuardAllow();
      }
      return LmGuardRedirect.toLogin('/login', context);
    }),
  ],
  routes: routes,
);
```

Guards return `LmGuardAllow`, `LmGuardBlock`, or `LmGuardRedirect`. Redirects
keep the attempted location available to guard evaluation. Use
`LmGuardRedirect.toLogin('/login', context)` when a login screen should receive
`?returnTo=...` and resume after authentication.

Use `Lm.popGuard` when a route must block or redirect attempts to leave the
current page, such as unsaved form changes:

```dart
Lm.popGuard((context) {
  final leavingEditor = context.transaction.from?.path == '/orders/42/edit';
  if (leavingEditor && formStore.hasUnsavedChanges) {
    return const LmGuardBlock('unsaved changes');
  }
  return const LmGuardAllow();
});
```

## Adaptive Shell

```dart
LmAdaptiveShell(
  compactBuilder: (context) => const MobileTabs(),
  mediumBuilder: (context) => const TabletCompactShell(),
  expandedBuilder: (context) => const TabletSplitShell(),
);
```

For the common app-chrome case, use `LmAdaptiveChromeScaffold` instead of
manually composing the shell. Compact layouts receive your custom bottom bar;
expanded layouts receive your custom sidebar. Set `sidebarOnMedium: true` when
tablet portrait widths should use the sidebar too:

```dart
LmAdaptiveChromeScaffold(
  router: router,
  sidebarOnMedium: true,
  bottomBarBuilder: (context, router) => MyBottomTabs(router: router),
  sidebarBuilder: (context, router) => MyTabletSidebar(router: router),
  expandedContentBuilder: (context, child) => MyTabletFrame(child: child),
  child: child,
);
```

Use `LmAdaptiveRouterSplitView` when you need to project the same semantic route
stack into compact mobile navigation or expanded split-pane navigation.
`LmDetailPolicy.secondaryPaneOnExpanded` projects detail routes into the
secondary pane, `replaceSecondary` keeps only the latest detail route, and
`modalOnExpanded` keeps the detail route in a modal overlay stack on expanded
layouts.

Branch-aware navigation is path based. If the app is currently showing
`/orders/42` and you call `context.lm.go('/settings')`, the router switches the
active branch to `settings` and preserves the `orders` branch stack. Use
`context.lm.switchBranch('orders')` only when you want to switch to an existing
branch without changing that branch's current stack. Use `go` or `push` when
you want to open a specific route in another branch.

`LmChromeScaffold` hides its bottom navigation bar while router-owned modals are
open by default so dialog, sheet, action sheet, and popover barriers can use the
full app viewport. Set `hideBottomBarWhenModalOpen: false` when an app shell
intentionally keeps chrome visible behind modals.

## Verification

The package is covered by unit and widget tests for:

- route matching
- typed params and codecs
- navigation state and back behavior
- guard redirects
- adaptive projection and shell selection
- transition and modal primitives
- custom router engine behavior
- state snapshot codecs and diagnostics

Run:

```bash
flutter test
dart analyze
```

The example app also exposes a one-command local performance gate:

```bash
cd example
./tool/router_perf_gate.sh
```

## Documentation

Open [`doc/index.html`](doc/index.html) in a browser for a readable guide with
setup, recipes, API cheat sheet, iOS-style transitions, deep links, testing, and
links to the detailed markdown docs.

For app-level adoption patterns, see
[`doc/production-recipes.md`](doc/production-recipes.md).
For API stability and platform support notes, see
[`doc/api-stability.md`](doc/api-stability.md) and
[`doc/compatibility-matrix.md`](doc/compatibility-matrix.md).
For a map of the stable preview export surface, see
[`doc/public-api-reference.md`](doc/public-api-reference.md).
For a go_router migration guide, see [`doc/go-router-migration.md`](doc/go-router-migration.md).
For the shortest complete setup, see [`doc/minimal-app.md`](doc/minimal-app.md).
For the typed route codegen plan, see [`doc/typed-codegen-roadmap.md`](doc/typed-codegen-roadmap.md).

## Advanced API

Most apps should import `package:lm_flutter_router/lm_flutter_router.dart`.
`package:lm_flutter_router/lm_flutter_router_advanced.dart` exposes lower-level
delegate, matcher, state node, and page factory APIs for custom shells and
framework work. Treat the advanced surface as less stable before `1.0.0`.

## License

MIT. See [`LICENSE`](LICENSE).
