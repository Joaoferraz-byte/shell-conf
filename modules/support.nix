{ config, lib, pkgs, desktopProfile ? { }, noctaliaRuntime, ... }:
let
  source = ../src/livara;
  themeRoot = "${config.xdg.stateHome}/livara/theme";
  weztermConfig = pkgs.writeText "wezterm.lua" (builtins.readFile (source + "/applications/wezterm.lua"));
  syncSource = source + "/scripts/sync-livara-themes.sh";
  syncThemes = pkgs.writeShellApplication {
    name = "sync-livara-themes";
    runtimeInputs = with pkgs; [ bash coreutils findutils gawk gnugrep gnused imagemagick jq matugen procps wezterm flatpak dconf zip ];
    text = builtins.readFile syncSource;
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
    runtimeInputs = with pkgs; [ bash coreutils gawk libnotify ];
    text = builtins.readFile (source + "/scripts/daily_note.sh");
  };

  screenRecordingCore = pkgs.writeShellApplication {
    name = "livara-screen-recording-toggle";
    runtimeInputs = with pkgs; [ coreutils gpu-screen-recorder libnotify procps util-linux ];
    text = builtins.readFile (source + "/scripts/screen-recording-toggle.sh");
  };

  toggleScreenRecording = pkgs.writeShellApplication {
    name = "livara-toggle-screen-recording";
    text = ''
      exec ${screenRecordingCore}/bin/livara-screen-recording-toggle audio "$@"
    '';
  };

  toggleScreenRecordingSilent = pkgs.writeShellApplication {
    name = "livara-toggle-screen-recording-silent";
    text = ''
      exec ${screenRecordingCore}/bin/livara-screen-recording-toggle silent "$@"
    '';
  };

  reloadZen = pkgs.writeShellApplication {
    name = "reload-zen";
    runtimeInputs = with pkgs; [ bash coreutils libnotify procps ];
    text = builtins.readFile (source + "/scripts/reload-zen.sh");
  };

  bootstrapPalette = source + "/theme/bootstrap.json";
  fastfetchCatSource = source + "/assets/fastfetch-cat.png";
in
{
  imports = [ noctaliaRuntime.homeModules.default ];

  home.packages = [
    pkgs.jq
    syncThemes
    tabletStatus
    xournalNewNote
    dailyNote
    toggleScreenRecording
    toggleScreenRecordingSilent
    reloadZen
  ];

  systemd.user.services.livara-theme-sync = {
    Unit = {
      Description = "Synchronize the active Noctalia palette with application themes";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${syncThemes}/bin/sync-livara-themes";
      Environment = [
        "LIVARA_THEME_ROOT=${themeRoot}"
        "LIVARA_DEFAULT_PALETTE=${themeRoot}/bootstrap.json"
        "LIVARA_IDE_THEME_PLUGIN=${config.home.sessionVariables.LIVARA_IDE_THEME_PLUGIN or ""}"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.paths.livara-theme-sync = {
    Unit = {
      Description = "Watch the Noctalia palette for application theme updates";
    };
    Path = {
      PathChanged = "${themeRoot}/palette.dark.json";
      Unit = "livara-theme-sync.service";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
      # The theme adapter keeps this transparent PNG synchronized with the
      # active Noctalia primary color. kitty-direct requires both dimensions;
      # the source content is 1296x1518 (0.854:1), while terminal cells are
      # approximately twice as tall as wide. A 16x9 cell box maps to
      # 16*0.5/9 ~= 0.889, close enough to preserve the source proportion.
      # Fastfetch emits 17 text rows here. A 9-row logo has center 4.5, so
      # top padding 4 places its center at 8.5, matching the text center.
      logo = {
        source = "${themeRoot}/fastfetch-cat.png";
        type = "kitty-direct";
        width = 16;
        height = 9;
        padding = { top = 4; right = 3; left = 3; };
      };
      display.separator = " ";
      modules = [
        { key = "╭───────────╮"; type = "custom"; }
        { key = "│ {#36} user    {#keys}│"; type = "title"; format = "{user-name}"; }
        { key = "│ {#36}󰇅 hname   {#keys}│"; type = "title"; format = "{host-name}"; }
        { key = "│ {#36}󰅐 uptime  {#keys}│"; type = "uptime"; }
        { key = "│ {#36}{icon} distro  {#keys}│"; type = "os"; }
        { key = "│ {#36} kernel  {#keys}│"; type = "kernel"; }
        { key = "│ {#36} wm      {#keys}│"; type = "wm"; }
        { key = "│ {#36}󰇄 desktop {#keys}│"; type = "de"; }
        { key = "│ {#36} term    {#keys}│"; type = "terminal"; }
        { key = "│ {#36} shell   {#keys}│"; type = "shell"; }
        { key = "│ {#36}󰍛 cpu     {#keys}│"; type = "cpu"; format = "{name}"; }
        { key = "│ {#36}󰯦 gpu     {#keys}│"; type = "gpu"; format = "{name} "; detectionMethod = "auto"; }
        { key = "│ {#36}󰉉 disk    {#keys}│"; type = "disk"; folders = "/"; format = "{size-used} / {size-total}"; }
        { key = "│ {#36} memory  {#keys}│"; type = "memory"; }
        { key = "├───────────┤"; type = "custom"; }
        { key = "│ {#36} colors  {#keys}│"; type = "colors"; symbol = "circle"; }
        { key = "╰───────────╯"; type = "custom"; }
      ];
    };
  };

  programs.zsh.initContent = lib.mkAfter ''
    if [[ -o interactive && -t 1 && "''${TERM:-dumb}" != "dumb" && -z "''${LIVARA_FASTFETCH_SHOWN:-}" ]]; then
      export LIVARA_FASTFETCH_SHOWN=1
      fastfetch --pipe false
    fi
  '';

  home.sessionVariables = {
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
  home.file.".local/share/livara/scripts/toggle-screen-recording.sh".source = "${toggleScreenRecording}/bin/livara-toggle-screen-recording";
  home.file.".local/share/livara/scripts/toggle-screen-recording-silent.sh".source = "${toggleScreenRecordingSilent}/bin/livara-toggle-screen-recording-silent";
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
  xdg.configFile."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-icon-theme-name=Livara-Kora
    gtk-application-prefer-dark-theme=true
    gtk-enable-animations=true
  '';
  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-icon-theme-name=Livara-Kora
    gtk-application-prefer-dark-theme=true
    gtk-enable-animations=true
  '';

  home.file.".config/livara/manifest.json".text = builtins.toJSON {
    name = "Livara";
    role = "noctalia-application-adapters";
    owner = "shell-conf";
    compositor = "niri";
    shell = "Noctalia";
    theme = "Noctalia wallpaper-derived";
    iconTheme = "Livara-Kora";
    adapters = [
      "Noctalia palette: GTK/Qt/Kitty/WezTerm/Starship"
      "Firefox/Zen userChrome contracts"
      "Nixvim Markdown, Mermaid, LaTeX and Xournal++ workflows"
      "Freesm Launcher"
      "Heroic/Prism: Noctalia templates pinados"
      "Xournal++"
      "IntelliJ IDEA and Android Studio: generated Matugen ICLS"
      "Telegram Desktop: generated tdesktop-theme import"
      "Hydra Launcher: generated theme.css for upstream submission"
      "Nuclear Music Player: Noctalia-generated v2 advanced theme JSON"
    ];
  };

  home.activation.seedLivaraTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    theme_root="${themeRoot}"
    mkdir -p "$theme_root"
    if [ ! -s "$theme_root/bootstrap.json" ]; then
      install -Dm0644 "${bootstrapPalette}" "$theme_root/bootstrap.json"
    fi
    for palette in palette.json palette.dark.json palette.light.json; do
      if [ ! -s "$theme_root/$palette" ]; then
        cp -f "$theme_root/bootstrap.json" "$theme_root/$palette"
      fi
    done
  '';
}
