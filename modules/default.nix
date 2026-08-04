{ inputs }:
{ config, pkgs, lib, ... }:

{
  imports = [
    # niri-flake home-manager module
    inputs.niri.homeModules.niri

    # DMS home module (provides programs.dank-material-shell options)
    inputs.dms.homeModules.dank-material-shell

    # DMS niri integration module (provides programs.dank-material-shell.niri options)
    inputs.dms.homeModules.niri

    ./dms.nix
    ./niri.nix
    ./theme.nix
  ];
}
