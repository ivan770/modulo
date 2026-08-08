{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    attrNames
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

    # Network support implied by default.
    modulo.networking.enable = lib.mkDefault true;

    # Fonts are meant to be set up using Home Manager.
    fonts.fontconfig.defaultFonts = {
      monospace = [ ];
      serif = [ ];
      sansSerif = [ ];
      emoji = [ ];
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
        "preempt=full"
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
      dbus.enable = true;

      displayManager.autoLogin =
        let
          users = attrNames config.snowfallorg.users;
          autoLogin = (length users) == 1;
        in
        {
          enable = autoLogin;
          user = head users;
        };
    };
  };
}
