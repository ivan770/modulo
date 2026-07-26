{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.desktop.flatpak;
in
{
  options.modulo.desktop.flatpak = {
    enable = mkEnableOption "Flatpak support";
  };

  config = mkIf cfg.enable {
    services.flatpak.enable = true;

    modulo.impermanence.directories = [
      {
        directory = "/var/lib/flatpak";
        mode = "0755";
      }
    ];
  };
}
