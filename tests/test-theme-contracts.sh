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
mkdir -p "$config_home/JetBrains/IntelliJIdea2026.1" "$config_home/Google/AndroidStudio2025.1" "$root/data/JetBrains/IntelliJIdea2026.1" "$root/data/Google/AndroidStudio2025.1" "$config_home/matugen" "$config_home/spicetify/Themes/Livara" "$config_home/xournalpp" "$bin_dir" "$state_home/livara/theme"
cat > "$state_home/livara/theme/bootstrap.json" <<'EOF'
{"base":"#111318","primary":"#7bb7ff","surface0":"#1a2029","surface1":"#242b36","text":"#eef2f7","subtext0":"#b2bdca","blue":"#7bb7ff","teal":"#70d7c3","red":"#f0878a","sapphire":"#9bc9ff","crust":"#07090d","mantle":"#0b0d12","overlay0":"#596575","overlay1":"#6d7a8b"}
EOF
cat > "$config_home/matugen/config.toml" <<'EOF'
[config]
EOF
printf '%s\n' 'main = 111318' > "$config_home/spicetify/Themes/Livara/color.ini"
cat > "$config_home/xournalpp/settings.xml" <<'EOF'
<settings>
  <property name="backgroundColor" value="4278190080"/>
  <property name="selectionBorderColor" value="4278190080"/>
  <property name="pageTemplate" value="xoj/template&#10;backgroundType=graph&#10;backgroundColor=#000000&#10;"/>
</settings>
EOF
cat > "$bin_dir/matugen" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
mkdir -p "$LIVARA_THEME_ROOT/intellij"
printf '%s\n' '<scheme name="Matugen Dark" version="142" parent_scheme="Darcula" />' > "$LIVARA_THEME_ROOT/intellij/Matugen-Dark.icls"
EOF
cat > "$bin_dir/spicetify" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '%s\n' "$*" >> "$LIVARA_THEME_ROOT/spicetify-apply.log"
if [[ "$1 ${2:-} ${3:-}" == "config current_theme Livara" ]]; then
  mkdir -p "$XDG_CONFIG_HOME/spicetify"
  printf '%s\n' 'current_theme = Livara' > "$XDG_CONFIG_HOME/spicetify/config-xpui.ini"
  exit 0
fi
if [[ "${SPICETIFY_FAIL:-0}" == "1" && "$*" == *"apply"* ]]; then
  exit 1
fi
EOF
chmod +x "$bin_dir/matugen" "$bin_dir/spicetify"
export HOME="$root/home"
export PATH="$bin_dir:$PATH"
export XDG_CONFIG_HOME="$config_home"
export XDG_STATE_HOME="$state_home"
export XDG_DATA_HOME="$root/data"
export LIVARA_THEME_ROOT="$state_home/livara/theme"
export LIVARA_DEFAULT_PALETTE="$state_home/livara/theme/bootstrap.json"
export MATUGEN_CONFIG="$config_home/matugen-config.toml"
export LIVARA_FASTFETCH_CAT_PNG="$root/missing.png"
export LIVARA_HYDRA_FRIEND_CODE=""
export LIVARA_HYDRA_SCREENSHOT="$root/missing-screenshot.png"
export LIVARA_IDE_THEME_PLUGIN="$root/livara-theme"
mkdir -p "$LIVARA_IDE_THEME_PLUGIN/META-INF"
printf '%s\n' '<idea-plugin />' > "$LIVARA_IDE_THEME_PLUGIN/META-INF/plugin.xml"
bash "$sync_script" dark >/dev/null
[[ -L "$config_home/JetBrains/IntelliJIdea2026.1/colors/Matugen-Dark.icls" ]]
[[ -L "$config_home/Google/AndroidStudio2025.1/colors/Matugen-Dark.icls" ]]
[[ -L "$root/data/JetBrains/IntelliJIdea2026.1/plugins/LivaraTheme" ]]
[[ -L "$root/data/Google/AndroidStudio2025.1/plugins/LivaraTheme" ]]
[[ -s "$config_home/xournalpp/palettes/tokyonight.gpl" ]]
grep -q '^Name: Tokyo Night$' "$config_home/xournalpp/palettes/tokyonight.gpl"
grep -q 'tokyonight.gpl' "$config_home/xournalpp/settings.xml"
grep -q 'backgroundTypeConfig=f1=#596575,af1=#596575' "$config_home/xournalpp/settings.xml"
[[ -s "$state_home/livara/theme/hydra-export/themes/Livara-local/theme.css" ]]
jq -e '.applications[] | select(.name == "Spotify via Spicetify" and .generated == true and .applied == true)' "$state_home/livara/theme/applied-applications.json" >/dev/null
jq -e '.applications[] | select(.name == "Telegram Desktop" and .generated == true and .applied == false)' "$state_home/livara/theme/applied-applications.json" >/dev/null
jq -e '.applications[] | select(.name == "IntelliJ IDEA UI theme" and .installed == true and .applied == false)' "$state_home/livara/theme/applied-applications.json" >/dev/null
! jq -e '.applications[] | select(.name == "Hydra Launcher" and .submissionReady == true)' "$state_home/livara/theme/applied-applications.json" >/dev/null
printf '%s\n' 'local contract passed'
export LIVARA_HYDRA_FRIEND_CODE="ABC123"
export LIVARA_HYDRA_SCREENSHOT="$root/screenshot.png"
printf '%s\n' 'screenshot' > "$LIVARA_HYDRA_SCREENSHOT"
bash "$sync_script" dark >/dev/null
[[ -s "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/theme.css" ]]
[[ -s "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/README.txt" ]]
[[ -s "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/screenshot.png" ]]
jq -e '.applications[] | select(.name == "Hydra Launcher" and .submissionReady == true and .generated == true)' "$state_home/livara/theme/applied-applications.json" >/dev/null
export SPICETIFY_FAIL=1
bash "$sync_script" dark >/dev/null
! jq -e '.applications[] | select(.name == "Spotify via Spicetify" and .applied == true)' "$state_home/livara/theme/applied-applications.json" >/dev/null
printf '%s\n' 'submission contract passed'
