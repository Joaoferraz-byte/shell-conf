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

    # Impedimos que o módulo DMS crie arquivos imutáveis no nix-store
    settings = lib.mkForce {};
    session = lib.mkForce {};
  };

  # Em vez de um symlink estático que pode quebrar se o repositório mudar de lugar,
  # usamos um script de ativação que detecta onde o repositório está clonado
  # (assumindo que o usuário roda o rebuild de dentro dele ou de um local conhecido).
  # No entanto, para ser robusto, vamos procurar o repositório shell-conf no sistema.
  home.activation.linkDmsSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Procuramos pelo repositório shell-conf em locais comuns
    # 1. ~/.config/nixos/shell-conf (padrão sugerido)
    # 2. ~/Projects/shell-conf (local de desenvolvimento)
    # 3. No diretório atual se houver um .git do shell-conf
    
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
      mkdir -p "$HOME/.config/DankMaterialShell"
      mkdir -p "$HOME/.local/state/DankMaterialShell"
      
      # Link settings.json
      ln -sf "$REPO_PATH/settings/dms-settings.json" "$HOME/.config/DankMaterialShell/settings.json"
      # Link session.json
      ln -sf "$REPO_PATH/settings/dms-session.json" "$HOME/.local/state/DankMaterialShell/session.json"
      
      echo "DMS settings linked to $REPO_PATH/settings"
    else
      echo "Warning: shell-conf repository not found. DMS settings persistence might not work."
    fi
  '';
}
