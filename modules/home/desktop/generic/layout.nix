{
  config,
  lib,
  ...
}: let
  inherit (lib) concatStringsSep mkIf mkOption types;

  cfg = config.modulo.desktop.layout;
in {
  options.modulo.desktop.layout = {
    layout = mkOption {
      type = types.listOf types.str;
      description = ''
        Keyboard layout.
      '';
    };

    options = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        X keyboard options.
      '';
    };
  };

  config = mkIf config.modulo.desktop.enable {
    home.keyboard = {
      inherit (cfg) options;

      layout = concatStringsSep "," cfg.layout;
    };
  };
}
