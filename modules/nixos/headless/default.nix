{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modulo.headless;
in {
  options.modulo.headless = {
    enable = mkEnableOption "generic headless configuration";
  };

  config = mkIf cfg.enable {
    security.lockKernelModules = true;
  };
}
