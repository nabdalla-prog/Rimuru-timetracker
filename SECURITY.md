# Security policy

## Reporting a vulnerability

Please report security problems privately rather than in a public issue: use GitHub's [private vulnerability reporting](https://github.com/nabdalla-prog/Rimuru-timetracker/security/advisories/new). Include what you found, how to reproduce it, and the version (Settings › About).

This is a small volunteer project. Expect a first reply within about a week.

## Supported versions

Only the latest release is supported.

## What it does, for reviewers

Omarchy plugins and Quickshell apps run with your user's permissions and are not sandboxed. Time Tracker:

- makes **no network requests** and contains no telemetry;
- reads and writes only `~/.local/share/omarchy-timetracker/data.json` (and keeps an unreadable copy beside it rather than overwriting it);
- writes a CSV to `~/Downloads` only when you press Export;
- runs only `mkdir -p` and `cp` on its data folder, `sh -c 'mkdir -p … && cat > …'` for the export, `notify-send`, `quickshell`, `hyprctl` and `jq` (the launcher, to set the window rule at runtime), and its own `install.sh` when you press *Add to App Launcher*;
- the bar widget only reads the data file and starts the launcher;
- `install.sh` writes a `.desktop` file and a symlink in `~/.local/bin`, and edits no configuration;
- never runs `sudo`, installs packages, or executes downloaded code.
