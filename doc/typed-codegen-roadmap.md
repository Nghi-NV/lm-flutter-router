# Typed Route Codegen Roadmap

`go_router_builder` is the main DX advantage `go_router` has for large apps:
missing params and many location mistakes are caught by the compiler. Matching
that properly should be a separate builder package, not ad hoc runtime helpers.

## Target Package

Create a companion package:

```text
lm_flutter_router_builder
```

The runtime package should stay usable without build_runner.

## Proposed Authoring API

```dart
@LmTypedRoute(path: '/orders/:orderId')
final class OrderRoute extends LmTypedRouteLocation {
  const OrderRoute(this.orderId);

  final int orderId;
}
```

Generated output:

```dart
extension OrderRouteDefinition on OrderRoute {
  static LmRouteDefinition<OrderRoute> route({
    required LmRouteWidgetBuilder<OrderRoute> build,
  }) {
    return Lm.page<OrderRoute>(
      path: '/orders/:orderId',
      decode: (params) => OrderRoute(
        Lm.params(params).requiredInt('orderId'),
      ),
      buildPath: (route) => '/orders/${route.orderId}',
      build: build,
    );
  }
}
```

## Requirements

- Generate `decode` and `buildPath` from path params.
- Support path param codecs: `String`, `int`, `double`, `bool`, `DateTime`,
  enum by name.
- Generate modal route definitions for `dialog`, `sheet`, `actionSheet`,
  `fullscreenDialog`, and `popover`.
- Fail build on missing constructor fields, unsupported path param types, and
  duplicate generated paths.
- Preserve runtime package behavior for teams that do not want codegen.

## Acceptance Tests

- Missing path param field fails build.
- Unsupported param type fails build with an actionable message.
- Generated page route round-trips `location -> decode -> buildPath`.
- Generated modal route participates in `present` and browser restoration.
- Generated code passes `dart format` and `dart analyze`.

## Why Not Put This Directly In Runtime?

Runtime helpers can reduce boilerplate, but they cannot make missing params a
compile-time error. A builder package is the correct place to close the DX gap
with `go_router_builder`.
