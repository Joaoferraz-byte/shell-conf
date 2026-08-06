{ config, pkgs, lib, ... }:

{
  # ─── Zen Browser + DMS Theme Integration ──────────────────────────────────
  # DMS matugen generates ~/.config/DankMaterialShell/zen.css automatically.
  # This module symlinks it to Zen Browser's chrome directory as userChrome.css
  # and enables userChrome.css support via a custom prefs.js override.
  #
  # Supports: native install (~/.zen), Flatpak (~/.var/app/app.zen_browser.zen/.zen)

  # Write a custom prefs.js fragment that enables userChrome.css support
  xdg.configFile."zen/default/user.js".text = ''
    // DMS theme: enable userChrome.css for dynamic theming
    user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
  '';

  # Symlink DMS-generated zen.css to Zen Browser chrome directory
  # We use home.file to create the symlink declaratively.
  # The symlink name must be userChrome.css (not zen.css) per Firefox/Zen convention.
  home.file."zen/default/chrome/userChrome.css".source =
    lib.mkIf (lib.pathExists "${config.home.homeDirectory}/.config/DankMaterialShell/zen.css")
      "${config.home.homeDirectory}/.config/DankMaterialShell/zen.css";

  # Activation script: handles the case where zen.css may not exist yet
  # (DMS needs to run at least once to generate it). Also covers Flatpak path.
  home.activation.linkZenBrowserTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Find Zen Browser profile directories and symlink zen.css
    DMS_CSS="$HOME/.config/DankMaterialShell/zen.css"

    for PROFILE_DIR in \
      "$(find "$HOME/.zen" -maxdepth 1 -type d -name "*.Default Profile" 2>/dev/null | head -n 1)" \
      "$(find "$HOME/.config/zen" -maxdepth 1 -type d -name "*Default (release)" 2>/dev/null | head -n 1)" \
      "$(find "$HOME/.var/app/app.zen_browser.zen/.zen" -maxdepth 1 -type d -name "*Default (release)" 2>/dev/null | head -n 1)"; do

      if [ -n "$PROFILE_DIR" ] && [ -f "$DMS_CSS" ]; then
        mkdir -p "$PROFILE_DIR/chrome"
        $DRY_RUN_CMD ln -sf "$DMS_CSS" "$PROFILE_DIR/chrome/userChrome.css"
      fi
    done
  '';

  # Systemd service to re-link zen.css when DMS theme changes
  systemd.user.services.zen-browser-theme-sync = {
    Unit = {
      Description = "Sync DMS zen.css theme to Zen Browser chrome directory";
    };

    Service = {
      ExecStart = "${pkgs.writeShellScript "zen-browser-theme-sync" ''
        #!/bin/bash
        set -euo pipefail

        DMS_CSS="$HOME/.config/DankMaterialShell/zen.css"

        for PROFILE_DIR in \
          "$(find "$HOME/.zen" -maxdepth 1 -type d -name "*.Default Profile" 2>/dev/null | head -n 1)" \
          "$(find "$HOME/.config/zen" -maxdepth 1 -type d -name "*Default (release)" 2>/dev/null | head -n 1)" \
          "$(find "$HOME/.var/app/app.zen_browser.zen/.zen" -maxdepth 1 -type d -name "*Default (release)" 2>/dev/null | head -n 1)"; do

          [ -z "$PROFILE_DIR" ] && continue

          if [ -f "$DMS_CSS" ]; then
            mkdir -p "$PROFILE_DIR/chrome"
            ln -sf "$DMS_CSS" "$PROFILE_DIR/chrome/userChrome.css"
          fi
        done

        sleep 60
      ''}";

      Restart = "always";
      RestartSec = 10;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
