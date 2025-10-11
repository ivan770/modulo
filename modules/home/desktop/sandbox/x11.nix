{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.x11;
in
{
  options.modulo.x11 = {
    enable = mkEnableOption "X11 support";
  };

  config = mkIf cfg.enable {
    bubblewrap.bind.ro = [ "/tmp/.X11-unix" ];
    modulo.environment.envPassthrough = [ "DISPLAY" ];
  };
}
