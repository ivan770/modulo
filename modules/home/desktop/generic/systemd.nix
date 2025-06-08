{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    makeBinPath
    mkIf
    mkOption
    types
    ;

  cfg = config.modulo.desktop.systemd;

  env-loader = pkgs.writeShellScript "env-loader" ''
    current=$(printenv)

    [ -f /etc/profile ] && . /etc/profile

    changed=$(comm -23 <(printenv | sort) <(echo "$current" | sort) \
      | sed 's/=.*//' \
      | xargs)

    systemctl --user import-environment $changed
  '';
in
{
  options.modulo.desktop.systemd = {
    command = mkOption {
      type = types.str;
      description = ''
        Window manager command.
      '';
    };

    runner = mkOption {
      internal = true;
      readOnly = true;
      type = types.str;
      default = "${getExe pkgs.modulo.slicer} -s app --";
      description = ''
        Application runner command.
      '';
    };
  };

  config = mkIf config.modulo.desktop.enable {
    systemd.user = {
      services = {
        wayland-wm = {
          Unit = {
            Description = "Wayland compositor";

            Requires = "graphical-session-pre.target";
            After = "graphical-session-pre.target";

            BindsTo = "graphical-session.target";
            Before = "graphical-session.target";
            PropagatesStopTo = "graphical-session.target";

            CollectMode = "inactive-or-failed";
          };

          Service = {
            Type = "notify";
            NotifyAccess = "all";
            ExecStart = cfg.command;
            TimeoutStartSec = 10;
            TimeoutStopSec = 10;
            Slice = "session.slice";
          };
        };

        env-loader = {
          Unit = {
            Description = "Shell profile loader";
            Before = "graphical-session-pre.target";
            RefuseManualStart = true;
            StopWhenUnneeded = true;
            CollectMode = "inactive-or-failed";
          };

          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            Environment = [ "PATH=${makeBinPath [ pkgs.coreutils ]}" ];
            ExecStart = env-loader;
          };

          Install.RequiredBy = [ "graphical-session-pre.target" ];
        };
      };

      sessionVariables = {
        SDL_VIDEODRIVER = "wayland";
        QT_QPA_PLATFORM = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
        NIXOS_OZONE_WL = 1;
        _JAVA_AWT_WM_NONREPARENTING = 1;
      };
    };
  };
}
