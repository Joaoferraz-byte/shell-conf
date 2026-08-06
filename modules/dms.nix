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

    # settings e session são declarados pelo consumidor (nix-conf/home/livara/home.nix).
    # Não usar mkForce aqui para permitir que o Home Manager declare
    # wallpaperCycling, wallpaperPath e outras preferências de sessão.
  };

  # Screenshot directory
  home.activation.setupScreenshots = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/Pictures/Screenshots"
  '';
}
