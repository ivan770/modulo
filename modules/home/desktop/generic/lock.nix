{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) getExe' mkOption types;
in {
  options.modulo.desktop.lock = {
    command = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Optional desktop lock command to use during the suspend process.
      '';
    };

    suspend = mkOption {
      internal = true;
      readOnly = true;
      type = types.path;
      default = pkgs.writeShellScript "suspend" ''
        ${config.modulo.desktop.lock.command}
        ${getExe' pkgs.systemd "systemctl"} suspend
      '';
      description = ''
        Lock and suspend command.
      '';
    };
  };
}
