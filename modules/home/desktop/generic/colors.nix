{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.modulo.desktop.colors = {
    theme = mkOption {
      type = types.str;
      description = ''
        Selected color schema.
      '';
    };
  };
}
