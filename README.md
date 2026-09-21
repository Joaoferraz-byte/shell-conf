# Livara shell support

This repository is the intermediary integration layer for the Livara desktop. It provides a shell-neutral support core and an optional Noctalia adapter for session helpers, application adapters, GTK preferences, browser profiles and host-specific Home Manager composition.

## Ownership model

| Responsibility | Owner | Interface |
| --- | --- | --- |
| Host, hardware, drivers, services, Niri, PipeWire and system capabilities | `nix-conf` | NixOS and Home Manager modules |
| Noctalia runtime, settings, wallpaper policy, templates, plugins and shell assets | `noctalia-conf` | `packages.default`, `homeModules.default` |
| Session helpers, application adapters and shell-independent support | This repository | `homeModules.support-core` |
| Noctalia runtime adapter | This repository + `noctalia-conf` | `homeModules.support` |
| NixVim configuration and editor workflow | `vim-conf` | NixVim module consuming generated palette data |
| Markdown notes and source material | `Vault` | Versioned files and user data |

The exported `homeModules.support-core` has no shell-runtime input and can be consumed by Ambxst or another shell. `homeModules.support` is the Noctalia adapter and imports `noctalia-conf.homeModules.default`; it does not define a second Noctalia lifecycle. A shell consumer must choose one complete shell and must not activate Noctalia and Ambxst together.

## Shell-independent support

The core module provides Fastfetch, WezTerm configuration, tablet detection, Xournal++ and daily-note helpers, GTK preferences, browser-theme synchronization, and application-specific theme adapters. In the active Ambxst composition, the bridge promotes `~/.cache/ambxst/colors.json` into a validated semantic palette under `$XDG_STATE_HOME/livara/theme`; this repository consumes that output and does not read or rewrite Ambxst state directly. Source configuration remains in its owning repository and mutable profiles remain outside the Nix store. The browser adapter is the sole writer of the profile-consumable `browser/firefox.css`; the Zen/Firefox profile module imports it through `chrome/userChrome.css`. Ambxst remains the sole writer of `wezterm/colors/Ambxst.toml` in the integration, while this repository selects and watches that file for reload.

## Validation

Run `nix flake check --no-build --no-update-lock-file --all-systems` in this repository, `ambxst-conf` and `nix-conf`. Validate shell scripts with `bash -n` and `shellcheck`, validate the generated Niri contract and Ambxst patch in their owning repositories, and verify on hardware that Niri starts one Ambxst process, manual wallpaper selection updates the palette, Zen imports the generated `userChrome.css`, and application adapters remain outside the store's mutable state.

## References

[1]: https://docs.noctalia.dev/noctalia/ "Noctalia v5 documentation"
[2]: https://docs.noctalia.dev/noctalia/getting-started/nixos/ "Noctalia v5 NixOS and Home Manager"
[3]: https://docs.noctalia.dev/noctalia/theming/app-theming/ "Noctalia v5 application theming"
[4]: https://github.com/noctalia-dev/official-plugins "Noctalia official plugins"
