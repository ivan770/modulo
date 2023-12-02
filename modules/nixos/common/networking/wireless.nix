{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) any attrValues mkIf;

  wirelessEnabled =
    any ({wireless, ...}: wireless)
    (attrValues config.modulo.networking.interfaces);
in
  mkIf (config.modulo.networking.enable && wirelessEnabled) {
    networking.wireless.iwd.enable = true;

    environment.systemPackages = [pkgs.iwgtk];

    modulo.impermanence.directories = [
      {
        directory = "/var/lib/iwd";
        mode = "0700";
      }
    ];
  }
