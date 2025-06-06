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
    mkMerge
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
      in
      {
        bind.ro = mkMerge [
          (mkIf (cfg.gtk3Config != null) [
            (sloth.concat' sloth.xdgConfigHome "/gtk-3.0/settings.ini")
            (builtins.toString gtk3)
          ])

          (mkIf (cfg.gtk4Config != null) [
            (sloth.concat' sloth.xdgConfigHome "/gtk-4.0/settings.ini")
            (builtins.toString gtk4)
          ])
        ];

        env = {
          XCURSOR_THEME = builtins.toString cfg.cursor.name;
          XCURSOR_SIZE = builtins.toString cfg.cursor.size;
          XCURSOR_PATH = "${cfg.cursor.package}/share/icons";
        };

        extraStorePaths =
          [ cfg.cursor.package ]
          ++ optional (cfg.gtk3Config != null) gtk3
          ++ optional (cfg.gtk4Config != null) gtk4;
      };
  };
}
