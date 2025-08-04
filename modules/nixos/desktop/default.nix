{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    getExe
    head
    length
    mkEnableOption
    mkIf
    ;

  cfg = config.modulo.desktop;
in
{
  options.modulo.desktop = {
    enable = mkEnableOption "generic desktop configuration";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.snowfallorg.users != { };
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
      monospace = [ ];
      serif = [ ];
      sansSerif = [ ];
      emoji = [ ];
    };

    boot.enableContainers = false;
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

    systemd.oomd = {
      enable = true;
      enableUserSlices = true;
    };

    services = {
      dbus = {
        enable = true;
        implementation = "broker";
        packages = [ pkgs.gcr ];
      };

      # Activated by greetd by default.
      displayManager.enable = false;

      greetd =
        let
          users = attrNames config.snowfallorg.users;
          autoLogin = (length users) == 1;
          command = getExe pkgs.modulo.desktop-init;
        in
        {
          enable = true;

          settings = {
            terminal = {
              vt = "current";
              switch = false;
            };

            default_session.command = ''
              ${getExe pkgs.greetd.tuigreet} \
                --time \
                --cmd "${command}"
            '';

            initial_session = mkIf autoLogin {
              inherit command;
              user = head users;
            };
          };
        };
    };
  };
}
