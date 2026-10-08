#!/usr/bin/env bash
# Adds Time Tracker to your app launcher (Super + Space → "Time Tracker") and
# puts the `omarchy-timetracker` command in ~/.local/bin. It edits no config:
# the window's float rule is set at runtime by the launcher.
#
#   ./install.sh              add the launcher entry and the command
#   ./install.sh --uninstall  remove both (your data is kept)
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
bin="$HOME/.local/bin/omarchy-timetracker"
desktop="$HOME/.local/share/applications/omarchy-timetracker.desktop"
hypr="$HOME/.config/hypr/hyprland.lua"
# Version 0.1.0 before release wrote this rule into hyprland.lua; clean it up.
legacy="-- Time Tracker window (added by omarchy-timetracker/install.sh)"

remove_legacy_rule() {
  if [[ -f "$hypr" ]] && grep -qF -- "$legacy" "$hypr"; then
    cp "$hypr" "$hypr.bak.$(date +%s)"
    awk -v m="$legacy" '
      $0 == m { skip = 1; next }
      skip && /^}\)$/ { skip = 0; next }
      skip { next }
      { print }
    ' "$hypr" > "$hypr.tmp" && mv "$hypr.tmp" "$hypr"
    # Drop the blank line the rule left at the end, if any.
    sed -i -e ':a' -e '/^\n*$/{$d;N;ba' -e '}' "$hypr"
    hyprctl reload >/dev/null 2>&1 || true
  fi
}

if [[ "${1:-}" == "--uninstall" ]]; then
  rm -f "$bin" "$desktop"
  remove_legacy_rule
  echo "Removed the launcher entry and command. Data kept in ~/.local/share/omarchy-timetracker/"
  exit 0
fi

mkdir -p "$(dirname "$bin")" "$(dirname "$desktop")"
ln -sf "$here/bin/omarchy-timetracker" "$bin"

cat > "$desktop" <<DESK
[Desktop Entry]
Type=Application
Name=Time Tracker
Comment=Track where your time goes, one click per activity
Exec=$here/bin/omarchy-timetracker
Icon=appointment-soon
Terminal=false
Categories=Utility;Office;
Keywords=time;tracker;timer;timelines;productivity;
StartupWMClass=rimuru.timetracker
DESK

remove_legacy_rule
echo "Added. Open Time Tracker from the app launcher (Super + Space) or run: omarchy-timetracker"
