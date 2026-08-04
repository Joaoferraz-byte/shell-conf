{ inputs }:
{ config, pkgs, lib, ... }:

{
  imports = [
    # niri-flake must come first: provides config.lib.niri.actions used by DMS niri module
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
