{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modulo.desktop.batsignal;
in
{
  options.modulo.desktop.batsignal = {
    enable = mkEnableOption "batsignal battery daemon";

    thresholds = {
      warning = mkOption {
        type = types.ints.positive;
        default = 20;
        description = ''
          Warning notification threshold.
        '';
      };

      critical = mkOption {
        type = types.ints.positive;
        default = 10;
        description = ''
          Critical notification threshold.
        '';
      };
    };
  };

  config.services.batsignal = mkIf cfg.enable {
    enable = true;

    extraArgs = [
      "-e"
      "-d"
      "0"
      "-w"
      (toString cfg.thresholds.warning)
      "-c"
      (toString cfg.thresholds.critical)
    ];
  };
}
