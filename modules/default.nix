# User-specific DankMaterialShell preferences.
# This module layers on top of DMS's own HM module, expressing only the
# choices that are unique to this user (theme, keybinds, compositor startup).
# Everything DMS already provides (default settings, polkit, portals, etc.)
# is inherited from the upstream module — do not duplicate it here.
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.dank-material-shell;
  jsonFormat = pkgs.formats.json { };
in
{
  options.programs.dank-material-shell = {
    # User-tunable DMS settings (written to ~/.config/DankMaterialShell/settings.json).
    # DMS ships sensible defaults; this attrset only overrides what the user cares about.
    userSettings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      description = "User preferences for DankMaterialShell, merged into the settings JSON.";
      example = {
        appearance = {
          colorScheme = "dark";
          accentColor = "#1e88e5";
          roundness = 16;
        };
        bar = {
          position = "top";
          height = 40;
        };
        font = {
          family = "JetBrainsMono Nerd Font";
          size = 12;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Merge user settings into the DMS settings JSON.
    programs.dank-material-shell.settings = lib.mkMerge [
      {
        # Defaults the user wants overridden from DMS's built-in defaults.
        # Theme: dark, matching the previous Ambxst preference.
        appearance = {
          colorScheme = "dark";
        };
      }
      cfg.userSettings
    ];
  };
}
