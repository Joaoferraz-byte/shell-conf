{ config, pkgs, lib, ... }:

{
  # ─── GTK Theme ────────────────────────────────────────────────────────────
  # Let DMS/matugen control the GTK theme dynamically.
  # Only enforce icon and cursor themes declaratively.
  gtk = {
    enable = true;
    iconTheme = {
      name = "kora";
      package = pkgs.kora-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
  };

  # Force cursor and icons via dconf for Wayland/Niri.
  # GTK theme is managed by DMS matugen dynamically.
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      cursor-theme = "Bibata-Modern-Classic";
      cursor-size = 24;
      icon-theme = "kora";
      color-scheme = "prefer-dark";
    };
  };
}
