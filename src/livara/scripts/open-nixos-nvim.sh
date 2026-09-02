#!/usr/bin/env bash
set -euo pipefail

repo="${NIXOS_CONFIG_DIR:-$HOME/.config/nixos}"
mkdir -p "$repo"

resolve_nvim() {
  local candidate
  for candidate in \
    "$HOME/.local/state/nix/profiles/home-manager/home-path/bin/nvim" \
    "$HOME/.nix-profile/bin/nvim" \
    "/run/current-system/sw/bin/nvim"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  command -v nvim 2>/dev/null || true
}

nvim_bin="$(resolve_nvim)"
if [[ -z "$nvim_bin" ]]; then
  notify-send -u critical "Livara Shell" "Neovim not available in Home Manager profile" 2>/dev/null || true
  exit 127
fi

if wezterm_bin="$(command -v wezterm 2>/dev/null)"; then
  exec "$wezterm_bin" start --always-new-process --cwd "$repo" -- "$nvim_bin" --cmd "set nomore" --cmd "set shortmess+=F" -c "cd -- $repo" -c "Oil"
fi

if footclient_bin="$(command -v footclient 2>/dev/null)"; then
  exec "$footclient_bin" --working-directory="$repo" "$nvim_bin" --cmd "set nomore" --cmd "set shortmess+=F" -c "cd -- $repo" -c "Oil"
fi

exec "$nvim_bin" --cmd "set nomore" --cmd "set shortmess+=F" -c "cd -- $repo" -c "Oil"
