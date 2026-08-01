{
  description = "Ambxst-X local fork for NixOS, Home Manager, and Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # axctl remains a runtime dependency while the Ambxst QML services use its
    # daemon and IPC API. Its scope is reviewed in docs/axctl-decision.md.
    axctl = {
      url = "github:Axenide/axctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, axctl, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      version = nixpkgs.lib.removeSuffix "\n" (builtins.readFile ./version);

      mkPkgs = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # `self = ./.` is intentional: the Ambxst launcher and source derivation
      # always resolve to this repository's tracked source tree, never to an
      # upstream flake input or a generated patch directory.
      mkAmbxst = system:
        let
          pkgs = mkPkgs system;
        in
        import ./nix/packages {
          inherit pkgs system axctl version;
          lib = pkgs.lib;
          self = ./.;
        };

      mkAmbxstDev = system:
        let
          pkgs = mkPkgs system;
          ambxst = mkAmbxst system;
        in
        pkgs.writeShellApplication {
          name = "ambxst-dev";
          runtimeInputs = with pkgs; [ bash coreutils ];
          text = ''
            : "''${AMBXST_SOURCE_ROOT:?Set AMBXST_SOURCE_ROOT to the shell-conf checkout.}"

            source_root="$(realpath "$AMBXST_SOURCE_ROOT")"
            test -f "$source_root/shell.qml" || {
              echo "ambxst-dev: shell.qml not found in $source_root" >&2
              exit 2
            }

            # The normal launcher provides Quickshell, axctl, QML imports,
            # font configuration and XDG paths. The CLI then redirects only
            # source lookups to AMBXST_SOURCE_ROOT, enabling QS live reload.
            export AMBXST_SOURCE_ROOT="$source_root"
            exec ${ambxst}/bin/ambxst
          '';
        };
    in
    {
      packages = forAllSystems (system:
        let
          ambxst = mkAmbxst system;
        in
        {
          default = ambxst;
          ambxst = ambxst;
          Ambxst = ambxst;
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.ambxst}/bin/ambxst";
        };
      });

      nixosModules.default = { pkgs, lib, ... }: {
        imports = [ ./nix/modules ];

        programs.ambxst = {
          enable = lib.mkDefault true;
          package = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.ambxst;
        };
      };

      homeManagerModules.default = { pkgs, lib, ... }:
        let
          system = pkgs.stdenv.hostPlatform.system;
          settingsNames = [
            "theme"
            "bar"
            "compositor"
            "desktop"
            "dock"
            "overview"
            "performance"
            "lockscreen"
            "workspaces"
            "notch"
            "system"
            "weather"
            "prefix"
          ];
        in
        {
          home.packages = [ self.packages.${system}.ambxst ];

          # Ambxst settings are mutable by design. Seed once, then let Ambxst
          # modify its state without linking mutable JSON into the Nix store.
          home.activation.prepareAmbxstRuntimeState = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
            runtime_root="''${XDG_STATE_HOME:-$HOME/.local/state}/ambxst"
            config_dir="$runtime_root/config"
            legacy_root="$HOME/.config/ambxst"
            seed="${./settings}"

            mkdir -p "$config_dir" "$runtime_root/presets"

            for setting in ${lib.concatStringsSep " " settingsNames}; do
              target="$config_dir/$setting.json"
              legacy="$legacy_root/config/$setting.json"

              if [ ! -e "$target" ]; then
                if [ -e "$legacy" ] && [ ! -L "$legacy" ]; then
                  cp --preserve=mode "$legacy" "$target"
                else
                  cp --preserve=mode "$seed/$setting.json" "$target"
                fi
              fi

              if [ -L "$legacy" ]; then
                resolved="$(readlink -f "$legacy" || true)"
                if [[ "$resolved" == /nix/store/* ]]; then
                  rm -f "$legacy"
                fi
              fi
            done

            legacy_binds="$legacy_root/binds.json"
            if [ ! -e "$runtime_root/binds.json" ] && [ -e "$legacy_binds" ] && [ ! -L "$legacy_binds" ]; then
              cp --preserve=mode "$legacy_binds" "$runtime_root/binds.json"
            fi
            if [ -L "$legacy_binds" ]; then
              resolved="$(readlink -f "$legacy_binds" || true)"
              if [[ "$resolved" == /nix/store/* ]]; then
                rm -f "$legacy_binds"
              fi
            fi

            legacy_presets="$legacy_root/presets"
            if [ -d "$legacy_presets" ] && [ ! -L "$legacy_presets" ] \
              && [ -z "$(find "$runtime_root/presets" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
              cp -a "$legacy_presets"/. "$runtime_root/presets"/
            fi
            if [ -L "$legacy_presets" ]; then
              resolved="$(readlink -f "$legacy_presets" || true)"
              if [[ "$resolved" == /nix/store/* ]]; then
                rm -f "$legacy_presets"
              fi
            fi
          '';
        };

      devShells = forAllSystems (system:
        let
          pkgs = mkPkgs system;
          ambxst = mkAmbxst system;
          ambxstDev = mkAmbxstDev system;
        in
        {
          default = pkgs.mkShell {
            packages = [ ambxst ambxstDev ];
            shellHook = ''
              export AMBXST_SOURCE_ROOT="''${AMBXST_SOURCE_ROOT:-$PWD}"
              echo "Ambxst local development environment loaded. Run: ambxst-dev"
            '';
          };
        });

      checks = forAllSystems (system:
        let
          pkgs = mkPkgs system;
        in
        {
          source-layout = pkgs.stdenvNoCC.mkDerivation {
            name = "ambxst-local-source-layout";
            src = self;
            dontUnpack = true;
            buildPhase = ''
              test -f "$src/flake.nix"
              test -f "$src/shell.qml"
              test -f "$src/nix/packages/default.nix"
              test -f "$src/config/Config.qml"
              test ! -e "$src/vendor"
              grep -q 'AMBXST_CONFIG_ROOT' "$src/config/Config.qml"
              if grep -q 'exec-once = "ambxst"' "$src/modules/services/CompositorTomlWriter.qml"; then
                echo "Ambxst must not generate a second shell autostart" >&2
                exit 1
              fi
            '';
            installPhase = ''
              touch "$out"
            '';
          };
        });
    };
}
