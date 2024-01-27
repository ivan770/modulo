{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) getExe mkEnableOption mkIf;

  cfg = config.modulo.desktop.sway;
in {
  options.modulo.desktop.sway = {
    enable = mkEnableOption "Sway desktop support";
  };

  config = mkIf cfg.enable {
    # Explicitly start sway from PATH to ensure that extraSessionCommands
    # are correctly executed when configured from HM.
    modulo.desktop.command = "systemd-cat -t sway sway";

    security.pam.services.swaylock = {};

    xdg.portal = {
      config.sway.default = ["wlr" "gtk"];

      wlr = {
        enable = true;

        settings.screencast = {
          max_fps = 30;
          chooser_type = "dmenu";
          chooser_cmd = "${getExe pkgs.bemenu} --list 10 -c -W 0.5 -f";
        };
      };

      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };
  };
}
