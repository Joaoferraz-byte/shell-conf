{ config, pkgs, lib, ... }:

{
  programs.dank-material-shell = {
    enable = true;

    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    enableSystemMonitoring = true;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    enableClipboardPaste = true;

    niri = {
      enableKeybinds = true;
      enableSpawn = false;
      includes.enable = false;
    };

    settings = lib.mkForce {};
    session = lib.mkForce {};
  };

  # Na primeira ativação, copia os arquivos mutáveis do repo para os paths reais do DMS.
  # Depois disso, um serviço systemd (dms-settings-sync) usa inotifywait para detectar
  # mudanças nos arquivos reais e copia de volta para o repositório shell-conf.
  home.activation.linkDmsSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/DankMaterialShell"
    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.local/state/DankMaterialShell"

    SEARCH_PATHS=(
      "$HOME/.config/nixos/shell-conf"
      "$HOME/Projects/shell-conf"
      "$(pwd)"
    )

    REPO_PATH=""
    for path in "''${SEARCH_PATHS[@]}"; do
      if [ -d "$path/settings" ] && [ -f "$path/flake.nix" ]; then
        REPO_PATH="$path"
        break
      fi
    done

    if [ -n "$REPO_PATH" ]; then
      ${pkgs.coreutils}/bin/cp -f "$REPO_PATH/settings/dms-settings.json" "$HOME/.config/DankMaterialShell/settings.json"
      ${pkgs.coreutils}/bin/cp -f "$REPO_PATH/settings/dms-session.json" "$HOME/.local/state/DankMaterialShell/session.json"
    fi
  '';

  # Serviço systemd que watch os arquivos do DMS e copia de volta para o repo
  systemd.user.services.dms-settings-sync = {
    Unit = {
      Description = "Sync DMS settings back to shell-conf repository";
    };

    Service = {
      ExecStart = "${pkgs.writeShellScript "dms-settings-sync" ''
        #!/bin/bash
        set -euo pipefail

        SETTINGS_FILE="$HOME/.config/DankMaterialShell/settings.json"
        SESSION_FILE="$HOME/.local/state/DankMaterialShell/session.json"

        find_repo() {
          for path in \
            "$HOME/.config/nixos/shell-conf" \
            "$HOME/Projects/shell-conf" \
            "$(pwd)"; do
            if [ -d "$path/settings" ] && [ -f "$path/flake.nix" ]; then
              echo "$path"
              return 0
            fi
          done
          return 1
        }

        while true; do
          REPO_PATH=$(find_repo) || {
            sleep 30
            continue
          }

          ${pkgs.inotify-tools}/bin/inotifywait -e close_write -e moved_to \
            --format '%w%f' "$HOME/.config/DankMaterialShell" \
            "$HOME/.local/state/DankMaterialShell" 2>/dev/null | \
          while read -r changed_file; do
            case "$changed_file" in
              */DankMaterialShell/settings.json)
                ${pkgs.coreutils}/bin/cp -f "$SETTINGS_FILE" "$REPO_PATH/settings/dms-settings.json"
                ;;
              */DankMaterialShell/session.json)
                ${pkgs.coreutils}/bin/cp -f "$SESSION_FILE" "$REPO_PATH/settings/dms-session.json"
                ;;
            esac
          done

          sleep 5
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
