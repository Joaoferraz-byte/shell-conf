#!/usr/bin/env bash
set -Eeuo pipefail

no_open=false
if [[ "${1:-}" == "--no-open" ]]; then
  no_open=true
  shift
fi

vault_root="${LIVARA_VAULT_ROOT:-$HOME/Vault}"
template_dir="${LIVARA_TEMPLATE_DIR:-$vault_root/06 - Config/templates}"
daily_dir="${LIVARA_DAILY_DIR:-$vault_root/03 - Daily Notes}"
template_path="${LIVARA_DAILY_TEMPLATE:-$template_dir/00 - Daily Note.md}"
today="$(date '+%Y-%m-%d')"
title="${LIVARA_DAILY_TITLE:-$today}"
note="$daily_dir/$today.md"

notify_error() {
  notify-send -u critical "Daily Note" "$1" 2>/dev/null || true
}

if [[ ! -r "$template_path" ]]; then
  notify_error "Template not found: $template_path"
  exit 1
fi

format_date() {
  local format="$1"
  # Replace longest tokens first so local date-format placeholders remain deterministic.
  format="${format//YYYY/%Y}"
  format="${format//yyyy/%Y}"
  format="${format//MMMM/%B}"
  format="${format//dddd/%A}"
  format="${format//MMM/%b}"
  format="${format//ddd/%a}"
  format="${format//MM/%m}"
  format="${format//DD/%d}"
  format="${format//dd/%d}"
  format="${format//YY/%y}"
  format="${format//yy/%y}"
  format="${format//D/%-d}"
  format="${format//HH/%H}"
  format="${format//mm/%M}"
  format="${format//ss/%S}"
  format="${format//\'/}"
  date "+$format"
}

replace_token() {
  local token="$1" value="$2"
  rendered="${rendered//"$token"/"$value"}"
}

mkdir -p "$daily_dir" "${LIVARA_IMAGE_DIR:-$vault_root/00 - Black Box/Assets/Images}"
if [[ -e "$note" ]]; then
  :
else
  rendered="$(<"$template_path")"
  replace_token '{{title}}' "$title"
  replace_token '{{date}}' "$today"
  replace_token '{{time}}' "$(date '+%H:%M')"
  replace_token '{{week}}' "$(date '+%V')"
  replace_token '{{cursor}}' ''
  while [[ "$rendered" =~ \{\{date:([^}]*)\}\} ]]; do
    token="${BASH_REMATCH[0]}"
    value="$(format_date "${BASH_REMATCH[1]}")"
    replace_token "$token" "$value"
  done
  umask 077
  printf '%s\n' "$rendered" > "$note"
fi

if [[ "$no_open" == true ]]; then
  printf '%s\n' "$note"
  exit 0
fi

resolve_nvim() {
  local candidate
  for candidate in \
    "$HOME/.local/state/nix/profiles/home-manager/home-path/bin/nvim" \
    "$HOME/.nix-profile/bin/nvim" \
    "/run/current-system/sw/bin/nvim"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  command -v nvim 2>/dev/null || true
}

nvim_bin="$(resolve_nvim)"
if [[ -z "$nvim_bin" ]]; then
  notify_error "Neovim is not available in the Home Manager profile"
  exit 127
fi

nvim_args=(--cmd "set nomore" --cmd "set shortmess+=F" "$note")
if wezterm_bin="$(command -v wezterm 2>/dev/null)"; then
  exec "$wezterm_bin" start --always-new-process --cwd "$vault_root" -- "$nvim_bin" "${nvim_args[@]}"
fi
if footclient_bin="$(command -v footclient 2>/dev/null)"; then
  exec "$footclient_bin" --working-directory="$vault_root" "$nvim_bin" "${nvim_args[@]}"
fi
exec "$nvim_bin" "${nvim_args[@]}"
