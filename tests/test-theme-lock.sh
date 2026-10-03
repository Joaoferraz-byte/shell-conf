#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export HOME="$tmp/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
export LIVARA_THEME_ROOT="$XDG_STATE_HOME/livara/theme"
export LIVARA_LOCK_FILE="$tmp/theme-sync.lock"
mkdir -p "$HOME" "$XDG_CACHE_HOME/ambxst" "$(dirname "$LIVARA_LOCK_FILE")"

exec 9>"$LIVARA_LOCK_FILE"
flock -n 9

bash "$repo_root/src/livara/scripts/sync-ambxst-palette.sh" >/dev/null 2>"$tmp/bridge.log"
bash "$repo_root/src/livara/scripts/sync-livara-themes.sh" dark >/dev/null 2>"$tmp/adapters.log"

[[ ! -e "$LIVARA_THEME_ROOT/palette.dark.json" ]]
[[ ! -e "$LIVARA_THEME_ROOT/applied-applications.json" ]]
grep -Fq 'skipping Ambxst palette bridge' "$tmp/bridge.log"
grep -Fq 'skipping application adapters' "$tmp/adapters.log"
printf '%s\n' 'shared theme lock contract passed'
