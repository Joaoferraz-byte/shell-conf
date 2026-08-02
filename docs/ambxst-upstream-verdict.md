# Veredito de upstream: manter Ambxst-X no `shell-conf`

**Decisão registrada em:** 2 de agosto de 2026
**Escopo auditado:** Ambxst principal em `c5c943dd5136b559d6f9deda2031eb88256d4438`, Ambxst-X em `ee9fcbd4f8d602bad3bc9ede0f32f20b09989ba3` e esta configuração em `01af79ed110979b523236b46ec315d8922112195`.

> **Decisão:** o `shell-conf` continuará vendorizando **Ambxst-X**. A substituição imediata pelo `Axenide/Ambxst` principal foi rejeitada nesta revisão porque a paridade de integração, estado mutável e ciclo de vida de sessão ainda não está demonstrada no upstream estável.

## Fundamentação

O Ambxst principal contém uma flake, um pacote padrão e um módulo NixOS; a avaliação e o build do pacote foram aprovados durante a auditoria. Essa evidência prova que o upstream é empacotável por Nix, mas não prova que ele substitui com segurança o contrato de integração preservado neste repositório.[1]

A melhoria de sincronização Hyprland considerada para a migração está na PR #196, não no `main`. Na data da análise, essa pull request estava aberta e não mesclável. Sua implementação lê caminhos legados sob `~/.config/ambxst`, escreve artefatos em `~/.local/share/ambxst` e cobre somente compositor e binds. Ela não fornece uma migração compatível com o estado mutável adotado por este projeto, nem cobre temas, presets e preferências de aplicativos externos.[2]

A configuração atual preserva estado editável pelo usuário sob `${XDG_STATE_HOME:-$HOME/.local/state}/ambxst`, semeia os presets necessários, usa `axctl` para materializar e recarregar a configuração auxiliar do Hyprland e mantém correções acumuladas desde a promoção do Ambxst-X. Essa relação entre JSON de interface, TOML de `axctl` e arquivos Hyprland gerados é uma fronteira funcional: qualquer mudança de fonte precisa preservá-la e validá-la em uma sessão real.

A documentação oficial do Hyprland distingue claramente as configurações declaradas por Home Manager das configurações de nível NixOS. Portanto, uma futura troca não deve criar autoridades concorrentes entre o estado de interface e o módulo declarativo.[3] Da mesma forma, o `nixGL` se destina principalmente a aplicações Nix em sistemas não-NixOS, não sendo uma justificativa para reintroduzir um fluxo de instalação imperativo em NixOS.[4]

| Critério | Resultado atual | Efeito na decisão |
|---|---|---|
| Flake e pacote do Ambxst principal | Avaliados e construídos com êxito | Demonstra viabilidade de empacotamento, não paridade de integração. |
| Flake e pacote deste `shell-conf` | Avaliados e construídos com êxito | Confirma que a solução atualmente vendorizada é reproduzível. |
| `sync-hyprland-conf.py` no upstream estável | Ausente do `main`; presente apenas na PR #196 | Não é dependência aceitável para uma migração agora. |
| Home Manager para estado mutável no upstream | Não encontrado na revisão principal nem na cabeça da PR | Seria necessário projetar e testar uma camada local adicional. |
| Migração de presets/temas/preferências | Não oferecida pela PR examinada | Há risco de perda de personalizações e regressão de UX. |

## Garantias preservadas neste ciclo

Não foram alterados os valores de arredondamento, os atalhos existentes, a relação entre o launcher e `Super+Return`, os perfis de teclado, os presets de temas nem o diretório de estado do usuário. Nenhum componente da sessão foi trocado por uma implementação parcialmente integrada do upstream.

A decisão de manter o Ambxst-X não impede o acompanhamento do upstream. O ponto de reavaliação é deliberadamente objetivo: a funcionalidade equivalente deve estar mesclada ou liberada em uma revisão estável; deve existir migração explícita do estado em XDG; a fronteira entre arquivos declarativos e mutáveis deve estar definida; e os testes precisam comprovar persistência de presets, arredondamento, atalhos, autostart de `axctl` e reload do Hyprland.

## Como reabrir a decisão

| Condição de entrada | Evidência mínima exigida |
|---|---|
| Estabilidade upstream | Implementação equivalente à PR #196 incorporada ao `main` ou a uma release. |
| Estado e presets | Migração de `${XDG_STATE_HOME}/ambxst` sem retorno a caminhos legados. |
| Integração Nix | Bootstrap e propriedade de arquivos definidos por Home Manager ou por módulo local testado. |
| Sessão | Ordem verificável para autostart, geração de TOML/Hyprland e reloads. |
| Paridade | Testes de arredondamento, atalhos, Super+Return, perfil de teclado, temas e presets. |
| Validação final | `nix flake check` em ambos os repositórios e teste manual em uma sessão Hyprland alvo. |

## Referências

[1]: https://github.com/Axenide/Ambxst "Axenide/Ambxst"
[2]: https://github.com/Axenide/Ambxst/pull/196 "PR #196 — Merge NothingLess improvements into Ambxst"
[3]: https://wiki.hypr.land/Nix/Hyprland-on-Home-Manager/ "Hyprland on Home Manager"
[4]: https://github.com/nix-community/nixGL "nix-community/nixGL"
[5]: https://github.com/OrynVail/Ambxst-X "OrynVail/Ambxst-X"
