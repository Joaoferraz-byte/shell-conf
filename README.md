# Livara shell integration

This repository owns shell-independent user support and the curated Noctalia integration for the Livara desktop. `noctalia-conf` owns the local Noctalia runtime contract; this repository consumes that runtime and owns the user-facing policy around its configuration, templates, plugins, palette adapters, application integrations, and helper programs.

## Ownership model

| Responsibility | Owner | Interface |
| --- | --- | --- |
| Host, hardware, drivers, services, Niri, PipeWire, and system capabilities | `nix-conf` | NixOS and Home Manager modules |
| Upstream Noctalia package and local runtime policy | `noctalia-conf` | `packages.default`, `homeModules.default` |
| Noctalia TOML, user templates, reviewed plugin sources, and visual policy | This repository | `programs.noctalia`, `config/noctalia`, and `plugins/*` |
| Application adapters and shell-independent user support | This repository | `homeModules.support` |
| NixVim configuration and editor workflow | `vim-conf` | NixVim module consuming generated palette data |

The exported `homeModules.support` imports the runtime module from `noctalia-conf`, enables exactly one Noctalia process through the Niri-owned startup path, materializes the curated configuration and reviewed plugin sources, and provides application adapters. It does not write compositor configuration or start a second shell lifecycle.

## Noctalia integration

The curated configuration is stored under `config/noctalia/config.toml`. Its template paths are resolved during evaluation and its mutable settings remain under the Noctalia state directory. Plugins are stored under `plugins/` and installed as Home Manager data files. Community templates remain pinned as a flake input and are not fetched during activation.

The generated Niri include is a visual bridge only: compositor policy stays in `nix-conf`, while the Noctalia palette supplies colors. The two repositories share the same border-width contract and the integration check rejects drift.

## Shell-independent support

The module provides Fastfetch, WezTerm configuration, tablet detection, Xournal++ and daily-note helpers, GTK preferences, browser-theme synchronization, and application-specific theme adapters. The Vault repository owns Markdown notes, `vim-conf` owns the editor, and Niri remains owned by `nix-conf`.

## Validation

Run `nix flake check --no-build --no-update-lock-file --all-systems` in this repository and in `nix-conf`. Validate shell scripts with `bash -n` and `shellcheck`, inspect the generated Noctalia TOML and plugin manifests, and verify on hardware that Niri starts one Noctalia process, the wallpaper palette updates, and the application adapters remain outside the Nix store's mutable state.

## References

[1]: https://docs.noctalia.dev/noctalia/ "Noctalia v5 documentation"
[2]: https://docs.noctalia.dev/noctalia/configuration/ "Noctalia v5 configuration"
[3]: https://docs.noctalia.dev/noctalia/compositor-settings/niri/ "Noctalia v5 Niri integration"
[4]: https://github.com/noctalia-dev/official-plugins "Official Noctalia plugins"
