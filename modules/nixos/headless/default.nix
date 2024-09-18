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
    assertions = [
      {
        assertion = !config.modulo.desktop.enable;
        message = ''
          Desktop and headless configurations are mutually exclusive.
        '';
      }
    ];

    security.lockKernelModules = true;
  };
}
