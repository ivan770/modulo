{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.desktop.udiskie;
in
{
  options.modulo.desktop.udiskie = {
    enable = mkEnableOption "udiskie support";
  };

  config = mkIf cfg.enable {
    services.udiskie = {
      enable = true;
      tray = "never";
    };

    home.packages = [ pkgs.udiskie ];
  };
}
