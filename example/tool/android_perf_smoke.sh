#!/usr/bin/env bash
set -euo pipefail

DEVICE_ID="${DEVICE_ID:-}"
PACKAGE_NAME="${PACKAGE_NAME:-com.example.lm_flutter_router_example}"
MAIN_ACTIVITY="${MAIN_ACTIVITY:-com.example.lm_flutter_router_example.MainActivity}"
WARMUP_SEQUENCE="${WARMUP_SEQUENCE:-1}"
INCLUDE_HEAVY_VIEW="${INCLUDE_HEAVY_VIEW:-1}"
HEAVY_ROUTE_URL="${HEAVY_ROUTE_URL:-https://field-orders.example/lab/heavy}"

if [[ -z "${DEVICE_ID}" ]]; then
  echo "Set DEVICE_ID to the Android device or emulator id to profile." >&2
  exit 1
fi

if ! adb devices | grep -q "^${DEVICE_ID}[[:space:]]"; then
  echo "Device ${DEVICE_ID} is not connected." >&2
  exit 1
fi

launch_app() {
  adb -s "${DEVICE_ID}" shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
  adb -s "${DEVICE_ID}" shell am force-stop "${PACKAGE_NAME}" >/dev/null
  local start_output
  start_output="$(
    adb -s "${DEVICE_ID}" shell am start \
      -n "${PACKAGE_NAME}/${MAIN_ACTIVITY}" 2>&1
  )"
  if echo "${start_output}" | grep -q "Error"; then
    echo "${start_output}" >&2
    exit 1
  fi
  for _ in 1 2 3 4 5; do
    if adb -s "${DEVICE_ID}" shell dumpsys window |
      grep -q "mCurrentFocus=.*${PACKAGE_NAME}"; then
      return
    fi
    sleep 0.5
  done
  echo "Package ${PACKAGE_NAME} did not become the focused window." >&2
  exit 1
}

run_navigation_sequence() {
  adb -s "${DEVICE_ID}" shell input tap 270 1540
  sleep 0.4
  adb -s "${DEVICE_ID}" shell input tap 300 420
  sleep 0.6
  adb -s "${DEVICE_ID}" shell input tap 330 900
  sleep 0.6
  adb -s "${DEVICE_ID}" shell input swipe 8 800 520 800 180
  sleep 0.6
  adb -s "${DEVICE_ID}" shell input swipe 8 800 520 800 180
  sleep 0.6
  adb -s "${DEVICE_ID}" shell input tap 300 520
  sleep 0.4
  adb -s "${DEVICE_ID}" shell input keyevent KEYCODE_BACK
  sleep 0.6
}

run_heavy_view_sequence() {
  local start_output
  start_output="$(
    adb -s "${DEVICE_ID}" shell am start \
      -a android.intent.action.VIEW \
      -d "${HEAVY_ROUTE_URL}" \
      -n "${PACKAGE_NAME}/${MAIN_ACTIVITY}" 2>&1
  )"
  if echo "${start_output}" | grep -q "Error"; then
    echo "${start_output}" >&2
    exit 1
  fi
  sleep 1.2
  adb -s "${DEVICE_ID}" shell input keyevent KEYCODE_BACK
  sleep 0.4
}

if [[ "${WARMUP_SEQUENCE}" == "1" ]]; then
  launch_app
  run_navigation_sequence
fi

launch_app
sleep 1
adb -s "${DEVICE_ID}" shell dumpsys gfxinfo "${PACKAGE_NAME}" reset >/dev/null
run_navigation_sequence
if [[ "${INCLUDE_HEAVY_VIEW}" == "1" ]]; then
  run_heavy_view_sequence
fi

echo "== gfxinfo =="
GFXINFO="$(adb -s "${DEVICE_ID}" shell dumpsys gfxinfo "${PACKAGE_NAME}")"
printf '%s\n' "${GFXINFO}" | sed -n '1,35p'

echo "== meminfo =="
adb -s "${DEVICE_ID}" shell dumpsys meminfo "${PACKAGE_NAME}" | sed -n '1,35p'

echo "== battery =="
adb -s "${DEVICE_ID}" shell dumpsys battery | grep -E "level|temperature|status"

JANK_PERCENT="$(printf '%s\n' "${GFXINFO}" | awk -F'[()%]' '/Janky frames:/ {gsub(/ /, "", $2); print $2; exit}')"
P95_MS="$(printf '%s\n' "${GFXINFO}" | awk '/95th percentile:/ {print $3; exit}' | tr -d 'ms')"
TOTAL_FRAMES="$(printf '%s\n' "${GFXINFO}" | awk '/Total frames rendered:/ {print $4; exit}')"

python3 - "$JANK_PERCENT" "$P95_MS" "$TOTAL_FRAMES" <<'PY'
import sys

jank = float(sys.argv[1])
p95 = float(sys.argv[2])
total = int(sys.argv[3])
if total == 0:
    raise SystemExit("android_perf_smoke_fail total_frames=0")
if jank > 5.0 or p95 > 16.0:
    raise SystemExit(
        f"android_perf_smoke_fail total_frames={total} "
        f"jank_percent={jank:.2f} p95_ms={p95:.1f}"
    )
print(
    f"android_perf_smoke_pass total_frames={total} "
    f"jank_percent={jank:.2f} p95_ms={p95:.1f}"
)
PY
