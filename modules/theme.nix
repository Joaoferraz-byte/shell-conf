{ config, pkgs, lib, ... }:

{
  # Catppuccin for GTK
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-lavender-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "lavender" ];
        size = "standard";
        tweaks = [ "rimless" ];
        variant = "mocha";
      };
    };
    iconTheme = {
      name = "kora";
      package = pkgs.kora-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
  };

  # Wezterm configuration with Catppuccin
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      return {
        color_scheme = 'Catppuccin Mocha',
        font = wezterm.font('JetBrainsMono Nerd Font'),
        font_size = 12.0,
        hide_tab_bar_if_only_one_tab = true,
        window_background_opacity = 0.9,
        enable_wayland = true,
        window_close_confirmation = 'NeverPrompt',
        default_prog = { 'zsh' },
      }
    '';
  };

  # DankMaterialShell (DMS) dynamic theming
  programs.dank-material-shell = {
    enableDynamicTheming = true;
    # DMS uses matugen to generate colors from wallpaper,
    # but we can hint it towards catppuccin colors if needed.
  };

  # Force cursor and icons via dconf for Wayland/Niri
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      cursor-theme = "Bibata-Modern-Classic";
      cursor-size = 24;
      icon-theme = "kora";
      gtk-theme = "catppuccin-mocha-lavender-standard";
      color-scheme = "prefer-dark";
    };
  };
}
