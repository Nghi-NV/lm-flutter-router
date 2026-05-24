# Public API Reference

Date: 2026-05-20

Use this document as the adoption map for the stable preview import:

```dart
import 'package:lm_flutter_router/lm_flutter_router.dart';
```

Generated dartdoc is validated with:

```bash
dart doc --dry-run
```

## Router Setup

- `Lm`: short factory namespace for common app setup. Prefer `Lm.router(...)`,
  `Lm.platformRouter(...)`, `Lm.page(...)`, `Lm.sheet(...)`, `Lm.branch(...)`,
  `Lm.path(...)`, `Lm.params(...)`, `Lm.links(...)`, and `Lm.guard(...)` in
  application code.
- `LmRouter`, `LmRouter.app`, `LmRouter.platformApp`: owns route parsing,
  delegate state, guards, modal routes, branch config, diagnostics, and
  `RouterConfig`.
- `LmRouteInformationParser`: converts browser/platform route information into
  `LmLocation` and restores `LmLocation` back to `RouteInformation`.
- `LmLinkTransformer`, `Lm.links(...)`: maps incoming universal links into
  internal app locations and optionally restores locations to URLs.
- `LmRouterScope`, `BuildContext.lm`, `router.scopeBuilder(...)`,
  `router.scopedBuilder(...)`: ergonomic app-level navigation helpers. Prefer
  `scopeBuilder(autoDispose: false)` when the router is app-owned by a
  singleton, provider, or state-management container. Use `scopedBuilder()`
  when the subtree should own and dispose the router.
- `LmRouterKeyboardShortcuts`, `LmRouterBackIntent`: optional desktop/web
  keyboard shortcut wrapper for router-owned back navigation.

## Locations And Typed Routes

- `LmLocation`: immutable canonical path/query/fragment/extra value.
- `LmRouteDefinition<TParams>.page`, `LmRouteDefinition.location(...)`: page
  route declaration with typed decoding, path building, transition, chrome
  metadata, and detail policy. Dynamic and wildcard paths require non-null
  params plus `buildPath`; this fails fast instead of returning a path template.
- `LmModalRouteDefinition<TParams>.dialog`, `cupertinoDialog`, `sheet`,
  `actionSheet`, `fullscreenDialog`, and `popover`: router-owned modal
  declarations for common presentations. Modal definitions also support
  `location(...)` when `buildPath` is provided.

## Params

- `LmCodecs`: built-in string, int, double, bool, DateTime, and enum codecs.
- `LmPathParams`, `Lm.params(...)`: concise path-param reader for common
  required typed params, such as `Lm.params(params).requiredInt('orderId')`.
- `LmRouteDecodeException`, `LmMissingParamException`,
  `LmInvalidParamException`, `LmUnknownEnumValueException`: route-aware decode
  failures suitable for not-found handling.

## Navigation And Guards

- `LmGuard`: app-defined activation guard.
- `LmGuardContext`: current navigation attempt context.
- `LmGuardAllow`, `LmGuardBlock`, `LmGuardRedirect`: guard decisions.
- `LmCallbackGuard`, `Lm.guard(...)`: callback guard helper for simple app
  policies that do not need their own guard class.
- `LmRouterDiagnostics`, `LmNavigationEvent`: structured navigation events for
  logging and production monitoring. `maxEvents` bounds retained history while
  listeners still receive every emitted event.

## Adaptive Layout

- `LmBranch`: first-class tab/branch metadata.
- `LmBranchSwitchPolicy`: branch switching behavior.
- `BuildContext.lm.go(...)`, `push(...)`, and `replace(...)`: resolve the
  target path's owning branch at runtime. Navigating from `/orders/42` to
  `/settings` switches `activeBranchId` to the `settings` branch and preserves
  the old `orders` stack. Use `goPath(...)`, `pushPath(...)`,
  `replacePath(...)`, and `presentPath(...)` when the call site intentionally
  uses plain string paths.
- `BuildContext.lm.switchBranch(...)`: pure branch switch that restores the
  destination branch's existing stack without opening a new route.
- `LmAdaptiveShell`: compact/medium/expanded shell selection.
- `LmBreakpointPolicy`: width-to-layout policy.
- `LmAdaptiveRouterSplitView`: stable split-view widget for tablet layouts.
- `LmDetailPolicy`: route placement policy for expanded layouts.

## Chrome

- `LmRouteChrome`: route-level tabbar/navigation-bar visibility metadata.
- `LmTabBarVisibility`: tabbar visibility policy.
- `LmNavigationBarPolicy`: navigation-bar behavior metadata.
- `LmAdaptiveChromeScaffold`: high-level adaptive chrome wrapper with custom
  bottom-bar, tablet sidebar, opt-in medium-width sidebar, and per-layout
  content wrapper slots.
- `LmChromeScaffold`: compact scaffold that can hide tabs on pushed routes,
  hides the bottom bar while router-owned modals are open by default, and
  optionally exposes a fallback edge-back gesture.
- `LmNavigationBar`: built-in iOS-style title/back bar.

## Transitions And Modals

- `LmTransition`: route transition descriptors, including Cupertino push,
  fullscreen modal, scale, and hero-friendly page transitions.
- `LmTransitionPolicy`: transition resolution helper.
- `LmSlideFrom`: slide direction metadata.
- `LmModalPresentation`: dialog, Cupertino dialog, bottom sheet, action sheet,
  fullscreen dialog, and popover descriptors.
- `LmModalPresentationKind`: modal presentation category.
- `LmCupertinoSheetNestedConfig`, `LmCupertinoSheetPage`,
  `LmCupertinoSheetNavigator.bound`: reusable iOS 15-style sheet-page
  navigation with clean deep-link mapping handled by the library.

## Advanced Import

Use this only when building custom router framework integrations:

```dart
import 'package:lm_flutter_router/lm_flutter_router_advanced.dart';
```

Advanced APIs include the delegate, matcher, guard pipeline, route-state codec,
layout projector, navigation controller, state nodes, page factory, and
transition binding. They are intentionally not part of the stable preview
compatibility promise yet.
