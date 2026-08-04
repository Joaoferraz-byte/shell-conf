
## [Unreleased] - Integração WezTerm (2026-08-04)

### Added
- **WezTerm Theme Integration**: Adicionado módulo `wezterm.nix` para configurar o WezTerm para usar automaticamente o tema gerado pelo Matugen do DMS (`dank-theme.toml`).

### Changed
- **Home Manager Configuration**: Removido `wezterm` da lista de pacotes globais em `home.nix` (nix-conf), pois agora é gerenciado declarativamente pelo módulo `wezterm.nix` no `shell-conf`.
