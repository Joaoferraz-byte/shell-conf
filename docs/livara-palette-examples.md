# Livara application palette examples

A paleta ativa do Noctalia é a fonte de verdade. Os adaptadores abaixo transformam os mesmos papéis semânticos em formatos próprios de cada aplicação.

| Aplicação | Fundo principal | Superfície | Texto | Acento | Aplicação |
| --- | --- | --- | --- | --- | --- |
| IntelliJ IDEA / Android Studio editor | `background` | `surface_container` | `on_background` | `primary` | O arquivo `Matugen-Dark.icls` é gerado e ligado aos diretórios versionados `colors` encontrados em JetBrains e Google. |
| IntelliJ IDEA / Android Studio UI | `base` | `surface0`/`surface1` | `text` | `blue` | O plugin local `Livara Theme` é instalado diretamente na raiz de plugins do produto descoberta pelo adaptador e fornece o `Livara Dark`. |
| Nuclear Music Player | `base` | `surface0`/`surface1` | `text`/`subtext0` | `blue` | O sincronizador grava `themes/Livara.json`, seleciona esse ID relativo em `core.theme.active.id` e grava `core.theme.dark` explicitamente em cada modo; o watcher recarrega mudanças de paleta. |
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

For Nuclear, the same values become `background=base`, `card=surface0`, `foreground=text`, `muted-foreground=subtext0`, `primary=blue` and `border=overlay0` in the v2 advanced-theme JSON. For Hydra, the CSS variables `--livara-background`, `--livara-surface`, `--livara-surface-raised`, `--livara-text`, `--livara-muted`, `--livara-primary` and `--livara-error` use exactly the same semantic roles.

These are application-format examples of one Noctalia palette, not manually invented palettes. When Noctalia changes wallpaper, the adapters regenerate file-based contracts from the active palette, while mutable application-owned stores are changed only through their documented JSON or UI contracts.

## External application boundaries

IntelliJ IDEA and Android Studio have two independent theme contracts. The adapter places the generated `.icls` editor color scheme under each versioned `colors` directory and installs the `Livara Theme` plugin in the corresponding product plugin root, including a product discovered through its configuration root. The IDE still controls final selection of the editor scheme and UI theme; appearing in Plugins is expected for a JetBrains UI theme. The adapter rewrites the Nuclear dark-mode flag in both directions and avoids rewriting Nuclear settings while the official process name is running. Hydra themes are repository-backed; the generated CSS is staged in both the launcher's native user-data theme directory and the official publication layout, while the Settings > Appearance list remains backed by a private LevelDB database and is not mutated by the adapter because no declarative import API exists.

## References

1. [JetBrains color schemes](https://www.jetbrains.com/help/idea/configuring-colors-and-fonts.html)
2. [Hydra Themes repository](https://github.com/hydralauncher/hydra-themes)
3. [Nuclear advanced themes](https://docs.nuclearplayer.com/nuclear/theming/themes-advanced.md)
4. [Hydra custom themes](https://docs.hydralauncher.gg/documentation/10/hydra-custom-themes-10)
