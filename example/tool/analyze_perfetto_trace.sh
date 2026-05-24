#!/usr/bin/env bash
set -euo pipefail

TRACE_PATH="${1:-/tmp/lm_flutter_router_12s.perfetto-trace}"
TRACE_PROCESSOR="${TRACE_PROCESSOR:-/tmp/trace_processor}"
MAX_JANK_PERCENT="${MAX_JANK_PERCENT:-5.0}"
MAX_FRAME_MS="${MAX_FRAME_MS:-20.0}"

if [[ ! -f "${TRACE_PATH}" ]]; then
  echo "Trace file not found: ${TRACE_PATH}" >&2
  exit 1
fi

if [[ ! -x "${TRACE_PROCESSOR}" ]]; then
  curl -fsSL https://get.perfetto.dev/trace_processor -o "${TRACE_PROCESSOR}"
  chmod +x "${TRACE_PROCESSOR}"
fi

SUMMARY="$("${TRACE_PROCESSOR}" -Q "
select
  count(*) || ',' ||
  sum(case when jank_type != 'None' then 1 else 0 end) || ',' ||
  sum(case when on_time_finish = 0 or jank_type like '%Deadline Missed%' then 1 else 0 end) || ',' ||
  printf('%.3f', max(dur) / 1e6) || ',' ||
  printf('%.3f', avg(dur) / 1e6) || ',' ||
  printf(
    '%.3f',
    coalesce(
      max(case
        when on_time_finish = 0 or jank_type like '%Deadline Missed%' then dur
      end) / 1e6,
      0
    )
  ) as summary
from actual_frame_timeline_slice
where upid = (
  select upid
  from process
  where name = 'com.example.lm_flutter_router_example'
  limit 1
);
" "${TRACE_PATH}" | awk -F'"' '/^[\"]?[0-9]+,/ { print $2; exit }')"

IFS=',' read -r APP_FRAMES JANKY_FRAMES DEADLINE_MISSED_FRAMES MAX_FRAME_MS_ACTUAL AVG_FRAME_MS MAX_DEADLINE_MISSED_FRAME_MS <<< "${SUMMARY}"

python3 - "$APP_FRAMES" "$JANKY_FRAMES" "$DEADLINE_MISSED_FRAMES" "$MAX_FRAME_MS_ACTUAL" "$AVG_FRAME_MS" "$MAX_DEADLINE_MISSED_FRAME_MS" "$MAX_JANK_PERCENT" "$MAX_FRAME_MS" <<'PY'
import sys

frames = int(sys.argv[1])
janky = int(sys.argv[2])
deadline_missed = int(sys.argv[3])
max_frame = float(sys.argv[4])
avg_frame = float(sys.argv[5])
max_deadline_missed_frame = float(sys.argv[6])
max_jank_percent = float(sys.argv[7])
max_frame_threshold = float(sys.argv[8])

if frames == 0:
    raise SystemExit("perfetto_analysis_fail app_frames=0")
all_jank_percent = janky / frames * 100.0
deadline_missed_percent = deadline_missed / frames * 100.0
if deadline_missed_percent > max_jank_percent or max_deadline_missed_frame > max_frame_threshold:
    raise SystemExit(
        "perfetto_analysis_fail "
        f"app_frames={frames} all_jank_percent={all_jank_percent:.2f} "
        f"deadline_missed_percent={deadline_missed_percent:.2f} "
        f"max_frame_ms={max_frame:.3f} "
        f"max_deadline_missed_frame_ms={max_deadline_missed_frame:.3f} "
        f"avg_frame_ms={avg_frame:.3f}"
    )
print(
    "perfetto_analysis_pass "
    f"app_frames={frames} all_jank_percent={all_jank_percent:.2f} "
    f"deadline_missed_percent={deadline_missed_percent:.2f} "
    f"max_frame_ms={max_frame:.3f} "
    f"max_deadline_missed_frame_ms={max_deadline_missed_frame:.3f} "
    f"avg_frame_ms={avg_frame:.3f}"
)
PY

"${TRACE_PROCESSOR}" -Q "
select
  count(*) as app_frames,
  sum(case when jank_type != 'None' then 1 else 0 end) as janky_frames,
  sum(case when on_time_finish = 0 or jank_type like '%Deadline Missed%' then 1 else 0 end) as deadline_missed_frames,
  max(dur) / 1e6 as max_frame_ms,
  coalesce(
    max(case
      when on_time_finish = 0 or jank_type like '%Deadline Missed%' then dur
    end) / 1e6,
    0
  ) as max_deadline_missed_frame_ms,
  avg(dur) / 1e6 as avg_frame_ms
from actual_frame_timeline_slice
where upid = (
  select upid
  from process
  where name = 'com.example.lm_flutter_router_example'
  limit 1
);
" "${TRACE_PATH}"

"${TRACE_PROCESSOR}" -Q "
select
  name as frame_token,
  dur / 1e6 as frame_ms,
  present_type,
  on_time_finish,
  jank_type,
  jank_severity_type,
  layer_name
from actual_frame_timeline_slice
where upid = (
  select upid
  from process
  where name = 'com.example.lm_flutter_router_example'
  limit 1
)
order by dur desc
limit 8;
" "${TRACE_PATH}"

"${TRACE_PROCESSOR}" -Q "
select
  t.name as thread,
  s.name as slice,
  s.dur / 1e6 as dur_ms
from slice s
join thread_track tt on s.track_id = tt.id
join thread t on tt.utid = t.utid
join process p on t.upid = p.upid
where p.name = 'com.example.lm_flutter_router_example'
  and s.dur > 2000000
order by s.dur desc
limit 12;
" "${TRACE_PATH}"
