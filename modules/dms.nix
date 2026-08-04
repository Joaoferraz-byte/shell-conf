{ config, pkgs, lib, ... }:

{
  programs.dank-material-shell = {
    enable = true;
    
    # Systemd integration for auto-start
    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    # Core features
    enableSystemMonitoring = true;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    
    # Integration with niri
    niri = {
      enableKeybinds = true; # Enables default DMS keybinds (Mod+Space, etc)
      enableSpawn = false;   # We'll handle spawn in our niri config
      includes = {
        enable = true;
        override = true;
      };
    };
  };
}
