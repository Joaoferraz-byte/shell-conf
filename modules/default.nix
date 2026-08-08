{ inputs }:
{ config, pkgs, lib, ... }:

{
  imports = [
    # DMS home module (provides programs.dank-material-shell options)
    inputs.dms.homeModules.dank-material-shell

    # DMS niri integration module (provides programs.dank-material-shell.niri options)
    # This module internally imports niri-flake home-manager module.
    inputs.dms.homeModules.niri

    ./dms.nix
    ./theme.nix
    ./storage.nix
    ./wezterm.nix
    ./zen.nix
  ];
}
