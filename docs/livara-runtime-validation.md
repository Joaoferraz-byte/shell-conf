# Livara runtime validation

Run these checks after applying the `nix-conf` generation on the host. They are mostly read-only; opening a panel, changing a wallpaper, or opening a note changes only the user session/Vault state.

## Apply the generation

```bash
cd ~/.config/nixos
git pull --ff-only origin main
sudo nixos-rebuild switch --flake .#latitude   # or .#myMachine
```

The session must contain exactly one Noctalia process started by Niri:

```bash
pgrep -a noctalia || true
pgrep -a 'quickshell|dms' || true
systemctl --user --type=service --state=running | grep -Ei 'noctalia|livara|theme' || true
```

There should be no second shell, wallpaper daemon, or idle daemon introduced by the user configuration. The Home Manager unit for Noctalia is intentionally disabled because Niri owns the single startup edge.

## Noctalia and plugins

```bash
noctalia msg plugins list
printf '\n--- Noctalia IPC help ---\n'
noctalia msg --help
printf '\n--- configuration state ---\n'
find "${XDG_CONFIG_HOME:-$HOME/.config}/noctalia" -maxdepth 2 -type f -printf '%P\n' 2>/dev/null | sort
find "${XDG_DATA_HOME:-$HOME/.local/share}/noctalia/plugins" -maxdepth 3 -type f -printf '%P\n' 2>/dev/null | sort
```

The enabled plugins should include `dotnetrob/cat`, `noctalia/timer` and `noctalia/screen_recorder`. Plugin source files are store-backed; only plugin settings and runtime state are mutable.

## Nixvim installation and Markdown workflow

```bash
command -v nvim
command -v oil || true
nvim --headless '+checkhealth' '+qa'
find ~/.config/nvim -maxdepth 3 -type f \( -name '*.nix' -o -name '*.lua' \) -printf '%P\n' 2>/dev/null | sort
```

The active editor must be the Nixvim package imported from `vim-conf`. Markdown buffers should expose Treesitter/Marksman support and the `render-markdown` setup. Mermaid notes should be testable through the pinned Mermaid commands or a trusted local preview when that optional layer is enabled; LaTeX math should remain ordinary Markdown source and render through the selected preview path rather than an Obsidian plugin.

Open a representative note from each active Vault area and verify that links, code fences, tables, Mermaid fences, and LaTeX expressions remain editable as plain Markdown. The workflow must not depend on `.obsidian`, Dataview, Templater, dashboard JavaScript, or an Obsidian process.

## Xournal++ integration

```bash
command -v xournalpp
ls -l ~/Vault/04\ -\ Xournal++/*.xopp 2>/dev/null || true
```

Use `livara-xournal-new-note` to create `04 - Xournal++/YYYY-MM-DD.xopp`, then open an existing `.xopp` from the file manager and from NixVim's file explorer. Xournal++ remains the only owner of the journal format and must not create a competing editor-specific path.

## Theme pipeline

```bash
THEME_ROOT="${LIVARA_THEME_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/livara/theme}"
test -s "$THEME_ROOT/palette.dark.json"
jq -e '(.primary | type == "string") and (.background | type == "string")' "$THEME_ROOT/palette.dark.json"
test -s ~/.config/nvim/lua/matugen_colors.lua
printf '\n--- generated theme state ---\n'
find "$THEME_ROOT" -maxdepth 3 -type f -printf '%P\n' | sort
```

After selecting another wallpaper through Noctalia, the generated `matugen_colors.lua` should change atomically. Restarting or reloading Nixvim must reapply the palette through `_G.reload_livara_theme`; the editor should remain transparent and should not require a generated CSS snippet in the Vault.

## Other application contracts

```bash
find "${XDG_STATE_HOME:-$HOME/.local/state}/livara/theme/browser" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | sort
find ~/.config/vesktop/themes -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | sort
find ~/.config/xournalpp/palettes -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | sort
find "$THEME_ROOT/telegram" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | sort
find "$THEME_ROOT/hydra/Livara" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | sort
for file in ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini ~/.config/wezterm/colors/Noctalia.toml ~/.config/nvim/lua/matugen_colors.lua; do
  test -s "$file" && printf 'ok %s\n' "$file" || printf 'missing %s\n' "$file"
done
```

Firefox profiles may link `userChrome.css` to the Noctalia-generated Firefox output through the shell bridge. Zen Browser `userChrome.css`, profiles, containers and session stores are owned by the declarative `nix-conf`/Noctalia integration and must be validated under each of `~/.config/zen/{personal,school,programming,hobby}`. Native GTK, Qt, Kitty and WezTerm files are owned by Noctalia templates; `shell-conf` must not overwrite those outputs with a static theme.

The theme adapter should report Telegram Desktop as generated when `telegram/Livara.tdesktop-theme` exists; selecting it is intentionally manual. Hydra should report `hydra/Livara/theme.css` as generated; publishing it requires the official `hydra-themes` workflow. IntelliJ IDEA and Android Studio should discover a `Matugen-Dark.icls` link under their versioned `colors` directories. Spotify should be provided by the Home Manager `programs.spicetify` module, not by cmus or an imperative player setup.

## Niri and input

```bash
niri validate --config ~/.config/niri/config.kdl
niri msg focused-output
niri msg workspaces
niri msg keyboard-layouts
```

The file should contain one `input` section, one `binds` section, `mod-key "Super"`, the four `Mod+WheelScroll*` binds with cooldown, and `spawn-at-startup "noctalia"`. `Mod+Shift+R` and `Mod+Ctrl+Shift+R` should invoke the two direct recorder wrappers. Brightness is tested separately with `brightnessctl --class=backlight info` and the `XF86MonBrightness*` events from the Latitude `Video Bus`.

## Keyboard, drivers and host capabilities

```bash
systemctl status keyd --no-pager -n 20
sudo keyd check
sudo keyd monitor
```

Validate NVIDIA/Wayland, PipeWire, portals, Bluetooth, the tablet udev rule and power-profile services through their system modules. These capabilities are intentionally not moved into the Noctalia or Nixvim configuration. The expected icon theme is `Livara-Kora` and the cursor is `Bibata-Modern-Classic`.


## Super+N and the NixOS configuration editor

The Super+N path is owned by Niri and exported directly by `shell-conf` as `open-nixos-nvim.sh`. The historical continuation prompt came from output emitted while Neovim was starting; setting `nomore` only with a post-init `-c` command left a window where startup messages could still trigger the pager.

The wrapper now passes `--cmd "set nomore"` and `--cmd "set shortmess+=F"` before the init files in the WezTerm, footclient and fallback paths, then opens the repository with Oil. Validate the static contract with:

```bash
~/.local/share/livara/scripts/validate-livara-shell.sh
bash -n ~/.local/share/livara/scripts/open-nixos-nvim.sh
```

A live session should open the NixOS repository without asking for a key. This check is intentionally separate from `nixos-rebuild`; no rebuild or boot-affecting operation is required to validate the wrapper.


## Matugen/NixVim path contract

NixVim/Home Manager generates the editable palette module at `~/.config/nvim/lua/matugen_colors.lua`. The theme synchronization script must write to that exact path; writing to `~/.config/nvim/matugen_colors.lua` leaves the editor using a stale or missing palette. The shell validator checks both the producer path and the absence of the legacy root-level path.
