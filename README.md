# shell-conf — Ambxst para NixOS + Niri

Repositório de configuração do shell [Ambxst](https://github.com/Axenide/Ambxst) para NixOS com o compositor [Niri](https://github.com/YaLTeR/niri).

## Arquitetura

Este flake empacota o Ambxst para NixOS, garantindo compatibilidade com o Niri via [axctl](https://github.com/Axenide/axctl) — o daemon IPC universal que abstrai a comunicação com o compositor.

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
│   └── workspaces.json # Configuração de workspaces
└── README.md
```

## Como funciona

### Integração com o Niri

O Ambxst usa o `axctl` para se comunicar com o Niri. O `axctl` detecta automaticamente o compositor via `NIRI_SOCKET` e expõe uma API JSON-RPC unificada.

O Niri envia comandos para o Ambxst via pipe FIFO (`/tmp/ambxst_ipc.pipe`), que é escutado pelo `GlobalShortcuts.qml` do Ambxst.

### Configuração declarativa em JSON

As configurações base são gerenciadas pelo Home Manager e copiadas para `~/.config/ambxst/config/`. Para customizar, edite os arquivos em `settings/` e faça `nixos-rebuild switch`.

### Keybinds

Os keybinds são definidos em `~/.config/ambxst/binds.json` (gerenciado pelo Home Manager). O Niri envia os comandos via pipe IPC, evitando conflitos de keybinds.

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

No `modules/features/niri.nix`, configure o `spawn-at-startup`:

```nix
spawn-at-startup = [
  { command = [ "ambxst" ]; }
];
```

## Referências

- [Ambxst](https://github.com/Axenide/Ambxst) — Shell Quickshell original
- [axctl](https://github.com/Axenide/axctl) — Daemon IPC para Wayland compositors
- [Niri](https://github.com/YaLTeR/niri) — Compositor Wayland scrolling
- [Quickshell](https://quickshell.org) — Framework QML para shells Wayland
