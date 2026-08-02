# shell-conf — DankMaterialShell para NixOS + Niri

Repositório de configuração do shell [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
(DMS) para NixOS com o compositor [Niri](https://github.com/YaLTeR/niri).

Este repositório **não empacota** o DMS — ele apenas fixa a versão
(`inputs.dms.follows`/`inputs.nixpkgs.follows`) e expõe um módulo fino de
Home Manager com as preferências deste usuário. Toda a lógica de build,
QML e Go vive em `AvengeMedia/DankMaterialShell` e é consumida como flake
input, exatamente como recomendado pelos mantenedores do projeto.

## Arquitetura

```
shell-conf/
├── flake.nix   # Fixa dms + nixpkgs, expõe homeManagerModules.default
└── README.md
```

Comparado ao setup anterior (Ambxst-X): não há mais `settings/*.json`
copiados manualmente por ativação do Home Manager, nem QML remendado por
cima do pacote upstream. As preferências do usuário são um único attrset
Nix (`programs.dank-material-shell.settings`), que o próprio DMS já expõe
como opção estruturada.

## Como funciona

- **Empacotamento:** vem 100% de `dms.packages.${system}.dms-shell`
  (Go + QML), sem patches locais.
- **Integração com o Niri:** o DMS roda como serviço `systemd --user`
  (`dms.service`), não via `spawn-at-startup` do Niri — esse é o caminho
  oficialmente recomendado pelos docs do DMS quando o compositor roda como
  sessão systemd (que é o padrão em NixOS).
- **Config do Niri:** deliberadamente **não** usamos o módulo
  `dms.homeModules.niri` nem `programs.dank-material-shell.niri.includes`.
  Esse "hack" de include não gera os fragmentos `niri/dms/*.kdl` quando o
  `config.kdl` do Niri é gerenciado declarativamente pelo Home Manager
  (arquivo fica no `/nix/store`, somente leitura) — isso é uma causa
  conhecida da shell travar na tela de carregamento do Quickshell sem
  nunca terminar de subir (ver
  [AvengeMedia/DankMaterialShell#1788](https://github.com/AvengeMedia/DankMaterialShell/issues/1788)).
  Se você quiser keybinds/includes específicos do DMS no Niri, gere os
  fragmentos uma vez com `dms setup --niri` fora do Nix store e traga-os
  para o flake como texto estático.

## Integração no nix-conf

No `nix-conf`, no `flake.nix`:

```nix
inputs.shell-conf = {
  url = "github:Joaoferraz-byte/shell-conf";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

No home-manager do usuário (não em `configuration.nix` a nível de sistema —
isto é um programa de usuário):

```nix
imports = [ inputs.shell-conf.homeManagerModules.default ];

programs.dank-material-shell.systemd.enable = true;
```

Veja `nix-conf_niri-e-home_snippet.nix` para o trecho completo, incluindo o
que **não** habilitar.

## ⚠️ Antes de rodar `nixos-rebuild`

Os nomes de opção usados aqui (`programs.dank-material-shell.settings`,
`.systemd.enable`, `.systemd.target`, `.niri.enableSpawn`,
`.niri.includes`) foram confirmados contra o `flake.nix` e a documentação
oficial do DMS em 02/08/2026, mas esse projeto evolui rápido. Antes de
aplicar:

```bash
nix flake show github:AvengeMedia/DankMaterialShell
# e/ou
nix eval github:AvengeMedia/DankMaterialShell#homeModules.dank-material-shell --apply builtins.attrNames
```

para confirmar que as opções ainda existem com esses nomes na revisão que
você travou no `flake.lock`.

## Referências

- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) — shell Quickshell + Go
- [Docs oficiais](https://danklinux.com/docs/dankmaterialshell/) — instalação, compositores, IPC
- [Niri](https://github.com/YaLTeR/niri) — compositor Wayland scrolling
- [Quickshell](https://quickshell.org) — framework QML para shells Wayland
