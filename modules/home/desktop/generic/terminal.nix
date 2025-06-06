{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.modulo.desktop.terminal = {
    generic = mkOption {
      type = types.str;
      description = ''
        Preferred user-wide terminal launch command.
      '';
    };

    exec = mkOption {
      type = types.str;
      description = ''
        Command used to launch the preferred terminal with an exec program.
      '';
    };
  };
}
