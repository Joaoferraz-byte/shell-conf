{
  description = "DankMaterialShell configuration for NixOS + Niri (este flake apenas fixa a versão do DMS e expõe um módulo fino com as preferências do usuário; a build em si vive inteira em AvengeMedia/DankMaterialShell)";

  inputs = {
    # Compartilha o mesmo nixpkgs do nix-conf pai, para evitar builds
    # duplicadas de Quickshell/Qt e drift de versão (era parte do que
    # deixava o setup antigo do Ambxst-X instável).
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

      # Módulo fino de Home Manager: liga o programa DMS e aplica só as
      # preferências deste usuário (tema/tokens), como um attrset simples —
      # em vez de 8 arquivos JSON separados como no setup antigo do
      # Ambxst-X. O DMS já expõe `programs.dank-material-shell.settings`
      # como JSON estruturado; não duplicamos essa superfície de opções.
      #
      # IMPORTANTE: de propósito NÃO importamos `dms.homeModules.niri`.
      # Ver README.md — esse módulo é um "include hack" que não gera os
      # fragmentos niri/dms/*.kdl necessários quando o config.kdl do Niri
      # é gerenciado declarativamente (fica no /nix/store, somente leitura),
      # e isso é uma causa conhecida (AvengeMedia/DankMaterialShell#1788)
      # da shell travar na tela de carregamento do Quickshell sem nunca
      # terminar de subir.
      homeManagerModules.default = { config, lib, pkgs, ... }: {
        imports = [ dms.homeModules.dank-material-shell ];

        programs.dank-material-shell = {
          enable = true;

          settings = {
            # Preferências do usuário — ajuste livremente, isto é só um
            # ponto de partida sensato para Niri + tema escuro.
            theme = {
              mode = "dark";
              matugenEnabled = true;
            };
            bar = {
              position = "top";
            };
          };
        };
      };

      nixosModules.default = dms.nixosModules.dank-material-shell;
    };
}
