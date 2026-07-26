{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modulo.desktop;
in
{
  options.modulo.desktop = {
    enable = mkEnableOption "desktop support";

    associations = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Application associations with MIME types.
      '';
    };
  };

  imports = [ ./layout.nix ];

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    xdg = {
      enable = true;
      mime.enable = true;
    };
  };
}
