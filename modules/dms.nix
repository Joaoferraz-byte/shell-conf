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

    settings = {
      showWelcome = false;
      showKeybinds = false;
    };

    # enableKeybinds provides: Mod+Space (launcher), Mod+N (notifications),
    # Mod+Comma (settings), Mod+P (notepad), Super+Alt+L (lock), Mod+X (power),
    # volume/brightness media keys, Mod+V (clipboard), Mod+M (process list).
    # includes.enable is mutually exclusive with enableKeybinds — we use enableKeybinds
    # so DMS manages its own binds declaratively and niri.nix adds the complementary ones.
    niri = {
      enableKeybinds = true;
      # enableSpawn is set to false to avoid double bars (systemd service is already enabled)
      enableSpawn = false;

      includes = {
        enable = false;
      };
    };
  };
}
