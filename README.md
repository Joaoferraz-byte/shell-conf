# shell-conf — Caelestia Shell para NixOS + Hyprland

Repositório de configuração do [Caelestia Shell](https://github.com/caelestia-dots/shell) para NixOS com o compositor Hyprland.

Este repositório **não empacota** o Caelestia — ele apenas fixa a versão (`inputs.caelestia-shell.follows`/`inputs.nixpkgs.follows`) e expõe um módulo fino de Home Manager com as preferências deste usuário. Toda a lógica de build vive em `caelestia-dots/shell` e é consumida como flake input.

## Arquitetura

```
shell-conf/
├── flake.nix   # Fixa caelestia-shell + nixpkgs, expõe homeManagerModules.default e pacotes
└── README.md
```

As preferências do usuário são um único attrset Nix (`programs.caelestia.settings`), que o próprio Caelestia já expõe como opção estruturada através do seu módulo home-manager.

## Como funciona

- **Empacotamento:** vem 100% de `caelestia-shell.packages.${system}.default`, sem patches locais.
- **Integração:** O Caelestia é ativado via `programs.caelestia.enable = true`. O serviço systemd é desabilitado intencionalmente (`systemd.enable = false`) porque a sessão gráfica é gerenciada pelo UWSM, alinhado com as configurações de Hyprland no `nix-conf`.
- **Configuração:** Configurações como terminal padrão (`kitty`), áudio (`pavucontrol`), diretório de wallpapers e visibilidade da bateria estão declaradas diretamente em `programs.caelestia.settings`.

## Integração no nix-conf

No `nix-conf`, no `flake.nix`:

```nix
inputs.shell-conf = {
  url = "github:Joaoferraz-byte/shell-conf";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

No home-manager do usuário:

```nix
imports = [ inputs.shell-conf.homeManagerModules.default ];
```

E no módulo NixOS para as dependências de sistema, caso o Caelestia venha a prover opções de sistema no futuro (atualmente é um fallback vazio para evitar quebras).
