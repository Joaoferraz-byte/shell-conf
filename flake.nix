{
  description = "Livara shell integration and application support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    noctalia-conf = {
      url = "github:Joaoferraz-byte/noctalia-conf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, flake-parts, ... }:
    let
      noctaliaRuntime = inputs.noctalia-conf;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { pkgs, ... }: {
        packages.default = pkgs.runCommand "livara-shell-support" { } ''
          mkdir -p "$out/share/livara"
          cp -R --no-preserve=mode "${./src/livara}/." "$out/share/livara/"
        '';

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ bash jq shellcheck ];
        };

        checks = {
          support-scripts = pkgs.runCommand "livara-support-script-check" { } ''
            bash -n ${self}/src/livara/scripts/daily_note.sh
            bash -n ${self}/src/livara/scripts/open-nixos-nvim.sh
            bash -n ${self}/src/livara/scripts/open-zen.sh
            bash -n ${self}/src/livara/scripts/reload-zen.sh
            bash -n ${self}/src/livara/scripts/screen-recording-toggle.sh
            bash -n ${self}/src/livara/scripts/sync-livara-themes.sh
            bash -n ${self}/src/livara/scripts/xournal_new_note.sh
            bash -n ${self}/tests/test-theme-contracts.sh
            if grep -Eq 'config\.dpi|LIVARA_WEZTERM_DPI|weztermDpi' ${self}/modules/support.nix; then
              exit 1
            fi
            touch "$out"
          '';
        };
      };

      flake.homeModules = rec {
        support = { config, lib, pkgs, desktopProfile ? { }, ... }:
          import ./modules/support.nix {
            inherit config lib pkgs desktopProfile;
            noctaliaRuntime = noctaliaRuntime;
          };
        default = support;
      };
    };
}
