{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    genAttrs
    getExe
    mkIf
    mkOption
    types
    ;

  cfg = config.modulo.desktop.systemd;
in
{
  options.modulo.desktop.systemd = {
    startCommand = mkOption {
      type = types.str;
      description = ''
        Window manager start command.
      '';
    };

    reloadCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Window manager config reload command.
      '';
    };

    forceSessionSlice = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Units that should be forced to run in the `session.slice`.
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
      services.wayland-wm = {
        Unit = {
          Description = "Wayland compositor";

          Requires = "graphical-session-pre.target";
          After = "graphical-session-pre.target";

          BindsTo = "graphical-session.target";
          Before = "graphical-session.target";
          PropagatesStopTo = "graphical-session.target";

          CollectMode = "inactive-or-failed";

          X-SwitchMethod = "reload";
        };

        Service = {
          Type = "notify";
          NotifyAccess = "all";

          ExecStart = cfg.startCommand;
          ExecReload = mkIf (cfg.reloadCommand != null) cfg.reloadCommand;

          TimeoutStartSec = 10;
          TimeoutStopSec = 10;

          Slice = "session.slice";
        };
      };

      targets.graphical-session-post.Unit = {
        Description = "Session services which should run after the graphical session is terminated";
        DefaultDependencies = false;
        StopWhenUnneeded = true;

        Conflicts = [
          "graphical-session.target"
          "graphical-session-pre.target"
        ];

        After = [
          "graphical-session.target"
          "graphical-session-pre.target"
        ];
      };

      sessionVariables = {
        SDL_VIDEODRIVER = "wayland";
        QT_QPA_PLATFORM = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
        NIXOS_OZONE_WL = 1;
        _JAVA_AWT_WM_NONREPARENTING = 1;
      };
    };

    xdg.configFile =
      let
        sessionSliceFiles = map (n: "systemd/user/${n}.d/session-slice.conf") cfg.forceSessionSlice;
      in
      {
        "systemd/user/app-.service.d/order.conf".text = ''
          [Unit]
          After=wayland-wm.service graphical-session.target
        '';
      }
      // genAttrs sessionSliceFiles (_: {
        text = ''
          [Service]
          Slice=session.slice
        '';
      });
  };
}
