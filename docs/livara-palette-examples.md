# Livara application palette examples

A paleta ativa do Noctalia é a fonte de verdade. Os adaptadores abaixo transformam os mesmos papéis semânticos em formatos próprios de cada aplicação.

| Aplicação | Fundo principal | Superfície | Texto | Acento | Aplicação |
| --- | --- | --- | --- | --- | --- |
| IntelliJ IDEA / Android Studio | `background` | `surface_container` | `on_background` | `primary` | O arquivo `Matugen-Dark.icls` é gerado e ligado aos diretórios versionados `colors` encontrados em JetBrains e Google. |
| Spotify via Spicetify | `base` | `surface0`/`surface1` | `text`/`subtext0` | `blue` | O template Noctalia grava `Themes/Livara/color.ini` e executa uma aplicação serializada; o esquema Nix permanece como fallback de build. |
| Telegram Desktop | `base` | `surface0`/`mantle` | `text`/`subtext0` | `blue` | O sincronizador gera `Livara.tdesktop-theme`, um ZIP importável em Telegram Desktop. A importação é manual. |
| Hydra Launcher | `base` | `surface0`/`surface1` | `text`/`subtext0` | `blue`/`teal` | O sincronizador gera `hydra-export/themes/<name>-<friend-code>/theme.css`; screenshot, código pessoal e publicação continuam controlados pelo usuário. |
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

For Spicetify, the same values become `main=111318`, `card=1A2029`, `text=EEF2F7`, `subtext=B2BDCA`, `button=7BB7FF`, `notification=254634` and `notification-error=512D34` in the Noctalia-generated `color.ini`; the Nix `customColorScheme` remains a bootstrap fallback. For Telegram Desktop, `windowBg` uses `base`, `windowFg` uses `text`, `menuBg` uses `mantle`, `lightButtonBg` uses `surface0` and `activeButtonBg` uses `blue`. For Hydra, the CSS variables `--livara-background`, `--livara-surface`, `--livara-surface-raised`, `--livara-text`, `--livara-muted`, `--livara-primary` and `--livara-error` use exactly the same semantic roles.

These are five **application-format examples** of one Noctalia palette, not five manually invented palettes. When Noctalia changes wallpaper, its templates and the serialized Spicetify hook regenerate file-based contracts from the active palette; the immutable Spicetify-Nix package remains a stable fallback and cannot be mutated in the Nix store.

## External application boundaries

IntelliJ IDEA and Android Studio can consume an imported `.icls` color scheme. The adapter places it under each existing versioned `colors` directory and leaves selection to the IDE. Telegram Desktop accepts a `.tdesktop-theme` package, but selecting/importing it is an account/application action and is not automated. Hydra themes are repository-backed; the generated CSS is staged in the official folder layout, but the screenshot, friend-code validation, fork, pull request and publication are not automated.

## References

1. [JetBrains color schemes](https://www.jetbrains.com/help/idea/configuring-colors-and-fonts.html)
2. [Telegram custom cloud themes](https://core.telegram.org/themes)
3. [Hydra Themes repository](https://github.com/hydralauncher/hydra-themes)
4. [Spicetify-Nix module](https://wiki.nixos.org/wiki/Spicetify-Nix)
5. [Noctalia Spicetify community template](https://github.com/noctalia-dev/community-templates/tree/main/spicetify)
6. [Hydra custom themes](https://docs.hydralauncher.gg/documentation/10/hydra-custom-themes-10)
