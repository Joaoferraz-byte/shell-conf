# shell-conf

## Visão geral

Este repositório fornece uma **integração Nix reproduzível do Ambxst-X para NixOS, Home Manager e Hyprland**. A fonte completa do Ambxst está incorporada em `vendor/ambxst`; a flake constrói essa cópia local diretamente, em vez de aplicar uma camada de patches sobre uma fonte remota durante a avaliação.

> **Princípio de manutenção:** o código do shell, a integração Nix e os ajustes de compatibilidade são versionados juntos. Atualizações upstream devem ser revisadas e incorporadas conscientemente à árvore vendorizada, nunca executadas por instaladores imperativos no sistema do usuário.

| Camada | Responsabilidade | Fonte de verdade |
|---|---|---|
| `vendor/ambxst/` | Código QML, launcher, módulo NixOS e pacote Ambxst auditados. | Este repositório |
| `flake.nix` | Expõe o pacote, aplicativo e módulo NixOS consumidos pelo `nix-conf`. | Este repositório |
| `settings/*.json` | Valores iniciais editáveis de tema, barra, compositor, workspaces e widgets. | Este repositório |
| Estado em `XDG_STATE_HOME/ambxst` | Configuração mutável criada e mantida pelo Ambxst durante o uso. | Perfil do usuário |
| `axctl` | Aplica regras e atalhos dinâmicos ao compositor por IPC. | Input fixado em `flake.lock` |
| `nix-conf` | Declara sessão, dependências de desktop e os atalhos de recuperação mínimos. | Repositório de sistema |

## Estrutura e integração

A flake raiz não depende de um input remoto do Ambxst. Ela importa `vendor/ambxst/nix/packages/default.nix`, passa a árvore vendorizada como fonte e exporta `packages.<system>.ambxst`, `apps.<system>.default`, `nixosModules.default` e `homeManagerModules.default`. O `nix-conf` consome os módulos NixOS e Home Manager diretamente.

O uso esperado no flake do sistema é o seguinte:

```nix
inputs.shell-conf = {
  url = "github:Joaoferraz-byte/shell-conf";
  inputs.nixpkgs.follows = "nixpkgs";
};

# Em um módulo NixOS
imports = [ inputs.shell-conf.nixosModules.default ];

home-manager.sharedModules = [
  inputs.shell-conf.homeManagerModules.default
];
```

A saída `homeManagerModules` é uma convenção amplamente usada por flakes que exportam módulos Home Manager. Ela é uma extensão de terceiros e, por isso, pode gerar um aviso informativo de saída desconhecida no `nix flake check`; esse aviso não invalida a avaliação nem indica uma API legada. [1] [2]

## Ciclo de inicialização

A inicialização foi deliberadamente separada para impedir duplicação de processos, carregamento de estado antigo e colisões de atalhos.

| Etapa | Componente responsável | Resultado |
|---|---|---|
| 1 | Ativação do Home Manager | Semeia `settings/*.json` apenas quando o arquivo mutável ainda não existe. Migra conteúdo local antigo sem criar links para a store. |
| 2 | `ambxst` | Inicia o Quickshell usando a árvore vendorizada e exporta `AMBXST_CONFIG_ROOT`. |
| 3 | `CompositorTomlWriter` | Grava `axctl.toml` no diretório de estado mutável. |
| 4 | `AxctlService` | Inicia o daemon somente após uma gravação bem-sucedida do TOML. A inicialização é idempotente. |
| 5 | `axctl` | Confirma a disponibilidade do IPC e aplica regras e atalhos dinâmicos ao Hyprland. |
| 6 | `CompositorKeybinds` | Aguarda o IPC do `axctl` antes de enviar um lote de unbinds e binds do Ambxst. |

O `nix-conf` inicia o shell uma única vez no evento Lua `hyprland.start`. A antiga tentativa de chamar `settings.exec_once` foi removida porque não existe essa propriedade na API Lua; a documentação do Hyprland recomenda uma configuração baseada na API Lua quando `configType = "lua"`. [3] [4]

## Estado persistente e personalização

Os valores distribuídos em `settings/` são **defaults de primeira inicialização**, não arquivos imutáveis do Home Manager. Eles são copiados para os caminhos abaixo e podem ser alterados pela interface do Ambxst sem falhar por tentativas de escrita em links da Nix store.

| Caminho | Conteúdo |
|---|---|
| `${XDG_STATE_HOME:-$HOME/.local/state}/ambxst/config/` | Arquivos JSON de tema, painel, compositor, desktop, dock, lockscreen e demais adaptadores. |
| `${XDG_STATE_HOME:-$HOME/.local/state}/ambxst/binds.json` | Atalhos configuráveis pelo Ambxst. |
| `${XDG_STATE_HOME:-$HOME/.local/state}/ambxst/presets/` | Presets criados pelo usuário. |
| `${XDG_STATE_HOME:-$HOME/.local/state}/ambxst/axctl.toml` | Configuração entregue ao daemon `axctl`. |

Para alterar o padrão de novas instalações, edite o JSON correspondente em `settings/`. Para alterar a configuração do usuário já inicializada, use a interface do Ambxst ou o arquivo no diretório de estado. Não modifique arquivos dentro de `/nix/store`.

## Autoridade sobre compositor e atalhos

A configuração é dividida por responsabilidade. O Hyprland mantém apenas ambiente de sessão, dispositivos e saídas de recuperação. O Ambxst e o `axctl` são a única autoridade para ajustes dinâmicos de aparência, workspaces, regras e atalhos do shell.

| Atalho | Autoridade | Função |
|---|---|---|
| `SUPER + T` | Ambxst | Abre a interface de gerenciamento de terminais/tmux do shell. |
| `SUPER + Return` | `nix-conf` | Recuperação: abre `kitty`. |
| `SUPER + R` | `nix-conf` | Recuperação: executa `ambxst reload`. |
| `SUPER + SHIFT + Q` | `nix-conf` | Recuperação: encerra a sessão por `uwsm stop`. |

Os três atalhos de recuperação foram comparados com os defaults do Ambxst e não reutilizam `SUPER + T`. O serviço de keybinds do shell remove e recria apenas os atalhos que ele próprio administra; não toca nos três atalhos declarados no módulo Hyprland.

## Validação e manutenção

A validação estática recomendada é:

```bash
nix flake check --no-build
nix build --dry-run --no-link .#packages.x86_64-linux.ambxst
```

Antes de atualizar o Ambxst upstream, compare a árvore completa com `vendor/ambxst`, revise as mudanças em QML, no launcher e nos módulos Nix e então integre a revisão como uma atualização explícita da fonte vendorizada. Antes de atualizar `axctl`, execute novamente os comandos acima e avalie os hosts consumidores no `nix-conf`.

## Referências

[1]: https://discourse.nixos.org/t/nixos-home-manager-config-where-both-use-flakes/41410 "NixOS + Home Manager config where both use flakes"
[2]: https://discourse.nixos.org/t/custom-flake-outputs-for-checks/18877 "Custom flake outputs for checks"
[3]: https://wiki.hypr.land/Configuring/Start/ "Hyprland: Start"
[4]: https://wiki.hypr.land/Configuring/Using-Lua/ "Hyprland: Using Lua"
[5]: https://github.com/OrynVail/Ambxst-X "Ambxst-X upstream"
[6]: https://github.com/Axenide/axctl "axctl"

A implementação foi avaliada em relação ao Ambxst-X e às interfaces do Hyprland e do `axctl` disponíveis nas referências acima. [3] [4] [5] [6]
