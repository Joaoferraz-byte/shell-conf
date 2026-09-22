# Livara runtime validation

This guide validates the application-adapter layer without assuming a particular shell. The selected shell or theme producer owns the canonical palette; `shell-conf` consumes the neutral files under `$XDG_STATE_HOME/livara/theme` and writes only documented application formats.

## Palette contract

The producer should provide `palette.json`, `palette.dark.json` and, when supported, `palette.light.json`. Each file must contain valid six-digit hexadecimal roles required by the enabled adapters. The synchronizer selects the requested `dark` or `light` variant, validates it before writing any destination, and records an explicit fallback to `palette.json` when a separate variant is unavailable. Invalid input must preserve the previous generated outputs.

```bash
THEME_ROOT="${LIVARA_THEME_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/livara/theme}"
test -s "$THEME_ROOT/palette.dark.json"
jq -e '(.base | strings | test("^#[0-9A-Fa-f]{6}$")) and (.blue | strings | test("^#[0-9A-Fa-f]{6}$"))' "$THEME_ROOT/palette.dark.json"
sha256sum "$THEME_ROOT/palette.dark.json"
```

## Applications

Firefox and Zen consume the generated `browser/firefox.css` only through their declarative profile owner. WezTerm consumes the selected TOML scheme from its `colors` directory, btop consumes the generated `.theme`, and Fastfetch consumes `fastfetch.jsonc` through the `livara-fastfetch` wrapper. GTK files generated here provide the palette projection and dark/light preference for GTK3/GTK4 applications such as GParted; libadwaita remains toolkit-owned and GTK applications need a restart. Qt/KDE uses its configured platform/color scheme. NixVim, Xournal++, Foliate, KDE/Okular, Nuclear, Hydra Launcher, IntelliJ IDEA and Android Studio must be checked only when their documented profiles or state roots exist.

For each adapter, distinguish `generated`, `selected`, `loaded` and `confirmed`. The existence of a file is not proof that an application imported or selected it. GTK3/GTK4, Firefox/Zen, FreeSM, Vesktop and Xournal++ generally need an application restart after an external file change; WezTerm, Neovim, btop and JavaFX Study Planner reload through their documented watcher or signal path. No logout is required for these file-based transitions, and the synchronizer never overwrites an application-owned profile while it is running.

## Session and ownership

The selected shell is the only owner of bars, docks, launchers, panels, compositor IPC and layer-shell reservations. `shell-conf` must not start a shell, create a second panel, define compositor shortcuts or emulate exclusive zones. Niri owns window rules, workspace definitions and key bindings; application commands are separate packages or scripts with explicit contracts.

No full system build is required for this guide. Use `bash -n`, focused fixture tests, `git diff --check`, and documented application validators. Runtime visual validation must be performed on the real Wayland session after the declarative configuration has been activated.

## References

[1]: https://docs.noctalia.dev/noctalia/theming/palette/ "Noctalia palette contract"
[2]: https://docs.noctalia.dev/noctalia/theming/app-theming/ "Noctalia application theming"
[3]: https://docs.zen-browser.app/guides/live-editing "Zen Browser live editing"
[4]: https://wezterm.org/config/appearance.html "WezTerm appearance configuration"
[5]: https://docs.gtk.org/gtk4/css-overview.html "GTK CSS overview"
[6]: https://doc.qt.io/qt-6/stylesheet.html "Qt Style Sheets"
