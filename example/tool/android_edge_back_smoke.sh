#!/usr/bin/env bash
set -euo pipefail

DEVICE_ID="${1:-${ANDROID_SERIAL:-}}"
PACKAGE_NAME="com.example.lm_flutter_router_example"
MAIN_ACTIVITY="$PACKAGE_NAME/.MainActivity"
BLOCKED_DEVICE_IDS=("LMVA720251200031")

if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "No Android device found. Pass a device id or set ANDROID_SERIAL." >&2
  exit 1
fi

for blocked_device_id in "${BLOCKED_DEVICE_IDS[@]}"; do
  if [[ "$DEVICE_ID" == "$blocked_device_id" ]]; then
    echo "Refusing to run $PACKAGE_NAME on blocked device $DEVICE_ID." >&2
    exit 1
  fi
done

dump_ui() {
  local output_file="$1"
  local required_text="${2:-}"
  for _ in 1 2 3; do
    adb -s "$DEVICE_ID" exec-out uiautomator dump /dev/tty >"$output_file" 2>/dev/null || true
    if grep -q "<hierarchy" "$output_file" &&
      { [[ -z "$required_text" ]] || grep -q "$required_text" "$output_file"; }; then
      return 0
    fi
    sleep 1
  done
  echo "Could not capture uiautomator hierarchy for $PACKAGE_NAME." >&2
  return 1
}

adb -s "$DEVICE_ID" shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
adb -s "$DEVICE_ID" shell wm dismiss-keyguard >/dev/null 2>&1 || true
adb -s "$DEVICE_ID" shell am force-stop "$PACKAGE_NAME" >/dev/null 2>&1 || true
adb -s "$DEVICE_ID" shell am start -W -n "$MAIN_ACTIVITY" >/dev/null
sleep 3

UI_DUMP="$(mktemp -t lm-router-ui.XXXXXX.xml)"
dump_ui "$UI_DUMP" "Orders, Tab"

read -r ORDERS_X ORDERS_Y SCREEN_WIDTH SCREEN_HEIGHT < <(python3 - "$UI_DUMP" <<'PY'
import re
import sys
import xml.etree.ElementTree as ET

raw = open(sys.argv[1], "r", encoding="utf-8", errors="replace").read()
start = raw.find("<hierarchy")
end = raw.rfind("</hierarchy>")
if start < 0 or end < 0:
    raise SystemExit("could not find uiautomator hierarchy XML")
tree = ET.ElementTree(ET.fromstring(raw[start : end + len("</hierarchy>")]))
root = tree.getroot()
first = next(root.iter("node"))
screen_match = re.fullmatch(
    r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]",
    first.attrib["bounds"],
)
if not screen_match:
    raise SystemExit("could not read root bounds")
left, top, right, bottom = map(int, screen_match.groups())

def center_for(text):
    for node in tree.iter("node"):
        description = node.attrib.get("content-desc", "")
        if text not in description:
            continue
        match = re.fullmatch(
            r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]",
            node.attrib.get("bounds", ""),
        )
        if not match:
            continue
        l, t, r, b = map(int, match.groups())
        return (l + r) // 2, (t + b) // 2
    raise SystemExit(f"could not find {text!r} in UI dump")

orders_x, orders_y = center_for("Orders, Tab")
print(orders_x, orders_y, right - left, bottom - top)
PY
)

# The integration test remains the authoritative semantic check; this smoke
# verifies that a real left-edge system/app swipe does not background the app.
adb -s "$DEVICE_ID" shell input tap "$ORDERS_X" "$ORDERS_Y"
sleep 1

dump_ui "$UI_DUMP" "Minh Tran #1042"
read -r FIRST_X FIRST_Y < <(python3 - "$UI_DUMP" <<'PY'
import re
import sys
import xml.etree.ElementTree as ET

raw = open(sys.argv[1], "r", encoding="utf-8", errors="replace").read()
start = raw.find("<hierarchy")
end = raw.rfind("</hierarchy>")
if start < 0 or end < 0:
    raise SystemExit("could not find uiautomator hierarchy XML")
tree = ET.ElementTree(ET.fromstring(raw[start : end + len("</hierarchy>")]))

for node in tree.iter("node"):
    description = node.attrib.get("content-desc", "")
    if "Minh Tran #1042" not in description:
        continue
    match = re.fullmatch(
        r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]",
        node.attrib.get("bounds", ""),
    )
    if not match:
        continue
    left, top, right, bottom = map(int, match.groups())
    print((left + right) // 2, (top + bottom) // 2)
    break
else:
    raise SystemExit("could not find first order item in UI dump")
PY
)

adb -s "$DEVICE_ID" shell input tap "$FIRST_X" "$FIRST_Y"
sleep 1
SWIPE_Y=$((SCREEN_HEIGHT / 2))
SWIPE_END_X=$((SCREEN_WIDTH - 80))
adb -s "$DEVICE_ID" shell input swipe 1 "$SWIPE_Y" "$SWIPE_END_X" "$SWIPE_Y" 180
sleep 1

WINDOW_DUMP="$(adb -s "$DEVICE_ID" shell dumpsys window 2>/dev/null || true)"
if ! grep -q "mCurrentFocus=.*$PACKAGE_NAME" <<<"$WINDOW_DUMP"; then
  echo "Smoke failed: $PACKAGE_NAME is not the foreground window after edge back." >&2
  exit 1
fi

echo "android_edge_back_smoke_pass device=$DEVICE_ID package=$PACKAGE_NAME"
