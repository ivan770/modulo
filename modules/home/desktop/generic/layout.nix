{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mkIf
    mkOption
    types
    ;

  cfg = config.modulo.desktop.layout;
in
{
  options.modulo.desktop.layout = {
    xcompose = mkOption {
      type = with types; nullOr (listOf str);
      default = null;
      description = ''
        XCompose configuration.
      '';
    };
  };

  config = mkIf config.modulo.desktop.enable {
    home.file.".XCompose".text =
      let
        concat = concatStringsSep "\n" cfg.xcompose;
      in
      mkIf (cfg.xcompose != null) concat;
  };
}
