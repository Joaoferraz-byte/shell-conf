# Livara application palette examples

A paleta ativa do shell ou do serviço de temas é a fonte de verdade. Ela deve ser publicada no contrato neutro de `shell-conf` e validada antes de os adapters transformarem seus papéis semânticos nos formatos próprios de cada aplicação.

| Aplicação | Fundo principal | Superfície | Texto | Acento | Aplicação |
| --- | --- | --- | --- | --- | --- |
| Hydra Launcher | `base` | `surface0`/`surface1` | `text`/`subtext0` | `blue`/`teal` | O sincronizador gera `~/.config/Hydra/themes/<name>-<friend-code>/theme.css` e espelha `hydra-export/themes/<name>-<friend-code>/theme.css`; a seleção exige o fluxo Create/Edit do Hydra, enquanto screenshot, código pessoal e publicação continuam controlados pelo usuário. |
| Neovim/NixVim | `background` | `surface_container` | `on_background` | `primary` | O template `nvim-base16.lua` produz as cores Lua observadas pelo editor e preserva transparência para o wallpaper. |

## Concrete palette mapping

A paleta bootstrap, usada até o primeiro wallpaper ser processado, produz os seguintes valores:

```text
base       = #111318
surface0   = #1a2029
surface1   = #242b36
text       = #eef2f7
subtext0   = #b2bdca
primary    = #7bb7ff
secondary  = #83d6a3
tertiary   = #e7a9c3
error      = #f0878a
blue       = #7bb7ff
teal       = #70d7c3
red        = #f0878a
```

For Hydra, the CSS variables `--livara-background`, `--livara-surface`, `--livara-surface-raised`, `--livara-text`, `--livara-muted`, `--livara-primary` and `--livara-error` use exactly the same semantic roles.

These are application-format examples of one active palette, not manually invented palettes. When Ambxst changes the wallpaper, its canonical dark output is bridged once and the adapters regenerate file-based contracts from it, while mutable application-owned stores are changed only through their documented JSON or UI contracts.

## External application boundaries

Hydra themes are repository-backed; the generated CSS is staged in both the launcher's native user-data theme directory and the official publication layout, while the Settings > Appearance list remains backed by a private LevelDB database and is not mutated by the adapter because no declarative import API exists.

## References

2. [Hydra Themes repository](https://github.com/hydralauncher/hydra-themes)
3. [Hydra custom themes](https://docs.hydralauncher.gg/documentation/10/hydra-custom-themes-10)
