{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.desktop.yubikey;
in
{
  options.modulo.desktop.yubikey = {
    enable = mkEnableOption "YubiKey support";
  };

  config.services.udev.packages = mkIf cfg.enable [
    pkgs.yubikey-personalization
  ];
}
