{
  config,
  lib,
  options,
  ...
}:
let
  inherit (lib) getExe mkIf;

  cfg = config.modulo.desktop.alacritty;
in
{
  options.modulo.desktop.alacritty = {
    inherit (options.programs.alacritty) enable settings;
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      inherit (cfg) settings;

      enable = true;
    };

    modulo.desktop.terminal =
      let
        generic = getExe config.programs.alacritty.package;
      in
      {
        inherit generic;
        exec = "${generic} -e";
      };
  };
}
