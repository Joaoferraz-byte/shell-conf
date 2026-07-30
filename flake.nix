{
  description = "Quickshell configuration for Niri inspired by Ambxst/Noctalia";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      # Pacotes para a shell (caso precise compilar algo)
      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system}; in {
          default = pkgs.stdenv.mkDerivation {
            pname = "quickshell-config";
            version = "1.0.0";
            src = self;
            installPhase = ''
              mkdir -p $out/share/quickshell/shell-conf
              cp -r modules shell.qml settings.json $out/share/quickshell/shell-conf
            '';
          };
        });

      # Configurações Home Manager para integrar ao Nix
      homeManagerModules.default = { config, pkgs, ... }: {
        home.file.".config/quickshell/shell-conf" = {
          source = "${self.packages.${pkgs.system}.default}/share/quickshell/shell-conf";
          recursive = true;
        };
      };
    };
}
