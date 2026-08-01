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

    # Expose icon themes and data from envAmbxst and user profile to Quickshell.
    # We include common Nix profile paths to ensure Home Manager installed icons are found.
    export XDG_DATA_DIRS="${envAmbxst}/share:$HOME/.nix-profile/share:/etc/profiles/per-user/$USER/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

    # Make bundled fonts available to fontconfig
    export FONTCONFIG_PATH="${fontconfigConf}/etc/fonts:''${FONTCONFIG_PATH:-}"

    # Try to detect the current GTK icon theme to help Qt/Quickshell pick the right one.
    if command -v gsettings >/dev/null 2>&1; then
      GTK_ICON_THEME=$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")
      if [ -n "$GTK_ICON_THEME" ]; then
        export XCURSOR_THEME="$GTK_ICON_THEME"
        # Some Qt versions/Quickshell setups might look for this.
        export QS_ICON_THEME="$GTK_ICON_THEME"
      fi
    fi

    # Delegate execution to CLI (now in the Nix store)
    exec ${shellSrc}/cli.sh "$@"
  '';

in pkgs.buildEnv {
  name = "Ambxst-${version}";
  paths = [ envAmbxst launcher ];
  meta.mainProgram = "ambxst";
}
