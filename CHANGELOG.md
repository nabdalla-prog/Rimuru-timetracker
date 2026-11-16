# Changelog

## 0.1.2 - 2026-11-16

- The text field no longer reads the clipboard on its own. An editable Qt text field reads the whole clipboard whenever it changes, so a program that owns the clipboard could stall or exhaust the tracker by streaming endless text. The field is now read-only to Qt and handles typing itself; the clipboard is read only when you press the paste shortcut. The field has no undo or input-method composition as a result.
- `Model.VERSION` matches the manifest again (0.1.1 left it at 0.1.0, which failed the version test).

## 0.1.1 - 2026-10-08

- Notifications no longer include activity names, tracked times or file paths. They were passed to `notify-send` as command-line arguments, which other local users can read.

## 0.1.0 - 2026-10-07

First release.

- Tracking tab: activity tiles in a grid or list, click to start or stop, live timers, right click to edit, a "Basic Reporting" summary of today
- Events log grouped by day; edit, delete or add events by hand
- Timeline: pie chart or bars by day, week, month or year, paging back in time, visible-activity filter, a strip of when each stretch happened, CSV export
- Daily and weekly goals and limits with notifications
- Settings: simultaneous timers, forgotten-timer reminders, time format, rounding, start of week, activity manager, add to the app launcher, delete all data
- Bar widget showing the running timer; click to open, right click to stop
- `omarchy-timetracker` command: open, toggle an activity by name, stop, status, export, quit
- Timers survive closing the window, restarts and reboots
