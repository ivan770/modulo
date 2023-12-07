{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.modulo.desktop.wallpaper = {
    file = mkOption {
      type = types.path;
      description = ''
        Preferred desktop wallpaper.
      '';
    };
  };
}
