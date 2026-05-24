# Field Orders Example

This example is a small dispatcher app built with `lm_flutter_router`.

## Flows Covered

- Dashboard, orders, order detail, line-item detail, settings, and login.
- Router Lab branch with buttons for `go`, `push`, `replace`, `pop`, every
  built-in page transition, and every modal presentation.
- Bottom tabs on mobile and side menu on tablet.
- `LmAdaptiveChromeScaffold` demo with custom compact bottom tabs and custom
  tablet sidebar.
- Android, iOS, web, and desktop use the same iOS-style transition policy in
  this example.
- Mobile tabs use `CupertinoTabBar`; order actions use `CupertinoActionSheet`.
- Auto-hidden mobile tab bar on pushed detail routes.
- Deep links:
  - `/orders/1042`
  - `/orders/1042/items/9`
- Typed route params for `orderId` and `itemId`.
- Auth redirect: sign out in Settings, then open a protected order link.
- Android/system back through `RouterDelegate.popRoute()` and `Navigator`.
- iOS-style edge-swipe capable routes on detail screens via Cupertino pages.
- Router-owned order action sheet and reschedule bottom sheet from a real order
  action.
- Router-owned dialog, Cupertino dialog, bottom sheet, action sheet,
  fullscreen dialog, and popover examples from Router Lab.
- Expanded tablet split view keeps the orders list stable while detail and
  line-item routes deep link into the right pane.
- Debug-only router panel with stack, projection, diagnostics, and restoration state.

## Run

```bash
cd example
flutter pub get
flutter run
```

Resize the app to see compact tabs switch to the expanded side-menu layout.
See `DEMO_CATALOG.md` for copyable route, modal, adaptive chrome, and split-view
patterns.
Open Router Lab -> Heavy View, or deep link to `/lab/heavy`, to demo routing
transitions against a deliberately dense music-app screen with blur layers,
album shelves, a playback queue, and a fixed now-playing bar.

## Smoke Gates

```bash
./tool/router_perf_gate.sh
RUN_ANDROID_PERF=1 ./tool/router_perf_gate.sh
ANDROID_DEVICE_ID=<android-device-id> RUN_ANDROID_PERF=1 ./tool/router_perf_gate.sh

flutter test integration_test/navigation_performance_test.dart -d <device-id>
./tool/android_edge_back_smoke.sh <device-id>
flutter run -d <device-id> --debug --no-resident --dart-define=LM_ROUTER_TRACE_TRANSITIONS=true
./tool/android_transition_trace_smoke.sh <device-id>
./tool/android_oem_matrix_smoke.sh <android-device-id>
./tool/android_perf_smoke.sh
./tool/android_perfetto_trace.sh
./tool/analyze_perfetto_trace.sh /tmp/lm_flutter_router_12s.perfetto-trace
flutter build web --dart-define=LM_ROUTER_WEB_SMOKE=true
node tool/web_perf_smoke.mjs
```

Android perf smoke and Perfetto include `/lab/heavy` by default through the
`https://field-orders.example/lab/heavy` deep link; set
`INCLUDE_HEAVY_VIEW=0` to measure only the lighter order flow.
Run Android performance gates with no other ADB/Flutter jobs using the same
device, otherwise another app can steal focus and invalidate frame metrics.
