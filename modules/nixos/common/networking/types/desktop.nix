{
  config,
  lib,
  ...
}:
let
  cfg = config.modulo.networking;
in
{
  config = lib.mkIf (cfg.enable && config.modulo.desktop.enable) {
    networking.networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      wifi.macAddress = "stable-ssid";
    };

    modulo.impermanence.directories = [
      {
        directory = "/var/lib/NetworkManager";
        mode = "0700";
      }

      {
        directory = "/etc/NetworkManager/system-connections";
        mode = "0700";
      }
    ];
  };
}
