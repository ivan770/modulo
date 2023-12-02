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
        assertion = config.snowfallorg.user != {};
        message = ''
          At least one activated user is required to use the desktop configuration.
        '';
      }
    ];

    console.earlySetup = true;

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
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
        "boot.shell_on_fail"

        "mitigations=off"
        "nowatchdog"
        "nmi_watchdog=0"
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
          users = attrNames config.snowfallorg.user;
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
