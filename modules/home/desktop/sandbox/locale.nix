{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.locale;
in {
  options.modulo.locale = {
    enable = mkEnableOption "locale propagation";
  };

  config = mkIf cfg.enable {
    locale.enable = true;

    bubblewrap = {
      bind.ro = [
        "/etc/localtime"
        "/etc/zoneinfo"
      ];

      extraStorePaths = [pkgs.tzdata];
    };
  };
}
