{ config, pkgs, lib, ... }:

{
  # ─── Zen Browser + DMS Theme Integration ──────────────────────────────────
  # Matugen generates zen.css from the DMS palette.
  # This module symlinks the generated theme to Zen Browser's chrome directory
  # and enables userChrome.css support.

  home.activation.setupZenBrowserTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Create Zen Browser chrome directory
    mkdir -p "$HOME/.zen/default/chrome"
    mkdir -p "$HOME/.zen/default/user"

    # Symlink DMS matugen-generated zen.css to Zen Browser chrome
    DMS_CSS="$HOME/.config/DankMaterialShell/zen.css"
    ZEN_CSS="$HOME/.zen/default/chrome/zen.css"

    if [ -f "$DMS_CSS" ]; then
      $DRY_RUN_CMD ln -sf "$DMS_CSS" "$ZEN_CSS"
    fi

    # Enable userChrome.css in Zen Browser preferences
    ZEN_PREFS="$HOME/.zen/default/prefs.js"
    if [ -f "$ZEN_PREFS" ]; then
      $DRY_RUN_CMD grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$ZEN_PREFS" 2>/dev/null \
        || $DRY_RUN_CMD echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$ZEN_PREFS"
    fi
  '';

  # Systemd timer to re-link zen.css when DMS theme changes
  systemd.user.services.zen-browser-theme-sync = {
    Unit = {
      Description = "Sync DMS zen.css theme to Zen Browser chrome directory";
    };

    Service = {
      ExecStart = "${pkgs.writeShellScript "zen-browser-theme-sync" ''
        #!/bin/bash
        set -euo pipefail

        DMS_CSS="$HOME/.config/DankMaterialShell/zen.css"
        ZEN_CSS="$HOME/.zen/default/chrome/zen.css"
        ZEN_PREFS="$HOME/.zen/default/prefs.js"

        while true; do
          if [ -f "$DMS_CSS" ]; then
            ln -sf "$DMS_CSS" "$ZEN_CSS"
          fi

          # Enable userChrome.css if not already set
          if [ -f "$ZEN_PREFS" ]; then
            grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$ZEN_PREFS" 2>/dev/null \
              || echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$ZEN_PREFS"
          fi

          sleep 60
        done
      ''}";

      Restart = "always";
      RestartSec = 10;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
