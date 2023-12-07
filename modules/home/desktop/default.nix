{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.desktop;
in {
  options.modulo.desktop = {
    enable = mkEnableOption "desktop support";
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

    fonts.fontconfig.enable = true;

    xdg = {
      enable = true;
      mime.enable = true;
      mimeApps.enable = true;
    };

    home = {
      packages = [
        # Fonts
        pkgs.corefonts
        pkgs.liberation_ttf
        pkgs.jetbrains-mono
        pkgs.material-design-icons
        pkgs.noto-fonts

        # Desktop utilities
        pkgs.wl-clipboard
        pkgs.xdg-utils
      ];
    };
  };
}
