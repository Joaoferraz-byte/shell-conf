#!/usr/bin/env bash
set -Eeuo pipefail

profile_dir="$HOME/.config/zen/personal"
# nix-conf imports homeModules.beta, whose deterministic binary name is
# zen-beta. Do not fall back to an unrelated generic Zen/Flatpak executable:
# that would silently use another config root and only show a different
# profile's default Space.
browser="zen-beta"
if command -v "$browser" >/dev/null 2>&1; then
  # Do not force --new-instance here.  The four Spaces belong to one profile;
  # letting Zen reuse its running process preserves the native window-sync and
  # Space state instead of creating an isolated second browser process.
  exec "$browser" --profile "$profile_dir" "$@"
fi

if command -v notify-send >/dev/null 2>&1; then
  notify-send -u critical "Livara Shell" "Zen Browser (zen-beta) not found in session PATH"
fi
exit 127
