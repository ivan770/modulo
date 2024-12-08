{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.modulo.desktop;
in {
  options.modulo.desktop = {
    enable = mkEnableOption "desktop support";

    associations = mkOption {
      type = types.attrsOf types.str;
      default = {};
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
    ./terminal.nix
    ./wallpaper.nix
  ];

  config = mkIf cfg.enable {
    gtk = {
      enable = true;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    };

    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

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
