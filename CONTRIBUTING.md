# Contributing

Thanks for helping. Bug reports, ideas and pull requests are all welcome.

## Reporting a problem

Paste the output of `omarchy-timetracker status` and your Omarchy version (`omarchy version`) into the issue, with what you did and what you expected. The [issue forms](https://github.com/nabdalla-prog/Rimuru-timetracker/issues/new/choose) ask for these. For a security problem see [SECURITY.md](SECURITY.md) instead of opening a public issue.

## The ground rules

- **Free and local.** No network requests, no telemetry, no accounts, no paid features. Ever.
- **Its own files only.** The app writes `~/.local/share/omarchy-timetracker/` and, when asked, CSV exports to `~/Downloads`. `install.sh` adds a launcher entry and a link in `~/.local/bin`, and nothing else. No user config is edited.
- **Keep it small and readable.** Match the surrounding code's style and comment density.

## Layout

| Path | What it is |
|---|---|
| `js/Model.js` | All the logic: data validation, timers, totals, periods, goals, formatting, CSV. No UI, unit tested. |
| `shell.qml` | The app: window, command-line (IPC) handlers. |
| `qml/Store.qml` | Loads and saves the data, notifications, the actions the screens call. |
| `qml/Main.qml` | Tabs, tab bar, the add/edit sheets, keyboard shortcuts. |
| `qml/*View.qml`, `qml/components/` | The five tabs and their building blocks. `Theme.qml` holds colours, fonts and icons. |
| `qml/BarWidget.qml` | The Omarchy bar widget (runs inside the Omarchy shell, reads the data file). |
| `bin/omarchy-timetracker` | Launcher: starts the app or talks to the running one. |

## Setting up

```bash
git clone https://github.com/nabdalla-prog/Rimuru-timetracker.git
cd Rimuru-timetracker
TIMETRACKER_HOME=/tmp/tt quickshell -p .     # run against throwaway data
```

To work on the bar widget, link the checkout as a plugin:

```bash
ln -s "$PWD" ~/.config/omarchy/plugins/rimuru.timetracker
omarchy-shell shell rescanPlugins && omarchy plugin enable rimuru.timetracker
```

Handy while working, from the checkout:

```bash
quickshell ipc -p . call timetracker tab 2        # switch tab
quickshell ipc -p . call timetracker sheet goal   # open a sheet
```

## Testing

```bash
node --test tests/*.test.js     # logic, versions, changelog
omarchy plugin validate .       # the manifest
```

Add a test with any change to `js/Model.js`. Things worth knowing when writing QML here:

- Don't name a property `data` on an `Item`: it is Qt's built-in children list.
- Quickshell's CLI reserves `show` as an IPC word, so the open call is named `open`.
- Exiting while an item still has keyboard focus crashes Qt during teardown; quit through `shell.quit()`, which drops focus first.

## Branches and releases

`main` only holds tagged releases, since it is what every user installs. Work on `dev` (or a feature branch) and open pull requests against `dev`.

To release: bump the version in `manifest.json` **and** `js/Model.js` (a test checks they match), add a `## x.y.z` entry to `CHANGELOG.md` (a test checks it), run the tests, merge into `main`, tag `vx.y.z` and create a GitHub release with the changelog entry.
