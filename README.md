# shell-conf — DankMaterialShell

> Este repositório é a camada de integração declarativa do **DankMaterialShell**
> para a configuração NixOS do projeto. Ele não reimplementa o DMS; apenas
> importa e expõe os módulos oficiais do upstream, adicionando as preferências
> específicas do usuário.

O `nix-conf` é a autoridade da sessão Hyprland/UWSM; este repositório é a
autoridade do shell DankMaterialShell e das suas dependências declarativas.

## Arquitetura

| Componente | Responsabilidade | Fonte de verdade |
|---|---|---|
| `flake.nix` | Flake wrapper que importa os módulos HM e NixOS do DMS upstream. | Este checkout Git. |
| `modules/default.nix` | Preferências do usuário (tema, fontes, layout) mescladas no JSON do DMS. | Este checkout Git. |
| DankMaterialShell upstream | Shell completo: painel, launcher, dashboard, IPC, theming dinâmico. | [`AvengeMedia/DankMaterialShell`](https://github.com/AvengeMedia/DankMaterialShell) |
| `nix-conf` | Sessão Hyprland (UWSM), módulo HM do DMS, systemd target. | Repositório `nix-conf`. |
| `~/.config/DankMaterialShell/` | Configuração mutável gerada pelo DMS (settings.json, plugins). | Máquina local, inicializado pelo Home Manager. |

O `flake.nix` é deliberadamente enxuto: ele importa `dms.homeModules.dank-material-shell`
e `dms.nixosModules.dank-material-shell` diretamente. Nenhuma lógica de empacotamento
é reimplementada localmente — o DMS constrói o próprio binário a partir do fonte
(`core/`) com Go, Quickshell e as dependências Qt6 necessárias.

## Como o nix-conf consome este flake

```nix
{ inputs, ... }: {
  flake.nixosModules.dankMaterialShell = { pkgs, ... }: {
    imports = [
      inputs.shell-conf.nixosModules.default
      inputs.shell-conf.homeManagerModules.default
    ];
  };
}
```

O `inputs.shell-conf.nixosModules.default` habilita `programs.dank-material-shell`
no nível do sistema (systemd, polkit, accounts-daemon). O
`inputs.shell-conf.homeManagerModules.default` habilita o mesmo programa no nível
do usuário (settings JSON, Quickshell, systemd user service para `dms.service`).

## Personalização

Para alterar tema, fontes, ou preferências de layout, edite
`modules/default.nix` e ajuste o attrset `userSettings`:

```nix
programs.dank-material-shell.userSettings = {
  appearance.colorScheme = "light";
  font.family = "JetBrainsMono Nerd Font";
};
```

Esse attrset é mesclado com as configurações padrão do DMS e serializado para
`~/.config/DankMaterialShell/settings.json` pelo módulo Home Manager.

## Sessão Hyprland declarativa

A sessão é declarada pelo `nix-conf` e aplicada por rebuild. O DMS é iniciado
pela unidade `dms.service` associada a `graphical-session.target`, alcançada
depois que o UWSM importa o ambiente Wayland/DBus.

| Operação | Comando |
|---|---|
| Verificar o shell | `systemctl --user status dms.service` |
| Acompanhar logs | `journalctl --user -u dms.service -f` |
| Reiniciar o shell | `systemctl --user restart dms.service` |
| Parar a sessão Hyprland/UWSM | `uwsm stop` |

## Compositor

DMS suporta Hyprland, Niri, Sway, MangoWC, labwc, MiracleWM e Scroll.
Este repositório atualmente integra com **Hyprland** (via UWSM). Caso o usuário
migre de volta para Niri, o módulo `dms.homeModules.niri` fica disponível para
habilitar keybinds e spawn-at-startup específicos do Niri.

## Validação

```bash
cd ~/shell-conf
nix flake check

cd ~/nix-conf
nix flake check
sudo nixos-rebuild build --flake .#myMachine
```

## Limites de estado

O checkout Git contém código e defaults. Preferências alteradas pela interface
são mutáveis e vivem em `~/.config/DankMaterialShell/` e
`~/.local/state/DankMaterialShell/`; o módulo Home Manager os inicializa via
`xdg.configFile` e `xdg.stateFile`. Não versione esse estado como se fosse
código do shell.

Para uma configuração reprodutível de defaults, edite `modules/default.nix`,
valide no ambiente local e publique a mudança no Git. Para uma personalização
exclusiva de uma máquina, altere a interface do DMS diretamente.

## Referências

- [DankMaterialShell Docs](https://danklinux.com/docs)
- [DankMaterialShell Nix Module Source](https://github.com/AvengeMedia/DankMaterialShell/tree/master/distro/nix)
- [Quickshell](https://quickshell.org/)
- [NixOS Hyprland Module](https://search.nixos.org/options?query=programs.hyprland)
