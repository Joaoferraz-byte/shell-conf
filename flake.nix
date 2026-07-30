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
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in {
          default = ambxst-x.packages.${system}.default;
          ambxst = ambxst-x.packages.${system}.default;
          ttf-phosphor-icons = ambxst-x.packages.${system}.default;
        });

      homeManagerModules.default = { config, pkgs, lib, ... }:
        let
          system = pkgs.system;
        in {
          home.packages = [ self.packages.${system}.default ];

          # Mapeando para ~/.config/ambxst/config/ para ser compatível com a expectativa do Ambxst-X
          # O Ambxst-X usa XDG_CONFIG_HOME/ambxst/config/
          home.file.".config/ambxst/config/theme.json".source = ./settings/theme.json;
          home.file.".config/ambxst/config/bar.json".source = ./settings/bar.json;
          home.file.".config/ambxst/config/compositor.json".source = ./settings/compositor.json;
          home.file.".config/ambxst/config/desktop.json".source = ./settings/desktop.json;
          home.file.".config/ambxst/config/dock.json".source = ./settings/dock.json;
          home.file.".config/ambxst/config/overview.json".source = ./settings/overview.json;
          home.file.".config/ambxst/config/performance.json".source = ./settings/performance.json;
          home.file.".config/ambxst/config/lockscreen.json".source = ./settings/lockscreen.json;
          home.file.".config/ambxst/config/workspaces.json".source = ./settings/workspaces.json;
          home.file.".config/ambxst/config/notch.json".source = ./settings/notch.json;
          home.file.".config/ambxst/config/system.json".source = ./settings/system.json;
        };
    };
}
