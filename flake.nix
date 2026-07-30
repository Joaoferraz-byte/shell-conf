{
  description = "Ambxst shell configuration for NixOS + Niri";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # ── ARCH-001: Migração para Ambxst-X ──────────────────────────────────
    # TODO: Avaliar migração de github:Axenide/Ambxst para github:OrynVail/Ambxst-X
    # Ambxst-X tem melhor suporte a Nix:
    #   - flake.nix próprio com nixosModules.default
    #   - diretório nix/ estruturado (lib.nix, modules/)
    #   - IpcHandler (axctl) como mecanismo IPC secundário (além do FIFO pipe)
    # A migração eliminaria o patchedAmbxstSrc e simplificaria este flake.
    # Bloquear: verificar paridade de features e testar IpcHandler antes de migrar.
    # Código-fonte do Ambxst (não é um flake, apenas o código)
    ambxst-src = {
      url = "github:Axenide/Ambxst";
      flake = false;
    };

    # axctl: daemon IPC universal que suporta Niri nativamente
    axctl = {
      url = "github:Axenide/axctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ambxst-src, axctl, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # ─── Pacotes ─────────────────────────────────────────────────────────
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          lib = nixpkgs.lib;

          # ── Phosphor Icons (fonte de ícones do shell) ──────────────────
          ttf-phosphor-icons = pkgs.stdenvNoCC.mkDerivation rec {
            pname = "ttf-phosphor-icons";
            version = "2.1.2";
            src = pkgs.fetchzip {
              url = "https://github.com/phosphor-icons/web/archive/refs/tags/v${version}.zip";
              sha256 = "sha256-96ivFjm0cBhqDKNB50klM7D3fevt8X9Zzm82KkJKMtU=";
              stripRoot = true;
            };
            dontBuild = true;
            installPhase = ''
              runHook preInstall
              install -Dm644 src/*/*.ttf -t $out/share/fonts/truetype
              install -Dm644 LICENSE -t $out/share/licenses/${pname}
              runHook postInstall
            '';
          };

          # ── Ambiente de dependências do Ambxst ─────────────────────────
          ambxstEnv = pkgs.buildEnv {
            name = "ambxst-env";
            paths = with pkgs; [
              # Quickshell e axctl
              quickshell
              axctl.packages.${system}.default

              # Core Qt/Wayland
              mesa libglvnd egl-wayland wayland
              qt6.qtbase qt6.qtsvg qt6.qttools qt6.qtwayland
              qt6.qtdeclarative qt6.qtimageformats
              kdePackages.qtmultimedia kdePackages.qtshadertools
              kdePackages.syntax-highlighting

              # Ferramentas do sistema
              brightnessctl ddcutil fontconfig glib grim imagemagick
              jq libnotify matugen python3 power-profiles-daemon
              slurp sqlite upower wl-clip-persist wl-clipboard
              wlsunset wtype zbar zenity inetutils

              # Mídia
              gpu-screen-recorder mpvpaper ffmpeg x264 playerctl
              pipewire wireplumber

              # Fontes
              roboto roboto-mono league-gothic
              nerd-fonts.symbols-only
              noto-fonts noto-fonts-color-emoji
              noto-fonts-cjk-sans noto-fonts-cjk-serif
              ttf-phosphor-icons
            ];
          };

          # ── Fontconfig para fontes bundled ────────────────────────────
          fontconfigConf = pkgs.writeTextDir "etc/fonts/conf.d/99-ambxst-fonts.conf" ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
              <dir>${ambxstEnv}/share/fonts</dir>
            </fontconfig>
          '';

          # ── Código-fonte do Ambxst com patches para Niri ──────────────
          # NOTA: O patch desativa o CompositorConfig.qml (que usa comandos
          # hardcoded do Hyprland) e deixa apenas o CompositorTomlWriter.qml
          # ativo, que usa o axctl e funciona corretamente com o Niri.
          patchedAmbxstSrc = pkgs.stdenv.mkDerivation {
            pname = "ambxst-src-patched";
            version = "1.0.0";
            src = ambxst-src;
            dontBuild = true;

            # Patch: Desativa os comandos hyprctl no CompositorConfig.qml
            # Esses comandos são ignorados pelo Niri e causam spam no log.
            # O CompositorTomlWriter.qml (via axctl) é a abordagem correta.
            patchPhase = ''
              # Comentar o bloco de batchCommand que usa comandos Hyprland
              sed -i \
                's/batchCommand += `keyword general:/\/\/ [niri-compat] batchCommand += `keyword general:/g' \
                modules/services/CompositorConfig.qml
              sed -i \
                's/batchCommand += `keyword decoration:/\/\/ [niri-compat] batchCommand += `keyword decoration:/g' \
                modules/services/CompositorConfig.qml
              sed -i \
                's/batchCommand += `keyword animation/\/\/ [niri-compat] batchCommand += `keyword animation/g' \
                modules/services/CompositorConfig.qml
              sed -i \
                's/batchCommand += `keyword bezier/\/\/ [niri-compat] batchCommand += `keyword bezier/g' \
                modules/services/CompositorConfig.qml
              sed -i \
                's/batchCommand += `keyword layerrule/\/\/ [niri-compat] batchCommand += `keyword layerrule/g' \
                modules/services/CompositorConfig.qml
            '';

            installPhase = ''
              mkdir -p $out/share/ambxst
              cp -r . $out/share/ambxst/
            '';
          };

          # ── Wrapper de lançamento do Ambxst ───────────────────────────
          ambxstWrapper = pkgs.writeShellScriptBin "ambxst" ''
            set -euo pipefail

            export PATH="${ambxstEnv}/bin:$PATH"
            export QML2_IMPORT_PATH="${ambxstEnv}/lib/qt-6/qml:''${QML2_IMPORT_PATH:-}"
            export QML_IMPORT_PATH="$QML2_IMPORT_PATH"
            export FONTCONFIG_PATH="${fontconfigConf}/etc/fonts:''${FONTCONFIG_PATH:-}"

            # Expõe ícones do sistema para o Quickshell
            # Inclui Nix store, perfil do usuário e Flatpak
            export XDG_DATA_DIRS="/run/current-system/sw/share:$HOME/.nix-profile/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

            # Tema de ícones: tenta ler do gsettings, fallback para hicolor
            if command -v gsettings >/dev/null 2>&1; then
              ICON_THEME=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'" || echo "hicolor")
            else
              ICON_THEME="hicolor"
            fi
            export QS_ICON_THEME="''${ICON_THEME:-hicolor}"

            # Iniciar o daemon axctl se não estiver rodando
            # O axctl detecta automaticamente o Niri via NIRI_SOCKET
            if ! pgrep -x "axctl" > /dev/null 2>&1; then
              axctl daemon &
              # Aguardar o daemon inicializar
              sleep 0.5
            fi

            # Criar o pipe IPC se não existir (usado pelo Niri para enviar comandos)
            AMBXST_IPC_PIPE="/tmp/ambxst_ipc.pipe"
            if [ ! -p "$AMBXST_IPC_PIPE" ]; then
              mkfifo "$AMBXST_IPC_PIPE"
            fi

            # Salvar PID para controle
            echo $$ > /tmp/ambxst.pid

            # Lançar o Quickshell com o shell.qml do Ambxst
            exec "${ambxstEnv}/bin/qs" -p "${patchedAmbxstSrc}/share/ambxst/shell.qml" "$@"
          '';

        in {
          default = ambxstWrapper;
          ambxst = ambxstWrapper;
          ttf-phosphor-icons = ttf-phosphor-icons;
        });

      # ─── Módulo Home Manager ──────────────────────────────────────────────
      # Gerencia os arquivos JSON de configuração do Ambxst de forma declarativa,
      # seguindo o mesmo padrão do noctalia.json no nix-conf.
      homeManagerModules.default = { config, pkgs, lib, ... }:
        let
          system = pkgs.system;
        in {
          home.packages = [ self.packages.${system}.default ];

          # ── Configurações base em JSON ─────────────────────────────────
          # Os arquivos são gerenciados pelo Nix. Para customizar, edite os
          # arquivos em settings/ no repositório shell-conf.
          home.file.".config/ambxst/config/theme.json" = {
            source = ./settings/theme.json;
          };
          home.file.".config/ambxst/config/bar.json" = {
            source = ./settings/bar.json;
          };
          home.file.".config/ambxst/config/compositor.json" = {
            source = ./settings/compositor.json;
          };
          home.file.".config/ambxst/config/desktop.json" = {
            source = ./settings/desktop.json;
          };
          home.file.".config/ambxst/config/dock.json" = {
            source = ./settings/dock.json;
          };
          home.file.".config/ambxst/config/overview.json" = {
            source = ./settings/overview.json;
          };
          home.file.".config/ambxst/config/performance.json" = {
            source = ./settings/performance.json;
          };
          home.file.".config/ambxst/config/lockscreen.json" = {
            source = ./settings/lockscreen.json;
          };
          home.file.".config/ambxst/config/workspaces.json" = {
            source = ./settings/workspaces.json;
          };

          # ── Keybinds do Ambxst ─────────────────────────────────────────
          # NOTA: Os keybinds do Ambxst são gerenciados aqui para garantir
          # que não conflitem com os keybinds do Niri definidos em niri.nix.
          # O Niri envia comandos via pipe IPC; o Ambxst não precisa registrar
          # keybinds globais próprios (evita duplicação).
          home.file.".config/ambxst/binds.json".text = builtins.toJSON {
            ambxst = {
              # Launcher: SUPER (Super_L) — abre o launcher de apps
              launcher = {
                modifiers = [ "SUPER" ];
                key = "Super_L";
                action = { id = "ambxst.launcher"; args = {}; };
              };
              # Dashboard: SUPER+D — painel principal
              dashboard = {
                modifiers = [ "SUPER" ];
                key = "D";
                action = { id = "ambxst.dashboard"; args = {}; };
              };
              # Clipboard: SUPER+V — histórico de clipboard
              # NOTA: Conflito com "toggle floating" do Niri.
              # O Niri será configurado para usar SUPER+Shift+V para floating.
              clipboard = {
                modifiers = [ "SUPER" ];
                key = "V";
                action = { id = "ambxst.clipboard"; args = {}; };
              };
              # Emoji: SUPER+. — seletor de emojis
              emoji = {
                modifiers = [ "SUPER" ];
                key = "PERIOD";
                action = { id = "ambxst.emoji"; args = {}; };
              };
              # Notes: SUPER+N — notas rápidas
              notes = {
                modifiers = [ "SUPER" ];
                key = "N";
                action = { id = "ambxst.notes"; args = {}; };
              };
              # Wallpapers: SUPER+, — seletor de wallpapers
              wallpapers = {
                modifiers = [ "SUPER" ];
                key = "COMMA";
                action = { id = "ambxst.wallpapers"; args = {}; };
              };
            };
            system = {
              # Overview: SUPER+Tab — visão geral de workspaces
              overview = {
                modifiers = [ "SUPER" ];
                key = "TAB";
                action = { id = "ambxst.overview"; args = {}; };
              };
              # Power menu: SUPER+Escape
              powermenu = {
                modifiers = [ "SUPER" ];
                key = "ESCAPE";
                action = { id = "ambxst.powermenu"; args = {}; };
              };
              # Lock screen: SUPER+L
              lockscreen = {
                modifiers = [ "SUPER" ];
                key = "L";
                action = { id = "system.lock"; args = {}; };
              };
              # Screenshot: SUPER+Shift+S
              screenshot = {
                modifiers = [ "SUPER" "SHIFT" ];
                key = "S";
                action = { id = "ambxst.screenshot"; args = {}; };
              };
              # Tools: SUPER+T — movido de SUPER+S (conflito com launcher via IPC do Niri)
              # O Niri usa Mod+S para enviar 'launcher' via pipe IPC; SUPER+T é livre.
              # Referência: BUG-004 no audit report
              tools = {
                modifiers = [ "SUPER" ];
                key = "T";
                action = { id = "ambxst.tools"; args = {}; };
              };
            };
          };
        };
    };
}
