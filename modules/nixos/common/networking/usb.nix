{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.networking.usb;
in
{
  options.modulo.networking.usb = {
    enable = mkEnableOption "usb tethering support" // {
      default = !config.modulo.headless.enable;
      defaultText = "!config.modulo.headless.enable";
    };
  };

  config = mkIf (config.modulo.networking.enable && cfg.enable) {
    systemd.network.links."80-usb" = {
      matchConfig.OriginalName = "usb*";
      linkConfig.NamePolicy = "kernel";
    };
  };
}
