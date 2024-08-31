{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.modulo.desktop.gammastep;
in {
  options.modulo.desktop.gammastep = {
    enable = mkEnableOption "gammastep daemon";

    temperature = {
      day = mkOption {
        type = types.ints.between 1000 25000;
        default = 6500;
        description = ''
          Day time temperature.
        '';
      };

      night = mkOption {
        type = types.ints.between 1000 25000;
        default = 3500;
        description = ''
          Night time temperature.
        '';
      };
    };

    time = {
      dawn = mkOption {
        type = types.str;
        default = "06:00-07:00";
        description = ''
          Dawn time range.
        '';
      };

      dusk = mkOption {
        type = types.str;
        default = "21:00-22:00";
        description = ''
          Dusk time range.
        '';
      };
    };

    nightBrightness = mkOption {
      type = types.numbers.between 0.1 1;
      default = 1;
      description = ''
        Night time screen brightness ratio.
      '';
    };
  };

  config.services.gammastep = mkIf cfg.enable {
    inherit (cfg) temperature;

    enable = true;

    latitude = 0.0;
    longitude = 0.0;

    dawnTime = cfg.time.dawn;
    duskTime = cfg.time.dusk;

    package =
      (pkgs.gammastep.override {
        withRandr = false;
        withGeolocation = false;
        withAppIndicator = false;
      })
      .overrideAttrs (_: {
        postInstall = ''
          rm $out/share/applications/gammastep.desktop
          rm $out/share/applications/gammastep-indicator.desktop
        '';
      });

    settings.general.brightness-night = cfg.nightBrightness;
  };
}
