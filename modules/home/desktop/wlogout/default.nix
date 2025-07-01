{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    getExe'
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modulo.desktop.wlogout;
in
{
  options.modulo.desktop.wlogout = {
    enable = mkEnableOption "wlogout support";

    command = mkOption {
      type = types.str;
      internal = true;
      description = ''
        Command to run the wlogout menu.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modulo.desktop.enable;
        message = ''
          You need to activate config.modulo.desktop.enable to use the wlogout module.
        '';
      }
    ];

    programs.wlogout = {
      enable = true;

      layout =
        let
          inherit (config.modulo.desktop) lock;

          systemctl = getExe' pkgs.systemd "systemctl";
        in
        [
          {
            text = "Shutdown";
            label = "shutdown";
            action = "${systemctl} poweroff";
          }
          {
            text = "Reboot";
            label = "reboot";
            action = "${systemctl} reboot";
          }
          {
            text = "Suspend";
            label = "suspend";
            action = lock.suspend;
          }
          {
            text = "Lock";
            label = "lock";
            action = lock.command;
          }
        ];
    };

    modulo.desktop.wlogout.command = "${getExe pkgs.wlogout} -b 2";
  };
}
