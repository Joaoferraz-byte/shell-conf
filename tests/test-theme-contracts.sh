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
cat > "$bin_dir/matugen" <<'EOF'
#!/usr/bin/env bash
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
mkdir -p "$LIVARA_IDE_THEME_PLUGIN/META-INF" "$root/data/com.nuclearplayer"
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
[[ -L "$config_home/JetBrains/IntelliJIdea2026.1/colors/Matugen-Dark.icls" ]]
[[ -L "$config_home/Google/AndroidStudio2025.1/colors/Matugen-Dark.icls" ]]
[[ -L "$root/data/JetBrains/IntelliJIdea2026.1/plugins/LivaraTheme" ]]
[[ -L "$root/data/Google/AndroidStudio2025.1/plugins/LivaraTheme" ]]
[[ -s "$config_home/xournalpp/palettes/tokyonight.gpl" ]]
grep -q '^Name: Tokyo Night$' "$config_home/xournalpp/palettes/tokyonight.gpl"
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
printf '%s\n' '{"base":"not-a-color","blue":"#123"}' > "$state_home/livara/theme/palette.dark.json"
bash "$sync_script" dark >/dev/null
! grep -q 'not-a-color' "$config_home/Hydra/themes/Livara-ABC123/theme.css"
grep -q '#111318' "$config_home/Hydra/themes/Livara-ABC123/theme.css"
printf '%s\n' 'palette validation contract passed'
