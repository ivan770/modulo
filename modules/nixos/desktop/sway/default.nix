{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.desktop.sway;
in
{
  options.modulo.desktop.sway = {
    enable = mkEnableOption "Sway desktop support";
  };

  config = mkIf cfg.enable {
    security.pam.services.swaylock = { };
  };
}
