#!/usr/bin/env bash
set -Eeuo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
THEME_ROOT="${LIVARA_THEME_ROOT:-$XDG_STATE_HOME/livara/theme}"
failures=0
warnings=0

pass() { printf 'PASS  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*"; failures=$((failures + 1)); }
warn() { printf 'WARN  %s\n' "$*"; warnings=$((warnings + 1)); }
info() { printf 'INFO  %s\n' "$*"; }
section() { printf '\n=== %s ===\n' "$*"; }
contains() { grep -Fq -- "$1" "$2" 2>/dev/null; }

find_unique() {
  local path
  declare -A seen=()
  for path in "$@"; do
    [[ -e "$path" ]] || continue
    [[ "${seen[$path]+yes}" ]] && continue
    seen[$path]=1
    printf '%s\n' "$path"
  done
  while IFS= read -r path; do
    [[ -n "$path" && -e "$path" ]] || continue
    [[ "${seen[$path]+yes}" ]] && continue
    seen[$path]=1
    printf '%s\n' "$path"
  done
}

section 'State discovery'
info "HOME=$HOME"
info "XDG_CONFIG_HOME=$XDG_CONFIG_HOME"
info "XDG_DATA_HOME=$XDG_DATA_HOME"
info "XDG_STATE_HOME=$XDG_STATE_HOME"

section 'Xournal++'
xournal_files=()
while IFS= read -r path; do xournal_files+=("$path"); done < <(
  find_unique \
    "$XDG_CONFIG_HOME/xournalpp/settings.xml" \
    "$HOME/.var/app/com.github.xournalpp.xournalpp/config/xournalpp/settings.xml" \
    "$HOME/.config/xournalpp/settings.xml" \
    "$HOME/.config/com.github.xournalpp.xournalpp/settings.xml" \
    < <(find "$HOME/.var/app" "$HOME/.config" -type f -path '*/xournalpp/settings.xml' -print 2>/dev/null || true)
)
if ((${#xournal_files[@]} == 0)); then
  warn 'no Xournal++ settings.xml was found'
else
  for settings in "${xournal_files[@]}"; do
    info "Xournal++ candidate: $settings"
    if command -v xmllint >/dev/null 2>&1; then
      if xmllint --noout "$settings" >/dev/null 2>&1; then
        pass "XML is valid: $settings"
      else
        fail "XML is invalid: $settings"
      fi
    else
      warn "XML parser unavailable; syntax was not independently validated: $settings"
    fi
    contains 'name="colorPalette"' "$settings" && contains 'livara.gpl' "$settings" \
      && pass "Livara palette selected: $settings" || fail "Livara palette is not selected: $settings"
    grep -Eq 'name="themeVariant" value="useSystem"' "$settings" \
      && pass "Xournal++ follows the system GTK appearance: $settings" || fail "Xournal++ is not using the system appearance: $settings"
    grep -Eq 'name="backgroundColor" value="[0-9]+"' "$settings" \
      && pass "external canvas has a valid ARGB color: $settings" || fail "external canvas value is invalid: $settings"
    grep -Eq 'name="selectionBorderColor" value="[0-9]+"' "$settings" \
      && pass "selection border has a valid ARGB color: $settings" || fail "selection border value is invalid: $settings"
    contains 'name="menubarVisible" value="false"' "$settings" \
      && pass "file menu bar is hidden: $settings" || fail "file menu bar is not hidden: $settings"
    contains 'name="defaultViewModeAttributes" value="showToolbar,showSidebar"' "$settings" \
      && pass "default view mode excludes the menu bar: $settings" || fail "default view mode still includes the menu bar: $settings"
    if grep -Eq 'name="pageTemplate"[^>]*value="[^"]*backgroundTypeConfig=f1=#[0-9A-Fa-f]{6},af1=#[0-9A-Fa-f]{6}' "$settings" 2>/dev/null; then
      pass "pageTemplate contains a native backgroundTypeConfig: $settings"
    else
      warn "pageTemplate backgroundTypeConfig was not found: $settings"
    fi
    contains 'backgroundColor=#000000' "$settings" \
      && pass "journal page background is preserved: $settings" || fail "journal page background is not preserved: $settings"
    palette="$(dirname "$settings")/palettes/livara.gpl"
    if [[ -s "$palette" ]] && awk 'NF >= 3 && $1 ~ /^[0-9]+$/ { key = $1 FS $2 FS $3; if (++seen[key] > 1) duplicate = 1 } END { exit duplicate }' "$palette"; then
      pass "Xournal++ palette has unique RGB entries: $palette"
    elif [[ -e "$palette" ]]; then
      fail "Xournal++ palette contains duplicate RGB entries: $palette"
    fi
    if [[ -s "$palette" ]] && grep -Eiq '[[:space:]](Primary|Primary Container|Secondary|Tertiary|Error|Crust|Mantle)$' "$palette"; then
      fail "Xournal++ palette contains a Material/surface role: $palette"
    elif [[ -s "$palette" ]]; then
      pass "Xournal++ palette contains drawing roles only: $palette"
    fi
  done
fi

if command -v spicetify >/dev/null 2>&1; then
  fail "spicetify remains in PATH: $(command -v spicetify)"
else
  pass 'spicetify is absent from PATH'
fi
if command -v spotify >/dev/null 2>&1; then
  warn "Spotify executable remains in PATH: $(command -v spotify)"
else
  pass 'Spotify executable is absent from PATH'
fi
[[ ! -d "$XDG_CONFIG_HOME/spicetify" ]] && pass 'Spicetify configuration is absent' || warn "stale Spicetify configuration remains: $XDG_CONFIG_HOME/spicetify"

section 'Hydra'
hydra_css=()
while IFS= read -r path; do hydra_css+=("$path"); done < <(
  find_unique < <(
    [[ -d "$THEME_ROOT/hydra-export/themes" ]] && find "$THEME_ROOT/hydra-export/themes" -type f -name theme.css -print 2>/dev/null || true
  )
)
if ((${#hydra_css[@]} == 0)); then
  warn "no Hydra theme.css was found in $THEME_ROOT/hydra-export/themes"
else
  for css in "${hydra_css[@]}"; do
    [[ -s "$css" ]] && pass "Hydra theme.css exists: $css" || fail "Hydra theme.css is empty: $css"
  done
fi
hydra_dbs=()
while IFS= read -r path; do hydra_dbs+=("$path"); done < <(
  find_unique < <(
    for root in "$XDG_CONFIG_HOME" "$HOME/.config" "$HOME/.var/app"; do
      [[ -d "$root" ]] || continue
      find "$root" -type d -name hydra-db -print 2>/dev/null || true
    done
  )
)
if ((${#hydra_dbs[@]} == 0)); then
  warn 'no Hydra hydra-db directory was found'
else
  for db in "${hydra_dbs[@]}"; do
    info "Hydra database: $db"
    if pgrep -x hydra >/dev/null 2>&1 || pgrep -x hydralauncher >/dev/null 2>&1 || pgrep -x Hydra >/dev/null 2>&1; then
      warn 'Hydra is running; its ClassicLevel state was not inspected'
    elif rg -a -l -F 'Livara' "$db" >/dev/null 2>&1; then
      pass "a textual Livara record was found in Hydra state: $db"
    else
      warn "Hydra export exists, but no safe offline ClassicLevel reader is available: $db"
    fi
  done
fi

printf '\n=== Post-build result ===\n'
printf 'Failures: %d\n' "$failures"
printf 'Warnings: %d\n' "$warnings"
if ((failures > 0)); then
  printf 'Result: FAILED\n'
  exit 1
fi
printf 'Result: OK\n'
