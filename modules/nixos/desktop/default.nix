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
      {
        assertion = !config.modulo.headless.enable;
        message = ''
          Desktop and headless configurations are mutually exclusive.
        '';
      }
    ];

    # Required for Pipewire and Sway to acquire realtime capabilities.
    #
    # Modulo relies on user services for Pipewire activation,
    # so the "audio" group is not used here.
    security.pam.loginLimits = [
      {
        domain = "@users";
        type = "-";
        item = "memlock";
        value = "unlimited";
      }
      {
        domain = "@users";
        type = "-";
        item = "rtprio";
        value = "99";
      }
      {
        domain = "@users";
        type = "-";
        item = "nice";
        value = "-19";
      }
    ];

    # Fonts are meant to be set up using Home Manager.
    fonts.fontconfig.defaultFonts = {
      monospace = [];
      serif = [];
      sansSerif = [];
      emoji = [];
    };

    console.enable = false;
    hardware.graphics.enable = true;

    boot = {
      consoleLogLevel = 0;
      initrd.verbose = false;

      kernel.sysctl = {
        # https://github.com/FeralInteractive/gamemode/issues/425
        "kernel.split_lock_mitigate" = 0;
      };

      kernelParams = [
        "quiet"
        "udev.log_level=3"
        "boot.shell_on_fail"
        "mitigations=off"
        "nowatchdog"
        "tsc=nowatchdog"
        "audit=0"
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

      # Activated by greetd by default.
      displayManager.enable = false;

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
    };
  };
}
