#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
bridge="$repo_root/src/livara/scripts/sync-ambxst-palette.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export HOME="$tmp/home"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export LIVARA_THEME_ROOT="$XDG_STATE_HOME/livara/theme"
mkdir -p "$XDG_CACHE_HOME/ambxst"

cat > "$XDG_CACHE_HOME/ambxst/colors.json" <<'JSON'
{
  "background":"#101010","surface":"#202020","surfaceContainerLowest":"#181818","surfaceContainerLow":"#242424","surfaceContainer":"#303030","surfaceContainerHigh":"#404040","surfaceContainerHighest":"#505050","overBackground":"#f0f0f0","overError":"#220000","outline":"#808080","outlineVariant":"#606060","primary":"#ff5577","primaryContainer":"#552233","secondary":"#55ccaa","secondaryContainer":"#225544","tertiary":"#ddaa55","tertiaryContainer":"#554422","error":"#ff3333","blue":"#5599ff","cyan":"#55dddd","green":"#55dd77","magenta":"#dd55dd","red":"#ff3333","yellow":"#dddd55","overPrimary":"#22000a","overSecondary":"#002211","overTertiary":"#221100"
}
JSON

mkdir -p "$LIVARA_THEME_ROOT/wezterm"
printf '%s\n' legacy > "$LIVARA_THEME_ROOT/wezterm/Ambxst.toml"
bash "$bridge"
test "$(jq -r .blue "$LIVARA_THEME_ROOT/palette.dark.json")" = '#ff5577'
test "$(jq -r .base "$LIVARA_THEME_ROOT/palette.json")" = '#202020'
test "$(jq -r .surface0 "$LIVARA_THEME_ROOT/palette.json")" = '#303030'
test "$(jq -r .surface1 "$LIVARA_THEME_ROOT/palette.json")" = '#404040'
[[ ! -e "$LIVARA_THEME_ROOT/wezterm/Ambxst.toml" ]]
[[ ! -e "$HOME/.config/nvim/lua/matugen_colors.lua" ]]

cp "$LIVARA_THEME_ROOT/palette.dark.json" "$tmp/previous.json"
printf '{"primary":"not-a-color"}\n' > "$XDG_CACHE_HOME/ambxst/colors.json"
if bash "$bridge"; then
  echo 'invalid palette unexpectedly accepted' >&2
  exit 1
fi
cmp -s "$tmp/previous.json" "$LIVARA_THEME_ROOT/palette.dark.json"

rm -f "$XDG_CACHE_HOME/ambxst/colors.json"
if LIVARA_REQUIRE_AMBXST=1 bash "$bridge"; then
  echo 'missing Ambxst palette unexpectedly accepted' >&2
  exit 1
fi
printf '%s\n' 'ambxst palette bridge contract passed'
