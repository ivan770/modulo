{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption types;

  cfg = config.modulo.desktop.cursor;
in {
  options.modulo.desktop.cursor = {
    # https://github.com/nix-community/home-manager/blob/134deb46abd5d0889d913b8509413f6f38b0811e/modules/config/home-cursor.nix#L11-L28
    package = mkOption {
      type = types.package;
      default = pkgs.adwaita-icon-theme;
      defaultText = "pkgs.adwaita-icon-theme";
      description = ''
        Package providing the cursor theme.
      '';
    };

    name = mkOption {
      type = types.str;
      default = "Adwaita";
      description = ''
        The cursor name within the package.
      '';
    };

    size = mkOption {
      type = types.int;
      default = 36;
      description = ''
        The cursor size.
      '';
    };
  };

  config = mkIf config.modulo.desktop.enable {
    home.pointerCursor = {
      inherit (cfg) package name size;

      gtk.enable = true;
    };
  };
}
