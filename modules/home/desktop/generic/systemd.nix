{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe mkOption types;
in
{
  options.modulo.desktop.systemd = {
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
}
