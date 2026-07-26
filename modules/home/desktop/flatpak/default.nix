{
  lib,
  osConfig,
  ...
}:
let
  flatpakEnabled = osConfig.modulo.desktop.flatpak.enable;
in
{
  config = lib.mkIf flatpakEnabled {
    modulo.home-impermanence = {
      directories = [
        {
          directory = ".var/app";
          mode = "0700";
        }

        {
          directory = ".local/share/flatpak";
          mode = "0700";
        }
      ];
    };
  };
}
