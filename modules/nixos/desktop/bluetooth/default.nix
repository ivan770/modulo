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
    onStartup = mkEnableOption "automatically enable Bluetooth on startup";
  };

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = cfg.onStartup;

      # Required to acquire the battery status of connected devices
      package = pkgs.bluez5-experimental;
      settings.General.Experimental = true;
    };

    modulo.impermanence.directories = [
      {
        directory = "/var/lib/bluetooth";
        mode = "0700";
      }
    ];
  };
}
