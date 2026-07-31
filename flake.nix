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
      packages = forAllSystems (system: {
        default = ambxst-x.packages.${system}.default;
        ambxst = ambxst-x.packages.${system}.default;
      });

      # Reexporta o módulo NixOS mantido pelo upstream. Ele registra as fontes
      # Phosphor e as dependências de runtime que o Ambxst-X espera.
      nixosModules.default = ambxst-x.nixosModules.default;

      homeManagerModules.default = { pkgs, lib, ... }:
        let
          system = pkgs.stdenv.hostPlatform.system;
        in {
          # Permite usar este módulo também fora do módulo NixOS reexportado.
          home.packages = [ self.packages.${system}.default ];

          # O Ambxst-X carrega estes adaptadores de XDG_CONFIG_HOME/ambxst/config.
          # Mantê-los no repositório evita que o primeiro login crie defaults
          # implícitos e não versionados.
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
          home.file.".config/ambxst/config/weather.json".source = ./settings/weather.json;
          home.file.".config/ambxst/config/prefix.json".source = ./settings/prefix.json;

          # Em versões anteriores este flake criava um binds.json mínimo como
          # link imutável. O Ambxst-X atual administra e migra esse arquivo por
          # conta própria via axctl; remover somente o link legado deixa o
          # arquivo mutable para a UI e evita duplicação de binds com Hyprland.
          home.activation.removeLegacyAmbxstBinds = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
            target="$HOME/.config/ambxst/binds.json"
            if [ -L "$target" ]; then
              resolved="$(readlink -f "$target" || true)"
              if [[ "$resolved" == /nix/store/* ]]; then
                rm -f "$target"
              fi
            fi
          '';
        };
    };
}
