# API Stability Policy

Date: 2026-05-20

`lm_flutter_router` is still pre-1.0. The package uses the following stability
levels so app teams can adopt it without accidentally depending on internals.

## Stable Preview API

The default import is the stable preview surface:

```dart
import 'package:lm_flutter_router/lm_flutter_router.dart';
```

This surface contains app-facing routing primitives:

- `LmRouter`
- `Lm`
- `LmRouterScope`, `BuildContext.lm`
- `LmRouteDefinition`, `LmModalRouteDefinition`
- `LmLocation`
- typed param codecs and route decode exceptions
- guards and guard results
- adaptive shell/split-view primitives
- chrome metadata and navigation bar widgets
- transition descriptors and modal presentation descriptors
- diagnostics events

Before `1.0.0`, breaking changes may still happen, but they should be called
out in `CHANGELOG.md` with a migration note.

## Advanced API

Advanced imports are available for framework authors and app teams building
custom shells:

```dart
import 'package:lm_flutter_router/lm_flutter_router_advanced.dart';
```

This surface exposes lower-level concepts such as the delegate, matcher, guard
pipeline, route-state codec, layout projector, navigation controller, state
nodes, transition page factory, and chrome transition binding. These APIs are
useful for inspection and custom projection, but they are not considered stable
until explicitly promoted.

## Internal API

Files under `lib/src/` are implementation details unless exported by one of the
two public library files above. Apps should not import `src/*` directly.

## Semver Rules

Before `1.0.0`:

- Minor versions may include breaking changes.
- Patch versions should only include fixes, docs, tests, or compatible
  additions.
- Any breaking change must include a migration note in `CHANGELOG.md`.

At and after `1.0.0`:

- Stable preview APIs become stable APIs.
- Breaking stable API changes require a major version bump.
- Advanced APIs may still change in minor versions until promoted.
- Behavior changes to navigation semantics, browser history, back handling, or
  typed param decoding must be treated as compatibility-sensitive and documented.

## Typed Codegen

`lm_flutter_router` intentionally keeps the runtime package usable without
build_runner. Compile-time typed route generation should live in a companion
builder package and follow the plan in [`typed-codegen-roadmap.md`](typed-codegen-roadmap.md).
