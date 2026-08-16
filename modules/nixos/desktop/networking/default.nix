{
  config,
  lib,
  ...
}:
let
  cfg = config.modulo.networking;
in
{
  imports = [ ./firewall.nix ];

  config = lib.mkIf config.modulo.desktop.enable {
    networking.networkmanager = {
      # Enforce consistency even when the default desktop configuration from Nixpkgs enables networking by default.
      inherit (cfg) enable;

      dns = "systemd-resolved";
      wifi.macAddress = "stable-ssid";
    };

    modulo.impermanence.directories = lib.mkIf cfg.enable [
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
