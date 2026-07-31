{
  description = "Vendored Ambxst integration for NixOS, Home Manager, and Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # axctl is a build/runtime dependency of the vendored Ambxst source.
    axctl = {
      url = "github:Axenide/axctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, axctl, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      mkAmbxst = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          version = nixpkgs.lib.removeSuffix "\n" (builtins.readFile ./vendor/ambxst/version);
        in
        import ./vendor/ambxst/nix/packages {
          inherit pkgs system axctl version;
          lib = pkgs.lib;
          # The upstream package calls this argument `self`; supplying the
          # vendored directory makes the generated launcher reference only
          # audited code contained in this repository.
          self = ./vendor/ambxst;
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
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.ambxst}/bin/ambxst";
        };
      });

      nixosModules.default = { config, lib, pkgs, ... }: {
        imports = [ ./vendor/ambxst/nix/modules ];

        # Consumers may still override `programs.ambxst.package`, but the
        # default is always the package built from this vendored source tree.
        config.programs.ambxst.package = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.ambxst;
      };

      homeModules.default = { pkgs, lib, ... }:
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

          # Ambxst settings are intentionally mutable. They are seeded once,
          # then remain editable by Ambxst without creating links into /nix/store.
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

      checks = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          source-layout = pkgs.runCommand "ambxst-source-layout" { } ''
            test -f ${./vendor/ambxst}/flake.nix
            test -f ${./vendor/ambxst}/shell.qml
            test -f ${./vendor/ambxst}/nix/packages/default.nix
            grep -q 'AMBXST_CONFIG_ROOT' ${./vendor/ambxst}/config/Config.qml
            if grep -q 'exec-once = "ambxst"' ${./vendor/ambxst}/modules/services/CompositorTomlWriter.qml; then
              echo "Ambxst must not generate a second shell autostart" >&2
              exit 1
            fi
            touch "$out"
          '';
        });
    };
}
