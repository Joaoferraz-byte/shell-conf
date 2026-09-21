# Livara application support

This repository provides application adapters and small user-session helpers for Home Manager. It does not provide a compositor, desktop shell, layer-shell panels, a wallpaper daemon, an idle daemon or shell-specific IPC.

The selected shell or theme producer owns the visible desktop surfaces and publishes the neutral palette consumed from `$XDG_STATE_HOME/livara/theme`. `shell-conf` owns only the generated application contracts. Firefox/Zen profile ownership remains in the declarative desktop configuration; this repository produces the profile-consumable CSS. WezTerm selects a documented color scheme generated from the same palette. GTK files contain stable icon and dark-mode preferences, while native GTK/libadwaita and Qt styles remain toolkit-owned.

Run focused shell tests and `bash -n` for scripts. Use `git diff --check` for changes. A full NixOS or Home Manager build is not required for repository-level checks and must be performed only on the target machine when the complete system configuration is intentionally activated.

## References

[1]: https://docs.noctalia.dev/noctalia/theming/palette/ "Noctalia palette contract"
[2]: https://docs.noctalia.dev/noctalia/theming/app-theming/ "Noctalia application theming"
[3]: https://docs.zen-browser.app/guides/live-editing "Zen Browser live editing"
[4]: https://wezterm.org/config/appearance.html "WezTerm appearance configuration"
[5]: https://docs.gtk.org/gtk4/css-overview.html "GTK CSS overview"
[6]: https://doc.qt.io/qt-6/stylesheet.html "Qt Style Sheets"
