{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.modulo.filesystem.image;
  version = builtins.toString cfg.version;
in
{
  config = mkIf (config.modulo.filesystem.type == "image") {
    fileSystems = {
      "/" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "size=${cfg.partitions.root.size}"
          "mode=755"
        ];
      };

      # Required for UKI updates
      "/efi" = {
        fsType = "vfat";
        device = "/dev/disk/by-partlabel/esp";
        neededForBoot = false;
      };

      "/usr" = {
        fsType = "erofs";
        device = "/dev/disk/by-partlabel/${cfg.name}_${version}";
        neededForBoot = true;
      };

      "/nix/store" = {
        fsType = "none";
        device = "/usr";
        options = [ "bind" ];
        neededForBoot = true;
      };

      "/data" = {
        fsType = cfg.partitions.data.type;
        label = "data";
        neededForBoot = true;
      };
    };

    boot.initrd.systemd = {
      repart = {
        inherit (cfg) device;

        enable = true;
      };

      services.udev-barrier = {
        description = "Trigger systemd-udevd and wait for device discovery";

        requires = [ "systemd-repart.service" ];
        after = [ "systemd-repart.service" ];

        wantedBy = [ "initrd.target" ];
        before = [
          "sysroot.mount"
          "sysusr-usr.mount"
          "create-needed-for-boot-dirs.service"
        ];

        script = ''
          udevadm trigger --settle
        '';

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
        };
      };

      units."systemd-fsck@.service".text = ''
        [Unit]
        After=udev-barrier.service
      '';
    };

    systemd.repart.partitions = {
      "10-esp" = {
        Type = "esp";
        Format = "vfat";
        SizeMinBytes = cfg.partitions.esp.size;
        SizeMaxBytes = cfg.partitions.esp.size;
      };

      "20-a-store" = {
        Type = "linux-generic";
        SizeMinBytes = cfg.partitions.store.size;
        SizeMaxBytes = cfg.partitions.store.size;
      };

      "30-b-store" = {
        Type = "linux-generic";
        Label = "_empty";
        SizeMinBytes = cfg.partitions.store.size;
        SizeMaxBytes = cfg.partitions.store.size;
      };

      "40-data" = {
        Type = "linux-generic";
        Label = "data";
        Format = cfg.partitions.data.type;
        FactoryReset = true;
      };
    };

    system.image = {
      inherit version;

      id = cfg.name;
    };

    modulo.impermanence.persistentDirectory = lib.mkDefault "/data";

    # /usr/bin/env is initialized during the activation phase,
    # breaking the activation script since the /usr filesystem is immutable.
    system.activationScripts = {
      usrbinenv = lib.mkForce "";
      binsh = lib.mkForce "";
    };

    # FIXME: console setup fails on image-based systems for some reason.
    # May be related: https://github.com/NixOS/nixpkgs/issues/312452
    boot.kernelParams = [ "systemd.mask=systemd-vconsole-setup.service" ];
  };
}
