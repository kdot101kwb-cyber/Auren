# NOVA offline daily planner

This pure Dart planner turns a list of estimated tasks into a bounded daily
plan using an available-minute budget.

- Orders urgent, high, normal, then low priority.
- Uses duration and stable ID as deterministic tie-breakers.
- Excludes completed, malformed, non-positive-duration, and duplicate-ID tasks.
- Schedules only tasks that fit; all others remain visible as deferred.
- Reports used and remaining minutes.

The planner is fully offline and has no network or AI dependency. It does not
start tasks, create reminders, or claim that work was completed. Estimates and
priority remain user-controlled inputs.
