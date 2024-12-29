{
  config,
  lib,
  sloth,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.modulo.gtk;
in {
  options.modulo.gtk = {
    enable =
      mkEnableOption "GTK configuration propagation"
      // {
        enable = true;
      };

    cursor = {
      package = mkOption {
        type = types.package;
        description = ''
          Cursor package.
        '';
      };

      name = mkOption {
        type = types.str;
        description = ''
          The cursor name within the package.
        '';
      };

      size = mkOption {
        type = types.int;
        description = ''
          The cursor size.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    bubblewrap = {
      bind.ro = [
        (sloth.concat' sloth.xdgConfigHome "/gtk-3.0")
        (sloth.concat' sloth.xdgConfigHome "/gtk-4.0")
      ];

      env = {
        XCURSOR_THEME = cfg.cursor.name;
        XCURSOR_SIZE = cfg.cursor.size;
        XCURSOR_PATH = "${cfg.cursor.package}/share/icons";
      };

      extraStorePaths = [cfg.cursor.package];
    };
  };
}
