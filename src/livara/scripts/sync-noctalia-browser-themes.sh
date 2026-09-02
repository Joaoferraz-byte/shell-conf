#!/usr/bin/env bash
set -Eeuo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
THEME_ROOT="${LIVARA_THEME_ROOT:-$XDG_STATE_HOME/livara/theme}"
BROWSER_ROOT="$THEME_ROOT/browser"
FIREFOX_CSS="$BROWSER_ROOT/firefox.css"

link_profile_css() {
  local profile_dir="$1"
  local source_css="$2"
  local target_name="$3"
  [[ -d "$profile_dir" && -s "$source_css" ]] || return 0

  local chrome_dir="$profile_dir/chrome"
  local target="$chrome_dir/$target_name"
  mkdir -p "$chrome_dir"
  if [[ -L "$target" ]]; then
    local current
    current="$(readlink -f "$target" 2>/dev/null || true)"
    [[ "$current" == "$source_css" ]] && return 0
    rm -f "$target"
  elif [[ -e "$target" ]]; then
    # Never overwrite a user's regular userChrome.css. Home Manager owns
    # generated browser CSS where it is declaratively configured.
    return 0
  fi
  ln -s "$source_css" "$target"
}

ensure_userchrome_pref() {
  local profile_dir="$1"
  [[ -d "$profile_dir" ]] || return 0
  local user_js="$profile_dir/user.js"
  # A Home Manager profile normally has user.js as a store symlink. Its
  # settings already contain the stylesheet preference; never write through
  # that symlink into the immutable generation.
  [[ -L "$user_js" ]] && return 0
  touch "$user_js"
  grep -Fqx 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' "$user_js" ||
    printf '%s\n' 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$user_js"
}

# Firefox profiles use userChrome.css. Zen profiles are intentionally not
# handled here: nix-conf owns their declarative userChrome import so this
# bridge cannot replace it with a competing symlink.
for profile in "$XDG_CONFIG_HOME"/mozilla/firefox/*.default* "$XDG_CONFIG_HOME"/mozilla/firefox/*.profile*; do
  [[ -d "$profile" ]] || continue
  link_profile_css "$profile" "$FIREFOX_CSS" userChrome.css
  ensure_userchrome_pref "$profile"
done
