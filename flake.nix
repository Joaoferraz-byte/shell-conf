{
  description = "Shell configuration layer combining DankMaterialShell and Niri";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.caelestia-cli.follows = "";
    };

    m3shapes-src = {
      url = "github:soramanew/m3shapes";
      flake = false;
    };


  };

  outputs = { self, nixpkgs, dms, niri, caelestia-cli, caelestia-shell, m3shapes-src, ... }@inputs: let
    caelestia-shell-package = { system, withCli }:
      nixpkgs.legacyPackages.${system}.callPackage ./nix/default.nix {
        rev = inputs.self.rev or "unknown";
        caelestia-cli = caelestia-cli.packages.${system}.caelestia-cli;
        m3shapes = m3shapes-src;
        inherit withCli;
      };
  in {
    # NixOS module: DMS system components (power-profiles-daemon, accounts-daemon,
    # geoclue2, polkit) + Niri compositor
    nixosModules.dankMaterialShell = { ... }: {
      imports = [
        dms.nixosModules.dank-material-shell
        niri.nixosModules.niri
        ./modules/niri.nix
      ];
    };
    nixosModules.default = self.nixosModules.dankMaterialShell;

    # NixOS module: dank-greeter (greetd-based, replaces SDDM)
    # Opt-in: import this module only if you want to replace SDDM with dank-greeter.
    nixosModules.dankGreeter = { ... }: {
      imports = [
        dms.nixosModules.greeter
      ];
    };

    # Home Manager module: DMS + Niri + theme
    homeManagerModules.default = import ./modules/default.nix { inherit inputs; };
    homeManagerModules.dankMaterialShell = self.homeManagerModules.default;
    homeManagerModules.caelestia = import ./nix/hm-module.nix self;

    # Caelestia Shell packages
    packages.x86_64-linux = {
      default = caelestia-shell-package { system = "x86_64-linux"; withCli = false; };
      with-cli = caelestia-shell-package { system = "x86_64-linux"; withCli = true; };
    };
    packages.aarch64-linux = {
      default = caelestia-shell-package { system = "aarch64-linux"; withCli = false; };
      with-cli = caelestia-shell-package { system = "aarch64-linux"; withCli = true; };
    };
  };
}
