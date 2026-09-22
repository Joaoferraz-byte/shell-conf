#!/usr/bin/env bash
set -Eeuo pipefail

XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
source_file="${AMBXST_COLORS_FILE:-$XDG_CACHE_HOME/ambxst/colors.json}"
theme_root="${LIVARA_THEME_ROOT:-$XDG_STATE_HOME/livara/theme}"
variant="${LIVARA_PALETTE_VARIANT:-dark}"
NVIM_THEME_PATH="${NVIM_THEME_PATH:-$XDG_CONFIG_HOME/nvim/lua/matugen_colors.lua}"

case "$variant" in
  dark|light) ;;
  *) printf 'invalid Livara palette variant: %s\n' "$variant" >&2; exit 2 ;;
esac
[[ -s "$source_file" ]] || exit 0
command -v jq >/dev/null 2>&1 || exit 1

is_hex='^#[0-9A-Fa-f]{6}$'
color() {
  local key="$1"
  jq -er --arg key "$key" '.[$key] // error("missing color: " + $key)' "$source_file" \
    | grep -E "$is_hex"
}

# Validate every source role before touching a consumer output.
for key in background surface surfaceContainer surfaceContainerHigh \
  overBackground outline outlineVariant primary secondary tertiary error blue cyan green magenta red yellow \
  overPrimary overSecondary overTertiary; do
  color "$key" >/dev/null
done

mkdir -p "$theme_root" "$theme_root/wezterm" "$(dirname "$NVIM_THEME_PATH")"
tmpdir="$(mktemp -d "$theme_root/.ambxst-palette.XXXXXX")"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

atomic_install() {
  local source="$1" target="$2" target_dir tmp
  target_dir="$(dirname "$target")"
  mkdir -p "$target_dir"
  tmp="$(mktemp "$target_dir/.livara-theme.XXXXXX")"
  cat "$source" > "$tmp"
  chmod 0644 "$tmp"
  mv -f -- "$tmp" "$target"
}

jq -n --slurpfile c "$source_file" '
  def c($key; $fallback): ($c[0][$key] // $c[0][$fallback]);
  {
    base: c("background"; "surface"),
    mantle: c("surfaceContainerLowest"; "surfaceContainer"),
    crust: c("surfaceContainerLowest"; "background"),
    surface0: c("surface"; "background"),
    surface1: c("surfaceContainer"; "surface"),
    surface2: c("surfaceContainerHigh"; "surfaceContainer"),
    surface3: c("surfaceContainerHigh"; "surfaceContainer"),
    text: c("overBackground"; "white"),
    on_surface: c("overBackground"; "white"),
    subtext0: c("outline"; "outlineVariant"),
    subtext1: c("outlineVariant"; "outline"),
    overlay0: c("outline"; "outlineVariant"),
    overlay1: c("outlineVariant"; "outline"),
    overlay2: c("overBackground"; "outlineVariant"),
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
    error: c("error"; "red"),
    on_primary: c("overPrimary"; "background"),
    on_secondary: c("overSecondary"; "background"),
    on_tertiary: c("overTertiary"; "background"),
    on_error: c("overError"; "background")
  }
' > "$tmpdir/palette.$variant.json"
jq -e 'type == "object" and (to_entries | all(.value | type == "string" and test("^#[0-9A-Fa-f]{6}$")))' \
  "$tmpdir/palette.$variant.json" >/dev/null

# Keep palette.json as the currently active projection while preserving the
# other variant. The variant-specific file is the source selected by adapters.
cp "$tmpdir/palette.$variant.json" "$tmpdir/palette.json"

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
' "$tmpdir/palette.$variant.json" > "$tmpdir/Ambxst.toml"

jq -r 'to_entries | map("  " + .key + " = " + (.value | @json) + ",") | "return {\n" + join("\n") + "\n}\n"' \
  "$tmpdir/palette.$variant.json" > "$tmpdir/matugen_colors.lua"

atomic_install "$tmpdir/palette.$variant.json" "$theme_root/palette.$variant.json"
atomic_install "$tmpdir/palette.json" "$theme_root/palette.json"
atomic_install "$tmpdir/Ambxst.toml" "$theme_root/wezterm/Ambxst.toml"
atomic_install "$tmpdir/matugen_colors.lua" "$NVIM_THEME_PATH"
