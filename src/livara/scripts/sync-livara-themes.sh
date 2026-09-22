#!/usr/bin/env bash
set -Eeuo pipefail

    XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
    THEME_DIR="${LIVARA_THEME_ROOT:-$XDG_STATE_HOME/livara/theme}"
    SHELL_NAME="${LIVARA_SHELL_NAME:-Livara}"
    LOG_DIR="$XDG_STATE_HOME/livara/logs"
    LOG_FILE="$LOG_DIR/theme-sync.log"
    FOLIATE_CONFIG_HOME="$XDG_CONFIG_HOME/com.github.johnfactotum.Foliate"
    FOLIATE_FLATPAK_HOME="$HOME/.var/app/com.github.johnfactotum.Foliate/config/com.github.johnfactotum.Foliate"
    VESKTOP_CONFIG_HOME="$XDG_CONFIG_HOME/vesktop"
    VESKTOP_FLATPAK_HOME="$HOME/.var/app/dev.vencord.Vesktop/config/vesktop"
    XOURNAL_PALETTE_NAME="livara.gpl"
    FASTFETCH_CAT_SOURCE="${LIVARA_FASTFETCH_CAT_PNG:-$HOME/.local/share/livara/assets/fastfetch-cat.png}"
    FASTFETCH_CAT_OUTPUT="$THEME_DIR/fastfetch-cat.png"
    FASTFETCH_CAT_STATE="$THEME_DIR/fastfetch-cat.state"
    INTELLIJ_SCHEME="$THEME_DIR/intellij/Matugen-Dark.icls"
    INTELLIJ_CONFIG_ROOTS=(
      "${IDEA_CONFIG_PATH:-}"
      "$XDG_CONFIG_HOME/JetBrains"
      "$XDG_CONFIG_HOME/Google"
    )
    INTELLIJ_DATA_ROOTS=(
      "${IDEA_DATA_PATH:-}"
      "${XDG_DATA_HOME:-$HOME/.local/share}/JetBrains"
      "${XDG_DATA_HOME:-$HOME/.local/share}/Google"
    )
    ANDROID_STUDIO_DATA_PATH="${ANDROID_STUDIO_DATA_PATH:-$XDG_DATA_HOME/Google}"
    INTELLIJ_THEME_PLUGIN="${LIVARA_IDE_THEME_PLUGIN:-}"
    HYDRA_THEME_NAME="${LIVARA_HYDRA_THEME_NAME:-Livara}"
    HYDRA_FRIEND_CODE="${LIVARA_HYDRA_FRIEND_CODE:-}"
    case "$HYDRA_THEME_NAME" in
      ""|*/*|*\\*) HYDRA_THEME_NAME="Livara" ;;
    esac
    [[ "$HYDRA_FRIEND_CODE" =~ ^[[:alnum:]]+$ ]] || HYDRA_FRIEND_CODE=""
    HYDRA_THEME_ID="$HYDRA_THEME_NAME-${HYDRA_FRIEND_CODE:-local}"
    HYDRA_USER_DATA_ROOT="${LIVARA_HYDRA_USER_DATA:-$XDG_CONFIG_HOME/Hydra}"
    HYDRA_THEME_DIR="$HYDRA_USER_DATA_ROOT/themes/$HYDRA_THEME_ID"
    HYDRA_THEME_EXPORT_DIR="$THEME_DIR/hydra-export/themes/$HYDRA_THEME_ID"
    HYDRA_SCREENSHOT_SOURCE="${LIVARA_HYDRA_SCREENSHOT:-}"
    HYDRA_SCREENSHOT="$HYDRA_THEME_DIR/screenshot.png"
    NUCLEAR_DATA_ROOTS=(
      "${LIVARA_NUCLEAR_DATA_HOME:-$XDG_DATA_HOME/com.nuclearplayer}"
      "$HOME/.local/share/com.nuclearplayer"
      "$HOME/.var/app/com.nuclearplayer.Nuclear/data/com.nuclearplayer"
    )
    NUCLEAR_DATA_HOME="${NUCLEAR_DATA_ROOTS[0]}"
    NUCLEAR_THEME_DIR="$NUCLEAR_DATA_HOME/themes"
    NUCLEAR_THEME_PATH="$NUCLEAR_THEME_DIR/Livara.json"
    NUCLEAR_THEME_ID="themes/Livara.json"
    NUCLEAR_DARK_MODE="${1:-dark}"
    case "$NUCLEAR_DARK_MODE" in
      dark|light) ;;
      *) printf 'invalid Livara palette variant: %s\n' "$NUCLEAR_DARK_MODE" >&2; exit 2 ;;
    esac
    PALETTE_VARIANT="$NUCLEAR_DARK_MODE"
    PALETTE_FILE="$THEME_DIR/palette.$PALETTE_VARIANT.json"
    BTOP_CONFIG="$XDG_CONFIG_HOME/btop/btop.conf"
    BTOP_THEME="$XDG_CONFIG_HOME/btop/themes/Livara.theme"
    WEZTERM_SCHEME="${LIVARA_WEZTERM_COLOR_SCHEME:-$SHELL_NAME}"
    WEZTERM_THEME="$XDG_CONFIG_HOME/wezterm/colors/$WEZTERM_SCHEME.toml"
    MATUGEN_CONFIG="$XDG_CONFIG_HOME/matugen/config.toml"
    # NixVim/Home Manager exposes the generated Lua module under lua/.
    NVIM_THEME_PATH="$XDG_CONFIG_HOME/nvim/lua/matugen_colors.lua"
    FREESM_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/FreesmLauncher"
    FREESM_FLATPAK_HOME="$HOME/.var/app/org.freesmlauncher.FreesmLauncher/data/FreesmLauncher"
    mkdir -p "$THEME_DIR" "$LOG_DIR"
    log() { printf '[%s] %s\n' "$(date --iso-8601=seconds)" "$*" | tee -a "$LOG_FILE"; }
    LOCK_FILE="${LIVARA_LOCK_FILE:-$XDG_STATE_HOME/livara/theme-sync.lock}"
    mkdir -p "$(dirname "$LOCK_FILE")"
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
      log "theme synchronization already running; skipping overlapping invocation"
      exit 0
    fi

    # The application adapters below consume each ecosystem's documented
    # format. The selected shell owns palette production; this adapter only
    # consumes the requested neutral variant and publishes projections.
    if [[ ! -s "$THEME_DIR/palette.json" ]]; then
      install -m 0644 "${LIVARA_DEFAULT_PALETTE:-$THEME_DIR/bootstrap.json}" "$THEME_DIR/palette.json"
      log "installed the emergency Livara fallback palette"
    fi
    if [[ ! -s "$PALETTE_FILE" ]]; then
      if [[ -s "$THEME_DIR/palette.json" ]]; then
        cp -f "$THEME_DIR/palette.json" "$PALETTE_FILE"
        log "palette.$PALETTE_VARIANT.json missing; using the active palette as an explicit fallback"
      else
        log "palette.$PALETTE_VARIANT.json and palette.json are missing"
        exit 1
      fi
    fi
    jq -e 'type == "object" and all(.[]; type == "string" and test("^#[0-9A-Fa-f]{6}$"))' "$PALETTE_FILE" >/dev/null || {
      log "palette.$PALETTE_VARIANT.json is invalid"
      exit 1
    }
    json_color() {
      local key="$1"
      local fallback="${2:-base}"
      local color
      if ! color="$(jq -er --arg key "$key" --arg fallback "$fallback" '.[$key] // .[$fallback] // .base // error("missing color")' "$PALETTE_FILE")"; then
        log "palette is missing required color role: $key"
        return 1
      fi
      if [[ "$color" =~ ^#[[:xdigit:]]{6}$ ]]; then
        printf '%s\n' "$color"
      else
        log "palette contains invalid color role: $key"
        return 1
      fi
      }

    sync_browser_theme() {
      local browser_css="$THEME_DIR/browser/firefox.css"
      write_atomic "$browser_css" <<EOF
/* Generated by Livara for Firefox/Zen userChrome.css. */
:root {
  --livara-base: $(json_color base);
  --livara-surface: $(json_color surface0);
  --livara-surface-raised: $(json_color surface1);
  --livara-text: $(json_color text);
  --livara-muted: $(json_color subtext0);
  --livara-primary: $(json_color blue);
  --livara-on-primary: $(json_color overPrimary);
  --livara-border: $(json_color overlay0);
}

@-moz-document url-prefix("chrome://browser/content/browser.xhtml") {
  /* Firefox and Zen keep the browser chrome separate from web content. */
  :root,
  #main-window,
  #browser,
  #zen-main-app-wrapper,
  #zen-browser-background,
  #zen-toolbar-background,
  #zen-appcontent-wrapper,
  #zen-tabbox-wrapper,
  #tabbrowser-tabbox,
  #tabbrowser-tabpanels {
    background: var(--livara-base) !important;
    color: var(--livara-text) !important;
  }

  #zen-browser-background::before,
  #zen-browser-background::after,
  #zen-toolbar-background::before,
  #zen-toolbar-background::after {
    background: var(--livara-base) !important;
    opacity: 1 !important;
  }

  #navigator-toolbox,
  #TabsToolbar,
  #nav-bar,
  #PersonalToolbar,
  #zen-appcontent-navbar-wrapper,
  #zen-appcontent-navbar-container,
  #zen-toolbar-background {
    background: var(--livara-base) !important;
    color: var(--livara-text) !important;
    border-color: var(--livara-border) !important;
  }

  #zen-tabs-wrapper,
  #zen-essentials,
  #zen-sidebar-top-buttons,
  #zen-sidebar-foot-buttons,
  #sidebar-box,
  #sidebar-header,
  #zen-sidebar-splitter,
  #zen-expand-sidebar-button,
  #zen-workspaces-button,
  #zen-create-new-button,
  #zen-sidebar-foot-buttons toolbarbutton,
  #zen-sidebar-top-buttons toolbarbutton,
  #appcontent,
  #statuspanel,
  #findbar,
  #downloadsPanel,
  #downloadsListBox,
  panel,
  panelview,
  menupopup,
  menu,
  menuitem {
    background: var(--livara-surface) !important;
    color: var(--livara-text) !important;
    border-color: var(--livara-border) !important;
  }

  #zen-tabs-wrapper,
  #zen-essentials,
  #sidebar-box,
  #sidebar-header,
  #zen-sidebar-foot-buttons,
  #zen-sidebar-top-buttons {
    box-shadow: none !important;
  }

  #urlbar,
  #urlbar-background,
  .urlbar-background,
  #searchbar,
  .urlbar-input-container,
  .searchbar-textbox {
    background: var(--livara-surface) !important;
    color: var(--livara-text) !important;
    border-color: var(--livara-border) !important;
  }

  #urlbar-input,
  .urlbar-input,
  .searchbar-textbox {
    color: var(--livara-text) !important;
    fill: var(--livara-text) !important;
  }

  toolbarbutton,
  toolbarbutton .toolbarbutton-icon,
  #zen-sidebar-foot-buttons toolbarbutton,
  #zen-sidebar-top-buttons toolbarbutton {
    color: var(--livara-text) !important;
    fill: var(--livara-text) !important;
    -moz-context-properties: fill, fill-opacity, stroke, stroke-opacity !important;
  }

  toolbarbutton:hover,
  menu:hover,
  menuitem:hover,
  .subviewbutton:hover,
  .toolbarbutton-1:hover,
  #zen-sidebar-foot-buttons toolbarbutton:hover,
  #zen-sidebar-top-buttons toolbarbutton:hover {
    background: var(--livara-surface-raised) !important;
    color: var(--livara-text) !important;
    fill: var(--livara-text) !important;
  }

  toolbarbutton[checked="true"],
  toolbarbutton[open="true"],
  toolbarbutton[aria-pressed="true"],
  .subviewbutton[checked="true"],
  .tabbrowser-tab[selected="true"] .tab-background {
    background: var(--livara-primary) !important;
    color: var(--livara-on-primary) !important;
    fill: var(--livara-on-primary) !important;
  }

  #zen-sidebar-foot-buttons toolbarbutton[open="true"],
  #zen-sidebar-foot-buttons toolbarbutton[checked="true"],
  #zen-sidebar-top-buttons toolbarbutton[open="true"],
  #zen-sidebar-top-buttons toolbarbutton[checked="true"] {
    background: var(--livara-primary) !important;
    color: var(--livara-on-primary) !important;
    fill: var(--livara-on-primary) !important;
  }

  .tabbrowser-tab .tab-background {
    background: var(--livara-surface) !important;
    border-color: var(--livara-border) !important;
  }

  .tabbrowser-tab[selected="true"] .tab-label,
  .tabbrowser-tab[selected="true"] .tab-icon-image,
  .tabbrowser-tab[selected="true"] .tab-throbber {
    color: var(--livara-on-primary) !important;
    fill: var(--livara-on-primary) !important;
  }

  .tabbrowser-tab:not([selected="true"]) .tab-label,
  #sidebar-header,
  #sidebar-box {
    color: var(--livara-muted) !important;
  }

  #sidebar-splitter,
  #zen-sidebar-splitter,
  .sidebar-splitter {
    border-color: var(--livara-border) !important;
  }

  /* Zen compact mode controls geometry upstream; these rules only paint it. */
  :root[zen-compact-mode="true"] #zen-appcontent-navbar-wrapper,
  :root[zen-compact-mode-active="true"] #navigator-toolbox,
  :root[zen-has-hover="true"] #navigator-toolbox,
  :root[zen-user-show="true"] #navigator-toolbox,
  :root[has-popup-menu="true"] #navigator-toolbox {
    background: var(--livara-base) !important;
    color: var(--livara-text) !important;
  }

  /* Firefox panels, menus, downloads and the Zen three-dot panel. */
  panel,
  panelview,
  menupopup,
  menu,
  menuitem,
  .panel-subview-body,
  .subviewbutton,
  #PanelUI-popup,
  #appMenu-popup,
  #downloadsPanel,
  #downloadsListBox {
    background: var(--livara-base) !important;
    color: var(--livara-text) !important;
    border-color: var(--livara-border) !important;
  }
}
EOF
    }

    sync_nvim_palette() {
      local tmp
      tmp="$(mktemp)"
      jq -r 'to_entries | map("  " + .key + " = " + (.value | @json) + ",") | "return {\n" + join("\n") + "\n}\n"' \
        "$PALETTE_FILE" > "$tmp"
      write_atomic "$NVIM_THEME_PATH" < "$tmp"
      rm -f "$tmp"
    }

    hex_to_rgb() {
      local hex="${1#\#}"
      [[ "${#hex}" == 6 ]] || hex=000000
      printf '%d %d %d' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
    }

    hex_to_argb_decimal() {
      local hex="${1#\#}"
      [[ "${#hex}" == 6 ]] || hex=000000
      printf '%u' "$((16#FF${hex}))"
    }

    write_atomic() {
      local target="$1"
      local target_dir tmp
      target_dir="$(dirname "$target")"
      mkdir -p "$target_dir"
      tmp="$(mktemp "$target_dir/.livara-theme.XXXXXX")"
      cat > "$tmp"
      chmod 0644 "$tmp"
      mv -f -- "$tmp" "$target"
      }

    write_atomic "$THEME_DIR/palette.json" < "$PALETTE_FILE"

    sync_gtk_theme() {
      local dark_mode=false
      [[ "$PALETTE_VARIANT" == dark ]] && dark_mode=true
      local gtk_css gtk_settings
      for gtk_css in "$XDG_CONFIG_HOME/gtk-3.0/gtk.css" "$XDG_CONFIG_HOME/gtk-4.0/gtk.css"; do
        write_atomic "$gtk_css" <<EOF
/* Generated by Livara from palette.$PALETTE_VARIANT.json. */
window, .background, .view, textview, entry, list, row, popover, menu,
headerbar, .titlebar, button, .suggested-action, .destructive-action,
treeview, scrollbar, scale, switch, checkbutton, radiobutton {
  color: $(json_color text);
  background-color: $(json_color base);
  border-color: $(json_color overlay0);
}
headerbar, .titlebar, popover, menu, button, entry, list, row {
  background-color: $(json_color surface0);
}
button:hover, row:hover, .view:selected, textview text selection {
  background-color: $(json_color surface1);
  color: $(json_color text);
}
button:checked, .suggested-action, scale highlight, progressbar progress {
  background-color: $(json_color primary);
  color: $(json_color on_primary);
}
*:focus, entry:focus, button:focus {
  outline-color: $(json_color primary);
  border-color: $(json_color primary);
}
label:disabled, entry:disabled, button:disabled {
  color: $(json_color subtext0);
}
EOF
      done
      for gtk_settings in "$XDG_CONFIG_HOME/gtk-3.0/settings.ini" "$XDG_CONFIG_HOME/gtk-4.0/settings.ini"; do
        write_atomic "$gtk_settings" <<EOF
[Settings]
gtk-icon-theme-name=Livara-Kora
gtk-application-prefer-dark-theme=$dark_mode
gtk-enable-animations=true
EOF
      done
      log "GTK3/GTK4 CSS and preference files synchronized for $PALETTE_VARIANT mode"
    }

    sync_gtk_theme
    sync_browser_theme
    sync_nvim_palette

    sync_fastfetch_cat() {
      [[ -s "$FASTFETCH_CAT_SOURCE" ]] || {
        log "Fastfetch cat source not available: $FASTFETCH_CAT_SOURCE"
        return 0
      }
      command -v convert >/dev/null 2>&1 || {
        log "Fastfetch cat skipped: ImageMagick convert is unavailable"
        return 0
      }

      local color source_hash signature current_signature
      local png_tmp="$FASTFETCH_CAT_OUTPUT.tmp.$$"
      local state_tmp="$FASTFETCH_CAT_STATE.tmp.$$"
      color="$(json_color primary blue)"
      [[ "$color" =~ ^#[[:xdigit:]]{6}$ ]] || color="#7bb7ff"
      source_hash="$(sha256sum "$FASTFETCH_CAT_SOURCE" | cut -d' ' -f1)"
      signature="$color $source_hash"
      current_signature=""
      [[ -s "$FASTFETCH_CAT_STATE" ]] && current_signature="$(<"$FASTFETCH_CAT_STATE")"
      if [[ -s "$FASTFETCH_CAT_OUTPUT" && "$current_signature" == "$signature" ]]; then
        return 0
      fi
      if ! convert "$FASTFETCH_CAT_SOURCE" -alpha on -channel RGB -fill "$color" -colorize 100% +channel -strip "PNG32:$png_tmp" >/dev/null 2>&1; then
        rm -f "$png_tmp" "$state_tmp"
        log "Fastfetch cat colorization failed"
        return 0
      fi
      chmod 0644 "$png_tmp"
      printf '%s\n' "$signature" > "$state_tmp"
      chmod 0644 "$state_tmp"
      mv -f "$png_tmp" "$FASTFETCH_CAT_OUTPUT"
      mv -f "$state_tmp" "$FASTFETCH_CAT_STATE"
      log "Fastfetch cat synchronized: $FASTFETCH_CAT_OUTPUT"
    }

    sync_fastfetch_config() {
      local tmp primary text logo
      primary="$(json_color primary)"
      text="$(json_color text)"
      logo="$FASTFETCH_CAT_OUTPUT"
      tmp="$(mktemp)"
      jq -n --arg primary "$primary" --arg text "$text" --arg logo "$logo" '
        {
          "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
          logo: {source: $logo, type: "kitty-direct", width: 16, height: 9,
            padding: {top: 4, right: 3, left: 3}},
          display: {separator: " ", color: {keys: $primary, title: $primary, output: $text}},
          modules: [
            {type: "custom", key: "╭───────────╮", keyColor: $primary},
            {type: "title", key: "│  user    │", format: "{user-name}", keyColor: $primary},
            {type: "title", key: "│ 󰇅 hname   │", format: "{host-name}", keyColor: $primary},
            {type: "uptime", key: "│ 󰅐 uptime  │", keyColor: $primary},
            {type: "os", key: "│ {icon} distro  │", keyColor: $primary},
            {type: "kernel", key: "│  kernel  │", keyColor: $primary},
            {type: "wm", key: "│  wm      │", keyColor: $primary},
            {type: "de", key: "│ 󰇄 desktop │", keyColor: $primary},
            {type: "terminal", key: "│  term    │", keyColor: $primary},
            {type: "shell", key: "│  shell   │", keyColor: $primary},
            {type: "cpu", key: "│ 󰍛 cpu     │", format: "{name}", keyColor: $primary},
            {type: "gpu", key: "│ 󰯦 gpu     │", format: "{name} ", detectionMethod: "auto", keyColor: $primary},
            {type: "disk", key: "│ 󰉉 disk    │", folders: ["/"], format: "{size-used} / {size-total}", keyColor: $primary},
            {type: "memory", key: "│  memory  │", keyColor: $primary},
            {type: "custom", key: "├───────────┤", keyColor: $primary},
            {type: "colors", key: "│  colors  │", symbol: "circle", keyColor: $primary},
            {type: "custom", key: "╰───────────╯", keyColor: $primary}
          ]
        }
      ' > "$tmp"
      write_atomic "$THEME_DIR/fastfetch.jsonc" < "$tmp"
      rm -f "$tmp"
    }

    sync_fastfetch_cat
    sync_fastfetch_config

    sync_wezterm_scheme() {
      write_atomic "$WEZTERM_THEME" <<EOF
[colors]
foreground = "$(json_color text)"
background = "$(json_color base)"
cursor_bg = "$(json_color primary)"
cursor_fg = "$(json_color base)"
selection_fg = "$(json_color text)"
selection_bg = "$(json_color surface1)"
quick_select_label_bg = "$(json_color primary)"
quick_select_label_fg = "$(json_color on_primary)"
input_selector_label_bg = "$(json_color secondary)"
input_selector_label_fg = "$(json_color on_secondary)"
launcher_label_bg = "$(json_color tertiary)"
launcher_label_fg = "$(json_color on_tertiary)"
ansi = ["$(json_color base)", "$(json_color red)", "$(json_color green)", "$(json_color yellow)", "$(json_color blue)", "$(json_color mauve)", "$(json_color teal)", "$(json_color text)"]
brights = ["$(json_color surface1)", "$(json_color red)", "$(json_color green)", "$(json_color yellow)", "$(json_color blue)", "$(json_color mauve)", "$(json_color teal)", "$(json_color text)"]
EOF
      log "WezTerm scheme synchronized: $WEZTERM_THEME"
    }

    sync_btop_theme() {
      write_atomic "$BTOP_THEME" <<EOF
# Livara btop theme generated from the active palette.
theme[main_bg]="$(json_color base)"
theme[main_fg]="$(json_color text)"
theme[title]="$(json_color text)"
theme[hi_fg]="$(json_color primary)"
theme[selected_bg]="$(json_color primary)"
theme[selected_fg]="$(json_color on_primary)"
theme[inactive_fg]="$(json_color subtext0)"
theme[graph_text]="$(json_color secondary)"
theme[meter_bg]="$(json_color surface1)"
theme[proc_misc]="$(json_color tertiary)"
theme[cpu_box]="$(json_color primary)"
theme[mem_box]="$(json_color secondary)"
theme[net_box]="$(json_color tertiary)"
theme[proc_box]="$(json_color blue)"
theme[div_line]="$(json_color overlay0)"
theme[temp_start]="$(json_color green)"
theme[temp_mid]="$(json_color yellow)"
theme[temp_end]="$(json_color red)"
theme[cpu_start]="$(json_color green)"
theme[cpu_mid]="$(json_color primary)"
theme[cpu_end]="$(json_color red)"
theme[free_end]="$(json_color green)"
theme[free_mid]="$(json_color secondary)"
theme[free_start]="$(json_color red)"
theme[cached_start]="$(json_color green)"
theme[cached_mid]="$(json_color secondary)"
theme[cached_end]="$(json_color red)"
theme[available_start]="$(json_color red)"
theme[available_mid]="$(json_color yellow)"
theme[available_end]="$(json_color green)"
theme[used_start]="$(json_color green)"
theme[used_mid]="$(json_color yellow)"
theme[used_end]="$(json_color red)"
theme[download_start]="$(json_color green)"
theme[download_mid]="$(json_color secondary)"
theme[download_end]="$(json_color red)"
theme[upload_start]="$(json_color green)"
theme[upload_mid]="$(json_color secondary)"
theme[upload_end]="$(json_color red)"
theme[process_start]="$(json_color subtext1)"
theme[process_mid]="$(json_color primary)"
theme[process_end]="$(json_color tertiary)"
EOF
      mkdir -p "$(dirname "$BTOP_CONFIG")"
      if [[ -s "$BTOP_CONFIG" ]]; then
        local config_tmp
        config_tmp="$(mktemp)"
        awk '
          BEGIN { replaced = 0 }
          /^color_theme[[:space:]]*=/ { print "color_theme = \"Livara\""; replaced = 1; next }
          { print }
          END { if (!replaced) print "color_theme = \"Livara\"" }
        ' "$BTOP_CONFIG" > "$config_tmp"
        write_atomic "$BTOP_CONFIG" < "$config_tmp"
        rm -f "$config_tmp"
      else
        printf 'color_theme = "Livara"\n' | write_atomic "$BTOP_CONFIG"
      fi
      if pgrep -x btop >/dev/null 2>&1; then
        pkill -USR2 -x btop || true
        log "btop theme reloaded through SIGUSR2"
      fi
    }

    sync_wezterm_scheme
    sync_btop_theme

    sync_intellij_scheme() {
      [[ -s "$MATUGEN_CONFIG" ]] || return 0
      command -v matugen >/dev/null 2>&1 || {
        log "IntelliJ scheme skipped: Matugen is unavailable"
        return 0
      }
      local primary
      primary="$(json_color primary blue)"
      [[ "$primary" =~ ^#[[:xdigit:]]{6}$ ]] || primary="#7bb7ff"
      mkdir -p "$(dirname "$INTELLIJ_SCHEME")"
      if ! matugen color hex "$primary" -m dark >/dev/null 2>&1; then
        log "IntelliJ scheme generation failed"
        return 0
      fi
      if [[ ! -s "$INTELLIJ_SCHEME" ]] || ! grep -qE '^<scheme[[:space:]]+name=' "$INTELLIJ_SCHEME"; then
        log "IntelliJ scheme rejected because the generated file is not a valid scheme"
        return 0
      fi
      log "IntelliJ scheme generated: $INTELLIJ_SCHEME"
    }

    intellij_linked=false
    android_studio_linked=false
    intellij_ui_theme_installed=false
    android_studio_ui_theme_installed=false
    intellij_ui_theme_applied=false
    android_studio_ui_theme_applied=false

    link_intellij_scheme() {
      [[ -s "$INTELLIJ_SCHEME" ]] || return 0
      local config_root product_root product_name colors_dir target current
      for config_root in "${INTELLIJ_CONFIG_ROOTS[@]}"; do
        [[ -n "$config_root" && -d "$config_root" ]] || continue
        while IFS= read -r -d "" product_root; do
          product_name="$(basename "$product_root")"
          colors_dir="$product_root/colors"
          mkdir -p "$colors_dir"
          target="$colors_dir/Matugen-Dark.icls"
          if [[ -L "$target" ]]; then
            current="$(readlink -f "$target" 2>/dev/null || true)"
            if [[ "$current" != "$INTELLIJ_SCHEME" ]]; then
              rm -f "$target"
            fi
          elif [[ -e "$target" ]]; then
            continue
          fi
          if [[ ! -e "$target" ]]; then
            ln -s "$INTELLIJ_SCHEME" "$target"
          fi
          case "$product_name" in
            IntelliJIdea*) intellij_linked=true ;;
            AndroidStudio*) android_studio_linked=true ;;
          esac
        done < <(if [[ "$config_root" == */IntelliJIdea* || "$config_root" == */AndroidStudio* ]]; then printf '%s\0' "$config_root"; else find "$config_root" -mindepth 1 -maxdepth 1 -type d \( -name 'IntelliJIdea*' -o -name 'AndroidStudio*' \) -print0 2>/dev/null; fi)
      done
    }

    install_intellij_ui_theme() {
      [[ -d "$INTELLIJ_THEME_PLUGIN" && -s "$INTELLIJ_THEME_PLUGIN/META-INF/plugin.xml" ]] || {
        log "IDE UI theme skipped: LIVARA_IDE_THEME_PLUGIN is unavailable"
        return 0
      }
      local theme_plugin="$THEME_DIR/intellij/LivaraTheme"
      mkdir -p "$theme_plugin/META-INF" "$theme_plugin/theme"
      cp -f "$INTELLIJ_THEME_PLUGIN/META-INF/plugin.xml" "$theme_plugin/META-INF/plugin.xml"
      write_atomic "$theme_plugin/theme/Livara.theme.json" <<EOF
{
  "name": "Livara Dark",
  "dark": true,
  "author": "Joaoferraz-byte",
  "editorScheme": "/theme/Matugen-Dark.xml",
  "ui": {
    "*": {
      "background": "$(json_color base)",
      "foreground": "$(json_color text)"
    },
    "Panel.background": "$(json_color base)",
    "ToolWindow.background": "$(json_color mantle)",
    "EditorTabs.background": "$(json_color mantle)",
    "EditorTabs.selectedBackground": "$(json_color surface0)",
    "TabbedPane.background": "$(json_color mantle)",
    "TabbedPane.selectedBackground": "$(json_color surface0)",
    "Button.background": "$(json_color surface0)",
    "Button.hoverBackground": "$(json_color surface1)",
    "Button.foreground": "$(json_color text)",
    "Label.foreground": "$(json_color text)",
    "TextField.background": "$(json_color surface0)",
    "TextField.foreground": "$(json_color text)",
    "List.background": "$(json_color base)",
    "List.foreground": "$(json_color text)",
    "Tree.background": "$(json_color base)",
    "Tree.foreground": "$(json_color text)",
    "Link.activeForeground": "$(json_color blue)",
    "ProgressBar.foreground": "$(json_color blue)",
    "ProgressBar.background": "$(json_color surface1)",
    "Component.focusColor": "$(json_color blue)",
    "Borders.color": "$(json_color surface1)",
    "ScrollBar.thumbColor": "$(json_color overlay0)"
  }
}
EOF
      [[ -s "$INTELLIJ_SCHEME" ]] && cp -f "$INTELLIJ_SCHEME" "$theme_plugin/theme/Matugen-Dark.xml"
      if ! jq -e '.name == "Livara Dark" and .dark == true and (.ui | type == "object")' "$theme_plugin/theme/Livara.theme.json" >/dev/null 2>&1; then
        log "IDE UI theme rejected because the generated JSON is invalid"
        return 0
      fi
      local data_root product_root product_name target current theme_id
      theme_id="$(sed -n 's/.*themeProvider[[:space:]]\+id="\([^"]*\)".*/\1/p' "$theme_plugin/META-INF/plugin.xml" | head -n1)"
      [[ -n "$theme_id" ]] || {
        log "IDE UI theme rejected because plugin.xml has no themeProvider id"
        return 0
      }
      install_theme_plugin() {
        local product_root product_name plugin_root target current
        product_root="$1"
        product_name="$(basename "$product_root")"
        plugin_root="$product_root"
        target="$plugin_root/LivaraTheme"
        mkdir -p "$plugin_root"
        if [[ -L "$target" ]]; then
          current="$(readlink -f "$target" 2>/dev/null || true)"
          [[ "$current" == "$theme_plugin" ]] || rm -f "$target"
        elif [[ -e "$target" ]]; then
          return 0
        fi
        [[ -e "$target" ]] || ln -s "$theme_plugin" "$target"
        case "$product_name" in
          IntelliJIdea*) intellij_ui_theme_installed=true ;;
          AndroidStudio*) android_studio_ui_theme_installed=true ;;
        esac
      }
      select_theme_in_config() {
        local config_root="$1"
        local laf="$config_root/options/laf.xml"
        local laf_line="    <laf class-name=\"com.intellij.ide.ui.laf.darcula.DarculaLaf\" themeId=\"$theme_id\" />"
        mkdir -p "$(dirname "$laf")"
        if [[ ! -e "$laf" ]]; then
          write_atomic "$laf" <<EOF
<application>
  <component name="LafManager" autodetect="false">
$laf_line
  </component>
</application>
EOF
        elif [[ ! -L "$laf" ]]; then
          local laf_tmp="$laf.tmp.$$"
          awk -v replacement="$laf_line" '
            BEGIN { inside = 0; component = 0; selected = 0 }
            /<component[[:space:]]+name="LafManager"/ { inside = 1; component = 1; print; next }
            inside && /<laf[[:space:]]/ { print replacement; selected = 1; next }
            inside && /<\/component>/ && !selected { print replacement; selected = 1 }
            inside && /<\/component>/ { inside = 0 }
            { print }
          ' "$laf" > "$laf_tmp"
          if ! grep -q 'name="LafManager"' "$laf_tmp"; then
            sed -i "/<\/application>/i\\  <component name=\"LafManager\" autodetect=\"false\">\\n$laf_line\\n  </component>" "$laf_tmp"
          fi
          chmod 0644 "$laf_tmp"
          mv -f "$laf_tmp" "$laf"
        fi
        case "$(basename "$config_root")" in
          IntelliJIdea*) intellij_ui_theme_applied=true ;;
          AndroidStudio*) android_studio_ui_theme_applied=true ;;
        esac
      }

      for data_root in "${INTELLIJ_DATA_ROOTS[@]}"; do
        [[ -n "$data_root" && -d "$data_root" ]] || continue
        while IFS= read -r -d "" product_root; do
          install_theme_plugin "$product_root"
        done < <(if [[ "$data_root" == */IntelliJIdea* || "$data_root" == */AndroidStudio* ]]; then
          printf '%s\0' "$data_root"
        else
          find "$data_root" -mindepth 1 -maxdepth 1 -type d \( -name 'IntelliJIdea*' -o -name 'AndroidStudio*' \) -print0 2>/dev/null
        fi)
      done

      for config_root in "${INTELLIJ_CONFIG_ROOTS[@]}"; do
        [[ -d "$config_root" ]] || continue
        while IFS= read -r -d "" product_root; do
          local plugin_product_root
          product_name="$(basename "$product_root")"
          case "$product_name" in
            IntelliJIdea*)
              plugin_product_root="${IDEA_DATA_PATH:-$XDG_DATA_HOME/JetBrains}/$product_name"
              ;;
            AndroidStudio*)
              plugin_product_root="$ANDROID_STUDIO_DATA_PATH/$product_name"
              ;;
          esac
          if [[ -n "${plugin_product_root:-}" ]]; then
            install_theme_plugin "$plugin_product_root"
            [[ -e "$plugin_product_root/LivaraTheme" ]] && select_theme_in_config "$product_root"
          fi
        done < <(if [[ "$config_root" == */IntelliJIdea* || "$config_root" == */AndroidStudio* ]]; then
          printf '%s\0' "$config_root"
        else
          find "$config_root" -mindepth 1 -maxdepth 1 -type d \( -name 'IntelliJIdea*' -o -name 'AndroidStudio*' \) -print0 2>/dev/null
        fi)
      done
    }

    sync_intellij_scheme
    link_intellij_scheme
    install_intellij_ui_theme


    sync_hydra_theme_root() {
      local root="$1"
      mkdir -p "$root"
      local screenshot_name="screenshot.png"
      rm -f "$root"/screenshot.*
      if [[ -n "$HYDRA_SCREENSHOT_SOURCE" ]]; then
        if [[ ! -s "$HYDRA_SCREENSHOT_SOURCE" ]]; then
          log "Hydra screenshot skipped because the configured file is missing: $HYDRA_SCREENSHOT_SOURCE"
        else
          local screenshot_extension="${HYDRA_SCREENSHOT_SOURCE##*.}"
          screenshot_extension="${screenshot_extension,,}"
          case "$screenshot_extension" in
            png|webp|jpg|jpeg|avif|heic|heif)
              screenshot_name="screenshot.$screenshot_extension"
              cp -f "$HYDRA_SCREENSHOT_SOURCE" "$root/$screenshot_name"
              if [[ "$root" == "$HYDRA_THEME_DIR" ]]; then
                HYDRA_SCREENSHOT="$root/$screenshot_name"
              fi
              ;;
            *) log "Hydra screenshot skipped because its extension is unsupported: $HYDRA_SCREENSHOT_SOURCE" ;;
          esac
        fi
      fi
      write_atomic "$root/theme.css" <<EOF
:root {
  --livara-background: $(json_color base);
  --livara-surface: $(json_color surface0);
  --livara-surface-raised: $(json_color surface1);
  --livara-text: $(json_color text);
  --livara-muted: $(json_color subtext0);
  --livara-primary: $(json_color blue);
  --livara-secondary: $(json_color teal);
  --livara-error: $(json_color red);
}

html, body, #root { background: var(--livara-background) !important; color: var(--livara-text) !important; }
button, input, select, textarea, [role="button"] { background: var(--livara-surface) !important; color: var(--livara-text) !important; border-color: $(json_color overlay0) !important; }
button:hover, [role="button"]:hover { background: var(--livara-surface-raised) !important; border-color: var(--livara-primary) !important; }
a, [data-state="active"], .active { color: var(--livara-primary) !important; }
.error, [data-variant="error"] { color: var(--livara-error) !important; }
EOF
      write_atomic "$root/README.txt" <<EOF
Livara Hydra theme generated from the active shell palette.

Theme directory: $HYDRA_THEME_ID
CSS file: theme.css
Screenshot file: $screenshot_name
Friend code configured: $([[ -n "$HYDRA_FRIEND_CODE" ]] && printf true || printf false)
Submission readiness: $([[ -n "$HYDRA_FRIEND_CODE" && -s "$HYDRA_SCREENSHOT" ]] && printf true || printf false)

Hydra stores local themes in its LevelDB database and does not discover this
directory automatically in Settings > Appearance. Use Create theme in Hydra,
open the editor for the new theme, and replace its CSS with this theme.css.
EOF
    }

    sync_hydra_theme() {
      sync_hydra_theme_root "$HYDRA_THEME_DIR"
      sync_hydra_theme_root "$HYDRA_THEME_EXPORT_DIR"
      if [[ -n "$HYDRA_FRIEND_CODE" && -s "$HYDRA_SCREENSHOT" ]]; then
        log "Hydra theme export ready for review: $HYDRA_THEME_EXPORT_DIR"
      else
        log "Hydra theme source generated; friend code and screenshot are still required: $HYDRA_THEME_EXPORT_DIR"
      fi
    }

    sync_hydra_theme

    sync_nuclear_theme_root() {
      local data_home="$1"
      local theme_path="$data_home/themes/Livara.json"
      local settings_path="$data_home/settings.json"
      mkdir -p "$(dirname "$theme_path")"
      write_atomic "$theme_path" <<EOF
{
  "version": 2,
  "name": "Livara",
  "dark": {
    "background": "$(json_color base)",
    "foreground": "$(json_color text)",
    "muted": "$(json_color mantle)",
    "muted-foreground": "$(json_color subtext0)",
    "card": "$(json_color surface0)",
    "card-foreground": "$(json_color text)",
    "popover": "$(json_color surface0)",
    "popover-foreground": "$(json_color text)",
    "input": "$(json_color surface1)",
    "input-foreground": "$(json_color text)",
    "primary": "$(json_color blue)",
    "primary-foreground": "$(json_color base)",
    "topbar": "$(json_color mantle)",
    "topbar-foreground": "$(json_color text)",
    "bottombar": "$(json_color mantle)",
    "bottombar-foreground": "$(json_color text)",
    "border": "$(json_color overlay0)",
    "ring": "$(json_color blue)",
    "radius-md": "8px",
    "radius-lg": "12px"
  }
}
EOF
      jq -e '.version == 2 and .name == "Livara" and (.dark | type == "object")' "$theme_path" >/dev/null
      if pgrep -x nuclear >/dev/null 2>&1 || pgrep -x Nuclear >/dev/null 2>&1 || pgrep -x nuclear-music-player >/dev/null 2>&1 || pgrep -x com.nuclearplayer.Nuclear >/dev/null 2>&1; then
        log "Nuclear is running; active theme state was not rewritten: $data_home"
        return 0
      fi
      if [[ -s "$settings_path" ]] && ! jq -e 'type == "object"' "$settings_path" >/dev/null 2>&1; then
        log "Nuclear settings are invalid; active theme state was not rewritten: $settings_path"
        return 0
      fi
      local settings_tmp="$settings_path.tmp.$$"
      if [[ -s "$settings_path" ]]; then
        jq --arg theme_path "$NUCLEAR_THEME_ID" --arg dark_mode "$NUCLEAR_DARK_MODE" \
          '."core.theme.active.type" = "advanced" | ."core.theme.active.id" = $theme_path | ."core.theme.dark" = ($dark_mode == "dark")' \
          "$settings_path" > "$settings_tmp"
      else
        jq -n --arg theme_path "$NUCLEAR_THEME_ID" --arg dark_mode "$NUCLEAR_DARK_MODE" \
          '{"core.theme.active.type":"advanced","core.theme.active.id":$theme_path,"core.theme.dark":($dark_mode == "dark")}' \
          > "$settings_tmp"
      fi
      chmod 0644 "$settings_tmp"
      mv -f "$settings_tmp" "$settings_path"
      log "Nuclear Livara theme selected through its JSON settings store: $data_home"
    }

    sync_nuclear_theme() {
      local data_home
      local found=false
      local seen="|"
      for data_home in "${NUCLEAR_DATA_ROOTS[@]}"; do
        [[ -n "$data_home" ]] || continue
        [[ "$seen" == *"|$data_home|"* ]] && continue
        seen+="$data_home|"
        if [[ -d "$data_home" || "$data_home" == "${NUCLEAR_DATA_ROOTS[0]}" || -d "${data_home%/data/com.nuclearplayer}" ]]; then
          sync_nuclear_theme_root "$data_home"
          found=true
        fi
      done
      if [[ "$found" != true ]]; then
        sync_nuclear_theme_root "$NUCLEAR_DATA_HOME"
      fi
    }

    sync_nuclear_theme

    sync_foliate_theme_root() {
      local root="$1"
      [[ -n "$root" ]] || return 0
      local theme="$root/themes/livara.json"
      mkdir -p "$(dirname "$theme")"
      write_atomic "$theme" <<EOF
{
  "label": "Livara",
  "light": {
    "fg": "$(json_color text)",
    "bg": "$(json_color base)",
    "link": "$(json_color blue)"
  },
  "dark": {
    "fg": "$(json_color text)",
    "bg": "$(json_color base)",
    "link": "$(json_color blue)"
  }
}
EOF
    }

    sync_foliate_theme_root "$FOLIATE_CONFIG_HOME"
    [[ -d "$HOME/.var/app/com.github.johnfactotum.Foliate" ]] && sync_foliate_theme_root "$FOLIATE_FLATPAK_HOME"

    # Foliate is a GTK4/libadwaita application, but its reader appearance is
    # an application-level JSON theme consumed by the WebKit reader. The
    # selection key belongs to Foliate's GSettings schema
    # com.github.johnfactotum.Foliate (relocatable child path viewer/view,
    # key 'theme'). Native and Flatpak installations have separate settings
    # backends, so never query the host schema on behalf of the Flatpak sandbox.
    #
    # On NixOS the Foliate GSettings schema is typically NOT installed in the
    # host XDG_DATA_DIRS (it lives inside the Foliate package or Flatpak
    # runtime), so `gsettings` will fail with "No such schema". Use `dconf`
    # instead, which writes directly to the dconf database without requiring
    # any schema to be installed. For the Flatpak sandbox, GSettings uses a
    # keyfile backend at ~/.var/app/.../config/glib-2.0/settings/keyfile;
    # write to it directly since the sandbox is not running during activation.
    foliate_dconf_path="/com/github/johnfactotum/Foliate/viewer/view/theme"
    foliate_keyfile_section="com/github/johnfactotum/Foliate/viewer/view"
    sync_foliate_theme_selection() {
      local selected=false

      # Native: write directly to the dconf database. dconf does not need
      # the GSettings schema to be installed on the host.
      if command -v dconf >/dev/null 2>&1; then
        if dconf write "$foliate_dconf_path" "'livara.json'" >/dev/null 2>&1; then
          log "Foliate native reader theme selected: livara.json"
          selected=true
        else
          log "Foliate native reader theme generated; dconf write failed"
        fi
      fi

      # Flatpak: GSettings uses a keyfile backend inside the sandbox. The
      # keyfile is at ~/.var/app/.../config/glib-2.0/settings/keyfile and
      # uses dconf-style paths as section headers. Write to it directly so
      # the setting persists even when the Flatpak is not running.
      if [[ "$selected" != true ]] &&
         [[ -d "$HOME/.var/app/com.github.johnfactotum.Foliate" ]]; then
        local keyfile="$HOME/.var/app/com.github.johnfactotum.Foliate/config/glib-2.0/settings/keyfile"
        mkdir -p "$(dirname "$keyfile")"
        touch "$keyfile"
        # Rewrite the keyfile: replace any existing theme= line in the
        # target section, or add the section + key if absent. GVariant
        # strings are single-quoted.
        awk -v section="$foliate_keyfile_section" '
          BEGIN { in_section = 0; found = 0 }
          /^\[/ {
            if (in_section && !found) { print "theme='\''livara.json'\''"; found = 1 }
            in_section = ($0 == "[" section "]")
          }
          in_section && /^theme=/ { print "theme='\''livara.json'\''"; found = 1; next }
          { print }
          END { if (in_section && !found) { print "theme='\''livara.json'\''"; found = 1 } }
        ' "$keyfile" > "$keyfile.tmp.$$"
        # Ensure the section exists even if it was not present originally.
        if ! grep -q "^\[$foliate_keyfile_section\]$" "$keyfile.tmp.$$"; then
          printf '\n[%s]\ntheme='\''livara.json'\''\n' "$foliate_keyfile_section" >> "$keyfile.tmp.$$"
        fi
        mv -f "$keyfile.tmp.$$" "$keyfile"
        chmod 0644 "$keyfile"
        log "Foliate Flatpak reader theme selected: livara.json"
        selected=true
      fi

      if [[ "$selected" != true ]]; then
        log "Foliate reader JSON theme generated; no native dconf or Flatpak keyfile backend available"
      fi
    }
    sync_foliate_theme_selection

    # Okular follows KDE's color-scheme preference, not qt6ct's palette alone.
    # The active shell owns the generated .colors file; this adapter selects it in the KDE
    # config without rewriting unrelated KDE application preferences.
    sync_kde_color_scheme() {
      local kdeglobals="$XDG_CONFIG_HOME/kdeglobals"
      local scheme_dir="${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes"
      local scheme=""
      if [[ -s "$scheme_dir/DankMatugenDark.colors" ]]; then
        scheme="DankMatugenDark"
      elif [[ -s "$scheme_dir/DankMatugen.colors" ]]; then
        scheme="DankMatugen"
      fi
      [[ -n "$scheme" ]] || {
        log "KDE color scheme not selected: generated .colors file is not available yet"
        return 0
      }

      mkdir -p "$(dirname "$kdeglobals")"
      if [[ -f "$kdeglobals" ]]; then
        if grep -q '^\[General\]$' "$kdeglobals"; then
          if sed -n '/^\[General\]$/,/^\[/p' "$kdeglobals" | grep -q '^ColorScheme='; then
            sed -i "/^\[General\]$/,/^\[/ s/^ColorScheme=.*/ColorScheme=$scheme/" "$kdeglobals"
          else
            sed -i "/^\[General\]$/a ColorScheme=$scheme" "$kdeglobals"
          fi
        else
          printf '\n[General]\nColorScheme=%s\n' "$scheme" >> "$kdeglobals"
        fi
      else
        printf '[General]\nColorScheme=%s\n' "$scheme" > "$kdeglobals"
      fi
      log "KDE color scheme selected: $scheme"
    }
    sync_kde_color_scheme

    sync_freesm_theme_root() {
      local root="$1"
      [[ -n "$root" ]] || return 0
      local theme_root="$root/themes/livara"
      local manifest="$theme_root/theme.json"
      local qss="$theme_root/themeStyle.css"
      mkdir -p "$theme_root"

      write_atomic "$manifest" <<EOF
{
  "name": "Livara",
  "widgets": "Fusion",
  "qssFilePath": "themeStyle.css",
  "colors": {
    "Window": "$(json_color base)",
    "WindowText": "$(json_color text)",
    "Base": "$(json_color base)",
    "AlternateBase": "$(json_color mantle)",
    "ToolTipBase": "$(json_color mantle)",
    "ToolTipText": "$(json_color text)",
    "Text": "$(json_color text)",
    "Button": "$(json_color surface0)",
    "ButtonText": "$(json_color text)",
    "BrightText": "$(json_color red)",
    "Link": "$(json_color blue)",
    "Highlight": "$(json_color blue)",
    "HighlightedText": "$(json_color crust)",
    "fadeColor": "$(json_color base)",
    "fadeAmount": 0.5
  },
  "logColors": {
    "Launcher": "$(json_color mauve)",
    "Error": "$(json_color red)",
    "Warning": "$(json_color yellow)",
    "Debug": "$(json_color green)",
    "FatalHighlight": "$(json_color red)",
    "Fatal": "$(json_color crust)"
  }
}
EOF
      write_atomic "$qss" <<EOF
/* Livara Freesm Launcher theme; generated from the active wallpaper. */
QWidget { background-color: $(json_color base); color: $(json_color text); }
QToolTip { background-color: $(json_color mantle); color: $(json_color text); border: 1px solid $(json_color blue); }
QPushButton, QComboBox, QSpinBox, QDoubleSpinBox { background-color: $(json_color surface0); color: $(json_color text); border: 1px solid $(json_color overlay0); border-radius: 4px; padding: 4px 8px; }
QPushButton:hover, QComboBox:hover, QSpinBox:hover, QDoubleSpinBox:hover { background-color: $(json_color surface1); border-color: $(json_color blue); }
QPushButton:pressed, QPushButton:checked, QAbstractButton:checked { background-color: $(json_color blue); color: $(json_color crust); }
QLineEdit, QTextEdit, QPlainTextEdit, QListView, QTreeView, QTableView { background-color: $(json_color surface0); color: $(json_color text); border: 1px solid $(json_color overlay0); selection-background-color: $(json_color blue); selection-color: $(json_color crust); }
QListView::item:hover, QTreeView::item:hover, QTableView::item:hover { background-color: $(json_color surface1); }
QListView::item:selected, QTreeView::item:selected, QTableView::item:selected { background-color: $(json_color blue); color: $(json_color crust); }
QHeaderView::section { background-color: $(json_color mantle); color: $(json_color text); border: 1px solid $(json_color overlay0); padding: 4px; }
QGroupBox { border: 1px solid $(json_color overlay0); margin-top: 8px; padding-top: 8px; }
QSlider::groove:horizontal, QProgressBar { background-color: $(json_color surface0); border: 1px solid $(json_color overlay0); }
QSlider::handle:horizontal, QProgressBar::chunk { background-color: $(json_color blue); }
QScrollBar:vertical, QScrollBar:horizontal { background-color: $(json_color mantle); }
QScrollBar::handle:vertical, QScrollBar::handle:horizontal { background-color: $(json_color overlay0); border-radius: 4px; }
QCheckBox::indicator:checked, QRadioButton::indicator:checked { background-color: $(json_color blue); border: 1px solid $(json_color sapphire); }
EOF

      # Prism/Freesm reads ApplicationTheme from its launcher-root INI and
      # reloads it only after restart. Prefer the canonical Prism filename;
      # otherwise update an existing launcher config without touching unrelated
      # INI files. A missing config is created only for a canonical Prism root.
      local config=""
      if [[ "${root##*/}" == "PrismLauncher" ]]; then
        config="$root/prismlauncher.cfg"
        if [[ ! -e "$config" ]]; then
          write_atomic "$config" <<CFG
[General]
ApplicationTheme=livara
CFG
        fi
      else
        while IFS= read -r -d "" candidate; do
          if grep -q '^ApplicationTheme=' "$candidate"; then
            config="$candidate"
            break
          fi
        done < <(find "$root" -maxdepth 1 -type f \( -name '*.cfg' -o -name '*.ini' \) -print0 2>/dev/null)
      fi
      if [[ -n "$config" ]]; then
        if grep -q '^ApplicationTheme=' "$config"; then
          sed -i 's/^ApplicationTheme=.*/ApplicationTheme=livara/' "$config"
        elif grep -q '^\[General\]$' "$config"; then
          sed -i '/^\[General\]$/a ApplicationTheme=livara' "$config"
        fi
      fi
    }

    sync_freesm_theme_root "$FREESM_DATA_HOME"
    [[ -d "$HOME/.var/app/org.freesmlauncher.FreesmLauncher" ]] && sync_freesm_theme_root "$FREESM_FLATPAK_HOME"

    sync_xournal_theme() {
      local root="$1"
      local palette="$root/palettes/$XOURNAL_PALETTE_NAME"
      local palette_tmp
      mkdir -p "$(dirname "$palette")"
      palette_tmp="$(mktemp "$(dirname "$palette")/.livara-xournal.XXXXXX")"
      {
        local seen=""

        add_unique_color() {
          local rgb
          rgb="$(hex_to_rgb "$(json_color "$1" "${3:-base}")")"
          if [[ "|$seen|" == *"|$rgb|"* ]]; then
            return 0
          fi
          seen="${seen:+$seen|}$rgb"
          printf '%s %s\n' "$rgb" "$2"
        }

        printf '%s\n' 'GIMP Palette' 'Name: Livara' 'Columns: 4' '#'
        # GPL has no aliases: keep the first semantic role for equal RGB values.
        # Material roles are application-surface semantics, not drawing colors;
        # wallpaper-derived primary/container/secondary/tertiary roles often
        # collapse to the same RGB value. Keep stable drawing roles only and
        # let the RGB guard below enforce the contract for future palettes.
        add_unique_color text Text
        add_unique_color subtext0 Muted
        add_unique_color overlay1 Outline
        add_unique_color blue Blue
        add_unique_color sapphire Sapphire
        add_unique_color teal Teal
        add_unique_color green Green
        add_unique_color yellow Yellow
        add_unique_color peach Orange
        add_unique_color mauve Purple
        add_unique_color red Red
      } | write_atomic "$palette_tmp"

      if grep -Eiq '[[:space:]](Primary|Primary Container|Secondary|Tertiary|Error|Crust|Mantle)$' "$palette_tmp"; then
        rm -f "$palette_tmp"
        log "Xournal palette rejected: application role leaked into drawing colors"
        return 1
      fi
      if ! awk 'NF >= 3 && $1 ~ /^[0-9]+$/ { key = $1 FS $2 FS $3; if (++seen[key] > 1) duplicate = 1 } END { exit duplicate }' "$palette_tmp"; then
        rm -f "$palette_tmp"
        log "Xournal palette rejected: duplicate RGB entries"
        return 1
      fi
      mv -f "$palette_tmp" "$palette"

      local canvas_color grid_color selection_color canvas_argb selection_argb
      canvas_color="$(json_color mantle)"
      grid_color="$(json_color overlay0)"
      selection_color="$(json_color blue)"
      canvas_argb="$(hex_to_argb_decimal "$canvas_color")"
      selection_argb="$(hex_to_argb_decimal "$selection_color")"
      local settings="$root/settings.xml"
      if [[ ! -e "$settings" ]]; then
        write_atomic "$settings" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<settings>
  <property name="colorPalette" value="$palette"/>
  <property name="backgroundColor" value="$canvas_argb"/>
  <property name="selectionBorderColor" value="$selection_argb"/>
  <property name="menubarVisible" value="false"/>
  <property name="defaultViewModeAttributes" value="showToolbar,showSidebar"/>
</settings>
EOF
        return 0
      fi
      [[ -f "$settings" && ! -L "$settings" ]] || return 0
      local settings_tmp="$settings.tmp.$$"
      awk -v palette="$palette" '
        BEGIN { updated = 0 }
        /<property[[:space:]]+name="colorPalette"/ { next }
        /<\/settings>/ && !updated {
          printf "  <property name=\"colorPalette\" value=\"%s\"/>\n", palette
          updated = 1
        }
        { print }
      ' "$settings" > "$settings_tmp"
      sed -i \
        -e 's|<property name="backgroundColor" value="[^"]*"/>|<property name="backgroundColor" value="'"$canvas_argb"'"/>|' \
        -e 's|<property name="selectionBorderColor" value="[^"]*"/>|<property name="selectionBorderColor" value="'"$selection_argb"'"/>|' \
        -e 's|backgroundTypeConfig=f1=#[0-9A-Fa-f]\{6\},af1=#[0-9A-Fa-f]\{6\}|backgroundTypeConfig=f1='"$grid_color"',af1='"$canvas_color"'|' \
        -e 's|<property name="menubarVisible" value="[^"]*"/>|<property name="menubarVisible" value="false"/>|' \
        -e 's|<property name="defaultViewModeAttributes" value="[^"]*"/>|<property name="defaultViewModeAttributes" value="showToolbar,showSidebar"/>|' \
        "$settings_tmp"
      mv -f "$settings_tmp" "$settings"
    }

    if [[ -s "$THEME_DIR/palette.json" ]]; then
      sync_xournal_theme "$XDG_CONFIG_HOME/xournalpp"
      [[ -d "$HOME/.var/app/com.github.xournalpp.xournalpp" ]] && sync_xournal_theme "$HOME/.var/app/com.github.xournalpp.xournalpp/config/xournalpp"
    fi

    sync_vesktop_theme_root() {
      local root="$1"
      [[ -n "$root" && -d "$root" ]] || return 0
      local themes_dir="$root/themes"
      local css="$themes_dir/livara-midnight.theme.css"
      mkdir -p "$themes_dir"
      write_atomic "$css" <<EOF
/**
 * @name Livara Midnight
 * @description Midnight Discord with the active $SHELL_NAME palette.
 * @source https://github.com/refact0r/midnight-discord
 */
@import url('https://refact0r.github.io/midnight-discord/build/midnight.css');

body {
  --font: '';
  --code-font: '';
  --gap: 12px;
  --border-thickness: 1px;
  --animations: on;
  --custom-window-controls: on;
  --top-bar-button-position: titlebar;
  --small-user-panel: off;
}

:root {
  --colors: on;
  --text-0: $(json_color base);
  --text-1: $(json_color text);
  --text-2: $(json_color subtext1);
  --text-3: $(json_color subtext0);
  --text-4: $(json_color overlay0);
  --text-5: $(json_color overlay1);
  --bg-1: $(json_color surface2);
  --bg-2: $(json_color surface1);
  --bg-3: $(json_color surface0);
  --bg-4: $(json_color base);
  --hover: color-mix(in srgb, $(json_color primary) 12%, transparent);
  --active: $(json_color surface2);
  --active-2: $(json_color surface1);
  --message-hover: color-mix(in srgb, $(json_color primary) 8%, transparent);
  --accent-1: $(json_color primary);
  --accent-2: $(json_color primary);
  --accent-3: $(json_color secondary);
  --accent-4: $(json_color secondary);
  --accent-5: $(json_color tertiary);
  --accent-new: $(json_color error);
  --online: $(json_color green);
  --dnd: $(json_color red);
  --idle: $(json_color yellow);
  --streaming: $(json_color mauve);
  --offline: $(json_color overlay0);
  --border-light: var(--hover);
  --border: var(--active);
  --border-hover: var(--active);
  --button-border: color-mix(in srgb, $(json_color text) 12%, transparent);
  --red-1: $(json_color red);
  --red-2: $(json_color red);
  --red-3: $(json_color red);
  --red-4: $(json_color red);
  --red-5: $(json_color red);
  --green-1: $(json_color green);
  --green-2: $(json_color green);
  --green-3: $(json_color green);
  --green-4: $(json_color green);
  --green-5: $(json_color green);
  --blue-1: $(json_color blue);
  --blue-2: $(json_color blue);
  --blue-3: $(json_color blue);
  --blue-4: $(json_color blue);
  --blue-5: $(json_color blue);
  --yellow-1: $(json_color yellow);
  --yellow-2: $(json_color yellow);
  --yellow-3: $(json_color yellow);
  --yellow-4: $(json_color yellow);
  --yellow-5: $(json_color yellow);
  --purple-1: $(json_color mauve);
  --purple-2: $(json_color mauve);
  --purple-3: $(json_color mauve);
  --purple-4: $(json_color mauve);
  --purple-5: $(json_color mauve);
  --background-primary: $(json_color base);
  --background-secondary: $(json_color surface0);
  --background-secondary-alt: $(json_color surface1);
  --background-tertiary: $(json_color mantle);
  --channeltextarea-background: $(json_color surface0);
  --text-normal: $(json_color text);
  --text-muted: $(json_color subtext0);
  --header-primary: $(json_color text);
  --header-secondary: $(json_color subtext1);
  --interactive-normal: $(json_color text);
  --interactive-hover: $(json_color primary);
  --brand-experiment: $(json_color primary);
  --brand-experiment-560: $(json_color primary);
}
EOF
      rm -f "$themes_dir/dank-discord.css" "$themes_dir/noctalia-material.theme.css" "$themes_dir/livara-material.theme.css"

      local settings="$root/settings/settings.json"
      local tmp="$settings.tmp.$$"
      mkdir -p "$(dirname "$settings")"
      if [[ -f "$settings" ]]; then
        jq '.enabledThemes = (((.enabledThemes // []) - ["dank-discord.css", "noctalia-material.theme.css", "livara-material.theme.css"] + ["livara-midnight.theme.css"]) | unique)' "$settings" > "$tmp"
      else
        jq -n '{enabledThemes: ["livara-midnight.theme.css"]}' > "$tmp"
      fi
      chmod 0644 "$tmp"
      mv -f "$tmp" "$settings"
      log "$SHELL_NAME Midnight Discord theme enabled: $css (restart Vesktop if it was already running)"
    }

    # Generate the CSS from the active shell palette and select it in Vencord;
    # mirror the same contract into an existing Vesktop Flatpak data root.
    sync_vesktop_theme_root "$VESKTOP_CONFIG_HOME"
    [[ -d "$HOME/.var/app/dev.vencord.Vesktop" ]] && sync_vesktop_theme_root "$VESKTOP_FLATPAK_HOME"

    foliate_root="$FOLIATE_CONFIG_HOME"
    [[ -d "$FOLIATE_FLATPAK_HOME" ]] && foliate_root="$FOLIATE_FLATPAK_HOME"
    freesm_root="$FREESM_DATA_HOME"
    [[ -d "$FREESM_FLATPAK_HOME" ]] && freesm_root="$FREESM_FLATPAK_HOME"
    xournal_root="$XDG_CONFIG_HOME/xournalpp"
    [[ -d "$HOME/.var/app/com.github.xournalpp.xournalpp/config/xournalpp" ]] && xournal_root="$HOME/.var/app/com.github.xournalpp.xournalpp/config/xournalpp"

    palette_applied=false
    [[ -s "$PALETTE_FILE" ]] && palette_applied=true

    nvim_applied=false
    [[ -s "$NVIM_THEME_PATH" ]] && nvim_applied=true

    nuclear_selected=false
    for nuclear_data_home in "${NUCLEAR_DATA_ROOTS[@]}"; do
      nuclear_settings="$nuclear_data_home/settings.json"
      nuclear_theme="$nuclear_data_home/themes/Livara.json"
      if [[ -s "$nuclear_settings" && -s "$nuclear_theme" ]] && jq -e \
        --arg theme_id "$NUCLEAR_THEME_ID" \
        '."core.theme.active.type" == "advanced" and ."core.theme.active.id" == $theme_id' \
        "$nuclear_settings" >/dev/null 2>&1; then
        nuclear_selected=true
        break
      fi
    done

    foliate_applied=false
    # Verify via dconf (native) or keyfile (Flatpak). dconf read does not
    # need the GSettings schema to be installed on the host.
    if [[ -s "$foliate_root/themes/livara.json" ]]; then
      if command -v dconf >/dev/null 2>&1 &&
         [[ "$(dconf read "$foliate_dconf_path" 2>/dev/null || true)" == "'livara.json'" ]]; then
        foliate_applied=true
      fi
      if [[ "$foliate_applied" != true ]] &&
         [[ -f "$HOME/.var/app/com.github.johnfactotum.Foliate/config/glib-2.0/settings/keyfile" ]]; then
        foliate_keyfile="$HOME/.var/app/com.github.johnfactotum.Foliate/config/glib-2.0/settings/keyfile"
        if awk -v section="$foliate_keyfile_section" '
          BEGIN { in_section = 0 }
          /^\[/ { in_section = ($0 == "[" section "]") }
          in_section && /^theme='\''livara.json'\''$/ { found = 1; exit }
          END { exit !found }
        ' "$foliate_keyfile" 2>/dev/null; then
          foliate_applied=true
        fi
      fi
    fi

    kde_applied=false
    if [[ -s "${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes/DankMatugenDark.colors" ||
          -s "${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes/DankMatugen.colors" ]] &&
       grep -q '^ColorScheme=DankMatugen\(Dark\)\?$' "$XDG_CONFIG_HOME/kdeglobals" 2>/dev/null; then
      kde_applied=true
    fi

    freesm_applied=false
    if [[ -s "$freesm_root/themes/livara/theme.json" && -s "$freesm_root/themes/livara/themeStyle.css" ]]; then
      while IFS= read -r -d "" config; do
        if grep -q '^ApplicationTheme=livara$' "$config"; then
          freesm_applied=true
          break
        fi
      done < <(find "$freesm_root" -maxdepth 2 -type f \( -name '*.cfg' -o -name '*.ini' \) -print0 2>/dev/null)
    fi

    xournal_applied=false
    if [[ -s "$xournal_root/palettes/$XOURNAL_PALETTE_NAME" ]] &&
       grep -q 'name="colorPalette"' "$xournal_root/settings.xml" 2>/dev/null; then
      xournal_applied=true
    fi

    fastfetch_applied=false
    [[ -s "$FASTFETCH_CAT_OUTPUT" && -s "$THEME_DIR/fastfetch.jsonc" ]] && fastfetch_applied=true

    vesktop_applied=false
    for vesktop_root in "$VESKTOP_CONFIG_HOME" "$VESKTOP_FLATPAK_HOME"; do
      if [[ -s "$vesktop_root/themes/livara-midnight.theme.css" && -s "$vesktop_root/settings/settings.json" ]] &&
         jq -e --arg theme "livara-midnight.theme.css" '((.enabledThemes // []) | index($theme)) != null' "$vesktop_root/settings/settings.json" >/dev/null 2>&1; then
        vesktop_applied=true
        break
      fi
    done
    hydra_generated=false
    [[ -s "$HYDRA_THEME_DIR/theme.css" ]] && hydra_generated=true

    hydra_submission_ready=false
    [[ -n "$HYDRA_FRIEND_CODE" && -s "$HYDRA_SCREENSHOT" ]] && hydra_submission_ready=true
    hydra_applied=false

    # The overview distinguishes generated files from confirmed activation.
    # A file can exist while an app still needs a restart or a selected theme.
    write_atomic "$THEME_DIR/applied-applications.json" <<EOF
{
  "generatedFrom": "$SHELL_NAME application contracts",
  "applications": [
    {"name":"$SHELL_NAME palette","contract":"$SHELL_NAME palette variant $PALETTE_VARIANT for GTK/Qt/Kitty/WezTerm and application adapters","path":"$PALETTE_FILE","applied":$palette_applied,"activation":"active shell palette generated"},
    {"name":"GTK/libadwaita/GParted","contract":"GTK3/GTK4 gtk.css plus settings.ini generated from the active variant","path":"$XDG_CONFIG_HOME/gtk-3.0/gtk.css","applied":true,"activation":"restart GTK applications; no logout required"},
    {"name":"Zen/Firefox","contract":"profile-consumable userChrome.css imported by the declarative profile module","path":"$THEME_DIR/browser/firefox.css","applied":true,"activation":"restart Zen/Firefox after enabling userChrome.css"},
    {"name":"Neovim/NixVim","contract":"matugen_colors.lua + NixVim transparent highlight policy","path":"$NVIM_THEME_PATH","applied":$nvim_applied,"activation":"palette file generated and watched by NixVim"},
    {"name":"Nuclear Music Player","contract":"Nuclear v2 advanced theme JSON generated from the active $SHELL_NAME palette","path":"$NUCLEAR_THEME_PATH","applied":$nuclear_selected,"generated":true,"activation":"selection is owned by Nuclear settings; edits reload live after Livara is selected"},
    {"name":"Foliate","contract":"Foliate reader JSON theme + viewer.view.theme (GTK4/libadwaita host UI)","path":"$foliate_root/themes/livara.json","applied":$foliate_applied,"activation":"native or sandbox GSettings selection verified"},
    {"name":"KDE/Okular","contract":"Generated .colors + kdeglobals ColorScheme","path":"${XDG_CONFIG_HOME}/kdeglobals","applied":$kde_applied,"activation":"KDE color scheme selection verified"},
    {"name":"Freesm Launcher","contract":"themes/livara/theme.json + themeStyle.css + ApplicationTheme","path":"$freesm_root/themes/livara","applied":$freesm_applied,"activation":"ApplicationTheme selection verified"},
    {"name":"Xournal++","contract":"palettes/$XOURNAL_PALETTE_NAME + settings.xml colorPalette","path":"$xournal_root/palettes/$XOURNAL_PALETTE_NAME","applied":$xournal_applied,"activation":"restart Xournal++ after a palette change"},
    {"name":"Fastfetch","contract":"$SHELL_NAME primary color + generated keyColor hex + kitty-direct","path":"$THEME_DIR/fastfetch.jsonc","applied":$fastfetch_applied,"activation":"next invocation reads the generated config"},
    {"name":"btop","contract":"generated $BTOP_THEME + color_theme selection","path":"$BTOP_THEME","applied":true,"activation":"SIGUSR2 sent when btop is running"},
    {"name":"WezTerm","contract":"generated color scheme watched by the WezTerm Lua config","path":"$WEZTERM_THEME","applied":true,"activation":"automatically_reload_config handles reload"},
    {"name":"Vesktop","contract":"Midnight Discord CSS + Vencord enabledThemes","path":"$VESKTOP_CONFIG_HOME/themes/livara-midnight.theme.css","applied":$vesktop_applied,"activation":"restart Vesktop after external settings change"},
    {"name":"IntelliJ IDEA editor scheme","contract":"Matugen generated .icls + versioned JetBrains colors directory symlink","path":"$INTELLIJ_SCHEME","applied":false,"available":$intellij_linked,"activation":"Editor color scheme is available; selection remains IDE-controlled"},
    {"name":"IntelliJ IDEA UI theme","contract":"Livara Theme plugin + JetBrains product plugin-root symlink + LafManager selection","path":"$THEME_DIR/intellij/LivaraTheme","applied":$intellij_ui_theme_applied,"installed":$intellij_ui_theme_installed,"activation":"selected by options/laf.xml; restart the IDE to load the plugin"},
    {"name":"Android Studio editor scheme","contract":"Matugen generated .icls + versioned Google colors directory symlink","path":"$INTELLIJ_SCHEME","applied":false,"available":$android_studio_linked,"activation":"Editor color scheme is available; selection remains IDE-controlled"},
    {"name":"Android Studio UI theme","contract":"Livara Theme plugin + Google product plugin-root symlink + LafManager selection","path":"$THEME_DIR/intellij/LivaraTheme","applied":$android_studio_ui_theme_applied,"installed":$android_studio_ui_theme_installed,"activation":"selected by options/laf.xml; restart the IDE to load the plugin"},
    {"name":"Hydra Launcher","contract":"theme.css export plus official hydra-themes publication layout","path":"$HYDRA_THEME_DIR/theme.css","exportPath":"$HYDRA_THEME_EXPORT_DIR/theme.css","applied":$hydra_applied,"generated":$hydra_generated,"registered":false,"activated":false,"submissionReady":$hydra_submission_ready,"activationRequired":true,"activation":"Hydra's Appearance list is LevelDB-owned; use Create/Edit and paste the generated CSS"}
  ]
}
EOF

    applied_count="$(jq '[.applications[] | select(.applied == true)] | length' "$THEME_DIR/applied-applications.json")"
    total_count="$(jq '.applications | length' "$THEME_DIR/applied-applications.json")"
    if [[ "$applied_count" == "$total_count" ]]; then
      log "theme adapters synchronized: $applied_count/$total_count active contracts (reload is application-specific)"
    else
      inactive_contracts="$(jq -r '[.applications[] | select(.applied != true) | .name] | join(", ")' "$THEME_DIR/applied-applications.json")"
      log "theme adapters generated with activation gaps: $applied_count/$total_count active contracts; inactive: $inactive_contracts"
    fi
