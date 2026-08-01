# Decisão arquitetural: `axctl` no fork local do Ambxst

## Decisão

O fork **manterá `axctl` como dependência de execução por enquanto**. A decisão não é manter uma abstração genérica por conveniência: na revisão atual do Ambxst, `axctl` é o backend efetivo de serviços que continuam necessários mesmo quando o compositor suportado é exclusivamente o Hyprland. A remoção imediata trocaria uma dependência explícita e fixada por uma reimplementação parcial, sem cobertura funcional equivalente.

| Alternativa | Resultado da avaliação | Decisão |
|---|---|---|
| Manter `axctl` e isolar a sessão no NixOS | Preserva o daemon, o streaming de estado, os atalhos dinâmicos, a configuração do compositor, monitores, janelas, modo de jogo e os serviços de idle já usados pelo QML. | **Adotada agora.** |
| Executar `ambxst install hyprland` | É um instalador imperativo que injeta um `source`/`loadfile` na configuração do usuário. Ele cria uma segunda autoridade de configuração fora do `nix-conf` e fora do ciclo de rebuild. | **Não usar neste fork.** |
| Substituir `axctl` por `hyprctl`/IPC direto | É viável como projeto de refatoração, mas requer backend QML completo e testes de paridade para várias áreas do shell. | **Adiar até haver paridade validada.** |

> O escopo correto para a configuração atual é: **NixOS/UWSM inicia a sessão; Ambxst inicia uma única vez; `axctl` é iniciado e administrado pelo próprio shell; o Ambxst não escreve um segundo autostart do shell.**

## Evidências no código do fork

A busca na árvore local identificou **14 arquivos QML** que invocam ou dependem diretamente de `axctl`. Não se trata apenas de `AxctlService.qml` e `CompositorTomlWriter.qml`. As dependências incluem `CompositorConfig.qml`, `CompositorKeybinds.qml`, `GameModeService.qml`, `IdleInhibitor.qml`, `IdleMonitor.qml`, `Screenshot.qml`, o painel de atalhos, o menu de energia e componentes de espaço de trabalho.

| Área funcional | Uso atual de `axctl` | Consequência de remover sem backend substituto |
|---|---|---|
| Serviço de compositor | Inicia o daemon, recebe eventos e controla o ciclo de vida. | Perda de sincronização de estado e reconexão. |
| Configuração dinâmica | `CompositorTomlWriter.qml` gera o TOML a partir dos controles da interface. | Preferências alteradas na UI deixam de chegar ao compositor. |
| Atalhos do Ambxst | `CompositorKeybinds.qml` faz lote de bind/unbind e preserva os atalhos de recuperação do NixOS. | Atalhos configuráveis e ações do shell deixam de ter aplicação atômica. |
| Janelas, telas e captura | Serviços consultam monitores e clientes e aplicam operações de tela. | Captura, seleção de janela e operações de DPMS ficam incompletas. |
| Idle e modo de jogo | Serviços chamam a API de inibidores, monitores de idle e recarga de configuração. | Regressão em bloqueio, inibição de idle e perfil de jogo. |

O próprio changelog upstream descreve a migração de uma parte significativa da camada de serviços do Hyprland para `axctl`, incluindo daemon, streaming de estado e pipeline de teclas/configuração.[2] A camada não é, portanto, uma opção exclusiva para suportar Niri ou Mango; ela é o backend que o Ambxst atual usa para o Hyprland.

## Por que não usar `ambxst install hyprland`

O método upstream é adequado para instalações imperativas: ele altera `~/.config/hypr/hyprland.lua` ou `hyprland.conf` para carregar um arquivo gerado sob `~/.local/share/ambxst`.[1] Isso conflita com este repositório, no qual o `nix-conf` já é a única fonte declarativa da sessão e usa Home Manager com `configType = "lua"`.

Além de introduzir estado não rastreado, o fluxo imperativo já teve incompatibilidade pública com a transição do Hyprland para Lua.[3] A documentação atual passou a declarar suporte a Lua, mas o modelo continua sendo de mutação do arquivo do usuário. Neste fork, o estado mutável é propositalmente limitado a `XDG_STATE_HOME/ambxst`, enquanto o programa e a sessão permanecem versionados no Git e aplicados por Nix. Por isso, o comando de instalação não deve ser executado.

Há também uma issue upstream aberta relatando um caso de sucesso silencioso em que `axctl config bind-key` não registra o atalho no Hyprland.[4] Isso é uma razão para **encapsular e testar** `axctl`, não uma justificativa para removê-lo de modo incompleto. O fork mantém os atalhos de recuperação fora desse caminho, no módulo Hyprland do `nix-conf`.

## Mitigações implementadas neste fork

A integração reduz as fontes de fragilidade sem romper a paridade funcional atual. O pacote fixa `axctl` como input do flake e exporta-o somente por meio do ambiente do Ambxst. `CompositorTomlWriter.qml` gera o arquivo necessário para o daemon, mas não pode gerar `exec-once = "ambxst"`; o `checks.source-layout` falha se esse autostart reaparecer. A sessão UWSM/NixOS, e não o TOML gerado, é a única responsável por iniciar o Ambxst.

## Caminho de saída para IPC direto do Hyprland

A migração poderá ser reconsiderada quando um backend Hyprland-local atender aos critérios abaixo. Até então, remover `axctl` seria uma redução de funcionalidade, e não uma simplificação segura.

| Etapa | Entregável necessário | Critério de aceite |
|---|---|---|
| 1. Inventário | Matriz de cada comando `axctl` por arquivo QML e equivalente `hyprctl`/socket. | Nenhum consumidor fica sem equivalente identificado. |
| 2. Backend | `HyprlandService.qml` com cliente de socket/IPC e API estável para os consumidores. | Monitores, clientes, focus, eventos e DPMS funcionam sem `axctl`. |
| 3. Configuração | Aplicação declarada de regras, animações e layout sem editar arquivos externos. | Alterações feitas pela UI são idempotentes e sobrevivem a reinício. |
| 4. Atalhos | Substituto transacional para bind/unbind, com escopo estrito dos atalhos do Ambxst. | Os atalhos de recuperação NixOS nunca são removidos. |
| 5. Validação | Testes manuais em ambos os hosts, incluindo reload e suspensão. | Captura, idle, lockscreen, modo de jogo e atalhos têm paridade. |

## Referências

[1]: https://github.com/Axenide/Ambxst "Ambxst — instalação e integração com Hyprland"
[2]: https://axeni.de/ambxst/changelog/ "Ambxst Changelog — migração da camada de serviços para axctl"
[3]: https://github.com/Axenide/Ambxst/issues/173 "Ambxst issue #173 — suporte a Lua do Hyprland"
[4]: https://github.com/Axenide/Ambxst/issues/218 "Ambxst issue #218 — falha de registro de atalhos via axctl"
[5]: https://github.com/Axenide/axctl "Axctl — repositório upstream"
