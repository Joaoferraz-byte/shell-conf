{
  description = "Livara application adapters and shell-independent user support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { pkgs, ... }: {
        packages.default = pkgs.runCommand "livara-visual-api" { } ''
          mkdir -p "$out/share/livara"
          cp -R --no-preserve=mode "${./src/livara}/." "$out/share/livara/"
        '';

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ bash jq shellcheck ];
        };
      };

      flake = {
        homeModules = {
          default = import ./modules/support.nix;
          support = import ./modules/support.nix;
        };
      };
    };
}
