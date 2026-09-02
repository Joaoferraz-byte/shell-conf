#!/usr/bin/env bash
set -Eeuo pipefail

browser="zen-beta"
notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send -a "Livara" "Zen Browser" "$1"
}

if pgrep -x "$browser" >/dev/null 2>&1; then
  pkill -TERM -x "$browser" || true
  for _ in {1..100}; do
    pgrep -x "$browser" >/dev/null 2>&1 || break
    sleep 0.2
  done
  if pgrep -x "$browser" >/dev/null 2>&1; then
    notify "Zen não encerrou no tempo esperado; reload cancelado."
    exit 1
  fi
fi

exec "$HOME/.local/share/livara/scripts/open-zen.sh" "$@"
