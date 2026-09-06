    #!/usr/bin/env bash
    set -Eeuo pipefail

    XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
    THEME_DIR="${LIVARA_THEME_ROOT:-$XDG_STATE_HOME/livara/theme}"
    LOG_DIR="$XDG_STATE_HOME/livara/logs"
    LOG_FILE="$LOG_DIR/theme-sync.log"
    FOLIATE_CONFIG_HOME="$XDG_CONFIG_HOME/com.github.johnfactotum.Foliate"
    FOLIATE_FLATPAK_HOME="$HOME/.var/app/com.github.johnfactotum.Foliate/config/com.github.johnfactotum.Foliate"
    VESKTOP_CONFIG_HOME="$XDG_CONFIG_HOME/vesktop"
    VESKTOP_FLATPAK_HOME="$HOME/.var/app/dev.vencord.Vesktop/config/vesktop"
    XOURNAL_PALETTE_NAME="tokyonight.gpl"
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
    # format. Matugen owns the shared palette, while this script only writes
    # formats that the target application actually consumes.
    if [[ ! -s "$THEME_DIR/palette.json" ]]; then
      install -m 0644 "${LIVARA_DEFAULT_PALETTE:-$THEME_DIR/bootstrap.json}" "$THEME_DIR/palette.json"
      log "installed the emergency Livara fallback palette"
    fi
    [[ -s "$THEME_DIR/palette.light.json" ]] || cp -f "$THEME_DIR/palette.json" "$THEME_DIR/palette.light.json"
    [[ -s "$THEME_DIR/palette.dark.json" ]] || cp -f "$THEME_DIR/palette.json" "$THEME_DIR/palette.dark.json"

    json_color() {
      local key="$1"
      local fallback="${2:-base}"
      local color
      # palette.dark.json is the single dark-mode source produced from the
      # current Noctalia wallpaper. palette.json remains only a compatibility copy.
      color="$(jq -r --arg key "$key" --arg fallback "$fallback" '.[$key] // .[$fallback] // .base // "#111318"' "$THEME_DIR/palette.dark.json")"
      if [[ "$color" =~ ^#[[:xdigit:]]{6}$ ]]; then
        printf '%s\n' "$color"
      else
        printf '%s\n' '#111318'
      fi
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
      local tmp="${target}.tmp.$$"
      mkdir -p "$(dirname "$target")"
      cat > "$tmp"
      chmod 0644 "$tmp"
      mv -f "$tmp" "$target"
      }

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

    sync_fastfetch_cat

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
      local data_root product_root product_name plugins_dir target current theme_id
      theme_id="$(sed -n 's/.*themeProvider[[:space:]]\+id="\([^"]*\)".*/\1/p' "$theme_plugin/META-INF/plugin.xml" | head -n1)"
      [[ -n "$theme_id" ]] || {
        log "IDE UI theme rejected because plugin.xml has no themeProvider id"
        return 0
      }
      install_theme_plugin() {
        local product_root product_name plugins_dir target current
        product_root="$1"
        product_name="$(basename "$product_root")"
        plugins_dir="$product_root/plugins"
        target="$plugins_dir/LivaraTheme"
        mkdir -p "$plugins_dir"
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
          product_name="$(basename "$product_root")"
          case "$config_root" in
            "$XDG_CONFIG_HOME/JetBrains"|"$XDG_CONFIG_HOME/JetBrains"/*)
              install_theme_plugin "$XDG_DATA_HOME/JetBrains/$product_name"
              select_theme_in_config "$product_root"
              ;;
            "$XDG_CONFIG_HOME/Google"|"$XDG_CONFIG_HOME/Google"/*)
              install_theme_plugin "$XDG_DATA_HOME/Google/$product_name"
              select_theme_in_config "$product_root"
              ;;
          esac
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
Livara Hydra theme generated from the active Noctalia palette.

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
      if pgrep -x nuclear >/dev/null 2>&1 || pgrep -x Nuclear >/dev/null 2>&1 || pgrep -x com.nuclearplayer.Nuclear >/dev/null 2>&1; then
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
          '."core.theme.active.type" = "advanced" | ."core.theme.active.id" = $theme_path | if $dark_mode == "dark" then ."core.theme.dark" = true else . end' \
          "$settings_path" > "$settings_tmp"
      else
        jq -n --arg theme_path "$NUCLEAR_THEME_ID" --arg dark_mode "$NUCLEAR_DARK_MODE" \
          '{"core.theme.active.type":"advanced","core.theme.active.id":$theme_path} + (if $dark_mode == "dark" then {"core.theme.dark":true} else {} end)' \
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
    # Noctalia owns the generated .colors file; this adapter selects it in the KDE
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
        log "KDE color scheme not selected: Noctalia .colors file is not generated yet"
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
      local palette_tmp="$palette.tmp.$$"
      mkdir -p "$(dirname "$palette")"
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

        printf '%s\n' 'GIMP Palette' 'Name: Tokyo Night' 'Columns: 4' '#'
        # GPL has no aliases: keep the first semantic role for equal RGB values.
        # Surface roles such as crust/mantle are intentionally excluded: they
        # describe the black page/background, not useful pen colors. Keeping
        # only contrast-bearing roles prevents a dark swatch from becoming a
        # misleading toolbar choice while preserving deterministic order.
        add_unique_color text Text
        add_unique_color primary Primary
        add_unique_color primary_container 'Primary Container'
        add_unique_color secondary Secondary
        add_unique_color tertiary Tertiary
        add_unique_color error Error
        add_unique_color red Alert
        add_unique_color green Success
        add_unique_color blue Link
        add_unique_color teal Teal
        add_unique_color yellow Warning
        add_unique_color peach Accent
        add_unique_color mauve Emphasis
      } | write_atomic "$palette_tmp"

      if grep -Eq '[[:space:]](Crust|Mantle)$' "$palette_tmp"; then
        rm -f "$palette_tmp"
        log "Xournal palette rejected: surface role leaked into drawing colors"
        return 1
      fi
      if ! awk 'NF >= 3 && $1 ~ /^[0-9]+$/ { key = $1 FS $2 FS $3; if (++seen[key] > 1) duplicate = 1 } END { exit duplicate }' "$palette_tmp"; then
        rm -f "$palette_tmp"
        log "Xournal palette rejected: duplicate RGB entries"
        return 1
      fi
      mv -f "$palette_tmp" "$palette"

      local canvas_color selection_color canvas_argb selection_argb
      canvas_color="$(json_color mantle)"
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
      local source_css="$VESKTOP_CONFIG_HOME/themes/noctalia-material.theme.css"
      [[ -s "$source_css" ]] || source_css="$VESKTOP_FLATPAK_HOME/themes/noctalia-material.theme.css"
      [[ -n "$root" && -d "$root" && -s "$source_css" ]] || return 0
      local themes_dir="$root/themes"
      local css="$themes_dir/noctalia-material.theme.css"
      mkdir -p "$themes_dir"
      if [[ "$source_css" != "$css" ]]; then
        cp -f "$source_css" "$css"
      fi
      rm -f "$themes_dir/dank-discord.css"

      local settings="$root/settings/settings.json"
      local tmp="$settings.tmp.$$"
      mkdir -p "$(dirname "$settings")"
      if [[ -f "$settings" ]]; then
        jq '.enabledThemes = (((.enabledThemes // []) - ["dank-discord.css"] + ["noctalia-material.theme.css"]) | unique)' "$settings" > "$tmp"
      else
        jq -n '{enabledThemes: ["noctalia-material.theme.css"]}' > "$tmp"
      fi
      chmod 0644 "$tmp"
      mv -f "$tmp" "$settings"
      log "Official Noctalia Discord theme enabled: $css"
    }

    # Noctalia owns the generated CSS; this adapter selects it in Vencord
    # and mirrors the same file into an existing Vesktop Flatpak data root.
    sync_vesktop_theme_root "$VESKTOP_CONFIG_HOME"
    [[ -d "$HOME/.var/app/dev.vencord.Vesktop" ]] && sync_vesktop_theme_root "$VESKTOP_FLATPAK_HOME"

    # Noctalia owns the WezTerm template. The external adapter intentionally
    # does not overwrite or reload the consumer-owned configuration.

    foliate_root="$FOLIATE_CONFIG_HOME"
    [[ -d "$FOLIATE_FLATPAK_HOME" ]] && foliate_root="$FOLIATE_FLATPAK_HOME"
    freesm_root="$FREESM_DATA_HOME"
    [[ -d "$FREESM_FLATPAK_HOME" ]] && freesm_root="$FREESM_FLATPAK_HOME"
    xournal_root="$XDG_CONFIG_HOME/xournalpp"
    [[ -d "$HOME/.var/app/com.github.xournalpp.xournalpp/config/xournalpp" ]] && xournal_root="$HOME/.var/app/com.github.xournalpp.xournalpp/config/xournalpp"

    noctalia_applied=false
    [[ -s "$THEME_DIR/palette.dark.json" ]] && noctalia_applied=true

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
    if [[ -s "$xournal_root/palettes/tokyonight.gpl" ]] &&
       grep -q 'name="colorPalette"' "$xournal_root/settings.xml" 2>/dev/null; then
      xournal_applied=true
    fi

    fastfetch_applied=false
    [[ -s "$FASTFETCH_CAT_OUTPUT" ]] && fastfetch_applied=true

    vesktop_applied=false
    for vesktop_root in "$VESKTOP_CONFIG_HOME" "$VESKTOP_FLATPAK_HOME"; do
      if [[ -s "$vesktop_root/themes/noctalia-material.theme.css" && -s "$vesktop_root/settings/settings.json" ]] &&
         jq -e --arg theme "noctalia-material.theme.css" '((.enabledThemes // []) | index($theme)) != null' "$vesktop_root/settings/settings.json" >/dev/null 2>&1; then
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
  "generatedFrom": "Matugen application contracts",
  "applications": [
    {"name":"Noctalia template contracts","contract":"Noctalia v5 templates (GTK/Qt/Firefox/Zen/WezTerm/Kitty)","path":"$THEME_DIR/palette.dark.json","applied":$noctalia_applied,"activation":"Noctalia palette template generated"},
    {"name":"Neovim/NixVim","contract":"matugen_colors.lua + NixVim transparent highlight policy","path":"$NVIM_THEME_PATH","applied":$nvim_applied,"activation":"palette file generated and watched by NixVim"},
    {"name":"Nuclear Music Player","contract":"Nuclear v2 advanced theme JSON generated from the active Noctalia palette","path":"$NUCLEAR_THEME_PATH","applied":$nuclear_selected,"generated":true,"activation":"selection is owned by Nuclear settings; edits reload live after Livara is selected"},
    {"name":"Foliate","contract":"Foliate reader JSON theme + viewer.view.theme (GTK4/libadwaita host UI)","path":"$foliate_root/themes/livara.json","applied":$foliate_applied,"activation":"native or sandbox GSettings selection verified"},
    {"name":"KDE/Okular","contract":"Noctalia .colors + kdeglobals ColorScheme","path":"${XDG_CONFIG_HOME}/kdeglobals","applied":$kde_applied,"activation":"KDE color scheme selection verified"},
    {"name":"Freesm Launcher","contract":"themes/livara/theme.json + themeStyle.css + ApplicationTheme","path":"$freesm_root/themes/livara","applied":$freesm_applied,"activation":"ApplicationTheme selection verified"},
    {"name":"Xournal++","contract":"palettes/tokyonight.gpl + settings.xml colorPalette","path":"$xournal_root/palettes/tokyonight.gpl","applied":$xournal_applied,"activation":"palette selection verified"},
    {"name":"Fastfetch","contract":"Noctalia primary color + transparent cat PNG + kitty-direct","path":"$FASTFETCH_CAT_OUTPUT","applied":$fastfetch_applied,"activation":"recolored image generated"},
    {"name":"Vesktop","contract":"Noctalia Discord template + Vencord enabledThemes","path":"$VESKTOP_CONFIG_HOME/themes/noctalia-material.theme.css","applied":$vesktop_applied,"activation":"enabledThemes selection verified"},
    {"name":"IntelliJ IDEA editor scheme","contract":"Matugen generated .icls + versioned JetBrains colors directory symlink","path":"$INTELLIJ_SCHEME","applied":false,"available":$intellij_linked,"activation":"Editor color scheme is available; selection remains IDE-controlled"},
    {"name":"IntelliJ IDEA UI theme","contract":"Livara Theme plugin + versioned JetBrains plugins directory symlink + LafManager selection","path":"$THEME_DIR/intellij/LivaraTheme","applied":$intellij_ui_theme_applied,"installed":$intellij_ui_theme_installed,"activation":"selected by options/laf.xml; restart the IDE to load the plugin"},
    {"name":"Android Studio editor scheme","contract":"Matugen generated .icls + versioned Google colors directory symlink","path":"$INTELLIJ_SCHEME","applied":false,"available":$android_studio_linked,"activation":"Editor color scheme is available; selection remains IDE-controlled"},
    {"name":"Android Studio UI theme","contract":"Livara Theme plugin + versioned Google plugins directory symlink + LafManager selection","path":"$THEME_DIR/intellij/LivaraTheme","applied":$android_studio_ui_theme_applied,"installed":$android_studio_ui_theme_installed,"activation":"selected by options/laf.xml; restart the IDE to load the plugin"},
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
