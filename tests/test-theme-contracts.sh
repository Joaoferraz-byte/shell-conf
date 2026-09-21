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
mkdir -p "$config_home/JetBrains/IntelliJIdea2026.1" "$config_home/Google/AndroidStudio2025.1" "$config_home/matugen" "$config_home/xournalpp" "$bin_dir" "$state_home/livara/theme"
mkdir -p "$config_home/vesktop"
cat > "$state_home/livara/theme/bootstrap.json" <<'EOF'
{"base":"#111318","primary":"#7bb7ff","surface0":"#1a2029","surface1":"#242b36","text":"#eef2f7","subtext0":"#b2bdca","blue":"#7bb7ff","teal":"#70d7c3","red":"#f0878a","sapphire":"#9bc9ff","crust":"#07090d","mantle":"#0b0d12","overlay0":"#596575","overlay1":"#6d7a8b"}
EOF
cat > "$config_home/matugen/config.toml" <<'EOF'
[config]
EOF
cat > "$config_home/xournalpp/settings.xml" <<'EOF'
<settings>
  <property name="backgroundColor" value="4278190080"/>
  <property name="selectionBorderColor" value="4278190080"/>
  <property name="colorPalette" value="/old/first.gpl"/>
  <property name="colorPalette" value="/old/second.gpl"/>
  <property name="menubarVisible" value="true"/>
  <property name="defaultViewModeAttributes" value="showMenubar,showToolbar,showSidebar"/>
  <property name="pageTemplate" value="xoj/template&#10;backgroundType=graph&#10;backgroundColor=#000000&#10;"/>
</settings>
EOF
printf '#!%s\n' "$(command -v bash)" > "$bin_dir/matugen"
cat >> "$bin_dir/matugen" <<'EOF'
set -Eeuo pipefail
mkdir -p "$LIVARA_THEME_ROOT/intellij"
printf '%s\n' '<scheme name="Matugen Dark" version="142" parent_scheme="Darcula" />' > "$LIVARA_THEME_ROOT/intellij/Matugen-Dark.icls"
EOF
chmod +x "$bin_dir/matugen"
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
export LIVARA_SHELL_NAME="Ambxst"
mkdir -p "$LIVARA_IDE_THEME_PLUGIN/META-INF" "$root/data/com.nuclearplayer"
cat > "$state_home/livara/theme/palette.dark.json" <<'EOF'
{"background":"#101318","surface":"#171d26","surfaceContainer":"#202936","surfaceContainerLowest":"#080a0e","surfaceDim":"#0b0d12","overBackground":"#eef2f7","outline":"#596575","outlineVariant":"#6d7a8b","primary":"#7bb7ff","primaryContainer":"#29405e","secondary":"#74d7c4","secondaryContainer":"#27493e","tertiary":"#e5bf89","tertiaryContainer":"#554218","error":"#f0878a","errorContainer":"#512d34","overPrimary":"#0c1420","overSecondary":"#0d1a13","overTertiary":"#2b1927","overError":"#2a1218","base":"#101318","mantle":"#0b0d12","crust":"#080a0e","text":"#eef2f7","subtext0":"#596575","subtext1":"#6d7a8b","surface0":"#171d26","surface1":"#202936","surface2":"#303946","overlay0":"#596575","overlay1":"#6d7a8b","overlay2":"#8b9aaa","blue":"#7bb7ff","sapphire":"#72d4e6","peach":"#e5bf89","green":"#83d6a3","red":"#f0878a","mauve":"#c2a4f5","pink":"#e7a9c3","maroon":"#d38b9b","yellow":"#e8cf85","teal":"#74d7c4"}
EOF
cat > "$LIVARA_IDE_THEME_PLUGIN/META-INF/plugin.xml" <<'EOF'
<idea-plugin>
  <id>com.joaoferraz.livara.theme</id>
  <name>Livara Theme</name>
  <version>1.0.0</version>
  <idea-version since-build="221"/>
  <extensions defaultExtensionNs="com.intellij">
    <themeProvider id="livara" path="/theme/Livara.theme.json"/>
  </extensions>
</idea-plugin>
EOF
bash "$sync_script" dark >/dev/null
[[ -s "$state_home/livara/theme/browser/firefox.css" ]]
grep -q -- '--livara-primary: #7bb7ff' "$state_home/livara/theme/browser/firefox.css"
grep -q '#navigator-toolbox' "$state_home/livara/theme/browser/firefox.css"
[[ -s "$config_home/vesktop/themes/livara-material.theme.css" ]]
jq -e '(.enabledThemes // []) | index("livara-material.theme.css") != null' "$config_home/vesktop/settings/settings.json" >/dev/null
printf '%s\n' 'browser and Vesktop theme contracts passed'
[[ -L "$config_home/JetBrains/IntelliJIdea2026.1/colors/Matugen-Dark.icls" ]]
[[ -L "$config_home/Google/AndroidStudio2025.1/colors/Matugen-Dark.icls" ]]
[[ -L "$root/data/JetBrains/IntelliJIdea2026.1/LivaraTheme" ]]
[[ -L "$root/data/Google/AndroidStudio2025.1/LivaraTheme" ]]
[[ -s "$config_home/xournalpp/palettes/tokyonight.gpl" ]]
grep -q '^Name: Tokyo Night$' "$config_home/xournalpp/palettes/tokyonight.gpl"
! grep -Eiq '[[:space:]](Primary|Primary Container|Secondary|Tertiary|Error|Crust|Mantle)$' "$config_home/xournalpp/palettes/tokyonight.gpl"
awk 'NF >= 3 && $1 ~ /^[0-9]+$/ { key = $1 FS $2 FS $3; if (++seen[key] > 1) exit 1 }' "$config_home/xournalpp/palettes/tokyonight.gpl"
grep -q 'tokyonight.gpl' "$config_home/xournalpp/settings.xml"
! grep -q 'backgroundTypeConfig=f1=' "$config_home/xournalpp/settings.xml"
grep -q 'backgroundColor=#000000' "$config_home/xournalpp/settings.xml"
grep -q 'name="menubarVisible" value="false"' "$config_home/xournalpp/settings.xml"
grep -q 'name="defaultViewModeAttributes" value="showToolbar,showSidebar"' "$config_home/xournalpp/settings.xml"
! grep -q 'name="defaultViewModeAttributes" value="showMenubar' "$config_home/xournalpp/settings.xml"
[[ -s "$config_home/Hydra/themes/Livara-local/theme.css" ]]
[[ -s "$state_home/livara/theme/hydra-export/themes/Livara-local/theme.css" ]]
grep -q 'Settings > Appearance' "$config_home/Hydra/themes/Livara-local/README.txt"
jq -e '.applications[] | select(.name == "Nuclear Music Player" and .generated == true and .applied == true)' "$state_home/livara/theme/applied-applications.json" >/dev/null
jq -e '."core.theme.active.type" == "advanced" and ."core.theme.active.id" == "themes/Livara.json" and ."core.theme.dark" == true' "$root/data/com.nuclearplayer/settings.json" >/dev/null
rm -f "$root/data/com.nuclearplayer/settings.json"
bash "$sync_script" light >/dev/null
jq -e '."core.theme.active.type" == "advanced" and ."core.theme.active.id" == "themes/Livara.json" and ."core.theme.dark" == false' "$root/data/com.nuclearplayer/settings.json" >/dev/null
printf '%s\n' 'light mode contract passed'
jq -e '."core.theme.dark" == false' "$root/data/com.nuclearplayer/settings.json" >/dev/null
bash "$sync_script" dark >/dev/null
jq -e '."core.theme.dark" == true' "$root/data/com.nuclearplayer/settings.json" >/dev/null
printf '%s\n' 'dark/light transition contract passed'
jq -e '.applications[] | select(.name == "IntelliJ IDEA UI theme" and .installed == true and .applied == true)' "$state_home/livara/theme/applied-applications.json" >/dev/null
grep -q 'themeId="livara"' "$config_home/JetBrains/IntelliJIdea2026.1/options/laf.xml"
grep -q 'themeId="livara"' "$config_home/Google/AndroidStudio2025.1/options/laf.xml"
grep -q 'themeProvider.*path="/theme/Livara.theme.json"' "$state_home/livara/theme/intellij/LivaraTheme/META-INF/plugin.xml"
[[ -s "$state_home/livara/theme/intellij/LivaraTheme/theme/Matugen-Dark.xml" ]]
! jq -e '.applications[] | select(.name == "Hydra Launcher" and .submissionReady == true)' "$state_home/livara/theme/applied-applications.json" >/dev/null
printf '%s\n' 'local contract passed'
export LIVARA_HYDRA_FRIEND_CODE="ABC123"
export LIVARA_HYDRA_SCREENSHOT="$root/screenshot.png"
printf '%s\n' 'screenshot' > "$LIVARA_HYDRA_SCREENSHOT"
bash "$sync_script" dark >/dev/null
[[ -s "$config_home/Hydra/themes/Livara-ABC123/theme.css" ]]
[[ -s "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/theme.css" ]]
[[ -s "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/README.txt" ]]
[[ -s "$state_home/livara/theme/hydra-export/themes/Livara-ABC123/screenshot.png" ]]
jq -e '.applications[] | select(.name == "Hydra Launcher" and .submissionReady == true and .generated == true)' "$state_home/livara/theme/applied-applications.json" >/dev/null
grep -q '"version": 2' "$root/data/com.nuclearplayer/themes/Livara.json"
grep -q 'name="backgroundColor" value="4278914322"' "$config_home/xournalpp/settings.xml"
grep -q 'name="selectionBorderColor" value="4286298111"' "$config_home/xournalpp/settings.xml"
[[ "$(grep -c 'name="colorPalette"' "$config_home/xournalpp/settings.xml")" == 1 ]]
printf '%s\n' 'submission contract passed'
settings_before="$(sha256sum "$root/data/com.nuclearplayer/settings.json" | cut -d' ' -f1)"
bash "$sync_script" dark >/dev/null
settings_after="$(sha256sum "$root/data/com.nuclearplayer/settings.json" | cut -d' ' -f1)"
[[ "$settings_before" == "$settings_after" ]]
printf '%s\n' 'idempotence contract passed'
mkdir -p "$HOME/.var/app/com.nuclearplayer.Nuclear"
bash "$sync_script" dark >/dev/null
[[ -s "$HOME/.var/app/com.nuclearplayer.Nuclear/data/com.nuclearplayer/themes/Livara.json" ]]
jq -e '."core.theme.active.type" == "advanced" and ."core.theme.active.id" == "themes/Livara.json" and ."core.theme.dark" == true' "$HOME/.var/app/com.nuclearplayer.Nuclear/data/com.nuclearplayer/settings.json" >/dev/null
printf '%s\n' 'multi-root and removed adapter contracts passed'
env -u XDG_DATA_HOME bash "$sync_script" dark >/dev/null
printf '%s\n' 'xdg fallback contract passed'
before_invalid="$(sha256sum "$config_home/Hydra/themes/Livara-ABC123/theme.css" "$config_home/vesktop/themes/livara-material.theme.css")"
printf '%s\n' '{"base":"not-a-color","blue":"#123"}' > "$state_home/livara/theme/palette.dark.json"
if bash "$sync_script" dark >/dev/null 2>&1; then
  echo 'invalid Ambxst canonical palette was accepted' >&2
  exit 1
fi
after_invalid="$(sha256sum "$config_home/Hydra/themes/Livara-ABC123/theme.css" "$config_home/vesktop/themes/livara-material.theme.css")"
[[ "$before_invalid" == "$after_invalid" ]]
! grep -q 'not-a-color' "$config_home/Hydra/themes/Livara-ABC123/theme.css"
printf '%s\n' 'palette validation contract passed'
