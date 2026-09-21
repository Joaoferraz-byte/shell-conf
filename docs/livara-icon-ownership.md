# Livara icon ownership

The selected desktop shell owns the bar, dock, launcher and shell surfaces. This repository owns only application adapters and shell-neutral support files; it must not install a competing launcher asset or paint a shell-owned dock.

The Fastfetch cat asset is an application adapter asset. It is generated from the canonical Livara palette and is independent from shell launcher or dock icons. GTK icon-theme preferences are stable desktop preferences; they do not recolor application or shell SVG assets.
