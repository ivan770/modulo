{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.modulo.desktop.tlp;

  batteryThresholds = {
    preferBattery = {
      start = 95;
      stop = 100;
    };

    preferBalanced = {
      start = 75;
      stop = 80;
    };

    preferAC = {
      start = 45;
      stop = 50;
    };
  };
in
{
  options.modulo.desktop.tlp = {
    cpu = mkOption {
      type =
        with types;
        nullOr (submodule {
          options = {
            ac = mkOption {
              type = str;
              description = ''
                CPU scaling governor to use when connected to AC.
              '';
            };

            bat = mkOption {
              type = str;
              description = ''
                CPU scaling governor to use with battery.
              '';
            };
          };
        });
      default = null;
      description = ''
        TLP CPU governor configuration.
      '';
    };

    battery = {
      chargeMode = mkOption {
        type =
          with types;
          nullOr (enum [
            "preferBattery"
            "preferBalanced"
            "preferAC"
          ]);
        default = null;
        description = ''
          Battery charging thresholds configuration.
          Pass `null` to disable battery thresholds entirely.
        '';
      };
    };
  };

  config.services.tlp = mkIf (cfg.cpu != null) {
    enable = true;

    settings = mkMerge [
      {
        CPU_SCALING_GOVERNOR_ON_AC = cfg.cpu.ac;
        CPU_SCALING_GOVERNOR_ON_BAT = cfg.cpu.bat;

        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
      }

      (mkIf (cfg.battery.chargeMode != null) {
        START_CHARGE_THRESH_BAT0 = batteryThresholds.${cfg.battery.chargeMode}.start;
        STOP_CHARGE_THRESH_BAT0 = batteryThresholds.${cfg.battery.chargeMode}.stop;
      })
    ];
  };
}
