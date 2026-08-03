{
  description = "Caelestia Shell thin configuration wrapper for NixOS + Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      caelestia-shell,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system: {
        default = caelestia-shell.packages.${system}.default;
      });

      homeManagerModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [ caelestia-shell.homeManagerModules.default ];

          programs.caelestia = {
            enable = true;
            cli.enable = true;

            systemd = {
              enable = true;
              target = "graphical-session.target";
            };

            settings = {
              general.apps = {
                terminal = [ "kitty" ];
                audio = [ "pavucontrol" ];
              };
              bar.status.showBattery = true;
              paths.wallpaperDir = "~/Pictures/Wallpapers";
              appearance.transparency.enabled = false;
            };

            cli.settings = {
              theme.enableGtk = false;
            };
          };
        };

      nixosModules.default = caelestia-shell.nixosModules.default or { };
    };
}
