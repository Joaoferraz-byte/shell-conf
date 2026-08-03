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

            settings = {
              general.apps = {
                terminal = [ "kitty" ];
                audio = [ "pavucontrol" ];
              };
              bar.status.showBattery = true;
              paths.wallpaperDir = "~/Pictures/Wallpapers";
              appearance.transparency.enabled = false;
            };

            # ── CLI settings ────────────────────────────────────────────────
            # toggles: configura os special workspaces gerenciados pelo caelestia-cli.
            #   - social  → Vesktop  (Super + D)
            #   - todo    → ZenNotes (Super + I)
            #
            # theme: desabilita GTK para evitar conflito com o tema declarativo
            #   do home-manager (adw-gtk3-dark + kora).
            #
            # wallpaper.postHook: após trocar wallpaper/scheme, regenera o
            #   template do Kitty e recarrega as cores em todas as janelas abertas
            #   via `kitty @ set-colors`.
            cli.settings = {
              theme.enableGtk = false;

              toggles = {
                # ── social → Vesktop ──────────────────────────────────────
                social = {
                  vesktop = {
                    enable = true;
                    match = [{ class = "vesktop"; }];
                    command = [ "vesktop" ];
                    move = true;
                  };
                };

                # ── todo → ZenNotes (Flatpak) ─────────────────────────────
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

              # ── Wallpaper post-hook: reaplica tema dinâmico ao Kitty ────
              # Após qualquer troca de wallpaper/scheme o Caelestia regera os
              # templates em ~/.local/state/caelestia/theme/.  O hook abaixo
              # recarrega as cores em todas as janelas Kitty já abertas.
              wallpaper.postHook = "kitty @ --to unix:/tmp/kitty-livara set-colors --all ~/.local/state/caelestia/theme/kitty.conf 2>/dev/null || true";
            };
          };

          # ── Template do Kitty para tema dinâmico do Caelestia ───────────
          # O Caelestia CLI processa os templates em ~/.config/caelestia/templates/
          # e escreve o resultado em ~/.local/state/caelestia/theme/kitty.conf.
          # O kitty.conf inclui esse arquivo gerado via `include`.
          xdg.configFile."caelestia/templates/kitty.conf".text = ''
            # Caelestia dynamic theme template for Kitty
            # Gerado automaticamente — não edite manualmente.
            # Variáveis disponíveis: {{ <role>.hex }} ou {{ <role>.rgb }}
            # Roles: primary, secondary, tertiary, surface, onSurface,
            #        background, onBackground, term0..term15, etc.

            foreground            #{{ onSurface.hex }}
            background            #{{ surface.hex }}
            cursor                #{{ primary.hex }}
            cursor_text_color     #{{ onPrimary.hex }}
            selection_foreground  #{{ onSecondaryContainer.hex }}
            selection_background  #{{ secondaryContainer.hex }}

            # URL color
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
