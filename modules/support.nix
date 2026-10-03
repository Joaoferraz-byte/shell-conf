{ config, lib, pkgs, shellName ? "Livara", ... }:
let
  source = ../src/livara;
  themeRoot = "${config.xdg.stateHome}/livara/theme";
  weztermColorScheme = if shellName == "Ambxst" then "Ambxst" else "Livara";
  weztermConfig = pkgs.writeText "wezterm.lua" (builtins.replaceStrings
    [ "@LIVARA_WEZTERM_COLOR_SCHEME@" ]
    [ weztermColorScheme ]
    (builtins.readFile (source + "/applications/wezterm.lua")));
  syncSource = source + "/scripts/sync-livara-themes.sh";
  syncThemes = pkgs.writeShellApplication {
    name = "sync-livara-themes";
    runtimeInputs = with pkgs; [ bash coreutils findutils gawk gnugrep gnused imagemagick jq procps util-linux dconf ];
    text = builtins.readFile syncSource;
  };

  syncAmbxstPalette = pkgs.writeShellApplication {
    name = "sync-ambxst-palette";
    runtimeInputs = with pkgs; [ bash coreutils gnugrep jq util-linux ];
    text = builtins.readFile (source + "/scripts/sync-ambxst-palette.sh");
  };

  syncAllThemes = pkgs.writeShellApplication {
    name = "sync-all-livara-themes";
    runtimeInputs = [ syncAmbxstPalette syncThemes pkgs.util-linux ];
    text = ''
      set -Eeuo pipefail

      # Livara is intentionally dark-only. Ignore stale light-mode callers so
      # a previous variant can never switch the desktop back to light mode.
      lock_file="''${LIVARA_LOCK_FILE:-''${XDG_STATE_HOME:-$HOME/.local/state}/livara/theme-sync.lock}"
      mkdir -p "$(dirname "$lock_file")"
      exec 9>"$lock_file"
      if ! flock -n 9; then
        printf '%s\n' 'theme synchronization already running; skipping orchestration' >&2
        exit 0
      fi

      LIVARA_LOCK_HELD=1 LIVARA_LOCK_FILE="$lock_file" LIVARA_PALETTE_VARIANT=dark sync-ambxst-palette
      LIVARA_LOCK_HELD=1 LIVARA_LOCK_FILE="$lock_file" sync-livara-themes dark
    '';
  };


  tabletStatus = pkgs.writeShellApplication {
    name = "livara-tablet-status";
    runtimeInputs = with pkgs; [ bash coreutils findutils jq ];
    text = ''
      set -Eeuo pipefail
      shopt -s nullglob

      # Primary identity: the physical MTM-1106/T501 USB tablet.
      for dev in /sys/bus/usb/devices/*; do
        [[ -r "$dev/idVendor" && -r "$dev/idProduct" ]] || continue
        vid="$(<"$dev/idVendor")"
        pid="$(<"$dev/idProduct")"
        if [[ "$vid" == "08f2" && "$pid" == "6811" ]]; then
          product="$(cat "$dev/product" 2>/dev/null || printf 'MTM-1106 / T501')"
          jq -cn --arg name "$product" '{connected: true, name: $name}'
          exit 0
        fi
      done

      # Stable by-id fallback for other external USB tablets.
      for link in /dev/input/by-id/*; do
        [[ -L "$link" ]] || continue
        name="''${link##*/}"
        lower="''${name,,}"
        case "$lower" in
          *tablet*|*wacom*|*huion*|*xp-pen*|*xppen*|*gaomon*|*veikk*|*parblo*|*digitizer*|*stylus*|*pen*)
            jq -cn --arg name "$name" '{connected: true, name: $name}'
            exit 0
            ;;
        esac
      done

      jq -cn '{connected: false, name: ""}'
    '';
  };

  xournalNewNote = pkgs.writeShellApplication {
    name = "livara-xournal-new-note";
    runtimeInputs = with pkgs; [ bash coreutils gnused gzip libnotify xournalpp ];
    text = builtins.readFile (source + "/scripts/xournal_new_note.sh");
  };

  dailyNote = pkgs.writeShellApplication {
    name = "livara-daily-note";
    runtimeInputs = with pkgs; [ bash coreutils gawk libnotify neovim wezterm foot ];
    text = builtins.readFile (source + "/scripts/daily_note.sh");
  };

  reloadZen = pkgs.writeShellApplication {
    name = "reload-zen";
    runtimeInputs = with pkgs; [ bash coreutils libnotify procps ];
    text = builtins.readFile (source + "/scripts/reload-zen.sh");
  };

  bootstrapPalette = source + "/theme/bootstrap.json";
  fastfetchCatSource = source + "/assets/fastfetch-cat.png";
  fastfetchCommand = pkgs.writeShellApplication {
    name = "livara-fastfetch";
    runtimeInputs = [ pkgs.fastfetch ];
    text = ''
      if [ -s "${themeRoot}/fastfetch.jsonc" ]; then
        exec fastfetch --config "${themeRoot}/fastfetch.jsonc" "$@"
      fi
      exec fastfetch "$@"
    '';
  };
in
{
  # Re-run adapters during every Home Manager activation. The user service
  # handles later palette changes, but it is not a sufficient guarantee when
  # an application config was deleted immediately before a rebuild.
  home.activation.livaraThemeSync = lib.hm.dag.entryAfter [ "writeBoundary" "xournalppLocalConfig" ] ''
    XDG_CONFIG_HOME="${config.xdg.configHome}" \
    XDG_DATA_HOME="${config.xdg.dataHome}" \
    XDG_CACHE_HOME="${config.xdg.cacheHome}" \
    XDG_STATE_HOME="${config.xdg.stateHome}" \
    LIVARA_THEME_ROOT="${themeRoot}" \
    LIVARA_DEFAULT_PALETTE="${themeRoot}/bootstrap.json" \
    LIVARA_REQUIRE_AMBXST=0 \
    LIVARA_PALETTE_VARIANT=dark \
    $DRY_RUN_CMD "${syncAllThemes}/bin/sync-all-livara-themes" || true
  '';

  home.packages = [
    pkgs.jq
    syncAmbxstPalette
    syncAllThemes
    syncThemes
    fastfetchCommand
    tabletStatus
    xournalNewNote
    dailyNote
    reloadZen
  ];

  systemd.user.services.livara-theme-sync = {
    Unit = {
      Description = "Synchronize the active ${shellName} palette with application themes";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${syncAllThemes}/bin/sync-all-livara-themes";
      Environment = [
        "LIVARA_SHELL_NAME=${shellName}"
        "XDG_CONFIG_HOME=${config.xdg.configHome}"
        "XDG_DATA_HOME=${config.xdg.dataHome}"
        "XDG_CACHE_HOME=${config.xdg.cacheHome}"
        "XDG_STATE_HOME=${config.xdg.stateHome}"
        "LIVARA_THEME_ROOT=${themeRoot}"
        "LIVARA_DEFAULT_PALETTE=${themeRoot}/bootstrap.json"
        "LIVARA_REQUIRE_AMBXST=1"
        "AMBXST_COLORS_FILE=${config.xdg.cacheHome}/ambxst/colors.json"
        "LIVARA_WEZTERM_COLOR_SCHEME=${weztermColorScheme}"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.paths.livara-theme-sync = {
    Unit = {
      Description = "Watch the ${shellName} palette for application theme updates";
    };
    Path = {
      PathChanged = "${config.xdg.cacheHome}/ambxst/colors.json";
      Unit = "livara-theme-sync.service";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.zsh.initContent = lib.mkAfter ''
    if [[ -o interactive && -t 1 && "''${TERM:-dumb}" != "dumb" && -z "''${LIVARA_FASTFETCH_SHOWN:-}" ]]; then
      export LIVARA_FASTFETCH_SHOWN=1
      livara-fastfetch --pipe false
    fi
  '';

  home.sessionVariables = {
    LIVARA_SHELL_NAME = shellName;
    LIVARA_THEME_ROOT = themeRoot;
    LIVARA_DEFAULT_PALETTE = "${themeRoot}/bootstrap.json";
    LIVARA_VAULT_ROOT = "${config.home.homeDirectory}/Vault";
    LIVARA_TEMPLATE_DIR = "${config.home.homeDirectory}/Vault/06 - Config/templates";
    LIVARA_DAILY_DIR = "${config.home.homeDirectory}/Vault/03 - Daily Notes";
    LIVARA_DAILY_TEMPLATE = "${config.home.homeDirectory}/Vault/06 - Config/templates/00 - Daily Note.md";
    LIVARA_IMAGE_DIR = "${config.home.homeDirectory}/Vault/00 - Black Box/Assets/Images";
    XOURNAL_VAULT_DIR = "${config.home.homeDirectory}/Vault/04 - Xournal++";
    LIVARA_FASTFETCH_CAT_PNG = "${config.home.homeDirectory}/.local/share/livara/assets/fastfetch-cat.png";
  };

  xdg.configFile."wezterm/wezterm.lua".source = weztermConfig;
  home.file.".local/bin/sync-livara-themes".source = "${syncThemes}/bin/sync-livara-themes";
  home.file.".local/share/livara/bootstrap.json".source = bootstrapPalette;
  home.file.".local/share/livara/assets/fastfetch-cat.png".source = fastfetchCatSource;
  home.file.".local/share/livara/scripts/open-zen.sh".source = source + "/scripts/open-zen.sh";
  home.file.".local/bin/reload-zen".source = "${reloadZen}/bin/reload-zen";
  home.file.".local/share/livara/scripts/open-nixos-nvim.sh".source = source + "/scripts/open-nixos-nvim.sh";
  home.file.".local/share/livara/scripts/xournal_new_note.sh".source = source + "/scripts/xournal_new_note.sh";
  home.file.".local/share/livara/scripts/daily_note.sh".source = source + "/scripts/daily_note.sh";

  # Override the beta package entry by its exact desktop-file ID. Keeping a
  # different `zen-browser.desktop` creates a second launcher; masking
  # `zen-beta.desktop` cannot hide that distinct ID.
  xdg.desktopEntries."zen-beta" = {
    name = "Zen Browser";
    genericName = "Web Browser";
    exec = "${config.home.homeDirectory}/.local/share/livara/scripts/open-zen.sh %U";
    icon = "zen-browser";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" ];
    startupNotify = true;
  };
  home.file.".config/livara/manifest.json".text = builtins.toJSON {
    name = "Livara";
    role = "application-adapters";
    owner = "shell-conf";
    compositor = "niri";
    shell = shellName;
    theme = "${shellName} palette-derived";
    iconTheme = "Livara-Kora";
    adapters = [
      "${shellName} palette: Fastfetch/btop/WezTerm and documented application adapters"
      "GTK3/GTK4 CSS and dark/light preferences; native libadwaita/Qt toolkit behavior remains toolkit-owned"
      "Firefox/Zen userChrome contracts"
      "Nixvim Markdown, Mermaid, LaTeX and Xournal++ workflows"
      "Freesm Launcher"
      "Heroic/Prism: application-owned templates"
      "Xournal++"
      "Hydra Launcher: generated theme.css for the supported Create/Edit flow and upstream submission"
    ];
  };

  home.activation.seedLivaraTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    theme_root="${themeRoot}"
    mkdir -p "$theme_root"
    if [ ! -s "$theme_root/bootstrap.json" ]; then
      install -Dm0644 "${bootstrapPalette}" "$theme_root/bootstrap.json"
    fi
    for palette in palette.json palette.dark.json; do
      if [ ! -s "$theme_root/$palette" ]; then
        cp -f "$theme_root/bootstrap.json" "$theme_root/$palette"
      fi
    done
  '';
}
