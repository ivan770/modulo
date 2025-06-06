{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkIf
    mkOption
    types
    ;

  cfg = config.modulo.boot;
in
{
  options.modulo.boot = {
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

  config.boot = {
    loader = {
      inherit (cfg) timeout;

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = cfg.systemd-boot.mountpoint;
      };

      grub.enable = mkDefault false;

      systemd-boot = mkIf (config.modulo.filesystem.type == "standard") {
        enable = true;
        editor = false;
        consoleMode = "max";
        configurationLimit = 5;
      };
    };

    initrd.systemd.enable = true;
  };
}
