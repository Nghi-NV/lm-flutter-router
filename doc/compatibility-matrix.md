# Compatibility Matrix

Date: 2026-05-20

## Verification Gates

| Area | Status | Evidence |
| --- | --- | --- |
| Flutter stable SDK | Required | `dart analyze`, `flutter test`, example tests, and web build |
| Dart analyzer | Required | Package and example `dart analyze` |
| Android debug build | Recommended | `flutter test -d <device-id> integration_test/navigation_performance_test.dart` |
| Android back button | Covered by tests, device smoke recommended | Widget tests cover modal/page back behavior; device smoke should be run before release |
| Android edge/predictive-style route progress | Covered by tests, device smoke recommended | Widget tests cover progress mapping; optional smoke scripts can assert route traces on a device or emulator |
| iOS-style route transitions | Covered by tests, simulator/manual smoke recommended | Cupertino route/page tests, modal route scrub tests, and example widget tests |
| Flutter web build | Required | `flutter build web --dart-define=LM_ROUTER_WEB_SMOKE=true` |
| Web modal URL and browser back/forward | Recommended | `example/tool/web_perf_smoke.mjs` |
| Tablet split projection | Covered by tests | `LmAdaptiveRouterSplitView` and cross-branch router tests |

## Intended Platform Policy

The router is platform-independent Flutter code. It should support every
platform where `MaterialApp.router`, `RouterDelegate`, `Navigator.pages`, and
Flutter's `RouteInformationProvider` are supported.

Before a stable release, each supported platform should have at least one gate:

- Android: widget tests plus physical/emulator integration smoke.
- iOS: widget tests plus simulator/manual smoke for edge swipe and sheet
  presentation.
- Web: build plus Chrome smoke for URL/history behavior.
- Desktop: widget tests plus keyboard/focus audit for built-in chrome.

Manual Android device smoke:

```bash
cd example
flutter test integration_test/navigation_performance_test.dart -d <device-id>
./tool/android_edge_back_smoke.sh <device-id>
flutter run -d <device-id> --debug --no-resident --dart-define=LM_ROUTER_TRACE_TRANSITIONS=true
./tool/android_transition_trace_smoke.sh <device-id>
./tool/android_oem_matrix_smoke.sh <device-id>
```

The smoke scripts may include local blocked-device guards. Treat those guards
as project-local safety checks, not package compatibility policy.

## Unsupported Guarantees

- Exact native SwiftUI sheet physics are not guaranteed; the package provides
  Flutter-native iOS-style sheet transitions.
- OEM-reserved Android x=0 system gesture visuals remain platform-owned; the
  app-owned iOS-style edge band is tested separately from system back.
- Broad multi-OEM Android compatibility should be validated by downstream apps
  on their own supported device matrix.
- Apps importing `lib/src/*` directly are outside the compatibility contract.
