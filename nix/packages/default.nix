# Main Ambxst package
{ pkgs, lib, self, system, axctl, version }:

let
  quickshellPkg = pkgs.quickshell;
  axctlPkg = axctl.packages.${system}.default;

  # Import sub-packages
  ttf-phosphor-icons = import ./phosphor-icons.nix { inherit pkgs; };

  # Import modular package lists
  corePkgs = import ./core.nix { inherit pkgs quickshellPkg; };
  toolsPkgs = import ./tools.nix { inherit pkgs; };
  mediaPkgs = import ./media.nix { inherit pkgs; };
  appsPkgs = import ./apps.nix { inherit pkgs; };
  fontsPkgs = import ./fonts.nix { inherit pkgs ttf-phosphor-icons; };
  tesseractPkgs = import ./tesseract.nix { inherit pkgs; };

  # Combine all packages (NixOS-specific deps handled by the module)
  baseEnv = corePkgs
    ++ [ axctlPkg ]
    ++ toolsPkgs
    ++ mediaPkgs
    ++ appsPkgs
    ++ fontsPkgs
    ++ tesseractPkgs;

  envAmbxst = pkgs.buildEnv {
    name = "Ambxst-env";
    paths = baseEnv;
  };

  # Create fontconfig configuration to find bundled fonts
  fontconfigConf = pkgs.writeTextDir "etc/fonts/conf.d/99-ambxst-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <dir>${envAmbxst}/share/fonts</dir>
    </fontconfig>
  '';

  # Copy shell sources to the Nix store
  shellSrc = pkgs.stdenv.mkDerivation {
    pname = "ambxst-shell";
    inherit version;
    src = lib.cleanSource self;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  };

  launcher = pkgs.writeShellScriptBin "ambxst" ''
    # User-editable settings and generated compositor state must never reside
    # in the immutable Nix store.
    export AMBXST_CONFIG_ROOT="''${AMBXST_CONFIG_ROOT:-''${XDG_STATE_HOME:-$HOME/.local/state}/ambxst}"
    # nix-conf owns the Hyprland session declaratively. The CLI must not inject
    # a second source/loadfile block into a user-managed Hyprland config.
    export AMBXST_DECLARATIVE_HYPRLAND=1
    export AMBXST_QS="${quickshellPkg}/bin/qs"
    export PATH="${envAmbxst}/bin:$PATH"

    # Set QML2_IMPORT_PATH to include modules from envAmbxst (like syntax-highlighting)
    export QML2_IMPORT_PATH="${envAmbxst}/lib/qt-6/qml:$QML2_IMPORT_PATH"
    export QML_IMPORT_PATH="$QML2_IMPORT_PATH"

    # Expose icon themes, GSettings schemas, and data from envAmbxst and user
    # profile to Quickshell.  /run/current-system/sw/share is included so that
    # gsettings can find the org.gnome.desktop.interface schema even when the
    # systemd user service does not inherit the full desktop-session environment.
    export XDG_DATA_DIRS="${envAmbxst}/share:$HOME/.nix-profile/share:/etc/profiles/per-user/$USER/share:/run/current-system/sw/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    # Make bundled fonts available to fontconfig
    export FONTCONFIG_PATH="${fontconfigConf}/etc/fonts:''${FONTCONFIG_PATH:-}"
    # Detect the current GTK icon theme and export it for Quickshell (QS_ICON_THEME)
    # and the cursor (XCURSOR_THEME).  Falls back to 'kora' (the theme declared in
    # home.nix) when gsettings is unavailable or returns empty (e.g. dconf daemon
    # not yet running at service start).
    GTK_ICON_THEME=""
    if command -v gsettings >/dev/null 2>&1; then
      GTK_ICON_THEME=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
    fi
    # Fall back to the theme declared in home.nix when gsettings is unavailable or
    # returns an empty string (e.g. dconf daemon not yet running at service start).
    if [ -z "$GTK_ICON_THEME" ]; then
      GTK_ICON_THEME="kora"
    fi
    export XCURSOR_THEME="$GTK_ICON_THEME"
    export QS_ICON_THEME="$GTK_ICON_THEME"

    # Delegate execution to CLI (now in the Nix store)
    exec ${shellSrc}/cli.sh "$@"
  '';

in pkgs.buildEnv {
  name = "Ambxst-${version}";
  paths = [ envAmbxst launcher ];
  meta.mainProgram = "ambxst";
}
