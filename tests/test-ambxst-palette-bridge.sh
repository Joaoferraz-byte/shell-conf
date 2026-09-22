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
  "background":"#101010","surface":"#202020","surfaceContainer":"#303030","surfaceContainerHigh":"#404040","overBackground":"#f0f0f0","outline":"#808080","outlineVariant":"#606060","primary":"#ff5577","secondary":"#55ccaa","tertiary":"#ddaa55","error":"#ff3333","blue":"#5599ff","cyan":"#55dddd","green":"#55dd77","magenta":"#dd55dd","red":"#ff3333","yellow":"#dddd55","overPrimary":"#22000a","overSecondary":"#002211","overTertiary":"#221100"
}
JSON

bash "$bridge"
test "$(jq -r .blue "$LIVARA_THEME_ROOT/palette.dark.json")" = '#ff5577'
test "$(jq -r .base "$LIVARA_THEME_ROOT/palette.json")" = '#101010'
grep -Fq 'background = "#101010"' "$LIVARA_THEME_ROOT/wezterm/Ambxst.toml"
grep -Fxq 'return {' "$HOME/.config/nvim/lua/matugen_colors.lua"
grep -Fq 'primary = "#ff5577"' "$HOME/.config/nvim/lua/matugen_colors.lua"

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
