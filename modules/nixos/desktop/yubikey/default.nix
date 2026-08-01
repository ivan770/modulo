{
  config,
  lib,
  pkgs,
  ...
}:
{
  config.services.udev.packages = lib.mkIf config.modulo.desktop.enable [
    pkgs.yubikey-personalization
  ];
}
