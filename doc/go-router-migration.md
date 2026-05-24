# go_router Migration Guide

Use this guide when moving an app from `go_router` to `lm_flutter_router`.

## Concept Map

| go_router | lm_flutter_router |
| --- | --- |
| `GoRouter` | `Lm.router(...)` / `LmRouter` |
| `GoRoute` | `Lm.page(...)` |
| `context.go('/path')` | `context.lm.goPath('/path')` |
| `context.push('/path')` | `context.lm.pushPath('/path')` |
| `redirect` | `Lm.guard(...)` |
| `ShellRoute` | app shell + `LmChromeScaffold` |
| `StatefulShellRoute` | `Lm.branch(...)` + app shell |
| custom dialog side effect | `Lm.dialog(...)` / `Lm.actionSheet(...)` + `presentPath` |
| `go_router_builder` generated typed route | `Lm.page<T>` with `decode`, `buildPath`, and `location` |

## Basic Route

go_router:

```dart
GoRoute(
  path: '/orders/:orderId',
  builder: (context, state) {
    final orderId = int.parse(state.pathParameters['orderId']!);
    return OrderScreen(orderId: orderId);
  },
)
```

lm_flutter_router:

```dart
final orderRoute = Lm.page<int>(
  path: '/orders/:orderId',
  decode: (params) => Lm.params(params).requiredInt('orderId'),
  buildPath: (orderId) => '/orders/$orderId',
  build: (context, orderId) => OrderScreen(orderId: orderId!),
);
```

Navigate with either a typed location or an explicit string path:

```dart
context.lm.push(orderRoute.location(1042));
context.lm.pushPath('/orders/1042');
```

## Redirects And Guards

go_router:

```dart
redirect: (context, state) {
  if (session.isSignedIn) return null;
  return '/login?returnTo=${Uri.encodeComponent(state.uri.toString())}';
}
```

lm_flutter_router:

```dart
Lm.guard((context) {
  if (session.isSignedIn) {
    return const LmGuardAllow();
  }
  return LmGuardRedirect.toLogin('/login', context);
})
```

Use `refreshListenable` to rerun guards when auth/session state changes.

## Shells And Branches

go_router's `StatefulShellRoute` keeps independent branch stacks. In
`lm_flutter_router`, declare branches and let path navigation choose the owning
branch:

```dart
final router = Lm.router(
  branches: [
    Lm.branch(id: 'orders', root: '/orders'),
    Lm.branch(id: 'settings', root: '/settings'),
  ],
  routes: routes,
);
```

Use `context.lm.goPath('/settings')` when the user wants a specific location in
another branch. Use `context.lm.switchBranch('settings')` only for pure tab or
side-menu selection that should restore that branch's existing stack.

## Router-Owned Modals

In go_router, dialogs and sheets are often side effects launched from a page or
custom `Page`. In `lm_flutter_router`, prefer modal routes so URL, browser
history, back, and restore all see the modal:

```dart
final orderActionsRoute = Lm.actionSheet<int>(
  path: '/orders/:orderId/actions',
  decode: (params) => Lm.params(params).requiredInt('orderId'),
  buildPath: (orderId) => '/orders/$orderId/actions',
  build: (context, orderId) => OrderActionsSheet(orderId: orderId!),
);

context.lm.present(orderActionsRoute.location(1042));
```

Use `presentPath('/orders/1042/actions')` when the call site intentionally uses
a string path.

## Typed Routes

`go_router_builder` gives compile-time generated route classes. The current
`lm_flutter_router` runtime API uses `decode` and `buildPath` instead. This
avoids build_runner, but it is not the same level of compile-time safety.

Until codegen is added, keep route definitions in named variables and navigate
through `route.location(...)` for important app flows.
