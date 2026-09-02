{
  description = "Livara shell integration and application support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    noctalia-conf = {
      url = "github:Joaoferraz-byte/noctalia-conf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    community-templates = {
      url = "github:noctalia-dev/community-templates";
      flake = false;
    };
  };

  outputs = inputs@{ self, flake-parts, ... }:
    let
      noctaliaRuntime = inputs.noctalia-conf;
      communityTemplates = inputs."community-templates";
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
          noctalia-config = pkgs.runCommand "livara-noctalia-config-check" {
            nativeBuildInputs = [ noctaliaRuntime.packages.${pkgs.stdenv.hostPlatform.system}.default ];
          } ''
            sed \
              -e 's|@NOCTALIA_PALETTE_TEMPLATE@|${self}/config/noctalia/templates/livara-palette.json|g' \
              -e 's|@NOCTALIA_NVIM_TEMPLATE@|${self}/config/noctalia/templates/nvim-base16.lua|g' \
              -e 's|@NOCTALIA_FIREFOX_TEMPLATE@|${self}/config/noctalia/templates/firefox.css|g' \
              -e 's|@NOCTALIA_ZEN_TEMPLATE@|${self}/config/noctalia/templates/zen-userchrome.css|g' \
              -e 's|@NOCTALIA_CONTROL_CENTER_ICON@|${self}/assets/japanese-kanji.svg|g' \
              -e 's|@NOCTALIA_DISCORD_TEMPLATE@|${communityTemplates}/discord/discord-material.css|g' \
              -e 's|@NOCTALIA_HEROIC_TEMPLATE@|${communityTemplates}/heroiclauncher/heroic.css|g' \
              -e 's|@NOCTALIA_PRISM_TEMPLATE@|${communityTemplates}/prismlauncher/prismlauncher.json|g' \
              -e 's|@NOCTALIA_NIRI_TEMPLATE@|${self}/config/noctalia/templates/niri.kdl|g' \
              ${self}/config/noctalia/config.toml > config.toml
            noctalia config validate config.toml
            test -f ${self}/assets/japanese-kanji.svg
            grep -q 'viewBox="0 0 38.427 38.427"' ${self}/assets/japanese-kanji.svg
            grep -q 'custom_image = "@NOCTALIA_CONTROL_CENTER_ICON@"' ${self}/config/noctalia/config.toml
            grep -q 'custom_image_colorize = true' ${self}/config/noctalia/config.toml
            touch "$out"
          '';

          plugin-manifests = pkgs.runCommand "livara-noctalia-plugin-manifest-check" { } ''
            grep -q '^id[[:space:]]*=[[:space:]]*"dotnetrob/cat"' ${self}/plugins/cat/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"noctalia/screen_recorder"' ${self}/plugins/screen_recorder/plugin.toml
            grep -q '^default[[:space:]]*=[[:space:]]*"focused"' ${self}/plugins/screen_recorder/plugin.toml
            grep -q 'fallback-cpu-encoding yes' ${self}/plugins/screen_recorder/recorder_service.luau
            grep -q '^id[[:space:]]*=[[:space:]]*"noctalia/timer"' ${self}/plugins/timer/plugin.toml
            grep -q '^plugin_api[[:space:]]*=[[:space:]]*[0-9]' ${self}/plugins/cat/plugin.toml
            test -f ${self}/plugins/cat/cat.luau
            test -f ${self}/plugins/cat/cat_panel.luau
            test -f ${self}/plugins/cat/fonts/catwalk2.otf
            grep -q 'fontFamily = catFont' ${self}/plugins/cat/cat_panel.luau
            test -f ${self}/plugins/screen_recorder/recorder_service.luau
            test -f ${self}/plugins/timer/service.luau
            grep -q '^id[[:space:]]*=[[:space:]]*"alexander/screen-toolkit"' ${self}/plugins/screen_toolkit/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"nomadcxx/gamer-mode"' ${self}/plugins/gamer_mode/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"radimous/prismlauncher-instances"' ${self}/plugins/prismlauncher_instances/plugin.toml
            grep -q 'local function splitCommand' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            grep -q 'runAsync(argv, function(result)' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            grep -q 'result.exitCode' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            grep -q 'local function findLauncherConfig' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            grep -q 'freesmlauncher.cfg' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            grep -q 'prismlauncher.cfg' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            grep -q 'InstanceDir' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            ! grep -qF '/*.cfg' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            ! grep -q 'string.format(launcherCommand' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            ! grep -q 'getPrismPath' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            grep -q 'getLauncherRoot() .. "/icons/"' ${self}/plugins/prismlauncher_instances/prismlauncher-instances.luau
            grep -q 'data/FreesmLauncher' ${self}/config/noctalia/config.toml
            ! grep -q 'data/PrismLauncher' ${self}/config/noctalia/config.toml
            grep -q 'data/FreesmLauncher' ${self}/plugins/prismlauncher_instances/plugin.toml
            ! grep -q 'data/PrismLauncher' ${self}/plugins/prismlauncher_instances/plugin.toml
            grep -q '^id[[:space:]]*=[[:space:]]*"noctalia/bitwarden"' ${self}/plugins/bitwarden/plugin.toml
            touch "$out"
          '';
        };
      };

      flake.homeModules = rec {
        support = {
          _module.args.noctaliaRuntime = noctaliaRuntime;
          _module.args.noctaliaCommunityTemplates = communityTemplates;
          imports = [ ./modules/support.nix ];
        };
        default = support;
      };
    };
}
