-- WezTerm configuration for niri.
--
-- Forces XWayland (enable_wayland = false) to work around WezTerm's
-- Wayland/niri sizing bugs (#7886, #4708, #6472): on native Wayland
-- WezTerm ignores niri's default-column-width and opens at 80 columns,
-- shifting the viewport.  Through XWayland niri sizes the window like
-- any other X11 client.  The Noctalia-generated color scheme
-- (~/.config/wezterm/colors/Noctalia.toml) is loaded by name.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.enable_wayland = false
-- Host-specific DPI is inserted by the Home Manager support module.
-- @LIVARA_WEZTERM_DPI@
-- Fastfetch uses the Kitty graphics protocol for the dynamic Matugen-colored cat PNG.
config.enable_kitty_graphics = true
config.adjust_window_size_when_changing_font_size = false
-- Let niri choose the window geometry; snapping to cell increments can make
-- the first XWayland configure event appear to have a different scale.
config.use_resize_increments = false
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.window_padding = {
  left = 12,
  right = 12,
  top = 10,
  bottom = 10,
}
config.hide_tab_bar_if_only_one_tab = true
config.enable_tab_bar = false
config.use_fancy_tab_bar = false

config.color_scheme = "Noctalia"
pcall(wezterm.add_to_config_reload_watch_list,
      wezterm.config_dir .. "/colors/Noctalia.toml")

config.window_background_opacity = 0.88
config.text_background_opacity = 0.92
config.automatically_reload_config = true

config.font = wezterm.font_with_fallback({
  "JetBrains Mono",
  "Symbols Nerd Font Mono",
  "Noto Sans Mono",
})
config.font_size = 11.0
config.line_height = 1.0

config.scrollback_lines = 10000
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 700
config.audible_bell = "Disabled"
config.warn_about_missing_glyphs = false

return config
