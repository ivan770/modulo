{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.desktop.bluetooth;
in
{
  options.modulo.desktop.bluetooth = {
    enable = mkEnableOption "Bluetooth support";
  };

  config = {
    hardware.bluetooth = {
      # Enforce consistency even when the default desktop configuration from Nixpkgs enables Bluetooth by default.
      inherit (cfg) enable;

      powerOnBoot = false;

      # Required to acquire the battery status of connected devices
      package = pkgs.bluez5-experimental;
      settings.General.Experimental = true;
    };

    modulo.impermanence.directories = mkIf cfg.enable [
      {
        directory = "/var/lib/bluetooth";
        mode = "0700";
      }
    ];
  };
}
