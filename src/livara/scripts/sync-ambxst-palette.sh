#!/usr/bin/env bash
set -Eeuo pipefail

XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
source_file="${AMBXST_COLORS_FILE:-$XDG_CACHE_HOME/ambxst/colors.json}"
theme_root="${LIVARA_THEME_ROOT:-$XDG_STATE_HOME/livara/theme}"

[[ -s "$source_file" ]] || exit 0
command -v jq >/dev/null 2>&1 || exit 1

is_hex='^#[0-9A-Fa-f]{6}$'
color() {
  local key="$1"
  jq -er --arg key "$key" '.[$key] // error("missing color: " + $key)' "$source_file" \
    | grep -E "$is_hex"
}

# Validate every source role before touching a consumer output.
for key in background surface surfaceContainer surfaceContainerHigh overBackground \
  outline outlineVariant primary secondary tertiary error blue cyan green magenta red yellow \
  overPrimary overSecondary overTertiary; do
  color "$key" >/dev/null
done

mkdir -p "$theme_root" "$theme_root/wezterm"
tmpdir="$(mktemp -d "$theme_root/.ambxst-palette.XXXXXX")"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

jq -n --slurpfile c "$source_file" '
  def c($key; $fallback): ($c[0][$key] // $c[0][$fallback]);
  {
    base: c("background"; "surface"),
    surface0: c("surface"; "background"),
    surface1: c("surfaceContainer"; "surface"),
    surface2: c("surfaceContainerHigh"; "surfaceContainer"),
    mantle: c("surfaceContainerLowest"; "surfaceContainer"),
    crust: c("surfaceContainerLowest"; "background"),
    text: c("overBackground"; "white"),
    subtext0: c("outline"; "outlineVariant"),
    subtext1: c("outlineVariant"; "outline"),
    overlay0: c("outline"; "outlineVariant"),
    overlay1: c("outlineVariant"; "outline"),
    blue: c("primary"; "blue"),
    sapphire: c("blue"; "primary"),
    teal: c("secondary"; "cyan"),
    green: c("green"; "secondary"),
    yellow: c("yellow"; "tertiary"),
    peach: c("tertiary"; "primary"),
    maroon: c("error"; "red"),
    red: c("red"; "error"),
    mauve: c("tertiary"; "primary"),
    pink: c("magenta"; "primary"),
    lavender: c("primary"; "blue"),
    primary: c("primary"; "blue"),
    secondary: c("secondary"; "cyan"),
    tertiary: c("tertiary"; "primary"),
    error: c("error"; "red")
  }
' > "$tmpdir/palette.dark.json"
jq -e 'type == "object" and (to_entries | all(.value | type == "string" and test("^#[0-9A-Fa-f]{6}$")))' "$tmpdir/palette.dark.json" >/dev/null
cp "$tmpdir/palette.dark.json" "$tmpdir/palette.json"

jq -r '
  "[colors]",
  ("foreground = " + (.text | @json)),
  ("background = " + (.base | @json)),
  ("cursor_bg = " + (.primary | @json)),
  ("cursor_fg = " + (.base | @json)),
  ("selection_fg = " + (.text | @json)),
  ("selection_bg = " + (.surface1 | @json)),
  "ansi = [" + ([.base, .red, .green, .yellow, .blue, .mauve, .teal, .text] | map(@json) | join(", ")) + "]",
  "brights = [" + ([.surface1, .red, .green, .yellow, .blue, .mauve, .teal, .text] | map(@json) | join(", ")) + "]"
' "$tmpdir/palette.dark.json" > "$tmpdir/Ambxst.toml"

for name in palette.dark.json palette.json Ambxst.toml; do
  case "$name" in
    Ambxst.toml) target="$theme_root/wezterm/$name" ;;
    *) target="$theme_root/$name" ;;
  esac
  chmod 0644 "$tmpdir/$name"
  mv -f "$tmpdir/$name" "$target"
done
