# Demo Catalog

This catalog maps common router use cases to concrete screens, paths, and code
locations in the example app.

## Quick Demo Path

Run the example:

```bash
cd example
flutter run
```

Then try:

1. Open **Orders**.
2. Tap an order to open `/orders/1042`.
3. Tap an order item to open `/orders/1042/items/9`.
4. Open the order actions sheet.
5. Open **Lab** and test transitions and modal presentations.
6. Resize the app past tablet width to see split-view projection.
7. Open the debug panel in debug mode to inspect location, stacks, projection,
   diagnostics, and restoration snapshots.

## Demo Matrix

| Case | Try This | What It Demonstrates | Code |
| --- | --- | --- | --- |
| Basic root route | `/` | Root page, no transition tab root | `field_orders_app.dart` dashboard route |
| Plain page navigation | `/orders` | Branch root and tab switch | `OrdersScreen` |
| Typed path params | `/orders/1042` | `decode`, `buildPath`, typed `OrderParams` | `OrderParams`, order detail route |
| Nested typed params | `/orders/1042/items/9` | Multi-param decoding and nested detail path | `OrderItemParams` |
| Branch switching | Tap bottom tabs or side menu | Preserved branch stacks | `branches` in `FieldOrdersApp` |
| Cross-branch route open | From Lab, go to Orders | Path navigation chooses owning branch | `NavigationLabScreen` |
| Detail hides tab bar | Open order detail on phone | `LmRouteChrome.tabBarVisibility` | order detail route chrome |
| Adaptive split | Resize to wide layout | Same semantic stack projected into primary/secondary panes | `FieldOrdersShell`, `LmAdaptiveRouterSplitView` |
| Router-owned action sheet | `/orders/1042/actions` | Modal route, path params, back dismiss | `Lm.actionSheet<OrderParams>` |
| Router-owned bottom sheet | `/orders/1042/reschedule` | Modal route with form-like content | `Lm.sheet<OrderParams>` |
| Dialog presentation | `/lab/modal/dialog` | Compact iOS-style dialog surface | Router Lab modal routes |
| Cupertino dialog | `/lab/modal/cupertino-dialog` | Cupertino dialog defaults | Router Lab modal routes |
| Bottom sheet | `/lab/modal/bottom-sheet` | Sheet presentation | Router Lab modal routes |
| Action sheet | `/lab/modal/action-sheet` | iOS-style action sheet surface | Router Lab modal routes |
| Fullscreen dialog | `/lab/modal/fullscreen-dialog` | Fullscreen modal presentation | Router Lab modal routes |
| Popover | `/lab/modal/popover` | Popover on wide, bottom sheet on compact | Router Lab modal routes |
| No transition | `/lab/none` | Immediate route switch | `_labTransitionRoute` |
| Fade transition | `/lab/fade` | Fade descriptor | `_labTransitionRoute` |
| Slide transitions | `/lab/slide-left`, `/lab/slide-right`, `/lab/slide-top`, `/lab/slide-bottom` | Slide directions | `_labTransitionRoute` |
| Cupertino push | `/lab/cupertino` | iOS push and back gesture | `_labTransitionRoute` |
| Fullscreen modal transition | `/lab/fullscreen` | Cupertino fullscreen route transition | `_labTransitionRoute` |
| iOS sheet transition | `/lab/cupertino-sheet` | iOS sheet-style page transition | `_labTransitionRoute` |
| Scale transition | `/lab/scale` | Scale route transition | `_labTransitionRoute` |
| Hero transition | `/lab/hero` | Hero-friendly route | `_labTransitionRoute` |
| Heavy view | `/lab/heavy` | Performance-heavy page for transition testing | `LabHeavyViewScreen` |
| Auth redirect | Sign out in Settings, then open `/orders/1042` | Guard redirect with return-to intent | `Lm.guard` in `FieldOrdersApp` |
| Deep link transformer | `https://field-orders.example/o/1042` | External URL normalization | `Lm.links` in `FieldOrdersApp` |
| Fragment deep link | `/#/orders/1042` on web | Hash-style fallback link | `Lm.links` in `FieldOrdersApp` |
| Not found | `/missing` | `notFoundRoute` fallback | `notFoundRoute` in `FieldOrdersApp` |
| Keyboard back | Escape on desktop/web | `LmRouterKeyboardShortcuts` pattern | library tests and docs |
| Diagnostics | Open debug panel | `LmRouterDiagnostics` event stream | `FieldOrdersShell` debug panel |

## Copyable Patterns

### App-Owned Router Setup

```dart
return MaterialApp.router(
  routerConfig: router.config,
  builder: router.scopeBuilder(autoDispose: false),
);
```

Use this when the router is stored on a `State`, provider, singleton, or any
object that outlives the `MaterialApp` subtree.

### Typed Page Route

```dart
final orderRoute = Lm.page<OrderParams>(
  path: '/orders/:orderId',
  decode: OrderParams.decode,
  buildPath: (params) => '/orders/${params.orderId}',
  build: (context, params) => OrderDetailScreen(orderId: params!.orderId),
);
```

Navigate with:

```dart
context.lm.push(orderRoute.location(const OrderParams(1042)));
```

### Explicit String Navigation

```dart
context.lm.goPath('/settings');
context.lm.pushPath('/orders/1042');
context.lm.presentPath('/orders/1042/actions');
```

Use the `Path` aliases when a call site intentionally uses strings.

### Router-Owned Modal

```dart
final actionsRoute = Lm.actionSheet<OrderParams>(
  path: '/orders/:orderId/actions',
  decode: OrderParams.decode,
  buildPath: (params) => '/orders/${params.orderId}/actions',
  build: (context, params) => OrderActionsSheet(orderId: params!.orderId),
);
```

Present and dismiss:

```dart
context.lm.present(actionsRoute.location(const OrderParams(1042)));
context.lm.pop();
```

### Guard With Return-To

```dart
Lm.guard((context) {
  final protected = context.current.location.path.startsWith('/orders/');
  if (!protected || session.isSignedIn) {
    return const LmGuardAllow();
  }
  return LmGuardRedirect.toLogin('/login', context);
});
```

### Branches And Adaptive Split

```dart
final router = Lm.router(
  branches: [
    Lm.branch(id: 'dashboard', root: '/'),
    Lm.branch(id: 'orders', root: '/orders'),
    Lm.branch(id: 'settings', root: '/settings'),
  ],
  routes: routes,
);

LmAdaptiveRouterSplitView(
  router: router,
  primaryPane: const OrdersListPane(),
  emptySecondary: const EmptyDetailPane(),
  child: child,
);
```

### Custom Bottom Bar And Tablet Sidebar

```dart
LmAdaptiveChromeScaffold(
  router: router,
  sidebarOnMedium: true,
  glass: const LmGlassThemeData.liquid(),
  bottomBarBuilder: (context, router) => FieldOrdersBottomTabs(router: router),
  sidebarBuilder: (context, router) => FieldOrdersSidebar(router: router),
  mediumContentBuilder: (context, child) => FieldOrdersTabletFrame(child),
  expandedContentBuilder: (context, child) => FieldOrdersTabletFrame(child),
  child: child,
);
```

### iOS 26 Liquid Glass Surface

```dart
LmGlassSurface(
  variant: LmGlassSurfaceVariant.actionSheet,
  child: OrderActionsSheet(orderId: orderId),
);
```

## Suggested Manual QA

- Direct-open every path in the demo matrix.
- On compact width, confirm pushed detail pages hide the tab bar.
- On expanded width, confirm order detail stays in the secondary pane.
- Press Android/system back from detail, modal, and root.
- Dismiss every modal with its button, barrier where allowed, and system back.
- Sign out, open a protected `/orders/...` path, sign in, and confirm return-to.
- Open debug panel and confirm diagnostics events match the last navigation.
