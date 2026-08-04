{ config, pkgs, lib, ... }:

{
  programs.wezterm = {
    enable = true;
    package = pkgs.wezterm;
    
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()

      -- DMS Matugen generates the theme at ~/.config/wezterm/colors/dank-theme.toml
      -- We attempt to load it directly to ensure compatibility with dynamic updates.
      local theme_path = wezterm.home_dir .. "/.config/wezterm/colors/dank-theme.toml"
      
      local function load_dms_theme()
        local f = io.open(theme_path, "r")
        if f ~= nil then
          io.close(f)
          return wezterm.color.load_base16_scheme(theme_path)
        end
        return nil
      end

      local dms_theme = load_dms_theme()
      if dms_theme then
        config.colors = dms_theme
      else
        -- Fallback to a default if DMS theme is not yet generated
        config.color_scheme = 'Catppuccin Mocha'
      end
      
      -- Enable automatic reload when the config or the theme file changes
      config.automatically_reload_config = true
      
      -- Default font configuration
      config.font = wezterm.font('JetBrains Mono')
      config.font_size = 11.0
      
      -- Window styling
      config.window_background_opacity = 0.85
      config.hide_tab_bar_if_only_one_tab = true
      config.window_padding = {
        left = 10,
        right = 10,
        top = 10,
        bottom = 10,
      }
      
      return config
    '';
  };

  # Ensure the directory for the generated theme exists
  home.activation.setupWeztermColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.config/wezterm/colors"
  '';
}
