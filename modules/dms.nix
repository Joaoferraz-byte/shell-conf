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

    # Set settings and session to empty to prevent the DMS module from creating
    # read-only files in the nix-store that would overwrite our mutable symlinks.
    settings = lib.mkForce {};
    session = lib.mkForce {};
  };

  # DMS settings.json and session.json are managed as out-of-store symlinks pointing
  # to the versioned files in the shell-conf repository clone at
  # ~/.config/nixos/shell-conf/settings/. This allows the DMS UI to write changes
  # directly to those files, which can then be committed and pushed to the repository.
  # On rebuild the symlinks are recreated pointing to the same mutable files.
  xdg.configFile."DankMaterialShell/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nixos/shell-conf/settings/dms-settings.json";

  home.file.".local/state/DankMaterialShell/session.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nixos/shell-conf/settings/dms-session.json";
}
