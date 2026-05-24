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
adb -s "$DEVICE_ID" logcat -c
adb -s "$DEVICE_ID" shell am start -W -n "$MAIN_ACTIVITY" >/dev/null
sleep 3

UI_DUMP="$(mktemp -t lm-router-ui.XXXXXX.xml)"
dump_ui "$UI_DUMP" "Minh Tran #1042"

read -r TAP_X TAP_Y < <(python3 - "$UI_DUMP" <<'PY'
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

read -r SCREEN_WIDTH SCREEN_HEIGHT < <(python3 - "$UI_DUMP" <<'PY'
import re
import sys
import xml.etree.ElementTree as ET

raw = open(sys.argv[1], "r", encoding="utf-8", errors="replace").read()
start = raw.find("<hierarchy")
end = raw.rfind("</hierarchy>")
if start < 0 or end < 0:
    raise SystemExit("could not find uiautomator hierarchy XML")
root = ET.fromstring(raw[start : end + len("</hierarchy>")])
first = next(root.iter("node"))
match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", first.attrib["bounds"])
if not match:
    raise SystemExit("could not read root bounds")
left, top, right, bottom = map(int, match.groups())
print(right - left, bottom - top)
PY
)

# Open the first detail route, then use the app-owned near-edge gesture band.
# On some OEMs the physical x=0 edge is reserved by SystemUI, so this trace
# verifies the library-owned iOS-style path just outside that reserve.
adb -s "$DEVICE_ID" shell input tap "$TAP_X" "$TAP_Y"
sleep 1
SWIPE_Y=$((SCREEN_HEIGHT / 2))
SWIPE_START_X=$((SCREEN_WIDTH < 380 ? SCREEN_WIDTH / 4 : 190))
SWIPE_END_X=$((SCREEN_WIDTH - 80))
adb -s "$DEVICE_ID" shell input swipe "$SWIPE_START_X" "$SWIPE_Y" "$SWIPE_END_X" "$SWIPE_Y" 160
sleep 1

LOG_FILE="$(mktemp -t lm-router-android-trace.XXXXXX.log)"
adb -s "$DEVICE_ID" logcat -d >"$LOG_FILE"

WINDOW_DUMP="$(adb -s "$DEVICE_ID" shell dumpsys window 2>/dev/null || true)"
if ! grep -q "mCurrentFocus=.*$PACKAGE_NAME" <<<"$WINDOW_DUMP"; then
  echo "Trace smoke failed: $PACKAGE_NAME is not foreground after app edge back." >&2
  echo "Log: $LOG_FILE" >&2
  exit 1
fi

python3 - "$LOG_FILE" <<'PY'
import re
import sys

log_path = sys.argv[1]
values = []
with open(log_path, "r", encoding="utf-8", errors="replace") as handle:
    for line in handle:
        if "LM_ROUTER_TRACE" not in line or "route=/orders/1042 event=frame" not in line:
            continue
        if "status=reverse" not in line and "status=dismissed" not in line:
            continue
        match = re.search(r"event=frame value=([0-9.]+)", line)
        if match:
            values.append(float(match.group(1)))

if len(values) < 4:
    raise SystemExit(f"not enough reverse animation frames captured: {values}")

violations = [
    (left, right)
    for left, right in zip(values, values[1:])
    if right > left + 0.0001
]
if violations:
    raise SystemExit(f"reverse animation was not monotonic: {violations[:4]}")

if values[-1] > 0.01:
    raise SystemExit(f"reverse animation did not reach dismissed state: {values[-1]}")

print(
    "android_transition_trace_smoke_pass "
    f"reverse_frames={len(values)} first={values[0]:.4f} last={values[-1]:.4f}"
)
PY
