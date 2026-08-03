{
  description = "Caelestia Shell thin configuration wrapper for NixOS + Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      caelestia-shell,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system: {
        default = caelestia-shell.packages.${system}.default;
      });

      homeManagerModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [ caelestia-shell.homeManagerModules.default ];

          programs.caelestia = {
            enable = true;
            cli.enable = true;

            systemd = {
              enable = true;
              target = "graphical-session.target";
            };

            # ── Configurações Estruturais e Visuais (O "Jeito Nix") ──────────
            # No NixOS, arquivos declarados aqui tornam-se read-only no store.
            # Isso impede que a GUI do Caelestia salve alterações, causando erro.
            #
            # RECOMENDAÇÃO: Use este bloco para fixar o que você quer que seja
            # imutável (como atalhos e caminhos). Se preferir usar a GUI para
            # aparência, remova os campos 'bar' e 'appearance' daqui.
            settings = {
              general.apps = {
                terminal = [ "kitty" ];
                audio = [ "pavucontrol" ];
              };

              # ── Caminho dos Wallpapers ──────────────────────────────────
              # Aponta para o diretório no seu repositório nix-conf.
              paths.wallpaperDir = "/home/livara/.config/nixos/Wallpapers";

              # ── Ajustes de Escala e Barra ───────────────────────────────
              # Se a barra parecer grande/pequena ou os ícones desproporcionais,
              # ajuste os valores abaixo.
              bar = {
                height = 40;           # Altura da barra em pixels
                iconSize = 22;         # Tamanho dos ícones na barra
                status.showBattery = true;
              };

              appearance = {
                transparency.enabled = true;
                # Se o shell parecer "esticado" ou pequeno, você pode tentar
                # forçar uma escala global (se suportado pelo seu monitor/shell)
                # scale = 1.0; 
              };
            };

            # ── CLI settings ────────────────────────────────────────────────
            cli.settings = {
              theme.enableGtk = false;

              toggles = {
                social = {
                  vesktop = {
                    enable = true;
                    match = [{ class = "vesktop"; }];
                    command = [ "vesktop" ];
                    move = true;
                  };
                };

                todo = {
                  zennotes = {
                    enable = true;
                    match = [{ class = "org.zennotes.ZenNotes"; }];
                    command = [
                      "flatpak"
                      "run"
                      "org.zennotes.ZenNotes"
                    ];
                    move = true;
                  };
                };
              };

              wallpaper.postHook = "kitty @ --to unix:/tmp/kitty-livara set-colors --all ~/.local/state/caelestia/theme/kitty.conf 2>/dev/null || true";
            };
          };

          # ── Template do Kitty para tema dinâmico do Caelestia ───────────
          xdg.configFile."caelestia/templates/kitty.conf".text = ''
            foreground            #{{ onSurface.hex }}
            background            #{{ surface.hex }}
            cursor                #{{ primary.hex }}
            cursor_text_color     #{{ onPrimary.hex }}
            selection_foreground  #{{ onSecondaryContainer.hex }}
            selection_background  #{{ secondaryContainer.hex }}
            url_color             #{{ primary.hex }}

            # Terminal colors (0-15)
            color0   #{{ term0.hex }}
            color1   #{{ term1.hex }}
            color2   #{{ term2.hex }}
            color3   #{{ term3.hex }}
            color4   #{{ term4.hex }}
            color5   #{{ term5.hex }}
            color6   #{{ term6.hex }}
            color7   #{{ term7.hex }}
            color8   #{{ term8.hex }}
            color9   #{{ term9.hex }}
            color10  #{{ term10.hex }}
            color11  #{{ term11.hex }}
            color12  #{{ term12.hex }}
            color13  #{{ term13.hex }}
            color14  #{{ term14.hex }}
            color15  #{{ term15.hex }}
          '';
        };

      nixosModules.default = caelestia-shell.nixosModules.default or { };
    };
}
