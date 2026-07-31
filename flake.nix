{
  description = "Ambxst-X shell configuration for NixOS + Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    ambxst-x = {
      url = "github:OrynVail/Ambxst-X";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ambxst-x, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          upstreamPackage = ambxst-x.packages.${system}.default;

          # Keep the upstream revision and its axctl input intact. Only the
          # audited QML/bootstrap behavior is patched in a separate derivation.
          patchedSource = pkgs.runCommand "ambxst-x-patched-source" {
            src = ambxst-x.outPath;
            nativeBuildInputs = [ pkgs.patch ];
          } ''
            cp -R --no-preserve=mode "$src"/. "$out"
            chmod -R u+w "$out"
            patch --batch --forward -p1 -d "$out" < ${./patches/0001-ambxst-runtime-state-bootstrap-and-workspace-icons.patch}
          '';

          # The upstream wrapper creates this fontconfig file dynamically in
          # its own package expression. Recreate the same contract because the
          # patched launcher must point at the patched QML source tree.
          fontconfigConf = pkgs.writeTextDir "etc/fonts/conf.d/99-ambxst-fonts.conf" ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
              <dir>${upstreamPackage}/share/fonts</dir>
            </fontconfig>
          '';

          patchedLauncher = pkgs.writeShellScriptBin "ambxst" ''
            export AMBXST_QS="${upstreamPackage}/bin/qs"
            export PATH="${upstreamPackage}/bin:$PATH"
            export QML2_IMPORT_PATH="${upstreamPackage}/lib/qt-6/qml:$QML2_IMPORT_PATH"
            export QML_IMPORT_PATH="$QML2_IMPORT_PATH"
            export FONTCONFIG_PATH="${fontconfigConf}/etc/fonts:''${FONTCONFIG_PATH:-}"

            # Nix owns the immutable seed while AMBXST owns all runtime state:
            # JSON edits, binds.json and presets must never target /nix/store.
            export AMBXST_CONFIG_ROOT="''${AMBXST_CONFIG_ROOT:-''${XDG_STATE_HOME:-$HOME/.local/state}/ambxst}"

            exec ${patchedSource}/cli.sh "$@"
          '';

          ambxstPatched = pkgs.symlinkJoin {
            name = "ambxst-x-patched";
            paths = [ upstreamPackage ];
            postBuild = ''
              mkdir -p "$out/bin"
              rm -f "$out/bin/ambxst"
              ln -s ${patchedLauncher}/bin/ambxst "$out/bin/ambxst"
            '';
            meta = upstreamPackage.meta or { };
          };
        in
        {
          default = ambxstPatched;
          ambxst = ambxstPatched;
          upstream = upstreamPackage;
        });

      # Reexport the upstream NixOS module. nix-conf selects the patched package
      # explicitly through programs.ambxst.package.
      nixosModules.default = ambxst-x.nixosModules.default;

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

          # The repository settings are only a first-run seed. The active files
          # live under XDG_STATE_HOME so AMBXST can update JSON, binds and presets
          # without attempting to write through a Nix-store symlink.
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

            # Preserve presets authored before the runtime-state migration. A
            # real directory is copied once; a store symlink is discarded so
            # PresetsService can own the writable destination.
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
    };
}
