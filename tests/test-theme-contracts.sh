#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
sync_script="$repo_root/src/livara/scripts/sync-livara-themes.sh"
root="$PWD/livara-theme-test.$$"
mkdir -p "$root"
trap 'rm -rf "$root"' EXIT
config_home="$root/config"
state_home="$root/state"
bin_dir="$root/bin"
mkdir -p "$config_home/xournalpp" "$config_home/com.github.johnfactotum.Foliate" "$root/data/FreesmLauncher" "$bin_dir" "$state_home/livara/theme"
mkdir -p "$config_home/vesktop"
cat > "$state_home/livara/theme/bootstrap.json" <<'EOF'
{"base":"#111318","primary":"#7bb7ff","surface0":"#1a2029","surface1":"#242b36","secondary":"#74d7c4","text":"#eef2f7","subtext0":"#b2bdca","blue":"#7bb7ff","teal":"#70d7c3","on_primary":"#0c1420","on_secondary":"#0c1420","on_tertiary":"#0c1420","on_error":"#0c1420","red":"#f0878a","sapphire":"#9bc9ff","crust":"#07090d","mantle":"#0b0d12","overlay0":"#596575","overlay1":"#6d7a8b"}
EOF
cat > "$config_home/xournalpp/settings.xml" <<'EOF'
<settings>
  <property name="backgroundColor" value="4278190080"/>
  <property name="selectionBorderColor" value="4278190080"/>
  <property name="colorPalette" value="/old/first.gpl"/>
  <property name="colorPalette" value="/old/second.gpl"/>
  <property name="menubarVisible" value="true"/>
  <property name="defaultViewModeAttributes" value="showMenubar,showToolbar,showSidebar"/>
  <property name="pageTemplate" value="xoj/template&#10;backgroundType=graph&#10;backgroundTypeConfig=f1=#ffffff,af1=#ffffff&#10;backgroundColor=#000000&#10;"/>
</settings>
EOF
export HOME="$root/home"
export PATH="$bin_dir:$PATH"
export XDG_CONFIG_HOME="$config_home"
export XDG_STATE_HOME="$state_home"
export XDG_DATA_HOME="$root/data"
export LIVARA_THEME_ROOT="$state_home/livara/theme"
export LIVARA_DEFAULT_PALETTE="$state_home/livara/theme/bootstrap.json"
export LIVARA_FASTFETCH_CAT_PNG="$root/missing.png"
export LIVARA_HYDRA_FRIEND_CODE=""
export LIVARA_HYDRA_SCREENSHOT="$root/missing-screenshot.png"
export LIVARA_SHELL_NAME="Livara"
bash "$sync_script" dark >/dev/null
[[ ! -e "$state_home/livara/theme/palette.light.json" ]]
[[ -s "$state_home/livara/theme/browser/firefox.css" ]]
grep -q -- '--livara-accent: #7bb7ff' "$state_home/livara/theme/browser/firefox.css"
grep -q -- '--livara-on-accent: #0c1420' "$state_home/livara/theme/browser/firefox.css"
grep -q '#navigator-toolbox' "$state_home/livara/theme/browser/firefox.css"
grep -q '#zen-browser-background' "$state_home/livara/theme/browser/firefox.css"
grep -q '#zen-sidebar-foot-buttons' "$state_home/livara/theme/browser/firefox.css"
grep -q '#urlbar-background' "$state_home/livara/theme/browser/firefox.css"
grep -q 'border-inline-end: 1px solid var(--livara-border)' "$state_home/livara/theme/browser/firefox.css"
grep -q 'border-bottom: 1px solid var(--livara-border)' "$state_home/livara/theme/browser/firefox.css"
! grep -q 'toolbarbutton-icon.*background' "$state_home/livara/theme/browser/firefox.css"
[[ -s "$config_home/vesktop/themes/livara-midnight.theme.css" ]]
grep -q 'refact0r.github.io/midnight-discord/build/midnight.css' "$config_home/vesktop/themes/livara-midnight.theme.css"
jq -e '(.enabledThemes // []) | index("livara-midnight.theme.css") != null' "$config_home/vesktop/settings/settings.json" >/dev/null
[[ -s "$state_home/livara/theme/fastfetch.jsonc" ]]
jq -e '.modules[1].keyColor == "#7bb7ff" and (.modules | map(select(.key | contains("{#"))) | length == 0)' "$state_home/livara/theme/fastfetch.jsonc" >/dev/null
[[ -s "$config_home/wezterm/colors/Livara.toml" ]]
grep -q 'cursor_border = "#7bb7ff"' "$config_home/wezterm/colors/Livara.toml"
[[ -s "$config_home/btop/themes/Livara.theme" ]]
grep -q 'theme\[mem_box\]="#74d7c4"' "$config_home/btop/themes/Livara.theme"
grep -q 'color_theme = "Livara"' "$config_home/btop/btop.conf"
[[ -s "$config_home/nvim/lua/matugen_colors.lua" ]]
grep -q 'primary = "#7bb7ff"' "$config_home/nvim/lua/matugen_colors.lua"
[[ -s "$config_home/gtk-3.0/gtk.css" && -s "$config_home/gtk-4.0/gtk.css" ]]
grep -q 'background-color: #111318;' "$config_home/gtk-3.0/gtk.css"
grep -q -- '--window-bg-color: #111318;' "$config_home/gtk-4.0/gtk.css"
grep -q -- '--accent-color: #7bb7ff;' "$config_home/gtk-4.0/gtk.css"
grep -q -- '--error-color:' "$config_home/gtk-4.0/gtk.css"
grep -q 'gtk-theme-name=Adwaita' "$config_home/gtk-3.0/settings.ini"
grep -q 'gtk-interface-color-scheme=dark' "$config_home/gtk-4.0/settings.ini"
[[ -s "$config_home/com.github.johnfactotum.Foliate/themes/Livara.json" ]]
jq -e '.light.fg == "#eef2f7" and .dark.bg == "#111318"' "$config_home/com.github.johnfactotum.Foliate/themes/Livara.json" >/dev/null
grep -q '^ApplicationTheme=livara$' "$root/data/FreesmLauncher/freesmlauncher.cfg"
jq -e '.logColors.Message and .logColors.Fatal and .logColors.MessageHighlight' "$root/data/FreesmLauncher/themes/livara/theme.json" >/dev/null
printf '%s\n' 'browser, GTK, Foliate, Freesm, terminal, monitor and editor theme contracts passed'
[[ -s "$config_home/xournalpp/palettes/livara.gpl" ]]
grep -q '^Name: Livara$' "$config_home/xournalpp/palettes/livara.gpl"
! grep -Eiq '[[:space:]](Primary|Primary Container|Secondary|Tertiary|Error|Crust|Mantle)$' "$config_home/xournalpp/palettes/livara.gpl"
awk 'NF >= 3 && $1 ~ /^[0-9]+$/ { key = $1 FS $2 FS $3; if (++seen[key] > 1) exit 1 }' "$config_home/xournalpp/palettes/livara.gpl"
grep -q 'livara.gpl' "$config_home/xournalpp/settings.xml"
grep -q 'backgroundTypeConfig=f1=#596575,af1=#0b0d12' "$config_home/xournalpp/settings.xml"
grep -q 'backgroundColor=#000000' "$config_home/xournalpp/settings.xml"
grep -q 'name="menubarVisible" value="false"' "$config_home/xournalpp/settings.xml"
grep -q 'name="defaultViewModeAttributes" value="showToolbar,showSidebar"' "$config_home/xournalpp/settings.xml"
! grep -q 'name="defaultViewModeAttributes" value="showMenubar' "$config_home/xournalpp/settings.xml"
[[ ! -e "$config_home/Hydra/themes/Livara-local/theme.css" ]]
[[ -s "$state_home/livara/theme/hydra-export/themes/Livara-local/theme.css" ]]
grep -q 'Settings > Appearance' "$state_home/livara/theme/hydra-export/themes/Livara-local/README.txt"
if bash "$sync_script" light >/dev/null 2>&1; then
  echo 'light mode unexpectedly accepted' >&2
  exit 1
fi
grep -q 'gtk-application-prefer-dark-theme=true' "$config_home/gtk-3.0/settings.ini"
printf '%s\n' 'dark-only contract passed'
! jq -e '.applications[] | select(.name == "Hydra Launcher" and .submissionReady == true)' "$state_home/livara/theme/applied-applications.json" >/dev/null
printf '%s\n' 'local contract passed'
export LIVARA_HYDRA_FRIEND_CODE="ABC123"
export LIVARA_HYDRA_SCREENSHOT="$root/screenshot.png"
printf '%s\n' 'screenshot' > "$LIVARA_HYDRA_SCREENSHOT"
bash "$sync_script" dark >/dev/null
[[ ! -e "$config_home/Hydra/themes/Livara-ABC123/theme.css" ]]
[[ -s "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/theme.css" ]]
[[ -s "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/README.txt" ]]
[[ -s "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/screenshot.png" ]]
jq -e '.applications[] | select(.name == "Hydra Launcher" and .submissionReady == true and .generated == true)' "$state_home/livara/theme/applied-applications.json" >/dev/null
grep -q 'name="backgroundColor" value="4278914322"' "$config_home/xournalpp/settings.xml"
grep -q 'name="selectionBorderColor" value="4286298111"' "$config_home/xournalpp/settings.xml"
[[ "$(grep -c 'name="colorPalette"' "$config_home/xournalpp/settings.xml")" == 1 ]]
printf '%s\n' 'submission contract passed'
settings_before="$(sha256sum "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/theme.css" | cut -d' ' -f1)"
bash "$sync_script" dark >/dev/null
settings_after="$(sha256sum "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/theme.css" | cut -d' ' -f1)"
[[ "$settings_before" == "$settings_after" ]]
printf '%s\n' 'idempotence contract passed'
bash "$sync_script" dark >/dev/null
printf '%s\n' 'multi-root and removed adapter contracts passed'
env -u XDG_DATA_HOME bash "$sync_script" dark >/dev/null
printf '%s\n' 'xdg fallback contract passed'
before_invalid="$(sha256sum "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/theme.css" "$config_home/vesktop/themes/livara-midnight.theme.css")"
printf '%s\n' '{"base":"not-a-color","blue":"#123"}' > "$state_home/livara/theme/palette.dark.json"
if bash "$sync_script" dark >/dev/null 2>&1; then
  echo 'invalid canonical palette was accepted' >&2
  exit 1
fi
after_invalid="$(sha256sum "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/theme.css" "$config_home/vesktop/themes/livara-midnight.theme.css")"
[[ "$before_invalid" == "$after_invalid" ]]
! grep -q 'not-a-color' "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/theme.css"
printf '%s\n' 'palette validation contract passed'
