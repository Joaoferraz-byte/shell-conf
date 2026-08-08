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


    # settings e session são declarados pelo consumidor (nix-conf/home/livara/home.nix).
    # Não usar mkForce aqui para permitir que o Home Manager declare
    # wallpaperCycling, wallpaperPath e outras preferências de sessão.
  };

}
