{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkMerge;

  cfg = config.modulo.display;
in
{
  options.modulo.display = {
    x11 = mkEnableOption "x11 support";
  };

  config = mkMerge [
    {
      bubblewrap.sockets.wayland = true;
    }

    (mkIf cfg.x11 {
      bubblewrap = {
        # FIXME: Dynamically detect display index.
        env.XAUTHORITY = "/tmp/.X11-unix/X0";
        bind.ro = [ "/tmp/.X11-unix" ];
      };

      modulo.environment.envPassthrough = [ "DISPLAY" ];
    })
  ];
}
