{ config, pkgs, lib, ... }:

{
  programs.wezterm = {
    enable = true;
    package = pkgs.wezterm;
    
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()

      -- Configuração básica
      config.font = wezterm.font('JetBrains Mono')
      config.font_size = 11.0
      config.window_background_opacity = 0.85
      config.hide_tab_bar_if_only_one_tab = true
      config.automatically_reload_config = true
      config.window_padding = {
        left = 10,
        right = 10,
        top = 10,
        bottom = 10,
      }

      -- DMS Matugen gera o tema em ~/.config/wezterm/colors/dank-theme.toml
      -- WezTerm procura automaticamente no diretório colors/
      -- Se o arquivo existir, usamos ele; caso contrário, usamos um fallback.
      config.color_scheme = 'dank-theme'
      
      return config
    '';
  };

  # Garantir que o diretório de cores exista para o Matugen salvar o tema
  home.activation.setupWeztermColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.config/wezterm/colors"
  '';
}
