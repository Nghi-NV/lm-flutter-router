#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="$(cd "${EXAMPLE_DIR}/.." && pwd)"

ANDROID_TARGET="${ANDROID_DEVICE_ID:-}"
if [[ "${RUN_ANDROID_PERF:-0}" == "1" && "${ANDROID_TARGET}" == "LMVA720251200031" ]]; then
  echo "Refusing to install or profile on blocked Android device ${ANDROID_TARGET}." >&2
  exit 1
fi
if [[ "${RUN_ANDROID_PERF:-0}" == "1" && -z "${ANDROID_TARGET}" ]]; then
  echo "Set ANDROID_DEVICE_ID before running Android performance gates." >&2
  exit 1
fi
if [[ -n "${IOS_DEVICE_ID:-}" ]]; then
  DEVICE_ID="${IOS_DEVICE_ID}" VALIDATE_ONLY=1 \
    "${EXAMPLE_DIR}/tool/ios_xctrace_split_perf.sh"
fi

cd "${REPO_DIR}"
dart analyze
LIB_TESTS=()
while IFS= read -r test_file; do
  LIB_TESTS+=("${test_file}")
done < <(find test -name '*_test.dart' ! -name 'performance_regression_test.dart' | sort)
flutter test "${LIB_TESTS[@]}"
flutter test test/performance_regression_test.dart
flutter test benchmark/router_benchmark.dart

cd "${EXAMPLE_DIR}"
flutter test test/widget_test.dart
flutter build web --dart-define=LM_ROUTER_WEB_SMOKE=true
node tool/web_perf_smoke.mjs

if [[ "${RUN_ANDROID_PERF:-0}" == "1" ]]; then
  flutter test integration_test/navigation_performance_test.dart \
    -d "${ANDROID_TARGET}"
  flutter build apk --profile --target-platform android-arm64
  adb -s "${ANDROID_TARGET}" install -r \
    build/app/outputs/flutter-apk/app-profile.apk
  DEVICE_ID="${ANDROID_TARGET}" ./tool/android_perf_smoke.sh
  DEVICE_ID="${ANDROID_TARGET}" ./tool/android_perfetto_trace.sh
  ./tool/analyze_perfetto_trace.sh /tmp/lm_flutter_router_12s.perfetto-trace
fi

if [[ -n "${IOS_DEVICE_ID:-}" ]]; then
  DEVICE_ID="${IOS_DEVICE_ID}" ./tool/ios_xctrace_split_perf.sh
fi
