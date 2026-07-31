# shell-conf — Ambxst-X para NixOS e Hyprland

Este repositório contém a camada declarativa do usuário para o shell [Ambxst-X](https://github.com/OrynVail/Ambxst-X) em NixOS. Ele não é um fork completo do shell QML: consome o pacote e o módulo NixOS mantidos pelo upstream via flake, injetando correções específicas de runtime e versionando os JSONs de personalização locais para integração com o Home Manager.

## Arquitetura (Hyprland + axctl)

| Camada | Responsabilidade | Fonte de verdade |
|---|---|---|
| `flake.nix` | Reexporta o pacote e o módulo NixOS oficiais do Ambxst-X, aplicando um `patchedSource` com correções críticas. Expõe o módulo Home Manager local. | `OrynVail/Ambxst-X` e `flake.lock` |
| `settings/*.json` | Define tema, barra, compositor, workspaces, dock, notch e demais adaptadores lidos pelo shell. | Este repositório |
| Ambxst-X | Inicia Quickshell, produz `~/.local/state/ambxst/axctl.toml` e inicializa o daemon `axctl`. | Pacote upstream + Patches locais |
| `axctl` | Aplica o TOML ao compositor via IPC e gera `hyprland.lua`. | Pacote upstream |
| `nix-conf` | Gera a configuração principal do sistema e carrega dinamicamente o `hyprland.lua` gerado pelo Ambxst-X. | Repositório do sistema |

> **Nota de Migração**: O setup anterior utilizava Niri, mas foi totalmente migrado para Hyprland. O Hyprland 0.55+ prefere Lua, e o Home Manager 26.05+ gera `hyprland.lua` por padrão. A integração correta é via `loadfile(.../ambxst/hyprland.lua)()` no `extraConfig` do Hyprland, protegida contra ausência do arquivo no primeiro boot.

## Patches e Riscos de Manutenção

Para contornar falhas de `patch` e garantir o funcionamento no NixOS, o `flake.nix` deste repositório substitui integralmente **seis arquivos QML** do upstream. Isso introduz um risco de manutenção, pois atualizações no upstream (novas funcionalidades, como OSD ou Screenshot Tools) não serão refletidas automaticamente nestes arquivos:

1. **`shell.qml`**: Modificado para forçar o bootstrap do `PresetsService` e injetar o `CompositorKeybinds` e `CompositorTomlWriter`. A versão local foi recentemente sincronizada com o upstream para recuperar as tools avançadas (screen record, mirror, settings).
2. **`AxctlService.qml`**: Modificado para usar `XDG_STATE_HOME` e garantir a ordem de inicialização (só sobe o daemon axctl após o TOML ser escrito).
3. **`CompositorTomlWriter.qml`**: Modificado para usar `XDG_STATE_HOME` e disparar o `AxctlService` no callback de sucesso.
4. **`PresetsService.qml`**: Modificado para buscar presets no `AMBXST_CONFIG_ROOT` (injetado via launcher do Nix).
5. **`Config.qml`**: Modificado para apontar o diretório de config para `AMBXST_CONFIG_ROOT`.
6. **`Workspaces.qml`**: Ajustes estéticos e de animação.

**Aviso**: Ao atualizar a revisão do `Ambxst-X` no `flake.lock`, verifique se o upstream alterou esses arquivos e incorpore as mudanças manualmente na pasta `files/`.

## Configurações Versionadas

| Arquivo | Função |
|---|---|
| `theme.json` | Paleta, fontes, arredondamento e componentes visuais. |
| `bar.json`, `workspaces.json`, `overview.json`, `notch.json` | Barra, navegação e superfícies de produtividade. |
| `compositor.json` | Valores dinâmicos de gaps, bordas, sombra, blur e animações enviados ao axctl. |
| `desktop.json`, `dock.json`, `lockscreen.json` | Desktop, dock e lockscreen do shell. |
| `performance.json`, `system.json` | Perfil de desempenho, idle, OCR e recursos de sistema. |
| `weather.json`, `prefix.json` | Defaults explícitos para todos os adaptadores que o Ambxst-X atual carrega. |

Os arquivos são semeados pelo Home Manager no primeiro login em `~/.local/state/ambxst/config/` (o novo runtime root mutável). Para alterar o comportamento persistente inicial, edite o JSON correspondente neste repositório.

## Binds e Inicialização

O arquivo `binds.json` vive em `~/.local/state/ambxst/binds.json` e **não** é gerenciado como link imutável pelo Home Manager. O Ambxst-X atualiza esse arquivo com seus próprios atalhos por meio do `axctl`; essa decisão evita conflito entre a UI do shell e o gerenciador declarativo.

Os atalhos básicos e de recuperação (emergência) pertencem ao `nix-conf/modules/features/hyprland.nix`. O `axctl` cuida dos atalhos específicos do shell.

## Uso no `nix-conf`

O flake do sistema consome este repositório como input:

```nix
inputs.shell-conf = {
  url = "github:Joaoferraz-byte/shell-conf";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

O módulo local do sistema (`ambxst.nix`) importa o módulo reexportado e adiciona o módulo Home Manager:

```nix
imports = [
  inputs.shell-conf.nixosModules.default
];

home-manager.sharedModules = [
  inputs.shell-conf.homeManagerModules.default
];
```

## Referências

* [Ambxst-X (Upstream)](https://github.com/OrynVail/Ambxst-X)
* [axctl](https://github.com/Axenide/axctl)
* [Hyprland Lua configuration](https://wiki.hypr.land/Configuring/Start/)
