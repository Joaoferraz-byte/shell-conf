{
  description = "Shell configuration layer combining DankMaterialShell and Niri";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # DankMaterialShell (DMS)
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Niri compositor
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DMS System monitoring widget dependency
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dms, niri, dgop, ... }@inputs: {
    # Re-exporting DMS NixOS module
    nixosModules.dankMaterialShell = dms.nixosModules.dank-material-shell;
    
    # Our custom Home Manager module that wraps DMS and Niri
    homeManagerModules.default = import ./modules/default.nix { inherit inputs; };
    
    # Expose for legacy compatibility if needed
    homeManagerModules.dankMaterialShell = self.homeManagerModules.default;
  };
}
