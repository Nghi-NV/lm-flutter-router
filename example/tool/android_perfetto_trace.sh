#!/usr/bin/env bash
set -euo pipefail

DEVICE_ID="${DEVICE_ID:-}"
PACKAGE_NAME="${PACKAGE_NAME:-com.example.lm_flutter_router_example}"
MAIN_ACTIVITY="${MAIN_ACTIVITY:-com.example.lm_flutter_router_example.MainActivity}"
TRACE_SECONDS="${TRACE_SECONDS:-12}"
WARMUP_SEQUENCE="${WARMUP_SEQUENCE:-1}"
SEQUENCE_REPEATS="${SEQUENCE_REPEATS:-1}"
INCLUDE_HEAVY_VIEW="${INCLUDE_HEAVY_VIEW:-1}"
HEAVY_ROUTE_URL="${HEAVY_ROUTE_URL:-https://field-orders.example/lab/heavy}"
DEVICE_TRACE="/data/misc/perfetto-traces/lm_flutter_router_${TRACE_SECONDS}s.perfetto-trace"
HOST_TRACE="${HOST_TRACE:-/tmp/lm_flutter_router_${TRACE_SECONDS}s.perfetto-trace}"

if [[ -z "${DEVICE_ID}" ]]; then
  echo "Set DEVICE_ID to the Android device or emulator id to trace." >&2
  exit 1
fi

if ! adb devices | grep -q "^${DEVICE_ID}[[:space:]]"; then
  echo "Device ${DEVICE_ID} is not connected." >&2
  exit 1
fi

adb -s "${DEVICE_ID}" shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
if ! adb -s "${DEVICE_ID}" shell pm path "${PACKAGE_NAME}" | grep -q "^package:"; then
  echo "Package ${PACKAGE_NAME} is not installed on ${DEVICE_ID}. Build and install the profile APK first." >&2
  exit 1
fi

adb -s "${DEVICE_ID}" shell am force-stop "${PACKAGE_NAME}" >/dev/null
START_OUTPUT="$(
  adb -s "${DEVICE_ID}" shell am start \
    -n "${PACKAGE_NAME}/${MAIN_ACTIVITY}" 2>&1
)"
if echo "${START_OUTPUT}" | grep -q "Error"; then
  echo "${START_OUTPUT}" >&2
  exit 1
fi
sleep 2
if ! adb -s "${DEVICE_ID}" shell pidof "${PACKAGE_NAME}" | grep -q "[0-9]"; then
  echo "Package ${PACKAGE_NAME} did not stay running after launch." >&2
  exit 1
fi

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
  run_navigation_sequence
  if [[ "${INCLUDE_HEAVY_VIEW}" == "1" ]]; then
    run_heavy_view_sequence
  fi
  sleep 0.8
fi

adb -s "${DEVICE_ID}" shell rm -f "${DEVICE_TRACE}" >/dev/null 2>&1 || true
adb -s "${DEVICE_ID}" shell perfetto \
  --background-wait \
  --time "${TRACE_SECONDS}s" \
  --buffer 64mb \
  --out "${DEVICE_TRACE}" \
  sched/sched_switch \
  sched/sched_wakeup \
  gfx \
  view \
  input \
  wm \
  am >/tmp/lm_flutter_router_perfetto_pid.txt

for ((repeat = 0; repeat < SEQUENCE_REPEATS; repeat += 1)); do
  run_navigation_sequence
  if [[ "${INCLUDE_HEAVY_VIEW}" == "1" ]]; then
    run_heavy_view_sequence
  fi
done

sleep "${TRACE_SECONDS}"
adb -s "${DEVICE_ID}" pull "${DEVICE_TRACE}" "${HOST_TRACE}" >/dev/null
echo "android_perfetto_trace=${HOST_TRACE}"
