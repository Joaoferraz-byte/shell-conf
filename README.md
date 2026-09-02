# Livara shell support

This repository is the intermediary integration layer for the Livara desktop. It imports the complete customized Noctalia module from `noctalia-conf` and connects that shell to session helpers, application adapters, GTK preferences, browser profiles and the host-specific Home Manager composition.

## Ownership model

| Responsibility | Owner | Interface |
| --- | --- | --- |
| Host, hardware, drivers, services, Niri, PipeWire and system capabilities | `nix-conf` | NixOS and Home Manager modules |
| Noctalia runtime, settings, wallpaper policy, templates, plugins and shell assets | `noctalia-conf` | `packages.default`, `homeModules.default` |
| Session helpers, application adapters and shell-independent support | This repository | `homeModules.support` |
| NixVim configuration and editor workflow | `vim-conf` | NixVim module consuming generated palette data |
| Markdown notes and source material | `Vault` | Versioned files and user data |

The exported `homeModules.support` imports `noctalia-conf.homeModules.default`. It does not define `programs.noctalia.settings`, install Noctalia plugins, copy Noctalia templates, or start a second shell lifecycle. Niri starts the single Noctalia process through its declarative session edge in `nix-conf`.

## Shell-independent support

The module provides Fastfetch, WezTerm configuration, tablet detection, Xournal++ and daily-note helpers, GTK preferences, browser-theme synchronization, and application-specific theme adapters. The generated palette is consumed as runtime state under `$XDG_STATE_HOME/livara/theme`; source configuration remains in its owning repository and mutable profiles remain outside the Nix store.

## Validation

Run `nix flake check --no-build --no-update-lock-file --all-systems` in this repository, `noctalia-conf` and `nix-conf`. Validate shell scripts with `bash -n` and `shellcheck`, validate the Noctalia TOML through the Noctalia check in `noctalia-conf`, and verify on hardware that Niri starts one Noctalia process, manual wallpaper selection updates the palette, and application adapters remain outside the store's mutable state.

## References

[1]: https://docs.noctalia.dev/noctalia/ "Noctalia v5 documentation"
[2]: https://docs.noctalia.dev/noctalia/getting-started/nixos/ "Noctalia v5 NixOS and Home Manager"
[3]: https://docs.noctalia.dev/noctalia/theming/app-theming/ "Noctalia v5 application theming"
[4]: https://github.com/noctalia-dev/official-plugins "Noctalia official plugins"
