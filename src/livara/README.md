# Livara application-support assets

This repository contains application adapters, templates and small user-session helpers consumed by Home Manager. It is not a compositor, desktop shell, session manager, wallpaper service or layer-shell panel.

The selected shell or theme producer owns the visible bar, launcher, panels, wallpaper and palette. This repository consumes a neutral palette under `$XDG_STATE_HOME/livara/theme` and writes only documented application formats. Generated files remain mutable runtime outputs outside the Nix store.

Fastfetch uses the transparent cat asset from `src/livara/assets/fastfetch-cat.png`. The theme adapter recolors only opaque pixels with the active `primary` role and preserves alpha edges. The application adapter does not recolor shell launcher or dock icons.

The runtime contract is dark-first and wallpaper-derived when the selected palette producer supports that mode. Xournal++ receives a drawing palette only. Firefox/Zen receive a profile-consumable CSS file. WezTerm receives a selected color scheme. NixVim, Foliate, Hydra and KDE/Okular adapters write their documented formats only when their application roots exist.

IDE editor color schemes and UI themes are outside the active Livara adapter contract; no IDE files or plugins are generated.

GTK settings generated here select icon theme and dark preference. Native GTK/libadwaita styles remain toolkit-owned. Qt applications retain their configured platform theme. The repository does not install a second shell process, compositor, wallpaper daemon, idle daemon or shell-specific IPC layer.
