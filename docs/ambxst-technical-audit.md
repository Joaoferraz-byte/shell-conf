# Avaliação técnica da integração Ambxst

## Escopo e método

Esta avaliação compara alternativas de Ambxst a partir de código, flake, modelo de configuração, integração com `axctl`, divergência de commits e disponibilidade verificável. Ela não usa nome, popularidade ou README como critério de escolha. O objetivo é manter uma integração NixOS previsível, com uma única autoridade para inicialização, estado e atalhos do compositor.

A análise considerou a documentação Lua do Hyprland, a serialização do Home Manager, a implementação fixada de `axctl`, o instalador/launcher do Ambxst-X e as árvores dos projetos indicados. O problema inicial foi reproduzido conceitualmente: em configuração Lua, `settings.exec_once` é convertido para uma chamada Lua inexistente, enquanto o autostart compatível deve usar o evento `hyprland.start`. [1] [2] [3]

## Critérios técnicos

| Critério | Pergunta avaliada | Importância |
|---|---|---|
| Integração Nix | O projeto disponibiliza pacote, flake e módulo utilizáveis sem instalação imperativa? | Alta |
| Atualidade e divergência | As mudanças próprias são aplicáveis sobre uma base recente ou exigem reintroduzir código obsoleto? | Alta |
| Modelo de compositor | Há separação clara entre boot do shell, estado mutável e aplicação de regras/atalhos? | Alta |
| Superfície de manutenção | A solução evita patches amplos e dependências remotas não verificadas em tempo de avaliação? | Alta |
| Disponibilidade | A fonte pode ser obtida e auditada integralmente? | Obrigatória |

## Resultados comparativos

| Fonte | Evidência de código e integração | Risco técnico | Decisão |
|---|---|---|---|
| `OrynVail/Ambxst-X` | A fonte usada pela configuração original possui flake, pacote, módulo NixOS e integração com `axctl`. O launcher e a derivação são suficientemente estruturados para serem consumidos a partir de uma árvore local. [4] | O histórico é curto e o projeto não é uma distribuição NixOS estável por si só; atualizações upstream exigem revisão. | **Base escolhida, vendorizada e fixada.** |
| `Valo-Asura/Ambxst-nixos` | Fork completo de `Axenide/Ambxst` sem commits à frente e aproximadamente 479 commits atrás da base comum no momento da análise. A árvore não oferece manutenção própria que justifique migrar toda a integração. [5] | Adotar o fork reintroduziria uma base antiga e aumentaria o custo de portabilidade de correções. | Não adotar como base; apenas comparar correções específicas se um defeito for reproduzido. |
| `rafmiqgus/Ambxst-fork` | Fork com seis commits próprios, incluindo ajustes de dados/QML e remoção de terminais pré-instalados, porém aproximadamente 479 commits atrás da base comum. As alterações foram avaliadas como diffs seletivos, não como uma atualização segura de toda a árvore. [6] | Alterações locais sobre base muito defasada podem conflitar com arquitetura atual de painel, serviços e compositor. | Não adotar como base; considerar somente patches isolados, reproduzidos e testados. |
| `TimothyBear11/AmbxstNixDots` | A URL indicada retornou 404 e a consulta autenticada não localizou o repositório. [7] | Não há código disponível para auditoria, teste ou manutenção. | Não avaliável enquanto uma fonte verificável não for fornecida. |

A decisão não foi migrar para um fork alternativo. A solução escolhida incorpora a revisão auditada do Ambxst-X por inteiro em `vendor/ambxst`, preserva sua estrutura de pacote e módulo, e mantém apenas adaptações explicitamente necessárias à execução declarativa no NixOS.

## Defeitos identificados na integração anterior

A implementação anterior reexportava uma fonte remota e substituía arquivos QML completos por uma camada local de overrides. Esse padrão criava duas fragilidades: mudanças upstream podiam ser silenciosamente perdidas nos arquivos substituídos, e o pacote efetivamente construído dependia de uma combinação de fonte remota, patches e estado de lockfile mais difícil de auditar.

Também havia duas autoridades de autostart. O Home Manager tentava gerar `settings.exec_once` em Lua e o gerador TOML adicionava outro `exec-once` para o próprio Ambxst. Além de a primeira forma produzir `attempt to call a nil value (field 'exec_once')`, a combinação podia iniciar o shell duas vezes. A implementação atual usa somente `hl.on("hyprland.start", ...)` para iniciar o Ambxst e não permite que o TOML do `axctl` reinicie o próprio shell. [1] [2] [3]

## Arquitetura implementada

| Elemento | Implementação adotada | Justificativa |
|---|---|---|
| Fonte do Ambxst | Árvore completa em `vendor/ambxst`. | O código construído, revisado e versionado é idêntico ao que está no repositório. |
| Flake | `shell-conf/flake.nix` constrói o pacote diretamente da árvore vendorizada. | Elimina o input remoto do Ambxst e reduz a superfície de atualização implícita. |
| Estado | `AMBXST_CONFIG_ROOT` com fallback em `XDG_STATE_HOME/ambxst`. | Mantém arquivos editáveis fora da Nix store e preserva semeadura inicial pelo Home Manager. |
| Inicialização | O Hyprland inicia `ambxst` uma única vez no evento Lua oficial. | Remove a chamada inexistente `exec_once` e elimina ciclo de autostart. |
| Regras e binds dinâmicos | `axctl` aplica TOML e lote de keybinds por IPC após confirmar disponibilidade do daemon. | Evita carregar Lua de sessão antiga e impede comandos precoces durante o boot. |
| Recuperação | O NixOS mantém apenas `SUPER + Return`, `SUPER + R` e `SUPER + SHIFT + Q`. | Preserva `SUPER + T` para a interface de terminais/tmux do Ambxst. |

O serviço `CompositorKeybinds` aguarda `AxctlService.daemonReady` antes de emitir `axctl config keybinds-batch`. A aplicação dinâmica remove apenas os atalhos previamente administrados pelo Ambxst e não atinge os três atalhos de recuperação do NixOS. Essa separação elimina a colisão histórica entre `SUPER + Enter` e a semântica prevista de `SUPER + T`.

## Validação executada

| Verificação | Resultado |
|---|---|
| `nix flake check --no-build` em `shell-conf` | Aprovado. |
| `nix flake check --no-build` em `nix-conf` | Aprovado. |
| Avaliação das derivações `myMachine` e `dellLatitude5410` | Aprovada. |
| Planos de build sem execução do pacote Ambxst e dos dois hosts | Dependências resolvidas. |
| `bash -n` no launcher vendorizado | Aprovado. |
| Parsing de QML modificado com `qmlformat` | Aprovado para `Config.qml`, `AxctlService.qml`, `CompositorTomlWriter.qml`, `CompositorKeybinds.qml`, `PresetsService.qml` e `shell.qml`. |
| Lint QML genérico | Sem erro sintático explícito; avisos de tipos/imports Quickshell são esperados fora de um runtime Quickshell. |

A validação no ambiente de automação não inicia uma sessão Wayland gráfica real. Depois de aplicar a geração, a verificação operacional recomendada é iniciar uma sessão Hyprland, confirmar que existe apenas um processo `ambxst`, testar `SUPER + T`, testar os três atalhos de recuperação e verificar o socket/processo do `axctl`.

## Processo de atualização

Atualizações devem preservar a auditoria. Primeiro, compare a fonte upstream com `vendor/ambxst`; em seguida, integre a revisão como mudança explícita, revise os arquivos QML tocados e valide a flake do `shell-conf`. Depois de publicar essa revisão, atualize o input `shell-conf` no `nix-conf`, reavalie os dois hosts e aplique a geração somente após os checks serem aprovados.

Evite executar instaladores upstream em uma instalação gerenciada pelo NixOS. Eles podem escrever arquivos de configuração fora do fluxo declarativo e reintroduzir fontes concorrentes de autostart, binds ou estado.

## Referências

[1]: https://wiki.hypr.land/Configuring/Basics/Autostart/ "Hyprland: Autostart"
[2]: https://github.com/nix-community/home-manager/issues/9341 "Home Manager issue #9341"
[3]: https://github.com/Axenide/axctl/tree/1e163c0193cf3b407b5d9bf65fbdb3ef8c8c1710 "axctl revision audited"
[4]: https://github.com/OrynVail/Ambxst-X/tree/ee9fcbd4f8d602bad3bc9ede0f32f20b09989ba3 "Ambxst-X revision audited"
[5]: https://github.com/Valo-Asura/Ambxst-nixos "Valo-Asura/Ambxst-nixos"
[6]: https://github.com/rafmiqgus/Ambxst-fork "rafmiqgus/Ambxst-fork"
[7]: https://github.com/TimothyBear11/AmbxstNixDots "TimothyBear11/AmbxstNixDots"
