# lm_flutter_router Production Recipes

This document focuses on adoption patterns an app team needs before using the
package in production.

## Route Locations

For simple app call sites, use `LmRouteDefinition.location(...)` with
`buildPath` so path construction stays next to the route declaration. Keep
string paths at platform boundaries such as incoming links and browser URLs.

```dart
final orderDetailRoute = Lm.page<int>(
  path: '/orders/:orderId',
  decode: (params) => Lm.params(params).requiredInt('orderId'),
  buildPath: (orderId) => '/orders/$orderId',
  build: (context, orderId) => OrderDetailScreen(orderId: orderId!),
);

context.lm.push(orderDetailRoute.location(1042));
```

Use plain strings or `LmLocation` at call sites. Route-object classes are an
advanced escape hatch, not the recommended default.

When the call site intentionally uses a plain string path, prefer the explicit
aliases:

```dart
context.lm.goPath('/settings');
context.lm.pushPath('/orders/1042');
context.lm.presentPath('/orders/1042/actions');
```

Use `go`, `push`, and `present` when passing `LmLocation` or a typed route
location object.

## Auth Redirect With Return-To-Intent

Use guards for protected routes. Redirects keep the attempted destination
available during guard evaluation; `LmGuardRedirect.toLogin` encodes it into
the login URL as `returnTo` so the login screen can resume after authentication.

```dart
final router = Lm.router(
  routes: routes,
  guards: [
    Lm.guard((context) {
      final protected = context.transaction.to.path.startsWith('/orders/');
      if (!protected || session.isSignedIn) {
        return const LmGuardAllow();
      }
      return LmGuardRedirect.toLogin('/login', context);
    }),
  ],
  refreshListenable: session,
);
```

Wire `refreshListenable` so auth changes rerun guards.

## Mobile Tabs, Tablet Split, And Cross-Branch Navigation

Keep one semantic route stack. Let layout projection decide whether detail
routes render as a mobile stack or as tablet secondary pane content.

Use `LmAdaptiveChromeScaffold` for the common shell shape: custom bottom chrome
on compact layouts and custom sidebar chrome on expanded layouts. Add
`sidebarOnMedium: true` if tablet portrait widths should also use the sidebar.

```dart
LmAdaptiveChromeScaffold(
  router: router,
  sidebarOnMedium: true,
  bottomBarBuilder: (context, router) => OrdersBottomTabs(router: router),
  sidebarBuilder: (context, router) => OrdersSidebar(router: router),
  mediumContentBuilder: (context, child) => TabletHeader(child: child),
  expandedContentBuilder: (context, child) => TabletHeader(child: child),
  child: child,
);
```

```dart
Lm.page<OrderParams>(
  path: '/orders/:orderId',
  detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
  chrome: const LmRouteChrome(
    tabBarVisibility: LmTabBarVisibility.hidden,
  ),
  decode: OrderParams.decode,
  build: (context, params) => OrderDetailScreen(orderId: params!.orderId),
);
```

For expanded layouts, mount `LmAdaptiveRouterSplitView` around the router body.
Inside `MaterialApp.router.builder`, pass the provided `child`; do not create a
second raw `Router` unless you are building a custom framework integration.

```dart
LmAdaptiveRouterSplitView(
  router: router,
  primaryPane: const OrdersListPane(),
  emptySecondary: const EmptyDetailPane(),
  child: child,
);
```

### Jumping From One Branch To Another

Use path navigation when the user action should open a specific route, even if
that route belongs to another tab, side-menu item, or split-view branch.

```dart
// Current branch: orders, current stack: /orders -> /orders/42
await context.lm.go('/settings');

// Active branch becomes settings. The orders branch keeps its old stack.
```

Use `switchBranch` only when the action is a pure tab/menu switch and should
restore whatever stack the destination branch already had.

```dart
context.lm.switchBranch('orders'); // restores the existing orders stack
context.lm.go('/orders/1042');     // opens a specific route in orders
```

This matters on iPad and macOS split views: a route that belongs to the
`settings` branch should not be pushed into the secondary pane of the `orders`
branch. The router resolves ownership from `LmBranch(root: ...)` and optional
`routes`, switches `activeBranchId`, then commits the target branch stack.

## Router-Owned Modal Routes

Declare action sheets and bottom sheets as modal routes. This lets deep links,
system back, browser history, and state restoration see the modal.

```dart
final orderActionsRoute = Lm.actionSheet<OrderParams>(
  path: '/orders/:orderId/actions',
  decode: OrderParams.decode,
  buildPath: (params) => '/orders/${params.orderId}/actions',
  build: (context, params) => OrderActionsSheet(orderId: params!.orderId),
);
```

Present modals through the router:

```dart
context.lm.present(orderActionsRoute.location(OrderParams(order.id)));
```

For string paths, make modal intent explicit:

```dart
context.lm.presentPath('/orders/1042/actions');
```

Use `go('/orders/1042/actions')` for direct modal deep links. The router keeps
the background route at `/orders/1042` and reports the modal path through
`currentConfiguration`.

## Android And iOS Back Behavior

Use `LmTransition.cupertino()` for detail pages that should support iOS-style
push/pop and edge gestures.

```dart
Lm.page<void>(
  path: '/detail',
  transition: const LmTransition.cupertino(),
  build: (context, params) => const DetailScreen(),
);
```

Production checks:

- Android hardware back from detail returns to the previous route, not home.
- Android hardware back dismisses modals before pages.
- Android edge back does not double-pop.
- iOS edge swipe scrubs the page and can cancel.
- Root route back can exit the app.

For Android regressions, run the example integration smoke:

```bash
cd example
flutter test -d <android-device-id> integration_test/navigation_performance_test.dart
```

## Web And Browser History

Use platform URLs only at the boundary:

```dart
Lm.router(
  linkTransformers: [
    Lm.links(
      normalize: (uri) => uri.host == 'orders.example.com'
          ? Lm.path('/orders/${uri.pathSegments.single}')
          : null,
    ),
  ],
  routes: routes,
);
```

Browser contract to verify in app-level tests:

- Direct URL opens the same semantic state as in-app navigation.
- Browser back dismisses the top modal before popping page routes.
- Browser forward restores the modal or detail route.
- Unknown URLs render `notFoundRoute` without crashing.

## Migration From go_router

Map concepts deliberately instead of doing a mechanical rename.

| go_router concept | lm_flutter_router equivalent |
| --- | --- |
| `GoRoute` | `LmRouteDefinition` |
| `ShellRoute` / `StatefulShellRoute` | `LmBranch` + app shell + `LmAdaptiveRouterSplitView` |
| `redirect` | `Lm.guard(...)` with `LmGuardRedirect` |
| path params | `decode` + `LmCodecs` |
| `context.go` | `context.lm.go` or `router.go` |
| `context.push` | `context.lm.push` or `router.push` |
| dialog side effect | `LmModalRouteDefinition` + `present` |

### Before And After

`go_router` route:

```dart
GoRoute(
  path: '/orders/:orderId',
  builder: (context, state) {
    final orderId = int.parse(state.pathParameters['orderId']!);
    return OrderDetailScreen(orderId: orderId);
  },
)
```

Equivalent `lm_flutter_router` route:

```dart
final orderDetailRoute = Lm.page<int>(
  path: '/orders/:orderId',
  decode: (params) => Lm.params(params).requiredInt('orderId'),
  buildPath: (orderId) => '/orders/$orderId',
  detailPolicy: LmDetailPolicy.secondaryPaneOnExpanded,
  build: (context, orderId) => OrderDetailScreen(orderId: orderId!),
);
```

`go_router` redirect:

```dart
redirect: (context, state) {
  if (session.isSignedIn) return null;
  return '/login?returnTo=${Uri.encodeComponent(state.uri.toString())}';
}
```

Equivalent guard:

```dart
Lm.guard((context) {
  if (session.isSignedIn) {
    return const LmGuardAllow();
  }
  return LmGuardRedirect.toLogin('/login', context);
})
```

`ShellRoute` / `StatefulShellRoute` migration:

```dart
final router = Lm.router(
  branches: [
    Lm.branch(id: 'orders', root: '/orders'),
    Lm.branch(id: 'settings', root: '/settings'),
  ],
  routes: routes,
);
```

Inside the app shell, use `LmAdaptiveRouterSplitView` for tablet/macOS detail
projection and `context.lm.go('/settings')` when an action should jump to a
specific route in another branch.

## Troubleshooting

### Detail push flashes the tab bar

Set route chrome metadata on detail routes:

```dart
chrome: const LmRouteChrome(
  tabBarVisibility: LmTabBarVisibility.hidden,
),
```

### Tablet detail click rebuilds the whole page

Use `LmAdaptiveRouterSplitView` and mark detail routes with
`LmDetailPolicy.secondaryPaneOnExpanded`.

### Android back exits from detail

Check that back reaches `RouterDelegate.popRoute()` and that the semantic stack
has more than one node. Run with:

```bash
flutter run --dart-define=LM_ROUTER_TRACE_TRANSITIONS=true
```

Filter logs for `LM_ROUTER_TRACE`.

### Action sheet does not dismiss

For router-owned sheets, use the drag handle at the top of the sheet or call
`context.lm.pop()` / `router.pop()`. Avoid presenting Flutter modals outside
the router if the modal should participate in deep links, back, or restoration.
