## [Unreleased] - 2026-08-06

### Added
- **Niri Screenshot Keybinds**: Super+Shift+S (region), Super+S (fullscreen), Super+Ctrl+S (window)
- **Zen Browser Matugen Integration**: Auto-syncs DMS theme to Zen Browser chrome
- **Wallpaper Screenshot Directory**: ~/Pictures/Screenshots created automatically

### Fixed
- **WezTerm Missing Glyphs**: Switched to JetBrainsMono Nerd Font with fallback chain
- **DMS Theme Conflict**: Removed forced Catppuccin GTK theme, let DMS matugen control it
- **Cursor and Icon Integration**: Bibata cursor and kora icons now work correctly with DMS UI

## [Unreleased] - Integração WezTerm (2026-08-04)

### Added
- **WezTerm Theme Integration**: Adicionado módulo `wezterm.nix` para configurar o WezTerm para usar automaticamente o tema gerado pelo Matugen do DMS (`dank-theme.toml`).

### Changed
- **Home Manager Configuration**: Removido `wezterm` da lista de pacotes globais em `home.nix` (nix-conf), pois agora é gerenciado declarativamente pelo módulo `wezterm.nix` no `shell-conf`.
