{
  config,
  lib,
  ...
}: let
  inherit (lib) any attrValues mkIf;

  wirelessEnabled =
    any ({wireless, ...}: wireless)
    (attrValues config.modulo.networking.interfaces);
in
  mkIf (config.modulo.networking.enable && wirelessEnabled) {
    networking.wireless.iwd = {
      enable = true;

      settings = {
        General = {
          AddressRandomization = "network";
          AddressRandomizationRange = "full";
          EnableNetworkConfiguration = false;

          # Prevent frequent roaming on unstable networks
          RoamThreshold = -75;
          RoamThreshold5G = -80;
        };

        Scan.DisablePeriodicScan = true;
      };
    };

    modulo.impermanence.directories = [
      {
        directory = "/var/lib/iwd";
        mode = "0700";
      }
    ];
  }
