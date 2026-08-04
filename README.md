# Shell Conf

Este repositório atua como um intermediário (wrapper) para o **DankMaterialShell (DMS)** e **Niri**, fornecendo uma configuração pronta para uso e pré-otimizada para NixOS.

## Arquitetura

O `shell-conf` consome os flakes upstream do DMS e Niri e re-exporta os módulos com configurações "opinadas":

- **DankMaterialShell**: Configurado com monitoramento de sistema, VPN, tema dinâmico e integração nativa com Niri.
- **Niri**: Configurado com atalhos de teclado complementares (Super+1..9 para workspaces, Super+W para Helium, etc), regras de janelas para arredondamento (radius 12) e variáveis de ambiente Wayland.
- **Tema**: Força o tema de ícones `kora` (via GTK e dconf) de forma declarativa, evitando conflitos com o gerador de cores dinâmicas do DMS.

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
