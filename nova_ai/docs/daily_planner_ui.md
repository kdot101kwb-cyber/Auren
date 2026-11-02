# NOVA Daily Planner UI

The daily planner reads open tasks from the device-local workspace and uses
`NovaOfflineDailyPlanner` to fit estimates into a user-selected minute budget.

- Duration estimates are editable in the screen and default to 30 minutes.
- The plan reports scheduled, deferred, used, and remaining minutes.
- Completed tasks are excluded.
- Estimates are session-only in this version; they do not modify task records.
- Planning never executes tasks or launches agents.

Focused test: `flutter test test/features/planning/nova_daily_planner_screen_test.dart`.
