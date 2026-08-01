# Auditoria técnica da integração Ambxst

## Escopo e decisão

Esta auditoria registra a arquitetura mantida por `shell-conf` depois da migração de um wrapper com fonte remota para um **fork local completo** do Ambxst-X. O objetivo é manter uma única autoridade para código, sessão, estado mutável e atalhos do compositor, sem depender de patches frágeis contra um input upstream em tempo de avaliação.

A base escolhida continua sendo [OrynVail/Ambxst-X][1], pois ela fornece a estrutura de QML, flake, pacote NixOS e integração com `axctl` que este projeto já usa. A mudança de arquitetura não troca essa origem por um fork alternativo: ela a promove para a raiz deste próprio repositório, preservando histórico e permitindo atualizações explícitas por merge.

| Critério | Decisão adotada | Resultado |
|---|---|---|
| Origem do código | Árvore completa na raiz de `shell-conf`. | O código construído é o código versionado e revisado localmente. |
| Atualização upstream | Remoto Git `upstream` para `OrynVail/Ambxst-X`. | Atualizações futuras usam `git fetch upstream && git merge upstream/main`. |
| Fonte de build | `self = ./.` no `flake.nix`. | Nenhum input remoto do Ambxst, `patchedSource`, diretório `vendor` ou `runCommand` de remendo permanece. |
| Sessão gráfica | UWSM/NixOS no `nix-conf`. | O shell é iniciado por `ambxst.service`, uma única vez após `graphical-session.target`. |
| Estado mutável | `${XDG_STATE_HOME:-~/.local/state}/ambxst`. | Preferências não são vinculadas à Nix store e continuam editáveis pela interface. |

## Defeitos eliminados

A integração anterior dependia de uma combinação de fonte remota, lockfile e sobreposição de arquivos QML completos. Isso escondia a relação real entre uma alteração local e sua base upstream: uma mudança do autor original podia ser silenciosamente perdida pelo override local, e o resultado do build não era representado por uma única árvore Git.

Também havia múltiplas autoridades de inicialização. A configuração Lua do Hyprland tentava iniciar o shell, e o gerador de configuração do compositor podia introduzir outro autostart. A arquitetura atual elimina ambos os caminhos: o `nix-conf` declara a sessão UWSM e uma unidade `ambxst.service`; o fork impede que `CompositorTomlWriter.qml` gere `exec-once = "ambxst"` e bloqueia `ambxst install hyprland` no launcher empacotado.

> A sessão declarativa é deliberadamente diferente da instalação imperativa upstream. O instalador upstream adiciona um `source` ou `loadfile` a `hyprland.conf`/`hyprland.lua`; nesta topologia, esse arquivo seria uma segunda fonte de verdade fora do Nix e do Git.[2]

## Arquitetura implementada

| Elemento | Implementação | Justificativa operacional |
|---|---|---|
| Fonte QML | `shell.qml`, `config/`, `modules/`, `services/` e assets na raiz. | Edição, revisão, build e merge ocorrem na mesma árvore. |
| Pacote | `nix/packages/default.nix` copia `self` para a Nix store e expõe `ambxst`. | Produção é imutável, mas parte da fonte Git local. |
| Desenvolvimento | `nix develop .#default` e `ambxst-dev`. | `AMBXST_SOURCE_ROOT` faz o launcher usar o checkout sem duplicar dependências de runtime. |
| Live reload | Quickshell recebe `-p <checkout>/shell.qml`. | O Quickshell recarrega arquivos QML salvos.[3] |
| UWSM | Desktop entry declarada no `nix-conf`, com `-e -D Hyprland`. | Garante `XDG_CURRENT_DESKTOP=Hyprland`, evitando a divergência documentada no nixpkgs.[4] |
| Spawn do shell | `systemd.user.services.ambxst`, associado a `graphical-session.target`. | UWSM importa o ambiente Wayland/DBus antes de iniciar o shell; não há callback Lua concorrente. |
| Recuperação | `SUPER + R` executa `systemctl --user restart ambxst.service`. | O processo continua sob o controle do serviço, sem o launcher criar instância desacoplada. |
| Serviços de compositor | `axctl` permanece fixado como input de runtime. | A revisão atual ainda o usa em serviços de compositor, idle, monitores, tela e atalhos. |

O plano de saída de `axctl`, a matriz de consumidores QML e os critérios de paridade para IPC direto do Hyprland estão em [axctl-decision.md](./axctl-decision.md). A manutenção atual não trata `axctl` como um atalho de suporte a vários compositores: ele continua sendo parte da implementação funcional de Hyprland do Ambxst.

## Atualização upstream

O repositório contém um remoto local chamado `upstream`. Como remotos não são versionados, cada dispositivo deve configurá-lo uma vez:

```bash
cd ~/shell-conf
git remote get-url upstream 2>/dev/null \
  || git remote add upstream https://github.com/OrynVail/Ambxst-X.git
```

Uma atualização é uma mesclagem consciente, não uma substituição de diretório nem um novo patch. Antes de integrar, reveja os commits e os arquivos impactados; depois, resolva conflitos preservando as regras declarativas deste fork.

```bash
git fetch upstream --prune
git log --oneline --left-right HEAD...upstream/main
git merge upstream/main

git diff --check
nix flake check
git push origin main
```

Mudanças upstream em `cli.sh`, `flake.nix`, `nix/`, `modules/services/AxctlService.qml`, `modules/services/CompositorTomlWriter.qml`, `modules/services/PresetsService.qml`, `config/Config.qml`, `modules/bar/workspaces/Workspaces.qml` e `shell.qml` merecem revisão adicional, porque são as superfícies que conectam a fonte do Ambxst à integração declarativa local.

## Validação requerida

A validação estática deste fork deve comprovar que a árvore é local, que o launcher preserva a sintaxe de shell e que o Nix pode avaliar o pacote. Como uma sessão Wayland real não é iniciada em automação sem desktop, a validação funcional continua sendo obrigatória no host NixOS após a troca de geração.

| Camada | Comando ou teste | Resultado esperado |
|---|---|---|
| Estrutura | `git diff --check` e `grep` por referências antigas. | Sem `vendor/ambxst`, `patchedSource`, input remoto do Ambxst ou autostart TOML do shell. |
| Launcher | `bash -n cli.sh`. | Sintaxe válida; `AMBXST_DECLARATIVE_HYPRLAND=1 ambxst install hyprland` falha sem escrever config. |
| Flake do shell | `nix flake check` e `nix build .#packages.x86_64-linux.ambxst`. | Fonte local, `axctl` e dependências resolvidos. |
| Flake do sistema | `nix flake check` em `nix-conf`. | Sessão UWSM e serviço do Ambxst avaliam sem conflito. |
| Sessão | Login em **Hyprland (UWSM)**. | `XDG_CURRENT_DESKTOP=Hyprland`, uma instância do shell e `ambxst.service` ativo. |
| Interface | Edite um `.qml` via `ambxst-dev`. | Quickshell recarrega ao salvar e o serviço de produção permanece parado durante o desenvolvimento. |

## Referências

[1]: https://github.com/OrynVail/Ambxst-X "OrynVail/Ambxst-X"
[2]: https://github.com/Axenide/Ambxst "Ambxst — instalação e integração com Hyprland"
[3]: https://quickshell.org/docs/v0.1.0/guide/introduction/ "Quickshell — live reload de código QML"
[4]: https://github.com/NixOS/nixpkgs/issues/476375 "NixOS/nixpkgs #476375 — `XDG_CURRENT_DESKTOP` com UWSM"
