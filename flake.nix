{
  description = "DankMaterialShell thin configuration wrapper for NixOS + Niri";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dms, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # Expose upstream packages directly
      packages = forAllSystems (system: {
        default = dms.packages.${system}.dms-shell;
        dms-shell = dms.packages.${system}.dms-shell;
      });

      # Thin Home Manager module that delegates to upstream but fixes Niri integration
      homeManagerModules.default = { config, lib, pkgs, ... }: {
        imports = [ dms.homeModules.dank-material-shell ];

        programs.dank-material-shell = {
          enable = true;
          
          # Use systemd for session management (best practice for NixOS + UWSM/Niri)
          systemd = {
            enable = true;
            target = "graphical-session.target";
          };

          # User preferences
          settings = {
            theme = {
              mode = "dark";
              matugenEnabled = true;
            };
            bar.position = "top";
          };
        };

        # Ensure matugen is available for dynamic theming
        home.packages = [ pkgs.matugen ];
      };

      # Expose upstream NixOS module directly
      nixosModules.default = dms.nixosModules.dank-material-shell;
    };
}
