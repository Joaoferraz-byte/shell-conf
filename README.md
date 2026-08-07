# Shell Conf

This repository acts as an intermediary (wrapper) for **DankMaterialShell (DMS)** and **Niri**, providing a ready-to-use and pre-optimized configuration for NixOS.

## Architecture

`shell-conf` consumes upstream DMS and Niri flakes and re-exports modules with "opinionated" settings:

- **DankMaterialShell**: Configured with system monitoring, VPN, dynamic theme (matugen), and native Niri integration.
- **Niri**: Configured with complementary keyboard shortcuts (Super+1..9 for workspaces, Super+W for Zen Browser), screenshot keybinds (Super+Shift+S, Super+S, Super+Ctrl+S), window rules for rounding (radius 12), and Wayland environment variables.
- **Theme**: GTK theme dynamically controlled by DMS matugen. `kora` icons and `Bibata-Modern-Classic` cursor are applied declaratively via GTK and dconf.
- **WezTerm**: JetBrainsMono Nerd Font with fallbacks, dynamic theme via matugen (`dank-theme`).
- **Zen Browser**: Automatic DMS theme integration via matugen, with symlink to userChrome.css.

## Modules

| Module | Responsibility |
|---|---|
| `dms.nix` | DankMaterialShell systemd, settings sync via inotifywait |
| `niri.nix` | Keyboard shortcuts, window rules, screenshots |
| `theme.nix` | kora icons, Bibata cursor, dark mode |
| `wezterm.nix` | Nerd Fonts, matugen theme, opacity |
| `zen.nix` | Zen Browser theme sync via userChrome.css |

## Screenshot Keybinds

| Shortcut | Action |
|---|---|
| Super+Shift+S | Selected region screenshot |
| Super+S | Fullscreen screenshot |
| Super+Ctrl+S | Active window screenshot |

All captures are saved in `~/Pictures/Screenshots/` with a timestamp.

## How to use on NixOS

Add to your `flake.nix`:

```nix
inputs = {
  shell-conf = {
    url = "github:Joaoferraz-byte/shell-conf";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

In your `configuration.nix` (System module):

```nix
imports = [
  inputs.shell-conf.nixosModules.dankMaterialShell
];
```

In your `home.nix` (User module):

```nix
imports = [
  inputs.shell-conf.homeManagerModules.default
];
```
