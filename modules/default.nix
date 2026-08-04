{ inputs }:
{ config, pkgs, lib, ... }:

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.niri.homeModules.niri
    ./dms.nix
    ./niri.nix
    ./theme.nix
  ];
}
