{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.modulo.desktop.lock;
in
{
  options.modulo.desktop.lock = {
    command = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Optional desktop lock command to use during the suspend process.
      '';
    };
  };

  config = mkIf (config.modulo.desktop.enable && cfg.command != null) {
    home.packages = [ pkgs.systemd-lock-handler ];

    systemd.user.services = {
      systemd-lock-handler = {
        Unit.Description = "Mapper from logind events to systemd";

        Service = {
          Type = "notify";
          ExecStart = "${pkgs.systemd-lock-handler}/lib/systemd-lock-handler";
          Restart = "on-failure";
          RestartSec = 5;
          Slice = "session.slice";
        };

        Install.RequiredBy = [ "wayland-wm.service" ];
      };

      lock-screen = {
        Unit = {
          Description = "Desktop screen lock";
          OnSuccess = "unlock.target";
          PartOf = "lock.target";
          After = "lock.target";
        };

        Service = {
          Type = "forking";
          ExecStart = cfg.command;
          Restart = "on-failure";
          RestartSec = 0;
          Slice = "session.slice";
        };

        Install.WantedBy = [ "lock.target" ];
      };
    };
  };
}
