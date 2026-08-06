{ config, pkgs, lib, ... }:

{
  # ─── Zen Browser + DMS Theme Integration ──────────────────────────────────
  # DMS matugen generates ~/.config/DankMaterialShell/zen.css at runtime.
  # This module declares the preference and userChrome import declaratively
  # via zen-browser-flake, replacing the previous imperative find/symlink/sync
  # approach which used unstable profile patterns and a Restart=always daemon.
  #
  # The actual userChrome content and settings are configured in the consumer
  # (nix-conf/home/livara/home.nix) using:
  #   programs.zen-browser.profiles.default.settings
  #   programs.zen-browser.profiles.default.userChrome
  #
  # Supports: native install (~/.config/zen)

  # Enable the preference declaratively so zen-browser-flake writes it to prefs.js
  programs.zen-browser.profiles.default.settings = {
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  };
}
