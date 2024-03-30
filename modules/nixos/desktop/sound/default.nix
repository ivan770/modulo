{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.desktop.sound;
in {
  options.modulo.desktop.sound = {
    enable = mkEnableOption "audio playback support";

    bluetooth = {
      extendedCodecs =
        mkEnableOption "extended Bluetooth codec support"
        // {
          default = true;
        };
    };
  };

  config = mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    security.rtkit.enable = true;

    environment.etc = mkIf config.modulo.desktop.bluetooth.enable {
      # https://nixos.wiki/wiki/PipeWire#Bluetooth_Configuration
      "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = mkIf cfg.bluetooth.extendedCodecs ''
        bluez_monitor.properties = {
          ["bluez5.enable-sbc-xq"] = true,
          ["bluez5-enable-msbc"] = true
        }
      '';
    };
  };
}
