{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    attrNames
    getExe
    head
    length
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modulo.desktop;
in {
  options.modulo.desktop = {
    enable = mkEnableOption "generic desktop configuration";

    command = mkOption {
      type = types.str;
      description = ''
        Desktop environment start command.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.snowfallorg.users != {};
        message = ''
          At least one activated user is required to use the desktop configuration.
        '';
      }
    ];

    # Required for default system-wide fonts configuration.
    # See fonts.fontconfig.defaultFonts.* for more information.
    fonts.packages = builtins.attrValues {
      inherit (pkgs) dejavu_fonts noto-fonts-color-emoji;
    };

    hardware.opengl.enable = true;

    xdg.portal.enable = true;

    boot = {
      consoleLogLevel = 0;
      initrd.verbose = false;

      kernelParams = [
        "quiet"
        "udev.log_level=3"
        "boot.shell_on_fail"
        "mitigations=off"
        "nowatchdog"
        "tsc=nowatchdog"
      ];

      blacklistedKernelModules = [
        # AMD-specific hardware watchdog
        "sp5100_tco"
      ];

      plymouth.enable = true;
    };

    programs.dconf.enable = true;

    services = {
      dbus = {
        enable = true;
        implementation = "broker";
        packages = [pkgs.gcr];
      };

      greetd = {
        enable = true;

        settings = let
          users = attrNames config.snowfallorg.users;
        in {
          default_session =
            if (length users) > 1
            then {
              command = ''
                ${getExe pkgs.greetd.tuigreet} \
                  --time \
                  --cmd ${cfg.command}
              '';

              user = "greeter";
            }
            else {
              inherit (cfg) command;
              user = head users;
            };
        };
      };

      # Delegate lid switch suspend to WM
      logind.lidSwitch = "ignore";
    };
  };
}
