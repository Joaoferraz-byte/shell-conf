# shell-conf — fork local do Ambxst-X

![Ambxst logo](./assets/ambxst/ambxst-logo-color.svg)

> Este repositório é o **fork operacional e versionado** do Ambxst-X usado pela configuração NixOS do projeto. O código-fonte completo do shell vive nesta árvore; ele não é mais obtido como input remoto nem recebe patches em tempo de build.

O objetivo é que mudanças em QML sejam revisáveis, reproduzíveis e fáceis de propagar entre os dois dispositivos. O `nix-conf` é a autoridade da sessão Hyprland/UWSM; este repositório é a autoridade do shell Quickshell e das suas dependências de runtime.

## Arquitetura

| Componente | Responsabilidade | Fonte de verdade |
|---|---|---|
| `shell.qml`, `config/`, `modules/`, `services/` | Código e interface do Ambxst. | Este checkout Git. |
| `flake.nix` | Pacote, módulo NixOS, módulo Home Manager, ambiente de desenvolvimento e verificações. | Este checkout Git. |
| `nix/packages/default.nix` | Launcher imutável, dependências Quickshell/QML e `axctl`. | Este checkout Git. |
| `nix-conf` | Sessão `Hyprland (UWSM)`, `XDG_CURRENT_DESKTOP=Hyprland` e `ambxst.service`. | Repositório `nix-conf`. |
| `XDG_STATE_HOME/ambxst` | Preferências e estado mutável gerado pela interface. | Máquina local, inicializado pelo Home Manager. |

A árvore de código do Ambxst está na **raiz** de `shell-conf`. Não existe `vendor/ambxst`, `patchedSource` nem `runCommand` para sobrescrever QML. O pacote Nix usa `self = ./.`, de modo que o build sempre parte da fonte versionada deste repositório.

## Sessão Hyprland declarativa

A integração com Hyprland **não** usa `ambxst install hyprland`. Esse comando upstream altera imperativamente `hyprland.conf` ou `hyprland.lua`; neste projeto, a sessão é declarada pelo `nix-conf` e aplicada por rebuild. O pacote exporta `AMBXST_DECLARATIVE_HYPRLAND=1` justamente para impedir que o comando introduza uma segunda autoridade de configuração.

A sessão UWSM criada pelo `nix-conf` executa `start-hyprland` e fixa `XDG_CURRENT_DESKTOP=Hyprland`. Isso evita a divergência conhecida em que UWSM preenche o valor como `start-hyprland` e o Hyprland alerta que a variável foi gerenciada externamente.[1] [2] O Ambxst é iniciado uma única vez por `ambxst.service`, depois que `graphical-session.target` é alcançado; não há `exec-once` ou callback Lua concorrente.

| Operação | Comando recomendado |
|---|---|
| Verificar o shell de sessão | `systemctl --user status ambxst.service` |
| Acompanhar logs | `journalctl --user -u ambxst.service -f` |
| Reiniciar o shell instalado | `systemctl --user restart ambxst.service` |
| Parar a sessão Hyprland/UWSM | `uwsm stop` |
| Inspecionar identidade de desktop | `systemctl --user show-environment | grep '^XDG_CURRENT_DESKTOP='` |

> **Não execute** `ambxst install hyprland` nem `ambxst remove hyprland` no pacote gerenciado pelo Nix. A integração já está declarada no `nix-conf`; esses comandos retornam erro intencionalmente nesse modo.

## `axctl`: decisão atual

O Ambxst atual usa `axctl` para o daemon de compositor, streaming de estado, configuração dinâmica, monitores, inibidores de idle, modo de jogo e atalhos configuráveis. Mesmo com uso exclusivo de Hyprland, removê-lo agora causaria perda de paridade funcional. A decisão, a matriz de consumidores QML e o plano de uma futura migração para IPC direto estão em [docs/axctl-decision.md](./docs/axctl-decision.md).

O instalador upstream de Hyprland é apropriado para instalações imperativas, mas não para esta topologia declarativa.[3] A documentação do fork mantém o daemon e a configuração do `axctl` isolados do gerenciamento de sessão, que continua sob controle do NixOS.

## Preparação inicial e remoto upstream

O remoto `origin` aponta para `Joaoferraz-byte/shell-conf`; o remoto `upstream` aponta para o projeto original `OrynVail/Ambxst-X`. Remotos são configuração local do Git e, por isso, devem existir em cada dispositivo.

```bash
cd ~/shell-conf

git remote -v
git remote get-url upstream 2>/dev/null \
  || git remote add upstream git@github.com:OrynVail/Ambxst-X.git

git fetch upstream --prune
```

Antes de iniciar uma atualização upstream, confirme quais commits ainda não estão no fork:

```bash
git fetch upstream --prune
git log --oneline --left-right HEAD...upstream/main
```

Se a atualização for desejada, faça uma mesclagem real, resolva conflitos mantendo a política Nix local e valide antes de publicar:

```bash
git merge upstream/main
# Resolver conflitos, executar as validações desta documentação e testar a sessão.
git push origin main
```

O histórico de merge é deliberado: ele conserva a proveniência upstream e permite revisões claras de mudanças locais versus mudanças trazidas do autor original.

## Ciclo de edição com live reload do Quickshell

O Quickshell executado com `-p <checkout>/shell.qml` observa os arquivos QML originais e recarrega o painel quando um arquivo é salvo.[4] O ambiente de desenvolvimento fornecido por este flake preserva as dependências de produção, mas redireciona o código, assets e scripts para o checkout com `AMBXST_SOURCE_ROOT`.

| Etapa | Ação | Resultado esperado |
|---|---|---|
| 1. Entrar no ambiente | `cd ~/shell-conf && nix develop .#default` | Disponibiliza `ambxst-dev` e exporta o caminho da fonte local. |
| 2. Evitar duas instâncias | `systemctl --user stop ambxst.service` | A instância instalada deixa de disputar painéis, IPC e `axctl`. |
| 3. Iniciar o checkout | `ambxst-dev` | O Quickshell abre usando `~/shell-conf/shell.qml`. |
| 4. Editar QML | Salve, por exemplo, `config/Config.qml` ou `modules/.../*.qml`. | O Quickshell recarrega a configuração sem rebuild. |
| 5. Recuperar de erro de QML | Pare a instância de desenvolvimento com `Ctrl+C` e rode `ambxst-dev` de novo. | O shell retorna a partir da árvore local. |
| 6. Voltar ao modo normal | `systemctl --user start ambxst.service` | A sessão volta a usar o pacote aplicado pelo Nix. |

Durante uma sessão de desenvolvimento, **não** use `ambxst reload` como recuperação principal: esse comando reinicia o launcher que o invocou. Para garantir que a fonte local continue selecionada, deixe `ambxst-dev` no terminal em primeiro plano; para reiniciar, encerre-o e execute `ambxst-dev` novamente.

Após validar visualmente a mudança, registre-a no Git:

```bash
cd ~/shell-conf
git status
git diff --check
git add shell.qml config/ modules/ services/ scripts/ nix/ flake.nix README.md docs/
git commit -m "feat: descrever a mudança"
git push origin main
```

## Sincronização entre os dois dispositivos

O fluxo abaixo mantém o código QML, os módulos Nix e o lockfile coerentes. Não copie arquivos manualmente entre máquinas; o Git é o mecanismo de sincronização.

| Fase | Dispositivo de edição | Segundo dispositivo |
|---|---|---|
| Desenvolver | Edite com `nix develop .#default` e `ambxst-dev`. | Nenhuma ação. |
| Publicar | Faça `git commit` e `git push origin main` em `shell-conf`; publique alterações coordenadas no `nix-conf`. | Nenhuma ação até o push terminar. |
| Atualizar a fonte | — | `cd ~/shell-conf && git pull --ff-only` |
| Atualizar a integração | — | `cd ~/nix-conf && git pull --ff-only` |
| Aplicar Home Manager | — | `home-manager switch --flake ~/nix-conf#<perfil>` |
| Aplicar NixOS, se aplicável | — | `sudo nixos-rebuild switch --flake ~/nix-conf#<host>` |
| Conferir | — | `systemctl --user status ambxst.service` e confirme a sessão gráfica. |

O identificador `<perfil>` e `<host>` devem ser os já usados por cada máquina no `nix-conf`. Quando Home Manager é aplicado pelo módulo NixOS do host, o `nixos-rebuild switch` é a etapa que materializa tanto o pacote quanto a ativação do estado mutável.

## Validação antes de publicar

Use as verificações abaixo no dispositivo que possui Nix. O `source-layout` assegura que a fonte continua local, que `AMBXST_CONFIG_ROOT` é usado e que o gerador de TOML não reintroduz um segundo autostart do shell.

```bash
cd ~/shell-conf
nix flake check
nix build .#checks.x86_64-linux.source-layout
nix build .#packages.x86_64-linux.ambxst

cd ~/nix-conf
nix flake check
```

Faça também uma verificação funcional depois do rebuild: entre na entrada **Hyprland (UWSM)** do display manager, execute `systemctl --user status ambxst.service`, confirme `XDG_CURRENT_DESKTOP=Hyprland` e verifique que somente uma instância do Quickshell está em execução.

## Limites de estado

O checkout Git contém código e defaults. Preferências alteradas pela interface são mutáveis e vivem em `${XDG_STATE_HOME:-~/.local/state}/ambxst`; o módulo Home Manager as inicializa uma vez e migra dados legados sem criar links para a Nix store. Não versione esse estado de usuário como se fosse QML do shell.

Para uma configuração reprodutível de defaults, edite `settings/*.json` no fork, valide no ambiente local e publique a mudança no Git. Para uma personalização exclusiva de uma máquina, altere a interface do Ambxst ou o estado local correspondente.

## Créditos e licença

Este fork preserva a licença AGPL-3.0 e reconhece o trabalho do [Ambxst-X upstream](https://github.com/OrynVail/Ambxst-X), do [Ambxst atual](https://github.com/Axenide/Ambxst), do [Quickshell](https://quickshell.org/) e de seus colaboradores. A política de integração Nix e os ajustes locais são mantidos neste repositório.

## Referências

[1]: https://github.com/NixOS/nixpkgs/issues/476375 "NixOS/nixpkgs #476375 — XDG_CURRENT_DESKTOP com UWSM"
[2]: https://man.archlinux.org/man/uwsm.1.en "UWSM(1) — `-D` e `-e` em `uwsm start`"
[3]: https://github.com/Axenide/Ambxst "Ambxst — instalação e integração imperativa com Hyprland"
[4]: https://quickshell.org/docs/v0.1.0/guide/introduction/ "Quickshell — live reload de código QML"
