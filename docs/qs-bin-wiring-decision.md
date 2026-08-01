# Decisão arquitetural: verificação do wiring `$QS_BIN`

## Veredicto: encadeamento íntegro, sem correção necessária

A auditoria confirmou que a variável `QS_BIN` — usada em `cli.sh` para invocar o Quickshell — está corretamente encadeada desde a definição do pacote Nix até a execução do launcher.

## Cadeia de dependência

| Etapa | Arquivo | Linha | Mecanismo |
|---|---|---|---|
| 1. Definição do pacote | `nix/packages/core.nix` | 5 | `quickshellPkg = pkgs.quickshell` passado como parâmetro |
| 2. Inclusão no closure | `nix/packages/default.nix` | 20-21 | `corePkgs` injetado em `baseEnv` |
| 3. Export da variável | `nix/packages/default.nix` | 61 | `export AMBXST_QS="${quickshellPkg}/bin/qs"` no wrapper `ambxst` |
| 4. Fallback no CLI | `cli.sh` | 15 | `QS_BIN="${AMBXST_QS:-qs}"` |
| 5. Execução | `cli.sh` | 674-676 | `exec "$QS_BIN" -p "${SCRIPT_DIR}/shell.qml"` |

O pacote `quickshell` do nixpkgs (v0.3.0) instala o binário primário como `quickshell` e cria um symlink `qs → quickshell` via `install(CODE)` no CMakeLists.txt. O caminho `${quickshellPkg}/bin/qs` é, portanto, resolvível e determinístico.

## Evidência de ausência de bug

A mudança introduzida em commit `1f73367` (substituição de `qs` hardcoded por `$QS_BIN`) não cria um novo *"binary could not be found"*. O wrapper `ambxst` injeta `AMBXST_QS` com caminho absoluto para o symlink `qs` dentro do closure Nix, e o fallback `:-qs` garante que, mesmo sem o wrapper (ex: desenvolvimento local), o binário `qs` no PATH do sistema seja utilizado.

## Conclusão

Nenhuma correção adicional é necessária nesta cadeia. O Stage 2 é encerrado com resultado positivo.
