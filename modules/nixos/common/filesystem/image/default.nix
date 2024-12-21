{lib, ...}: let
  inherit (lib) mkEnableOption mkOption types;
in {
  options.modulo.filesystem.image = {
    name = mkOption {
      type = types.str;
      default = "modulo";
      description = ''
        Identifier used for various purposes (images, UKI files, etc.).
        Editing the value after the initial provisioning is a breaking change.
      '';
    };

    version = mkOption {
      type = types.ints.positive;
      description = ''
        Current image version.
        Should be incremented on new update releases.
      '';
    };

    device = mkOption {
      type = types.str;
      description = ''
        Primary device path to operate on.
      '';
    };

    partitions = {
      root = {
        size = mkOption {
          type = types.str;
          default = "6G";
          description = ''
            tmpfs root partition max size.
          '';
        };
      };

      esp = {
        size = mkOption {
          type = types.str;
          default = "256M";
          description = ''
            ESP partition size.
          '';
        };
      };

      store = {
        size = mkOption {
          type = types.str;
          default = "10G";
          description = ''
            Store partition size used per each A/B slot.
          '';
        };
      };

      data = {
        type = mkOption {
          type = types.enum ["ext4" "btrfs" "xfs"];
          default = "ext4";
          description = ''
            Filesystem to use for the data partition.
          '';
        };
      };
    };

    update = {
      enable = mkEnableOption "automatic system updates";

      url = mkOption {
        type = types.str;
        description = ''
          Update server URL. See systemd-sysupdate for more information.
        '';
      };

      reboot = mkEnableOption "automatic system reboot";
    };
  };

  imports = [
    ./build.nix
    ./runtime.nix
    ./update.nix
  ];
}
