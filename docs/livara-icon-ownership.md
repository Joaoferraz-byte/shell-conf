# Livara icon ownership

The active Ambxst session owns the bar, dock, launcher and shell surfaces. This repository owns only application adapters and shell-neutral support files; it must not install a Noctalia launcher asset or attempt to paint the Ambxst dock.

Noctalia icon notes remain relevant only when the optional `homeModules.support` compatibility module is deliberately selected. They are not part of the active `nix-conf` composition, which imports `ambxst-conf.homeModules.default` and `shell-conf.homeModules.support-core`.

The Fastfetch cat asset is an application adapter asset. It is generated from the canonical Livara palette and is independent from shell launcher or dock icons.
