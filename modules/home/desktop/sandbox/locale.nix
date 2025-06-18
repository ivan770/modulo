{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.locale;
in
{
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

      extraStorePaths = [ pkgs.tzdata ];
    };

    modulo.environment.envPassthrough = [
      "LANG"
      "LC_ADDRESS"
      "LC_COLLATE"
      "LC_CTYPE"
      "LC_MEASUREMENT"
      "LC_MESSAGES"
      "LC_MONETARY"
      "LC_NAME"
      "LC_NUMERIC"
      "LC_PAPER"
      "LC_TELEPHONE"
      "LC_TIME"
      "TZDIR"
    ];
  };
}
