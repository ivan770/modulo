{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkOption types;

  cfg = config.modulo.desktop.tlp;
in {
  options.modulo.desktop.tlp = {
    cpu = mkOption {
      type = with types;
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
  };

  config.services.tlp = mkIf (cfg.cpu != null) {
    enable = true;

    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = cfg.cpu.ac;
      CPU_SCALING_GOVERNOR_ON_BAT = cfg.cpu.bat;

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
    };
  };
}
