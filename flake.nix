{
  description = "Livara application adapters for the Ambxst desktop shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { pkgs, ... }: {
        packages.default = pkgs.runCommand "livara-shell-support" { } ''
          mkdir -p "$out/share/livara"
          cp -R --preserve=mode "${./src/livara}/." "$out/share/livara/"
        '';

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ bash jq shellcheck ];
        };

        checks.support-scripts = pkgs.runCommand "livara-support-script-check" {
          nativeBuildInputs = with pkgs; [ bash coreutils findutils gawk gnugrep gnused jq procps util-linux ];
        } ''
          bash -n ${self}/src/livara/scripts/daily_note.sh
          bash -n ${self}/src/livara/scripts/open-nixos-nvim.sh
          bash -n ${self}/src/livara/scripts/open-zen.sh
          bash -n ${self}/src/livara/scripts/reload-zen.sh
          bash -n ${self}/src/livara/scripts/sync-livara-themes.sh
          bash -n ${self}/src/livara/scripts/sync-ambxst-palette.sh
          bash -n ${self}/tests/test-theme-contracts.sh
          bash -n ${self}/tests/test-ambxst-palette-bridge.sh
          bash ${self}/tests/test-theme-contracts.sh
          bash ${self}/tests/test-ambxst-palette-bridge.sh
          grep -Fq 'config reload' ${self}/modules/support.nix
          ! grep -Fq 'json_color overPrimary' ${self}/src/livara/scripts/sync-livara-themes.sh
          ! grep -Fq 'window, .background' ${self}/src/livara/scripts/sync-livara-themes.sh
          if grep -Eq 'config\.dpi|LIVARA_WEZTERM_DPI|weztermDpi' ${self}/modules/support.nix; then
            exit 1
          fi
          touch "$out"
        '';
      };

      flake.homeModules.default = {
        config,
        lib,
        pkgs,
        desktopProfile ? { },
        shellName ? "Livara",
        ambxstPackage ? null,
        ...
      }:
        import ./modules/support.nix {
          inherit config lib pkgs desktopProfile shellName ambxstPackage;
        };
    };
}
