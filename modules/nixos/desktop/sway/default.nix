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
    # Explicitly start sway from PATH to ensure that extraSessionCommands
    # are correctly executed when configured from HM.
    modulo.desktop.command = "systemd-cat -t sway sway";

    security.pam.services.swaylock = { };
  };
}
