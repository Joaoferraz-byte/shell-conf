{
  description = "DankMaterialShell integration for NixOS + Home Manager";

  inputs = {
    # DankMaterialShell upstream — the shell we re-export
    dms.url = "github:AvengeMedia/DankMaterialShell";
    # nixpkgs follows the parent flake to avoid duplicate Qt/Quickshell builds
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, dms, nixpkgs, ... }: {
    # ── Home Manager module ────────────────────────────────────────────
    # Thin wrapper that imports DMS's own HM module + user preferences layer.
    homeManagerModules.default = { config, pkgs, lib, ... }: {
      imports = [
        dms.homeModules.dank-material-shell
        ./modules/default.nix
      ];

      programs.dank-material-shell = {
        enable = true;
        systemd.enable = true;
        enableDynamicTheming = true;
        enableSystemMonitoring = true;
        enableAudioWavelength = true;
        enableCalendarEvents = true;
      };
    };

    # ── NixOS module ───────────────────────────────────────────────────
    # Thin wrapper that imports DMS's own NixOS module.
    nixosModules.default = { config, pkgs, lib, ... }: {
      imports = [ dms.nixosModules.dank-material-shell ];

      programs.dank-material-shell = {
        enable = true;
        systemd.target = "graphical-session.target";
      };
    };

    # ── Re-export DMS packages for convenience ─────────────────────────
    packages = dms.packages;
  };
}
