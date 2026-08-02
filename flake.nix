{
  description = "DankMaterialShell configuration for NixOS + Niri/Hyprland";

  inputs = {
    # Compartilha o mesmo nixpkgs do nix-conf pai, para evitar builds
    # duplicadas de Quickshell/Qt e drift de versão.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, dms, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # Não reimplementamos o packaging do DMS — apenas re-exportamos.
      packages = forAllSystems (system: {
        default = dms.packages.${system}.dms-shell;
        dms-shell = dms.packages.${system}.dms-shell;
      });

      # Módulo fino de Home Manager: liga o programa DMS e aplica as preferências do usuário.
      homeManagerModules.default = { config, lib, pkgs, ... }: {
        imports = [ dms.homeModules.dank-material-shell ];

        programs.dank-material-shell = {
          enable = true;

          # Habilita o serviço systemd para gerenciar o ciclo de vida da shell.
          # Isso evita o travamento na tela de carregamento do Quickshell ao
          # garantir que o daemon Go (dms) seja iniciado corretamente.
          systemd = {
            enable = true;
            # Para sessões UWSM (como configurado no nix-conf), o target
            # correto é graphical-session.target.
            target = "graphical-session.target";
          };

          settings = {
            theme = {
              mode = "dark";
              matugenEnabled = true;
            };
            bar = {
              position = "top";
            };
          };
        };

        # Adiciona matugen e outras dependências necessárias ao PATH do usuário.
        # O DMS com matugenEnabled exige o binário matugen para gerar temas.
        home.packages = with pkgs; [
          matugen
        ];
      };

      nixosModules.default = dms.nixosModules.dank-material-shell;
    };
}
