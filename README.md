# shell-conf — Ambxst-X para NixOS e Hyprland

Este repositório contém a camada declarativa do usuário para o shell [Ambxst-X](https://github.com/OrynVail/Ambxst-X) em NixOS. Ele não é um fork do shell QML: consome o pacote e o módulo NixOS mantidos pelo upstream, enquanto versiona os JSONs de personalização locais e os disponibiliza ao Home Manager.

## Arquitetura

| Camada | Responsabilidade | Fonte de verdade |
|---|---|---|
| `flake.nix` | Reexporta o pacote e o módulo NixOS oficiais do Ambxst-X; expõe o módulo Home Manager local. | `OrynVail/Ambxst-X` e `flake.lock` |
| `settings/*.json` | Define tema, barra, compositor, workspaces, dock, notch e demais adaptadores lidos pelo shell. | Este repositório |
| Ambxst-X | Inicia Quickshell, produz `~/.local/share/ambxst/axctl.toml` e inicializa o daemon `axctl`. | Pacote upstream |
| `axctl` | Aplica o TOML ao compositor e gera `hyprland.conf` e `hyprland.lua`. | Pacote upstream |
| `nix-conf` | Gera a configuração principal em Lua e carrega, com proteção, o bloco `hyprland.lua` do Ambxst-X. | Repositório do sistema |

> O Hyprland 0.55 passou a preferir Lua, e o Home Manager 26.05 também gera `hyprland.lua` por padrão. Logo, a integração correta é `loadfile(.../ambxst/hyprland.lua)()` protegida contra arquivo ausente — não uma linha `source = ...hyprland.conf` dentro de Lua. Consulte a [documentação de binds](https://wiki.hypr.land/Configuring/Basics/Binds/) e a [migração oficial de configuração](https://wiki.hypr.land/Configuring/Start/).

## Configurações versionadas

| Arquivo | Função |
|---|---|
| `theme.json` | Paleta, fontes, arredondamento e componentes visuais. |
| `bar.json`, `workspaces.json`, `overview.json`, `notch.json` | Barra, navegação e superfícies de produtividade. |
| `compositor.json` | Valores dinâmicos de gaps, bordas, sombra, blur e animações enviados ao axctl. |
| `desktop.json`, `dock.json`, `lockscreen.json` | Desktop, dock e lockscreen do shell. |
| `performance.json`, `system.json` | Perfil de desempenho, idle, OCR e recursos de sistema. |
| `weather.json`, `prefix.json` | Defaults explícitos para todos os adaptadores que o Ambxst-X atual carrega. |

Os arquivos são vinculados para `~/.config/ambxst/config/` pelo Home Manager. Para alterar comportamento persistente, edite o JSON correspondente neste repositório e aplique o rebuild da configuração Nix.

## Binds e inicialização

O `binds.json` fica em `~/.config/ambxst/binds.json`, mas **não** é gerenciado como link imutável pelo Home Manager. O Ambxst-X atual cria, migra e atualiza esse arquivo com seus próprios atalhos por meio do `axctl`; essa decisão evita conflito entre a UI do shell e o gerenciador declarativo de arquivos.

Os atalhos básicos e de recuperação pertencem ao `nix-conf/modules/features/hyprland.nix`. Os atalhos específicos do shell são gerados pelo Ambxst-X. No primeiro login, antes de `hyprland.lua` existir, a configuração principal inicia o Ambxst-X de forma segura; nas sessões seguintes, o arquivo gerado pelo axctl contém o startup normal do shell. Esse desenho evita tanto uma dependência circular no primeiro boot quanto registros duplicados de atalhos.

## Uso no `nix-conf`

O flake do sistema deve seguir o mesmo `nixpkgs`:

```nix
inputs.shell-conf = {
  url = "github:Joaoferraz-byte/shell-conf";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

O módulo local do sistema importa o módulo reexportado e adiciona o módulo Home Manager:

```nix
imports = [
  inputs.shell-conf.nixosModules.default
];

home-manager.sharedModules = [
  inputs.shell-conf.homeManagerModules.default
];
```

A configuração do Hyprland deve permanecer em Lua e carregar condicionalmente `~/.local/share/ambxst/hyprland.lua`. Não execute `ambxst install hyprland`: esse subcomando edita `~/.config/hypr` imperativamente e conflita com o arquivo gerenciado pelo Home Manager.

## Referências

[Ambxst-X](https://github.com/OrynVail/Ambxst-X) · [axctl](https://github.com/Axenide/axctl) · [Hyprland Lua configuration](https://wiki.hypr.land/Configuring/Start/) · [Home Manager Hyprland module](https://nix-community.github.io/home-manager/options.xhtml#opt-wayland.windowManager.hyprland.configType)
