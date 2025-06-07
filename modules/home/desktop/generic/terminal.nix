{ config, lib, ... }:
let
  inherit (lib) mkOption types;

  cfg = config.modulo.desktop.terminal;
in
{
  options.modulo.desktop.terminal = {
    generic = mkOption {
      type = types.str;
      description = ''
        Preferred user-wide terminal launch command.
      '';
    };

    wrapped = mkOption {
      internal = true;
      type = types.str;
      description = ''
        Wrapped generic terminal launch command to utilize the application launcher.
      '';
    };

    exec = mkOption {
      type = types.str;
      description = ''
        Command used to launch the preferred terminal with an exec program.
      '';
    };
  };

  config =
    let
      inherit (config.modulo.desktop.systemd) runner;
    in
    {
      modulo.desktop.terminal.wrapped = "${runner} ${cfg.generic}";
    };
}
