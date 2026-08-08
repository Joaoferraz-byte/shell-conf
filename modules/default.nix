{ inputs }:
{ config, pkgs, lib, ... }:

{
  imports = [
    # DMS home module (provides programs.dank-material-shell options)
    inputs.dms.homeModules.dank-material-shell


    ./dms.nix
    ./theme.nix
    ./storage.nix
    ./wezterm.nix
    ./zen.nix
  ];
}
