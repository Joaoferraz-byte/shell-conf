{ inputs }:
{ config, pkgs, lib, ... }:

{
  imports = [
    # DMS home module (provides programs.dank-material-shell options)
    inputs.dms.homeModules.dank-material-shell

    # niri-flake Home Manager module (provides programs.niri settings options)
    inputs.niri.homeModules.niri
    # Niri settings: keybinds (incl. DMS wallpaper IPC), environment, layout
    ./niri.nix


    ./dms.nix
    ./theme.nix
    ./storage.nix
    ./wezterm.nix
    ./zen.nix
  ];
}
