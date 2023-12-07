{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.modulo.desktop.lock = {
    command = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Optional desktop lock command to use during the suspend process.
      '';
    };
  };
}
