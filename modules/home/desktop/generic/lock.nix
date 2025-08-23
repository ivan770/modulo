{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe'
    mkEnableOption
    mkIf
    mkOption
    types
    ;

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

    usbguard = mkEnableOption "usbguard protection on the lock screen" // {
      default = osConfig.modulo.desktop.usbguard.enable;
      defaultText = "osConfig.modulo.desktop.usbguard.enable";
    };
  };

  config = mkIf (config.modulo.desktop.enable && cfg.command != null) {
    # Install systemd targets from upstream.
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

      usbguard-lock-screen = mkIf cfg.usbguard {
        Unit = {
          Description = "Disable all new USB devices on the lock screen";
          PartOf = "lock.target";
          Before = "lock.target";
        };

        Service =
          let
            usbguard = getExe' pkgs.usbguard "usbguard";
          in
          {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${usbguard} set-parameter InsertedDevicePolicy reject";
            ExecStop = "${usbguard} set-parameter InsertedDevicePolicy apply-policy";
            Slice = "session.slice";
          };

        Install.WantedBy = [ "lock.target" ];
      };

      lock-screen = {
        Unit = {
          Description = "Desktop screen lock";
          OnSuccess = "unlock.target";
          PartOf = "lock.target";
          Before = "lock.target";
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
