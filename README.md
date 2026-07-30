# shell-conf — Ambxst-X para NixOS + Hyprland

Repositório de configuração do shell [Ambxst-X](https://github.com/OrynVail/Ambxst-X) para NixOS com o compositor [Hyprland](https://hyprland.org).

## Arquitetura

Este flake empacota o Ambxst para NixOS, garantindo compatibilidade com o Hyprland via [axctl](https://github.com/Axenide/axctl) — o daemon IPC universal que abstrai a comunicação com o compositor.

```
shell-conf/
├── flake.nix          # Flake principal: empacota o Ambxst + axctl
├── settings/          # Configurações base em JSON (gerenciadas pelo Nix)
│   ├── theme.json     # Tema visual (cores, fontes, arredondamento)
│   ├── bar.json       # Configuração da barra
│   ├── compositor.json # Aparência do compositor (gaps, bordas, blur)
│   ├── desktop.json   # Widgets de desktop
│   ├── dock.json      # Dock de aplicativos
│   ├── overview.json  # Overview de workspaces
│   ├── performance.json # Modo de performance
│   ├── lockscreen.json # Tela de bloqueio
│   ├── notch.json     # Configuração do notch
│   ├── system.json    # Configuração do sistema (idle, OCR, pomodoro)
│   └── workspaces.json # Configuração de workspaces
├── shell.qml          # Shell QML principal (Quickshell)
├── modules/           # Componentes QML reutilizáveis
│   ├── bar/           # Barra principal
│   └── widgets/       # Widgets reutilizáveis
└── README.md
```

## Como funciona

### Integração com o Hyprland

O Ambxst-X usa o `axctl` para se comunicar com o Hyprland. O `axctl` detecta automaticamente o compositor e expõe uma API JSON-RPC unificada.

O Hyprland envia comandos para o Ambxst-X via pipe FIFO (`/tmp/ambxst_ipc.pipe`), que é escutado pelo `GlobalShortcuts.qml` do Ambxst-X.

### Configuração declarativa em JSON

As configurações base são gerenciadas pelo Home Manager e copiadas para `~/.config/ambxst/config/`. Para customizar, edite os arquivos em `settings/` e faça `nixos-rebuild switch`.

### Keybinds

Os keybinds são definidos em `~/.config/ambxst/binds.json` (gerenciado pelo Home Manager). O Hyprland envia os comandos via pipe IPC, evitando conflitos de keybinds.

## Integração no nix-conf

No `nix-conf`, adicione ao `flake.nix`:

```nix
inputs = {
  shell-conf = {
    url = "github:Joaoferraz-byte/shell-conf";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

No `modules/hosts/my-machine/configuration.nix`:

```nix
imports = [
  # ...
  self.nixosModules.ambxst
];
```

No `modules/features/hyprland.nix`, configure o `exec-once`:

```nix
exec-once = [
  "ambxst"
];
```

## Referências

- [Ambxst-X](https://github.com/OrynVail/Ambxst-X) — Shell Quickshell com suporte Hyprland
- [axctl](https://github.com/Axenide/axctl) — Daemon IPC para Wayland compositors
- [Hyprland](https://hyprland.org) — Compositor Wayland dinâmico
- [Quickshell](https://quickshell.org) — Framework QML para shells Wayland
