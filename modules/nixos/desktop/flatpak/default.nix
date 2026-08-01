{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.modulo.desktop.enable {
    services.flatpak.enable = true;

    modulo.impermanence.directories = [
      {
        directory = "/var/lib/flatpak";
        mode = "0755";
      }
    ];
  };
}
