# Shell Conf

Este repositório atua como um intermediário (wrapper) para o **DankMaterialShell (DMS)** e **Niri**, fornecendo uma configuração pronta para uso e pré-otimizada para NixOS.

## Arquitetura

O `shell-conf` consome os flakes upstream do DMS e Niri e re-exporta os módulos com configurações "opinadas":

- **DankMaterialShell**: Configurado com monitoramento de sistema, VPN, tema dinâmico (matugen) e integração nativa com Niri.
- **Niri**: Configurado com atalhos de teclado complementares (Super+1..9 para workspaces, Super+W para Zen Browser), screenshot keybinds (Super+Shift+S, Super+S, Super+Ctrl+S), regras de janelas para arredondamento (radius 12) e variáveis de ambiente Wayland.
- **Tema**: Tema GTK controlado dinamicamente pelo DMS matugen. Ícones `kora` e cursor `Bibata-Modern-Classic` são aplicados declarativamente via GTK e dconf.
- **WezTerm**: Fonte JetBrainsMono Nerd Font com fallbacks, tema dinâmico via matugen (`dank-theme`).
- **Zen Browser**: Integração automática do tema DMS via matugen, com symlink para userChrome.css.

## Módulos

| Módulo | Responsabilidade |
|---|---|
| `dms.nix` | DankMaterialShell systemd, settings sync via inotifywait |
| `niri.nix` | Atalhos de teclado, regras de janela, screenshots |
| `theme.nix` | Ícones kora, cursor Bibata, cor escura |
| `wezterm.nix` | Nerd Fonts, tema matugen, opacity |
| `zen.nix` | Zen Browser theme sync via userChrome.css |

## Screenshot Keybinds

| Atalho | Ação |
|---|---|
| Super+Shift+S | Screenshot de região selecionada |
| Super+S | Screenshot de tela inteira |
| Super+Ctrl+S | Screenshot da janela ativa |

Todas as capturas são salvas em `~/Pictures/Screenshots/` com timestamp.

## Como usar no NixOS

Adicione ao seu `flake.nix`:

```nix
inputs = {
  shell-conf = {
    url = "github:Joaoferraz-byte/shell-conf";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

No seu `configuration.nix` (Módulo de sistema):

```nix
imports = [
  inputs.shell-conf.nixosModules.dankMaterialShell
];
```

No seu `home.nix` (Módulo do usuário):

```nix
imports = [
  inputs.shell-conf.homeManagerModules.default
];
```
