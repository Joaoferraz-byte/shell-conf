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
    # Thin wrapper that imports DMS's own HM module. No reimplementation.
    homeManagerModules.default = { config, pkgs, lib, ... }: {
      imports = [ dms.homeModules.dank-material-shell ];

      programs.dank-material-shell = {
        enable = true;
        # DMS ships its own package builder; we pass it through unchanged.
        systemd.enable = true;
        # Dynamic theming via matugen (wallpaper-driven color extraction)
        enableDynamicTheming = true;
        # System monitoring widget (dgop process list)
        enableSystemMonitoring = true;
        # Audio visualiser on player widgets
        enableAudioWavelength = true;
        # Calendar events via khal
        enableCalendarEvents = true;
      };
    };

    # ── NixOS module ───────────────────────────────────────────────────
    # Thin wrapper that imports DMS's own NixOS module. Enables system-level
    # prerequisites (polkit, accounts-daemon, geoclue2, power-profiles-daemon)
    # that DMS already sets via mkDefault.
    nixosModules.default = { config, pkgs, lib, ... }: {
      imports = [ dms.nixosModules.dank-material-shell ];

      programs.dank-material-shell = {
        enable = true;
        systemd.target = "graphical-session.target";
      };
    };

    # ── Re-export DMS packages for convenience ─────────────────────────
    # Mirrors DMS's own package set; useful if nix-conf wants to reference
    # the dms-shell package directly without importing the DMS flake input.
    packages = dms.packages;
  };
}
