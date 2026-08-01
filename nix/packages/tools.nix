# System tools and utilities
{ pkgs }:

with pkgs; [
  brightnessctl
  ddcutil
  fontconfig
  glib
  grim
  imagemagick
  jq

  libnotify
  matugen
  python3
  power-profiles-daemon
  slurp
  sqlite
  upower
  wl-clip-persist
  wl-clipboard
  wlsunset
  wtype
  zbar
  zenity
  inetutils
  adw-gtk3

  # Missing runtime dependencies required by QML services and scripts
  bash
  coreutils
  curl
  findutils
  gawk
  gnugrep
  gnused
  procps
  xdg-user-dirs
  xdg-utils
  hyprpicker
  wf-recorder
]
