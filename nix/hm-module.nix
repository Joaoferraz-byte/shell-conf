self: {
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;

  cli-default = self.inputs.caelestia-cli.packages.${system}.default;
  shell-default = self.packages.${system}.with-cli;

  cfg = config.programs.caelestia;
in {
  imports = [
    (lib.mkRenamedOptionModule ["programs" "caelestia" "environment"] ["programs" "caelestia" "systemd" "environment"])
  ];
  options = with lib; {
    programs.caelestia = {
      enable = mkEnableOption "Enable Caelestia shell";
      package = mkOption {
        type = types.package;
        default = shell-default;
        description = "The package of Caelestia shell";
      };
      systemd = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable the systemd service for Caelestia shell";
        };
        target = mkOption {
          type = types.str;
          description = ''
            The systemd target that will automatically start the Caelestia shell.
          '';
          default = config.wayland.systemd.target;
        };
        environment = mkOption {
          type = types.listOf types.str;
          description = "Extra Environment variables to pass to the Caelestia shell systemd service.";
          default = [];
          example = [
            "QT_QPA_PLATFORMTHEME=gtk3"
          ];
        };
      };
      settings = mkOption {
        type = types.attrsOf types.anything;
        default = {};
        description = "Caelestia shell settings";
      };
      mutableSettings = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to make settings files mutable to allow the UI to save changes.";
      };
      extraConfig = mkOption {
        type = types.str;
        default = "";
        description = "Caelestia shell extra configs written to shell.json";
      };
      cli = {
        enable = mkEnableOption "Enable Caelestia CLI";
        package = mkOption {
          type = types.package;
          default = cli-default;
          description = "The package of Caelestia CLI";
        };
        settings = mkOption {
          type = types.attrsOf types.anything;
          default = {};
          description = "Caelestia CLI settings";
        };
        extraConfig = mkOption {
          type = types.str;
          default = "";
          description = "Caelestia CLI extra configs written to cli.json";
        };
      };
      hyprland = {
        enable = mkEnableOption "Enable Caelestia Hyprland integration";
        manageConfigs = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to manage Hyprland Lua configs from the vendored source.";
        };
        userConfig = mkOption {
          type = types.str;
          default = "";
          description = "Custom Lua configuration to be written to hypr-user.lua";
        };
      };
    };
  };

  config = let
    cli = cfg.cli.package;
    shell = cfg.package;
    
    # Seeder script to copy config files if they don't exist, allowing them to be mutable.
    seederScript = pkgs.writeShellScript "caelestia-config-seeder" ''
      mkdir -p "$HOME/.config/caelestia"
      
      seed_config() {
        local dest="$1"
        local source="$2"
        if [ ! -f "$dest" ]; then
          cp "$source" "$dest"
          chmod +w "$dest"
        fi
      }

      ${lib.optionalString (cfg.settings != {} || cfg.extraConfig != "") ''
        seed_config "$HOME/.config/caelestia/shell.json" "${pkgs.writeText "shell.json" (builtins.toJSON (lib.recursiveUpdate (if cfg.extraConfig != "" then builtins.fromJSON cfg.extraConfig else {}) cfg.settings))}"
      ''}

      ${lib.optionalString (cfg.cli.settings != {} || cfg.cli.extraConfig != "") ''
        seed_config "$HOME/.config/caelestia/cli.json" "${pkgs.writeText "cli.json" (builtins.toJSON (lib.recursiveUpdate (if cfg.cli.extraConfig != "" then builtins.fromJSON cfg.cli.extraConfig else {}) cfg.cli.settings))}"
      ''}
    '';

  in
    lib.mkIf cfg.enable {
      systemd.user.services.caelestia = lib.mkIf cfg.systemd.enable {
        Unit = {
          Description = "Caelestia Shell Service";
          After = [cfg.systemd.target];
          PartOf = [cfg.systemd.target];
        };

        Service = {
          Type = "exec";
          ExecStart = "${shell}/bin/caelestia-shell";
          Restart = "on-failure";
          RestartSec = "5s";
          TimeoutStopSec = "5s";
          Environment =
            [
              "QT_QPA_PLATFORM=wayland"
            ]
            ++ cfg.systemd.environment;

          Slice = "session.slice";
        };

        Install = {
          WantedBy = [cfg.systemd.target];
        };
      };

      # Use activation script to seed mutable configs
      home.activation.caelestiaConfigSeeder = lib.mkIf cfg.mutableSettings (lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${seederScript}
      '');

      # Configuration files
      xdg.configFile = let
        mkConfig = c:
          lib.pipe (
            if c.extraConfig != ""
            then c.extraConfig
            else "{}"
          ) [
            builtins.fromJSON
            (lib.recursiveUpdate c.settings)
            builtins.toJSON
          ];
        shouldGenerate = c: c.extraConfig != "" || c.settings != {};
      in lib.mkMerge [
        # JSON Configs (only if mutableSettings is false)
        (lib.mkIf (!cfg.mutableSettings) {
          "caelestia/shell.json" = lib.mkIf (shouldGenerate cfg) {
            text = mkConfig cfg;
          };
          "caelestia/cli.json" = lib.mkIf (shouldGenerate cfg.cli) {
            text = mkConfig cfg.cli;
          };
        })
        # Hyprland Lua Integration
        (lib.mkIf cfg.hyprland.enable {
          "hypr/hyprland.lua".source = ../hypr_upstream/hyprland.lua;
          "hypr/variables.lua".source = ../hypr_upstream/variables.lua;
          "hypr/hyprland".source = ../hypr_upstream/hyprland;
          "hypr/utils".source = ../hypr_upstream/utils;
          "hypr/scheme".source = ../hypr_upstream/scheme;
          "caelestia/hypr-user.lua" = lib.mkIf (cfg.hyprland.userConfig != "") {
            text = cfg.hyprland.userConfig;
          };
        })
      ];

      home.packages = [shell] ++ lib.optional cfg.cli.enable cli;
    };
}
