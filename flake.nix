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
  };

  outputs = { self, nixpkgs, dms, niri, ... }@inputs: {
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
  };
}
