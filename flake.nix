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
    # Re-export DMS NixOS module (enables quickshell, polkit, etc at system level)
    nixosModules.dankMaterialShell = dms.nixosModules.dank-material-shell;
    nixosModules.default = self.nixosModules.dankMaterialShell;

    # Home Manager module: DMS + Niri + theme
    homeManagerModules.default = import ./modules/default.nix { inherit inputs; };
    homeManagerModules.dankMaterialShell = self.homeManagerModules.default;
  };
}
