#!/usr/bin/env bash
set -euo pipefail

DEVICE_ID="${DEVICE_ID:-}"
BUNDLE_ID="${BUNDLE_ID:-com.example.lmFlutterRouterExample}"
TEMPLATE="${TEMPLATE:-Animation Hitches}"
TRACE_SECONDS="${TRACE_SECONDS:-20s}"
OUTPUT="${OUTPUT:-/tmp/lm_flutter_router_ios_split.trace}"
APP_PATH="${APP_PATH:-build/ios/iphoneos/Runner.app}"
SKIP_BUILD="${SKIP_BUILD:-0}"
REQUIRE_IPAD="${REQUIRE_IPAD:-1}"
VALIDATE_ONLY="${VALIDATE_ONLY:-0}"

if [[ -z "${DEVICE_ID}" ]]; then
  echo "Set DEVICE_ID to a physical iPad UDID. Refusing to use a simulator or an arbitrary connected device." >&2
  echo "List devices: xcrun xctrace list devices" >&2
  echo "Inspect physical device metadata: xcrun devicectl list devices" >&2
  exit 1
fi

DEVICE_LINE="$(xcrun xctrace list devices | grep "(${DEVICE_ID})" || true)"
if [[ -z "${DEVICE_LINE}" ]]; then
  echo "Device ${DEVICE_ID} was not found by xctrace." >&2
  exit 1
fi

if echo "${DEVICE_LINE}" | grep -qi "Simulator"; then
  echo "Device ${DEVICE_ID} is a simulator. Use a physical device for native-like performance evidence." >&2
  exit 1
fi

if [[ "${DEVICE_ID}" =~ ^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$ ]]; then
  echo "Device ${DEVICE_ID} looks like a simulator UUID. Use a physical iPad UDID for native-like performance evidence." >&2
  echo "Matched device: ${DEVICE_LINE}" >&2
  exit 1
fi

DEVICE_INFO_JSON="$(mktemp -t lm_ios_devices.XXXXXX.json)"
DEVICE_INFO=""
if xcrun devicectl list devices --json-output "${DEVICE_INFO_JSON}" >/dev/null 2>/dev/null; then
  DEVICE_INFO="$(
    ruby -rjson -e '
      data = JSON.parse(File.read(ARGV[0]))
      target = ARGV[1]
      device = data.dig("result", "devices")&.find do |item|
        item["identifier"] == target ||
          item.dig("hardwareProperties", "udid") == target ||
          item.dig("connectionProperties", "potentialHostnames")&.include?("#{target}.coredevice.local")
      end
      if device
        puts [
          device.dig("deviceProperties", "name"),
          device.dig("hardwareProperties", "deviceType"),
          device.dig("hardwareProperties", "marketingName"),
          device.dig("hardwareProperties", "reality"),
          device.dig("connectionProperties", "tunnelState")
        ].map { |value| value || "" }.join("|")
      end
    ' "${DEVICE_INFO_JSON}" "${DEVICE_ID}"
  )"
fi
rm -f "${DEVICE_INFO_JSON}"

if [[ -n "${DEVICE_INFO}" ]]; then
  IFS='|' read -r DEVICE_NAME DEVICE_TYPE DEVICE_MARKETING DEVICE_REALITY DEVICE_TUNNEL_STATE <<<"${DEVICE_INFO}"
  if [[ "${DEVICE_REALITY}" != "physical" ]]; then
    echo "Device ${DEVICE_ID} is not physical. Use a physical iPad for native-like performance evidence." >&2
    echo "Matched device: ${DEVICE_NAME} ${DEVICE_MARKETING}" >&2
    exit 1
  fi
  if [[ "${REQUIRE_IPAD}" == "1" && "${DEVICE_TYPE}" != "iPad" ]]; then
    echo "Device ${DEVICE_ID} is not an iPad. Set REQUIRE_IPAD=0 only when intentionally profiling a non-iPad iOS device." >&2
    echo "Matched device: ${DEVICE_NAME} ${DEVICE_MARKETING}" >&2
    exit 1
  fi
  if [[ "${DEVICE_TUNNEL_STATE}" == "unavailable" ]]; then
    echo "Device ${DEVICE_ID} is not currently available to devicectl. Connect/unlock it before profiling." >&2
    echo "Matched device: ${DEVICE_NAME} ${DEVICE_MARKETING}" >&2
    exit 1
  fi
elif [[ "${REQUIRE_IPAD}" == "1" ]] && ! echo "${DEVICE_LINE}" | grep -qi "iPad"; then
  echo "Device ${DEVICE_ID} could not be identified as an iPad. Set REQUIRE_IPAD=0 only when intentionally profiling a non-iPad iOS device." >&2
  echo "Matched device: ${DEVICE_LINE}" >&2
  exit 1
fi

if [[ "${VALIDATE_ONLY}" == "1" ]]; then
  echo "ios_xctrace_device_valid=${DEVICE_ID}"
  exit 0
fi

if [[ "${SKIP_BUILD}" != "1" ]]; then
  flutter build ios --profile
fi

if [[ ! -d "${APP_PATH}" ]]; then
  echo "Expected app bundle not found: ${APP_PATH}" >&2
  echo "Set APP_PATH to a signed .app bundle or run without SKIP_BUILD=1." >&2
  exit 1
fi

rm -rf "${OUTPUT}"
xcrun devicectl device install app --device "${DEVICE_ID}" "${APP_PATH}" >/dev/null
xcrun devicectl device process launch --device "${DEVICE_ID}" "${BUNDLE_ID}" >/dev/null

cat <<'EOF'
Record this split-view route flow manually while xctrace is running:
1. Launch in expanded/tablet width and open Orders.
2. Select an order from the primary list to push the first secondary detail.
3. Select two more orders rapidly from the primary list.
4. Open an order action sheet, then dismiss it.
5. Navigate to a line-item detail and pop back to the order detail.
6. Use the secondary pane back affordance to return to the placeholder pane.

Accept the trace only if secondary push/pop has no sustained hitches, primary
pane rendering stays idle during secondary-only transitions, and no long build,
layout, route matching, modal decoding, or stack projection slice is
attributable to lm_flutter_router.
EOF
xcrun xctrace record \
  --template "${TEMPLATE}" \
  --device "${DEVICE_ID}" \
  --attach "${BUNDLE_ID}" \
  --time-limit "${TRACE_SECONDS}" \
  --output "${OUTPUT}"

xcrun xctrace export --input "${OUTPUT}" --toc
echo "ios_xctrace_output=${OUTPUT}"
