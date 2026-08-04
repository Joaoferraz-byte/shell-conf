{ config, pkgs, lib, ... }:

{
  # Theme settings
  # DMS handles dynamic theming (colors) via matugen,
  # but we can set the icon theme here safely.
  
  gtk = {
    enable = true;
    iconTheme = {
      name = "kora";
      package = pkgs.kora-icon-theme;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      icon-theme = "kora";
    };
  };
}
