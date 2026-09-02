#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/src/livara/scripts/open-nixos-nvim.sh"
theme_script="$repo_root/src/livara/scripts/sync-livara-themes.sh"

fail() {
  printf 'Livara shell contract check failed: %s\n' "$1" >&2
  exit 1
}

require() {
  local pattern="$1"
  grep -Eq -- "$pattern" "$script" || fail "missing '$pattern' in ${script#$repo_root/}"
}

forbidden() {
  local pattern="$1"
  if grep -Eq -- "$pattern" "$script"; then
    fail "forbidden '$pattern' in ${script#$repo_root/}"
  fi
}

bash -n "$script"
bash -n "$theme_script"
grep -Eq 'NVIM_THEME_PATH=.*nvim/lua/matugen_colors\.lua' "$theme_script" || fail 'Matugen path must target nvim/lua/matugen_colors.lua'
if grep -Eq 'NVIM_THEME_PATH=.*nvim/matugen_colors\.lua([" ]|$)' "$theme_script"; then
  fail 'legacy Matugen path must not be used'
fi
require '--cmd "set nomore"'
require '--cmd "set shortmess\+=F"'
require 'Oil'
require 'start --always-new-process'
forbidden 'Neotree'
forbidden 'Press any key'

printf 'Livara shell contracts: OK\n'
