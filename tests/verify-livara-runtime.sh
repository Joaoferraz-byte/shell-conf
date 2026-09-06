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
    contains 'name="colorPalette"' "$settings" && contains 'tokyonight.gpl' "$settings" \
      && pass "Tokyo Night palette selected: $settings" || fail "Tokyo Night palette is not selected: $settings"
    contains 'name="backgroundColor" value="4279900966"' "$settings" \
      && pass "external canvas uses the expected Tokyo Night value: $settings" || fail "external canvas value is unexpected: $settings"
    contains 'name="selectionBorderColor" value="4286227191"' "$settings" \
      && pass "selection border uses the expected Tokyo Night value: $settings" || fail "selection border value is unexpected: $settings"
    contains 'name="menubarVisible" value="true"' "$settings" \
      && pass "file menu bar is enabled: $settings" || fail "file menu bar is not enabled: $settings"
    contains 'name="defaultViewModeAttributes" value="showMenubar,showToolbar,showSidebar"' "$settings" \
      && pass "default view mode includes the menu bar: $settings" || fail "default view mode does not include the menu bar: $settings"
    if grep -q 'backgroundTypeConfig=' "$settings" 2>/dev/null; then
      fail "pageTemplate contains backgroundTypeConfig: $settings"
    else
      pass "pageTemplate does not override the journal grid: $settings"
    fi
    contains 'backgroundColor=#000000' "$settings" \
      && pass "journal page background is preserved: $settings" || fail "journal page background is not preserved: $settings"
    palette="$(dirname "$settings")/palettes/tokyonight.gpl"
    if [[ -s "$palette" ]] && awk 'NF >= 3 && $1 ~ /^[0-9]+$/ { key = $1 FS $2 FS $3; if (++seen[key] > 1) duplicate = 1 } END { exit duplicate }' "$palette"; then
      pass "Xournal++ palette has unique RGB entries: $palette"
    elif [[ -e "$palette" ]]; then
      fail "Xournal++ palette contains duplicate RGB entries: $palette"
    fi
  done
fi

section 'IntelliJ IDEA and Android Studio'
jetbrains_plugins=()
while IFS= read -r path; do jetbrains_plugins+=("$path"); done < <(
  find_unique < <(
    for root in "$XDG_DATA_HOME/JetBrains" "$XDG_DATA_HOME/Google" "$HOME/.local/share/JetBrains" "$HOME/.local/share/Google" "$HOME/.var/app"; do
      [[ -d "$root" ]] || continue
      find "$root" -type f -path '*/LivaraTheme/META-INF/plugin.xml' -print 2>/dev/null || true
    done
  )
)
if ((${#jetbrains_plugins[@]} == 0)); then
  warn 'no LivaraTheme plugin was found in JetBrains or Google data roots'
else
  for plugin_xml in "${jetbrains_plugins[@]}"; do
    plugin="${plugin_xml%/META-INF/plugin.xml}"
    info "JetBrains theme plugin: $plugin"
    pass "theme plugin found: $plugin"
    [[ -f "$plugin/theme/Livara.theme.json" ]] \
      && jq -e '.ui["*"] | has("background") and has("foreground")' "$plugin/theme/Livara.theme.json" >/dev/null 2>&1 \
      && pass 'UI theme schema is valid' || fail "UI theme schema is invalid: $plugin"
    [[ -s "$plugin/theme/Matugen-Dark.xml" ]] && pass 'editor scheme is bundled' || fail "editor scheme is missing: $plugin"
    contains 'idea-version' "$plugin_xml" && pass 'plugin compatibility is declared' || fail "idea-version is missing: $plugin_xml"
    nested="$(dirname "$plugin")/plugins/LivaraTheme"
    [[ ! -e "$nested" ]] && pass 'legacy nested plugin installation is absent' || fail "legacy nested plugin installation found: $nested"
  done
fi

section 'Nuclear'
nuclear_candidates=()
while IFS= read -r path; do nuclear_candidates+=("$path"); done < <(
  find_unique \
    "$XDG_DATA_HOME/com.nuclearplayer/themes/Livara.json" \
    "$HOME/.local/share/com.nuclearplayer/themes/Livara.json" \
    < <(find "$XDG_DATA_HOME" "$HOME/.local/share" "$HOME/.var/app" -type f -path '*/com.nuclearplayer/themes/Livara.json' -print 2>/dev/null || true)
)
if ((${#nuclear_candidates[@]} == 0)); then
  fail 'Nuclear Livara theme was not found'
else
  for nuclear_theme in "${nuclear_candidates[@]}"; do
    info "Nuclear theme: $nuclear_theme"
    jq -e '.version == 2 and .name == "Livara" and (.dark | type == "object")' "$nuclear_theme" >/dev/null 2>&1 \
      && pass "Nuclear v2 theme is valid: $nuclear_theme" || fail "Nuclear theme is invalid: $nuclear_theme"
    nuclear_data="$(dirname "$(dirname "$nuclear_theme")")"
    nuclear_settings="$nuclear_data/settings.json"
    if [[ -s "$nuclear_settings" ]] && jq -e \
      --arg theme_id 'themes/Livara.json' \
      '."core.theme.active.type" == "advanced" and ."core.theme.active.id" == $theme_id' \
      "$nuclear_settings" >/dev/null 2>&1; then
      pass "Nuclear active theme points to Livara: $nuclear_settings"
    else
      warn "Nuclear theme is available but its active selection is not confirmed: $nuclear_settings"
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
