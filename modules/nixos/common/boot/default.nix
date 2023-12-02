{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkMerge mkOption types;

  cfg = config.modulo.boot;
in {
  options.modulo.boot = {
    type = mkOption {
      type = types.enum [
        "systemd-boot"
        "generic-extlinux-compatible"
      ];
      description = ''
        Bootloader used for the current configuration.
      '';
    };

    timeout = mkOption {
      type = types.ints.unsigned;
      default = 0;
      description = "Bootloader entry selection screen timeout";
      example = 5;
    };

    systemd-boot.mountpoint = mkOption {
      type = types.str;
      default = "/boot/efi";
      description = "Bootloader mountpoint";
      example = "/boot";
    };
  };

  config.boot = let
    configurationLimit = 5;
  in
    mkMerge [
      {
        loader = {
          inherit (cfg) timeout;

          grub.enable = false;
        };

        initrd.systemd.enable = true;
      }
      (mkIf (cfg.type == "systemd-boot") {
        loader = {
          efi = {
            canTouchEfiVariables = true;
            efiSysMountPoint = cfg.systemd-boot.mountpoint;
          };

          systemd-boot = {
            inherit configurationLimit;

            enable = true;
            editor = false;
            consoleMode = "max";
          };
        };
      })
      (mkIf (cfg.type == "generic-extlinux-compatible") {
        loader.generic-extlinux-compatible = {
          inherit configurationLimit;

          enable = true;
        };
      })
    ];
}
