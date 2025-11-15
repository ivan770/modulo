{
  config,
  lib,
  pkgs,
  sloth,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    optional
    types
    ;

  cfg = config.modulo.gtk;
in
{
  options.modulo.gtk = {
    enable = mkEnableOption "GTK configuration propagation" // {
      default = true;
    };

    gtk3Config = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        GTK3 configuration file.
      '';
    };

    gtk4Config = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        GTK4 configuration file.
      '';
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
    bubblewrap =
      let
        # HM consolidates all generated files into a single derivation,
        # making it impossible to granularly control application access to
        # GTK configuration files.
        #
        # To avoid exposing the entire derivation, GTK configuration files
        # are generated once more for sandboxed apps.
        gtk3 = pkgs.writeText "gtk3-config" cfg.gtk3Config;
        gtk4 = pkgs.writeText "gtk4-config" cfg.gtk4Config;

        mkGtkBind =
          version: config:
          optional (cfg."gtk${version}Config" != null) [
            (builtins.toString config)
            (sloth.concat' sloth.xdgConfigHome "/gtk-${version}.0/settings.ini")
          ];
      in
      {
        bind.ro = (mkGtkBind "3" gtk3) ++ (mkGtkBind "4" gtk4);

        env = {
          XCURSOR_THEME = builtins.toString cfg.cursor.name;
          XCURSOR_SIZE = builtins.toString cfg.cursor.size;
          XCURSOR_PATH = "${cfg.cursor.package}/share/icons";
        };

        extraStorePaths = [
          cfg.cursor.package
        ]
        ++ optional (cfg.gtk3Config != null) gtk3
        ++ optional (cfg.gtk4Config != null) gtk4;
      };
  };
}
