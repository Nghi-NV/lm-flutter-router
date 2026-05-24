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
