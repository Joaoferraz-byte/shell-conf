{ config, pkgs, lib, ... }:

{
  programs.niri = {
    settings = {
      prefer-no-csd = true;

      hotkey-overlay.skip-at-startup = true;

      environment = {
        XDG_CURRENT_DESKTOP = "niri";
        QT_QPA_PLATFORM = "wayland";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        QT_QPA_PLATFORMTHEME = "gtk3";
      };

      # cliphist is used for clipboard history (DMS clipboard widget reads from it)
      spawn-at-startup = [
        { command = [ "bash" "-c" "wl-paste --watch cliphist store" ]; }
      ];

      layout = {
        gaps = 5;
        border.enable = false;
        focus-ring.enable = false;
      };

      window-rules = [
        {
          matches = [{ is-active = false; }];
          opacity = 0.9;
        }
        {
          geometry-corner-radius = {
            top-left = 12.0;
            top-right = 12.0;
            bottom-left = 12.0;
            bottom-right = 12.0;
          };
          clip-to-geometry = true;
        }
      ];

      binds = {
        # Workspace navigation (DMS does not provide these)
        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;

        "Mod+Shift+1".action.move-column-to-workspace = 1;
        "Mod+Shift+2".action.move-column-to-workspace = 2;
        "Mod+Shift+3".action.move-column-to-workspace = 3;
        "Mod+Shift+4".action.move-column-to-workspace = 4;
        "Mod+Shift+5".action.move-column-to-workspace = 5;
        "Mod+Shift+6".action.move-column-to-workspace = 6;
        "Mod+Shift+7".action.move-column-to-workspace = 7;
        "Mod+Shift+8".action.move-column-to-workspace = 8;
        "Mod+Shift+9".action.move-column-to-workspace = 9;

        # Application shortcuts (complementary to DMS defaults)
        "Mod+W".action.spawn = "helium";
        "Mod+E".action.spawn = "nautilus";
        "Mod+O".action.spawn = "zennotes";
        "Mod+T".action.spawn = "wezterm";
        "Mod+Return".action.spawn = "wezterm";
        "Mod+C".action.close-window = {};

        # Window focus
        "Mod+Left".action.focus-column-left = {};
        "Mod+Right".action.focus-column-right = {};
        "Mod+Up".action.focus-window-up = {};
        "Mod+Down".action.focus-window-down = {};

        # Mouse scroll on window selection (with cooldown to avoid over-scrolling)
        "Mod+WheelScrollDown" = {
          action.focus-column-right = {};
          cooldown-ms = 150;
        };
        "Mod+WheelScrollUp" = {
          action.focus-column-left = {};
          cooldown-ms = 150;
        };

        # Window sizing
        # Super+F: maximize column to cover the full workspace width (not fullscreen)
        "Mod+F" = {
          action.maximize-column = {};
          hotkey-overlay.title = "Maximize Column";
        };
        # Super+Shift+F: fullscreen the focused window
        "Mod+Shift+F" = {
          action.fullscreen-window = {};
          hotkey-overlay.title = "Fullscreen Window";
        };

        # Alt+Tab triggers DMS window switcher (alttab overlay)
        "Alt+Tab".action.spawn = [ "dms" "ipc" "call" "alttab" "toggle" ];
      };
    };
  };
}
