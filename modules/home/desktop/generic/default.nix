{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modulo.desktop;
in
{
  options.modulo.desktop = {
    enable = mkEnableOption "desktop support";

    theme = mkOption {
      type = types.enum [
        "dark"
        "light"
      ];
      description = ''
        Preferred desktop color theme.
      '';
    };

    associations = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Application associations with MIME types.
      '';
    };
  };

  imports = [
    ./colors.nix
    ./cursor.nix
    ./layout.nix
    ./lock.nix
    ./menu.nix
    ./portal.nix
    ./systemd.nix
    ./terminal.nix
    ./wallpaper.nix
  ];

  config = mkIf cfg.enable {
    gtk = {
      enable = true;

      gtk3.extraConfig.gtk-application-prefer-dark-theme = mkIf (cfg.theme == "dark") true;

      gtk4 = {
        extraConfig.gtk-application-prefer-dark-theme = mkIf (cfg.theme == "dark") true;

        # Round corners are removed to make GTK 4 windows look better on tiling WMs.
        extraCss = ''
          window {
            border-top-left-radius: 0;
            border-top-right-radius: 0;
            border-bottom-left-radius: 0;
            border-bottom-right-radius: 0;
          }
        '';
      };
    };

    dconf.settings."org/gnome/desktop/interface".color-scheme =
      if cfg.theme == "dark" then "prefer-dark" else "prefer-light";

    fonts.fontconfig.enable = true;

    xdg = {
      enable = true;
      mime.enable = true;
      mimeApps = {
        enable = true;
        associations.added = cfg.associations;
        defaultApplications = cfg.associations;
      };
    };

    home.packages = [
      # Desktop utilities
      pkgs.wl-clipboard
      pkgs.xdg-utils
    ];
  };
}
