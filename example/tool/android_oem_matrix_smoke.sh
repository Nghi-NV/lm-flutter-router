#!/usr/bin/env bash
set -euo pipefail

PACKAGE_NAME="com.example.lm_flutter_router_example"
BLOCKED_DEVICE_IDS=("LMVA720251200031")
MIN_ALLOWED_PHYSICAL_DEVICES="${MIN_ALLOWED_PHYSICAL_DEVICES:-1}"

is_blocked_device() {
  local device_id="$1"
  for blocked_device_id in "${BLOCKED_DEVICE_IDS[@]}"; do
    if [[ "$device_id" == "$blocked_device_id" ]]; then
      return 0
    fi
  done
  return 1
}

is_physical_android_device() {
  local device_id="$1"
  [[ "$device_id" != emulator-* ]]
}

allowed_devices=()
blocked_devices=()
skipped_non_physical_devices=()
if [[ "$#" -gt 0 ]]; then
  for device_id in "$@"; do
    if is_blocked_device "$device_id"; then
      echo "Refusing to run $PACKAGE_NAME on blocked device $device_id." >&2
      exit 1
    fi
    if ! is_physical_android_device "$device_id"; then
      echo "Skipping non-physical Android device $device_id." >&2
      skipped_non_physical_devices+=("$device_id")
      continue
    fi
    allowed_devices+=("$device_id")
  done
else
  while read -r device_id state _; do
    if [[ "$state" != "device" ]]; then
      continue
    fi
    if is_blocked_device "$device_id"; then
      blocked_devices+=("$device_id")
      continue
    fi
    if ! is_physical_android_device "$device_id"; then
      skipped_non_physical_devices+=("$device_id")
      continue
    fi
    allowed_devices+=("$device_id")
  done < <(adb devices -l | awk 'NR > 1 && NF >= 2 { print }')
fi

if (( ${#allowed_devices[@]} < MIN_ALLOWED_PHYSICAL_DEVICES )); then
  echo "Need at least $MIN_ALLOWED_PHYSICAL_DEVICES allowed physical Android devices; found ${#allowed_devices[@]}." >&2
  printf 'Allowed devices: %s\n' "${allowed_devices[*]:-<none>}" >&2
  printf 'Blocked devices: %s\n' "${blocked_devices[*]:-<none>}" >&2
  printf 'Skipped non-physical devices: %s\n' "${skipped_non_physical_devices[*]:-<none>}" >&2
  exit 1
fi

for device_id in "${allowed_devices[@]}"; do
  echo "Running Android OEM smoke on $device_id"
  flutter run \
    -d "$device_id" \
    --debug \
    --no-resident \
    --dart-define=LM_ROUTER_TRACE_TRANSITIONS=true
  ./tool/android_transition_trace_smoke.sh "$device_id"
  ./tool/android_edge_back_smoke.sh "$device_id"
done

echo "android_oem_matrix_smoke_pass devices=${allowed_devices[*]}"
