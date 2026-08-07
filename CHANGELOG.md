## [Unreleased] - 2026-08-06

### Fixed
- **Wallpaper IPC Keybinds**: Use the documented DMS `wallpaper next` and `wallpaper prev` functions instead of the nonexistent `cycleNext` and `cyclePrevious` names.

### Added
- **Niri Screenshot Keybinds**: Super+Shift+S (region), Super+S (fullscreen), Super+Ctrl+S (window)
- **Zen Browser Matugen Integration**: Auto-syncs DMS theme to Zen Browser chrome
- **Wallpaper Screenshot Directory**: ~/Pictures/Screenshots created automatically

### Fixed
- **WezTerm Missing Glyphs**: Switched to JetBrainsMono Nerd Font with fallback chain
- **DMS Theme Conflict**: Removed forced Catppuccin GTK theme, let DMS matugen control it
- **Cursor and Icon Integration**: Bibata cursor and kora icons now work correctly with DMS UI

### Added
- **Wallpaper Cycling Default Enabled**: `dms-session.json` now sets `wallpaperCyclingEnabled = true` by default (previously `false`)
- **Manual Wallpaper Cycling Keybinds**: `Mod+Ctrl+Shift+W` (next wallpaper) and `Mod+Alt+Shift+W` (previous wallpaper) added to Niri
- **Zen Browser DMS Preferences**: Added `zen.urlbar.behavior = float`, `zen.view.compact.hide-tabbar = false`, `zen.workspaces.continue-where-left-off = true`, smooth scrolling with `msdPhysics` inertia

### Fixed
- **Wallpaper Cycling Not Working**: Fixed `wallpaperCyclingEnabled` being set to `false` in the declarative `dms-session.json` (now `true`)
- **Zen Browser Theme**: Nix-conf now uses runtime symlink via `home.activation` instead of `@import url("file://...")` which was blocked by Chrome CSP

## [Unreleased] - Integração WezTerm (2026-08-04)

### Added
- **WezTerm Theme Integration**: Adicionado módulo `wezterm.nix` para configurar o WezTerm para usar automaticamente o tema gerado pelo Matugen do DMS (`dank-theme.toml`).

### Changed
- **Home Manager Configuration**: Removido `wezterm` da lista de pacotes globais em `home.nix` (nix-conf), pois agora é gerenciado declarativamente pelo módulo `wezterm.nix` no `shell-conf`.
