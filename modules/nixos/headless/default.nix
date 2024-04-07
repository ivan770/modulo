{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf;

  cfg = config.modulo.headless;
in {
  options.modulo.headless = {
    enable = mkEnableOption "generic headless configuration";
  };

  config = mkIf cfg.enable {
    boot.kernelPackages = mkDefault pkgs.linuxPackages_hardened;

    environment.noXlibs = true;
  };
}
